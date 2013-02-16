#!/usr/bin/perl -w

# Here is a test only.
#
# Searching for answers on the internet is perfectly acceptable, but key references should be recorded.
# These exercises are to demonstrate knowledge of OO techniques, so please use them wherever possible.
# 1) Take as source the Cities provided at the end of the mail and write a script city_info.pl that when
# passed the city name via
# city_info.pl --city <city name> [--filename <optional filename holding the city info>]
# will print out a small summary of the details of the city.
# Please write this entirely using OO techniques.
# Please write this in as few statements as possible.
# There is no limitation on the Perl Modules you can use.
# 2) Take the city example above and provide summary information for all cities
# Please load, construct and display all city object from a data file in as few lines as possible.
# Plus the file must be loaded into a string in one operation. (To test knowledge of an idiom).
# 3) The data set for the cities including ID, City, Country, and Population, however when a
# city is a capital city, it should output additionally the population of the country.
# Discuss how you would modify the script to achieve this using standard OO techniques.
# 4) What is the difference between an Object Accessor and a Class Accessor.
#

use strict;
use warnings;
use Getopt::Long qw(:config no_ignore_case bundling);
use lib "lib";
use myParser;
use myDisplay;

# Constants
use constant CONF_DIR => "./conf/";
use constant CONF_FILE => CONF_DIR."/cities.txt";

use vars qw(
		$city
		$file_name
		$format
		$help_opt
);

GetOptions(
		"city=s"			=>\$city,
		"filename=s"		=>\$file_name,
		"format=s"			=>\$format,
		"help"				=>\$help_opt
);

sub getCityInfo($){
	my $city = shift @_;
	
	my $config_name = "";
	if (defined($file_name) and "" ne $file_name){
		$config_name = $file_name;
	}else{
		$config_name = CONF_FILE;
	}
	my $parser = myParser->new(); 
	$parser->setConfigFile($config_name);
	my $display = myDisplay->new();
	$display->setFormat($format);
	
	return $display->Output($parser->Parse($city));
}

print "Result is: ".getCityInfo($city);
