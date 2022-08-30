# --
# Copyright (C) 2001-2021 OTRS AG, https://otrs.com/
# Copyright (C) 2021-2022 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see https://www.gnu.org/licenses/gpl-3.0.txt.
# --

package Kernel::System::EventHandler;
## nofilter(TidyAll::Plugin::OTRS::Perl::Pod::FunctionPod)

use strict;
use warnings;

use Kernel::System::VariableCheck qw(IsArrayRefWithData);

our $ObjectManagerDisabled = 1;

=head1 NAME

Kernel::System::EventHandler - event handler interface

=head1 DESCRIPTION

Inherit from this class if you want to use events there.

    use parent qw(Kernel::System::EventHandler);

In your class, have to call L</EventHandlerInit()> first.

Then, to register events as they occur, use the L</EventHandler()>
method. It will call the event handler modules which are registered
for the given event, or queue them for later execution (so-called
'Transaction' events).

In the destructor, you should add a call to L</EventHandlerTransaction()>
to make sure that also C<Transaction> events will be executed correctly.
This is only necessary if you use C<Transaction> events in your class.

=head1 PUBLIC INTERFACE

=head2 EventHandlerInit()

Call this to initialize the event handling mechanisms to work
correctly with your object.

    $Self->EventHandlerInit(
        # name of configured event modules
        Config     => 'Example::EventModule',
    );

Example 1:

    $Self->EventHandlerInit(
        Config     => 'Ticket::EventModulePost',
    );

Example 1 XML config:

    <ConfigItem Name="Example::EventModule###99-EscalationIndex" Required="0" Valid="1">
        <Description Translatable="1">Example event module updates the example escalation index.</Description>
        <Group>Example</Group>
        <SubGroup>Core::Example</SubGroup>
        <Setting>
            <Hash>
                <Item Key="Module">Kernel::System::Example::Event::ExampleEscalationIndex</Item>
                <Item Key="Event">(ExampleSLAUpdate|ExampleQueueUpdate|ExampleStateUpdate|ExampleCreate)</Item>
                <Item Key="SomeOption">Some Option accessable via $Param{Config}->{SomeOption} in Run() of event module.</Item>
                <Item Key="Transaction">(0|1)</Item>
            </Hash>
        </Setting>
    </ConfigItem>

Example 2:

    $Self->EventHandlerInit(
        Config     => 'ITSM::EventModule',
    );

Example 2 XML config:

    <ConfigItem Name="ITSM::EventModule###01-HistoryAdd" Required="0" Valid="1">
        <Description Translatable="1">ITSM event module updates the history for Change and WorkOrder objects..</Description>
        <Group>ITSM Change Management</Group>
        <SubGroup>Core::ITSMEvent</SubGroup>
        <Setting>
            <Hash>
                <Item Key="Module">Kernel::System::ITSMChange::Event::HistoryAdd</Item>
                <Item Key="Event">(ChangeUpdate|WorkOrderUpdate|ChangeAdd|WorkOrderAdd)</Item>
                <Item Key="SomeOption">Some Option accessable via $Param{Config}->{SomeOption} in Run() of event module.</Item>
                <Item Key="Transaction">(0|1)</Item>
            </Hash>
        </Setting>
    </ConfigItem>
    <ConfigItem Name="ITSM::EventModule###02-HistoryAdd" Required="0" Valid="1">
        <Description Translatable="1">ITSM event module updates the ConfigItem History.</Description>
        <Group>ITSM Configuration Management</Group>
        <SubGroup>Core::ITSMEvent</SubGroup>
        <Setting>
            <Hash>
                <Item Key="Module">Kernel::System::ITSMConfigurationManagement::Event::HistoryAdd</Item>
                <Item Key="Event">(ConfigItemUpdate|ConfigItemAdd)</Item>
                <Item Key="SomeOption">Some Option accessable via $Param{Config}->{SomeOption} in Run() of event module.</Item>
                <Item Key="Transaction">(0|1)</Item>
            </Hash>
        </Setting>
    </ConfigItem>

=cut

sub EventHandlerInit {
    my ( $Self, %Param ) = @_;

    $Self->{EventHandlerInit} = \%Param;
    $Kernel::OM->ObjectRegisterEventHandler( EventHandler => $Self );

    return 1;
}

=head2 EventHandler()

call event handler, returns true if it was executed successfully.

Example 1:

    my $Success = $EventHandler->EventHandler(
        Event => 'TicketStateUpdate',   # event classification, passed to the configured event handlers
        Data  => {                      # data payload for the event, passed to the configured event handlers
            TicketID => 123,
        },
        UserID => 123,
        Transaction => 1,               # optional, 0 or 1
    );

