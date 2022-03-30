# --
# Copyright (C) 2021-2022 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --
## nofilter(TidyAll::Plugin::OTRS::Perl::Pod::NamePod)

package scripts::Migration::Znuny6_3::MigrateSysConfigSettings;    ## no critic

use strict;
use warnings;

use parent qw(scripts::Migration::Base);

our @ObjectDependencies = (
    'Kernel::System::SysConfig',
);

=head1 SYNOPSIS

Migrates SysConfig settings.

=cut

sub Run {
    my ( $Self, %Param ) = @_;

    my $SysConfigObject = $Kernel::OM->Get('Kernel::System::SysConfig');

    # Todo: DEPRECATED. Don't use this function any more. Delete me and use:
    # $SysConfigMigrationObject->MigrateSysConfigSettings()

    #
    # Handle renamed SysConfig.
    #
    my %MigrateSysConfig = (

        # Znuny(4OTRS)-DatabaseBackend
        'Znuny4OTRSDatabaseBackend###Export###DefaultFormat' => [
            'DBCRUD###Export###DefaultFormat',
        ],
        'Znuny4OTRSDatabaseBackend###Export###CSV###Separator' => [
            'DBCRUD###Export###CSV###Separator',
        ],
        'Znuny4OTRSDatabaseBackend###Export###CSV###Quote"' => [
            'DBCRUD###Export###CSV###Quote',
        ],
        'ZnunyDatabaseBackend###Export###DefaultFormat' => [
            'DBCRUD###Export###DefaultFormat',
        ],
        'ZnunyDatabaseBackend###Export###CSV###Separator' => [
            'DBCRUD###Export###CSV###Separator',
        ],
        'ZnunyDatabaseBackend###Export###CSV###Quote"' => [
            'DBCRUD###Export###CSV###Quote',
        ],

        # Znuny(4OTRS)-OwnerToolbar
        'Frontend::Module###AgentTicketOwnerView' => [
            'Frontend::Module###AgentTicketOwnerView',
        ],
        'Loader::Module::AgentTicketOwnerView###002-Znuny4OTRSOwnerToolbar' => [
            'Loader::Module::AgentTicketOwnerView###002-Ticket',
        ],
        'Frontend::Navigation###AgentTicketOwnerView###002-Znuny4OTRSOwnerToolbar' => [
            'Frontend::Navigation###AgentTicketOwnerView###002-Ticket',
        ],
        'Frontend::ToolBarModule###9-Ticket::TicketOwner' => [
            'Frontend::ToolBarModule###191-Ticket::TicketOwner',
        ],

        # Znuny(4OTRS)-CalendarBasedTicketCreation
        'Ticket::Frontend::AgentAppointmentEdit###StateType' => [
            'AppointmentCalendar::Plugin::TicketCreate###StateType'
        ],
        'Ticket::Frontend::AgentAppointmentEdit###StateDefault' => [
            'AppointmentCalendar::Plugin::TicketCreate###StateDefault'
        ],
        'Ticket::Frontend::AgentAppointmentEdit###PriorityDefault' => [
            'AppointmentCalendar::Plugin::TicketCreate###PriorityDefault'
        ],
        'Ticket::Frontend::AgentAppointmentEdit###ProcessTreeView' => [
            'AppointmentCalendar::Plugin::TicketCreate###ProcessTreeView'
        ],
        'Ticket::Frontend::AgentAppointmentEdit###Group' => [
            'AppointmentCalendar::Plugin::TicketCreate###Group'
        ],
        'Znuny4OTRSCalendarBasedTicketCreation###Title' => [
            'AppointmentCalendar::Plugin::TicketCreate###Title'
        ],
        'Znuny4OTRSCalendarBasedTicketCreation###Body' => [
            'AppointmentCalendar::Plugin::TicketCreate###Body'
        ],
        'Znuny4OTRSCalendarBasedTicketCreation###ArticleChannelName' => [
            'AppointmentCalendar::Plugin::TicketCreate###ArticleChannelName'
        ],
        'Znuny4OTRSCalendarBasedTicketCreation###ArticleIsVisibleForCustomer' => [
            'AppointmentCalendar::Plugin::TicketCreate###ArticleIsVisibleForCustomer'
        ],
        'Znuny4OTRSCalendarBasedTicketCreation###SenderType' => [
            'AppointmentCalendar::Plugin::TicketCreate###SenderType'
        ],
        'Znuny4OTRSCalendarBasedTicketCreation###From' => [
            'AppointmentCalendar::Plugin::TicketCreate###From'
        ],
        'Znuny4OTRSCalendarBasedTicketCreation###HistoryType' => [
            'AppointmentCalendar::Plugin::TicketCreate###HistoryType'
        ],
        'Znuny4OTRSCalendarBasedTicketCreation###HistoryComment' => [
            'AppointmentCalendar::Plugin::TicketCreate###HistoryComment'
        ],
        'Znuny4OTRSCalendarBasedTicketCreation###ContentType' => [
            'AppointmentCalendar::Plugin::TicketCreate###ContentType'
        ],
        'Znuny4OTRSCalendarBasedTicketCreation::TicketCreationCatchUpThreshold' => [
            'AppointmentCalendar::Plugin::TicketCreate###TicketCreateCatchUpThreshold'
        ],
        'Daemon::SchedulerCronTaskManager::Task###Znuny4OTRSCalendarBasedTicketCreation' => [
            'Daemon::SchedulerCronTaskManager::Task###CalendarTicketCreate'
        ],
        'Daemon::SchedulerCronTaskManager::Task###Znuny4OTRSCalendarBasedTicketCreationCleanup' => [
            'Daemon::SchedulerCronTaskManager::Task###CalendarTicketCreateCleanup'
        ],
        'Loader::Module::AgentAppointmentCalendarOverview###999-Znuny4OTRSCalendarBasedTicketCreation' => [
            'Loader::Module::AgentAppointmentCalendarOverview###500-AppointmentCalendar::Plugin::TicketCreate'
        ],
    );

    SYSCONFIG:
    for my $SysConfigName ( sort keys %MigrateSysConfig ) {

        my %Setting = $SysConfigObject->SettingGet(
            Name    => $SysConfigName,
            NoLog   => 1,
            NoCache => 1,
        );

        next SYSCONFIG if !%Setting;

        my $NewSysConfigNames = $MigrateSysConfig{$SysConfigName};
        for my $NewSysConfigName ( @{$NewSysConfigNames} ) {

            my $SettingUpdated = $Self->SettingUpdate(
                Name           => $NewSysConfigName,
                IsValid        => 1,
                EffectiveValue => $Setting{EffectiveValue},
                UserID         => 1,
            );

            next SYSCONFIG if $SettingUpdated;

            print "\n    Error: Unable to migrate value of SysConfig $SysConfigName to $NewSysConfigName\n\n";
            next SYSCONFIG;
        }
    }

    return 1;
}

1;
