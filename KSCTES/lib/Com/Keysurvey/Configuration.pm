package Com::Keysurvey::Configuration;

use strict;
####################### Synopsis #####################
# The list of main configuration parameters are stored in main.conf.
# All parameters are read and initialize once right after the start of 
# the script. This module checks the configuration parameters 
# which are taken from file and outputs the status:
#     - CONFIG_OK - config file is loaded without errors;
#     - CONFIG_ERR - wrong format of cofiguration file;
#     - FILE_CORRUPT - somefiles aremising or unexpected symbols are 
# present;
#     - FILE_MISS - unable to read configuration file.
# The service starts if the CONFIG_OK is returned only.  

########## Variables #########
my $CONFIG_FILE = "";	# path to configuration file
my @ERRORS = ();		# Module errors

# Constructor
sub new($)
{
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $self={};
	bless($self, $class);
	
	my $param = shift @_;
	$self->Init($param);

	return($self);
}

# Initialize
sub Init(@)
{
	my $self = shift;
	my $path_to_config_file = shift @_;
	
	$self->{PROGRAMM_NAME} = undef;
	$self->{PROGRAMM_VERSION} = undef;
	$self->{LOGGER_FILE} = undef;
	$self->{LOGGER_MODE} = undef;
	$self->{DATABASE_HOST} = undef;
	$self->{DATABASE_NAME} = undef;
	$self->{DATABASE_LOGIN} = undef;
	$self->{DATABASE_PASSWORD} = undef;
	$self->{CHECK_DOMAIN_PERIOD} = undef;
	$self->{CHECK_VALIDITY_RECORDS_PERIOD} = undef;
	$self->{NOTIFY_PERIOD} = undef;
	$self->{OPERATOR_MAILS} = undef;
	$self->{SENDER_SMTP_SERVER} = undef;
	
	$CONFIG_FILE = $path_to_config_file;
	if (!$CONFIG_FILE or $CONFIG_FILE eq "")
	{
		my $message = "CONFIG::NO_FILE_PATH";	#"ERROR. It is not assign config file";
		$self->ReturnedMessage($message);
	}
	else
	{
		$self->ParseConfigParameters($CONFIG_FILE);
	}
}

# Decstructor
sub DESTROY
{
	# Created just in case. 
}

# Open configuration file and load data into array
sub OpenConfigFile($)
{
	my $self = shift;
	my $path_to_config_file = shift @_;
	my @result = ();
	if (-e $path_to_config_file)
	{
		# If file exist get file info without comments and empty lines
		open(FILE, $path_to_config_file);
		
		# read file, while strings are defined
		while(defined(my $file_contents=<FILE>))
		{
			next if $file_contents =~ m/^#/;		# pass a comments
			next if $file_contents =~ m/^\s+/;		# pass a new lines
			chomp $file_contents;
			push (@result, $file_contents);
		}
		close(FILE);
	}
	else
	{
		my $message = "CONFIG::FILE_MISS";	#"ERROR. Missing file";
		$self->ReturnedMessage($message);
	}
	return @result;
}

