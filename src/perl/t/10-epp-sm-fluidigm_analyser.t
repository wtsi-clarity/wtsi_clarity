use strict;
use warnings;
use Test::More tests => 9;
use Test::Exception;
use File::Temp qw/ tempdir /;
use File::Spec::Functions;
use Carp;
use XML::LibXML;
use wtsi_clarity::genotyping::fluidigm::assay_set;

use_ok('wtsi_clarity::epp::sm::fluidigm_analyser', 'can use wtsi_clarity::epp::sm::fluidigm_analyser');
my $test_dir = 't/data/epp/sm/fluidigm_analyser';

sub _write_config {
  my $dir = shift;
  my $file = catfile $dir, 'config';
  open my $fh, '>', $file or croak "Cannot open file $file for writing";
  print $fh "[robot_file_dir]\n";
  print $fh "fluidigm_analysis=$dir\n";
  close $fh or carp "Cannot close file $file";
}

{
  my $epp = wtsi_clarity::epp::sm::fluidigm_analyser->new(process_url => 'http://clarity.co');
  isa_ok($epp, 'wtsi_clarity::epp::sm::fluidigm_analyser');
  can_ok($epp, qw/ run /);
}

# _filename
{
  my $epp = wtsi_clarity::epp::sm::fluidigm_analyser->new(
    process_url => 'http://clartiy-ap/processes/24-16130'
  );

  local $ENV{'WTSI_CLARITY_HOME'} = 't/data/config';
  # local $ENV{'SAVE2WTSICLARITY_WEBCACHE'} = 1;
  local $ENV{'WTSICLARITY_WEBCACHE_DIR'} = $test_dir;

  is($epp->_filename, '5345895674125', 'Gets the barcode of the container i.e. the filename');
}

# _filepath
{
  local $ENV{'WTSICLARITY_WEBCACHE_DIR'} = $test_dir;
  local $ENV{'WTSI_CLARITY_HOME'} = 't/data/config';

  my $epp = wtsi_clarity::epp::sm::fluidigm_analyser->new(
    process_url => 'http://clartiy-ap/processes/24-16130'
  );

  is($epp->_filepath, 't/data/genotyping/fluidigm/5345895674125', 'Successfully gets the right filepath');
}

# _find_artifact_by_sample_name
{
  local $ENV{'WTSICLARITY_WEBCACHE_DIR'} = $test_dir;
  local $ENV{'WTSI_CLARITY_HOME'} = 't/data/config';

  my $output_artifacts = XML::LibXML->load_xml(location => $test_dir . '/POST/artifacts.batch_5a42bc650e09d68d04a25a5a22022c58');

  my $epp = wtsi_clarity::epp::sm::fluidigm_analyser->new(
    process_url => 'http://clartiy-ap/processes/24-16927',
    _output_artifacts => $output_artifacts,
  );

  my $artifact = $epp->_find_artifact_by_sample_name('SMI102A96');
  is($artifact->findvalue('@limsid'), '2-40656', 'Finds the correct artifact in the batch');

  throws_ok { $epp->_find_artifact_by_sample_name('fake') } qr/Found 0 artifacts for sample fake/,
    'Throws if sample can not be found in batch';
}

# _update_artifact
{
  local $ENV{'WTSICLARITY_WEBCACHE_DIR'} = $test_dir;
  local $ENV{'WTSI_CLARITY_HOME'} = 't/data/config';

  my $output_artifacts = XML::LibXML->load_xml(location => $test_dir . '/POST/artifacts.batch_5a42bc650e09d68d04a25a5a22022c58');
  my $artifact = $output_artifacts->findnodes('/art:details/art:artifact[@limsid="2-40655"]')->pop;

  my $assay_set = wtsi_clarity::genotyping::fluidigm::assay_set->new(
    file_content => [[
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
                   ]
  );

  my $epp = wtsi_clarity::epp::sm::fluidigm_analyser->new(
    process_url => 'http://clartiy-ap/processes/24-16927',
    _output_artifacts => $output_artifacts,
  );

  my $updated_artifact = $epp->_update_artifact($artifact, $assay_set);

  is($updated_artifact->findvalue('udf:field[@name="WTSI Fluidigm Call Rate (SM)"]'), '3/3', 'Adds the call rate to the artifact');
  is($updated_artifact->findvalue('udf:field[@name="WTSI Fluidigm Gender (SM)"]'), 'M', 'Adds the gender to the artifact');
}