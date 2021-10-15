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

my $ZnunyHelperObject = $Kernel::OM->Get('Kernel::System::ZnunyHelper');
my $HelperObject      = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');
my $TicketObject      = $Kernel::OM->Get('Kernel::System::Ticket');
my $ConfigObject      = $Kernel::OM->Get('Kernel::Config');
my $LinkObject        = $Kernel::OM->Get('Kernel::System::LinkObject');
my $ArticleObject     = $Kernel::OM->Get('Kernel::System::Ticket::Article');

my $TransitionActionObject = $Kernel::OM->Get('Kernel::System::ProcessManagement::TransitionAction::TicketCreate');

my %AttachmentMapping = (
    Inline => {
        Count => 2,
        1     => {
            'ContentAlternative' => '',
            'ContentID'          => '',
            'ContentType'        => 'text/html; charset="utf-8"',
            'Disposition'        => 'inline',
            'Filename'           => 'file-2',
            'FilesizeRaw'        => '173'
        },
        2 => {
            'ContentAlternative' => '',
            'ContentID'          => '<inline760391.12719198.1466262667.1299839.10746837@localhost>',
            'ContentType'        => 'image/png; name="xmpl.png"',
            'Disposition'        => 'inline',
            'Filename'           => 'xmpl.png',
            'FilesizeRaw'        => '584236'
        },
        Body => 'Der erste Artikel:

Inline :)

Signatur A
der letzte Artikel:
 UnitTest body test
',
    },
    HTML => {
        Count => 1,
        1     => {
            'ContentAlternative' => '',
            'ContentID'          => '',
            'ContentType'        => 'text/html; charset="utf-8"',
            'Disposition'        => 'inline',
            'Filename'           => 'file-2',
            'FilesizeRaw'        => '178'
        },
        Body => "Der erste Artikel:

Mit freundlichem HACK

der letzte Artikel:
 UnitTest body test
",
    },
    Plain => {
        Count => 1,
        1     => {
            'ContentAlternative' => '',
            'ContentID'          => '',
            'ContentType'        => 'text/html; charset="utf-8"',
            'Disposition'        => 'inline',
            'Filename'           => 'file-2',
            'FilesizeRaw'        => '203'
        },
        Body => 'Der erste Artikel:
Mit freundlichem HACK

~~~~~~~~~~~~~~~~~~~~~~~~~~~~

der letzte Artikel:
 UnitTest body test
',
    },
    HTML_ISO => {
        Count => 2,
        1     => {
            'ContentAlternative' => '',
            'ContentID'          => '',
            'ContentType'        => 'text/html; charset="utf-8"',
            'Disposition'        => 'inline',
            'Filename'           => 'file-2',
            'FilesizeRaw'        => '411'
        },
        2 => {
            'ContentAlternative' => '',
            'ContentID'          => '<image001.png@01D1CC67.F8899900>',
            'ContentType'        => 'image/png; name="image001.png"',
            'Disposition'        => 'inline',
            'Filename'           => 'image001.png',
            'FilesizeRaw'        => '54345'
        },
        Body => 'Der erste Artikel:
Bilder wären toll

Masdasd
A
Sd
Asd
[cid:image001.png@01D1CC67.F8899900]

[cid:image001.png@01D1CC67.F8899900]
[cid:image001.png@01D1CC67.F8899900]
[cid:image001.png@01D1CC67.F8899900]

~~~~~~~~~~~~~~~~~~~~~~~~~~~~
der letzte Artikel:
 UnitTest body test
',
    },
);

