# --
# Copyright (C) 2001-2021 OTRS AG, https://otrs.com/
# Copyright (C) 2021-2022 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see https://www.gnu.org/licenses/gpl-3.0.txt.
# --

package Kernel::System::Auth;

use strict;
use warnings;

use Kernel::Language qw(Translatable);

our @ObjectDependencies = (
    'Kernel::Config',
    'Kernel::System::DateTime',
    'Kernel::System::Group',
    'Kernel::System::Log',
    'Kernel::System::Main',
    'Kernel::System::SystemMaintenance',
    'Kernel::System::User',
    'Kernel::System::Valid',
);

=head1 NAME

Kernel::System::Auth - agent authentication module.

=head1 DESCRIPTION

The authentication module for the agent interface.

=head1 PUBLIC INTERFACE

=head2 new()

Don't use the constructor directly, use the ObjectManager instead:

    my $AuthObject = $Kernel::OM->Get('Kernel::System::Auth');

=cut

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {};
    bless( $Self, $Type );

    # get needed objects
    my $MainObject   = $Kernel::OM->Get('Kernel::System::Main');
    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');

    # load auth modules
    COUNT:
    for my $Count ( '', 1 .. 10 ) {

        my $GenericModule = $ConfigObject->Get("AuthModule$Count");

        next COUNT if !$GenericModule;

        if ( !$MainObject->Require($GenericModule) ) {
            $MainObject->Die("Can't load backend module $GenericModule! $@");
        }

        $Self->{"AuthBackend$Count"} = $GenericModule->new( Count => $Count );
    }

    # load 2factor auth modules
    COUNT:
    for my $Count ( '', 1 .. 10 ) {

        my $GenericModule = $ConfigObject->Get("AuthTwoFactorModule$Count");

        next COUNT if !$GenericModule;

        if ( !$MainObject->Require($GenericModule) ) {
            $MainObject->Die("Can't load backend module $GenericModule! $@");
        }

        $Self->{"AuthTwoFactorBackend$Count"} = $GenericModule->new( %{$Self}, Count => $Count );
    }

    # load sync modules
    COUNT:
    for my $Count ( '', 1 .. 10 ) {

        my $GenericModule = $ConfigObject->Get("AuthSyncModule$Count");

        next COUNT if !$GenericModule;

        if ( !$MainObject->Require($GenericModule) ) {
            $MainObject->Die("Can't load backend module $GenericModule! $@");
        }

        $Self->{"AuthSyncBackend$Count"} = $GenericModule->new( %{$Self}, Count => $Count );
    }

    # Initialize last error message
    $Self->{LastErrorMessage} = '';

    return $Self;
}

=head2 GetOption()

Get module options. Currently there is just one option, "PreAuth".

    if ( $AuthObject->GetOption( What => 'PreAuth' ) ) {
        print "No login screen is needed. Authentication is based on some other options. E. g. $ENV{REMOTE_USER}\n";
    }

=cut

sub GetOption {
    my ( $Self, %Param ) = @_;

    return $Self->{AuthBackend}->GetOption(%Param);
}

=head2 Auth()

The authentication function.

    if ( $AuthObject->Auth( User => $User, Pw => $Pw ) ) {
        print "Auth ok!\n";
    }
    else {
        print "Auth invalid!\n";
    }

=cut

