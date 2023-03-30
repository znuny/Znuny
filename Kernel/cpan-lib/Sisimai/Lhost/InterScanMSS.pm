package Sisimai::Lhost::InterScanMSS;
use parent 'Sisimai::Lhost';
use feature ':5.10';
use strict;
use warnings;

sub description { 'Trend Micro InterScan Messaging Security Suite' }
sub make {
    # Detect an error from InterScanMSS
    # @param    [Hash] mhead    Message headers of a bounce email
    # @param    [String] mbody  Message body of a bounce email
    # @return   [Hash]          Bounce data list and message/rfc822 part
    # @return   [Undef]         failed to parse or the arguments are missing
    # @since v4.1.2
    my $class = shift;
    my $mhead = shift // return undef;
    my $mbody = shift // return undef;
    my $match = 0;
    my $tryto = [
        'Mail could not be delivered',
        'メッセージを配信できません。',
        'メール配信に失敗しました',
    ];

    # 'received' => qr/[ ][(]InterScanMSS[)][ ]with[ ]/,
    $match ||= 1 if index($mhead->{'from'}, '"InterScan MSS"') == 0;
    $match ||= 1 if index($mhead->{'from'}, '"InterScan Notification"') == 0;
    $match ||= 1 if grep { $mhead->{'subject'} eq $_ } @$tryto;
    return undef unless $match;

    state $rebackbone = qr|^Content-type:[ ]message/rfc822|m;
    my $dscontents = [__PACKAGE__->DELIVERYSTATUS];
    my $emailsteak = Sisimai::RFC5322->fillet($mbody, $rebackbone);
    my $recipients = 0;     # (Integer) The number of 'Final-Recipient' header
    my $v = undef;

    for my $e ( split("\n", $emailsteak->[0]) ) {
        # Read error messages and delivery status lines from the head of the email
        # to the previous line of the beginning of the original message.
        next unless length $e;

        $v = $dscontents->[-1];
        if( $e =~ /\A.+[<>]{3}[ \t]+.+[<]([^ ]+[@][^ ]+)[>]\z/ ||
            $e =~ /\A.+[<>]{3}[ \t]+.+[<]([^ ]+[@][^ ]+)[>]/   ||
            $e =~ /\A(?:Reason:[ ]+)?Unable[ ]to[ ]deliver[ ]message[ ]to[ ][<](.+)[>]/ ) {
            # Sent <<< RCPT TO:<kijitora@example.co.jp>
            # Received >>> 550 5.1.1 <kijitora@example.co.jp>... user unknown
            # Unable to deliver message to <kijitora@neko.example.jp>
            my $cr = $1;
            if( $v->{'recipient'} && $cr ne $v->{'recipient'} ) {
                # There are multiple recipient addresses in the message body.
                push @$dscontents, __PACKAGE__->DELIVERYSTATUS;
                $v = $dscontents->[-1];
            }
            $v->{'recipient'} = $cr;
            $v->{'diagnosis'} = $e if $e =~ /Unable[ ]to[ ]deliver[ ]/;
            $recipients = scalar @$dscontents;
        }

        if( $e =~ /\ASent[ \t]+[<]{3}[ \t]+([A-Z]{4})[ \t]/ ) {
            # Sent <<< RCPT TO:<kijitora@example.co.jp>
            $v->{'command'} = $1

        } elsif( $e =~ /\AReceived[ \t]+[>]{3}[ \t]+(\d{3}[ \t]+.+)\z/ ) {
            # Received >>> 550 5.1.1 <kijitora@example.co.jp>... user unknown
            $v->{'diagnosis'} = $1;

        } else {
            # Error message in non-English
            next unless $e =~ /[ ][<>]{3}[ ]/;
            $v->{'command'}   = $1 if $e =~ /[ ][>]{3}[ ]([A-Z]{4})/; # >>> RCPT TO ...
            $v->{'diagnosis'} = $1 if $e =~ /[ ][<]{3}[ ](.+)/;       # <<< 550 5.1.1 User unknown
        }
    }
    return undef unless $recipients;

    for my $e ( @$dscontents ) {
        # Set default values if each value is empty.
        $e->{'diagnosis'} = Sisimai::String->sweep($e->{'diagnosis'});
        $e->{'reason'} = 'userunknown' if $e->{'diagnosis'} =~ /Unable[ ]to[ ]deliver/;
    }
    return { 'ds' => $dscontents, 'rfc822' => $emailsteak->[1] };
}

1;
__END__

=encoding utf-8

=head1 NAME

Sisimai::Lhost::InterScanMSS - bounce mail parser class for
C<Trend Micro InterScan Messaging Security Suite>.

=head1 SYNOPSIS

    use Sisimai::Lhost::InterScanMSS;

=head1 DESCRIPTION

Sisimai::Lhost::InterScanMSS parses a bounce email which created by C<Trend Micro
InterScan Messaging Security Suite>. Methods in the module are called from only
Sisimai::Message.

=head1 CLASS METHODS

=head2 C<B<description()>>

C<description()> returns description string of this module.

    print Sisimai::Lhost::InterScanMSS->description;

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

