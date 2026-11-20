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

$Kernel::OM->ObjectParamAdd(
    'Kernel::System::UnitTest::Helper' => {
        RestoreDatabase  => 1,
        UseTmpArticleDir => 1,
    },
);

my $HelperObject         = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');
my $TicketObject         = $Kernel::OM->Get('Kernel::System::Ticket');
my $ArticleObject        = $Kernel::OM->Get('Kernel::System::Ticket::Article');
my $ArticleBackendObject = $ArticleObject->BackendForChannel( ChannelName => 'Internal' );

my $RandomID   = $HelperObject->GetRandomID();
my $SearchTerm = "PINEAPPLE-$RandomID";

my $TicketID = $TicketObject->TicketCreate(
    Title        => "ArticleIDsGet $RandomID",
    Queue        => 'Raw',
    Lock         => 'unlock',
    Priority     => '3 normal',
    State        => 'open',
    CustomerNo   => '123465',
    CustomerUser => 'customer@example.com',
    OwnerID      => 1,
    UserID       => 1,
);
$Self->True(
    $TicketID,
    'TicketCreate()'
);

my $OtherTicketID = $TicketObject->TicketCreate(
    Title        => "Other ArticleIDsGet $RandomID",
    Queue        => 'Raw',
    Lock         => 'unlock',
    Priority     => '3 normal',
    State        => 'open',
    CustomerNo   => '123465',
    CustomerUser => 'customer@example.com',
    OwnerID      => 1,
    UserID       => 1,
);
$Self->True(
    $OtherTicketID,
    'TicketCreate() for other ticket'
);

my $MatchingArticleID = $ArticleBackendObject->ArticleCreate(
    TicketID             => $TicketID,
    SenderType           => 'agent',
    IsVisibleForCustomer => 0,
    From                 => 'agent@example.com',
    To                   => 'customer@example.com',
    Subject              => "Matching subject $RandomID",
    Body                 => "Body with marker $SearchTerm for contains search.",
    ContentType          => 'text/plain; charset=utf-8',
    HistoryType          => 'AddNote',
    HistoryComment       => 'UnitTest',
    UserID               => 1,
    NoAgentNotify        => 1,
);
$Self->True(
    $MatchingArticleID,
    'ArticleCreate() matching article'
);

my $NonMatchingArticleID = $ArticleBackendObject->ArticleCreate(
    TicketID             => $TicketID,
    SenderType           => 'agent',
    IsVisibleForCustomer => 0,
    From                 => 'agent@example.com',
    To                   => 'customer@example.com',
    Subject              => "Non-matching subject $RandomID",
    Body                 => 'Body without the rare marker.',
    ContentType          => 'text/plain; charset=utf-8',
    HistoryType          => 'AddNote',
    HistoryComment       => 'UnitTest',
    UserID               => 1,
    NoAgentNotify        => 1,
);
$Self->True(
    $NonMatchingArticleID,
    'ArticleCreate() non-matching article'
);

my $WordsBetweenArticleID = $ArticleBackendObject->ArticleCreate(
    TicketID             => $TicketID,
    SenderType           => 'agent',
    IsVisibleForCustomer => 0,
    From                 => 'agent@example.com',
    To                   => 'customer@example.com',
    Subject              => "Words in between $RandomID",
    Body                 => 'Please refund the customer invoice after the call.',
    ContentType          => 'text/plain; charset=utf-8',
    HistoryType          => 'AddNote',
    HistoryComment       => 'UnitTest',
    UserID               => 1,
    NoAgentNotify        => 1,
);
$Self->True(
    $WordsBetweenArticleID,
    'ArticleCreate() words in between'
);

my $ReversedWordsArticleID = $ArticleBackendObject->ArticleCreate(
    TicketID             => $TicketID,
    SenderType           => 'agent',
    IsVisibleForCustomer => 0,
    From                 => 'agent@example.com',
    To                   => 'customer@example.com',
    Subject              => "Reversed words $RandomID",
    Body                 => 'The invoice versus refund note.',
    ContentType          => 'text/plain; charset=utf-8',
    HistoryType          => 'AddNote',
    HistoryComment       => 'UnitTest',
    UserID               => 1,
    NoAgentNotify        => 1,
);
$Self->True(
    $ReversedWordsArticleID,
    'ArticleCreate() reversed words'
);

my $RefundOnlyArticleID = $ArticleBackendObject->ArticleCreate(
    TicketID             => $TicketID,
    SenderType           => 'agent',
    IsVisibleForCustomer => 0,
    From                 => 'agent@example.com',
    To                   => 'customer@example.com',
    Subject              => "Refund only $RandomID",
    Body                 => 'Please refund today.',
    ContentType          => 'text/plain; charset=utf-8',
    HistoryType          => 'AddNote',
    HistoryComment       => 'UnitTest',
    UserID               => 1,
    NoAgentNotify        => 1,
);
$Self->True(
    $RefundOnlyArticleID,
    'ArticleCreate() refund only'
);

