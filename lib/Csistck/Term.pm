package Csistck::Term;

use 5.010;
use strict;
use warnings;

use base 'Exporter';

use Term::ReadKey;
use Csistck::Test;

our @EXPORT_OK = qw/
    prompt
/;

# Interactive terminal prompt. Takes in test as argument, and displays action 
# options
sub prompt {
    my $test = shift;
    my %options;

    # Ask question loop, get input. If choices are not code refs, do not show choice
    say("What would you like to:");
    my @choices = ();
    # Repair
    if ($test->has_repair()) {
        say("  Y : Repair");
        push(@choices, 'Y');
    }
    # Skip
    say("  N : Skip");
    push(@choices, 'n');
    # DIff
    if ($test->has_diff()) {
        say("  D : Diff");
        push(@choices, 'd');
    }
    print("[Y/n/d]? ");
    
    ReadMode 3;
    my $action = ReadKey(0);
    say($action); 
    ReadMode 0;
    
    given ($action) {
        when (/[Yy\n]/) { 
            $test->repair() if ($test->has_repair());
        }
        when (/[Dd]/) { 
            # Show diff, loop through prompt again
            $test->diff() if ($test->has_diff());
            prompt($test);
        }
        default {}
    }
}

1;
