package Csistck::Test::Permission;

use 5.010;
use strict;
use warnings;

use base 'Exporter';
our @EXPORT_OK = qw/permission/;

use Csistck::Oper qw/debug/;
use Csistck::Test;

use File::stat;

# Input is src (glob as string), and assoc. array of permisison checks
sub permission {
    my $src = shift;
    my %args = @_; # assoc array to hash

    # Get glob of files
    my @files = glob($src);
     
    # Return array of tests
    return map { permission_build_test($src, \%args); } @files;
}

# Helper function to avoid same scope in map and to build test
sub permission_build_test {
    my ($src, $args) = @_;
    
    # Bad arguments
    die("Invalid arguments")
     if (!defined $args or !ref $args eq "HASH");
    
    return Csistck::Test->new(
        check => sub { permission_process($src, $args); },
        repair => sub { permission_process($src, $args); },
        desc => "Permission check on $_"
    );
}

# First is file, second call is hash of args
sub permission_process {
    my $file = shift;
    my $args = shift;

    # Make sure dest is a path
    die("Path not found")
      if (! -e $file);
    
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
    die("Invalid file mode")
      if ($mode !~ m/^[0-7]{3,4}$/);

    die("File mode does not match")
      unless (mode_compare($file, $mode));
}

sub uid_process {
    my ($file, $uid) = @_;

    # Check uid is legit
    die("Invalid user id")
      if ($uid !~ m/^[0-9]+$/);

    # Run check, repair if fixing
    die("File uid does not match")
      unless (uid_compare($file, $uid));
}

sub gid_process {
    my ($file, $gid) = @_;

    # Check gid is legit
    die("Invalid group id")
      if ($gid !~ m/^[0-9]+$/);

    # Run check, repair if fixing
    die("File gid does not match")
      unless (gid_compare($file, $gid));
}

# Compare all files
sub mode_compare {
    my ($file, $mode) = @_;
    
    # Don't accept honkey permissions
    $mode =~ s/^([0-7]{3})$/0$1/; 

    my $fh = stat($file);

    if ($fh) {
        my $curmode = sprintf "%04o", $fh->mode & 07777;
        debug("File mode: file=<$file> mode=<$curmode>");
        return ($curmode eq $mode);
    }

    return 0;
}

# Repair mode
sub mode_repair {
    my ($file, $mode) = @_;

    debug("Chmod file: file=<$file> mode=<$mode>");
    
    chmod(oct($mode), $file) or die("Failed to chmod file: $file") if (fix());

    return
}

# Compare uid
sub uid_compare {
    my ($file, $uid) = @_;
    
    my $fh = stat($file);

    if ($fh) {
        my $curuid = $fh->uid;
        debug("File owner: file=<$file> uid=<$uid>");
        return ($curuid == $uid);
    }

    return 0;
}

# Repair uid
sub uid_repair {
    my ($file, $uid) = @_;

    debug("Chown file: file=<$file> uid=<$uid>");
    
    chown($uid, -1, $file) or die("Failed to chown file: $file") if (fix());

    return
}

# Compare gid
sub gid_compare {
    my ($file, $gid) = @_;
    
    my $fh = stat($file);

    if ($fh) {
        my $curgid = $fh->gid;
        debug("File group: file=<$file> gid=<$gid>");
        return ($curgid == $gid);
    }

    return 0;
}

# Repair gid
sub gid_repair {
    my ($file, $gid) = @_;

    debug("Chown file: file=<$file> gid=<$gid>");
    
    chown(-1, $gid, $file) or die("Failed to chown file: $file") if (fix());

    return
}



1;
__END__

=head1 NAME

Csistck::Test::Permission - Csistck permission check

=head1 DESCRIPTION

=head1 METHODS

=head2 permission($glob, %args)

Change permission and ownership on file glob pattern. Arguments should be
passed as a hashref that consists of any of the following keys:

=over

=item mode =E<gt> [string]

Change files matching file glob pattern to the specified numerical mode. Mode
should be specified as a string of numbers, ie: '0755'.

=item uid =E<gt> [integer]

Change owner of files matching file glob pattern to the specified user ID.

=item gid =E<gt> [integer]

Change group of files matching file glob pattern to the specified group ID.

=back

=head1 AUTHOR

Anthony Johnson, E<lt>anthony@ohess.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2011 Anthony Johnson

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,

