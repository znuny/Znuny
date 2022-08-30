# --
# Copyright (C) 2001-2021 OTRS AG, https://otrs.com/
# Copyright (C) 2021-2022 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see https://www.gnu.org/licenses/gpl-3.0.txt.
# --

package Kernel::System::Calendar::Event::Transport::Email;
## nofilter(TidyAll::Plugin::OTRS::Perl::LayoutObject)
## nofilter(TidyAll::Plugin::OTRS::Perl::ParamObject)

use strict;
use warnings;

use Kernel::System::VariableCheck qw(:all);
use Kernel::Language qw(Translatable);

use parent qw(Kernel::System::Calendar::Event::Transport::Base);

our @ObjectDependencies = (
    'Kernel::Config',
    'Kernel::Output::HTML::Layout',
    'Kernel::System::Crypt::PGP',
    'Kernel::System::Crypt::SMIME',
    'Kernel::System::Email',
    'Kernel::System::Log',
    'Kernel::System::Main',
    'Kernel::System::SystemAddress',
    'Kernel::System::Web::Request',
);

=head1 NAME

Kernel::System::Calendar::Event::Transport::Email - email transport layer for appointment notifications

=head1 DESCRIPTION

Notification event transport layer.

=head1 PUBLIC INTERFACE

=head2 new()

create a notification transport object. Do not use it directly, instead use:

    my $TransportObject = $Kernel::OM->Get('Kernel::System::Ticket::Event::NotificationEvent::Transport::Email');

=cut

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {};
    bless( $Self, $Type );

    return $Self;
}

sub SendNotification {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Needed (qw(UserID Notification Recipient)) {
        if ( !$Param{$Needed} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => 'Need $Needed!',
            );
            return;
        }
    }

    # cleanup event data
    $Self->{EventData} = undef;

    # get needed objects
    my $ConfigObject        = $Kernel::OM->Get('Kernel::Config');
    my $SystemAddressObject = $Kernel::OM->Get('Kernel::System::SystemAddress');
    my $LayoutObject        = $Kernel::OM->Get('Kernel::Output::HTML::Layout');

    # get recipient data
    my %Recipient = %{ $Param{Recipient} };

    return if !$Recipient{UserEmail};

    return if $Recipient{UserEmail} !~ /@/;

    my $IsLocalAddress = $Kernel::OM->Get('Kernel::System::SystemAddress')->SystemAddressIsLocalAddress(
        Address => $Recipient{UserEmail},
    );

    return if $IsLocalAddress;

    my %Notification = %{ $Param{Notification} };

    if ( $Param{Notification}->{ContentType} && $Param{Notification}->{ContentType} eq 'text/html' ) {

        # Get configured template with fallback to Default.
        my $EmailTemplate = $Param{Notification}->{Data}->{TransportEmailTemplate}->[0] || 'Default';

        my $Home              = $Kernel::OM->Get('Kernel::Config')->Get('Home');
        my $TemplateDir       = "$Home/Kernel/Output/HTML/Templates/Standard/NotificationEvent/Email";
        my $CustomTemplateDir = "$Home/Custom/Kernel/Output/HTML/Templates/Standard/NotificationEvent/Email";

        if ( !-r "$TemplateDir/$EmailTemplate.tt" && !-r "$CustomTemplateDir/$EmailTemplate.tt" ) {
            $EmailTemplate = 'Default';
        }

        # generate HTML
        $Notification{Body} = $LayoutObject->Output(
            TemplateFile => "NotificationEvent/Email/$EmailTemplate",
            Data         => {
                Body    => $Notification{Body},
                Subject => $Notification{Subject},
            },
        );
    }

    my $FromEmail = $ConfigObject->Get('NotificationSenderEmail');

    # send notification
    my $From = $ConfigObject->Get('NotificationSenderName') . ' <'
        . $FromEmail . '>';

    # security part
    my $SecurityOptions = $Self->SecurityOptionsGet( %Param, FromEmail => $FromEmail );
    return if !$SecurityOptions;

    # get needed objects
    my $EmailObject = $Kernel::OM->Get('Kernel::System::Email');

    my $Sent = $EmailObject->Send(
        From          => $From,
        To            => $Recipient{UserEmail},
        Subject       => $Notification{Subject},
        MimeType      => $Notification{ContentType},
        Type          => $Notification{ContentType},
        Charset       => 'utf-8',
        Body          => $Notification{Body},
        Loop          => 1,
        Attachment    => $Param{Attachments},
        EmailSecurity => $SecurityOptions || {},
    );

    if ( !$Sent->{Success} ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => "'$Notification{Name}' notification could not be sent to agent '$Recipient{UserEmail} ",
        );

        return;
    }

    # log event
    $Kernel::OM->Get('Kernel::System::Log')->Log(
        Priority => 'info',
        Message  => "Sent agent '$Notification{Name}' notification to '$Recipient{UserEmail}'.",
    );

    return 1;
}

