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

use Mail::Address;
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

sub GetAvailableConfigOptions {
    my ( $Self, %Param ) = @_;

    my %ConfigOptions = (
        Host => {
            Required     => 1,
            DefaultValue => undef,
        },
        Timeout => {
            Required     => 0,
            DefaultValue => undef,
        },
        SkipSSLVerification => {
            Required     => 0,
            DefaultValue => undef,
        },
        AuthenticationType => {
            Required       => 1,
            DefaultValue   => 'oauth2_token',
            PossibleValues => {
                oauth2_token => {
                    AuthUser => {
                        Required => 1,
                    },
                    OAuth2TokenConfigID => {
                        Required => 1,
                    },
                },
            },
        },
    );

    return \%ConfigOptions;
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
            Value         =>
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
    # Folded To/Cc fields must be read in full. Inserting Bcc after only the first physical line
    # makes the continuation lines part of Bcc, so those recipients disappear from To/Cc.
    #
    my $Header = ${ $Param{Header} };

    $Header = $Self->_AddBccHeader(
        Header  => $Header,
        ToArray => $Param{ToArray},
    );

    my $MIMEMessage = $Header . "\n" . ${ $Param{Body} };

    my $Base64EncodedMIMEMessage = MIME::Base64::encode_base64($MIMEMessage);

    my $To        = join ', ', @{ $Param{ToArray} };
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
        RequestData         => $Base64EncodedMIMEMessage,
        Timeout             => $SendmailModuleConfig{Timeout},
        SkipSSLVerification => $SendmailModuleConfig{SkipSSLVerification},
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

# Graph delivers Bcc and strips that header. To and Cc may be folded across
# several physical lines; the whole field has to be parsed, and Bcc has to be
# inserted after the complete To field so continuation lines stay on To.
sub _AddBccHeader {
    my ( $Self, %Param ) = @_;

    return $Param{Header} if ref $Param{ToArray} ne 'ARRAY';
    return $Param{Header} if !defined $Param{Header};

    my $Header = $Param{Header};

    my %VisibleRecipient;

    FIELD:
    for my $Field (qw(To Cc)) {
        my @FieldValues = $Self->_HeaderFieldValues(
            Header => $Header,
            Name   => $Field,
        );

        FIELDVALUE:
        for my $FieldValue (@FieldValues) {
            next FIELDVALUE if !IsStringWithData($FieldValue);

            EMAIL:
            for my $Email ( Mail::Address->parse($FieldValue) ) {
                next EMAIL if !$Email;

                my $Address = $Email->address();
                next EMAIL if !IsStringWithData($Address);

                $VisibleRecipient{ lc $Address } = 1;
            }
        }
    }

    my %BccRecipient;

    RECIPIENT:
    for my $Recipient ( @{ $Param{ToArray} } ) {
        next RECIPIENT if !IsStringWithData($Recipient);

        my $Address = $Recipient;
        $Address =~ s{\A\s+|\s+\z}{}g;

        next RECIPIENT if !IsStringWithData($Address);
        next RECIPIENT if $VisibleRecipient{ lc $Address };

        $BccRecipient{$Address} = 1;
    }

    return $Header if !%BccRecipient;

    my $BccLine = 'Bcc: ' . join( ', ', sort keys %BccRecipient ) . "\n";

    # Consume the To field including every continuation line and its terminating newline.
    my $Inserted = $Header =~ s{^(To:[^\n]*\n(?:[ \t][^\n]*\n)*)}{$1$BccLine}im;

    if ( !$Inserted ) {
        if ( $Header ne '' ) {
            $Header =~ s{\n*\z}{\n};
        }
        $Header .= $BccLine;
    }

    return $Header;
}

sub _HeaderFieldValues {
    my ( $Self, %Param ) = @_;

    my @Values;
    return @Values if !IsStringWithData( $Param{Header} );
    return @Values if !IsStringWithData( $Param{Name} );

    my $Collecting = 0;
    my @Lines      = split /\n/, $Param{Header};

    LINE:
    for my $Line (@Lines) {
        last LINE if !IsStringWithData($Line);

        if ( $Line =~ m{\A\Q$Param{Name}\E:\s*(.*)\z}i ) {
            push @Values, $1;
            $Collecting = 1;
            next LINE;
        }

        if ( $Collecting && $Line =~ m{\A[ \t]+(.*)\z} ) {
            $Values[-1] .= " $1";
            next LINE;
        }

        $Collecting = 0;
    }

    return @Values;
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
