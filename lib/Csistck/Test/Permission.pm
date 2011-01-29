package Csistck::Test::Permission;

use 5.010;
use strict;
use warnings;

use Csistck::Oper;
use File::stat;

sub mode {
    my $file = shift;
    my $mode = shift;

    # Depending on mode
    return sub { mode_process($file, $mode); };
}

sub mode_process {
    my $file = shift;
    my $mode = shift;

    # Make sure dest is a path
    if (! -e $file) {
        return fail("Path/file $file does not exist");
    }

    # Check mode is legit
    if ($mode !~ m/^[0-7]{3,4}$/) {
        return fail("Invalid file mode");
    }
    
    if (mode_compare($file, $mode)) {
        return okay(sprintf "File %s mode matches %s", $file, $mode);
    }
    else {
        # Fail with message, then try to fix it.
        fail(sprintf "File %s mode doesn't match %s", $file, $mode);
        mode_repair($file, $mode) if (fix() or diff()); 
        return
    }
}

sub mode_repair {
    my ($file, $mode) = @_;

    diff("Chmod file: <file=$file> <mode=$mode>");
    
    chmod(oct($mode), $file) or die("Failed to chmod file: $file") if (fix());

    return
}

# Compare all files
sub mode_compare {
    my ($file, $mode) = @_;
    
    # Don't accept honkey permissions
    $mode =~ s/^([0-7]{3})$/0$1/; 

    my $fh = stat($file);

    if ($fh) {
        my $curmode = sprintf "%04o", $fh->mode & 07777;
        debug("<file=$file> <mode=$curmode>");
        return ($curmode eq $mode);
    }

    return 0;
}

1;
