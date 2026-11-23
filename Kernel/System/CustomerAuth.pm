# --
# Copyright (C) 2001-2021 OTRS AG, https://otrs.com/
# Copyright (C) 2021 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see https://www.gnu.org/licenses/gpl-3.0.txt.
# --

package Kernel::System::CustomerAuth;

use strict;
use warnings;

use Kernel::System::VariableCheck qw(:all);
use Kernel::Language              qw(Translatable);

our @ObjectDependencies = (
    'Kernel::Config',
    'Kernel::System::CustomerUser',
    'Kernel::System::DateTime',
    'Kernel::System::Log',
    'Kernel::System::Main',
    'Kernel::System::SystemMaintenance',
    'Kernel::System::Valid',
);

=head1 NAME

Kernel::System::CustomerAuth - customer authentication module.

=head1 DESCRIPTION

The authentication module for the customer interface.

=head1 PUBLIC INTERFACE

=head2 new()

Don't use the constructor directly, use the ObjectManager instead:

    my $CustomerAuthObject = $Kernel::OM->Get('Kernel::System::CustomerAuth');

=cut

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {};
    bless( $Self, $Type );

    # get needed objects
    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');
    my $MainObject   = $Kernel::OM->Get('Kernel::System::Main');

    # load auth modules
    SOURCE:
    for my $Count ( '', 1 .. 10 ) {
        my $GenericModule = $ConfigObject->Get("Customer::AuthModule$Count");
        next SOURCE if !$GenericModule;

        if ( !$MainObject->Require($GenericModule) ) {
            $MainObject->Die("Can't load backend module $GenericModule! $@");
        }
        $Self->{"Backend$Count"} = $GenericModule->new( %{$Self}, Count => $Count );
    }

    # load 2factor auth modules
    SOURCE:
    for my $Count ( '', 1 .. 10 ) {
        my $GenericModule = $ConfigObject->Get("Customer::AuthTwoFactorModule$Count");
        next SOURCE if !$GenericModule;

        if ( !$MainObject->Require($GenericModule) ) {
            $MainObject->Die("Can't load backend module $GenericModule! $@");
        }
        $Self->{"AuthTwoFactorBackend$Count"} = $GenericModule->new( %{$Self}, Count => $Count );
    }

    # Initialize last error message
    $Self->{LastErrorMessage} = '';

    return $Self;
}

=head2 GetOption()

Get module options. Currently there is just one option, "PreAuth".

    if ($AuthObject->GetOption(What => 'PreAuth')) {
        print "No login screen is needed. Authentication is based on other options. E. g. $ENV{REMOTE_USER}\n";
    }

=cut

sub GetOption {
    my ( $Self, %Param ) = @_;

    # The default slot (Customer::AuthModule without number) may be empty, e.g. if only SAML
    # is configured in numbered slots. No backend there means no options (e.g. no PreAuth).
    return if !$Self->{Backend};

    return $Self->{Backend}->GetOption(%Param);
}

=head2 Auth()

The authentication function.

    if ($AuthObject->Auth(User => $User, Pw => $Pw)) {
        print "Auth ok!\n";
    }
    else {
        print "Auth invalid!\n";
    }

=cut

