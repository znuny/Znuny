package Sisimai::Rhost::NTTDOCOMO;
use feature ':5.10';
use strict;
use warnings;

sub get {
    # Detect bounce reason from NTT DOCOMO
    # @param    [Sisimai::Data] argvs   Parsed email object
    # @return   [String]                The bounce reason for docomo.ne.jp
    # @since v4.25.15
    my $class = shift;
    my $argvs = shift // return undef;

    my $messagesof = {
        'mailboxfull' => qr/552 too much mail data/,
        'toomanyconn' => qr/552 too many recipients/,
        'syntaxerror' => qr/(?:503 bad sequence of commands|504 command parameter not implemented)/,
    };
    my $statuscode = $argvs->{'deliverystatus'}    || '';
    my $commandtxt = $argvs->{'smtpcommand'}       || '';
    my $esmtperror = lc $argvs->{'diagnosticcode'} || '';
    my $reasontext = '';

    # Check the value of Status: field, an SMTP Reply Code, and the SMTP Command
    if( $statuscode eq '5.1.1' || $statuscode eq '5.0.911' ) {
        #    ----- Transcript of session follows -----
        # ... while talking to mfsmax.docomo.ne.jp.:
        # >>> RCPT To:<***@docomo.ne.jp>
        # <<< 550 Unknown user ***@docomo.ne.jp
        # 550 5.1.1 <***@docomo.ne.jp>... User unknown
        # >>> DATA
        # <<< 503 Bad sequence of commands
        $reasontext = 'userunknown';

    } elsif( $statuscode eq '5.2.0' ) {
        #    ----- The following addresses had permanent fatal errors -----
        # <***@docomo.ne.jp>
        # (reason: 550 Unknown user ***@docomo.ne.jp)
        # 
        #    ----- Transcript of session follows -----
        # ... while talking to mfsmax.docomo.ne.jp.:
        # >>> DATA
        # <<< 550 Unknown user ***@docomo.ne.jp
        # 554 5.0.0 Service unavailable
        # ...
        # Final-Recipient: RFC822; ***@docomo.ne.jp
        # Action: failed
        # Status: 5.2.0
        $reasontext = 'filtered';

    } else {
        # The value of "Diagnostic-Code:" field is not empty
        for my $e ( keys %$messagesof ) {
            # Try to match the value of "diagnosticcode"
            next unless $esmtperror =~ $messagesof->{ $e };
            $reasontext = $e;
            last;
        }
    }
    return $reasontext if length $reasontext;

    # A bounce reason did not decide from a status code, an error message.
    if( $statuscode eq '5.0.0' ) {
        # Status: 5.0.0
        if( $commandtxt eq 'RCPT' ) {
            # Your message to the following recipients cannot be delivered:
            #
            # <***@docomo.ne.jp>:
            # mfsmax.docomo.ne.jp [203.138.181.112]:
            # >>> RCPT TO:<***@docomo.ne.jp>
            # <<< 550 Unknown user ***@docomo.ne.jp
            # ...
            #
            # Final-Recipient: rfc822; ***@docomo.ne.jp
            # Action: failed
            # Status: 5.0.0
            # Remote-MTA: dns; mfsmax.docomo.ne.jp [203.138.181.112]
            # Diagnostic-Code: smtp; 550 Unknown user ***@docomo.ne.jp
            $reasontext = 'userunknown';

        } elsif( $commandtxt eq 'DATA' ) {
            # <***@docomo.ne.jp>: host mfsmax.docomo.ne.jp[203.138.181.240] said:
            # 550 Unknown user ***@docomo.ne.jp (in reply to end of DATA
            # command)
            # ...
            # Final-Recipient: rfc822; ***@docomo.ne.jp
            # Original-Recipient: rfc822;***@docomo.ne.jp
            # Action: failed
            # Status: 5.0.0
            # Remote-MTA: dns; mfsmax.docomo.ne.jp
            # Diagnostic-Code: smtp; 550 Unknown user ***@docomo.ne.jp
            $reasontext = 'rejected';

        } else {
            # Rejected by other SMTP commands: AUTH, MAIL,
            #   もしもこのブロックを通過するNTTドコモからのエラーメッセージを見つけたら
            #   https://github.com/sisimai/p5-sisimai/issues からご連絡ねがいます。
            #
            #   If you found a error message from mfsmax.docomo.ne.jp which passes this block,
            #   please open an issue at https://github.com/sisimai/p5-sisimai/issues .
        }
    } else {
        # Status: field is neither 5.0.0 nor values defined in code above
        #   もしもこのブロックを通過するNTTドコモからのエラーメッセージを見つけたら
        #   https://github.com/sisimai/p5-sisimai/issues からご連絡ねがいます。
        #
        #   If you found a error message from mfsmax.docomo.ne.jp which passes this block,
        #   please open an issue at https://github.com/sisimai/p5-sisimai .
    }
    return $reasontext;
}

1;
__END__

=encoding utf-8

=head1 NAME

Sisimai::Rhost::NTTDOCOMO - Detect the bounce reason returned from NTT DOCOMO.

=head1 SYNOPSIS

    use Sisimai::Rhost;

=head1 DESCRIPTION

Sisimai::Rhost detects the bounce reason from the content of Sisimai::Data
object as an argument of get() method when the value of C<rhost> of the object
is "mfsmax.docomo.ne.jp". This class is called only Sisimai::Data class.

=head1 CLASS METHODS

=head2 C<B<get(I<Sisimai::Data Object>)>>

C<get()> detects the bounce reason.

=head1 AUTHOR

azumakuniyuki

=head1 COPYRIGHT

Copyright (C) 2022 azumakuniyuki, All rights reserved.

=head1 LICENSE

This software is distributed under The BSD 2-Clause License.

=cut

