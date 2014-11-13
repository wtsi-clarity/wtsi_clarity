use strict;
use warnings;
use Test::More tests => 15;
use Test::Exception;
use Test::Warn;
use Carp;
use Data::Dumper;
use Readonly;

use_ok('wtsi_clarity::file_parsing::ISC_pool_calculator', 'can use ISC_pool_calculator');

{ # _update_concentrations_for_all_pools
  my $mapping = {
    '10' => {
      'A1' => [
        { 'source_plate' => '1', 'source_well' =>  'A1', },
        { 'source_plate' => '1', 'source_well' =>  'B1', },
        { 'source_plate' => '1', 'source_well' =>  'C1', },
        { 'source_plate' => '1', 'source_well' =>  'D1', },
        { 'source_plate' => '1', 'source_well' =>  'E1', },
        { 'source_plate' => '1', 'source_well' =>  'F1', },
        { 'source_plate' => '1', 'source_well' =>  'G1', },
        { 'source_plate' => '1', 'source_well' =>  'H1', },
        { 'source_plate' => '2', 'source_well' =>  'A1', },
        { 'source_plate' => '2', 'source_well' =>  'B1', },
        { 'source_plate' => '2', 'source_well' =>  'C1', },
        { 'source_plate' => '2', 'source_well' =>  'D1', },
        { 'source_plate' => '2', 'source_well' =>  'E1', },
        { 'source_plate' => '2', 'source_well' =>  'F1', },
        { 'source_plate' => '2', 'source_well' =>  'G1', },
        { 'source_plate' => '2', 'source_well' =>  'H1', },
      ],
      'A2' => [
        { 'source_plate' => '1', 'source_well' =>  'A2', },
        { 'source_plate' => '1', 'source_well' =>  'B2', },
        { 'source_plate' => '1', 'source_well' =>  'C2', },
        { 'source_plate' => '1', 'source_well' =>  'D2', },
        { 'source_plate' => '1', 'source_well' =>  'E2', },
        { 'source_plate' => '1', 'source_well' =>  'F2', },
        { 'source_plate' => '1', 'source_well' =>  'G2', },
        { 'source_plate' => '1', 'source_well' =>  'H2', },
        { 'source_plate' => '2', 'source_well' =>  'A3', },
        { 'source_plate' => '2', 'source_well' =>  'B3', },
        { 'source_plate' => '2', 'source_well' =>  'C3', },
        { 'source_plate' => '2', 'source_well' =>  'D3', },
        { 'source_plate' => '2', 'source_well' =>  'E3', },
        { 'source_plate' => '2', 'source_well' =>  'F3', },
        { 'source_plate' => '2', 'source_well' =>  'G3', },
      ],
      'A3' => [
        { 'source_plate' => '2', 'source_well' =>  'H3', },
      ],
    },
  };

  my $data ={
      '1' =>  {
        'A1' => 8.35069091420415,
        'B1' => 8.38632847062985,
        'C1' => 7.61459705293945,
        'D1' => 7.57639709237205,
        'E1' => 7.1901825375243,
        'F1' => 7.46400249292614,
        'G1' => 3.67239221718722,
        'H1' => 3.15141713078042,
      },
      '2' =>  {
        'H3' => 3,
      },
  };

  my $EXPECTED_DATA = {
          '10' => {
                    'A3' => [
                              {
                                'Molarity' => '15',
                                'source_plate' => '2',
                                'source_well' => 'H3',
                                'Volume' => '50',
                              }
                            ],
                    'A1' => [
                              {
                                'Molarity' => '41.7534545710208',
                                'source_plate' => '1',
                                'Volume' => '17.5460977698434',
                                'source_well' => 'A1'
                              },
                              {
                                'Molarity' => '41.9316423531493',
                                'source_plate' => '1',
                                'Volume' => '17.4715359336938',
                                'source_well' => 'B1'
                              },
                              {
                                'Molarity' => '38.0729852646973',
                                'source_plate' => '1',
                                'Volume' => '19.2422577593659',
                                'source_well' => 'C1'
                              },
                              {
                                'Molarity' => '37.8819854618602',
                                'source_plate' => '1',
                                'Volume' => '19.3392766297701',
                                'source_well' => 'D1'
                              },
                              {
                                'Molarity' => '35.9509126876215',
                                'source_plate' => '1',
                                'Volume' => '20.3780694664838',
                                'source_well' => 'E1'
                              },
                              {
                                'Molarity' => '37.3200124646307',
                                'source_plate' => '1',
                                'Volume' => '19.6304917321815',
                                'source_well' => 'F1'
                              },
                              {
                                'Molarity' => '18.3619610859361',
                                'source_plate' => '1',
                                'Volume' => '39.8982544785463',
                                'source_well' => 'G1'
                              },
                              {
                                'Molarity' => '15.7570856539021',
                                'source_plate' => '1',
                                'Volume' => '46.4940162301154',
                                'source_well' => 'H1'
                              },
                              {
                                'Molarity' => '0',
                                'source_plate' => '2',
                                'Volume' => 0,
                                'source_well' => 'A1'
                              },
                              {
                                'Molarity' => '0',
                                'source_plate' => '2',
                                'Volume' => 0,
                                'source_well' => 'B1'
                              },
                              {
                                'Molarity' => '0',
                                'source_plate' => '2',
                                'Volume' => 0,
                                'source_well' => 'C1'
                              },
                              {
                                'Molarity' => '0',
                                'source_plate' => '2',
                                'Volume' => 0,
                                'source_well' => 'D1'
                              },
                              {
                                'Molarity' => '0',
                                'source_plate' => '2',
                                'Volume' => 0,
                                'source_well' => 'E1'
                              },
                              {
                                'Molarity' => '0',
                                'source_plate' => '2',
                                'Volume' => 0,
                                'source_well' => 'F1'
                              },
                              {
                                'Molarity' => '0',
                                'source_plate' => '2',
                                'Volume' => 0,
                                'source_well' => 'G1'
                              },
                              {
                                'Molarity' => '0',
                                'source_plate' => '2',
                                'Volume' => 0,
                                'source_well' => 'H1'
                              }
                            ],
                    'A2' => [
                              {
                                'Molarity' => '0',
                                'source_plate' => '1',
                                'source_well' => 'A2'
                              },
                              {
                                'Molarity' => '0',
                                'source_plate' => '1',
                                'source_well' => 'B2'
                              },
                              {
                                'Molarity' => '0',
                                'source_plate' => '1',
                                'source_well' => 'C2'
                              },
                              {
                                'Molarity' => '0',
                                'source_plate' => '1',
                                'source_well' => 'D2'
                              },
                              {
                                'Molarity' => '0',
                                'source_plate' => '1',
                                'source_well' => 'E2'
                              },
                              {
                                'Molarity' => '0',
                                'source_plate' => '1',
                                'source_well' => 'F2'
                              },
                              {
                                'Molarity' => '0',
                                'source_plate' => '1',
                                'source_well' => 'G2'
                              },
                              {
                                'Molarity' => '0',
                                'source_plate' => '1',
                                'source_well' => 'H2'
                              },
                              {
                                'Molarity' => '0',
                                'source_plate' => '2',
                                'source_well' => 'A3'
                              },
                              {
                                'Molarity' => '0',
                                'source_plate' => '2',
                                'source_well' => 'B3'
                              },
                              {
                                'Molarity' => '0',
                                'source_plate' => '2',
                                'source_well' => 'C3'
                              },
                              {
                                'Molarity' => '0',
                                'source_plate' => '2',
                                'source_well' => 'D3'
                              },
                              {
                                'Molarity' => '0',
                                'source_plate' => '2',
                                'source_well' => 'E3'
                              },
                              {
                                'Molarity' => '0',
                                'source_plate' => '2',
                                'source_well' => 'F3'
                              },
                              {
                                'Molarity' => '0',
                                'source_plate' => '2',
                                'source_well' => 'G3'
                              }
                            ]
                  }
        };
  my $EXPECTED_WARNING = {
          '10' => {
                    'A3' => [],
                    'A1' => [
                              'Warning: concentration data missing for [ plate 2 | well A1 ]',
                              'Warning: concentration data missing for [ plate 2 | well B1 ]',
                              'Warning: concentration data missing for [ plate 2 | well C1 ]',
                              'Warning: concentration data missing for [ plate 2 | well D1 ]',
                              'Warning: concentration data missing for [ plate 2 | well E1 ]',
                              'Warning: concentration data missing for [ plate 2 | well F1 ]',
                              'Warning: concentration data missing for [ plate 2 | well G1 ]',
                              'Warning: concentration data missing for [ plate 2 | well H1 ]',
                              'Warning: volume required from [ plate 2 | well A1 ] if too low ( = 0 )!',
                              'Warning: volume required from [ plate 2 | well B1 ] if too low ( = 0 )!',
                              'Warning: volume required from [ plate 2 | well C1 ] if too low ( = 0 )!',
                              'Warning: volume required from [ plate 2 | well D1 ] if too low ( = 0 )!',
                              'Warning: volume required from [ plate 2 | well E1 ] if too low ( = 0 )!',
                              'Warning: volume required from [ plate 2 | well F1 ] if too low ( = 0 )!',
                              'Warning: volume required from [ plate 2 | well G1 ] if too low ( = 0 )!',
                              'Warning: volume required from [ plate 2 | well H1 ] if too low ( = 0 )!',
                            ],
                    'A2' => [
                              'Warning: Too many concentration data missing! This well cannot be configured!'
                            ]
                  }
        };

  my $warnings = wtsi_clarity::file_parsing::ISC_pool_calculator::_update_concentrations_for_all_pools($mapping, $data, 5, 50, 200);
  is_deeply( $mapping,  $EXPECTED_DATA,    "_update_concentrations_for_all_pools() should return the correct content.");
  is_deeply( $warnings, $EXPECTED_WARNING, "_update_concentrations_for_all_pools() should return the correct warnings.");
}

