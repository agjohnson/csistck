package Csistck::Oper;

use 5.010;
use strict;
use warnings;

use base 'Exporter';

our @EXPORT_OK = qw/
    debug error info
    repair
/;

use Carp;
use Getopt::Long;

# Logging levels, default boolean
our $Modes = { 
    debug => 0,
    error => 1,
    info => 0
};

# Boolean options
our $Options = {
    verbose => 0,
    debug => 0,
    quiet => 0,
    repair => 0
};

# Dynamic setup of reporting functions
for my $level (keys %{$Modes}) {

    no strict 'refs';

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

# Repair mode accessor
sub repair {
    return $Options->{repair};
}

# Set up mode via command line options
sub set_mode_by_cli {

    # Map options (as getopt negatable option) to $Options
    # TODO more options
    my %opts = map { +"$_!" => \$Options->{$_} } keys %{$Options};
    my $result = GetOptions(%opts);

    # Set reporting mode based on options
    $Modes->{info} = ($Options->{verbose}) ? 1 : 0;
    $Modes->{debug} = ($Options->{debug}) ? 1 : 0;
    $Modes->{error} = ($Options->{quiet}) ? 0 : 1;
}

sub log_message {
    my $level = shift;
    my $msg = shift;
    
    printf("[%s]\ %s\n", uc($level), $msg);
}

1;
