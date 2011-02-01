package Csistck;

use 5.010;
use strict;
use warnings;

our $VERSION = '0.01';

# We export function in the main namespace
use base 'Exporter';
our @EXPORT = qw(
    host
    role
    check
    option

    file
    noop
    permission
    pkg
    template
);

# Imports for base
use Csistck::Config;
use Csistck::Test::NOOP;
use Csistck::Test::File;
use Csistck::Test::Permission;
use Csistck::Test::Pkg;
use Csistck::Test::Template;

use Sys::Hostname;
use Data::Dumper;

# Exports from other classes
sub option { Csistck::Config::option(@_); }
sub file { Csistck::Test::File::file(@_); }
sub noop { Csistck::Test::NOOP::noop(@_); }
sub permission { Csistck::Test::Permission::permission(@_); }
sub pkg { Csistck::Test::Pkg::pkg(@_); }
sub template { Csistck::Test::Template::template(@_); }


# Package wide
my $Hosts = {};
my $Roles = {};

sub host {
    my $hostname = shift;

    # Add domain if option is set?
    my $domain_name = Csistck::Config::option('domain_name');
    $hostname = join '.', $hostname, $domain_name
      if (defined $domain_name);

    while (my $require = shift) {
        push(@{$Hosts->{$hostname}}, $require);
    }

    return $Hosts->{$hostname};
}

sub role {
    my $role = shift;

    # If tests specified, add now
    while (my $require = shift) {
        push(@{$Roles->{$role}}, $require);
    }

    return sub { 
        # Run required role or die
        if(defined $Roles->{$role}) {
            for my $require (@{$Roles->{$role}}) {
                &$require();
            }
        }
        else {
            die ("What's this, \"${role}\"? That role is bupkis.");
        }
    }
}

sub check {
    my $hostname = shift // hostname;

    # Get options by command line
    Csistck::Oper::set_mode_by_cli();

    if (defined $Hosts->{$hostname}) {
        for my $require (@{$Hosts->{$hostname}}) {
            &$require();
        }
    }
    else {
        die ("What's this, \"${hostname}\"? That host is bupkis.");
    }
}

1;
__END__

=head1 NAME

Csistck - Perl extension for blah blah blah

=head1 SYNOPSIS

A simple example of using csistck to create an executable management
script:

    use Csistck;
    
    for my $host (qw/a b/) {
        host $host => role('test');
    }

    host 'c' => role('test');
    
    role 'test' => 
        template(".files/test.tt", "/tmp/test", { text => "Some text here" }),
        permission("/tmp/test*", mode => '0777', uid => 100, gid => 100);
    
    check;

The script can then be called directly, using command line arguements below

=head1 DESCRIPTION

Csistck is a configuration management tool that falls somewhere in between
the management tools slack and chef.

The model of csistck is more complex than slack, requiring syntax knowledge 
of Perl and knowledge of csistck calls. However, having used slack for a 
short period of time -- and having struggled to adapt slightly more complex
usage to slacks's simplistic model -- csistck was designed under a similar
philosophy goal to keep usage as simple as possible.

To say chef is more complex than csistck is a heavy understatement. The model
of csistck clearly pulls from chef, however the aim of csistck isn't meant to be
a mere port of chef to Perl. Where both chef and csistck aim to provide
consistency checks, csistck does not aim to provide the depth of checks 
and resolution that chef provides. 

=head1 SCRIPT USAGE

The following options are recognized in a csistck based script

=over 8

=item B<--okay>

Display okay returns on tests

=item B<--fail>

Display failure returns on tests

=item B<--debug>

Display debug messages

=item B<--diff>

Display file diff and test differences

=item B<--fix>

Fix differences in files and tests

=back

=head1 AUTHOR

Anthony Johnson, E<lt>anthony@ohess.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 by Anthony Johnson

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.1 or,
at your option, any later version of Perl 5 you may have available.


=cut

