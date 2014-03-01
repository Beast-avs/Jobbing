#!/usr/local/bin/perl -w

#
# See README file for description
#

use strict;

# Use own libs for better portability
use lib "lib";

use Log::Log4perl;
use Net::SNMP;	
# Change XML::LibXML to another parser which is not bonded to OS as hard as XML::LibXML does.
# XML::LibXML uses libxml lib which is compile for particular host.
use XML::LibXML;

our $CONFIG_FILE = "./etc/config.xml";
our $LOGGER_CONFIG_FILE;
our $LOCK_FILE;
our $HISTORY_FILE;
our $JOSLEE;
our $NETSTAT_CMD;
our @NMS_HOSTS;
our @SERVICES;
our $LOGGER;

#
# Reads configuration file, initialize all parameters, checks for availability of all resource files. 
#
# Receives path to configuration file.
#
# Returns nothing. 
#
sub Configuration($) {
	my $config_file = shift @_;
	
	require "./etc/SERVICE_Trapsender_configuration.pl";
	
	my $config_handle = XML::LibXML->new( load_ext_dtd => 0, validation => 0,);
	my $root = $config_handle->parse_file("$config_file");
	my $configuration = $root->getDocumentElement();
	
	# Resources
	my ($resource_element) = $configuration->findnodes('//resources');
	$LOGGER_CONFIG_FILE = $resource_element->findnodes('./logger_config_file');
	$LOCK_FILE = $resource_element->findnodes('./lock_file');
	$HISTORY_FILE = $resource_element->findnodes('./history_file');
	$JOSLEE = $resource_element->findnodes('./joslee');
	
	if (!defined($LOGGER_CONFIG_FILE) || $LOGGER_CONFIG_FILE eq "") {
		Logger("PANIC", "Path to log file ($LOGGER_CONFIG_FILE) is not set.\n");
	}
	if (! -f $LOGGER_CONFIG_FILE) {
		Logger("PANIC","Configuration file ($LOGGER_CONFIG_FILE) for logger is not available.");
	}
	
	# Initialize logger
	open(LOG_CONFIG, "<$LOGGER_CONFIG_FILE") or Logger("PANIC: Unable to open configuration file for logger $LOGGER_CONFIG_FILE");
	local $/ = undef;
	my $conf = <LOG_CONFIG>;
	close(LOG_CONFIG);

  	Log::Log4perl::init( \$conf );
	$LOGGER = Log::Log4perl->get_logger("Main");
	
	if (!defined($LOCK_FILE) || $LOCK_FILE eq "") {
		Logger("PANIC", "Path to lock file ($LOCK_FILE) is not set.\n");
	}
	if (!defined($HISTORY_FILE) || $HISTORY_FILE eq "") {
		Logger("ERROR", "Path to history file ($HISTORY_FILE) is not set.\n");
	}
	if (!defined($JOSLEE) || $JOSLEE eq "") {
		Logger("PANIC", "Path to JOSLEE ($JOSLEE) is not set.\n");
	}
	if (! -f $JOSLEE) {
		Logger("PANIC", "JOSLEE file ($JOSLEE) is not available.");
	}
	
	# NMS configuration hash building
	my ($monitoring_element) = $configuration->findnodes('//monitoring');
	foreach my $host ($monitoring_element->findnodes('//nms_host')) {
		my $community = $host->getChildrenByTagName('snmp_community');
		my $version = $host->getChildrenByTagName('snmp_version');
		
		if ($host->getAttribute('ip') !~ /\b(\d{1,3}(?:\.\d{1,3}){3})\b/) {
			Logger("PANIC", "IP address of NMS is not set or unvalid ($host->getAttribute('name')).\n");
		} else {		
			push(@NMS_HOSTS, {Name=>$host->getAttribute('name'),
				IP=>$host->getAttribute('ip'),
				Port=>$host->getAttribute('port'),
				community=>$community,
				version=>$version}
			);
		}
	}
	
	# SERVICE services hash building
	#
	# The configuration structure of is quite tricky:
	#      Array[Hash{key=value,...,key=array(Hash{key=value,...}),key=array(Hash{key=value,...})}]
	#
	# For example:
	# SERVICE[
	#			{name=SRV_1,trap_id="1",ip=10.10.10.10,port=50101,description="Service 1",
	#				metrics[
	#					{name='metric_1',trap_id="1",warning='',major='',critical=''},
	#					{name='metric_2',trap_id="2",critical=''}
	#				],
	#				connections[
	#					{name='REMOTE_HOST_1',trap_id="1",ip='10.10.20.1',port='*',warning='4',major='2',critical='1'},
	#					{name='REMOTE_HOST_2',trap_id="2",ip='10.10.40.1',port='*'},
	#					{name='REMOTE_HOST_3',trap_id="3",ip='10.10.50.1',port='*'},
	#					{name='REMOTE_HOST_4',trap_id="4",ip='10.10.0.1',port='50654-50657',major='2',critical='1'},
	#					{name='REMOTE_HOST_5',trap_id="5",ip='10.10.0.1',port='9004,9006',critical='1'}
	#				]
	#			}
	#		]
	#
	#
	my ($services_element) = $configuration->findnodes('//services');
	foreach my $service ($services_element->findnodes('./service_instance')) {
		if ($service->getAttribute('ip') !~ /\b(\d{1,3}(?:\.\d{1,3}){3})\b/) {
				Logger("PANIC", "IP address of SERVICE client is not set or unvalid (".$service->getAttribute('ip').")");
		} else {
			my $descr = $service->getChildrenByTagName('description');
			my @mertics;
			my ($metrics_nod) = $service->findnodes('./metrics');
			foreach my $metric ($metrics_nod->findnodes('./metric')) {
				push(@mertics,{
					Name=>$metric->getAttribute('name'),
					ID=>$metric->getAttribute('trap_id'),
					WARN=>$metric->getAttribute('warning'),
					MAJR=>$metric->getAttribute('major'),
					CRIT=>$metric->getAttribute('critical')}
				);
			}
			my @connections;
			my ($connections_nod) = $service->findnodes('./connections'); 
			foreach my $connection ($connections_nod->findnodes('./connection')) {
				if ($connection->getAttribute('ip') !~ /\b(\d{1,3}(?:\.\d{1,3}){3})\b/) {
					Logger("PANIC", "IP address of DIAMETER client is not set or unvalid (".$connection->getAttribute('ip').").");
				} else {
					push(@connections,{
						Name=>$connection->getAttribute('name'),
						ID=>$connection->getAttribute('trap_id'),
						IP=>$connection->getAttribute('ip'),
						Port=>$connection->getAttribute('port'),
						CRIT=>$connection->getAttribute('critical'),
						MAJR=>$connection->getAttribute('major'),
						WARN=>$connection->getAttribute('warning')}
					);
				}
			}
			push(@SERVICES,{
				Name=>$service->getAttribute('name'),
				ID=>$service->getAttribute('trap_id'),
				IP=>$service->getAttribute('ip'),
				Port=>$service->getAttribute('port'),
				Description=>$descr,
				Metrics=>\@mertics,
				Connections=>\@connections}
			);
		}
	} 
}

