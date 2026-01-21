# --
# Copyright (C) 2021 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::Auth::Sync::SAML;

use strict;
use warnings;

use utf8;

use Kernel::System::VariableCheck qw(:all);

our @ObjectDependencies = (
    'Kernel::Config',
    'Kernel::System::Group',
    'Kernel::System::Log',
    'Kernel::System::User',
);

sub new {
    my ( $Type, %Param ) = @_;

    my $Self = {};
    bless( $Self, $Type );

    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');

    $Self->{Count}        = $Param{Count} || '';
    $Self->{AuthBackends} = [];

    # Assemble SAML auth backends with successful responses
    COUNT:
    for my $Count ( '', 1 .. 10 ) {
        my $ParamKey = "AuthBackend$Count";
        next COUNT if !ref $Param{$ParamKey};
        next COUNT if ref $Param{$ParamKey} ne 'Kernel::System::Auth::SAML';

        push @{ $Self->{AuthBackends} }, $Param{$ParamKey};
    }

    return $Self;
}

sub Sync {
    my ( $Self, %Param ) = @_;

    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');
    my $LogObject    = $Kernel::OM->Get('Kernel::System::Log');
    my $UserObject   = $Kernel::OM->Get('Kernel::System::User');
    my $GroupObject  = $Kernel::OM->Get('Kernel::System::Group');

    if ( !$Param{User} ) {
        $LogObject->Log(
            Priority => 'error',
            Message  => 'Need User!'
        );
        return;
    }

    # Check if there's an auth backend which matches the requested user.
    # This can only be done here (not in new()) because the response is not yet available when this object
    # is being created.
    my @AuthBackends = grep {
        $_->{Response}->IsValid()
            && $_->{Response}->GetNameID() eq $Param{User}
    } @{ $Self->{AuthBackends} };

    return if !@AuthBackends;

    # Only use the first matching auth backend.
    my $AuthBackend = $AuthBackends[0];

    my $UserID = $UserObject->UserLookup(
        UserLogin => $Param{User},
        Silent    => 1,
    );

    my %PermissionsEmpty =
        map { $_ => 0 } @{ $ConfigObject->Get('System::Permission') // [] };

    my %SystemGroups       = $GroupObject->GroupList( Valid => 1 );
    my %SystemGroupsByName = reverse %SystemGroups;

    my %SystemRoles       = $GroupObject->RoleList( Valid => 1 );
    my %SystemRolesByName = reverse %SystemRoles;

    #    sync user
    my $UserSyncMap = $ConfigObject->Get( 'AuthSyncModule::SAML::UserSyncMap' . $Self->{Count} );
    if ( IsHashRefWithData($UserSyncMap) ) {
        my %SyncUser;

        KEY:
        for my $Key ( sort keys %{$UserSyncMap} ) {
            my $Attribute = $UserSyncMap->{$Key};
            next KEY if !$Attribute;

            my $Value = $AuthBackend->{Response}->GetFirstAttributeValue($Attribute);
            next KEY if !defined $Value;

            $SyncUser{$Key} = $Value;
        }

        # add new user
        if ( %SyncUser && !$UserID ) {
            $UserID = $UserObject->UserAdd(
                UserLogin => $Param{User},
                %SyncUser,    # Must contain other parameters required by UserAdd.
                UserType     => 'User',
                ValidID      => 1,
                ChangeUserID => 1,
            );
            if ( !$UserID ) {
                $LogObject->Log(
                    Priority => 'error',
                    Message  => "Could not create user '$Param{User}'.",
                );

                return;
            }

            $LogObject->Log(
                Priority => 'notice',
                Message  => "Initial data for '$Param{User}' created.",
            );

            # sync initial groups
            my $UserSyncInitialGroups = $ConfigObject->Get(
                'AuthSyncModule::SAML::UserSyncInitialGroups' . $Self->{Count}
            );
            if ( IsArrayRefWithData($UserSyncInitialGroups) ) {
                GROUP:
                for my $Group ( @{$UserSyncInitialGroups} ) {

                    # only for valid groups
                    if ( !$SystemGroupsByName{$Group} ) {
                        $LogObject->Log(
                            Priority => 'notice',
                            Message  =>
                                "Invalid group '$Group' in "
                                . "'AuthSyncModule::SAML::UserSyncInitialGroups"
                                . "$Self->{Count}'!",
                        );
                        next GROUP;
                    }

                    $GroupObject->PermissionGroupUserAdd(
                        GID        => $SystemGroupsByName{$Group},
                        UID        => $UserID,
                        Permission => {
                            rw => 1,
                        },
                        UserID => 1,
                    );
                }
            }
        }

        # update user attributes (only if changed)
        elsif (%SyncUser) {
            my %UserData = $UserObject->GetUserData( User => $Param{User} );

            # check for changes
            my $AttributeChange;
            ATTRIBUTE:
            for my $Attribute ( sort keys %SyncUser ) {

                # Treat undef and empty strings as equal.
                my $SyncUserAttribute = $SyncUser{$Attribute} // '';
                my $UserDataAttribute = $UserData{$Attribute} // '';
                next ATTRIBUTE if $SyncUserAttribute eq $UserDataAttribute;

                $AttributeChange = 1;
                last ATTRIBUTE;
            }

            if ($AttributeChange) {
                $UserObject->UserUpdate(
                    %UserData,
                    UserID    => $UserID,
                    UserLogin => $Param{User},
                    %SyncUser,    # Must contain other parameters required by UserUpdate.
                    UserType     => 'User',
                    ChangeUserID => 1,
                );
            }
        }
    }

    # sync SAML groups
    my %GroupPermissionsFromSAML;
    my $UserSyncGroupsDefinition = $ConfigObject->Get(
        'AuthSyncModule::SAML::UserSyncGroupsDefinition' . $Self->{Count}
    );
    my $UserSyncGroupsDefinitionAttribute = $ConfigObject->Get(
        'AuthSyncModule::SAML::UserSyncGroupsDefinition::Attribute' . $Self->{Count}
    );

    if (
        IsStringWithData($UserSyncGroupsDefinitionAttribute)
        && IsHashRefWithData($UserSyncGroupsDefinition)
        )
    {
        my $SAMLGroups = $AuthBackend->{Response}->GetAttributeValues($UserSyncGroupsDefinitionAttribute) // [];

        SAMLGROUP:
        for my $SAMLGroup ( @{$SAMLGroups} ) {
            next SAMLGROUP if !IsHashRefWithData( $UserSyncGroupsDefinition->{$SAMLGroup} );

            # remember group permissions
            my %SyncGroups = %{ $UserSyncGroupsDefinition->{$SAMLGroup} };
            SYNCGROUP:
            for my $SyncGroup ( sort keys %SyncGroups ) {

                # only for valid groups
                if ( !$SystemGroupsByName{$SyncGroup} ) {
                    $LogObject->Log(
                        Priority => 'notice',
                        Message  =>
                            "Invalid group '$SyncGroup' in "
                            . "'AuthSyncModule::SAML::UserSyncGroupsDefinition"
                            . "$Self->{Count}'!",
                    );
                    next SYNCGROUP;
                }

                # if rw permission exists, discard all other permissions
                if ( $SyncGroups{$SyncGroup}->{rw} ) {
                    $GroupPermissionsFromSAML{ $SystemGroupsByName{$SyncGroup} } = {
                        rw => 1,
                    };
                    next SYNCGROUP;
                }

                # remember permissions as provided
                $GroupPermissionsFromSAML{ $SystemGroupsByName{$SyncGroup} } = {
                    %PermissionsEmpty,
                    %{ $SyncGroups{$SyncGroup} },
                };
            }
        }
    }

    # Sync SAML attributes to groups
    my $UserSyncAttributeGroupsDefinition = $ConfigObject->Get(
        'AuthSyncModule::SAML::UserSyncAttributeGroupsDefinition' . $Self->{Count}
    );
    if ( IsHashRefWithData($UserSyncAttributeGroupsDefinition) ) {
        my %SyncConfig = %{$UserSyncAttributeGroupsDefinition};

        for my $Attribute ( sort keys %SyncConfig ) {
            my $FoundAttributeValues = $AuthBackend->{Response}->GetAttributeValues($Attribute) // [];
            my %FoundAttributeValues = map { $_ => 1 } @{$FoundAttributeValues};

            my %AttributeValues = %{ $SyncConfig{$Attribute} };
            ATTRIBUTEVALUE:
            for my $AttributeValue ( sort keys %AttributeValues ) {
                next ATTRIBUTEVALUE if !$FoundAttributeValues{$AttributeValue};
                my %SyncGroups = %{ $AttributeValues{$AttributeValue} };
                SYNCGROUP:
                for my $SyncGroup ( sort keys %SyncGroups ) {

                    # only for valid groups
                    if ( !$SystemGroupsByName{$SyncGroup} ) {
                        $LogObject->Log(
                            Priority => 'notice',
                            Message  =>
                                "Invalid group '$SyncGroup' in "
                                . "'AuthSyncModule::SAML::UserSyncAttributeGroupsDefinition"
                                . "$Self->{Count}'!",
                        );
                        next SYNCGROUP;
                    }

                    # if rw permission exists, discard all other permissions
                    if ( $SyncGroups{$SyncGroup}->{rw} ) {
                        $GroupPermissionsFromSAML{ $SystemGroupsByName{$SyncGroup} } = {
                            rw => 1,
                        };
                        next SYNCGROUP;
                    }

                    # remember permissions as provided
                    $GroupPermissionsFromSAML{ $SystemGroupsByName{$SyncGroup} } = {
                        %PermissionsEmpty,
                        %{ $SyncGroups{$SyncGroup} },
                    };
                }
            }
        }
    }

    # Compare group permissions from SAML with current user group permissions.
    my %GroupPermissionsChanged;

    PERMISSIONTYPE:
    for my $PermissionType ( @{ $ConfigObject->Get('System::Permission') } ) {

        # get current permission for type
        my %GroupPermissions = $GroupObject->PermissionUserGroupGet(
            UserID => $UserID,
            Type   => $PermissionType,
        );

        GROUPID:
        for my $GroupID ( sort keys %SystemGroups ) {
            my $OldPermission = $GroupPermissions{$GroupID} ? 1 : 0;

            # Set the new permission (from SAML) if it exists. If not, set it to a default value
            #   regularly 0 but if SAML has rw permission set it to 1 as PermissionUserGroupGet()
            #   gets all system permissions as 1 if stored permission is rw.
            my $NewPermission = $GroupPermissionsFromSAML{$GroupID}->{$PermissionType}
                || $GroupPermissionsFromSAML{$GroupID}->{rw} ? 1 : 0;

            # Skip permission if it's identical to the already stored one.
            next GROUPID if $OldPermission == $NewPermission;

            # next GROUPID if !exists $GroupPermissionsFromSAML{$GroupID};

            $GroupPermissionsChanged{$GroupID} = $GroupPermissionsFromSAML{$GroupID};
        }
    }

    # update changed group permissions
    if (
        %GroupPermissionsChanged
        && (
            IsHashRefWithData($UserSyncGroupsDefinition)
            || IsHashRefWithData($UserSyncAttributeGroupsDefinition)
        )
        )
    {
        for my $GroupID ( sort keys %GroupPermissionsChanged ) {
            $LogObject->Log(
                Priority => 'notice',
                Message  => "Synced group $SystemGroups{$GroupID} with user $Param{User} via SAML.",
            );
            $GroupObject->PermissionGroupUserAdd(
                GID        => $GroupID,
                UID        => $UserID,
                Permission => $GroupPermissionsChanged{$GroupID} || \%PermissionsEmpty,
                UserID     => 1,
            );
        }
    }

    # sync SAML roles
    my %RolePermissionsFromSAML;

    my $UserSyncRolesDefinitionAttribute = $ConfigObject->Get(
        'AuthSyncModule::SAML::UserSyncRolesDefinition::Attribute' . $Self->{Count}
    );
    my $UserSyncRolesDefinition = $ConfigObject->Get(
        'AuthSyncModule::SAML::UserSyncRolesDefinition' . $Self->{Count}
    );

    if (
        IsStringWithData($UserSyncRolesDefinitionAttribute)
        && IsHashRefWithData($UserSyncRolesDefinition)
        )
    {
        my $SAMLRoles = $AuthBackend->{Response}->GetAttributeValues($UserSyncRolesDefinitionAttribute) // [];

        SAMLROLE:
        for my $SAMLRole ( @{$SAMLRoles} ) {
            next SAMLROLE if !IsHashRefWithData( $UserSyncRolesDefinition->{$SAMLRole} );

            my %SyncRoles = %{ $UserSyncRolesDefinition->{$SAMLRole} };

            SYNCROLE:
            for my $SyncRole ( sort keys %SyncRoles ) {

                # only for valid roles
                if ( !$SystemRolesByName{$SyncRole} ) {
                    $LogObject->Log(
                        Priority => 'notice',
                        Message  =>
                            "Invalid role '$SyncRole' in "
                            . "'AuthSyncModule::SAML::UserSyncRolesDefinition"
                            . "$Self->{Count}'!",
                    );
                    next SYNCROLE;
                }

                # set/overwrite remembered permissions
                $RolePermissionsFromSAML{ $SystemRolesByName{$SyncRole} } =
                    $SyncRoles{$SyncRole};
            }
        }
    }

    # Sync SAML attributes to roles
    my $UserSyncAttributeRolesDefinition = $ConfigObject->Get(
        'AuthSyncModule::SAML::UserSyncAttributeRolesDefinition' . $Self->{Count}
    );

    if ( IsHashRefWithData($UserSyncAttributeRolesDefinition) ) {
        my %SyncConfig = %{$UserSyncAttributeRolesDefinition};
        for my $Attribute ( sort keys %SyncConfig ) {
            my $FoundAttributeValues = $AuthBackend->{Response}->GetAttributeValues($Attribute) // [];
            my %FoundAttributeValues = map { $_ => 1 } @{$FoundAttributeValues};

            my %AttributeValues = %{ $SyncConfig{$Attribute} };
            ATTRIBUTEVALUE:
            for my $AttributeValue ( sort keys %AttributeValues ) {
                next ATTRIBUTEVALUE if !$FoundAttributeValues{$AttributeValue};

                my %SyncRoles = %{ $AttributeValues{$AttributeValue} };
                SYNCROLE:
                for my $SyncRole ( sort keys %SyncRoles ) {

                    # only for valid roles
                    if ( !$SystemRolesByName{$SyncRole} ) {
                        $LogObject->Log(
                            Priority => 'notice',
                            Message  =>
                                "Invalid role '$SyncRole' in "
                                . "'AuthSyncModule::SAML::UserSyncAttributeRolesDefinition"
                                . "$Self->{Count}'!",
                        );
                        next SYNCROLE;
                    }

                    # set/overwrite remembered permissions
                    $RolePermissionsFromSAML{ $SystemRolesByName{$SyncRole} } =
                        $SyncRoles{$SyncRole};
                }
            }
        }
    }

    if (
        IsHashRefWithData($UserSyncRolesDefinition)
        || IsHashRefWithData($UserSyncAttributeRolesDefinition)
        )
    {
        my %UserRoles = $GroupObject->PermissionUserRoleGet(
            UserID => $UserID,
        );

        ROLEID:
        for my $RoleID ( sort keys %SystemRoles ) {

            # if old and new permission for role matches, do nothing
            if (
                ( $UserRoles{$RoleID} && $RolePermissionsFromSAML{$RoleID} )
                ||
                ( !$UserRoles{$RoleID} && !$RolePermissionsFromSAML{$RoleID} )
                )
            {
                next ROLEID;
            }

            $LogObject->Log(
                Priority => 'notice',
                Message  => "Synced role $SystemRoles{$RoleID} with user $Param{User} via SAML.",
            );
            $GroupObject->PermissionRoleUserAdd(
                UID    => $UserID,
                RID    => $RoleID,
                Active => $RolePermissionsFromSAML{$RoleID} || 0,
                UserID => 1,
            );
        }
    }

    return $Param{User};
}

1;
