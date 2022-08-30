# --
# Copyright (C) 2001-2021 OTRS AG, https://otrs.com/
# Copyright (C) 2021-2022 Znuny GmbH, https://znuny.org/
# Copyright (C) 2021 maxence business consulting GmbH, http://www.maxence.de
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see https://www.gnu.org/licenses/gpl-3.0.txt.
# --

package Kernel::System::Console::Command::Admin::WebService::Add;

use strict;
use warnings;

use parent qw(Kernel::System::Console::BaseCommand);

our @ObjectDependencies = (
    'Kernel::System::GenericInterface::Webservice',
    'Kernel::System::Main',
    'Kernel::System::YAML',
);

sub Configure {
    my ( $Self, %Param ) = @_;

    $Self->Description('Create a new web service.');
    $Self->AddOption(
        Name        => 'name',
        Description => "The name of the new web service.",
        Required    => 1,
        HasValue    => 1,
        ValueRegex  => qr/.*/smx,
    );
    $Self->AddOption(
        Name        => 'source-path',
        Description => "Specify the location of the web service YAML configuration file.",
        Required    => 1,
        HasValue    => 1,
        ValueRegex  => qr/.*/smx,
    );

    return;
}

sub PreRun {
    my ( $Self, %Param ) = @_;

    my $SourcePath = $Self->GetOption('source-path');
    if ( !-r $SourcePath ) {
        die "Source file $SourcePath does not exist / is not readable.\n";
    }

    my $List = $Kernel::OM->Get('Kernel::System::GenericInterface::Webservice')->WebserviceList( Valid => 0 );
    my %WebServiceLookup = reverse %{$List};

    my $Name = $Self->GetOption('name');
    if ( $WebServiceLookup{$Name} ) {
        die "A web service with name $Name already exists in this system.\n";
    }

    return;
}

sub Run {
    my ( $Self, %Param ) = @_;

    $Self->Print("<yellow>Creating web service...</yellow>\n");

    # read config
    my $Content = $Kernel::OM->Get('Kernel::System::Main')->FileRead(
        Location => $Self->GetOption('source-path'),
    );
    if ( !$Content ) {
        $Self->PrintError('Could not read YAML source.');
        return $Self->ExitCodeError();
    }

    my $Config = $Kernel::OM->Get('Kernel::System::YAML')->Load( Data => ${$Content} );

    if ( !$Config ) {
        $Self->PrintError('Could not parse YAML source.');
        return $Self->ExitCodeError();
    }

    # add new web service
    my $ID = $Kernel::OM->Get('Kernel::System::GenericInterface::Webservice')->WebserviceAdd(
        Name    => $Self->GetOption('name'),
        Config  => $Config,
        ValidID => 1,
        UserID  => 1,
    );

    if ( !$ID ) {
        $Self->PrintError('Could not create web service!');
        return $Self->ExitCodeError();
    }

    $Self->Print("<green>Done.</green>\n");
    return $Self->ExitCodeOk();
}

1;
