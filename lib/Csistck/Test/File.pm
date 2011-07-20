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
        check => sub { file_check($src, $dest_abs); },
        repair => sub { file_install($src, $dest_abs); },
        diff => sub { file_diff($src, $dest_abs); },
        desc => "File check on $src"
    );
}

# Check file and file in destination are the same via md5
sub file_check {
    my $src = shift;
    my $dest = shift;

    die("Files do not match: src=<$src> dest=<$dest>")
      unless(file_compare($src, $dest));
}

# Copy file to destination
sub file_install {
    my ($src, $dest) = @_;
    
    backup_file($dest)
      if(-f -e -r $dest);

    debug("Copying file: <src=$src> <dest=$dest>");

    copy($src, $dest) or die("Failed to copy file: $!: src=<$src> dest=<$dest>");
}

# Diff for files
sub file_diff {
    my ($src, $dest) = @_;

    say(Text::Diff::diff($dest, $src))
      if(-f -e -r $dest);
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
__END__

=head1 NAME

Csistck::Test::File - Csistck file check

=head1 DESCRIPTION

=head1 METHODS

=head2 file($glob, $target)

Select files using file glob pattern and copy files into target path. Target
path should be a directory, not a file.

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

