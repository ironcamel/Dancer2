package Dancer::Core::Response;

use strict;
use warnings;
use Carp;
use Moo;
use Encode;
use Dancer::Moo::Types;

use Scalar::Util qw/looks_like_number blessed/;
use Dancer::HTTP;
use Dancer::MIME;

with 'Dancer::Core::Role::Headers';

sub BUILD {
    my ($self) = @_;
    $self->header('Server' => "Perl Dancer");
}

# boolean to tell if the route passes or not
has has_passed => (
    is => 'rw',
    isa => sub { Dancer::Moo::Types::Bool(@_) },
    default => 0,
);

has is_encoded => (
    is => 'rw',
    isa => sub { Dancer::Moo::Types::Bool(@_) },
    default => 0,
);

has is_halted => (
    is => 'rw',
    isa => sub { Dancer::Moo::Types::Bool(@_) },
    default => 0,
);

has status => (
    is => 'rw',
    isa => sub { Dancer::Moo::Types::Num(@_) },
    default => sub { 200 },
    lazy => 1,
    coerce => sub {
        my ($status) = @_;
        return $status if looks_like_number($status);
        Dancer::HTTP->status($status);
    },
);

has content => (
    is => 'rw',
    isa => sub { Dancer::Moo::Types::Str(@_) },
    default => sub { '' },
    coerce => sub {
        my ($value) = @_;
        $value = "$value" if ref($value);
        return $value;
    },
    trigger => sub { 
        my ($self, $value) = @_;
        $self->header('Content-Length' => length($value));
    },
);

sub encode_content {
    my ($self) = @_;
    return if $self->is_encoded;
    return if $self->content_type !~ /^text/;
    $self->is_encoded(1);
    $self->content(Encode::encode('UTF-8', $self->content));
}

sub to_psgi {
    my ($self) = @_;

    return [
        $self->status,
        $self->headers_to_array,
        [ $self->content ],
    ];
}

# sugar for accessing the content_type header, with mimetype care
sub content_type {
    my $self = shift;

    if (scalar @_ > 0) {
        my $mimetype = Dancer::MIME->instance();
        $self->header('Content-Type' => $mimetype->name_or_type(shift));
    } else {
        return $self->header('Content-Type');
    }
}

has _forward => (
    is => 'rw',
    isa => sub { Dancer::Moo::Types::HashRef(@_) },
);

sub forward {
    my ($self, $uri, $params, $opts) = @_;
    $self->_forward({to_url => $uri, params => $params, options => $opts});
}

sub is_forwarded {
    my $self = shift;
    $self->_forward;
}

1;
__END__
=head1 NAME

Dancer::Response - Response object for Dancer

TODO ...
