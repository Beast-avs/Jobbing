package myDisplay;

#
# Add description !!!
#

use strict;

my $FORMAT;			# Format to display
my @FORMATS = ('cli_s','cli_c','multiline','xml');

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
	
	$FORMAT = 'multiline';
}

sub getFormat(){
	my $self = shift;
	return $FORMAT;
}

sub setFormat($){
	my ($self, $format) = @_;
	if (defined $format){
		$FORMAT = $format;
	}
}

# Receives the list of supported formats. These formats are set into array @FORMATS
sub getSupportedFormats(){
	my $self = shift;
	return join(',',@FORMATS);
}

# Prepare output in given format. Should be improved for processing various structures and data types (such as XML).
# Receives a hash with city info
# Returns a string with built city info.
# 
# Input data format is:
#	$hash{'ID'}, $hash{'city'}, $hash{'country'}, $hash{'population'}
# Output may vary. Depends on $FORMAT
sub Output(%){
	my $self = shift;
	my %city_info = @_;			# City info
	my $result = "";			# Contains the dormatted data

	if ('cli_s' eq $FORMAT){
		# Output for Command Line. Space as delimiter
		$result = $city_info{'ID'}." ".$city_info{'name'}." ".$city_info{'country'}." ".$city_info{'population'};
		
		#
		# This solution leaves space in the end
		#
		#while (my ($key, $value) = each(%city_info)){
     	#	$result .= " ".$value;
		#}	
	}elsif('cli_c' eq $FORMAT){
		# Output for Command Line. Comma as delimiter
		$result = $city_info{'ID'}.",".$city_info{'name'}.",".$city_info{'country'}.",".$city_info{'population'};
		
		#
		# This solution leaves comma in the end
		#
		#while (my ($key, $value) = each(%city_info)){
     	#	$result .= $value.",";
		#}
	}elsif('multiline' eq $FORMAT){
		# Output for Multiline
		$result = "\n\tID: ".$city_info{'ID'}."\n\tName: ".$city_info{'name'}."\n\tCountry: ".$city_info{'country'}."\n\tPopulation: ".$city_info{'population'}."\n";
	}elsif('xml' eq $FORMAT){
		# Not supported yet;
		$result = "<?xml version =\"1.0\" encoding=\"utf-8\" ?>\n";
		$result .= "<city_info name=\'$city_info{'name'}\'>\n";
		while (my ($key, $value) = each(%city_info)){
			$result .= "\t<$key>".$value."</$key>\n";
		}
		$result .= "</city_info>\n";
	}
	else{
		# Awkward solution.
		# return to a requester the string "ERROR"; 
		$result = "ERROR in format: \'$FORMAT\'. Supported formats are: ".$self->getSupportedFormats()."\n";
	}
		
	return $result;
}

1;
