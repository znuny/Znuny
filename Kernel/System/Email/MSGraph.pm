# --
# Copyright (C) 2021 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::Email::MSGraph;

use strict;
use warnings;

use utf8;

use MIME::Base64;

use Kernel::System::VariableCheck qw(:all);

our @ObjectDependencies = (
    'Kernel::Config',
    'Kernel::System::MSGraph',
    'Kernel::System::OAuth2Token',
    'Kernel::System::OAuth2TokenConfig',
);

sub new {
    my ( $Type, %Param ) = @_;

    my $Self = {%Param};
    bless( $Self, $Type );

    return $Self;
}

sub Send {
    my ( $Self, %Param ) = @_;

    my $ConfigObject            = $Kernel::OM->Get('Kernel::Config');
    my $OAuth2TokenConfigObject = $Kernel::OM->Get('Kernel::System::OAuth2TokenConfig');
    my $OAuth2TokenObject       = $Kernel::OM->Get('Kernel::System::OAuth2Token');
    my $MSGraphObject           = $Kernel::OM->Get('Kernel::System::MSGraph');

    $Param{CommunicationLogObject}->ObjectLogStart(
        ObjectLogType => 'Connection',
    );

    my %SendmailModuleConfig;

    # Required config options
    SENDMAILMODULECONFIGKEY:
    for my $SendmailModuleConfigKey (qw( Host AuthUser AuthenticationType OAuth2TokenConfigName )) {
        my $ConfigValue = $ConfigObject->Get("SendmailModule::$SendmailModuleConfigKey");
        if ( !IsStringWithData($ConfigValue) ) {
            $Param{CommunicationLogObject}->ObjectLog(
                ObjectLogType => 'Connection',
                Priority      => 'Error',
                Key           => ref $Self,
                Value         => "Config option SendmailModule::$SendmailModuleConfigKey is not set.",
            );

            $Param{CommunicationLogObject}->ObjectLogStop(
                ObjectLogType => 'Connection',
                Status        => 'Failed',
            );

            return $Self->_Error(%Param);
        }

        $SendmailModuleConfig{$SendmailModuleConfigKey} = $ConfigValue;
    }

    # Optional config options
    SENDMAILMODULECONFIGKEY:
    for my $SendmailModuleConfigKey (qw( Timeout SkipSSLVerification )) {
        $SendmailModuleConfig{$SendmailModuleConfigKey}
            = $ConfigObject->Get("SendmailModule::$SendmailModuleConfigKey");
    }

    if ( $SendmailModuleConfig{AuthenticationType} ne 'oauth2_token' ) {
        $Param{CommunicationLogObject}->ObjectLog(
            ObjectLogType => 'Connection',
            Priority      => 'Error',
            Key           => ref $Self,
            Value         => "Config option SendmailModule::AuthenticationType must be set to 'oauth2_token'.",
        );

        $Param{CommunicationLogObject}->ObjectLogStop(
            ObjectLogType => 'Connection',
            Status        => 'Failed',
        );

        return $Self->_Error(%Param);
    }

    my %OAuth2TokenConfig = $OAuth2TokenConfigObject->DataGet(
        Name   => $SendmailModuleConfig{OAuth2TokenConfigName},
        UserID => 1,
    );
    if ( !%OAuth2TokenConfig ) {
        $Param{CommunicationLogObject}->ObjectLog(
            ObjectLogType => 'Connection',
            Priority      => 'Error',
            Key           => ref $Self,
            Value => "OAuth2 token config with name '$SendmailModuleConfig{OAuth2TokenConfigName}' could not be found.",
        );

        $Param{CommunicationLogObject}->ObjectLogStop(
            ObjectLogType => 'Connection',
            Status        => 'Failed',
        );

        return $Self->_Error(%Param);
    }

    my $OAuth2Token = $OAuth2TokenObject->GetToken(
        TokenConfigID => $OAuth2TokenConfig{ $OAuth2TokenConfigObject->{Identifier} },
        UserID        => 1,
    );
    if ( !$OAuth2Token ) {
        $Param{CommunicationLogObject}->ObjectLog(
            ObjectLogType => 'Connection',
            Priority      => 'Error',
            Key           => ref $Self,
            Value =>
                "OAuth2 token for config with name '$SendmailModuleConfig{OAuth2TokenConfigName}' could not be retrieved.",
        );

        $Param{CommunicationLogObject}->ObjectLogStop(
            ObjectLogType => 'Connection',
            Status        => 'Failed',
        );

        return $Self->_Error(%Param);
    }

    $Param{CommunicationLogObject}->ObjectLog(
        ObjectLogType => 'Message',
        Priority      => 'Info',
        Key           => ref $Self,
        Value         => 'Received message for sending, validating message content.',
    );

    for my $Needed (qw(Header Body ToArray)) {
        if ( !$Param{$Needed} ) {
            $Param{CommunicationLogObject}->ObjectLog(
                ObjectLogType => 'Message',
                Priority      => 'Error',
                Key           => ref $Self,
                Value         => "Parameter $Needed is missing.",
            );

            return $Self->_Error(
                %Param,
                ErrorMessage => "Parameter $Needed is missing.",
            );
        }
    }

    if ( !$Param{From} ) {
        $Param{From} = '';
    }

    #
    # Add Bcc to MIME message (Graph will send the mail to Bcc but remove the Bcc line from the message).
    # Bcc can be determined by matching To and Cc in the given header with given ToArray. Any address
    # in ToArray not found in To or Cc of header will be added as Bcc.
    #
    my @MIMEMessageRecipients = ( ${ $Param{Header} } =~ m{^(?:To|Cc):\s*(.+?)$}msgi );
    my %BccRecipients;

    TO:
    for my $To ( @{ $Param{ToArray} } ) {
        my $IsMIMEMessageRecipient = grep { $_ =~ m{\b$To\b}i } @MIMEMessageRecipients;
        next TO if $IsMIMEMessageRecipient;

        $BccRecipients{$To} = 1;
    }
    if (%BccRecipients) {
        my $BccRecipientsString = join ', ', sort keys %BccRecipients;

        ${ $Param{Header} } =~ s{(^To:.+?$)}{$1\nBcc: $BccRecipientsString}ims;
    }

    my $MIMEMessage = ${ $Param{Header} } . "\n" . ${ $Param{Body} };

    my $Base64EncodedMIMEMessage = MIME::Base64::encode_base64($MIMEMessage);

    my $To = join ', ', @{ $Param{ToArray} };
    my $EmailSent = $MSGraphObject->ExecuteOperation(
        CommunicationLogObject => $Param{CommunicationLogObject},
        Host                   => $SendmailModuleConfig{Host},

        # Will use proxy of WebUserAgent::Proxy, if configured.
        #Proxy                  => '',

        Login          => $SendmailModuleConfig{AuthUser},
        OAuth2Token    => $OAuth2Token,
        Operation      => '/sendMail',
        RequestType    => 'POST',
        RequestHeaders => {
            'Content-Type' => 'text/plain',
        },
        RequestData => $Base64EncodedMIMEMessage,
    );

    if ($EmailSent) {
        $Param{CommunicationLogObject}->ObjectLog(
            ObjectLogType => 'Message',
            Priority      => 'Info',
            Key           => ref $Self,
            Value         => "Email successfully sent from '$Param{From}' to '$To'.",
        );
    }
    else {
        $Param{CommunicationLogObject}->ObjectLog(
            ObjectLogType => 'Message',
            Priority      => 'Error',
            Key           => ref $Self,
            Value         => "Error sending email from '$Param{From}' to '$To'.",
        );
    }

    $Param{CommunicationLogObject}->ObjectLogStop(
        ObjectLogType => 'Connection',
        Status        => $EmailSent ? 'Successful' : 'Failed',
    );

    if ( !$EmailSent ) {
        return $Self->_Error(
            %Param,
        );
    }

    return $Self->_Success(
        %Param,
    );
}

sub _Success {
    my ( $Self, %Param ) = @_;

    return {
        %Param,
        Success => 1,
    };
}

sub _Error {
    my ( $Self, %Param ) = @_;

    return {
        %Param,
        Success => 0,

        #         SMTPError => 1,
    };
}

1;