In 'Transaction' mode, all events will be collected and executed together,
usually in the destructor of your object.

Example 2:

    my $Success = $EventHandler->EventHandler(
        Event => 'ChangeUpdate',
        Data  => {
            ChangeID => 123,
        },
        UserID => 123,
    );

=cut

sub EventHandler {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Needed (qw(Data Event UserID)) {
        if ( !$Param{$Needed} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Needed!"
            );
            return;
        }
    }

    # get configured modules
    my $Modules = $Kernel::OM->Get('Kernel::Config')->Get( $Self->{EventHandlerInit}->{Config} );

    # return if there is no one
    return 1 if !$Modules;

    # remember events only on normal mode
    if ( !$Self->{EventHandlerTransaction} ) {
        push @{ $Self->{EventHandlerPipe} }, \%Param;
    }

    # get main object
    my $MainObject = $Kernel::OM->Get('Kernel::System::Main');

    # load modules and execute
    MODULE:
    for my $Module ( sort keys %{$Modules} ) {

        # If the module has an event configuration, determine if it should be executed for this event,
        #   and store the result in a small cache to avoid repetition on jobs involving many tickets.
        if ( !defined $Self->{ExecuteModuleOnEvent}->{$Module}->{ $Param{Event} } ) {
            if ( !$Modules->{$Module}->{Event} ) {
                $Self->{ExecuteModuleOnEvent}->{$Module}->{ $Param{Event} } = 1;
            }
            else {
                $Self->{ExecuteModuleOnEvent}->{$Module}->{ $Param{Event} } =
                    $Param{Event} =~ /$Modules->{$Module}->{Event}/;
            }
        }

        if ( $Self->{ExecuteModuleOnEvent}->{$Module}->{ $Param{Event} } ) {

            if ( $Self->{EventHandlerTransaction} && !$Param{Transaction} ) {

                # This is a special case. A new event was fired during processing of
                #   the queued events in transaction mode. This event must be immediately
                #   processed.
            }
            else {

                # This is the regular case. A new event was fired in regular mode, or
                #   we are processing a queued event in transaction mode. Only execute
                #   this if the transaction settings of event and listener are the same.

                # skip if we are not in transaction mode, but module is in transaction
                next MODULE if !$Param{Transaction} && $Modules->{$Module}->{Transaction};

                # skip if we are in transaction mode, but module is not in transaction
                next MODULE if $Param{Transaction} && !$Modules->{$Module}->{Transaction};
            }

            # load event module
            next MODULE if !$MainObject->Require( $Modules->{$Module}->{Module} );

            # execute event backend
            my $Generic = $Modules->{$Module}->{Module}->new();

            $Generic->Run(
                %Param,
                Config => $Modules->{$Module},
            );
        }
    }

    return 1;
}

=head2 EventHandlerTransaction()

handle all queued 'Transaction' events which were collected up to this point.

    $EventHandler->EventHandlerTransaction();

Call this method in the destructor of your object which inherits from
Kernel::System::EventHandler, like this:

    sub DESTROY {
        my $Self = shift;

        # execute all transaction events
        $Self->EventHandlerTransaction();

        return 1;
    }

=cut

sub EventHandlerTransaction {
    my ( $Self, %Param ) = @_;

    # remember, we are in destroy mode, do not execute new events
    $Self->{EventHandlerTransaction} = 1;

    # execute events on end of transaction
    if ( $Self->{EventHandlerPipe} ) {

        for my $Params ( @{ $Self->{EventHandlerPipe} } ) {
            $Self->EventHandler(
                %Param,
                %{$Params},
                Transaction => 1,
            );
        }

        # delete event pipe
        $Self->{EventHandlerPipe} = undef;
    }

    # reset transaction mode
    $Self->{EventHandlerTransaction} = 0;

    return 1;
}

=head2 EventHandlerHasQueuedTransactions()

Return a true value if there are queued transactions, which
C<EventHandlerTransaction> handles, when called.

=cut

sub EventHandlerHasQueuedTransactions {
    my ( $Self, %Param ) = @_;

    return IsArrayRefWithData( $Self->{EventHandlerPipe} );
}

1;

=head1 TERMS AND CONDITIONS

This software is part of the OTRS project (L<https://otrs.org/>).

This software comes with ABSOLUTELY NO WARRANTY. For details, see
the enclosed file COPYING for license information (GPL). If you
did not receive this file, see L<https://www.gnu.org/licenses/gpl-3.0.txt>.

=cut
