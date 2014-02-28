package Com::Keysurvey::Sender;

use strict;
use lib "../../../lib";
use Net::SMTP;

####################### Synopsis ########################################
# The information should send through defined SMTP-server.				# 
# Must send one message for one checking, i.e by checking several 		#
# domains, or databases, or ssls, the one email will be send with the	#
# list of domains or statistic of database. 							#
# Module provides following public methods:								#
#	- new - constructor;												#
#	- SendNotification - sends mail to recipients;						#
#	- getSMTPServer - returns a SMTP-server through will be send a mail;#
#	- isChecked - returns an error if occurea;							#
#	- getErrorDescription - returns a descriptipton of an error;		#
#########################################################################

# TODO:
#       1: Make support of plain-text mail

########## Variables #########
my $VERSION = "1.1";			# Version of module
my @notify_recipients = ();		# recipients of notofication 
my @errors = ();				# Array of errors during work

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
# Destructor
sub DESTROY
{
	
}
#Method Init
sub Init(@)
{
	my $self = shift;
	my $mails = shift @_;
	my @recipients = split(/;/, $mails);
	@notify_recipients = @recipients;
	$self->{SMTP_SERVER} = undef;
}
# Method SendNotification
# return status of sending
sub SendNotification(@)
{
	my $self = shift;
	my @recipients = @notify_recipients;
	my $message = shift;
	my $result = "";
	if(scalar @recipients == 0)
	{
		my $err = "SENDER::NO_RECIPIENTS"; # ERROR! Recipients not given.
		$self->ReturnedMessage($err);
		return 1;
	}
	my $smtp_host = $self->getSMTPServer();
	my $from = 'postmaster@worldapp.com';
	my $sender = Net::SMTP->new($smtp_host);
	$sender->mail($from);
	$sender->recipient(@recipients);
	$sender->data();
	$sender->datasend("Mime-Version: 1.0\n");
	$sender->datasend("Content-type: text/html; charset='iso-8859-1'\n");
	$sender->datasend("From: $from\n");
	$sender->datasend("To: @recipients\n");
	$sender->datasend("Subject: Statistic from KSDRLS utility.\n");
	$sender->datasend("\n");
	$sender->datasend("$message\n");
	$sender->quit;

	return $result;
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
		$result = "SENDER::OK";
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
	if("SENDER::NO_RECIPIENTS" eq $error)
	{
		$description = "SENDER ERROR! Recipients not given.";
	}
	else
	{
		$description = "SENDER ERROR! Unknown error.";
	}
	return $description;
}

######################## Getters and setters
# Method setSMTPServer(PARAM)
sub setSMTPServer($)
{
	my $self = shift;
	my $smtp_server = shift @_;
	$self->{SMTP_SERVER} = $smtp_server;
}

# Method getSMTPServer
sub getSMTPServer
{
	my ($self, $smtp_server) = @_;
	return $self->{SMTP_SERVER};
} 

1;
