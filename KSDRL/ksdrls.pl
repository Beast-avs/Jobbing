#!/usr/bin/perl -w
# DONE: 1. Add Logger.
# DONE: 2. Add Sender.
# DONE: 3. Add Configurator.
# DONE: 4. Make readable output for functions.
# DONE: 5. Implement input parameter under which will be choosing backup mechanism (releases or logs).
# DONE: 6. Calculate size of folder
# DONE: 7. Building statistics.
# TODO: 8. Implement mechanizm of dumping logs
# TODO: 9. Implement mechanizm for threads (for tracking copying progress). Now 
#			have a problem with load average. Planning to use limited numbers of
#			threads (ex. 50) and move mechanizm of copying to separate module.

############ Work dir ########################
use constant WORKING_DIR => "/home/beast/Projects/KS_Dump_Releases_Logs/";
##############################################
############ Incluided modules ###############
use lib WORKING_DIR."lib/";

use Com::Keysurvey::Configurator;
use Com::Keysurvey::Logger;
use Com::Keysurvey::Sender;
use Com::Keysurvey::CopyAnyFile;
use threads;
use POSIX;

use strict;
##############################################
############ Global variables ################
use constant PATH_TO_CONFIGURATION_FILE => WORKING_DIR."etc/main.conf";
use constant VERSION => "1.0 beta";
my $configuration;
my $logger;
my $sender;
my $MAX_AGE;
my $MAX_LOG_AGE = "20";
my $MAX_RELEASES;
my $ARTIFACTS_HOST;
my $ARTIFACTS_SCHEME;
my $ARTIFACTS_USER;
my $ARTIFACTS_PATH;
my $LOGS_PATH = "/tmp/ksaus/cc.surveysoftwareservices.com/logs/";
my $LOGS_HOST = "localhost";
my $LOGS_SCHEME = "file";
my $LOGS_USER = "";
my $BACKUP_HOST;
my $BACKUP_USER;
my $BACKUP_PATH;
my $BACKUP_SCHEME;
my $TIME_BEGIN;
my $TIME_END;
my $TEST_MODE = 'false';
my @ERRORS = ();
my @STATISTIC = ();
##############################################
############ Auxulary functions ##############
sub onError(@)
{
	my ($type,$message) = @_;
	$message = "" if !$message;
	if($type eq 'Critical')
	{
		print($message ."\n");
		exit 1;
	}
	elsif($type eq 'Warning')
	{
	
	}
	elsif($type eq 'Usage')
	{
		print("\t\t$message\n");
		print("Usage:\n");
		print("\ \ \ \ \ ./ksdrls.pl PARAMETER [test]\n");
		print("where PARAMETER is:\n");
		print("\ \ \ \ \ - release - dump releases\n");
		print("\ \ \ \ \ - log - dump logs\n");
		print("and:\n");
		print("\ \ \ \ \ - test - tests confiruaration and output messages whithout effects (such as copying, removing)\n");
		print("\n");
		exit 1;
	}
}
sub ParseReleases($)
{
	# Synopsis
	# $full_path_to_artifacts - full path to artifacts
	# 		<scheme>://<user>@<host>:/<path>
	# 	for local path will be
	# 		file://user@localhost:/path_to_source
	my($full_path_to_artifacts) = shift;
	my @applications = ();
	my %artifacts;
	($artifacts{'scheme'},$artifacts{'user'},$artifacts{'host'},$artifacts{'path'}) = split(m/\:\/\/|\@|\:/,$full_path_to_artifacts);
	$artifacts{'scheme'} = 'file' if $artifacts{'scheme'} eq "";
	$artifacts{'user'} = 'localuser' if $artifacts{'user'} eq "";
	$artifacts{'host'} = 'localhost' if $artifacts{'host'} eq "";
	
	if($artifacts{'scheme'} eq 'ssh')
	{
	}
	elsif($artifacts{'scheme'} eq 'ftp')
	{
	}
	elsif($artifacts{'scheme'} eq 'http')
	{
	}
	elsif($artifacts{'scheme'} eq 'file')
	{
		chdir($artifacts{'path'});
		opendir(DIR1,".");
		my @dir_contents1 = grep {!/^\.{1,2}$/}readdir(DIR1);
		closedir(DIR1);
		foreach my $dir_content1 (@dir_contents1)
		{
			my @releases = ();
			my $releases_str = "";
			my $releases_count = "";
			my $du = "/usr/bin/du";
			if(-d $dir_content1)
			{
				chdir($dir_content1);
				opendir(DIR2,".");
				my @dir_contents2 = grep {!/^\.{1,2}$/ and not -l}readdir(DIR2);
				closedir(DIR2);
				foreach my $dir_content2 (@dir_contents2)
				{
					my $du_cmd_rel = "$du --max-depth 0 $artifacts{'path'}$dir_content1\/$dir_content2";
					my $size = 0;
					if(`$du_cmd_rel` =~ m/(\d*)\s+./)
					{
						$size = $1;
					}
					push(@releases,"$dir_content2=$size");
				}
				chdir($artifacts{'path'});
			}
			if((scalar @releases) <= 0)
			{
				$releases_str = "";
				$releases_count = 0;
			}
			else
			{
				$releases_str = join("|",sort @releases);
				$releases_count = scalar @releases;
			}
			my $du_cmd_app = "$du --max-depth 0 $artifacts{'path'}$dir_content1";
			my $size = 0;
			if(`$du_cmd_app` =~ m/(\d*)\s+./)
			{
				$size = $1;
			}
			push(@applications,{path=>"$artifacts{'path'}$dir_content1",name=>$dir_content1,count=>"$releases_count",COUNT=>"$releases_count",size=>"$size",releases=>"$releases_str"});
		}
	}
	# Return
	# 	{<path>,<app>,<count_of_releases>,<COUNT_UNCHANGED>,<size_of_all_releases_of_application>,<release1=size|release2=size|...|releaseN=size>}
	return @applications;
}
sub ParseLogs($)
{
	# Synopsis
	# $full_path_to_logs - full path to logs
	# 		<scheme>://<user>@<host>:/<path>
	# 	for local path will be
	# 		file://user@localhost:/path_to_source
	my($full_path_to_logs) = shift;
	my @applications = ();
	my %logs;
	($logs{'scheme'},$logs{'user'},$logs{'host'},$logs{'path'}) = split(m/\:\/\/|\@|\:/,$full_path_to_logs);
	$logs{'scheme'} = 'file' if $logs{'scheme'} eq "";
	$logs{'user'} = 'localuser' if $logs{'user'} eq "";
	$logs{'host'} = 'localhost' if $logs{'host'} eq "";

	if($logs{'scheme'} eq 'ssh')
	{
	}
	elsif($logs{'scheme'} eq 'ftp')
	{
	}
	elsif($logs{'scheme'} eq 'http')
	{
	}
	elsif($logs{'scheme'} eq 'file')
	{
		chdir($logs{'path'});
		opendir(DIR1,".");
		my @dir_contents1 = grep {!/^\.{1,2}$/} readdir(DIR1);
		closedir(DIR1);
		foreach my $dir_content1 (@dir_contents1)
		{
			my @releases = ();
			my $releases_str = "";
			my $releases_count = "";
			my $du = "/usr/bin/du";
			##print("<1>->->->->\t$dir_content1\n");
			if(-d $dir_content1)
			{
				chdir($dir_content1);
				opendir(DIR2,".");
				##my @dir_contents2 = grep {!/^\.{1,2}$/ and not -l and !/\.gz$/}readdir(DIR2);
				my @dir_contents2 = grep {!/^\.{1,2}$/ and !/\.gz$/ and m/^log.*/} readdir(DIR2);
				closedir(DIR2);
				foreach my $dir_content2 (@dir_contents2)
				{
					##print("<2>->->->->\t$dir_content1\/$dir_content2\n");
					my $du_cmd_rel = "$du --max-depth 0 \"$logs{'path'}$dir_content1\/$dir_content2\"";
					my $size = 0;
					if(`$du_cmd_rel` =~ m/(\d*)\s+./)
					{
						$size = $1;
					}
					push(@releases,"$dir_content2=$size");
				}
				chdir($logs{'path'});
			}
			if((scalar @releases) <= 0)
			{
				$releases_str = "";
				$releases_count = 0;
			}
			else
			{
				$releases_str = join("|",sort @releases);
				$releases_count = scalar @releases;
			}
			my $du_cmd_app = "$du --max-depth 0 \"$logs{'path'}$dir_content1\"";
			my $size = 0;
			if(`$du_cmd_app` =~ m/(\d*)\s+./)
			{
				$size = $1;
			}
			push(@applications,{path=>"$logs{'path'}$dir_content1",name=>$dir_content1,count=>"$releases_count",COUNT=>"$releases_count",size=>"$size",releases=>"$releases_str"});
		}
	}
	# Return
	# 	{<path>,<app>,<count_of_logs>,<COUNT_UNCHANGED>,<size_of_all_logs_of_application>,<log1=size|log2=size|...|logN=size>}
	return @applications;
}
sub Remove($)
{
	# Synopsis
	# $full_path_to_source - path to source like:
	#               <scheme>://<user>@<host>:/<path>
	#       will be modified to following dependid on protocol (scheme)
	#               scp://user@source_host:/path_to_source
	#               http://user@source_host/path_to_source
	#               file:///path_to_source
	my($full_path_to_source) = shift;
	my $result = "";
	my %source = ();
	($source{'scheme'},$source{'user'},$source{'host'},$source{'path'}) = split(m/\:\/\/|\@|\:/,$full_path_to_source);
	my $prefix_cmd = "";
	my $mv = "/bin/mv";
	my $rm = "/bin/rm";
	my $ftp = "/usr/bin/ftp";
	my $scp = "/usr/bin/scp";
	# Calculating source
	if(lc($source{'scheme'}) eq 'file')
	{
		$prefix_cmd = "$rm -R -f $source{'path'}";
		`$prefix_cmd`;
		if(not -e $source{'path'})
		{
			$result = "OK(file)";
		}
		else
		{
			$result = "ERROR";
		}
	}
	elsif(lc($source{'scheme'}) eq 'ftp')
	{
		$prefix_cmd = "$ftp ";
		$result = "OK(ftp)";
	}
	elsif(lc($source{'scheme'}) eq 'scp')
	{
		$prefix_cmd = "$scp ";
		$result = "OK(scp)";
	}
	else
	{
		$result .= "Unknown scheme ($source{'scheme'}) for removing source $source{'path'}.";
	}
	# Return
	# 	OK(<scheme>) or Error
	return $result;
}
sub getCurrentDate
{
        my @current_time=localtime(time);               # Array of current time (see in perldoc)
        my $result;
        my $year = ($current_time[5]) + 1900;   # Current year
        my $month_word = ('Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec')[ $current_time[4] ];         # Current month
        my $month_num;
        my $day_of_week_word = ('Sun','Mon','Tue','Wed','Thur','Fri','Sat')[ $current_time[6] ];                # Current day of week
        my $day_of_week_num = $current_time[6];
        my $day;        # Current day
        my $hour;       # Current hour
        my $min;        # Current minut
        my $sec;        # Current second
	# Folloving checking for day, hour, minits and second needed for a correct output of values less then 10 (for example 12:09:08).
	# If one of currents day, hour, minits and second are less then 10, before value will be add a 0 (zero).
	if ($current_time[4] < 10 && $current_time[4] >= 0)
        {
                $month_num = "0". ($current_time[4]+1);
        }
        else
        {
                $month_num = ($current_time[4]+1);
        }
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
        return "$year-$month_num-$day $hour:$min:$sec";
}
##############################################
############ Main function ###################
sub Main(@)
{
	my(@arguments) = @_;
	my $result = "";
	# Error checking
	if(scalar @arguments == 0)
	{
		my $message = "";
		&onError('Usage',)
	}
	unless(-e PATH_TO_CONFIGURATION_FILE)
	{
		my $message = PATH_TO_CONFIGURATION_FILE ." not exist. Check parameter 'PATH_TO_CONFIGURATION_FILE' in this file ". $0;
		&onError('Critical',$message);
		exit 1;
	}
	$TIME_BEGIN = time();
	$configuration = Com::Keysurvey::Configurator->new(PATH_TO_CONFIGURATION_FILE);
	# Check for errors in modules
	if($configuration->isChecked ne "CONFIG::OK")
	{
		my $message = "Error in ". PATH_TO_CONFIGURATION_FILE ." file ". $configuration->getErrorDescription($configuration->isChecked());
		print($message .". \n");
		&onError('Critical',$message);
		exit 1;
	}
	$logger = Com::Keysurvey::Logger->new($configuration->getLoggerFile());
	$logger->setMode($configuration->getLoggerMode);
	$logger->MakeRecord("","-----------------");
	if("LOGGER::OK" ne $logger->isChecked())
	{
		# TODO: make with &onError();
		print("Logger say ". $logger->isChecked() ."\n");
		print("Configuration say ". $configuration->isChecked() ."\n");
		exit 1;
	}
	my $type_of_log = "";
	my $message_to_log = $configuration->getProgrammName() .", version ". VERSION;
	$logger->MakeRecord($type_of_log,$message_to_log);
	print($message_to_log ."\n");
	# Check error in configuration
	$MAX_AGE = $configuration->getMaxAge();
	$MAX_RELEASES = $configuration->getMaxReleases();
	$ARTIFACTS_HOST = $configuration->getArtifactsHost();
	$ARTIFACTS_SCHEME = $configuration->getArtifactsScheme();
	$ARTIFACTS_USER = $configuration->getArtifactsUser();
	$ARTIFACTS_PATH = $configuration->getArtifactsPath();
	$ARTIFACTS_HOST = "localhost" if !$configuration->getArtifactsHost();
	$ARTIFACTS_SCHEME = "file" if !$configuration->getArtifactsScheme();
	$ARTIFACTS_USER = "" if !$configuration->getArtifactsUser();
	$LOGS_SCHEME = $configuration->getLogsScheme();
	$LOGS_SCHEME = "file" if !$configuration->getLogsScheme();
	$LOGS_USER = $configuration->getLogsUser();
	$LOGS_USER = "" if !$configuration->getArtifactsUser();
	$LOGS_HOST = $configuration->getLogsHost();
	$LOGS_PATH = $configuration->getLogsPath();
	$BACKUP_HOST = $configuration->getBackupHost();
	$BACKUP_HOST = "localhost" if !$configuration->getBackupHost();
	$BACKUP_USER = $configuration->getBackupUser();
	if($configuration->getBackupUser() =~ m/^CONF_FILE\:([a-zA-Z1234567890.\/\-\s*\_]*)/)
	{
		$BACKUP_USER = $1;
	}
	elsif($configuration->getBackupUser() )
	{
		$BACKUP_USER = "" if !$configuration->getBackupUser();
	}
	$BACKUP_PATH = $configuration->getBackupPath();
	$BACKUP_SCHEME = $configuration->getBackupScheme();
	$BACKUP_SCHEME = "file" if !$configuration->getBackupScheme();
	if(!$ARTIFACTS_PATH)
	{
		my $message = "Path to artifacts is not set.\n\ \ \ \ FIX: Set value in parameter 'ARTIFACTS_PATH' in config main configuration file.";
		my $type_of_log = "ERROR";
		$logger->MakeRecord($type_of_log,$message);
		&onError('Critical',$message);
	}
	elsif(!$BACKUP_PATH)
	{
		my $message = "Path to backup is not set.\n\ \ \ \ FIX: Set value in parameter 'BACKUP_PATH' in config main configuration file.";
		my $type_of_log = "ERROR";
		$logger->MakeRecord($type_of_log,$message);
		&onError('Critical',$message);
	}
	elsif($ARTIFACTS_PATH eq $BACKUP_PATH and $ARTIFACTS_HOST eq $BACKUP_HOST)
	{
		my $message = "Path to artifacts server and backup server are the same ($ARTIFACTS_HOST:$ARTIFACTS_PATH and $BACKUP_HOST:$BACKUP_PATH).\n\ \ \ \ FIX: Put different path.";
		$logger->MakeRecord("ERROR",$message);
		&onError('Critical',$message);
	}
	elsif($BACKUP_USER ne "" and ($BACKUP_SCHEME eq 'file' or ($BACKUP_SCHEME eq '')))
	{
		my $message = "Wrong scheme $BACKUP_SCHEME for user name (or authentificate file) $BACKUP_USER.\n\ \ \ \ FIX: Put scheme for $BACKUP_HOST.";
		$logger->MakeRecord("ERROR",$message);
		&onError('Critical',$message);
	}
	else
	{
		# Initialize testing mode
		if($arguments[-1] eq 'test')
		{
			$TEST_MODE = 'true';
		}
		foreach my $argument (@arguments)
		{
			if($argument eq 'release')
			{
				# Release
				#*/
				# DEBUG
				# 	full path to source
				# 	full path to destination
				#	what doing now
				#	total count of applications in source
				#/*
				my $message_to_log = "Source\: $ARTIFACTS_SCHEME\:\/\/$ARTIFACTS_USER\@$ARTIFACTS_HOST\:$ARTIFACTS_PATH\n".
					"Destination\: $BACKUP_SCHEME\:\/\/$BACKUP_USER\@$BACKUP_HOST\:$BACKUP_PATH\n".
					"Release moved if age grater than $MAX_AGE day(s)\n".
					"Release moved if application have releases grater than $MAX_RELEASES\n".
					"Calculating count of releases of each application ...";
				$logger->MakeRecord("DEBUG",$message_to_log);
				print($message_to_log) if "DEBUG" eq $configuration->getLoggerMode;
				my @releases = &ParseReleases("$ARTIFACTS_SCHEME\:\/\/$ARTIFACTS_USER\@$ARTIFACTS_HOST\:$ARTIFACTS_PATH");
				$message_to_log = " done.";
				$logger->MakeRecord("DEBUG",$message_to_log);
				print($message_to_log."\n") if "DEBUG" eq $configuration->getLoggerMode;
				$message_to_log = "Total applications in Source is: ".scalar(@releases);
				$logger->MakeRecord("DEBUG",$message_to_log);
				print($message_to_log."\n") if "DEBUG" eq $configuration->getLoggerMode;
				$message_to_log = "Number of applications in $ARTIFACTS_SCHEME\:\/\/$ARTIFACTS_USER\@$ARTIFACTS_HOST\:$ARTIFACTS_PATH is: ".scalar(@releases);
				$logger->MakeRecord("INFO",$message_to_log);
				for(my $i = 0; $i < scalar(@releases); $i++)
				{
					my $message_to_log = "Start the calculating for $releases[$i]{'name'}.";
					$logger->MakeRecord("INFO",$message_to_log);
					#/*
					# Counting releases by aplication
					# DEBUG
					# 	How much releases in apllication
					# 	Total size of appliaction releases
					#/*
					$message_to_log = "In $releases[$i]{'name'}: Total_releases = $releases[$i]{'count'}; Total_size = ".(ceil(($releases[$i]{'size'}/1024)*100)/100)." Mb|";
					$logger->MakeRecord("DEBUG",$message_to_log);
					print($message_to_log."\n") if "DEBUG" eq $configuration->getLoggerMode;
					if($releases[$i]{'count'} < $MAX_RELEASES)
					{
						#/*
						# DEBUG
						# 	Output following print
						#*/
						print("$releases[$i]{'name'} have releases less then $MAX_RELEASES.\n");
						# Fill statistic
						my @releases_ar = split(/\|/, $releases[$i]{'releases'});
						foreach my $release_raw(@releases_ar)
						{
							my ($release,$size) = split(/\=/,$release_raw);
							push(@STATISTIC,{Application=>"$releases[$i]{'name'}",Total_count=>"$releases[$i]{'COUNT'}",Total_size=>"$releases[$i]{'size'}",Release_name=>"$release",Release_size=>"$size",Release_status=>"false"});
						}
					}
					else
					{
						#/*
						# DEBUG
						# 	Output following print
						#*/
						my $message_to_log = "Number of releases in $releases[$i]{'name'}\: $releases[$i]{'count'}";
						$logger->MakeRecord("DEBUG",$message_to_log);
						print("Number of releases in $releases[$i]{'name'}\: $releases[$i]{'count'}\n");
						#/*
						# Calculating age
						#*/
						my @current_date_time = split(/\ /,&getCurrentDate());
						my @current_date = split(/\-/,$current_date_time[0]);
						my @current_time = split(/\:/,$current_date_time[1]);
						my @releases_ar = split(/\|/,$releases[$i]{'releases'});
						my $is_moved = '';
						foreach my $release_raw(@releases_ar)
						{
							my ($release,$size) = split(/\=/,$release_raw);
							my ($r_path,$r_year,$r_mon,$r_day,$r_hour,$r_min,$r_sec) = split(/^(\d{4})(\d{2})(\d{2})(\d{2})(\d{2})(\d{2})$/,$release);
							$r_path = "$releases[$i]{'path'}\/$release";
							my $result_days = 
								($current_date[0] - $r_year)*365 +
								($current_date[1] - $r_mon)*30 +
								($current_date[2] - $r_day);
							# Check for old releases
							if(($result_days > $MAX_AGE) and ($releases[$i]{'count'} > $MAX_RELEASES))
							{
								# Move old release to BACKUP if number releases in app folder greater then $MAX_RELEASES
								#/*
								# DEBUG
								# 	Output following print
								#*/
								my $message_to_log = "Release $release of $releases[$i]{'name'}($size) is $result_days days old.";
								$logger->MakeRecord("DEBUG",$message_to_log);
								print("$message_to_log.\n");
								my $release_del_raw = $release_raw;
								# split to release name and release size
								my ($release_del,$size) = split(/\=/,$release_del_raw);
								$releases[$i]{'count'}--;
								my $copy_file = Com::Keysurvey::CopyAnyFile->new();
								my $copy_result = $copy_file->Copy(
									{scheme=>$ARTIFACTS_SCHEME,user=>$ARTIFACTS_USER,host=>$ARTIFACTS_HOST,path=>"$ARTIFACTS_PATH$releases[$i]{'name'}\/$release_del"},
									{scheme=>$BACKUP_SCHEME,user=>$BACKUP_USER,host=>$BACKUP_HOST,path=>$BACKUP_PATH}
									) if $TEST_MODE ne 'true';
								my $remove_result = "";
								my $type_of_log = "";
								$message_to_log = "";
								if($copy_result eq "OK")
								{
									$remove_result = &Remove("$ARTIFACTS_SCHEME\:\/\/$ARTIFACTS_USER\@$ARTIFACTS_HOST\:$ARTIFACTS_PATH$releases[$i]{'name'}\/$release_del") if $TEST_MODE ne 'true';
									if($remove_result !~ /^OK\(.*\)$/)
									{
										$is_moved = 'warning';
										$type_of_log = "WARN";
									}
									else
									{
										$is_moved = 'true';
										$type_of_log = "DEBUG";
									}
								}
								else
								{
									$is_moved = 'error';
									$type_of_log = "ERROR";
								}
								$message_to_log = "$release_del of $releases[$i]{'name'} has been moved to $BACKUP_PATH with result ". $copy_result ." and removing from temporary is 3 ".$remove_result;
								$logger->MakeRecord($type_of_log,$message_to_log);
								print("\n$message_to_log\n\n");
								# Fill statistic
								push(@STATISTIC,{Application=>"$releases[$i]{'name'}",Total_count=>"$releases[$i]{'COUNT'}",Total_size=>"$releases[$i]{'size'}",Release_name=>"$release_del",Release_size=>"$size",Release_status=>"$is_moved"});
							}
							else
							{
								my $release_del_raw = $release_raw;
								my ($release_del,$size) = split(/\=/,$release_del_raw);
								$is_moved = 'false';
								# Fill statistic
								push(@STATISTIC,{Application=>"$releases[$i]{'name'}",Total_count=>"$releases[$i]{'COUNT'}",Total_size=>"$releases[$i]{'size'}",Release_name=>"$release_del",Release_size=>"$size",Release_status=>"$is_moved"});
							}
						}
					}
				}		
			}
			elsif($argument eq 'log')
			{
				# Log
				#*/
				# DEBUG
				# 	full path to source
				# 	full path to destination
				#	what doing now
				#	total count of applications in source
				#/*
				my $message_to_log = "Source\: $LOGS_SCHEME\:\/\/$LOGS_USER\@$LOGS_HOST\:$LOGS_PATH\n".
					"Destination\: $BACKUP_SCHEME\:\/\/$BACKUP_USER\@$BACKUP_HOST\:$BACKUP_PATH\n".
					"Log moved if age grater than $MAX_AGE day(s)\n".
					"Log moved if application have releases grater than $MAX_RELEASES\n".
					"Calculating count of logs of each application ...";
				$logger->MakeRecord("DEBUG",$message_to_log);
				print($message_to_log);# if "DEBUG" eq $configuration->getLoggerMode;

				my @releases = &ParseLogs("$LOGS_SCHEME\:\/\/$LOGS_USER\@$LOGS_HOST\:$LOGS_PATH");
				#my @releases1 = ();

				$message_to_log = " done.";
				$logger->MakeRecord("DEBUG",$message_to_log);
				print($message_to_log."\n") if "DEBUG" eq $configuration->getLoggerMode;
				##$message_to_log = "Total applications in Source is: ".scalar(@releases);
				##$logger->MakeRecord("DEBUG",$message_to_log);
				##print($message_to_log."\n") if "DEBUG" eq $configuration->getLoggerMode;
				$message_to_log = "Number of applications in $ARTIFACTS_SCHEME\:\/\/$ARTIFACTS_USER\@$ARTIFACTS_HOST\:$ARTIFACTS_PATH is: ".scalar(@releases);
				$logger->MakeRecord("INFO",$message_to_log);
				# Main cycl
				for(my $i = 0; $i < scalar(@releases); $i++)
				{
					#/*
					# Calculating age
					#*/
					my @current_date_time = split(/\ /,&getCurrentDate());
					my @current_date = split(/\-/,$current_date_time[0]);
					my @current_time = split(/\:/,$current_date_time[1]);
					my @releases_ar = split(/\|/,$releases[$i]{'releases'});
					my $is_moved = '';
					foreach my $release_raw(@releases_ar)
					{
						my ($release,$size) = split(/\=/,$release_raw);
						my ($r_path,$r_year,$r_mon,$r_day,$r_hour,$r_min,$r_sec) = split(/^log(\d{4})(\d{2})(\d{2})(\d{2})(\d{2})(\d{2}).*\.xml$/,$release);
						##my ($r_path,$r_year,$r_mon,$r_day,$r_hour,$r_min,$r_sec) = ("0","0","0","0","0","0","0");
						##print("\t\t$release\n");
						$r_path = "$releases[$i]{'path'}\/$release";
						my $result_days = 
							($current_date[0] - $r_year)*365 +
							($current_date[1] - $r_mon)*30 +
							($current_date[2] - $r_day);
						# Check for old releases
						if($result_days > $MAX_LOG_AGE)
						{
							# Move old release to BACKUP if number releases in app folder greater then $MAX_RELEASES
							#/*
							# DEBUG
							# 	Output following print
							#*/
							my $message_to_log = "Log $release of $releases[$i]{'name'}($size) is $result_days days old.";
							$logger->MakeRecord("DEBUG",$message_to_log);
							print("$message_to_log.\n");
							my $release_del_raw = $release_raw;
							# split to release name and release size
							my ($release_del,$size) = split(/\=/,$release_del_raw);
							$releases[$i]{'count'}--;
							my $gzip_result = "OK"; # TODO: Make this.
							my $remove_result = "";
							my $type_of_log = "";
							$message_to_log = "";
							if($gzip_result eq "OK")
							{
								$remove_result = "OK(bla)";
								$remove_result = "4545";
								if($remove_result !~ /^OK\(.*\)$/)
								{
									$is_moved = 'warning';
									$type_of_log = "WARN";
								}
								else
								{
									$is_moved = 'true';
									$type_of_log = "DEBUG";
								}
							}
							else
							{
								$is_moved = 'error';
								$type_of_log = "ERROR";
								
							}
							$message_to_log = "$release_del of $releases[$i]{'name'} has been moved to $BACKUP_PATH with result ". $gzip_result ." and removing from temporary is ".$remove_result;
							$logger->MakeRecord($type_of_log,$message_to_log);
							print("\n$message_to_log\n\n");
							# Fill statistic
							push(@STATISTIC,{Application=>"$releases[$i]{'name'}",Total_count=>"$releases[$i]{'COUNT'}",Total_size=>"$releases[$i]{'size'}",Release_name=>"$release_del",Release_size=>"$size",Release_status=>"$is_moved"});
						}
						else
						{
							my $release_del_raw = $release_raw;
							my ($release_del,$size) = split(/\=/,$release_del_raw);
							$is_moved = 'false';
							# Fill statistic
							push(@STATISTIC,{Application=>"$releases[$i]{'name'}",Total_count=>"$releases[$i]{'COUNT'}",Total_size=>"$releases[$i]{'size'}",Release_name=>"$release_del",Release_size=>"$size",Release_status=>"$is_moved"});
						}
					}
				}
			}
			elsif($argument eq 'test')
			{
			}
			else
			{
				my $message = "";
				&onError('Usage',$message);
			}
		}
	}
	# Creation of statistic
	my @STATISTICS = sort {"$a->{Application}$a->{Release_name}" cmp "$b->{Application}$b->{Release_name}" } @STATISTIC;
	my @rows_to_send = ();
	foreach (@STATISTICS)
	{
		my %hash = %$_;
		my $row_color = "";
		if($hash{'Release_status'} eq 'true')
		{
			$row_color = " bgcolor='#66ff66'";
		}
		elsif($hash{'Release_status'} eq 'false')
		{
			$row_color = "";
		}
		elsif($hash{'Release_status'} eq 'error')
		{
			$row_color = " bgcolor='#ff6666'";
		}
		elsif($hash{'Release_status'} eq 'warning')
		{
			$row_color = " bgcolor='#ffff66'";
		}
		my $string = "<TR$row_color><TD>$hash{'Application'}</TD><TD>$hash{'Total_count'}</TD><TD>".(ceil(($hash{'Total_size'}/1024)*100)/100)."</TD><TD>$hash{'Release_name'}</TD><TD>".(ceil(($hash{'Release_size'}/1024)*100)/100);#."</TD><TD>$hash{'Release_status'}</TD></TR>";
		push(@rows_to_send,$string)
	}
	# Send statistic
	$sender = Com::Keysurvey::Sender->new($configuration->getOperatorMails());
	$sender->setSMTPServer($configuration->getSenderSMTPServer);
        # Count time of working
	$TIME_END = time();
	my $time_total = $TIME_END - $TIME_BEGIN;
	# Load average
	my $load_average = `uptime`;
	$load_average =~s/.*load average(.*)$/$1/;
	if($sender->isChecked() ne "SENDER::OK")
	{
		print("Can not send mail. Sender say ".$sender->getErrorDescription($sender->isChecked())."\n");
	}
	my $message_to_sender = "
<!DOCTYPE html PUBLIC '-//W3C//DTD XHTML 1.0 Transitional//EN' 'http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd'>
<HTML xmlns='http://www.w3.org/1999/xhtml''>
<TITLE>Statistics form KSDRLS utility.</TITLE>
<HEAD></HEAD>
<BODY>
<P><H3>In <B><A HREF='"."$ARTIFACTS_SCHEME\:\/\/$ARTIFACTS_USER\@$ARTIFACTS_HOST\:$ARTIFACTS_PATH"."'>"."$ARTIFACTS_SCHEME\:\/\/$ARTIFACTS_USER\@$ARTIFACTS_HOST\:$ARTIFACTS_PATH"."</A>
</B></H3>
</P>
<TABLE frame='border'>
<THEAD>
<TR><TD>Legend</TD></TR>
</THEAD>
<TR><TD bgcolor='#ff6666'>Can't copy files</TD><TD bgcolor='#ffff66'>Can't remove files</TD><TD bgcolor='#66ff66'>Move files ok</TD><TD bgcolor=''>Leave files</TD></TR>
</TABLE>
<BR>
<TABLE width = '100%' frame='border' rules='rows'>
<TR bgcolor='#cccccc'><TD>Application</TD><TD>Count Releases</TD><TD>Application size (Mb)</TD><TD>Release name</TD><TD>Relese size (Mb)</TD></TR>\n
";
	$message_to_sender .= join("\n",@rows_to_send,);
	$message_to_sender .= "<TR><TD>Nothing to send</TD></TR>\n" if scalar @rows_to_send == 0;
	$message_to_sender .= "\n</TABLE>\n";
	$message_to_sender .= "<P><TABLE>";
	$message_to_sender .= "<TR><TD><B>Time:</B> $time_total</TD></TR>";
	$message_to_sender .= "<TR><TD><B>Load average:</B> $load_average</TD></TR>";
	$message_to_sender .= "</TABLE></P>";
	$message_to_sender .= "<P><B>For more information see utility log.</B></P></BODY></HTML>";
	$sender->SendNotification($message_to_sender);
	$message_to_log = "Compleated during $time_total second(s). Load average $load_average";
	$logger->MakeRecord("",$message_to_log);
	print($message_to_log ."\n");
	# Return
	# 	
	return $result;
}
############# Launch #########################
&Main(@ARGV);
##############################################
