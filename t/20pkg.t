use Test::More;
use Test::Exception;
use Csistck;
use Csistck::Test::Pkg;

plan tests => 13;

# Pkg tests
$Csistck::Test::Pkg::Cmds->{testpass} = {
    check => '/bin/true',
    diff => '/bin/true',
    install => '/bin/true'
};
$Csistck::Test::Pkg::Cmds->{testfail} = {
    check => '/bin/false',
    diff => '/bin/false',
    install => '/bin/false'
};

my $t = pkg('test', 'testpass');
isa_ok($t, Csistck::Test, 'Is a test');
ok($t->can('check'), 'Can check');
ok($t->check, 'Manual check');
isa_ok($t->check, Csistck::Test::Return, 'Manual check return');

my $ret;

# Fail
$t = pkg('test', 'testfail');
$ret = $t->execute('check');
is($ret->failed, 1, 'False expect fail');
isnt($ret->failed, 0, 'False not not fail');
isnt($ret->passed, 1, 'False not pass');
# Repair
$t = pkg('test', 'testpass');
$ret = $t->execute('repair');
is($ret->passed, 1, 'True repair expect pass');
isnt($ret->passed, 0, 'True repair not not pass');
isnt($ret->failed, 1, 'True repair not fail');
# Pass
$t = pkg('test', 'testpass');
$ret = $t->execute('check');
is($ret->passed, 1, 'True expect pass');
isnt($ret->passed, 0, 'True not not pass');
isnt($ret->failed, 1, 'True not fail');

1;
