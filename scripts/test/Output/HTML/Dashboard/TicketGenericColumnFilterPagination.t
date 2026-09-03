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
use Kernel::Output::HTML::Dashboard::TicketGeneric;

$Kernel::OM->ObjectParamAdd(
    'Kernel::System::UnitTest::Helper' => {
        RestoreDatabase => 1,
    },
);
my $HelperObject = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');
my $ConfigObject = $Kernel::OM->Get('Kernel::Config');
my $QueueObject  = $Kernel::OM->Get('Kernel::System::Queue');
my $TicketObject = $Kernel::OM->Get('Kernel::System::Ticket');
my $UserObject   = $Kernel::OM->Get('Kernel::System::User');
my $JSONObject   = $Kernel::OM->Get('Kernel::System::JSON');
my $CacheObject  = $Kernel::OM->Get('Kernel::System::Cache');

my ( $TestUserLogin, $UserID ) = $HelperObject->TestUserCreate(
    Groups => [ 'admin', 'users' ],
);
$Self->True(
    $UserID,
    'Test user created',
);

my @QueueIDs;
for my $Counter ( 1 .. 2 ) {
    my $QueueName = 'ColumnFilterPagination' . $HelperObject->GetRandomID();
    my $QueueID   = $QueueObject->QueueAdd(
        Name            => $QueueName,
        ValidID         => 1,
        GroupID         => 1,
        SystemAddressID => 1,
        SalutationID    => 1,
        SignatureID     => 1,
        Comment         => 'UnitTest',
        UserID          => $UserID,
    );
    $Self->True(
        $QueueID,
        "Queue '$QueueName' created",
    );
    push @QueueIDs, $QueueID;
}

# Create enough matching tickets so pagination appears with PageShown = 2.
my @TicketIDs;
for my $Index ( 0 .. 2 ) {
    my $TicketID = $TicketObject->TicketCreate(
        Title        => 'ColumnFilter pagination test',
        QueueID      => $QueueIDs[ $Index % scalar @QueueIDs ],
        Lock         => 'unlock',
        Priority     => '3 normal',
        State        => 'new',
        CustomerID   => 'CustomerCompany',
        CustomerUser => 'customer@example.com',
        OwnerID      => $UserID,
        UserID       => $UserID,
    );
    $Self->True(
        $TicketID,
        "TicketID $TicketID created",
    );
    push @TicketIDs, $TicketID;
}

my $WidgetName = '0120-TicketNew';
my %Config     = %{ $ConfigObject->Get('DashboardBackend')->{$WidgetName} };
$Config{CacheTTLLocal}           = 0;
$Config{Limit}                   = 2;
$Config{DefaultColumns}->{Queue} = '2';

$Kernel::OM->ObjectParamAdd(
    'Kernel::Output::HTML::Layout' => {
        Lang => 'en',
    },
);
my $LayoutObject = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
$LayoutObject->{UserID}       = $UserID;
$LayoutObject->{UserLogin}    = $TestUserLogin;
$LayoutObject->{UserLanguage} = 'en';
$LayoutObject->{Action}       = 'AgentDashboard';
$LayoutObject->{Baselink}     = 'index.pl?';

my %GetColumnFilter = (
    "Queue$WidgetName" => [@QueueIDs],
);
my %GetColumnFilterSelect = (
    Queue => [@QueueIDs],
);
my %ColumnFilter = (
    QueueIDs => [@QueueIDs],
);

my $DashboardObject = Kernel::Output::HTML::Dashboard::TicketGeneric->new(
    Config                => \%Config,
    Name                  => $WidgetName,
    UserID                => $UserID,
    PageShown             => 2,
    Action                => 'AgentDashboard',
    ColumnFilter          => \%ColumnFilter,
    GetColumnFilter       => \%GetColumnFilter,
    GetColumnFilterSelect => \%GetColumnFilterSelect,
);

$CacheObject->CleanUp(
    Type => 'Dashboard',
);

my $Content = $DashboardObject->Run(
    AJAX => 1,
);
$Self->True(
    $Content,
    'Dashboard widget content generated',
);

my $PaginationLinks = '';
if ( $Content =~ m{Core\.Config\.AddConfig\((.+?)\);\s*//\]\]>}s ) {
    my $ConfigData = $JSONObject->Decode(
        Data => $1,
    );
    my $PaginationData = $ConfigData->{PaginationData0120TicketNew} || {};
    if ( IsHashRefWithData($PaginationData) ) {
        $PaginationLinks = join "\n", (
            keys %{$PaginationData},
            map { $_->{Baselink} // '' } grep { IsHashRefWithData($_) } values %{$PaginationData},
        );
    }
}

$Self->True(
    length $PaginationLinks,
    'Pagination links present in widget AJAX output',
);

$Self->True(
    index( $PaginationLinks, 'ARRAY(' ) == -1,
    'Pagination links do not contain stringified array references',
);

for my $QueueID (@QueueIDs) {
    my $ExpectedParam = "ColumnFilterQueue$WidgetName=$QueueID";
    $Self->True(
        index( $PaginationLinks, $ExpectedParam ) > -1,
        "Pagination links contain repeated multiselect filter '$ExpectedParam'",
    );
}

# Preferences must keep real multiselect values, not a stringified array reference.
my %Preferences = $UserObject->GetPreferences(
    UserID => $UserID,
);
my $StoredFilters = $JSONObject->Decode(
    Data => $Preferences{ 'UserDashboardTicketGenericColumnFilters' . $WidgetName } // '{}',
);
$Self->IsDeeply(
    [ sort map {"$_"} @{ $StoredFilters->{Queue} || [] } ],
    [ sort map {"$_"} @QueueIDs ],
    'Stored column filter preferences keep both multiselect queue values',
);

my $StoredRealKeys = $JSONObject->Decode(
    Data => $Preferences{ 'UserDashboardTicketGenericColumnFiltersRealKeys' . $WidgetName } // '{}',
);
$Self->IsDeeply(
    [ sort map {"$_"} @{ $StoredRealKeys->{QueueIDs} || [] } ],
    [ sort map {"$_"} @QueueIDs ],
    'Stored real-key column filter preferences keep both multiselect queue values',
);

1;
