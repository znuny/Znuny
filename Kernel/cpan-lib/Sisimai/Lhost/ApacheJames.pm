package Sisimai::Lhost::ApacheJames;
use parent 'Sisimai::Lhost';
use feature ':5.10';
use strict;
use warnings;

sub description { 'Java Apache Mail Enterprise Server' }
sub make {
    # Detect an error from ApacheJames
    # @param    [Hash] mhead    Message headers of a bounce email
    # @param    [String] mbody  Message body of a bounce email
    # @return   [Hash]          Bounce data list and message/rfc822 part
    # @return   [Undef]         failed to parse or the arguments are missing
    # @since v4.1.26
    my $class = shift;
    my $mhead = shift // return undef;
    my $mbody = shift // return undef;
    my $match = 0;

    # 'subject'    => qr/\A\[BOUNCE\]\z/,
    # 'received'   => qr/JAMES SMTP Server/,
    # 'message-id' => qr/\d+[.]JavaMail[.].+[@]/,
    $match ||= 1 if $mhead->{'subject'} eq '[BOUNCE]';
    $match ||= 1 if defined $mhead->{'message-id'} && rindex($mhead->{'message-id'}, '.JavaMail.') > -1;
    $match ||= 1 if grep { rindex($_, 'JAMES SMTP Server') > -1 } @{ $mhead->{'received'} };
    return undef unless $match;

    state $indicators = __PACKAGE__->INDICATORS;
    state $rebackbone = qr|^Content-Type:[ ]message/rfc822|m;
    state $startingof = {
        # apache-james-2.3.2/src/java/org/apache/james/transport/mailets/
        #   AbstractNotify.java|124:  out.println("Error message below:");
        #   AbstractNotify.java|128:  out.println("Message details:");
        'message' => [''],
        'error'   => ['Error message below:'],
    };

    my $dscontents = [__PACKAGE__->DELIVERYSTATUS];
    my $emailsteak = Sisimai::RFC5322->fillet($mbody, $rebackbone);
    my $readcursor = 0;     # (Integer) Points the current cursor position
    my $recipients = 0;     # (Integer) The number of 'Final-Recipient' header
    my $diagnostic = '';    # (String) Alternative diagnostic message
    my $subjecttxt = undef; # (String) Alternative Subject text
    my $gotmessage = 0;     # (Integer) Flag for error message
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

        # Message details:
        #   Subject: Nyaaan
        #   Sent date: Thu Apr 29 01:20:50 JST 2015
        #   MAIL FROM: shironeko@example.jp
        #   RCPT TO: kijitora@example.org
        #   From: Neko <shironeko@example.jp>
        #   To: kijitora@example.org
        #   Size (in bytes): 1024
        #   Number of lines: 64
        $v = $dscontents->[-1];

        if( $e =~ /\A[ ][ ]RCPT[ ]TO:[ ]([^ ]+[@][^ ]+)\z/ ) {
            #   RCPT TO: kijitora@example.org
            if( $v->{'recipient'} ) {
                # There are multiple recipient addresses in the message body.
                push @$dscontents, __PACKAGE__->DELIVERYSTATUS;
                $v = $dscontents->[-1];
            }
            $v->{'recipient'} = $1;
            $recipients++;

        } elsif( $e =~ /\A[ ][ ]Sent[ ]date:[ ](.+)\z/ ) {
            #   Sent date: Thu Apr 29 01:20:50 JST 2015
            $v->{'date'} = $1;

        } elsif( $e =~ /\A[ ][ ]Subject:[ ](.+)\z/ ) {
            #   Subject: Nyaaan
            $subjecttxt = $1;

        } else {
            next if $gotmessage == 1;

            if( $v->{'diagnosis'} ) {
                # Get an error message text
                if( $e eq 'Message details:' ) {
                    # Message details:
                    #   Subject: nyaan
                    #   ...
                    $gotmessage = 1;

                } else {
                    # Append error message text like the followng:
                    #   Error message below:
                    #   550 - Requested action not taken: no such user here
                    $v->{'diagnosis'} .= ' '.$e;
                }
            } else {
                # Error message below:
                # 550 - Requested action not taken: no such user here
                $v->{'diagnosis'} = $e if $e eq $startingof->{'error'}->[0];
                $v->{'diagnosis'} .= ' '.$e unless $gotmessage;
            }
        }
    }
    return undef unless $recipients;

    # Set the value of $subjecttxt as a Subject if there is no original message
    # in the bounce mail.
    $emailsteak->[1] .= sprintf("Subject: %s\n", $subjecttxt) unless $emailsteak->[1] =~ /^Subject:/m;
    $_->{'diagnosis'} = Sisimai::String->sweep($_->{'diagnosis'} || $diagnostic) for @$dscontents;
    return { 'ds' => $dscontents, 'rfc822' => $emailsteak->[1] };
}

1;
__END__

=encoding utf-8

=head1 NAME

Sisimai::Lhost::ApacheJames - bounce mail parser class for C<ApacheJames>.

=head1 SYNOPSIS

    use Sisimai::Lhost::ApacheJames;

=head1 DESCRIPTION

Sisimai::Lhost::ApacheJames parses a bounce email which created by C<ApacheJames>.
Methods in the module are called from only Sisimai::Message.

=head1 CLASS METHODS

=head2 C<B<description()>>

C<description()> returns description string of this module.

    print Sisimai::Lhost::ApacheJames->description;

=head2 C<B<make(I<header data>, I<reference to body string>)>>

C<make()> method parses a bounced email and return results as a array reference.
See Sisimai::Message for more details.

=head1 AUTHOR

azumakuniyuki

=head1 COPYRIGHT

Copyright (C) 2015-2020 azumakuniyuki, All rights reserved.

=head1 LICENSE

This software is distributed under The BSD 2-Clause License.

=cut

