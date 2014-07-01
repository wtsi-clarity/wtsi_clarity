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

use Net::SFTP::Foreign;

use wtsi_clarity::util::config;

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

has 'config'      => (
    isa             => 'wtsi_clarity::util::config',
    is              => 'ro',
    required        => 0,
    lazy_build      => 1,
);
sub _build_config {
  return wtsi_clarity::util::config->new();
}

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

=head2 base_url

Base urls for API calls; if not provided,
will be generated from the first requested URL.

=cut
has 'base_url'      => (isa        => 'Maybe[Str]',
                        is         => 'ro',
                        required   => 0,
                        'writer'   => '_write_base_url',
                       );

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
    if (!$self->base_url) {
        croak q[Base url is needed for authentication];
    }
    my $ua = LWP::UserAgent->new();
    $ua->agent(join q[/], __PACKAGE__, $VERSION);
    $ua->timeout($LWP_TIMEOUT);
    $ua->env_proxy();
    $ua->credentials($self->base_url, $REALM, $self->user, $self->password);
    return $ua;
}

sub _set_base_url {
    my ($self, $url) = @_;
    if (!$url) {
        croak q[URL argument should be provided];
    }
    my ($base_url) = $url =~ /https?:\/\/([^\/]+)\//smx;
    if (!$base_url) {
        croak qq[Cannot get base url from $url];
    }
    if (!$self->base_url) {
        $self->_write_base_url($base_url);
    }
    return;
}

=head2 get

Contacts a web service to perform a GET request.
Optionally saves the content of a requested web resource
to a cache. If a global variable whose name is returned by
$self->cache_dir_var_name is set, for GET requests retrieves the
requested resource from a cache.

=cut
sub get {
    my ($self, $uri) = @_;

    my $cache = $ENV{$self->cache_dir_var_name} ? $ENV{$self->cache_dir_var_name} : q[];
    my $path = q[];
    if ($cache) {
        $self->_check_cache_dir($cache);
        $path = $self->_create_path($uri);
        if (!$path) {
            croak qq[Empty path generated for $uri];
        }
    }

    my $content = ($cache && !$ENV{$self->save2cache_dir_var_name}) ?
                  $self->_from_cache($path, $uri) :
                  $self->_from_web($uri, $path);
    if (!$content) {
        croak qq[Empty document at $uri $path];
    }

    return $content;
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

sub _request {
    my ($self, $type, $uri, $content) = @_;

    if ( !$type || $type !~ /GET|POST|PUT|DELETE/smx) {
        $type = !defined $type ? 'undefined' : $type;
        croak qq[Invalid request type "$type", valid types are POST, PUT, DELETE];
    }
    $self->_set_base_url($uri);

    my $req=HTTP::Request->new($type, $uri,undef, $content);
    $req->header('encoding' =>   'UTF-8');
    $req->header('Accept',       $self->content_type);
    $req->header('Content-Type', $self->content_type);
    $req->header('User-Agent',   $self->useragent->agent());
    my $res=$self->useragent()->request($req);
    if(!$res->is_success()) {
        croak "$type request to $uri failed: " . join q[ ], $res->status_line(), $res->decoded_content;
    }
    return $res->decoded_content;
}


=head2 upload_file

Open an FTP connection and upload a given file.

=cut

sub upload_file {
    my ($self, $server, $remote_directory, $oldfilename, $newfilename) = @_;
    my $sftp=Net::SFTP::Foreign->new($server,
            'user'=>$self->ftpuser,
            'password' => $self->ftppassword,
            ) or croak qq{could not open connection to $server};


    $sftp->put($oldfilename, qq{/$remote_directory/$newfilename} )
      or croak qq{could not upload the file $oldfilename as $remote_directory / $newfilename on the server $server}.$sftp->error;

    return $sftp->disconnect();
}

=head2 del

Contacts a web service to perform a DELETE request.

=cut
sub del {
    my ($self, $uri, $content) = @_;
    return $self->_request('DELETE',$uri);
}

sub _create_path {
    my ( $self, $url ) = @_;
    my @components = split /\//xms, $url;
    my $query  = pop @components;
    my $entity = pop @components;
    my $path;
    if ($query and $entity) {
        $path = catdir($entity, $query);
    }
    if ($path) {
        $path = catfile($ENV{$self->cache_dir_var_name}, $path);
    }
    return $path;
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
    my ($self, $uri, $path) = @_;

    my $content;
    if ($path && $ENV{$self->save2cache_dir_var_name} && $ENV{$self->cache_dir_var_name}) {
        ##no critic (RequireCheckingReturnValueOfEval)
        eval {
          $content = $self->_from_cache($path, $uri);
        };
        ##use critic
        if ($content) {
            return $content;
        }
    }

    $content = $self->_request('GET', $uri);
    if ($ENV{$self->save2cache_dir_var_name}) {
        $self->_write2cache($path, $content);
    }
    return $content;
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
