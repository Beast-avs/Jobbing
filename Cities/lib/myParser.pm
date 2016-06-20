package myParser;

#
# Module gets the data form given file and puts that data into hash. 
# I know that hash could be too heavy for server (consumes a much more memory than siple string).
# But now it is easy for me to process that data  
#

use strict;

my $CONFIG_FILE;

# Constructor
sub new($){
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $self = {};
	bless ($self, $class);
	
	my $param = shift @_;
	$self->Init($param);
	
	return $self;
}

# Initialization all of the module parameters. Why here? Just my old habit.
sub Init($){
	my $self = shift;
	
	$CONFIG_FILE = undef;
}

sub getConfigFile(){
	my $self = shift;
	return $CONFIG_FILE;
}

sub setConfigFile($){
	my ($self, $conf_file) = @_;	
	$CONFIG_FILE = $conf_file;
}

# Parse the file with cities with given structure. Should be improved for processing various structures and data types (such as XML).
# Receives a city name. This city will be chosen from file
# Returns the hash with city info.
# 
# 
# Input $CONFIG_FILE file format is:
#	ID, City, Country,Population
sub Parse($){
	my $self = shift;
	
	my $city = shift @_ || "";	# Name of the city
	my %city_info=();		# Contains the city info
	$city_info{'ID'} = 'unknown';
	$city_info{'name'} = 'unknown';
	$city_info{'country'} = 'unknown';
	$city_info{'population'} = 'unknown';
	
	open(CITIES, "<".$CONFIG_FILE);
	
	while(<CITIES>){
		chomp;
		next if $city eq "";
		if ($_ =~ /$city/){
	 		($city_info{'ID'}, $city_info{'name'}, $city_info{'country'}, $city_info{'population'}) = $_=~ /^(\d+\.)\s*(.*),\s*(.*)-\s*(.*)/;
	 		$city_info{'ID'} =~ s/(?:^ +)||(?: +$)//g;
	 		$city_info{'name'} =~ s/(?:^ +)||(?: +$)//g;
	 		$city_info{'country'} =~ s/(?:^ +)||(?: +$)//g;
	 		$city_info{'population'} =~ s/(?:^ +)||(?: +$)//g;
		} 
	}
	close(CITIES);
		
	return %city_info;
}

1;
