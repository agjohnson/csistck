package Csistck::Test;

use 5.010;
use strict;
use warnings;

use Csistck::Oper;

sub new {
    my $class = shift;
    my %args = @_;
    my $args = \%args;
    
    # Require both functions
    die ("Check subroutine not specified")
      unless (defined $args->{check});
    die ("Repair subroutine not specified")
      unless (defined $args->{repair});

    # Build Test object to bless and return
    my $self = {};
    $self->{CHECK} = $args->{check};
    $self->{REPAIR} = $args->{repair};
    $self->{DIFF} = $args->{diff} // undef;
    $self->{DESC} = $args->{desc} // "Unidentified test";
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
        Csistck::Oper::error("$self->{DESC}: $error");
        return 0;
    }
    else {
        Csistck::Oper::info("$self->{DESC}");
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
        Csistck::Oper::error("Repairing $self->{DESC}: $error");
        return 0;
    }
    else {
        Csistck::Oper::info("Repairing $self->{DESC}");
        return 1;
    }   
}

# Diff, show some form of diff for interactive mode
sub diff {
    my $self = shift;

    # No diff code defined
    unless (defined $self->{DIFF}) {
        return 1;
    }

    die ("Not a code reference")
      unless (ref $self->{DIFF} eq "CODE");

    # Execute code reference in eval, return response
    eval { &{$self->{DIFF}}; };

    return 1;
}

1;