sub Auth {
    my ( $Self, %Param ) = @_;

    my $ConfigObject       = $Kernel::OM->Get('Kernel::Config');
    my $CustomerUserObject = $Kernel::OM->Get('Kernel::System::CustomerUser');
    my $ValidObject        = $Kernel::OM->Get('Kernel::System::Valid');
    my $LogObject          = $Kernel::OM->Get('Kernel::System::Log');

    # use all 11 backends and return on first auth
    my $User;
    COUNT:
    for my $MainCount ( '', 1 .. 10 ) {

        # next on no config setting
        next COUNT if !$Self->{"Backend$MainCount"};

        # SAML: Only the requested auth backend is checked
        next COUNT if $Param{IsSAMLLogin} && $Param{Count} ne $MainCount;

        # check auth backend
        $User = $Self->{"Backend$MainCount"}->Auth(%Param);

        # next on no success
        next COUNT if !$User;

        # SAML logins can't carry a two factor token, the identity provider posts the response
        # to Znuny. MFA has to be enforced by the identity provider instead. Decided by the
        # backend that authenticated the user, never by the IsSAMLLogin request parameter, which
        # could be sent along with a username/password login to skip two factor authentication.
        my $SkipTwoFactorAuth = $Self->{"Backend$MainCount"}->isa('Kernel::System::CustomerAuth::SAML');

        # check 2factor auth backends
        my $TwoFactorAuth;
        TWOFACTORSOURCE:
        for my $Count ( '', 1 .. 10 ) {

            last TWOFACTORSOURCE if $SkipTwoFactorAuth;

            # return on no config setting
            next TWOFACTORSOURCE if !$Self->{"AuthTwoFactorBackend$Count"};

            # 2factor backend
            my $AuthOk = $Self->{"AuthTwoFactorBackend$Count"}->Auth(
                TwoFactorToken => $Param{TwoFactorToken},
                User           => $User,
            );
            $TwoFactorAuth = $AuthOk ? 'passed' : 'failed';

            last TWOFACTORSOURCE if $AuthOk;
        }

        # if at least one 2factor auth backend was checked but none was successful,
        # it counts as a failed login
        if ( $TwoFactorAuth && $TwoFactorAuth ne 'passed' ) {
            $User = undef;
            last COUNT;
        }

        # remember auth backend
        $CustomerUserObject->SetPreferences(
            Key    => 'UserAuthBackend',
            Value  => $MainCount,
            UserID => $User,
        );
        last COUNT;
    }

    if ( !$User ) {
        return if !defined $Param{User};
        return if !length $Param{User};

        my %CustomerUserData = $CustomerUserObject->CustomerUserDataGet( User => $Param{User} );
        return if !%CustomerUserData;

        my $Count = $CustomerUserData{UserLoginFailed} || 0;
        $Count++;
        $CustomerUserObject->SetPreferences(
            Key    => 'UserLoginFailed',
            Value  => $Count,
            UserID => $CustomerUserData{UserLogin},
        );

        my $BackendConfig = $ConfigObject->Get( $CustomerUserData{Source} );
        return if !IsHashRefWithData($BackendConfig);
        return if $BackendConfig->{ReadOnly};

        # set customer user to invalid-temporarily if max failed logins reached
        my $Config = $ConfigObject->Get('CustomerPreferencesGroups');
        my $PasswordMaxLoginFailed;

        if ( IsHashRefWithData($Config) && $Config->{Password} && $Config->{Password}->{PasswordMaxLoginFailed} ) {
            $PasswordMaxLoginFailed = $Config->{Password}->{PasswordMaxLoginFailed};
        }

        return if !$PasswordMaxLoginFailed;
        return if $Count < $PasswordMaxLoginFailed;

        my $TemporarilyInvalidID = $ValidObject->ValidLookup(
            Valid => 'invalid-temporarily',
        );
        return if !$TemporarilyInvalidID;

        return if !defined $CustomerUserData{ValidID};
        return if $CustomerUserData{ValidID} == $TemporarilyInvalidID;

        # Don't overwrite the password.
        delete $CustomerUserData{UserPassword};

        my $Updated = $CustomerUserObject->CustomerUserUpdate(
            %CustomerUserData,
            ID      => $CustomerUserData{UserLogin},
            ValidID => $TemporarilyInvalidID,
            UserID  => 1,
        );
        return if !$Updated;

        $LogObject->Log(
            Priority => 'notice',
            Message  => "Login failed $Count times. Setting customer user $CustomerUserData{UserLogin} to "
                . "'invalid-temporarily'.",
        );

        return;
    }

    # check if user is valid
    my %CustomerUserData = $CustomerUserObject->CustomerUserDataGet( User => $User );
    return $User if !%CustomerUserData;

    if ( defined $CustomerUserData{ValidID} && $CustomerUserData{ValidID} != 1 ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'notice',
            Message  => "CustomerUser: '$User' is set to invalid, can't login!",
        );
        return;
    }

    # reset failed logins
    $CustomerUserObject->SetPreferences(
        Key    => 'UserLoginFailed',
        Value  => 0,
        UserID => $CustomerUserData{UserLogin},
    );

    # on system maintenance customers
    # shouldn't be allowed to get into the system
    my $ActiveMaintenance = $Kernel::OM->Get('Kernel::System::SystemMaintenance')->SystemMaintenanceIsActive();
    if ($ActiveMaintenance) {
        $Self->{LastErrorMessage} =
            $ConfigObject->Get('SystemMaintenance::IsActiveDefaultLoginErrorMessage')
            || Translatable("It is currently not possible to login due to a scheduled system maintenance.");

        return;
    }

    # last login preferences update
    my $DateTimeObject = $Kernel::OM->Create('Kernel::System::DateTime');

    $CustomerUserObject->SetPreferences(
        Key    => 'UserLastLogin',
        Value  => $DateTimeObject->ToEpoch(),
        UserID => $CustomerUserData{UserLogin},
    );

    return $User;
}

