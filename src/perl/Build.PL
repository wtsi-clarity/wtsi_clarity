use strict;
use warnings;
use lib 'lib';
use Module::Build;

my $class = Module::Build->subclass(code => <<'EOF');

 sub dir_files {
    my $dir = shift;
    opendir my $dh, $dir || die "can't opendir $dir: $!";
    my @files = map { "$dir/$_" } grep { /^\w+$/ && -f "$dir/$_" } readdir $dh;
    closedir $dh;
    return @files;
  }

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

    my $root = q[./blib/lib];
    my @dirs  = ($root);
    for my $path (@dirs){
      opendir ( DIR, $path ) or next;   # skip dirs we can't read
      while (my $file = readdir DIR) {
        my $full_path = join '/', $path, $file;
        next if $file eq '.' or $file eq '..'; # skip dot files
           if ( -d $full_path ) {
            push @dirs, $full_path;     # add dir to list
          } 
      }
      closedir DIR;
    }

    my @modules;
    foreach my $dir (@dirs) {
    opendir(DIR, $dir) or die $!;
    while (my $file = readdir(DIR)) {
        next unless (-f "$dir/$file");
        next unless ($file =~ m/\.pm$/);
        push @modules, $dir . q[/] . $file;
    }
    closedir(DIR);
  }

    foreach my $module (@modules) {
      my $gitver = $self->git_tag();
      if (-e $module) {
        warn "Changing version of $module to $gitver\n";
        my $backup = '.original';
        local $^I = $backup;
        local @ARGV = ($module);
        while (<>) {
          s/(\$VERSION\s*=\s*)('?\S+'?)\s*;/${1}'$gitver';/;
          s/head1 VERSION$/head1  VERSION\n\nVersion $gitver/;
          print;
        }
        unlink "$module$backup";
      } else {
        warn "File $module not found\n";
      }
    }
 
}

EOF

my $builder = $class->new(

                'module_name'         => 'clarity-perl',
                'dist_author'         => q(wtsi-clarity <npg@sanger.ac.uk>),
                'dist_version'        => $class->git_tag(),
                'dist_abstract'       => 'Custom scripting for GenoLogics (http://www.genologics.com) Clarity LIMS at Wellcome Trust Sanger Institute',
                'license'             => 'gpl',

          'configure_requires' => {
                'ExtUtils::CBuilder'              => 0,
                'Readonly'                        => 0,
                'Readonly::XS'                    => 0,
          },

          'build_requires' => {
                'ExtUtils::CBuilder'              => 0,
                'IPC::Open2'                      => 0,
                'Test::Compile'                   => 0,
                'Test::Distribution'              => 0,
                'Test::Deep'                      => '0.103',
                'Test::Exception'                 => '0.27',
                'Test::Exception::LessClever'     => '0.005',
                'Test::LongString'                => 0,
                'Test::MockModule'                => 0,
                'Test::MockObject'                => 0,
                'Test::More'                      => '0.86',
                'Test::Pod'                       => 0,
                'Test::Pod::Coverage'             => 0,
                'Test::Perl::Critic'              => 0,
                'Perl::Critic::Policy::Subroutines::ProhibitUnusedPrivateSubroutines' => 0,
                'Test::Trap'                      => '0.2.0',
                'Test::Warn'                      => '0.11',
                'DateTime::Format::SQLite'        => 0,
          },

          'requires'    => {
                'autodie'                         => '2.10',
                'base'                            => '2.12',
                'Carp'                            => '1.04',
                'Clone'                           => 0,
                'Config::Auto'                    => 0,
                'Crypt::CBC'                      => 0,
                'Cwd'                             => 0,
                'Data::Dumper'                    => '2.121_08',
                'Date::Calc'                      => '5.4',
                'Date::Parse'                     => '2.27',
                'DateTime'                        => '0.5',
                'DateTime::TimeZone'              => 0,
                'DateTime::Format::MySQL'         => 0,
                'DateTime::Format::Strptime'      => '1.0702',
                'DateTime::TimeZone'              => 0,
                'DBI'                             => '1.608',
                'DBIx::Class'                     => '0.08119',
                'Digest::MD5'                     => 0,
                'Digest::SHA'                     => 0,
                'English'                         => '1.02',
                'Exporter'                        => '5.63',
                'File::Slurp'                     => '9999.13',
                'File::Type'                      => '0.22',
                'FindBin'                         => '1.47',
                'File::Basename'                  => 0,
                'File::Copy'                      => 0,
                'File::Find'                      => 0,
                'File::Path'                      => 0,
                'File::Spec'                      => 0,
                'File::Spec::Functions'           => 0,
                'File::Slurp'                     => 0,
                'File::Temp'                      => 0,
                'File::Type'                      => 0,
                'File::chdir'                     => 0,
                'Getopt::Long'                    => '2.37',
                'HTML::PullParser'                => '3.57',
                'HTML::Tidy'                      => 0,
                'HTTP::Request'                   => '5.818',
                'HTTP::Request::Common'           => '5.822',
                'HTTP::Response'                  => 0,
                'IO::All'                         => '0.39',
                'IO::All::FTP'                    => 0,
                'IO::Scalar'                      => '2.110',
                'IPC::System::Simple'             => 0,
                'JSON'                            => '2.12',
                'lib'                             => '0.5565',
                'Lingua::EN::Inflect'             => 0,
                'List::MoreUtils'                 => '0.22',
                'List::Util'                      => '1.21',
                'Log::Log4perl'                   => 0,
                'LWP::UserAgent'                  => '5.823',
                'Math::Round'                     => '0.06',
                'MIME::Base64'                    => 0,
                'MIME::Lite'                      => '3.024',
                'MIME::Parser'                    => '5.427',
		'Module::PluginFinder'            => '0.04',
                'namespace::autoclean'            => '0.09',
                'Net::LDAP'                       => 0,
                'Perl6::Slurp'                    => '0.03',
                'POSIX'                           => '1.09',
                'Readonly'                        => '1.03',
                'Readonly::XS'                    => 0,
                'Scalar::Util'                    => 0,
                'Socket'                          => 0,
                'strict'                          => '1.03',
                'SQL::Translator'                 => '0.11006',
                'Sys::Hostname'                   => '1.11',
                'Template'                        => '2.19',
                'Try::Tiny'                       => 0,
                'URI'                             => '1.37',
                'URI::Escape'                     => 0,
                'warnings'                        => '1.05',
                'XML::Generator'                  => '1.01',
                'XML::LibXML'                     => '1.70',
                'XML::Simple'                     => '2.18',
                'YAML'                            => '0.68',
            },
         
            'dist'         => { COMPRESS => 'gzip', SUFFIX => 'gz', },
         );

if ($builder->install_base()) {
  $builder->install_path('data' => join q{/}, $builder->install_base(), 'data');
  $builder->add_build_element('data');
} else {
  warn "WARNING: '--install_base' option is not given, 'data' element will not be installed\n\n";
}

$builder->create_build_script();

1;