{ # _update_concentrations_for_one_pool
  my $mapping = [
        { 'source_plate' => '1', 'source_well' =>  'A1', },
        { 'source_plate' => '1', 'source_well' =>  'B1', },
        { 'source_plate' => '1', 'source_well' =>  'C1', },
        { 'source_plate' => '1', 'source_well' =>  'D1', },
        { 'source_plate' => '1', 'source_well' =>  'E1', },
        { 'source_plate' => '1', 'source_well' =>  'F1', },
        { 'source_plate' => '1', 'source_well' =>  'G1', },
        { 'source_plate' => '1', 'source_well' =>  'H1', },
        { 'source_plate' => '2', 'source_well' =>  'A1', },
        { 'source_plate' => '2', 'source_well' =>  'B1', },
        { 'source_plate' => '2', 'source_well' =>  'C1', },
        { 'source_plate' => '2', 'source_well' =>  'D1', },
        { 'source_plate' => '2', 'source_well' =>  'E1', },
        { 'source_plate' => '2', 'source_well' =>  'F1', },
        { 'source_plate' => '2', 'source_well' =>  'G1', },
        { 'source_plate' => '2', 'source_well' =>  'H1', },
                ];

  my $data = {
    '1' =>  {
      'A1' => 8.5,
      'B1' => 7.5,
      'C1' => 5.5,
      'D1' => 6.5,
      'E1' => 7,
      'F1' => 7,
      'G1' => 8,
      'H1' => 7.5,
    },
    '2' =>  {
      'A1' => 8.5,
      'B1' => 7.5,
      'C1' => 5.5,
      'D1' => 6.5,
      'E1' => 7,
      'F1' => 7,
      'G1' => 8,
      'H1' => 7.5,
    },
  };

  my $EXPECTED_DATA = [
          {
            'Molarity' => '42.5',
            'source_plate' => '1',
            'Volume' => '10.4048691184056',
            'source_well' => 'A1'
          },
          {
            'Molarity' => '37.5',
            'source_plate' => '1',
            'Volume' => '11.7921850008597',
            'source_well' => 'B1'
          },
          {
            'Molarity' => '27.5',
            'source_plate' => '1',
            'Volume' => '16.0802522738996',
            'source_well' => 'C1'
          },
          {
            'Molarity' => '32.5',
            'source_plate' => '1',
            'Volume' => '13.6063673086843',
            'source_well' => 'D1'
          },
          {
            'Molarity' => '35',
            'source_plate' => '1',
            'Volume' => '12.6344839294925',
            'source_well' => 'E1'
          },
          {
            'Molarity' => '35',
            'source_plate' => '1',
            'Volume' => '12.6344839294925',
            'source_well' => 'F1'
          },
          {
            'Molarity' => '40',
            'source_plate' => '1',
            'Volume' => '11.055173438306',
            'source_well' => 'G1'
          },
          {
            'Molarity' => '37.5',
            'source_plate' => '1',
            'Volume' => '11.7921850008597',
            'source_well' => 'H1'
          },
          {
            'Molarity' => '42.5',
            'source_plate' => '2',
            'Volume' => '10.4048691184056',
            'source_well' => 'A1'
          },
          {
            'Molarity' => '37.5',
            'source_plate' => '2',
            'Volume' => '11.7921850008597',
            'source_well' => 'B1'
          },
          {
            'Molarity' => '27.5',
            'source_plate' => '2',
            'Volume' => '16.0802522738996',
            'source_well' => 'C1'
          },
          {
            'Molarity' => '32.5',
            'source_plate' => '2',
            'Volume' => '13.6063673086843',
            'source_well' => 'D1'
          },
          {
            'Molarity' => '35',
            'source_plate' => '2',
            'Volume' => '12.6344839294925',
            'source_well' => 'E1'
          },
          {
            'Molarity' => '35',
            'source_plate' => '2',
            'Volume' => '12.6344839294925',
            'source_well' => 'F1'
          },
          {
            'Molarity' => '40',
            'source_plate' => '2',
            'Volume' => '11.055173438306',
            'source_well' => 'G1'
          },
          {
            'Molarity' => '37.5',
            'source_plate' => '2',
            'Volume' => '11.7921850008597',
            'source_well' => 'H1'
          },
      ];
  my $EXPECTED_WARNING = [];

  my $warnings = wtsi_clarity::file_parsing::ISC_pool_calculator::_update_concentrations_for_one_pool($mapping, $data, 5, 50, 200);
  is_deeply( $mapping,  $EXPECTED_DATA,  "_update_concentrations_for_one_pool() should return the correct content.");
  is_deeply( $warnings,  $EXPECTED_WARNING,  "_update_concentrations_for_one_pool() should return the correct warnings.");
}

