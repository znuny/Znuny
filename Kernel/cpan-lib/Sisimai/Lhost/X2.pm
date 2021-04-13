package Sisimai::Lhost::X2;
use parent 'Sisimai::Lhost';
use feature ':5.10';
use strict;
use warnings;

sub description { 'Unknown MTA #2' }
sub make {
    # Detect an error from Unknown MTA #2
    # @param    [Hash] mhead    Message headers of a bounce email
    # @param    [String] mbody  Message body of a bounce email
    # @return   [Hash]          Bounce data list and message/rfc822 part
    # @return   [Undef]         failed to parse or the arguments are missing
    # @since v4.1.7
    my $class = shift;
    my $mhead = shift // return undef;
    my $mbody = shift // return undef;

    return undef unless index($mhead->{'from'}, 'MAILER-DAEMON@') > -1;
    return undef unless $mhead->{'subject'} =~ /\A(?>Delivery[ ]failure|fail(?:ure|ed)[ ]delivery)/;

    state $indicators = __PACKAGE__->INDICATORS;
    state $rebackbone = qr|^--- Original message follows[.]|m;
    state $startingof = { 'message' => ['Unable to deliver message to the following address'] };

    my $dscontents = [__PACKAGE__->DELIVERYSTATUS];
    my $emailsteak = Sisimai::RFC5322->fillet($mbody, $rebackbone);
    my $readcursor = 0;     # (Integer) Points the current cursor position
    my $recipients = 0;     # (Integer) The number of 'Final-Recipient' header
    my $v = undef;

    for my $e ( split("\n", $emailsteak->[0]) ) {
        # Read error messages and delivery status lines from the head of the email
        # to the previous line of the beginning of the original message.
        unless( $readcursor ) {
            # Beginning of the bounce message or message/delivery-status part
            $readcursor |= $indicators->{'deliverystatus'} if index($e, $startingof->{'message'}->[0]) == 0;
            next;
        }
        next unless $readcursor & $indicators->{'deliverystatus'};
        next unless length $e;

        # Message from example.com.
        # Unable to deliver message to the following address(es).
        #
        # <kijitora@example.com>:
        # This user doesn't have a example.com account (kijitora@example.com) [0]
        $v = $dscontents->[-1];

        if( $e =~ /\A[<]([^ ]+[@][^ ]+)[>]:\z/ ) {
            # <kijitora@example.com>:
            if( $v->{'recipient'} ) {
                # There are multiple recipient addresses in the message body.
                push @$dscontents, __PACKAGE__->DELIVERYSTATUS;
                $v = $dscontents->[-1];
            }
            $v->{'recipient'} = $1;
            $recipients++;

        } else {
            # This user doesn't have a example.com account (kijitora@example.com) [0]
            $v->{'diagnosis'} .= ' '.$e;
        }
    }
    return undef unless $recipients;

    $_->{'diagnosis'} = Sisimai::String->sweep($_->{'diagnosis'}) for @$dscontents;
    return { 'ds' => $dscontents, 'rfc822' => $emailsteak->[1] };
}

1;
__END__

=encoding utf-8

=head1 NAME

Sisimai::Lhost::X2 - bounce mail parser class for C<X2>.

=head1 SYNOPSIS

    use Sisimai::Lhost::X2;

=head1 DESCRIPTION

Sisimai::Lhost::X2 parses a bounce email which created by Unknown MTA #2.
Methods in the module are called from only Sisimai::Message.

=head1 CLASS METHODS

=head2 C<B<description()>>

C<description()> returns description string of this module.

    print Sisimai::Lhost::X2->description;

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

