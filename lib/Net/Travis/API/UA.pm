use 5.010;    # mro
use strict;
use warnings;
use utf8;

package Net::Travis::API::UA;
$Net::Travis::API::UA::VERSION = '0.001001';
# ABSTRACT: Travis Specific User Agent that handles authorization

our $AUTHORITY = 'cpan:KENTNL'; # AUTHORITY













use Moo qw( extends has );
use Net::Travis::API::Exception qw( fatal );
use mro;
extends 'HTTP::Tiny';






































use Carp qw(croak);

sub _package_version {
  my $vfield = join q[::], __PACKAGE__, q[VERSION];
  ## no critic (BuiltinFunctions::ProhibitStringyEval,Lax::ProhibitStringyEval::ExceptForRequire)
  if ( eval "defined \$$vfield" ) {
    ## no critic(ErrorHandling::RequireCheckingReturnValueOfEval)
    return eval "\$$vfield";
  }
  return;
}

sub _ua_version {
  my ( $self, ) = @_;
  return 0 if not defined $self->_package_version;
  return $self->_package_version;
}
sub _ua_name { return __PACKAGE__ }

sub _ua_flags {
  my ( $self, ) = @_;
  my $flags = ['cpan'];
  push @{$flags}, 'dev' if not defined $self->_package_version;
  return $flags;
}

sub _agent {
  my ($self) = @_;
  my $own_ua = sprintf '%s/%s (%s)', $self->_ua_name, $self->_ua_version, ( join q{; }, @{ $self->_ua_flags } );
  my @agent_strings = ($own_ua);
  for my $class ( @{ mro::get_linear_isa(__PACKAGE__) } ) {
    next unless $class->can('_agent');
    next if $class eq __PACKAGE__;
    push @agent_strings, $class->_agent();
  }
  return join q[ ], @agent_strings;
}











has 'http_prefix' => (
  is      => ro  =>,
  lazy    => 1,
  builder => sub { return 'https://api.travis-ci.org' },
);















has 'authtokens' => (
  is        => rw =>,
  predicate => 'has_authtokens',
);









has 'json' => (
  is      => ro =>,
  lazy    => 1,
  builder => sub {
    require JSON;
    return JSON->new();
  },
);

sub _add_auth_tokens {
  my ( $self, $options ) = @_;
  $options = {} if not defined $options;
  if ( exists $options->{travis_no_auth} ) {
    delete $options->{travis_no_auth};
    return $options;
  }
  return $options unless $self->has_authtokens;
  return $options if exists $options->{headers} and exists $options->{headers}->{Authorization};
  $options->{headers}->{Authorization} = [ map { 'token ' . $_ } @{ $self->authtokens || [] } ];
  return $options;
}

sub _expand_uri {
  my ( $self, $uri ) = @_;
  require URI;
  return URI->new_abs( $uri, $self->http_prefix );
}

sub FOREIGNBUILDARGS {
  my ( undef, @elems ) = @_;
  my $hash;
  if ( 1 == @elems and ref $elems[0] ) {
    $hash = $elems[0];
  }
  elsif ( @elems % 2 == 0 ) {
    $hash = {@elems};
  }
  else {
    croak q[Uneven number of parameters or non-ref passed];
  }
  my %not = map { $_ => 1 } qw( http_prefix authtokens );
  my %out;
  for my $key ( keys %{$hash} ) {
    next if $not{$key};
    $out{$key} = $hash->{$key};
  }
  return %out;
}










sub request {
  my ( $self, $method, $uri, $opts ) = @_;
  my $result = $self->SUPER::request( $method, $self->_expand_uri($uri), $self->_add_auth_tokens($opts) );
  require Net::Travis::API::UA::Response;
  my $r = Net::Travis::API::UA::Response->new(
    json => $self->json,
    %{$result},
  );
  if ( $r->status != 200 ) {
    fatal(
      'http_failure' => {
        request => {
          method   => $method,
          uri      => $uri,
          real_uri => $self->_expand_uri($uri),
          options  => $opts,
        },
        response => $r
      }
    );
  }
  return $r;
}

sub request_json {
  my ( $self, $method, $uri, $opts ) = @_;
  my $response = $self->request( $method, $uri, $opts );
  if ( not length $response->content ) {
    fatal(
      http_no_content => {
        response => $response,
        request  => {
          method => $method,
          uri    => $uri,
          opts   => $opts
        }
      }
    );
  }
  my $json = $response->content_json;
  if ( not defined $json ) {
    fatal(
      content_json_expected => {
        response => $response,
        request  => {
          method => $method,
          uri    => $uri,
          opts   => $opts
        }
      }
    );
  }
  return $json;
}

