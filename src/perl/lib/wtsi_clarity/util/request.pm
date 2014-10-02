package wtsi_clarity::util::request;

use Moose;
use Carp;
use English qw( -no_match_vars );
use MooseX::StrictConstructor;
use MooseX::ClassAttribute;
use LWP::UserAgent;
use HTTP::Request;
use File::Basename;
use File::Path;
use File::Spec::Functions;
use Readonly;
use XML::LibXML;

use Net::SFTP::Foreign;
use Digest::MD5;

with 'wtsi_clarity::util::configurable';
with 'wtsi_clarity::util::batch';
with 'wtsi_clarity::util::clarity_query';

our $VERSION = '0.0';

Readonly::Scalar my $REALM => q[GLSSecurity];

=head1 NAME

wtsi_clarity::util::request

=head1 SYNOPSIS

=head1 DESCRIPTION

Performs requests to Clarity API.
Retrieves requested contents either from a specified URI or from a cache.
When retrieving the contents from URI can, optionally, save the resource
to cache.

The location of the cache is stored in an environment variable

=head1 SUBROUTINES/METHODS

=cut

Readonly::Scalar our $DEFAULT_VAR_NAME => q[WTSICLARITY_WEBCACHE_DIR];
Readonly::Scalar our $SAVE2CACHE_VAR_NAME => q[SAVE2WTSICLARITY_WEBCACHE];

Readonly::Scalar our $LWP_TIMEOUT => 60;
Readonly::Scalar our $DEFAULT_METHOD => q[GET];
Readonly::Scalar our $DEFAULT_CONTENT_TYPE => q[application/xml];

Readonly::Scalar my $EXCEPTION_MESSAGE_PATH => q[exc:exception/message];

=head2 cache_dir_var_name

Name of the environmental variable that defines the location
of the cache. Class attribute.

=cut
class_has 'cache_dir_var_name'=> (isa      => 'Str',
                                  is       => 'ro',
                                  required => 0,
                                  default  => $DEFAULT_VAR_NAME,
                                 );

=head2 save2cache_dir_var_name

Name of the environmental variable that defines whether
the retrieved files have to be saved to cache. Class attribute.

=cut
class_has 'save2cache_dir_var_name'=> (isa      => 'Str',
                                       is       => 'ro',
                                       required => 0,
                                       default  => $SAVE2CACHE_VAR_NAME,
                                      );

=head2 content_type

Content type to accept

=cut
has 'content_type'=> (isa      => 'Str',
                      is       => 'ro',
                      required => 0,
                      default  => $DEFAULT_CONTENT_TYPE,
                     );

=head2 user

Username of a user authorised to use API;
if not given will be read from the configuration file.

=cut
has 'user'      => (isa        => 'Str',
                    is         => 'ro',
                    required   => 0,
                    lazy_build => 1,
                   );
sub _build_user {
    my $self = shift;
    my $user = $self->config->clarity_api->{'username'} ||
        croak q[Cannot retrieve username from the configuration file];
    return $user;
}

=head2 ftpuser

Username of a user authorised to use FTP;
if not given will be read from the configuration file.

=cut

has 'ftpuser'      => (isa        => 'Str',
                    is         => 'ro',
                    required   => 0,
                    lazy_build => 1,
                   );
sub _build_ftpuser {
    my $self = shift;
    my $user = $self->config->ftp_user->{'username'} ||
        croak q[Cannot retrieve ftp username from the configuration file];
    return $user;
}

=head2 password

Password of a user authorised to use API;
if not given will be read from the configuration file.

=cut
has 'password'      => (isa        => 'Str',
                        is         => 'ro',
                        required   => 0,
                        lazy_build => 1,
                       );
sub _build_password {
    my $self = shift;
    my $p = $self->config->clarity_api->{'password'} ||
        croak q[Cannot retrieve password from the configuration file];
    return $p;
}


=head2 ftppassword

Password of a user authorised to use FTP;
if not given will be read from the configuration file.

=cut

has 'ftppassword'      => (isa        => 'Str',
                        is         => 'ro',
                        required   => 0,
                        lazy_build => 1,
                       );
sub _build_ftppassword {
    my $self = shift;
    my $p = $self->config->ftp_user->{'password'} ||
        croak q[Cannot retrieve ftp password from the configuration file];
    return $p;
}

=head2 useragent

Useragent for making an HTTP request.

=cut
has 'useragent' => (isa        => 'Object',
                    is         => 'ro',
                    required   => 0,
                    lazy_build => 1,
                   );
