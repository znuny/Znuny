# --
# Copyright (C) 2001-2021 OTRS AG, https://otrs.com/
# Copyright (C) 2021 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see https://www.gnu.org/licenses/gpl-3.0.txt.
# --

# This test should verify that a module gets the configured parameters
#   passed directly in the param hash

## no critic (Modules::RequireExplicitPackage)
use strict;
use warnings;
use utf8;

use vars (qw($Self));

# get needed objects
my $ConfigObject       = $Kernel::OM->Get('Kernel::Config');
my $TicketObject       = $Kernel::OM->Get('Kernel::System::Ticket');
my $GenericAgentObject = $Kernel::OM->Get('Kernel::System::GenericAgent');

# get helper object
$Kernel::OM->ObjectParamAdd(
    'Kernel::System::UnitTest::Helper' => {
        RestoreDatabase  => 1,
        UseTmpArticleDir => 1,
    },
);
my $Helper = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');

my %Jobs;

# create a Ticket to test JobRun and JobRunTicket
my $TicketID = $TicketObject->TicketCreate(
    Title        => 'Testticket for Untittest of the Generic Agent',
    Queue        => 'Raw',
    Lock         => 'unlock',
    PriorityID   => 1,
    StateID      => 1,
    CustomerNo   => '123465',
    CustomerUser => 'customerUnitTest@example.com',
    OwnerID      => 1,
    UserID       => 1,
);

$Self->True(
    $TicketID,
    "Ticket is created - $TicketID",
);

my %Ticket = $TicketObject->TicketGet(
    TicketID => $TicketID,
);

$Self->True(
    $Ticket{TicketNumber},
    "Found ticket number - $Ticket{TicketNumber}",
);

my $Home = $ConfigObject->Get('Home');

my $FileTempObject = $Kernel::OM->Get('Kernel::System::FileTemp');

ALLOWCUSTOMMODULEEXECUTION:
for my $AllowCustomModuleExecution ( 0, 1 ) {

    $ConfigObject->Set(
        Key   => 'Ticket::GenericAgentAllowCustomModuleExecution',
        Value => $AllowCustomModuleExecution,
    );

    my ( $FileHandle, $FileName ) = $FileTempObject->TempFile();

    $Self->True(
        -e $FileName ? 1 : 0,
        "GenericAgent ModuleExecution: $AllowCustomModuleExecution TmpFile $FileName created"
    );

    my $Name = 'job' . $Helper->GetRandomID();

    my %NewJob = (
        Name => $Name,
        Data => {
            TicketNumber => $Ticket{TicketNumber},
        },
    );

    $NewJob{Data}->{NewModule}      = 'scripts::test::sample::GenericAgent::CustomCode::DeleteTmp';
    $NewJob{Data}->{NewParamKey1}   = 'FileName';
    $NewJob{Data}->{NewParamValue1} = $FileName;

    my $JobAdd = $GenericAgentObject->JobAdd(
        %NewJob,
        UserID => 1,
    );
    $Self->True(
        $JobAdd || '',
        "GenericAgent ModuleExecution: $AllowCustomModuleExecution JobAdd() - $Name",
    );

    $Self->True(
        $GenericAgentObject->JobRun(
            Job    => $Name,
            UserID => 1,
        ),
        "GenericAgent ModuleExecution: $AllowCustomModuleExecution JobRun() - $Name",
    );

    my $JobDelete = $GenericAgentObject->JobDelete(
        Name   => $Name,
        UserID => 1,
    );
    $Self->True(
        $JobDelete || '',
        "GenericAgent ModuleExecution: $AllowCustomModuleExecution JobDelete() - $Name",
    );

    if ($AllowCustomModuleExecution) {
        $Self->False(
            -e $FileName ? 1 : 0,
            "GenericAgent ModuleExecution: $AllowCustomModuleExecution TmpFile $FileName exists with false"
        );
        next ALLOWCUSTOMMODULEEXECUTION;
    }
    $Self->True(
        -e $FileName ? 1 : 0,
        "GenericAgent ModuleExecution: $AllowCustomModuleExecution TmpFile $FileName exists (no custom module executed)"
    );
}

1;
