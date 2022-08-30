# --
# Copyright (C) 2001-2021 OTRS AG, https://otrs.com/
# Copyright (C) 2021-2022 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see https://www.gnu.org/licenses/gpl-3.0.txt.
# --

package Kernel::Modules::AdminRoleGroup;

use strict;
use warnings;

our $ObjectManagerDisabled = 1;

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {%Param};
    bless( $Self, $Type );

    return $Self;
}

sub Run {
    my ( $Self, %Param ) = @_;

    my $LayoutObject = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $ParamObject  = $Kernel::OM->Get('Kernel::System::Web::Request');
    my $GroupObject  = $Kernel::OM->Get('Kernel::System::Group');
    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');

    # ------------------------------------------------------------ #
    # user <-> group 1:n
    # ------------------------------------------------------------ #
    if ( $Self->{Subaction} eq 'Role' ) {

        # get user data
        my $ID       = $ParamObject->GetParam( Param => 'ID' );
        my %RoleData = $GroupObject->RoleGet( ID => $ID );

        # get group data
        my %GroupData = $GroupObject->GroupList( Valid => 1 );
        my %Types;
        for my $Type ( @{ $ConfigObject->Get('System::Permission') } ) {
            my %Data = $GroupObject->PermissionRoleGroupGet(
                RoleID => $ID,
                Type   => $Type,
            );
            $Types{$Type} = \%Data;
        }

        my $Output = $LayoutObject->Header();
        $Output .= $LayoutObject->NavigationBar();
        $Output .= $Self->_Change(
            %Types,
            Data => \%GroupData,
            ID   => $RoleData{ID},
            Name => $RoleData{Name},
            Type => 'Role',
        );
        $Output .= $LayoutObject->Footer();
        return $Output;
    }

    # ------------------------------------------------------------ #
    # group <-> user n:1
    # ------------------------------------------------------------ #
    elsif ( $Self->{Subaction} eq 'Group' ) {

        # get group data
        my $ID        = $ParamObject->GetParam( Param => 'ID' );
        my %GroupData = $GroupObject->GroupGet( ID => $ID );

        # get user list
        my %RoleData = $GroupObject->RoleList( Valid => 1 );

        # get permission list users
        my %Types;
        for my $Type ( @{ $ConfigObject->Get('System::Permission') } ) {
            my %Data = $GroupObject->PermissionGroupRoleGet(
                GroupID => $ID,
                Type    => $Type,
            );
            $Types{$Type} = \%Data;
        }

        my $Output = $LayoutObject->Header();
        $Output .= $LayoutObject->NavigationBar();
        $Output .= $Self->_Change(
            %Types,
            Data => \%RoleData,
            ID   => $GroupData{ID},
            Name => $GroupData{Name},
            Type => 'Group',
        );
        $Output .= $LayoutObject->Footer();
        return $Output;
    }

    # ------------------------------------------------------------ #
    # add user to groups
    # ------------------------------------------------------------ #
    elsif ( $Self->{Subaction} eq 'ChangeGroup' ) {

        # challenge token check for write action
        $LayoutObject->ChallengeTokenCheck();

        my $ID = $ParamObject->GetParam( Param => 'ID' ) || '';

        # get new groups
        my %Permissions;
        for my $Type ( @{ $ConfigObject->Get('System::Permission') } ) {
            my @IDs = $ParamObject->GetArray( Param => $Type );
            $Permissions{$Type} = \@IDs;
        }

        # get group data
        my %RoleData = $GroupObject->RoleList( Valid => 1 );
        my %NewPermission;
        for my $RoleID ( sort keys %RoleData ) {
            for my $Permission ( sort keys %Permissions ) {
                $NewPermission{$Permission} = 0;
                my @Array = @{ $Permissions{$Permission} };
                ID:
                for my $ID (@Array) {
                    next ID if !$ID;
                    if ( $RoleID == $ID ) {
                        $NewPermission{$Permission} = 1;
                    }
                }
            }
            $GroupObject->PermissionGroupRoleAdd(
                RID        => $RoleID,
                GID        => $ID,
                Permission => \%NewPermission,
                UserID     => $Self->{UserID},
            );
        }

        # if the user would like to continue editing the role-group relation just redirect to the edit screen
        # otherwise return to relations overview
        if (
            defined $ParamObject->GetParam( Param => 'ContinueAfterSave' )
            && ( $ParamObject->GetParam( Param => 'ContinueAfterSave' ) eq '1' )
            )
        {
            return $LayoutObject->Redirect( OP => "Action=$Self->{Action};Subaction=Group;ID=$ID" );
        }
        else {
            return $LayoutObject->Redirect( OP => "Action=$Self->{Action}" );
        }
    }

    # ------------------------------------------------------------ #
    # groups to user
    # ------------------------------------------------------------ #
    elsif ( $Self->{Subaction} eq 'ChangeRole' ) {

        # challenge token check for write action
        $LayoutObject->ChallengeTokenCheck();

        my $ID = $ParamObject->GetParam( Param => 'ID' );

        # get new groups
        my %Permissions;
        for my $Type ( @{ $ConfigObject->Get('System::Permission') } ) {
            my @IDs = $ParamObject->GetArray( Param => $Type );
            $Permissions{$Type} = \@IDs;
        }

        # get group data
        my %GroupData = $GroupObject->GroupList( Valid => 1 );
        my %NewPermission;
        for my $GroupID ( sort keys %GroupData ) {
            for my $Permission ( sort keys %Permissions ) {
                $NewPermission{$Permission} = 0;
                my @Array = @{ $Permissions{$Permission} };
                ID:
                for my $ID (@Array) {
                    next ID if !$ID;
                    if ( $GroupID == $ID ) {
                        $NewPermission{$Permission} = 1;
                    }
                }
            }
            $GroupObject->PermissionGroupRoleAdd(
                RID        => $ID,
                GID        => $GroupID,
                Permission => \%NewPermission,
                UserID     => $Self->{UserID},
            );
        }

        # if the user would like to continue editing the group-role relation just redirect to the edit screen
        # otherwise return to relations overview
        if (
            defined $ParamObject->GetParam( Param => 'ContinueAfterSave' )
            && ( $ParamObject->GetParam( Param => 'ContinueAfterSave' ) eq '1' )
            )
        {
            return $LayoutObject->Redirect( OP => "Action=$Self->{Action};Subaction=Role;ID=$ID" );
        }
        else {
            return $LayoutObject->Redirect( OP => "Action=$Self->{Action}" );
        }
    }

    # ------------------------------------------------------------ #
    # overview
    # ------------------------------------------------------------ #
    my $Output = $LayoutObject->Header();
    $Output .= $LayoutObject->NavigationBar();
    $Output .= $Self->_Overview();
    $Output .= $LayoutObject->Footer();
    return $Output;
}

