package Sisimai::Reason::SecurityError;
use feature ':5.10';
use strict;
use warnings;

sub text  { 'securityerror' }
sub description { 'Email rejected due to security violation was detected on a destination host' }
sub match {
    # Try to match that the given text and regular expressions
    # @param    [String] argv1  String to be matched with regular expressions
    # @return   [Integer]       0: Did not match
    #                           1: Matched
    # @since v4.0.0
    my $class = shift;
    my $argv1 = shift // return undef;

    state $regex = qr{(?>
         account[ ]not[ ]subscribed[ ]to[ ]ses
        |authentication[ ](?:
             credentials invalid
            |failure
            |failed;[ ]server[ ][^ ]+[ ]said:  # Postfix
            |required
            |turned[ ]on[ ]in[ ]your[ ]email[ ]client
            )
        |authentification[ ]requise.+[0-9a-z_]+402
        |codes?[ ]d'?[ ]*authentification[ ]invalide.+[0-9a-z_]+305
        |domain[ ][^ ]+[ ]is[ ]a[ ]dead[ ]domain
        |executable[ ]files[ ]are[ ]not[ ]allowed[ ]in[ ]compressed[ ]files
        |insecure[ ]mail[ ]relay
        |recipient[ ]address[ ]rejected:[ ]access[ ]denied
        |sorry,[ ]you[ ]don'?t[ ]authenticate[ ]or[ ]the[ ]domain[ ]isn'?t[ ]in[ ]
                my[ ]list[ ]of[ ]allowed[ ]rcpthosts
        |tls[ ]required[ ]but[ ]not[ ]supported # SendGrid:the recipient mailserver does not support TLS or have a valid certificate
        |unauthenticated[ ]senders[ ]not[ ]allowed
        |user[ ][^ ]+[ ]is[ ]not[ ]authorized[ ]to[ ]perform[ ]ses:sendrawemail[ ]on[ ]resource
        |you[ ]are[ ]not[ ]authorized[ ]to[ ]send[ ]mail,[ ]authentication[ ]is[ ]required
        |verification[ ]failure
        )
    }x;
    return 1 if $argv1 =~ $regex;
    return 0;
}

sub true {
    # The bounce reason is security error or not
    # @param    [Sisimai::Data] argvs   Object to be detected the reason
    # @return   [Integer]               1: is security error
    #                                   0: is not security error
    # @see http://www.ietf.org/rfc/rfc2822.txt
    return undef;
}

1;
__END__

=encoding utf-8

=head1 NAME

Sisimai::Reason::SecurityError - Bounce reason is C<securityerror> or not.

=head1 SYNOPSIS

    use Sisimai::Reason::SecurityError;
    print Sisimai::Reason::SecurityError->match('570 5.7.0 Authentication failure');   # 1

=head1 DESCRIPTION

Sisimai::Reason::SecurityError checks the bounce reason is C<securityerror> or
not. This class is called only Sisimai::Reason class.

This is the error that a security violation was detected on a destination mail
server. Depends on the security policy on the server, a sender's email address
is camouflaged address. Sisimai will set C<securityerror> to the reason of email
bounce if the value of Status: field in a bounce email is C<5.7.*>.

    Action: failed
    Status: 5.7.1
    Remote-MTA: DNS; gmail-smtp-in.l.google.com
    Diagnostic-Code: SMTP; 550-5.7.1 [2001:f22:222:1513:192:0:2:2...
    Last-Attempt-Date: Sun, 29 Nov 2015 14:12:25 +0900

=head1 CLASS METHODS

=head2 C<B<text()>>

C<text()> returns string: C<securityerror>.

    print Sisimai::Reason::SecurityError->text;  # securityerror

=head2 C<B<match(I<string>)>>

C<match()> returns 1 if the argument matched with patterns defined in this class.

    print Sisimai::Reason::SecurityError->match('570 5.7.0 Authentication failure');   # 1

=head2 C<B<true(I<Sisimai::Data>)>>

C<true()> returns 1 if the bounce reason is C<securityerror>. The argument must be
Sisimai::Data object and this method is called only from Sisimai::Reason class.

=head1 AUTHOR

azumakuniyuki

=head1 COPYRIGHT

Copyright (C) 2014-2018,2020 azumakuniyuki, All rights reserved.

=head1 LICENSE

This software is distributed under The BSD 2-Clause License.

=cut
