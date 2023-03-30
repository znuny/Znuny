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
        RestoreDatabase => 1,
    },
);

use parent qw(Kernel::System::ProcessManagement::TransitionAction::Base);

my $TicketObject       = $Kernel::OM->Get('Kernel::System::Ticket');
my $HelperObject       = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');
my $DynamicFieldObject = $Kernel::OM->Get('Kernel::System::DynamicField');

my $RandomID = $HelperObject->GetRandomID();
my $UserID   = 1;

my $TestCustomerUserLogin = $HelperObject->TestCustomerUserCreate(
    Language => 'de',
);

my $TicketID = $HelperObject->TicketCreate(
    CustomerUser => $TestCustomerUserLogin,
);
my $TicketID2 = $HelperObject->TicketCreate();

my %Ticket = $TicketObject->TicketGet(
    TicketID      => $TicketID,
    DynamicFields => 1,
    UserID        => $UserID,
);

# _CheckParams
my @Tests = (
    {
        Name => "_CheckParams: Valid",
        Data => {
            CommonMessage            => 'Message ',
            UserID                   => 1,
            Ticket                   => \%Ticket,
            ProcessEntityID          => 'Process-36055bb5a4e5588a4fecc97712cce3e0',
            ActivityEntityID         => 'Activity-a86e85ddbe13912fa95c7cdb511743d8',
            TransitionEntityID       => 'Transition-3355f16e2343ef00cee769cf6601461a',
            TransitionActionEntityID => 'TransitionAction-30dcb7335d2429e8e5a8bd4f2603a614',
            Config                   => {
                UserID => 1,
            }
        },
        ExpectedResult => 1,
    },
    {
        Name => "_CheckParams: Invalid - Need UserID",
        Data => {
            CommonMessage            => 'Message ',
            Ticket                   => \%Ticket,
            ProcessEntityID          => 'Process-36055bb5a4e5588a4fecc97712cce3e0',
            ActivityEntityID         => 'Activity-a86e85ddbe13912fa95c7cdb511743d8',
            TransitionEntityID       => 'Transition-3355f16e2343ef00cee769cf6601461a',
            TransitionActionEntityID => 'TransitionAction-30dcb7335d2429e8e5a8bd4f2603a614',
            Config                   => {
                UserID => 1,
            }
        },
        ExpectedResult => undef,
    },
);

for my $Test (@Tests) {
    my $Success = $Self->_CheckParams(
        %{ $Test->{Data} },
    );

    $Self->IsDeeply(
        $Success,
        $Test->{ExpectedResult},
        $Test->{Name},
    );
}

# _OverrideUserID
@Tests = (
    {
        Name => "_OverrideUserID: Valid",
        Data => {
            UserID => 1,
            Config => {
                UserID => 2
            }
        },
        ExpectedResult => 2,
    },
    {
        Name => "_OverrideUserID: Invalid - no number",
        Data => {
            UserID => 1,
            Config => {
                UserID => 'a,'
            }
        },
        ExpectedResult => 1,
    },
);

for my $Test (@Tests) {
    my $Success = $Self->_OverrideUserID(
        %{ $Test->{Data} },
    );

    $Self->IsDeeply(
        $Success,
        $Test->{ExpectedResult},
        $Test->{Name},
    );
}

# _ReplaceTicketAttributes

# <OTRS_FIRST_ARTICLE_...>
# <OTRS_LAST_ARTICLE_...>
# <OTRS_TICKET_DynamicField_Name1_Value> or <OTRS_Ticket_DynamicField_Name1_Value>.
# <OTRS_Ticket_*> is deprecated and should be removed in further versions of OTRS.

@Tests = (
    {
        Name         => "_ReplaceTicketAttributes: Title <OTRS_TICKET_DynamicField_UnitTest*>",
        DynamicField => {
            Name       => 'UnitTest' . $RandomID,
            FieldType  => 'Text',
            ObjectType => 'Ticket',
        },
        Values => {
            DynamicField => '1234',
        },
        Data => {
            UserID => 1,
            Ticket => {
                %Ticket,
                "DynamicField_UnitTest$RandomID" => 1234,
            },
            Config => {
                UserID => 1,
                Title  => "Title <OTRS_TICKET_DynamicField_UnitTest$RandomID>",
            },
        },
        ExpectedResult => {
            Title => 'Title 1234',
        },
    },
);

