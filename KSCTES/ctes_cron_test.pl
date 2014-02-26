#!/usr/bin/perl -w

#######################################################################################################
use constant WORKING_DIRECTORY => "/path_to_ksctes/";				# Path to current working directory
########################################## Using modules ##############################################
use lib WORKING_DIRECTORY."lib";

use strict;
# Module of configuration reading and initializing
use Com::Keysurvey::Configuration;
# Module for intecoursing with database (mysql)
use Com::Keysurvey::DBUse;
# Module for log all need information anout program working
use Com::Keysurvey::Logger;
# Module for sending a reports about working process of program and all modules
use Com::Keysurvey::Sender;
# Module for parsing records from whois servers (for detailed see ./lib/Com/Keysurvey/Whois.pm)
use Com::Keysurvey::Whois;
# Module for parsing SSL Certificates
use Com::Keysurvey::SSL;
########################################### Variables #################################################
use constant PATH_TO_CONFIGURATION_FILE => WORKING_DIRECTORY ."etc/main_test.conf";		# Default path to configuration file 
use constant NOTIFY_LIMIT => 30;														# Limit of notify for domain date expires

my $database;				# link for object DBUse
my $configuration; 			# link for object Configuration
my $sender;					# link for object Sender
my $logger;					# link for object Logger
my $message_to_log;			# message to log output
my $type_of_log = "";		# type of output message
my @domain_to_submit = ();	# Domain for submit to recipients 
my $notify_limit;			# module variable
my $time_begin;				# time beginning of work program, need for report
my $time_end;				# ending time of wokr program, need for report
my $total_time;
my $load_average;
############################################ Check Domain #############################################
sub CheckDomain()
{
	### Check domin expire date by the way interrogation of database
	my @domains = $database->getDomainExpire();
	$message_to_log = "Parse each row from tadabase to domain name, domain date, domain time.";
	$logger->MakeRecord("DEBUG",$message_to_log);
	print("$message_to_log;\n") if $configuration->getLoggerMode eq "DEBUG";
	foreach my $domain (@domains)
	{
		# split $domain in view 
		# 	DomainName YYYY-MM-DD HH:MM:SS
		# by delimeter SPACE to array
		my @row = split (/ /, $domain);
		my $domain_name = $row[0];
		my @domain_date = split (/-/, $row[1]);
		my @domain_time = split (/:/, $row[2]);
		my @current_date_time = split (/ /, &getCurrentDate());
		my @current_date = split (/-/, $current_date_time[0]);
		my @current_time = split (/:/, $current_date_time[1]);
		$message_to_log = "\tFor $domain_name";
		$logger->MakeRecord("DEBUG",$message_to_log);
		print("$message_to_log\n") if "DEBUG" eq $configuration->getLoggerMode;
		
		# count days till expiration date for domain
		my $result_days = 
					($domain_date[0] - $current_date[0])*365 +
					($domain_date[1] - $current_date[1])*30 +
					($domain_date[2] - $current_date[2]);
		$type_of_log = "DEBUG";
		$message_to_log = "\tCount days to expire registration date of $domain_name is $result_days and will be expired in $row[1].";
		$logger->MakeRecord("DEBUG",$message_to_log);
		print("$message_to_log\n") if "DEBUG" eq $configuration->getLoggerMode;
		
		# check days till expiration date for domain
		if ($result_days <= $notify_limit and $result_days > 0)
		{
			$message_to_log = "Expiration date for $domain_name will be expire about $result_days day(s).";
			$logger->MakeRecord("WARN",$message_to_log);
			print("$message_to_log\n");
			# prepare data about domain to sending 
			push (@domain_to_submit, {type=>'Domain',domain=>"$domain_name",status=>'warn',e_date=>"$row[1] $row[2]",days=>"$result_days"});
		}
		elsif($result_days < 0)
		{
			$message_to_log = "Expiration date for $domain_name is not set. Check manualy by whois(1)";
			$logger->MakeRecord("ERROR",$message_to_log);
			print("$message_to_log\n");
			# prepare data about domain to sending 
			push (@domain_to_submit, {type=>'Domain',domain=>"$domain_name",status=>'error',e_date=>"$row[1] $row[2]",days=>"$result_days"});
		}
		else
		{
			$message_to_log = "Domain $domain_name has checked.";
			$logger->MakeRecord("INFO",$message_to_log);
			print("$message_to_log\n");
			push (@domain_to_submit, {type=>'Domain',domain=>"$domain_name",status=>'ok',e_date=>"$row[1] $row[2]",days=>"$result_days"});
		}
	}
}
############################################ Check Database ###########################################
sub CheckDatabase()
{
	### Check data in database by the way of comparesion with whois records. 
	# NOTNEED: Let update records in DB only if it need (whois priority)
	my @domains = $database->getDomains();
	foreach my $domain (@domains)
	{
		my @record = ();
		my $whois = Com::Keysurvey::Whois->new();
		$whois->ParseWhois($domain);
		my $comp_result = "0";
	
		#**********************************
		#* Check by string of validity data
		#* GET string from database in view:
		#*	DomainName|DateCreate|DateUpdate|DateExpire
		#* GET string from whois server in view:
		#*	DomainName|DateCreate|DateUpdate|DateExpire
		#* Compare data between them, if in DB found line with "n/a"
		#* or something else (not date) and data in the same column 
		#* of whois answer not equivalent "n/a", insert into column 
		#* of DB valid data
		#**********************************
		
		# get one domain record form database
		my @row = $database->getRecordOnDomain($domain);
		foreach my $row (@row)
		{
			my @cols = split(/\*/, $row);
			my $domain_name = $cols[0];
			my $isSSL = 'false';
			my $c_date = $cols[1];
			my $u_date = $cols[2];
			my $e_date = $cols[3];
			my $adm_contact = $cols[4];
			my $tech_contact = $cols[5];
			my $reg_contact = $cols[6];
			my $ns = $cols[7];
			my $db_domain_name = $whois->getDomainName();
			my $db_c_date = $c_date;
			my $db_u_date = $u_date;
			my $db_e_date = $e_date;
			my $whois_c_date = $whois->getDataCreate();
			$whois_c_date = "n/a" if !$whois->getDataCreate();
			my $whois_u_date = $whois->getDataUpdate();
			$whois_u_date = "n/a" if !$whois->getDataUpdate();
			my $whois_e_date = $whois->getDataExpire();
			$whois_e_date = "n/a" if !$whois->getDataExpire();
			my $db_c_date_status;
			my $db_u_date_status;
			my $db_e_date_status;
			my $db_status = 'ok';
			if("n/a" ne $whois_c_date)
			{
				$db_c_date = $whois_c_date;
				$db_c_date_status = "ok";
				$message_to_log = "Insert date ". $whois_c_date ." as CREATION DATE for domain ". $db_domain_name .".";
				$logger->MakeRecord("DEBUG",$message_to_log);
				print("$message_to_log\n") if "DEBUG" eq $configuration->getLoggerMode;
			}
			else
			{
				$db_c_date_status = "warn";
				$message_to_log = "Can not insert ". $whois_c_date ." for ". $db_domain_name .", because date unset. Using old date (c_date) $c_date.";
				$logger->MakeRecord("WARN",$message_to_log);
				print("$message_to_log\n");
			}
			if("n/a" ne $whois_u_date)
			{
				$db_u_date = $whois_u_date;
				$db_u_date_status = "ok";
				$message_to_log = "Insert date ". $whois_u_date ." as UPDATION DATE for domain ". $db_domain_name .".";
				$logger->MakeRecord("DEBUG",$message_to_log);
				print("$message_to_log\n") if "DEBUG" eq $configuration->getLoggerMode;
			}
			else
			{
				$db_u_date_status = "warn";
				$message_to_log = "Can not insert ". $whois_u_date ." for ". $db_domain_name .", because date unset. Using old date (u_date) $u_date.";
				$logger->MakeRecord("WARN",$message_to_log);
				print("$message_to_log\n");
			}
			if("n/a" ne $whois_e_date)
			{
				my @date_time_whois = split /\ /,$whois_e_date;
				my @date_whois = split /\-/,$date_time_whois[0];
				my @date_time_db = split /\ /,$e_date;
				my @date_db = split /\-/,$date_time_db[0];
				my $result_days = 
						($date_whois[0] - $date_db[0])*365 +
						($date_whois[1] - $date_db[1])*30 +
						($date_whois[2] - $date_db[2]);
				$comp_result = $result_days;
				if($comp_result > 0)
				{
					$db_e_date = $whois_e_date;
					$db_e_date_status = "ok";
					$message_to_log = "Insert date ". $whois_e_date ." as EXPIRATION DATE for domain ". $db_domain_name .".";
					$logger->MakeRecord("DEBUG",$message_to_log);
					print("$message_to_log\n") if "DEBUG" eq $configuration->getLoggerMode;
				}
				else
				{
					$db_e_date_status = "warn";
	                $message_to_log = "Can not insert ". $whois_e_date ." for ". $db_domain_name .", because date unset. Using old date (e_date) $e_date.";
        	        $logger->MakeRecord("WARN",$message_to_log);
                    print("$message_to_log\n");
				}
			}
			else
			{
				$db_e_date_status = "warn";
				$message_to_log = "Can not insert ". $whois_e_date ." for ". $db_domain_name .", because date unset. Using old date (e_date) $e_date.";
				$logger->MakeRecord("WARN",$message_to_log);
				print("$message_to_log\n");
			}
			# Another parameters for checking
			# Put here for check using statement if...else
			
			$message_to_log = "Update in table domains values |$domain_name|$db_c_date|$db_u_date|$db_e_date|";
			$logger->MakeRecord("DEBUG",$message_to_log);
			print("$message_to_log\n")  if "DEBUG" eq $configuration->getLoggerMode;
			print($database->UpdateRecord("$domain_name","$isSSL","$db_c_date","$db_u_date","$db_e_date") ."\n");
			$db_status = 'ok' if ($db_c_date_status or $db_u_date_status or $db_e_date_status) eq 'ok';
			$db_status = 'warn' if ($db_c_date_status or $db_u_date_status or $db_e_date_status) eq 'warn';
			$db_status = 'error' if ($db_c_date_status or $db_u_date_status or $db_e_date_status) eq 'error';
			push (@domain_to_submit, {type=>'Database',domain=>"$domain_name",status=>"$db_status",c_date=>"$db_c_date",u_date=>"$db_u_date",e_date=>"$db_e_date"});
		}
	}
	my @ssldomains = $database->getSSLDomains();
	foreach my $ssldomain_name(@ssldomains)
	{
		my $ssl = Com::Keysurvey::SSL->new($ssldomain_name ,'');
		my $ssldomain_c = $ssl->getDateCreate();
		$ssldomain_c = '0000-00-00 00:00:00' if !$ssldomain_c;
		my $ssldomain_u = $ssl->getDateCreate();
		$ssldomain_u = '0000-00-00 00:00:00' if !$ssldomain_u;
		my $ssldomain_e = $ssl->getDateExpire();
		$ssldomain_e = '0000-00-00 00:00:00' if !$ssldomain_e;		
		my @row = $database->getRecordOnDomain($ssldomain_name);
		foreach my $row (@row)
		{
			my @cols = split(/\*/, $row);
			my $ssldomain_name = $cols[0];
			my $isSSL = 'true';
			my $ssldomaindate_c = $cols[1];
			my $ssldomaindate_u = $cols[2];
			my $ssldomaindate_e = $cols[3];
			my $ssldomain_adm_contact = $cols[4];
			my $ssldomain_tech_contact = $cols[5];
			my $ssldomain_reg_contact = $cols[6];
			my $ssldomain_ns = $cols[7];
			my $ssldomaindate_c_status = "ok";
			my $ssldomaindate_u_status = "ok";
			my $ssldomaindate_e_status = "ok";
			my $ssldomain_status = "ok";

			if(($ssldomaindate_c eq $ssldomain_c) and ("0000-00-00 00:00:00" ne $ssldomaindate_c))
			{
				$ssldomaindate_c_status = "ok";
			}
			elsif("0000-00-00 00:00:00" eq $ssldomaindate_c)
			{
				$ssldomaindate_c = $ssl->getDateCreate();
				$ssldomaindate_c_status = "error";
			}
			else
			{
				$ssldomaindate_c = $ssl->getDateCreate();
				$ssldomaindate_c_status = "warn";
			}
			if($ssldomaindate_u eq $ssldomain_u)
			{
				$ssldomaindate_u_status = "ok";
			}
			elsif("0000-00-00 00:00:00" eq $ssldomaindate_u)
			{
				$ssldomaindate_u = $ssl->getDateCreate();
				$ssldomaindate_u_status = "error";
			}
			else
			{
				$ssldomaindate_u_status = "warn";
				$ssldomaindate_u = $ssl->getDateCreate();
			}
			if($ssldomaindate_e eq $ssldomain_e)
			{
				$ssldomaindate_e_status = "ok";
			}
			elsif("0000-00-00 00:00:00" eq $ssldomaindate_e)
			{
				$ssldomaindate_e = $ssl->getDateExpire();
				$ssldomaindate_e_status = "error";
			}
			else
			{
				$ssldomaindate_e = $ssl->getDateExpire();
				$ssldomaindate_e_status = "warn";
			}
			if("SSL::OK" ne $ssl->isChecked)
			{
				$message_to_log = $ssl->getErrorDescription($ssl->isChecked);
				$logger->MakeRecord("WARN",$message_to_log);
				print($message_to_log ."\n");
				$ssldomain_status = $ssl->getErrorDescription($ssl->isChecked);
			}
			print($database->UpdateRecord("$ssldomain_name","$isSSL","$ssldomaindate_c","$ssldomaindate_u","$ssldomaindate_e") ."\n");
			$ssldomain_status = 'ok' if ($ssldomaindate_c_status or $ssldomaindate_u_status or $ssldomaindate_e_status) eq 'ok';
			$ssldomain_status = 'warn' if ($ssldomaindate_c_status or $ssldomaindate_u_status or $ssldomaindate_e_status) eq 'warn';
			$ssldomain_status = 'error' if ($ssldomaindate_c_status or $ssldomaindate_u_status or $ssldomaindate_e_status) eq 'error';
            push (@domain_to_submit, {type=>'Database',domain=>"$ssldomain_name",status=>"$ssldomain_status",c_date=>"$ssldomaindate_c",u_date=>"$ssldomaindate_u",e_date=>"$ssldomaindate_e"});
		}
	}
}
############################################ Add Domains to Database ##################################
sub AddDomains(@)
{
	### Add domains to database
	############################
	my @commandline_params = @_;
	foreach my $new_domain(@commandline_params)
	{
		my $id = ($database->getTotalRecords()) + 1;
		my $domain_name = $new_domain;
		my $isSSL = "false";
		my $c_date = "0";
		my $u_date = "0";
		my $e_date = "0";
		my $admin_contact = "0";
		my $tech_contact = "0";
		my $registrant_contact = "0";
		my $ns = "0";
		my @record = ($id,$domain_name, $isSSL, $c_date, $u_date, $e_date, 
		$admin_contact, $tech_contact, $registrant_contact, $ns);
		my $result = $database->getErrorDescription($database->AddRecord(@record));
		$message_to_log = "Add domain $new_domain with status $result";
		$logger->MakeRecord("INFO",$message_to_log);
		push (@domain_to_submit, {type=>'Add',domain=>"$new_domain",status=>"$result"});
	}
}
############################################ Add domains to Database for SSL checking #################
sub AddSSLDomains(@)
{
	### Add domains to database
	############################
	my @commandline_params = @_;
	foreach my $new_domain(@commandline_params)
	{
		my $id = ($database->getTotalRecords()) + 1;
		my $domain_name = $new_domain;
		my $isSSL = "true";
		my $c_date = "0";
		my $u_date = "0";
		my $e_date = "0";
		my $admin_contact = "0";
		my $tech_contact = "0";
		my $registrant_contact = "0";
		my $ns = "0";
		my @record = ($id,$domain_name, $isSSL, $c_date, $u_date, $e_date, 
		$admin_contact, $tech_contact, $registrant_contact, $ns);
		my $result = $database->getErrorDescription($database->AddRecord(@record));
		$message_to_log = "Add domain $new_domain with status $result";
		$logger->MakeRecord("INFO",$message_to_log);
		push (@domain_to_submit, {type=>'Add',domain=>"$new_domain",status=>"$result"});
	}
}
############################################ Checking a SSL Certificate ###############################
sub CheckSSL
{
	### Check SSL Certificate expire date by the way interrogation of database
	my @domains = $database->getSSLDomainExpire();		# in format DOMAIN_NAME DOMAIN_EXPIRE
	$message_to_log = "Parse each row from tadabase to domain name, domain date, domain time.";
	$logger->MakeRecord("DEBUG",$message_to_log);
	print("$message_to_log\n") if "DEBUG" eq $configuration->getLoggerMode;
	foreach my $ssldomain_name (@domains)
	{
		my @row = split (/ /, $ssldomain_name);
		my $domain_name = $row[0];
		my $domain_date_time = $row[1] ." ". $row[2];
		my @domain_date = split (/-/, $row[1]);
		my @domain_time = split (/:/, $row[2]);
		my @current_date_time = split (/ /, &getCurrentDate());
		my @current_date = split (/-/, $current_date_time[0]);
		my @current_time = split (/:/, $current_date_time[1]);
		my $result_days = 
				($domain_date[0] - $current_date[0])*365 +
				($domain_date[1] - $current_date[1])*30 +
				($domain_date[2] - $current_date[2]);
		
		if ($result_days <= $notify_limit and $result_days > 0)
		{
			$message_to_log = "Expiration date SSL Certificate for $domain_name will be expire about $result_days day(s).";
			$logger->MakeRecord("WARN",$message_to_log);
			print("$message_to_log\n");
			# prepare data about domain to sending 
			push (@domain_to_submit, {type=>'SSL',domain=>"$domain_name",status=>'warn',e_date=>"$domain_date_time",days=>"$result_days"});
		}
		elsif($result_days < 0)
		{
			$message_to_log = "Expiration date of SSL Certificate for $domain_name is not set. Check manualy by openssl(1)";
			$logger->MakeRecord("ERROR",$message_to_log);
			print("$message_to_log\n");
			# prepare data about domain to sending 
			push (@domain_to_submit, {type=>'SSL',domain=>"$domain_name",status=>'error',e_date=>"$domain_date_time",days=>"$result_days"});
		}
		else
		{
			$message_to_log = "SSL Certificate for $domain_name has checked.";
			$logger->MakeRecord("INFO",$message_to_log);
			print("$message_to_log\n");
			push (@domain_to_submit, {type=>'SSL',domain=>"$domain_name",status=>'ok',e_date=>"$domain_date_time",days=>"$result_days"});
		}
	}
}	
############################################ Create database tables ###################################
sub CreateTables
{
	$message_to_log = "Now start to create following tables in database ". $configuration->getDatabaseName .".";
	$logger->MakeRecord($type_of_log,$message_to_log);
	print("$message_to_log"."\n") if "DEBUG" eq $configuration->getLoggerMode;
	my @result = $database->CreateTables();
	$message_to_log = "Result:\n\t". join("\n\t", @result);
	$logger->MakeRecord("INFO",$message_to_log);
	push (@domain_to_submit, {type=>'Create',status=>(join("*", @result))});
}
############################################ Remove domains ###########################################
sub RemoveDomains(@)
{
	### Remove domains from database
    ############################
	my @commandline_params = @_;
	foreach my $exist_domain(@commandline_params)
	{
		$message_to_log = "Now removing record in table for ". $exist_domain .".";
		$logger->MakeRecord("DEBUG",$message_to_log);
		print("$message_to_log"."\n") if "DEBUG" eq $configuration->getLoggerMode();
		my $result = $database->getErrorDescription($database->RemoveRecord($exist_domain));
		$message_to_log = "Remove record for $exist_domain with status $result";
		$logger->MakeRecord("INFO",$message_to_log);
		push (@domain_to_submit, {type=>'Remove',domain=>"$exist_domain",status=>"$result"});
	}
}
############################################ Insert informations ######################################
sub InsertInfo(@)
{
	my($domain_name,$isSSL,$create_date,$update_date,$expire_date,$admin_contact,$tech_contact,$registrant_contact,$nameservers) = split(/\,/,join("",@_));
	my $result = "";
	
	$admin_contact = "" if !$admin_contact;
	$tech_contact = "" if !$tech_contact;
	$registrant_contact = "" if !$registrant_contact;
	$nameservers = "" if !$nameservers;
	$message_to_log = "Update record of values |$domain_name|$isSSL|$create_date|$update_date|$expire_date|$admin_contact|$tech_contact|$registrant_contact|$nameservers|";
	$logger->MakeRecord("DEBUG",$message_to_log);
	print("$message_to_log\n") if "DEBUG" eq $configuration->getLoggerMode();
	###
	# Check domain
	###
	my @res = $database->getRecordOnDomain($domain_name);
	if((scalar @res) > 0)
	{
		my($d_name,$c_date,$u_date,$e_date,$adm_contact,$tech_old_contact,$reg_contact,$ns) = split(/\*/,join("",@res));
		$adm_contact = "" if !$adm_contact;
		$tech_old_contact = "" if !$tech_old_contact;
		$reg_contact = "" if !$reg_contact;
		$ns = "" if !$ns;
		
		my $id = ($database->getTotalRecords()) + 1;
		
		$result = $database->UpdateRecord("$domain_name","$isSSL","$create_date","$update_date","$expire_date","$admin_contact","$tech_contact","$registrant_contact","$nameservers");
	}
	else
	{
		$result = "ERROR";
	}

	push (@domain_to_submit, {type=>'Insert',domain=>"$domain_name",isSSL=>"$isSSL",status=>"$result",
		c_date=>"$create_date",u_date=>"$update_date",e_date=>"$expire_date",
		admin=>"$admin_contact",tech=>"$tech_contact", reg=>"$registrant_contact",ns=>"$nameservers"});

	#print("$result\n");
	return $result; 
}
############################################ Auxulary functions #######################################
sub getCurrentDate()
{
	my @current_time=localtime(time);		# Array of current time (see in perldoc)
	my $result;
	
	my $year = ($current_time[5]) + 1900;	# Current year
	my $month_word = ('Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec')[ $current_time[4] ];		# Current month
	my $month_num;
	my $day_of_week_word = ('Sun','Mon','Tue','Wed','Thur','Fri','Sat')[ $current_time[6] ];		# Current day of week
	my $day_of_week_num = $current_time[6];
	my $day;	# Current day
	my $hour;	# Current hour
	my $min;	# Current minut
	my $sec;	# Current second
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
sub PrintUsage()
{
	print("Usage: adddomains <list of domains>|addssldomains <list of domains>|all|createtables|domain|database|help|insert <record>|removedomains|ssl.\n");
}
sub PrintHelp()
{
	print("\n");
	print("Checks to how much time remains to expiration date of domain name and SSL 
	certificate of gomain name.\n");
	print("\n");
	&PrintUsage();
	print("\n");
	print("Description of available parameters:\n");
	print("\t- adddomains <list of domains> - add domain names to database for checking exipation date.\n");
	print("\t\t <list of domains> - list of domain names (without prefix 'http://www.' or 'http://' or 'www.') delimits by ' ' (space).\n");
	print("\t- addssldomains <list of domains> - add domain names to database for checking expiration date of SSL certificate.\n");
	print("\t\t <list of domains> - list of domain names (without prefix 'http://www.' or 'http://' or 'www.') delimits by ' ' (space).\n");
	print("\t- all - allow checking for expiration date of domian name and SSL certificate.\n");
	print("\t- createtables - create empty tables in database given in main configuration file.\n");
	print("\t\tWARNING! If tables exists in database they are be deleted and making now.\n");
	print("\t- domain - check domain names for expiration date.\n");
	print("\t- database - validate database records by whois.\n");
	print("\t- help - print current help.\n");
	print("\t- insert <record> - insert row into table domains, delimits by , (comma):\n");
	print("\t\t <record> - domain_name,isSSL,date_create,date_update,date_expire,contact_admin,contact_tech,contact_registrant,nameservers\n");
	print("\t- removedomains <list of domains> - remove one or several domains from database table `domains`.\n");
	print("\t\t <list of domains> - list of domain names in database for removing, delimits by ' ' (space).\n");
	print("\t- ssl - check SSL certificates for expiration date.\n");
	print("\n");
	print("For correct utility working following modules must be used:\n");
	print("\t- Net::SSL - support for Secure Sockets Layer.\n");
	print("\t- Crypt::SSLeay - OpenSSL support for LWP by 2006-2007 David Landgren, 1999-2003 Joshua Chamas, 1998 Gisle Aas.\n");
	print("\t" .'- Net::SMTP - Simple Mail Transfer Protocol Client by Graham Barr <gbarr@pobox.com>'. "\n");
	print("\n");

	return 0;
}
sub Statistic(@)
{
	my @to_submit = @_;

	my $domain_list = ""; 		#<TR><TD>Domain</TD><TD>Status</TD></TR>";
	my $database_list = "";		#<TR><TD>Domain</TD><TD>Create date</TD><TD>Update date</TD><TD>Expire date</TD></TR>";
	my $ssl_list = "";			#<TR><TD>Domain</TD><TD>Create</TD><TD>Expire</TD></TR>";
	my $create_list = "";		#<TR><TD>Table</TD><TD>Status</TD></TR>;
	my $remove_list = "";		#<TR><TD>Domain</TD><TD>Status</TD></TR>;
	my $add_list = "";			#<TR><TD>Domain</TD><TD>Status</TD></TR>;
	my $insert_list = "";		#<TR><TD>Record</TD><TD>Status</TD></TR>;
	for(my $i = 0; $i < scalar(@to_submit); $i++)
	{
		my $type = $to_submit[$i]{'type'};
		my $domain_name = $to_submit[$i]{'domain'};
		my $domain_status = $to_submit[$i]{'status'};
		my $isSSL = $to_submit[$i]{'isSSL'};
		my $c_date = $to_submit[$i]{'c_date'};
		my $u_date = $to_submit[$i]{'u_date'};
		my $e_date = $to_submit[$i]{'e_date'};
		my $admin = $to_submit[$i]{'admin'};
		my $tech = $to_submit[$i]{'tech'};
		my $reg = $to_submit[$i]{'reg'};
		my $ns = $to_submit[$i]{'ns'};
		my $days = $to_submit[$i]{'days'};
				
		if($type eq 'Domain')
		{
			if($domain_status eq 'ok')
			{
				$domain_list .= "<TR><TD>$domain_name</TD><TD>$e_date</TD><TD>$days</TD></TR>\n";
			}
			elsif($domain_status eq 'warn')
			{
				$domain_list .= "<TR bgcolor='#ffff66'><TD>$domain_name</TD><TD>$e_date</TD><TD>$days</TD></TR>\n";
			}
			elsif($domain_status eq 'error')
			{
				$domain_list .= "<TR bgcolor='#ff6666'><TD>$domain_name</TD><TD>$e_date</TD><TD>$days</TD></TR>\n";
			}
		}
		elsif($type eq 'Database')
		{
			if($domain_status eq 'ok')
			{
				$database_list .= "<TR><TD>$domain_name</TD><TD>$c_date</TD><TD>$u_date</TD><TD>$e_date</TD></TR>\n";
			}
			elsif($domain_status eq 'warn')
			{
				$database_list .= "<TR bgcolor='#ffff66'><TD>$domain_name</TD><TD>$c_date</TD><TD>$u_date</TD><TD>$e_date</TD></TR>\n";
			}
			elsif($domain_status eq 'error')
			{
				$database_list .= "<TR bgcolor='#ff6666'><TD>$domain_name</TD><TD>$c_date</TD><TD>$u_date</TD><TD>$e_date</TD></TR>\n";
			}
		}
		elsif($type eq 'SSL')
		{
			if($domain_status eq 'ok')
			{
				$ssl_list .= "<TR><TD>$domain_name</TD><TD>$e_date</TD><TD>$days</TD></TR>\n";
			}
			elsif($domain_status eq 'warn')
			{
				$ssl_list .= "<TR bgcolor='#ffff66'><TD>$domain_name</TD><TD>$e_date</TD><TD>$days</TD></TR>\n";
			}
			elsif($domain_status eq 'error')
			{
				$ssl_list .= "<TR bgcolor='#ff6666'><TD>$domain_name</TD><TD>$e_date</TD><TD>$days</TD></TR>\n";
			}
		}
		elsif($type eq 'Create')
		{
			foreach(split(/\*/,$domain_status))
			{
				my($t_type,$t_name,$t_status) = split(/\ /,$_); 
				if($t_status eq 'created')
				{
					$create_list .= "<TR><TD>$t_type $t_name</TD><TD>$t_status</TD></TR>\n";
				}
				else
				{
					$create_list .= "<TR bgcolor='#ff6666'><TD>$t_type $t_name</TD><TD>$t_status</TD></TR>\n";
				}
			}
		}
		elsif($type eq 'Remove')
		{
			if($domain_status eq 'OK')
			{
				$remove_list .= "<TR><TD>$domain_name</TD><TD>$domain_status</TD></TR>\n";
			}
			else
			{
				$remove_list .= "<TR bgcolor='#ff6666'><TD>$domain_name</TD><TD>$domain_status</TD></TR>\n";
			}
		}
		elsif($type eq 'Add')
		{
			if($domain_status eq 'OK')
			{
				$add_list .= "<TR><TD>$domain_name</TD><TD>$domain_status</TD></TR>\n";
			}
			else
			{
				$add_list .= "<TR bgcolor='#ff6666'><TD>$domain_name</TD><TD>$domain_status</TD></TR>\n";
			}
		}
		elsif($type eq 'Insert')
		{
			if($domain_status ne 'ERROR')
			{
				$insert_list .= "<TR><TD>$domain_name</TD><TD>$isSSL</TD><TD>$c_date</TD><TD>$u_date</TD><TD>$e_date</TD><TD>$admin</TD><TD>$tech</TD><TD>$reg</TD><TD>$ns</TD></TR>\n";
			}
			else
			{
				$insert_list .= "<TR bgcolor='#ff6666'><TD>$domain_name</TD><TD>$isSSL</TD><TD>$c_date</TD><TD>$u_date</TD><TD>$e_date</TD><TD>$admin</TD><TD>$tech</TD><TD>$reg</TD><TD>$ns</TD></TR>\n";
			}
		}
	}
	my $message_to_send_html = "<!DOCTYPE html PUBLIC '-//W3C//DTD XHTML 1.0 Transitional//EN' 'http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd'><HTML xmlns='http://www.w3.org/1999/xhtml''>\n<HEAD><TITLE>Statistic of CTES utility</TITLE>\n</HEAD>\n<BODY>";
	my $subject_string= "";
	my $subject_ssl = "";
	my $subject_database = "";
	my $subject_domain = "";
	my $database_maintanse_list = "";
	if("" ne $database_list)
	{
		$subject_database = "Database current state" if $subject_database eq "";
		$message_to_send_html .= "<P><H3>Database checking</H3></P><P><TABLE><TR bgcolor='#ff6666'><TD>Unknown error in database record.</TD></TR><TR bgcolor='#ffff66'><TD>Can not insert date in record.</TD></TR><TR><TD>Normal status.</TD></TR></TABLE></P><TABLE width='100%'><TR bgcolor='#cccccc'><TD><B>Domain</B></TD><TD><B>Create date</B></TD><TD><B>Update date</B></TD><TD><B>Expire date</B></TD></TR>$database_list</TABLE>";
	}
	if("" ne $domain_list)
	{
		$subject_domain = "Domain expire statictic" if $subject_domain eq "";
		$message_to_send_html .= "<P><H3>Domain checking</H3></P>\n<P><TABLE><TR bgcolor='#ff6666'><TD>Unfully answer from whois or expiration date on domain already elapsed.</TD></TR><TR bgcolor='#ffff66'><TD>Expiration date will be expired soon.</TD></TR><TR><TD>Normal status.</TD></TR></TABLE></P><TABLE width = '100%'><TR bgcolor='#cccccc'><TD><B>Domain</B></TD><TD><B>Expiration date</B></TD><TD><B>Days remaining</B></TD></TR>$domain_list</TABLE>";
	}
	if("" ne $ssl_list)
	{
		$subject_ssl = "SSL Certs statistic" if $subject_ssl eq "";
		$message_to_send_html .= "<P><H3>SSL checking</H3></P><P><TABLE><TR bgcolor='#ff6666'><TD>Date unsnswer from openssl or expiration date on SSL Certifiacte already elapsed.</TD></TR><TR bgcolor='#ffff66'><TD>Expiration date will be expired soon.</TD></TR><TR><TD>Normal status.</TD></TR></TABLE></P><TABLE width='100%'><TR bgcolor='#cccccc'><TD><B>Domain</B></TD><TD><B>Expiration date</B></TD><TD><B>Days remaining</B></TD></TR>$ssl_list</TABLE>";
	}
	if ("" ne $create_list)
	{
		$subject_string = "Tables creation.";
		$message_to_send_html .= "<P><H3>Make tables in database</H3></P><TABLE width='100%'><TR bgcolor='#cccccc'><TD><B>Table</B></TD><TD><B>Status</B></TD></TR>$create_list</TABLE>";
	}
	if ("" ne $remove_list)
	{
		$subject_string = "Records removing.";
		$message_to_send_html .= "<P><H3>Removing records from database</H3></P><TABLE width='100%'><TR bgcolor='#cccccc'><TD><B>Domain</B></TD><TD><B>Status</B></TD></TR>$remove_list</TABLE>";
	}
	if ("" ne $add_list)
	{
		$subject_string = "Records adding.";
		$message_to_send_html .= "<P><H3>Add records to database</H3></P><TABLE width='100%'><TR bgcolor='#cccccc'><TD><B>Domain</B></TD><TD><B>Status</B></TD></TR>$add_list</TABLE>";
	}
	if ("" ne $insert_list)
	{
		$subject_string = "Record updating.";
		$message_to_send_html .= "<P><H3>Add records to database</H3></P><TABLE width='100%'><TR bgcolor='#cccccc'><TD><B>Domain</B></TD><TD><B>SSL token</B></TD><TD><B>Creation date</B></TD><TD><B>Updated</B></TD><TD><B>Expiration date</B></TD><TD><B>Administartive Contact</B></TD><TD><B>Technical contact</B></TD><TD><B>Registerer contact</B></TD><TD><B>Nameservers</B></TD></TR>$insert_list</TABLE>";
	}
	
	$message_to_send_html .= "<P><TABLE><TR><TD><B>Time:</B> $total_time</TD></TR>";
	$message_to_send_html .= "<TR><TD><B>Load average:</B> $load_average</TD></TR></TABLE></P>";
	$message_to_send_html .= "<P><B>For more information see utility log.</B></P>\n</BODY>\n</HTML>";
	
	return $message_to_send_html;
}
############################################ Main #####################################################
sub Main($)
{
	### Local variables
	my $config_file = PATH_TO_CONFIGURATION_FILE;
	my $INPUT_PARAM = shift;		# parameters from command line
	$notify_limit = NOTIFY_LIMIT;
	
	# check for input parameters
	if(!$INPUT_PARAM)
	{
		&PrintUsage();
		return 1;
	}
	else
	{		
		# checking for existing $config_file
		if (-e $config_file)
		{
			# get time of beginnig work
			$time_begin = time();
			$configuration = Com::Keysurvey::Configuration->new($config_file);
			
			# Check for errors in module Configuratiion.
			if($configuration->isChecked() ne "CONFIG::OK")
			{
				print("ERROR! $config_file ". $configuration->isChecked() ."\n");
			}
			else
			{
				$logger = Com::Keysurvey::Logger->new($configuration->getLoggerFile());
				# set mode of logger (DEBUG, INFO, WARN, ERROR)
				$logger->setMode($configuration->getLoggerMode);
				$logger->MakeRecord("","-----------------");
				if("LOGGER::OK" ne $logger->isChecked())
				{
					print("Logger say ". $logger->isChecked() ."\n");
					print("Configuration say ". $configuration->isChecked() ."\n");
					return 1;
				}
				$message_to_log = $configuration->getProgramName() .", version ". $configuration->getProgramVersion();
				$logger->MakeRecord($type_of_log,$message_to_log);
				print($configuration->getProgramName() .", version ". $configuration->getProgramVersion() ."\n");
				$message_to_log = "Logger mode set to ". $configuration->getLoggerMode;
				$logger->MakeRecord("DEBUG",$message_to_log);
				print("$message_to_log.\n") if "DEBUG" eq $configuration->getLoggerMode;
				$sender = Com::Keysurvey::Sender->new($configuration->getOperatorMails());
				$sender->setSMTPServer($configuration->getSenderSMTPServer);
				$message_to_log = "Sender will be working with SMTP server ". $configuration->getSenderSMTPServer ." and operator(s) ".$configuration->getOperatorMails();
				$logger->MakeRecord("DEBUG",$message_to_log);
				print($message_to_log ."\n") if "DEBUG" eq $configuration->getLoggerMode;
				$database = Com::Keysurvey::DBUse->new(
								$configuration->getDatabaseHost,
								$configuration->getDatabaseName,
								$configuration->getDatabaseLogin,
								$configuration->getDatabasePassword
								);		
				$message_to_log = "Connect to database ". $configuration->getDatabaseName .
						" on host ". $configuration->getDatabaseHost .
						", user ". $configuration->getDatabaseLogin .
						" password is not shown.";
				$logger->MakeRecord("DEBUG",$message_to_log);
				print($message_to_log ."\n") if "DEBUG" eq $configuration->getLoggerMode;
				$message_to_log = "Using DB ". $configuration->getDatabaseName() ." on host ". $configuration->getDatabaseHost();
				$logger->MakeRecord($type_of_log,$message_to_log);
				print("Using DB ". $configuration->getDatabaseName() ." on host ". $configuration->getDatabaseHost() ."\n");
				$message_to_log = "Now getting domain names with expiration dates.";
				$logger->MakeRecord("DEBUG",$message_to_log);
				print($message_to_log ."\n") if "DEBUG" eq $configuration->getLoggerMode;
				$notify_limit = $configuration->getNotifyPeriod;
				$message_to_log = "Value of amount before expires days set to ". $notify_limit;
				$logger->MakeRecord("DEBUG",$message_to_log);
				print($message_to_log ."\n") if "DEBUG" eq $configuration->getLoggerMode;
				# switch for input parameters from command line
				for($INPUT_PARAM)
				{
					if("domain" eq $INPUT_PARAM)
					{
						&CheckDomain();
					}
					elsif("database" eq $INPUT_PARAM)
					{
						&CheckDatabase();
					}
					elsif("adddomains" eq $INPUT_PARAM)
					{
						&AddDomains(@ARGV);
					}
					elsif("addssldomains" eq $INPUT_PARAM)
					{
						&AddSSLDomains(@ARGV);
					}
					elsif("ssl" eq $INPUT_PARAM)
					{
						&CheckSSL();
					}
					elsif("all" eq $INPUT_PARAM)
					{
						&CheckDatabase();
						&CheckDomain();
						&CheckSSL();
					}
					elsif("createtables" eq $INPUT_PARAM)
					{
						&CreateTables();
					}
					elsif("help" eq $INPUT_PARAM)
					{
						&PrintHelp();
						exit 0;
					}
					elsif("insert" eq $INPUT_PARAM)
					{
						my @arguments = @ARGV;
						&InsertInfo(@arguments);
					}
					elsif("removedomains" eq $INPUT_PARAM)
					{
						&RemoveDomains(@ARGV);
					}
					else
					{
						&PrintUsage();
						exit 1;
					}
				}
				print("Counting records in database ... ");
				my $total_records = $database->getTotalRecords();
				$message_to_log = "Get number of total records in database (table `domains`) is $total_records records.";
				$logger->MakeRecord("DEBUG",$message_to_log);
				print($message_to_log ."\n") if "DEBUG" eq $configuration->getLoggerMode;
				$time_end = time();
				$total_time = $time_end-$time_begin;
				$load_average = `uptime`;
				$load_average =~s/.*load average(.*)$/$1/;
				
				# Submit @domain_to_submit for send to operator about domain checks
				$sender->SendNotification(&Statistic(@domain_to_submit));
				print("done\n");
				$message_to_log = "Done. Total parsed domains $total_records in $total_time second(s).";
				$logger->MakeRecord("",$message_to_log);
				print($message_to_log ."\n");
			}
		}
		else
		{
			# print to console (if running from command line), or STDUOT error message
			print ("ERROR! $config_file file is not defined or not accesseble.\n");
		}		
	}
}
############################################ LAUNCH ###################################################
# take input parameters from command line
&Main(shift);
