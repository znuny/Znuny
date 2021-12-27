package Sisimai::Lhost::Yahoo;
use parent 'Sisimai::Lhost';
use feature ':5.10';
use strict;
use warnings;

sub description { 'Yahoo! MAIL: https://www.yahoo.com' }
sub make {
    # Detect an error from Yahoo! MAIL
    # @param    [Hash] mhead    Message headers of a bounce email
    # @param    [String] mbody  Message body of a bounce email
    # @return   [Hash]          Bounce data list and message/rfc822 part
    # @return   [Undef]         failed to parse or the arguments are missing
    # @since v4.1.3
    my $class = shift;
    my $mhead = shift // return undef;
    my $mbody = shift // return undef;

    # X-YMailISG: YtyUVyYWLDsbDh...
    # X-YMail-JAS: Pb65aU4VM1mei...
    # X-YMail-OSG: bTIbpDEVM1lHz...
    # X-Originating-IP: [192.0.2.9]
    return undef unless $mhead->{'x-ymailisg'};

    state $indicators = __PACKAGE__->INDICATORS;
    state $rebackbone = qr|^--- Below this line is a copy of the message[.]|m;
    state $startingof = { 'message' => ['Sorry, we were unable to deliver your message'] };

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

        # Sorry, we were unable to deliver your message to the following address.
        #
        # <kijitora@example.org>:
        # Remote host said: 550 5.1.1 <kijitora@example.org>... User Unknown [RCPT_TO]
        $v = $dscontents->[-1];

        if( $e =~ /\A[<](.+[@].+)[>]:[ \t]*\z/ ) {
            # <kijitora@example.org>:
            if( $v->{'recipient'} ) {
                # There are multiple recipient addresses in the message body.
                push @$dscontents, __PACKAGE__->DELIVERYSTATUS;
                $v = $dscontents->[-1];
            }
            $v->{'recipient'} = $1;
            $recipients++;

        } else {
            if( index($e, 'Remote host said:') == 0 ) {
                # Remote host said: 550 5.1.1 <kijitora@example.org>... User Unknown [RCPT_TO]
                $v->{'diagnosis'} = $e;

                # Get SMTP command from the value of "Remote host said:"
                $v->{'command'} = $1 if $e =~ /\[([A-Z]{4}).*\]\z/;
            } else {
                # <mailboxfull@example.jp>:
                # Remote host said:
                # 550 5.2.2 <mailboxfull@example.jp>... Mailbox Full
                # [RCPT_TO]
                if( $v->{'diagnosis'} eq 'Remote host said:' ) {
                    # Remote host said:
                    # 550 5.2.2 <mailboxfull@example.jp>... Mailbox Full
                    if( $e =~ /\[([A-Z]{4}).*\]\z/ ) {
                        # [RCPT_TO]
                        $v->{'command'} = $1;

                    } else {
                        # 550 5.2.2 <mailboxfull@example.jp>... Mailbox Full
                        $v->{'diagnosis'} = $e;
                    }
                } else {
                    # Error message which does not start with 'Remote host said:'
                    $v->{'diagnosis'} .= ' '.$e;
                }
            }
        }
    }
    return undef unless $recipients;

    for my $e ( @$dscontents ) {
        $e->{'diagnosis'} =~ y/\n/ /;
        $e->{'diagnosis'} =  Sisimai::String->sweep($e->{'diagnosis'});
        $e->{'command'} ||=  'RCPT' if $e->{'diagnosis'} =~ /[<].+[@].+[>]/;
    }
    return { 'ds' => $dscontents, 'rfc822' => $emailsteak->[1] };
}

1;
__END__

=encoding utf-8

=head1 NAME

Sisimai::Lhost::Yahoo - bounce mail parser class for C<Yahoo! MAIL>.

=head1 SYNOPSIS

    use Sisimai::Lhost::Yahoo;

=head1 DESCRIPTION

Sisimai::Lhost::Yahoo parses a bounce email which created by C<Yahoo! MAIL>.
Methods in the module are called from only Sisimai::Message.

=head1 CLASS METHODS

=head2 C<B<description()>>

C<description()> returns description string of this module.

    print Sisimai::Lhost::Yahoo->description;

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

