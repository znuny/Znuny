# --
# Copyright (C) 2001-2021 OTRS AG, https://otrs.com/
# Copyright (C) 2021-2022 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see https://www.gnu.org/licenses/gpl-3.0.txt.
# --

package Kernel::Modules::AdminUserGroup;

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

    # get needed objects
    my $ParamObject  = $Kernel::OM->Get('Kernel::System::Web::Request');
    my $LayoutObject = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');
    my $GroupObject  = $Kernel::OM->Get('Kernel::System::Group');
    my $UserObject   = $Kernel::OM->Get('Kernel::System::User');

    # ------------------------------------------------------------ #
    # user <-> group 1:n
    # ------------------------------------------------------------ #
    if ( $Self->{Subaction} eq 'User' ) {

        # get user data
        my $ID = $ParamObject->GetParam( Param => 'ID' );

        my %UserData = $UserObject->GetUserData(
            UserID => $ID,
        );

        # get group data
        my %GroupData = $GroupObject->GroupList(
            Valid => 1,
        );
        my %Types;
        for my $Type ( @{ $ConfigObject->Get('System::Permission') } ) {

            my %Data = $GroupObject->PermissionUserGroupGet(
                UserID => $ID,
                Type   => $Type,
            );
            $Types{$Type} = \%Data;
        }

        my $Output = $LayoutObject->Header();
        $Output .= $LayoutObject->NavigationBar();
        $Output .= $Self->_Change(
            %Types,
            Data => \%GroupData,
            ID   => $UserData{UserID},
            Name => "$UserData{UserFullname}",
            Type => 'User',
        );
        $Output .= $LayoutObject->Footer();
        return $Output;
    }

    # ------------------------------------------------------------ #
    # group <-> user n:1
    # ------------------------------------------------------------ #
    elsif ( $Self->{Subaction} eq 'Group' ) {

        # get group data
        my $ID = $ParamObject->GetParam( Param => 'ID' );

        my %GroupData = $GroupObject->GroupGet(
            ID => $ID,
        );

        # get user list
        my %UserData = $UserObject->UserList(
            Valid => 1,
        );

        # get user name
        USERID:
        for my $UserID ( sort keys %UserData ) {
            my $Name = $UserObject->UserName(
                UserID => $UserID,
            );
            next USERID if !$Name;
            $UserData{$UserID} .= " ($Name)";
        }

        # get permission list users
        my %Types;
        for my $Type ( @{ $ConfigObject->Get('System::Permission') } ) {

            my %Data = $GroupObject->PermissionGroupUserGet(
                GroupID => $ID,
                Type    => $Type,
            );
            $Types{$Type} = \%Data;
        }

        my $Output = $LayoutObject->Header();
        $Output .= $LayoutObject->NavigationBar();
        $Output .= $Self->_Change(
            %Types,
            Data => \%UserData,
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
        my %UserData = $UserObject->UserList(
            Valid => 1,
        );
        my %NewPermission;
        for my $UserID ( sort keys %UserData ) {
            for my $Permission ( sort keys %Permissions ) {
                $NewPermission{$Permission} = 0;
                my @Array = @{ $Permissions{$Permission} };
                ID:
                for my $ID (@Array) {
                    next ID if !$ID;
                    if ( $UserID == $ID ) {
                        $NewPermission{$Permission} = 1;
                    }
                }
            }
            $GroupObject->PermissionGroupUserAdd(
                UID        => $UserID,
                GID        => $ID,
                Permission => \%NewPermission,
                UserID     => $Self->{UserID},
            );
        }

        # if the user would like to continue editing the group-user relation just redirect to the edit screen
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
    elsif ( $Self->{Subaction} eq 'ChangeUser' ) {

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
        my %GroupData = $GroupObject->GroupList(
            Valid => 1,
        );
        my %NewPermission;
        for my $GroupID ( sort keys %GroupData ) {
            for my $Permission ( sort keys %Permissions ) {
                $NewPermission{$Permission} = 0;
                my @Array = @{ $Permissions{$Permission} };
                ID:
                for my $ID (@Array) {
                    next ID if !$ID;
                    if ( $GroupID eq $ID ) {
                        $NewPermission{$Permission} = 1;
                    }
                }
            }
            $GroupObject->PermissionGroupUserAdd(
                UID        => $ID,
                GID        => $GroupID,
                Permission => \%NewPermission,
                UserID     => $Self->{UserID},
            );
        }

        # if the user would like to continue editing the group-user relation just redirect to the edit screen
        # otherwise return to relations overview
        if (
            defined $ParamObject->GetParam( Param => 'ContinueAfterSave' )
            && ( $ParamObject->GetParam( Param => 'ContinueAfterSave' ) eq '1' )
            )
        {
            return $LayoutObject->Redirect( OP => "Action=$Self->{Action};Subaction=User;ID=$ID" );
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

    my %Data   = %{ $Param{Data} };
    my $Type   = $Param{Type} || 'User';
    my $NeType = $Type eq 'Group' ? 'User' : 'Group';

    my %VisibleType = (
        Group => 'Group',
        User  => 'Agent',
    );

    # get layout object
    my $LayoutObject = $Kernel::OM->Get('Kernel::Output::HTML::Layout');

    $Param{BreadcrumbTitle} = $LayoutObject->{LanguageObject}->Translate("Change Group Relations for Agent");

    if ( $VisibleType{$Type} eq 'Group' ) {
        $Param{BreadcrumbTitle} = $LayoutObject->{LanguageObject}->Translate("Change Agent Relations for Group");
    }

    $LayoutObject->Block(
        Name => 'ActionList',
    );
    $LayoutObject->Block(
        Name => 'ActionOverview',
    );
    $LayoutObject->Block(
        Name => 'ChangeReference',
    );
    $LayoutObject->Block(
        Name => 'Change',
        Data => {
            %Param,
            ActionHome    => 'Admin' . $Type,
            NeType        => $NeType,
            VisibleType   => $VisibleType{$Type},
            VisibleNeType => $VisibleType{$NeType},
        },
    );

    # check if there are groups
    if ( $NeType eq 'Group' ) {
        if ( !%Data ) {
            $LayoutObject->Block(
                Name => 'NoDataFoundMsgList',
                Data => {
                    ColSpan => 8,
                },
            );
        }
    }

    # get config object
    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');

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
                    Mark     => $Mark,
                    Type     => $Type,
                    ID       => $ID,
                    Selected => $Selected,
                    Name     => $Param{Data}->{$ID},
                },
            );
        }
    }

    return $LayoutObject->Output(
        TemplateFile => 'AdminUserGroup',
        Data         => \%Param,
    );
}

