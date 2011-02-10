package Csistck::Test::File;

use 5.010;
use strict;
use warnings;

use base 'Exporter';
our @EXPORT_OK = qw/file/;

use Csistck::Oper qw/debug/;
use Csistck::Test;

use Digest::MD5;
use File::Basename;
use File::Copy;
use FindBin;

sub file {
    my $src = shift;
    my $dest = shift;
    my $args = shift;

    # Get glob of files
    my @files = glob($src);
    
    # Return array of tests
    return map { file_build_test($_, $dest); } @files;
}

# Helper function to avoid same scope in map and to build test
sub file_build_test {
    my ($src, $dest) = @_;
    
    # Get absolute paths
    my $src_abs = join '/', $FindBin::Bin, $src;
    my $src_base = basename($src);
    my $dest_abs = join "/", $dest, $src_base;
    
    return Csistck::Test->new(
        sub { file_check($src_abs, $dest_abs); },
        sub { file_install($src_abs, $dest_abs); },
        "File check on $src_abs"
    );
}

# Check file and file in destination are the same via md5
sub file_check {
    my $src = shift;
    my $dest = shift;

    # Make sure dest is a path
    #die("Destination path does not exist")
    #  if (! -e $dest);
    #die("Destination path is not a path")
    #  if (! -d $dest);
    #die("Destination path is not writable")
    #  if (-d $dest and ! -w $dest);
    
    die("Files do not match")
      unless(file_compare($src, $dest));
}

# Copy file to destination
sub file_install {
    my ($src, $dest) = @_;

    debug("Copying file: <src=$src> <dest=$dest>");
    copy($src, $dest) or die("Failed to copy file: $!");
}

# Compare hashes between two files
sub file_compare {
    my @files = @_;

    # Require two files
    return 0 unless (scalar @files == 2);

    # Get hashes and return compare
    my ($hasha, $hashb) = map file_hash($_), @files;

    debug(sprintf "File compare result: <hash=%s> <hash=%s>", $hasha, $hashb);
    
    return ($hasha eq $hashb);
}

# Hash file, return hash or die if error
sub file_hash {
    my $file = shift;

    debug("<file=$file>: Hashing file");

    # Errors to die on
    die("File does not exist")
      if (! -e $file);
    die("File not readable")
      if (! -r $file);

    open(my $h, $file) or die("Error opening file: $!");
        
    my $hash = Digest::MD5->new();
    $hash->addfile($h);
    close($h);

    my $digest = $hash->hexdigest();

    debug(sprintf "<file=%s> <hash=%s>: File hash successful", $file, $digest);

    return $digest;    
}

1;
