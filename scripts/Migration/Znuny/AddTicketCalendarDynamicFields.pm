# --
# Copyright (C) 2021-2022 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package scripts::Migration::Znuny::AddTicketCalendarDynamicFields;    ## no critic

use strict;
use warnings;

use parent qw(scripts::Migration::Base);

our @ObjectDependencies = (
    'Kernel::System::DynamicField',
    'Kernel::System::Log',
);

=head1 SYNOPSIS

Added dynamic field 'TicketCalendarStartTime' and 'TicketCalendarEndTime'.

=cut

sub Run {
    my ( $Self, %Param ) = @_;

    my $DynamicFieldObject = $Kernel::OM->Get('Kernel::System::DynamicField');
    my $LogObject          = $Kernel::OM->Get('Kernel::System::Log');

    my $AvailableDynamicFieldConfigs = $DynamicFieldObject->DynamicFieldListGet() // [];

    my @NewDynamicFieldConfigs = (
        {
            Name       => 'TicketCalendarStartTime',
            Label      => 'Ticket Calendar Start Time',
            FieldOrder => 4,
            FieldType  => 'DateTime',
            ObjectType => 'Ticket',
            Config     => {
                DefaultValue  => 0,
                YearsInFuture => 0,
                YearsInPast   => 0,
                YearsPeriod   => 0,
            },
            Reorder => 1,
            ValidID => 1,
            UserID  => 1,
        },
        {
            Name       => 'TicketCalendarEndTime',
            Label      => 'Ticket Calendar End Time',
            FieldOrder => 4,
            FieldType  => 'DateTime',
            ObjectType => 'Ticket',
            Config     => {
                DefaultValue  => 0,
                YearsInFuture => 0,
                YearsInPast   => 0,
                YearsPeriod   => 0,
            },
            Reorder => 1,
            ValidID => 1,
            UserID  => 1,
        },
    );

    DYNAMICFIELDCONFIG:
    for my $DynamicFieldConfig (@NewDynamicFieldConfigs) {
        next DYNAMICFIELDCONFIG if grep { $_->{Name} eq $DynamicFieldConfig->{Name} } @{$AvailableDynamicFieldConfigs};

        my $DynamicFieldID = $DynamicFieldObject->DynamicFieldAdd(
            %{$DynamicFieldConfig},
        );
        next DYNAMICFIELDCONFIG if defined $DynamicFieldID;

        $LogObject->Log(
            Priority => 'error',
            Message  => "Could not create dynamic field '$DynamicFieldConfig->{Name}'.",
        );
    }

    return 1;
}

1;
