use Test::More;

plan tests => 4;

use Csistck;

my $pkgref = {
    dpkg => 'test-server',
    emerge => 'testd',
    pkg_info => 'net-test',
    default => 'test'
};

is(Csistck::Test::Pkg::get_pkg($pkgref, 'dpkg'), 'test-server');
is(Csistck::Test::Pkg::get_pkg($pkgref, 'emerge'), 'testd');
is(Csistck::Test::Pkg::get_pkg($pkgref, 'pkg_info'), 'net-test');
is(Csistck::Test::Pkg::get_pkg($pkgref, 'rpm'), 'test');

