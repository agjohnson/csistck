package Csistck::Test::File;

use 5.010;
use strict;
use warnings;

use base 'Exporter';
our @EXPORT_OK = qw/file/;

use Csistck::Oper;
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
    
    # Depending on mode
    return sub { for my $file (@files) { file_process($file, $dest); }; };
}

sub file_process {
    my $file = shift;
    my $dest = shift;

    # Make sure dest is a path
    if (! -d -w $dest) {
        return fail("dest path $dest does not exist or is not a path");
    }

    # Get absolute source and desination
    my $file_src = join '/', $FindBin::Bin, $file;
    my $file_base = basename($file);
    my $file_dest = join "/", $dest, $file_base;

    if (file_compare($file_src, $file_dest)) {
        return okay(sprintf "File %s matches %s", $file_src, $file_dest);
    }
    else {
        # Fail with message, then try to fix it.
        fail(sprintf "File %s doesn't match %s", $file_src, $file_dest);
        file_install($file_src, $file_dest) if (fix() or diff()); 
        return
    }
}

sub file_install {
    my ($src, $dest) = @_;

    diff("Copying file: <src=$src> <dest=$dest>");
    
    copy($src, $dest) or die("Failed to copy file: $!") if (fix());

    return
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

sub file_hash {
    my $file = shift;

    if (-r $file) {
        open(my $h, $file);
        
        my $hash = Digest::MD5->new();
        $hash->addfile($h);
        close($h);

        my $digest = $hash->hexdigest();
        debug(sprintf "<file=%s> <hash=%s>: File hash successful", $file, $digest);
        return $digest;
    }

    debug(sprintf "<file=%s>: File hash failed", $file);
    return 0;
}

1;
