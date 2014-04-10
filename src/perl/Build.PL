use strict;
use warnings;
use Module::Build;

my $class = Module::Build->subclass(code => <<'EOF');

  sub git_tag {
    my $version;
    my $gitver = q[./scripts/gitver];
    if (!-e $gitver) {
      warn "$gitver script not found";
      $version = q[unknown];
    }
    if (!-x $gitver) {
      warn "$gitver script is not executable";
      $version = q[unknown];
    }
    if (!$version) {
      $version = `$gitver`;
      $version =~ s/\s$//smxg;
    }
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

          'module_name'         => 'wtsi_clarity_perl',
          'dist_author'         => 'wtsi-clarity',
          'dist_version'        => $class->git_tag(),
          'dist_abstract'       => 'Custom scripting for GenoLogics (http://www.genologics.com) Clarity LIMS at WTSI',
          'license'             => 'gpl',

          'configure_requires' => {
                'ExtUtils::CBuilder'              => 0,
          },

          'build_requires' => {
                'strict'                          => 0,
                'warnings'                        => 0,
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
          },

          'requires'    => {
                'Carp'                            => 0,
                'Config::Auto'                    => 0,
                'English'                         => 0,
                'File::Spec::Functions'           => 0,
                'Moose'                           => 0,
                'Moose::Util::TypeConstraints'    => 0,
                'Readonly'                        => 0,
          },
         
          'dist'         => { COMPRESS => 'gzip', SUFFIX => 'gz', },
);

$builder->create_build_script();

1;
