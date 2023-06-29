package Sisimai::Rhost::ExchangeOnline;
use feature ':5.10';
use strict;
use warnings;

# https://technet.microsoft.com/en-us/library/bb232118
# https://learn.microsoft.com/en-us/Exchange/mail-flow-best-practices/non-delivery-reports-in-exchange-online/non-delivery-reports-in-exchange-online
# https://learn.microsoft.com/en-us/Exchange/mail-flow/non-delivery-reports-and-bounce-messages/non-delivery-reports-and-bounce-messages
sub get {
    # Detect bounce reason from Exchange 2019 or older and Exchange Online
    # @param    [Sisimai::Data] argvs   Parsed email object
    # @return   [String]                The bounce reason for Exchange Online
    # @see      https://technet.microsoft.com/en-us/library/bb232118
    my $class = shift;
    my $argvs = shift // return undef;

    return $argvs->reason if $argvs->reason;
    return '' unless $argvs->diagnosticcode;
    return '' unless $argvs->deliverystatus;
    return '' unless $argvs->deliverystatus =~ /\A[245][.]\d[.]\d+\z/;

    state $messagesof = {
        'blocked' => [
            # Exchange Server 2019 ----------------------------------------------------------------
            # - Transient network issues or server problems that might eventually correct them-
            #   selves. The sending server will retry delivery of the message, and will generate
            #   further status reports. The message size limit for the connection has been reached,
            #   or the message submission rate for the source IP address has exceeded the configur-
            #   ed limit. For more information, see Message rate limits and throttling. Antispam,
            #   SMTP proxy, or firewall configuration issues are blocking email from the Exchange
            #   server.
            ['4.4.2', 0, 0, 'connection dropped'],

            # Exchange Online ---------------------------------------------------------------------
            # - Suspicious activity has been detected on the IP in question, and it has been tempo-
            #   rarily restricted while it's being further evaluated.
            # - If this activity is valid, this restriction will be lifted shortly.
            ['4.7.', 850, 899, 'access denied, please try again later'],

            # - Access denied, the sending IPv6 address [2a01:111:f200:2004::240] must have a re-
            #   verse DNS record
            # - The sending IPv6 address must have a reverse DNS record in order to send email over
            #   IPv6.
            ['5.7.25', 0, 0, 'must have a reverse dns record'],

            # - Your server is attempting to introduce itself (HELO according to RFC 821) as the
            #   server it's trying to connect to, rather than its own fully qualified domain name.
            # - This isn't allowed, and it's characteristic of typical spambot behavior.
            ['5.7.506', 0, 0, 'access denied, bad helo'],

            # - The IP that you're attempting to send from has been blocked by the recipient's or-
            #   ganization.
            # - Contact the recipient in order to resolve this issue.
            ['5.7.507', 0, 0, 'access denied, rejected by recipient'],

            # - Access denied, [contoso.com] does not accept email over IPv6
            # - The sender is attempting to transmit a message to the recipient over IPv6, but the
            #   recipient doesn't accept email messages over IPv6.
            ['5.7.510', 0, 0, 'does not accept email over ipv6'],

            # - The IP that you're attempting to send from has been banned.
            # - To delist the address, email delist@messaging.microsoft.com and provide the full
            #   NDR code and IP address to delist. For more information, see Use the delist portal
            #   to remove yourself from the blocked senders list.
            ['5.7.511', 0, 0, 'access denied, banned sender'],

            # - Service unavailable, Client host [$ConnectingIP] blocked by $recipientDomain using
            #   Customer Block list (AS16012607)
            # - The recipient domain has added your sending IP address to its custom blocklist.
            # - The domain that received the email has blocked your sender's IP address. If you
            #   think your IP address has been added to the recipient domain's custom blocklist in
            #   error, you need to contact them directly and ask them to remove it from the block-
            #   list.
            ['5.7.513', 0, 0, 'using customer block list'],

            # - 5.7.606-649 Access denied, banned sending IP [IP1.IP2.IP3.IP4]
            # - The IP that you're attempting to send from has been banned.
            # - Verify that you're following the best practices for email deliverability, and en-
            #   sure your IPs' reputations haven't been degraded as a result of compromise or mali-
            #   cious traffic. If you believe you're receiving this message in error, you can use
            #   the self-service portal to request to be removed from this list.
            # - For more information, see Use the delist portal to remove yourself from the blocked
            #   senders list. 
            ['5.7.', 606, 649, 'access denied, banned sending ip '],

            # Previous versions of Exchange Server ------------------------------------------------
            # - Suspicious activity has been detected and sending has been temporarily restricted
            #   for further evaluation.
            # - If this activity is valid, this restriction will be lifted shortly.
            ['4.7.', 500, 699, 'access denied, please try again later'],

            # Previous versions of Exchange Server ------------------------------------------------
            ['5.5.4',  0, 0, 'invalid domain name'],
            ['5.7.51', 0, 0, 'restrictdomainstoipaddresses or restrictdomainstocertificate'],

            # Undocumented error messages ---------------------------------------------------------
            # - 550 5.7.1 Unfortunately, messages from [10.0.2.5] weren't sent. Please contact your
            #   Internet service provider since part of their network is on our block list (S3150). 
            ['5.7.1', 0, 0, 'part of their network is on our block list (s3150)'],

            # - Access denied, a message sent over IPv6 [2a01:111:f200:2004::240] must pass either
            #   SPF or DKIM validation, this message is not signed
            # - The sending message sent over IPv6 must pass either SPF or DKIM.
            ['4.7.26', 0, 0, 'must pass either spf or dkim validation, this message is not signed'],

            # - Records are DNSSEC authentic, but one or multiple of these scenarios occurred:
            #   - The destination mail server's certificate doesn't match with what is expected per
            #     the authentic TLSA record.
            #   - Authentic TLSA record is misconfigured.
            #   - Destination domain is being attacked.
            #   - Any other DANE failure.
            # - This message usually indicates an issue on the destination email server. Check the
            #   validity of recipient address and determine if the destination server is configured
            #   correctly to receive messages. 
            # - For more information about DANE, see: https://datatracker.ietf.org/doc/html/rfc7671
            ['4.7.323', 0, 0, 'tlsa-invalid: The domain failed dane validation'],
            ['5.7.323', 0, 0, 'tlsa-invalid: The domain failed dane validation'],

            # - The destination domain indicated it was DNSSEC-authentic, but Exchange Online was 
            #   not able to verify it as DNSSEC-authentic.
            ['4.7.324', 0, 0, 'dnssec-invalid: destination domain returned invalid dnssec records'],
            ['5.7.324', 0, 0, 'dnssec-invalid: destination domain returned invalid dnssec records'],

            # - This happens when the presented certificate identities (CN and SAN) of a destina-
            #   tion SMTP target host don't match any of the domains or MX host.
            # - This message usually indicates an issue on the destination email server. Check the
            #   validity of recipient address and determine if the destination server is configured
            #   correctly to receive messages. For more information, see How SMTP DNS-based Authen-
            #   tication of Named Entities (DANE) works to secure email communications.
            ['4.7.325', 0, 0, 'certificate-host-mismatch: remote certificate must have a common name or subject alternative name matching the hostname (dane)'],
            ['5.7.325', 0, 0, 'certificate-host-mismatch: remote certificate must have a common name or subject alternative name matching the hostname (dane)'],

            # - The destination email system uses SPF to validate inbound mail, and there's a prob-
            #   lem with your SPF configuration.
            ['5.7.23', 0, 0, 'the message was rejected because of sender policy framework violation'],

            # - DNSSEC checks have passed, yet upon establishing the connection the destination
            #   mail server provides a certificate that is expired.
            # - A valid X.509 certificate that isn't expired must be presented. X.509 certificates
            #   must be renewed after their expiration, commonly annually.
            ['5.7.322', 0, 0, "certificate-expired: destination mail server's certificate is expired"],

            # - Access denied, sending domain [$SenderDomain] does not pass DMARC verification
            # - The sender's domain in the 5322.From address doesn't pass DMARC.
            ['5.7.509', 0, 0, 'does not pass dmarc verification'],
            # Undocumented error messages ---------------------------------------------------------
            # - status=deferred (host outlook-com.olc.protection.outlook.com[192.0.2.255] said:
            #   451 4.7.650 The mail server [192.0.2.5] has been temporarily rate limited due to IP
            #   reputation. For e-mail delivery information, see https://postmaster.live.com (S775)
            #   [***.prod.protection.outlook.com] (in reply to MAIL FROM command))
            ['4.7.650', 0, 0, 'has been temporarily rate limited due to ip reputation'],
        ],
        'contenterror' => [
            # Exchange Server 2019 ----------------------------------------------------------------
            # - The message was determined to be malformed, and was moved to the poison message
            #   queue. For more information, see Types of queues.
            ['5.3.0', 0, 0, 'too many related errors'],

            # Exchange Online ---------------------------------------------------------------------
            # - Your email program added invalid characters (bare line feed characters) into a mes-
            #   sage you sent.
            ['5.6.11', 0, 0, 'invalid characters'],

            # Previous versions of Exchange Server ------------------------------------------------
            ['5.4.11', 0, 0, 'agent generated message depth exceeded'],
            ['5.5.6',  0, 0, 'invalid message content'],
        ],
        'exceedlimit' => [
            # Exchange Server 2019 ----------------------------------------------------------------
            # - The message is too large. Send the message again without any attachments, or confi-
            #   gure a larger message size limit for the recipient. For more information, see Re-
            #   cipient limits.
            ['5.2.3', 0, 0, 'resolver.rst.recipsizelimit; message too large for this recipient'],
        ],
        'expired' => [
            # Exchange Server 2019 ----------------------------------------------------------------
            # - Transient network issues that might eventually correct themselves. The Exchange
            #   server periodically tries to connect to the destination server to deliver the mes-
            #   sage. After multiple failures, the message is returned to the sender in an NDR with
            #   a permanent failure code.
            #   For more information about configuring the queue retry and failure intervals, see
            #   Configure message retry, resubmit, and expiration intervals. To manually retry a
            #   queue, see Retry queues. Firewall or Internet service provider (ISP) restrictions
            #   on TCP port 25.
            ['4.4.1', 0, 0, 'connection timed out'],

            # - Send connector configuration issues. For example:
            #   - The Send connector is configured to use DNS routing when it should be using smart
            #     host routing, or vice-versa. Use nslookup to verify that the destination domain
            #     is reachable from the Exchange server.
            #   - The FQDN that the Send connector provides to HELO or EHLO requests doesn't match
            #     the host name in your MX record (for example, mail.contoso.com). Some messaging
            #     systems are configured to compare these values in an effort to reduce spam. The
            #     default value on a Send connector is blank, which means the FQDN of the Exchange
            #     server is used (for example, exchange01.contoso.com).
            # - The Mailbox Transport Delivery service isn't started on the destination server
            #   (which prevents the delivery of the message to the mailbox).
            # - The destination messaging system has issues with Transport Neutral Encryption For-
            #   mat (TNEF) messages (also known as rich text format or RTF in Outlook). For exam-
            #   ple, meeting requests or messages with images embedded in the message body.
            # - If the destination domain uses the Sender Policy Framework (SPF) to check message
            #   sources, there may be SPF issues with your domain (for example, your SPF record
            #   doesn't include all email sources for your domain).
            ['4.4.7', 0, 0, 'message delayed'],
            ['4.4.7', 0, 0, 'queue expired; message expired'],

            # Exchange Online ---------------------------------------------------------------------
            # - The message in the queue has expired. The sending server tried to relay or deliver
            #   the message, but the action wasn't completed before the message expiration time oc-
            #   curred. This message can also indicate that a message header limit has been reached
            #   on a remote server, or some other protocol time-out occurred while communicating
            #   with the remote server.
            # - This message usually indicates an issue on the receiving server. Check the validity
            #   of the recipient address, and determine if the receiving server is configured cor-
            #   rectly to receive messages. You might have to reduce the number of recipients in
            #   the message header for the host about which you're receiving this error. If you
            #   send the message again, it's placed in the queue again. If the receiving server is
            #   available, the message is delivered. 
            ['4.4.7', 0, 0, 'message expired'],

            # - The email took too long to be successfully delivered, either because the destina-
            #   tion server never responded or the sent message generated an NDR error and that NDR
            #   couldn't be delivered to the original sender.
            ['5.4.300', 0, 0, 'message expired'],
        ],
        'mailboxfull' => [
            # Exchange Server 2019 ----------------------------------------------------------------
            # - The recipient's mailbox has exceeded its storage quota and is no longer able to ac-
            #   cept new messages. For more information about configuring mailbox quotas, see Con-
            #   figure storage quotas for a mailbox.
            ['5.2.2', 0, 0, 'mailbox full'],
        ],
        'mesgtoobig' => [
            # Exchange Server 2019 ----------------------------------------------------------------
            # - The message is too large. This error can be generated by the source or destination
            #   messaging system. Send the message again without any attachments, or configure a
            #   larger message size limit. For more information, see Message size and recipient
            #   limits in Exchange Server.
            ['5.3.4', 0, 0, 'message size exceeds fixed maximum message size'],

            # Previous versions of Exchange Server ------------------------------------------------
            ['5.3.4', 0, 0, 'message too big for system'],
        ],
        'networkerror' => [
            # Exchange Server 2019 ----------------------------------------------------------------
            # - There's a DNS or network adapter configuration issue on the Exchange server. Verify
            #   the internal and external DNS lookup settings for the Exchange by running this com-
            #   mand in the Exchange Management Shell:
            #   - Get-TransportService | Format-List Name,ExternalDNS*,InternalDNS*;
            #   - Get-FrontEndTransportService | Format-List Name,ExternalDNS*,InternalDNS*`
            #   You can configure these settings by using the InternalDNS* and ExternalDNS* parame-
            #   ters on the Set-TransportService and Set-FrontEndTransportService cmdlets.
            #   By default, these settings are used by Send connectors (the default value of the
            #   UseExternalDNSServersEnabled parameter value is $false). Check the priority (order)
            #   of the network adapters in the operating system of the Exchange server.
            ['5.4.4', 0, 0, 'smtpsend.dns.nonexistentdomain; nonexistent domain'],

            # - A configuration error has caused an email loop. By default, after 20 iterations of
            #   an email loop, Exchange interrupts the loop and generates an NDR. Verify that Inbox
            #   rules for the recipient and sender, or forwarding rules on the recipient's mailbox
            #   aren't causing this (the message generates a message, which generates another mes-
            #   sage, and the process continues indefinitely).
            #   Verify the mailbox doesn't have a targetAddress property value in Active Directory
            #   (this property corresponds to the ExternalEmailAddress parameter for mail users in
            #   Exchange). If you remove Exchange servers, or modify settings related to mail rout-
            #   ing an mail flow, be sure to restart the Microsoft Exchange Transport and Exchange
            #   Frontend Transport services.
            ['5.4.6', 0, 0, 'hop count exceeded - possible mail loop'],

            # Exchange Online ---------------------------------------------------------------------
	        # - Microsoft 365 or Office 365 is trying to send a message to an email server outside
            #   of Microsoft 365 or Office 365, but attempts to connect to it are failing due to a
            #   network connection issue at the external server's location.
            # - This error almost always indicates an issue with the receiving server or network
            #   outside of Microsoft 365 or Office 365. The error should also include the IP ad-
            #   dress of the server or service that's generating the error, which you can use to
            #   identify the party responsible for fixing this.
            ['4.4.316', 0, 0, 'connection refused'], # [Message=Socket error code 10061]

            # - A configuration error has caused an email loop. 5.4.6 is generated by on-premises
            #   Exchange server (you'll see this code in hybrid environments). 5.4.14 is generated
            #   by Exchange Online. By default, after 20 iterations of an email loop, Exchange in-
            #   terrupts the loop and generates an NDR to the sender of the message.
            # - This error occurs when the delivery of a message generates another message in re-
            #   sponse. That message then generates a third message, and the process is repeated,
            #   creating a loop. To help protect against exhausting system resources, Exchange in-
            #   terrupts the mail loop after 20 iterations. Mail loops are typically created be-
            #   cause of a configuration error on the sending mail server, the receiving mail serv-
            #   er, or both. Check the sender's and the recipient's mailbox rules configuration to
            #   determine whether automatic message forwarding is enabled.
            ['5.4.4',  0, 0, 'invalid arguments'],
            ['5.4.6',  0, 0, 'routing loop detected'],
            ['5.4.14', 0, 0, 'routing loop detected'],
        ],
        'norelaying' => [
            # Exchange Server 2019 ----------------------------------------------------------------
            # - You have an application server or device that's trying to relay messages through
            #   Exchange. For more information, see Allow anonymous relay on Exchange servers. The
            #   recipient is configured to only accept messages from authenticated (typically, in-
            #   ternal) senders. For more information, see Configure message delivery restrictions
            #   for a mailbox.
            ['5.7.1', 0, 0, 'unable to relay'],
            ['5.7.1', 0, 0, 'client was not authenticated'],

            # Exchange Online ---------------------------------------------------------------------
            # - The mail server that's generating the error doesn't accept mail for the recipient's
            #   domain. This error is caused by mail server or DNS misconfiguration.
            ['5.4.1', 0, 0, 'relay access denied'],

            # - The sending email system isn't allowed to send a message to an email system where
            #   that email system isn't the final destination of the message.
            # - This error occurs when the sending email system tries to send an anonymous message
            #   to a receiving email system, and the receiving email system doesn't accept messages
            #   for the domain or domains specified in one or more of the recipients. The following
            #   are the most common reasons for this error:
            #   - A third party tries to use a receiving email system to send spam, and the receiv-
            #     ing email system rejects the attempt. By the nature of spam, the sender's email
            #     address might have been forged, and the resulting NDR could have been sent to the
            #     unsuspecting sender's email address. It's difficult to avoid this situation.
            #   - An MX record for a domain points to a receiving email system where that domain is
            #     not accepted. The administrator responsible for the specific domain name must
            #     correct the MX record or configure the receiving email system to accept messages
            #     sent to that domain, or both.
            #   - A sending email system or client that should use the receiving email system to
            #     relay messages doesn't have the correct permissions to do this.
            ['5.7.1', 0, 0, 'unable to relay'],

            # - You use an inbound connector to receive messages from your on-premises email envi-
            #   ronment, and something has changed in your on-premises environment that makes the
            #   inbound connector's configuration incorrect.
            ['5.7.64', 0, 0, 'tenantattribution; relay access denied'],

            # Previous versions of Exchange Server ------------------------------------------------
            ['5.4.310', 0, 0, 'does not exist'], # DNS domain * does not exist
        ],
        'notaccept' => [
            ['4.3.2', 0, 0, 'system not accepting network messages'],

            # Exchange Server 2019 ----------------------------------------------------------------
            # - You're using the ABP Routing agent, and the recipient isn't a member of the global
            #   address list that's specified in their address book policy (ABP). For more infor-
            #   mation, see Use the Exchange Management Shell to install and configure the Address
            #   Book Policy Routing Agent and Address book policies in Exchange Server.
            ['5.3.2', 0, 0, 'storedrv.deliver: missing or bad storedriver mdb properties'],
        ],
        'policyviolation' => [
            # - 5.0.350 is a generic catch-all error code for a wide variety of non-specific errors
            #   lfrom the recipient's email organization. The specific x-dg-ref header is too long
            #   message is related to Rich Text formatted messages. The specific Requested action
            #   not taken: policy violation detected (AS345) message is related to nested attach-
            #   ments.
            ['5.0.350', 0, 0, 'x-dg-ref header is too long'],
            ['5.0.350', 0, 0, 'requested action not taken: policy violation detected (as345)'],

            # - The message was rejected by a mail flow rule (also known as a transport rule). This
            #   enhanced status code range is available when the rule is configured to reject mes-
            #   sages (otherwise, the default code that's used is 5.7.1). For more information, see
            #   Mail flow rule actions in Exchange Server.
            ['5.7.', 900, 999, 'delivery not authorized, message refused'],
        ],
        'rejected' => [
            # Exchange Server 2019 ----------------------------------------------------------------
            # - There's a problem with the sender's email address. Verify the sender's email ad-
            #   dress.
            ['5.1.7', 0, 0, 'invalid address'],
            ['5.1.7', 0, 0, 'unknown sender address'],

            # - A common cause of this NDR is when you use Microsoft Outlook to save an email mes-
            #   sage as a file, and then someone opened the message offline and replied to it. The
            #   message property only preserves the legacyExchangeDN attribute when Outlook deliv-
            #   ers the message, and therefore the lookup could fail.
            # - Either the recipient address is incorrectly formatted, or the recipient couldn't be
            #   correctly resolved. The first step in resolving this error is to check the recipi-
            #   ent address, and send the message again. 
            ['5.1.0', 0, 0, 'sender denied'],

            # - The account has been blocked for sending too much spam. Typically, this problem oc-
            #   curs because the account has been compromised (hacked) by phishing or malware.
            ['5.1.8', 0, 0, 'access denied, bad outbound sender'],

            # Exchange Online ---------------------------------------------------------------------
            # - The sender of the message isn't allowed to send messages to the recipient.
            # - This error occurs when the sender tries to send a message to a recipient but the
            #   sender isn't authorized to do this. This frequently occurs when a sender tries to
            #   send messages to a distribution group that has been configured to accept messages
            #   only from members of that distribution group or other authorized senders. The send-
            #   er must request permission to send messages to the recipient.  This error can also
            #   occur if an Exchange transport rule rejects a message because the message matched
            #   conditions that are configured on the transport rule.
            ['5.7.1', 0, 0, 'delivery not authorized'],

            # - The sender's message is rejected because the recipient address is set up to reject
            #   messages sent from outside of its organization. Only an email admin for the recipi-
            #   ent's organization can change this.
            ['5.7.12', 0, 0, 'sender was not authenticated by organization'],

            # - The sender doesn't have permission to send to the distribution group because the
            #   sender isn't in the group's allowed-senders list. Depending how the group is set
            #   up, even the group's owner might need to be added to the allowed sender list in or-
            #   der to send messages to the group.
            ['5.7.124', 0, 0, 'sender not in allowed-senders list'],

            # - The recipient address is a group distribution list that is set up to reject mes-
            #   sages sent from outside of its organization. Only an email admin for the recipi-
            #   ent's organization or the group owner can change this.
            ['5.7.133', 0, 0, 'sender not authenticated for group'],

            # - The recipient address is a mailbox that is set up to reject messages sent from out-
            #   side of its organization. Only an email admin for the recipient's organization can
            #   change this.
            ['5.7.134', 0, 0, 'sender was not authenticated for mailbox'],

            # - The recipient address is a public folder that is set up to reject messages sent
            #   from outside of its organization. Only an email admin for the recipient's organiza-
            #   tion can change this.
            ['5.7.13',  0, 0, 'sender was not authenticated for public folder'],
            ['5.7.135', 0, 0, 'sender was not authenticated for public folder'],

            # - The recipient address is a mail user that is set up to reject messages sent from
            #   outside of its organization. Only an email admin for the recipient's organization
            #   can change this.
            ['5.7.136', 0, 0, 'sender was not authenticated'],

            # - The sending account has been banned due to detected spam activity.
            # - For details, see Fix email delivery issues for error code 451 5.7.500-699 (ASxxx)
            #   in Exchange Online.
            # - Verify that any account issues have been resolved, and reset its credentials. To
            #   restore this account's ability to send mail, contact support through your regular
            #   channel.
            ['5.7.', 501, 503, 'access denied, spam abuse detected'],

            # - Message was sent without a valid "From" email address.
            # - Office 365 only. Each message must contain a valid email address in the "From"
            #   header field. Proper formatting of this address includes angle brackets around the
            #   email address, for example, <security@contoso.com>. Without this address Microsoft
            #   365 or Office 365 will reject the message.
            ['5.7.512', 0, 0, 'access denied, message must be rfc 5322 section 3.6.2 compliant'],

            # - A suspicious number of messages from unprovisioned domains is coming from this ten-
            #   ant.
            # - Add and validate any and all domains that you use to send email from Microsoft 365
            #   or Office 365. For more information, see Fix email delivery issues for error codes
            #   5.7.700 through 5.7.750 in Exchange Online.
            ['5.7.750', 0, 0, 'service unavailable. client blocked from sending from unregistered domains'],

            # Previous versions of Exchange Server ------------------------------------------------
            ['5.7.', 501, 503, 'access denied, banned sender'],
        ],
        'securityerror' => [
            # Exchange Server 2019 ----------------------------------------------------------------
            # - A firewall or other device is blocking the Extended SMTP command that's required
            #   for Exchange Server authentication (X-EXPS). Internal email traffic is flowing
            #   through connectors that aren't configured to use the Exchange Server authentication
            #   method . Verify the remote IP address ranges on any custom Receive connectors.
            ['5.7.3', 0, 0, 'cannot achieve exchange server authentication'],
            ['5.7.3', 0, 0, 'not authorized'],

            # Exchange Online ---------------------------------------------------------------------
            # - DNSSEC checks have passed, yet upon connection, destination mail server doesn't re-
            #   spond to the STARTTLS command. The destination server responds to the STARTTLS com-
            #   mand, but the TLS handshake fails.
            # - This message usually indicates an issue on the destination email server. Check the
            #   validity of the recipient address. Determine if the destination server is configur-
            #   ed correctly to receive the messages.
            ['4.7.321', 0, 0, 'starttls-not-supported: destination mail server must support tls to receive mail'],
            ['5.7.321', 0, 0, 'starttls-not-supported: destination mail server must support tls to receive mail'],

            # - The sending email system didn't authenticate with the receiving email system. The
            #   receiving email system requires authentication before message submission.
            # - This error occurs when the receiving server must be authenticated before message
            #   submission, and the sending email system hasn't authenticated with the receiving e-
            #   mail system. The sending email system administrator must configure the sending e-
            #   mail system to authenticate with the receiving email system for delivery to be suc-
            #   cessful. 
            ['5.7.1', 0, 0, 'client was not authenticated'],

            # - You configured an application or device to send (relay) email messages in Microsoft
            #   365 or Office 365 using the smtp.office365.com endpoint, and there's a problem with
            #   the configuration of the application or device.
            ['5.7.57', 0, 0, 'client was not authenticated to send anonymous mail during mail from'],
        ],
        'spamdetected' => [
            # Exchange Server 2019 ----------------------------------------------------------------
            # - The message was quarantined by content filtering. To configure exceptions to con-
            #   tent filtering, see Use the Exchange Management Shell to configure recipient and
            #   sender exceptions for content filtering.
            ['5.2.1', 0, 0, 'content filter agent quarantined this message'],
        ],
        'suspend' => [
            # Exchange Online ---------------------------------------------------------------------
            # - The recipient address that you're attempting to contact isn't valid.
            # - Verify the recipient's email address, and try again.
            # - If you feel this is in error, contact support.
            ['5.7.504', 0, 0, 'recipient address rejected: access denied'],
            ['5.7.505', 0, 0, 'access denied, banned recipient'],

            # Previous versions of Exchange Server ------------------------------------------------
            ['5.2.1', 0, 0, 'mailbox cannot be accessed'],
        ],
        'syntaxerror' => [
            # Exchange Server 2019 ----------------------------------------------------------------
            # - Receive connectors that are used for internal mail flow are missing the required
            #   Exchange Server authentication mechanism. For more information about authentication
            #   on Receive connectors, see Receive connector authentication mechanisms.
            ['5.3.3', 0, 0, 'unrecognized command'],

            # - SMTP commands are sent out of sequence (for example, a server sends an SMTP command
            #   like AUTH or MAIL FROM before identifying itself with the EHLO command). After es-
            #   tablishing a connection to a messaging server, the first SMTP command must always
            #   be EHLO or HELO.
            ['5.5.2', 0, 0, 'send hello first'],
        ],
        'systemerror' => [
            # Exchange Server 2019 ----------------------------------------------------------------
            # - You've configured a custom Receive connector in the Transport (Hub) service on a
            #   Mailbox server that listens on port 25. Typically, custom Receive connectors that
            #   listen on port 25 belong in the Front End Transport service on the Mailbox server.
            #   Important Exchange server components are inactive. You can confirm this by running
            #   the following command in the Exchange Management Shell:
            #       Get-ServerComponent -Identity <ServerName>.
            #   To restart all inactive components, run the following command:
            #       Set-ServerComponentState -Identity <ServerName> -Component ServerWideOffline
            #         -State Active -Requester Maintenance.
            #   Incompatible transport agents (in particular, after an Exchange update). After you
            #   identify the transport agent, disable it or uninstall it. For more information, see
            #   Troubleshoot transport agents.
            ['4.3.2', 0, 0, 'service not available'],
            ['4.3.2', 0, 0, 'service not active'],

            # - A mail loop was detected. Verify that the FQDN property on the Receive connector
            #   doesn't match the FQDN of another server, service, or device that's used in mail
            #   flow in your organization (by default, the Receive connector uses the FQDN of the
            #   Exchange server).
            ['5.3.5', 0, 0, 'system incorrectly configured'],

            # Exchange Online ---------------------------------------------------------------------
            # - Journaling on-premises messages to Microsoft 365 or Office 365 isn't supported for
            #   this organization because they haven't turned on Journaling Archive in their set-
            #   tings.
            # - A journaling rule is configured in the organization's on-premises environment to
            #   journal on-premises messages to Microsoft 365 or Office 365, but Journaling Archive
            #   is disabled. For this scenario to work, the organization's Office 365 administrator
            #   should either enable Journaling Archive or change the journaling rule to journal
            #   messages to a different location.
            ['5.3.190', 0, 0, 'journaling on-premises messages to microsoft 365 or office 365 not supported when journaling archive is disabled'],

            # Previous versions of Exchange Server ------------------------------------------------
            ['5.0.0',  0, 0, 'helo / ehlo requires domain address'],
            ['5.1.4',  0, 0, 'destination mailbox address ambiguous'],
            ['5.2.4',  0, 0, 'mailing list expansion problem'],
            ['5.2.14', 0, 0, 'misconfigured forwarding address'],

            # Undocumented error messages ---------------------------------------------------------
            ['4.4.3',  0, 0, 'temporary server error. please try again later attr18'],
            ['4.7.0',  0, 0, 'temporary server error. please try again later. prx4 nexthop:'],
            ['4.4.24', 0, 0, 'message failed to be replicated: insufficient system resource:'],
            ['4.4.25', 0, 0, 'message failed to be replicated: no healthy secondary server available to accept replica at this time.'],
            ['4.4.28', 0, 0, 'message failed to be replicated: the operation was canceled'],

            # - status=deferred (host hotmail-com.olc.protection.outlook.com[192.0.2.1] said:
            #   451 4.7.500 Server busy. Please try again later from [192.0.2.2]. (AS761) (in reply
            #   to RCPT TO command))
            ['4.7.500', 0, 0, 'server busy. please try again later from '],

            # - status=deferred (host apc.olc.protection.outlook.com[192.0.2.1] said:
            #   451 4.7.700 PFA agent busy, please try again. [***.***.prod.protection.outlook.com]
            #   (in reply to MAIL FROM command))
            ['4.7.700', 0, 0, 'pfa agent busy, please try again.'],
        ],
        'systemfull' => [
            # Exchange Server 2019 ----------------------------------------------------------------
            # - Free disk space is low (for example, the disk that holds the queue database doesn't
            #   have the required amount of free space). For more information, see Understanding
            #   back pressure. To move the queue database to a different disk, see Change the loca-
            #   tion of the queue database.
            # - Available memory is low (for example, Exchange installed on a virtual machine that
            #   is configured to use dynamic memory). Always use static memory on Exchange virtual
            #   machines.
            ['4.3.1', 0, 0, 'insufficient system resources'],
        ],
        'toomanyconn' => [
            # Exchange Server 2019 ----------------------------------------------------------------
            # - The combined total of recipients on the To, Cc, and Bcc lines of the message ex-
            #   ceeds the total number of recipients allowed in a single message for the organiza-
            #   tion, Receive connector, or sender. For more information, see Message size and re-
            #   cipient limits in Exchange Server.
            ['5.5.3', 0, 0, 'too many recipients'],
            
            # Exchange Online ---------------------------------------------------------------------
            # - The message has more than 200 SMTP envelope recipients from the same domain.
            # - An envelope recipient is the original, unexpanded recipient that's used in the RCPT
            #   TO command to transmit the message between SMTP servers. When this error is return-
            #   ed by Microsoft 365 or Office 365, the sending server must break up the number of
            #   envelope recipients into smaller chunks (chunking) and resend the message.
            ['4.5.3', 0, 0, 'too many recipients'],

            # Previous versions of Exchange Server ------------------------------------------------
            ['5.2.122', 0, 0, 'the recipient has exceeded their limit for'],

            # Exchange Online ---------------------------------------------------------------------
	        # - The recipient mailbox's ability to accept messages is being throttled because it's
            #   receiving too many messages too quickly. This is done so a single recipient's mail
            #   processing doesn't unfairly impact other recipients sharing the same mailbox data-
            #   base.
            ['4.3.2', 0, 0, 'storedrv.deliver; recipient thread limit exceeded'],

            # - The sender has exceeded the recipient rate limit as described in Sending limits.
            # - This could indicate the account has been compromised and is being used to send
            #   spam.
            ['5.1.90', 0, 0, "your message can't be sent because you've reached your daily limit for message recipients"],

            # - The sender has exceeded the recipient rate limit or the message rate limit as de-
            #   scribed in Sending limits.
            # - This could indicate the account has been compromised and is being used to send
            #   spam.
            ['5.2.2', 0, 0, 'submission quota exceeded'],

            # - The sender has exceeded the maximum number of messages they're allowed to send per
            #   hour to a specific recipient in Exchange Online.
            # - The automated mailer or sender should try again later, and reduce the number of
            #   messages they send per hour to a specific recipient. This limit helps protect
            #   Microsoft 365 or Office 365 users from rapidly filling their inboxes with a large
            #   number of messages from errant automated notification systems or other single-send-
            #   er mail storms.
            ['5.2.121', 0, 0, "recipient's per hour message receive limit from specific sender exceeded"],

            # - The Microsoft 365 or Office 365 recipient has exceeded the number of messages they
            #   can receive per hour from all senders.
            # - The automated mailer or sender should try again later, and reduce the number of
            #   messages they send per hour to a specific recipient. This limit helps protect
            #   Microsoft 365 and Office 365 users from rapidly filling their inboxes with a large
            #   number of messages from errant automated notification systems or other mail storms.
            ['5.2.122', 0, 0, "recipient's per hour message receive limit exceeded"],

            # - Access denied, [$SenderIPAddress] has exceeded permitted limits within $range range
            # - The sender's IPv6 range has attempted to send too many messages in too short a time
            #   period.
            ['5.7.508', 0, 0, 'has exceeded permitted limits within'],

            # - The majority of traffic from this tenant has been detected as suspicious and has
            #   resulted in a ban on sending ability for the tenant.
            # - Ensure that any compromises or open relays have been resolved, and then contact
            #   support through your regular channel. For more information, see Fix email delivery
            #   issues for error codes 5.7.700 through 5.7.750 in Exchange Online.
            ['5.7.', 700, 749, 'access denied, tenant has exceeded threshold'],
            ['5.7.', 700, 749, 'access denied, traffic not accepted from this ip'],
        ],
        'userunknown' => [
            # Exchange Server 2019 ----------------------------------------------------------------
            # - The recipient's email address is incorrect (the recipient doesn't exist in the des-
            #   tination messaging system). Verify the recipient's email address. You recreated a
            #   deleted mailbox, and internal users are addressing email messages in Outlook or
            #   Outlook on the web using old entries in their autocomplete cache (the X.500 values
            #   or LegacyExchangeDN values for the recipient are now different). Tell users to de-
            #   lete the entry from their autocomplete cache and select the recipient again.
            ['5.1.1', 0, 0, 'resolver.adr.exrecipnotfound; not found'],
            ['5.1.1', 0, 0, 'user unknown'],

            # - The recipient's email address is incorrect (for example, it contains unsupported
            #   characters or invalid formatting).
            ['5.1.3', 0, 0, 'storedrv.submit; invalid recipient address'],

            # - Receive connectors reject SMTP connections that contain the top level domains de-
            #   fined in RFC 2606 (.test, .example, .invalid, or .localhost), This behavior is con-
            #   trolled by the RejectReservedTopLevelRecipientDomains parameter on the New-Receive-
            #   Connector and Set-ReceiveConnector cmdlets.
            ['5.1.', 4, 5, 'recipient address reserved by rfc 2606'],

            # - Receive connectors reject SMTP connections that contain single label domains (for
            #   example, chris@contoso instead of chris@contoso.com) This behavior is controlled by
            #   the RejectSingleLabelRecipientDomains parameter on the New-ReceiveConnector and
            #   Set-ReceiveConnector cmdlets.
            ['5.1.6', 0, 0, 'recipient addresses in single label domains not accepted'],

            # Exchange Online ---------------------------------------------------------------------
            # - This failure might be caused by the following conditions:
            #   - The recipient's email address was entered incorrectly by the sender.
            #   - No recipient's exists in the destination email system.
            #   - The recipient's mailbox has been moved and the Outlook recipient cache on the
            #     sender's computer hasn't updated.
            #   - An invalid legacy domain name (DN) exists for the recipient's mailbox Active Di-
            #     rectory Domain Service.
            # - This error typically occurs when the sender of the message incorrectly enters the
            #   email address of the recipient. The sender should check the recipient's email ad-
            #   dress and send again. This error can also occur if the recipient email address was
            #   correct in the past but has changed or has been removed from the destination email
            #   system. If the sender of the message is in the same organization as the recipient,
            #   and the recipient's mailbox still exists, determine whether the recipient's mailbox
            #   has been relocated to a new email server. If this is the case, Outlook might not
            #   have updated the recipient cache correctly. Instruct the sender to remove the re-
            #   cipient's address from sender's Outlook recipient cache and then create a new mes-
            #   sage. Resending the original message will result in the same failure. 
            ['5.1.1', 0, 0, 'bad destination mailbox address'],

            # - The recipient's <SMTP Address> wasn't found by SMTP address lookup.
            ['5.1.10', 0, 0, 'recipient not found'],

            # - The recipient's address doesn't exist.
            ['5.4.1', 0, 0, 'recipient address rejected: access denied'],

            # - The recipient's <SMTP Address> domain is @hotmail.com or @outlook.com and it wasn't
            #   found by SMTP address lookup.
            # - Similar to 550 5.1.10.
            ['5.5.0', 0, 0, 'requested action not taken: mailbox unavailable'],

            # Previous versions of Exchange Server ------------------------------------------------
            ['5.1.2', 0, 0, 'invalid x.400 address'],
        ],
    };

    my $statuscode = $argvs->deliverystatus;
    my $thirddigit = int [split /[.]/, $statuscode]->[-1];
    my $esmtperror = lc  $argvs->diagnosticcode;
    my $reasontext = '';

    REASON: for my $e ( keys %$messagesof ) {
        # The key is a reason name
        for my $f ( @{ $messagesof->{ $e } } ) {
            # ["status-code", min, max, "error message"]
            if( $f->[1] == $f->[2] ) {
                # This error code have no range
                next unless $statuscode eq $f->[0];

            } else {
                # This error code has a range
                next if index($statuscode, $f->[0]) < 0;
                next if $thirddigit < $f->[1]; 
                next if $thirddigit > $f->[2]; 
            }

            next unless index($esmtperror, $f->[3]) > -1;
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

Copyright (C) 2016-2022 azumakuniyuki, All rights reserved.

=head1 LICENSE

This software is distributed under The BSD 2-Clause License.

=cut

