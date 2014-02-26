package Com::Keysurvey::SSL;

use strict;
use lib "../../../lib";
use Net::SSL;
####################### Synopsis #####################
# Parsing a SSL Certificate which has been recived from www-domain.
# For getting SSL Certificate Net::SSL is used.
# Module provides following public methods:
#	- new - constructor;
#	- getSubject - returns a subject of SSL Certificate;
#	- getExpiredate - returns expire date of SSL Certificate of given domain;
#	- getDateCreate - returns create date of SSL Certificate of given domain;
#	- isChecked - returns a error if occures;
#	- getErrorDescription - returns a descriptipton of given error. 

# TODO:
#      1: Register an error as numbers (instead of WORD? for example "SSL::OK")

########## Variables #########
my $VERSION = "1.0";		# Version of module
my @errors = ();			# Array of errors during work

# Constructor
sub new($)
{
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $self = {};
	bless($self, $class);
	my ($domain,$port) = @_;
	
	$self->Init($domain,$port);
	
	return($self);
}

# Destructor
sub DESTROY
{
	# Created just in case.
}

#Method Init
sub Init(@)
{
	my $self = shift;
	my ($domain,$port) = @_;
	
	if(!$domain)
	{
		my $err = "SSL::NO_DOMAIN"; # ERROR! Domain not given.
		$self->ReturnedMessage($err);
		return 1;
	}
	$self->{DOMAIN} = $domain;
	$self->{PORT} = $port;
	$self->{SUBJECT} = undef;
	$self->{DATE_CREATE} = undef;
	$self->{DATE_EXPIRE} = undef;
	@errors = ();
	$port = $port ? $port : '443';

	$self->ParseSSL($domain,$port);
} 

# Method ParseSSL
# Here is produced a parsing of SSL Certificate
sub ParseSSL($)
{
	my $self = shift;
	my ($domain,$port) = @_;

	my $sock;
	eval
	{
		$sock = Net::SSL->new(PeerAddr => $domain, PeerPort => $port, Timeout => 5);
	};

	if($@)
	{
		################### leave comments
	  	## $cert_error_message = "SSL certificate invalid or is not from a trusted source: $@";
		## $cert_error_message =~ s/ at .+$//s;
		###################
		my $err = "SSL::UNTRUSTED_CERT"; # ERROR! Unable to read certificate;
		$self->ReturnedMessage($err);
	}
	my $cert;
	if(!$sock)
	{
		my $err = "SSL::ERROR_CERT"; # ERROR! Can not call method 'get_peer_certificate' for $domain.;
		$self->ReturnedMessage($err);
		return 1;
	}
	else
	{
		$cert = $sock->get_peer_certificate;
	}
	my $subject = $cert->subject_name;
	
	$self->setSubject($subject);
	
	my ($CN) = $subject =~ /CN=(.*)\W/;
	if(!$CN)
	{
		my $err = "SSL::NO_READ_CERT"; # ERROR! Unable to read certificate;
		$self->ReturnedMessage($err);
		#return 1;
	}
	elsif($domain !~ /$CN/i)
	{
		my $err = "SSL::MISSMATCH_CERT"; # ERROR! SSL Certificate Common Name mismatch. Retrieved common name '$CN' does not match hostname '$domain';
		$self->ReturnedMessage($err);
		#return 1;
	}
	
	my ($year,$month,$days,$hours,$minutes,$seconds,$GMT);
	($year,$month,$days,$hours,$minutes,$seconds,$GMT) = split(/[\-\ \:]/, $cert->not_before);		# # in format YYYY-MM-DD HH:MM:SS GMT
	my $date_create = "$year-$month-$days $hours:$minutes:$seconds";
	($year,$month,$days,$hours,$minutes,$seconds,$GMT) = split(/[\-\ \:]/, $cert->not_after);		# in format YYYY-MM-DD HH:MM:SS GMT
	my $date_expire = "$year-$month-$days $hours:$minutes:$seconds";
	$self->setDateCreate($date_create);
	$self->setDateExpire($date_expire);
}

# Check for errors
sub isChecked
{
	my $self = shift;
	my $result;
	
	if (scalar @errors ne 0)
	{
		$result = join(":", @errors);
	}
	else
	{
		$result = "SSL::OK";
	}
	return $result;
}

# Returned messages
sub ReturnedMessage(@)
{
	my $self = shift;
	my $message = shift @_;
	push (@errors, $message);
}

# Description of errors
sub getErrorDescription($)
{
	my $self = shift;
	my $error = shift @_;
	my $description;
	if("SSL::NO_DOMAIN" eq $error)
	{
		$description = "SSL ERROR! Domain not given.";
	}
	elsif("SSL::UNTRUSTED_CERT" eq $error)
	{
		$description = "SSL ERROR! SSL Certificate invalid or is not from a trusted source for ".$self->{DOMAIN} .".";
	}
	elsif("SSL::ERROR_CERT" eq $error)
	{
		$description = "SSL ERROR! Can not call method 'get_peer_certificate' for ".$self->{DOMAIN} .".";
	}
	elsif("SSL::NO_READ_CERT" eq $error)
	{
		$description = "SSL ERROR! Unable to read certificate for ".$self->{DOMAIN} .".";
	}
	elsif("SSL::MISSMATCH_CERT" eq $error)
	{
		$description = "SSL ERROR! SSL Certificate Common Name mismatch. Retrieved common name '/CN' does not match domainname '". $self->{DOMAIN} ."'.";
	}
	else
	{
		$description = "SSL ERROR! Unknown error for ". $self->{DOMAIN} .".";
	}
	return $description;
}

######################## Getters and setters

# Method setSubject(PARAM)
sub setSubject($)
{
	my ($self,$subject) = @_;
	$self->{SUBJECT} = $subject;
}

# Method getSubject()
sub getSubject()
{
	my $self = shift;
	return $self->{SUBJECT};
}

# Method setDateExpire(PARAM)
sub setDateExpire($)
{
	my ($self,$date_expire) = @_;
	$self->{DATE_EXPIRE} = $date_expire;
}

# Method getDateExpire
sub getDateExpire()
{
	my $self = shift;
	return $self->{DATE_EXPIRE};
}

# Method setDateCreate(PARAM)
sub setDateCreate($)
{
	my ($self,$date_create) = @_;
	$self->{DATE_CREATE} = $date_create;
}

# Method getDateCreate
sub getDateCreate()
{
	my $self = shift;
	return $self->{DATE_CREATE};
}

1;
