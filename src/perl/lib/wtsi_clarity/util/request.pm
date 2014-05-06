package wtsi_clarity::util::request;

use Moose;
use Carp;
use English qw( -no_match_vars );
use Moose::Util::TypeConstraints;
use MooseX::StrictConstructor;
use MooseX::ClassAttribute;
use LWP::UserAgent;
use HTTP::Request::Common;
use File::Basename;
use File::Path;
use File::Spec::Functions;
use Readonly;

use wtsi_clarity::util::config;

our $VERSION = '0.0';

Readonly::Scalar my $REALM => q[GLSSecurity];

## no critic (RequirePodAtEnd RequireCheckingReturnValueOfEval)

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

Readonly::Scalar our $MAX_RETRIES => 3;
Readonly::Scalar our $RETRY_DELAY => 10;
Readonly::Scalar our $LWP_TIMEOUT => 60;
Readonly::Scalar our $DEFAULT_METHOD => q[GET];
Readonly::Scalar our $DEFAULT_CONTENT_TYPE => q[text/xml];

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

=head2 max_retries

Maximum number of attempts to retrieve a requested resource.

=cut
has 'max_retries'=> (isa      => 'Num',
                     is       => 'ro',
                     required => 0,
                     default  => $MAX_RETRIES,
                    );

=head2 retry_delay

A delay (in seconds) between attempts.

=cut
has 'retry_delay'=> (isa      => 'Num',
                     is       => 'ro',
                     required => 0,
                     default  => $RETRY_DELAY,
                    );

=head2 content_type

Content type to accept

=cut
has 'content_type'=> (isa      => 'Maybe[Str]',
                      is       => 'ro',
                      required => 0,
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

=head2 base_url

Base urls for API calls; if not provided,
will be generated from the first requested URL.

=cut
has 'base_url'      => (isa        => 'Maybe[Str]',
                        is         => 'ro',
                        required   => 0,
                        'writer'   => '_set_base_url',
                       );
sub _get_base_url {
    my $url = shift;
    if ($url) {
        croak q[URL argument should be provided];
    }
    my ($base_url) = $url =~ /https?:\/\/([^\/]+)\//smx;
    if (!$base_url) {
        croak qq[Cannot get base url from $url];
    }
    carp qq[Base url $base_url];
    return $base_url;
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

=head2 make

Contacts a web service to perform a requested operation.
For GET requests optionally saves the content of a requested web resource
to a cache. If a global variable whose name is returned by
$self->cache_dir_var_name is set, for GET requests retrieves the
requested resource from a cache.

=cut
sub make {
    my ($self, $uri, $method, $args) = @_;

    if (!$uri) {
        croak q[Uri is not defined];
    }
    if ($self->base_url) {
        $self->_set_base_url(_get_base_url($uri));
    }

    if (!$method) {
        $method = $DEFAULT_METHOD;
    }

    my $cache = $ENV{$self->cache_dir_var_name} ? $ENV{$self->cache_dir_var_name} : q[];

    my $content;

    if ($method ne $DEFAULT_METHOD) {
        if ($cache) {
            croak qq[$method requests cannot use cache: $uri];
        }
        $content = $self->_from_web($uri, $method, $args);
    } else {
        my $path = q[];
        if ($cache) {
            $self->_check_cache_dir($cache);
            $path = $self->_create_path($uri);
            if (!$path) {
                croak qq[Empty path generated for $uri];
            }
        }

        $content = ($cache && !$ENV{$self->save2cache_dir_var_name}) ?
                  $self->_from_cache($path, $uri) :
                  $self->_from_web($uri, $method, $args, $path);
        if (!$content) {
            croak qq[Empty document at $uri $path];
        }
    }

    return $content;
}

sub _create_path {
    my ( $self, $url ) = @_;
    my @components = split /\//xms;
    my $query  = pop @components;
    my $entity = pop @components;
    my $path;
    if ($query and $entity) {
        $path = catdir($query, $entity);
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

    $path .= $self->_extension($self->content_type);
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
    my ($self, $uri, $method, $args, $path) = @_;

    if ($path && $ENV{$self->save2cache_dir_var_name} && $ENV{$self->cache_dir_var_name}) {
        my $content;
        eval {
          $content = $self->_from_cache($path, $uri);
        };
        if ($content) {
            return $content;
        }
    }

    my $req;
    if ($method eq $DEFAULT_METHOD) {
        $req = GET $uri, @{$args || []};
    } else {
        $req = POST $uri, @{$args || []};
    }
    if ($self->content_type) {
        $req->header('Accept' => $self->content_type);
    }

    my $response = $self->_retry(sub {
             my $inner_response = $self->useragent()->request($req);
             if(!$inner_response->is_success()) {
                 croak $inner_response->status_line();
             }
             return $inner_response;
                                 }, $uri);

    if(!$response->is_success()) {
        croak qq[Web request to $uri failed: ] . $response->status_line();
    }

    my $content = $response->content();
    if($content =~ /<h\d>An[ ]Error[ ]Occurred/smix) {
        my ($errstr) = $content =~ m{<p>(Error.*?)</p>}smix;
        croak $errstr;
    }

    if (defined $self->content_type && $self->content_type eq $DEFAULT_CONTENT_TYPE && $content =~ /<!DOCTYPE[ ]html/xms) {
        carp 'there has been a problem - the xml is formated with an HTML doctype';
        $content =~ s/<!DOCTYPE[ ]html.*//xms;
    }

    if ($ENV{$self->save2cache_dir_var_name}) {
        my $content_type = $response->headers->header('Content-Type');
        if (!$content_type) {
            $content_type = $self->content_type;
        }
        $self->_write2cache($path, $content, $content_type);
    }

    return $content;
}

sub _write2cache {
    my ($self, $path, $content, $content_type) = @_;

    $path .= $self->_extension($content_type);

    my ($name,$dir,$suffix) = fileparse($path);
    if (-e $dir) {
        if (!-d $dir) {
            croak qq[$dir should be a directory];
        }
    } else {
        File::Path::make_path($dir);
    }

    open my $fh, q[>], $path or croak qq[Error when opening $path for writing: $ERRNO];
    $fh or croak qq[Undefined filehandle returned for $path];
    print {$fh} $content or croak qq[Failed to write to open $path: $ERRNO];
    close $fh or croak qq[Failed to close a filehandle for $path: $ERRNO];
    return;
}

sub _retry {
    my ($self, $cb, $uri) = @_;

    my $retry = 0;
    my $result;
    my $error;

    while($retry < $self->max_retries) {
        $retry++;
        eval {
            $error = q[];
            $result = $cb->();
        } or do {
            $error = $EVAL_ERROR;
        };

        if($result) {
            last;
        }

        if($retry == $self->max_retries) {
            croak q[Failed ] . $self->max_retries .
              qq[ attempts to request $uri. Giving up. Last error: $error];
        }

        sleep $self->retry_delay;
    }

    return $result;
}

sub _extension {
    my ($self, $content_type) = @_;

    my $extension = q[];
    if ($content_type) {
        my @types = split /;/smx, $content_type;
        @types = split /\//smx, $types[0];
        $extension = q[.] . $types[-1];
    }
    return $extension;
}

1;

__END__

=head1 DIAGNOSTICS

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=over

=item Moose

=item Moose::Util::TypeConstraints

=item MooseX::StrictConstructor

=item Readonly

=item Carp

=item English

=item LWP::UserAgent

=item HTTP::Request::Common

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
