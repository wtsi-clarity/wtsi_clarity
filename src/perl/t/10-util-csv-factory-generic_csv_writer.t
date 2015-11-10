use strict;
use warnings;
use Test::More tests => 4;
use Test::Exception;
use Test::Warn;
use Carp;
use Data::Dumper;
use Readonly;
use Text::CSV;

use_ok('wtsi_clarity::util::csv::factories::generic_csv_writer', 'can use csv::factories');

{
  my $csv_writer = wtsi_clarity::util::csv::factories::generic_csv_writer->new();

  my $headers = ['a', 'b', 'c',];
  my $some_content = [
    {
      'a' => '1',
      'b' => '2',
      'c' => '4',
    },
    {
      'a' => '1',
      'c' => '2',
      'b' => '4',
    },
  ];
  my $expected_result = [
    'a,b,c',
    '1,2,4',
    '1,4,2',
  ];
  my $file = $csv_writer->build(headers => $headers, data => $some_content);
  is_deeply($file->content, $expected_result, 'build returns a file object with the correct content');
}

{
  my $csv_writer = wtsi_clarity::util::csv::factories::generic_csv_writer->new();

  throws_ok{$csv_writer->build()} qr/Requires headers!/, "Requires headers.";
  throws_ok{$csv_writer->build(("headers" => "header"))} qr/Requires some data to write down!/, "Requires data.";

}

1;