for my $sub_name (qw/get head put post delete/) {
  my $req_method = uc $sub_name;
  no strict 'refs';
  eval <<"HERE";    ## no critic
    sub ${sub_name} _json {
      my ( \$self, \$url, \$args ) = \@_;
      if ( \@_ < 2 ) {
        fatal(
          arg_count_minimum => {
            minimum   => 2,
            count     => scalar \@_,
            signature => '->(url,?args)'
          }
        );
      }
      if ( \@_ > 3 ) {
        fatal(
          arg_count_maximum => {
            maximum   => 3,
            count     => scalar \@_,
            signature => '->(url,?args)'
          }
        );
      }
      if ( defined \$args and ( not ref \$args or ref \$args ne 'HASH' ) ) {
        fatal(
          arg_wrong_type => {
            got => ( ref \$args ? ref \$args : 'scalar' ),
            want     => 'HASH',
            arg_name => '\args',
            arg_pos  => 3
          }
        );
      }
      return \$self->request_json( '$req_method', \$url, \$args || {} );
    }
HERE
}

sub post_form_json {
  my ( $self, $url, $data, $args ) = @_;
  if ( @_ < 3 ) {
    fatal(
      arg_count_minimum => {
        minimum   => 3,
        count     => scalar @_,
        signature => '->(url,data,?args)'
      }
    );
  }
  if ( @_ > 4 ) {
    fatal(
      arg_count_maximum => {
        maximum   => 4,
        count     => scalar @_,
        signature => '->(url,data,?args)'
      }
    );
  }
  if ( defined $args and ( not ref $args or ref $args ne 'HASH' ) ) {
    fatal(
      arg_wrong_type => {
        got => ( ref $args ? ref $args : 'scalar' ),
        want     => 'HASH',
        arg_name => '$args',
        arg_pos  => 4
      }
    );
  }

  my $headers = {};
  while ( my ( $key, $value ) = each %{ $args->{headers} || {} } ) {
    $headers->{ lc $key } = $value;
  }
  delete $args->{headers};

  return $self->request_json(
    'POST' => $url => {
      %$args,
      content => $self->www_form_urlencode($data),
      headers => {
        %$headers, 'content-type' => 'application/x-www-form-urlencoded'
      },
    }
  );
}





no Moo;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Travis::API::UA - Travis Specific User Agent that handles authorization

=head1 VERSION

version 0.001001

=head1 SYNOPSIS

    use Net::Travis::API::UA;
    use Data::Dump qw( pp );

    my $ua = Net::Travis::API::UA->new(
        http_prefix => 'https://api.travis-ci.org', # default
        authtokens => [ 'sometoken' ]               # multiple supported, but it may not mean anything for travis
    );

    # Easy
    print pp( $ua->get_json('/users') );

    # Fine Control
    my $result = $ua->get('/users');
    if ( $result->content_type eq 'application/json' ) {
        print pp( $result->content_json );
    else {
        print pp( $result );
    }

This module does a few things:

=over 4

=item 1. Wrap HTTP::Tiny

=item 2. Assume you want to use relative URI's to the travis service

=item 3. Inject Authorization tokens where possible.

=back

All requests return L<< C<::Response>|Net::Travis::API::UA::Response >> objects.

=head1 METHODS

=head2 C<has_authtokens>

A predicate that returns whether L<< C<authtokens>|/authtokens >> is set or not

=head2 C<request>

This method overrides C<HTTP::Tiny>'s L<< C<request>|HTTP::Tiny/request >> method so
as to augment all other methods inherited.

This simply wraps all responses in a L<< C<Net::Travis::API::UA::Response>|Net::Travis::API::UA::Response >>

=head1 ATTRIBUTES

=head2 C<http_prefix>

I<Optional.>

Determines the base URI to use for relative URIs.

Defaults as L<< C<https://api.travis-ci.org>|https://api.travis-ci.org >> but should be changed if you're using their paid-for service.

=head2 C<authtokens>

I<Optional.>

If specified, determines a list of authentication tokens to pass with all requests.

=head2 C<json>

I<Optional.>

Defines a JSON decoder object.

=begin MetaPOD::JSON v1.1.0

{
    "namespace":"Net::Travis::API::UA",
    "interface":"class",
    "inherits":"HTTP::Tiny"
}


=end MetaPOD::JSON

=for Pod::Coverage FOREIGNBUILDARGS

=head1 AUTHOR

Kent Fredric <kentfredric@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Kent Fredric <kentfredric@gmail.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
