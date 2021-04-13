package Sisimai::Lhost::PowerMTA;
use parent 'Sisimai::Lhost';
use feature ':5.10';
use strict;
use warnings;

sub description { 'PowerMTA: https://www.sparkpost.com/powermta/' }
sub make {
    # Detect an error from PowerMTA
    # @param    [Hash] mhead    Message headers of a bounce email
    # @param    [String] mbody  Message body of a bounce email
    # @return   [Hash]          Bounce data list and message/rfc822 part
    # @return   [Undef]         failed to parse or the arguments are missing
    # @since v4.25.6
    my $class = shift;
    my $mhead = shift // return undef;
    my $mbody = shift // return undef;
    return undef unless index($mhead->{'subject'}, 'Delivery report') > -1;

    state $indicators = __PACKAGE__->INDICATORS;
    state $rebackbone = qr|^Content-Type:[ ]text/rfc822-headers|m;
    state $startingof = { 'message' => ['Hello, this is the mail server on '] };
    state $categories = {
        'bad-domain'          => 'hostunknown',
        'bad-mailbox'         => 'userunknown',
        'inactive-mailbox'    => 'disabled',
        'message-expired'     => 'expired',
        'no-answer-from-host' => 'networkerror',
        'policy-related'      => 'policyviolation',
        'quota-issues'        => 'mailboxfull',
        'routing-errors'      => 'systemerror',
        'spam-related'        => 'spamdetected',
    };

    require Sisimai::RFC1894;
    my $fieldtable = Sisimai::RFC1894->FIELDTABLE;
    my $permessage = {};    # (Hash) Store values of each Per-Message field

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
            if( rindex($e, $startingof->{'message'}->[0]) > -1 ) {
                $readcursor |= $indicators->{'deliverystatus'};
                next;
            }
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
            # Hello, this is the mail server on neko2.example.org.
            #
            # I am sending you this message to inform you on the delivery status of a
            # message you previously sent.  Immediately below you will find a list of
            # the affected recipients;  also attached is a Delivery Status Notification
            # (DSN) report in standard format, as well as the headers of the original
            # message.
            #
            #  <kijitora@example.jp>  delivery failed; will not continue trying
            #
            if( $e =~ /\AX-PowerMTA-BounceCategory:[ ]*(.+)\z/ ) {
                # X-PowerMTA-BounceCategory: bad-mailbox
                $v->{'category'} = $1;
            }
        }
    }
    return undef unless $recipients;

    for my $e ( @$dscontents ) {
        # Set default values if each value is empty.
        $e->{ $_ } ||= $permessage->{ $_ } || '' for keys %$permessage;
        $e->{'diagnosis'} = Sisimai::String->sweep($e->{'diagnosis'});
        $e->{'reason'}    = $categories->{ $e->{'category'} } || '';
    }
    return { 'ds' => $dscontents, 'rfc822' => $emailsteak->[1] };
}

1;
__END__

=encoding utf-8

=head1 NAME

Sisimai::Lhost::PowerMTA - bounce mail parser class for C<PowerMTA>.

=head1 SYNOPSIS

    use Sisimai::Lhost::PowerMTA;

=head1 DESCRIPTION

Sisimai::Lhost::PowerMTA parses a bounce email which created by C<PowerMTA>.
Methods in the module are called from only Sisimai::Message.

=head1 CLASS METHODS

=head2 C<B<description()>>

C<description()> returns description string of this module.

    print Sisimai::Lhost::PowerMTA->description;

=head2 C<B<make(I<header data>, I<reference to body string>)>>

C<make()> method parses a bounced email and return results as a array reference.
See Sisimai::Message for more details.

=head1 AUTHOR

azumakuniyuki

=head1 COPYRIGHT

Copyright (C) 2020 azumakuniyuki, All rights reserved.

=head1 LICENSE

This software is distributed under The BSD 2-Clause License.

=cut

