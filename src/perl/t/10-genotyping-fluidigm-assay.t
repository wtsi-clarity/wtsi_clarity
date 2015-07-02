use strict;
use warnings;
use Test::More tests => 14;

use_ok('wtsi_clarity::genotyping::fluidigm::assay');

{
  my $assay = wtsi_clarity::genotyping::fluidigm::assay->new(
    assay          => 'S26-A01',
    snp_assayed    => 'rs0123456',
    x_allele       => 'C',
    y_allele       => 'T',
    sample_name    => 'ABC0123456789',
    type           => 'Unknown',
    auto           => 'No Call',
    confidence     => '0.1',
    final          => 'XY',
    converted_call => 'C:T',
    x_intensity    => '0.1',
    y_intensity    => '0.1'
  );

  isa_ok($assay, 'wtsi_clarity::genotyping::fluidigm::assay');
}

# is_control
{
  my $assay = wtsi_clarity::genotyping::fluidigm::assay->new(
    assay          => 'S26-A01',
    snp_assayed    => '',
    x_allele       => 'C',
    y_allele       => 'T',
    sample_name    => 'ABC0123456789',
    type           => 'Unknown',
    auto           => 'No Call',
    confidence     => '0.1',
    final          => 'XY',
    converted_call => 'C:T',
    x_intensity    => '0.1',
    y_intensity    => '0.1'
  );

  my $assay2 = wtsi_clarity::genotyping::fluidigm::assay->new(
    assay          => 'S26-A01',
    snp_assayed    => 'rs0123456',
    x_allele       => 'C',
    y_allele       => 'T',
    sample_name    => '[ Empty ]',
    type           => 'Unknown',
    auto           => 'No Call',
    confidence     => '0.1',
    final          => 'XY',
    converted_call => 'C:T',
    x_intensity    => '0.1',
    y_intensity    => '0.1'
  );

  my $assay3 = wtsi_clarity::genotyping::fluidigm::assay->new(
    assay          => 'S26-A01',
    snp_assayed    => 'rs0123456',
    x_allele       => 'C',
    y_allele       => 'T',
    sample_name    => 'ABC0123456789',
    type           => 'NTC',
    auto           => 'No Call',
    confidence     => '0.1',
    final          => 'XY',
    converted_call => 'C:T',
    x_intensity    => '0.1',
    y_intensity    => '0.1'
  );

  my $assay4 = wtsi_clarity::genotyping::fluidigm::assay->new(
    assay          => 'S26-A01',
    snp_assayed    => 'rs0123456',
    x_allele       => 'C',
    y_allele       => 'T',
    sample_name    => 'ABC0123456789',
    type           => 'Unknown',
    auto           => 'No Call',
    confidence     => '0.1',
    final          => 'XY',
    converted_call => 'C:T',
    x_intensity    => '0.1',
    y_intensity    => '0.1'
  );

  is($assay->is_control, 1, 'Assay is seen as a control');
  is($assay2->is_control, 1, 'Assay is seen as a control');
  is($assay3->is_control, 1, 'Assay is seen as a control');
  is($assay4->is_control, '', 'Assay is not seen as a control');
}

# is_call
{
  my $assay = wtsi_clarity::genotyping::fluidigm::assay->new(
    assay          => 'S26-A01',
    snp_assayed    => '',
    x_allele       => 'C',
    y_allele       => 'T',
    sample_name    => 'ABC0123456789',
    type           => 'Unknown',
    auto           => 'No Call',
    confidence     => '0.1',
    final          => 'No Call',
    converted_call => 'C:T',
    x_intensity    => '0.1',
    y_intensity    => '0.1'
  );

  my $assay2 = wtsi_clarity::genotyping::fluidigm::assay->new(
    assay          => 'S26-A01',
    snp_assayed    => '',
    x_allele       => 'C',
    y_allele       => 'T',
    sample_name    => 'ABC0123456789',
    type           => 'Unknown',
    auto           => 'No Call',
    confidence     => '0.1',
    final          => 'XY',
    converted_call => 'C:T',
    x_intensity    => '0.1',
    y_intensity    => '0.1'
  );

  my $assay3 = wtsi_clarity::genotyping::fluidigm::assay->new(
    assay          => 'S26-A01',
    snp_assayed    => '',
    x_allele       => 'C',
    y_allele       => 'T',
    sample_name    => 'ABC0123456789',
    type           => 'Unknown',
    auto           => 'No Call',
    confidence     => '0.1',
    final          => 'XY',
    converted_call => 'No Call',
    x_intensity    => '0.1',
    y_intensity    => '0.1'
  );

  is($assay->is_call, '', 'Assay is not seen as a call');
  is($assay2->is_call, 1, 'Assay is seen as a call');
  is($assay3->is_call, '', 'Assay is not seen as a call');
}

# is_valid
{
  my $assay = wtsi_clarity::genotyping::fluidigm::assay->new(
    assay          => 'S26-A01',
    snp_assayed    => '',
    x_allele       => 'C',
    y_allele       => 'T',
    sample_name    => 'ABC0123456789',
    type           => 'Unknown',
    auto           => 'No Call',
    confidence     => '0.1',
    final          => 'Invalid',
    converted_call => 'C:T',
    x_intensity    => '0.1',
    y_intensity    => '0.1'
  );

  my $assay2 = wtsi_clarity::genotyping::fluidigm::assay->new(
    assay          => 'S26-A01',
    snp_assayed    => '',
    x_allele       => 'C',
    y_allele       => 'T',
    sample_name    => 'ABC0123456789',
    type           => 'Unknown',
    auto           => 'No Call',
    confidence     => '0.1',
    final          => 'XY',
    converted_call => 'Invalid',
    x_intensity    => '0.1',
    y_intensity    => '0.1'
  );

  my $assay3 = wtsi_clarity::genotyping::fluidigm::assay->new(
    assay          => 'S26-A01',
    snp_assayed    => 'rs0123456',
    x_allele       => 'C',
    y_allele       => 'T',
    sample_name    => '[ Empty ]',
    type           => 'Unknown',
    auto           => 'No Call',
    confidence     => '0.1',
    final          => 'XY',
    converted_call => 'C:T',
    x_intensity    => '0.1',
    y_intensity    => '0.1'
  );

  is($assay->is_valid, '', 'Assay is invalid');
  is($assay2->is_valid, '', 'Assay is invalid');
  is($assay3->is_valid, 1, 'Assay is valid');
}

# is_gender_marker
{
  my $assay = wtsi_clarity::genotyping::fluidigm::assay->new(
    assay          => 'S26-A01',
    snp_assayed    => 'rs0123456',
    x_allele       => 'C',
    y_allele       => 'T',
    sample_name    => 'ABC0123456789',
    type           => 'Unknown',
    auto           => 'No Call',
    confidence     => '0.1',
    final          => 'No Call',
    converted_call => 'C:T',
    x_intensity    => '0.1',
    y_intensity    => '0.1'
  );

  my $assay2 = wtsi_clarity::genotyping::fluidigm::assay->new(
    assay          => 'S26-A01',
    snp_assayed    => 'GS1234567',
    x_allele       => 'C',
    y_allele       => 'T',
    sample_name    => 'ABC0123456789',
    type           => 'Unknown',
    auto           => 'No Call',
    confidence     => '0.1',
    final          => 'XY',
    converted_call => 'C:T',
    x_intensity    => '0.1',
    y_intensity    => '0.1'
  );

  is($assay->is_gender_marker, '', 'Assay is not seen as a gender marker');
  is($assay2->is_gender_marker, 1, 'Assay is seen as a gender marker');
}