package Csistck::Oper;

use 5.010;
use strict;
use warnings;

use base 'Exporter';

our @EXPORT = qw/
    OKAY
    FAIL
    DEBUG
    DIFF
    FIX
    okay
    fail
    debug
    diff
    fix
/;

use Carp;
use Getopt::Long;

# Run mode levels
use constant OKAY => 1;   
use constant FAIL => 2;
use constant DEBUG => 4;
use constant DIFF => 8;
use constant FIX => 16;

# For now, constant referencing from strings isn't working out.
my $Modes = { 
    okay => OKAY, 
    fail => FAIL, 
    debug => DEBUG, 
    diff => DIFF, 
    fix => FIX 
};

# Run mode. Default to passing ok and fail
my $Mode = 0;

# Dynamic setup of functions for levels
for my $level (keys %{$Modes}) {

    no strict 'refs';

    # Set up reporting functions
    *{"Csistck\::Oper\::$level"} = sub {
        my $func = shift;

        # Maybe this isn't the best way. If func is passed and
        # is code, execute. If func is passed and is a scalar,
        # debug it?!
        if (defined $func and ($Mode & $Modes->{$level})) {
            given (ref $func) {
                when ("CODE") { return &$func; };
                when ("") { return log_message($level, $func) };
            }
        }
        else {
            # Bitewise and to test for mode
            return $Mode & $Modes->{$level};
        }
    };
}


# Set up mode via command line options
sub set_mode_by_cli {
    my $levels = { map { $_ => 0 } keys %{$Modes} }; 

    my %opts = map { $_ => \$levels->{$_} } keys %{$Modes};
    my $result = GetOptions( %opts );

    # Iterate through options, bitwise OR values
    for my $lvl (keys %{$Modes}) {
        $Mode |= $Modes->{$lvl}
          if ($levels->{$lvl});
    }
}

sub log_message {
    my $level = shift;
    my $msg = shift;
    
    say "$level\: $msg";
}

1;
