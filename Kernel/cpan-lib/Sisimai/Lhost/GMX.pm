package Sisimai::Lhost::GMX;
use parent 'Sisimai::Lhost';
use feature ':5.10';
use strict;
use warnings;

sub description { 'GMX: https://www.gmx.net' }
sub make {
    # Detect an error from GMX and mail.com
    # @param    [Hash] mhead    Message headers of a bounce email
    # @param    [String] mbody  Message body of a bounce email
    # @return   [Hash]          Bounce data list and message/rfc822 part
    # @return   [Undef]         failed to parse or the arguments are missing
    # @since v4.1.4
    my $class = shift;
    my $mhead = shift // return undef;
    my $mbody = shift // return undef;

    # Envelope-To: <kijitora@mail.example.com>
    # X-GMX-Antispam: 0 (Mail was not recognized as spam); Detail=V3;
    # X-GMX-Antivirus: 0 (no virus found)
    # X-UI-Out-Filterresults: unknown:0;
    return undef unless defined $mhead->{'x-gmx-antispam'};

    state $indicators = __PACKAGE__->INDICATORS;
    state $rebackbone = qr|^---[ ]The[ ]header[ ]of[ ]the[ ]original[ ]message[ ]is[ ]following[.][ ]---|m;
    state $startingof = { 'message' => ['This message was created automatically by mail delivery software'] };
    state $messagesof = { 'expired' => ['delivery retry timeout exceeded'] };

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

        # This message was created automatically by mail delivery software.
        #
        # A message that you sent could not be delivered to one or more of
        # its recipients. This is a permanent error. The following address
        # failed:
        #
        # "shironeko@example.jp":
        # SMTP error from remote server after RCPT command:
        # host: mx.example.jp
        # 5.1.1 <shironeko@example.jp>... User Unknown
        $v = $dscontents->[-1];

        if( $e =~ /\A["]([^ ]+[@][^ ]+)["]:\z/ || $e =~ /\A[<]([^ ]+[@][^ ]+)[>]\z/ ) {
            # "shironeko@example.jp":
            # ---- OR ----
            # <kijitora@6jo.example.co.jp>
            #
            # Reason:
            # delivery retry timeout exceeded
            if( $v->{'recipient'} ) {
                # There are multiple recipient addresses in the message body.
                push @$dscontents, __PACKAGE__->DELIVERYSTATUS;
                $v = $dscontents->[-1];
            }
            $v->{'recipient'} = $1;
            $recipients++;

        } elsif( $e =~ /\ASMTP error .+ ([A-Z]{4}) command:\z/ ) {
            # SMTP error from remote server after RCPT command:
            $v->{'command'} = $1;

        } elsif( $e =~ /\Ahost:[ \t]*(.+)\z/ ) {
            # host: mx.example.jp
            $v->{'rhost'} = $1;

        } else {
            # Get error message
            if( $e =~ /\b[45][.]\d[.]\d\b/ || $e =~ /[<][^ ]+[@][^ ]+[>]/ || $e =~ /\b[45]\d{2}\b/ ) {
                $v->{'diagnosis'} ||= $e;

            } else {
                next if $e eq '';
                if( $e eq 'Reason:' ) {
                    # Reason:
                    # delivery retry timeout exceeded
                    $v->{'diagnosis'} = $e;

                } elsif( $v->{'diagnosis'} eq 'Reason:' ) {
                    $v->{'diagnosis'} = $e;
                }
            }
        }
    }
    return undef unless $recipients;

    for my $e ( @$dscontents ) {
        $e->{'diagnosis'} =~ y/\n/ /;
        $e->{'diagnosis'} =  Sisimai::String->sweep($e->{'diagnosis'});

        SESSION: for my $r ( keys %$messagesof ) {
            # Verify each regular expression of session errors
            next unless grep { index($e->{'diagnosis'}, $_) > -1 } @{ $messagesof->{ $r } };
            $e->{'reason'} = $r;
            last;
        }
    }
    return { 'ds' => $dscontents, 'rfc822' => $emailsteak->[1] };
}

1;
__END__

=encoding utf-8

=head1 NAME

Sisimai::Lhost::GMX - bounce mail parser class for C<GMX> and mail.com.

=head1 SYNOPSIS

    use Sisimai::Lhost::GMX;

=head1 DESCRIPTION

Sisimai::Lhost::GMX parses a bounce email which created by C<GMX>.
Methods in the module are called from only Sisimai::Message.

=head1 CLASS METHODS

=head2 C<B<description()>>

C<description()> returns description string of this module.

    print Sisimai::Lhost::GMX->description;

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

