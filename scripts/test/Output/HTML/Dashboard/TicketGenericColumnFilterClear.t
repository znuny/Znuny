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
    my $QueueName = 'ColumnFilterClear' . $HelperObject->GetRandomID();
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

my @TicketIDs;
for my $Index ( 0 .. 1 ) {
    my $TicketID = $TicketObject->TicketCreate(
        Title        => 'ColumnFilter clear test',
        QueueID      => $QueueIDs[$Index],
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
$Config{Limit}                   = 25;
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

# Store an active multiselect column filter.
my $DashboardObject = Kernel::Output::HTML::Dashboard::TicketGeneric->new(
    Config       => \%Config,
    Name         => $WidgetName,
    UserID       => $UserID,
    PageShown    => 25,
    Action       => 'AgentDashboard',
    AddFilters   => 1,
    ColumnFilter => {
        QueueIDs => [@QueueIDs],
    },
    GetColumnFilter => {
        "Queue$WidgetName" => [@QueueIDs],
    },
    GetColumnFilterSelect => {
        Queue => [@QueueIDs],
    },
);

$CacheObject->CleanUp(
    Type => 'Dashboard',
);

my $Content = $DashboardObject->Run(
    AJAX => 1,
);
$Self->True(
    $Content,
    'Dashboard widget content generated with column filter',
);

my %Preferences = $UserObject->GetPreferences(
    UserID => $UserID,
);
my $StoredFilters = $JSONObject->Decode(
    Data => $Preferences{ 'UserDashboardTicketGenericColumnFilters' . $WidgetName } // '{}',
);
$Self->IsDeeply(
    [ sort map {"$_"} @{ $StoredFilters->{Queue} || [] } ],
    [ sort map {"$_"} @QueueIDs ],
    'Column filter preferences stored for Queue',
);

# Clear via DeleteFilter (same signal Confirm sends for empty multiselect).
$DashboardObject = Kernel::Output::HTML::Dashboard::TicketGeneric->new(
    Config       => \%Config,
    Name         => $WidgetName,
    UserID       => $UserID,
    PageShown    => 25,
    Action       => 'AgentDashboard',
    AddFilters   => 1,
    ColumnFilter => {
        QueueIDs => ['DeleteFilter'],
    },
    GetColumnFilter => {
        "Queue$WidgetName" => ['DeleteFilter'],
    },
    GetColumnFilterSelect => {
        Queue => ['DeleteFilter'],
    },
);

$CacheObject->CleanUp(
    Type => 'Dashboard',
);

$Content = $DashboardObject->Run(
    AJAX => 1,
);
$Self->True(
    $Content,
    'Dashboard widget content generated after DeleteFilter',
);

%Preferences = $UserObject->GetPreferences(
    UserID => $UserID,
);
$StoredFilters = $JSONObject->Decode(
    Data => $Preferences{ 'UserDashboardTicketGenericColumnFilters' . $WidgetName } // '{}',
);
$Self->False(
    exists $StoredFilters->{Queue},
    'DeleteFilter removes Queue from column filter preferences',
);

my $StoredRealKeys = $JSONObject->Decode(
    Data => $Preferences{ 'UserDashboardTicketGenericColumnFiltersRealKeys' . $WidgetName } // '{}',
);
$Self->False(
    exists $StoredRealKeys->{QueueIDs},
    'DeleteFilter removes QueueIDs from real-key column filter preferences',
);

# Also cover DeleteFilter when only GetColumnFilter* carry the clear signal
# (matches AgentDashboardCommon before it populated ColumnFilter on clear).
my $StoredFiltersJSON = $JSONObject->Encode(
    Data => {
        Queue => [@QueueIDs],
    },
);
my $StoredRealKeysJSON = $JSONObject->Encode(
    Data => {
        QueueIDs => [@QueueIDs],
    },
);
$UserObject->SetPreferences(
    UserID => $UserID,
    Key    => 'UserDashboardTicketGenericColumnFilters' . $WidgetName,
    Value  => $StoredFiltersJSON,
);
$UserObject->SetPreferences(
    UserID => $UserID,
    Key    => 'UserDashboardTicketGenericColumnFiltersRealKeys' . $WidgetName,
    Value  => $StoredRealKeysJSON,
);

$DashboardObject = Kernel::Output::HTML::Dashboard::TicketGeneric->new(
    Config          => \%Config,
    Name            => $WidgetName,
    UserID          => $UserID,
    PageShown       => 25,
    Action          => 'AgentDashboard',
    AddFilters      => 1,
    ColumnFilter    => {},
    GetColumnFilter => {
        "Queue$WidgetName" => ['DeleteFilter'],
    },
    GetColumnFilterSelect => {
        Queue => ['DeleteFilter'],
    },
);

$CacheObject->CleanUp(
    Type => 'Dashboard',
);

$Content = $DashboardObject->Run(
    AJAX => 1,
);
$Self->True(
    $Content,
    'Dashboard widget content generated after DeleteFilter without ColumnFilter',
);

%Preferences = $UserObject->GetPreferences(
    UserID => $UserID,
);
$StoredFilters = $JSONObject->Decode(
    Data => $Preferences{ 'UserDashboardTicketGenericColumnFilters' . $WidgetName } // '{}',
);
$Self->False(
    exists $StoredFilters->{Queue},
    'DeleteFilter without ColumnFilter removes Queue preferences',
);

$StoredRealKeys = $JSONObject->Decode(
    Data => $Preferences{ 'UserDashboardTicketGenericColumnFiltersRealKeys' . $WidgetName } // '{}',
);
$Self->False(
    exists $StoredRealKeys->{QueueIDs},
    'DeleteFilter without ColumnFilter removes QueueIDs real-key preferences',
);

1;
