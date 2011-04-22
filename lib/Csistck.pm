package Csistck;

use 5.010;
use strict;
use warnings;

our $VERSION = '0.01.2';

# We export function in the main namespace
use base 'Exporter';
our @EXPORT = qw(
    host
    role
    check
    option

    file
    noop
    permission
    pkg
    script
    template
);

# Imports for base
use Csistck::Config qw/option/;
use Csistck::Test::NOOP qw/noop/;
use Csistck::Test::File qw/file/;
use Csistck::Test::Permission qw/permission/;
use Csistck::Test::Pkg qw/pkg/;
use Csistck::Test::Script qw/script/;
use Csistck::Test::Template qw/template/;

use Sys::Hostname;
use Data::Dumper;

# Package wide
my $Hosts = {};
my $Roles = {};

# Add obj to host array. Tests are Csistck::Test blessed references and
# roles are code references.
sub host {
    my $hostname = shift;

    # Add domain if option is set?
    my $domain_name = Csistck::Config::option('domain_name');
    $hostname = join '.', $hostname, $domain_name
      if (defined $domain_name);

    while (my $require = shift) {
        push(@{$Hosts->{$hostname}}, $require);
    }

    return $Hosts->{$hostname};
}

# Define/reference role and define subrole code ref or Csistck::Test
sub role {
    my $role = shift;

    # If tests specified, add now
    while (my $require = shift) {
        push(@{$Roles->{$role}}, $require);
    }

    return sub { 
        # Run required role or die
        die ("What's this, \"${role}\"? That role is bupkis.")
          unless (defined $Roles->{$role});
        
        process($Roles->{$role});
    }
}

# Main call to start processing
sub check {
    my $hostname = shift // hostname;

    # Get options by command line
    Csistck::Oper::set_mode_by_cli();

    die ("What's this, \"${hostname}\"? That host is bupkis.")
      unless (defined $Hosts->{$hostname});

    process($Hosts->{$hostname});
}

# For recursive testing based on type
sub process {
    my $obj = shift;
    
    # Iterate through array and recursively call process, call code refs, 
    # and run tests 
    given (ref $obj) {
        when ("ARRAY") {
            foreach my $subobj (@{$obj}) {
                process($subobj);
            }
        }
        when ("CODE") {
            &{$obj};
        }
        when ("Csistck::Test") {
            # Check is mandatory, repair if check is bad and we're repairing
            if (!$obj->check()) {
                $obj->repair()
                  if (Csistck::Oper::repair());
            }
        }
        default { die(sprintf("Unkown object reference: ", ref $obj)); }
    }
}

1;
__END__

=head1 NAME


Csistck - Perl system consistency check framework

=head1 SYNOPSIS

A simple example of using csistck to create an executable management
script:

    use Csistck;
    
    for my $host (qw/a b/) {
        host $host => role('test');
    }

    host 'c' => role('test');
    
    role 'test' => 
        template(".files/test.tt", "/tmp/test", { text => "Some text here" }),
        permission("/tmp/test*", mode => '0777', uid => 100, gid => 100);
    
    check;

The script can then be called directly, using command line arguements below

=head1 DESCRIPTION

Csistck is a small Perl framework for writing scripts to maintain system 
configuration and consistency. The focus of csistck is to stay lightweight,
simple, and flexible.

=head1 METHODS

=head2 Options

=over

=item option($name, $value)

Set option to specified value.

=back


=head3 Available Options

=over

=item pkg_type [string]

Set package type

=back



=head2 Defining Hosts and Roles

=over

=item host($hostname, [@tests]);

Append test or array of tests to host definition.

    host 'hostname' => noop(1), noop(1);
    host 'hostname' => noop(0);

Returns a reference to the host object.

=item role($rolename, [@tests]);

Append test or array of tests to role definition.
    
    role 'test' => noop(0);
    host 'hostname' => role('test');

Returns a reference to the role object.

=back

=head2 Tests

=over

=item noop($return)

"No operation" test, used only for testing or placeholders.

    role 'test' => noop(1);

=item file($glob, $target)

Copy files matching file glob pattern to target directory. 

    role 'test' => file("lighttpd/app/*.conf", "/etc/lighttpd");

See L<Csistck::Test::File>

=item template($template, $target, [%args])

Process file $template as a Template Toolkit template, output to path $target.
Hashref %args is passed to the template processor.

    role 'test' => template("sys/motd", "/etc/motd", { hot => 'dog' });

See L<Csistck::Test::Template>

=item permission($glob, %args)

Change permissions on files matching file glob pattern

    role 'test' => permission("/etc/couchdb/*", {
      mode => '0640',
      uid => 130,
      gid => 130
    });

See L<Csistck::Test::Permission>

=item script($script, [@arguments])

Call script with specified arguments 

    role 'test' => script("apache2/mod-check", "rewrite");

See L<Csistck::Test::Script>

=item pkg($package, [$type])

Check for package using system package manager.

    option 'pkg_type' => 'dpkg';
    role 'test' => pkg("lighttpd");

See L<Csistck::Test::Pkg>

=back

=head1 SCRIPT USAGE

The following command line options are recognized in a csistck based script

=over

=item B<--okay>

Enable reporting of okay returns on tests

=item B<--fail>

Enable reporting of failure returns on tests

=item B<--debug>

Enable reporting of debug messages

=item B<--check>

Run script in system check mode, do not run repair operations. (default)

=item B<--repair>

Run script in system repair mode

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
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.

=cut
