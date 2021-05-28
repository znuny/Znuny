package Sisimai::Lhost::MailMarshalSMTP;
use parent 'Sisimai::Lhost';
use feature ':5.10';
use strict;
use warnings;

sub description { 'Trustwave Secure Email Gateway' }
sub make {
    # Detect an error from MailMarshalSMTP
    # @param    [Hash] mhead    Message headers of a bounce email
    # @param    [String] mbody  Message body of a bounce email
    # @return   [Hash]          Bounce data list and message/rfc822 part
    # @return   [Undef]         failed to parse or the arguments are missing
    # @since v4.1.9
    my $class = shift;
    my $mhead = shift // return undef;
    my $mbody = shift // return undef;
    return undef unless index($mhead->{'subject'}, 'Undeliverable Mail: "') == 0;

    state $indicators = __PACKAGE__->INDICATORS;
    state $rebackbone = qr/^[ \t]*[+]+[ \t]*/m;
    state $startingof = {
        'message'  => ['Your message:'],
        'error'    => ['Could not be delivered because of'],
        'rcpts'    => ['The following recipients were affected:'],
    };

    my $dscontents = [__PACKAGE__->DELIVERYSTATUS];
    my $readcursor = 0;     # (Integer) Points the current cursor position
    my $recipients = 0;     # (Integer) The number of 'Final-Recipient' header
    my $endoferror = 0;     # (Integer) Flag for the end of error message
    my $v = undef;

    if( my $boundary00 = Sisimai::MIME->boundary($mhead->{'content-type'}, 1) ) {
        # Convert to regular expression
        $rebackbone = qr/^\Q$boundary00\E/m;
    }
    my $emailsteak = Sisimai::RFC5322->fillet($mbody, $rebackbone);

    for my $e ( split("\n", $emailsteak->[0]) ) {
        # Read error messages and delivery status lines from the head of the email
        # to the previous line of the beginning of the original message.
        unless( $readcursor ) {
            # Beginning of the bounce message or message/delivery-status part
            $readcursor |= $indicators->{'deliverystatus'} if index($e, $startingof->{'message'}->[0]) == 0;
        }
        next unless $readcursor & $indicators->{'deliverystatus'};

        # Your message:
        #    From:    originalsender@example.com
        #    Subject: ...
        #
        # Could not be delivered because of
        #
        # 550 5.1.1 User unknown
        #
        # The following recipients were affected:
        #    dummyuser@blabla.xxxxxxxxxxxx.com
        $v = $dscontents->[-1];

        if( $e =~ /\A[ \t]{4}([^ ]+[@][^ ]+)\z/ ) {
            # The following recipients were affected:
            #    dummyuser@blabla.xxxxxxxxxxxx.com
            if( $v->{'recipient'} ) {
                # There are multiple recipient addresses in the message body.
                push @$dscontents, __PACKAGE__->DELIVERYSTATUS;
                $v = $dscontents->[-1];
            }
            $v->{'recipient'} = $1;
            $recipients++;

        } else {
            # Get error message lines
            if( $e eq $startingof->{'error'}->[0] ) {
                # Could not be delivered because of
                #
                # 550 5.1.1 User unknown
                $v->{'diagnosis'} = $e;

            } elsif( $v->{'diagnosis'} && ! $endoferror ) {
                # Append error messages
                $endoferror = 1 if index($e, $startingof->{'rcpts'}->[0]) == 0;
                next if $endoferror;

                $v->{'diagnosis'} .= ' '.$e;

            } else {
                # Additional Information
                # ======================
                # Original Sender:    <originalsender@example.com>
                # Sender-MTA:         <10.11.12.13>
                # Remote-MTA:         <10.0.0.1>
                # Reporting-MTA:      <relay.xxxxxxxxxxxx.com>
                # MessageName:        <B549996730000.000000000001.0003.mml>
                # Last-Attempt-Date:  <16:21:07 seg, 22 Dezembro 2014>
                if( $e =~ /\AOriginal Sender:[ \t]+[<](.+)[>]\z/ ) {
                    # Original Sender:    <originalsender@example.com>
                    # Use this line instead of "From" header of the original
                    # message.
                    $emailsteak->[1] .= sprintf("From: %s\n", $1);

                } elsif( $e =~ /\ASender-MTA:[ \t]+[<](.+)[>]\z/ ) {
                    # Sender-MTA:         <10.11.12.13>
                    $v->{'lhost'} = $1;

                } elsif( $e =~ /\AReporting-MTA:[ \t]+[<](.+)[>]\z/ ) {
                    # Reporting-MTA:      <relay.xxxxxxxxxxxx.com>
                    $v->{'rhost'} = $1;

                } elsif( $e =~ /\A\s+(From|Subject):\s*(.+)\z/ ) {
                    #    From:    originalsender@example.com
                    #    Subject: ...
                    $emailsteak->[1] .= sprintf("%s: %s\n", $1, $2);
                }
            }
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

Sisimai::Lhost::MailMarshalSMTP - bounce mail parser class for
C<Trustwave Secure Email Gateway>.

=head1 SYNOPSIS

    use Sisimai::Lhost::MailMarshalSMTP;

=head1 DESCRIPTION

Sisimai::Lhost::MailMarshalSMTP parses a bounce email which created by
C<Trustwave Secure Email Gateway>: formerly MailMarshal SMTP.
Methods in the module are called from only Sisimai::Message.

=head1 CLASS METHODS

=head2 C<B<description()>>

C<description()> returns description string of this module.

    print Sisimai::Lhost::MailMarshalSMTP->description;

=head2 C<B<make(I<header data>, I<reference to body string>)>>

C<make()> method parses a bounced email and return results as a array reference.
See Sisimai::Message for more details.

=head1 AUTHOR

azumakuniyuki

=head1 COPYRIGHT

Copyright (C) 2014-2021 azumakuniyuki, All rights reserved.

=head1 LICENSE

This software is distributed under The BSD 2-Clause License.

=cut


