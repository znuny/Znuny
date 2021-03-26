package Sisimai::Lhost::MailFoundry;
use parent 'Sisimai::Lhost';
use feature ':5.10';
use strict;
use warnings;

sub description { 'MailFoundry' }
sub make {
    # Detect an error from MailFoundry
    # @param    [Hash] mhead    Message headers of a bounce email
    # @param    [String] mbody  Message body of a bounce email
    # @return   [Hash]          Bounce data list and message/rfc822 part
    # @return   [Undef]         failed to parse or the arguments are missing
    # @since v4.1.1
    my $class = shift;
    my $mhead = shift // return undef;
    my $mbody = shift // return undef;

    return undef unless $mhead->{'subject'} eq 'Message delivery has failed';
    return undef unless grep { rindex($_, '(MAILFOUNDRY) id') > -1 } @{ $mhead->{'received'} };

    state $indicators = __PACKAGE__->INDICATORS;
    state $rebackbone = qr|^Content-Type:[ ]message/rfc822|m;
    state $startingof = {
        'message' => ['Unable to deliver message to:'],
        'error'   => ['Delivery failed for the following reason:'],
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
            $readcursor |= $indicators->{'deliverystatus'} if index($e, $startingof->{'message'}->[0]) == 0;
        }
        next unless $readcursor & $indicators->{'deliverystatus'};
        next unless length $e;

        # Unable to deliver message to: <kijitora@example.org>
        # Delivery failed for the following reason:
        # Server mx22.example.org[192.0.2.222] failed with: 550 <kijitora@example.org> No such user here
        #
        # This has been a permanent failure.  No further delivery attempts will be made.
        $v = $dscontents->[-1];

        if( $e =~ /\AUnable to deliver message to: [<]([^ ]+[@][^ ]+)[>]\z/ ) {
            # Unable to deliver message to: <kijitora@example.org>
            if( $v->{'recipient'} ) {
                # There are multiple recipient addresses in the message body.
                push @$dscontents, __PACKAGE__->DELIVERYSTATUS;
                $v = $dscontents->[-1];
            }
            $v->{'recipient'} = $1;
            $recipients++;

        } else {
            # Error message
            if( $e eq $startingof->{'error'}->[0] ) {
                # Delivery failed for the following reason:
                $v->{'diagnosis'} = $e;

            } else {
                # Detect error message
                next unless length $e;
                next unless $v->{'diagnosis'};
                next if index($e, '-') == 0;

                # Server mx22.example.org[192.0.2.222] failed with: 550 <kijitora@example.org> No such user here
                $v->{'diagnosis'} .= ' '.$e;
            }
        }
    }
    return undef unless $recipients;

    for my $e ( @$dscontents ) {
        # Set default values if each value is empty.
        $e->{'diagnosis'} = Sisimai::String->sweep($e->{'diagnosis'});
    }
    return { 'ds' => $dscontents, 'rfc822' => $emailsteak->[1] };
}

1;
__END__

=encoding utf-8

=head1 NAME

Sisimai::Lhost::MailFoundry - bounce mail parser class for C<MailFoundry>.

=head1 SYNOPSIS

    use Sisimai::Lhost::MailFoundry;

=head1 DESCRIPTION

Sisimai::Lhost::MailFoundry parses a bounce email which created by C<MailFoundry>.
Methods in the module are called from only Sisimai::Message.

=head1 CLASS METHODS

=head2 C<B<description()>>

C<description()> returns description string of this module.

    print Sisimai::Lhost::MailFoundry->description;

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

