package Sisimai::Lhost::Notes;
use parent 'Sisimai::Lhost';
use feature ':5.10';
use strict;
use warnings;
use Encode;

sub description { 'Lotus Notes' }
sub make {
    # Detect an error from Lotus Notes
    # @param    [Hash] mhead    Message headers of a bounce email
    # @param    [String] mbody  Message body of a bounce email
    # @return   [Hash]          Bounce data list and message/rfc822 part
    # @return   [Undef]         failed to parse or the arguments are missing
    # @since v4.1.1
    my $class = shift;
    my $mhead = shift // return undef;
    my $mbody = shift // return undef;
    return undef unless index($mhead->{'subject'}, 'Undeliverable message') == 0;

    state $indicators = __PACKAGE__->INDICATORS;
    state $rebackbone = qr|^-------[ ]Returned[ ]Message[ ]--------|m;
    state $startingof = { 'message' => ['------- Failure Reasons '] };
    state $messagesof = {
        'userunknown' => [
            'User not listed in public Name & Address Book',
            'ディレクトリのリストにありません',
        ],
        'networkerror' => ['Message has exceeded maximum hop count'],
    };

    my $dscontents = [__PACKAGE__->DELIVERYSTATUS];
    my $emailsteak = Sisimai::RFC5322->fillet($mbody, $rebackbone);
    my $readcursor = 0;     # (Integer) Points the current cursor position
    my $recipients = 0;     # (Integer) The number of 'Final-Recipient' header
    my $removedmsg = 'MULTIBYTE CHARACTERS HAVE BEEN REMOVED';
    my $encodedmsg = '';
    my $v = undef;

    # Get character set name, Content-Type: text/plain; charset=ISO-2022-JP
    my $characters = $mhead->{'content-type'} =~ /\A.+;[ ]*charset=(.+)\z/ ? lc $1 : '';

    for my $e ( split("\n", $emailsteak->[0]) ) {
        # Read error messages and delivery status lines from the head of the email
        # to the previous line of the beginning of the original message.
        unless( $readcursor ) {
            # Beginning of the bounce message or message/delivery-status part
            $readcursor |= $indicators->{'deliverystatus'} if index($e, $startingof->{'message'}->[0]) == 0;
            next;
        }
        next unless $readcursor & $indicators->{'deliverystatus'};

        # ------- Failure Reasons  --------
        #
        # User not listed in public Name & Address Book
        # kijitora@notes.example.jp
        #
        # ------- Returned Message --------
        $v = $dscontents->[-1];
        if( $e =~ /\A[^ ]+[@][^ ]+/ ) {
            # kijitora@notes.example.jp
            if( $v->{'recipient'} ) {
                # There are multiple recipient addresses in the message body.
                push @$dscontents, __PACKAGE__->DELIVERYSTATUS;
                $v = $dscontents->[-1];
            }
            $v->{'recipient'} ||= $e;
            $recipients++;

        } else {
            next if $e eq '';
            next if index($e, '-') == 0;

            if( $e =~ /[^\x20-\x7e]/ ) {
                # Error message is not ISO-8859-1
                $encodedmsg = $e;
                if( $characters ) {
                    # Try to convert string
                    eval { Encode::from_to($encodedmsg, $characters, 'utf8'); };
                    $encodedmsg = $removedmsg if $@;    # Failed to convert

                } else {
                    # No character set in Content-Type header
                    $encodedmsg = $removedmsg;
                }
                $v->{'diagnosis'} .= $encodedmsg;

            } else {
                # Error message does not include multi-byte character
                $v->{'diagnosis'} .= $e;
            }
        }
    }

    unless( $recipients ) {
        # Fallback: Get the recpient address from RFC822 part
        if( $emailsteak->[1] =~ /^To:[ ]*(.+)$/m ) {
            $v->{'recipient'} = Sisimai::Address->s3s4($1);
            $recipients++ if $v->{'recipient'};
        }
    }
    return undef unless $recipients;

    for my $e ( @$dscontents ) {
        $e->{'diagnosis'} = Sisimai::String->sweep($e->{'diagnosis'});
        $e->{'recipient'} = Sisimai::Address->s3s4($e->{'recipient'});

        for my $r ( keys %$messagesof ) {
            # Check each regular expression of Notes error messages
            next unless grep { index($e->{'diagnosis'}, $_) > -1 } @{ $messagesof->{ $r } };
            $e->{'reason'} = $r;
            $e->{'status'} = Sisimai::SMTP::Status->code($r) || '';
            last;
        }
    }
    return { 'ds' => $dscontents, 'rfc822' => $emailsteak->[1] };
}

1;
__END__

=encoding utf-8

=head1 NAME

Sisimai::Lhost::Notes - bounce mail parser class for C<Lotus Notes Server>.

=head1 SYNOPSIS

    use Sisimai::Lhost::Notes;

=head1 DESCRIPTION

Sisimai::Lhost::Notes parses a bounce email which created by
C<Lotus Notes Server>.
Methods in the module are called from only Sisimai::Message.

=head1 CLASS METHODS

=head2 C<B<description()>>

C<description()> returns description string of this module.

    print Sisimai::Lhost::Notes->description;

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

