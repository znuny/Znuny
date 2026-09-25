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

# _ReplaceTicketAttributes: attachment handling for <OTRS_FIRST_ARTICLE_Body>/<OTRS_LAST_ARTICLE_Body>.
# Only attachments actually referenced inline in the article body (e.g. embedded images) must be
# copied automatically. Regular file attachments must only be added via
# Attachments/AttachmentIDs/AttachmentsReuse in TicketCreate.pm/TicketArticleCreate.pm.
$HelperObject->ConfigSettingChange(
    Valid => 1,
    Key   => 'Frontend::RichText',
    Value => 1,
);

my $AttachmentArticleID = $HelperObject->ArticleCreate(
    TicketID => $TicketID,
);

my $ArticleBackendObject = $Kernel::OM->Get('Kernel::System::Ticket::Article')->BackendForChannel(
    ChannelName => 'Internal',
);

$ArticleBackendObject->ArticleWriteAttachment(
    Content     => 'inline image content',
    ContentType => 'image/png',
    Filename    => 'inline' . $RandomID . '.png',
    Disposition => 'inline',
    ContentID   => '<inline' . $RandomID . '>',
    ArticleID   => $AttachmentArticleID,
    UserID      => 1,
);

$ArticleBackendObject->ArticleWriteAttachment(
    Content     => 'regular file content',
    ContentType => 'application/pdf',
    Filename    => 'regular' . $RandomID . '.pdf',
    Disposition => 'attachment',
    ArticleID   => $AttachmentArticleID,
    UserID      => 1,
);

my %AttachmentTicket = $TicketObject->TicketGet(
    TicketID      => $TicketID,
    DynamicFields => 1,
    UserID        => 1,
);

# ContentType/Attachment are only resolved by _ReplaceTicketAttributes() when the call stack (as
# seen by caller()) runs through one of Base.pm's IsArticleBodyCaller whitelist modules - not
# based on which class the method is called on. To keep this a focused unit test of
# _ReplaceTicketAttributes() itself (instead of a full TicketCreate->Run() integration test with
# unrelated side effects like the new article's own auto-generated HTML body attachment), install
# a throwaway sub into TicketCreate's namespace so caller() sees a legitimate whitelisted frame.
my $AttachmentTicketCreateObject
    = $Kernel::OM->Get('Kernel::System::ProcessManagement::TransitionAction::TicketCreate');

# a fully qualified sub declaration (not an anonymous sub assigned via typeglob, whose name for
# caller() purposes would be ambiguous) so it is unambiguously registered under this name
sub Kernel::System::ProcessManagement::TransitionAction::TicketCreate::UnitTestReplaceTicketAttributes {
    my ( $UnitTestSelf, %Param ) = @_;
    return $UnitTestSelf->_ReplaceTicketAttributes(%Param);
}

my %AttachmentTestConfig = (
    UserID => 1,
    Body   => 'Text <OTRS_FIRST_ARTICLE_Body> Text',
);

my $AttachmentTestSuccess = $AttachmentTicketCreateObject->UnitTestReplaceTicketAttributes(
    UserID => 1,
    Ticket => \%AttachmentTicket,
    Config => \%AttachmentTestConfig,
);

$Self->True(
    $AttachmentTestSuccess,
    '_ReplaceTicketAttributes: attachment handling - call successful',
);

my @CopiedAttachmentFilenames = sort map { $_->{Filename} } @{ $AttachmentTestConfig{Attachment} || [] };

$Self->IsDeeply(
    \@CopiedAttachmentFilenames,
    [ 'inline' . $RandomID . '.png' ],
    '_ReplaceTicketAttributes: only inline attachments are copied automatically via <OTRS_FIRST_ARTICLE_Body>, regular file attachments are not',
);

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
