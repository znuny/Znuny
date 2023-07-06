package Sisimai::Reason::SpamDetected;
use feature ':5.10';
use strict;
use warnings;

sub text  { 'spamdetected' }
sub description { 'Email rejected by spam filter running on the remote host' }
sub match {
    # Try to match that the given text and regular expressions
    # @param    [String] argv1  String to be matched with regular expressions
    # @return   [Integer]       0: Did not match
    #                           1: Matched
    # @since v4.1.19
    my $class = shift;
    my $argv1 = shift // return undef;

    state $regex = qr{(?>
         ["]the[ ]mail[ ]server[ ]detected[ ]your[ ]message[ ]as[ ]spam[ ]and[ ]
            has[ ]prevented[ ]delivery[.]["]    # CPanel/Exim with SA rejections on
        |(?:\d[.]\d[.]\d|\d{3})[ ]spam\z
        |554[ ]5[.]7[.]0[ ]reject,[ ]id=\d+
        |appears[ ]to[ ]be[ ]unsolicited
        |blacklisted[ ]url[ ]in[ ]message
        |block[ ]for[ ]spam
        |blocked[ ]by[ ](?:
             policy:[ ]no[ ]spam[ ]please
            |spamassassin                   # rejected by SpamAssassin
            )
        |blocked[ ]for[ ]abuse[.][ ]see[ ]http://att[.]net/blocks   # AT&T
        |bulk[ ]email
        |considered[ ]unsolicited[ ]bulk[ ]e-mail[ ][(]spam[)][ ]by[ ]our[ ]mail[ ]filters
        |content[ ]filter[ ]rejection
        |cyberoam[ ]anti[ ]spam[ ]engine[ ]has[ ]identified[ ]this[ ]email[ ]as[ ]a[ ]bulk[ ]email
        |denied[ ]due[ ]to[ ]spam[ ]list
        |greylisted.?.[ ]please[ ]try[ ]again[ ]in
        |high[ ]probability[ ]of[ ]spam
        |https?://(?:www[.]spamhaus[.]org|dsbl[.]org|mail[.]163[.]com/help/help_spam_16[.]htm)
        |listed[ ]in[ ]work[.]drbl[.]imedia[.]ru
        |mail[ ](?:
             appears[ ]to[ ]be[ ]unsolicited    # rejected due to spam
            |content[ ]denied   # http://service.mail.qq.com/cgi-bin/help?subtype=1&&id=20022&&no=1000726
            |rejete[.][ ]mail[ ]rejected[.][ ][0-9a-z_]+506
            )
        |may[ ]consider[ ]spam
        |message[ ](?:
             considered[ ]as[ ]spam[ ]or[ ]virus
            |contains[ ]spam[ ]or[ ]virus
            |content[ ]rejected
            |detected[ ]as[ ]spam
            |filtered
            |filtered[.][ ](?:
                 please[ ]see[ ]the[ ]faqs[ ]section[ ]on[ ]spam
                |refer[ ]to[ ]the[ ]troubleshooting[ ]page[ ]at[ ]
                )
            |is[ ]being[ ]rejected[ ]as[ ]it[ ]seems[ ]to[ ]be[ ]a[ ]spam
            |looks[ ]like[ ]spam
            |refused[ ]by[ ](?:
                 mailmarshal[ ]spamprofiler
                |trustwave[ ]seg[ ]spamprofiler
                )
            |rejected[ ](?:
                 as[ ]spam
                |because[ ]of[ ]unacceptable[ ]content
                |due[ ]to[ ]suspected[ ]spam[ ]content
                |for[ ]policy[ ]reasons
                )
            )
        |our[ ](?:
             email[ ]server[ ]thinks[ ]this[ ]email[ ]is[ ]spam
            |filters[ ]rate[ ]at[ ]and[ ]above[ ]\d+[ ]percent[ ]probability[ ]of[ ]being[ ]spam
            |system[ ]has[ ]detected[ ]that[ ]this[ ]message[ ]is
            )
        |probable[ ]spam
        |reject[ ]bulk[.]advertising
        |rejected(?:
             :[ ]spamassassin[ ]score[ ]
            |[ ]by[ ][^ ]+[ ][(]spam[)]
            |[ ]due[ ]to[ ]spam[ ](?:url[ ]in[ ])?(?:classification|content)
            )
        |rejecting[ ](?:banned|mail)[ ]content
        |related[ ]to[ ]content[ ]with[ ]spam[-]like[ ]characteristics
        |rule[ ]imposed[ ]as[ ][^ ]+[ ]is[ ]blacklisted[ ]on
        |sender[ ]domain[ ]listed[ ]at[ ][^ ]+
        |sending[ ]address[ ]not[ ]accepted[ ]due[ ]to[ ]spam[ ]filter
        |spam[ ](?:
             [^ ]+[ ]exceeded
            |blocked
            |check
            |content[ ]matched
            |detected
            |email
            |email[ ]not[ ]accepted
            |message[ ]rejected[.]       # mail.ru
            |not[ ]accepted
            |refused
            |rejection
            |reporting[ ]address    # SendGrid|a message to an address has previously been marked as Spam by the recipient.
            |score[ ]
            )
        |spambouncer[ ]identified[ ]spam    # SpamBouncer identified SPAM
        |spamming[ ]not[ ]allowed
        |too[ ]much[ ]spam[.]               # Earthlink
        |the[ ]email[ ]message[ ]was[ ]detected[ ]as[ ]spam
        |the[ ]message[ ](?:
             has[ ]been[ ]rejected[ ]by[ ]spam[ ]filtering[ ]engine
            |was[ ]rejected[ ]due[ ]to[ ]classification[ ]as[ ]bulk[ ]mail
            )
        |the[ ]content[ ]of[ ]this[ ]message[ ]looked[ ]like[ ]spam # SendGrid
        |this[ ](?:e-mail|mail)[ ](?:
             cannot[ ]be[ ]forwarded[ ]because[ ]it[ ]was[ ]detected[ ]as[ ]spam
            |is[ ]classified[ ]as[ ]spam[ ]and[ ]is[ ]rejected
            )
        |this[ ]message[ ](?:
             appears[ ]to[ ]be[ ]spam
            |has[ ]been[ ](?:
                 identified[ ]as[ ]spam
                |scored[ ]as[ ]spam[ ]with[ ]a[ ]probability
                )
            |scored[ ][^ ]+[ ]spam[ ]points
            |was[ ]classified[ ]as[ ]spam
            |was[ ]rejected[ ]by[ ]recurrent[ ]pattern[ ]detection[ ]system
            )
        |transaction[ ]failed[ ]spam[ ]message[ ]not[ ]queued       # SendGrid
        |we[ ]dont[ ]accept[ ]spam
        |you're[ ]using[ ]a[ ]mass[ ]mailer
        |your[ ](?:
             email[ ](?:
                 appears[ ]similar[ ]to[ ]spam[ ]we[ ]have[ ]received[ ]before
                |breaches[ ]local[ ]uribl[ ]policy
                |had[ ]spam[-]like[ ]
                |is[ ](?:considered|probably)[ ]spam
                |was[ ]detected[ ]as[ ]spam
                )
            |message[ ](?:
                 as[ ]spam[ ]and[ ]has[ ]prevented[ ]delivery
                |has[ ]been[ ](?:
                     temporarily[ ]blocked[ ]by[ ]our[ ]filter
                    |rejected[ ]because[ ]it[ ]appears[ ]to[ ]be[ ]spam
                    )
                |has[ ]triggered[ ]a[ ]spam[ ]block
                |may[ ]contain[ ]the[ ]spam[ ]contents
                |failed[ ]several[ ]antispam[ ]checks
                )
            )
        )
    }x;
    return 1 if $argv1 =~ $regex;
    return 0;
}

sub true {
    # Rejected due to spam content in the message
    # @param    [Sisimai::Data] argvs   Object to be detected the reason
    # @return   [Integer]               1: rejected due to spam
    #                                   0: is not rejected due to spam
    # @since v4.1.19
    # @see http://www.ietf.org/rfc/rfc2822.txt
    my $class = shift;
    my $argvs = shift // return undef;

    return undef unless $argvs->deliverystatus;
    return 1 if $argvs->reason eq 'spamdetected';
    return 1 if (Sisimai::SMTP::Status->name($argvs->deliverystatus) || '') eq 'spamdetected';

    # The value of "reason" isn't "spamdetected" when the value of "smtpcommand" is an SMTP command
    # to be sent before the SMTP DATA command because all the MTAs read the headers and the entire
    # message body after the DATA command.
    return 0 if $argvs->{'smtpcommand'} =~ /\A(?:CONN|EHLO|HELO|MAIL|RCPT)\z/;
    return 1 if __PACKAGE__->match(lc $argvs->diagnosticcode);
    return 0;
}

1;
__END__

=encoding utf-8

=head1 NAME

Sisimai::Reason::SpamDetected - Bounce reason is C<spamdetected> due to Spam
content in the message or not.

=head1 SYNOPSIS

    use Sisimai::Reason::SpamDetected;
    print Sisimai::Reason::SpamDetected->match('550 spam detected');   # 1

=head1 DESCRIPTION

Sisimai::Reason::SpamDetected checks the bounce reason is C<spamdetected> due to
Spam content in the message or not. This class is called only Sisimai::Reason
class.

This is the error that the message you sent was rejected by C<spam> filter which
is running on the remote host. This reason has added in Sisimai 4.1.25 and does
not exist in any version of bounceHammer.

    Action: failed
    Status: 5.7.1
    Diagnostic-Code: smtp; 550 5.7.1 Message content rejected, UBE, id=00000-00-000
    Last-Attempt-Date: Thu, 9 Apr 2008 23:34:45 +0900 (JST)

=head1 CLASS METHODS

=head2 C<B<text()>>

C<text()> returns string: C<spamdetected>.

    print Sisimai::Reason::SpamDetected->text;  # spamdetected

=head2 C<B<match(I<string>)>>

C<match()> returns 1 if the argument matched with patterns defined in this class.

    print Sisimai::Reason::SpamDetected->match('550 Spam detected');   # 1

=head2 C<B<true(I<Sisimai::Data>)>>

C<true()> returns 1 if the bounce reason is C<rejected> due to Spam content in
the message. The argument must be Sisimai::Data object and this method is called
only from Sisimai::Reason class.

=head1 AUTHOR

azumakuniyuki

=head1 COPYRIGHT

Copyright (C) 2015-2018,2020-2022 azumakuniyuki, All rights reserved.

=head1 LICENSE

This software is distributed under The BSD 2-Clause License.

=cut

