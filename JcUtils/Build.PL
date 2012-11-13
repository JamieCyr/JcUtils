use 5.006;
use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'JcUtils',
    license             => 'perl',
    dist_author         => q{Jamie Cyr <jjcyr@yahoo.com>},
    dist_version_from   => 'lib/JcUtils/Logger.pm',
    build_requires => {
        'Test::More' => 0,
    },
    requires => {
        'perl' => 5.006,
    },
    add_to_cleanup      => [ 'JcUtils-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