sub _Change {
    my ( $Self, %Param ) = @_;

    my $LayoutObject = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');

    my %Data   = %{ $Param{Data} };
    my $Type   = $Param{Type} || 'Role';
    my $NeType = $Type eq 'Group' ? 'Role' : 'Group';

    $Param{BreadcrumbTitle} = $LayoutObject->{LanguageObject}->Translate("Change Group Relations for Role");

    if ( $Type eq 'Group' ) {
        $Param{BreadcrumbTitle} = $LayoutObject->{LanguageObject}->Translate("Change Role Relations for Group");
    }

    $LayoutObject->Block(
        Name => 'Overview',
        Data => \%Param,
    );

    $LayoutObject->Block(
        Name => 'Change',
        Data => {
            %Param,
            ActionHome => 'Admin' . $Type,
            NeType     => $NeType,
        },
    );

    $LayoutObject->Block( Name => 'ActionList' );
    $LayoutObject->Block( Name => 'ActionOverview' );

    # check if there are groups/roles
    if ( !%Data ) {
        $LayoutObject->Block(
            Name => 'NoDataFoundMsgList',
            Data => {
                ColSpan => 8,
            },
        );
    }

    my @Permissions;

    TYPE:
    for my $Type ( @{ $ConfigObject->Get('System::Permission') } ) {
        next TYPE if !$Type;
        my $Mark = $Type eq 'rw' ? "Highlight" : '';
        $LayoutObject->Block(
            Name => 'ChangeHeader',
            Data => {
                %Param,
                Mark => $Mark,
                Type => $Type,
            },
        );

        push @Permissions, $Type;
    }

    # set permissions
    $LayoutObject->AddJSData(
        Key   => 'RelationItems',
        Value => \@Permissions,
    );

    for my $ID ( sort { uc( $Data{$a} ) cmp uc( $Data{$b} ) } keys %Data ) {

        # set output class
        $LayoutObject->Block(
            Name => 'ChangeRow',
            Data => {
                %Param,
                Name   => $Param{Data}->{$ID},
                ID     => $ID,
                NeType => $NeType,
            },
        );
        TYPE:
        for my $Type ( @{ $ConfigObject->Get('System::Permission') } ) {
            next TYPE if !$Type;
            my $Mark     = $Type eq 'rw'        ? "Highlight"          : '';
            my $Selected = $Param{$Type}->{$ID} ? ' checked="checked"' : '';

            $LayoutObject->Block(
                Name => 'ChangeRowItem',
                Data => {
                    %Param,
                    Name     => $Param{Data}->{$ID},
                    Mark     => $Mark,
                    Type     => $Type,
                    ID       => $ID,
                    Selected => $Selected,
                },
            );
        }
    }

    return $LayoutObject->Output(
        TemplateFile => 'AdminRoleGroup',
        Data         => \%Param,
    );
}

sub _Overview {
    my ( $Self, %Param ) = @_;

    my $LayoutObject = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $GroupObject  = $Kernel::OM->Get('Kernel::System::Group');

    $LayoutObject->Block(
        Name => 'Overview',
        Data => {},
    );

    $LayoutObject->Block(
        Name => 'OverviewAction',
        Data => {},
    );

    # get user list
    my %RoleData = $GroupObject->RoleList( Valid => 1 );

    if (%RoleData) {
        for my $RoleID ( sort { uc( $RoleData{$a} ) cmp uc( $RoleData{$b} ) } keys %RoleData ) {

            # set output class
            $LayoutObject->Block(
                Name => 'List1n',
                Data => {
                    Name      => $RoleData{$RoleID},
                    Subaction => 'Role',
                    ID        => $RoleID,
                },
            );
        }
    }
    else {
        $LayoutObject->Block(
            Name => 'NoDataFoundMsgRole',
            Data => {},
        );
    }

    # get group data
    my %GroupData = $GroupObject->GroupList( Valid => 1 );

    if (%GroupData) {
        for my $GroupID ( sort { uc( $GroupData{$a} ) cmp uc( $GroupData{$b} ) } keys %GroupData ) {

            # set output class
            $LayoutObject->Block(
                Name => 'Listn1',
                Data => {
                    Name      => $GroupData{$GroupID},
                    Subaction => 'Group',
                    ID        => $GroupID,
                },
            );
        }
    }
    else {
        $LayoutObject->Block(
            Name => 'NoDataFoundMsgGroup',
            Data => {},
        );
    }

    # return output
    return $LayoutObject->Output(
        TemplateFile => 'AdminRoleGroup',
        Data         => \%Param,
    );
}

1;
