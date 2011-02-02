package Csistck::Test::Pkg;

use 5.010;
use strict;
use warnings;

use Csistck::Oper;
use Csistck::Config qw/option/;

# Package command return
use constant EXISTS => 1;
use constant MISSING => 0;

use Digest::MD5;
use File::Basename;

sub pkg {
    my $pkg = shift;
    my $type = shift;

    # Default package type
    $type = option('pkg_type') // 'dpkg'
      unless (defined $type);

    return sub {
        my $ret = MISSING;

        # Given package type, run command
        given ($type) {
            when ("pacman") { $ret = check_pacman($pkg); };
            when ("dpkg") { $ret = check_dpkg($pkg); };
        }

        if ($ret == EXISTS) {
            okay(sprintf "Package %s found, using %s", $pkg, $type);
        }
        else {
            fail(sprintf "Package %s not found, using %s", $pkg, $type);
        }
    }
}

sub check_pacman {
    my $pkg = shift;
    
    if($pkg =~ m/^[A-Za-z0-9\-\_\.]+$/) {
        my $ret = system("pacman -Qe $pkg &>/dev/null");
        if ($ret == 0) {
            return EXISTS;
        }
    }

    return MISSING;
}

sub check_dpkg {
    my $pkg = shift;

    if($pkg =~ m/^[A-Za-z0-9\-\_\.]+$/) {
        my $ret = system("dpkg -L $pkg &>/dev/null");
        if ($ret == 0) {
            return EXISTS;
        }
    }

    return MISSING;
}

1;
