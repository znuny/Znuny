# --
# Copyright (C) 2001-2021 OTRS AG, https://otrs.com/
# Copyright (C) 2021 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see https://www.gnu.org/licenses/gpl-3.0.txt.
# --

## nofilter(TidyAll::Plugin::Znuny4OTRS::Legal::AGPLValidator)

package Kernel::System::Ticket::Event::DynamicFieldFromCustomerCompany;

use strict;
use warnings;
use utf8;

our @ObjectDependencies = (
    'Kernel::Config',
    'Kernel::System::CustomerCompany',
    'Kernel::System::DynamicField',
    'Kernel::System::DynamicField::Backend',
    'Kernel::System::Log',
    'Kernel::System::Ticket',
);

use Kernel::System::VariableCheck qw(:all);

sub new {
    my ( $Type, %Param ) = @_;

    my $Self = {};
    bless( $Self, $Type );

    return $Self;
}

sub Run {
    my ( $Self, %Param ) = @_;

    my $LogObject                 = $Kernel::OM->Get('Kernel::System::Log');
    my $ConfigObject              = $Kernel::OM->Get('Kernel::Config');
    my $TicketObject              = $Kernel::OM->Get('Kernel::System::Ticket');
    my $DynamicFieldObject        = $Kernel::OM->Get('Kernel::System::DynamicField');
    my $DynamicFieldBackendObject = $Kernel::OM->Get('Kernel::System::DynamicField::Backend');
    my $CustomerCompanyObject     = $Kernel::OM->Get('Kernel::System::CustomerCompany');

    NEEDED:
    for my $Needed (qw( Data Event Config UserID )) {
        next NEEDED if $Param{$Needed};

        $LogObject->Log(
            Priority => 'error',
            Message  => "Need $Needed!"
        );
        return;
    }

    NEEDED:
    for my $Needed (qw( TicketID )) {
        next NEEDED if $Param{Data}->{$Needed};

        $LogObject->Log(
            Priority => 'error',
            Message  => "Need $Needed in Data!"
        );
        return;
    }

    my %Mapping = %{ $ConfigObject->Get('DynamicFieldFromCustomerCompany::Mapping') // {} };
    return 1 if !%Mapping;

    my %Ticket = $TicketObject->TicketGet(
        TicketID => $Param{Data}->{TicketID},
    );
    return if !%Ticket;

    my $DynamicFieldNameByID = $DynamicFieldObject->DynamicFieldList(
        Valid      => 1,
        ObjectType => 'Ticket',
        ResultType => 'HASH',
    );
    my %DynamicFieldIDByName = reverse %{$DynamicFieldNameByID};

    my %CustomerCompany = $CustomerCompanyObject->CustomerCompanyGet(
        CustomerID => $Ticket{CustomerID},
    );

    # also continue if there was no CustomerCompany data found - erase values
    # loop over the configured mapping of customer data variables to dynamic fields
    CUSTOMERCOMPANYFIELDNAME:
    for my $CustomerCompanyFieldName ( sort keys %Mapping ) {
        my $DynamicFieldName = $Mapping{$CustomerCompanyFieldName};
        if ( !IsStringWithData($DynamicFieldName) ) {
            $LogObject->Log(
                Priority => 'error',
                Message =>
                    "Dynamic field $DynamicFieldName not found but used in DynamicFieldFromCustomerCompany::Mapping.",
            );
            next CUSTOMERCOMPANYFIELDNAME;
        }

        my $DynamicFieldConfig = $DynamicFieldObject->DynamicFieldGet(
            Name => $DynamicFieldName,
        );

        $DynamicFieldBackendObject->ValueSet(
            DynamicFieldConfig => $DynamicFieldConfig,
            ObjectID           => $Param{Data}->{TicketID},
            Value              => $CustomerCompany{$CustomerCompanyFieldName} // '',
            UserID             => $Param{UserID},
        );
    }

    return 1;
}

1;
