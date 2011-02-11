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
use Sys::Hostname;
use FindBin;

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
        hostname => hostname,
        %{$args}
    };

    return Csistck::Test->new(
      sub { template_check($abs_tpl, $dest, $args_add); },
      sub { template_install($abs_tpl, $dest, $args_add); },
      "Process template $template for destination $dest"
    );
}

sub template_check {
    my ($template, $dest, $args) = @_;
    my $tplout;

    template_file($template, \$tplout, $args)
      or die("Template file $template not processed");
    
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

    debug("Output template <template=$template> <dest=$dest>");

    open(my $h, '>', $dest) 
      or die("Permission denied writing template");
    template_file($template, $h, $args);
    close($h);
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
