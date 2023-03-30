# --
# Copyright (C) 2021 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::Console::Command::Admin::OAuth2TokenManagement::ImportTokenConfig;

use strict;
use warnings;

use Kernel::System::VariableCheck qw(:all);

use parent qw(Kernel::System::Console::BaseCommand);

our @ObjectDependencies = (
    'Kernel::System::Main',
    'Kernel::System::Valid',
    'Kernel::System::YAML',
    'Kernel::System::OAuth2TokenConfig',
);

sub Configure {
    my ( $Self, %Param ) = @_;

    $Self->Description('Imports YAML OAuth2 token config file.');

    $Self->AddOption(
        Name        => 'overwrite',
        Description => 'If a token config with the same name already exists it will be overwritten.',
        Required    => 0,
        HasValue    => 0,
    );

    $Self->AddArgument(
        Name        => 'file-path',
        Description => 'Path to YAML token config file.',
        Required    => 1,
        ValueRegex  => qr{.+},
    );

    return;
}

sub Run {
    my ( $Self, %Param ) = @_;

    my $MainObject              = $Kernel::OM->Get('Kernel::System::Main');
    my $ValidObject             = $Kernel::OM->Get('Kernel::System::Valid');
    my $YAMLObject              = $Kernel::OM->Get('Kernel::System::YAML');
    my $OAuth2TokenConfigObject = $Kernel::OM->Get('Kernel::System::OAuth2TokenConfig');

    my $UserID   = 1;
    my $FilePath = $Self->GetArgument('file-path');

    $Self->Print("Importing YAML token config file $FilePath ...\n");

    my $FileContentRef = $MainObject->FileRead(
        Location => $FilePath,
    );
    if ( !$FileContentRef ) {
        $Self->PrintError("Error reading file $FilePath.");
        return $Self->ExitCodeError();
    }

    my $TokenConfigs = $YAMLObject->Load(
        Data => ${$FileContentRef},
    );

    if (
        !IsArrayRefWithData($TokenConfigs)
        && !IsHashRefWithData($TokenConfigs)
        )
    {
        $Self->PrintError("File $FilePath does not contain valid YAML data.");
        return $Self->ExitCodeError();
    }

    if ( IsHashRefWithData($TokenConfigs) ) {
        $TokenConfigs = [$TokenConfigs];
    }

    my $Overwrite = $Self->GetOption('overwrite');

    my @ValidIDs = $ValidObject->ValidIDsGet();
    my $ValidID  = shift @ValidIDs;

    my $ImportSuccessful = $OAuth2TokenConfigObject->DataImport(
        Content   => ${$FileContentRef},
        Format    => 'yml',
        Overwrite => $Overwrite,
        Data      => {
            ValidID  => $ValidID,
            CreateBy => $UserID,
            ChangeBy => $UserID,
        },
        UserID => $UserID,
    );
    if ( !$ImportSuccessful ) {
        $Self->PrintError("Error importing/parsing file $FilePath.");
        return $Self->ExitCodeError();
    }

    my @TokenConfigNames       = sort map { $_->{Name} } @{$TokenConfigs};
    my $TokenConfigNamesString = join "\n", @TokenConfigNames;

    $Self->Print("\nFile contains the following token configs:\n");
    $Self->Print("$TokenConfigNamesString\n");

    $Self->Print("\nDone.\n");

    return $Self->ExitCodeOk();
}

1;
