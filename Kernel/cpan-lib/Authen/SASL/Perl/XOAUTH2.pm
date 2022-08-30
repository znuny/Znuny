#!/usr/bin/perl
# Copyright (c) 2018 Veltro. All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
# This package is provided "as is" and without any express or implied
# warranties, including, without limitation, the implied warranties of
# merchantability and fitness for a particular purpose
#
# Description:
# Part of SASL authentication mechanism for OAuth 2.0 (RFC 6749)
# This package contains the method to create the initial client
# response according to the format specified in:
# https://developers.google.com/gmail/imap/xoauth2-protocol

# https://www.perlmonks.org/?node_id=1218405
package Authen::SASL::Perl::XOAUTH2 ;

use strict ;
use warnings ;

our $VERSION = "0.01c" ;
our @ISA = qw( Authen::SASL::Perl ) ;

my %secflags = ( ) ;

sub _order { 1 }

sub _secflags {
  shift ;
  scalar grep { $secflags{$_} } @_ ;
}

sub mechanism {
    # SMTP->auth may call mechanism again with arg $mechanisms
    #            but that means something is not right
    if ( defined $_[1] ) { die "XOAUTH2 not supported by host\n" } ;
    return 'XOAUTH2' ;
} ;

my @tokens = qw( user auth access_token ) ;

sub client_start {
    # Create authorization string:
    # "user=" {User} "^Aauth=Bearer " {Access Token} "^A^A"
    my $self = shift ;
    $self->{ error } = undef ;
    $self->{ need_step } = 0 ;
    return
        'user=' .
        $self->_call( $tokens[0] ) .
        "\001auth=" .
        $self->_call( $tokens[1] ) .
        " " .
        $self->_call( $tokens[2] ) .
        "\001\001" ;
}

1 ;
