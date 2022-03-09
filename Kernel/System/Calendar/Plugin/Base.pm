# --
# Copyright (C) 2001-2021 OTRS AG, https://otrs.com/
# Copyright (C) 2021-2022 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see https://www.gnu.org/licenses/gpl-3.0.txt.
# --
## nofilter(TidyAll::Plugin::OTRS::Perl::Pod::SpellCheck)

use strict;
use warnings;

package Kernel::System::Calendar::Plugin::Base;

use Kernel::System::VariableCheck qw(:all);

our @ObjectDependencies = (
    'Kernel::System::Calendar::Plugin',
);

=head1 NAME

Kernel::System::Calendar::Plugin::Base - Base plugin

=head1 DESCRIPTION

Ticket appointment plugin.

=head1 PUBLIC INTERFACE

=head2 new()

create an object. Do not use it directly, instead use:

    use Kernel::System::ObjectManager;
    local $Kernel::OM = Kernel::System::ObjectManager->new();
    my $BasePluginObject = $Kernel::OM->Get('Kernel::System::Calendar::Plugin::Base');

=cut

sub new {
    my ( $Type, %Param ) = @_;

    my $Self = {};
    bless( $Self, $Type );

    return $Self;
}

=head2 RenderOutput()

renders the output as html.

    my $HTML = $BasePluginObject->RenderOutput(
        Param           => \%Param,
        GetParam        => \%GetParam,
        Appointment     => \%Appointment,
        Plugin          => \%Plugin,
        PermissionLevel => $PermissionLevel{$Permissions},
        UserID          => $Self->{UserID},
    );

Returns:

    my $HTML = 'HTML';

=cut

sub RenderOutput {
    my ( $Self, %Param ) = @_;

    return '';
}

=head2 Update()

updated accordingly as needed.

    my $Success = $BasePluginObject->Update(
        GetParam    => \%GetParam,
        Appointment => \%Appointment,
        Plugin      => \%Plugin,
        UserID      => $Self->{UserID},
    );

Returns:

    my $Success = 1;

=cut

sub Update {
    my ( $Self, %Param ) = @_;

    my $PluginObject = $Kernel::OM->Get('Kernel::System::Calendar::Plugin');

    my %Data = $PluginObject->DataGet(
        AppointmentID => $Param{Appointment}->{AppointmentID},
        PluginKey     => $Param{Plugin}->{PluginKey},
        UserID        => 1,
    );

    if (%Data) {
        $PluginObject->DataUpdate(
            ID     => $Data{ID},
            Config => {
                %{ $Data{Config} },
                %{ $Param{Plugin}->{Param} },
            },
            CreateBy => $Param{UserID},
            ChangeBy => $Param{UserID},
            UserID   => $Param{UserID},
        );
    }
    else {
        $PluginObject->DataAdd(
            AppointmentID => $Param{Appointment}->{AppointmentID},
            PluginKey     => $Param{Plugin}->{PluginKey},
            Config        => {
                %{ $Param{Plugin}->{Param} },
            },
            CreateBy => $Param{UserID},
            ChangeBy => $Param{UserID},
            UserID   => $Param{UserID},
        );
    }

    return 1;
}

=head2 Delete()

delete all plugin information.

    my $Success = $BasePluginObject->Delete(
        GetParam    => \%GetParam,
        Appointment => \%Appointment,
        Plugin      => \%Plugin,
        UserID      => $Self->{UserID},
    );

Returns:

    my $Success = 1;

=cut

sub Delete {
    my ( $Self, %Param ) = @_;

    my $PluginObject = $Kernel::OM->Get('Kernel::System::Calendar::Plugin');

    my $Success = $PluginObject->DataDelete(
        AppointmentID => $Param{Appointment}->{AppointmentID},
        PluginKey     => $Param{Plugin}->{PluginKey},
        UserID        => 1,
    );

    return $Success;
}

=head2 Get()

Get all plugin information.

    my %Data = $BasePluginObject->Get(
        GetParam    => \%GetParam,
        Appointment => \%Appointment,
        Plugin      => \%Plugin,
        UserID      => $Self->{UserID},
    );

Returns:

    my %Data = {};

=cut

sub Get {
    my ( $Self, %Param ) = @_;

    my $PluginObject = $Kernel::OM->Get('Kernel::System::Calendar::Plugin');

    my %Data = $PluginObject->DataGet(
        AppointmentID => $Param{Appointment}->{AppointmentID},
        PluginKey     => $Param{Plugin}->{PluginKey},
        UserID        => 1,
    );
    return if ( !%Data );

    return \%Data;
}

=head2 AJAXUpdate()

Return an array with all plugin ajax update informations to build the layoutobject selection JSON.

    my @PluginAJAX = $BasePluginObject->AJAXUpdate(
        GetParam    => \%GetParam,
        Appointment => \%Appointment,
        Plugin      => \%Plugin,
        UserID      => $Self->{UserID},
    );

Returns:

    my @PluginAJAX = (
        {
            Data         => \%Data,
            Name         => 'Plugin_HTML_Field',
            ID           => 'Plugin_HTML_Field',
            SelectedID   => 1,
            PossibleNone => 1,
            Translation  => 1,
            Class        => 'Modernize',
        },
    );

=cut

sub AJAXUpdate {
    my ( $Self, %Param ) = @_;

    return;
}

1;
