#!/usr/bin/perl -w

#
# This script sends SNMP messages generated as trap or clear to NMS host.
# This script has a configuration file which contains all necessary 
# values, such as:
#      - A list of SNMP_service instances (hosts);
#      - A list of metrics (counters) for all SNMP_service instances;
#      - A list of SNMP configuration parameters (community, version);
#      - IP adress of the host which receives SNMP traps (NMS);
#      - Paths to log, lock, and history files.
# 
# The script has a mechanism which not allows to run more than one its 
# instance simultaneously. 
#
# Log file contains the results of key calls and steps during the work.
#
# For sending the clear messages (signal that problem has been solved) 
# the history file is used. It keeps the pairs Service_name-Metric_name. As
# soon as problem is found this pair adds to history file. When problem has
# solved this pair is removed from history.
#
# The path to configuration file is hardcoded.
#
# TODO:
#       1. Implement reading configuration file from command line.
#       2. Implement current configuration without running the script.
#       3. Implement getting trap message from 'snmp_alets.out' file.

use strict;

use POSIX;
use File::Basename;
use Getopt::Long qw(:config no_ignore_case bundling);
use FileHandle;

our $PROGRAMM_VERSION = "1.0";

our $BASE_DIR = dirname($0);
(our $PROGRAMM = basename($0)) =~ s/\.[^.]+$//;

our $CONFIG_FILE = $BASE_DIR."/etc/SNMP_trapsender.conf";
our $PID = $$;

# Date and time format: YYYY-MM-DD HH:MM:SS
our $DATE_FORMAT = "%F %T";

our $METRICS_EXTRACTOR = "/<PATH_TO_METRIC_EXTRACTOR>/METRICS_EXTRACTOR.sh";

# Read from config file
our $LOG_FILE = "";
our $LOCK_FILE = "";
our $HIST_FILE = "";
our $NMS_host = "";
our %Snmp_service;
our %Metrics;
our %Snmp;

use vars qw (
	$verbose
);

GetOptions(
	'v!'		=> \$verbose,
	'verbose!'	=> \$verbose,
	'h'			=> \&Help,
	'help'		=> \&Help
);
 

sub Help (){
	print << "HELP";
This script sends SNMP messages generated as trap or clear to NMS host.

Version: $PROGRAMM_VERSION

Usage: $PROGRAMM.pl [options]

Options:
     -h, help        - Print this message
     -v, verbose     - Enable verbose output
	
HELP
}

sub Errors ($$) {
	my $saverity = shift @_;
	my $message = shift @_;
	my $HEADER = POSIX::strftime("$DATE_FORMAT", localtime())."     $saverity";
	
	open LOG_FILE, ">>$LOG_FILE" or die $!;

	if ("ERROR" eq $saverity){
		print LOG_FILE "$HEADER     $message\nI'm exit.\n";
		print("ERROR! $message\n");
		&Exit(1);
	}elsif("WARNING" eq $saverity){
		print LOG_FILE "$HEADER   $message\n";
	}elsif("OK" eq $saverity){
		print LOG_FILE "$HEADER        $message\n";
	}else{
		print LOG_FILE "$HEADER     $message\nI'm exit.\n";
		print("ERROR! $message\n");
		&Exit(1);
	}

	close LOG_FILE;
}

sub Exit ($){
	my $exitCode = shift @_;
	unlink $LOCK_FILE;
	Errors("OK","Exit with code $exitCode");
	exit($exitCode);
}

