use strict;
use warnings;
use Module::Build;

my $class = Module::Build->subclass(code => <<'EOF');

  sub git_tag {
    my $gitver = q[git describe --dirty --always];
    my $version = `$gitver` || 'unknown';
    $version =~ s/\s$//smxg;
    $version=~s/\A(?![\d])/0.0-/smx; #prepend 0.0- if does not start with a number
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

  sub ACTION_installdeps {
    my $self = shift;

    $self->SUPER::ACTION_installdeps;

    print "Fetching WTSI::DNAP::Utilities...\n";
    `cpanm -n --no-lwp https://github.com/wtsi-npg/perl-dnap-utilities/releases/download/0.4.1/WTSI-DNAP-Utilities-0.4.1.tar.gz`;

    print "Fetching WTSI::DNAP::RabbitMQ...\n";
    `cpanm -n --no-lwp https://github.com/wtsi-npg/perl-rabbit-wrap/releases/download/0.3.0/WTSI-DNAP-RabbitMQ-0.3.0.tar.gz`;

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
                'Test::MockObject::Extends'       => 0,
                'Test::More'                      => 0,
                'Test::Pod'                       => 0,
                'Test::Pod::Coverage'             => 0,
                'Test::Perl::Critic'              => 0,
                'Test::Warn'                      => 0,
                'File::Slurp'                     => 0,
                'Cwd'                             => 0,
          },

          'requires'    => {
                'AnyEvent'                        => 0,
                'AnyEvent::RabbitMQ'              => 0,
                'App::cpanminus'                  => 0,
                'Carp'                            => 0,
                'Config::Auto'                    => 0,
                'Daemon::Control'                 => 0,
                'DateTime'                        => 0,
                'Digest::MD5'                     => 0,
                'English'                         => 0,
                'Exporter'                        => 0,
                'Getopt::Long'                    => 0,
                'File::Basename'                  => 0,
                'File::Spec::Functions'           => 0,
                'File::Copy'                      => 0,
                'File::Copy::Recursive'           => 0,
                'File::Path'                      => 0,
                'File::Temp'                      => 0,
                'FindBin'                         => 0,
                'JSON'                            => 0,
                'JSON::Any'                       => 0,
                'JSON::Parse'                     => 0,
                'HTTP::Request'                   => 0,
                'lib'                             => 0,
                'List::Compare'                   => 0,
                'Log::Log4perl'                   => 0,
                'LWP::UserAgent'                  => 0,
                'Mojo::Collection'                => 0,
                'Moose'                           => 0,
                'Moose::Util::TypeConstraints'    => 0,
                'MooseX::ClassAttribute'          => 0,
                'MooseX::Getopt'                  => 0,
                'MooseX::Getopt::Meta::Attribute::Trait::NoGetopt' => 0,
                'MooseX::Storage'                 => 0,
                'MooseX::Aliases'                 => 0,
                'MooseX::StrictConstructor'       => 0,
                'MooseX::Aliases'                 => 0,
                'namespace::autoclean'            => 0,
                'PDF::API2'                       => 0,
                'PDF::Table'                      => '0.9.7',
                'Net::SFTP::Foreign'              => 0,
                'Readonly'                        => 0,
                'strict'                          => 0,
                'Text::CSV'                       => 0,
                'Try::Tiny'                       => 0,
                'warnings'                        => 0,
                'XML::LibXML'                     => 2.0105,
                'XML::SemanticDiff'               => 0,
                'URI::Escape'                     => 0,
                'POSIX'                           => 0,
                'WTSI::DNAP::Utilities'           => '>= 0.4.1',
                'WTSI::DNAP::RabbitMQ'            => '>= 0.3.0',
                'UUID::Tiny'                      => '>=1.04',

          },

          'dist'         => { COMPRESS => 'gzip', SUFFIX => 'gz', },
);

$builder->create_build_script();

1;
