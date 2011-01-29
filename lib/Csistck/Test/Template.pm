package Csistck::Test::Template;

use 5.010;
use strict;
use warnings;

use Csistck::Oper;
use Template;
use File::Copy;
use Data::Dumper;

sub template {
    my $template = shift;
    my $dest = shift;
    my $args = shift;

    return sub { template_process($template, $dest, $args); };
}

sub template_process {
    my ($template, $dest, $args) = @_;

    # Process template and output to reference
    my $tplout;
    template_file($template, \$tplout, $args);
    
    my $hashsrc = string_hash($tplout);
    my $hashdst = file_hash($dest);

    if (defined $hashsrc and defined $hashdst and ($hashsrc eq $hashdst)) {
        return okay(sprintf "Template %s matches %s", $template, $dest);
    }
    else {
        fail(sprintf "Template %s doesn't match %s", $template, $dest);
        if (fix()) {
            template_install($template, $dest, $args);
        }
    } 
}

sub template_install {
    my ($template, $dest, $args) = @_;

    diff("Output template <template=$template> <dest=$dest>");

    if (-f -w $dest) {
        open(my $h, '>', $dest);
        template_file($template, $h, $args);
        close($h);
    }
    else {
        fail("Destination $dest is not writable or is not a file.");
    }
}

sub template_file {
    my $file = shift;
    my $out = shift;
    my $args = shift;
    
    # Create Template object, no config for now
    my $t = Template->new();
    my $output = "";
    
    if (-r $file) {
        open(my $h, $file);
        $t->process($h, $args, $out) or die $t->error();
        close($h);
    }

    return $output;
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
