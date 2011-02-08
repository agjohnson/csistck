package Csistck::Test::Pkg;

use 5.010;
use strict;
use warnings;

use base 'Exporter';
our @EXPORT_OK = qw/pkg/;

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

        if (pkg_check($pkg, $type) == EXISTS) {
            return okay(sprintf "Package %s found, using %s", $pkg, $type);
        }
        else {
            fail(sprintf "Package %s not found, using %s", $pkg, $type);
            pkg_install($pkg, $type) if (fix() or diff());
            return 0;
        }
    }
}

sub pkg_check {
    my ($pkg, $type) = @_;
    my $cmd = "";

    # Test package name
    return fail('Invalid package name')
      unless ($pkg =~ m/^[A-Za-z0-9\-\_\.]+$/);

    # Decide command, execute. Return MISSING by default
    given ($type) {
        when ('dpkg') { $cmd = "dpkg -s \"$pkg\""; };
        when ('pacman') { $cmd = "pacman -Qe \"$pkg\""; };
    }
    
    my $ret = system("$cmd 1>/dev/null 2>/dev/null");
    if ($ret == 0) {
        return EXISTS;
    }

    return MISSING;
}

# Package install
sub pkg_install {
    my ($pkg, $type) = @_;
    my $cmd = "";
    
    # Test package name
    return fail('Invalid package name')
      unless ($pkg =~ m/^[A-Za-z0-9\-\_\.]+$/);
    
    given ($type) {
        when ("dpkg") { $cmd = "apt-get -qq -y install \"$pkg\""; };
        when ("pacman") { $cmd = "pacman -Sq --noconfirm \"$pkg\""; };
    }
    
    diff("Install package via command: $cmd");

    if (fix()) {
        my $ret = system("$cmd 1>/dev/null 2>/dev/null");
        if ($ret == 0) {
            return okay("Package $pkg installed");
        }
        else {
            return fail("Package $pkg installation failed");
        }
    }
}

1;
