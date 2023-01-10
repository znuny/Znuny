# --
# Copyright (C) 2021 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::Ticket::Event::DynamicFieldWebservice;

use strict;
use warnings;

use Kernel::System::VariableCheck qw(:all);

our @ObjectDependencies = (
    'Kernel::System::DynamicField',
    'Kernel::System::Log',
    'Kernel::System::DynamicField::Webservice',
);

sub new {
    my ( $Type, %Param ) = @_;

    my $Self = {};
    bless( $Self, $Type );

    return $Self;
}

sub Run {
    my ( $Self, %Param ) = @_;

    my $LogObject                    = $Kernel::OM->Get('Kernel::System::Log');
    my $DynamicFieldObject           = $Kernel::OM->Get('Kernel::System::DynamicField');
    my $DynamicFieldWebserviceObject = $Kernel::OM->Get('Kernel::System::DynamicField::Webservice');

    # if 'New' exists, generic agent is running, so use this data
    if ( $Param{New} ) {
        $Param{UserID} = 1;
        $Param{Event}  = 'TicketDynamicFieldUpdate';
        $Param{Data}   = {
            TicketID  => $Param{TicketID},
            FieldName => $Param{New}->{FieldName},
        };
        $Param{Config} = {
            Event       => 'TicketDynamicFieldUpdate',
            Module      => 'Kernel::System::Ticket::Event::DynamicFieldWebservice',
            Transaction => 0,
        };
    }

    NEEDED:
    for my $Needed (qw( Data Event Config UserID )) {
        next NEEDED if $Param{$Needed};

        $LogObject->Log(
            Priority => 'error',
            Message  => "Need $Needed!"
        );
        return 1;
    }

    NEEDED:
    for my $Needed (qw( TicketID )) {
        next NEEDED if $Param{Data}->{$Needed};

        $LogObject->Log(
            Priority => 'error',
            Message  => "Need $Needed in Data!"
        );
        return 1;
    }

    my $DynamicFieldConfig = $DynamicFieldObject->DynamicFieldGet(
        Name => $Param{Data}->{FieldName},
    );
    return if !IsHashRefWithData($DynamicFieldConfig);

    return 1
        if !$DynamicFieldWebserviceObject->{SupportedDynamicFieldTypes}->{ $DynamicFieldConfig->{FieldType} };
    return 1 if !IsArrayRefWithData( $DynamicFieldConfig->{Config}->{AdditionalDFStorage} );

    $DynamicFieldWebserviceObject->AdditionalDynamicFieldValuesStore(
        DynamicFieldConfig => $DynamicFieldConfig,
        TicketID           => $Param{Data}->{TicketID},
        UserID             => $Param{UserID},
    );

    return 1;
}

1;