{ # _update_concentrations_for_one_pool
  my $mapping = [
        { 'source_plate' => '1', 'source_well' =>  'A1', },
        { 'source_plate' => '1', 'source_well' =>  'B1', },
                ];

  my $data =  {
        '1' =>  {
          'A1' => 50,
          'B1' => 1,
                }
              };

  my $EXPECTED_DATA = [
        {
          'Molarity' => '250',
          'source_plate' => '1',
          'Volume' => '1',
          'source_well' => 'A1'
        },
        {
          'Molarity' => '5',
          'source_plate' => '1',
          'Volume' => '50',
          'source_well' => 'B1'
        },
                      ];

  my $EXPECTED_WARNING = [ q{Warning: volume required from [ plate 1 | well A1 ] if too low ( = 1 )!} ];
  my $warnings = wtsi_clarity::file_parsing::ISC_pool_calculator::_update_concentrations_for_one_pool($mapping, $data, 5, 50, 200);
  is_deeply( $mapping,  $EXPECTED_DATA,  "_update_concentrations_for_one_pool() should return the correct content when the molarity ratio is too high.");
  is_deeply( $warnings,  $EXPECTED_WARNING,  "_update_concentrations_for_one_pool() should return the correct warnings when the molarity ratio is too high.");
}

{ # _update_concentrations_for_one_pool
  my $mapping = [
        { 'source_plate' => '1', 'source_well' =>  'A1', },
                ];

  my $data =  {
        '1' =>  {
          'A1' => 3
                },
              };

  my $EXPECTED_DATA = [
        {
          'Molarity' => '15',
          'source_plate' => '1',
          'Volume' => '50',
          'source_well' => 'A1',
        },
                      ];

  my $EXPECTED_WARNING = [ ];
  my $warnings = wtsi_clarity::file_parsing::ISC_pool_calculator::_update_concentrations_for_one_pool($mapping, $data, 5, 50, 200);
  is_deeply( $mapping,  $EXPECTED_DATA,  "_update_concentrations_for_one_pool() should return the correct content when there's only one well.");
  is_deeply( $warnings,  $EXPECTED_WARNING,  "_update_concentrations_for_one_pool() should return the correct warnings when there's only one well.");
}

