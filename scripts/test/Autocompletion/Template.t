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

my $HelperObject                 = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');
my $ConfigObject                 = $Kernel::OM->Get('Kernel::Config');
my $QueueObject                  = $Kernel::OM->Get('Kernel::System::Queue');
my $StandardTemplateObject       = $Kernel::OM->Get('Kernel::System::StandardTemplate');
my $ValidObject                  = $Kernel::OM->Get('Kernel::System::Valid');
my $AutocompletionTemplateObject = $Kernel::OM->Get('Kernel::System::Autocompletion::Template');

my $UserID = 1;

my @ValidIDs = $ValidObject->ValidIDsGet();
my $ValidID  = shift @ValidIDs;

# Prepare standard templates
my $StandardTemplate1ID = $StandardTemplateObject->StandardTemplateAdd(
    Name         => 'Unit test standard template 1',
    Template     => 'Hi there. This is template 1.',
    Comment      => 'Comment for template 1.',
    ContentType  => 'text/plain; charset=utf-8',
    TemplateType => 'Snippet',
    ValidID      => $ValidID,
    UserID       => $UserID,
);

my $StandardTemplate2ID = $StandardTemplateObject->StandardTemplateAdd(
    Name         => 'Unit test standard template 2',
    Template     => 'And tis is template 2.',
    Comment      => 'Comment for template 2.',
    ContentType  => 'text/plain; charset=utf-8',
    TemplateType => 'Snippet',
    ValidID      => $ValidID,
    UserID       => $UserID,
);

# Assign templates to queues.
my %QueueIDByName = reverse $QueueObject->QueueList();

$QueueObject->QueueStandardTemplateMemberAdd(
    QueueID            => $QueueIDByName{'Postmaster'},
    StandardTemplateID => $StandardTemplate1ID,
    Active             => 1,
    UserID             => $UserID,
);

$QueueObject->QueueStandardTemplateMemberAdd(
    QueueID            => $QueueIDByName{'Misc'},
    StandardTemplateID => $StandardTemplate2ID,
    Active             => 1,
    UserID             => $UserID,
);

# Prepare ticket
my $TicketID = $HelperObject->TicketCreate(
    QueueID => $QueueIDByName{'Postmaster'},
);

#
# Invalid ticket ID
#
my $AutocompletionData = $AutocompletionTemplateObject->GetData(
    SearchString     => 'template 1',
    UserID           => $UserID,
    AdditionalParams => {
        TicketID => 999999999,
    },
);

my $ExpectedAutocompletionData = undef;

$Self->IsDeeply(
    $AutocompletionData,
    $ExpectedAutocompletionData,
    'GetData() returned expected autocompletion data.',
);

#
# Valid ticket ID, should lead to template 1.
#
$AutocompletionData = $AutocompletionTemplateObject->GetData(
    SearchString     => 'template 1',
    UserID           => $UserID,
    AdditionalParams => {
        TicketID => $TicketID,
    },
);

$ExpectedAutocompletionData = [
    {
        'selection_list_title' => 'Unit test standard template 1 - Comment for template 1.',
        'inserted_value'       => 'Hi there. This is template 1.',
        'id'                   => $StandardTemplate1ID,
    },
];

$Self->IsDeeply(
    $AutocompletionData,
    $ExpectedAutocompletionData,
    'GetData() returned expected autocompletion data.',
);

#
# Queue without assigned template
#
$AutocompletionData = $AutocompletionTemplateObject->GetData(
    SearchString     => 'template 1',
    UserID           => $UserID,
    AdditionalParams => {
        QueueID => $QueueIDByName{'Misc'},
    },
);

$ExpectedAutocompletionData = [];

$Self->IsDeeply(
    $AutocompletionData,
    $ExpectedAutocompletionData,
    'GetData() returned expected autocompletion data.',
);

#
# Queue with assigned template
#
$AutocompletionData = $AutocompletionTemplateObject->GetData(
    SearchString     => 'template 2',
    UserID           => $UserID,
    AdditionalParams => {
        QueueID => $QueueIDByName{'Misc'},
    },
);

$ExpectedAutocompletionData = [
    {
        'selection_list_title' => 'Unit test standard template 2 - Comment for template 2.',
        'inserted_value'       => 'And tis is template 2.',
        'id'                   => $StandardTemplate2ID,
    },
];

$Self->IsDeeply(
    $AutocompletionData,
    $ExpectedAutocompletionData,
    'GetData() returned expected autocompletion data.',
);

#
# Without ticket ID or queue ID parameter
#
$AutocompletionData = $AutocompletionTemplateObject->GetData(
    SearchString => 'template 1',
    UserID       => $UserID,
);

$ExpectedAutocompletionData = undef;

$Self->IsDeeply(
    $AutocompletionData,
    $ExpectedAutocompletionData,
    'GetData() returned expected autocompletion data.',
);

1;