=head2 GetLastErrorMessage()

Retrieve $Self->{LastErrorMessage} content.

    my $AuthErrorMessage = $AuthObject->GetLastErrorMessage();

    Result:

        $AuthErrorMessage = "An error string message.";

=cut

sub GetLastErrorMessage {
    my ( $Self, %Param ) = @_;

    return $Self->{LastErrorMessage};
}

=head2 GetSAMLSLOData()

Returns the NameID/NameIDFormat/SessionIndex of the last successful SAML
login on the given backend slot, if that slot's backend supports it (only
Kernel::System::CustomerAuth::SAML does). Returns an empty list otherwise.

    my %SLOData = $CustomerAuthObject->GetSAMLSLOData(
        Count => $Count,
    );

=cut

sub GetSAMLSLOData {
    my ( $Self, %Param ) = @_;

    my $Count = $Param{Count} // '';

    my $Backend = $Self->{"Backend$Count"};
    return if !$Backend;
    return if !$Backend->can('GetLastSLOData');

    return $Backend->GetLastSLOData();
}

=head2 InitiateSAMLLogout()

Builds a SAML LogoutRequest redirect URL for the given backend slot, if that
slot's backend supports it (only Kernel::System::CustomerAuth::SAML does).
Returns undef if not supported, or if the Identity Provider doesn't
advertise Single Logout.

    my $URL = $CustomerAuthObject->InitiateSAMLLogout(
        Count        => $Count,
        NameID       => $NameID,
        NameIDFormat => $NameIDFormat, # optional
        SessionIndex => $SessionIndex,
    );

=cut

sub InitiateSAMLLogout {
    my ( $Self, %Param ) = @_;

    my $Count = $Param{Count} // '';

    my $Backend = $Self->{"Backend$Count"};
    return if !$Backend;
    return if !$Backend->can('CreateLogoutURL');

    return $Backend->CreateLogoutURL(%Param);
}

=head2 GetSAMLLogoutRequestID()

Returns the ID of the LogoutRequest built by the last InitiateSAMLLogout()
call on the given backend slot, if that slot's backend supports it (only
Kernel::System::CustomerAuth::SAML does). For replay protection.

    my $LogoutRequestID = $CustomerAuthObject->GetSAMLLogoutRequestID(
        Count => $Count,
    );

=cut

sub GetSAMLLogoutRequestID {
    my ( $Self, %Param ) = @_;

    my $Count = $Param{Count} // '';

    my $Backend = $Self->{"Backend$Count"};
    return if !$Backend;
    return if !$Backend->can('GetLastLogoutRequestID');

    return $Backend->GetLastLogoutRequestID();
}

=head2 VerifySAMLLogoutResponse()

Verifies and parses an inbound SAML LogoutResponse redirect on the given
backend slot, if that slot's backend supports it (only
Kernel::System::CustomerAuth::SAML does). Returns undef otherwise.

    my $LogoutResponse = $CustomerAuthObject->VerifySAMLLogoutResponse(
        Count       => $Count,
        QueryString => $QueryString,
    );

=cut

sub VerifySAMLLogoutResponse {
    my ( $Self, %Param ) = @_;

    my $Count = $Param{Count} // '';

    my $Backend = $Self->{"Backend$Count"};
    return if !$Backend;
    return if !$Backend->can('VerifySAMLLogoutResponse');

    return $Backend->VerifySAMLLogoutResponse(%Param);
}

1;

=head1 TERMS AND CONDITIONS

This software is part of the OTRS project (L<https://otrs.org/>).

This software comes with ABSOLUTELY NO WARRANTY. For details, see
the enclosed file COPYING for license information (GPL). If you
did not receive this file, see L<https://www.gnu.org/licenses/gpl-3.0.txt>.

=cut