sub _Overview {
    my ( $Self, %Param ) = @_;

    # get layout object
    my $LayoutObject = $Kernel::OM->Get('Kernel::Output::HTML::Layout');

    $LayoutObject->Block(
        Name => 'Overview',
    );

    $LayoutObject->Block(
        Name => 'ActionList',
    );
    $LayoutObject->Block(
        Name => 'NewActions',
    );

    $LayoutObject->Block(
        Name => 'UserFilter',
    );
    $LayoutObject->Block(
        Name => 'GroupFilter',
    );
    $LayoutObject->Block(
        Name => 'OverviewResult',
    );

    # get use object
    my $UserObject = $Kernel::OM->Get('Kernel::System::User');

    # get user list
    my %UserData = $UserObject->UserList(
        Valid => 1,
    );

    # get user name
    USERID:
    for my $UserID ( sort keys %UserData ) {
        my $Name = $UserObject->UserName( UserID => $UserID );
        next USERID if !$Name;
        $UserData{$UserID} .= " ($Name)";
    }
    for my $UserID ( sort { uc( $UserData{$a} ) cmp uc( $UserData{$b} ) } keys %UserData ) {

        # set output class
        $LayoutObject->Block(
            Name => 'List1n',
            Data => {
                Name      => $UserData{$UserID},
                Subaction => 'User',
                ID        => $UserID,
            },
        );
    }

    # get group data
    my %GroupData = $Kernel::OM->Get('Kernel::System::Group')->GroupList(
        Valid => 1,
    );

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
            Name => 'NoDataFoundMsg',
            Data => {},
        );
    }

    # return output
    return $LayoutObject->Output(
        TemplateFile => 'AdminUserGroup',
        Data         => \%Param,
    );
}

1;
