use 5.006;    # our
use strict;
use warnings;

package Net::Travis::API::Role::Client;

our $VERSION = '0.002000';

# ABSTRACT: Anything that fetches from Travis and returns JSON data

# AUTHORITY

=begin MetaPOD::JSON v1.1.0

{
    "namespace":"Net::Travis::API::Role::Client",
    "interface":"role"
}

=end MetaPOD::JSON

=cut

use Moo::Role qw( has );

=attr C<http_engine>

A L<< C<Net::Travis::API::UA>|Net::Travis::API::UA >> instance for performing requests with.

=cut

has 'http_engine' => (
  is      => ro =>,
  lazy    => 1,
  builder => sub {
    require Net::Travis::API::UA;
    return Net::Travis::API::UA->new();
  },
);

no Moo::Role;

1;

