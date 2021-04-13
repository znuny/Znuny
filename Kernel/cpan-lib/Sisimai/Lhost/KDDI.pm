package Sisimai::Lhost::KDDI;
use parent 'Sisimai::Lhost';
use feature ':5.10';
use strict;
use warnings;

sub description { 'au by KDDI: https://www.au.kddi.com' }
sub make {
    # Detect an error from au by KDDI
    # @param    [Hash] mhead    Message headers of a bounce email
    # @param    [String] mbody  Message body of a bounce email
    # @return   [Hash]          Bounce data list and message/rfc822 part
    # @return   [Undef]         failed to parse or the arguments are missing
    # @since v4.0.0
    my $class = shift;
    my $mhead = shift // return undef;
    my $mbody = shift // return undef;
    my $match = 0;

    # 'message-id' => qr/[@].+[.]ezweb[.]ne[.]jp[>]\z/,
    $match ||= 1 if $mhead->{'from'} =~ /no-reply[@].+[.]dion[.]ne[.]jp/;
    $match ||= 1 if $mhead->{'reply-to'} && $mhead->{'reply-to'} eq 'no-reply@app.auone-net.jp';
    $match ||= 1 if grep { rindex($_, 'ezweb.ne.jp (') > -1 } @{ $mhead->{'received'} };
    $match ||= 1 if grep { rindex($_, '.au.com (') > -1 } @{ $mhead->{'received'} };
    return undef unless $match;

    state $indicators = __PACKAGE__->INDICATORS;
    state $rebackbone = qr|^Content-Type:[ ]message/rfc822|m;
    state $markingsof = {
        'message' => qr/\AYour[ ]mail[ ](?:
             sent[ ]on:?[ ][A-Z][a-z]{2}[,]
            |attempted[ ]to[ ]be[ ]delivered[ ]on:?[ ][A-Z][a-z]{2}[,]
            )
        /x,
    };
    state $messagesof = {
        'mailboxfull' => ['As their mailbox is full'],
        'norelaying'  => ['Due to the following SMTP relay error'],
        'hostunknown' => ['As the remote domain doesnt exist'],
    };

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
            $readcursor |= $indicators->{'deliverystatus'} if $e =~ $markingsof->{'message'};
        }
        next unless $readcursor & $indicators->{'deliverystatus'};
        next unless length $e;

        $v = $dscontents->[-1];
        if( $e =~ /\A[ \t]+Could not be delivered to: [<]([^ ]+[@][^ ]+)[>]/ ) {
            # Your mail sent on: Thu, 29 Apr 2010 11:04:47 +0900
            #     Could not be delivered to: <******@**.***.**>
            #     As their mailbox is full.
            if( $v->{'recipient'} ) {
                # There are multiple recipient addresses in the message body.
                push @$dscontents, __PACKAGE__->DELIVERYSTATUS;
                $v = $dscontents->[-1];
            }

            my $r = Sisimai::Address->s3s4($1);
            next unless Sisimai::RFC5322->is_emailaddress($r);
            $v->{'recipient'} = $r;
            $recipients++;

        } elsif( $e =~ /Your mail sent on: (.+)\z/ ) {
            # Your mail sent on: Thu, 29 Apr 2010 11:04:47 +0900
            $v->{'date'} = $1;

        } else {
            #     As their mailbox is full.
            $v->{'diagnosis'} .= $e.' ' if $e =~ /\A[ \t]+/;
        }
    }
    return undef unless $recipients;

    for my $e ( @$dscontents ) {
        $e->{'diagnosis'} = Sisimai::String->sweep($e->{'diagnosis'});

        if( defined $mhead->{'x-spasign'} && $mhead->{'x-spasign'} eq 'NG' ) {
            # Content-Type: text/plain; ..., X-SPASIGN: NG (spamghetti, au by KDDI)
            # Filtered recipient returns message that include 'X-SPASIGN' header
            $e->{'reason'} = 'filtered';

        } else {
            if( $e->{'command'} eq 'RCPT' ) {
                # set "userunknown" when the remote server rejected after RCPT
                # command.
                $e->{'reason'} = 'userunknown';

            } else {
                # SMTP command is not RCPT
                SESSION: for my $r ( keys %$messagesof ) {
                    # Verify each regular expression of session errors
                    next unless grep { index($e->{'diagnosis'}, $_) > -1 } @{ $messagesof->{ $r } };
                    $e->{'reason'} = $r;
                    last;
                }
            }
        }
    }
    return { 'ds' => $dscontents, 'rfc822' => $emailsteak->[1] };
}

1;
__END__
=encoding utf-8

=head1 NAME

Sisimai::Lhost::KDDI - bounce mail parser class for C<au by KDDI>.

=head1 SYNOPSIS

    use Sisimai::Lhost::KDDI;

=head1 DESCRIPTION

Sisimai::Lhost::KDDI parses a bounce email which created by C<au by KDDI>.
Methods in the module are called from only Sisimai::Message.

=head1 CLASS METHODS

=head2 C<B<description()>>

C<description()> returns description string of this module.

    print Sisimai::Lhost::KDDI->description;

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