sub ConfigurationRead($){
	my $config_file = shift @_;

	my %config;
	open CONF_FILE, "<$config_file" or Errors("ERROR", "Unable to open configuration file $config_file");
	
	 my $snmp_flag = 0;
	 my $Snmp_service_flag = 0;
	 my $metrics_flag = 0;

	while (<CONF_FILE>){
		my $conf_line = $_;
		chop ($conf_line);          
		$conf_line =~ s/^\s*//;
		$conf_line =~ s/\s*$//;
		if (($conf_line !~ /^#/) && ($conf_line ne "")){
			my ($name, $value) = split (/=/, $conf_line);
			$name =~ s/^\s*// if defined($name);
			$name =~ s/\s*$// if defined($name);
			$value =~ s/^\s*// if defined($value);
			$value =~ s/\s*$// if defined($value);
			$value =~ s/"([^"]*)"/$1/ if defined($value);

			if ($conf_line =~ /^Log_file/){
				($LOG_FILE) = $conf_line =~ /"([^"]*)"/;
			}elsif($conf_line =~ /^Lock_file/){
				($LOCK_FILE) = $conf_line =~ /"([^"]*)"/;
			}elsif($conf_line =~ /^History_file/){
				($HIST_FILE) = $conf_line =~ /"([^"]*)"/;
            }elsif($conf_line =~ /^NMS_host/){
				($NMS_host) = $conf_line =~ /"([^"]*)"/;
			}elsif($conf_line =~ /^SNMP\s*=\s*{/){
				$snmp_flag = 1;
			}elsif($conf_line =~ /^SNMP_service\s*=\s*\{/){
				$Snmp_service_flag = 1;
			}elsif($conf_line =~ /^Metrics\s*=\s*\{/){
				$metrics_flag = 1;
			}elsif($snmp_flag eq 1) {
				if($conf_line =~ /^\s*}\s*$/){
					$snmp_flag = 0;
				}else{
					$Snmp{$name} = $value;
				}
			}elsif($Snmp_service_flag eq 1){
				if($conf_line =~ /^\s*}\s*$/){
					$Snmp_service_flag = 0;
				}else{
					$Snmp_service{$name} = $value;
				}
			}elsif($metrics_flag eq 1){
				if($conf_line =~ /^\s*}\s*$/){
					$metrics_flag = 0;
				}else{
					$Metrics{$name} = $value;
				}
			}
		}
	}
	
	close(CONF_FILE);
}

sub CheckConfiguration(){
	if (!defined($LOCK_FILE) || $LOCK_FILE eq ""){
		Errors("ERROR", "Path to lock file ($LOCK_FILE) is not set.\n");
	}
	if (!defined($LOG_FILE) || $LOG_FILE eq ""){
		Errors("ERROR", "Path to log file ($LOG_FILE) is not set.\n");
	}
	if (!defined($HIST_FILE) || $HIST_FILE eq ""){
        Errors("ERROR", "Path to history file ($HIST_FILE) is not set.\n");
    }
	if ($NMS_host !~ /\b(\d{1,3}(?:\.\d{1,3}){3})\b/){
		Errors("ERROR", "IP address of NMS is not set or unvalid ($NMS_host).\n");
	}
	
	foreach my $Snmp_service_key (keys %Snmp_service){
		if ($Snmp_service{$Snmp_service_key} !~ /\b(\d{1,3}(?:\.\d{1,3}){3}:\d{1,5})\b/){
			Errors("ERROR", "IP address for $Snmp_service_key is invalid ($Snmp_service{$Snmp_service_key}).");
		}
	}

	if (-f "$LOCK_FILE") {
		open LOCK_FILE, "<$LOCK_FILE" or die $!;
		Errors("ERROR", "I'm already running (my PID is ".<LOCK_FILE>.")");
		close LOCK_FILE;
	}else{
		open LOCK_FILE, ">$LOCK_FILE" or die $!;
		print LOCK_FILE "$PID";
		Errors("OK", "Starting the programm with PID ".$PID);
		close LOCK_FILE or die $!;
	}
}

sub isClearTrapNeeded ($){
    my $record = shift @_;
    my $result = 0;
    my @HISTORY = ();
    
    if (-f $HIST_FILE){
       open (IN_FILE, "<$HIST_FILE") or Errors("ERROR", "Unable to open history file $HIST_FILE");
       @HISTORY = <IN_FILE>;
       close (IN_FILE);
    }

    open (IN_FILE, ">$HIST_FILE") or Errors("ERROR", "Unable to open history file $HIST_FILE. It seems to blocked.");
    foreach my $file_record (@HISTORY){
       chomp($file_record);
       ($file_record eq $record) ? $result = 1 : print IN_FILE "$file_record\n";
    }
    close (IN_FILE);

    return $result;
}

