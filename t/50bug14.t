use Test::More;
use Test::Exception;

use Csistck;
use Csistck::Test;

plan tests => 2;

my $tobj = Csistck::Test->new(
  check => sub { return 1; },
  diff => sub { return 1; },
  repair => 'failure'
);

ok($tobj->has_diff() eq 1, "Testing object with proper action");

ok($tobj->has_repair() eq 0, "Testing object with failing action");

