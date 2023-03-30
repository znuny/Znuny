# --
# Copyright (C) 2021 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::ProcessManagement::TransitionAction::AppointmentUpdate;

use strict;
use warnings;
use utf8;

use parent qw(Kernel::System::ProcessManagement::TransitionAction::Base);

our @ObjectDependencies = (
    'Kernel::System::Calendar',
    'Kernel::System::Calendar::Appointment',
    'Kernel::System::Log',
);

=head1 NAME

Kernel::System::ProcessManagement::TransitionAction::AppointmentUpdate - A module to update an appointment

=head1 SYNOPSIS

All AppointmentUpdate functions.

=head1 PUBLIC INTERFACE

=head2 new()

create an object. Do not use it directly, instead use:

    my $AppointmentUpdateObject = $Kernel::OM->Get('Kernel::System::ProcessManagement::TransitionAction::AppointmentUpdate');

=cut

sub new {
    my ( $Type, %Param ) = @_;

    my $Self = {};
    bless( $Self, $Type );

    return $Self;
}

=head2 Run()

Runs TransitionAction AppointmentUpdate.

    my $Success = $AppointmentUpdateActionObject->Run(
        UserID                   => 123,
        Ticket                   => \%Ticket,                                       # required
        ProcessEntityID          => 'P123',
        ActivityEntityID         => 'A123',
        TransitionEntityID       => 'T123',
        TransitionActionEntityID => 'TA123',
        Config                   => {
            CalendarID            => 1,                                             # (required) valid CalendarID
            # or
            CalendarName          => 'Calendar 1',                                  # (required) valid CalendarName

            AppointmentID         => 1,                                             # (required) AppointmentID to update the appointment

            Title                 => 'Webinar',                                     # (required) Title
            StartTime             => '2016-01-01 16:00:00',                         # (required)
            EndTime               => '2016-01-01 17:00:00',                         # (required)

            ParentID              => 1,                                             # (optional) valid ParentID for recurring appointments
            UniqueID              => 'jwioji-fwjio',                                # (optional) provide desired UniqueID; if there is already existing Appointment
                                                                                    #            with same UniqueID, system will delete it
            Description           => 'How to use Process tickets...',               # (optional) Description
            Location              => 'Berlin',                                      # (optional) Location
            AllDay                => 0,                                             # (optional) default 0
            TeamID                => '1',                                           # (optional) must be an array reference if supplied
            ResourceID            => '1, 3',                                        # (optional) must be an array reference if supplied
            Recurring             => 1,                                             # (optional) flag the appointment as recurring (parent only!)
            RecurringRaw          => 1,                                             # (optional) skip loop for recurring appointments (do not create occurrences!)
            RecurrenceType        => 'Daily',                                       # (required if Recurring) Possible "Daily", "Weekly", "Monthly", "Yearly",
                                                                                    #           "CustomWeekly", "CustomMonthly", "CustomYearly"

            RecurrenceFrequency   => '1, 3, 5',                                     # (required if Custom Recurring) Recurrence pattern
                                                                                    #           for CustomWeekly: 1-Mon, 2-Tue,..., 7-Sun
                                                                                    #           for CustomMonthly: 1-1st, 2-2nd,.., 31th
                                                                                    #           for CustomYearly: 1-Jan, 2-Feb,..., 12-Dec
                                                                                    # ...
            RecurrenceCount       => 1,                                             # (optional) How many Appointments to create
            RecurrenceInterval    => 2,                                             # (optional) Repeating interval (default 1)
            RecurrenceUntil       => '2016-01-10 00:00:00',                         # (optional) Until date
            RecurrenceID          => '2016-01-10 00:00:00',                         # (optional) Expected start time for this occurrence
            RecurrenceExclude     => '2016-01-10 00:00:00, 2016-01-11 00:00:00',    # (optional) Which specific occurrences to exclude
            NotificationTime      => '2016-01-01 17:00:00',                         # (optional) Point of time to execute the notification event
            NotificationTemplate  => 'Custom',                                      # (optional) Template to be used for notification point of time
            NotificationCustom    => 'relative',                                    # (optional) Type of the custom template notification point of time
                                                                                    #            Possible "relative", "datetime"
            NotificationCustomRelativeUnitCount   => '12',                          # (optional) minutes, hours or days count for custom template
            NotificationCustomRelativeUnit        => 'minutes',                     # (optional) minutes, hours or days unit for custom template
            NotificationCustomRelativePointOfTime => 'beforestart',                 # (optional) Point of execute for custom templates
                                                                                    #            Possible "beforestart", "afterstart", "beforeend", "afterend"
            NotificationCustomDateTime => '2016-01-01 17:00:00',                    # (optional) Notification date time for custom template
            TicketAppointmentRuleID    => '9bb20ea035e7a9930652a9d82d00c725',       # (optional) Ticket appointment rule ID (for ticket appointments only!)


            UserID                     => 1,                                        # (optional) UserID
        }
    );

