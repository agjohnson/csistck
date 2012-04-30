package Csistck::Test;

use 5.010;
use strict;
use warnings;

use base 'Exporter';
use Csistck::Oper;
use Csistck::Test::Return;

use Scalar::Util qw/blessed/;

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
    unless ($self->can($mode)) {
        return $self->fail('Test missing mode');
        # TODO make this better error
    };

    given ($mode) {
        when ("check") { $func = sub { $self->check } if ($self->can('check')); }
        when ("repair") { $func = sub { $self->repair } if ($self->can('repair')); }
        when ("diff") { $func = sub { $self->diff } if ($self->can('diff')); }
    }

    Csistck::Oper::info($self->desc);
    my $ret = eval { &{$func}; };
    
    # Catch errors
    if ($@) {
        my $error = $@;
        $error =~ s/ at [A-Za-z0-9\/\_\-\.]+ line [0-9]+.\n//;
        # TODO move error display
        # Csistck::Oper::error(sprintf("%s: %s", $self->desc, $error));
        return $self->fail($error);
    }
    
    # Return should be an object from now on. If not blessed, assume ret value
    if (blessed($ret) and $ret->isa('Csistck::Test::Return')) {
        return $ret;
    }
    else {
        return $self->ret($ret, "Test response");
    }   
}

# Return test response
sub ret {
    my ($self, $resp, $msg) = @_;
    return Csistck::Test::Return->new(
        desc => $self->desc,
        resp => $resp,
        msg => $msg
    );
}
sub fail { shift->ret(0, @_); }
sub pass { shift->ret(1, @_); }

1;
