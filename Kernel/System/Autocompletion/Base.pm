# --
# Copyright (C) 2021 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::Autocompletion::Base;

use strict;
use warnings;

use Kernel::System::VariableCheck qw(:all);

our @ObjectDependencies = (
    'Kernel::Config',
    'Kernel::System::HTMLUtils',
    'Kernel::System::Log',
);

sub new {
    my ( $Type, %Param ) = @_;
    my $Self = {%Param};

    bless( $Self, $Type );

    return $Self;
}

# Will be implemented in corresponding module.
sub GetData {
    return;
}

=head2 _MapData()

Ensures correct format of returned data as expected by frontend.

    my $Data = $AutocompletionObject->_MapData(
        ID                 => 5,
        SelectionListTitle => 'Title of object',
        InsertedValue      => 'Text to insert on selection',
    );

    Returns:

    my $Data = {
        id                   => 5,
        selection_list_title => 'Title of object',
        inserted_value       => 'Text to insert on selection',
    };

=cut

sub _MapData {
    my ( $Self, %Param ) = @_;

    my $LogObject       = $Kernel::OM->Get('Kernel::System::Log');
    my $ConfigObject    = $Kernel::OM->Get('Kernel::Config');
    my $HTMLUtilsObject = $Kernel::OM->Get('Kernel::System::HTMLUtils');

    NEEDED:
    for my $Needed (qw(ID SelectionListTitle InsertedValue)) {
        next NEEDED if defined $Param{$Needed};

        $LogObject->Log(
            Priority => 'error',
            Message  => "Parameter '$Needed' is needed!",
        );
        return;
    }

    # Sanitize values for output in browser.
    my $BlockLoadingRemoteContent = $ConfigObject->Get('Ticket::Frontend::BlockLoadingRemoteContent');

    for my $ParamName (qw(ID SelectionListTitle InsertedValue)) {
        my %SafetyCheckResult = $HTMLUtilsObject->Safety(
            String       => $Param{$ParamName} // '',
            NoExtSrcLoad => $BlockLoadingRemoteContent,
            NoApplet     => 1,
            NoObject     => 1,
            NoEmbed      => 1,
            NoSVG        => 1,
            NoJavaScript => 1,
        );

        $Param{$ParamName} = $SafetyCheckResult{String};
    }

    my $Data = {
        id                   => $Param{ID},
        selection_list_title => $Param{SelectionListTitle},
        inserted_value       => $Param{InsertedValue},
    };

    return $Data;
}

=head2 _GetModuleConfig()

    Returns the config of the module from which it will be called.

    my $ModuleConfig = $AutocompletionObject->_GetModuleConfig();

    Returns:

    my $ModuleConfig = {
        Trigger => '!EX',
        # ...
    }:

=cut

sub _GetModuleConfig {
    my ( $Self, %Param ) = @_;

    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');

    my $ModuleConfigs = $ConfigObject->Get('Frontend::RichText::Autocompletion::Modules');
    return if !IsHashRefWithData($ModuleConfigs);

    my ($PackageName) = caller();
    ( my $ModuleName = $PackageName ) =~ s{\A.*::}{};

    my $ModuleConfig = $ModuleConfigs->{$ModuleName};

    return $ModuleConfig;
}

1;