my $OtherTicketArticleID = $ArticleBackendObject->ArticleCreate(
    TicketID             => $OtherTicketID,
    SenderType           => 'agent',
    IsVisibleForCustomer => 0,
    From                 => 'agent@example.com',
    To                   => 'customer@example.com',
    Subject              => "Other ticket subject $RandomID",
    Body                 => "Other ticket also has $SearchTerm.",
    ContentType          => 'text/plain; charset=utf-8',
    HistoryType          => 'AddNote',
    HistoryComment       => 'UnitTest',
    UserID               => 1,
    NoAgentNotify        => 1,
);
$Self->True(
    $OtherTicketArticleID,
    'ArticleCreate() other ticket article'
);

for my $ArticleBuild (
    {
        TicketID  => $TicketID,
        ArticleID => $MatchingArticleID,
    },
    {
        TicketID  => $TicketID,
        ArticleID => $NonMatchingArticleID,
    },
    {
        TicketID  => $TicketID,
        ArticleID => $WordsBetweenArticleID,
    },
    {
        TicketID  => $TicketID,
        ArticleID => $ReversedWordsArticleID,
    },
    {
        TicketID  => $TicketID,
        ArticleID => $RefundOnlyArticleID,
    },
    {
        TicketID  => $OtherTicketID,
        ArticleID => $OtherTicketArticleID,
    },
    )
{
    my $IndexBuilt = $ArticleObject->ArticleSearchIndexBuild(
        TicketID  => $ArticleBuild->{TicketID},
        ArticleID => $ArticleBuild->{ArticleID},
        UserID    => 1,
    );
    $Self->True(
        $IndexBuilt,
        "ArticleSearchIndexBuild() for ArticleID $ArticleBuild->{ArticleID}"
    );
}

my @MatchingIDs = $ArticleObject->ArticleSearchIndexArticleIDsGet(
    TicketID   => $TicketID,
    SearchTerm => $SearchTerm,
);

$Self->IsDeeply(
    [ sort { $a <=> $b } @MatchingIDs ],
    [$MatchingArticleID],
    'ArticleSearchIndexArticleIDsGet() returns only matching article for ticket (contains)',
);

my @PhraseIDs = $ArticleObject->ArticleSearchIndexArticleIDsGet(
    TicketID   => $TicketID,
    SearchTerm => 'refund invoice',
);

$Self->IsDeeply(
    [ sort { $a <=> $b } @PhraseIDs ],
    [ sort { $a <=> $b } ( $WordsBetweenArticleID, $ReversedWordsArticleID ) ],
    'ArticleSearchIndexArticleIDsGet() keeps articles when both words are present in any order',
);

my @StopWordPhraseIDs = $ArticleObject->ArticleSearchIndexArticleIDsGet(
    TicketID   => $TicketID,
    SearchTerm => 'refund the invoice',
);

$Self->IsDeeply(
    [ sort { $a <=> $b } @StopWordPhraseIDs ],
    [ sort { $a <=> $b } ( $WordsBetweenArticleID, $ReversedWordsArticleID ) ],
    'ArticleSearchIndexArticleIDsGet() ignores unstored words such as the',
);

my @NoMatch = $ArticleObject->ArticleSearchIndexArticleIDsGet(
    TicketID   => $TicketID,
    SearchTerm => 'zzxqnohit',
);

$Self->IsDeeply(
    \@NoMatch,
    [],
    'ArticleSearchIndexArticleIDsGet() returns empty list when nothing matches',
);

my @AllTicketArticleIDs = sort { $a <=> $b } (
    $MatchingArticleID,
    $NonMatchingArticleID,
    $WordsBetweenArticleID,
    $ReversedWordsArticleID,
    $RefundOnlyArticleID,
);

my @StarIDs = $ArticleObject->ArticleSearchIndexArticleIDsGet(
    TicketID   => $TicketID,
    SearchTerm => '*',
);

$Self->IsDeeply(
    [ sort { $a <=> $b } @StarIDs ],
    \@AllTicketArticleIDs,
    'ArticleSearchIndexArticleIDsGet() does not filter when the search term is only *',
);

my @MissingParams = $ArticleObject->ArticleSearchIndexArticleIDsGet(
    TicketID => $TicketID,
);
$Self->False(
    scalar @MissingParams,
    'ArticleSearchIndexArticleIDsGet() fails without SearchTerm',
);

1;
