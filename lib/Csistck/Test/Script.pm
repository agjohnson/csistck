package Csistck::Test::Script;

use 5.010;
use strict;
use warnings;

use base 'Csistck::Test';
use Csistck::Oper qw/debug/;
use Csistck::Config qw/option/;

our @EXPORT_OK = qw/script/;

use Digest::MD5;
use File::Basename;
use FindBin;

use constant MODE_CHECK => 'check';
use constant MODE_RUN => 'run';

sub script { Csistck::Test::Script->new($_); };

sub new {
    my ($class, $script) = @_;
    my $self = $class->SUPER::new();
    my @args = @_;

    $self->{CHECK} = sub { script_run(MODE_CHECK, $script, @args); };
    $self->{REPAIR} = sub { script_run(MODE_RUN, $script, @args); };
    $self->{DESC} = "Executing script $script";

    bless($self, $class);
    return $self;
}

sub script_run {
    my $mode = shift;
    my $script = shift;
    my @args = @_;

    # TODO sanity check on script

    # Build command
    my @command = ($script, $mode, @args);
    
    debug(sprintf("Run command: cmd=<%s>", join(" ", @command)));
    
    # my $ret = system("$cmd 1>/dev/null 2>/dev/null");
    chdir($FindBin::Bin);
    my $ret = system(@command);

    die("Command returned $ret")
      unless($ret == 0);
}

1;
__END__

=head1 NAME

Csistck::Test::Script - Csistck script check

=head1 DESCRIPTION

=head1 METHODS

=head2 script($script, [@args])

Call script with extra arguments, if supplied. The first argument passed to
the script is the run mode, C<MODE_CHECK> or C<MODE_RUN>.

    role 'test' => script('apache2/mod-check', 'rewrite');

When processed, the code above, in check mode for example, the process spawned
would be:

    /path/to/script/apache2/mod-check check rewrite

=head1 CONSTANTS

=head2 MODE_CHECK

The string passed to scripts when in check mode

=head2 MODE_RUN

The string passed to scripts when in repair mode

=head1 EXAMPLE

    #!/bin/bash
    
    PKGINFO=`which pkg_info`
    MODE=$1
    PKG=$2
    
    # We can't automate pkgsrc
    [ "$MODE" == "run" ] &&
      { echo "Error: do it yourself, asshole."; exit 1; }
    
    # Test for pkgsrc
    [ -d /usr/pkg ] ||
      { echo "Error: pkgsrc does not exist."; exit 1; }
    
    # Check we have pkg_info and test for package
    [ "$PKGINFO" == "" ] &&
      { echo "Error: pkg_info not found."; exit 1; }
    
    $PKGINFO $PKG >& /dev/null ||
      { echo "Error: package $PKG not found."; exit 1; }
    
    exit 0

The above script is an example of using the script test to test for pkgsrc
packages. This script reports an error in repair mode, as pkgsrc can't really
be automated.

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


