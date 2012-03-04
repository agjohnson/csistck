use Test::More;
use Test::Exception;
use Csistck;
use File::Temp;
use File::stat;

plan tests => 7;

# Make file and test array (due to glob)
my $h = File::Temp->new();
my $file = $h->filename;
print $h "Test";
chmod(oct('0666'), $file);
my @perm_tests = permission($file, mode => '0660');

# Get first test, make sure we are what we are
my $perm = pop(@perm_tests);
isa_ok($perm, Csistck::Test);
isa_ok($perm->{CHECK}, "CODE");

# Expect check to fail first, as well as manual. Repair and final check should
# succeed, throw in a manual check again to test Csistck::Test abstraction
ok(!$perm->check);
dies_ok(sub { Csistck::Test::Permission::mode_check($file, '0660'); }, 
  "Manual check of mode" );
ok($perm->repair, 'Testing repair operation');
ok($perm->check, 'Testing file mode again');
lives_ok(sub { Csistck::Test::Permission::mode_check($file, '0660'); }, 
  "Manual check of mode" );

1;
