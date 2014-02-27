package Com::Keysurvey::Configurator;

use strict;

####################### Synopsis ########################################
# The list of configuration parameters store in file main.conf. All 	#
# partameters are read and initialise once after the program start.		#
# Module provides checking of validity reciving parameters and their 	#
# values from file and outputs status message of configuration file:	#
# 	- CONFIG_OK - corrected config file have loaded;					#
#	- CONFIG_ERR - unsupported format of config file;					#
#	- FILE_CORRUPT - file is corrupt (missing parameter or unexpected 	#
#                  symbolspresent are presents);						#
#	- FILE_MISS - missing file or file can not be read.					#
# Module provides following public methods:								#
#	- new - constructor;												#
#	- isChecked - returns an error if occures;							#
#	- getErrorDescription - returns a descriptipton of given error.		#
#########################################################################

########## Variables #########
my $VERSION = "1.11";			# Version of module
my $CONFIG_FILE = "";			# path to configuration file
my @ERRORS=();					# Module errors

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
	$self->{LOGGER_FILE} = undef;
	$self->{LOGGER_MODE} = undef;
	$self->{ARTIFACTS_HOST} = undef;
	$self->{ARTIFACTS_SCHEME} = undef;
	$self->{ARTIFACTS_USER} = undef;
	$self->{ARTIFACTS_PATH} = undef;
	$self->{LOGS_HOST} = undef;
	$self->{LOGS_SCHEME} = undef;
	$self->{LOGS_USER} = undef;
	$self->{LOGS_PATH} = undef;
	$self->{BACKUP_HOST} = undef;
	$self->{BACKUP_USER} = undef;
	$self->{BACKUP_PATH} = undef;
	$self->{BACKUP_SCHEME} = undef;
	$self->{MAX_AGE} = undef;
	$self->{MAX_RELEASES} = undef;
	$self->{OPERATOR_MAILS} = undef;

	$CONFIG_FILE = $path_to_config_file;
	if (!$CONFIG_FILE or $CONFIG_FILE eq "")
	{
		my $message = "CONFIG::NO_FILE_PATH"; #"ERROR. It is not assign config file";
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
		my $message = "CONFIG::FILE_MISS"; #"ERROR. Missing file";
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
			if($result =~ m/(^PROGRAMM_NAME)\s*\=\s*\"(\D*)\s*\"/)
			{
				$self->setProgrammName($2);
			}
			elsif($result =~ m/(^LOGGER_FILE)\s*\=\s*\"([a-zA-Z1234567890.\/\-\s*\_]*)\"/)
			{
				$self->setLoggerFile($2);
			}
			elsif($result =~ m/(^LOGGER_MODE)\s*\=\s*\"([A-Z]*)\"/)
			{
				$self->setLoggerMode($2);
			}
			elsif($result =~ m/(^ARTIFACTS_HOST)\s\=\s\"([a-zA-Z1234567890.\/\-\s*\_]*|\d{1-3}\.\d{1-3}\.\d{1-3}\.\d{1-3})\s*\"/)
			{
				$self->{ARTIFACTS_HOST} = $2;
			}
			elsif($result =~ m/(^ARTIFACTS_SCHEME)\s*\=\s*\"([a-z]*)\s*\"/ig)
			{
				$self->{ARTIFACTS_SCHEME} = $2;
			}
			elsif($result =~ m/(^ARTIFACTS_USER)\s*\=\s*\"([a-zA-Z1234567890]*)\"/)
			{
				$self->{ARTIFACTS_USER} = $2;
			}
			elsif($result =~ m/(^ARTIFACTS_PATH)\s*\=\s*\"([a-zA-Z1234567890.\/\-\s*\_]*)\"/)
           {
            	$self->{ARTIFACTS_PATH} = $2;
            }
            elsif($result =~ m/(^LOGS_HOST)\s\=\s\"([a-zA-Z1234567890.\/\-\s*\_]*|\d{1-3}\.\d{1-3}\.\d{1-3}\.\d{1-3})\s*\"/)
			{
				$self->{LOGS_HOST} = $2;
			}
			elsif($result =~ m/(^LOGS_SCHEME)\s*\=\s*\"([a-z]*)\s*\"/ig)
			{
				$self->{LOGS_SCHEME} = $2;
			}
			elsif($result =~ m/(^LOGTS_USER)\s*\=\s*\"([a-zA-Z1234567890]*)\"/)
			{
				$self->{LOGTS_USER} = $2;
			}
			elsif($result =~ m/(^LOGS_PATH)\s*\=\s*\"([a-zA-Z1234567890.\/\-\s*\_]*)\"/)
                        {
                                $self->{LOGS_PATH} = $2;
                        }
			elsif($result =~ m/(^BACKUP_HOST)\s*\=\s*\"([a-zA-Z1234567890\.\-\_\/]*)\"/)
                        {
                                $self->{BACKUP_HOST} = $2;
                        }
			elsif($result =~ m/(^BACKUP_SCHEME)\s*\=\s*\"([a-z]*)\"/)
                        {
                                $self->{BACKUP_SCHEME} = $2;
                        }
                       	elsif($result =~ m/(^BACKUP_USER)\s*\=\s*\"([a-zA-Z1234567890\:\/\-\s*\_\.]*)\"/)
                        {
                                $self->{BACKUP_USER} = $2;
                        }
                       	elsif($result =~ m/(^BACKUP_PATH)\s*\=\s*\"([a-zA-Z1234567890.\/\-\s*\_]*)\"/)
                        {
                                $self->{BACKUP_PATH} = $2;
                        }
                        elsif($result =~ m/(^MAX_AGE)\s*\=\s*\"([\d*a-z]*)\"/)
                        {
                                $self->{MAX_AGE} = $2;
                        }
                        elsif($result =~ m/(^MAX_RELEASES)\s*\=\s*\"(\d*)\"/)
                        {
                                $self->{MAX_RELEASES} = $2;
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
# Search parameter
sub getParameterByName($)
{
	my $self = shift;
	my $input_parameter = shift @_;
	my $using_parameter = $input_parameter;
	my $output_parameter = "";
	if($self->{$using_parameter})
	{
		$output_parameter = $self->{$using_parameter};
	}
	else
	{
		$output_parameter = 'NULL';
	}
	return $output_parameter;
}

# Returned messages
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
# Description of errors
sub getErrorDescription($)
{
	my $self = shift;
	my $error = shift @_;
	my $description;
	if("CONFIG::FILE_CORRUPT" eq $error)
	{
		$description = "CONFIG ERROR! Config file corrupt.";
	}
	elsif("CONFIG::FILE_MISS" eq $error)
	{
		$description = "CONFIG ERROR! Missing file";
	}
	elsif("CONFIG::NO_FILE_PATH" eq $error)
	{
		$description = "CONFIG ERROR! It is not assign config file";
	}
	elsif("CONFIG::OK" eq $error)
	{
		$description = "CONFIG OK!";
	}
	else
	{
		$description = "CONFIG ERROR! Unknown error.";
	}
	return $description;
}
################# Setters and getters
# Method setProgrammName()
sub setProgrammName($)
{
	my ($self, $programm_name) = @_;
	$self->{PROGRAMM_NAME} = $programm_name;
}
#Method getProgrammName()
sub getProgrammName
{
	my $self = shift;
	return $self->{PROGRAMM_NAME};
}
# Method setLoggerFile()
sub setLoggerFile($)
{
	my ($self, $logger_file) = @_;
	$self->{LOGGER_FILE} = $logger_file;
}
#Method getLoggerFile()
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
#Method getLoggerMode()
sub getLoggerMode
{
	my $self = shift;
	return $self->{LOGGER_MODE};
}
#Method getBackupHost
sub getBackupHost
{
	my $self = shift;
	return $self->{BACKUP_HOST};
}
#Method getBackupPath()
sub getBackupPath
{
	my $self = shift;
	return $self->{BACKUP_PATH};
}
#Method getBackupScheme
sub getBackupScheme($)
{
	my $self = shift;
	return $self->{BACKUP_SCHEME};
}
#Method getBackupUser
sub getBackupUser
{
	my $self = shift;
	return $self->{BACKUP_USER};
}
#Method getArtifactsHost
sub getArtifactsHost
{
        my $self = shift;
        return $self->{ARTIFACTS_HOST};
}
#Method getArtifactsPath
sub getArtifactsPath
{
        my $self = shift;
        return $self->{ARTIFACTS_PATH};
}
#Method setArtifactsScheme
sub getArtifactsScheme($)
{
        my $self = shift;
        return $self->{ARTIFACTS_SCHEME};
}
#Method getArtifactsUser
sub getArtifactsUser
{
        my $self = shift;
        return $self->{ARTIFACTS_USER};
}
##################
#Method getLogsHost
sub getLogsHost
{
        my $self = shift;
        return $self->{LOGS_HOST};
}
#Method getLogsPath
sub getLogsPath
{
        my $self = shift;
        return $self->{LOGS_PATH};
}
#Method getLogsScheme
sub getLogsScheme($)
{
        my $self = shift;
        return $self->{LOGS_SCHEME};
}
#Method getLogsUser
sub getLogsUser
{
        my $self = shift;
        return $self->{LOGS_USER};
}
##################
#Method getMaxAge
sub getMaxAge
{
        my $self = shift;
        return $self->{MAX_AGE};
}
#Method getMaxReleases
sub getMaxReleases
{
        my $self = shift;
        return $self->{MAX_RELEASES};
}
#Method setOperatorMails()
sub setOperatorMails($)
{
	my ($self, $operator_mails) = @_;
	$self->{OPERATOR_MAILS} = $operator_mails;
}
#Method getOperatorMails()
sub getOperatorMails
{
	my $self = shift;
	return $self->{OPERATOR_MAILS};
}
#Method setSenderSMTPServer()
sub setSenderSMTPServer($)
{
	my ($self, $sender_smtp_server) = @_;
	$self->{SENDER_SMTP_SERVER} = $sender_smtp_server;
}
#Method getOperatorMails()
sub getSenderSMTPServer
{
	my $self = shift;
	return $self->{SENDER_SMTP_SERVER};
}

1;