# Parser of config file for obtaining configuration parameters
sub ParseConfigParameters($)
{
	my $self = shift;
	my @result=();
	my $message;
	my $config_file = shift @_;
	@result = $self->OpenConfigFile($config_file);
	foreach my $result (@result)
	{
		for ($result)
		{
			if($result =~ m/(PROGRAMM_NAME)\s*\=\s*\"(\D*)\s*\"/)
			{
				$self->setProgrammName($2);
			}
			elsif($result =~ m/(PROGRAMM_VERSION)\s*\=\s*\"([a-zA-Z1234567890.\-\s*]*)\"/)
			{
				$self->setProgrammVersion($2);
			}
			elsif($result =~ m/(LOGGER_FILE)\s*\=\s*\"([a-zA-Z1234567890.\/\-\s*\_]*)\"/)
			{
				$self->setLoggerFile($2);
			}
			elsif($result =~ m/(LOGGER_MODE)\s*\=\s*\"([A-Z]*)\"/)
			{
				$self->setLoggerMode($2);
			}
			elsif($result =~ m/(DATABASE_HOST)\s*\=\s*\"([a-zA-Z1234567890\.\-\_]*)\"/)
			{
				$self->setDatabaseHost($2);
			}
			elsif($result =~ m/(DATABASE_NAME)\s*\=\s*\"([\D\_]*)\"/)
			{
				$self->setDatabaseName($2);
			}
			elsif($result =~ m/(DATABASE_LOGIN)\s*\=\s*\"(\D*)\"/)
			{
				$self->setDatabaseLogin($2);
			}
			elsif($result =~m/(DATABASE_PASSWORD)\s*\=\s*\"([\W*\w*\d]*)\"/)
			{
				$self->setDatabasePassword($2);
			}
			elsif($result =~ m/(CHECK_DOMAIN_PERIOD)\s*\=\s*(\d*)/)
			{
				$self->setCheckDomainPeriod($2);
			}
			elsif($result =~ m/(CHECK_VALIDITY_RECORDS_PERIOD)\s\=\s(\d+\w{0,1})\s*/)
			{
				$self->setCheckValidityRecordsPeriod($2);
			}
			elsif($result =~ m/(NOTIFY_PERIOD)\s\=\s(\d*)/)
			{
				$self->setNotifyPeriod($2);
			}
			elsif($result =~ m/(MAIL_TO)\s*\=\s*\"([\D*\_\.]*\@\D+\.[a-z]{2,})\s*\"/ig)
			{
				$self->setOperatorMails($2);
			}
			elsif($result =~ m/(SMTP_SERVER)\s*\=\s*\"([a-zA-Z1234567890\.\-\_]*)\"/)
			{
				$self->setSenderSMTPServer($2);
			}
			else
			{
				$message = "CONFIG::FILE_CORRUPT";
				$self->ReturnedMessage($message);
			}
		}
	}
}

# Returned messages
# Populates the array by errors for further processing (displaying to operator)
sub ReturnedMessage(@)
{
	my $self = shift;
	my $message = shift @_;
	push (@ERRORS, $message);
}

# Check for errors
sub isChecked
{
	my $result;
	if (scalar @ERRORS ne 0)
	{
		$result = join(":", @ERRORS);
	}
	else
	{
		$result = "CONFIG::OK";
	}
	return $result;
}

################# Setters and getters
# Method setProgramName()
sub setProgramName($)
{
	my ($self, $program_name) = @_;
	$self->{PROGRAM_NAME} = $program_name;
}
# Method getProgramName()
sub getProgramName
{
	my $self = shift;
	return $self->{PROGRAM_NAME};
}
# Method setProgramVersion()
sub setProgramVersion($)
{
	my ($self, $program_version) = @_;
	$self->{PROGRAM_VERSION} = $program_version;
}
# Method getProgramVersion()
sub getProgramVersion
{
	my $self = shift;
	return $self->{PROGRAM_VERSION};
}
# Method setLoggerFile()
sub setLoggerFile($)
{
	my ($self, $logger_file) = @_;
	$self->{LOGGER_FILE} = $logger_file;
}
# Method getLoggerFile()
sub getLoggerFile
{
	my $self = shift;
	return $self->{LOGGER_FILE};
}
# Method setLoggerMode()
sub setLoggerMode($)
{
	my ($self, $logger_mode) = @_;
	$self->{LOGGER_MODE} = $logger_mode;
}
# Method getLoggerMode()
sub getLoggerMode
{
	my $self = shift;
	return $self->{LOGGER_MODE};
}
# Method setDatabaseHost()
sub setDatabaseHost($)
{
	my ($self, $database_host) = @_;
	$self->{DATABASE_HOST} = $database_host;
}
# Method getDatabaseHost()
sub getDatabaseHost
{
	my $self = shift;
	return $self->{DATABASE_HOST};
}
# Method setDatabaseName()
sub setDatabaseName($)
{
	my ($self, $database_name) = @_;
	$self->{DATABASE_NAME} = $database_name;
}
# Method getDatabaseName()
sub getDatabaseName
{
	my $self = shift;
	return $self->{DATABASE_NAME};
}
# Method setDatabaseLogin()
sub setDatabaseLogin($)
{
	my ($self, $database_login) = @_;
	$self->{DATABASE_LOGIN} = $database_login;
}
# Method getDatabaseLogin()
sub getDatabaseLogin
{
	my $self = shift;
	return $self->{DATABASE_LOGIN};
}
# Method setDatabasePassword()
sub setDatabasePassword($)
{
	my ($self, $database_password) = @_;
	$self->{DATABASE_PASSWORD} = $database_password;
}
# Method getDatabasePassword()
sub getDatabasePassword
{
	my $self = shift;
	return $self->{DATABASE_PASSWORD};
}
# Method setCheckDomainPeriod()
sub setCheckDomainPeriod($)
{
	my ($self, $check_domain_period) = @_;
	$self->{CHECK_DOMAIN_PERIOD} = $check_domain_period;
}
# Method getCheckDomainPeriod()
sub getCheckDomainPeriod
{
	my $self = shift;
	return $self->{CHECK_DOMAIN_PERIOD};
}
# Method setCheckValidityRecordsPeriod()
sub setCheckValidityRecordsPeriod($)
{
	my ($self, $check_validity_records_period) = @_;
	$self->{CHECK_VALIDITY_RECORDS_PERIOD} = $check_validity_records_period;
}
# Method setNotifyPeriod()
sub setNotifyPeriod($)
{
	my ($self, $notify_period) = @_;
	$self->{NOTIFY_PERIOD} = $notify_period;
}
# Method getNotifyPeriod
sub getNotifyPeriod
{
	my $self = shift;
	return $self->{NOTIFY_PERIOD};
}
# Method getCheckValidityRecordsPeriod()
sub getCheckValidityRecordsPeriod
{
	my $self = shift;
	return $self->{CHECK_VALIDITY_RECORDS_PERIOD};
}
# Method setOperatorMails()
sub setOperatorMails($)
{
	my ($self, $operator_mails) = @_;
	$self->{OPERATOR_MAILS} = $operator_mails;
}
# Method getOperatorMails()
sub getOperatorMails
{
	my $self = shift;
	return $self->{OPERATOR_MAILS};
}
# Method setSenderSMTPServer()
sub setSenderSMTPServer($)
{
	my ($self, $sender_smtp_server) = @_;
	$self->{SENDER_SMTP_SERVER} = $sender_smtp_server;
}
# Method getOperatorMails()
sub getSenderSMTPServer
{
	my $self = shift;
	return $self->{SENDER_SMTP_SERVER};
}

1;
