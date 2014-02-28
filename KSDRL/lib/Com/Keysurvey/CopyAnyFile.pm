package Com::Keysurvey::CopyAnyFile;

use strict;

# TODO: 
#       1. Make suppress output of smbclient. Or get output data in variable.
#       2. Track copying progress.
#       3. Make checking for existing command (by which(1)).
#		4. Make something in isChecked() for better output.


####################### Synopsis ########################################
# Parameters can be following:											#
# Module provides following public methods:								#
#	- new - constructor													#
#	- isChecked - returns an error if occures;							#
#	- getErrorDescription - returns a descriptipton of given error		#
#########################################################################

########## Variables #########
my $VERSION = "1.1";	# Version of module
my @ERRORS=();			# Module errors
my $TMP_DIR = "";		# Temporary folder for storing files which have been 
						# copied from remote destination (not from localhost)
my @LIST_FILES = ();	# List of files will be copy

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
# Initialize
sub Init(@)
{
	my $self = shift;
	my $path_to_log_file = shift @_;
	@LIST_FILES = ();
	$TMP_DIR = "";
	@ERRORS = ();
}
# Decstructor
sub DESTROY
{
	
}
# Check for errors
sub isChecked
{
	my $self = shift;
	my $result;
	
	if (scalar @ERRORS ne 0)
	{
		$result = join(":", @ERRORS);
	}
	else
	{
		$result = "COPY::OK";
	}
	return $result;
}
# Description of errors
sub getErrorDescription($)
{
	my $self = shift;
	my $error = shift @_;
	my $description;
	
	if("COPY::FILE_MISS" eq $error)
	{
		$description = "COPY ERROR! Missing file";
	}
	elsif("COPY::NO_FILE_PATH" eq $error)
	{
		$description = "COPY ERROR! It is not assign logger file";
	}
	else
	{
		$description = "COPY ERROR! Unknown error.";
	}
	
	return $description;
}
# Returned messages
sub ReturnedMessage(@)
{
	my $self = shift;
	my $message = shift @_;
	push (@ERRORS, $message);
}
sub Copy()
{
	my $self = shift;
	my $result = "";
	my %source = %{(shift)};
	my %destination = %{(shift)};
	my $tmp_dir = $TMP_DIR;

	my $res = &CreateDirList(
		{scheme=>$source{'scheme'},user=>$source{'user'},host=>$source{'host'},path=>$source{'path'}}
		);
	my @LIST_FILES1 = sort {"$a->{parent_name}" cmp "$b->{parent_name}" } @LIST_FILES;
	for(my $i = 0; $i < scalar(@LIST_FILES); $i++)
	{
		if($source{'scheme'} eq 'file' or !$source{'scheme'})
		{
			my $copy_result = &CopyProtoFile(
				{scheme=>$source{'scheme'},user=>$source{'user'},host=>$source{'host'},path=>"$LIST_FILES1[$i]{'parent_name'}/$LIST_FILES1[$i]{'file_name'}",file_size=>"$LIST_FILES1[$i]{'file_size'}"},
				{scheme=>$destination{'scheme'},user=>$destination{'user'},host=>$destination{'host'},path=>$destination{'path'}}
				);
			$result = $copy_result;
		}
		else
		{
			$result = "Error";
		}
	}
	$result .= "OK";
	return $result;
}
sub CreateDirList()
{
	my %source = %{(shift)};
	my $result = "";

	# Parse source
	if($source{'scheme'} eq 'smb')
	{
		$result = "Scheme is ".$source{'scheme'};
	}
	elsif($source{'scheme'} eq 'file' or !$source{'scheme'})
	{
		chdir($source{'path'});
		opendir(DIR, ".");
		my @contents = grep{!/^\./} readdir(DIR);
		closedir(DIR);
		foreach my $dir_content(@contents)
		{
			if(-d $dir_content)
			{
				chdir($dir_content);
				opendir(SUBDIR, ".");
				my @subcontents = grep{!/^\./} readdir(SUBDIR);
				closedir(SUBDIR);
				if(scalar(@subcontents) eq 0)
				{
					my $total_file_size = 'NULL';
					push(@LIST_FILES,{parent_name=>"$source{'path'}",file_name => "$dir_content\/",file_size => "$total_file_size"});
				}
				else
				{
					&CreateDirList(
						{scheme=>$source{'scheme'},user=>$source{'user'},host=>$source{'host'},path=>"$source{'path'}\/$dir_content"}
						);
				}
					chdir("..");
			}
			elsif (-f $dir_content)
			{
				# Get total file size
				my $total_file_size = (-s "$source{'path'}\/$dir_content");
				push(@LIST_FILES,{parent_name=>"$source{'path'}",file_name => "$dir_content",file_size => "$total_file_size"});
			}
		}
		$result = "OK";
	}
	elsif($source{'scheme'} eq 'ssh')
	{
		$result = "Unimplemented scheme ".$source{'scheme'};
	}
	elsif($source{'scheme'} eq 'ftp')
	{
		$result = "Unimplemented scheme ".$source{'scheme'};
	}
	elsif($source{'scheme'} eq 'http' or 'https')
	{
		$result = "Unimplemented scheme ".$source{'scheme'};
	}
	else
	{
		$result = "Unknown scheme ".$source{'scheme'};
	}
	return $result;
}
sub CopyProtoFile($)
{
	my %source = %{(shift)};
	my %destination = %{(shift)};
	my $result = "";
	
	my $which = "/usr/bin/which";
	my $smbclient = "/usr/bin/smbclient";
	
	if($destination{'scheme'} eq 'file' or !$destination{'scheme'})
	{
		$result = "CP";
	}
	elsif($destination{'scheme'} eq 'smb')
	{
		# Create identical path to file
		my @path_to_file = split(/\//,$source{'path'}); # split '/path/to/file' by '/' and put in array
		push(@path_to_file,"") if $source{'file_size'} eq 'NULL'; # adding empty if /path/to/ is emty folder
		my $file_to_put = pop(@path_to_file);	# get the file name
		my $full_path_to_put_destination = join("",split(/\//,$destination{'path'})).join("/",@path_to_file)."/";	# built path to file without file name
		
		# Copy file with smbclient
		$result = `$smbclient $destination{'host'} -A $destination{'user'} -d 1 -c \'recurse;mkdir $full_path_to_put_destination;cd $full_path_to_put_destination;put $source{'path'} $file_to_put'`;
	}
	return $result;
}
1;
