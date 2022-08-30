# --
# Copyright (C) 2001-2021 OTRS AG, https://otrs.com/
# Copyright (C) 2021-2022 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see https://www.gnu.org/licenses/gpl-3.0.txt.
# --

package Kernel::GenericInterface::Mapping;

use strict;
use warnings;

use Kernel::System::VariableCheck qw(IsHashRefWithData IsStringWithData);

# prevent 'Used once' warning for Kernel::OM
use Kernel::System::ObjectManager;

our $ObjectManagerDisabled = 1;

=head1 NAME

Kernel::GenericInterface::Mapping - GenericInterface data mapping interface

=head1 PUBLIC INTERFACE

=head2 new()

create an object.

    use Kernel::GenericInterface::Debugger;
    use Kernel::GenericInterface::Mapping;

    my $DebuggerObject = Kernel::GenericInterface::Debugger->new(
        DebuggerConfig   => {
            DebugThreshold  => 'debug',
            TestMode        => 0,           # optional, in testing mode the data will not be written to the DB
            # ...
        },
        WebserviceID      => 12,
        CommunicationType => Requester, # Requester or Provider
        RemoteIP          => 192.168.1.1, # optional
    );
    my $MappingObject = Kernel::GenericInterface::Mapping->new(
        DebuggerObject => $DebuggerObject,
        Invoker        => 'TicketLock',            # the name of the invoker in the web service
        InvokerType    => 'Nagios::TicketLock',    # the Invoker backend to use
        Operation      => 'TicketCreate',          # the name of the operation in the web service
        OperationType  => 'Ticket::TicketCreate',  # the local operation backend to use
        MappingConfig => {
            Type => 'MappingSimple',
            Config => {
                # ...
            },
        },
    );

=cut

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {};
    bless( $Self, $Type );

    # check needed params
    for my $Needed (qw(DebuggerObject MappingConfig)) {
        if ( !$Param{$Needed} ) {

            return {
                Success      => 0,
                ErrorMessage => "Got no $Needed!"
            };
        }

        $Self->{$Needed} = $Param{$Needed};
    }

    # add optional params
    OPTIONAL:
    for my $Optional (qw(Invoker InvokerType Operation OperationType)) {
        next OPTIONAL if !$Param{$Optional};

        $Self->{$Optional} = $Param{$Optional};
    }

    # check config - we need at least a config type
    if ( !IsHashRefWithData( $Param{MappingConfig} ) ) {

        return $Self->{DebuggerObject}->Error(
            Summary => 'Got no MappingConfig as hash ref with content!',
        );
    }
    if ( !IsStringWithData( $Param{MappingConfig}->{Type} ) ) {

        return $Self->{DebuggerObject}->Error(
            Summary => 'Got no MappingConfig with Type as string with value!',
        );
    }

    # check config - if we have a map config, it has to be a non-empty hash ref
    if (
        defined $Param{MappingConfig}->{Config}
        && !IsHashRefWithData( $Param{MappingConfig}->{Config} )
        )
    {

        return $Self->{DebuggerObject}->Error(
            Summary => 'Got MappingConfig with Data, but Data is no hash ref with content!',
        );
    }

    # load backend module
    my $GenericModule = 'Kernel::GenericInterface::Mapping::' . $Param{MappingConfig}->{Type};
    if ( !$Kernel::OM->Get('Kernel::System::Main')->Require($GenericModule) ) {

        return $Self->{DebuggerObject}->Error( Summary => "Can't load mapping backend module!" );
    }
    $Self->{BackendObject} = $GenericModule->new( %{$Self} );

    # pass back error message from backend if backend module could not be executed
    return $Self->{BackendObject} if ref $Self->{BackendObject} ne $GenericModule;

    return $Self;
}

=head2 Map()

perform data mapping in backend

    my $Result = $MappingObject->Map(
        Data => {              # data payload before mapping
            ...
        },
    );

    $Result = {
        Success         => 1,  # 0 or 1
        ErrorMessage    => '', # in case of error
        Data            => {   # data payload of after mapping
            ...
        },
    };

=cut

sub Map {
    my ( $Self, %Param ) = @_;

    # start map on backend
    return $Self->{BackendObject}->Map(%Param);
}

1;

=head1 TERMS AND CONDITIONS

This software is part of the OTRS project (L<https://otrs.org/>).

This software comes with ABSOLUTELY NO WARRANTY. For details, see
the enclosed file COPYING for license information (GPL). If you
did not receive this file, see L<https://www.gnu.org/licenses/gpl-3.0.txt>.

=cut
