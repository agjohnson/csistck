use Test::More;
use Test::Exception;
use Csistck;
use File::Temp;
use File::stat;

plan tests => 5;

my $h = File::Temp->new();
my $file = $h->filename;
print $h "Test";
chmod(oct('0666'), $file);

my $t = Csistck::Test::Template->new($file, mode => '0660');

# Get first test, make sure we are what we are
isa_ok($t, Csistck::Test);
ok($t->can('check'));

# Expect check to fail first, as well as manual. Repair and final check should
# succeed, throw in a manual check again to test Csistck::Test abstraction
dies_ok(sub { $t->check; }, "Manual check of mode" );
ok($t->execute('repair'), 'Testing repair operation');
ok($t->execute('check'), 'Testing file mode again');

1;
