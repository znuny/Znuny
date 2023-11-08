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

my $SeleniumObject = $Kernel::OM->Get('Kernel::System::UnitTest::Selenium');

my $SeleniumTest = sub {

    my $CacheObject       = $Kernel::OM->Get('Kernel::System::Cache');
    my $HelperObject      = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');
    my $ZnunyHelperObject = $Kernel::OM->Get('Kernel::System::ZnunyHelper');
    my $LinkObject        = $Kernel::OM->Get('Kernel::System::LinkObject');
    my $ConfigObject      = $Kernel::OM->Get('Kernel::Config');

    $CacheObject->Configure(
        CacheInMemory => 0,
    );

    my $ShowDeleteButton = $ConfigObject->Get('LinkObject::ShowDeleteButton');
    $Self->True(
        $ShowDeleteButton,
        'LinkObject::ShowDeleteButton',
    );

    # create test user and login
    my %TestUser = $SeleniumObject->AgentLogin(
        Groups => ['users'],
    );

    # create test Ticket and Articles
    my $TicketID = $HelperObject->TicketCreate();

    my $Article = $HelperObject->ArticleCreate(
        TicketID => $TicketID,
    );

    # navigate to created test ticket in AgentTicketZoom page
    $SeleniumObject->AgentInterface(
        Action      => 'AgentTicketZoom',
        TicketID    => $TicketID,
        WaitForAJAX => 0,
    );

    $SeleniumObject->ElementExistsNot(
        Selector     => '#AgentTicketNoteToLinkedTicket',
        SelectorType => 'css',
    );

    my @TicketIDs;
    for my $Count ( 0 .. 2 ) {

        # create test Ticket and Articles
        my $TicketID = $HelperObject->TicketCreate();

        push @TicketIDs, $TicketID;

        my $Article = $HelperObject->ArticleCreate(
            TicketID => $TicketID,
        );
    }

    my $True = $LinkObject->LinkAdd(
        SourceObject => 'Ticket',
        SourceKey    => $TicketIDs[0],
        TargetObject => 'Ticket',
        TargetKey    => $TicketIDs[1],
        Type         => 'ParentChild',
        State        => 'Valid',
        UserID       => 1,
    );

    # check link
    $Self->True(
        $True,
        "LinkAdd successfully.",
    );

    # navigate to created test ticket in AgentTicketZoom page
    $SeleniumObject->AgentInterface(
        Action      => 'AgentTicketZoom',
        TicketID    => $TicketIDs[0],
        WaitForAJAX => 0,
    );

    # check elements
    $Self->True(
        $SeleniumObject->find_element( 'a[href*="AgentTicketNoteToLinkedTicket"]', 'css' )->is_displayed(),
        "AgentTicketNoteToLinkedTicket article menu item is visible",
    );

    # click 'Transfer notice' button (AgentTicketNoteToLinkedTicket)
    $SeleniumObject->find_element( 'a[href*="AgentTicketNoteToLinkedTicket"]', 'css' )->click();

    # switch window
    $SeleniumObject->SwitchToPopUp(
        WaitForAJAX => 0,
    );

    my $Result = $SeleniumObject->InputFieldIDMapping(
        Action  => 'AgentTicketNoteToLinkedTicket',
        Mapping => {
            RichText        => 'RichText',
            Subject         => 'Subject',
            LinkedTicketIDs => 'LinkedTicketIDs',
        },
    );

    $Self->True(
        $SeleniumObject->find_element( '#LinkedTicketIDs_Search', 'css' )->is_displayed(),
        "Element LinkedTicketIDs_Search is visible",
    );

    $SeleniumObject->ElementExists(
        Selector     => '#LinkedTicketIDs',
        SelectorType => 'css',
    );

    $SeleniumObject->InputSet(
        Attribute   => 'LinkedTicketIDs',
        Content     => $TicketIDs[1],
        WaitForAJAX => 0,
    );

    my $LinkedTicketIDs = $SeleniumObject->InputGet(
        Attribute => 'LinkedTicketIDs',
    ) // [];

    $Self->Is(
        scalar @{$LinkedTicketIDs},
        1,
        'One ticket must be selected for linking.',
    );

    my $LinkedTicketID = shift @{$LinkedTicketIDs};

    $Self->Is(
        $LinkedTicketID,
        $TicketIDs[1],
        "LinkedTicketID is correct.",
    );

    my $NoteToLinkedTicket = 'This note is for linked ticket.';

    $SeleniumObject->InputSet(
        Attribute   => 'RichText',
        Content     => $NoteToLinkedTicket,
        WaitForAJAX => 0,
    );

    $SeleniumObject->InputSet(
        Attribute   => 'Subject',
        Content     => $NoteToLinkedTicket,
        WaitForAJAX => 0,
    );

    $SeleniumObject->find_element( '#submitRichText', 'css' )->click();

    my $ArticleObject        = $Kernel::OM->Get('Kernel::System::Ticket::Article');
    my $ArticleBackendObject = $ArticleObject->BackendForChannel( ChannelName => 'Internal' );

    my @Articles = $ArticleObject->ArticleList(
        TicketID => $TicketIDs[1],

        #         IsVisibleForCustomer => 1,
    );
    my @ArticleBox;
    for my $Article ( \@Articles ) {
        my %Article = $ArticleBackendObject->ArticleGet(
            TicketID      => $TicketIDs[1],
            ArticleID     => $Article->{ArticleID},
            DynamicFields => 0,
            UserID        => 1,
        );
        push @ArticleBox, \%Article;
    }

    $Self->Is(
        $ArticleBox[1]->{Body},
        $NoteToLinkedTicket,
        "Article text is correct.",
    );

};

# finally run the test(s) in the browser
$SeleniumObject->RunTest($SeleniumTest);

1;
