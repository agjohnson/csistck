use Test::More;
use Test::Exception;
use Csistck;

plan tests => 5;

ok(Csistck::Test::File->new('test', 'test')->has_repair());
ok(Csistck::Test::Template->new('test', 'test')->has_repair());
ok(Csistck::Test::Script->new('test')->has_repair());
ok(Csistck::Test::Pkg->new('test')->has_repair());
ok(Csistck::Test::Permission->new('test')->has_repair());

1;
