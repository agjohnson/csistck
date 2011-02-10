package Csistck::Test;

use 5.010;
use strict;
use warnings;

use Csistck::Oper;

sub new {
    my $class = shift;
    my ($check, $repair, $desc) = @_;

    # Require both functions
    die ("Check subroutine not specified")
      unless (defined $check);
    die ("Repair subroutine not specified")
      unless (defined $repair);

    # Build Test object to bless and return
    my $self = {};
    $self->{CHECK} = $check;
    $self->{REPAIR} = $repair;
    $self->{DESC} = $desc // "Unidentified test";
    bless $self, $class;
    return $self;
}

# Check, use eval to catch fatal errors in test
sub check {
    my $self = shift;

    die ("Not a code reference")
      unless (ref $self->{CHECK} eq "CODE");

    # Execute code reference in eval, return response
    eval { &{$self->{CHECK}}; };

    if ($@) {
        my $error = $@;
        $error =~ s/ at [A-Za-z0-9\/\_\-\.]+ line [0-9]+.\n//;
        Csistck::Oper::fail("$self->{DESC}: $error");
        return 0;
    }
    else {
        Csistck::Oper::okay("$self->{DESC}");
        return 1;
    }   
}

# Repair, use eval to catch fatal errors in repair
sub repair {
    my $self = shift;

    die ("Not a code reference")
      unless (ref $self->{REPAIR} eq "CODE");

    # Execute code reference in eval, return response
    eval { &{$self->{REPAIR}}; };

    if ($@) {
        my $error = $@;
        $error =~ s/ at [A-Za-z0-9\/\_\-\.]+ line [0-9]+.\n//;
        Csistck::Oper::fail("Repairing $self->{DESC}: $error");
        return 0;
    }
    else {
        Csistck::Oper::okay("Repairing $self->{DESC}");
        return 1;
    }   
}

1;
