# --
# Copyright (C) 2021 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::GenericAgent::ExecuteInvoker;

use strict;
use warnings;

use Kernel::System::VariableCheck qw(:all);

our @ObjectDependencies = (
    'Kernel::System::Log',
    'Kernel::GenericInterface::Requester',
    'Kernel::System::GenericInterface::Webservice',
);

sub new {
    my ( $Type, %Param ) = @_;

    my $Self = {};
    bless( $Self, $Type );

    return $Self;
}

sub Run {
    my ( $Self, %Param ) = @_;

    my $LogObject        = $Kernel::OM->Get('Kernel::System::Log');
    my $RequesterObject  = $Kernel::OM->Get('Kernel::GenericInterface::Requester');
    my $WebserviceObject = $Kernel::OM->Get('Kernel::System::GenericInterface::Webservice');

    return 1 if !$Param{TicketID};

    NEEDED:
    for my $Needed (qw(Webservice Invoker)) {
        next NEEDED if defined $Param{New}->{$Needed};
        $LogObject->Log(
            Priority => 'error',
            Message  => "Parameter '$Needed' is needed in GenericAgent::ExecuteInvoker!",
        );
        return;
    }

    my $Webservice = $WebserviceObject->WebserviceGet( 'Name' => $Param{New}->{Webservice} );
    if ( !IsHashRefWithData($Webservice) ) {
        $LogObject->Log(
            Priority => 'error',
            Message =>
                "Could not find web service $Param{New}->{Webservice}.",
        );
        return;
    }

    $RequesterObject->Run(
        WebserviceID => $Webservice->{ID},
        Invoker      => $Param{New}->{Invoker},
        Asynchronous => $Param{New}->{Asynchronous} || 0,
        Data         => {
            Event       => 'GenericAgent',
            EventValues => $Param{'EventValues'},
            TicketID    => $Param{TicketID},
        },
    );

    return 1;
}

1;
