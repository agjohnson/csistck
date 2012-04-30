use Test::More;
use Csistck;
use Csistck::Test::Pkg;

plan tests => 8;

# First on NOOP
ok(noop(0)->execute('check')->isa('Csistck::Test::Return'), 
  'Test return type');
ok(noop(0)->execute('check')->failed, 'Test failed evaluation');
ok(noop(1)->execute('check')->passed, 'Test passed evaluation');
ok(noop(1)->execute('repair')->failed, 'Missing repair operation');

# Pkg tests
$Csistck::Test::Pkg::Cmds->{testpkg} = {
    check => 'sh -c "echo %s"',
    diff => 'sh -c "echo %s"',
    install => 'sh -c "echo %s"'
};
ok(pkg('test', 'testpkg')->execute('check')->isa(
  'Csistck::Test::Return'), 'Check pkg check return');
ok(pkg('test', 'testpkg')->execute('check')->passed,
  'Check pkg check return');
ok(pkg('test', 'testpkg')->execute('repair')->passed,
  'Check pkg repair return');

# File tests
ok(file('/tmp/na')->execute('check')->passed, 'File exists');

1;