sub Auth {
    my ( $Self, %Param ) = @_;

    # get needed objects
    my $UserObject   = $Kernel::OM->Get('Kernel::System::User');
    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');

    # use all 11 auth backends and return on first true
    my $User;
    COUNT:
    for my $Count ( '', 1 .. 10 ) {

        # return on no config setting
        next COUNT if !$Self->{"AuthBackend$Count"};

        # check auth backend
        $User = $Self->{"AuthBackend$Count"}->Auth(%Param);

        # next on no success
        next COUNT if !$User;

        # Sync will happen before two factor authentication (if configured)
        # because user might not exist before being created in sync (see bug #11966).
        # A failed two factor auth after successful sync will result
        # in a new or updated user but no information or permission leak.

        # configured auth sync backend
        my $AuthSyncBackend = $ConfigObject->Get("AuthModule::UseSyncBackend$Count");
        if ( !defined $AuthSyncBackend ) {
            $AuthSyncBackend = $ConfigObject->Get("AuthModule{$Count}::UseSyncBackend");
        }

        # for backwards compatibility, OTRS 3.1.1, 3.1.2 and 3.1.3 used this wrong format (see bug#8387)

        # sync with configured auth backend
        if ( defined $AuthSyncBackend ) {

            # if $AuthSyncBackend is defined but empty, don't sync with any backend
            if ($AuthSyncBackend) {

                # sync configured backend
                $Self->{$AuthSyncBackend}->Sync( %Param, User => $User );
            }
        }

        # use all 11 sync backends
        else {
            SOURCE:
            for my $Count ( '', 1 .. 10 ) {

                # return on no config setting
                next SOURCE if !$Self->{"AuthSyncBackend$Count"};

                # sync backend
                $Self->{"AuthSyncBackend$Count"}->Sync( %Param, User => $User );
            }
        }

        # If we have no UserID at this point
        # it means auth was ok but user didn't exist before
        # and wasn't created in sync module.
        # We will skip two factor authentication even if configured
        # because we don't have user data to compare the otp anyway.
        # This will not count as a failed login.
        my $UserID = $UserObject->UserLookup(
            UserLogin => $User,
        );
        last COUNT if !$UserID;

        # check 2factor auth backends
        my $TwoFactorAuth;
        TWOFACTORSOURCE:
        for my $Count ( '', 1 .. 10 ) {

            # return on no config setting
            next TWOFACTORSOURCE if !$Self->{"AuthTwoFactorBackend$Count"};

            # 2factor backend
            my $AuthOk = $Self->{"AuthTwoFactorBackend$Count"}->Auth(
                TwoFactorToken => $Param{TwoFactorToken},
                User           => $User,
                UserID         => $UserID,
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
        $UserObject->SetPreferences(
            Key    => 'UserAuthBackend',
            Value  => $Count,
            UserID => $UserID,
        );

        last COUNT;
    }

    # return if no auth user
    if ( !$User ) {

        # remember failed logins
        my $UserID = $UserObject->UserLookup(
            UserLogin => $Param{User},
        );

        return if !$UserID;

        my %User = $UserObject->GetUserData(
            UserID => $UserID,
            Valid  => 1,
        );

        my $Count = $User{UserLoginFailed} || 0;
        $Count++;

        $UserObject->SetPreferences(
            Key    => 'UserLoginFailed',
            Value  => $Count,
            UserID => $UserID,
        );

        # set agent to invalid-temporarily if max failed logins reached
        my $Config = $ConfigObject->Get('PreferencesGroups');
        my $PasswordMaxLoginFailed;

        if ( $Config && $Config->{Password} && $Config->{Password}->{PasswordMaxLoginFailed} ) {
            $PasswordMaxLoginFailed = $Config->{Password}->{PasswordMaxLoginFailed};
        }

        return if !%User;
        return if !$PasswordMaxLoginFailed;
        return if $Count < $PasswordMaxLoginFailed;

        my $ValidID = $Kernel::OM->Get('Kernel::System::Valid')->ValidLookup(
            Valid => 'invalid-temporarily',
        );

        # Make sure not to accidentially overwrite the password.
        delete $User{UserPw};

        my $Update = $UserObject->UserUpdate(
            %User,
            ValidID      => $ValidID,
            ChangeUserID => 1,
        );

        return if !$Update;

        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'notice',
            Message  => "Login failed $Count times. Set $User{UserLogin} to "
                . "'invalid-temporarily'.",
        );

        return;
    }

    # remember login attributes
    my $UserID = $UserObject->UserLookup(
        UserLogin => $User,
    );

    return $User if !$UserID;

    # on system maintenance just admin users
    # should be allowed to get into the system
    my $ActiveMaintenance = $Kernel::OM->Get('Kernel::System::SystemMaintenance')->SystemMaintenanceIsActive();

    # reset failed logins
    $UserObject->SetPreferences(
        Key    => 'UserLoginFailed',
        Value  => 0,
        UserID => $UserID,
    );

    # check if system maintenance is active
    if ($ActiveMaintenance) {

        # check if user is allow to login
        # get current user groups
        my %Groups = $Kernel::OM->Get('Kernel::System::Group')->PermissionUserGet(
            UserID => $UserID,
            Type   => 'move_into',
        );

        # reverse groups hash for easy look up
        %Groups = reverse %Groups;

        # check if the user is in the Admin group
        # if that is not the case return
        if ( !$Groups{admin} ) {

            $Self->{LastErrorMessage} =
                $ConfigObject->Get('SystemMaintenance::IsActiveDefaultLoginErrorMessage')
                || Translatable("It is currently not possible to login due to a scheduled system maintenance.");

            return;
        }
    }

    # last login preferences update
    $UserObject->SetPreferences(
        Key    => 'UserLastLogin',
        Value  => $Kernel::OM->Create('Kernel::System::DateTime')->ToEpoch(),
        UserID => $UserID,
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

1;

=head1 TERMS AND CONDITIONS

This software is part of the OTRS project (L<https://otrs.org/>).

This software comes with ABSOLUTELY NO WARRANTY. For details, see
the enclosed file COPYING for license information (GPL). If you
did not receive this file, see L<https://www.gnu.org/licenses/gpl-3.0.txt>.

=cut
