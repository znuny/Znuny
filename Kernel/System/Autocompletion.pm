# --
# Copyright (C) 2021 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::Autocompletion;

use strict;
use warnings;

use Kernel::System::VariableCheck qw(:all);

our @ObjectDependencies = (
    'Kernel::Config',
    'Kernel::System::Autocompletion',
    'Kernel::System::Log',
);

=head2 new()

Don't use the constructor directly, use the ObjectManager instead:

    my $AutocompletionObject = $Kernel::OM->Get('Kernel::System::Autocompletion');

=cut

sub new {
    my ( $Type, %Param ) = @_;
    my $Self = {%Param};

    bless( $Self, $Type );

    return $Self;
}

=head2 GetData()

    Returns data for autocompletion of given trigger.

    my $Data = $AutocompletionObject->GetData(
        Trigger          => '!EX', # !EX is from example autocompletion module Kernel::System::Autocompletion::Example
        SearchString     => 'Raw',
        UserID           => 2,
        AdditionalParams => { # optional
            TicketID => 3, # this will only be passed if available (e.g. it's not available for AgentTicketPhone)
        },
    );

    Returns:

    my $Data = [
        {
            id                   => 3,
            selection_list_title => 'Raw',
            inserted_value       => 'Raw (3)',
        },
    ];

=cut

sub GetData {
    my ( $Self, %Param ) = @_;

    my $LogObject            = $Kernel::OM->Get('Kernel::System::Log');
    my $AutocompletionObject = $Kernel::OM->Get('Kernel::System::Autocompletion');

    NEEDED:
    for my $Needed (qw(Trigger SearchString UserID)) {
        next NEEDED if defined $Param{$Needed};

        $LogObject->Log(
            Priority => 'error',
            Message  => "Parameter '$Needed' is needed!",
        );
        return;
    }

    my $AutocompletionSettings = $AutocompletionObject->GetAutocompletionSettings();
    return if !IsHashRefWithData($AutocompletionSettings);
    return if !IsHashRefWithData( $AutocompletionSettings->{Triggers} );

    if ( !IsHashRefWithData( $AutocompletionSettings->{Triggers}->{ $Param{Trigger} } ) ) {
        $LogObject->Log(
            Priority => 'error',
            Message  => "Unknown trigger '$Param{Trigger}' given for autocompletion.",
        );
        return;
    }

    my $AutcompletionModule = $AutocompletionSettings->{Triggers}->{ $Param{Trigger} }->{Module};
    return if !IsStringWithData($AutcompletionModule);

    my $AutocompletionModuleObject = $Kernel::OM->Get("Kernel::System::Autocompletion::$AutcompletionModule");
    return if !$AutocompletionModuleObject;

    my $AutocompletionData = $AutocompletionModuleObject->GetData(
        SearchString     => $Param{SearchString},
        UserID           => $Param{UserID},
        AdditionalParams => $Param{AdditionalParams},    # optional
    ) // [];

    return $AutocompletionData;
}

=head2 GetAutocompletionSettings()

    Returns a hash with autocompletion settings by trigger.

    my $AutocompletionSettings = $AutocompletionObject->GetAutocompletionSettings();

    Returns:

    my $AutocompletionSettings = {
        ItemTemplate    => '<li data-id={id}>{selection_list_title}</li>',
        OutputTemplate  => '{inserted_value}',
        MinSearchLength => 3,
        Triggers        => {
            '!EX' => {
                Module  => 'Example',
                Trigger => '!EX',
            },
        },
    };

=cut

sub GetAutocompletionSettings {
    my ( $Self, %Param ) = @_;

    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');
    my $LogObject    = $Kernel::OM->Get('Kernel::System::Log');

    my $AutocompletionSettings = $ConfigObject->Get('Frontend::RichText::Autocompletion::General') // {};
    $AutocompletionSettings->{Triggers} = {};

    my $ModulesSettings = $ConfigObject->Get('Frontend::RichText::Autocompletion::Modules') // {};

    MODULE:
    for my $Module ( sort keys %{$ModulesSettings} ) {
        my $ModuleSettings = $ModulesSettings->{$Module} // {};

        # Check for missing configured trigger.
        if ( !IsStringWithData( $ModuleSettings->{Trigger} ) ) {
            $LogObject->Log(
                Priority => 'error',
                Message =>
                    "Trigger is missing in configuration of autocompletion module in SysConfig option 'Frontend::RichText::Autocompletion::Modules###$Module'.",
            );

            next MODULE;
        }

        # Check for multiple use of the same trigger across different modules.
        if ( exists( $AutocompletionSettings->{Triggers}->{ $ModuleSettings->{Trigger} } ) ) {
            $LogObject->Log(
                Priority => 'error',
                Message =>
                    "Trigger '$ModuleSettings->{Trigger}' is used for more than one autocompletion module in SysConfig option 'Frontend::RichText::Autocompletion::Modules'.",
            );

            next MODULE;
        }

        $ModuleSettings->{Module} = $Module;

        $AutocompletionSettings->{Triggers}->{ $ModuleSettings->{Trigger} } = $ModuleSettings;
    }

    return {} if !IsHashRefWithData( $AutocompletionSettings->{Triggers} );

    return $AutocompletionSettings;
}

1;
