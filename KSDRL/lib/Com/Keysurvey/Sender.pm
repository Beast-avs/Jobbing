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
sub SendNotification1(@)
{
	my $self = shift;
	my @recipients = @notify_recipients;
	if(scalar @recipients == 0)
	{
		my $err = "SENDER::NO_RECIPIENTS"; # ERROR! Recipients not given.
		$self->ReturnedMessage($err);
		return 1;
	}
	my @to_submit = @_;

	my $expire_list = "";
	my $database_list = "";
	my $ssl_list = "";
	foreach my $entry (@to_submit)
	{
		my @row = split (/\|/, $entry);
		if('Expire_ok' eq $row[0])
		{
			$expire_list .= "<TR><TD>$row[1]</TD><TD>OK</TD</TR>";
		}
		elsif('Expire_warn' eq $row[0])
		{
			my @string = split(/\t/,$row[1]);
			$expire_list .= "<TR bgcolor='#ffff66'><TD>$string[0]</TD><TD>$string[1] day(s) is remainded</TD</TR>";
		}
		elsif('Expire_er' eq $row[0])
		{
			$expire_list .= "<TR bgcolor='#ff6666'><TD>$row[1]</TD><TD>Expiration date not set</TD</TR>";
		}
		elsif('Database' eq $row[0])
		{
			my @col1 = split(/=>/, $row[2]);
			my @col2 = split(/=>/, $row[3]);
			my @col3 = split(/=>/, $row[4]);
			$database_list .= "<TR><TD>$row[1]</TD>";
			if('ok' eq $col1[0])
			{
				$database_list .= "<TD>$col1[1]</TD>";
			}
			else#('warn' eq $col1[0])
			{
				$database_list .= "<TD bgcolor='#ffff66'>$col1[1]</TD>";
			}
			if('ok' eq $col2[0])
			{
				$database_list .= "<TD>$col2[1]</TD>";
			}
			else#('warn' eq $col2[0])
			{
				$database_list .= "<TD bgcolor='#ffff66'>$col2[1]</TD>";	
			}
			if('ok' eq $col3[0])
			{
				$database_list .= "<TD>$col3[1]</TD>";
			}
			else#('warn' eq $col3[0])
			{
				$database_list .= "<TD bgcolor='#ffff66'>$col3[1]</TD>";	
			}
			$database_list .= "</TR>";
		}
		elsif('SSL_ok' eq $row[0])
		{
			$ssl_list .= "<TR><TD>$row[1]</TD><TD>$row[2]</TD><TD>$row[3]</TD></TR>";
		}
		elsif('SSL_warn' eq $row[0])
		{
			$ssl_list .= "<TR bgcolor='#ffff66'><TD>$row[1]</TD><TD>$row[2]</TD><TD>$row[3]</TD></TR>";
		}
		elsif('SSL_er' eq $row[0])
		{
			$ssl_list .= "<TR bgcolor='#ff6666'><TD>$row[1]</TD><TD>$row[2]</TD><TD>$row[3]</TD></TR>";
		}
	}
	my $message_to_send_plaintext = "
\t\tStatistic of CTES utility.\n
------------------------------\n
	";
	my $message_to_send_html = "
<!DOCTYPE html PUBLIC '-//W3C//DTD XHTML 1.0 Transitional//EN' 'http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd'>
<HTML xmlns='http://www.w3.org/1999/xhtml''>
<HEAD><TITLE>Statistic of CTES utility</TITLE>
</HEAD>
<BODY>";
	if("" ne $expire_list)
	{
		$message_to_send_html .= "
<P><H3>Domain checking</H3></P>
<TABLE width = '100%'>
<TR bgcolor='#cccccc'>
<TD><B>Domain</B></TD><TD><B>Status</B></TD>
</TR>
$expire_list
</TABLE>";
		$message_to_send_plaintext .= "
\tDomain checking:\n
|\t\tDomain\t\t\t|\t\tStatus\t\t|\n
-----------------------------------------\n
$expire_list\n";
	}
	if("" ne $database_list)
	{
		$message_to_send_html .= "
<P><H3>Database checking</H3></P>
<TABLE width='100%'>
<TR bgcolor='#cccccc'>
<TD><B>Domain</B></TD><TD><B>Create date</B></TD><TD><B>Update date</B></TD><TD><B>Expire date</B></TD>
</TR>
$database_list
</TABLE>";
		$message_to_send_plaintext .= "
\tDatabase checking:\n
|\t\tDomain\t\t\t|\tCreate Date\t\t|\tUpdate Date\t\t|\tExpire Date\t\t|\n
-------------------------------------------------------------------------------------\n
$database_list\n";
	}
	if(""ne $ssl_list)
	{
		$message_to_send_html .= "
<P><H3>SSL checking</H3></P>
<TABLE width='100%'>
<TR bgcolor='#cccccc'>
<TD><B>Domain</B></TD><TD><B>Craete</B></TD><TD><B>Expire</B></TD>
</TR>
$ssl_list
</TABLE>";
		$message_to_send_plaintext .= "
\tSSL checking:\n
|\t\tDomain\t\t|\t\tCreate\t\t\t|\t\tExpire\t\t\t\n
---------------------------------------------------------------------\n
$ssl_list";

	}
	$message_to_send_html .= "
</BODY>
</HTML>
";
	$message_to_send_plaintext .= "\n";
	my $smtp_host = $self->getSMTPServer();
	my $message_body_type = "html-text"; # plain-text|html-text;
	my $message_to_send;
	if("html-text" eq $message_body_type)
	{
		$message_to_send = $message_to_send_html;
	} 
	elsif("plain-text" eq $message_body_type)
	{
		$message_to_send = $message_to_send_plaintext;
	}
	my $from = 'postmaster@worldapp.com';

	my $sender = Net::SMTP->new($smtp_host);
	$sender->mail($from);
	$sender->recipient(@recipients);
	$sender->data();
	$sender->datasend("Mime-Version: 1.0\n");
	$sender->datasend("Content-type: text/html; charset='iso-8859-1'\n");
	$sender->datasend("From: $from\n");
	$sender->datasend("To: @recipients\n");
	$sender->datasend("Subject: Statistic from CTES utility.\n");
	$sender->datasend("\n");
	$sender->datasend("$message_to_send\n");

    $sender->quit;
}
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