sub _build_useragent {
    my $self = shift;
    if (!$self->config->clarity_api->{'base_uri'}) {
        croak q[Base uri is needed for authentication];
    }
    my $ua = LWP::UserAgent->new();
    $ua->agent(join q[/], __PACKAGE__, $VERSION);
    $ua->timeout($LWP_TIMEOUT);
    $ua->env_proxy();
    if (!$self->ss_request) {
        # the credential requires the network location to follow the HOST:PORT format.
        # we use the base_uri to find this value
        my $host_port = $self->config->clarity_api->{'base_uri'};
        if ( $host_port =~ /http:/xms ) {
            ##no critic (RegularExpressions::ProhibitEscapedMetacharacters)
            ($host_port) = ( $host_port =~ m/http:\/\/([\w\d:\-\.]+).*/xms );
            ##use critic
        }
        $ua->credentials( $host_port, $REALM, $self->user, $self->password);
    }
    return $ua;
}

has 'additional_headers'=> (  isa      => 'HashRef',
                              is       => 'ro',
                              required => 0,
                           );

has 'ss_request'=> (  isa       => 'Bool',
                      is        => 'ro',
                      required  => 0,
                   );

=head2 get

Contacts a web service to perform a GET request.
Optionally saves the content of a requested web resource
to a cache. If a global variable whose name is returned by
$self->cache_dir_var_name is set, for GET requests retrieves the
requested resource from a cache.

=cut
sub get {
    my ($self, $uri) = @_;

    return $self->_request('GET', $uri);
}

=head2 post

Contacts a web service to perform a POST request.

=cut
sub post {
    my ($self, $uri, $content) = @_;
    return $self->_request('POST',$uri, $content);
}

=head2 put

Contacts a web service to perform a PUT request.

=cut
sub put {
    my ($self, $uri, $content) = @_;
    return $self->_request('PUT',$uri, $content);
}

=head2 del

Contacts a web service to perform a DELETE request.

=cut
sub del {
    my ($self, $uri, $content) = @_;
    return $self->_request('DELETE', $uri);
}

sub _request {
    my ($self, $type, $uri, $content) = @_;

    if ( !$type || $type !~ /GET|POST|PUT|DELETE/smx) {
        $type = !defined $type ? 'undefined' : $type;
        croak qq[Invalid request type "$type", valid types are GET, POST, PUT, DELETE];
    }

    my $cache = $ENV{$self->cache_dir_var_name} ? $ENV{$self->cache_dir_var_name} : q[];
    my $path = q[];

    if ($cache) {
        $self->_check_cache_dir($cache);
        $path = $self->_create_path($uri, $type, $content);
        if (!$path) {
            croak qq[Empty path generated for $uri];
        }
    }

    my $response = ($cache && !$ENV{$self->save2cache_dir_var_name}) ?
                  $self->_from_cache($path, $uri) :
                  $self->_from_web($type, $uri, $content, $path);

    if (!$response) {
        croak qq[Empty document at $uri $path];
    }

    if ($ENV{$self->save2cache_dir_var_name}) {
      $self->_write2cache($path, $response);
    }

    return $response;
}

=head2 upload_file

Open an FTP connection and upload a given file.

=cut

sub upload_file {
    my ($self, $server, $remote_directory, $oldfilename, $newfilename) = @_;
    my $sftp=Net::SFTP::Foreign->new($server,
            'user'=>$self->ftpuser,
            'password' => $self->ftppassword,
            ) or croak qq{could not open connection to $server. };
    $sftp->mkdir(qq{/$remote_directory}); # we let this call fail silently, as it *should* indicate that the folder already exists.
    $sftp->put($oldfilename, qq{/$remote_directory/$newfilename} )
      or croak qq{could not upload the file $oldfilename as $remote_directory / $newfilename on the server $server.\n}.$sftp->error;

    return $sftp->disconnect();
}

=head2 download_file

Open an FTP connection and download a given file.

=cut

sub download_file {
    my ($self, $server, $remote_path, $local_path) = @_;

    my $sftp=Net::SFTP::Foreign->new($server,
            'user'=>$self->ftpuser,
            'password' => $self->ftppassword,
            ) or croak qq{could not open connection to $server};

    $sftp->get($remote_path, $local_path)
        or croak qq ( Failed to fetch the file at $remote_path);

    return $sftp->disconnect();
}

sub _create_path {
    my ( $self, $url, $type, $content ) = @_;

    my $base_uri = $self->config->clarity_api->{'base_uri'}.q{/};

    my $path;
    my @components;
    my $first_element;
    my $second_element;

    my $short_url = $url;
    if ($url =~ /$base_uri/xms) {
        # if we match the clarity-uri, then we know the format
        $short_url =~ s/$base_uri//xms;
        @components     = split /\//xms, $short_url;
        $first_element  = shift @components;
        $second_element = shift @components;
    } else {
        @components     = split /\//xms, $url;
        $second_element = pop @components;
        $first_element  = pop @components;
        $path = $type;
    }

    if($content) {
        $second_element .= _decorate_resource_name($content);
    }

    if ($second_element and $first_element) {
        # matching  BASE_URI/resourcename/query
        $path = catdir($type, $first_element, $second_element);
    } elsif ($first_element) {
        # matching  BASE_URI/query
        $path = catdir($type, $first_element);
    }

    if ($path) {
        $path = catfile($ENV{$self->cache_dir_var_name} || q{}, $path);
    } else {
        if (!$content) { $content = q/(No payload)/; }
        croak qq{Wrong URL format for caching.\n    $type\n    $url  (in short : $short_url )\n    with "$content"\n    Is it matching the base url correct ? ($base_uri)\n   }
    }

    return $path;
}

