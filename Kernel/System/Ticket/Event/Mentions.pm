# --
# Copyright (C) 2021-2022 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::Ticket::Event::Mentions;

use strict;
use warnings;

use Kernel::System::VariableCheck qw(:all);

our @ObjectDependencies = (
    'Kernel::System::Mention',
    'Kernel::System::Group',
    'Kernel::System::User',
    'Kernel::Output::HTML::Layout',
    'Kernel::Config',
);

sub new {
    my ( $Type, %Param ) = @_;

    my $Self = {};

    bless( $Self, $Type );

    return $Self;
}

sub Run {
    my ( $Self, %Param ) = @_;

    my $MentionObject = $Kernel::OM->Get('Kernel::System::Mention');
    my $LayoutObject  = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $ConfigObject  = $Kernel::OM->Get('Kernel::Config');

    my $Triggers = $ConfigObject->Get('Mentions::RichTextEditor')->{Triggers};

    my $Body = $LayoutObject->ArticlePreview(
        TicketID  => $Param{Data}{TicketID},
        ArticleID => $Param{Data}{ArticleID}
    );
    return {} if !IsStringWithData($Body);

    my @Recipients = ( $Body =~ m{<a class="Mention" href=".*?" target=".*?">$Triggers->{User}(.*?)<\/a>}sg );
    my %Recipients = map { $_ => 1 } @Recipients;

    my @RecipientGroups
        = ( $Body =~ m{<a class="GroupMention" href=".*?" target=".*?">$Triggers->{Group}(.*?)<\/a>}sg );
    my $GroupUsers = {};
    if (@RecipientGroups) {
        $GroupUsers = $Self->_GetUserFromGroup(
            Groups => \@RecipientGroups,
        ) // {};
    }

    %Recipients = ( %Recipients, %{$GroupUsers} );
    return {} if !%Recipients;

    $Self->_GetRecipientAddresses(
        Recipients => \%Recipients,
    );

    # If addresses could not be parsed/verified.
    return {} if !%Recipients;

    $MentionObject->SendNotification(
        Recipients => \%Recipients,
        TicketID   => $Param{Data}{TicketID},
        ArticleID  => $Param{Data}{ArticleID},
    );

    return \%Recipients;
}

sub _GetRecipientAddresses {
    my ( $Self, %Param ) = @_;

    my $UserObject = $Kernel::OM->Get('Kernel::System::User');

    my $Recipients = $Param{Recipients};

    for my $Recipient ( sort keys %{$Recipients} ) {
        my %User = $UserObject->GetUserData(
            User => $Recipient,
        );

        my %UserData;
        for my $Attribute (qw(UserID UserEmail)) {
            $UserData{$Attribute} = $User{$Attribute};
        }

        $Recipients->{$Recipient} = \%UserData;
    }

    return 1;
}

sub _GetUserFromGroup {
    my ( $Self, %Param ) = @_;

    my $GroupObject = $Kernel::OM->Get('Kernel::System::Group');

    my $Groups = $Param{Groups};

    my %Recipients;

    GROUP:
    for my $Group ( @{$Groups} ) {
        my $GroupID = $GroupObject->GroupLookup(
            Group => $Group,
        );

        next GROUP if !$GroupID;

        my %UserList = $GroupObject->PermissionGroupUserGet(
            GroupID => $GroupID,
            Type    => 'ro',
        );

        %Recipients = ( %Recipients, %UserList );
    }

    %Recipients = map { $_ => 1 } values %Recipients;

    return \%Recipients;

}

1;
