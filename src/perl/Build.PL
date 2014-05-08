use strict;
use warnings;
use Module::Build;

my $class = Module::Build->subclass(code => <<'EOF');

  sub git_tag {
    my $gitver = q[git describe --dirty --always];
    my $version = `$gitver`;
    $version =~ s/\s$//smxg;
    return $version;
  }

  sub ACTION_code {
    my $self = shift;

    $self->SUPER::ACTION_code;

    my $gitver = $self->git_tag();
    my @files = split q[\n], `find blib/lib -type f -name "*.pm"`;
    if (-d 'blib/script') {
      push @files, split q[\n],  `find blib/script -type f`;
    }
    foreach my $file (@files) {
      warn "Changing version of $file to $gitver\n";
      my $backup = '.original';
      local $^I = $backup;
      local @ARGV = ($file);
      while (<>) {
        s/(\$VERSION\s*=\s*)('?\S+'?)\s*;/${1}'$gitver';/;
        print;
      }
      unlink "$file$backup";
    }
    return; 
  }
EOF

my $builder = $class->new(

          'module_name'         => 'wtsi_clarity',
          'dist_author'         => 'WTSI, Seq. Informatics',
          'dist_version'        => $class->git_tag(),
          'dist_abstract'       => 'Custom scripting for GenoLogics (http://www.genologics.com) Clarity LIMS at WTSI',
          'license'             => 'gpl',

          'configure_requires' => {
                'ExtUtils::CBuilder'              => 0,
          },

          'build_requires' => {
                'Module::Build'                   => 0,
                'ExtUtils::CBuilder'              => 0,
                'Test::Compile'                   => 0,
                'Test::Distribution'              => 0,
                'Test::Deep'                      => 0,
                'Test::Exception'                 => 0,
                'Test::More'                      => 0,
                'Test::Pod'                       => 0,
                'Test::Pod::Coverage'             => 0,
                'Test::Perl::Critic'              => 0,
                'Test::Warn'                      => 0,
                'File::Temp'                      => 0,
                'Cwd'                             => 0,
          },

          'requires'    => {
                'Carp'                            => 0,
                'Config::Auto'                    => 0,
                'English'                         => 0,
                'Getopt::Long'                    => 0,
                'File::Basename'                  => 0,
                'File::Spec::Functions'           => 0,
                'File::Copy'                      => 0,
                'File::Path'                      => 0,
                'File::Spec::Functions'           => 0,
                'FindBin'                         => 0,
                'HTTP::Request'                   => 0,
                'lib'                             => 0,
                'LWP::UserAgent'                  => 0,
                'Moose'                           => 0,
                'Moose::Util::TypeConstraints'    => 0,
                'MooseX::ClassAttribute'          => 0,
                'MooseX::Getopt'                  => 0,
                'MooseX::Getopt::Meta::Attribute::Trait::NoGetopt' => 0,
                'MooseX::StrictConstructor'       => 0,
                'Readonly'                        => 0,
                'strict'                          => 0,
                'warnings'                        => 0,
          },
         
          'dist'         => { COMPRESS => 'gzip', SUFFIX => 'gz', },
);

$builder->create_build_script();

1;