sub _decorate_resource_name {
    my ($content) = @_;
    return q/_/ . Digest::MD5::md5_hex($content);
}

sub _check_cache_dir {
    my ($self, $cache) = @_;

    if (!-e $cache) {
       croak qq[Cache directory $cache does not exist];
    }
    if (!-d $cache) {
       croak qq[$cache (a proposed cache directory) is not a directory];
    }
    if ($ENV{$self->save2cache_dir_var_name}) {
        if (!-w $cache) {
            croak qq[Cache directory $cache is not writable];
        }
    } else {
        if (!-r $cache) {
            croak qq[Cache directory $cache is not readable];
        }
    }
    return 1;
}

sub _from_cache {
    my ($self, $path, $uri) = @_;

    if (!-e $path) {
        croak qq[$path for $uri is not in the cache];
    }

    local $RS = undef;
    open my $fh, q[<], $path or croak qq[Error when opening $path for reading: $ERRNO];
    if (!defined $fh) { croak qq[Undefined filehandle returned for $path]; }
    my $content = defined $fh ? <$fh> : croak qq[Failed to read from an open $path: $ERRNO];
    close $fh or croak qq[Failed to close a filehandle for $path: $ERRNO];

    return $content;
}

sub _from_web {
    my ($self, $type, $uri, $content, $path) = @_;
    if ($path && $ENV{$self->save2cache_dir_var_name} && $ENV{$self->cache_dir_var_name}) {
        my $result;
        ##no critic (RequireCheckingReturnValueOfEval)
        eval {
          $result = $self->_from_cache($path, $uri);
        };
        ##use critic
        if ($result) {
            return $result;
        }
    }
    my $req=HTTP::Request->new($type, $uri,undef, $content);
    $req->header('encoding' =>   'UTF-8');
    $req->header('Accept',       $self->content_type);
    $req->header('Content-Type', $self->content_type);
    $req->header('User-Agent',   $self->useragent->agent());

    # if additional headers exits, then adds them too
    if ($self->additional_headers) {
        for my $header_key ( keys %{$self->additional_headers} ) {
            $req->header($header_key, $self->additional_headers->{$header_key});
        }
    }
    my $res=$self->useragent()->request($req);

    # workaround a bug in SS (getting back a 301 response with the correct response body)
    if (($self->ss_request && (!defined $res->decoded_content || !$res->is_success() && !$res->is_redirect))
        || (!$self->ss_request && !$res->is_success())) {
      croak "$type request to $uri failed: " . join q[ ], $res->status_line(), $self->_error_message($res->decoded_content);
    }

    return $res->decoded_content;
}

sub _error_message {
    my ($self, $decoded_content) = @_;
    my $error_msg;

    eval {
        my $xml_msg = XML::LibXML->new()->load_xml(string => $decoded_content);
        $error_msg = $xml_msg->findnodes($EXCEPTION_MESSAGE_PATH)->pop()->textContent;
        1;
    } or do {
        $error_msg = $decoded_content;
    };

    return $error_msg;
}

sub _write2cache {
    my ($self, $path, $content) = @_;

    my ($name,$dir,$suffix) = fileparse($path);
    if (-e $dir) {
        if (!-d $dir) {
            croak qq[$dir should be a directory];
        }
    } else {
        File::Path::make_path($dir);
    }

    open my $fh, q[>:encoding(UTF-8)], $path or croak qq[Error when opening $path for writing: $ERRNO];
    $fh or croak qq[Undefined filehandle returned for $path];
    print {$fh} $content or croak qq[Failed to write to open $path: $ERRNO];
    close $fh or croak qq[Failed to close a filehandle for $path: $ERRNO];
    return;
}

1;

__END__

=head1 DIAGNOSTICS

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=over

=item Moose

=item MooseX::StrictConstructor

=item Readonly

=item Carp

=item English

=item LWP::UserAgent

=item File::Basename

=item File::Path

=item File::Spec::Functions

=back

=head1 INCOMPATIBILITIES

=head1 BUGS AND LIMITATIONS

=head1 AUTHOR

Marina Gourtovaia

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2014 GRL, by Marina Gourtovaia

This file is part of wtsi_clarity project.

wtsi_clarity is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program. If not, see <http://www.gnu.org/licenses/>.

=cut