Returns:

    my $Success = 1;

=cut

sub Run {
    my ( $Self, %Param ) = @_;

    my $AppointmentObject = $Kernel::OM->Get('Kernel::System::Calendar::Appointment');
    my $CalendarObject    = $Kernel::OM->Get('Kernel::System::Calendar');

    # define a common message to output in case of any error
    my $CommonMessage = "Process: $Param{ProcessEntityID} Activity: $Param{ActivityEntityID}"
        . " Transition: $Param{TransitionEntityID}"
        . " TransitionAction: $Param{TransitionActionEntityID} - ";

    # check for missing or wrong params
    my $Success = $Self->_CheckParams(
        %Param,
        CommonMessage => $CommonMessage,
    );
    return if !$Success;

    # override UserID if specified as a parameter in the TA config
    $Param{UserID} = $Self->_OverrideUserID(%Param);

    # special case for DynamicField UserID, convert form DynamicField_UserID to UserID
    if ( defined $Param{Config}->{DynamicField_UserID} ) {
        $Param{Config}->{UserID} = $Param{Config}->{DynamicField_UserID};
        delete $Param{Config}->{DynamicField_UserID};
    }

    # use ticket attributes if needed
    $Self->_ReplaceTicketAttributes(%Param);
    $Self->_ReplaceAdditionalAttributes(%Param);

    # get calendar id
    if ( $Param{Config}->{CalendarName} ) {
        my %Calendar = $CalendarObject->CalendarGet(
            CalendarName => $Param{Config}->{CalendarName},
            UserID       => 1,
        );

        $Param{Config}->{CalendarID} = $Calendar{CalendarID};
    }

    # convert some parameters to array if given
    PARAM:
    for my $Param (qw(TeamID ResourceID RecurrenceFrequency RecurrenceExclude )) {
        next PARAM if !defined $Param{Config}->{$Param};

        $Param{Config}->{$Param} = [ split /\s*,\s*/, $Param{Config}->{$Param} ];
    }

    # be sure that the date parameters are always in the correct format
    PARAM:
    for my $Param (
        qw( StartTime EndTime RecurrenceUntil RecurrenceID RecurrenceExclude NotificationTime NotificationCustomDateTime )
        )
    {
        next PARAM if !defined $Param{Config}->{$Param};

        if ( ref $Param{Config}->{$Param} eq 'ARRAY' ) {
            for my $Index ( 0 .. $#{ $Param{Config}->{$Param} } ) {
                $Param{Config}->{$Param}->[$Index] = $Self->_ValidDateTimeConvert(
                    String => $Param{Config}->{$Param}->[$Index],
                );
            }

            next PARAM;
        }

        $Param{Config}->{$Param} = $Self->_ValidDateTimeConvert(
            String => $Param{Config}->{$Param},
        );
    }

    if ( !$Param{Config}->{AppointmentID} ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => 'Need AppointmentID to update appointment!'
        );
        return;
    }

    # get dynamic field config
    $Success = $AppointmentObject->AppointmentUpdate(
        AppointmentID => $Param{Config}->{AppointmentID},
        UserID        => $Param{UserID},
        %{ $Param{Config} },
    );

    return $Success;
}

1;
