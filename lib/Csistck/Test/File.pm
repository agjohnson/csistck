package Csistck::Test::File;

use 5.010;
use strict;
use warnings;

use Csistck::Oper;
use Digest::MD5;
use File::Basename;
use File::Copy;

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
    
    # Fist get the basename, so we can add to the dest path
    my $file_base = basename($file);
    my $file_dest = join "/", $dest, $file_base;

        
    if (file_compare($file, $file_dest)) {
        return okay(sprintf "File %s matches %s", $file, $file_dest);
    }
    else {
        # Fail with message, then try to fix it.
        fail(sprintf "File %s doesn't match %s", $file, $file_dest);
        file_install($file, $file_dest) if (fix() or diff()); 
        return
    }
}

sub file_install {
    my ($src, $dest) = @_;

    diff("Copying file: <src=$src> <dest=$dest>");
    
    copy($src, $dest) or die("Failed to copy file: $!") if (fix());

    return
}

# Compare all files
sub file_compare {
    my @files = @_;
    my $hash = undef;
    
    for my $file (@files) {
        # Get file hash, debug
        my $hashret = file_hash($file);
        return 0 if (!defined $hashret);

        # If hash has been defined already, compare hash and hashret
        # If not, set it. This is the first file
        if (defined($hash)) {
            return 0 if (!$hashret eq $hash);
        }
        else {
            $hash = $hashret if (!defined($hash));
        }
    }

    return 1;
}

sub file_hash {
    my $file = shift;

    if (-r $file) {
        open(my $h, $file);
        
        my $hash = Digest::MD5->new();
        $hash->addfile($h);
        close($h);

        debug(sprintf "<file=%s> <hash=%s>: File hash successful", $file, $hash->hexdigest());
        return $hash->hexdigest();
    }

    debug(sprintf "<file=%s>: File hash failed", $file);
    return undef;
}

1;
