package Sisimai::Lhost::Office365;
use parent 'Sisimai::Lhost';
use feature ':5.10';
use strict;
use warnings;

sub description { 'Microsoft Office 365: https://office.microsoft.com/' }
sub make {
    # Detect an error from Microsoft Office 365
    # @param    [Hash] mhead    Message headers of a bounce email
    # @param    [String] mbody  Message body of a bounce email
    # @return   [Hash]          Bounce data list and message/rfc822 part
    # @return   [Undef]         failed to parse or the arguments are missing
    # @since v4.1.3
    my $class = shift;
    my $mhead = shift // return undef;
    my $mbody = shift // return undef;
    my $match = 0;
    my $tryto = qr/.+[.](?:outbound[.]protection|prod)[.]outlook[.]com\b/;

    # X-MS-Exchange-Message-Is-Ndr:
    # X-Microsoft-Antispam-PRVS: <....@...outlook.com>
    # X-Exchange-Antispam-Report-Test: UriScan:;
    # X-Exchange-Antispam-Report-CFA-Test:
    # X-MS-Exchange-CrossTenant-OriginalArrivalTime: 29 Apr 2015 23:34:45.6789 (JST)
    # X-MS-Exchange-CrossTenant-FromEntityHeader: Hosted
    # X-MS-Exchange-Transport-CrossTenantHeadersStamped: ...
    $match++ if index($mhead->{'subject'}, 'Undeliverable:') > -1;
    $match++ if $mhead->{'x-ms-exchange-message-is-ndr'};
    $match++ if $mhead->{'x-microsoft-antispam-prvs'};
    $match++ if $mhead->{'x-exchange-antispam-report-test'};
    $match++ if $mhead->{'x-exchange-antispam-report-cfa-test'};
    $match++ if $mhead->{'x-ms-exchange-crosstenant-originalarrivaltime'};
    $match++ if $mhead->{'x-ms-exchange-crosstenant-fromentityheader'};
    $match++ if $mhead->{'x-ms-exchange-transport-crosstenantheadersstamped'};
    $match++ if grep { $_ =~ $tryto } @{ $mhead->{'received'} };
    if( defined $mhead->{'message-id'} ) {
        # Message-ID: <00000000-0000-0000-0000-000000000000@*.*.prod.outlook.com>
        $match++ if $mhead->{'message-id'} =~ $tryto;
    }
    return undef if $match < 2;

    state $indicators = __PACKAGE__->INDICATORS;
    state $rebackbone = qr|^Content-Type:[ ]message/rfc822|m;
    state $markingsof = {
        'eoe'     => qr/\A(?:Original[ ][Mm]essage[ ][Hh]eaders:?|Message[ ]Hops)/,
        'error'   => qr/\A(?:Diagnostic[ ]information[ ]for[ ]administrators:|Error[ ]Details)/,
        'message' => qr{\A(?:
             Delivery[ ]has[ ]failed[ ]to[ ]these[ ]recipients[ ]or[ ]groups:
            |Original[ ]Message[ ]Details
            |.+[ ]rejected[ ]your[ ]message[ ]to[ ]the[ ]following[ ]e[-]?mail[ ]addresses:
            )
        }x,
    };
    state $statuslist = {
        # https://support.office.com/en-us/article/Email-non-delivery-reports-in-Office-365-51daa6b9-2e35-49c4-a0c9-df85bf8533c3
        qr/\A4[.]4[.]7\z/        => 'expired',
        qr/\A4[.]4[.]312\z/      => 'networkerror',
        qr/\A4[.]4[.]316\z/      => 'expired',
        qr/\A4[.]7[.]26\z/       => 'securityerror',
        qr/\A4[.]7[.][56]\d\d\z/ => 'blocked',
        qr/\A4[.]7[.]8[5-9]\d\z/ => 'blocked',
        qr/\A5[.]0[.]350\z/      => 'contenterror',
        qr/\A5[.]1[.]10\z/       => 'userunknown',
        qr/\A5[.]4[.]1\z/        => 'norelaying',
        qr/\A5[.]4[.]6\z/        => 'networkerror',
        qr/\A5[.]4[.]312\z/      => 'networkerror',
        qr/\A5[.]4[.]316\z/      => 'expired',
        qr/\A5[.]6[.]11\z/       => 'contenterror',
        qr/\A5[.]7[.]1\z/        => 'rejected',
        qr/\A5[.]7[.]1[23]\z/    => 'rejected',
        qr/\A5[.]7[.]124\z/      => 'rejected',
        qr/\A5[.]7[.]13[3-6]\z/  => 'rejected',
        qr/\A5[.]7[.]23\z/       => 'blocked',
        qr/\A5[.]7[.]25\z/       => 'networkerror',
        qr/\A5[.]7[.]50[1-3]\z/  => 'spamdetected',
        qr/\A5[.]7[.]50[4-5]\z/  => 'filtered',
        qr/\A5[.]7[.]50[6-7]\z/  => 'blocked',
        qr/\A5[.]7[.]508\z/      => 'toomanyconn',
        qr/\A5[.]7[.]509\z/      => 'securityerror',
        qr/\A5[.]7[.]510\z/      => 'notaccept',
        qr/\A5[.]7[.]511\z/      => 'rejected',
        qr/\A5[.]7[.]512\z/      => 'securityerror',
        qr/\A5[.]7[.]57\z/       => 'securityerror',
        qr/\A5[.]7[.]60[6-9]\z/  => 'blocked',
        qr/\A5[.]7[.]6[1-4]\d\z/ => 'blocked',
        qr/\A5[.]7[.]7[0-4]\d\z/ => 'toomanyconn',
    };
    state $recommands = {
        'RCPT' => qr/unknown recipient or mailbox unavailable ->.+[<]?.+[@].+[.][a-zA-Z]+[>]?/,
    };

    require Sisimai::RFC1894;
    my $fieldtable = Sisimai::RFC1894->FIELDTABLE;
    my $permessage = {};    # (Hash) Store values of each Per-Message field
    my $dscontents = [__PACKAGE__->DELIVERYSTATUS];
    my $emailsteak = Sisimai::RFC5322->fillet($mbody, $rebackbone);
    my $readcursor = 0;     # (Integer) Points the current cursor position
    my $recipients = 0;     # (Integer) The number of 'Final-Recipient' header
    my $endoferror = 0;     # (Integer) Flag for the end of error messages
    my $v = undef;

    for my $e ( split("\n", $emailsteak->[0]) ) {
        # Read error messages and delivery status lines from the head of the email
        # to the previous line of the beginning of the original message.
        unless( $readcursor ) {
            # Beginning of the bounce message or message/delivery-status part
            $readcursor |= $indicators->{'deliverystatus'} if $e =~ $markingsof->{'message'};
            next;
        }
        next unless $readcursor & $indicators->{'deliverystatus'};
        next unless length $e;

        # kijitora@example.com<mailto:kijitora@example.com>
        # The email address wasn't found at the destination domain. It might
        # be misspelled or it might not exist any longer. Try retyping the
        # address and resending the message.
        #
        # Original Message Details
        # Created Date:   4/29/2017 6:40:30 AM
        # Sender Address: neko@example.jp
        # Recipient Address:      kijitora@example.org
        # Subject:        Nyaan
        $v = $dscontents->[-1];
        if( $e =~ /\A.+[@].+[<]mailto:(.+[@].+)[>]\z/ ||
            $e =~ /\ARecipient[ ]Address:[ ]+(.+)\z/ ) {
            # kijitora@example.com<mailto:kijitora@example.com>
            if( $v->{'recipient'} ) {
                # There are multiple recipient addresses in the message body.
                push @$dscontents, __PACKAGE__->DELIVERYSTATUS;
                $v = $dscontents->[-1];
            }
            $v->{'recipient'} = $1;
            $recipients++;

        } elsif( $e =~ /\AGenerating server: (.+)\z/ ) {
            # Generating server: FFFFFFFFFFFF.e0.prod.outlook.com
            $permessage->{'lhost'} = lc $1;

        } else {
            if( $endoferror ) {
                # After "Original message headers:"
                next unless my $f = Sisimai::RFC1894->match($e);
                next unless my $o = Sisimai::RFC1894->field($e);
                next unless exists $fieldtable->{ $o->[0] };
                next if $o->[0] =~ /\A(?:diagnostic-code|final-recipient)\z/;
                $v->{ $fieldtable->{ $o->[0] } } = $o->[2];

                next unless $f == 1;
                $permessage->{ $fieldtable->{ $o->[0] } } = $o->[2];

            } else {
                if( $e =~ $markingsof->{'error'} ) {
                    # Diagnostic information for administrators:
                    $v->{'diagnosis'} = $e;
                } else {
                    # kijitora@example.com
                    # Remote Server returned '550 5.1.10 RESOLVER.ADR.RecipientNotFound; Recipien=
                    # t not found by SMTP address lookup'
                    next unless $v->{'diagnosis'};
                    if( $e =~ $markingsof->{'eoe'} ) {
                        # Original message headers:
                        $endoferror = 1;
                        next;
                    }
                    $v->{'diagnosis'} .= ' '.$e;
                }
            }
        }
    }
    return undef unless $recipients;

    for my $e ( @$dscontents ) {
        # Set default values if each value is empty.
        $e->{ $_ } ||= $permessage->{ $_ } || '' for keys %$permessage;
        $e->{'diagnosis'} = Sisimai::String->sweep($e->{'diagnosis'});

        if( ! $e->{'status'} || substr($e->{'status'}, -4, 4) eq '.0.0' ) {
            # There is no value of Status header or the value is 5.0.0, 4.0.0
            $e->{'status'} = Sisimai::SMTP::Status->find($e->{'diagnosis'}) || $e->{'status'};
        }

        for my $p ( keys %$recommands ) {
            # Try to match with regular expressions defined in recommands
            next unless $e->{'diagnosis'} =~ $recommands->{ $p };
            $e->{'command'} = $p;
            last;
        }

        # Find the error code from $statuslist
        next unless $e->{'status'};
        for my $f ( keys %$statuslist ) {
            # Try to match with each key as a regular expression
            next unless $e->{'status'} =~ $f;
            $e->{'reason'} = $statuslist->{ $f };
            last;
        }
    }
    return { 'ds' => $dscontents, 'rfc822' => $emailsteak->[1] };
}

1;
__END__

=encoding utf-8

=head1 NAME

Sisimai::Lhost::Office365 - bounce mail parser class for Microsoft Office 365.

=head1 SYNOPSIS

    use Sisimai::Lhost::Office365;

=head1 DESCRIPTION

Sisimai::Lhost::Office365 parses a bounce email which created by Microsoft
Office 365. Methods in the module are called from only Sisimai::Message.

=head1 CLASS METHODS

=head2 C<B<description()>>

C<description()> returns description string of this module.

    print Sisimai::Lhost::Office365->description;

=head2 C<B<make(I<header data>, I<reference to body string>)>>

C<make()> method parses a bounced email and return results as a array reference.
See Sisimai::Message for more details.

=head1 AUTHOR

azumakuniyuki

=head1 COPYRIGHT

Copyright (C) 2016-2020 azumakuniyuki, All rights reserved.

=head1 LICENSE

This software is distributed under The BSD 2-Clause License.

=cut

