use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
    "ABSTRACT"           => "module for processing makefiles",
    "AUTHOR"             => "Nick Ing-Simmons",
    "CONFIGURE_REQUIRES" => {
        "ExtUtils::MakeMaker" => "6.63_03",
    },
    "VERSION_FROM" => "lib/Make.pm",
    "NAME"         => "Make",
    "EXE_FILES"    => [ glob 'scripts/*' ],
    "LICENSE"      => "perl",
    "META_MERGE"   => {
        dynamic_config => 0,
        'meta-spec'    => { version   => 2 },
        no_index       => { directory => ['t'] },
        prereqs        => {
            develop => {
                requires => {
                    "Test::Pod" => "1.00",
                    "CPAN::Changes" => "0.400002",
                },
            },
            test => {
                recommends => {
                    'App::Prove' => '3.00',                 # prove -j4
                },
            },
        },
        resources => {
            bugtracker => { web => 'https://github.com/graphviz-perl/Make/issues' },
            homepage   => 'https://metacpan.org/pod/Make',
            repository => {
                type => 'git',
                url  => 'https://github.com/graphviz-perl/Make.git',
                web  => 'https://github.com/graphviz-perl/Make',
            },
            x_IRC => 'irc://irc.perl.org/#perl'
        },
    },
    MIN_PERL_VERSION => "5.014", # s///r
    "PREREQ_PM"        => {
        "Text::Balanced"   => '2.03',
        "Text::ParseWords" => '3.24',
        "Graph"            => '0.9712',    # TC with multiedged
    },
    "TEST_REQUIRES" => {
        "Test::More"     => "1.00",
        'Test::Snapshot' => '0.06',
    },
);
