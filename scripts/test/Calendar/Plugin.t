# --
# Copyright (C) 2001-2021 OTRS AG, https://otrs.com/
# Copyright (C) 2021 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see https://www.gnu.org/licenses/gpl-3.0.txt.
# --

use strict;
use warnings;
use utf8;

use vars (qw($Self));

# get helper object
$Kernel::OM->ObjectParamAdd(
    'Kernel::System::UnitTest::Helper' => {
        RestoreDatabase => 1,
    },
);
my $HelperObject      = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');
my $ConfigObject      = $Kernel::OM->Get('Kernel::Config');
my $CalendarObject    = $Kernel::OM->Get('Kernel::System::Calendar');
my $AppointmentObject = $Kernel::OM->Get('Kernel::System::Calendar::Appointment');
my $PluginObject      = $Kernel::OM->Get('Kernel::System::Calendar::Plugin');
my $MainObject        = $Kernel::OM->Get('Kernel::System::Main');
my $GroupObject       = $Kernel::OM->Get('Kernel::System::Group');
my $UserObject        = $Kernel::OM->Get('Kernel::System::User');
my $TicketObject      = $Kernel::OM->Get('Kernel::System::Ticket');

# get registered plugin modules
my $PluginConfig = $ConfigObject->Get("AppointmentCalendar::Plugin");
my $PluginCount  = scalar keys %{$PluginConfig};

my $PluginList = $PluginObject->PluginList();

$Self->True(
    $PluginList,
    'Plugin list loaded',
);

$Self->Is(
    scalar keys %{$PluginList},
    $PluginCount,
    'Registered plugin count',
);

my $PluginKeys = $PluginObject->PluginKeys();

$Self->True(
    $PluginKeys,
    'Plugin keys loaded',
);

$Self->Is(
    scalar keys %{$PluginKeys},
    $PluginCount,
    'Registered plugin count',
);

my $PluginKeyTicket;

# check all registered plugin modules
PLUGIN:
for my $PluginKey ( sort keys %{$PluginConfig} ) {

    my $GenericModule = $PluginConfig->{$PluginKey}->{Module};
    next PLUGIN if !$GenericModule;

    if ( $GenericModule eq 'Kernel::System::Calendar::Plugin::Ticket' ) {
        $PluginKeyTicket = $PluginKey;
    }

    # check if module can be required
    $Self->True(
        $MainObject->Require($GenericModule),
        "Required '$GenericModule' plugin module",
    );

    my $PluginModule = $GenericModule->new( %{$Self} );

    # check if module has been loaded
    $Self->True(
        $PluginModule,
        "Plugin module loaded successfully",
    );

    # check class name
    $Self->True(
        $PluginModule->isa($GenericModule),
        'Plugin module has correct package name',
    );

    # check required methods
    METHODE:
    for my $MethodName (qw(LinkAdd LinkList Search)) {

        next METHODE if !$PluginModule->can($MethodName);

        $Self->True(
            $PluginModule->can($MethodName),
            "Plugin module implements $MethodName()",
        );
    }

    my $URL = $PluginConfig->{$PluginKey}->{URL} || '';
    if ($URL) {

        # check if URL contains ID placeholder
        $Self->True(
            scalar $URL =~ /%s/,
            'Plugin module URL contains ID placeholder',
        );
    }
}

