package Com::Keysurvey::Logger;

use strict;

####################### Synopsis ########################################
# Logging must to be produced in accordance with configuration 			#
# parameters. Parameters can be following:								#
#	- DEBUG - output to log all records about proceedings events		#
#	- ERROR - output in log only errors									#
#	- INFO - output in log messages marked as INFO, WARN, ERROR 		#
#				(default)												#
#	- WARN - output messages marked as WARN and ERROR					#
# Module provides following public methods:								#
#	- new - constructor													#
#	- getMode - return a mode of logger									#
#	- setMode - allow to set a mode of logger							#
#	- isChecked - return a error if occure								#
#	- getErrorDescription - return a descriptipton of given error		#
#########################################################################

########## Variables #########
my $VERSION = "1.1";	# Version of module
my $LOG_FILE = "";		# path to log file
my $LOG_MODE = "";		# logger mode
my @ERRORS=();			# Module errors

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
	my $path_to_log_file = shift @_;
	$LOG_FILE = $path_to_log_file;

	if (!$LOG_FILE or $LOG_FILE eq "")
	{
		my $message = "LOGGER::NO_FILE_PATH"; #"ERROR. It is not assign logger file";
		$self->ReturnedMessage($message);
	}
}

# Decstructor
sub DESTROY
{
	
}

# Open configuration file and load data into array
sub OpenLogFile($)
{
	my $self = shift;
	my ($type, $message) = @_;
	my $path_to_log_file = $LOG_FILE;
	my $mode = $LOG_MODE;
	my @result = ();
	if (-e $path_to_log_file)
	{
		# If file exist get file info without comments and empty lines
		open(FILE, ">>$path_to_log_file");
		
		# write to file
		print FILE $self->GetCurrentDate() ."\t$type\t$message"."\n";

		close(FILE);
	}
	else
	{
		my $message = "LOGGER::FILE_MISS"; #"ERROR. Missing file";
		$self->ReturnedMessage($message);
	}
	return @result;
}

# Method GetCurrentDate
sub GetCurrentDate
{
	my($output_type)=shift;
	my @current_time=localtime(time);	# Array of current time (see in perldoc)
	my $result;
	
	my $year = ($current_time[5]) + 1900;	# Current year
	my $month = ('Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec')[ $current_time[4] ];	# Current month
	my $today = ('Sun','Mon','Tue','Wed','Thur','Fri','Sat')[ (localtime)[6] ];		# Current day of week
	my $day; 	# Current day
	my $hour;	# Current hour
	my $min;	# Current minut
	my $sec;	# Current second
	
	# Folloving checking for day, hour, minutes and second needed for a correct output of values less then 10 (for example 12:09:08).
	# If one of currents day, hour, minutes and second are less then 10, before value will be add a 0 (zero).
	if ($current_time[3] < 10 && $current_time[3] >= 0) 
	{
		$day = "0$current_time[3]";
	}
	else
	{
		$day = $current_time[3];
	}
	if ($current_time[2] < 10 && $current_time[2] >= 0) 
	{
		$hour = "0$current_time[2]";
	}
	else
	{
		$hour = ($current_time[2]);
	}
	if ($current_time[1] < 10 && $current_time[1] >= 0) 
	{
		$min = "0$current_time[1]";
	}
	else
	{
		$min = ($current_time[1]);
	}
	if ($current_time[0] < 10 && $current_time[0] >= 0) 
	{
		$sec = "0$current_time[0]";
	}
	else
	{
		$sec = ($current_time[0]);
	}
	# Return a current date and time in format (like an output in /var/log/messages):
	#	YEAR MON DAY HH:MM:SS
	#
	$result = "$year $month $day $hour:$min:$sec";

	return $result;
}
# Method MakeRecord
sub MakeRecord(@)
{
	my $self = shift;
	my ($type, $message) = @_;
	$self->OpenLogFile($type,$message);
}

# Check for errors
sub isChecked
{
	my $self = shift;
	my $result;
	
	if (scalar @ERRORS ne 0)
	{
		$result = join(":", @ERRORS);
	}
	else
	{
		$result = "LOGGER::OK";
	}
	return $result;
}
# Description of errors
sub getErrorDescription($)
{
	my $self = shift;
	my $error = shift @_;
	my $description;
	if("LOGGER::FILE_MISS" eq $error)
	{
		$description = "LOGGER ERROR! Missing file";
	}
	elsif("LOGGER::NO_FILE_PATH" eq $error)
	{
		$description = "LOGGER ERROR! It is not assign logger file";
	}
	else
	{
		$description = "LOGGER ERROR! Unknown error.";
	}
	return $description;
}
# Returned messages
sub ReturnedMessage(@)
{
	my $self = shift;
	my $message = shift @_;
	push (@ERRORS, $message);
}

################# Setters and getters
# Method setMode
sub setMode($)
{
	my ($self, $mode) = @_;
	$LOG_MODE = $mode;
}
# Method getMode
sub getMode($)
{
	my $self = shift;
	return $LOG_MODE;
}
1;
