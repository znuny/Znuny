package Sisimai::Lhost::X1;
use parent 'Sisimai::Lhost';
use feature ':5.10';
use strict;
use warnings;

sub description { 'Unknown MTA #1' }
sub make {
    # Detect an error from Unknown MTA #1
    # @param    [Hash] mhead    Message headers of a bounce email
    # @param    [String] mbody  Message body of a bounce email
    # @return   [Hash]          Bounce data list and message/rfc822 part
    # @return   [Undef]         failed to parse or the arguments are missing
    # @since v4.1.3
    my $class = shift;
    my $mhead = shift // return undef;
    my $mbody = shift // return undef;

    return undef unless index($mhead->{'subject'}, 'Returned Mail: ') == 0;
    return undef unless index($mhead->{'from'}, '"Mail Deliver System" ') == 0;

    state $indicators = __PACKAGE__->INDICATORS;
    state $rebackbone = qr/^Received: from \d+[.]\d+[.]\d+[.]\d/m;
    state $markingsof = { 'message' => qr/\AThe original message was received at (.+)\z/ };

    my $dscontents = [__PACKAGE__->DELIVERYSTATUS];
    my $emailsteak = Sisimai::RFC5322->fillet($mbody, $rebackbone);
    my $readcursor = 0;     # (Integer) Points the current cursor position
    my $recipients = 0;     # (Integer) The number of 'Final-Recipient' header
    my $datestring = '';    # (String) Date string
    my $v = undef;

    for my $e ( split("\n", $emailsteak->[0]) ) {
        # Read error messages and delivery status lines from the head of the email
        # to the previous line of the beginning of the original message.
        unless( $readcursor ) {
            # Beginning of the bounce message or message/delivery-status part
            $readcursor |= $indicators->{'deliverystatus'} if $e =~ $markingsof->{'message'};
            next;
        }
        next unless $readcursor & $indicators->{'deliverystatus'};
        next unless length $e;

        # The original message was received at Thu, 29 Apr 2010 23:34:45 +0900 (JST)
        # from shironeko@example.jp
        #
        # ---The following addresses had delivery errors---
        #
        # kijitora@example.co.jp [User unknown]
        $v = $dscontents->[-1];

        if( $e =~ /\A([^ ]+?[@][^ ]+?)[ \t]+\[(.+)\]\z/ ) {
            # kijitora@example.co.jp [User unknown]
            if( $v->{'recipient'} ) {
                # There are multiple recipient addresses in the message body.
                push @$dscontents, __PACKAGE__->DELIVERYSTATUS;
                $v = $dscontents->[-1];
            }
            $v->{'recipient'} = $1;
            $v->{'diagnosis'} = $2;
            $recipients++;

        } elsif( $e =~ $markingsof->{'message'} ) {
            # The original message was received at Thu, 29 Apr 2010 23:34:45 +0900 (JST)
            $datestring = $1;
        }
    }
    return undef unless $recipients;

    for my $e ( @$dscontents ) {
        $e->{'diagnosis'} = Sisimai::String->sweep($e->{'diagnosis'});
        $e->{'date'}      = $datestring || '';
    }
    return { 'ds' => $dscontents, 'rfc822' => $emailsteak->[1] };
}

1;
__END__

=encoding utf-8

=head1 NAME

Sisimai::Lhost::X1 - bounce mail parser class for C<X1>.

=head1 SYNOPSIS

    use Sisimai::Lhost::X1;

=head1 DESCRIPTION

Sisimai::Lhost::X1 parses a bounce email which created by Unknown MTA #1.
Methods in the module are called from only Sisimai::Message.

=head1 CLASS METHODS

=head2 C<B<description()>>

C<description()> returns description string of this module.

    print Sisimai::Lhost::X1->description;

=head2 C<B<make(I<header data>, I<reference to body string>)>>

C<make()> method parses a bounced email and return results as a array reference.
See Sisimai::Message for more details.

=head1 AUTHOR

azumakuniyuki

=head1 COPYRIGHT

Copyright (C) 2014-2020 azumakuniyuki, All rights reserved.

=head1 LICENSE

This software is distributed under The BSD 2-Clause License.

=cut

