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

# Conditionally use linux-only modules
BEGIN {
    if ("$^O" eq "linux") {
        require Linux::Distribution;
    }
}

our $Cmds = {
    dpkg => {
        check => 'dpkg -L "%s"',
        diff => 'apt-get -s install "%s"',
        install => 'apt-get -qq -y install "%s"'
    },
    rpm => {
        check => 'rpm -q "%s"',
        install => 'yum -q -y --noplugins install "%s"'
    },
    emerge => {
        check => 'equery -qC list "%s"',
        diff => 'emerge --color n -pq "%s"',
        install => 'emerge --color n -q "%s"'
    },
    pacman => {
        check => 'pacman -Qe "%s"',
        install => 'pacman -Sq --noconfirm "%s"'
    },
    pkg_info => {
        check => 'pkg_info -Qq "%s>0"'
    }
};

=head1 NAME

Csistck::Test::Pkg - Csistck package check

=head1 METHODS

=head2 pkg($package, [$type])

Test for existing package using forks to system package managers. Package can be
specified as a string, or as a hashref:

  pkg({
      dpkg => 'test-server',
      emerge => 'net-test',
      default => 'test-server'
  });

The package manager will be automatically detected if none is explicitly
specified, and the hashref key matching the package manager decides the package
name to check. If a default key is provided, that package is used by default.

In repair mode, install the package quietly, unless package manager doesn't
handle automating install.

Supported package managers:

=over

=item dpkg

Debian package management utility

=item pacman

Arch linux package management utility

=item More planned..

=back

=cut 

sub pkg {
    my $pkgref = shift;
    my $type = shift;
    my $pkg;
    my $diff;

    # Priority: 'type' argument, 'pkg_type' option, detect_pkg_manager.
    if (! $type) {
        $type = option('pkg_type') // detect_pkg_manager();
    }
    die("Bad package manager: manager=<$type>")
      if (! $type);
    die("Package manager not supported: type=<$type>")
      if (! $Cmds->{$type});
    
    $pkg = get_pkg($pkgref, $type);
    $diff = sub { pkg_diff($pkg, $type); }
      if ($Cmds->{$type}->{diff});
    
    return Csistck::Test->new(
        check => sub { pkg_check($pkg, $type); },
        repair => sub { pkg_install($pkg, $type); },
        diff => $diff,
        desc => "Searching for package $pkg, using $type"
    );
}

sub pkg_check {
    my ($pkg, $type) = @_;
    my $cmd = sprintf($Cmds->{$type}->{check}, $pkg) or
      die("Package check command missing: type=<$type>");

    debug("Searching for package via command: cmd=<$cmd>");    
    my $ret = system("$cmd 1>/dev/null 2>/dev/null");

    die("Package missing")
      unless($ret == 0);
}

# Package install
sub pkg_install {
    my ($pkg, $type) = @_;
    my $cmd;

    if (defined $Cmds->{$type}->{install}) {
        $cmd = sprintf($Cmds->{$type}->{install}, $pkg);
    }
    else {
        die("Package install command missing: type=<$type>");
    }

    $ENV{DEBIAN_FRONTEND} = "noninteractive";
    debug("Installing package via command: cmd=<$cmd>");
    my $ret = system("$cmd 1>/dev/null 2>/dev/null");

    die("Package installation failed")
      unless ($ret == 0);
}

# Package diff
sub pkg_diff {
    my ($pkg, $type) = @_;
    my $cmd = sprintf($Cmds->{$type}->{diff}, $pkg) or
      die("Package diff command missing: type=<$type>");
    
    $ENV{DEBIAN_FRONTEND} = "noninteractive";
    debug("Showing package differences via command: cmd=<$cmd>");
    my $ret = system("$cmd 2>/dev/null");

    die("Package differences query failed")
      unless ($ret == 0);
}

=head2 detect_pkg_manager()

Detect package manager based on system OS and Linux distribution if
applicable. Return package manager as string. This is not exported, it is 
used for the package test.

=cut

sub detect_pkg_manager {
    given ("$^O") {
        when (/^freebsd$/) { return 'pkg_info'; }
        when (/^netbsd$/) { return 'pkg_info'; }
        when (/^linux$/) { 
            given (distribution_name()) {
                when (/^(?:debian|ubuntu)$/) { return 'dpkg'; }
                when (/^(?:fedora|redhat|centos)$/) { return 'rpm'; }
                when (/^gentoo$/) { return 'emerge'; }
                when (/^arch$/) { return 'pacman'; }
                default { return undef; }
            }
        }
        when (/^darwin$/) { return undef; }
        default { return undef; }
    }
}

=head2 get_pkg($package, $type)

Based on input package, return package name. With OS and distribution detection,
$package can be passed as a string or a hashref.

See pkg() for information on passing hashrefs as package name

=cut

sub get_pkg {
    my $pkg = shift;
    my $type = shift;
    
    debug(sprintf('Searching for package: ref=<%s>, pkg=<%s>', 
      ref $pkg, $pkg));
    
    given (ref $pkg) {
        when ('') {
            return $pkg if ($pkg =~ m/^[A-Za-z0-9\-\_\.\/]+$/);
        }
        when ('HASH') {
            my $pkg_name = $pkg->{$type} // $pkg->{default};
            return $pkg_name if ($pkg_name =~ m/^[A-Za-z0-9\-\_\.\/]+$/);
        }
    }
    
    die('Invalid package');
}

1;
__END__

=head1 OPTIONS

=over

=item pkg_type [string]

Set the default package type

=back

=head1 AUTHOR

Anthony Johnson, C<< <aj@ohess.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2012 Anthony Johnson

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
the Software, and to permit persons to whom the Software is furnished to do so,
subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,

