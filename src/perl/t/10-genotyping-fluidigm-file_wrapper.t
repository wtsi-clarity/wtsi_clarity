use strict;
use warnings;
use Test::More tests => 10;
use Test::Exception;
use Carp;
use English qw{-no_match_vars};

use_ok('wtsi_clarity::genotyping::fluidigm::file_wrapper');

# Instantiating incorrectly...
{
  dies_ok {
    wtsi_clarity::genotyping::fluidigm::file_wrapper->new( file_name => 'fake/file/path' );
  }
    'falls over when file name is not provided';

  dies_ok {
    wtsi_clarity::genotyping::fluidigm::file_wrapper->new(
      file_name => 't/data/genotyping/fluidigm' );
  } 'falls over when file name is actually a directory';
}

# Happy path...
{
  my $file_wrapper;
  lives_ok {
    $file_wrapper = wtsi_clarity::genotyping::fluidigm::file_wrapper->new(
      file_name => 't/data/genotyping/fluidigm/complete/0123456789/0123456789.csv'
    );
  } 'Does not die';
}

{
  my $file_wrapper = wtsi_clarity::genotyping::fluidigm::file_wrapper->new(
    file_name => 't/data/genotyping/fluidigm/complete/0123456789/0123456789.csv'
  );

  open my $in, '<:encoding(utf8)', $file_wrapper->file_name
    or croak "Failed to open Fluidigm export file '",
  $file_wrapper->file_name, "': $OS_ERROR";

  my $sample_data = $file_wrapper->_sample_data_from_fluidigm_table($in);

  my @expected_addresses = (
    'S01', 'S02', 'S03', 'S04', 'S05', 'S06', 'S07', 'S08', 'S09', 'S10',
    'S11', 'S12', 'S13', 'S14', 'S15', 'S16', 'S17', 'S18', 'S19', 'S20',
    'S21', 'S22', 'S23', 'S24', 'S25', 'S26', 'S27', 'S28', 'S29', 'S30',
    'S31', 'S32', 'S33', 'S34', 'S35', 'S36', 'S37', 'S38', 'S39', 'S40',
    'S41', 'S42', 'S43', 'S44', 'S45', 'S46', 'S47', 'S48', 'S49', 'S50',
    'S51', 'S52', 'S53', 'S54', 'S55', 'S56', 'S57', 'S58', 'S59', 'S60',
    'S61', 'S62', 'S63', 'S64', 'S65', 'S66', 'S67', 'S68', 'S69', 'S70',
    'S71', 'S72', 'S73', 'S74', 'S75', 'S76', 'S77', 'S78', 'S79', 'S80',
    'S81', 'S82', 'S83', 'S84', 'S85', 'S86', 'S87', 'S88', 'S89', 'S90',
    'S91', 'S92', 'S93', 'S94', 'S95', 'S96',
  );
  my $expected_well_address_count = 96;

  my $expected_s01_data = [
    [
      'S01-A01', 'rs0123456', 'G', 'G', 'ABC0123456789', 'Unknown', 'No Call', '0.1', 'XY', 'G:G', '0.1', '0.1'
    ],
    [
      'S01-A02', 'rs0123456', 'A', 'T', 'ABC0123456789', 'Unknown', 'No Call', '0.1', 'XY', 'A:T', '0.1', '0.1'
    ],
    [
      'S01-A03', 'rs0123456', 'A', 'G', 'ABC0123456789', 'Unknown', 'No Call', '0.1', 'XY', 'A:G', '0.1', '0.1'
    ],
    [
      'S01-A04', 'rs0123456', 'G', 'T', 'ABC0123456789', 'Unknown', 'No Call', '0.1', 'XY', 'G:T', '0.1', '0.1'
    ],
    [
      'S01-A05', 'rs0123456', 'A', 'C', 'ABC0123456789', 'Unknown', 'No Call', '0.1', 'XY', 'A:C', '0.1', '0.1'
    ],
    [
      'S01-A06', 'rs0123456', 'T', 'G', 'ABC0123456789', 'Unknown', 'No Call', '0.1', 'XY', 'T:G', '0.1', '0.1'
    ],
    [
      'S01-A07', 'rs0123456', 'A', 'C', 'ABC0123456789', 'Unknown', 'No Call', '0.1', 'XY', 'A:C', '0.1', '0.1'
    ],
    [
      'S01-A08', 'rs0123456', 'C', 'T', 'ABC0123456789', 'Unknown', 'No Call', '0.1', 'XY', 'C:T', '0.1', '0.1'
    ],
    [
      'S01-A09', 'rs0123456', 'G', 'C', 'ABC0123456789', 'Unknown', 'No Call', '0.1', 'XY', 'G:C', '0.1', '0.1'
    ],
    [
      'S01-A10', 'rs0123456', 'T', 'A', 'ABC0123456789', 'Unknown', 'No Call', '0.1', 'XY', 'T:A', '0.1', '0.1'
    ],
    [
      'S01-A11', 'rs0123456', 'C', 'T', 'ABC0123456789', 'Unknown', 'No Call', '0.1', 'XY', 'C:T', '0.1', '0.1'
    ],
    [
      'S01-A12', 'rs0123456', 'G', 'T', 'ABC0123456789', 'Unknown', 'No Call', '0.1', 'XY', 'G:T', '0.1', '0.1'
    ],
    [
      'S01-A13', 'rs0123456', 'T', 'G', 'ABC0123456789', 'Unknown', 'No Call', '0.1', 'XY', 'T:G', '0.1', '0.1'
    ],
    [
      'S01-A14', 'rs0123456', 'G', 'A', 'ABC0123456789', 'Unknown', 'No Call', '0.1', 'XY', 'G:A', '0.1', '0.1'
    ],
    [
      'S01-A15', 'rs0123456', 'A', 'A', 'ABC0123456789', 'Unknown', 'No Call', '0.1', 'XY', 'A:A', '0.1', '0.1'
    ],
    [
      'S01-A16', 'rs0123456', 'T', 'T', 'ABC0123456789', 'Unknown', 'No Call', '0.1', 'XY', 'T:T', '0.1', '0.1'
    ],
    [
      'S01-A17', 'rs0123456', 'T', 'G', 'ABC0123456789', 'Unknown', 'No Call', '0.1', 'XY', 'T:G', '0.1', '0.1'
    ],
    [
      'S01-A18', 'rs0123456', 'T', 'A', 'ABC0123456789', 'Unknown', 'No Call', '0.1', 'XY', 'T:A', '0.1', '0.1'
    ],
    [
      'S01-A19', 'rs0123456', 'T', 'C', 'ABC0123456789', 'Unknown', 'No Call', '0.1', 'XY', 'T:C', '0.1', '0.1'
    ],
    [
      'S01-A20', 'rs0123456', 'A', 'A', 'ABC0123456789', 'Unknown', 'No Call', '0.1', 'XY', 'A:A', '0.1', '0.1'
    ],
    [
      'S01-A21', 'rs0123456', 'A', 'C', 'ABC0123456789', 'Unknown', 'No Call', '0.1', 'XY', 'A:C', '0.1', '0.1'
    ],
    [
      'S01-A22', 'rs0123456', 'C', 'T', 'ABC0123456789', 'Unknown', 'No Call', '0.1', 'XY', 'C:T', '0.1', '0.1'
    ],
    [
      'S01-A23', 'rs0123456', 'C', 'G', 'ABC0123456789', 'Unknown', 'No Call', '0.1', 'XY', 'C:G', '0.1', '0.1'
    ],
    [
      'S01-A24', 'rs0123456', 'G', 'T', 'ABC0123456789', 'Unknown', 'No Call', '0.1', 'XY', 'G:T', '0.1', '0.1'
    ],
    [
      'S01-A25', 'rs0123456', 'T', 'T', 'ABC0123456789', 'Unknown', 'No Call', '0.1', 'XY', 'T:T', '0.1', '0.1'
    ],
    [
      'S01-A26', 'rs0123456', 'A', 'G', 'ABC0123456789', 'Unknown', 'No Call', '0.1', 'XY', 'A:G', '0.1', '0.1'
    ],
    [
      'S01-A27', 'rs0123456', 'G', 'A', 'ABC0123456789', 'Unknown', 'No Call', '0.1', 'XY', 'G:A', '0.1', '0.1'
    ],
    [
      'S01-A28', 'rs0123456', 'A', 'A', 'ABC0123456789', 'Unknown', 'No Call', '0.1', 'XY', 'A:A', '0.1', '0.1'
    ],
    [
      'S01-A29', 'rs0123456', 'C', 'T', 'ABC0123456789', 'Unknown', 'No Call', '0.1', 'XY', 'C:T', '0.1', '0.1'
    ],
    [
      'S01-A30', 'rs0123456', 'C', 'G', 'ABC0123456789', 'Unknown', 'No Call', '0.1', 'XY', 'C:G', '0.1', '0.1'
    ],
    [
      'S01-A31', 'rs0123456', 'G', 'A', 'ABC0123456789', 'Unknown', 'No Call', '0.1', 'XY', 'G:A', '0.1', '0.1'
    ],
    [
      'S01-A32', 'rs0123456', 'A', 'G', 'ABC0123456789', 'Unknown', 'No Call', '0.1', 'XY', 'A:G', '0.1', '0.1'
    ],
    [
      'S01-A33', 'rs0123456', 'C', 'T', 'ABC0123456789', 'Unknown', 'No Call', '0.1', 'XY', 'C:T', '0.1', '0.1'
    ],
    [
      'S01-A34', 'rs0123456', 'A', 'A', 'ABC0123456789', 'Unknown', 'No Call', '0.1', 'XY', 'A:A', '0.1', '0.1'
    ],
    [
      'S01-A35', 'rs0123456', 'G', 'T', 'ABC0123456789', 'Unknown', 'No Call', '0.1', 'XY', 'G:T', '0.1', '0.1'
    ],
    [
      'S01-A36', 'rs0123456', 'T', 'A', 'ABC0123456789', 'Unknown', 'No Call', '0.1', 'XY', 'T:A', '0.1', '0.1'
    ],
    [
      'S01-A37', 'rs0123456', 'C', 'T', 'ABC0123456789', 'Unknown', 'No Call', '0.1', 'XY', 'C:T', '0.1', '0.1'
    ],
    [
      'S01-A38', 'rs0123456', 'A', 'A', 'ABC0123456789', 'Unknown', 'No Call', '0.1', 'XY', 'A:A', '0.1', '0.1'
    ],
    [
      'S01-A39', 'rs0123456', 'C', 'C', 'ABC0123456789', 'Unknown', 'No Call', '0.1', 'XY', 'C:C', '0.1', '0.1'
    ],
    [
      'S01-A40', 'rs0123456', 'T', 'A', 'ABC0123456789', 'Unknown', 'No Call', '0.1', 'XY', 'T:A', '0.1', '0.1'
    ],
    [
      'S01-A41', 'rs0123456', 'T', 'G', 'ABC0123456789', 'Unknown', 'No Call', '0.1', 'XY', 'T:G', '0.1', '0.1'
    ],
    [
      'S01-A42', 'rs0123456', 'G', 'A', 'ABC0123456789', 'Unknown', 'No Call', '0.1', 'XY', 'G:A', '0.1', '0.1'
    ],
    [
      'S01-A43', 'rs0123456', 'A', 'G', 'ABC0123456789', 'Unknown', 'No Call', '0.1', 'XY', 'A:G', '0.1', '0.1'
    ],
    [
      'S01-A44', 'rs0123456', 'G', 'G', 'ABC0123456789', 'Unknown', 'No Call', '0.1', 'XY', 'G:G', '0.1', '0.1'
    ],
    [
      'S01-A45', 'rs0123456', 'C', 'G', 'ABC0123456789', 'Unknown', 'No Call', '0.1', 'XY', 'C:G', '0.1', '0.1'
    ],
    [
      'S01-A46', 'rs0123456', 'T', 'C', 'ABC0123456789', 'Unknown', 'No Call', '0.1', 'XY', 'T:C', '0.1', '0.1'
    ],
    [
      'S01-A47', 'rs0123456', 'C', 'T', 'ABC0123456789', 'Unknown', 'No Call', '0.1', 'XY', 'C:T', '0.1', '0.1'
    ],
    [
      'S01-A48', 'rs0123456', 'C', 'G', 'ABC0123456789', 'Unknown', 'No Call', '0.1', 'XY', 'C:G', '0.1', '0.1'
    ],
    [
      'S01-A49', 'rs0123456', 'T', 'C', 'ABC0123456789', 'Unknown', 'No Call', '0.1', 'XY', 'T:C', '0.1', '0.1'
    ],
    [
      'S01-A50', 'rs0123456', 'A', 'T', 'ABC0123456789', 'Unknown', 'No Call', '0.1', 'XY', 'A:T', '0.1', '0.1'
    ],
    [
      'S01-A51', 'rs0123456', 'G', 'A', 'ABC0123456789', 'Unknown', 'No Call', '0.1', 'XY', 'G:A', '0.1', '0.1'
    ],
    [
      'S01-A52', 'rs0123456', 'C', 'A', 'ABC0123456789', 'Unknown', 'No Call', '0.1', 'XY', 'C:A', '0.1', '0.1'
    ],
    [
      'S01-A53', 'rs0123456', 'T', 'T', 'ABC0123456789', 'Unknown', 'No Call', '0.1', 'XY', 'T:T', '0.1', '0.1'
    ],
    [
      'S01-A54', 'rs0123456', 'T', 'A', 'ABC0123456789', 'Unknown', 'No Call', '0.1', 'XY', 'T:A', '0.1', '0.1'
    ],
    [
      'S01-A55', 'rs0123456', 'A', 'G', 'ABC0123456789', 'Unknown', 'No Call', '0.1', 'XY', 'A:G', '0.1', '0.1'
    ],
    [
      'S01-A56', 'rs0123456', 'G', 'A', 'ABC0123456789', 'Unknown', 'No Call', '0.1', 'XY', 'G:A', '0.1', '0.1'
    ],
    [
      'S01-A57', 'rs0123456', 'T', 'A', 'ABC0123456789', 'Unknown', 'No Call', '0.1', 'XY', 'T:A', '0.1', '0.1'
    ],
    [
      'S01-A58', 'rs0123456', 'G', 'T', 'ABC0123456789', 'Unknown', 'No Call', '0.1', 'XY', 'G:T', '0.1', '0.1'
    ],
    [
      'S01-A59', 'rs0123456', 'C', 'T', 'ABC0123456789', 'Unknown', 'No Call', '0.1', 'XY', 'C:T', '0.1', '0.1'
    ],
    [
      'S01-A60', 'rs0123456', 'A', 'T', 'ABC0123456789', 'Unknown', 'No Call', '0.1', 'XY', 'A:T', '0.1', '0.1'
    ],
    [
      'S01-A61', 'rs0123456', 'A', 'C', 'ABC0123456789', 'Unknown', 'No Call', '0.1', 'XY', 'A:C', '0.1', '0.1'
    ],
    [
      'S01-A62', 'rs0123456', 'A', 'T', 'ABC0123456789', 'Unknown', 'No Call', '0.1', 'XY', 'A:T', '0.1', '0.1'
    ],
    [
      'S01-A63', 'rs0123456', 'G', 'A', 'ABC0123456789', 'Unknown', 'No Call', '0.1', 'XY', 'G:A', '0.1', '0.1'
    ],
    [
      'S01-A64', 'rs0123456', 'C', 'A', 'ABC0123456789', 'Unknown', 'No Call', '0.1', 'XY', 'C:A', '0.1', '0.1'
    ],
    [
      'S01-A65', 'rs0123456', 'A', 'T', 'ABC0123456789', 'Unknown', 'No Call', '0.1', 'XY', 'A:T', '0.1', '0.1'
    ],
    [
      'S01-A66', 'rs0123456', 'A', 'A', 'ABC0123456789', 'Unknown', 'No Call', '0.1', 'XY', 'A:A', '0.1', '0.1'
    ],
    [
      'S01-A67', 'rs0123456', 'A', 'C', 'ABC0123456789', 'Unknown', 'No Call', '0.1', 'XY', 'A:C', '0.1', '0.1'
    ],
    [
      'S01-A68', 'rs0123456', 'A', 'G', 'ABC0123456789', 'Unknown', 'No Call', '0.1', 'XY', 'A:G', '0.1', '0.1'
    ],
    [
      'S01-A69', 'rs0123456', 'G', 'A', 'ABC0123456789', 'Unknown', 'No Call', '0.1', 'XY', 'G:A', '0.1', '0.1'
    ],
    [
      'S01-A70', 'rs0123456', 'C', 'C', 'ABC0123456789', 'Unknown', 'No Call', '0.1', 'XY', 'C:C', '0.1', '0.1'
    ],
    [
      'S01-A71', 'rs0123456', 'A', 'T', 'ABC0123456789', 'Unknown', 'No Call', '0.1', 'XY', 'A:T', '0.1', '0.1'
    ],
    [
      'S01-A72', 'rs0123456', 'G', 'T', 'ABC0123456789', 'Unknown', 'No Call', '0.1', 'XY', 'G:T', '0.1', '0.1'
    ],
    [
      'S01-A73', 'rs0123456', 'G', 'T', 'ABC0123456789', 'Unknown', 'No Call', '0.1', 'XY', 'G:T', '0.1', '0.1'
    ],
    [
      'S01-A74', 'rs0123456', 'C', 'T', 'ABC0123456789', 'Unknown', 'No Call', '0.1', 'XY', 'C:T', '0.1', '0.1'
    ],
    [
      'S01-A75', 'rs0123456', 'A', 'C', 'ABC0123456789', 'Unknown', 'No Call', '0.1', 'XY', 'A:C', '0.1', '0.1'
    ],
    [
      'S01-A76', 'rs0123456', 'C', 'G', 'ABC0123456789', 'Unknown', 'No Call', '0.1', 'XY', 'C:G', '0.1', '0.1'
    ],
    [
      'S01-A77', 'rs0123456', 'C', 'G', 'ABC0123456789', 'Unknown', 'No Call', '0.1', 'XY', 'C:G', '0.1', '0.1'
    ],
    [
      'S01-A78', 'rs0123456', 'G', 'A', 'ABC0123456789', 'Unknown', 'No Call', '0.1', 'XY', 'G:A', '0.1', '0.1'
    ],
    [
      'S01-A79', 'rs0123456', 'A', 'A', 'ABC0123456789', 'Unknown', 'No Call', '0.1', 'XY', 'A:A', '0.1', '0.1'
    ],
    [
      'S01-A80', 'rs0123456', 'G', 'A', 'ABC0123456789', 'Unknown', 'No Call', '0.1', 'XY', 'G:A', '0.1', '0.1'
    ],
    [
      'S01-A81', 'rs0123456', 'A', 'C', 'ABC0123456789', 'Unknown', 'No Call', '0.1', 'XY', 'A:C', '0.1', '0.1'
    ],
    [
      'S01-A82', 'rs0123456', 'A', 'A', 'ABC0123456789', 'Unknown', 'No Call', '0.1', 'XY', 'A:A', '0.1', '0.1'
    ],
    [
      'S01-A83', 'rs0123456', 'C', 'G', 'ABC0123456789', 'Unknown', 'No Call', '0.1', 'XY', 'C:G', '0.1', '0.1'
    ],
    [
      'S01-A84', 'rs0123456', 'A', 'C', 'ABC0123456789', 'Unknown', 'No Call', '0.1', 'XY', 'A:C', '0.1', '0.1'
    ],
    [
      'S01-A85', 'rs0123456', 'C', 'G', 'ABC0123456789', 'Unknown', 'No Call', '0.1', 'XY', 'C:G', '0.1', '0.1'
    ],
    [
      'S01-A86', 'rs0123456', 'A', 'G', 'ABC0123456789', 'Unknown', 'No Call', '0.1', 'XY', 'A:G', '0.1', '0.1'
    ],
    [
      'S01-A87', 'rs0123456', 'G', 'C', 'ABC0123456789', 'Unknown', 'No Call', '0.1', 'XY', 'G:C', '0.1', '0.1'
    ],
    [
      'S01-A88', 'rs0123456', 'C', 'G', 'ABC0123456789', 'Unknown', 'No Call', '0.1', 'XY', 'C:G', '0.1', '0.1'
    ],
    [
      'S01-A89', 'rs0123456', 'C', 'A', 'ABC0123456789', 'Unknown', 'No Call', '0.1', 'XY', 'C:A', '0.1', '0.1'
    ],
    [
      'S01-A90', 'rs0123456', 'G', 'C', 'ABC0123456789', 'Unknown', 'No Call', '0.1', 'XY', 'G:C', '0.1', '0.1'
    ],
    [
      'S01-A91', 'rs0123456', 'T', 'C', 'ABC0123456789', 'Unknown', 'No Call', '0.1', 'XY', 'T:C', '0.1', '0.1'
    ],
    [
      'S01-A92', 'rs0123456', 'G', 'C', 'ABC0123456789', 'Unknown', 'No Call', '0.1', 'XY', 'G:C', '0.1', '0.1'
    ],
    [
      'S01-A93', 'rs0123456', 'G', 'T', 'ABC0123456789', 'Unknown', 'No Call', '0.1', 'XY', 'G:T', '0.1', '0.1'
    ],
    [
      'S01-A94', 'rs0123456', 'T', 'A', 'ABC0123456789', 'Unknown', 'No Call', '0.1', 'XY', 'T:A', '0.1', '0.1'
    ],
    [
      'S01-A95', 'rs0123456', 'C', 'G', 'ABC0123456789', 'Unknown', 'No Call', '0.1', 'XY', 'C:G', '0.1', '0.1'
    ],
    [
      'S01-A96', 'rs0123456', 'T', 'T', 'ABC0123456789', 'Unknown', 'No Call', '0.1', 'XY', 'T:T', '0.1', '0.1'
    ]
  ];

  my $expected_s12_data = [
    [
      'S12-A01', 'rs0123456', 'C', 'T', 'ABC0123456789', 'Unknown', 'No Call', '0.1', 'XY', 'C:T', '0.1', '0.1'
    ],
    [
      'S12-A02', 'rs0123456', 'G', 'G', 'ABC0123456789', 'Unknown', 'No Call', '0.1', 'XY', 'G:G', '0.1', '0.1'
    ],
    [
      'S12-A03', 'rs0123456', 'A', 'G', 'ABC0123456789', 'Unknown', 'No Call', '0.1', 'XY', 'A:G', '0.1', '0.1'
    ],
    [
      'S12-A04', 'rs0123456', 'G', 'C', 'ABC0123456789', 'Unknown', 'No Call', '0.1', 'XY', 'G:C', '0.1', '0.1'
    ],
    [
      'S12-A05', 'rs0123456', 'T', 'T', 'ABC0123456789', 'Unknown', 'No Call', '0.1', 'XY', 'T:T', '0.1', '0.1'
    ],
    [
      'S12-A06', 'rs0123456', 'A', 'G', 'ABC0123456789', 'Unknown', 'No Call', '0.1', 'XY', 'A:G', '0.1', '0.1'
    ],
    [
      'S12-A07', 'rs0123456', 'T', 'C', 'ABC0123456789', 'Unknown', 'No Call', '0.1', 'XY', 'T:C', '0.1', '0.1'
    ],
    [
      'S12-A08', 'rs0123456', 'C', 'A', 'ABC0123456789', 'Unknown', 'No Call', '0.1', 'XY', 'C:A', '0.1', '0.1'
    ],
    [
      'S12-A09', 'rs0123456', 'C', 'A', 'ABC0123456789', 'Unknown', 'No Call', '0.1', 'XY', 'C:A', '0.1', '0.1'
    ],
    [
      'S12-A10', 'rs0123456', 'A', 'C', 'ABC0123456789', 'Unknown', 'No Call', '0.1', 'XY', 'A:C', '0.1', '0.1'
    ],
    [
      'S12-A11', 'rs0123456', 'C', 'C', 'ABC0123456789', 'Unknown', 'No Call', '0.1', 'XY', 'C:C', '0.1', '0.1'
    ],
    [
      'S12-A12', 'rs0123456', 'T', 'C', 'ABC0123456789', 'Unknown', 'No Call', '0.1', 'XY', 'T:C', '0.1', '0.1'
    ],
    [
      'S12-A13', 'rs0123456', 'A', 'G', 'ABC0123456789', 'Unknown', 'No Call', '0.1', 'XY', 'A:G', '0.1', '0.1'
    ],
    [
      'S12-A14', 'rs0123456', 'G', 'A', 'ABC0123456789', 'Unknown', 'No Call', '0.1', 'XY', 'G:A', '0.1', '0.1'
    ],
    [
      'S12-A15', 'rs0123456', 'C', 'C', 'ABC0123456789', 'Unknown', 'No Call', '0.1', 'XY', 'C:C', '0.1', '0.1'
    ],
    [
      'S12-A16', 'rs0123456', 'G', 'A', 'ABC0123456789', 'Unknown', 'No Call', '0.1', 'XY', 'G:A', '0.1', '0.1'
    ],
    [
      'S12-A17', 'rs0123456', 'A', 'G', 'ABC0123456789', 'Unknown', 'No Call', '0.1', 'XY', 'A:G', '0.1', '0.1'
    ],
    [
      'S12-A18', 'rs0123456', 'G', 'G', 'ABC0123456789', 'Unknown', 'No Call', '0.1', 'XY', 'G:G', '0.1', '0.1'
    ],
    [
      'S12-A19', 'rs0123456', 'A', 'G', 'ABC0123456789', 'Unknown', 'No Call', '0.1', 'XY', 'A:G', '0.1', '0.1'
    ],
    [
      'S12-A20', 'rs0123456', 'G', 'T', 'ABC0123456789', 'Unknown', 'No Call', '0.1', 'XY', 'G:T', '0.1', '0.1'
    ],
    [
      'S12-A21', 'rs0123456', 'G', 'A', 'ABC0123456789', 'Unknown', 'No Call', '0.1', 'XY', 'G:A', '0.1', '0.1'
    ],
    [
      'S12-A22', 'rs0123456', 'T', 'G', 'ABC0123456789', 'Unknown', 'No Call', '0.1', 'XY', 'T:G', '0.1', '0.1'
    ],
    [
      'S12-A23', 'rs0123456', 'T', 'C', 'ABC0123456789', 'Unknown', 'No Call', '0.1', 'XY', 'T:C', '0.1', '0.1'
    ],
    [
      'S12-A24', 'rs0123456', 'A', 'G', 'ABC0123456789', 'Unknown', 'No Call', '0.1', 'XY', 'A:G', '0.1', '0.1'
    ],
    [
      'S12-A25', 'rs0123456', 'A', 'C', 'ABC0123456789', 'Unknown', 'No Call', '0.1', 'XY', 'A:C', '0.1', '0.1'
    ],
    [
      'S12-A26', 'rs0123456', 'G', 'C', 'ABC0123456789', 'Unknown', 'No Call', '0.1', 'XY', 'G:C', '0.1', '0.1'
    ],
    [
      'S12-A27', 'rs0123456', 'G', 'C', 'ABC0123456789', 'Unknown', 'No Call', '0.1', 'XY', 'G:C', '0.1', '0.1'
    ],
    [
      'S12-A28', 'rs0123456', 'A', 'T', 'ABC0123456789', 'Unknown', 'No Call', '0.1', 'XY', 'A:T', '0.1', '0.1'
    ],
    [
      'S12-A29', 'rs0123456', 'G', 'A', 'ABC0123456789', 'Unknown', 'No Call', '0.1', 'XY', 'G:A', '0.1', '0.1'
    ],
    [
      'S12-A30', 'rs0123456', 'C', 'C', 'ABC0123456789', 'Unknown', 'No Call', '0.1', 'XY', 'C:C', '0.1', '0.1'
    ],
    [
      'S12-A31', 'rs0123456', 'G', 'A', 'ABC0123456789', 'Unknown', 'No Call', '0.1', 'XY', 'G:A', '0.1', '0.1'
    ],
    [
      'S12-A32', 'rs0123456', 'C', 'T', 'ABC0123456789', 'Unknown', 'No Call', '0.1', 'XY', 'C:T', '0.1', '0.1'
    ],
    [
      'S12-A33', 'rs0123456', 'A', 'A', 'ABC0123456789', 'Unknown', 'No Call', '0.1', 'XY', 'A:A', '0.1', '0.1'
    ],
    [
      'S12-A34', 'rs0123456', 'T', 'A', 'ABC0123456789', 'Unknown', 'No Call', '0.1', 'XY', 'T:A', '0.1', '0.1'
    ],
    [
      'S12-A35', 'rs0123456', 'T', 'A', 'ABC0123456789', 'Unknown', 'No Call', '0.1', 'XY', 'T:A', '0.1', '0.1'
    ],
    [
      'S12-A36', 'rs0123456', 'T', 'G', 'ABC0123456789', 'Unknown', 'No Call', '0.1', 'XY', 'T:G', '0.1', '0.1'
    ],
    [
      'S12-A37', 'rs0123456', 'C', 'G', 'ABC0123456789', 'Unknown', 'No Call', '0.1', 'XY', 'C:G', '0.1', '0.1'
    ],
    [
      'S12-A38', 'rs0123456', 'A', 'A', 'ABC0123456789', 'Unknown', 'No Call', '0.1', 'XY', 'A:A', '0.1', '0.1'
    ],
    [
      'S12-A39', 'rs0123456', 'C', 'A', 'ABC0123456789', 'Unknown', 'No Call', '0.1', 'XY', 'C:A', '0.1', '0.1'
    ],
    [
      'S12-A40', 'rs0123456', 'A', 'C', 'ABC0123456789', 'Unknown', 'No Call', '0.1', 'XY', 'A:C', '0.1', '0.1'
    ],
    [
      'S12-A41', 'rs0123456', 'C', 'T', 'ABC0123456789', 'Unknown', 'No Call', '0.1', 'XY', 'C:T', '0.1', '0.1'
    ],
    [
      'S12-A42', 'rs0123456', 'G', 'C', 'ABC0123456789', 'Unknown', 'No Call', '0.1', 'XY', 'G:C', '0.1', '0.1'
    ],
    [
      'S12-A43', 'rs0123456', 'G', 'G', 'ABC0123456789', 'Unknown', 'No Call', '0.1', 'XY', 'G:G', '0.1', '0.1'
    ],
    [
      'S12-A44', 'rs0123456', 'G', 'C', 'ABC0123456789', 'Unknown', 'No Call', '0.1', 'XY', 'G:C', '0.1', '0.1'
    ],
    [
      'S12-A45', 'rs0123456', 'A', 'G', 'ABC0123456789', 'Unknown', 'No Call', '0.1', 'XY', 'A:G', '0.1', '0.1'
    ],
    [
      'S12-A46', 'rs0123456', 'G', 'A', 'ABC0123456789', 'Unknown', 'No Call', '0.1', 'XY', 'G:A', '0.1', '0.1'
    ],
    [
      'S12-A47', 'rs0123456', 'C', 'G', 'ABC0123456789', 'Unknown', 'No Call', '0.1', 'XY', 'C:G', '0.1', '0.1'
    ],
    [
      'S12-A48', 'rs0123456', 'T', 'G', 'ABC0123456789', 'Unknown', 'No Call', '0.1', 'XY', 'T:G', '0.1', '0.1'
    ],
    [
      'S12-A49', 'rs0123456', 'A', 'A', 'ABC0123456789', 'Unknown', 'No Call', '0.1', 'XY', 'A:A', '0.1', '0.1'
    ],
    [
      'S12-A50', 'rs0123456', 'C', 'G', 'ABC0123456789', 'Unknown', 'No Call', '0.1', 'XY', 'C:G', '0.1', '0.1'
    ],
    [
      'S12-A51', 'rs0123456', 'A', 'G', 'ABC0123456789', 'Unknown', 'No Call', '0.1', 'XY', 'A:G', '0.1', '0.1'
    ],
    [
      'S12-A52', 'rs0123456', 'A', 'A', 'ABC0123456789', 'Unknown', 'No Call', '0.1', 'XY', 'A:A', '0.1', '0.1'
    ],
    [
      'S12-A53', 'rs0123456', 'T', 'T', 'ABC0123456789', 'Unknown', 'No Call', '0.1', 'XY', 'T:T', '0.1', '0.1'
    ],
    [
      'S12-A54', 'rs0123456', 'G', 'C', 'ABC0123456789', 'Unknown', 'No Call', '0.1', 'XY', 'G:C', '0.1', '0.1'
    ],
    [
      'S12-A55', 'rs0123456', 'T', 'A', 'ABC0123456789', 'Unknown', 'No Call', '0.1', 'XY', 'T:A', '0.1', '0.1'
    ],
    [
      'S12-A56', 'rs0123456', 'C', 'C', 'ABC0123456789', 'Unknown', 'No Call', '0.1', 'XY', 'C:C', '0.1', '0.1'
    ],
    [
      'S12-A57', 'rs0123456', 'C', 'G', 'ABC0123456789', 'Unknown', 'No Call', '0.1', 'XY', 'C:G', '0.1', '0.1'
    ],
    [
      'S12-A58', 'rs0123456', 'G', 'A', 'ABC0123456789', 'Unknown', 'No Call', '0.1', 'XY', 'G:A', '0.1', '0.1'
    ],
    [
      'S12-A59', 'rs0123456', 'T', 'A', 'ABC0123456789', 'Unknown', 'No Call', '0.1', 'XY', 'T:A', '0.1', '0.1'
    ],
    [
      'S12-A60', 'rs0123456', 'C', 'A', 'ABC0123456789', 'Unknown', 'No Call', '0.1', 'XY', 'C:A', '0.1', '0.1'
    ],
    [
      'S12-A61', 'rs0123456', 'A', 'G', 'ABC0123456789', 'Unknown', 'No Call', '0.1', 'XY', 'A:G', '0.1', '0.1'
    ],
    [
      'S12-A62', 'rs0123456', 'G', 'G', 'ABC0123456789', 'Unknown', 'No Call', '0.1', 'XY', 'G:G', '0.1', '0.1'
    ],
    [
      'S12-A63', 'rs0123456', 'A', 'A', 'ABC0123456789', 'Unknown', 'No Call', '0.1', 'XY', 'A:A', '0.1', '0.1'
    ],
    [
      'S12-A64', 'rs0123456', 'C', 'G', 'ABC0123456789', 'Unknown', 'No Call', '0.1', 'XY', 'C:G', '0.1', '0.1'
    ],
    [
      'S12-A65', 'rs0123456', 'G', 'A', 'ABC0123456789', 'Unknown', 'No Call', '0.1', 'XY', 'G:A', '0.1', '0.1'
    ],
    [
      'S12-A66', 'rs0123456', 'A', 'C', 'ABC0123456789', 'Unknown', 'No Call', '0.1', 'XY', 'A:C', '0.1', '0.1'
    ],
    [
      'S12-A67', 'rs0123456', 'G', 'T', 'ABC0123456789', 'Unknown', 'No Call', '0.1', 'XY', 'G:T', '0.1', '0.1'
    ],
    [
      'S12-A68', 'rs0123456', 'C', 'C', 'ABC0123456789', 'Unknown', 'No Call', '0.1', 'XY', 'C:C', '0.1', '0.1'
    ],
    [
      'S12-A69', 'rs0123456', 'T', 'G', 'ABC0123456789', 'Unknown', 'No Call', '0.1', 'XY', 'T:G', '0.1', '0.1'
    ],
    [
      'S12-A70', 'rs0123456', 'C', 'G', 'ABC0123456789', 'Unknown', 'No Call', '0.1', 'XY', 'C:G', '0.1', '0.1'
    ],
    [
      'S12-A71', 'rs0123456', 'G', 'T', 'ABC0123456789', 'Unknown', 'No Call', '0.1', 'XY', 'G:T', '0.1', '0.1'
    ],
    [
      'S12-A72', 'rs0123456', 'C', 'T', 'ABC0123456789', 'Unknown', 'No Call', '0.1', 'XY', 'C:T', '0.1', '0.1'
    ],
    [
      'S12-A73', 'rs0123456', 'G', 'C', 'ABC0123456789', 'Unknown', 'No Call', '0.1', 'XY', 'G:C', '0.1', '0.1'
    ],
    [
      'S12-A74', 'rs0123456', 'T', 'C', 'ABC0123456789', 'Unknown', 'No Call', '0.1', 'XY', 'T:C', '0.1', '0.1'
    ],
    [
      'S12-A75', 'rs0123456', 'C', 'T', 'ABC0123456789', 'Unknown', 'No Call', '0.1', 'XY', 'C:T', '0.1', '0.1'
    ],
    [
      'S12-A76', 'rs0123456', 'T', 'C', 'ABC0123456789', 'Unknown', 'No Call', '0.1', 'XY', 'T:C', '0.1', '0.1'
    ],
    [
      'S12-A77', 'rs0123456', 'C', 'C', 'ABC0123456789', 'Unknown', 'No Call', '0.1', 'XY', 'C:C', '0.1', '0.1'
    ],
    [
      'S12-A78', 'rs0123456', 'A', 'G', 'ABC0123456789', 'Unknown', 'No Call', '0.1', 'XY', 'A:G', '0.1', '0.1'
    ],
    [
      'S12-A79', 'rs0123456', 'G', 'G', 'ABC0123456789', 'Unknown', 'No Call', '0.1', 'XY', 'G:G', '0.1', '0.1'
    ],
    [
      'S12-A80', 'rs0123456', 'G', 'G', 'ABC0123456789', 'Unknown', 'No Call', '0.1', 'XY', 'G:G', '0.1', '0.1'
    ],
    [
      'S12-A81', 'rs0123456', 'T', 'C', 'ABC0123456789', 'Unknown', 'No Call', '0.1', 'XY', 'T:C', '0.1', '0.1'
    ],
    [
      'S12-A82', 'rs0123456', 'T', 'G', 'ABC0123456789', 'Unknown', 'No Call', '0.1', 'XY', 'T:G', '0.1', '0.1'
    ],
    [
      'S12-A83', 'rs0123456', 'G', 'C', 'ABC0123456789', 'Unknown', 'No Call', '0.1', 'XY', 'G:C', '0.1', '0.1'
    ],
    [
      'S12-A84', 'rs0123456', 'C', 'A', 'ABC0123456789', 'Unknown', 'No Call', '0.1', 'XY', 'C:A', '0.1', '0.1'
    ],
    [
      'S12-A85', 'rs0123456', 'C', 'A', 'ABC0123456789', 'Unknown', 'No Call', '0.1', 'XY', 'C:A', '0.1', '0.1'
    ],
    [
      'S12-A86', 'rs0123456', 'A', 'G', 'ABC0123456789', 'Unknown', 'No Call', '0.1', 'XY', 'A:G', '0.1', '0.1'
    ],
    [
      'S12-A87', 'rs0123456', 'T', 'G', 'ABC0123456789', 'Unknown', 'No Call', '0.1', 'XY', 'T:G', '0.1', '0.1'
    ],
    [
      'S12-A88', 'rs0123456', 'A', 'T', 'ABC0123456789', 'Unknown', 'No Call', '0.1', 'XY', 'A:T', '0.1', '0.1'
    ],
    [
      'S12-A89', 'rs0123456', 'A', 'A', 'ABC0123456789', 'Unknown', 'No Call', '0.1', 'XY', 'A:A', '0.1', '0.1'
    ],
    [
      'S12-A90', 'rs0123456', 'A', 'C', 'ABC0123456789', 'Unknown', 'No Call', '0.1', 'XY', 'A:C', '0.1', '0.1'
    ],
    [
      'S12-A91', 'rs0123456', 'G', 'T', 'ABC0123456789', 'Unknown', 'No Call', '0.1', 'XY', 'G:T', '0.1', '0.1'
    ],
    [
      'S12-A92', 'rs0123456', 'G', 'A', 'ABC0123456789', 'Unknown', 'No Call', '0.1', 'XY', 'G:A', '0.1', '0.1'
    ],
    [
      'S12-A93', 'rs0123456', 'T', 'G', 'ABC0123456789', 'Unknown', 'No Call', '0.1', 'XY', 'T:G', '0.1', '0.1'
    ],
    [
      'S12-A94', 'rs0123456', 'T', 'T', 'ABC0123456789', 'Unknown', 'No Call', '0.1', 'XY', 'T:T', '0.1', '0.1'
    ],
    [
      'S12-A95', 'rs0123456', 'C', 'C', 'ABC0123456789', 'Unknown', 'No Call', '0.1', 'XY', 'C:C', '0.1', '0.1'
    ],
    [
      'S12-A96', 'rs0123456', 'T', 'C', 'ABC0123456789', 'Unknown', 'No Call', '0.1', 'XY', 'T:C', '0.1', '0.1'
    ]
  ];

  my @actual_well_addresses = sort keys %{$sample_data};
  is_deeply(\@actual_well_addresses, \@expected_addresses, 'Returns the correct well addressees');
  is(scalar @actual_well_addresses, $expected_well_address_count, 'Returns the correct number of well addresses');

  is_deeply($sample_data->{'S01'}, $expected_s01_data, 'Returns the correct data for S01 well address');
  is_deeply($sample_data->{'S12'}, $expected_s12_data, 'Returns the correct data for S12 well address');
}

{
  throws_ok {
    my $file_wrapper = wtsi_clarity::genotyping::fluidigm::file_wrapper->new(
      file_name => 't/data/genotyping/fluidigm/missing_data/0123456789/0123456789.csv'
    );
  }
    qr/Parse error: expected 9216 or 4608 sample data rows, found/,
    'Throws error when data missing from the input table.';
}

{
  throws_ok {
    my $file_wrapper = wtsi_clarity::genotyping::fluidigm::file_wrapper->new(
      file_name => 't/data/genotyping/fluidigm/missing_data/0123456789/0123456788.csv'
    );
  }
    qr/Parse error: expected data for 96 samples, found/,
    'Throws error when well data missing from the 96 well input table.';
}

1;