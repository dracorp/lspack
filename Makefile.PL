use 5.020001;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME            => 'lspack',
    VERSION_FROM    => 'bin/lspack.pl',
    LICENSE         => 'perl',
    dist            => {
        COMPRESS=>'gzip -9f', EXT=>'gz',
        DIST_DEFAULT => 'tardist'
    },
    PREREQ_PM       => {
        Getopt::Long        => 0,
        Linux::Distribution => 0,
        Term::ANSIColor     => 0,
    },
    EXE_FILES       => [ qw(bin/lspack.pl) ],
    ABSTRACT        => 'Search package among installed packages',
    AUTHOR          => 'Piotr Rogoza <piotr.r.public@gmail.com>',
);
