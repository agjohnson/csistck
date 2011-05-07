package Csistck::Term;

use 5.010;
use strict;
use warnings;

use base 'Exporter';

use Term::ReadKey;

our @EXPORT_OK = qw/
    prompt
/;

# Interactive terminal prompt
sub prompt {
    my %args = @_;
    my $args = \%args;
    my %options;

    # TODO check repair and diff are coderefs?

    # Set repair and diff if defined
    my $repair = $args->{repair} // undef;
    my $diff = $args->{diff} // undef;
    
    # Ask question loop, get input
    say("What would you like to:");
    say("  Y : Repair");
    say("  N : Skip");
    say("  D : Diff");
    print("[Y/n/d]? ");
    
    ReadMode 3;
    my $action = ReadKey(0);
    say($action); 
    ReadMode 0;
    
    given ($action) {
        when (/[Yy\n]/) { &{$repair} if (defined $repair); }
        when (/[Dd]/) { 
            # Show diff, loop through prompt again
            &{$diff} if (defined $diff);
            prompt(
              repair => $repair,
              diff => $diff
            );
        }
        default {}
    }
}

1;
