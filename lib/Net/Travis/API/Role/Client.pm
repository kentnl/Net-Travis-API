use 5.008;    # utf8
use strict;
use warnings;
use utf8;

package Net::Travis::API::Role::Client;
$Net::Travis::API::Role::Client::VERSION = '0.001001';
# ABSTRACT: Anything that fetches from Travis and returns JSON data

our $AUTHORITY = 'cpan:KENTNL'; # AUTHORITY












use Moo::Role qw( has );







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

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Travis::API::Role::Client - Anything that fetches from Travis and returns JSON data

=head1 VERSION

version 0.001001

=head1 ATTRIBUTES

=head2 C<http_engine>

A L<< C<Net::Travis::API::UA>|Net::Travis::API::UA >> instance for performing requests with.

=begin MetaPOD::JSON v1.1.0

{
    "namespace":"Net::Travis::API::Role::Client",
    "interface":"role"
}


=end MetaPOD::JSON

=head1 AUTHOR

Kent Fredric <kentfredric@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Kent Fredric <kentfredric@gmail.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