for my $Test (@Tests) {

    my $ID = $DynamicFieldObject->DynamicFieldAdd(
        Name       => 'UnitTest' . $RandomID,
        Label      => 'UnitTest' . $RandomID,
        FieldOrder => 1,
        FieldType  => 'Text',
        ObjectType => 'Ticket',
        ValidID    => 1,
        UserID     => 1,
        Config     => {
            DefaultValue => "",
        },
        %{ $Test->{DynamicField} },
    );

    my $Success = $HelperObject->DynamicFieldSet(
        Field    => 'UnitTest' . $RandomID,
        ObjectID => $TicketID,
        Value    => $Test->{Values}->{DynamicField},
    );

    $Success = $Self->_ReplaceTicketAttributes(
        %{ $Test->{Data} },
    );

    $Self->True(
        $Success,
        '_ReplaceTicketAttributes',
    );

    for my $Attribute ( sort keys %{ $Test->{ExpectedResult} } ) {
        $Self->IsDeeply(
            $Test->{Data}->{Config}->{$Attribute},    # replaced by _ReplaceTicketAttributes
            $Test->{ExpectedResult}->{$Attribute},
            $Test->{Name} . ' - ' . $Attribute,
        );
    }
}

# _ReplaceAdditionalAttributes
# <OTRS_OWNER_*>
# <OTRS_CURRENT_*>
# <OTRS_RESPONSIBLE_*>
# <OTRS_CUSTOMER_DATA_*>
# <OTRS_AGENT_*>
# <OTRS_CUSTOMER_*>
# <OTRS_FIRST_ARTICLE_*>
# <OTRS_LAST_ARTICLE_*>
# <OTRS_CONFIG_*>

@Tests = (
    {
        Name => "_ReplaceAdditionalAttributes: Title <OTRS_OWNER_*>",
        Data => {
            UserID => 1,
            Ticket => {
                %Ticket,
            },
            Config => {
                UserID => 1,
                Title  => "Title <OTRS_OWNER_UserFirstname>",
            },
        },
        ExpectedResult => {
            Title => 'Title Admin',
        },
    },
    {
        Name => "_ReplaceAdditionalAttributes: Title <OTRS_CUSTOMER_DATA_UserCustomerID>",
        Data => {
            UserID => 1,
            Ticket => {
                %Ticket,
            },
            Config => {
                UserID => 1,
                Title  => "Title <OTRS_CUSTOMER_DATA_UserCustomerID>",
            },
        },
        ExpectedResult => {
            Title => "Title $TestCustomerUserLogin",
        },
    },
);

for my $Test (@Tests) {

    my $Success = $Self->_ReplaceAdditionalAttributes(
        %{ $Test->{Data} },
    );

    $Self->True(
        $Success,
        '_ReplaceAdditionalAttributes',
    );

    for my $Attribute ( sort keys %{ $Test->{ExpectedResult} } ) {
        $Self->IsDeeply(
            $Test->{Data}->{Config}->{$Attribute},    # replaced by _ReplaceAdditionalAttributes
            $Test->{ExpectedResult}->{$Attribute},
            $Test->{Name} . ' - ' . $Attribute,
        );
    }
}

# _ConvertScalar2ArrayRef
@Tests = (
    {
        Name => "_ConvertScalar2ArrayRef: success",
        Data => {
            Data => ' 1,2 ,3,4 '
        },
        ExpectedResult => [ 1, 2, 3, 4 ],
    },
);

for my $Test (@Tests) {
    my $Data = $Self->_ConvertScalar2ArrayRef(
        %{ $Test->{Data} },
    );

    $Self->IsDeeply(
        $Data,
        $Test->{ExpectedResult},
        $Test->{Name},
    );
}

# _OverrideTicketID
@Tests = (
    {
        Name => "_OverrideTicketID: success",
        Data => {
            Ticket => \%Ticket,
            Config => {
                ForeignTicketID => $TicketID2,
            },
        },
        ExpectedResult => $TicketID2,
    },
);

for my $Test (@Tests) {
    my $Data = $Self->_OverrideTicketID(
        %{ $Test->{Data} },
    );

    $Self->IsDeeply(
        $Ticket{TicketID},
        $Test->{ExpectedResult},
        $Test->{Name},
    );
}
1;
