package Csistck;

use 5.010001;
use strict;
use warnings;

our $VERSION = '0.01';

# We export function in the main namespace
use base 'Exporter';
our @EXPORT = qw(
    host
    role
    check

    file
    noop
    permission
    pkg
    template
);

# Imports for base
use Csistck::Test::NOOP;
use Csistck::Test::File;
use Csistck::Test::Permission;
use Csistck::Test::Pkg;
use Csistck::Test::Template;

use Sys::Hostname;
use Data::Dumper;

# Exports from other classes
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

  use Csistck;
  blah blah blah

=head1 DESCRIPTION

Blah blah blah.

=head1 AUTHOR

Anthony Johnson, E<lt>anthony@ohess.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 by Anthony Johnson

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.1 or,
at your option, any later version of Perl 5 you may have available.


=cut

