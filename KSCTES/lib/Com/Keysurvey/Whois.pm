package Com::Keysurvey::Whois;

use strict;
####################### Synopsis #####################
# Whois query parser module. The output data will contain: 
#	- domain name;
#	- registrant name;
#	- creation data;
#	- update data;
#	- expires data;
#	- admin email;
# 	- tech email;
#
# TODO: 
#       1. Add parse Contacts (Administrative, Technikal, Domain, etc.).
#       2. To get rid an error "Use of uninitialized value".
#		3. Think about implement the "smart parser". It means the code 
#			which is able to parse the info from registrant in any format.
#			Now the data from each registrant parses by own rules. Sometimes
#			These rules contains similar filters. 
#
# Return date in format:
#		YEAR-MM-DD HH:MM:SS

###################### List of parsed whois servers ###
#			whois.publicinterestregistry.net
#			whois.tucows.com
#			whois.markmonitor.com
#			whois.networksolutions.com
#			whois.safenames.net
#			whois.publicdomainregistry.com
#			whois.webmasters.com
#			whois.godaddy.com
#			whois.moniker.com
#			whois.fabulous.com
#			whois.register.com
#			whois.com.ua
#			whois.verisign-grs.com
#			whois.afilias.info
#			whois.neulevel.biz
#			whois.wildwestdomains.com
#			whois.nic.uk
#			whois.denic.de
#			whois.nic.us
#

# Constructor
sub new()
{
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $self={};
	
	$self->{DOMAIN_NAME} = undef;
	$self->{REGISTRANT} = undef;
	$self->{DATA_CREATE} = undef;
	$self->{DATA_UPDATE} = undef;
	$self->{DATA_EXPIRE} = undef;
	$self->{ADMIN_MAIL} = undef;
	$self->{TECH_MAIL} = undef;
	$self->{QUERIYNG_SERVER} = undef;
	$self->{LOGGER} = undef;
	
	bless($self, $class);
		
	return($self);
}

# Destructor
sub DESTROY
{
	# Created just in case.	
}

# Method setDomainName
sub setDomainName($)
{
	my ($self, $domain_name) = @_;
	$self->{DOMAIN_NAME} = $domain_name;	
}

# Method getDomainName
sub getDomainName()
{
	my $self = shift;
	return $self->{DOMAIN_NAME};
}

# Method setRegistrant
sub setRegistrant($)
{
	my ($self,$registrant) = @_;
	$self->{REGISTRANT} = $registrant;
}

# Method getRegistrant
sub getRegistrant()
{
	my $self = shift;
	return $self->{REGISTRANT};
}

# Method setDataCreate
sub setDataCreate($)
{
	my ($self, $data_create) = @_;
	$self->{DATA_CREATE} = $data_create;
}

# Method getDataCreate
sub getDataCreate()
{
	my $self = shift;
	return $self->{DATA_CREATE};
}

# Method setDataUpdate
sub setDataUpdate($)
{
	my ($self, $data_update) = @_;
	$self->{DATA_UPDATE} = $data_update;
}

# Method getDataUpdate 
sub getDataUpdate()
{
	my $self = shift;
	return $self->{DATA_UPDATE};
}

# Method setDataExpire
sub setDataExpire($)
{
	my $self = shift;
	if (@_)
	{
		$self->{DATA_EXPIRE} = shift;
	}
}

# Method getDataExpire
sub getDataExpire()
{
	my $self = shift;
	if (!$self->{DATA_EXPIRE} or $self->{DATA_EXPIRE} eq "")
	{
		return "n/a";
	}
	else
	{
		return $self->{DATA_EXPIRE};
	}
	
}

# Method setAdminMail
sub setAdminMail($)
{
	my $self = shift;
	if (@_)
	{
		$self->{ADMIN_MAIL} = shift;
	}
}

# Method getAdminMail
sub getAdminMail()
{
	my $self = shift;
	return $self->{ADMIN_MAIL};
}

# Method setTechMail
sub setTechMail($)
{
	my $self = shift;
	if (@_)
	{
		$self->{TECH_MAIL} = shift;
	}
}

# Method getTechMail
sub getTechMail()
{
	my $self = shift;
	return $self->{TECH_MAIL};
}

# Method getQueriyngServer
sub getQueriyngServer()
{
	my $self = shift;
	return $self->{QUERIYNG_SERVER};
}

# Method setQueriyngServer
sub setQueriyngServer($)
{
	my $self = shift;
	if (@_)
	{
		$self->{QUERIYNG_SERVER} = shift;
	}
}

# Method getLogger
sub getLogger()
{
	my $self = shift;
	return $self->{LOGGER};
}

# Method setLogger
sub setLogger()
{
	my $self = shift;
	if (@_)
	{
		$self->{LOGGER} = shift;
	}
}

####################### Parsers #####################

