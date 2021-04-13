package Sisimai::Rhost::ExchangeOnline;
use feature ':5.10';
use strict;
use warnings;

# https://technet.microsoft.com/en-us/library/bb232118
sub get {
    # Detect bounce reason from Exchange 2013 and Office 365
    # @param    [Sisimai::Data] argvs   Parsed email object
    # @return   [String]                The bounce reason for Exchange Online
    # @see      https://technet.microsoft.com/en-us/library/bb232118
    my $class = shift;
    my $argvs = shift // return undef;
    return $argvs->reason if $argvs->reason;

    state $statuslist = {
        '4.3.1'   => [{ 'reason' => 'systemfull', 'string' => 'Insufficient system resources' }],
        '4.3.2'   => [{ 'reason' => 'notaccept',  'string' => 'System not accepting network messages' }],
        '4.4.2'   => [{ 'reason' => 'blocked',    'string' => 'Connection dropped' }],
        '4.7.26'  => [{
            'reason' => 'securityerror',
            'string' => 'must pass either SPF or DKIM validation, this message is not signed'
        }],
        '5.0.0'   => [{ 'reason' => 'blocked',     'string' => 'HELO / EHLO requires domain address' }],
        '5.1.4'   => [{ 'reason' => 'systemerror', 'string' => 'Destination mailbox address ambiguous' }],
        '5.2.1'   => [{ 'reason' => 'suspend',     'string' => 'Mailbox cannot be accessed' }],
        '5.2.2'   => [{ 'reason' => 'mailboxfull', 'string' => 'Mailbox full' }],
        '5.2.3'   => [{ 'reason' => 'exceedlimit', 'string' => 'Message too large' }],
        '5.2.4'   => [{ 'reason' => 'systemerror', 'string' => 'Mailing list expansion problem' }],
        '5.2.14'  => [{ 'reason' => 'systemerror', 'string' => 'misconfigured forwarding address' }],
        '5.2.122' => [{ 'reason' => 'toomanyconn', 'string' => 'The recipient has exceeded their limit for' }],
        '5.3.3'   => [{ 'reason' => 'systemfull',  'string' => 'Unrecognized command' }],
        '5.3.4'   => [{ 'reason' => 'mesgtoobig',  'string' => 'Message too big for system' }],
        '5.3.5'   => [{ 'reason' => 'systemerror', 'string' => 'System incorrectly configured' }],
        '5.4.1'   => [{ 'reason' => 'rejected',    'string' => 'Recipient address rejected: Access denied' }],
        '5.4.11'  => [{ 'reason' => 'contenterror','string' => 'Agent generated message depth exceeded' }],
        '5.4.14'  => [{ 'reason' => 'networkerror','string' => 'Hop count exceeded' }],
        '5.4.310' => [{ 'reason' => 'systemerror', 'string' => 'does not exist'}], # DNS domain * does not exist
        '5.5.2'   => [{ 'reason' => 'syntaxerror', 'string' => 'Send hello first' }],
        '5.5.3'   => [{ 'reason' => 'syntaxerror', 'string' => 'Too many recipients' }],
        '5.5.4'   => [{ 'reason' => 'filtered',    'string' => 'Invalid domain name' }],
        '5.5.6'   => [{ 'reason' => 'contenterror','string' => 'Invalid message content' }],
        '5.7.1'   => [
            { 'reason' => 'securityerror', 'string' => 'Delivery not authorized' },
            { 'reason' => 'securityerror', 'string' => 'Client was not authenticated' },
            { 'reason' => 'norelaying',    'string' => 'Unable to relay' },
        ],
        '5.7.25'  => [{ 'reason' => 'blocked', 'string' => 'must have a reverse DNS record' }],
        '5.7.51'  => [{ 'reason' => 'blocked', 'string' => 'RestrictDomainsToIPAddresses or RestrictDomainsToCertificate' }],
        '5.7.506' => [{ 'reason' => 'blocked', 'string' => 'Bad HELO' }],
        '5.7.508' => [{ 'reason' => 'toomanyconn',  'string' => 'has exceeded permitted limits within ' }],
        '5.7.509' => [{ 'reason' => 'rejected',     'string' => 'does not pass DMARC verification' }],
        '5.7.510' => [{ 'reason' => 'notaccept',    'string' => 'does not accept email over IPv6' }],
        '5.7.511' => [{ 'reason' => 'blocked',      'string' => 'banned sender' }],
        '5.7.512' => [{ 'reason' => 'contenterror', 'string' => 'message must be RFC 5322' }],
    };
    state $restatuses = {
        qr/\A4[.]4[.][17]\z/ => [
            { 'reason' => 'expired', 'string' => ['Connection timed out', 'Message expired'] }
        ],
        qr/\A4[.]7[.][568]\d\d\z/ => [
            { 'reason' => 'securityerror', 'string' => ['Access denied, please try again later'] }
        ],
        qr/\A5[.]1[.][07]\z/ => [
            { 'reason' => 'rejected', 'string' => ['Sender denied', 'Invalid address'] }
        ],
        qr/\A5[.]1[.][123]\z/ => [{
            'reason' => 'userunknown',
            'string' => [
                'Bad destination mailbox address',
                'Invalid X.400 address',
                'Invalid recipient address',
            ]
        }],
        qr/\A5[.]4[.][46]\z/ => [{
            'reason' => 'networkerror',
            'string' => ['Invalid arguments', 'Routing loop detected'],
        }],
        qr/\A5[.]7[.][13]\z/ => [{
            'reason' => 'securityerror',
            'string' => ['Delivery not authorized', 'Not Authorized'],
        }],
        qr/\A5[.]7[.]50[1-3]\z/ => [{
            'reason' => 'spamdetected',
            'string' => [
                'Access denied, spam abuse detected',
                'Access denied, banned sender'
            ],
        }],
        qr/\A5[.]7[.]50[457]\z/ => [{
            'reason' => 'filtered',
            'string' => [
                'Recipient address rejected: Access denied',
                'Access denied, banned recipient',
                'Access denied, rejected by recipient'
            ]
        }],
        qr/\A5[.]7[.]6\d\d\z/ => [
            { 'reason' => 'blocked', 'string' => ['Access denied, banned sending IP '] }
        ],
        qr/\A5[.]7[.]7\d\d\z/ => [
            { 'reason' => 'toomanyconn', 'string' => ['Access denied, tenant has exceeded threshold'] }
        ],
    };
    state $messagesof = {
        # Copied and converted from Sisimai::Lhost::Exchange2007
        'expired'       => ['QUEUE.Expired'],
        'hostunknown'   => ['SMTPSEND.DNS.NonExistentDomain'],
        'mesgtoobig'    => ['RESOLVER.RST.RecipSizeLimit', 'RESOLVER.RST.RecipientSizeLimit'],
        'networkerror'  => ['SMTPSEND.DNS.MxLoopback'],
        'rejected'      => ['RESOLVER.RST.NotAuthorized'],
        'securityerror' => ['RESOLVER.RST.AuthRequired'],
        'systemerror'   => [
            'RESOLVER.ADR.Ambiguous',
            'RESOLVER.ADR.BadPrimary',
            'RESOLVER.ADR.InvalidInSmtp',
            'RESOLVER.FWD.NotFound',
        ],
        'toomanyconn'   => ['RESOLVER.ADR.RecipLimit', 'RESOLVER.ADR.RecipientLimit'],
        'userunknown'   => [
            'RESOLVER.ADR.RecipNotFound',
            'RESOLVER.ADR.RecipientNotFound',
            'RESOLVER.ADR.ExRecipNotFound',
            'RESOLVER.ADR.ExRecipientNotFound',
        ],
    };

    my $statuscode = $argvs->deliverystatus;
    my $statusmesg = $argvs->diagnosticcode;
    my $reasontext = '';

    for my $e ( keys %$statuslist ) {
        # Try to compare with each status code as a key
        next unless $statuscode eq $e;
        for my $f ( @{ $statuslist->{ $e } } ) {
            # Try to compare with each string of error messages
            next if index($statusmesg, $f->{'string'}) == -1;
            $reasontext = $f->{'reason'};
            last;
        }
        last if $reasontext;
    }
    return $reasontext if $reasontext;

    for my $e ( keys %$restatuses ) {
        # Try to compare with each string of delivery status codes
        next unless $statuscode =~ $e;
        for my $f ( @{ $restatuses->{ $e } } ) {
            # Try to compare with each string of error messages
            for my $g ( @{ $f->{'string'} } ) {
                next if index($statusmesg, $g) == -1;
                $reasontext = $f->{'reason'};
                last;
            }
            last if $reasontext;
        }
        last if $reasontext;
    }
    return $reasontext if $reasontext;

    # D.S.N. included in the error message did not matched with any key
    # in statuslist, restatuses
    for my $e ( keys %$messagesof ) {
        # Try to compare with error messages defined in MessagesOf
        for my $f ( @{ $messagesof->{ $e } } ) {
            next if index($statusmesg, $f) == -1;
            $reasontext = $e;
            last;
        }
        last if $reasontext;
    }
    return $reasontext;
}

1;
__END__

=encoding utf-8

=head1 NAME

Sisimai::Rhost::ExchangeOnline - Detect the bounce reason returned from on-premises
Exchange 2013 and Office 365.

=head1 SYNOPSIS

    use Sisimai::Rhost;

=head1 DESCRIPTION

Sisimai::Rhost detects the bounce reason from the content of Sisimai::Data
object as an argument of get() method when the value of C<rhost> of the object
is "*.protection.outlook.com". This class is called only Sisimai::Data class.

=head1 CLASS METHODS

=head2 C<B<get(I<Sisimai::Data Object>)>>

C<get()> detects the bounce reason.

=head1 AUTHOR

azumakuniyuki

=head1 COPYRIGHT

Copyright (C) 2016-2021 azumakuniyuki, All rights reserved.

=head1 LICENSE

This software is distributed under The BSD 2-Clause License.

=cut

