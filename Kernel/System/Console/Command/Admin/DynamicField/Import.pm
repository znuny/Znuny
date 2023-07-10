# --
# Copyright (C) 2021 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::Console::Command::Admin::DynamicField::Import;

use strict;
use warnings;
use utf8;

use Kernel::System::VariableCheck qw(:all);

use parent qw(Kernel::System::Console::BaseCommand);

our @ObjectDependencies = (
    'Kernel::Config',
    'Kernel::System::Main',
    'Kernel::System::YAML',
    'Kernel::System::ZnunyHelper',
);

sub Configure {
    my ( $Self, %Param ) = @_;

    $Self->Description(
        'Imports configuration of dynamic fields and dynamic field screens from a file in YAML format.',
    );

    $Self->AddArgument(
        Name        => 'file-path',
        Description => 'Path to YAML file with dynamic field configuration.',
        Required    => 1,
        HasValue    => 1,
        ValueRegex  => qr/.+/,
    );

    $Self->AddOption(
        Name        => 'overwrite-existing-configurations',
        Description => 'Overwrite existing dynamic field configurations.',
        Required    => 0,
        HasValue    => 0,
    );

    return;
}

sub Run {
    my ( $Self, %Param ) = @_;

    my $ZnunyHelperObject = $Kernel::OM->Get('Kernel::System::ZnunyHelper');
    my $MainObject        = $Kernel::OM->Get('Kernel::System::Main');
    my $ConfigObject      = $Kernel::OM->Get('Kernel::Config');
    my $YAMLObject        = $Kernel::OM->Get('Kernel::System::YAML');

    my $FilePath                        = $Self->GetArgument('file-path');
    my $OverwriteExistingConfigurations = $Self->GetOption('overwrite-existing-configurations');

    my $FileContent = $MainObject->FileRead(
        Location        => $FilePath,
        Mode            => 'utf8',
        Type            => 'Local',
        Result          => 'SCALAR',
        DisableWarnings => 1,
    );

    if ( !$FileContent ) {
        $Self->PrintError("File $FilePath could not be read.");
        return $Self->ExitCodeError();
    }

    my $ImportData = $YAMLObject->Load(
        Data => ${$FileContent}
    );

    if ( !IsHashRefWithData($ImportData) ) {
        $Self->PrintError("File $FilePath is not a valid YAML file.");
        return $Self->ExitCodeError();
    }

    # Import dynamic fields
    my $AvailableDynamicFieldTypes = $ConfigObject->Get('DynamicFields::Driver') // {};
    if ( IsHashRefWithData( $ImportData->{DynamicFields} ) ) {
        my @DynamicFieldConfigurations;
        DYNAMICFIELDNAME:
        for my $DynamicFieldName ( sort keys %{ $ImportData->{DynamicFields} } ) {
            next DYNAMICFIELDNAME if !IsHashRefWithData( $ImportData->{DynamicFields}->{$DynamicFieldName} );

            my $FieldType = $ImportData->{DynamicFields}->{$DynamicFieldName}->{FieldType};

            if ( !IsHashRefWithData( $AvailableDynamicFieldTypes->{$FieldType} ) ) {
                $Self->PrintError(
                    "Could not import configuration of dynamic field '$DynamicFieldName': Dynamic field backend for field type '$FieldType' does not exist."
                );

                next DYNAMICFIELDNAME;
            }

            push @DynamicFieldConfigurations, $ImportData->{DynamicFields}->{$DynamicFieldName};
        }

        if ($OverwriteExistingConfigurations) {
            $ZnunyHelperObject->_DynamicFieldsCreate(@DynamicFieldConfigurations);
        }
        else {
            $ZnunyHelperObject->_DynamicFieldsCreateIfNotExists(@DynamicFieldConfigurations);
        }
    }

    # Import dynamic fields screens
    if ( IsHashRefWithData( $ImportData->{DynamicFieldScreens} ) ) {
        $ZnunyHelperObject->_DynamicFieldsScreenConfigImport(
            Config => $ImportData->{DynamicFieldScreens},
        );
    }

    $Self->Print("<green>Done.</green>\n");

    return $Self->ExitCodeOk();
}

1;
