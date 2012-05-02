package Csistck::Test::FileBase;

use 5.010;
use strict;
use warnings;

use base 'Csistck::Test';
use Csistck::Oper qw/debug/;
use Csistck::Util qw/backup_file hash_file hash_string/;

use Digest::MD5;
use File::Basename;
use File::Copy;
use FindBin;
use File::stat;
use Sys::Hostname::Long qw//;

sub desc { sprintf("File check on %s", shift->{target}); }
sub dest { shift->{target}; }
sub src { shift->{src}; }
sub mode { shift->{mode}; }
sub uid { shift->{uid}; }
sub gid { shift->{gid}; }

sub check {
    my $self = shift;
    my $ret = 1;

    die("Destination path not found")
      if (! -e $self->dest);
    
    # If we defined a source file
    if (defined($self->src) and $self->can('file_check')) {
        $ret &= $self->file_check;
    }
    $ret &= $self->mode_process(\&mode_check);
    $ret &= $self->uid_process(\&uid_check);
    $ret &= $self->gid_process(\&gid_check);

    return (($ret == 1) ? $self->pass('File matches') :
      $self->fail("File doesn't match"));
}

sub repair {
    my $self = shift;
    my $ret = 1;

    # If we defined a source file
    if (defined($self->src) and $self->can('file_repair')) {
        if (-e $self->dest) {
            die("Destination ${\$self->dest} is not a file")
              if (-d $self->dest);
            die("Destination ${\$self->dest} exists is is not writable")
              if (-f $self->dest and ! -w $self->dest);
            backup_file($self->dest);
        }
        
        $ret &= $self->file_repair;
    }
    $ret &= $self->mode_process(\&mode_repair);
    $ret &= $self->uid_process(\&uid_repair);
    $ret &= $self->gid_process(\&gid_repair);
    
    return (($ret == 1) ? $self->pass('File repaired') :
      $self->fail('File not repaired'));
}

# Diff for files
sub diff {
    my $self = shift;
    
    die("Destination file does not exist: dest=<${\$self->dest}>")
      unless (-f -e -r $self->dest);
    
    # If we defined a source file
    if (defined($self->src) and $self->can('file_diff')) {
        $self->file_diff();
    }

    # TODO mode, uid, gid diff functions
}

# Wrapper functions to perform sanity tests on arguments
# Return pass if arguments are missing, die if invalid
sub mode_process {
    my ($self, $func) = @_;

    return 1 unless($self->mode);
    my $mode = $self->mode;
    die("Invalid file mode")
      if ($mode !~ m/^[0-7]{3,4}$/);
    $mode =~ s/^([0-7]{3})$/0$1/;
    $self->{mode} = $mode;
    
    &{$func}($self->dest, $self->mode);
}

sub uid_process {
    my ($self, $func) = @_;

    return 1 unless ($self->uid);
    die("Invalid user id")
      if ($self->uid !~ m/^[0-9]+$/);
    
    &{$func}($self->dest, $self->uid);
}

sub gid_process {
    my ($self, $func) = @_;

    return 1 unless ($self->gid);
    die("Invalid group id")
      if ($self->gid !~ m/^[0-9]+$/);

    &{$func}($self->dest, $self->gid);
}

# Mode operations
sub mode_check {
    my ($file, $mode) = @_;
    my $fh = stat($file);
    if ($fh) {
        my $curmode = sprintf "%04o", $fh->mode & 07777;
        debug("File mode: file=<$file> mode=<$curmode>");
        return 1 if ($curmode eq $mode);
    }
}

sub mode_repair {
    my ($file, $mode) = @_;
    debug("Chmod file: file=<$file> mode=<$mode>");
    chmod(oct($mode), $file);
}

# UID operations
sub uid_check {
    my ($file, $uid) = @_;
    my $fh = stat($file);
    my $curuid = undef;
    if ($fh) {
        my $curuid = $fh->uid;
        debug("File owner: file=<$file> uid=<$uid>");
    }
    return ($curuid == $uid);
}

sub uid_repair {
    my ($file, $uid) = @_;
    debug("Chown file: file=<$file> uid=<$uid>");
    chown($uid, -1, $file);
}

# GID operations
sub gid_check {
    my ($file, $gid) = @_;
    my $fh = stat($file);
    my $curgid = undef;
    if ($fh) {
        $curgid = $fh->gid;
        debug("File group: file=<$file> gid=<$gid>");
    }
    return ($curgid == $gid);
}

sub gid_repair {
    my ($file, $gid) = @_;
    debug("Chown file: file=<$file> gid=<$gid>");
    chown(-1, $gid, $file);
}

# Compare hashes between two files
sub file_compare {
    my @files = @_;
    return 0 unless (scalar @files == 2);
    
    # Get hashes and return compare
    my ($hasha, $hashb) = map hash_file($_), @files;
    debug(sprintf "File compare result: <hash=%s> <hash=%s>", $hasha, $hashb);
    return ($hasha eq $hashb);
}

1;
__END__

=head1 NAME

Csistck::Test::Template - Csistck template check

=head1 DESCRIPTION

=head1 METHODS

=head2 template($template, $target, [%args])

Process template toolkit file and output to target path. Target
path should be a file in an existing path. 

    role 'test' => template('sys/motd.tt', '/etc/motd', { production => 1 });

Some arguments are automatically passed to the template processor:

=over

=item hostname

The full hostname of the current system

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
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.

=cut


