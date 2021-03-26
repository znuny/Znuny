package Sisimai::Lhost::Amavis;
use parent 'Sisimai::Lhost';
use feature ':5.10';
use strict;
use warnings;

# https://www.amavis.org
sub description { 'amavisd-new: https://www.amavis.org/' }
sub make {
    # Detect an error from amavisd-new
    # @param    [Hash] mhead    Message headers of a bounce email
    # @param    [String] mbody  Message body of a bounce email
    # @return   [Hash]          Bounce data list and message/rfc822 part
    # @return   [Undef]         failed to parse or the arguments are missing
    # @since v4.25.0
    my $class = shift;
    my $mhead = shift // return undef;
    my $mbody = shift // return undef;

    # From: "Content-filter at neko1.example.jp" <postmaster@neko1.example.jp>
    # Subject: Undeliverable mail, MTA-BLOCKED
    return undef unless index($mhead->{'from'}, '"Content-filter at ') == 0;

    state $indicators = __PACKAGE__->INDICATORS;
    state $rebackbone = qr|^Content-Type:[ ]text/rfc822-headers|m;
    state $startingof = { 'message' => ['The message '] };
    state $messagesof = {
        # amavisd-new-2.11.1/amavisd:1840|%smtp_reason_by_ccat = (
        # amavisd-new-2.11.1/amavisd:1840|  # currently only used for blocked messages only, status 5xx
        # amavisd-new-2.11.1/amavisd:1840|  # a multiline message will produce a valid multiline SMTP response
        # amavisd-new-2.11.1/amavisd:1840|  CC_VIRUS,       'id=%n - INFECTED: %V',
        # amavisd-new-2.11.1/amavisd:1840|  CC_BANNED,      'id=%n - BANNED: %F',
        # amavisd-new-2.11.1/amavisd:1840|  CC_UNCHECKED.',1', 'id=%n - UNCHECKED: encrypted',
        # amavisd-new-2.11.1/amavisd:1840|  CC_UNCHECKED.',2', 'id=%n - UNCHECKED: over limits',
        # amavisd-new-2.11.1/amavisd:1840|  CC_UNCHECKED,      'id=%n - UNCHECKED',
        # amavisd-new-2.11.1/amavisd:1840|  CC_SPAM,        'id=%n - spam',
        # amavisd-new-2.11.1/amavisd:1840|  CC_SPAMMY.',1', 'id=%n - spammy (tag3)',
        # amavisd-new-2.11.1/amavisd:1840|  CC_SPAMMY,      'id=%n - spammy',
        # amavisd-new-2.11.1/amavisd:1840|  CC_BADH.',1',   'id=%n - BAD HEADER: MIME error',
        # amavisd-new-2.11.1/amavisd:1840|  CC_BADH.',2',   'id=%n - BAD HEADER: nonencoded 8-bit character',
        # amavisd-new-2.11.1/amavisd:1840|  CC_BADH.',3',   'id=%n - BAD HEADER: contains invalid control character',
        # amavisd-new-2.11.1/amavisd:1840|  CC_BADH.',4',   'id=%n - BAD HEADER: line made up entirely of whitespace',
        # amavisd-new-2.11.1/amavisd:1840|  CC_BADH.',5',   'id=%n - BAD HEADER: line longer than RFC 5322 limit',
        # amavisd-new-2.11.1/amavisd:1840|  CC_BADH.',6',   'id=%n - BAD HEADER: syntax error',
        # amavisd-new-2.11.1/amavisd:1840|  CC_BADH.',7',   'id=%n - BAD HEADER: missing required header field',
        # amavisd-new-2.11.1/amavisd:1840|  CC_BADH.',8',   'id=%n - BAD HEADER: duplicate header field',
        # amavisd-new-2.11.1/amavisd:1840|  CC_BADH,        'id=%n - BAD HEADER',
        # amavisd-new-2.11.1/amavisd:1840|  CC_OVERSIZED,   'id=%n - Message size exceeds recipient\'s size limit',
        # amavisd-new-2.11.1/amavisd:1840|  CC_MTA.',1',    'id=%n - Temporary MTA failure on relaying',
        # amavisd-new-2.11.1/amavisd:1840|  CC_MTA.',2',    'id=%n - Rejected by next-hop MTA on relaying',
        # amavisd-new-2.11.1/amavisd:1840|  CC_MTA,         'id=%n - Unable to relay message back to MTA',
        # amavisd-new-2.11.1/amavisd:1840|  CC_CLEAN,       'id=%n - CLEAN',
        # amavisd-new-2.11.1/amavisd:1840|  CC_CATCHALL,    'id=%n - OTHER',  # should not happen
        # ...
        # amavisd-new-2.11.1/amavisd:15289|my $status = setting_by_given_contents_category(
        # amavisd-new-2.11.1/amavisd:15289|  $blocking_ccat,
        # amavisd-new-2.11.1/amavisd:15289|  { CC_VIRUS,       "554 5.7.0",
        # amavisd-new-2.11.1/amavisd:15289|    CC_BANNED,      "554 5.7.0",
        # amavisd-new-2.11.1/amavisd:15289|    CC_UNCHECKED,   "554 5.7.0",
        # amavisd-new-2.11.1/amavisd:15289|    CC_SPAM,        "554 5.7.0",
        # amavisd-new-2.11.1/amavisd:15289|    CC_SPAMMY,      "554 5.7.0",
        # amavisd-new-2.11.1/amavisd:15289|    CC_BADH.",2",   "554 5.6.3",  # nonencoded 8-bit character
        # amavisd-new-2.11.1/amavisd:15289|    CC_BADH,        "554 5.6.0",
        # amavisd-new-2.11.1/amavisd:15289|    CC_OVERSIZED,   "552 5.3.4",
        # amavisd-new-2.11.1/amavisd:15289|    CC_MTA,         "550 5.3.5",
        # amavisd-new-2.11.1/amavisd:15289|    CC_CATCHALL,    "554 5.7.0",
        # amavisd-new-2.11.1/amavisd:15289|  });
        # ...
        # amavisd-new-2.11.1/amavisd:15332|my $response = sprintf("%s %s%s%s", $status,
        # amavisd-new-2.11.1/amavisd:15333|  ($final_destiny == D_PASS     ? "Ok" :
        # amavisd-new-2.11.1/amavisd:15334|   $final_destiny == D_DISCARD  ? "Ok, discarded" :
        # amavisd-new-2.11.1/amavisd:15335|   $final_destiny == D_REJECT   ? "Reject" :
        # amavisd-new-2.11.1/amavisd:15336|   $final_destiny == D_BOUNCE   ? "Bounce" :
        # amavisd-new-2.11.1/amavisd:15337|   $final_destiny == D_TEMPFAIL ? "Temporary failure" :
        # amavisd-new-2.11.1/amavisd:15338|                                  "Not ok ($final_destiny)" ),
        'spamdetected'  => [' - spam'],
        'virusdetected' => [' - infected'],
        'contenterror'  => [' - bad header:'],
        'exceedlimit'   => [' - message size exceeds recipient'],
        'systemerror'   => [
            ' - temporary mta failure on relaying',
            ' - rejected by next-hop mta on relaying',
            ' - unable to relay message back to mta',
        ],
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
            $readcursor |= $indicators->{'deliverystatus'} if index($e, $startingof->{'message'}->[0]) == 0;
            next;
        }
        next unless $readcursor & $indicators->{'deliverystatus'};
        next unless length $e;
        next unless my $f = Sisimai::RFC1894->match($e);

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
            $v->{'spec'} = 'SMTP' if $v->{'spec'} eq 'X-POSTFIX';
            $v->{'diagnosis'} = $o->[2];

        } else {
            # Other DSN fields defined in RFC3464
            next unless exists $fieldtable->{ $o->[0] };
            $v->{ $fieldtable->{ $o->[0] } } = $o->[2];

            next unless $f == 1;
            $permessage->{ $fieldtable->{ $o->[0] } } = $o->[2];
        }
    }
    return undef unless $recipients;

    for my $e ( @$dscontents ) {
        # Set default values if each value is empty.
        $e->{ $_ } ||= $permessage->{ $_ } || '' for keys %$permessage;
        $e->{'diagnosis'} ||= Sisimai::String->sweep($e->{'diagnosis'});
        my $q = lc $e->{'diagnosis'};
        DETECT_REASON: for my $p ( keys %$messagesof ) {
            # Try to detect an error reason
            for my $r ( @{ $messagesof->{ $p } } ) {
                # Try to find an error message including lower-cased string
                # defined in $messagesof
                next unless index($q, $r) > -1;
                $e->{'reason'} = $p;
                last(DETECT_REASON)
            }
        }
    }
    return { 'ds' => $dscontents, 'rfc822' => $emailsteak->[1] };
}

1;
__END__

=encoding utf-8

=head1 NAME

Sisimai::Lhost::Amavis - bounce mail parser class for C<amavisd-new>.

=head1 SYNOPSIS

    use Sisimai::Lhost::Amavis;

=head1 DESCRIPTION

Sisimai::Lhost::Amavis parses a bounce email which created by C<amavisd-new>.
Methods in the module are called from only Sisimai::Message.

=head1 CLASS METHODS

=head2 C<B<description()>>

C<description()> returns description string of this module.

    print Sisimai::Lhost::Amavis->description;

=head2 C<B<make(I<header data>, I<reference to body string>)>>

C<make()> method parses a bounced email and return results as a array reference.
See Sisimai::Message for more details.

=head1 AUTHOR

azumakuniyuki

=head1 COPYRIGHT

Copyright (C) 2019,2020 azumakuniyuki, All rights reserved.

=head1 LICENSE

This software is distributed under The BSD 2-Clause License.

=cut

