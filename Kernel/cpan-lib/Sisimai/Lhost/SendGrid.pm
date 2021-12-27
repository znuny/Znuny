package Sisimai::Lhost::SendGrid;
use parent 'Sisimai::Lhost';
use feature ':5.10';
use strict;
use warnings;

sub description { 'SendGrid: https://sendgrid.com/' }
sub make {
    # Detect an error from SendGrid
    # @param    [Hash] mhead    Message headers of a bounce email
    # @param    [String] mbody  Message body of a bounce email
    # @return   [Hash]          Bounce data list and message/rfc822 part
    # @return   [Undef]         failed to parse or the arguments are missing
    # @since v4.0.2
    my $class = shift;
    my $mhead = shift // return undef;
    my $mbody = shift // return undef;

    # Return-Path: <apps@sendgrid.net>
    # X-Mailer: MIME-tools 5.502 (Entity 5.502)
    return undef unless $mhead->{'return-path'};
    return undef unless $mhead->{'return-path'} eq '<apps@sendgrid.net>';
    return undef unless $mhead->{'subject'} eq 'Undelivered Mail Returned to Sender';

    state $indicators = __PACKAGE__->INDICATORS;
    state $rebackbone = qr|^Content-Type:[ ]message/rfc822|m;
    state $startingof = { 'message' => ['This is an automatically generated message from SendGrid.'] };

    require Sisimai::RFC1894;
    my $fieldtable = Sisimai::RFC1894->FIELDTABLE;
    my $permessage = {};    # (Hash) Store values of each Per-Message field

    my $dscontents = [__PACKAGE__->DELIVERYSTATUS];
    my $emailsteak = Sisimai::RFC5322->fillet($mbody, $rebackbone);
    my $readcursor = 0;     # (Integer) Points the current cursor position
    my $recipients = 0;     # (Integer) The number of 'Final-Recipient' header
    my $commandtxt = '';    # (String) SMTP Command name begin with the string '>>>'
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
            my $o = Sisimai::RFC1894->field($e);
            $v = $dscontents->[-1];

            unless( $o ) {
                # Fallback code for empty value or invalid formatted value
                # - Status: (empty)
                # - Diagnostic-Code: 550 5.1.1 ... (No "diagnostic-type" sub field)
                $v->{'diagnosis'} = $1 if $e =~ /\ADiagnostic-Code:[ ]*(.+)/;
                next;
            }

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

            } elsif( $o->[-1] eq 'date' ) {
                # Arrival-Date: 2012-12-31 23-59-59
                next unless $e =~ /\AArrival-Date: (\d{4})[-](\d{2})[-](\d{2}) (\d{2})[-](\d{2})[-](\d{2})\z/;
                $o->[1] .= 'Thu, '.$3.' ';
                $o->[1] .= Sisimai::DateTime->monthname(0)->[int($2) - 1];
                $o->[1] .= ' '.$1.' '.join(':', $4, $5, $6);
                $o->[1] .= ' '.Sisimai::DateTime->abbr2tz('CDT');
            } else {
                # Other DSN fields defined in RFC3464
                next unless exists $fieldtable->{ $o->[0] };
                $v->{ $fieldtable->{ $o->[0] } } = $o->[2];

                next unless $f == 1;
                $permessage->{ $fieldtable->{ $o->[0] } } = $o->[2];
            }
        } else {
            # This is an automatically generated message from SendGrid.
            #
            # I'm sorry to have to tell you that your message was not able to be
            # delivered to one of its intended recipients.
            #
            # If you require assistance with this, please contact SendGrid support.
            #
            # shironekochan:000000:<kijitora@example.jp> : 192.0.2.250 : mx.example.jp:[192.0.2.153] :
            #   550 5.1.1 <userunknown@cubicroot.jp>... User Unknown  in RCPT TO
            #
            # ------------=_1351676802-30315-116783
            # Content-Type: message/delivery-status
            # Content-Disposition: inline
            # Content-Transfer-Encoding: 7bit
            # Content-Description: Delivery Report
            #
            # X-SendGrid-QueueID: 959479146
            # X-SendGrid-Sender: <bounces+61689-10be-kijitora=example.jp@sendgrid.info>
            if( $e =~ /.+ in (?:End of )?([A-Z]{4}).*\z/ ) {
                # in RCPT TO, in MAIL FROM, end of DATA
                $commandtxt = $1;

            } else {
                # Continued line of the value of Diagnostic-Code field
                next unless index($p, 'Diagnostic-Code:') == 0;
                next unless $e =~ /\A[ \t]+(.+)\z/;
                $v->{'diagnosis'} .= ' '.$1;
            }
        }
    } continue {
        # Save the current line for the next loop
        $p = $e;
    }
    return undef unless $recipients;

    for my $e ( @$dscontents ) {
        # Get the value of SMTP status code as a pseudo D.S.N.
        $e->{'diagnosis'} = Sisimai::String->sweep($e->{'diagnosis'});
        $e->{'status'} = $1.'.0.0' if $e->{'diagnosis'} =~ /\b([45])\d\d[ \t]*/;

        if( $e->{'status'} eq '5.0.0' || $e->{'status'} eq '4.0.0' ) {
            # Get the value of D.S.N. from the error message or the value of
            # Diagnostic-Code header.
            $e->{'status'} = Sisimai::SMTP::Status->find($e->{'diagnosis'}) || $e->{'status'};
        }

        if( $e->{'action'} eq 'expired' ) {
            # Action: expired
            $e->{'reason'} = 'expired';
            if( ! $e->{'status'} || substr($e->{'status'}, -4, 4) eq '.0.0' ) {
                # Set pseudo Status code value if the value of Status is not
                # defined or 4.0.0 or 5.0.0.
                $e->{'status'} = Sisimai::SMTP::Status->code('expired') || $e->{'status'};
            }
        }
        $e->{'lhost'}   ||= $permessage->{'rhost'};
        $e->{'command'} ||= $commandtxt;
    }
    return { 'ds' => $dscontents, 'rfc822' => $emailsteak->[1] };
}

1;
__END__

=encoding utf-8

=head1 NAME

Sisimai::Lhost::SendGrid - bounce mail parser class for C<SendGrid>.

=head1 SYNOPSIS

    use Sisimai::Lhost::SendGrid;

=head1 DESCRIPTION

Sisimai::Lhost::SendGrid parses a bounce email which created by C<SendGrid>.
Methods in the module are called from only Sisimai::Message.

=head1 CLASS METHODS

=head2 C<B<description()>>

C<description()> returns description string of this module.

    print Sisimai::Lhost::SendGrid->description;

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
