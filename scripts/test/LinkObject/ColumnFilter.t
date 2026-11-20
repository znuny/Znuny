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
my $HelperObject = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');
my $TicketObject = $Kernel::OM->Get('Kernel::System::Ticket');
my $StateObject  = $Kernel::OM->Get('Kernel::System::State');
my $LinkObject   = $Kernel::OM->Get('Kernel::System::LinkObject');
my $ConfigObject = $Kernel::OM->Get('Kernel::Config');

$ConfigObject->Set(
    Key   => 'CheckEmailAddresses',
    Value => 0,
);

my $UserID = 1;

my %StateList = $StateObject->StateList(
    UserID => $UserID,
    Valid  => 1,
);
my ($OpenStateID) = grep { $StateList{$_} eq 'open' } keys %StateList;
my ($ClosedStateID)
    = grep { $StateList{$_} eq 'closed successful' || $StateList{$_} =~ m{\Aclosed}xms } keys %StateList;

$Self->True(
    scalar $OpenStateID,
    'Found open state for test',
);
$Self->True(
    scalar $ClosedStateID,
    'Found closed state for test',
);

my $SourceTicketID = $TicketObject->TicketCreate(
    Title        => 'LinkObject ColumnFilter Source',
    Queue        => 'Raw',
    Lock         => 'unlock',
    Priority     => '3 normal',
    State        => 'open',
    CustomerID   => 'LinkObjectColumnFilter',
    CustomerUser => 'customer@example.com',
    OwnerID      => $UserID,
    UserID       => $UserID,
);
$Self->True( $SourceTicketID, 'Created source ticket' );

my $OpenTicketID = $TicketObject->TicketCreate(
    Title        => 'LinkObject ColumnFilter Open',
    Queue        => 'Raw',
    Lock         => 'unlock',
    Priority     => '3 normal',
    State        => 'open',
    CustomerID   => 'LinkObjectColumnFilter',
    CustomerUser => 'customer@example.com',
    OwnerID      => $UserID,
    UserID       => $UserID,
);
$Self->True( $OpenTicketID, 'Created open linked ticket' );

my $ClosedTicketID = $TicketObject->TicketCreate(
    Title        => 'LinkObject ColumnFilter Closed',
    Queue        => 'Raw',
    Lock         => 'unlock',
    Priority     => '3 normal',
    StateID      => $ClosedStateID,
    CustomerID   => 'LinkObjectColumnFilter',
    CustomerUser => 'customer@example.com',
    OwnerID      => $UserID,
    UserID       => $UserID,
);
$Self->True( $ClosedTicketID, 'Created closed linked ticket' );

for my $TargetTicketID ( $OpenTicketID, $ClosedTicketID ) {
    my $Success = $LinkObject->LinkAdd(
        SourceObject => 'Ticket',
        SourceKey    => $SourceTicketID,
        TargetObject => 'Ticket',
        TargetKey    => $TargetTicketID,
        Type         => 'Normal',
        State        => 'Valid',
        UserID       => $UserID,
    );
    $Self->True( $Success, "Linked source ticket to $TargetTicketID" );
}

$Kernel::OM->ObjectParamAdd(
    'Kernel::Output::HTML::Layout' => {
        UserID => $UserID,
        Lang   => 'en',
    },
);
my $LayoutObject = $Kernel::OM->Get('Kernel::Output::HTML::Layout');

my $GetLinkedTicketIDs = sub {
    my (%Param) = @_;

    my %TicketIDs;
    for my $LinkType ( sort keys %{ $Param{LinkList}->{Ticket} || {} } ) {
        for my $Direction ( sort keys %{ $Param{LinkList}->{Ticket}->{$LinkType} } ) {
            for my $TicketID ( sort keys %{ $Param{LinkList}->{Ticket}->{$LinkType}->{$Direction} } ) {
                $TicketIDs{$TicketID} = 1;
            }
        }
    }
    return %TicketIDs;
};

my $FetchLinkList = sub {
    return $LinkObject->LinkListWithData(
        Object           => 'Ticket',
        Key              => $SourceTicketID,
        State            => 'Valid',
        UserID           => $UserID,
        ObjectParameters => {
            Ticket => {
                IgnoreLinkedTicketStateTypes => 1,
            },
        },
    );
};

my $LinkListWithData = $FetchLinkList->();
$Self->True(
    IsHashRefWithData( $LinkListWithData->{Ticket} ),
    'LinkListWithData contains Ticket entries',
);

my $FilteredOpen = $LayoutObject->LinkObjectColumnFilterApply(
    LinkListWithData => $FetchLinkList->(),
    ColumnFilter     => {
        StateIDs => [$OpenStateID],
    },
);
my %OpenRemaining = $GetLinkedTicketIDs->( LinkList => $FilteredOpen );

$Self->True(
    $OpenRemaining{$OpenTicketID},
    'Open linked ticket remains after State filter',
);
$Self->False(
    $OpenRemaining{$ClosedTicketID},
    'Closed linked ticket removed by State filter',
);