# check ticket plugin if registered
if ($PluginKeyTicket) {

    # create test group
    my $GroupName = 'test-calendar-group-' . $HelperObject->GetRandomID();
    my $GroupID   = $GroupObject->GroupAdd(
        Name    => $GroupName,
        ValidID => 1,
        UserID  => 1,
    );

    $Self->True(
        $GroupID,
        "Test group $GroupID created",
    );

    # create test user
    my ( $UserLogin, $UserID ) = $HelperObject->TestUserCreate(
        Groups => [ 'users', $GroupName ],
    );

    $Self->True(
        $UserID,
        "Test user $UserID created",
    );

    my $RandomID = $HelperObject->GetRandomID();

    # create a test ticket
    my $TicketID = $TicketObject->TicketCreate(
        Title        => 'Test Ticket ' . $RandomID,
        Queue        => 'Raw',
        Lock         => 'unlock',
        Priority     => '3 normal',
        State        => 'open',
        CustomerNo   => '123465',
        CustomerUser => 'customer@example.com',
        OwnerID      => $UserID,
        UserID       => $UserID,
    );
    $Self->True(
        $TicketID,
        "TicketCreate() - $TicketID",
    );
    my $TicketNumber = $TicketObject->TicketNumberLookup(
        TicketID => $TicketID,
        UserID   => $UserID,
    );
    $Self->True(
        $TicketNumber,
        "TicketNumberLookup() - $TicketNumber",
    );

    # crete test calendar
    my %Calendar = $CalendarObject->CalendarCreate(
        CalendarName => 'Test Calendar ' . $RandomID,
        Color        => '#3A87AD',
        GroupID      => $GroupID,
        UserID       => $UserID,
    );

    $Self->True(
        $Calendar{CalendarID},
        "CalendarCreate() - $Calendar{CalendarID}",
    );

    # create test appointment
    my $AppointmentID = $AppointmentObject->AppointmentCreate(
        CalendarID => $Calendar{CalendarID},
        Title      => 'Test appointment ' . $RandomID,
        StartTime  => '2016-01-01 12:00:00',
        EndTime    => '2016-01-01 13:00:00',
        TimezoneID => 0,
        UserID     => $UserID,
    );

    $Self->True(
        $AppointmentID,
        "AppointmentCreate() - $AppointmentID",
    );

    # search the ticket via ticket number
    my $ResultList = $PluginObject->PluginFunction(
        PluginKey      => $PluginKeyTicket,
        PluginFunction => 'Search',
        PluginData     => {
            UserID => $UserID,
            Search => $TicketNumber,    # (required) Search string
        },
    );

    $Self->IsDeeply(
        $ResultList,
        {
            $TicketID => {
                Subject => "$TicketNumber Test Ticket $RandomID",
                Title   => "Test Ticket $RandomID",
            },
        },
        'PluginSearch() - Search results (by ticket number)'
    );

    # search the ticket via ticket id
    $ResultList = $PluginObject->PluginFunction(
        PluginKey      => $PluginKeyTicket,
        PluginFunction => 'Search',
        PluginData     => {
            UserID   => $UserID,
            ObjectID => $TicketID,
        },
    );

    $Self->IsDeeply(
        $ResultList,
        {
            $TicketID => {
                Subject => "$TicketNumber Test Ticket $RandomID",
                Title   => 'Test Ticket ' . $RandomID,
            },
        },
        'PluginSearch() - Search results (by ticket ID)'
    );

    # link appointment with the ticket
    my $Success = $PluginObject->PluginFunction(
        PluginKey      => $PluginKeyTicket,
        PluginFunction => 'LinkAdd',
        PluginData     => {
            TargetKey => $TicketID,         # TicketID, depends on TargetObject
            SourceKey => $AppointmentID,    # AppointmentID
            UserID    => $UserID,
        }
    );

    $Self->True(
        $Success,
        'PluginLinkAdd() - Link appointment to the ticket',
    );

    # verify link
    my $LinkList = $PluginObject->PluginFunction(
        PluginKey      => $PluginKeyTicket,
        PluginFunction => 'LinkList',
        PluginData     => {
            AppointmentID => $AppointmentID,
            UserID        => $UserID,
        },
    );

    $Self->True(
        $LinkList->{$TicketID},
        'PluginLinkList() - Verify link to the ticket'
    );

    $Self->Is(
        $LinkList->{$TicketID}->{LinkID},
        $TicketID,
        'TicketID',
    );

    # check URL
    $Self->True(
        $LinkList->{$TicketID}->{LinkURL} =~ /TicketID=$TicketID/,
        'Ticket URL contains ticket ID'
    );

    # link name
    $Self->Is(
        $LinkList->{$TicketID}->{LinkName},
        "$TicketNumber Test Ticket $RandomID",
        'Link name'
    );

    # delete links
    $Success = $PluginObject->PluginFunction(
        PluginKey      => $PluginKeyTicket,
        PluginFunction => 'LinkDelete',
        PluginData     => {
            AppointmentID => $AppointmentID,
            UserID        => $UserID,
        },
    );

    $Self->True(
        $Success,
        'PluginLinkDelete() - Links deleted'
    );

    # verify links have been deleted
    $LinkList = $PluginObject->PluginFunction(
        PluginKey      => $PluginKeyTicket,
        PluginFunction => 'LinkList',
        PluginData     => {
            AppointmentID => $AppointmentID,
            UserID        => $UserID,
        },
    );

    $Self->IsDeeply(
        $LinkList,
        {},
        'PluginLinkList() - Empty link list',
    );
}

my @PluginGroups = $PluginObject->PluginGroups();

$Self->IsDeeply(
    \@PluginGroups,
    [
        {
            'Title' => 'Ticket',
            'Prio'  => 1000,
            'Key'   => 'Ticket'
        },
        {
            'Title' => 'Link',
            'Prio'  => 8000,
            'Key'   => 'Link'
        },
        {
            'Key'   => 'Miscellaneous',
            'Title' => 'Miscellaneous',
            'Prio'  => 9001
        }
    ],
    'Plugin keys loaded',
);

