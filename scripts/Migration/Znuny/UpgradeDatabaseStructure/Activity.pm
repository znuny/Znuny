# --
# Copyright (C) 2021 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package scripts::Migration::Znuny::UpgradeDatabaseStructure::Activity;    ## no critic

use strict;
use warnings;
use utf8;

use parent qw(scripts::Migration::Base);

our @ObjectDependencies = (
    'Kernel::System::NotificationEvent',
);

=head1 SYNOPSIS

Adds new activity table

=cut

sub Run {
    my ( $Self, %Param ) = @_;

    return if !$Self->_CreateActivityTable(%Param);
    return if !$Self->_ActivateActivityNotificationEvent(%Param);

    return 1;
}

sub _CreateActivityTable {
    my ( $Self, %Param ) = @_;

    my $ActivityTableExists = $Self->TableExists(
        Table => 'activity',
    );

    return 1 if $ActivityTableExists;

    my @XMLStrings = (
        '<TableCreate Name="activity">
            <Column Name="id" Required="true" PrimaryKey="true" AutoIncrement="true" Type="INTEGER"/>
            <Column Name="user_id" Required="true" Type="INTEGER"/>
            <Column Name="activity_type" Required="true" Size="200" Type="VARCHAR"/>
            <Column Name="activity_title" Required="true" Size="255" Type="VARCHAR"/>
            <Column Name="activity_text" Required="false" Type="LONGBLOB" />
            <Column Name="activity_state" Required="false" Size="255" Type="VARCHAR"/>
            <Column Name="activity_link" Required="false" Size="255" Type="VARCHAR"/>
            <Column Name="create_time" Required="true" Type="DATE"/>
            <Column Name="create_by" Required="true" Type="INTEGER"/>
            <ForeignKey ForeignTable="users">
                <Reference Local="user_id" Foreign="id"/>
                <Reference Local="create_by" Foreign="id"/>
            </ForeignKey>
        </TableCreate>',
    );

    return if !$Self->ExecuteXMLDBArray(
        XMLArray => \@XMLStrings,
    );

    return 1;
}

sub _ActivateActivityNotificationEvent {
    my ( $Self, %Param ) = @_;

    my $NotificationEventObject = $Kernel::OM->Get('Kernel::System::NotificationEvent');
    my %NotificationList        = $NotificationEventObject->NotificationList(
        Details => 1,
        All     => 1,
    );

    NOTIFICATION:
    for my $NotificationID ( sort keys %NotificationList ) {

        my %Notification = %{ $NotificationList{$NotificationID} };

        next NOTIFICATION if !$Notification{Data};
        next NOTIFICATION if !$Notification{Data}->{AgentEnabledByDefault};

        my $EmailEnabled = grep { $_ eq 'Email' } @{ $Notification{Data}->{Transports} };
        next NOTIFICATION if !$EmailEnabled;

        my $AgentEnabledByDefault = grep { $_ eq 'Email' } @{ $Notification{Data}->{AgentEnabledByDefault} };
        next NOTIFICATION if !$AgentEnabledByDefault;

        my %TempTransports = map { $_ => 1 } @{ $Notification{Data}->{Transports} };
        $TempTransports{Activity} = 1;
        @{ $Notification{Data}->{Transports} } = keys %TempTransports;

        my %TempAgentEnabledByDefault = map { $_ => 1 } @{ $Notification{Data}->{AgentEnabledByDefault} };
        $TempAgentEnabledByDefault{Activity} = 1;
        @{ $Notification{Data}->{AgentEnabledByDefault} } = keys %TempAgentEnabledByDefault;

        $NotificationEventObject->NotificationUpdate(
            %Notification,
            UserID => 1,
        );
    }

    return 1;
}

1;
