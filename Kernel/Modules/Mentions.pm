# --
# Copyright (C) 2021-2022 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::Modules::Mentions;

use strict;
use warnings;

use Kernel::Language qw(Translatable);

our $ObjectManagerDisabled = 1;

sub new {
    my ( $Type, %Param ) = @_;

    my $Self = {%Param};
    bless( $Self, $Type );

    return $Self;
}

sub Run {
    my ( $Self, %Param ) = @_;

    my $JSONObject    = $Kernel::OM->Get('Kernel::System::JSON');
    my $ParamObject   = $Kernel::OM->Get('Kernel::System::Web::Request');
    my $LayoutObject  = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $MentionObject = $Kernel::OM->Get('Kernel::System::Mention');

    my $Data = {};

    my $Subaction = $ParamObject->GetParam( Param => 'Subaction' ) || '';

    if ( $Subaction eq "Remove" ) {

        my %Params;
        for my $Needed (qw(TicketID UserID)) {
            $Params{$Needed} = $ParamObject->GetParam( Param => $Needed );
        }

        $Params{UserID} = $Self->{UserID} if !$Params{UserID};

        $MentionObject->RemoveMention(
            TicketID => $Params{TicketID},
            UserID   => $Params{UserID},
        );
    }
    elsif ( $Subaction eq "GetUsers" ) {
        my $SearchTerm = $ParamObject->GetParam( Param => "SearchTerm" );
        $Data = {
            Users => $Self->_UsersGet(
                SearchTerm => $SearchTerm
            )
        };
    }
    elsif ( $Subaction eq "GetGroups" ) {
        my $SearchTerm = $ParamObject->GetParam( Param => "SearchTerm" );
        $Data = {
            Groups => $Self->_GroupsGet(
                SearchTerm => $SearchTerm
            )
        };
    }

    my $ListEncoded = $JSONObject->Encode(
        Data => $Data,
    );

    return $LayoutObject->Attachment(
        ContentType => 'application/json; charset=' . $LayoutObject->{Charset},
        Content     => $ListEncoded,
        Type        => 'inline',
        NoCache     => 1,
    );
}

sub _UsersGet {
    my ( $Self, %Param ) = @_;

    my $UserObject = $Kernel::OM->Get('Kernel::System::User');

    my %UserList = $UserObject->UserList(
        Type  => 'Short',
        Valid => 1
    );

    my @Users;

    USER:
    for my $User ( sort keys %UserList ) {
        my %CleanUser;
        my %User = $UserObject->GetUserData(
            UserID => $User
        );

        next USER
            if $User{UserFullname} !~ m{\Q$Param{SearchTerm}\E}i
            && $User{UserEmail} !~ m{\Q$Param{SearchTerm}\E}i;

        $CleanUser{id}       = $User{UserID};
        $CleanUser{fullname} = $User{UserFullname};
        $CleanUser{name}     = $User{UserFirstname};
        $CleanUser{email}    = $User{UserEmail};
        $CleanUser{username} = $User{UserLogin};

        push @Users, \%CleanUser;
    }

    return \@Users;
}

sub _GroupsGet {
    my ( $Self, %Param ) = @_;

    my $GroupObject  = $Kernel::OM->Get('Kernel::System::Group');
    my $LayoutObject = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $UserObject   = $Kernel::OM->Get('Kernel::System::User');

    my %Groups = $GroupObject->GroupList(
        Valid => 1,
    );

    my @Groups;

    GROUPID:
    for my $GroupID ( sort keys %Groups ) {
        my $Group = $Groups{$GroupID};
        next GROUPID if index( $Group, $Param{SearchTerm} ) == -1;

        my %UserList = $GroupObject->PermissionGroupUserGet(
            GroupID => $GroupID,
            Type    => 'ro',
        );

        my @UserEmails;

        USER:
        for my $User ( sort keys %UserList ) {
            my %User = $UserObject->GetUserData(
                UserID => $User
            );
            next USER if !%User;

            push @UserEmails, $User{UserEmail};
        }

        my %CleanGroup;
        my $Count        = keys %UserList;
        my $MentionLabel = $LayoutObject->{LanguageObject}->Translate( '%s users will be mentioned', $Count );

        $CleanGroup{id}           = $GroupID;
        $CleanGroup{name}         = $Groups{$GroupID};
        $CleanGroup{mentionLabel} = $MentionLabel;
        $CleanGroup{emails}       = join( ',', @UserEmails );

        push @Groups, \%CleanGroup;
    }

    return \@Groups;
}

1;
