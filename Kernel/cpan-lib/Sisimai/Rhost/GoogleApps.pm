package Sisimai::Rhost::GoogleApps;
use feature ':5.10';
use strict;
use warnings;

sub get {
    # Detect bounce reason from Google Workspace
    # @param    [Sisimai::Data] argvs   Parsed email object
    # @return   [String]                The bounce reason for Google Workspace
    # @see      https://support.google.com/a/answer/3726730?hl=en
    my $class = shift;
    my $argvs = shift // return undef;

    return $argvs->reason if $argvs->reason;
    return '' unless $argvs->replycode;
    return '' unless $argvs->diagnosticcode;
    return '' unless $argvs->deliverystatus;
    return '' unless $argvs->deliverystatus =~ /\A[245][.]\d[.]\d+\z/;

    state $messagesof = {
        'blocked' => [
            ['421', '4.7.0', 'ip not in whitelist for rcpt domain, closing connection.'],

            # - 421 4.7.0 Our system has detected an unusual rate of unsolicited mail originating
            #   from your IP address. To protect our users from spam, mail sent from your IP ad-
            #   dress has been temporarily blocked.
            #   For more information, visit https://support.google.com/mail/answer/81126
            ['421', '4.7.0', 'our system has detected an unusual rate of unsolicited mail originating from your ip address'],

            # - 421 4.7.0 Try again later, closing connection. This usually indicates a Denial of
            #   Service (DoS) for the SMTP relay at the HELO stage.
            ['421', '4.7.0', 'try again later, closing connection.'],

            # - 501 5.5.4 HELO/EHLO argument is invalid. For more information, visit [HELO/EHLO e-
            #   mail error].
            ['501', '5.5.4', 'helo/ehlo argument is invalid'],

            # - 550 5.7.1 Our system has detected an unusual rate of unsolicited mail originating
            #   from your IP address. To protect our users from spam, mail sent from your IP ad-
            #   dress has been blocked. Review https://support.google.com/mail/answer/81126
            ['550', '5.7.1', 'our system has detected an unusual rate of unsolicited mail originating from your ip address'],

            # - 550 5.7.1 The IP you're using to send mail is not authorized to send email directly
            #   to our servers. Please use the SMTP relay at your service provider instead. For
            #   more information, visit https://support.google.com/mail/answer/10336
            ['550', '5.7.1', "the ip you're using to send mail is not authorized to send email directly to our servers"],

            # - 550 5.7.25 The IP address sending this message does not have a PTR record setup, or
            #   the corresponding forward DNS entry does not point to the sending IP. As a policy,
            #   Gmail does not accept messages from IPs with missing PTR records.
            ['550', '5.7.25', 'the ip address sending this message does not have a ptr record setup'],

            # - 550 5.7.26 Unauthenticated email from domain-name is not accepted due to domain's
            #   DMARC policy. Please contact the administrator of domain-name domain. If this was
            #   a legitimate mail please visit [Control unauthenticated mail from your domain] to
            #   learn about the DMARC initiative. If the messages are valid and aren't spam, con-
            #   tact the administrator of the receiving mail server to determine why your outgoing
            #   messages don't pass authentication checks.
            ['550', '5.7.26', "is not accepted due to domain's dmarc policy"],

            # - 550 5.7.26 This message does not have authentication information or fails to pass
            #   authentication checks (SPF or DKIM). To best protect our users from spam, the mes-
            #   sage has been blocked. Please visit https://support.google.com/mail/answer/81126
            #   for more information.
            ['550', '5.7.1',  'fails to pass authentication checks'],
            ['550', '5.7.26', 'fails to pass authentication checks'],

            # - 550 5.7.26 This message fails to pass SPF checks for an SPF record with a hard fail
            #   policy (-all). To best protect our users from spam and phishing, the message has
            #   been blocked. Please visit https://support.google.com/mail/answer/81126 for more
            #   information.
            ['550', '5.7.26', 'this message fails to pass spf checks for an spf record with a hard fail'],
            # - 550 5.7.1 Our system has detected that this message is likely suspicious due to the
            #   very low reputation of the sending IP address. To best protect our users from spam,
            #   the message has been blocked. 
            #   Please visit https://support.google.com/mail/answer/188131 for more information.
            ['550', '5.7.1', 'this message is likely suspicious due to the very low reputation of the sending ip address'],
        ],
        'contenterror' => [
            ['554', '5.6.0', 'mail message is malformed. Not accepted'],
        ],
        'exceedlimit' => [
            # - 552 5.2.3 Your message exceeded Google's message size limits. For more information,
            #   visit https://support.google.com/mail/answer/6584
            ['552', '5.2.3', "your message exceeded Google's message size limits"],
        ],
        'expired' => [
            ['451', '4.4.2', 'timeout - closing connection'],
        ],
        'mailboxfull' => [
            # - 452 4.2.2 The email account that you tried to reach is over quota. Please direct
            #   the recipient to Clear Google Drive space & increase storage.
            ['452', '4.2.2', 'the email account that you tried to reach is over quota'],
            ['552', '5.2.2', 'the email account that you tried to reach is over quota'],
            ['550', '5.7.1', 'email quota exceeded'],
        ],
        'networkerror' => [
            ['554', '5.6.0', 'message exceeded 50 hops, this may indicate a mail loop'],
        ],
        'norelaying' => [
            ['550', '5.7.0', 'mail relay denied'],
        ],
        'policyviolation' => [
            ['550', '5.7.1', 'messages with multiple addresses in from: header are not accepted'],

            # - 550 5.7.1 The user or domain that you are sending to (or from) has a policy that
            #   prohibited the mail that you sent. Please contact your domain administrator for
            #   further details.
            #   For more information, visit https://support.google.com/a/answer/172179
            ['550', '5.7.1', 'the user or domain that you are sending to (or from) has a policy that prohibited'],

            # - 552 5.7.0 Our system detected an illegal attachment on your message. Please visit
            #   http://mail.google.com/support/bin/answer.py?answer=6590 to review our attachment
            #   guidelines.
            ['552', '5.7.0', 'our system detected an illegal attachment on your message'],

            # - 552 5.7.0 This message was blocked because its content presents a potential securi-
            #   ty issue. Please visit https://support.google.com/mail/?p=BlockedMessage to review
            #   our message content and attachment content guidelines.
            ['552', '5.7.0', 'this message was blocked because its content presents a potential security issue'],
        ],
        'rejected' => [
            # - 550 5.7.0, Mail Sending denied. This error occurs if the sender account is disabled
            #   or not registered within your Google Workspace domain.
            ['550', '5.7.0', 'mail sending denied'],

            ['550', '5.7.1', 'unauthenticated email is not accepted from this domain'],
        ],
        'securityerror' => [
            ['421', '4.7.0', 'tls required for rcpt domain, closing connection'],
            ['501', '5.5.2', 'cannot decode response'],   # 2FA related error, maybe.

            # - 530 5.5.1 Authentication Required. For more information, visit
            #   https://support.google.com/accounts/troubleshooter/2402620
            ['530', '5.5.1', 'authentication required.'],

            # - 535 5.7.1 Application-specific password required.
            #   For more information, visit https://support.google.com/accounts/answer/185833
            ['535', '5.7.1', 'application-specific password required'],

            # - 535 5.7.1 Please log in with your web browser and then try again. For more infor-
            #   mation, visit https://support.google.com/mail/bin/accounts/answer/78754
            ['535', '5.7.1', 'please log in with your web browser and then try again'],

            # - 535 5.7.1 Username and Password not accepted. For more information, visit 
            #   https://support.google.com/accounts/troubleshooter/2402620
            ['535', '5.7.1', 'username and password not accepted'],

            ['550', '5.7.1', 'invalid credentials for relay'],
        ],
        'spamdetected' => [
            # - 550 5.7.1 Our system has detected that this message is likely unsolicited mail. To
            #   reduce the amount of spam sent to Gmail, this message has been blocked.
            #   For more information, visit https://support.google.com/mail/answer/188131
            ['550', '5.7.1', 'our system has detected that this message is likely unsolicited mail'],
        ],
        'suspend' => [
            [550, '5.2.1', 'the email account that you tried to reach is disabled'],
        ],
        'syntaxerror' => [
            ['451', '4.5.0', 'smtp protocol violation, visit rfc 2821'],
            ['454', '4.5.0', 'smtp protocol violation, no commands allowed to pipeline after starttls'],
            ['454', '5.5.1', 'starttls may not be repeated'],
            ['502', '5.5.1', 'too many unrecognized commands, goodbye'],
            ['502', '5.5.1', 'unimplemented command'],
            ['502', '5.5.1', 'unrecognized command'],
            ['503', '5.5.1', 'ehlo/helo first'],
            ['503', '5.5.1', 'mail first'],
            ['503', '5.5.1', 'rcpt first'],
            ['503', '5.7.0', 'no identity changes permitted'],
            ['504', '5.7.4', 'unrecognized authentication type'],
            ['530', '5.7.0', 'must issue a starttls command first'],
            ['535', '5.5.4', 'optional argument not permitted for that auth mode'],
            ['554', '5.7.0', 'too many unauthenticated commands'],
            ['555', '5.5.2', 'syntax error'],
        ],
        'systemerror' => [
            ['421', '4.3.0', 'temporary system problem'],
            ['421', '4.7.0', 'temporary system problem'],
            ['421', '4.4.5', 'server busy'],
            ['451', '4.3.0', 'mail server temporarily rejected message'],
            ['454', '4.7.0', 'cannot authenticate due to temporary system problem'],

            # - 452 4.5.3 Domain policy size per transaction exceeded, please try this recipient in
            #   a separate transaction. This message means the email policy size (size of policies,
            #   number of policies, or both) for the recipient domain has been exceeded.
            ['452', '4.5.3', 'domain policy size per transaction exceeded'],
        ],
        'toomanyconn' => [
            ['451', '4.3.0', 'multiple destination domains per transaction is unsupported'],

            # - 452 4.5.3 Your message has too many recipients. For more information regarding
            #   Google's sending limits, visit https://support.google.com/mail/answer/6592
            ['452', '4.5.3', 'your message has too many recipients'],

            # - 450 4.2.1 The user you are trying to contact is receiving mail too quickly. Please
            #   resend your message at a later time. If the user is able to receive mail at that
            #   time, your message will be delivered. 
            #   For more information, visit https://support.google.com/mail/answer/22839
            ['450', '4.2.1', 'is receiving mail too quickly'],

            # - 450 4.2.1 The user you are trying to contact is receiving mail at a rate that pre-
            #   vents additional messages from being delivered. Please resend your message at a
            #   later time. If the user is able to receive mail at that time, your message will be
            #   delivered. For more information, visit https://support.google.com/mail/answer/6592
            ['450', '4.2.1', 'is receiving mail at a rate that prevents additional messages from being delivered'],
            ['550', '5.2.1', 'is receiving mail at a rate that prevents additional messages from being delivered'],

            # - 450 4.2.1 Peak SMTP relay limit exceeded for customer. This is a temporary error.
            #   For more information on SMTP relay limits, please contact your administrator or
            #   visit https://support.google.com/a/answer/6140680
            ['450', '4.2.1', 'peak smtp relay limit exceeded for customer'],

            # - 550 5.4.5 Daily SMTP relay limit exceeded for user. For more information on SMTP
            #   relay sending limits please contact your administrator or visit SMTP relay service
            #   error messages.
            ['550', '5.4.5', 'daily smtp relay limit exceeded for user'],
            ['550', '5.4.5', 'daily sending quota exceeded'],

            # - 550 5.7.1 Daily SMTP relay limit exceeded for customer. For more information on
            #   SMTP relay sending limits please contact your administrator or visit
            #   https://support.google.com/a/answer/6140680
            ['550', '5.7.1', 'daily smtp relay limit exceeded for customer'],
        ],
        'userunknown' => [
            # - 550 5.1.1 The email account that you tried to reach does not exist. Please try dou-
            #   ble-checking the recipient's email address for typos or unnecessary spaces.
            #   For more information, visit https://support.google.com/mail/answer/6596
            ['550', '5.1.1', 'the email account that you tried to reach does not exist'],

            # - 553 5.1.2 We weren't able to find the recipient domain. Please check for any spell-
            #   ing errors, and make sure you didn't enter any spaces, periods, or other punctua-
            #   tion after the recipient's email address.
            ['553', '5.1.2', "we weren't able to find the recipient domain"],
        ],
    };

    my $statuscode = substr($argvs->deliverystatus, 2); # 421   => 21
    my $esmtpreply = substr($argvs->replycode, 1, 2);   # 5.7.1 => 7.1
    my $esmtperror = lc  $argvs->diagnosticcode;
    my $reasontext = '';

    REASON: for my $e ( keys %$messagesof ) {
        # Each key is a reason name
        for my $f ( @{ $messagesof->{ $e } } ) {
            # Try to match an SMTP reply code, a D.S.N., and an error message
            next unless index($esmtperror, $f->[2]) > -1;
            next unless index($f->[0], $esmtpreply) >  0;
            next unless index($f->[1], $statuscode) >  1;
            $reasontext = $e;
            last REASON;
        }
    }
    return $reasontext;
}

1;
__END__

=encoding utf-8

=head1 NAME

Sisimai::Rhost::GoogleApps - Detect the bounce reason returned from Google Workspace

=head1 SYNOPSIS

    use Sisimai::Rhost;

=head1 DESCRIPTION

Sisimai::Rhost detects the bounce reason from the content of Sisimai::Data
object as an argument of get() method when the value of C<rhost> of the object
is "aspmx.l.google.com". This class is called only Sisimai::Data class.

=head1 CLASS METHODS

=head2 C<B<get(I<Sisimai::Data Object>)>>

C<get()> detects the bounce reason.

=head1 AUTHOR

azumakuniyuki

=head1 COPYRIGHT

Copyright (C) 2014-2016,2018-2020,2022 azumakuniyuki, All rights reserved.

=head1 LICENSE

This software is distributed under The BSD 2-Clause License.

=cut
