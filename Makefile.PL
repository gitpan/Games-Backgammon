use 5.006001;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Games::Backgammon',
    'VERSION_FROM'	=> 'Backgammon.pm', # finds $VERSION
    'PREREQ_PM'		=> {
        List::Util        => 0,
        Carp              => 0,

        Test::More        => 0,
        Test::Differences => 0.45,
        Test::Exception   => 0.12,
        Test::Warn        => 0.05,
    }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'Backgammon.pm', # retrieve abstract from module
       AUTHOR     => 'Janek Schleicher <bigj@kamelfreun.de>') : ()),
);
