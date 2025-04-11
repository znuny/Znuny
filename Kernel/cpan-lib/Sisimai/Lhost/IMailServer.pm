package Sisimai::Lhost::IMailServer;
use parent 'Sisimai::Lhost';
use feature ':5.10';
use strict;
use warnings;

sub description { 'IPSWITCH IMail Server' }
sub make {
    # Detect an error from IMailServer
    # @param    [Hash] mhead    Message headers of a bounce email
    # @param    [String] mbody  Message body of a bounce email
    # @return   [Hash]          Bounce data list and message/rfc822 part
    # @return   [Undef]         failed to parse or the arguments are missing
    # @since v4.1.1
    my $class = shift;
    my $mhead = shift // return undef;
    my $mbody = shift // return undef;
    my $match = 0;

    # X-Mailer: <SMTP32 v8.22>
    $match ||= 1 if $mhead->{'subject'} =~ /\AUndeliverable Mail[ ]*\z/;
    $match ||= 1 if defined $mhead->{'x-mailer'} && index($mhead->{'x-mailer'}, '<SMTP32 v') == 0;
    return undef unless $match;

    state $rebackbone = qr|^Original[ ]message[ ]follows[.]|m;
    state $startingof = { 'error' => ['Body of message generated response:'] };
    state $recommands = {
        'conn' => qr/(?:SMTP connection failed,|Unexpected connection response from server:)/,
        'ehlo' => qr|Unexpected response to EHLO/HELO:|,
        'mail' => qr|Server response to MAIL FROM:|,
        'rcpt' => qr|Additional RCPT TO generated following response:|,
        'data' => qr|DATA command generated response:|,
    };
    state $refailures = {
        'hostunknown'   => qr/Unknown host/,
        'userunknown'   => qr/\A(?:Unknown user|Invalid final delivery userid)/,
        'mailboxfull'   => qr/\AUser mailbox exceeds allowed size/,
        'virusdetected' => qr/\ARequested action not taken: virus detected/,
        'undefined'     => qr/\Aundeliverable to/,
        'expired'       => qr/\ADelivery failed \d+ attempts/,
    };

    my $dscontents = [__PACKAGE__->DELIVERYSTATUS];
    my $emailsteak = Sisimai::RFC5322->fillet($mbody, $rebackbone);
    my $recipients = 0;     # (Integer) The number of 'Final-Recipient' header
    my $v = undef;

    for my $e ( split("\n", $emailsteak->[0]) ) {
        # Read error messages and delivery status lines from the head of the email
        # to the previous line of the beginning of the original message.

        # Unknown user: kijitora@example.com
        #
        # Original message follows.
        $v = $dscontents->[-1];

        if( $e =~ /\A([^ ]+)[ ](.+)[:][ \t]*([^ ]+[@][^ ]+)/ ) {
            # Unknown user: kijitora@example.com
            if( $v->{'recipient'} ) {
                # There are multiple recipient addresses in the message body.
                push @$dscontents, __PACKAGE__->DELIVERYSTATUS;
                $v = $dscontents->[-1];
            }
            $v->{'diagnosis'} = $1.' '.$2;
            $v->{'recipient'} = $3;
            $recipients++;

        } elsif( $e =~ /\Aundeliverable[ ]+to[ ]+(.+)\z/ ) {
            # undeliverable to kijitora@example.com
            if( $v->{'recipient'} ) {
                # There are multiple recipient addresses in the message body.
                push @$dscontents, __PACKAGE__->DELIVERYSTATUS;
                $v = $dscontents->[-1];
            }
            $v->{'recipient'} = Sisimai::Address->s3s4($1);
            $recipients++;

        } else {
            # Other error message text
            $v->{'alterrors'} //= '';
            $v->{'alterrors'}  .= ' '.$e if $v->{'alterrors'};
            $v->{'alterrors'}   = $e if index($e, $startingof->{'error'}->[0]) > -1;
        }
    }
    return undef unless $recipients;

    for my $e ( @$dscontents ) {
        if( exists $e->{'alterrors'} && $e->{'alterrors'} ) {
            # Copy alternative error message
            $e->{'diagnosis'} = $e->{'alterrors'}.' '.$e->{'diagnosis'};
            $e->{'diagnosis'} = Sisimai::String->sweep($e->{'diagnosis'});
            delete $e->{'alterrors'};
        }
        $e->{'diagnosis'} = Sisimai::String->sweep($e->{'diagnosis'});

        COMMAND: for my $r ( keys %$recommands ) {
            # Detect SMTP command from the message
            next unless $e->{'diagnosis'} =~ $recommands->{ $r };
            $e->{'command'} = uc $r;
            last;
        }

        SESSION: for my $r ( keys %$refailures ) {
            # Verify each regular expression of session errors
            next unless $e->{'diagnosis'} =~ $refailures->{ $r };
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

Sisimai::Lhost::IMailServer - bounce mail parser class for C<IMail Server>.

=head1 SYNOPSIS

    use Sisimai::Lhost::IMailServer;

=head1 DESCRIPTION

Sisimai::Lhost::IMailServer parses a bounce email which created by
C<Ipswitch IMail Server>. Methods in the module are called from only
Sisimai::Message.

=head1 CLASS METHODS

=head2 C<B<description()>>

C<description()> returns description string of this module.

    print Sisimai::Lhost::IMailServer->description;

=head2 C<B<make(I<header data>, I<reference to body string>)>>

C<make()> method parses a bounced email and return results as a array reference.
See Sisimai::Message for more details.

=head1 AUTHOR

azumakuniyuki

=head1 COPYRIGHT

Copyright (C) 2014-2022 azumakuniyuki, All rights reserved.

=head1 LICENSE

This software is distributed under The BSD 2-Clause License.

=cut

