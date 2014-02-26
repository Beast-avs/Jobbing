package Com::Keysurvey::DBUse;

use strict;
use DBI;

####################### Synopsis ########################################
# These features are done:												#
#	- Getting the total amount of records in database;					#
#	- Select from database by given value (domain);						#
#	- Data management (such as adding, removing, updating).				#
#		Method return following result:									#
#			- ADDING_OK - data added succesfully;						#
#			- ADDING_DUBLICATE_ERROR - error during add operation,		#
#			 	the record already exist;								#
#			- ADDING_ERROR - unknow error during add operation;			#
#			- REMOVE_OK - record removed succesfully					#
#			- REMOVE_EXIST_ERROR - the given record is non exist		#
#			- REMOVE_ERROR - unknown error while removing				#
# Module provides the following public methods:							#
#	- new - constructor, inits main	parameters;							#
#	- AddRecord - add records in database table `domains`;				#
#	- getDomainExpire - returns an expire date of domain name;			#
# 	- getDomains - returns a list of domains in table `domains`;		#
#	- isChecked - returns a error if occures;							#
#	- getErrorDescription - returns a descriptipton of given error;		#
#	- gerRecordOnDomain - returns a cortege from table by given domain;	#
#	- getSelection - NO MORE SUPPORTED. REMOVE IT;						#
#	- getTotalRecords - returns a total records from table `domains`;	#
#	- RemoveRecord - removes a record from table by given domain name	# 
#					and	returns a status as the result					#
#	- UpdateRecord - updates record in table `domains` by given domain	#
#					and return a status as the result					#
#########################################################################

############### Structure of tables in check_domain_db ##################
#DROP TABLE IF EXISTS domains;
#CREATE TABLE `domains` ( 
#	`ID` int(4) NOT NULL auto_increment, 
#	`DomainName` varchar(255) NOT NULL, 
#	`DateCreate` datetime NOT NULL, 
#	`DateUpdate` datetime, 
#	`DateExpire` datetime NOT NULL,
#	`AdminContact` int(4),
#	`TechContact` int(4),
#	`RegistrantContact` int(4),
#	`NameServers` int(4),  
#	PRIMARY KEY (`ID`),
#	CONSTRAINT `reg_cont_fk` FOREIGN KEY (`RegistrantContact`) REFERENCES `registrant_contacts` (`ID`) ON DELETE CASCADE,
#	CONSTRAINT `adm_cont_fk` FOREIGN KEY (`AdminContact`) REFERENCES `administrative_contacts` (`ID`) ON DELETE CASCADE,
#	CONSTRAINT `tech_cont_fk` FOREIGN KEY (`TechContact`) REFERENCES `technical_contacts` (`ID`) ON DELETE CASCADE,
#	CONSTRAINT `ns_fk` FOREIGN KEY (`NameServers`) REFERENCES `name_servers` (`ID`) ON DELETE CASCADE
#);
#
#DROP TABLE IF EXISTS registrant_contacts;
#CREATE TABLE `registrant_contacts` ( 
#	`ID` int(4) NOT NULL auto_increment, 
#	`RegistrantName` varchar(255), 
#	`RegistrantCompany` varchar(255), 
#	`RegistrantAddress` varchar(255), 
#	`RegistrantPhone` varchar(255),
#	`RegistrantMail` varchar(255), 
#	PRIMARY KEY (`ID`)
#);
#
#DROP TABLE IF EXISTS administrative_contacts;
#CREATE TABLE `administrative_contacts` ( 
#	`ID` int(4) NOT NULL auto_increment, 
#	`AdminName` varchar(255), 
#	`AdminCompany` varchar(255), 
#	`AdminAddress` varchar(255), 
#	`AdminPhone` varchar(255),
#	`AdminMail` varchar(255), 
#	PRIMARY KEY (`ID`)
#);
#
#DROP TABLE IF EXISTS technical_contacts;
#CREATE TABLE `technical_contacts` ( 
#	`ID` int(4) NOT NULL auto_increment, 
#	`TechName` varchar(255), 
#	`TechCompany` varchar(255), 
#	`TechAddress` varchar(255), 
#	`TechPhone` varchar(255),
#	`TechMail` varchar(255), 
#	PRIMARY KEY (`ID`)
#);
#
#DROP TABLE IF EXISTS name_servers;
#CREATE TABLE `name_servers` ( 
#	`ID` int(4) NOT NULL auto_increment,
#	`NameSeraver` varchar(255),
#	PRIMARY KEY (`ID`)
#); 

