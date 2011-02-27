package Csistck::Test::Script;

use 5.010;
use strict;
use warnings;

use base 'Exporter';
our @EXPORT_OK = qw/script/;

use Csistck::Oper qw/debug/;
use Csistck::Config qw/option/;
use Csistck::Test;

use Digest::MD5;
use File::Basename;
use FindBin;

use constant MODE_CHECK => 'check';
use constant MODE_RUN => 'run';

sub script {
    my $script = shift;
    my @args = @_;

    return Csistck::Test->new(
        sub { script_run(MODE_CHECK, $script, @args); },
        sub { script_run(MODE_RUN, $script, @args); },
        "Executing script $script"
    );
}

sub script_run {
    my $mode = shift;
    my $script = shift;
    my @args = @_;

    # TODO sanity check on script

    # Build command
    my @command = ($script, $mode, @args);
    
    debug(sprintf("Run command: %s", join(" ", @command)));
    
    # my $ret = system("$cmd 1>/dev/null 2>/dev/null");
    chdir($FindBin::Bin);
    my $ret = system(@command);

    die("Command returned $ret")
      unless($ret == 0);
}

1;