#
# Does some actions before exit, i.e. removes lock_file.
#
# Reseives the exit code.
#
# Returns nothing.
#
sub Exit($) {
	my $exitCode = shift @_;
	
	unlink $LOCK_FILE;
	Logger("INFO", "Exit with code $exitCode");
		
	exit($exitCode);
}

#
# Writes events into LOG_FILE.
#
# Recieves message saverity and the message.
#
# Returns nothing.
#
sub Logger($$) {
	my $saverity = shift @_;
	my $message = shift @_;
	
	if ($saverity eq "DEBUG") {
		$LOGGER->debug("$message");
	} elsif ($saverity eq "INFO") {
		$LOGGER->info("$message");
	} elsif ($saverity eq "WARN") {
		$LOGGER->warn("$message");	
	} elsif ($saverity eq "ERROR") {
		$LOGGER->error("$message");
	} elsif ($saverity eq "PANIC") {
		if (defined($LOGGER) && $LOGGER ne "") {
			$LOGGER->fatal("$message");
		}	
		print ("Logger: $saverity - $message|\n");
		Exit(1);
	}
	
}

#
# Send alert to remote NMS. Reads all NMS parameters from array @NMS_HOSTS.
#    NB! Severity ignored due to SNMP v1 limitations.
#
# Receives alert severity (CRIT/OK), id of item in SNMP tree, amd the message.
#
# Returns nothing.
#
sub SendNotification($$$) {
	my $severity = shift @_;
	my $trap_id = shift @_;
	my $message = shift @_;
	
	# This is a predefined OID
	my $SNMP_ENTERPRISE_OID = ".1.3.6.1.4.1.18376";
    my $SNMP_SPECIFIC_TRAP_OID = $trap_id;
	
	Logger("DEBUG", "Notification received: Severity=$severity, OID=$trap_id, Message=[$message]");
	
	my @vars = qw();
	my $varcounter = 1;
		
	push (@vars, $SNMP_ENTERPRISE_OID . '.' . $varcounter);
	push (@vars, OCTET_STRING);
	push (@vars, "Test string");
	
	foreach my $nms (@NMS_HOSTS) {
		Logger("DEBUG", "Notification will be send to NMS ".$$nms{'IP'}.":".$$nms{'Port'}." with community=".$$nms{'community'}." and SNMP v".$$nms{'version'});
		
		my ($session, $error) = Net::SNMP->session(
			-hostname  => $$nms{'IP'},
			-port => $$nms{'Port'},
      		-community => $$nms{'community'},
      		-version => $$nms{'version'}
   		);
   		
   		if (!defined $session) {
			Logger("ERROR", "Error connecting to target ".$$nms{'IP'}.":".$$nms{'Port'}. ": ". $error);
		}
		
		my $result = $session->trap(
			-varbindlist => \@vars,
			-enterprise => $SNMP_ENTERPRISE_OID,
			-specifictrap => $SNMP_SPECIFIC_TRAP_OID
		);
		
		Logger("DEBUG", $session->debug(255));
	}
}

