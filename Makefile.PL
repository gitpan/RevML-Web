
use ExtUtils::MakeMaker;

WriteMakefile(
    AUTHOR              => 'Kang-min Liu (gugod@gugod.org)',
    ABSTRACT            => 'RevML Revision Log Analyzer',
    NAME                => 'RevML-Web',
    VERSION             => '0.01_1',
    DISTNAME            => 'RevML-Web',
    PREREQ_PM           => {
        'Spoon'   => '0.14',
        'Spiffy' => '0.17',
        'Email::Find' => '0',
        'Imager::Graph' => 0,
        'YAML' => '0',
        'XML::Twig' => '0',
        'Class::DBI' => '0.96',
    },
    dist                => {
        COMPRESS        => 'gzip -9',
        SUFFIX          => '.gz',
    },
);

