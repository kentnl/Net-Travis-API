use 5.008;    # utf8
use strict;
use warnings;
use utf8;

package Net::Travis::API::UA::Response;
$Net::Travis::API::UA::Response::VERSION = '0.001000';
# ABSTRACT: Subclass of HTTP::Tiny::UA::Response for utility methods

our $AUTHORITY = 'cpan:KENTNL'; # AUTHORITY













use Moo;




























use Encode qw();

extends 'HTTP::Tiny::UA::Response';





has 'json' => (
    is       => ro =>,
    lazy     =>  1,
    builder  => sub {
        require JSON;
        return JSON->new();
    },
);

sub content_type {
    my ($self) = @_;
    return unless exists $self->headers->{'content-type'};
    return
      unless my ($type) =
      $self->headers->{'content-type'} =~ qr{ \A ( [^/]+ / [^;]+ ) }msx;
    return $type;
}

sub content_type_params {
    my ($self) = @_;
    return [] unless exists $self->headers->{'content-type'};
    return []
      unless my (@params) =
      $self->headers->{'content-type'} =~ qr{ (?:;([^;]+))+ }msx;
    return [@params];
}

sub decoded_content {
    my ( $self, $force_encoding ) = @_;
    if ( not $force_encoding ) {
        return $self->content if not my $type = $self->content_type;
        return $self->content unless $type =~ qr{ \Atext/ }msx;
        for my $param ( @{ $self->content_type_params } ) {
            if ( $param =~ qr{ \Acharset=(.+)\z }msx ) {
                $force_encoding = $param;
            }
        }
        return $self->content if not $force_encoding;
    }
    return Encode::decode( $force_encoding, $self->content, Encode::FB_CROAK );
}

sub content_json {
    my ($self) = @_;
    my %whitelist = ( 'application/json' => 1 );
    return unless exists $whitelist{ $self->content_type };
    my $charset = 'utf-8';
    for my $param ( @{ $self->content_type_params } ) {
        next unless $param =~ /^charset=(.+)$/;
        $charset = $1;
    }
    return $self->json->utf8(0)->decode( $self->decoded_content($charset) );
}

no Moo;

1;

## Please see file perltidy.ERR

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Travis::API::UA::Response - Subclass of HTTP::Tiny::UA::Response for utility methods

=head1 VERSION

version 0.001000

=head1 DESCRIPTION

This class warps extends C<HTTP::Tiny::UA::Response> and adds a few utility methods
and functionalities that either

=over 4

=item 1. Have not yet been approved for merge

=over 2

=item * L<< github-pull:HTTP-Tiny-UA#3|https://github.com/dagolden/HTTP-Tiny-UA/pull/3 >>

=back

=item 2. Don't make sense to propagate to a general purpose HTTP User Agent.

=over 2

=item * L<< C<content_json>|/content_json >>

=back

=back

=head1 ATTRIBUTES

=head2 C<json>

=begin MetaPOD::JSON v1.1.0

{
    "namespace":"Net::Travis::API::UA::Response",
    "interface":"class",
    "inherits":"HTTP::Tiny::UA::Response"
}


=end MetaPOD::JSON

=head1 AUTHOR

Kent Fredric <kentfredric@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Kent Fredric <kentfredric@gmail.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
