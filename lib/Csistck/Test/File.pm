package Csistck::Test::File;

use 5.010;
use strict;
use warnings;

use base 'Exporter';
our @EXPORT_OK = qw/file/;

use Csistck::Oper qw/debug/;
use Csistck::Util qw/backup_file hash_file/;
use Csistck::Test;

use Digest::MD5;
use File::Basename;
use File::Copy;
use FindBin;

sub file {
    my $src = shift;
    my $dest = shift;
    my $args = shift;

    # Get absolute paths for glob, glob files
    my $src_abs = join '/', $FindBin::Bin, $src;
    my @files = glob($src_abs);
    
    # Return array of tests
    return map { file_build_test($_, $dest); } @files;
}

# Helper function to avoid same scope in map and to build test
sub file_build_test {
    my ($src, $dest) = @_;
    
    # Test destination for file
    my $src_base = basename($src);
    my $dest_abs = join "/", $dest, $src_base;

    return Csistck::Test->new(
        sub { file_check($src, $dest_abs); },
        sub { file_install($src, $dest_abs); },
        "File check on $src"
    );
}

# Check file and file in destination are the same via md5
sub file_check {
    my $src = shift;
    my $dest = shift;

    die("Files do not match")
      unless(file_compare($src, $dest));
}

# Copy file to destination
sub file_install {
    my ($src, $dest) = @_;
    
    backup_file($dest)
      if(-f -e -r $dest);

    debug("Copying file: <src=$src> <dest=$dest>");
    copy($src, $dest) or die("Failed to copy file: $!");
}

# Compare hashes between two files
sub file_compare {
    my @files = @_;

    # Require two files
    return 0 unless (scalar @files == 2);

    # Get hashes and return compare
    my ($hasha, $hashb) = map hash_file($_), @files;

    debug(sprintf "File compare result: <hash=%s> <hash=%s>", $hasha, $hashb);
    
    return ($hasha eq $hashb);
}

1;
