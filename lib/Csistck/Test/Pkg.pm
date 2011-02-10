package Csistck::Test::Pkg;

use 5.010;
use strict;
use warnings;

use base 'Exporter';
our @EXPORT_OK = qw/pkg/;

use Csistck::Oper qw/debug/;
use Csistck::Config qw/option/;
use Csistck::Test;

use Digest::MD5;
use File::Basename;

sub pkg {
    my $pkg = shift;
    my $type = shift;

    # Default package type
    $type = option('pkg_type') // 'dpkg'
      unless (defined $type);

    return Csistck::Test->new(
        sub { pkg_check($pkg, $type); },
        sub { pkg_install($pkg, $type); },
        "Searching for package $pkg, using $type"
    );
}

sub pkg_check {
    my ($pkg, $type) = @_;
    my $cmd = "";

    # Test package name
    die('Invalid package name')
      unless ($pkg =~ m/^[A-Za-z0-9\-\_\.]+$/);

    # Decide command, execute. Die on failure
    given ($type) {
        when ('dpkg') { $cmd = "dpkg -L \"$pkg\""; };
        when ('pacman') { $cmd = "pacman -Qe \"$pkg\""; };
    }
    
    debug("Searching for package via command: $cmd");
    
    my $ret = system("$cmd 1>/dev/null 2>/dev/null");

    die("Package missing")
      unless($ret == 0);
}

# Package install
sub pkg_install {
    my ($pkg, $type) = @_;
    my $cmd = "";
    
    # Test package name
    die('Invalid package name')
      unless ($pkg =~ m/^[A-Za-z0-9\-\_\.]+$/);
    
    given ($type) {
        when ("dpkg") { 
            $ENV{DEBIAN_FRONTEND} = "noninteractive";
            $cmd = "apt-get -qq -y install \"$pkg\""; 
        }
        when ("pacman") { $cmd = "pacman -Sq --noconfirm \"$pkg\""; };
    }
    
    debug("Installing package via command: $cmd");

    my $ret = system("$cmd 1>/dev/null 2>/dev/null");

    die("Package installation failed")
      unless ($ret == 0);
}

1;
