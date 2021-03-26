package Sisimai::Lhost::MailRu;
use parent 'Sisimai::Lhost';
use feature ':5.10';
use strict;
use warnings;

# Based on Sisimai::Lhost::Exim
sub description { '@mail.ru: https://mail.ru' }
sub make {
    # Detect an error from @mail.ru
    # @param    [Hash] mhead    Message headers of a bounce email
    # @param    [String] mbody  Message body of a bounce email
    # @return   [Hash]          Bounce data list and message/rfc822 part
    # @return   [Undef]         failed to parse or the arguments are missing
    # @since v4.1.4
    my $class = shift;
    my $mhead = shift // return undef;
    my $mbody = shift // return undef;

    # Message-Id: <E1P1YNN-0003AD-Ga@*.mail.ru>
    return undef unless lc($mhead->{'from'}) =~ /[<]?mailer-daemon[@].*mail[.]ru[>]?/;
    return undef unless $mhead->{'message-id'} =~ /[.](?:mail[.]ru|smailru[.]net)[>]\z/;
    return undef unless $mhead->{'subject'} =~ qr{(?:
         Mail[ ]delivery[ ]failed(:[ ]returning[ ]message[ ]to[ ]sender)?
        |Warning:[ ]message[ ].+[ ]delayed[ ]+
        |Delivery[ ]Status[ ]Notification
        |Mail[ ]failure
        |Message[ ]frozen
        |error[(]s[)][ ]in[ ]forwarding[ ]or[ ]filtering
        )
    }x;

    state $indicators = __PACKAGE__->INDICATORS;
    state $rebackbone = qr|^------ This is a copy of the message, including all the headers[.] ------|m;
    state $startingof = { 'message' => ['This message was created automatically by mail delivery software.'] };
    state $recommands = [
        qr/SMTP error from remote (?:mail server|mailer) after ([A-Za-z]{4})/,
        qr/SMTP error from remote (?:mail server|mailer) after end of ([A-Za-z]{4})/,
    ];
    state $messagesof = {
        'expired'     => [
            'retry timeout exceeded',
            'No action is required on your part',
        ],
        'userunknown' => ['user not found'],
        'hostunknown' => [
            'all host address lookups failed permanently',
            'all relevant MX records point to non-existent hosts',
            'Unrouteable address',
        ],
        'mailboxfull' => [
            'mailbox is full',
            'error: quota exceed',
        ],
        'notaccept'   => [
            'an MX or SRV record indicated no SMTP service',
            'no host found for existing SMTP connection',
        ],
        'systemerror' => [
            'delivery to file forbidden',
            'delivery to pipe forbidden',
            'local delivery failed',
        ],
        'contenterror'=> ['Too many "Received" headers '],
    };

    my $dscontents = [__PACKAGE__->DELIVERYSTATUS];
    my $emailsteak = Sisimai::RFC5322->fillet($mbody, $rebackbone);
    my $readcursor = 0;     # (Integer) Points the current cursor position
    my $recipients = 0;     # (Integer) The number of 'Final-Recipient' header
    my $localhost0 = '';    # (String) Local MTA
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

        # Это письмо создано автоматически
        # сервером Mail.Ru, # отвечать на него не
        # нужно.
        #
        # К сожалению, Ваше письмо не может
        # быть# доставлено одному или нескольким
        # получателям:
        #
        # **********************
        #
        # This message was created automatically by mail delivery software.
        #
        # A message that you sent could not be delivered to one or more of its
        # recipients. This is a permanent error. The following address(es) failed:
        #
        #  kijitora@example.jp
        #    SMTP error from remote mail server after RCPT TO:<kijitora@example.jp>:
        #    host neko.example.jp [192.0.2.222]: 550 5.1.1 <kijitora@example.jp>... User Unknown
        $v = $dscontents->[-1];

        if( $e =~ /\A[ \t]+([^ \t]+[@][^ \t]+[.][a-zA-Z]+)\z/ ) {
            #   kijitora@example.jp
            if( $v->{'recipient'} ) {
                # There are multiple recipient addresses in the message body.
                push @$dscontents, __PACKAGE__->DELIVERYSTATUS;
                $v = $dscontents->[-1];
            }
            $v->{'recipient'} = $1;
            $recipients++;

        } elsif( scalar @$dscontents == $recipients ) {
            # Error message
            next unless length $e;
            $v->{'diagnosis'} .= $e.' ';

        } else {
            # Error message when email address above does not include '@'
            # and domain part.
            next unless $e =~ /\A[ \t]{4}/;
            $v->{'alterrors'} .= $e.' ';
        }
    }

    unless( $recipients ) {
        # Fallback for getting recipient addresses
        if( defined $mhead->{'x-failed-recipients'} ) {
            # X-Failed-Recipients: kijitora@example.jp
            my @rcptinhead = split(',', $mhead->{'x-failed-recipients'});
            $_ =~ y/ //d for @rcptinhead;
            $recipients = scalar @rcptinhead;

            for my $e ( @rcptinhead ) {
                # Insert each recipient address into @$dscontents
                $dscontents->[-1]->{'recipient'} = $e;
                next if scalar @$dscontents == $recipients;
                push @$dscontents, __PACKAGE__->DELIVERYSTATUS;
            }
        }
    }
    return undef unless $recipients;

    if( scalar @{ $mhead->{'received'} } ) {
        # Get the name of local MTA
        # Received: from marutamachi.example.org (c192128.example.net [192.0.2.128])
        $localhost0 = $1 if $mhead->{'received'}->[-1] =~ /from[ \t]([^ ]+) /;
    }

    for my $e ( @$dscontents ) {
        if( exists $e->{'alterrors'} && $e->{'alterrors'} ) {
            # Copy alternative error message
            $e->{'diagnosis'} ||= $e->{'alterrors'};
            if( index($e->{'diagnosis'}, '-') == 0 || substr($e->{'diagnosis'}, -2, 2) eq '__' ) {
                # Override the value of diagnostic code message
                $e->{'diagnosis'} = $e->{'alterrors'} if $e->{'alterrors'};
            }
            delete $e->{'alterrors'};
        }
        $e->{'diagnosis'} =  Sisimai::String->sweep($e->{'diagnosis'});
        $e->{'diagnosis'} =~ s/\b__.+\z//;

        unless( $e->{'rhost'} ) {
            # Get the remote host name
            # host neko.example.jp [192.0.2.222]: 550 5.1.1 <kijitora@example.jp>... User Unknown
            $e->{'rhost'} = $1 if $e->{'diagnosis'} =~ /host[ \t]+([^ \t]+)[ \t]\[.+\]:[ \t]/;

            unless( $e->{'rhost'} ) {
                if( scalar @{ $mhead->{'received'} } ) {
                    # Get localhost and remote host name from Received header.
                    my $r0 = $mhead->{'received'};
                    $e->{'rhost'} = pop @{ Sisimai::RFC5322->received($r0->[-1]) };
                }
            }
        }
        $e->{'lhost'} ||= $localhost0;

        unless( $e->{'command'} ) {
            # Get the SMTP command name for the session
            SMTP: for my $r ( @$recommands ) {
                # Verify each regular expression of SMTP commands
                next unless $e->{'diagnosis'} =~ $r;
                $e->{'command'} = uc $1;
                last;
            }

            REASON: while(1) {
                # Detect the reason of bounce
                if( $e->{'command'} eq 'MAIL' ) {
                    # MAIL | Connected to 192.0.2.135 but sender was rejected.
                    $e->{'reason'} = 'rejected';

                } elsif( $e->{'command'} eq 'HELO' || $e->{'command'} eq 'EHLO' ) {
                    # HELO | Connected to 192.0.2.135 but my name was rejected.
                    $e->{'reason'} = 'blocked';

                } else {
                    SESSION: for my $r ( keys %$messagesof ) {
                        # Verify each regular expression of session errors
                        next unless grep { index($e->{'diagnosis'}, $_) > -1 } @{ $messagesof->{ $r } };
                        $e->{'reason'} = $r;
                        last;
                    }
                }
                last;
            }
        }
        $e->{'command'} ||= '';
    }
    return { 'ds' => $dscontents, 'rfc822' => $emailsteak->[1] };
}

1;
__END__

=encoding utf-8

=head1 NAME

Sisimai::Lhost::MailRu - bounce mail parser class for C<@mail.ru>.

=head1 SYNOPSIS

    use Sisimai::Lhost::MailRu;

=head1 DESCRIPTION

Sisimai::Lhost::MailRu parses a bounce email which created by C<@mail.ru>.
Methods in the module are called from only Sisimai::Message.

=head1 CLASS METHODS

=head2 C<B<description()>>

C<description()> returns description string of this module.

    print Sisimai::Lhost::MailRu->description;

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