{ # _update_concentrations_for_one_pool
  my $mapping = [
        { 'source_plate' => '1', 'source_well' =>  'A1', },
        { 'source_plate' => '1', 'source_well' =>  'B1', },
                ];

  my $data =  {
        '1' =>  {
          'A1' => 5,
          'B1' => 5,
                }
              };

  my $EXPECTED_DATA = [
        {
          'Molarity' => '25',
          'source_plate' => '1',
          'Volume' => '50',
          'source_well' => 'A1'
        },
        {
          'Molarity' => '25',
          'source_plate' => '1',
          'Volume' => '50',
          'source_well' => 'B1'
        },
                      ];

  my $EXPECTED_WARNING = [ ];
  my $warnings = wtsi_clarity::file_parsing::ISC_pool_calculator::_update_concentrations_for_one_pool($mapping, $data, 5, 50, 200);
  is_deeply( $mapping,  $EXPECTED_DATA,  "_update_concentrations_for_one_pool() should return the correct content when the total volume must not be rescaled.");
  is_deeply( $warnings,  $EXPECTED_WARNING,  "_update_concentrations_for_one_pool() should return the correct warnings when the total volume must not be rescaled.");
}

{ # _update_concentrations_for_one_pool
  my $mapping = [
        { 'source_plate' => '1', 'source_well' =>  'A1', },
        { 'source_plate' => '1', 'source_well' =>  'B1', },
                ];

  my $data = {
        '1' =>  {
          'A1' => 5,
          'B1' => 5,
        }
      };

  my $EXPECTED_DATA = [
        {
          'Molarity' => '25',
          'source_plate' => '1',
          'Volume' => '40',
          'source_well' => 'A1'
        },
        {
          'Molarity' => '25',
          'source_plate' => '1',
          'Volume' => '40',
          'source_well' => 'B1'
        },
                      ];

  my $EXPECTED_WARNING = [ ];
  my $warnings = wtsi_clarity::file_parsing::ISC_pool_calculator::_update_concentrations_for_one_pool($mapping, $data, 5, 50, 80);
  is_deeply( $mapping,  $EXPECTED_DATA,  "_update_concentrations_for_one_pool() should return the correct content when the total volume must be rescaled.");
  is_deeply( $warnings,  $EXPECTED_WARNING,  "_update_concentrations_for_one_pool() should return the correct warnings when the total volume must be rescaled.");
}

