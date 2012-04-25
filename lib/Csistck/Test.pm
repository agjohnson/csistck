package Csistck::Test;

use 5.010;
use strict;
use warnings;

use base 'Exporter';
use Csistck::Oper;

sub new {
    my $class = shift;
    my $target = shift;

    bless {
        desc => "Unidentified test",
        target => $target,
        on_repair => undef,
        @_
    }, $class;
}

sub desc { $_[0]->{desc}; }
sub target { $_[0]->{target}; }

sub on_repair { 
    my $func = $_[0]->{on_repair};
    return $func if (ref $func eq 'CODE');
}

# This is used to wrap processes
sub execute {
    my ($self, $mode) = @_;
    
    # We will exit with pass here, as to not throw an error. It is not the fault
    # of the user if the test has no check or repair operation
    my $func = sub {};
    return 1 unless ($self->can($mode));
    given ($mode) {
        when ("check") { $func = sub { $self->check } if ($self->can('check')); }
        when ("repair") { $func = sub { $self->repair } if ($self->can('repair')); }
        when ("diff") { $func = sub { $self->diff } if ($self->can('diff')); }
    }

    Csistck::Oper::info($self->desc);
    eval { &{$func}; };
    
    if ($@) {
        my $error = $@;
        $error =~ s/ at [A-Za-z0-9\/\_\-\.]+ line [0-9]+.\n//;
        Csistck::Oper::error(sprintf("%s: %s", $self->desc, $error));
        return 0;
    }
    else {
        return 1;
    }   
}

1;
