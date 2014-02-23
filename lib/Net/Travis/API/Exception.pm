use 5.008;    # utf8
use strict;
use warnings;
use utf8;

package Net::Travis::API::Exception;
$Net::Travis::API::Exception::VERSION = '0.001001';
# ABSTRACT: Exception Base Class for TravisAPI

our $AUTHORITY = 'cpan:KENTNL'; # AUTHORITY

our @CARP_NOT = qw/Net::Travis::API::Exception/;

use Carp qw();
use Data::Dump qw(pp);
use overload ( q{""} => sub { $_[0]->exception_message }, fallback => 1 );
use Sub::Exporter::Progressive -setup => { exports => ['fatal'], };

sub id        { $_[0]->{id} }
sub message   { $_[0]->{message} }
sub trace     { $_[0]->{trace} }
sub fulltrace { $_[0]->{fulltrace} }
sub meta      { $_[0]->{meta} }
sub tags      { @{ $_[0]->{tags} } }

sub exception_line {
  my ($self) = @_;
  return $self->{exception_line} if $self->{exception_line};
  return ( $self->{exception_line} = sprintf qq[%s (id=%s;tags=%s)], $self->message, $self->id, ( join q[,], $self->tags ) );
}

sub exception_message {
  my ($self) = @_;
  return $self->{exception_message} if $self->{exception_message};

  $self->{exception_message} = '[ Exception : ' . $self->exception_line . ' ' . $self->trace . ']' . qq[\n];
  if ( $self->{meta} ) {
    $self->{exception_message} .= pp( $self->{meta} ) . qq[\n];
  }
  return $self->{exception_message};
}

sub CARP_TRACE {
  return $_[0]->exception_line;
}

# If you're reading this file because you grepped for the message
# grep for the id instead.
#
our $ex = {
  'arg_count_minimum'     => [ 'Method requires at least N arguments',        [ 'api',  'method' ] ],
  'arg_count_maximum'     => [ 'Method requires at most N arguments',         [ 'api',  'method' ] ],
  'arg_wrong_type'        => [ 'Method requires argument of a specific type', [ 'api',  'method' ] ],
  'arg_length_nonzero'    => [ 'Method requires argument with length >= 1',   [ 'api',  'method' ] ],
  'content_json_expected' => [ 'JSON Content Type was expected',              [ 'http', 'content', 'type' ] ],
  'http_failure'        => [ 'Got non-200 response performing request', ['http'] ],
  'http_no_content'     => [ 'Response returned zero-length content',   [ 'http', 'content' ] ],
  'json_field_expected' => [ 'JSON Did not contain an expected field',  [ 'content', 'json' ] ],
};

sub fatal {
  my ( $id, $meta ) = @_;
  my ( $message, $tags );
  if ( exists $ex->{ $id || '' } ) {
    return __PACKAGE__->throw( $id, @{ $ex->{ $id || '' } }, $meta );
  }
  return __PACKAGE__->throw( $id, undef, undef, $meta );
}

sub throw {
  my ( $class, $id, $message, $tags, $meta ) = @_;

  my $proto = {};
  $proto->{id}      = defined $id      ? $id      : "unknown";
  $proto->{message} = defined $message ? $message : "Unspecified Exception";
  if ( not defined $tags ) {
    $proto->{tags} = [];
  }
  elsif ( not ref $tags ) {
    $proto->{tags} = [$tags];
  }
  else {
    $proto->{tags} = $tags;
  }
  if ( defined $meta ) {
    $proto->{meta} = $meta;
  }
  local $Carp::CarpInternal{'Net::Travis::API::Exception'} = 1;
  chomp( my $trace     = Carp::shortmess );
  chomp( my $fulltrace = Carp::longmess );
  $proto->{trace}     = $trace;
  $proto->{fulltrace} = $fulltrace;

  die bless $proto, $class;

}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Travis::API::Exception - Exception Base Class for TravisAPI

=head1 VERSION

version 0.001001

=head1 AUTHOR

Kent Fredric <kentfredric@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Kent Fredric <kentfredric@gmail.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
