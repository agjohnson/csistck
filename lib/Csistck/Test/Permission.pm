package Csistck::Test::Permission;

use 5.010;
use strict;
use warnings;

use base 'Exporter';
our @EXPORT_OK = qw/permission/;

use Csistck::Oper;
use File::stat;

# Input is src (glob as string), and assoc. array of permisison checks
sub permission {
    my $src = shift;
    my %args = @_; # assoc array to hash

    # Get glob of files
    my @files = glob($src);
    
    # Depending on mode
    return sub { for my $file (@files) { permission_process($file, \%args); }; };
}

# First is file, second call is hash of args
sub permission_process {
    my $file = shift;
    my $args = shift;

    # Make sure dest is a path
    if (! -e $file) {
        return fail("Path/file $file does not exist");
    }
    
    # Bad arguments
    if (!defined $args or !ref $args eq "HASH") {
        return fail("Invalid arguments");
    }
    
    # Run tests with arguments
    # Check for mode
    if (defined $args->{mode}) {
        mode_process($file, $args->{mode});
    }
    
    # Check for owner
    if (defined $args->{uid}) {
        uid_process($file, $args->{uid});
    }

    # Check for group
    if (defined $args->{gid}) {
        gid_process($file, $args->{gid});
    }
}

# Run test on file mode
sub mode_process {
    my ($file, $mode) = @_;

    # Check mode is legit
    if ($mode !~ m/^[0-7]{3,4}$/) {
        return fail("Invalid file mode");
    }
    
    if (mode_compare($file, $mode)) {
        return okay("File mode of $file matches mode $mode");
    }
    else {
        fail("File mode of $file does not match mode $mode");
        mode_repair($file, $mode) if (fix or diff);
        return
    }
}

sub uid_process {
    my ($file, $uid) = @_;

    # Check uid is legit
    if ($uid !~ m/^[0-9]+$/) {
        return fail("Invalid user id");
    }

    # Run check, repair if fixing
    if (uid_compare($file, $uid)) {
        return okay("File user id of $file matches mode $uid");
    }
    else {
        fail("File user id of $file does not match mode $uid");
        uid_repair($file, $uid) if (fix or diff);
        return
    }
}

sub gid_process {
    my ($file, $gid) = @_;

    # Check gid is legit
    if ($gid !~ m/^[0-9]+$/) {
        return fail("Invalid group id");
    }

    # Run check, repair if fixing
    if (gid_compare($file, $gid)) {
        return okay("File group id of $file matches mode $gid");
    }
    else {
        fail("File group id of $file does not match mode $gid");
        gid_repair($file, $gid) if (fix or diff);
        return
    }
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

# Repair mode
sub mode_repair {
    my ($file, $mode) = @_;

    diff("Chmod file: <file=$file> <mode=$mode>");
    
    chmod(oct($mode), $file) or die("Failed to chmod file: $file") if (fix());

    return
}

# Compare uid
sub uid_compare {
    my ($file, $uid) = @_;
    
    my $fh = stat($file);

    if ($fh) {
        my $curuid = $fh->uid;
        debug("<file=$file> <uid=$uid>");
        return ($curuid == $uid);
    }

    return 0;
}

# Repair uid
sub uid_repair {
    my ($file, $uid) = @_;

    diff("Chown file: <file=$file> <uid=$uid>");
    
    chown($uid, -1, $file) or die("Failed to chown file: $file") if (fix());

    return
}

# Compare gid
sub gid_compare {
    my ($file, $gid) = @_;
    
    my $fh = stat($file);

    if ($fh) {
        my $curgid = $fh->gid;
        debug("<file=$file> <uid=$gid>");
        return ($curgid == $gid);
    }

    return 0;
}

# Repair gid
sub gid_repair {
    my ($file, $gid) = @_;

    diff("Chown file: <file=$file> <gid=$gid>");
    
    chown(-1, $gid, $file) or die("Failed to chown file: $file") if (fix());

    return
}



1;