my $FilteredClosed = $LayoutObject->LinkObjectColumnFilterApply(
    LinkListWithData => $FetchLinkList->(),
    ColumnFilter     => {
        StateIDs => [$ClosedStateID],
    },
);
my %ClosedRemaining = $GetLinkedTicketIDs->( LinkList => $FilteredClosed );

$Self->True(
    $ClosedRemaining{$ClosedTicketID},
    'Closed linked ticket remains after State filter',
);
$Self->False(
    $ClosedRemaining{$OpenTicketID},
    'Open linked ticket removed by closed State filter',
);

my $NoMatchList = $LayoutObject->LinkObjectColumnFilterApply(
    LinkListWithData => $FetchLinkList->(),
    ColumnFilter     => {
        StateIDs => [999999],
    },
);

$Self->IsDeeply(
    $NoMatchList->{Ticket},
    {},
    'Empty Ticket hash kept when filter matches nothing',
);

# Store an active State filter, then clear it with DeleteFilter (empty multiselect signal).
my $PreferencesSet = $LayoutObject->LinkObjectColumnFilterPreferencesSet(
    ColumnFilter => {
        StateIDs => [$OpenStateID],
    },
);
$Self->True(
    $PreferencesSet,
    'Stored State column filter in user preferences',
);

my $UnitTestParamObject = $Kernel::OM->Get('Kernel::System::UnitTest::Param');
$UnitTestParamObject->ParamSet(
    Name  => 'ColumnFilterState',
    Value => ['DeleteFilter'],
);

my %ClearedFilterResult = $LayoutObject->LinkObjectColumnFilterParamGet();
$Self->False(
    exists $ClearedFilterResult{ColumnFilter}->{StateIDs},
    'DeleteFilter removes StateIDs from column filter params',
);
$Self->False(
    exists $ClearedFilterResult{GetColumnFilter}->{State},
    'DeleteFilter removes State from GetColumnFilter',
);

my $ClearedList = $LayoutObject->LinkObjectColumnFilterApply(
    LinkListWithData => $FetchLinkList->(),
    ColumnFilter     => $ClearedFilterResult{ColumnFilter},
);
my %ClearedRemaining = $GetLinkedTicketIDs->( LinkList => $ClearedList );

$Self->True(
    $ClearedRemaining{$OpenTicketID},
    'Open linked ticket remains after DeleteFilter',
);
$Self->True(
    $ClearedRemaining{$ClosedTicketID},
    'Closed linked ticket remains after DeleteFilter',
);

my $ClearedPreferencesSet = $LayoutObject->LinkObjectColumnFilterPreferencesSet(
    ColumnFilter => $ClearedFilterResult{ColumnFilter} || {},
);
$Self->True(
    $ClearedPreferencesSet,
    'Cleared column filter preferences after DeleteFilter',
);

$Kernel::OM->ObjectsDiscard(
    Objects => ['Kernel::System::Web::Request'],
);

my %StoredAfterClear = $LayoutObject->LinkObjectColumnFilterParamGet();
$Self->IsDeeply(
    $StoredAfterClear{ColumnFilter},
    {},
    'Stored preferences no longer contain column filters after DeleteFilter',
);

# Store again, then clear all filters via DeleteFilters (Clear all filters link).
$PreferencesSet = $LayoutObject->LinkObjectColumnFilterPreferencesSet(
    ColumnFilter => {
        StateIDs => [$OpenStateID],
    },
);
$Self->True(
    $PreferencesSet,
    'Stored State column filter again for DeleteFilters test',
);

$Kernel::OM->ObjectsDiscard(
    Objects => ['Kernel::System::Web::Request'],
);

$UnitTestParamObject->ParamSet(
    Name  => 'DeleteFilters',
    Value => 'DeleteFilters',
);

my %DeleteAllResult = $LayoutObject->LinkObjectColumnFilterParamGet();
$Self->IsDeeply(
    $DeleteAllResult{ColumnFilter},
    {},
    'DeleteFilters clears all column filter params',
);
$Self->IsDeeply(
    $DeleteAllResult{GetColumnFilter},
    {},
    'DeleteFilters clears GetColumnFilter',
);

$ClearedPreferencesSet = $LayoutObject->LinkObjectColumnFilterPreferencesSet(
    ColumnFilter => $DeleteAllResult{ColumnFilter} || {},
);
$Self->True(
    $ClearedPreferencesSet,
    'Cleared column filter preferences after DeleteFilters',
);

$Kernel::OM->ObjectsDiscard(
    Objects => ['Kernel::System::Web::Request'],
);

my %StoredAfterDeleteAll = $LayoutObject->LinkObjectColumnFilterParamGet();
$Self->IsDeeply(
    $StoredAfterDeleteAll{ColumnFilter},
    {},
    'Stored preferences no longer contain column filters after DeleteFilters',
);

1;
