use 5.010;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Csistck',
    VERSION_FROM      => 'lib/Csistck.pm', # finds $VERSION
    PREREQ_PM         => {
        'Digest::MD5' => 0,
        'File::Basename' => 0,
        'File::Copy' => 0,
        'File::stat' => 0,
        'Getopt::Long' => 0,
        'Sys::Hostname::Long' => 0,
        'Template' => 0,
        'Term::ReadKey' => 0,
        'Text::Diff' => 0
    }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Csistck.pm', # retrieve abstract from module
       AUTHOR         => 'Anthony Johnson <aj@ohess.org>') : ()),
);
