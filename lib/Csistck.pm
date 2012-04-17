package Csistck;

use 5.010;
use strict;
use warnings;

our $VERSION = '0.09_06';

# We export function in the main namespace
use base 'Exporter';
our @EXPORT = qw(
    host
    role
    check
    option

    file
    noop
    pkg
    script
    template
);

# Imports for base
use Csistck::Config qw/option/;
use Csistck::Test::NOOP qw/noop/;
use Csistck::Test::File qw/file/;
use Csistck::Test::Pkg qw/pkg/;
use Csistck::Test::Script qw/script/;
use Csistck::Test::Template qw/template/;

use Csistck::Role;
use Csistck::Term;

use Sys::Hostname::Long qw//;
use Data::Dumper;
use Scalar::Util qw/blessed reftype/;

# Package wide
my $Hosts = {};
my $Roles = {};


=head1 NAME

Csistck - Perl system consistency check framework

=head1 SYNOPSIS

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

=head1 EXTENDING ROLES

Roles can be defined using the C<role> keyword syntax, however a more flexible
method is to extend a new object from L<Csistck::Role>:

    use Csistck;
    use base 'Csistck::Role';

    sub defaults {
        my $self = shift;
        $self->{config} = '/etc/example.conf';
    }

    sub tests {
        my $self = shift;
        $self->add(pkg({
            dpkg => 'test-server',
            pkg_info => 'net-test'
        }),
        template('files/example.conf', $self->{config}, { example => $self });
    }

    1;

See L<Csistck::Role> for information on extending roles


=head1 METHODS


=head2 host($host, $checks)

Add tests to host C<$host> test array. Tests are Csistck::Test blessed references, code
references, or arrays of either. To process host tests, use C<check()>.

=cut

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

=head2 role($role, $checks)

Define a weak role. Constructed similar to a host check, however roles are not
called directly, rather they are used to define groups of common tests that can
be used by multiple hosts.

See L<EXTENDING ROLES> above for an object-based style of defining roles, which
allows for passing role configuration.

=cut

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

=head2 check($target)

Runs processing on C<$target>. If C<$target> is C<undef>, then look up the
system's full hostname. If C<$target> is a string, use that string for a
hostname lookup. If C<$target> is a C<Csistck::Test> reference, a coderef, or an
arrayref, then process that object directly. This is useful for writing scripts
where hostname is not important.

=cut

sub check {
    my $target = shift // Sys::Hostname::Long::hostname_long();

    # Process cli arguments for mode/etc, usage
    Csistck::Oper::set_mode_by_cli();
    return if (Csistck::Oper::usage());

    # If target is a string, process as hostname reference. Otherwise, assume a
    # test object was passed
    if (!defined(reftype($target))) {
        die ("What's this, \"${target}\"? That host is bupkis.")
          unless (defined $Hosts->{$target});
        process($Hosts->{$target});
    }
    else {
        process($target);
    }
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
        default {
            if (blessed($obj) and $obj->isa('Csistck::Test')) {
                # Check is mandatory, if auto repair is set, repair, otherwise prompt
                if (!$obj->execute('check')) {
                    if (Csistck::Oper::repair()) {
                        $obj->execute('repair');
                    }
                    else {
                        Csistck::Term::prompt($obj);
                    }
                }
            }
            elsif (blessed($obj) and $obj->isa('Csistck::Role')) {
                # Object might be subclass of Csistck::Role
                foreach my $subobj (@{$obj->get_tests()}) {
                    process($subobj);
                }
            }
            else {
                die(sprintf("Unkown object reference: ref=<%s>", ref $obj));
            }
        }
    }
}

1;
__END__

=head1 EXPORTED METHODS

=head2 option($name, $value)

Set option to specified value.

=head3 Available Options

=over 3

=item *

pkg_type [string]

Set package type

=item *

domain_name [string]

Set default domain name to append to hosts

=back

=head2 host($hostname, [@tests]);

Append test or array of tests to host definition.

    host 'hostname' => noop(1), noop(1);
    host 'hostname' => noop(0);

Returns a reference to the host object.

=head2 role($rolename, [@tests]);

Append test or array of tests to role definition.
    
    role 'test' => noop(0);
    host 'hostname' => role('test');

Returns a reference to the role object.


=head2 noop($return)

"No operation" test, used only for testing or placeholders.

    role 'test' => noop(1);

=head2 file($glob, $target)

Copy files matching file glob pattern to target directory. 

    role 'test' => file("lighttpd/app/*.conf", "/etc/lighttpd");

See L<Csistck::Test::File>

=head2 template($template, $target, [%args])

Process file $template as a Template Toolkit template, output to path $target.
Hashref %args is passed to the template processor.

    role 'test' => template("sys/motd", "/etc/motd", { hot => 'dog' });

See L<Csistck::Test::Template>

=head2 permission($glob, %args)

Change permissions on files matching file glob pattern

    role 'test' => permission("/etc/couchdb/*", {
        mode => '0640',
        uid => 130,
        gid => 130
    });

See L<Csistck::Test::Permission>

=head2 script($script, [@arguments])

Call script with specified arguments 

    role 'test' => script("apache2/mod-check", "rewrite");

See L<Csistck::Test::Script>

=head2 pkg($package, [$type])

Check for package using system package manager. The C<package> argument may be
specified as a string, or as a hashref to specify package names for multiple
package managers. The package manager will be automatically detected if no
package manager is specified.

    option 'pkg_type' => 'dpkg';
    role 'test' => 
        pkg("lighttpd", 'dpkg'),
        pkg({
            dpkg => 'snmp-server',
            pkg_info => 'net-snmp'
        });

See L<Csistck::Test::Pkg> for more information

=head1 SCRIPT USAGE

Scripts based on csistck will run in an interactive mode by default. 
The following command line options are recognized in a csistck based script

=over

=item *

B<--[no]repair>

Automate repair mode, do not run in interactive mode.

=item *

B<--[no]verbose>

Toggle verbose reporting of events

=item *

B<--[no]debug>

Toggle debug reporting of events

=item *

B<--[no]quiet>

Toggle event reporting of errors

=back

=head1 AUTHOR

Anthony Johnson, C<< <aj@ohess.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2011-2012 Anthony Johnson

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
IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

=cut