# TODO: 
#       1. Rewrite the method RemoveRecord for deleting several records from database.

########## Variables #########
my $VERSION = "1.22";	# Version of module
my $DB_HOST = ""; 		# Database host
my $DB_NAME = ""; 		# Database name
my $DB_LOGIN = "";		# Database login
my $DB_PASSWORD = "";	# Database password
my $DB_CONNECTION;		# Object-link to the connected DB
my @errors = ();		# Array of errors during work

# Constructor
sub new($)
{
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $self={};
	bless($self, $class);
	
	my ($db_host,$db_name,$db_login,$db_password) = @_;
	
	$self->Init($db_host,$db_name,$db_login,$db_password);

	return($self);
}

# Initialize sub
sub Init(@)
{
	my $self = shift;
	my ($db_host,$db_name,$db_login,$db_password) = @_;
	
	$DB_HOST = $db_host;
	$DB_NAME = $db_name;
	$DB_LOGIN = $db_login;
	$DB_PASSWORD = $db_password;
	$DB_CONNECTION = undef;
}

# Decstructor
sub DESTROY
{
	# Created just in case.
}

# Method OpenConnection - PRIVATE
# Returns link to database connection
sub OpenConnection
{
	my $self = shift;
	
	my $db_host = $DB_HOST;
	my $db_name = $DB_NAME;
	my $db_login = $DB_LOGIN;
	my $db_password = $DB_PASSWORD;
	my $database_connection;
	
	# Prepare the MySQL DBD driver
	my $driver = DBI->install_driver('mysql');
 	my @databases = $driver->func($db_host, '_ListDBs');
	
	# connect to database on host using login and password
	$database_connection = DBI->connect("DBI:mysql:$db_name:$db_host", $db_login, $db_password);
	
	$DB_CONNECTION = $database_connection;
	
	return $database_connection;
}

# Method CloseConnection - PRIVATE
sub CloseConnection
{
	my $self = shift;
	my $database_connection = $DB_CONNECTION;
	$database_connection->disconnect();
}