for my $Mail (qw(Inline HTML Plain HTML_ISO)) {
    my @Result = $HelperObject->PostMaster(
        Location => $ConfigObject->Get('Home')
            . '/scripts/test/sample/ProcessManagement/TransitionAction/TicketCreate/ArticleTagReplace/'
            . $Mail . '.eml',
    );

    my $OldTicketID = $Result[1];

    my %OldTicket = $TicketObject->TicketGet(
        TicketID      => $OldTicketID,
        DynamicFields => 1,
        UserID        => 1,
    );

    my $OldLastArticleID = $HelperObject->ArticleCreate(
        TicketID => $OldTicketID,
    );

    my $NewTicketTitle  = $HelperObject->GetRandomID();
    my $NewTicketNumber = $TicketObject->TicketCreateNumber();

    my %Config = (

        # Ticket:
        TN           => $NewTicketNumber,
        Title        => $NewTicketTitle,
        Queue        => 'Junk',
        Lock         => 'unlock',
        Priority     => '3 normal',
        State        => 'new',
        CustomerID   => '<OTRS_TICKET_CustomerID>',
        CustomerUser => '<OTRS_TICKET_CustomerUserID>',
        OwnerID      => 1,

        # Article:
        IsVisibleForCustomer => 0,
        Body =>
            '<u>Der erste Artikel</u>:<br><OTRS_FIRST_ARTICLE_BODY><br><u>der letzte Artikel:</u><br> <OTRS_LAST_ARTICLE_BODY>',
        ContentType    => 'text/html; charset=ISO-8859-15',
        Subject        => '<OTRS_FIRST_ARTICLE_SUBJECT>',
        From           => '<OTRS_CUSTOMER_UserEmail>',
        HistoryComment => 'ProzessTicketSplit',
        HistoryType    => 'AddNote',
        LinkAs         => 'Child',
        SenderType     => 'agent',
    );

    my $TATicketCreate = $TransitionActionObject->Run(
        UserID                   => 1,
        Ticket                   => \%OldTicket,
        ProcessEntityID          => 'P1337',
        ActivityEntityID         => 'A1337',
        TransitionEntityID       => 'T1337',
        TransitionActionEntityID => 'TA1337',
        Config                   => \%Config
    );

    my $NewTicketID = $TicketObject->TicketIDLookup(
        TicketNumber => $NewTicketNumber,
        UserID       => 1,
    );

    $Self->True(
        $NewTicketID,
        "Ticket created '$NewTicketID' for $Mail mail",
    );

    my %NewTicket = $TicketObject->TicketGet(
        TicketID => $NewTicketID,
        UserID   => 1,
    );

    my $LinkList = $LinkObject->LinkList(
        Object  => 'Ticket',
        Key     => $OldTicket{TicketID},
        Object2 => 'Ticket',
        State   => 'Valid',
        Type    => 'ParentChild',
        UserID  => 1,
    );

    $Self->IsDeeply(
        $LinkList,
        {
            Ticket => {
                ParentChild => {
                    Target => {
                        $NewTicketID => 1,
                    },
                },
            },
        },
        "Link between both tickets set correctly.",
    );

    my @ArticleIDs = $ArticleObject->ArticleIndex(
        TicketID => $NewTicketID,
    );
    $Self->Is(
        ( scalar @ArticleIDs ),
        1,
        "Created one article for ticket '$NewTicketID' in $Mail mail",
    );

    for my $ArticleID (@ArticleIDs) {
        my %Article = $ArticleObject->ArticleGet(
            TicketID  => $NewTicketID,
            ArticleID => $ArticleID,
            UserID    => 1,
        );

        my %ArticleAttachmentIndex = $ArticleObject->ArticleAttachmentIndex(
            TicketID  => $NewTicketID,
            ArticleID => $ArticleID,
        );

        $Self->Is(
            ( scalar keys %ArticleAttachmentIndex ),
            $AttachmentMapping{$Mail}->{Count},
            "Attachment count for article '$Article{ArticleID}' of ticket '$NewTicketID' in $Mail mail",
        );

        for my $AtmID ( sort keys %ArticleAttachmentIndex ) {

            my %ArticleAttachment = $ArticleObject->ArticleAttachment(
                TicketID  => $NewTicketID,
                ArticleID => $Article{ArticleID},
                FileID    => $AtmID,
                UserID    => 1,
            );

            # skip content check
            delete $ArticleAttachment{Content};

            $Self->IsDeeply(
                \%ArticleAttachment,
                $AttachmentMapping{$Mail}->{$AtmID},
                "Matching attachment ID $AtmID for article '$Article{ArticleID}' of ticket '$NewTicketID' in $Mail mail",
            );
        }

        # due to Sublime we need to remove trailing space
        # since the little feller wouldn't let me disable it
        $Article{Body} =~ s{[ ]+\n}{\n}g;

        $Self->Is(
            $Article{Body},
            $AttachmentMapping{$Mail}->{Body},
            "Matching body for article '$Article{ArticleID}' of ticket '$NewTicketID' in $Mail mail",
        );
    }
}

1;