sub GetTransportRecipients {
    my ( $Self, %Param ) = @_;

    for my $Needed (qw(Notification)) {
        if ( !$Param{$Needed} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Needed",
            );
        }
    }

    my @Recipients;

    # get recipients by RecipientEmail
    if ( $Param{Notification}->{Data}->{RecipientEmail} ) {
        if ( $Param{Notification}->{Data}->{RecipientEmail}->[0] ) {
            my $RecipientEmail = $Param{Notification}->{Data}->{RecipientEmail}->[0];

            my @RecipientEmails;

            if ( !IsArrayRefWithData($RecipientEmail) ) {

                # Split multiple recipients on known delimiters: comma and semi-colon.
                #   Do this after the OTRS tags were replaced.
                @RecipientEmails = split /[;,\s]+/, $RecipientEmail;
            }
            else {
                @RecipientEmails = @{$RecipientEmail};
            }

            # Include only valid email recipients.
            for my $Recipient ( sort @RecipientEmails ) {
                if ( $Recipient && $Recipient =~ /@/ ) {
                    push @Recipients, {
                        Realname             => '',
                        Type                 => 'Customer',
                        UserEmail            => $Recipient,
                        IsVisibleForCustomer => $Param{Notification}->{Data}->{IsVisibleForCustomer},
                    };
                }
            }
        }
    }

    return @Recipients;
}

sub TransportSettingsDisplayGet {
    my ( $Self, %Param ) = @_;

    KEY:
    for my $Key (qw(RecipientEmail)) {
        next KEY if !$Param{Data}->{$Key};
        next KEY if !defined $Param{Data}->{$Key}->[0];
        $Param{$Key} = $Param{Data}->{$Key}->[0];
    }

    my $Home              = $Kernel::OM->Get('Kernel::Config')->Get('Home');
    my $TemplateDir       = "$Home/Kernel/Output/HTML/Templates/Standard/NotificationEvent/Email";
    my $CustomTemplateDir = "$Home/Custom/Kernel/Output/HTML/Templates/Standard/NotificationEvent/Email";

    my @Files = $Kernel::OM->Get('Kernel::System::Main')->DirectoryRead(
        Directory => $TemplateDir,
        Filter    => '*.tt',
    );
    if ( -d $CustomTemplateDir ) {
        push @Files, $Kernel::OM->Get('Kernel::System::Main')->DirectoryRead(
            Directory => $CustomTemplateDir,
            Filter    => '*.tt',
        );
    }

    # for deduplication
    my %Templates;

    for my $File (@Files) {
        $File =~ s{^.*/([^/]+)\.tt}{$1}smxg;
        $Templates{$File} = $File;
    }

    # get layout object
    my $LayoutObject = $Kernel::OM->Get('Kernel::Output::HTML::Layout');

    $Param{TransportEmailTemplateStrg} = $LayoutObject->BuildSelection(
        Data        => \%Templates,
        Name        => 'TransportEmailTemplate',
        Translation => 0,
        SelectedID  => $Param{Data}->{TransportEmailTemplate},
        Class       => 'Modernize W50pc',
    );

    # security fields

    # get config object
    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');

    my %SecuritySignEncryptOptions;

    if ( $ConfigObject->Get('PGP') ) {
        $SecuritySignEncryptOptions{'PGPSign'}      = Translatable('PGP sign only');
        $SecuritySignEncryptOptions{'PGPCrypt'}     = Translatable('PGP encrypt only');
        $SecuritySignEncryptOptions{'PGPSignCrypt'} = Translatable('PGP sign and encrypt');
    }

    if ( $ConfigObject->Get('SMIME') ) {
        $SecuritySignEncryptOptions{'SMIMESign'}      = Translatable('SMIME sign only');
        $SecuritySignEncryptOptions{'SMIMECrypt'}     = Translatable('SMIME encrypt only');
        $SecuritySignEncryptOptions{'SMIMESignCrypt'} = Translatable('SMIME sign and encrypt');
    }

    # set security settings enabled
    $Param{EmailSecuritySettings} = ( $Param{Data}->{EmailSecuritySettings} ? 'checked="checked"' : '' );
    $Param{SecurityDisabled}      = 0;

    if ( $Param{EmailSecuritySettings} eq '' ) {
        $Param{SecurityDisabled} = 1;
    }

    if ( !IsHashRefWithData( \%SecuritySignEncryptOptions ) ) {
        $Param{EmailSecuritySettings} = 'disabled="disabled"';
        $Param{EmailSecurityInfo}     = Translatable('PGP and SMIME not enabled.');
    }

    # create security methods field
    $Param{EmailSigningCrypting} = $LayoutObject->BuildSelection(
        Data         => \%SecuritySignEncryptOptions,
        Name         => 'EmailSigningCrypting',
        SelectedID   => $Param{Data}->{EmailSigningCrypting},
        Class        => 'Security Modernize W50pc',
        Multiple     => 0,
        Translation  => 1,
        PossibleNone => 1,
        Disabled     => $Param{SecurityDisabled},
    );

    # create missing signing actions field
    $Param{EmailMissingSigningKeys} = $LayoutObject->BuildSelection(
        Data => [
            {
                Key   => 'Skip',
                Value => Translatable('Skip notification delivery'),
            },
            {
                Key   => 'Send',
                Value => Translatable('Send unsigned notification'),
            },
        ],
        Name        => 'EmailMissingSigningKeys',
        SelectedID  => $Param{Data}->{EmailMissingSigningKeys},
        Class       => 'Security Modernize W50pc',
        Multiple    => 0,
        Translation => 1,
        Disabled    => $Param{SecurityDisabled},
    );

    # create missing crypting actions field
    $Param{EmailMissingCryptingKeys} = $LayoutObject->BuildSelection(
        Data => [
            {
                Key   => 'Skip',
                Value => Translatable('Skip notification delivery'),
            },
            {
                Key   => 'Send',
                Value => Translatable('Send unencrypted notification'),
            },
        ],
        Name        => 'EmailMissingCryptingKeys',
        SelectedID  => $Param{Data}->{EmailMissingCryptingKeys},
        Class       => 'Security Modernize W50pc',
        Multiple    => 0,
        Translation => 1,
        Disabled    => $Param{SecurityDisabled},
    );

    # generate HTML
    my $Output = $LayoutObject->Output(
        TemplateFile => 'AdminAppointmentNotificationEventTransportEmailSettings',
        Data         => \%Param,
    );

    return $Output;
}

