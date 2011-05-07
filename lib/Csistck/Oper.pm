package Csistck::Oper;

use 5.010;
use strict;
use warnings;

use base 'Exporter';

our @EXPORT_OK = qw/
    check repair
    okay fail debug
/;

use Carp;
use Getopt::Long;

# For now, constant referencing from strings isn't working out.
our $Modes = { 
    check => 1,
    repair => 0,
    okay => 0, 
    fail => 1, 
    debug => 0,
    error => 1,
    info => 0
};

# Dynamic setup of functions for levels
for my $level (keys %{$Modes}) {

    no strict 'refs';

    # Set up reporting functions
    *{"Csistck\::Oper\::$level"} = sub {
        my $func = shift;

        # Maybe this isn't the best way. If func is passed and
        # is code, execute. If func is passed and is a scalar,
        # debug it?!
        if (defined $func and $Modes->{$level}) {
            given (ref $func) {
                when ("CODE") { return &$func; };
                when ("") { return log_message($level, $func) };
            }
        }
        else {
            # Return mode
            return $Modes->{$level};
        }
    };
}

# Set up mode via command line options
sub set_mode_by_cli {
    # Map mode (as getopt negatable option) to $Modes
    my %opts = map { +"$_!" => \$Modes->{$_} } keys %{$Modes};
    my $result = GetOptions( %opts );
}

sub log_message {
    my $level = shift;
    my $msg = shift;
    
    printf("[%s]\ %s\n", uc($level), $msg);
}

1;
