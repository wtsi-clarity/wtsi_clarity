use strict;
use warnings;
use Test::More tests => 16;
use Test::Exception;

use_ok 'wtsi_clarity::genotyping::fluidigm_analysis';

# Check everything gets set correctly on initialisation
{
  my $samples = [
    {
      well_location        => 'A01',
      sample_name          => 'sample01',
      sample_concentration => '2.333',
      sample_type          => 'NTC',
    }
  ];

  my $file = wtsi_clarity::genotyping::fluidigm_analysis->new(
    file_format  => 'BioMark Something',
    sample_plate => 'DN12312313Q',
    barcode      => 123456789,
    description  => 'Description',
    plate_type   => 'My Plate Type',
    samples      => $samples,
  );

  isa_ok($file, 'wtsi_clarity::genotyping::fluidigm_analysis', 'Creates the object correctly');

  is($file->file_format, 'BioMark Something', 'Sets the file_format');
  is($file->sample_plate, 'DN12312313Q', 'Sets the sample plate');
  is($file->barcode, 123456789, 'Sets the barcode');
  is($file->description, 'Description', 'Sets the description');
  is($file->plate_type, 'My Plate Type', 'Sets the plate_type');

  is_deeply($file->samples, $samples, 'Sets the samples');

  my $file2 = wtsi_clarity::genotyping::fluidigm_analysis->new(
    sample_plate => 'Plate1',
    barcode      => 1234,
    samples      => $samples,
  );

  is($file2->file_format, 'BioMark Sample Format V1.0', 'Sets the file format to BioMark Sample Format when not present');
  is($file2->description, 'Plate1', 'Sets the description to the same as the sample_plate when missing');
  is($file2->plate_type, 'SBS96', 'Plate type defaults to SBS96');
}

# Test samples are valid
{
  my $samples = [
    {
      well_location        => 'A01',
      sample_name          => 'sample01',
      sample_concentration => '2.333',
      sample_type          => 'NTC',
    },
    {
      well_location => 'B01',
      sample_name   => 'sample02',
    },
    {
      well_location => 'C01',
    }
  ];

  throws_ok {
    wtsi_clarity::genotyping::fluidigm_analysis->new(
      sample_plate => 'DN12312313Q',
      barcode      => 123456789,
      description  => 'Description',
      plate_type   => 'My Plate Type',
      samples      => $samples,
    );
  } qr/Samples passed to Fluidigm Analysis are not valid/,
    'Throws an error when a sample name is missing from a sample';
}

# Test sample data is formatted properly for csv writer
{
  my $samples = [
    {
      well_location        => 'A01',
      sample_name          => 'sample01',
      sample_concentration => '2.333',
      sample_type          => 'NTC',
    },
    {
      well_location => 'B01',
      sample_name   => 'sample02',
    }
  ];

  my $expected_data = [{
      'Well Location' => 'A01',
      'Sample Name' => 'sample01',
      'Sample Concentration' => '2.333',
      'Sample Type' => 'NTC',
    }, {
      'Well Location' => 'B01',
      'Sample Name' => 'sample02',
      'Sample Concentration' => '',
      'Sample Type' => 'Unknown',
    }
  ];

  my $file = wtsi_clarity::genotyping::fluidigm_analysis->new(
    sample_plate => 'DN12312313Q',
    barcode      => 123456789,
    description  => 'Description',
    plate_type   => 'My Plate Type',
    samples      => $samples,
  );

  is_deeply($file->_data, $expected_data, 'Converts samples into necessary data format');
}

# Test file metadata is formatted properly
{
  my $samples = [];

  my $expected_metadata = [
    'File Format, BioMark Sample Format V1.0, , ',
    'Sample Plate, DN12312313Q, , ',
    'Barcode ID, 123456789, , ',
    'Description, DN12312313Q, , ',
    'Plate Type, SBS96, , ',
    ' , , , ',
  ];

  my $file = wtsi_clarity::genotyping::fluidigm_analysis->new(
    sample_plate => 'DN12312313Q',
    barcode      => 123456789,
    samples      => $samples,
  );

  is_deeply($file->_file_metadata, $expected_metadata, 'Correctly formats the attributes for the file metadata');
}

# Test text file is created properly
{
  my $samples = [
    {
      well_location        => 'A01',
      sample_name          => 'sample01',
      sample_concentration => '2.333',
      sample_type          => 'NTC',
    },
    {
      well_location => 'B01',
      sample_name   => 'sample02',
    }
  ];

  my $expected_content = [
    'File Format, BioMark Sample Format V1.0, , ',
    'Sample Plate, DN12312313Q, , ',
    'Barcode ID, 123456789, , ',
    'Description, DN12312313Q, , ',
    'Plate Type, SBS96, , ',
    ' , , , ',
    'Well Location, Sample Name, Sample Concentration, Sample Type',
    'A01, sample01, 2.333, NTC',
    'B01, sample02, , Unknown'
  ];

  my $file = wtsi_clarity::genotyping::fluidigm_analysis->new(
    sample_plate => 'DN12312313Q',
    barcode      => 123456789,
    samples      => $samples,
  );

  isa_ok($file->_textfile, 'wtsi_clarity::util::textfile', 'Creates a text file');
  is_deeply($file->content, $expected_content, 'Creates the text file correctly');
}

1;