sub Check($$){
    my %SNMP_service_instance = %{shift @_};
    my %SNMP_service_metric = %{shift @_};
    my $result = 0;

    if (!-f $METRICS_EXTRACTOR){
       Errors("ERROR", "Could not find $METRICS_EXTRACTOR.");
    }

    my $uptime = (split(/=/,`$METRICS_EXTRACTOR $SNMP_service_instance{'host'} -s TimeSec`))[1];
    $uptime = 0 if (!$uptime or "" eq $uptime);
    $uptime =~ s/^\s*//;
    $uptime =~ s/\s*$//;

    if ($uptime eq "0"){
       SendSNMPTRAP("error", "0", "SNMP service instance $SNMP_service_instance{'name'} ($SNMP_service_instance{'host'}) is unavailable.");
       Errors("OK", "Write to hitory file ($HIST_FILE): $SNMP_service_instance{'name'}:TimeSec");
       open (OUT_FILE, ">>$HIST_FILE") or Errors("ERROR", "Unable to open history file $HIST_FILE");
       print OUT_FILE "$SNMP_service_instance{'name'}:TimeSec\n";
       close (OUT_FILE);
    }else{
       if (&isClearTrapNeeded("$SNMP_service_instance{'name'}:TimeSec") eq "1"){
          SendSNMPTRAP("clear", "$uptime", "SNMP service instance $SNMP_service_instance{'name'} is working. Uptime is $result.");
       }else{
          $result = (split(/=/,`$METRICS_EXTRACTOR $SNMP_service_instance{'host'} -s $SNMP_service_metric{'name'}`))[1];
          $result = 0 if (!$result or "" eq $result);
          $result =~ s/^\s*//;
          $result =~ s/\s*$//;

          my ($threshold_high, $threshold_low) = split(/:/, $SNMP_service_metric{'value'});
          $threshold_high = 9**9**9 if (!defined($threshold_high) || $threshold_high eq "");
          $threshold_low = 0 if (!defined($threshold_low) || $threshold_low eq "");

          if ($result < $threshold_low){
             SendSNMPTRAP("error", "$uptime", "SNMP service instance $SNMP_service_instance{'name'} has a low value ($result) for $SNMP_service_metric{'name'}.");
             Errors("OK", "Write to hitory file ($HIST_FILE): $SNMP_service_instance{'name'}:$SNMP_service_metric{'name'}");
             open (OUT_FILE, ">>$HIST_FILE") or Errors("ERROR", "Unable to open history file $HIST_FILE");
             print OUT_FILE "$SNMP_service_instance{'name'}:$SNMP_service_metric{'name'}\n";
             close (OUT_FILE);
          }elsif (($result < $threshold_high) && ($result >= $threshold_low)){
             if (&isClearTrapNeeded("$SNMP_service_instance{'name'}:$SNMP_service_metric{'name'}") eq "1"){
                SendSNMPTRAP("clear", "$uptime",  "Snmp service instance $SNMP_service_instance{'name'} has a normal value ($result) for $SNMP_service_metric{'name'}");
             }else{
                Errors("OK", "SNMP service instance $SNMP_service_instance{'name'} has a normal value ($result) for $SNMP_service_metric{'name'}");
             }
          }elsif($result > $threshold_high){
             SendSNMPTRAP("error", "$uptime", "SNMP service instance $SNMP_service_instance{'name'} has a high value ($result) for $SNMP_service_metric{'name'}.");
             Errors("OK", "Write to hitory file ($HIST_FILE): $SNMP_service_instance{'name'}:$SNMP_service_metric{'name'}");
             open (OUT_FILE, ">>$HIST_FILE") or Errors("ERROR", "Unable to open history file $HIST_FILE");
             print OUT_FILE "$SNMP_service_instance{'name'}:$SNMP_service_metric{'name'}\n";
             close (OUT_FILE);
          }
       }
    }
}

sub SendSNMPTRAP ($$$) {
	my $trapType = shift @_;
    my $uptime = shift @_;
	my $trapMessage = shift @_;
	Errors("WARNING", $trapMessage);

	my $ENT_OID = ".1.3.6.1.4.1.2013";
	my $HEADER = "";
    if ($trapType eq "error"){
       $HEADER = "$uptime $ENT_OID $ENT_OID.1 string \"ENT\" $ENT_OID.2 string \"SNMP Service\" $ENT_OID.3 string \"Performance Monitoring\" $ENT_OID.4 string \"Trap\"";
    }elsif($trapType eq "clear"){
       $HEADER = "$uptime $ENT_OID $ENT_OID.1 string \"ENT\" $ENT_OID.2 string \"SNMP Service\" $ENT_OID.3 string \"Performance Monitoring\" $ENT_OID.4 string \"Clear\"";
    }
	
	if (!-f $Snmp{'SNMPTRAP_command'}){
		Errors("ERROR", "Could not find $Snmp{'SNMPTRAP_command'}");
	}

	my $cmd = "$Snmp{'SNMPTRAP_command'} -v $Snmp{'version'} -c $Snmp{'community'} $NMS_host $HEADER $ENT_OID.3.0 string \"$trapMessage\"";
	Errors("WARNING", "This trap will be sent:\n$cmd");
	`$cmd`;
	if ($? gt 0){
		Errors("ERROR", "Could not run $cmd");
	}
}

&ConfigurationRead($CONFIG_FILE);
&CheckConfiguration();

foreach my $Snmp_service_key (keys %Snmp_service){
	foreach my $metrics_key (keys %Metrics){
		&Check({name=>$Snmp_service_key,host=>$Snmp_service{$Snmp_service_key}},{name=>$metrics_key,value=>$Metrics{$metrics_key}});
	}
}


&Exit(0);
