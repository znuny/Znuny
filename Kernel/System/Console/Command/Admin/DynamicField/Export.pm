# --
# Copyright (C) 2021 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::Console::Command::Admin::DynamicField::Export;

use strict;
use warnings;

use parent qw(Kernel::System::Console::BaseCommand);

our @ObjectDependencies = (
    'Kernel::System::ZnunyHelper',
    'Kernel::System::Main',
    'Kernel::System::YAML',
);

sub Configure {
    my ( $Self, %Param ) = @_;

    $Self->Description(
        'Exports configuration of all dynamic fields. Output can be formatted as YAML or Perl structure.',
    );

    $Self->AddArgument(
        Name        => 'format',
        Description => 'Format of the export: YAML or Perl.',
        Required    => 1,
        ValueRegex  => qr/\A(ya?ml|perl)\z/i,
    );

    $Self->AddOption(
        Name        => 'include-internal-fields',
        Description => 'Includes dynamic fields with flag "InternalField" (e.g. those of the process management).',
        Required    => 0,
        HasValue    => 0,
    );

    $Self->AddOption(
        Name        => 'include-all-config-keys',
        Description =>
            'Additionally includes the following config keys: ChangeTime, CreateTime, ID, InternalField, ValidID.',
        Required => 0,
        HasValue => 0,
    );

    return;
}

sub Run {
    my ( $Self, %Param ) = @_;

    my $ZnunyHelperObject = $Kernel::OM->Get('Kernel::System::ZnunyHelper');
    my $YAMLObject        = $Kernel::OM->Get('Kernel::System::YAML');
    my $MainObject        = $Kernel::OM->Get('Kernel::System::Main');

    # first, collect the data as hashref
    my %Data;
    $Data{DynamicFields} = $ZnunyHelperObject->_DynamicFieldsConfigExport(
        Format                => 'var',
        IncludeInternalFields => $Self->GetOption('include-internal-fields') // 0,
        IncludeAllConfigKeys  => $Self->GetOption('include-all-config-keys') // 0,
        Result                => 'HASH',
    );
    %{ $Data{DynamicFieldScreens} } = $ZnunyHelperObject->_DynamicFieldsScreenConfigExport();

    # finally dump the data as YAML or Perl structure
    my $ConfigString = $Self->GetArgument('format') =~ m{\A ya?ml \z}xi
        ? $YAMLObject->Dump( Data => \%Data )
        : $MainObject->Dump( \%Data );
    $Self->Print("$ConfigString\n");

    return $Self->ExitCodeOk();
}

1;
