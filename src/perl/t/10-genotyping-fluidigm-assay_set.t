use strict;
use warnings;
use Test::More tests => 10;
use Test::Exception;

use_ok('wtsi_clarity::genotyping::fluidigm::assay_set');

my $file_content = [[
                     'S26-A01',
                     'rs0123456',
                     'C',
                     'T',
                     'ABC0123456789',
                     'Unknown',
                     'No Call',
                     '0.1',
                     'XY',
                     'C:T',
                     '0.1',
                     '0.1'
                   ],
                   [
                     'S26-A02',
                     'rs0123456',
                     'A',
                     'C',
                     'ABC0123456789',
                     'Unknown',
                     'No Call',
                     '0.1',
                     'XY',
                     'A:C',
                     '0.1',
                     '0.1'
                   ],
                   [
                     'S26-A03',
                     'GS35205',
                     'C',
                     'A',
                     'ABC0123456789',
                     'Unknown',
                     'No Call',
                     '0.1',
                     'XY',
                     'C:A',
                     '0.1',
                     '0.1'
                   ],
                   ];

# Happy path...
{
  my $assay_set;
  lives_ok {
    $assay_set = wtsi_clarity::genotyping::fluidigm::assay_set->new(
      file_content => $file_content,
    );
  } 'Does not die';
}

# Assay results
{
  my $assay_set = wtsi_clarity::genotyping::fluidigm::assay_set->new(
    file_content => $file_content,
  );

  is(scalar @{$assay_set->assay_results}, 3, 'Has 3 results');
}

# Sample Name
{
  my $assay_set = wtsi_clarity::genotyping::fluidigm::assay_set->new(
    file_content => $file_content,
  );

  is($assay_set->sample_name, 'ABC0123456789', 'Extracts the sample name');

  my $file_content2 = $file_content;

  $file_content2->[0]->[4] = 'Different sample name';

  my $assay_set2 = wtsi_clarity::genotyping::fluidigm::assay_set->new(
    file_content => $file_content2,
  );

  throws_ok { $assay_set2->sample_name } qr/Sample names in assay result set are not homogenous/,
    'Throws when sample names in an assay set are not homogeneous';
}

# Gender Set
{
  my $assay_set = wtsi_clarity::genotyping::fluidigm::assay_set->new(
    file_content => $file_content,
  );

  my $gender_set = ['XY'];

  is_deeply($assay_set->gender_set, $gender_set, 'Correctly creates the gender set');
}

# Gender
{
  my $assay_set = wtsi_clarity::genotyping::fluidigm::assay_set->new(
    file_content => $file_content,
  );

  my $file_content2 = $file_content;
  my @file_content2 = map {
    $_->[8] = 'XX';
    $_;
  } @{$file_content2};

  my $assay_set2 = wtsi_clarity::genotyping::fluidigm::assay_set->new(
    file_content => \@file_content2,
  );

  is($assay_set->gender, 'M', 'Correctly identifies the gender');
  is($assay_set2->gender, 'F', 'Correctly identitfies the gender');

  $file_content2->[3] = [
                     'S26-A03',
                     'GS35205',
                     'C',
                     'A',
                     'ABC0123456789',
                     'Unknown',
                     'No Call',
                     '0.1',
                     'XY',
                     'C:A',
                     '0.1',
                     '0.1'
                   ];

  my $assay_set3 = wtsi_clarity::genotyping::fluidigm::assay_set->new(
    file_content => $file_content2,
  );

  is($assay_set3->gender, 'Unknown', 'Returns unknown if gender set is not homogeneous');
}

# Call Rate
{
  $file_content->[3] = [
                     'S26-A03',
                     'rs1234566',
                     'C',
                     'A',
                     'ABC0123456789',
                     'Unknown',
                     'No Call',
                     '0.1',
                     'No Call',
                     'C:A',
                     '0.1',
                     '0.1'
                   ];

  my $assay_set = wtsi_clarity::genotyping::fluidigm::assay_set->new(
    file_content => $file_content,
  );

  is ($assay_set->call_rate, '3/4', 'Correctly determines the call rate');
}