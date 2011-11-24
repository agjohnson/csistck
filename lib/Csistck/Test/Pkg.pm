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

    # Currently, only dpkg support package install diff
    my $diff = undef;
    if ($type eq 'dpkg') {
        $diff = sub { pkg_diff($pkg, $type); };
    }

    return Csistck::Test->new(
        check => sub { pkg_check($pkg, $type); },
        repair => sub { pkg_install($pkg, $type); },
        diff => $diff,
        desc => "Searching for package $pkg, using $type"
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
    
    debug("Searching for package via command: cmd=<$cmd>");
    
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
    
    debug("Installing package via command: cmd=<$cmd>");

    my $ret = system("$cmd 1>/dev/null 2>/dev/null");

    die("Package installation failed")
      unless ($ret == 0);
}

# Package diff
sub pkg_diff {
    my ($pkg, $type) = @_;
    my $cmd = "";
    
    # Test package name
    die('Invalid package name')
      unless ($pkg =~ m/^[A-Za-z0-9\-\_\.]+$/);
    
    given ($type) {
        when ("dpkg") { 
            $ENV{DEBIAN_FRONTEND} = "noninteractive";
            $cmd = "apt-get -s install \"$pkg\""; 
        }
        default {}
    }
    
    debug("Showing package differences via command: cmd=<$cmd>");

    my $ret = system("$cmd 1>/dev/null 2>/dev/null");

    die("Package differences query failed")
      unless ($ret == 0);
}

1;
__END__

=head1 NAME

Csistck::Test::Pkg - Csistck package check

=head1 DESCRIPTION

=head1 METHODS

=head2 pkg($package, [$type])

Test for existing package using forks to system package managers. In repair mode,
install the package quietly. This is not an option for some package systems, such
as ports and pkgsrc; these package managers will fail without attempting to install
packages.

Supported package types:

=over

=item dpkg

Debian package management utility

=item pacman

Arch linux package management utility

=item More planned..

=back

=head1 OPTIONS

=over

=item pkg_type [string]

Set the default package type

=back

=head1 AUTHOR

Anthony Johnson, E<lt>anthony@ohess.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2011 Anthony Johnson

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,

