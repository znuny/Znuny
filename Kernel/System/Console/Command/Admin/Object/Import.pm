# --
# Copyright (C) 2021 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::Console::Command::Admin::Object::Import;

use strict;
use warnings;
use utf8;

use Kernel::System::VariableCheck qw(:all);

use parent qw(Kernel::System::Console::BaseExportImportCommand);

our @ObjectDependencies = (
    'Kernel::System::Cache',
    'Kernel::Config',
    'Kernel::System::Log'
);

sub Configure {
    my ( $Self, %Param ) = @_;

    $Self->Description('Import specified objects.');

    my $SettingKey = $Self->{_SettingKey} = 'ImportableObjects';
    my $Action     = $Self->{_Action}     = 'Import';

    $Self->{$SettingKey} = $Self->_ActionObjectsGet();

    return if !IsHashRefWithData( $Self->{$SettingKey} );

    $Self->_ProcessConfiguration();

    my $ImportableObjectsStrg = join ', ', sort keys %{ $Self->{$SettingKey} };

    # type is mandatory to send as command need to identify object
    $Self->AddOption(
        Name        => 'type',
        Description => "Type of objects, supported: $ImportableObjectsStrg.",
        Required    => 1,
        HasValue    => 1,
        ValueRegex  => qr/.*/smx,
    );

    return;
}

sub Run {
    my $Self = shift;

    return $Self->{CurrentModuleHandlerObject}->ImportHandle();
}

1;
