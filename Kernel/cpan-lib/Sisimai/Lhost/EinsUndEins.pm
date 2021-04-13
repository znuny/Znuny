package Sisimai::Lhost::EinsUndEins;
use parent 'Sisimai::Lhost';
use feature ':5.10';
use strict;
use warnings;

# X-UI-Out-Filterresults: unknown:0;
sub description { '1&1: https://www.1und1.de/' }
sub make {
    # Detect an error from 1&1
    # @param    [Hash] mhead    Message headers of a bounce email
    # @param    [String] mbody  Message body of a bounce email
    # @return   [Hash]          Bounce data list and message/rfc822 part
    # @return   [Undef]         failed to parse or the arguments are missing
    # @since v4.1.9
    my $class = shift;
    my $mhead = shift // return undef;
    my $mbody = shift // return undef;

    return undef unless index($mhead->{'from'}, '"Mail Delivery System"') == 0;
    return undef unless $mhead->{'subject'} eq 'Mail delivery failed: returning message to sender';

    state $indicators = __PACKAGE__->INDICATORS;
    state $rebackbone = qr|^---[ ]The[ ]header[ ]of[ ]the[ ]original[ ]message[ ]is[ ]following[.][ ]---|m;
    state $startingof = {
        'message' => ['This message was created automatically by mail delivery software'],
        'error'   => ['For the following reason:'],
    };
    state $messagesof = { 'mesgtoobig' => ['Mail size limit exceeded'] };

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

        # The following address failed:
        #
        # general@example.eu
        #
        # For the following reason:
        #
        # Mail size limit exceeded. For explanation visit
        # http://postmaster.1and1.com/en/error-messages?ip=%1s
        $v = $dscontents->[-1];

        if( $e =~ /\A([^ ]+[@][^ ]+?)[:]?\z/ ) {
            # general@example.eu
            if( $v->{'recipient'} ) {
                # There are multiple recipient addresses in the message body.
                push @$dscontents, __PACKAGE__->DELIVERYSTATUS;
                $v = $dscontents->[-1];
            }
            $v->{'recipient'} = $1;
            $recipients++;

        } elsif( index($e, $startingof->{'error'}->[0]) == 0 ) {
            # For the following reason:
            $v->{'diagnosis'} = $e;

        } else {
            if( length $v->{'diagnosis'} ) {
                # Get error message and append the error message strings
                $v->{'diagnosis'} .= ' '.$e;

            } else {
                # OR the following format:
                #   neko@example.fr:
                #   SMTP error from remote server for TEXT command, host: ...
                $v->{'alterrors'} .= ' '.$e;
            }
        }
    }
    return undef unless $recipients;

    for my $e ( @$dscontents ) {
        $e->{'diagnosis'} ||= $e->{'alterrors'} || '';

        if( $e->{'diagnosis'} =~ /host:[ ]+(.+?)[ ]+.+[ ]+reason:.+/ ) {
            # SMTP error from remote server for TEXT command,
            #   host: smtp-in.orange.fr (193.252.22.65)
            #   reason: 550 5.2.0 Mail rejete. Mail rejected. ofr_506 [506]
            $e->{'rhost'}   = $1;
            $e->{'command'} = 'DATA' if $e->{'diagnosis'} =~ /for TEXT command/;
            $e->{'spec'}    = 'SMTP' if $e->{'diagnosis'} =~ /SMTP error/;
            $e->{'status'}  = Sisimai::SMTP::Status->find($e->{'diagnosis'});
        } else {
            # For the following reason:
            $e->{'diagnosis'} =~ s/\A$startingof->{'error'}->[0]//g;
        }
        $e->{'diagnosis'} = Sisimai::String->sweep($e->{'diagnosis'});

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

Sisimai::Lhost::EinsUndEins - bounce mail parser class for C<1&1>.

=head1 SYNOPSIS

    use Sisimai::Lhost::EinsUndEins;

=head1 DESCRIPTION

Sisimai::Lhost::EinsUndEins parses a bounce email which created by C<1&1>.
Methods in the module are called from only Sisimai::Message.

=head1 CLASS METHODS

=head2 C<B<description()>>

C<description()> returns description string of this module.

    print Sisimai::Lhost::EinsUndEins->description;

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

