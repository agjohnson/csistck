package Csistck::Test::Template;

use 5.010;
use strict;
use warnings;

use base 'Exporter';
our @EXPORT_OK = qw/template/;

use Csistck::Oper;
use Template;
use File::Copy;
use Sys::Hostname;
use FindBin;

sub template {
    my $template = shift;
    my $dest = shift;
    my $args = shift // {};

    return sub { template_process($template, $dest, $args); };
}

sub template_process {
    my ($template, $dest, $args) = @_;

    # Add arguments, process template
    my $template_path = join "/", $FindBin::Bin, $template;
    my $tplout;
    my $args_add = {
        hostname => hostname,
        %{$args}
    };
    template_file($template_path, \$tplout, $args_add)
      or fail("Template file $template_path not processed");
    
    my $hashsrc = string_hash($tplout);
    my $hashdst = file_hash($dest);

    if (defined $hashsrc and defined $hashdst and ($hashsrc eq $hashdst)) {
        return okay(sprintf "Template %s matches %s", $template_path, $dest);
    }
    else {
        fail(sprintf "Template %s doesn't match %s", $template_path, $dest);
        if (fix() or diff()) {
            template_install($template_path, $dest, $args_add);
        }
    } 
}

sub template_install {
    my ($template, $dest, $args) = @_;

    diff("Output template <template=$template> <dest=$dest>");
    
    if (-e $dest) {
        # Exists, but is a directory
        return fail("Destination $dest exists and is not a file")
          if (-d $dest);
        # Exists but isn't writable
        return fail("Destination $dest exists is is not writable")
          if (-f $dest and ! -w $dest);
    }


    open(my $h, '>', $dest) or die("Permission denied writing template");
    template_file($template, $h, $args);
    close($h);
}

sub template_file {
    my $file = shift;
    my $out = shift;
    my $args = shift;
    
    # Create Template object, no config for now
    my $t = Template->new();
    
    if (-r $file) {
        open(my $h, $file);
        $t->process($h, $args, $out) or die $t->error();
        close($h);
        return 1;
    }

    return 0;
}

sub string_hash {
    my $string = shift;

    my $hash = Digest::MD5->new();
    $hash->add($string);

    return $hash->hexdigest();
}

sub file_hash {
    my $file = shift;

    if (-r $file) {
        open(my $h, $file);
        
        my $hash = Digest::MD5->new();
        $hash->addfile($h);
        close($h);

        return $hash->hexdigest();
    }

    return undef;
}

1;