{ # _transform_mapping
  my $mapping = [
    { 'source_plate' => '1', 'source_well' =>  'A1', 'dest_plate' => '10', 'dest_well' =>  'A1'},
    { 'source_plate' => '1', 'source_well' =>  'B1', 'dest_plate' => '10', 'dest_well' =>  'A1'},
    { 'source_plate' => '1', 'source_well' =>  'C1', 'dest_plate' => '10', 'dest_well' =>  'A1'},
    { 'source_plate' => '1', 'source_well' =>  'D1', 'dest_plate' => '10', 'dest_well' =>  'A1'},
    { 'source_plate' => '1', 'source_well' =>  'E1', 'dest_plate' => '10', 'dest_well' =>  'A1'},
    { 'source_plate' => '1', 'source_well' =>  'F1', 'dest_plate' => '10', 'dest_well' =>  'A1'},
    { 'source_plate' => '1', 'source_well' =>  'G1', 'dest_plate' => '10', 'dest_well' =>  'A1'},
    { 'source_plate' => '1', 'source_well' =>  'H1', 'dest_plate' => '10', 'dest_well' =>  'A1'},
    { 'source_plate' => '2', 'source_well' =>  'A1', 'dest_plate' => '10', 'dest_well' =>  'A1'},
    { 'source_plate' => '2', 'source_well' =>  'B1', 'dest_plate' => '10', 'dest_well' =>  'A1'},
    { 'source_plate' => '2', 'source_well' =>  'C1', 'dest_plate' => '10', 'dest_well' =>  'A1'},
    { 'source_plate' => '2', 'source_well' =>  'D1', 'dest_plate' => '10', 'dest_well' =>  'A1'},
    { 'source_plate' => '2', 'source_well' =>  'E1', 'dest_plate' => '10', 'dest_well' =>  'A1'},
    { 'source_plate' => '2', 'source_well' =>  'F1', 'dest_plate' => '10', 'dest_well' =>  'A1'},
    { 'source_plate' => '2', 'source_well' =>  'G1', 'dest_plate' => '10', 'dest_well' =>  'A1'},
    { 'source_plate' => '2', 'source_well' =>  'H1', 'dest_plate' => '10', 'dest_well' =>  'A1'},
    { 'source_plate' => '1', 'source_well' =>  'A2', 'dest_plate' => '10', 'dest_well' =>  'A2'},
    { 'source_plate' => '1', 'source_well' =>  'B2', 'dest_plate' => '10', 'dest_well' =>  'A2'},
    { 'source_plate' => '1', 'source_well' =>  'C2', 'dest_plate' => '10', 'dest_well' =>  'A2'},
    { 'source_plate' => '1', 'source_well' =>  'D2', 'dest_plate' => '10', 'dest_well' =>  'A2'},
    { 'source_plate' => '1', 'source_well' =>  'E2', 'dest_plate' => '10', 'dest_well' =>  'A2'},
    { 'source_plate' => '1', 'source_well' =>  'F2', 'dest_plate' => '10', 'dest_well' =>  'A2'},
    { 'source_plate' => '1', 'source_well' =>  'G2', 'dest_plate' => '10', 'dest_well' =>  'A2'},
    { 'source_plate' => '1', 'source_well' =>  'H2', 'dest_plate' => '10', 'dest_well' =>  'A2'},
    { 'source_plate' => '2', 'source_well' =>  'A3', 'dest_plate' => '10', 'dest_well' =>  'A2'},
    { 'source_plate' => '2', 'source_well' =>  'B3', 'dest_plate' => '10', 'dest_well' =>  'A2'},
    { 'source_plate' => '2', 'source_well' =>  'C3', 'dest_plate' => '10', 'dest_well' =>  'A2'},
    { 'source_plate' => '2', 'source_well' =>  'D3', 'dest_plate' => '10', 'dest_well' =>  'A2'},
    { 'source_plate' => '2', 'source_well' =>  'E3', 'dest_plate' => '10', 'dest_well' =>  'A2'},
    { 'source_plate' => '2', 'source_well' =>  'F3', 'dest_plate' => '10', 'dest_well' =>  'A2'},
    { 'source_plate' => '2', 'source_well' =>  'G3', 'dest_plate' => '10', 'dest_well' =>  'A2'},
    { 'source_plate' => '2', 'source_well' =>  'H3', 'dest_plate' => '10', 'dest_well' =>  'A3'},
  ];
  my $EXPECTED_DATA_2 = {
    '10' => {
      'A1' => [
        { 'source_plate' => '1', 'source_well' =>  'A1', },
        { 'source_plate' => '1', 'source_well' =>  'B1', },
        { 'source_plate' => '1', 'source_well' =>  'C1', },
        { 'source_plate' => '1', 'source_well' =>  'D1', },
        { 'source_plate' => '1', 'source_well' =>  'E1', },
        { 'source_plate' => '1', 'source_well' =>  'F1', },
        { 'source_plate' => '1', 'source_well' =>  'G1', },
        { 'source_plate' => '1', 'source_well' =>  'H1', },
        { 'source_plate' => '2', 'source_well' =>  'A1', },
        { 'source_plate' => '2', 'source_well' =>  'B1', },
        { 'source_plate' => '2', 'source_well' =>  'C1', },
        { 'source_plate' => '2', 'source_well' =>  'D1', },
        { 'source_plate' => '2', 'source_well' =>  'E1', },
        { 'source_plate' => '2', 'source_well' =>  'F1', },
        { 'source_plate' => '2', 'source_well' =>  'G1', },
        { 'source_plate' => '2', 'source_well' =>  'H1', },
      ],
      'A2' => [
        { 'source_plate' => '1', 'source_well' =>  'A2', },
        { 'source_plate' => '1', 'source_well' =>  'B2', },
        { 'source_plate' => '1', 'source_well' =>  'C2', },
        { 'source_plate' => '1', 'source_well' =>  'D2', },
        { 'source_plate' => '1', 'source_well' =>  'E2', },
        { 'source_plate' => '1', 'source_well' =>  'F2', },
        { 'source_plate' => '1', 'source_well' =>  'G2', },
        { 'source_plate' => '1', 'source_well' =>  'H2', },
        { 'source_plate' => '2', 'source_well' =>  'A3', },
        { 'source_plate' => '2', 'source_well' =>  'B3', },
        { 'source_plate' => '2', 'source_well' =>  'C3', },
        { 'source_plate' => '2', 'source_well' =>  'D3', },
        { 'source_plate' => '2', 'source_well' =>  'E3', },
        { 'source_plate' => '2', 'source_well' =>  'F3', },
        { 'source_plate' => '2', 'source_well' =>  'G3', },
      ],
      'A3' => [
        { 'source_plate' => '2', 'source_well' =>  'H3', },
      ],
    },
  };
  my $output = wtsi_clarity::file_parsing::ISC_pool_calculator::_transform_mapping($mapping);
  is_deeply( $output,  $EXPECTED_DATA_2,  "_transform_mapping() should return the correct content.");
}

{ # get_volume_calculations_and_warnings

  my $data = {
    '27' => {
      'A1' => 3,
      'B1' => 3,
    }
  };

  my $EXPECTED_DATA = {
    '1000' => {
      'B2' => [
              {
                'Molarity' => '15',
                'source_plate' => '27',
                'Volume' => '50',
                'source_well' => 'A1'
              },
          ]
        },
      };

  my $mapping = [
    { 'source_plate' => '27', 'source_well' =>  'A1', 'dest_plate' => '1000', 'dest_well' =>  'B2'},
  ];

  my $calc = wtsi_clarity::file_parsing::ISC_pool_calculator->new( data                => $data,
                                                                      mapping          => $mapping,
                                                                      min_volume       => 5,
                                                                      max_volume       => 50,
                                                                      max_total_volume => 200,
                                                                      original_plate_barcode => 27,
                                                                    );
  my ($output, $warnings) = $calc->get_volume_calculations_and_warnings();

  is_deeply( $output,  $EXPECTED_DATA,  "get_volume_calculations_and_warnings() should return the correct content.");
}

1;
