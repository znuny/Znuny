package Sisimai::Lhost::Facebook;
use parent 'Sisimai::Lhost';
use feature ':5.10';
use strict;
use warnings;

sub description { 'Facebook: https://www.facebook.com' }
sub make {
    # Detect an error from Facebook
    # @param    [Hash] mhead    Message headers of a bounce email
    # @param    [String] mbody  Message body of a bounce email
    # @return   [Hash]          Bounce data list and message/rfc822 part
    # @return   [Undef]         failed to parse or the arguments are missing
    # @since v4.0.0
    my $class = shift;
    my $mhead = shift // return undef;
    my $mbody = shift // return undef;

    return undef unless $mhead->{'from'} eq 'Facebook <mailer-daemon@mx.facebook.com>';
    return undef unless $mhead->{'subject'} eq 'Sorry, your message could not be delivered';

    state $indicators = __PACKAGE__->INDICATORS;
    state $rebackbone = qr|^Content-Disposition:[ ]inline|m;
    state $startingof = { 'message' => ['This message was created automatically by Facebook.'] };
    state $errorcodes = {
        # http://postmaster.facebook.com/response_codes
        # NOT TESTD EXCEPT RCP-P2
        'userunknown' => [
            'RCP-P1',   # The attempted recipient address does not exist.
            'INT-P1',   # The attempted recipient address does not exist.
            'INT-P3',   # The attempted recpient group address does not exist.
            'INT-P4',   # The attempted recipient address does not exist.
        ],
        'filtered' => [
            'RCP-P2',   # The attempted recipient's preferences prevent messages from being delivered.
            'RCP-P3',   # The attempted recipient's privacy settings blocked the delivery.
        ],
        'blocked' => [
            'POL-P1',   # Your mail server's IP Address is listed on the Spamhaus PBL.
            'POL-P2',   # Facebook will no longer accept mail from your mail server's IP Address.
        ],
        'mesgtoobig' => [
            'MSG-P1',   # The message exceeds Facebook's maximum allowed size.
            'INT-P2',   # The message exceeds Facebook's maximum allowed size.
        ],
        'contenterror' => [
            'MSG-P2',   # The message contains an attachment type that Facebook does not accept.
            'MSG-P3',   # The message contains multiple instances of a header field that can only be present once.
            'POL-P6',   # The message contains a url that has been blocked by Facebook.
            'POL-P7',   # The message does not comply with Facebook's abuse policies and will not be accepted.
        ],
        'securityerror' => [
            'POL-P7',   # The message does not comply with Facebook's Domain Authentication requirements.
        ],
        'notaccept' => [
            'POL-P3',   # Facebook is not accepting messages from your mail server. This will persist for 4 to 8 hours.
            'POL-P4',   # Facebook is not accepting messages from your mail server. This will persist for 24 to 48 hours.
            'POL-T1',   # Facebook is not accepting messages from your mail server, but they may be retried later. This will persist for 1 to 2 hours.
            'POL-T2',   # Facebook is not accepting messages from your mail server, but they may be retried later. This will persist for 4 to 8 hours.
            'POL-T3',   # Facebook is not accepting messages from your mail server, but they may be retried later. This will persist for 24 to 48 hours.
        ],
        'rejected' => [
            'DNS-P1',   # Your SMTP MAIL FROM domain does not exist.
            'DNS-P2',   # Your SMTP MAIL FROM domain does not have an MX record.
            'DNS-T1',   # Your SMTP MAIL FROM domain exists but does not currently resolve.
            'DNS-P3',   # Your mail server does not have a reverse DNS record.
            'DNS-T2',   # You mail server's reverse DNS record does not currently resolve.
        ],
        'systemerror' => [
            'CON-T1',   # Facebook's mail server currently has too many connections open to allow another one.
            'RCP-T1',   # The attempted recipient address is not currently available due to an internal system issue. This is a temporary condition.
        ],
        'toomanyconn' => [
            'CON-T2',   # Your mail server currently has too many connections open to Facebook's mail servers.
            'CON-T3',   # Your mail server has opened too many new connections to Facebook's mail servers in a short period of time.
        ],
        'virusdetected' => [
            'POL-P5',   # The message contains a virus.
        ],
        'suspend' => [
            'RCP-T4',   # The attempted recipient address is currently deactivated. The user may or may not reactivate it.
        ],
        'undefined' => [
            'MSG-T1',   # The number of recipients on the message exceeds Facebook's allowed maximum.
            'CON-T4',   # Your mail server has exceeded the maximum number of recipients for its current connection.
        ],
    };

    require Sisimai::RFC1894;
    my $fieldtable = Sisimai::RFC1894->FIELDTABLE;
    my $permessage = {};    # (Hash) Store values of each Per-Message field

    my $dscontents = [__PACKAGE__->DELIVERYSTATUS];
    my $emailsteak = Sisimai::RFC5322->fillet($mbody, $rebackbone);
    my $readcursor = 0;     # (Integer) Points the current cursor position
    my $recipients = 0;     # (Integer) The number of 'Final-Recipient' header
    my $fbresponse = '';    # (String) Response code from Facebook
    my $v = undef;
    my $p = '';

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

        if( my $f = Sisimai::RFC1894->match($e) ) {
            # $e matched with any field defined in RFC3464
            next unless my $o = Sisimai::RFC1894->field($e);
            $v = $dscontents->[-1];

            if( $o->[-1] eq 'addr' ) {
                # Final-Recipient: rfc822; kijitora@example.jp
                # X-Actual-Recipient: rfc822; kijitora@example.co.jp
                if( $o->[0] eq 'final-recipient' ) {
                    # Final-Recipient: rfc822; kijitora@example.jp
                    if( $v->{'recipient'} ) {
                        # There are multiple recipient addresses in the message body.
                        push @$dscontents, __PACKAGE__->DELIVERYSTATUS;
                        $v = $dscontents->[-1];
                    }
                    $v->{'recipient'} = $o->[2];
                    $recipients++;

                } else {
                    # X-Actual-Recipient: rfc822; kijitora@example.co.jp
                    $v->{'alias'} = $o->[2];
                }
            } elsif( $o->[-1] eq 'code' ) {
                # Diagnostic-Code: SMTP; 550 5.1.1 <userunknown@example.jp>... User Unknown
                $v->{'spec'} = $o->[1];
                $v->{'diagnosis'} = $o->[2];

            } else {
                # Other DSN fields defined in RFC3464
                next unless exists $fieldtable->{ $o->[0] };
                $v->{ $fieldtable->{ $o->[0] } } = $o->[2];

                next unless $f == 1;
                $permessage->{ $fieldtable->{ $o->[0] } } = $o->[2];
            }
        } else {
            # Continued line of the value of Diagnostic-Code field
            next unless index($p, 'Diagnostic-Code:') == 0;
            next unless $e =~ /\A[ \t]+(.+)\z/;
            $v->{'diagnosis'} .= ' '.$1;
        }
    } continue {
        # Save the current line for the next loop
        $p = $e;
    }
    return undef unless $recipients;

    for my $e ( @$dscontents ) {
        $e->{'lhost'}   ||= $permessage->{'lhost'};
        $e->{'diagnosis'} = Sisimai::String->sweep($e->{'diagnosis'});

        if( $e->{'diagnosis'} =~ /\b([A-Z]{3})[-]([A-Z])(\d)\b/ ) {
            # Diagnostic-Code: smtp; 550 5.1.1 RCP-P2
            $fbresponse = sprintf("%s-%s%d", $1, $2, $3);
        }

        SESSION: for my $r ( keys %$errorcodes ) {
            # Verify each regular expression of session errors
            PATTERN: for my $rr ( @{ $errorcodes->{ $r } } ) {
                # Check each regular expression
                next(PATTERN) unless $fbresponse eq $rr;
                $e->{'reason'} = $r;
                last(SESSION);
            }
        }
        next if $e->{'reason'};

        # http://postmaster.facebook.com/response_codes
        #   Facebook System Resource Issues
        #   These codes indicate a temporary issue internal to Facebook's
        #   system. Administrators observing these issues are not required to
        #   take any action to correct them.
        #
        # * INT-Tx
        #
        # https://groups.google.com/forum/#!topic/cdmix/eXfi4ddgYLQ
        # This block has not been tested because we have no email sample
        # including "INT-T?" error code.
        next unless $fbresponse =~ /\AINT-T\d+\z/;
        $e->{'reason'} = 'systemerror';
    }
    return { 'ds' => $dscontents, 'rfc822' => $emailsteak->[1] };
}

1;
__END__

=encoding utf-8

=head1 NAME

Sisimai::Lhost::Facebook - bounce mail parser class for C<Facebook>.

=head1 SYNOPSIS

    use Sisimai::Lhost::Facebook;

=head1 DESCRIPTION

Sisimai::Lhost::Facebook parses a bounce email which created by C<Facebook>.
Methods in the module are called from only Sisimai::Message.

=head1 CLASS METHODS

=head2 C<B<description()>>

C<description()> returns description string of this module.

    print Sisimai::Lhost::Facebook->description;

=head2 C<B<make(I<header data>, I<reference to body string>)>>

C<make()> method parses a bounced email and return results as a array reference.
See Sisimai::Message for more details.

=head1 AUTHOR

azumakuniyuki

=head1 COPYRIGHT

Copyright (C) 2014-2020,2022 azumakuniyuki, All rights reserved.

=head1 LICENSE

This software is distributed under The BSD 2-Clause License.

=cut
