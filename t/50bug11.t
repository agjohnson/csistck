use Test::More;
use Test::Exception;

use Csistck;
use File::Temp qw/tempfile/;

plan tests => 2;

# Print null data file
my $h = tempfile();
print $h "NULL";

my $test = file($h->filename, "/tmp/THIS_FILE_DOES_NOT_EXIST");
dies_ok( { &{$test->{check}} }, 'Non-existant file detected'); 

$test = template($h->filename, "/tmp/THIS_FILE_DOES_NOT_EXIST");
dies_ok( { &{$test->{check}} }, 'Non-existant file detected'); 

