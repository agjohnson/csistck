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
     
    # Bad arguments
    die("Invalid arguments")
      if (! %args);
    
    # Return array of tests
    return map { permission_build_test($_, \%args); } @files;
}

sub permission_build_test {
    my ($file, $args) = @_;
    return Csistck::Test->new(
        check => sub { permission_process(0, $file, $args); },
        repair => sub { permission_process(1, $file, $args); },
        desc => "Permission check on $file"
    );
}

sub permission_process {
    my $repair = shift;
    my $file = shift;
    my $args = shift;

    # Make sure dest is a path
    die("Path not found")
      if (! -e $file);
    
    mode_process($repair, $file, $args->{mode})
      if (defined $args->{mode});
    uid_process($repair, $file, $args->{uid})
      if (defined $args->{uid});
    gid_process($repair, $file, $args->{gid})
      if (defined $args->{gid});
}

# Run test on file mode
sub mode_process {
    my ($repair, $file, $mode) = @_;

    # Check mode is legit
    die("Invalid file mode")
      if ($mode !~ m/^[0-7]{3,4}$/);

    ($repair) ? mode_repair($file, $mode) : mode_check($file, $mode);
}

sub uid_process {
    my ($repair, $file, $uid) = @_;

    # Check uid is legit
    die("Invalid user id")
      if ($uid !~ m/^[0-9]+$/);

    ($repair) ? uid_repair($file, $uid) : uid_check($file, $uid);
}

sub gid_process {
    my ($repair, $file, $gid) = @_;

    # Check gid is legit
    die("Invalid group id")
      if ($gid !~ m/^[0-9]+$/);

    ($repair) ? gid_repair($file, $gid) : gid_check($file, $gid);
}

# Compare all files
sub mode_check {
    my ($file, $mode) = @_;
    
    # Normalize permissions first
    $mode =~ s/^([0-7]{3})$/0$1/; 

    # Return if file is found and permissions match
    my $fh = stat($file);
    if ($fh) {
        my $curmode = sprintf "%04o", $fh->mode & 07777;
        debug("File mode: file=<$file> mode=<$curmode>");
        return if ($curmode eq $mode);
    }

    die("Permission check failed: $file");
}

# Repair mode
sub mode_repair {
    my ($file, $mode) = @_;

    debug("Chmod file: file=<$file> mode=<$mode>");
    chmod(oct($mode), $file) or die("Failed to chmod file: $file");
}

# Compare uid
sub uid_check {
    my ($file, $uid) = @_;
    
    # Return if file is found and uid matches
    my $fh = stat($file);
    if ($fh) {
        my $curuid = $fh->uid;
        debug("File owner: file=<$file> uid=<$uid>");
        return if ($curuid == $uid);
    }

    die("File ownership check failed: $file");
}

# Repair uid
sub uid_repair {
    my ($file, $uid) = @_;

    debug("Chown file: file=<$file> uid=<$uid>");
    chown($uid, -1, $file) or die("Failed to chown file: $file");
}

# Compare gid
sub gid_check {
    my ($file, $gid) = @_;
    
    # Return if file is found and gid matches
    my $fh = stat($file);
    if ($fh) {
        my $curgid = $fh->gid;
        debug("File group: file=<$file> gid=<$gid>");
        return if ($curgid == $gid);
    }

    die("File group ownership failed: $file");
}

# Repair gid
sub gid_repair {
    my ($file, $gid) = @_;

    debug("Chown file: file=<$file> gid=<$gid>");
    chown(-1, $gid, $file) or die("Failed to chown file: $file");
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