# Method ParseWhois
sub ParseWhois($)
{
	my $self = shift;
	
	my $domain;
	my $queriyng_server;
	my $whois_exe = "/usr/bin/jwhois -i ";
	if (@_)
	{
		$domain = shift;
	}
	my $logger = $self->getLogger;
	$whois_exe .= " ".$domain;
	print("Com::Keysurvey:Whois -> ".$domain."\n");
	my @request = `$whois_exe`;
	foreach my $request(@request)
	{
		$self->setDomainName(lc($domain));
		if ($request =~ m/^\[(whois(\D*))\]/i)
		{
			my $raw_data = $1;
			$raw_data = lc($raw_data);
			$queriyng_server = $raw_data;
			$self->setQueriyngServer($queriyng_server);

			# Choose parser according regisrators
			for ($raw_data)
			{
				if ("whois.publicinterestregistry.net" eq $raw_data)
				{
					(my $domain_name,
						my $registrant,
						my $data_create,
						my $data_update,
						my $data_expire,
						my $admin_mail,
						my $tech_mail) = &ParserPublicinterestregistryNet(@request);
					$self->setDomainName($domain_name);
					$self->setRegistrant($registrant);
					$self->setDataCreate($data_create);
					$self->setDataUpdate($data_update);
					$self->setDataExpire($data_expire);
					$self->setAdminMail($admin_mail);
					$self->setTechMail($tech_mail);
				}
				elsif ("whois.tucows.com" eq $raw_data)
				{
					(my $domain_name,
						my $registrant,
						my $data_create,
						my $data_update,
						my $data_expire,
						my $admin_mail,
						my $tech_mail) = &ParserTucowsCom(@request);
					$self->setDomainName($domain_name);
					$self->setRegistrant($registrant);
					$self->setDataCreate($data_create);
					$self->setDataUpdate($data_update);
					$self->setDataExpire($data_expire);
					$self->setAdminMail($admin_mail);
					$self->setTechMail($tech_mail);
				}
				elsif ("whois.markmonitor.com" eq $raw_data)
				{
					(my $domain_name,
						my $registrant,
						my $data_create,
						my $data_update,
						my $data_expire,
						my $admin_mail,
						my $tech_mail) = &ParserMarkmonitorCom(@request);
					$self->setDomainName($domain_name);
					$self->setRegistrant($registrant);
					$self->setDataCreate($data_create);
					$self->setDataUpdate($data_update);
					$self->setDataExpire($data_expire);
					$self->setAdminMail($admin_mail);
					$self->setTechMail($tech_mail);
						
				}
				elsif ("whois.networksolutions.com" eq $raw_data)
				{
					(my $domain_name,
						my $registrant,
						my $data_create,
						my $data_update,
						my $data_expire,
						my $admin_mail,
						my $tech_mail) = &ParserNetworksolutionsCom(@request);
					$self->setDomainName($domain_name);
					$self->setRegistrant($registrant);
					$self->setDataCreate($data_create);
					$self->setDataUpdate($data_update);
					$self->setDataExpire($data_expire);
					$self->setAdminMail($admin_mail);
					$self->setTechMail($tech_mail);
				}
				elsif ("whois.safenames.net" eq $raw_data)
				{
					(my $domain_name,
						my $registrant,
						my $data_create,
						my $data_update,
						my $data_expire,
						my $admin_mail,
						my $tech_mail) = &ParserSafenamesNet(@request);
					$self->setDomainName($domain_name);
					$self->setRegistrant($registrant);
					$self->setDataCreate($data_create);
					$self->setDataUpdate($data_update);
					$self->setDataExpire($data_expire);
					$self->setAdminMail($admin_mail);
					$self->setTechMail($tech_mail);
				}
				elsif ("whois.publicdomainregistry.com" eq $raw_data)
				{
					(my $domain_name,
						my $registrant,
						my $data_create,
						my $data_update,
						my $data_expire,
						my $admin_mail,
						my $tech_mail) = &ParserPublicdomainregistryCom(@request);
					$self->setDomainName($domain_name);
					$self->setRegistrant($registrant);
					$self->setDataCreate($data_create);
					$self->setDataUpdate($data_update);
					$self->setDataExpire($data_expire);
					$self->setAdminMail($admin_mail);
					$self->setTechMail($tech_mail);
				}
				elsif ("whois.webmasters.com" eq $raw_data)
				{
					(my $domain_name,
						my $registrant,
						my $data_create,
						my $data_update,
						my $data_expire,
						my $admin_mail,
						my $tech_mail) = &ParserWebmastersCom(@request);
					$self->setDomainName($domain_name);
					$self->setRegistrant($registrant);
					$self->setDataCreate($data_create);
					$self->setDataUpdate($data_update);
					$self->setDataExpire($data_expire);
					$self->setAdminMail($admin_mail);
					$self->setTechMail($tech_mail);
				}
				elsif ("whois.godaddy.com" eq $raw_data)
				{
					(my $domain_name,
						my $registrant,
						my $data_create,
						my $data_update,
						my $data_expire,
						my $admin_mail,
						my $tech_mail) = &ParserGodaddyCom(@request);
					$self->setDomainName($domain_name);
					$self->setRegistrant($registrant);
					$self->setDataCreate($data_create);
					$self->setDataUpdate($data_update);
					$self->setDataExpire($data_expire);
					$self->setAdminMail($admin_mail);
					$self->setTechMail($tech_mail);
				}
				elsif ("whois.moniker.com" eq $raw_data)
				{
					(my $domain_name,
						my $registrant,
						my $data_create,
						my $data_update,
						my $data_expire,
						my $admin_mail,
						my $tech_mail) = &ParserMonikerCom(@request);
					$self->setDomainName($domain_name);
					$self->setRegistrant($registrant);
					$self->setDataCreate($data_create);
					$self->setDataUpdate($data_update);
					$self->setDataExpire($data_expire);
					$self->setAdminMail($admin_mail);
					$self->setTechMail($tech_mail);
				}
				elsif ("whois.fabulous.com" eq $raw_data)
				{
					(my $domain_name,
						my $registrant,
						my $data_create,
						my $data_update,
						my $data_expire,
						my $admin_mail,
						my $tech_mail) = &ParserFabulousCom(@request);
					$self->setDomainName($domain_name);
					$self->setRegistrant($registrant);
					$self->setDataCreate($data_create);
					$self->setDataUpdate($data_update);
					$self->setDataExpire($data_expire);
					$self->setAdminMail($admin_mail);
					$self->setTechMail($tech_mail);
				}
				elsif ("whois.register.com" eq $raw_data)
				{
					(my $domain_name,
						my $registrant,
						my $data_create,
						my $data_update,
						my $data_expire,
						my $admin_mail,
						my $tech_mail) = &ParserRegisterCom(@request);
					$self->setDomainName($domain_name);
					$self->setRegistrant($registrant);
					$self->setDataCreate($data_create);
					$self->setDataUpdate($data_update);
					$self->setDataExpire($data_expire);
					$self->setAdminMail($admin_mail);
					$self->setTechMail($tech_mail);
				}
				elsif ("whois.com.ua" eq $raw_data)
				{	
					(my $domain_name,
						my $registrant,
						my $data_create,
						my $data_update,
						my $data_expire,
						my $admin_mail,
						my $tech_mail) = &ParserComUa(@request);
					$self->setDomainName($domain_name);
					$self->setRegistrant($registrant);
					$self->setDataCreate($data_create);
					$self->setDataUpdate($data_update);
					$self->setDataExpire($data_expire);
					$self->setAdminMail($admin_mail);
					$self->setTechMail($tech_mail);
				}
				elsif ("whois.verisign-grs.com" eq $raw_data)
				{	
					(my $domain_name,
						my $registrant,
						my $data_create,
						my $data_update,
						my $data_expire,
						my $admin_mail,
						my $tech_mail) = &ParserVerisign_grsCom(@request);
					$self->setDomainName($domain_name);
					$self->setRegistrant($registrant);
					$self->setDataCreate($data_create);
					$self->setDataUpdate($data_update);
					$self->setDataExpire($data_expire);
					$self->setAdminMail($admin_mail);
					$self->setTechMail($tech_mail);
				}
				elsif ("whois.afilias.info" eq $raw_data)
				{	
					(my $domain_name,
						my $registrant,
						my $data_create,
						my $data_update,
						my $data_expire,
						my $admin_mail,
						my $tech_mail) = &ParserPublicinterestregistryNet(@request);
					$self->setDomainName($domain_name);
					$self->setRegistrant($registrant);
					$self->setDataCreate($data_create);
					$self->setDataUpdate($data_update);
					$self->setDataExpire($data_expire);
					$self->setAdminMail($admin_mail);
					$self->setTechMail($tech_mail);
				}
				elsif ("whois.neulevel.biz" eq $raw_data)
				{	
					(my $domain_name,
						my $registrant,
						my $data_create,
						my $data_update,
						my $data_expire,
						my $admin_mail,
						my $tech_mail) = &ParserNeulevelBiz(@request);
					$self->setDomainName($domain_name);
					$self->setRegistrant($registrant);
					$self->setDataCreate($data_create);
					$self->setDataUpdate($data_update);
					$self->setDataExpire($data_expire);
					$self->setAdminMail($admin_mail);
					$self->setTechMail($tech_mail);
				}
				elsif ("whois.wildwestdomains.com" eq $raw_data)
				{	
					(my $domain_name,
						my $registrant,
						my $data_create,
						my $data_update,
						my $data_expire,
						my $admin_mail,
						my $tech_mail) = &ParserWildwestdomainsCom(@request);
					$self->setDomainName($domain_name);
					$self->setRegistrant($registrant);
					$self->setDataCreate($data_create);
					$self->setDataUpdate($data_update);
					$self->setDataExpire($data_expire);
					$self->setAdminMail($admin_mail);
					$self->setTechMail($tech_mail);
				}
				elsif("whois.nic.uk" eq $raw_data)
				{
                    (my $domain_name,
                        my $registrant,
                        my $data_create,
                        my $data_update,
                        my $data_expire,
                        my $admin_mail,
                        my $tech_mail) = &ParserNicUk(@request);
					$self->setDomainName($domain_name);
                    $self->setRegistrant($registrant);
                    $self->setDataCreate($data_create);
                    $self->setDataUpdate($data_update);
                    $self->setDataExpire($data_expire);
                    $self->setAdminMail($admin_mail);
                    $self->setTechMail($tech_mail);
				}
				elsif("whois.denic.de" eq $raw_data)
				{
					(my $domain_name,
                        my $registrant,
                        my $data_create,
                        my $data_update,
                        my $data_expire,
                        my $admin_mail,
                        my $tech_mail) = &ParserDenicDe(@request);
					$self->setDomainName($domain_name);
                    $self->setRegistrant($registrant);
                    $self->setDataCreate($data_create);
                    $self->setDataUpdate($data_update);
                    $self->setDataExpire($data_expire);
                    $self->setAdminMail($admin_mail);
                    $self->setTechMail($tech_mail);
				}
				elsif("whois.nic.us" eq $raw_data)
				{
					(my $domain_name,
                        my $registrant,
                        my $data_create,
                        my $data_update,
                        my $data_expire,
                        my $admin_mail,
                        my $tech_mail) = &ParserNicUs(@request);
					$self->setDomainName($domain_name);
                    $self->setRegistrant($registrant);
                    $self->setDataCreate($data_create);
                    $self->setDataUpdate($data_update);
                    $self->setDataExpire($data_expire);
                    $self->setAdminMail($admin_mail);
                    $self->setTechMail($tech_mail);
				}
				elsif("whois.cira.ca" eq $raw_data)
				{
					(my $domain_name,
                        my $registrant,
                        my $data_create,
                        my $data_update,
                        my $data_expire,
                        my $admin_mail,
                        my $tech_mail) = &ParserCiraCa(@request);
					$self->setDomainName($domain_name);
                    $self->setRegistrant($registrant);
                    $self->setDataCreate($data_create);
                    $self->setDataUpdate($data_update);
                    $self->setDataExpire($data_expire);
                    $self->setAdminMail($admin_mail);
                    $self->setTechMail($tech_mail);
				}
				else
				{
					print ("$raw_data is not a match.\n");
					# TODO: Make exit from parser with error and record them to the log
					(my $domain_name,
                        my $registrant,
                        my $data_create,
                        my $data_update,
                        my $data_expire,
                        my $admin_mail,
                        my $tech_mail) = &ParserDontMatch(@request);
                    $self->setDomainName($domain_name);
                    $self->setRegistrant($registrant);
                    $self->setDataCreate($data_create);
                    $self->setDataUpdate($data_update);
                    $self->setDataExpire($data_expire);
                    $self->setAdminMail($admin_mail);
                    $self->setTechMail($tech_mail);
				}
			}
		}
	}
}

