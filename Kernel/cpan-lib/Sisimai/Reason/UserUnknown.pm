package Sisimai::Reason::UserUnknown;
use feature ':5.10';
use strict;
use warnings;

sub text  { 'userunknown' }
sub description { "Email rejected due to a local part of a recipient's email address does not exist" }
sub match {
    # Try to match that the given text and regular expressions
    # @param    [String] argv1  String to be matched with regular expressions
    # @return   [Integer]       0: Did not match
    #                           1: Matched
    # @since v4.0.0
    my $class = shift;
    my $argv1 = shift // return undef;

    state $regex = qr{(?>
         [#]5[.]1[.]1[ ]bad[ ]address
        |[<][^ ]+[>][ ]not[ ]found
        |[<][^ ]+[@][^ ]+[>][.][.][.][ ]blocked[ ]by[ ]
        |550[ ]address[ ]invalid
        |5[.]1[.]0[ ]address[ ]rejected[.]
        |account[ ][^ ]+[ ]does[ ]not[ ]exist[ ]at[ ]the[ ]organization
        |adresse[ ]d[ ]au[ ]moins[ ]un[ ]destinataire[ ]invalide[.][ ]invalid[ ]recipient[.][0-9a-z_]+41[68]
        |address[ ](?:does[ ]not[ ]exist|not[ ]present[ ]in[ ]directory|unknown)
        |archived[ ]recipient
        |bad[-_ \t]recipient
        |can[']t[ ]accept[ ]user
        |does[ ]not[ ]exist[.]
        |destination[ ](?:
             addresses[ ]were[ ]unknown
            |server[ ]rejected[ ]recipients
            )
        |email[ ]address[ ](?:does[ ]not[ ]exist|could[ ]not[ ]be[ ]found)
        |invalid[ ](?:
             address
            |mailbox:?
            |mailbox[ ]path|recipient
            )
        |is[ ]not[ ](?:
             a[ ]known[ ]user
            |a[ ]valid[ ]mailbox
            |an[ ]active[ ]address[ ]at[ ]this[ ]host
            )
        |mailbox[ ](?:
             [^ ]+[ ]does[ ]not[ ]exist
            |[^ ]+[@][^ ]+[ ]unavailable
            |does[ ]not[ ]exist
            |invalid
            |is[ ](?:inactive|unavailable)
            |not[ ](?:present|found)
            |unavailable
            )
        |nessun[ ]utente[ ]simile[ ]in[ ]questo[ ]indirizzo
        |no[ ](?:
             [ ][^ ]+[ ]in[ ]name[ ]directory
            |account[ ]by[ ]that[ ]name[ ]here
            |existe[ ](?:dicha[ ]persona|ese[ ]usuario[ ])
            |mail[ ]box[ ]available[ ]for[ ]this[ ]user
            |mailbox[ ](?:
                 by[ ]that[ ]name[ ]is[ ]currently[ ]available
                |found
                )
            |matches[ ]to[ ]nameserver[ ]query
            |such[ ](?:
                 address[ ]here
                |mailbox
                |person[ ]at[ ]this[ ]address
                |recipient
                |user(?:[ ]here)?
                )
            |thank[ ]you[ ]rejected:[ ]account[ ]unavailable:
            |valid[ ]recipients,[ ]bye
            )
        |non[- ]?existent[ ]user
        |not[ ](?:
             a[ ]valid[ ](?:recipient|user[ ]here)
            |a[ ]local[ ]address
            |email[ ]addresses
            )
        |rcpt[ ][<][^ ]+[>][ ]does[ ]not[ ]exist
        |recipient[ ]address[ ]rejected[.][ ][(]in[ ]reply[ ]to[ ]rcpt[ ]to[ ]command[)]
        |recipient[ ](?:
             [^ ]+[ ]was[ ]not[ ]found[ ]in
            |address[ ]rejected:[ ](?:
                 access[ ]denied
                |invalid[ ]user
                |invalid-recipient
                |user[ ][^ ]+[ ]does[ ]not[ ]exist
                |user[ ]unknown[ ]in[ ][^ ]+[ ]table
                |unknown[ ]user
                )
            |does[ ]not[ ]exist(?:[ ]on[ ]this[ ]system)?
            |is[ ]not[ ]local
            |not[ ](?:exist|found|ok)
            |refuses[ ]to[ ]accept[ ]your[ ]mail
            |unknown
            )
        |requested[ ]action[ ]not[ ]taken:[ ]mailbox[ ]unavailable
        |resolver[.]adr[.]recipient notfound
        |said:[ ]550[-[ ]]5[.]1[.]1[ ][^ ]+[ ]user[ ]unknown[ ]
        |sorry,[ ](?:
             user[ ]unknown
            |badrcptto
            |no[ ]mailbox[ ]here[ ]by[ ]that[ ]name
            |your[ ]envelope[ ]recipient[ ]has[ ]been[ ]denied
            )
        |that[ ]domain[ ]or[ ]user[ ]isn't[ ]in[ ]my[ ]list[ ]of[ ]allowed[ ]rcpthosts
        |the[ ](?:
             email[ ]account[ ]that[ ]you[ ]tried[ ]to[ ]reach[ ]does[ ]not[ ]exist
            |following[ ]recipients[ ]was[ ]undeliverable
            |user[']s[ ]email[ ]name[ ]is[ ]not[ ]found
            )
        |there[ ]is[ ]no[ ]one[ ]at[ ]this[ ]address
        |this[ ](?:
             address[ ]no[ ]longer[ ]accepts[ ]mail
            |email[ ]address[ ]is[ ]wrong[ ]or[ ]no[ ]longer[ ]valid
            |recipient[ ]is[ ]in[ ]my[ ]badrecipientto[ ]list
            |recipient[ ]is[ ]not[ ]in[ ]my[ ]validrcptto[ ]list
            |spectator[ ]does[ ]not[ ]exist
            |user[ ]doesn[']?t[ ]have[ ]a[ ][^ ]+[ ]account
            )
        |unknown[ ](?:
             e[-]?mail[ ]address
            |local[- ]part
            |mailbox
            |recipient
            |user
            )
        |user[ ](?:
             [^ ]+[ ]was[ ]not[ ]found
            |[^ ]+[ ]does[ ]not[ ]exist
            |does[ ]not[ ]exist
            |missing[ ]home[ ]directory
            |not[ ](?:active|exist|found|known)
            |unknown
            )
        |utilisateur[ ]inconnu[ ]!
        |vdeliver:[ ]invalid[ ]or[ ]unknown[ ]virtual[ ]user
        |your[ ]envelope[ ]recipient[ ]is[ ]in[ ]my[ ]badrcptto[ ]list
        )
    }x;
    return 1 if $argv1 =~ $regex;
    return 0;
}

sub true {
    # Whether the address is "userunknown" or not
    # @param    [Sisimai::Data] argvs   Object to be detected the reason
    # @return   [Integer]               1: is unknown user
    #                                   0: is not unknown user.
    # @since v4.0.0
    # @see http://www.ietf.org/rfc/rfc2822.txt
    my $class = shift;
    my $argvs = shift // return undef;
    return 1 if $argvs->reason eq 'userunknown';

    my $tempreason = Sisimai::SMTP::Status->name($argvs->deliverystatus) || '';
    return 0 if $tempreason eq 'suspend';

    my $diagnostic = lc $argvs->diagnosticcode;
    if( $tempreason eq 'userunknown' ) {
        # *.1.1 = 'Bad destination mailbox address'
        #   Status: 5.1.1
        #   Diagnostic-Code: SMTP; 550 5.1.1 <***@example.jp>:
        #     Recipient address rejected: User unknown in local recipient table
        state $prematches = [qw|NoRelaying Blocked MailboxFull HasMoved Rejected NotAccept|];
        state $ModulePath = {
            'Sisimai::Reason::NoRelaying'  => 'Sisimai/Reason/NoRelaying.pm',
            'Sisimai::Reason::Blocked'     => 'Sisimai/Reason/Blocked.pm',
            'Sisimai::Reason::MailboxFull' => 'Sisimai/Reason/MailboxFull.pm',
            'Sisimai::Reason::HasMoved'    => 'Sisimai/Reason/HasMoved.pm',
            'Sisimai::Reason::Rejected'    => 'Sisimai/Reason/Rejected.pm',
            'Sisimai::Reason::NotAccept'   => 'Sisimai/Reason/NotAccept.pm',
        };
        my $matchother = 0;

        for my $e ( @$prematches ) {
            # Check the value of "Diagnostic-Code" with other error patterns.
            my $p = 'Sisimai::Reason::'.$e;
            require $ModulePath->{ $p };

            next unless $p->match($diagnostic);
            # Match with reason defined in Sisimai::Reason::* except UserUnknown.
            $matchother = 1;
            last;
        }
        return 1 unless $matchother;    # Did not match with other message patterns

    } elsif( $argvs->smtpcommand eq 'RCPT' ) {
        # When the SMTP command is not "RCPT", the session rejected by other
        # reason, maybe.
        return 1 if __PACKAGE__->match($diagnostic);
    }
    return 0;
}

1;
__END__

=encoding utf-8

=head1 NAME

Sisimai::Reason::UserUnknown - Bounce reason is C<userunknown> or not.

=head1 SYNOPSIS

    use Sisimai::Reason::UserUnknown;
    print Sisimai::Reason::UserUnknown->match('550 5.1.1 Unknown User');   # 1

=head1 DESCRIPTION

Sisimai::Reason::UserUnknown checks the bounce reason is C<userunknown> or not.
This class is called only Sisimai::Reason class.

This is the error that a local part (Left hand side of @ sign) of a recipient's
email address does not exist. In many case, a user has changed internet service
provider, or has quit company, or the local part is misspelled. Sisimai will set
C<userunknown> to the reason of email bounce if the value of Status: field in a
bounce email is C<5.1.1>, or connection was refused at SMTP RCPT command, or the
contents of Diagnostic-Code: field represents that it is unknown user.

    <kijitora@example.co.jp>: host mx01.example.co.jp[192.0.2.8] said:
      550 5.1.1 Address rejected kijitora@example.co.jp (in reply to
      RCPT TO command)

=head1 CLASS METHODS

=head2 C<B<text()>>

C<text()> returns string: C<userunknown>.

    print Sisimai::Reason::UserUnknown->text;  # userunknown

=head2 C<B<match(I<string>)>>

C<match()> returns 1 if the argument matched with patterns defined in this class.

    print Sisimai::Reason::UserUnknown->match('550 5.1.1 Unknown User');   # 1

=head2 C<B<true(I<Sisimai::Data>)>>

C<true()> returns 1 if the bounce reason is C<userunknown>. The argument must be
Sisimai::Data object and this method is called only from Sisimai::Reason class.

=head1 AUTHOR

azumakuniyuki

=head1 COPYRIGHT

Copyright (C) 2014-2022 azumakuniyuki, All rights reserved.

=head1 LICENSE

This software is distributed under The BSD 2-Clause License.

=cut
