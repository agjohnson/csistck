package Csistck::Test;

use 5.010;
use strict;
use warnings;

use base 'Exporter';
use Csistck::Oper;

sub new {
    my $class = shift;
    my %args = @_;
    my $args = \%args;
    
    # Build Test object to bless and return
    my $self = {};
    $self->{CHECK} = sub { };
    $self->{REPAIR} = sub { };
    $self->{DIFF} = undef;
    $self->{DESC} = "Unidentified test";
    bless $self, $class;
    return $self;
}

# Check, use eval to catch fatal errors in test
sub check {
    my $self = shift;

    die ("Not a code reference")
      unless (ref $self->{CHECK} eq "CODE");
    
    # Execute code reference in eval, return response
    Csistck::Oper::info("$self->{DESC}");
    eval { &{$self->{CHECK}}; };

    if ($@) {
        my $error = $@;
        $error =~ s/ at [A-Za-z0-9\/\_\-\.]+ line [0-9]+.\n//;
        Csistck::Oper::error("$self->{DESC}: $error");
        return 0;
    }
    else {
        return 1;
    }   
}

# Repair, use eval to catch fatal errors in repair
sub repair {
    my $self = shift;

    die ("Not a code reference")
      unless ($self->has_repair());
    
    # Execute code reference in eval, return response
    Csistck::Oper::info("Repairing $self->{DESC}");
    eval { &{$self->{REPAIR}}; };

    if ($@) {
        my $error = $@;
        $error =~ s/ at [A-Za-z0-9\/\_\-\.]+ line [0-9]+.\n//;
        Csistck::Oper::error("Repairing $self->{DESC}: $error");
        return 0;
    }
    else {
        return 1;
    }   
}

# Returns if test object has proper repair action
sub has_repair {
    my $self = shift;

    return 1
      if (ref $self->{REPAIR} eq 'CODE');

    return 0;
}

# Diff, show some form of diff for interactive mode
sub diff {
    my $self = shift;

    # No diff code defined
    unless (defined $self->{DIFF}) {
        return 1;
    }

    die ("Not a code reference")
      unless ($self->has_diff());

    # Execute code reference in eval, return response
    eval { &{$self->{DIFF}}; };

    return 1;
}

# Returns if test object has proper diff action
sub has_diff {
    my $self = shift;

    return 1
      if (ref $self->{DIFF} eq 'CODE');

    return 0;
}

1;
