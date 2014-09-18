package wtsi_clarity::util::display_message_role;

use Moose::Role;
use Carp;
use Readonly;
use XML::LibXML;

our $VERSION = '0.0';

Readonly::Scalar my $DEBUG    => q{DEBUG};
Readonly::Scalar my $INFO     => q{INFO};
Readonly::Scalar my $WARNING  => q{WARNING};
Readonly::Scalar my $ERROR    => q{ERROR};

sub display_debug {
  my ($self, $msg) = @_;
  $self->_display_message($DEBUG, $msg);

  return;
}

sub display_info {
  my ($self, $msg) = @_;
  $self->_display_message($INFO, $msg);

  return;
}

sub display_warning {
  my ($self, $msg) = @_;
  $self->_display_message($WARNING, $msg);

  return;
}

sub display_error {
  my ($self, $msg) = @_;
  $self->_display_message($ERROR, $msg);

  return;
}

sub _display_message {
  my ($self, $level, $msg) = @_;
  $self->request->put($self->_step_url . '/programstatus', $self->_program_status_doc($level, $msg));
  if ($level eq $ERROR) {
    croak $msg;
  }
}

sub _step_url {
  my $self = shift;
  my $step_url;

  if ($self->can('step_url')) {
    $step_url = $self->step_url;
  } else {
    $step_url = $self->process_url;
    $step_url =~ s/processes/steps/ismg;
  }

  return $step_url;
}

sub _program_status_doc {
  my ($self, $level, $msg) = @_;
  my $xml_doc = XML::LibXML::Document->createDocument();

  # create the root element
  my $root_element = XML::LibXML::Element->new('program-status');
  $root_element->setNamespace('http://genologics.com/ri/step', 'stp');
  $root_element->setAttribute('uri', $self->_step_url);
  $xml_doc->setDocumentElement($root_element);

  # create status element
  my $status_element = XML::LibXML::Element->new('status');
  $status_element->appendText($level);
  $root_element->addChild($status_element);

  # create message element
  my $message_element = XML::LibXML::Element->new('message');
  $message_element->appendText($msg);
  $root_element->addChild($message_element);

  return $xml_doc->toString;
}

1;

__END__

=head1 NAME

wtsi_clarity::util::display_message_role

=head1 SYNOPSIS

  with 'wtsi_clarity::util::display_message_role';

=head1 DESCRIPTION

  Utility role for displaying a message at the program status window.

=head1 SUBROUTINES/METHODS

=head2 display_debug

Displays a debug message on the screens at the program status window.

=head2 display_info

Displays an information message on the screens at the program status window.

=head2 display_warning

Displays a warning message on the screens at the program status window.

=head2 display_error

Displays an error message on the screens at the program status window.

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=over

=item Moose

=back

=head1 AUTHOR

Karoly Erdos E<lt>ke4@sanger.ac.ukE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2014 Genome Research Ltd.

This file is part of wtsi_clarity project.

wtsi_clarity is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.

=cut
