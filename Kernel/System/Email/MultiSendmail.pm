# --
# Copyright (C) 2021 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::Email::MultiSendmail;

use strict;
use warnings;

use utf8;

use Kernel::System::VariableCheck qw(:all);

use Kernel::System::EmailParser;

our @ObjectDependencies = (
    'Kernel::Config',
    'Kernel::System::Log',
    'Kernel::System::Main',
    'Kernel::System::SendmailConfig',
);

sub new {
    my ( $Type, %Param ) = @_;

    my $Self = {%Param};
    bless( $Self, $Type );

    $Self->{OriginalObjectParam} = \%Param;

    return $Self;
}

sub Check {
    my ( $Self, %Param ) = @_;

    my %Result = (
        Successful => 1,
    );

    return %Result;
}

sub Send {
    my ( $Self, %Param ) = @_;

    my $ConfigObject         = $Kernel::OM->Get('Kernel::Config');
    my $SendmailConfigObject = $Kernel::OM->Get('Kernel::System::SendmailConfig');

    # Retrieve sender (From) from header if parameter has not been given.
    if (
        !IsStringWithData( $Param{From} )
        && IsStringWithData( ${ $Param{Header} } )
        )
    {
        # Check for 'From' is from package MultiSMTP.
        # Copyright (C) 2013 - 2022 Perl-Services.de, https://perl-services.de
        ( $Param{From} ) = ${ $Param{Header} } =~ m{
            ^ From: \s+
                (
                    (?:[^\n]+ )
                    (?: \n ^ \s+ [^\n]+ )*
                )
        }xms;
    }

    my $SendmailConfig;
    if ( IsStringWithData( $Param{From} ) ) {
        my $EmailParserObject = Kernel::System::EmailParser->new(
            Mode  => 'Standalone',
            Debug => 0,
        );

        my $EmailAddress = $EmailParserObject->GetEmailAddress(
            Email => $Param{From},
        );

        $SendmailConfig = $SendmailConfigObject->GetByEmailAddress(
            EmailAddress => $EmailAddress,
            UseFallback  => 1,
        );

        if ( !IsHashRefWithData($SendmailConfig) ) {
            return $Self->_ReturnError(
                ErrorMessage =>
                    'No sendmail config found for sender address "$Param{From}" and no fallback config available.',
            );
        }
    }
    else {
        $SendmailConfig = $SendmailConfigObject->GetFallback();
        if ( !IsHashRefWithData($SendmailConfig) ) {
            return $Self->_ReturnError(
                ErrorMessage => 'No fallback sendmail config found for unknown sender address.',
            );
        }
    }

    my $ConfigObjectUpdated = $Self->_UpdateConfigObjectSettings(
        ConfigObject   => $ConfigObject,
        SendmailConfig => $SendmailConfig,
    );
    if ( !$ConfigObjectUpdated ) {
        return $Self->_ReturnError(
            ErrorMessage => 'Error temporarily updating settings in config object.',
        );
    }

    my $SendmailObject = $Self->_GetSendmailObject(
        SendmailModule => $SendmailConfig->{SendmailModule},
    );
    if ( !$SendmailObject ) {
        return $Self->_ReturnError(
            ErrorMessage => "Error creating email object for $SendmailConfig->{SendmailModule}.",
        );
    }

    my $Result = $SendmailObject->Send(%Param);

    $Kernel::OM->ObjectsDiscard(
        Objects => [ 'Kernel::Config', ],
    );

    return $Result;
}

sub _GetSendmailObject {
    my ( $Self, %Param ) = @_;

    my $LogObject  = $Kernel::OM->Get('Kernel::System::Log');
    my $MainObject = $Kernel::OM->Get('Kernel::System::Main');

    NEEDED:
    for my $Needed (qw(SendmailModule)) {
        next NEEDED if defined $Param{$Needed};

        $LogObject->Log(
            Priority => 'error',
            Message  => "Parameter '$Needed' is needed!",
        );
        return;
    }

    my $PackageName = 'Kernel::System::Email::' . $Param{SendmailModule};

    my $Loaded = $MainObject->Require(
        $PackageName,
        Silent => 0,
    );
    return if !$Loaded;

    my $SendmailObject = $PackageName->new( %{ $Self->{OriginalObjectParam} } );
    return $SendmailObject;
}

sub _UpdateConfigObjectSettings {
    my ( $Self, %Param ) = @_;

    my $LogObject = $Kernel::OM->Get('Kernel::System::Log');

    if (
        ref $Param{ConfigObject} ne 'Kernel::Config'
        || !IsHashRefWithData( $Param{SendmailConfig} )
        )
    {
        $LogObject->Log(
            Priority => 'error',
            Message  => "Parameter 'ConfigObject' and or 'SendmailConfig' missing or invalid.",
        );
        return;
    }

    my $SendmailConfig = $Param{SendmailConfig};
    my $ConfigObject   = $Param{ConfigObject};

    $ConfigObject->Set(
        Key   => 'SendmailModule',
        Value => 'Kernel::System::Email::' . $SendmailConfig->{SendmailModule},
    );

    for my $ConfigKey (
        qw(CMD Host Port Timeout SkipSSLVerification AuthenticationType AuthUser AuthPassword OAuth2TokenConfigName)
        )
    {
        $ConfigObject->Set(
            Key   => "SendmailModule::$ConfigKey",
            Value => $SendmailConfig->{$ConfigKey},
        );
    }

    return 1;
}

sub _ReturnError {
    my ( $Self, %Param ) = @_;

    return {
        Success => 0,
        Message => 'MultiSendmail: ' . $Param{ErrorMessage},
    };
}

1;
