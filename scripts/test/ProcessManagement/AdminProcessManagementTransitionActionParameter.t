# --
# Copyright (C) 2021 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

use strict;
use warnings;
use utf8;

use vars (qw($Self));

use Kernel::System::VariableCheck qw(:all);

$Kernel::OM->ObjectParamAdd(
    'Kernel::System::UnitTest::Helper' => {
        RestoreDatabase  => 1,
        UseTmpArticleDir => 1,
    },
);

my $HelperObject = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');
my $LayoutObject = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
my $MainObject   = $Kernel::OM->Get('Kernel::System::Main');
my $ConfigObject = $Kernel::OM->Get('Kernel::Config');

$MainObject->Require('Kernel::Modules::AdminProcessManagementTransitionAction');

my $TestModule = Kernel::Modules::AdminProcessManagementTransitionAction->new();

# define variables
my $RandomID = $HelperObject->GetRandomID();

#
# Create the config for testing
#

# add config
$ConfigObject->Set(
    Key   => 'ProcessManagement::TransitionAction::DefaultParameters###001-Framework',
    Value => {
        TicketCreate => {
            Body   => $RandomID,
            From   => 'Znuny',
            UserID => 123,
        },
        TicketCustomerSet => {
            CustomerID     => 'client123',
            CustomerUserID => 'client-user-123',
        },
        TicketLockSet => {
            Lock   => '(Lock|Unlock)',
            LockID => '(1|2)',
        },
    }
);

$ConfigObject->Set(
    Key   => 'ProcessManagement::TransitionAction::DefaultParameters###001-Custom',
    Value => {
        NewTransitionAction => {
            Body   => $RandomID,
            UserID => 1,
            NewKey => 1,
        },
    }
);

# add tests
my @ParameterTestConfigs = (
    {
        Name         => 'TicketCreate',
        ActionModule => 'Kernel::System::ProcessManagement::TransitionAction::TicketCreate',
        Result       => {
            Body   => $RandomID,
            From   => 'Znuny',
            UserID => 123,
        },
    },
    {
        Name         => 'TicketCustomerSet',
        ActionModule => 'Kernel::System::ProcessManagement::TransitionAction::TicketCustomerSet',
        Result       => {
            CustomerID     => 'client123',
            CustomerUserID => 'client-user-123',
        },
    },
    {
        Name         => 'UnknownConfig',
        ActionModule => $RandomID,
        Result       => {},
    },
    {
        Name         => 'EmptyConfig',
        ActionModule => '',
        Result       => {},
    },
    {
        Name         => 'NewTransitionAction',
        ActionModule => 'Kernel::System::ProcessManagement::TransitionAction::NewTransitionAction',
        Result       => {
            Body   => $RandomID,
            UserID => 1,
            NewKey => 1,
        },
    },
);

for my $Test (@ParameterTestConfigs) {

    # run module
    my %Result = $TestModule->_GetDefaultConfigParameters(
        Module => $Test->{ActionModule},
    );

    $Self->IsDeeply(
        \%Result,
        $Test->{Result},
        $Test->{Name} . ' - Result is equal to the expectation.',
    );
}

1;