#
# Checks the need to send clear message or not.
#
# Receives the exact record for chrcking in hostory file.
#
# Returns true (1) or false (0)
#
sub isClearTrapNeeded($) {
	my $record = shift @_;
	
	my $result = 0;

	my @HISTORY = ();
	if (-f $HISTORY_FILE) {
		open (IN_FILE, "<$HISTORY_FILE") or Logger("ERROR", "Unable to open history file $HISTORY_FILE");
		@HISTORY = <IN_FILE>;
		close (IN_FILE);
	}

	open (IN_FILE, ">$HISTORY_FILE") or Logger("ERROR", "Unable to open history file $HISTORY_FILE. It seems to blocked.");
	foreach my $file_record (@HISTORY) {
		chomp($file_record);
		($file_record eq $record) ? $result = 1 : print IN_FILE "$file_record\n";
	}
	close (IN_FILE);

	Logger("DEBUG", "isClearTrapNeeded: $record, $result");
	
	return $result;
}

#
# Get the metric value from Java application via JMX. Actually here is getting the value via 
# external app which connects to Java via JMX. 
#     NB! The better way is to get the value via JMX directly. It would be nice  
#     but the application has a key role and it will be present always. So, the 
#     "better way" will need only for study CPAN for solutions. Or write own solution. 
#
# Receives IP:port of service and metric.
#
# Returns the metric value or 0 in case of error with JOSLEE.
#
sub GetMetricValue($$) {
	my $socket = shift @_;
	my $metric = shift @_;
	
	my $result = "";
	
	Logger("DEBUG", "Metric $metric for service $socket has been requesting. $JOSLEE");

	# Get the metric value via external application	
	$result = (split(/=/,`$JOSLEE $socket -s $metric`))[1];
	$result = 0 if (!$result or "" eq $result);
	$result =~ s/^\s*//;
	$result =~ s/\s*$//;
	
	Logger("DEBUG", "Metric $metric for service $socket has value $result");
	
	return $result;
}

#
# Get the amount of conenctions between the localhost and the remote host according to given IP and port (or the port pattern).
#     NB! Filtering connection by ports not implemented yet.
#
# Receives the IP and the port (template for grep).
#
# Returns the number of connections.
#
sub GetConnectionResult($$){
	my $connection_ip = shift @_;
	my $connection_port = shift @_; 	# Ignored in processing.
	
	if (! -f $NETSTAT_CMD){
        Logger("ERROR", "Could not find netstat ($NETSTAT_CMD).");
    }

    my $conn_counter = 0;

    open (NET, "-|", "netstat", "-an") or Logger("ERROR", "Unable to open netstat $NETSTAT_CMD");

    while (my $line = <NET>){
        if ($line =~ /$connection_ip.*ESTABLISHED/) {
            $conn_counter++;
        }
    }
    close (NET);
	
	Logger("DEBUG", "The amount of connections between 'localhost' and $connection_ip:$connection_port is $conn_counter");
	
	return $conn_counter;
}

