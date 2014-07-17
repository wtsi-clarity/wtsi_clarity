use strict;
use warnings;
use Test::MockObject::Extends;
use Test::More tests => 7;
use Test::Warn;

sub mocked_mapper {
  my @action_names = @_;
  my $mocked_mapper = Test::MockObject::Extends->new('wtsi_clarity::epp::mapper');

  $mocked_mapper->mock( q(package_names),
                        sub{
                          my @package_names;
                          foreach my $action_name (@action_names) {
                            push @package_names, 'wtsi_clarity::epp::sm::' . $action_name;
                          }
                          return @package_names;
                        }
  );

  return $mocked_mapper;
}

sub create_fake_action {
  my ($package_name, $process_url) = @_;
  my $fake_class = Moose::Meta::Class->create($package_name,
    superclasses  => ['wtsi_clarity::epp'],
    roles         => [qw / MooseX::Getopt /]
  )->new_object(process_url=>$process_url);

  return $fake_class;
}

use_ok('wtsi_clarity::epp::mapper');

{
  my $action_name = 'test_action1';
  my $dummy_process_url = 'dummy_url';
  my $faked_package_name = 'wtsi_clarity::epp::sm::' . $action_name;
  my @package_names = mocked_mapper($action_name)->package_names;

  is($package_names[0], $faked_package_name, 'correct package name');

  my $fake_action = create_fake_action($faked_package_name, $dummy_process_url);
  warning_like {
      $fake_action->run()
    }
    qr/Run method is called for class $faked_package_name/,
    'callback runs OK, logs process details';
}

{
  my @action_names = ('test_action1', 'test_action2');
  my @package_names = mocked_mapper(@action_names)->package_names;
  my $dummy_process_url = 'dummy_url';

  for my $i (0 .. $#action_names) {
    my $action_name  = $action_names[$i];
    my $package_name = $package_names[$i];
    my $faked_package_name = 'wtsi_clarity::epp::sm::' . $action_name;

    is($package_name, $faked_package_name, 'correct package name');

    my $fake_action = create_fake_action($faked_package_name, $dummy_process_url);
    warning_like {
        $fake_action->run()
      }
      qr/Run method is called for class $faked_package_name/,
      'callback runs OK, logs process details';
  }
}

1;
