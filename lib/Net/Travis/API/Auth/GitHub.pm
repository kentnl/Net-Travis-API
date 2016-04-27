use 5.008;    # utf8
use strict;
use warnings;
use utf8;

package Net::Travis::API::Auth::GitHub;

our $VERSION = '0.002000';

# ABSTRACT: Authorize with Travis using a GitHub token

# AUTHORITY

use Moo qw( with );
use Scalar::Util qw(blessed);

with 'Net::Travis::API::Role::Client';

=begin MetaPOD::JSON v1.1.0

{
    "namespace":"Net::Travis::API::Auth::GitHub",
    "inherits":"Moo::Object",
    "does":"Net::Travis::API::Role::Client",
    "interface":"class"
}

=end MetaPOD::JSON

=cut

sub _get_token_for {
  my ( $self, $gh_token ) = @_;
  return $self->http_engine->post_form( '/auth/github', { github_token => $gh_token } );
}

=method C<get_token_for>

Pass a GitHub token and receive a Travis token in exchange, if it is valid.

    my $travis_token = ($class|$instance)->get_token_for(<githubtoken>);

=cut

sub get_token_for {
  my ( $self, $gh_token ) = @_;
  if ( not blessed $self ) {
    $self = $self->new();
  }
  my $result = $self->_get_token_for($gh_token);
  return if not '200' eq $result->status;
  return if not length $result->content;
  return unless my $json = $result->content_json;
  return $json->{access_token};
}

=method C<get_authorised_ua_for>

Authenticate using a GitHub token and return a C<Net::Travis::API::UA> instance for subsequent requests that will execute
requests as authorized by that token.

    if ( my $ua = ($class|$instance)->get_authorized_ua_for( <githubtoken> ) ) {
        pp ( $ua->get('/users')->content_json );
    }

=cut

sub get_authorised_ua_for {
  my ( $self, $gh_token ) = @_;
  $self = $self->new() if not blessed $self;
  my $token = $self->get_token_for($gh_token);
  $self->http_engine->authtokens( [$token] );
  return $self->http_engine;
}

no Moo;

1;

