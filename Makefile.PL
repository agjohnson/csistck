use strict;
use warnings;
use inc::Module::Install;

name 'Csistck';

perl_version '5.010';

version_from 'lib/Csistck.pm';
license_from 'lib/Csistck.pm';
author_from 'lib/Csistck.pm';

homepage 'http://ohess.org/projects/csistck';
bugtracker 'http://github.com/agjohnson/csistck/issues';
repository 'http://github.com/agjohnson/csistck.git';

requires 'Digest::MD5';
requires 'File::Basename';
requires 'File::Copy';
requires 'File::stat';
requires 'Getopt::Long';
requires 'Sys::Hostname::Long';
requires 'Scalar::Util';
requires 'Linux::Distribution' => '0.21';
requires 'Template';
requires 'Term::ReadKey';
requires 'Text::Diff';
requires 'Test::Exception';

WriteAll;
