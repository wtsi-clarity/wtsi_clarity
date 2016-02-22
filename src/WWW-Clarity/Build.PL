use 5.006;
use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
  module_name        => 'WWW::Clarity',
  license            => 'gpl_2',
  dist_author        => q{Ronan Forman <rf9@sanger.ac.uk>},
  dist_version_from  => 'lib/WWW/Clarity.pm',
  release_status     => 'stable',
  configure_requires => {
    'Module::Build' => 0,
  },
  build_requires     => {
    'Test::More' => 0,
  },
  requires           => {
    'DateTime::Format::Strptime' => 0,
    'XML::LibXML'                => 0,
    'WWW::Mechanize'             => 0,
  },
  add_to_cleanup     => ['WWW-Clarity-*'],
  create_makefile_pl => 'traditional',
);

$builder->create_build_script();
