# --
# Copyright (C) 2021-2022 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package scripts::Migration::Znuny6_3::MigrateCalendarBasedTicketCreationTables;    ## no critic

use strict;
use warnings;

use parent qw(scripts::Migration::Base);

our @ObjectDependencies = (
    'Kernel::System::Calendar::Plugin',
    'Kernel::System::DB',
);

sub Run {
    my ( $Self, %Param ) = @_;

    #
    # calendar based ticket creation config to new table calendar_appointment_plugin
    #
    my $NewTableExists = $Self->TableExists( Table => 'calendar_appointment_plugin' );
    if ( !$NewTableExists ) {

        # Create new tables.
        my @XML = (
            '<Table Name="calendar_appointment_plugin">
                <Column Name="id" Required="true" PrimaryKey="true" AutoIncrement="true" Type="INTEGER"/>
                <Column Name="appointment_id" Required="true" Type="SMALLINT"/>
                <Column Name="plugin_key" Required="true" Size="1000" Type="VARCHAR"/>
                <Column Name="config" Required="false" Size="1000000" Type="VARCHAR"/>
                <Column Name="create_time" Required="true" Type="DATE"/>
                <Column Name="create_by" Required="true" Type="INTEGER"/>
                <Column Name="change_time" Required="true" Type="DATE"/>
                <Column Name="change_by" Required="true" Type="INTEGER"/>
                <ForeignKey ForeignTable="users">
                    <Reference Local="create_by" Foreign="id"/>
                    <Reference Local="change_by" Foreign="id"/>
                </ForeignKey>
            </Table>',
        );

        return if !$Self->ExecuteXMLDBArray(
            XMLArray => \@XML,
        );
    }

    my $OldTableExists = $Self->TableExists( Table => 'calendar_ticket_creation' );
    return 1 if !$OldTableExists;

    my $PluginObject = $Kernel::OM->Get('Kernel::System::Calendar::Plugin');
    my $DBObject     = $Kernel::OM->Get('Kernel::System::DB');

    return if !$DBObject->Prepare(
        SQL => '
            SELECT calendar_id, calendar_appointment_id, queue_id, ticket_lock_id, type_id, service_id, sla_id, ticket_priority_id, ticket_state_id, ticket_pending_time, ticket_pending_time_offset, ticket_pending_time_offset_u, owner_id, responsible_user_id, customer_id, customer_user_id, process_id, ticket_create_time, ticket_create_time_typ, ticket_create_offset, ticket_create_offset_unit, ticket_create_offset_point, ticket_created, ticket_link
            FROM calendar_ticket_creation',
        Bind => [],
    );

    my @DataList;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        push @DataList, {
            CalendarID                  => $Row[0],
            AppointmentID               => $Row[1],
            QueueID                     => $Row[2],
            LockID                      => $Row[3],
            TypeID                      => $Row[4],
            ServiceID                   => $Row[5],
            SLAID                       => $Row[6],
            PriorityID                  => $Row[7],
            StateID                     => $Row[8],
            TicketPendingTime           => $Row[9],
            TicketPendingTimeOffset     => $Row[10],
            TicketPendingTimeOffsetUnit => $Row[11],
            OwnerID                     => $Row[12],
            ResponsibleUserID           => $Row[13],
            CustomerID                  => $Row[14],
            CustomerUserID              => $Row[15],
            ProcessID                   => $Row[16],
            TicketCreateTime            => $Row[17],
            TicketCreateTimeType        => $Row[18],
            TicketCreateOffset          => $Row[19],
            TicketCreateOffsetUnit      => $Row[20],
            TicketCreateOffsetPoint     => $Row[21],
            TicketCreated               => $Row[22],
            Link                        => $Row[23],
        };
    }

    for my $Data (@DataList) {
        my $AppointmentID = $Data->{AppointmentID};

        if ( $Data->{QueueID} =~ m{;}g ) {
            my @QueueIDs = split( ";", $Data->{QueueID} );
            $Data->{QueueID} = \@QueueIDs;
        }

        my $CreatedID = $PluginObject->DataAdd(
            AppointmentID => $Data->{AppointmentID},
            PluginKey     => 'TicketCreate',
            Config        => {
                %{$Data},
            },
            CreateBy => 1,
            ChangeBy => 1,
            UserID   => 1,
        );
    }

    return 1;
}

1;