# Parser for whois.publicinterestregistry.net
sub ParserPublicinterestregistryNet(@)
{
	my @request = @_;
	my $domain_name = undef;
	my $registrant = undef;
	my $data_create = undef;
	my $data_update = undef;
	my $data_expire = undef;
	my $admin_mail = undef;
	my $tech_mail = undef;
	
	foreach my $request(@request)
	{
		# Domain
		if ($request =~ m/Domain Name:(\D*)/ig)
		{
			my $raw_data = lc($1);
			$domain_name = $raw_data;
		}
		# Registrant
		if ($request =~ m/Registrant Organization:(\D*)\s+/ig)
		{
			my $raw_data = $1;
			$registrant = $raw_data;
		}
		# Create date
		if ($request =~ m/Created\s+On:(\d*\S*\D*)\ /ig)
		{
			my $raw_data = $1;
			$raw_data = DdMonYearToStandart($raw_data);
			$data_create = $raw_data;
		}
		# Update date
		if ($request =~ m/Last\sUpdated\sOn:(\d*\S*\D*)\ /ig)
		{
			my $raw_data = $1;
			$raw_data = DdMonYearToStandart($raw_data);
			$data_update = $raw_data;
		}
		# Expire date
		if ($request =~ m/Expiration\sDate:(\d*\S*\D*)\ /ig)
		{
			my $raw_data = $1;
			$raw_data = DdMonYearToStandart($raw_data);
			$data_expire = $raw_data;
		}
		# Admin mail
		if ($request =~ m/Admin\sEmail:(\D*)\n/ig)
		{
			my $raw_data = $1;
			$admin_mail = $raw_data;
		}
		# Tech mail
		if ($request =~ m/Tech\sEmail:(\D*)\n/ig)
		{
			my $raw_data = $1;
			$tech_mail = $raw_data;
		}
		# You can add some data here
	}
	if (!$domain_name || ($domain_name eq "")) {$domain_name = "n/a"}; 
	if (!$registrant || $registrant eq "") {$registrant = "n/a"};
	if (!$data_create || $data_create eq "") {$data_create = "n/a"};
	if (!$data_update || $data_update eq "") {$data_update = "n/a"};
	if (!$data_expire || $data_expire eq "") {$data_expire = "n/a"};
	if (!$admin_mail || $admin_mail eq "") {$admin_mail = "n/a"};
	if (!$tech_mail || $tech_mail eq "") {$tech_mail = "n/a"};
	
	return ($domain_name,$registrant,$data_create,
			$data_update,$data_expire,$admin_mail,$tech_mail);
}
# Parser for whois.tucows.com
sub ParserTucowsCom(@)
{
	my @request = @_;
	my $domain_name = undef;
	my $registrant = undef;
	my $data_create = undef;
	my $data_update = undef;
	my $data_expire = undef;
	my $admin_mail = undef;
	my $tech_mail = undef;
	
	foreach my $request(@request)
	{
		# Domain
		if ($request =~ m/Domain\s+name:(\D*)/ig)
		{
			my $raw_data = lc($1);
			$domain_name = $raw_data;
		}
		# Registrant
		if ($request =~ m/Registrant:(\D*)\n/ig)
		{
			my $raw_data = $1;
			$registrant = $raw_data;
		}
		# Create date
		if ($request =~ m/Record created on (\d*\S*\D*)\ \.\ /ig)
		{
			my $raw_data = $1;
			$raw_data = DdMonYearToStandart($raw_data);
			$data_create = $raw_data;
		}
		# Update date
		if ($request =~ m/Record last updated on (\d*\S*\D*)\ \.\ /ig)
		{
			my $raw_data = $1;
			$raw_data = DdMonYearToStandart($raw_data);
			$data_update = $raw_data;
		}
		# Expire date
		if ($request =~ m/Record expires on (\d*\S*\D*)\ \.\ /ig)
		{
			my $raw_data = $1;
			$raw_data = DdMonYearToStandart($raw_data);
			$data_expire = $raw_data;
		}
		# Admin mail
		if ($request =~ m/Administrative Contact:(\D*)\n/ig)
		{
			my $raw_data = $1;
			$admin_mail = $raw_data;
		}
		# Tech mail
		if ($request =~ m/Technical Contact:(\D*)\n/ig)
		{
			my $raw_data = $1;
			$tech_mail = $raw_data;
		}
		# You can add some data here
	}
	if (!$domain_name || ($domain_name eq "")) {$domain_name = "n/a"}; 
	if (!$registrant || $registrant eq "") {$registrant = "n/a"};
	if (!$data_create || $data_create eq "") {$data_create = "n/a"};
	if (!$data_update || $data_update eq "") {$data_update = "n/a"};
	if (!$data_expire || $data_expire eq "") {$data_expire = "n/a"};
	if (!$admin_mail || $admin_mail eq "") {$admin_mail = "n/a"};
	if (!$tech_mail || $tech_mail eq "") {$tech_mail = "n/a"};
	
	return ($domain_name,$registrant,$data_create,
			$data_update,$data_expire,$admin_mail,$tech_mail);
}
#Parser for whois.markmonitor.com
sub ParserMarkmonitorCom(@)
{
	my @request = @_;
	my $domain_name = undef;
	my $registrant = undef;
	my $data_create = undef;
	my $data_update = undef;
	my $data_expire = undef;
	my $admin_mail = undef;
	my $tech_mail = undef;
	
	foreach my $request(@request)
	{
		# Domain
		if ($request =~ m/Domain Name:(\D*)\n/ig)
		{
			my $raw_data = lc($1);
			$domain_name = $raw_data;
		}
		# Registrant
		if ($request =~ m/Registrant:(\D*)\n/ig)
		{
			my $raw_data = $1;
			$registrant = $raw_data;
		}
		# Create date
		if ($request =~ m/Created on..............: (\d*\S*\D*)\ \.\ /ig)
		{
			my $raw_data = $1;
			$raw_data = YearMonDdToStandart($raw_data);
			$data_create = $raw_data;
		}
		# Update date
		if ($request =~ m/Record last updated on..: (\d*\S*\D*)\ \.\ /ig)
		{
			my $raw_data = $1;
			$raw_data = YearMonDdToStandart($raw_data);
			$data_update = $raw_data;
		}
		# Expire date
		if ($request =~ m/Expires on..............: (\d*\S*\D*)\ \.\ /ig)
		{
			my $raw_data = $1;
			$raw_data = YearMonDdToStandart($raw_data);
			$data_expire = $raw_data;
		}
		# Admin mail
		if ($request =~ m/Administrative Contact:(\D*)\n/ig)
		{
			my $raw_data = $1;
			$admin_mail = $raw_data;
		}
		# Tech mail
		if ($request =~ m/Technical Contact, Zone Contact:(\D*)\n/ig)
		{
			my $raw_data = $1;
			$tech_mail = $raw_data;
		}
		# You can add some data here
	}
	if (!$domain_name || ($domain_name eq "")) {$domain_name = "n/a"}; 
	if (!$registrant || $registrant eq "") {$registrant = "n/a"};
	if (!$data_create || $data_create eq "") {$data_create = "n/a"};
	if (!$data_update || $data_update eq "") {$data_update = "n/a"};
	if (!$data_expire || $data_expire eq "") {$data_expire = "n/a"};
	if (!$admin_mail || $admin_mail eq "") {$admin_mail = "n/a"};
	if (!$tech_mail || $tech_mail eq "") {$tech_mail = "n/a"};
	
	return ($domain_name,$registrant,$data_create,
			$data_update,$data_expire,$admin_mail,$tech_mail);
}
#Parser for whois.safenames.net
sub ParserSafenamesNet(@)
{
	my @request = @_;
	my $domain_name = undef;
	my $registrant = undef;
	my $data_create = undef;
	my $data_update = undef;
	my $data_expire = undef;
	my $admin_mail = undef;
	my $tech_mail = undef;
	
	foreach my $request(@request)
	{
		# Domain
		if ($request =~ m/Domain Name: (\D*)\n/ig)
		{
			my $raw_data = lc($1);
			$domain_name = $raw_data;
		}
		# Registrant
		if ($request =~ m/\[REGISTRANT\](\D*)\n/ig)
		{
			my $raw_data = $1;
			$registrant = $raw_data;
		}
		# Create date
		if ($request =~ m/Created on..............: (\d*\S*\D*)\ \.\ /ig)
		{
			my $raw_data = $1;
			$raw_data = YearMonDdToStandart($raw_data);
			$data_create = $raw_data;
		}
		# Update date
		if ($request =~ m/Record last updated on..: (\d*\S*\D*)\ \.\ /ig)
		{
			my $raw_data = $1;
			$raw_data = YearMonDdToStandart($raw_data);
			$data_update = $raw_data;
		}
		# Expire date
		if ($request =~ m/Expires on..............: (\d*\S*\D*)\ \.\ /ig)
		{
			my $raw_data = $1;
			$raw_data = YearMonDdToStandart($raw_data);
			$data_expire = $raw_data;
		}
		# Admin mail
		if ($request =~ m/\[ADMIN\](\D*)\n/ig)
		{
			my $raw_data = $1;
			$admin_mail = $raw_data;
		}
		# Tech mail
		if ($request =~ m/\[TECHNICAL\](\D*)\n/ig)
		{
			my $raw_data = $1;
			$tech_mail = $raw_data;
		}
		# You can add some data here
	}
	if (!$domain_name || ($domain_name eq "")) {$domain_name = "n/a"}; 
	if (!$registrant || $registrant eq "") {$registrant = "n/a"};
	if (!$data_create || $data_create eq "") {$data_create = "n/a"};
	if (!$data_update || $data_update eq "") {$data_update = "n/a"};
	if (!$data_expire || $data_expire eq "") {$data_expire = "n/a"};
	if (!$admin_mail || $admin_mail eq "") {$admin_mail = "n/a"};
	if (!$tech_mail || $tech_mail eq "") {$tech_mail = "n/a"};
	
	return ($domain_name,$registrant,$data_create,
			$data_update,$data_expire,$admin_mail,$tech_mail);
}
# Parser whois.networksolutions.com
sub ParserNetworksolutionsCom(@)
{
	my @request = @_;
	my $domain_name = undef;
	my $registrant = undef;
	my $data_create = undef;
	my $data_update = undef;
	my $data_expire = undef;
	my $admin_mail = undef;
	my $tech_mail = undef;
	
	foreach my $request(@request)
	{
		# Domain
		if ($request =~ m/Domain Name: (\D*)/ig)
		{
			my $raw_data = lc($1);
			$domain_name = $raw_data;
		}
		# Registrant
		if ($request =~ m/Registrant\s+\[\d+\]\:(\D*)\s+/ig)
		{
			my $raw_data = $1;
			$registrant = $raw_data;
		}
		# Create date
		if ($request =~ m/Record created on:\s+(\d*\S*\D*)\ /ig)
		{
			my $raw_data = $1;
			$raw_data = YearMmDd_HhMmSsToStandart($raw_data);
			$data_create = $raw_data;
		}
		# Update date
		if ($request =~ m/Database last updated on:\s+(\d*\S*\D*)\ /ig)
		{
			my $raw_data = $1;
			$raw_data = YearMmDd_HhMmSsToStandart($raw_data);
			$data_update = $raw_data;
		}
		# Expire date
		if ($request =~ m/Domain Expires on:\s+(\d*\S*\D*)\ /ig)
		{
			my $raw_data = $1;
			$raw_data = YearMmDd_HhMmSsToStandart($raw_data);
			$data_expire = $raw_data;
		}
		# Admin mail
		if ($request =~ m/Administrative Contact \[\d+\](\D*)\n/ig)
		{
			my $raw_data = $1;
			$admin_mail = $raw_data;
		}
		# Tech mail
		if ($request =~ m/Technical Contact \[\d+\](\D*)\n/ig)
		{
			my $raw_data = $1;
			$tech_mail = $raw_data;
		}
		# You can add some data here
	}
	if (!$domain_name || ($domain_name eq "")) {$domain_name = "n/a"}; 
	if (!$registrant || $registrant eq "") {$registrant = "n/a"};
	if (!$data_create || $data_create eq "") {$data_create = "n/a"};
	if (!$data_update || $data_update eq "") {$data_update = "n/a"};
	if (!$data_expire || $data_expire eq "") {$data_expire = "n/a"};
	if (!$admin_mail || $admin_mail eq "") {$admin_mail = "n/a"};
	if (!$tech_mail || $tech_mail eq "") {$tech_mail = "n/a"};
	
	return ($domain_name,$registrant,$data_create,
			$data_update,$data_expire,$admin_mail,$tech_mail);
}
# Parser whois.moniker.com
sub ParserMonikerCom(@)
{
	my @request = @_;
	my $domain_name = undef;
	my $registrant = undef;
	my $data_create = undef;
	my $data_update = undef;
	my $data_expire = undef;
	my $admin_mail = undef;
	my $tech_mail = undef;
	
	foreach my $request(@request)
	{
		# Domain
		if ($request =~ m/Domain Name: (\D*)/ig)
		{
			my $raw_data = lc($1);
			$domain_name = $raw_data;
		}
		# Registrant
		if ($request =~ m/Registrant\s+\[\d+\]\:(\D*)\s+/ig)
		{
			my $raw_data = $1;
			$registrant = $raw_data;
		}
		# Create date
		if ($request =~ m/Record created on:\s+(\d*\S*\D*)\s+\ /ig)
		{
			my $raw_data = $1;
			$raw_data = YearMmDd_HhMmSsToStandart($raw_data);
			$data_create = $raw_data;
		}
		# Update date
		if ($request =~ m/Database last updated on:\s+(\d*\S*\D*)\s+\ /ig)
		{
			my $raw_data = $1;
			$raw_data = YearMmDd_HhMmSsToStandart($raw_data);
			$data_update = $raw_data;
		}
		# Expire date
		if ($request =~ m/Domain Expires on:\s+(\d*\S*\D*)\s+\ /ig)
		{
			my $raw_data = $1;
			$raw_data = YearMmDd_HhMmSsToStandart($raw_data);
			$data_expire = $raw_data;
		}
		# Admin mail
		if ($request =~ m/Administrative Contact:(\D*)\n/ig)
		{
			my $raw_data = $1;
			$admin_mail = $raw_data;
		}
		# Tech mail
		if ($request =~ m/Technical Contact:(\D*)\n/ig)
		{
			my $raw_data = $1;
			$tech_mail = $raw_data;
		}
		# You can add some data here
	}
	if (!$domain_name || ($domain_name eq "")) {$domain_name = "n/a"}; 
	if (!$registrant || $registrant eq "") {$registrant = "n/a"};
	if (!$data_create || $data_create eq "") {$data_create = "n/a"};
	if (!$data_update || $data_update eq "") {$data_update = "n/a"};
	if (!$data_expire || $data_expire eq "") {$data_expire = "n/a"};
	if (!$admin_mail || $admin_mail eq "") {$admin_mail = "n/a"};
	if (!$tech_mail || $tech_mail eq "") {$tech_mail = "n/a"};
	
	return ($domain_name,$registrant,$data_create,
			$data_update,$data_expire,$admin_mail,$tech_mail);
}
# Parser whois.publicdomainregistry.com
sub ParserPublicdomainregistryCom(@)
{
	my @request = @_;
	my $domain_name = undef;
	my $registrant = undef;
	my $data_create = undef;
	my $data_update = undef;
	my $data_expire = undef;
	my $admin_mail = undef;
	my $tech_mail = undef;
	
	foreach my $request(@request)
	{
		# Domain
		if ($request =~ m/Domain Name:(\D*)/ig)
		{
			my $raw_data = lc($1);
			$domain_name = $raw_data;
		}
		# Registrant
		if ($request =~ m/Registrant:(\D*)\s+/ig)
		{
			my $raw_data = $1;
			$registrant = $raw_data;
		}
		# Create date
		if ($request =~ m/Creation Date:\s+(\d*\S*\D*)\ /ig)
		{
			my $raw_data = $1;
			$raw_data = DdMonYearToStandart($raw_data);
			$data_create = $raw_data;
		}
		# Update date
		# For thisregistrant thistype of record doesn't exist
		#if ($request =~ m/Database last updated on:\s+(\d*\S*\D*)\ /ig)
		#{
		#	my $raw_data = $1;
		#	$raw_data = DdMonYearToStandart($raw_data);
		#	$data_update = $raw_data;
		#}
		# Expire date
		if ($request =~ m/Expiration Date:\s+(\d*\S*\D*)\ /ig)
		{
			my $raw_data = $1;
			$raw_data = DdMonYearToStandart($raw_data);
			$data_expire = $raw_data;
		}
		# Admin mail
		if ($request =~ m/Administrative Contact:(\D*)\n/ig)
		{
			my $raw_data = $1;
			$admin_mail = $raw_data;
		}
		# Tech mail
		if ($request =~ m/Technical Contact:(\D*)\n/ig)
		{
			my $raw_data = $1;
			$tech_mail = $raw_data;
		}
		# You can add some data here
	}
	if (!$domain_name || ($domain_name eq "")) {$domain_name = "n/a"}; 
	if (!$registrant || $registrant eq "") {$registrant = "n/a"};
	if (!$data_create || $data_create eq "") {$data_create = "n/a"};
	if (!$data_update || $data_update eq "") {$data_update = "n/a"};
	if (!$data_expire || $data_expire eq "") {$data_expire = "n/a"};
	if (!$admin_mail || $admin_mail eq "") {$admin_mail = "n/a"};
	if (!$tech_mail || $tech_mail eq "") {$tech_mail = "n/a"};
	
	return ($domain_name,$registrant,$data_create,
			$data_update,$data_expire,$admin_mail,$tech_mail);
}
# Parser whois.webmasters.com
sub ParserWebmastersCom(@)
{
	my @request = @_;
	my $domain_name = undef;
	my $registrant = undef;
	my $data_create = undef;
	my $data_update = undef;
	my $data_expire = undef;
	my $admin_mail = undef;
	my $tech_mail = undef;
	
	foreach my $request(@request)
	{
		# Domain
		if ($request =~ m/Domain Name: (\D*)/ig)
		{
			my $raw_data = lc($1);
			$domain_name = $raw_data;
		}
		# Registrant
		if ($request =~ m/Registrant:(\D*)\s+/ig)
		{
			my $raw_data = $1;
			$registrant = $raw_data;
		}
		# Create date
		if ($request =~ m/Record created on\s+(\d*\S*\D*)\s+\ /ig)
		{
			my $raw_data = $1;
			$raw_data = DdMonYearToStandart($raw_data);
			$data_create = $raw_data;
		}
		# Update date
		if ($request =~ m/Record updated on\s+(\d*\S*\D*)\s+\ /ig)
		{
			my $raw_data = $1;
			$raw_data = DdMonYearToStandart($raw_data);
			$data_update = $raw_data;
		}
		# Expire date
		if ($request =~ m/Record expires on\s+(\d*\S*\D*)\s+\ /ig)
		{
			my $raw_data = $1;
			$raw_data = DdMonYearToStandart($raw_data);
			$data_expire = $raw_data;
		}
		# Admin mail
		if ($request =~ m/Administrative Contact:(\D*)\n/ig)
		{
			my $raw_data = $1;
			$admin_mail = $raw_data;
		}
		# Tech mail
		if ($request =~ m/Technical Contact:(\D*)\n/ig)
		{
			my $raw_data = $1;
			$tech_mail = $raw_data;
		}
		# You can add some data here
	}
	if (!$domain_name || ($domain_name eq "")) {$domain_name = "n/a"}; 
	if (!$registrant || $registrant eq "") {$registrant = "n/a"};
	if (!$data_create || $data_create eq "") {$data_create = "n/a"};
	if (!$data_update || $data_update eq "") {$data_update = "n/a"};
	if (!$data_expire || $data_expire eq "") {$data_expire = "n/a"};
	if (!$admin_mail || $admin_mail eq "") {$admin_mail = "n/a"};
	if (!$tech_mail || $tech_mail eq "") {$tech_mail = "n/a"};
	
	return ($domain_name,$registrant,$data_create,
			$data_update,$data_expire,$admin_mail,$tech_mail);
}
# Parser whois.godaddy.com
sub ParserGodaddyCom(@)
{
	my @request = @_;
	my $domain_name = undef;
	my $registrant = undef;
	my $data_create = undef;
	my $data_update = undef;
	my $data_expire = undef;
	my $admin_mail = undef;
	my $tech_mail = undef;
	
	foreach my $request(@request)
	{
		# Domain
		if ($request =~ m/Domain Name: (\D*)/ig)
		{
			my $raw_data = lc($1);
			$domain_name = $raw_data;
		}
		# Registrant
		if ($request =~ m/Registrant:(\D*)\s+\n/ig)
		{
			my $raw_data = $1;
			$registrant = $raw_data;
		}
		# Create date
		if ($request =~ m/Creation Date:\s+(\d*\S*\D*)\s+\ /ig)
		{
			my $raw_data = $1;
			$raw_data = DdMonYyToStandart($raw_data);
			$data_create = $raw_data;
		}
		# Update date
		if ($request =~ m/Last Updated on:\s+(\d*\S*\D*)\s+\ /ig)
		{
			my $raw_data = $1;
			$raw_data = DdMonYyToStandart($raw_data);
			$data_update = $raw_data;
		}
		# Expire date
		if ($request =~ m/Expires on:\s+(\d*\S*\D*)\s+\ /ig)
		{
			my $raw_data = $1;
			$raw_data = DdMonYyToStandart($raw_data);
			$data_expire = $raw_data;
		}
		# Admin mail
		if ($request =~ m/Administrative Contact:(\D*)\s+\n/ig)
		{
			my $raw_data = $1;
			$admin_mail = $raw_data;
		}
		# Tech mail
		if ($request =~ m/Technical Contact:(\D*)\s+\n/ig)
		{
			my $raw_data = $1;
			$tech_mail = $raw_data;
		}
		# You can add some data here
	}
	if (!$domain_name || ($domain_name eq "")) {$domain_name = "n/a"}; 
	if (!$registrant || $registrant eq "") {$registrant = "n/a"};
	if (!$data_create || $data_create eq "") {$data_create = "n/a"};
	if (!$data_update || $data_update eq "") {$data_update = "n/a"};
	if (!$data_expire || $data_expire eq "") {$data_expire = "n/a"};
	if (!$admin_mail || $admin_mail eq "") {$admin_mail = "n/a"};
	if (!$tech_mail || $tech_mail eq "") {$tech_mail = "n/a"};
	
	return ($domain_name,$registrant,$data_create,
			$data_update,$data_expire,$admin_mail,$tech_mail);
}
# Parser whois.fabulous.com
sub ParserFabulousCom(@)
{
	my @request = @_;
	my $domain_name = undef;
	my $registrant = undef;
	my $data_create = undef;
	my $data_update = undef;
	my $data_expire = undef;
	my $admin_mail = undef;
	my $tech_mail = undef;
	
	foreach my $request(@request)
	{
		# Domain
		if ($request =~ m/Domain Name: (\D*)/ig)
		{
			my $raw_data = lc($1);
			$domain_name = $raw_data;
		}
		# Registrant
		if ($request =~ m/Registrant:(\D*)\s+\n/ig)
		{
			my $raw_data = $1;
			$registrant = $raw_data;
		}
		# Create date
		if ($request =~ m/Record created on:\s+(\d*\S*\D*)\s+\ /ig)
		{
			my $raw_data = $1;
			$raw_data = YearMonDdToStandart($raw_data);
			$data_create = $raw_data;
		}
		# Update date
		if ($request =~ m/Record modified on:\s+(\d*\S*\D*)\s+\ /ig)
		{
			my $raw_data = $1;
			$raw_data = YearMonDdToStandart($raw_data);
			$data_update = $raw_data;
		}
		# Expire date
		if ($request =~ m/Record expires on:\s+(\d*\S*\D*)\ \s+UTC/ig)
		{
			my $raw_data = $1;
			$raw_data = YearMonDdToStandart($raw_data);
			$data_expire = $raw_data;
		}
		# Admin mail
		if ($request =~ m/Administrative contact:(\D*)\s+\n/ig)
		{
			my $raw_data = $1;
			$admin_mail = $raw_data;
		}
		# Tech mail
		if ($request =~ m/Technical contact:(\D*)\s+\n/ig)
		{
			my $raw_data = $1;
			$tech_mail = $raw_data;
		}
		# You can add some data here
	}
	if (!$domain_name || ($domain_name eq "")) {$domain_name = "n/a"}; 
	if (!$registrant || $registrant eq "") {$registrant = "n/a"};
	if (!$data_create || $data_create eq "") {$data_create = "n/a"};
	if (!$data_update || $data_update eq "") {$data_update = "n/a"};
	if (!$data_expire || $data_expire eq "") {$data_expire = "n/a"};
	if (!$admin_mail || $admin_mail eq "") {$admin_mail = "n/a"};
	if (!$tech_mail || $tech_mail eq "") {$tech_mail = "n/a"};
	
	return ($domain_name,$registrant,$data_create,
			$data_update,$data_expire,$admin_mail,$tech_mail);
} 
# Parser whois.verisign-grs.com
sub ParserVerisign_grsCom(@)
{
	my @request = @_;
	my $domain_name = undef;
	my $registrant = undef;
	my $data_create = undef;
	my $data_update = undef;
	my $data_expire = undef;
	my $admin_mail = undef;
	my $tech_mail = undef;
	
	foreach my $request(@request)
	{
		# Domain
		if ($request =~ m/Domain Name: (\D*)/ig)
		{
			my $raw_data = lc($1);
			$domain_name = $raw_data;
		}
		# Registrant
		if ($request =~ m/Registrant:(\D*)\s+\n/ig)
		{
			my $raw_data = $1;
			$registrant = $raw_data;
		}
		# Create date
		if ($request =~ m/Creation Date:\s+(\d*\S*\D*)\s+/ig)
		{
			my $raw_data = $1;
			$raw_data = DdMonYearToStandart($raw_data);
			$data_create = $raw_data;
		}
		# Update date
		if ($request =~ m/Updated Date:\s+(\d*\S*\D*)\s+/ig)
		{
			my $raw_data = $1;
			$raw_data = DdMonYearToStandart($raw_data);
			$data_update = $raw_data;
		}
		# Expire date
		if ($request =~ m/Expiration Date:\s+(\d*\S*\D*)\s+/ig)
		{
			my $raw_data = $1;
			$raw_data = DdMonYearToStandart($raw_data);
			$data_expire = $raw_data;
		}
		# Admin mail
		if ($request =~ m/Administrative contact:(\D*)\s+\n/ig)
		{
			my $raw_data = $1;
			$admin_mail = $raw_data;
		}
		# Tech mail
		if ($request =~ m/Technical contact:(\D*)\s+\n/ig)
		{
			my $raw_data = $1;
			$tech_mail = $raw_data;
		}
		# You can add some data here
	}
	if (!$domain_name || ($domain_name eq "")) {$domain_name = "n/a"}; 
	if (!$registrant || $registrant eq "") {$registrant = "n/a"};
	if (!$data_create || $data_create eq "") {$data_create = "n/a"};
	if (!$data_update || $data_update eq "") {$data_update = "n/a"};
	if (!$data_expire || $data_expire eq "") {$data_expire = "n/a"};
	if (!$admin_mail || $admin_mail eq "") {$admin_mail = "n/a"};
	if (!$tech_mail || $tech_mail eq "") {$tech_mail = "n/a"};
	
	return ($domain_name,$registrant,$data_create,
			$data_update,$data_expire,$admin_mail,$tech_mail);
}
# Parser whois.register.com
sub ParserRegisterCom(@)
{
	my @request = @_;
	my $domain_name = undef;
	my $registrant = undef;
	my $data_create = undef;
	my $data_update = undef;
	my $data_expire = undef;
	my $admin_mail = undef;
	my $tech_mail = undef;
	
	foreach my $request(@request)
	{
		# Domain
		if ($request =~ m/Domain Name: (\D*)/ig)
		{
			my $raw_data = lc($1);
			$domain_name = $raw_data;
		}
		# Registrant
		if ($request =~ m/Registrant:(\D*)\s+\n/ig)
		{
			my $raw_data = $1;
			$registrant = $raw_data;
		}
		# Create date
		if ($request =~ m/Created on..............:\s+(\d*\S*\D*)\ \s+\ /ig)
		{
			my $raw_data = $1;
			$raw_data = YearMonDdToStandart($raw_data);
			$data_create = $raw_data;
		}
		# Update date
		if ($request =~ m/Record last updated on..:\s+(\d*\S*\D*)\ \s+\ /ig)
		{
			my $raw_data = $1;
			$raw_data = YearMonDdToStandart($raw_data);
			$data_update = $raw_data;
		}
		# Expire date
		if ($request =~ m/Expires on..............:\s+(\d*\S*\D*)\ \s+UTC/ig)
		{
			my $raw_data = $1;
			$raw_data = YearMonDdToStandart($raw_data);
			$data_expire = $raw_data;
		}
		# Admin mail
		if ($request =~ m/Administrative Contact, Technical Contact, Zone Contact:(\D*)\s+\n/ig)
		{
			my $raw_data = $1;
			$admin_mail = $raw_data;
			$tech_mail = $admin_mail;
		}
	}
	if (!$domain_name || ($domain_name eq "")) {$domain_name = "n/a"}; 
	if (!$registrant || $registrant eq "") {$registrant = "n/a"};
	if (!$data_create || $data_create eq "") {$data_create = "n/a"};
	if (!$data_update || $data_update eq "") {$data_update = "n/a"};
	if (!$data_expire || $data_expire eq "") {$data_expire = "n/a"};
	if (!$admin_mail || $admin_mail eq "") {$admin_mail = "n/a"};
	if (!$tech_mail || $tech_mail eq "") {$tech_mail = "n/a"};
	
	return ($domain_name,$registrant,$data_create,
			$data_update,$data_expire,$admin_mail,$tech_mail);
}
# Parser whois.com.ua
sub ParserComUa(@)
{
	my @request = @_;
	my $domain_name = undef;
	my $registrant = undef;
	my $data_create = undef;
	my $data_update = undef;
	my $data_expire = undef;
	my $admin_mail = undef;
	my $tech_mail = undef;
	
	foreach my $request(@request)
	{
		# Domain
		if ($request =~ m/domain:\s+(\D*)/ig)
		{
			my $raw_data = lc($1);
			$domain_name = $raw_data;
		}
		# Registrant
		if ($request =~ m/remark:\s+(\D*)\s+\n/ig)
		{
			my $raw_data = $1;
			$registrant .= $raw_data ." ";
		}
		# Create date
		if ($request =~ m/changed:\s+SONC-UANIC\s+(\d*)\s+/ig)
		{
			my $raw_data = $1;
			$raw_data = YearMmDdHhMmSsToStandart($raw_data);
			$data_create = $raw_data;
		}
		# Update date
		if ($request =~ m/Record last updated on..:\s+(\d*\S*\D*)\ \s+\ /ig)
		{
			my $raw_data = $1;
			$raw_data = YearMmDdHhMmSsToStandart($raw_data);
			$data_update = $raw_data;
		}
		# Expire date
		if ($request =~ m/status:\s+OK-UNTIL\s+(\d*)\s+/ig)
		{
			my $raw_data = $1;
			$raw_data = YearMmDdHhMmSsToStandart($raw_data);
			$data_expire = $raw_data;
		}
		# Admin mail
		if ($request =~ m/Administrative Contact, Technical Contact, Zone Contact:(\D*)\s+\n/ig)
		{
			my $raw_data = $1;
			$admin_mail = $raw_data;
			$tech_mail = $admin_mail;
		}
	}
	if (!$domain_name || ($domain_name eq "")) {$domain_name = "n/a"}; 
	if (!$registrant || $registrant eq "") {$registrant = "n/a"};
	if (!$data_create || $data_create eq "") {$data_create = "n/a"};
	if (!$data_update || $data_update eq "") {$data_update = "n/a"};
	if (!$data_expire || $data_expire eq "") {$data_expire = "n/a"};
	if (!$admin_mail || $admin_mail eq "") {$admin_mail = "n/a"};
	if (!$tech_mail || $tech_mail eq "") {$tech_mail = "n/a"};
	
	return ($domain_name,$registrant,$data_create,
			$data_update,$data_expire,$admin_mail,$tech_mail);
}
# Parser whois.neulevel.biz
sub ParserNeulevelBiz(@)
{
	my @request = @_;
	my $domain_name = undef;
	my $registrant = undef;
	my $data_create = undef;
	my $data_update = undef;
	my $data_expire = undef;
	my $admin_mail = undef;
	my $tech_mail = undef;
	
	foreach my $request(@request)
	{
		# Domain
		if ($request =~ m/Domain Name:\s+(\D*)/ig)
		{
			my $raw_data = lc($1);
			$domain_name = $raw_data;
		}
		# Registrant
		if ($request =~ m/Registrant Name:\s+(\D*)\s+\n/ig)
		{
			my $raw_data = $1;
			$registrant .= $raw_data ." ";
		}
		# Create date
		if ($request =~ m/Domain Registration Date:\s*([\d*\s\D*]*)\s*\n/ig)
		{
			my $raw_data = $1;
			$raw_data = Wd_Mon_Dd_HhMmSs_GMT_YearToStandart($raw_data);
			$data_create = $raw_data;
		}
		# Update date
		if ($request =~ m/Domain Last Updated Date:\s+([\d*\s\D*]*)\s*\n/ig)
		{
			my $raw_data = $1;
			$raw_data = Wd_Mon_Dd_HhMmSs_GMT_YearToStandart($raw_data);
			$data_update = $raw_data;
		}
		# Expire date
		if ($request =~ m/Domain Expiration Date:\s+([\d*\s*\D*]*)\s*\n/ig)
		{
			my $raw_data = $1;
			$raw_data = Wd_Mon_Dd_HhMmSs_GMT_YearToStandart($raw_data);
			$data_expire = $raw_data;
		}
		# Admin mail
		if ($request =~ m/Administrative Contact Email:\s+(\D*)\s+\n/ig)
		{
			my $raw_data = $1;
			$admin_mail = $raw_data;
			$tech_mail = $admin_mail;
		}
		# Tech mail
		if ($request =~ m/Technical Contact Email:\s+(\D*)\s+\n/ig)
		{
			my $raw_data = $1;
			$tech_mail = $raw_data;
		}
		# You can add some data here
	}
	if (!$domain_name || ($domain_name eq "")) {$domain_name = "n/a"}; 
	if (!$registrant || $registrant eq "") {$registrant = "n/a"};
	if (!$data_create || $data_create eq "") {$data_create = "n/a"};
	if (!$data_update || $data_update eq "") {$data_update = "n/a"};
	if (!$data_expire || $data_expire eq "") {$data_expire = "n/a"};
	if (!$admin_mail || $admin_mail eq "") {$admin_mail = "n/a"};
	if (!$tech_mail || $tech_mail eq "") {$tech_mail = "n/a"};
	
	return ($domain_name,$registrant,$data_create,
			$data_update,$data_expire,$admin_mail,$tech_mail);
}
# Parser whois.wildwestdomains.com
sub ParserWildwestdomainsCom(@)
{
	my @request = @_;
	my $domain_name = undef;
	my $registrant = undef;
	my $data_create = undef;
	my $data_update = undef;
	my $data_expire = undef;
	my $admin_mail = undef;
	my $tech_mail = undef;
	
	foreach my $request(@request)
	{
		# Domain
		if ($request =~ m/Domain Name:\s+(\D*)/ig)
		{
			my $raw_data = lc($1);
			$domain_name = $raw_data;
		}
		# Registrant
		if ($request =~ m/Registrant Name:\s+(\D*)\s+\n/ig)
		{
			my $raw_data = $1;
			$registrant .= $raw_data ." ";
		}
		# Create date
		if ($request =~ m/Created on:\s+(\d*\S*\D*)\ \s+\ /ig)
		{
			my $raw_data = $1;
			$raw_data = YearMonDdToStandart($raw_data);
			$data_create = $raw_data;
		}
		# Update date
		if ($request =~ m/Last Updated on:\s+(\d*\S*\D*)\ \s+\ /ig)
		{
			my $raw_data = $1;
			$raw_data = YearMonDdToStandart($raw_data);
			$data_update = $raw_data;
		}
		# Expire date
		if ($request =~ m/Expires on:\s+(\d*\S*\D*)\ \s+UTC/ig)
		{
			my $raw_data = $1;
			$raw_data = YearMonDdToStandart($raw_data);
			$data_expire = $raw_data;
		}
		# Admin mail
		if ($request =~ m/Administrative Contact:\s+(\D*)\s+\n/ig)
		{
			my $raw_data = $1;
			$admin_mail = $raw_data;
			$tech_mail = $admin_mail;
		}
		# Tech mail
		if ($request =~ m/Technical Contact:\s+(\D*)\s+\n/ig)
		{
			my $raw_data = $1;
			$tech_mail = $raw_data;
		}
		# You can add some data here
	}
	if (!$domain_name || ($domain_name eq "")) {$domain_name = "n/a"}; 
	if (!$registrant || $registrant eq "") {$registrant = "n/a"};
	if (!$data_create || $data_create eq "") {$data_create = "n/a"};
	if (!$data_update || $data_update eq "") {$data_update = "n/a"};
	if (!$data_expire || $data_expire eq "") {$data_expire = "n/a"};
	if (!$admin_mail || $admin_mail eq "") {$admin_mail = "n/a"};
	if (!$tech_mail || $tech_mail eq "") {$tech_mail = "n/a"};
	
	return ($domain_name,$registrant,$data_create,
			$data_update,$data_expire,$admin_mail,$tech_mail);
}
# Parser whois.nic.uk
sub ParserNicUk(@)
{
	my @request = @_;
        my $domain_name = undef;
        my $registrant = undef;
        my $data_create = undef;
        my $data_update = undef;
        my $data_expire = undef;
        my $admin_mail = undef;
        my $tech_mail = undef;
	
	my $domain_name_present = "";

	foreach my $request(@request)
        {
		if($domain_name_present eq 'true')
                {
                        $request =~ /^\s*(\D*)/igx;
			my $raw_data = $1;
                        $domain_name = $raw_data;
                        $domain_name_present = 'false';
                }
                # Domain
                if ($request =~ m/Domain name:\s+(\D*)/ig)
                {
              		$domain_name_present = 'true';
                }

                # Registrant
                if ($request =~ m/Registrant:\s+(\D*)\s+\n/ig)
                {
                        my $raw_data = $1;
                        $registrant .= $raw_data ." ";
                }
                # Create date
                if ($request =~ m/Registered on:\s+([\d*\S*\D*]*)\s+\n/ig)
                {
                        my $raw_data = $1;
                        $raw_data = DdMonYearToStandart($raw_data);
                        $data_create = $raw_data;
                }
                # Update date
                if ($request =~ m/Last updated:\s+(\d*\S*\D*)\s+\n/ig)
                {
                        my $raw_data = $1;
                        $raw_data = DdMonYearToStandart($raw_data);
                        $data_update = $raw_data;
                }
                # Expire date
                if ($request =~ m/Renewal date:\s+(\d*\S*\D*)\s+\n/ig)
                {
                        my $raw_data = $1;
                        $raw_data = DdMonYearToStandart($raw_data);
                        $data_expire = $raw_data;
                }
                # Admin mail
                if ($request =~ m/Administrative Contact:\s+(\D*)\s+\n/ig)
                {
                        my $raw_data = $1;
                        $admin_mail = $raw_data;
                        $tech_mail = $admin_mail;
                }
                # Tech mail
                if ($request =~ m/Technical Contact:\s+(\D*)\s+\n/ig)
                {
                        my $raw_data = $1;
                        $tech_mail = $raw_data;
                }
                # You can add some data here
        }

	if (!$domain_name || ($domain_name eq "")) {$domain_name = "n/a"};
        if (!$registrant || $registrant eq "") {$registrant = "n/a"};
        if (!$data_create || $data_create eq "") {$data_create = "n/a"};
        if (!$data_update || $data_update eq "") {$data_update = "n/a"};
        if (!$data_expire || $data_expire eq "") {$data_expire = "n/a"};
        if (!$admin_mail || $admin_mail eq "") {$admin_mail = "n/a"};
        if (!$tech_mail || $tech_mail eq "") {$tech_mail = "n/a"};

        return ($domain_name,$registrant,$data_create,
                        $data_update,$data_expire,$admin_mail,$tech_mail);
}
# Parser for whois.nic.us
sub ParserNicUs(@)
{
	my @request = @_;
        my $domain_name = undef;
        my $registrant = undef;
        my $data_create = undef;
        my $data_update = undef;
        my $data_expire = undef;
        my $admin_mail = undef;
        my $tech_mail = undef;
	
	foreach my $request(@request)
        {
                # Domain
                if ($request =~ m/Domain name:\s+(\D*)/ig)
                {
                        my $raw_data = lc($1);
                        $domain_name = $raw_data;
                }
                # Registrant
                if ($request =~ m/Registrant Name:\s+(\D*)\s+\n/ig)
                {
                        my $raw_data = $1;
                        $registrant .= $raw_data ." ";
                }
                # Create date
                if ($request =~ m/Domain Registration Date:\s+([\d*\s*\D*]*)\s*\n/ig)
                {
                        my $raw_data = $1;
                        $raw_data = Wd_Mon_Dd_HhMmSs_GMT_YearToStandart($raw_data);
                        $data_create = $raw_data;
                }
                # Update date
                if ($request =~ m/Domain Last Updated Date:\s+([\d*\s*\D*]*)\s*\n/ig)
                {
                        my $raw_data = $1;
                        $raw_data = Wd_Mon_Dd_HhMmSs_GMT_YearToStandart($raw_data);
                        $data_update = $raw_data;
                }
                # Expire date
                if ($request =~ m/Domain Expiration Date:\s+([\d*\s*\D*]*)\s*\n/ig)
                {
                        my $raw_data = $1;
                        $raw_data = Wd_Mon_Dd_HhMmSs_GMT_YearToStandart($raw_data);
                        $data_expire = $raw_data;
                }
                # Admin mail
                if ($request =~ m/Administrative Contact:\s+(\D*)\s+\n/ig)
                {
                        my $raw_data = $1;
                        $admin_mail = $raw_data;
                        $tech_mail = $admin_mail;
                }
                # Tech mail
                if ($request =~ m/Technical Contact:\s+(\D*)\s+\n/ig)
                {
                        my $raw_data = $1;
                        $tech_mail = $raw_data;
                }
                # You can add some data here
        }
	
	if (!$domain_name || ($domain_name eq "")) {$domain_name = "n/a"};
        if (!$registrant || $registrant eq "") {$registrant = "n/a"};
        if (!$data_create || $data_create eq "") {$data_create = "n/a"};
        if (!$data_update || $data_update eq "") {$data_update = "n/a"};
        if (!$data_expire || $data_expire eq "") {$data_expire = "n/a"};
        if (!$admin_mail || $admin_mail eq "") {$admin_mail = "n/a"};
        if (!$tech_mail || $tech_mail eq "") {$tech_mail = "n/a"};

        return ($domain_name,$registrant,$data_create,
                        $data_update,$data_expire,$admin_mail,$tech_mail);
}
# Parser for whois.denic.de
sub ParserDenicDe(@)
{
        my @request = @_;
        my $domain_name = undef;
        my $registrant = undef;
        my $data_create = undef;
        my $data_update = undef;
        my $data_expire = undef;
        my $admin_mail = undef;
        my $tech_mail = undef;
	
	foreach my $request(@request)
        {
                # Domain
                if ($request =~ m/Domain:\s+(\D*)/ig)
                {
                        my $raw_data = lc($1);
                        $domain_name = $raw_data;
                }
                # Registrant
                if ($request =~ m/Registrant Name:\s+(\D*)\s+\n/ig)
                {
                        my $raw_data = $1;
                        $registrant .= $raw_data ." ";
                }
                # Create date
                if ($request =~ m/Changed:\s+(\d*\S*\D*.)\s*/ig)
                {
                        my $raw_data = $1;
                        $raw_data = YearMmDd_HhMmSsTShiftToStandart($raw_data);
                        $data_create = $raw_data;
                }
                # Update date
                if ($request =~ m/Changed:\s+(\d*\S*\D*.)\s*/ig)
                {
                        my $raw_data = $1;
                        $raw_data = YearMmDd_HhMmSsTShiftToStandart($raw_data);
                        $data_update = $raw_data;
                }
                # Expire date
                if ($request =~ m/Changed:\s+(\d*\S*\D*.)\s*/ig)
                {
                        my $raw_data = $1;
                        $raw_data = YearMmDd_HhMmSsTShiftToStandart($raw_data);
                        $data_expire = $raw_data;
                }
                # Admin mail
                if ($request =~ m/Administrative Contact:\s+(\D*)\s+\n/ig)
                {
                        my $raw_data = $1;
                        $admin_mail = $raw_data;
                        $tech_mail = $admin_mail;
                }
                # Tech mail
                if ($request =~ m/Technical Contact:\s+(\D*)\s+\n/ig)
                {
                        my $raw_data = $1;
                        $tech_mail = $raw_data;
                }
                # You can add some data here
        }
	
	if (!$domain_name || ($domain_name eq "")) {$domain_name = "n/a"};
        if (!$registrant || $registrant eq "") {$registrant = "n/a"};
        if (!$data_create || $data_create eq "") {$data_create = "n/a"};
        if (!$data_update || $data_update eq "") {$data_update = "n/a"};
        if (!$data_expire || $data_expire eq "") {$data_expire = "n/a"};
        if (!$admin_mail || $admin_mail eq "") {$admin_mail = "n/a"};
        if (!$tech_mail || $tech_mail eq "") {$tech_mail = "n/a"};

        return ($domain_name,$registrant,$data_create,
                        $data_update,$data_expire,$admin_mail,$tech_mail);
}
# Parser for whois.cira.ca
sub ParserCiraCa(@)
{
	my @request = @_;
        my $domain_name = undef;
        my $registrant = undef;
        my $data_create = undef;
        my $data_update = undef;
        my $data_expire = undef;
        my $admin_mail = undef;
        my $tech_mail = undef;

        foreach my $request(@request)
        {
                # Domain
                if ($request =~ m/Domain name:\s+(\D*)/ig)
                {
                        my $raw_data = lc($1);
                        $domain_name = $raw_data;
                }
                # Registrant
                if ($request =~ m/Registrar:\s+(\D*)\s+\n/ig)
                {
                        my $raw_data = $1;
                        $registrant .= $raw_data ." ";
                }
                # Create date
                if ($request =~ m/Approval date:\s+(\d*\S*\D*.)\s*/ig)
                {
                        my $raw_data = $1;
                        $raw_data = Year_Mm_Dd_ToStandart($raw_data);
                        $data_create = $raw_data;
                }
                # Update date
                if ($request =~ m/Name servers last changed:\s+(\d*\S*\D*.)\s*/ig)
                {
                        my $raw_data = $1;
                        $raw_data = Year_Mm_Dd_ToStandart($raw_data);
                        $data_update = $raw_data;
                }
				# Expire date
                if ($request =~ m/Renewal date:\s+(\d*\S*\D*.)\s*/ig)
                {
                        my $raw_data = $1;
                        $raw_data = Year_Mm_Dd_ToStandart($raw_data);
                        $data_expire = $raw_data;
                }
                # Admin mail
                if ($request =~ m/Administrative Contact:\s+(\D*)\s+\n/ig)
                {
                        my $raw_data = $1;
                        $admin_mail = $raw_data;
                        $tech_mail = $admin_mail;
                }
                # Tech mail
                if ($request =~ m/Technical Contact:\s+(\D*)\s+\n/ig)
                {
                        my $raw_data = $1;
                        $tech_mail = $raw_data;
                }
                # You can add some data here
        }

        if (!$domain_name || ($domain_name eq "")) {$domain_name = "n/a"};
        if (!$registrant || $registrant eq "") {$registrant = "n/a"};
        if (!$data_create || $data_create eq "") {$data_create = "n/a"};
        if (!$data_update || $data_update eq "") {$data_update = "n/a"};
        if (!$data_expire || $data_expire eq "") {$data_expire = "n/a"};
        if (!$admin_mail || $admin_mail eq "") {$admin_mail = "n/a"};
        if (!$tech_mail || $tech_mail eq "") {$tech_mail = "n/a"};

        return ($domain_name,$registrant,$data_create,
                        $data_update,$data_expire,$admin_mail,$tech_mail);
}
# Parser For non matched records
sub ParserDontMatch(@)
{
        my @request = @_;
        my $domain_name = undef;
        my $registrant = undef;
        my $data_create = undef;
        my $data_update = undef;
        my $data_expire = undef;
        my $admin_mail = undef;
        my $tech_mail = undef;
	
	foreach my $request(@request)
	{
		# Domain
		if ($request =~ m/Domain Name:\s+(\D*)/ig)
		{
			my $raw_data = lc($1);
			$domain_name = $raw_data;
		}
	}

        if (!$domain_name || ($domain_name eq "")) {$domain_name = "n/a"};
        if (!$registrant || $registrant eq "") {$registrant = "n/a"};
        if (!$data_create || $data_create eq "") {$data_create = "n/a"};
        if (!$data_update || $data_update eq "") {$data_update = "n/a"};
        if (!$data_expire || $data_expire eq "") {$data_expire = "n/a"};
        if (!$admin_mail || $admin_mail eq "") {$admin_mail = "n/a"};
        if (!$tech_mail || $tech_mail eq "") {$tech_mail = "n/a"};

        return ($domain_name,$registrant,$data_create,
                        $data_update,$data_expire,$admin_mail,$tech_mail);
}
#
####################### Time Parsers #####################
# Bring date DD-MON-YEAR into indicated above (YEAR-MM-DD HH:MM:SS)
sub DdMonYearToStandart($)
{
	my $date = shift;
	my @ar = ();
	push(@ar, split(/\-/, $date));
	my $days = $ar[0];
	my $month = lc($ar[1]);
	my %month_hash = ("jan"=>"01","feb"=>"02","mar"=>"03","apr"=>"04","may"=>"05","jun"=>"06",
				"jul"=>"07","aug"=>"08","sep"=>"09","oct"=>"10","nov"=>"11","dec"=>"12");
	my $yers = $ar[2];
	$date = "$yers-$month_hash{$month}-$days 00:00:00";
	return $date;
}
# Bring date DD-MON-YY into indicated above (YEAR-MM-DD HH:MM:SS)
sub DdMonYyToStandart($)
{
	my $date = shift;
	my @ar = ();
	push(@ar, split(/\-/, $date));
	my $days = $ar[0];
	my $month = $ar[1];
	my %month_hash = ("Jan"=>"01","Feb"=>"02","Mar"=>"03","Apr"=>"04","May"=>"05","Jun"=>"06",
				"Jul"=>"07","Aug"=>"08","Sep"=>"09","Oct"=>"10","Nov"=>"11","Dec"=>"12");
	my $yers;
	if ($ar[2] > 70)
	{
		$yers = "19$ar[2]";
	}
	else
	{
		$yers = "20$ar[2]";
	}
	$date = "$yers-$month_hash{$month}-$days 00:00:00";
	return $date;
}
# Bring date YEAR-MM-DD into indicated above (YEAR-MM-DD HH:MM:SS)
sub YearMonDdToStandart($)
{
	my $date = shift;
	my @ar = ();
	push(@ar, split(/\-/, $date));
	my $days = $ar[2];
	my $month = $ar[1];
	my %month_hash = ("Jan"=>"01","Feb"=>"02","Mar"=>"03","Apr"=>"04","May"=>"05","Jun"=>"06",
				"Jul"=>"07","Aug"=>"08","Sep"=>"09","Oct"=>"10","Nov"=>"11","Dec"=>"12");
	my $yers = $ar[0];
	$date = "$yers-$month-$days 00:00:00";
	return $date;
}
# Bring date YEAR-MM-DD HH:MM:SS.m into indicated above (YEAR-MM-DD HH:MM:SS)
sub YearMmDd_HhMmSsToStandart($)
{
	my $date = shift;
	my @date=();
	my @ymd = ();
	my @hms = ();
	my %month_hash = ("Jan"=>"01","Feb"=>"02","Mar"=>"03","Apr"=>"04","May"=>"05","Jun"=>"06",
				"Jul"=>"07","Aug"=>"08","Sep"=>"09","Oct"=>"10","Nov"=>"11","Dec"=>"12");
	push(@date, split(/\ /,$date));
	push(@ymd, split(/\-/, $date[0]));
	push(@hms, split(/[\:\.]/, $date[1]));
	my $days = $ymd[2];
	my $month = $ymd[1];
	my $yers = $ymd[0];
	my $hour = $hms[0];
	my $min = $hms[1];
	my $sec = $hms[2];
	$date = "$yers-$month-$days $hour:$min:$sec";
	return $date;
}
# Bring date WeekDay(Wed) Mon DD HH:MM:SS GMT YEAR into indicated above (YEAR-MM-DD HH:MM:SS)
sub Wd_Mon_Dd_HhMmSs_GMT_YearToStandart($)
{
	my $date = shift;
	my @date=();
	my @hms = ();
	my %month_hash = ("Jan"=>"01","Feb"=>"02","Mar"=>"03","Apr"=>"04","May"=>"05","Jun"=>"06",
				"Jul"=>"07","Aug"=>"08","Sep"=>"09","Oct"=>"10","Nov"=>"11","Dec"=>"12");
	push(@date, split(/\ /,$date));
	push(@hms, split(/\:/, $date[3]));
	my $yers = $date[5];
	my $month = $date[1];
	my $days = $date[2];
	my $hour = $hms[0];
	my $min = $hms[1];
	my $sec = $hms[2];
	$date = "$yers-$month_hash{$month}-$days $hour:$min:$sec";
	return $date;
}
# Bring date YEARMMDDHHMMSS into indicated above (YEARMMDDHHMMSS)
sub YearMmDdHhMmSsToStandart($)
{
	my $date = shift;
	my @ymd = ();
	my @hms = ();
	my %month_hash = ("Jan"=>"01","Feb"=>"02","Mar"=>"03","Apr"=>"04","May"=>"05","Jun"=>"06",
				"Jul"=>"07","Aug"=>"08","Sep"=>"09","Oct"=>"10","Nov"=>"11","Dec"=>"12");
	my($garbege,$yers,$month,$days,$hour,$min,$sec) = split(/(\d\d\d\d)(\d\d)(\d\d)(\d\d)(\d\d)(\d\d)/,$date);
	$date = "$yers-$month-$days $hour:$min:$sec";
	return $date;
}
# Bring date YEAR-MM-DDTHH:MM:SS+HH:MM into indicated above (YEAR-MM-DD HH:MM:SS)
sub YearMmDd_HhMmSsTShiftToStandart($)
{
        my $date = shift;
        my @date=();
        my @ymd = ();
        my @hms = ();
        my %month_hash = ("Jan"=>"01","Feb"=>"02","Mar"=>"03","Apr"=>"04","May"=>"05","Jun"=>"06",
                                "Jul"=>"07","Aug"=>"08","Sep"=>"09","Oct"=>"10","Nov"=>"11","Dec"=>"12");
        push(@date, split(/T/,$date));
        push(@ymd, split(/\-/, $date[0]));
        push(@hms, split(/[\:\+]/, $date[1]));
        my $days = $ymd[2];
        my $month = $ymd[1];
        my $yers = $ymd[0];
        my $hour = $hms[0];
        my $min = $hms[1];
        my $sec = $hms[2];
        $date = "$yers-$month-$days $hour:$min:$sec";
        return $date;
}
# Bring date YEAR/MM/DD into indicated above (YEAR-MM-DD HH:MM:SS)
sub Year_Mm_Dd_ToStandart($)
{
	my $date = shift;
	my @date= ();
	push(@date, split(/\//,$date));
	my $yers = $date[0];
	my $month = $date[1];
	my $days = $date[2];
	
	$date = "$yers-$month-$days 00:00:00";
        return $date;
}
1;