#
# Check the service availability and work.
#
# Receives the HASH of service data (service IP:Port, name, all metrics, and all connections to DIAMETER clients).
#
# Returns nothing.
#
sub Check(%){
	my %service = %{shift @_};
	
	my @mertics = $service{'Metrics'};
	my @connections = $service{'Connections'};
	
	Logger("DEBUG", "Checking the metrics for $service{'Name'}");
	
	foreach my $metrics (@mertics){
		foreach my $metric_out (@$metrics){			
			my $result = &GetMetricValue($service{'ip'}.":".$service{'Port'},$$metric_out{'Name'});
			
			# Calculating the saverity of message to send			
			if ($result >= $$metric_out{'critical'}) {
				SendNotification("CRIT",$$metric_out{'trap_id'},"Crtical threshold has been reached (".$$metric_out{'critical'}.")");
				open (OUT_FILE, ">>$HISTORY_FILE") or Logger("ERROR", "Unable to open history file $HISTORY_FILE");
        		print OUT_FILE "$service{'Name'}:$$metric_out{'Name'}\n";
        		close (OUT_FILE);
			} elsif ($result < $$metric_out{'critical'} && $result >= $$metric_out{'major'}) {
				SendNotification("MAJR",$$metric_out{'trap_id'},"Major threshold has been reached (".$$metric_out{'major'}.")");
				open (OUT_FILE, ">>$HISTORY_FILE") or Logger("ERROR", "Unable to open history file $HISTORY_FILE");
        		print OUT_FILE "$service{'Name'}:$$metric_out{'Name'}\n";
        		close (OUT_FILE);
			} elsif ($result < $$metric_out{'major'} && $result >= $$metric_out{'warning'}) {
				SendNotification("WARN",$$metric_out{'trap_id'},"Warning threshold has been reached (".$$metric_out{'warning'}.")");
				open (OUT_FILE, ">>$HISTORY_FILE") or Logger("ERROR", "Unable to open history file $HISTORY_FILE");
        		print OUT_FILE "$service{'Name'}:$$metric_out{'Name'}\n";
        		close (OUT_FILE);
			} elsif ($result < $$metric_out{'warning'}) {
				Logger("INFO", "Metric ".$$metric_out{'Name'}." has normal value $result for service ".$service{'Name'});
				if (&isClearTrapNeeded($service{'Name'}.":".$$metric_out{'Name'}) == 1) {
					SendNotification("OK",$$metric_out{'trap_id'},"Metric ".$$metric_out{'Name'}." has normal value ($result)");
				}
			}
		}
	}
	
	Logger("DEBUG", "Checking the connections for $service{'Name'}");
	
	foreach my $connections (@connections){
		foreach my $connection_out (@$connections){	
			my $result = &GetConnectionResult($$connection_out{'ip'},$$connection_out{'Port'});
			
			# Calculating the saverity of message to send
			if ($result < $$connection_out{'critical'}) {
				SendNotification("CRIT",$$connection_out{'id'},"Critical threshold has been reached for connection amount (".$$connection_out{'critical'}.") between 'localhost' and ".$$connection_out{'Name'});
				open (OUT_FILE, ">>$HISTORY_FILE") or Logger("ERROR", "Unable to open history file $HISTORY_FILE");
        		print OUT_FILE "$service{'Name'}:$$connection_out{'Name'}:$$connection_out{'Port'}\n";
        		close (OUT_FILE);
			} elsif ($result >= $$connection_out{'critical'} && $result < $$connection_out{'major'}) {
				SendNotification("MAJR",$$connection_out{'trap_id'},"Major threshold has been reached for connection amount (".$$connection_out{'major'}.") between 'localhost' and ".$$connection_out{'Name'});
				open (OUT_FILE, ">>$HISTORY_FILE") or Logger("ERROR", "Unable to open history file $HISTORY_FILE");
        		print OUT_FILE "$service{'Name'}:$$connection_out{'Name'}:$$connection_out{'Port'}\n";
        		close (OUT_FILE);				
			} elsif ($result >= $$connection_out{'major'} && $result < $$connection_out{'warning'}) {
				SendNotification("WARN",$$connection_out{'trap_id'},"Warning threshold has been reached for connection amount (".$$connection_out{'warning'}.") between 'localhost' and ".$$connection_out{'Name'});
				open (OUT_FILE, ">>$HISTORY_FILE") or Logger("ERROR", "Unable to open history file $HISTORY_FILE");
        		print OUT_FILE "$service{'Name'}:$$connection_out{'Name'}:$$connection_out{'Port'}\n";
        		close (OUT_FILE);
			} elsif ($result >= $$connection_out{'warning'}) {
				if (&isClearTrapNeeded($service{'Name'}.":".$$connection_out{'Name'}.":".$$connection_out{'Port'}) == 1) {
					SendNotification("OK",$$connection_out{'trap_id'},"The amount of connections between localhost and ".$$connection_out{'Name'}." is normal ($result)");
				}
			}
		}
	}
	
}

# Read configuration
Configuration($CONFIG_FILE);

# Main loop
foreach my $SERVICE (@SERVICES) {
	Check($SERVICE);
}

&Exit(0);