# Method CreateTables creates all tables - PUBLIC
# Returns the array of results for each table creation status
sub CreateTables()
{
	my $self = shift;
	my @result = ();
	push(@result, $self->CreateTableDomains());
	push(@result, $self->CreateTableRegistrantContacts());
	push(@result, $self->CreateTableAdministrativeContacts());
	push(@result, $self->CreateTableTechnicalContacts());
	push(@result, $self->CreateTableNameServers());
	
	return @result;
}
# Method CreateTableDomains - PUBLIC
# Returns the result of tablecreation
sub CreateTableDomains()
{
	my $self = shift;
	my $dbc;
	my $qdbc;
	my $result = "Table `domains` created";
	
	$dbc = $self->OpenConnection();

	# delete table from database
	$qdbc = $dbc->prepare("
			DROP TABLE IF EXISTS domains;
			");
	$qdbc->execute;
	$qdbc = $dbc->prepare("
				CREATE TABLE `domains` ( 
				`ID` int(4) NOT NULL auto_increment, 
				`DomainName` varchar(255) NOT NULL,
				`isSSL` varchar(255) NOT NULL DEFAULT 'false', 
				`DateCreate` datetime NOT NULL, 
				`DateUpdate` datetime, 
				`DateExpire` datetime NOT NULL,
				`AdminContact` int(4),
				`TechContact` int(4),
				`RegistrantContact` int(4),
				`NameServers` int(4),  
				PRIMARY KEY (`ID`),
				CONSTRAINT `reg_cont_fk` FOREIGN KEY (`RegistrantContact`) REFERENCES `registrant_contacts` (`ID`) ON DELETE CASCADE,
				CONSTRAINT `adm_cont_fk` FOREIGN KEY (`AdminContact`) REFERENCES `administrative_contacts` (`ID`) ON DELETE CASCADE,
				CONSTRAINT `tech_cont_fk` FOREIGN KEY (`TechContact`) REFERENCES `technical_contacts` (`ID`) ON DELETE CASCADE,
				CONSTRAINT `ns_fk` FOREIGN KEY (`NameServers`) REFERENCES `name_servers` (`ID`) ON DELETE CASCADE
				);
				");
	# Execute query
	$qdbc->execute();
	# finish query
	$qdbc->finish;
	$self->CloseConnection();
	return $result;	
}

# Method CreateTableRegistrantContacts - PUBLIC
# Returns the result of tablecreation
sub CreateTableRegistrantContacts()
{
	my $self = shift;
	my $dbc;
	my $qdbc;
	my $result = "Table `registrant_contacts` created";
	
	$dbc = $self->OpenConnection();
	# delete table from database
	$qdbc = $dbc->prepare("
			DROP TABLE IF EXISTS registrant_contacts;
			");
	$qdbc->execute;
	
	$qdbc = $dbc->prepare("
				CREATE TABLE `registrant_contacts` ( 
				`ID` int(4) NOT NULL auto_increment, 
				`RegistrantName` varchar(255), 
				`RegistrantCompany` varchar(255), 
				`RegistrantAddress` varchar(255), 
				`RegistrantPhone` varchar(255),
				`RegistrantMail` varchar(255), 
				PRIMARY KEY (`ID`)
				);
				");
	# Execute query
	$qdbc->execute;
	# finish query
	$qdbc->finish;
	$self->CloseConnection();
	return $result;	
} 

# Method CreateTableAdministrativeContacts - PUBLIC
# Returns the result of tablecreation
sub CreateTableAdministrativeContacts()
{
	my $self = shift;
	my $dbc;
	my $qdbc;
	my $result = "Table `administrative_contacts` created";
	
	$dbc = $self->OpenConnection();
	# delete table from database
	$qdbc = $dbc->prepare("
			DROP TABLE IF EXISTS administrative_contacts;
			");
	$qdbc->execute;	
	$qdbc = $dbc->prepare("
				CREATE TABLE `administrative_contacts` ( 
				`ID` int(4) NOT NULL auto_increment, 
				`AdminName` varchar(255), 
				`AdminCompany` varchar(255), 
				`AdminAddress` varchar(255), 
				`AdminPhone` varchar(255),
				`AdminMail` varchar(255), 
				PRIMARY KEY (`ID`)
				);
				");
	# Execute query
	$qdbc->execute;
	# finish query
	$qdbc->finish;
	$self->CloseConnection();
	return $result;	
} 

# Method CreateTableTechnicalContacts - PUBLIC
# Returns the result of tablecreation
sub CreateTableTechnicalContacts()
{
	my $self = shift;
	my $dbc;
	my $qdbc;
	my $result = "Table `technical_contacts` created";
	
	$dbc = $self->OpenConnection();
	# delete table from database
	$qdbc = $dbc->prepare("
			DROP TABLE IF EXISTS technical_contacts;
			");
	$qdbc->execute;		
	$qdbc = $dbc->prepare("
				CREATE TABLE `technical_contacts` ( 
				`ID` int(4) NOT NULL auto_increment, 
				`TechName` varchar(255), 
				`TechCompany` varchar(255), 
				`TechAddress` varchar(255), 
				`TechPhone` varchar(255),
				`TechMail` varchar(255), 
				PRIMARY KEY (`ID`)
				);
				");
	# Execute query
	$qdbc->execute;
	# finish query
	$qdbc->finish;
	$self->CloseConnection();
	return $result;	
} 

# Method CreateTableNameServers - PUBLIC
# Returns the result of tablecreation
sub CreateTableNameServers()
{
	my $self = shift;
	my $dbc;
	my $qdbc;
	my $result = "Table `name_servers` created";
	
	$dbc = $self->OpenConnection();
	# delete table from database
	$qdbc = $dbc->prepare("
			DROP TABLE IF EXISTS name_servers;
			");
	$qdbc->execute;		
	$qdbc = $dbc->prepare("
				CREATE TABLE `name_servers` ( 
				`ID` int(4) NOT NULL auto_increment,
				`NameSeraver` varchar(255),
				PRIMARY KEY (`ID`)
				);
				");
	# Execute query
	$qdbc->execute;
	# finish query
	$qdbc->finish;
	$self->CloseConnection();
	return $result;	
} 

# Method getTotalRecords - PUBLIC
# Returns total records in table `domains`
sub getTotalRecords()
{
	my $self = shift;
	my $dbc;
	my $qdbc;
	my $result;
	
	$dbc = $self->OpenConnection();
	
	# query to database for counting of records
	$qdbc = $dbc->prepare("
				SELECT COUNT( * )
				AS total_records
				FROM `domains`
				");
	# Execute query
	$qdbc->execute;
	# Appropriating result of query
	$result = $qdbc->fetchrow();
	# finish query
	$qdbc->finish;
	$self->CloseConnection();
	return $result;
}

# Method getSelection(PARAMS) - PUBLIC
# Returns a given domain from table `domains` if exist
sub getSelection(@)
{
	my $self = shift;
	my ($type,$param,$isSSL) = @_;
	my @result=();
	for ($type)
	{
		if("domain" eq $type)
		{
			my $dbc;
			my $qdbc;
			my $result = "_";
			
			$dbc = $self->OpenConnection();
			$qdbc = $dbc->prepare("
						SELECT DomainName
						FROM `domains`
						WHERE DomainName = '$param'
						AND isSSL = '$isSSL'
				");
			$qdbc->execute();
			$result = $qdbc->fetchrow();
			$qdbc->finish;
			$self->CloseConnection();
			if(!$result)
			{
				@result = 0;
			}
			else
			{	
				if($result eq $param)
				{
					push(@result,$param);
				}
			}
		}
		elsif("create" eq $type)
		{
			push(@result,$param);
			print("Nearest to creation date ". $param ." is:\n");
		}
		elsif("update" eq $type)
		{
			push(@result,$param);
			print("Nearest to updation date ". $param ." is:\n");
		}
		elsif("expire" eq $type)
		{
			push(@result,$param);
			print("Nearest to expiration date ". $param ." is:\n");
		}
		else
		{
			@result = 0;
		}
	}
	return @result;
}

# Method AddRecord(PARAMS) - PUBLIC
# Adds to database in table `domains` a record
sub AddRecord(@)
{
	my $self = shift;
	my @row = @_;
	my $dbc;
	
	# Checking for duplication
	my @record = $self->getSelection("domain","$row[1]","$row[2]");
	print("AddRecord = ". $row[1] ." - "); 
	if($record[0] eq $row[1] and $row[1] ne "0")
	{
		return "DB::ADDING_DUPLICATE_ERROR";
	}
	else
	{
		my $id = $row[0];
		my $domain = $row[1];
		my $isSSL = $row[2];
		my $c_date = $row[3];
		my $u_date = $row[4];
		my $e_date = $row[5];
		my $admin_contact = $row[6];
		my $tech_contact = $row[7];
		my $reg_contact = $row[8];
		my $ns = $row[9];
		$dbc = $self->OpenConnection();
		
		# get empty ID
		my $qdbc = $dbc->prepare("
					SELECT ID
					FROM `domains`
					");
		$qdbc->execute;
		my @ids;
		while (my $ids_current = $qdbc->fetchrow())
		{
			push(@ids,$ids_current);
		}
		my $ids_length = scalar(@ids);
		for(my $i = 0; $i <= $ids_length; $i++)
		{
			my $next_i = $i + 1;
			if(defined($ids[$i]) and $ids[$i] != $next_i)
			{
				$id = $next_i;
				last;
			}
		}
		$qdbc->finish;
		my $string = "
						'$id',
						'$domain',
						'$isSSL',
						'$c_date',
						'$u_date',
						'$e_date',
						'$admin_contact',
						'$tech_contact',
						'$reg_contact',
						'$ns'
					";
		# Add record to table `domains`
		$qdbc = $dbc->prepare("
					INSERT INTO `domains`
					VALUES ( $string )
					");
		$qdbc->execute;
		$qdbc->finish;
		$self->CloseConnection();
		return "DB::ADDING_OK";
	}
}

# Method RemoveRecord(PARAMS) - PUBLIC
# NOT IMPLEMENTED
sub RemoveRecord($)
{
	my $self = shift;
	my $domain = shift @_;
	
	my $record;
	my $result;

	print("RemoveRecord = ". $domain ." - ");
	
	my $dbc = $self->OpenConnection();
	my $qdbc = $dbc->prepare("
				SELECT DomainName
				FROM `domains`
				WHERE DomainName = '$domain'
				");
	$qdbc->execute();
	$record = $qdbc->fetchrow();
	$qdbc->finish;

	if(!$record)
	{
		$result = "DB::REMOVING_NO_RECORD";
	}
	else
	{
		$qdbc = $dbc->prepare("
					DELETE
					FROM `domains`
					WHERE DomainName = '$domain'
					");
		$qdbc->execute();
		$qdbc->finish;
		$result = "DB::REMOVING_OK";
	}
	$self->CloseConnection();
	return $result;
}

# Method UpdateRecord(PARAMS) - PUBLIC
# Updates record in table `domains`
sub UpdateRecord(@)
{
	my $self = shift;
	my ($domain,$isSSL,$c_date,$u_date,$e_date) = @_;
	my $admin_contact = "0";
	my $tech_contact = "0";
	my $reg_contact = "0";
	my $ns ="5";
	
	my @record;
	my $result;
	my $dbc;
	
	$dbc = $self->OpenConnection();
	my $qdbc = $dbc->prepare("
					UPDATE `domains`
					SET DateCreate = '". $c_date ."',
						DateUpdate = '". $u_date ."',
						DateExpire = '". $e_date ."',
						AdminContact = '". $admin_contact ."',
						TechContact = '". $tech_contact ."',
						RegistrantContact = '". $reg_contact ."',
						NameServers = '". $ns ."'
					WHERE DomainName = '". $domain ."' 
					");
	$qdbc->execute;
	$qdbc->finish;
	$self->CloseConnection();
	$result = "|$domain|$c_date|$u_date|$e_date|";

	return $result;
}

# Method getDomainExpire() - PUBLIC
# Outputs a list (array) of domains and expitation dates
sub getDomainExpire()
{
	my $self = shift;
	my $dbc;
	my $qdbc;
	my @result = ();
	$dbc = $self->OpenConnection();
	$qdbc = $dbc->prepare("
					SELECT DomainName,DateExpire 
					FROM `domains`
					WHERE isSSL = 'false'
					ORDER BY DateExpire
				");
	
	$qdbc->execute();
	while (my @result2 = $qdbc->fetchrow_array()) {
           push (@result, join(" ", @result2));
          }
	
	$qdbc->finish;
	$self->CloseConnection();
	return @result;
}

# Method getDomainExpire() - PUBLIC
# Outputs a list (array) of domains and expitation dates
sub getSSLDomainExpire()
{
        my $self = shift;
        my $dbc;
        my $qdbc;
        my @result = ();
        $dbc = $self->OpenConnection();
        $qdbc = $dbc->prepare("
                    SELECT DomainName,DateExpire
                    FROM `domains`
					WHERE isSSL = 'true'
                    ORDER BY DateExpire
                ");

        $qdbc->execute();
        while (my @result2 = $qdbc->fetchrow_array()) {
           push (@result, join(" ", @result2));
          }

        $qdbc->finish;
        $self->CloseConnection();
        return @result;
}

# Method getDomains() - PUBLIC
# Outputs a list (array) of domains
sub getDomains()
{
	my $self = shift;
	my $dbc;
	my $qdbc;
	my @result = ();
	$dbc = $self->OpenConnection();
	$qdbc = $dbc->prepare("
					SELECT DomainName 
					FROM `domains`
					WHERE isSSL = 'false'
					ORDER BY DomainName
				");
	
	$qdbc->execute();
	while (my @result2 = $qdbc->fetchrow_array()) {
           push (@result, join(" ", @result2));
          }
	
	$qdbc->finish;
	$self->CloseConnection();
	return @result;
}

# Method getDomains() - PUBLIC
# Outputs a list (array) of domains
sub getSSLDomains()
{
	my $self = shift;
	my $dbc;
	my $qdbc;
	my @result = ();
	$dbc = $self->OpenConnection();
	$qdbc = $dbc->prepare("
					SELECT DomainName 
					FROM `domains`
					WHERE isSSL = 'true'
					ORDER BY DomainName
				");
	
	$qdbc->execute();
	while (my @result2 = $qdbc->fetchrow_array()) {
           push (@result, join(" ", @result2));
          }
	
	$qdbc->finish;
	$self->CloseConnection();
	return @result;
}

# Method getRecordOnDomain(PARAM) - PUBLIC
# Returns a record by given domain
sub getRecordOnDomain($)
{
	my $self = shift;
	my $domain = shift @_;
	
	my $dbc;
	my $qdbc;
	my @result = ();
	$dbc = $self->OpenConnection();
	$qdbc = $dbc->prepare("
					SELECT DomainName,DateCreate,DateUpdate,DateExpire 
					FROM `domains`
					WHERE DomainName = '". $domain ."'
				");
	
	$qdbc->execute();
	# push to array a joined with '*' record from table `domains`
	while (my @result2 = $qdbc->fetchrow_array()) {
           push (@result, join("*", @result2));
          }
	$qdbc->finish;
	$self->CloseConnection();
	return @result;
}

# Checks for errors which were occure during the work - PUBLIC
# Returns the string of errors
sub isChecked()
{
	my $self = shift;
	my $result;
	
	if (scalar @errors ne 0)
	{
		$result = join(":", @errors);
	}
	else
	{
		$result = "DB::OK";
	}
	return $result;
}

# Returned messages. Populates the array by issues - PRIVATE
sub ReturnedMessage(@)
{
	my $self = shift;
	my $message = shift @_;
	push (@errors, $message);
}

# Description of errors. Get the issue description (understandable for human) - PUBLIC
sub getErrorDescription($)
{
	my $self = shift;
	my $error = shift @_;
	my $description;
	if("DB::REMOVING_NO_RECORD" eq $error)
	{
		$description = "DB ERROR! No such record";
	}
        elsif("DB::REMOVING_OK" eq $error)
        {
                $description = "OK";
        }
	elsif("DB::ADDING_OK" eq $error)
        {
                $description = "OK";
        }
        elsif("DB::ADDING_DUPLICATE_ERROR" eq $error)
        {
                $description = "DB ERROR! Already exist";
        }
	elsif("DB::OK" eq $error)
	{
		$description = "OK";
	}
	else
	{
		$description = "DB ERROR! Unknown error";
	}
	return $description;
}

1;
