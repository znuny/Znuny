# --
# Copyright (C) 2021 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::Auth::SAML;

use strict;
use warnings;
use utf8;

use Kernel::System::Auth::SAML::Request;
use Kernel::System::Auth::SAML::Response;

use Kernel::System::VariableCheck qw(:all);

our @ObjectDependencies = (
    'Kernel::Config',
    'Kernel::System::Log',
);

sub new {
    my ( $Type, %Param ) = @_;

    my $Self = {};
    bless( $Self, $Type );

    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');
    my $LogObject    = $Kernel::OM->Get('Kernel::System::Log');

    $Self->{Count} = $Param{Count} || '';

    $Self->{Config} = {};
    my $ConfigOptionPrefix = 'AuthModule::SAML::';

    #
    # Required config options
    #
    CONFIGKEY:
    for my $ConfigKey (
        qw(RequestLoginButtonText RequestAssertionConsumerURL Issuer)
        )
    {
        $Self->{Config}->{$ConfigKey} = $ConfigObject->Get("$ConfigOptionPrefix$ConfigKey$Self->{Count}");
        next CONFIGKEY if defined $Self->{Config}->{$ConfigKey};

        $LogObject->Log(
            Priority => 'error',
            Message  => "Need config $ConfigOptionPrefix$ConfigKey$Param{Count}.",
        );
        return;
    }

    for my $ConfigKey (
        qw(RequestMetaDataURL RequestMetaDataXML)
        )
    {
        $Self->{Config}->{$ConfigKey} = $ConfigObject->Get("$ConfigOptionPrefix$ConfigKey$Self->{Count}");
    }

    if (
        ( !$Self->{Config}->{RequestMetaDataURL} && !$Self->{Config}->{RequestMetaDataXML} )
        || ( $Self->{Config}->{RequestMetaDataURL} && $Self->{Config}->{RequestMetaDataXML} )
        )
    {

        $LogObject->Log(
            Priority => 'error',
            Message  =>
                "Either give config ${ConfigOptionPrefix}RequestMetaDataURL$Param{Count} OR ::RequestMetaDataXML$Param{Count}.",
        );
        return;
    }

    #
    # Optional config options
    #
    for my $ConfigKey (
        qw(RequestMetaDataURLSSLOptions RequestSignKey IdPCACert)
        )
    {
        $Self->{Config}->{$ConfigKey} = $ConfigObject->Get("$ConfigOptionPrefix$ConfigKey$Self->{Count}");
    }

    $Self->{Request} = Kernel::System::Auth::SAML::Request->new(
        Count  => $Self->{Count},
        Config => $Self->{Config},
    );

    $Self->{Response} = Kernel::System::Auth::SAML::Response->new(
        Count  => $Self->{Count},
        Config => $Self->{Config},
    );

    return $Self;
}

sub GetOption {
    my ( $Self, %Param ) = @_;

    my $LogObject = $Kernel::OM->Get('Kernel::System::Log');

    if ( !$Param{What} ) {
        $LogObject->Log(
            Priority => 'error',
            Message  => "Need 'What'!",
        );
        return;
    }

    my %Option = (
        PreAuth => 0,
    );

    return $Option{ $Param{What} };
}

sub Auth {
    my ( $Self, %Param ) = @_;

    my $LogObject = $Kernel::OM->Get('Kernel::System::Log');

    return if !$Param{SAMLResponse};

    my $ResponseDecoded = $Self->{Response}->DecodeResponse(
        Response => $Param{SAMLResponse},
    );
    if ( !$ResponseDecoded ) {
        $LogObject->Log(
            Priority => 'error',
            Message  => 'Error decoding SAML response.',
        );

        return;
    }

    my $ResponseIsValid = $Self->{Response}->IsValid(
        ExpectedSAMLRequestID => $Param{ExpectedSAMLRequestID},
    );
    if ( !$ResponseIsValid ) {
        $LogObject->Log(
            Priority => 'error',
            Message  => 'SAML response is not valid.',
        );

        return;
    }

    my $UserID = $Self->{Response}->GetNameID();
    return $UserID;
}

1;
