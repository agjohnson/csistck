package Csistck::Test::Template;

use 5.010;
use strict;
use warnings;

use base 'Exporter';
our @EXPORT_OK = qw/template/;

use Csistck::Oper qw/debug/;
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

    return Csistck::Test->new(
      sub { template_check($abs_tpl, $dest, $args); },
      sub { template_install($abs_tpl, $dest, $args); },
      "Process template $template for destination $dest"
    );
}

sub template_check {
    my ($template, $dest, $args) = @_;
    my $tplout;
    my $args_add = {
        hostname => hostname,
        %{$args}
    };

    template_file($template, \$tplout, $args_add)
      or die("Template file $template not processed");
    
    my $hashsrc = string_hash($tplout);
    my $hashdst = file_hash($dest);
    
    die("Template output does not match destination")
      unless(defined $hashsrc and defined $hashdst and ($hashsrc eq $hashdst));
}

sub template_install {
    my ($template, $dest, $args) = @_;

    debug("Output template <template=$template> <dest=$dest>");
    
    # Try to catch some errors
    if (-e $dest) {
        # Exists, but is a directory
        die("Destination $dest exists and is not a file")
          if (-d $dest);
        # Exists but isn't writable
        die("Destination $dest exists is is not writable")
          if (-f $dest and ! -w $dest);
    }

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

# Returns md5 hash of input string
sub string_hash {
    my $string = shift;

    my $hash = Digest::MD5->new();
    $hash->add($string);

    return $hash->hexdigest();
}

# Returns md5 hash of file
sub file_hash {
    my $file = shift;

    die("File not found")
      if(! -e $file);
    die("Permission denied hashing file")
      if(! -r $file);

    open(my $h, $file) or die("Problem opening file for hashing");
        
    my $hash = Digest::MD5->new();
    $hash->addfile($h);
    close($h);

    return $hash->hexdigest();
}

1;
