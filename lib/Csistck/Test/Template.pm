package Csistck::Test::Template;

use 5.010;
use strict;
use warnings;

use base 'Exporter';
our @EXPORT_OK = qw/template/;

use Csistck::Oper qw/debug/;
use Csistck::Util qw/backup_file hash_file hash_string/;
use Csistck::Test;

use Template;
use File::Copy;
use Sys::Hostname::Long qw//;
use FindBin;
use Text::Diff ();

sub template {
    my $template = shift;
    my $dest = shift;
    my $args = shift // {};

    # Die on invalid arguments
    die("Invalid template name")
      unless($template =~ /^[A-Za-z0-9\-\_][A-Za-z0-9\/\-\_\.]+$/);
    die("Destination not specified")
      unless(defined $dest);
    
    # Get full template path, return Test
    my $abs_tpl = get_absolute_template($template);

    # Add automatic arguments
    my $args_add = {
        hostname => Sys::Hostname::Long::hostname_long(),
        %{$args}
    };

    return Csistck::Test->new(
      check => sub { template_check($abs_tpl, $dest, $args_add); },
      repair => sub { template_install($abs_tpl, $dest, $args_add); },
      diff => sub { template_diff($abs_tpl, $dest, $args_add); },
      desc => "Process template $template for destination $dest"
    );
}

sub template_check {
    my ($template, $dest, $args) = @_;
    my $tplout;

    template_file($template, \$tplout, $args)
      or die("Template file not processed: template=<$template>");
    
    my $hashsrc = hash_string($tplout);
    my $hashdst = hash_file($dest);
    
    die("Template output does not match destination")
      unless(defined $hashsrc and defined $hashdst and ($hashsrc eq $hashdst));
}

sub template_install {
    my ($template, $dest, $args) = @_;

    # Try to catch some errors
    if (-e $dest) {
        die("Destination $dest exists and is not a file")
          if (-d $dest);
        die("Destination $dest exists is is not writable")
          if (-f $dest and ! -w $dest);
    }
        
    # Backup file
    backup_file($dest)
      if (-f -e -r $dest);

    debug("Output template: template=<$template> dest=<$dest>");

    open(my $h, '>', $dest) 
      or die("Permission denied writing template");
    template_file($template, $h, $args);
    close($h);
}

sub template_diff {
    my ($template, $dest, $args) = @_;

    # Try to catch some errors
    if (-e $dest) {
        die("Destination exists and is not a file: dest=<$dest>")
          if (-d $dest);
        die("Destination exists is is not writable: dest=<$dest>")
          if (-f $dest and ! -w $dest);
    }
    else {
        die("Destination file does not exist: dest=<$dest>");
    }
        
    if (-f -e -r $dest) {
        my $temp_h;
        template_file($template, \$temp_h, $args);
        say(Text::Diff::diff($dest, \$temp_h));
    }
}

# Processing absoulte template name and outputs to reference
# variable $out. Die on error or unreadable template file
sub template_file {
    my $file = shift;
    my $out = shift;
    my $args = shift;
    
    # Create Template object, no config for now
    my $t = Template->new();
    
    die("Template not found")
      if(! -e $file);
    die("Permission denied reading template")
      if(! -r $file);

    open(my $h, $file);
    $t->process($h, $args, $out) or die $t->error();
    close($h);
}

# Get absoulte path from relative path
# TODO error checking
sub get_absolute_template {
    my $template = shift;

    return join "/", $FindBin::Bin, $template;
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


