# --
# Copyright (C) 2001-2021 OTRS AG, https://otrs.com/
# Copyright (C) 2021-2022 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see https://www.gnu.org/licenses/gpl-3.0.txt.
# --

package Kernel::Output::HTML::ArticleCheck::SMIME;

use strict;
use warnings;

use Kernel::System::EmailParser;
use Kernel::Language qw(Translatable);

our @ObjectDependencies = (
    'Kernel::Config',
    'Kernel::System::Crypt::SMIME',
    'Kernel::System::Log',
    'Kernel::System::Ticket::Article',
    'Kernel::Output::HTML::Layout',
);

sub new {
    my ( $Type, %Param ) = @_;

    my $Self = {};
    bless( $Self, $Type );

    for my $Needed (qw(UserID ArticleID)) {
        if ( $Param{$Needed} ) {
            $Self->{$Needed} = $Param{$Needed};
        }
        else {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Needed!"
            );
        }
    }

    return $Self;
}

sub Check {
    my ( $Self, %Param ) = @_;

    my %SignCheck;
    my @Return;

    my $ConfigObject = $Param{ConfigObject} || $Kernel::OM->Get('Kernel::Config');
    my $LayoutObject = $Param{LayoutObject} || $Kernel::OM->Get('Kernel::Output::HTML::Layout');

    my $UserType     = $LayoutObject->{UserType} // '';
    my $ChangeUserID = $UserType eq 'Customer' ? $ConfigObject->Get('CustomerPanelUserID') : $Self->{UserID};

    # check if smime is enabled
    return if !$ConfigObject->Get('SMIME');

    # check if article is an email
    my $ArticleBackendObject
        = $Kernel::OM->Get('Kernel::System::Ticket::Article')->BackendForArticle( %{ $Param{Article} // {} } );
    return if $ArticleBackendObject->ChannelNameGet() ne 'Email';

    my $SMIMEObject = $Kernel::OM->Get('Kernel::System::Crypt::SMIME');

    # check inline smime
    if ( $Param{Article}->{Body} && $Param{Article}->{Body} =~ /^-----BEGIN PKCS7-----/ ) {
        %SignCheck = $SMIMEObject->Verify( Message => $Param{Article}->{Body} );
        if (%SignCheck) {

            # remember to result
            $Self->{Result} = \%SignCheck;
        }
        else {

            # return with error
            push(
                @Return,
                {
                    Key   => Translatable('Signed'),
                    Value => Translatable('"S/MIME SIGNED MESSAGE" header found, but invalid!'),
                }
            );
        }
    }

    # check smime
    else {

        # get email from fs
        my $Message = $ArticleBackendObject->ArticlePlain(
            TicketID  => $Param{Article}->{TicketID},
            ArticleID => $Self->{ArticleID},
            UserID    => $Self->{UserID},
        );
        return if !$Message;

        my @Email = ();
        my @Lines = split( /\n/, $Message );
        for my $Line (@Lines) {
            push( @Email, $Line . "\n" );
        }

        my $ParserObject = Kernel::System::EmailParser->new(
            Email => \@Email,
        );

        use MIME::Parser;
        my $Parser = MIME::Parser->new();
        $Parser->decode_headers(0);
        $Parser->extract_nested_messages(0);
        $Parser->output_to_core("ALL");
        my $Entity = $Parser->parse_data($Message);
        my $Head   = $Entity->head();
        $Head->unfold();
        $Head->combine('Content-Type');
        my $ContentType = $Head->get('Content-Type');

        if (
            $ContentType
            && $ContentType =~ /application\/(x-pkcs7|pkcs7)-mime/i
            && $ContentType !~ /signed/i
            )
        {

            # check if article is already decrypted
            if ( $Param{Article}->{Body} && $Param{Article}->{Body} ne '- no text message => see attachment -' ) {
                push(
                    @Return,
                    {
                        Key        => Translatable('Crypted'),
                        Value      => Translatable('Ticket decrypted before'),
                        Successful => 1,
                    }
                );
            }

            # check sender (don't decrypt sent emails)
            if ( $Param{Article}->{SenderType} && $Param{Article}->{SenderType} =~ /(agent|system)/i ) {

                # return info
                return (
                    {
                        Key        => Translatable('Crypted'),
                        Value      => Translatable('Sent message encrypted to recipient!'),
                        Successful => 1,
                    }
                );
            }

            # get all email addresses on article
            my %EmailsToSearch;
            for my $Email (qw(Resent-To Envelope-To To Cc Delivered-To X-Original-To)) {

                my @EmailAddressOnField = $ParserObject->SplitAddressLine(
                    Line => $ParserObject->GetParam( WHAT => $Email ),
                );

                # filter email addresses avoiding repeated and save on hash to search
                for my $EmailAddress (@EmailAddressOnField) {
                    my $CleanEmailAddress = $ParserObject->GetEmailAddress(
                        Email => $EmailAddress,
                    );
                    $EmailsToSearch{$CleanEmailAddress} = '1';
                }
            }

            # look for private keys for every email address
            # extract every resulting cert and put it into an hash of hashes avoiding repeated
            my %PrivateKeys;
            for my $EmailAddress ( sort keys %EmailsToSearch ) {
                my @PrivateKeysResult = $SMIMEObject->PrivateSearch(
                    Search => $EmailAddress,
                );
                for my $Cert (@PrivateKeysResult) {
                    $PrivateKeys{ $Cert->{Filename} } = $Cert;
                }
            }

            # search private cert to decrypt email
            if ( !%PrivateKeys ) {
                push(
                    @Return,
                    {
                        Key   => Translatable('Crypted'),
                        Value => Translatable('Impossible to decrypt: private key for email was not found!'),
                    }
                );
                return @Return;
            }

            my %Decrypt;
            PRIVATESEARCH:
            for my $CertResult ( values %PrivateKeys ) {

                # decrypt
                %Decrypt = $SMIMEObject->Decrypt(
                    Message            => $Message,
                    SearchingNeededKey => 1,
                    %{$CertResult},
                );
                last PRIVATESEARCH if ( $Decrypt{Successful} );
            }

            # ok, decryption went fine
            if ( $Decrypt{Successful} ) {

                push(
                    @Return,
                    {
                        Key   => Translatable('Crypted'),
                        Value => $Decrypt{Message} || Translatable('Successful decryption'),
                        %Decrypt,
                    }
                );

                # store decrypted data
                my $EmailContent = $Decrypt{Data};

                # now check if the data contains a signature too
                %SignCheck = $SMIMEObject->Verify(
                    Message => $Decrypt{Data},
                );

                if ( $SignCheck{SignatureFound} ) {

                    # If the signature was verified well, use the stripped content to store the email.
                    #   Now it contains only the email without other SMIME generated data.
                    $EmailContent = $SignCheck{Content} if $SignCheck{Successful};

                    push(
                        @Return,
                        {
                            Key   => Translatable('Signed'),
                            Value => $SignCheck{Message},
                            %SignCheck,
                        }
                    );
                }

                # parse the decrypted email body
                my $ParserObject = Kernel::System::EmailParser->new(
                    Email => $EmailContent
                );
                my $Body = $ParserObject->GetMessageBody();

                # from RFC 3850
                # 3.  Using Distinguished Names for Internet Mail
                #
                #   End-entity certificates MAY contain ...
                #
                #    ...
                #
                #   Sending agents SHOULD make the address in the From or Sender header
                #   in a mail message match an Internet mail address in the signer's
                #   certificate.  Receiving agents MUST check that the address in the
                #   From or Sender header of a mail message matches an Internet mail
                #   address, if present, in the signer's certificate, if mail addresses
                #   are present in the certificate.  A receiving agent SHOULD provide
                #   some explicit alternate processing of the message if this comparison
                #   fails, which may be to display a message that shows the recipient the
                #   addresses in the certificate or other certificate details.

                # as described in bug#5098 and RFC 3850 an alternate mail handling should be
                # made if sender and signer addresses does not match

                # get original sender from email
                my @OrigEmail        = map {"$_\n"} split( /\n/, $Message );
                my $ParserObjectOrig = Kernel::System::EmailParser->new(
                    Email => \@OrigEmail,
                );

                my $OrigFrom        = $ParserObjectOrig->GetParam( WHAT => 'From' );
                my $OrigFromEmail   = $ParserObjectOrig->GetEmailAddress( Email => $OrigFrom );
                my $OrigSender      = $ParserObjectOrig->GetParam( WHAT => 'Sender' );
                my $OrigSenderEmail = $ParserObjectOrig->GetEmailAddress( Email => $OrigSender );

                # compare sender email to signer email
                my $SignerSenderMatch = 0;
                SIGNER:
                for my $Signer ( @{ $SignCheck{Signers} } ) {
                    if (
                        $OrigFromEmail =~ m{\A \Q$Signer\E \z}xmsi
                        || $OrigSenderEmail =~ m{\A \Q$Signer\E \z}xmsi
                        )
                    {
                        $SignerSenderMatch = 1;
                        last SIGNER;
                    }
                }

                # sender email does not match signing certificate!
                if ( !$SignerSenderMatch ) {
                    $SignCheck{Successful} = 0;
                    $SignCheck{Message} =~ s/successful/failed!/;
                    $SignCheck{Message} .= " (signed by "
                        . join( ' | ', @{ $SignCheck{Signers} } )
                        . ")"
                        . ", but neither $OrigFromEmail nor $OrigSenderEmail match the certificate address!";
                }

                # Determine if we have decrypted article and attachments before.
                my %Index = $ArticleBackendObject->ArticleAttachmentIndex(
                    ArticleID => $Self->{ArticleID},
                );

                if (
                    !grep { $Index{$_}->{ContentType} =~ m{ application/ (?: x- )? pkcs7-mime }xms } sort keys %Index
                    )
                {
                    return @Return;
                }

                # updated article body
                $ArticleBackendObject->ArticleUpdate(
                    TicketID  => $Param{Article}->{TicketID},
                    ArticleID => $Self->{ArticleID},
                    Key       => 'Body',
                    Value     => $Body,
                    UserID    => $ChangeUserID,
                );

                # delete crypted attachments
                $ArticleBackendObject->ArticleDeleteAttachment(
                    ArticleID => $Self->{ArticleID},
                    UserID    => $ChangeUserID,
                );

                # write attachments to the storage
                for my $Attachment ( $ParserObject->GetAttachments() ) {
                    $ArticleBackendObject->ArticleWriteAttachment(
                        %{$Attachment},
                        ArticleID => $Self->{ArticleID},
                        UserID    => $ChangeUserID,
                    );
                }

                return @Return;
            }
            else {
                push(
                    @Return,
                    {
                        Key   => Translatable('Crypted'),
                        Value => "$Decrypt{Message}",
                        %Decrypt,
                    }
                );
            }
        }

        if (
            $ContentType
            && $ContentType =~ /application\/(x-pkcs7|pkcs7)/i
            && $ContentType =~ /signed/i
            )
        {

            # check sign and get clear content
            %SignCheck = $SMIMEObject->Verify(
                Message => $Message,
            );

            # parse and update clear content
            if ( %SignCheck && $SignCheck{Successful} && $SignCheck{Content} ) {

                my @Email = ();
                my @Lines = split( /\n/, $SignCheck{Content} );
                for my $Line (@Lines) {
                    push( @Email, $Line . "\n" );
                }
                my $ParserObject = Kernel::System::EmailParser->new(
                    Email => \@Email,
                );
                my $Body = $ParserObject->GetMessageBody();

                # from RFC 3850
                # 3.  Using Distinguished Names for Internet Mail
                #
                #   End-entity certificates MAY contain ...
                #
                #    ...
                #
                #   Sending agents SHOULD make the address in the From or Sender header
                #   in a mail message match an Internet mail address in the signer's
                #   certificate.  Receiving agents MUST check that the address in the
                #   From or Sender header of a mail message matches an Internet mail
                #   address, if present, in the signer's certificate, if mail addresses
                #   are present in the certificate.  A receiving agent SHOULD provide
                #   some explicit alternate processing of the message if this comparison
                #   fails, which may be to display a message that shows the recipient the
                #   addresses in the certificate or other certificate details.

                # as described in bug#5098 and RFC 3850 an alternate mail handling should be
                # made if sender and signer addresses does not match

                # get original sender from email
                my @OrigEmail        = map {"$_\n"} split( /\n/, $Message );
                my $ParserObjectOrig = Kernel::System::EmailParser->new(
                    Email => \@OrigEmail,
                );

                my $OrigFrom        = $ParserObjectOrig->GetParam( WHAT => 'From' );
                my $OrigFromEmail   = $ParserObjectOrig->GetEmailAddress( Email => $OrigFrom );
                my $OrigSender      = $ParserObjectOrig->GetParam( WHAT => 'Sender' );
                my $OrigSenderEmail = $ParserObjectOrig->GetEmailAddress( Email => $OrigSender );

                # compare sender email to signer email
                my $SignerSenderMatch = 0;
                SIGNER:
                for my $Signer ( @{ $SignCheck{Signers} } ) {
                    if (
                        $OrigFromEmail =~ m{\A \Q$Signer\E \z}xmsi
                        || $OrigSenderEmail =~ m{\A \Q$Signer\E \z}xmsi
                        )
                    {
                        $SignerSenderMatch = 1;
                        last SIGNER;
                    }
                }

                # sender email does not match signing certificate!
                if ( !$SignerSenderMatch ) {
                    $SignCheck{Successful} = 0;
                    $SignCheck{Message} =~ s/successful/failed!/;
                    $SignCheck{Message} .= " (signed by "
                        . join( ' | ', @{ $SignCheck{Signers} } )
                        . ")"
                        . ", but neither $OrigFromEmail nor $OrigSenderEmail match the certificate address!";
                }

                # Determine if we have decrypted article and attachments before.
                my %Index = $ArticleBackendObject->ArticleAttachmentIndex(
                    ArticleID => $Self->{ArticleID},
                );

                if (
                    grep { $Index{$_}->{ContentType} =~ m{ application/ (?: x- )? pkcs7 }xms } sort keys %Index
                    )
                {

                    # Update article body.
                    $ArticleBackendObject->ArticleUpdate(
                        TicketID  => $Param{Article}->{TicketID},
                        ArticleID => $Self->{ArticleID},
                        Key       => 'Body',
                        Value     => $Body,
                        UserID    => $ChangeUserID,
                    );

                    # Delete crypted attachments.
                    $ArticleBackendObject->ArticleDeleteAttachment(
                        ArticleID => $Self->{ArticleID},
                        UserID    => $ChangeUserID,
                    );

                    # Write decrypted attachments to the storage.
                    for my $Attachment ( $ParserObject->GetAttachments() ) {
                        $ArticleBackendObject->ArticleWriteAttachment(
                            %{$Attachment},
                            ArticleID => $Self->{ArticleID},
                            UserID    => $ChangeUserID,
                        );
                    }
                }

            }

            # output signature verification errors
            elsif (
                %SignCheck
                && !$SignCheck{SignatureFound}
                && !$SignCheck{Successful}
                && !$SignCheck{Content}
                )
            {

                # return result
                push(
                    @Return,
                    {
                        Key   => Translatable('Signed'),
                        Value => $SignCheck{Message},
                        %SignCheck,
                    }
                );
            }
        }
    }

    if ( $SignCheck{SignatureFound} ) {

        # return result
        push(
            @Return,
            {
                Key   => Translatable('Signed'),
                Value => $SignCheck{Message},
                %SignCheck,
            }
        );
    }
    return @Return;
}

sub Filter {
    my ( $Self, %Param ) = @_;

    # remove signature if one is found
    if ( $Self->{Result}->{SignatureFound} ) {

        # remove SMIME begin signed message
        $Param{Article}->{Body} =~ s/^-----BEGIN\sPKCS7-----.+?Hash:\s.+?$//sm;

        # remove SMIME inline sign
        $Param{Article}->{Body} =~ s/^-----END\sPKCS7-----//sm;
    }
    return 1;
}
1;