sub TransportParamSettingsGet {
    my ( $Self, %Param ) = @_;

    for my $Needed (qw(GetParam)) {
        if ( !$Param{$Needed} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Needed",
            );
        }
    }

    # get param object
    my $ParamObject = $Kernel::OM->Get('Kernel::System::Web::Request');

    PARAMETER:
    for my $Parameter (
        qw(RecipientEmail TransportEmailTemplate
        EmailSigningCrypting EmailMissingSigningKeys EmailMissingCryptingKeys
        EmailSecuritySettings)
        )
    {
        my @Data = $ParamObject->GetArray( Param => $Parameter );
        next PARAMETER if !@Data;
        $Param{GetParam}->{Data}->{$Parameter} = \@Data;
    }

    # Note: Example how to set errors and use them
    # on the normal AdminNotificationEvent screen
    # # set error
    # $Param{GetParam}->{$Parameter.'ServerError'} = 'ServerError';

    return 1;
}

sub IsUsable {
    my ( $Self, %Param ) = @_;

    # define if this transport is usable on
    # this specific moment
    return 1;
}

sub SecurityOptionsGet {
    my ( $Self, %Param ) = @_;

    # Verify security options are enabled.
    my $EnableSecuritySettings = $Param{Notification}->{Data}->{EmailSecuritySettings}->[0] || '';

    # Return empty hash ref to continue with email sending (without security options).
    return {} if !$EnableSecuritySettings;

    # Verify if the notification has to be signed or encrypted
    my $SignEncryptNotification = $Param{Notification}->{Data}->{EmailSigningCrypting}->[0] || '';

    # Return empty hash ref to continue with email sending (without security options).
    return {} if !$SignEncryptNotification;

    my %Queue = %{ $Param{Queue} || {} };

    # Define who is going to be the sender (from the given parameters)
    my $NotificationSenderEmail = $Param{FromEmail};

    # Define security options container
    my %SecurityOptions = (
        Method => 'Detached',
    );

    my @SignKeys;
    my @EncryptKeys;
    my $KeyField;

    # Get private and public keys for the given backend (PGP or SMIME)
    if ( $SignEncryptNotification =~ /^PGP/i ) {

        my $PGPObject = $Kernel::OM->Get('Kernel::System::Crypt::PGP');

        if ( !$PGPObject ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "No PGP support!",
            );
            return;
        }

        @SignKeys = $PGPObject->PrivateKeySearch(
            Search => $NotificationSenderEmail,
        );

        # take just valid keys
        @SignKeys = grep { $_->{Status} eq 'good' } @SignKeys;

        # get public keys
        @EncryptKeys = $PGPObject->PublicKeySearch(
            Search => $Param{Recipient}->{UserEmail},
        );

        # Get PGP method (Detached or In-line).
        if ( !$Kernel::OM->Get('Kernel::Output::HTML::Layout')->{BrowserRichText} ) {
            $SecurityOptions{Method} = $Kernel::OM->Get('Kernel::Config')->Get('PGP::Method') || 'Detached';
        }

        $SecurityOptions{Backend} = 'PGP';
        $KeyField = 'Key';
    }
    elsif ( $SignEncryptNotification =~ /^SMIME/i ) {

        my $SMIMEObject = $Kernel::OM->Get('Kernel::System::Crypt::SMIME');

        if ( !$SMIMEObject ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "No SMIME support!",
            );
            return;
        }

        @SignKeys = $Kernel::OM->Get('Kernel::System::Crypt::SMIME')->PrivateSearch(
            Search => $NotificationSenderEmail,
            Valid  => 1,
        );

        @EncryptKeys = $Kernel::OM->Get('Kernel::System::Crypt::SMIME')->CertificateSearch(
            Search => $Param{Recipient}->{UserEmail},
            Valid  => 1,
        );

        $SecurityOptions{Backend} = 'SMIME';
        $KeyField = 'Filename';
    }

    # Initialize sign key container
    my %SignKey;

    # Initialize crypt key container
    my %EncryptKey;

    # Get default signing key from the queue (if applies).
    if ( $Queue{DefaultSignKey} ) {

        my $DefaultSignKey;

        # Convert legacy stored default sign keys.
        if ( $Queue{DefaultSignKey} =~ m{ (?: Inline|Detached ) }msx ) {
            my ( $Type, $SubType, $Key ) = split /::/, $Queue{DefaultSignKey};
            $DefaultSignKey = $Key;
        }
        else {
            my ( $Type, $Key ) = split /::/, $Queue{DefaultSignKey};
            $DefaultSignKey = $Key;
        }

        if ( grep { $_->{$KeyField} eq $DefaultSignKey } @SignKeys ) {
            $SignKey{$KeyField} = $DefaultSignKey;
        }
    }

    # Otherwise take the first signing key available.
    if ( !%SignKey ) {
        SIGNKEY:
        for my $SignKey (@SignKeys) {
            %SignKey = %{$SignKey};
            last SIGNKEY;
        }
    }

    # Also take the first encryption key available.
    CRYPTKEY:
    for my $EncryptKey (@EncryptKeys) {
        %EncryptKey = %{$EncryptKey};
        last CRYPTKEY;
    }

    my $OnMissingSigningKeys = $Param{Notification}->{Data}->{EmailMissingSigningKeys}->[0] || '';

    # Add options to sign the notification
    if ( $SignEncryptNotification =~ /Sign/i ) {

        # Take an action if there are missing signing keys.
        if ( !IsHashRefWithData( \%SignKey ) ) {

            my $Message
                = "Could not sign notification '$Param{Notification}->{Name}' due to missing $SecurityOptions{Backend} sign key for '$NotificationSenderEmail'";

            if ( $OnMissingSigningKeys eq 'Skip' ) {

                # Log skipping notification (return nothing to stop email sending).
                $Kernel::OM->Get('Kernel::System::Log')->Log(
                    Priority => 'notice',
                    Message  => $Message . ', skipping notification distribution!',
                );

                return;
            }

            # Log sending unsigned notification.
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'notice',
                Message  => $Message . ', sending unsigned!',
            );
        }

        # Add signature option if a sign key is available
        else {
            $SecurityOptions{SignKey} = $SignKey{$KeyField};
        }
    }

    my $OnMissingEncryptionKeys = $Param{Notification}->{Data}->{EmailMissingCryptingKeys}->[0] || '';

    # Add options to encrypt the notification
    if ( $SignEncryptNotification =~ /Crypt/i ) {

        # Take an action if there are missing encryption keys.
        if ( !IsHashRefWithData( \%EncryptKey ) ) {

            my $Message
                = "Could not encrypt notification '$Param{Notification}->{Name}' due to missing $SecurityOptions{Backend} encryption key for '$Param{Recipient}->{UserEmail}'";

            if ( $OnMissingEncryptionKeys eq 'Skip' ) {

                # Log skipping notification (return nothing to stop email sending).
                $Kernel::OM->Get('Kernel::System::Log')->Log(
                    Priority => 'notice',
                    Message  => $Message . ', skipping notification distribution!',
                );

                return;
            }

            # Log sending unencrypted notification.
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'notice',
                Message  => $Message . ', sending unencrypted!',
            );
        }

        # Add encrypt option if a encrypt key is available
        else {
            $SecurityOptions{EncryptKeys} = [ $EncryptKey{$KeyField}, ];
        }
    }

    return \%SecurityOptions;

}
1;

=head1 TERMS AND CONDITIONS

This software is part of the OTRS project (L<https://otrs.org/>).

This software comes with ABSOLUTELY NO WARRANTY. For details, see
the enclosed file COPYING for license information (GPL). If you
did not receive this file, see L<https://www.gnu.org/licenses/gpl-3.0.txt>.

=cut