# PluginGetParam
my @Tests = (
    {
        Name => 'Normal data structure via AgentAppointmentEdit',
        Data => {
            'Plugin_TicketCreate_PriorityID'                  => '3',
            'Plugin_TicketCreate_Offset'                      => '1',
            'Plugin_TicketCreate_LockID'                      => '2',
            'Plugin_TicketCreate_TicketPendingTimeOffsetUnit' => '86400',
            'Plugin_TicketCreate_QueueID[]'                   => '[4,1,28]',
            'Plugin_TicketCreate_OffsetPoint'                 => 'beforestart',
            'Plugin_TicketCreate_TypeID'                      => '105',
            'Plugin_TicketCreate_OffsetUnit'                  => '60',
            'Plugin_TicketCreate_SLAID'                       => '1',
            'Plugin_TicketCreate_ResponsibleUserID'           => '1',
            'Plugin_TicketCreate_ServiceID'                   => '1',
            'Plugin_TicketCreate_OwnerID'                     => '1',
            'Plugin_TicketCreate_StateID'                     => '1',
            'Plugin_TicketCreate_TimeType'                    => 'Never',
            'Plugin_TicketLink_LinkList[]'                    => '[438,414]',
        },
        Expected => {
            'TicketCreate' => {
                'PriorityID'                  => '3',
                'Offset'                      => '1',
                'LockID'                      => '2',
                'TicketPendingTimeOffsetUnit' => '86400',
                'QueueID'                     => [
                    4,
                    1,
                    28
                ],
                'OffsetPoint'       => 'beforestart',
                'TypeID'            => '105',
                'OffsetUnit'        => '60',
                'SLAID'             => '1',
                'ResponsibleUserID' => '1',
                'ServiceID'         => '1',
                'OwnerID'           => '1',
                'StateID'           => '1',
                'TimeType'          => 'Never'
            },
            'TicketLink' => {
                'LinkList' => [
                    438,
                    414
                ]
            }
        },
    },
    {
        Name => 'Data structure via UpdateAppointment (eventDrop|eventResize)',
        Data => {
            'Plugin[TicketCreate][Config][PriorityID]'                  => '3',
            'Plugin[TicketCreate][Config][Offset]'                      => '1',
            'Plugin[TicketCreate][Config][LockID]'                      => '2',
            'Plugin[TicketCreate][Config][TicketPendingTimeOffsetUnit]' => '86400',
            'Plugin[TicketCreate][Config][QueueID][]'                   => '[4,1,28]',
            'Plugin[TicketCreate][Config][OffsetPoint]'                 => 'beforestart',
            'Plugin[TicketCreate][Config][TypeID]'                      => '105',
            'Plugin[TicketCreate][Config][OffsetUnit]'                  => '60',
            'Plugin[TicketCreate][Config][SLAID]'                       => '1',
            'Plugin[TicketCreate][Config][ResponsibleUserID]'           => '1',
            'Plugin[TicketCreate][Config][ServiceID]'                   => '1',
            'Plugin[TicketCreate][Config][OwnerID]'                     => '1',
            'Plugin[TicketCreate][Config][StateID]'                     => '1',
            'Plugin[TicketCreate][Config][TimeType]'                    => 'Never',
            'Plugin[TicketLink][Config][LinkList][]'                    => '[438,414]',
        },
        Expected => {
            'TicketCreate' => {
                'PriorityID'                  => '3',
                'Offset'                      => '1',
                'LockID'                      => '2',
                'TicketPendingTimeOffsetUnit' => '86400',
                'QueueID'                     => [
                    4,
                    1,
                    28
                ],
                'OffsetPoint'       => 'beforestart',
                'TypeID'            => '105',
                'OffsetUnit'        => '60',
                'SLAID'             => '1',
                'ResponsibleUserID' => '1',
                'ServiceID'         => '1',
                'OwnerID'           => '1',
                'StateID'           => '1',
                'TimeType'          => 'Never'
            },
            'TicketLink' => {
                'LinkList' => [
                    438,
                    414
                ]
            }
        },
    },
);

for my $Test (@Tests) {

    $Kernel::OM->ObjectsDiscard(
        Objects => ['Kernel::System::Web::Request'],
    );

    my $ParamObject = $Kernel::OM->Get('Kernel::System::Web::Request');

    for my $Attribute ( sort keys %{ $Test->{Data} } ) {

        $ParamObject->{Query}->param(
            -name  => $Attribute,
            -value => $Test->{Data}->{$Attribute},
        );
    }

    my %PluginGetParam = $PluginObject->PluginGetParam(
        %{ $Test->{Data} },
    );

    $Self->IsDeeply(
        \%PluginGetParam,
        $Test->{Expected},
        'PluginGetParam - ' . $Test->{Name},
    );

}

1;
