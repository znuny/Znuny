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
        RestoreDatabase  => 1,
        UseTmpArticleDir => 1,
    },
);

my $HelperObject            = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');
my $TicketObject            = $Kernel::OM->Get('Kernel::System::Ticket');
my $ArticleObject           = $Kernel::OM->Get('Kernel::System::Ticket::Article');
my $ArticleBackendObject    = $ArticleObject->BackendForChannel( ChannelName => 'Internal' );
my $DynamicFieldObject      = $Kernel::OM->Get('Kernel::System::DynamicField');
my $BackendObject           = $Kernel::OM->Get('Kernel::System::DynamicField::Backend');
my $DynamicFieldValueObject = $Kernel::OM->Get('Kernel::System::DynamicFieldValue');

my $RandomID  = $HelperObject->GetRandomID();
my $FieldName = "ArticleCallType$RandomID";

my $DynamicFieldID = $DynamicFieldObject->DynamicFieldAdd(
    Name       => $FieldName,
    Label      => 'Call Type',
    FieldOrder => 9991,
    FieldType  => 'Dropdown',
    ObjectType => 'Article',
    Config     => {
        DefaultValue   => '',
        PossibleValues => {
            Sales   => 'Sales',
            Support => 'Support',
        },
        TranslatableValues => 0,
    },
    ValidID => 1,
    UserID  => 1,
    Reorder => 0,
);
$Self->True(
    $DynamicFieldID,
    'DynamicFieldAdd() Article Dropdown'
);

my $DynamicFieldConfig = $DynamicFieldObject->DynamicFieldGet(
    ID => $DynamicFieldID,
);

my $TicketID = $TicketObject->TicketCreate(
    Title        => "ArticleFilterDF $RandomID",
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

my $SalesArticleID = $ArticleBackendObject->ArticleCreate(
    TicketID             => $TicketID,
    SenderType           => 'agent',
    IsVisibleForCustomer => 0,
    From                 => 'agent@example.com',
    To                   => 'customer@example.com',
    Subject              => "Sales article $RandomID",
    Body                 => 'Sales body',
    ContentType          => 'text/plain; charset=utf-8',
    HistoryType          => 'AddNote',
    HistoryComment       => 'UnitTest',
    UserID               => 1,
    NoAgentNotify        => 1,
);
$Self->True(
    $SalesArticleID,
    'ArticleCreate() Sales'
);

my $SupportArticleID = $ArticleBackendObject->ArticleCreate(
    TicketID             => $TicketID,
    SenderType           => 'agent',
    IsVisibleForCustomer => 0,
    From                 => 'agent@example.com',
    To                   => 'customer@example.com',
    Subject              => "Support article $RandomID",
    Body                 => 'Support body',
    ContentType          => 'text/plain; charset=utf-8',
    HistoryType          => 'AddNote',
    HistoryComment       => 'UnitTest',
    UserID               => 1,
    NoAgentNotify        => 1,
);
$Self->True(
    $SupportArticleID,
    'ArticleCreate() Support'
);

my $UnsetArticleID = $ArticleBackendObject->ArticleCreate(
    TicketID             => $TicketID,
    SenderType           => 'agent',
    IsVisibleForCustomer => 0,
    From                 => 'agent@example.com',
    To                   => 'customer@example.com',
    Subject              => "Unset article $RandomID",
    Body                 => 'Unset body',
    ContentType          => 'text/plain; charset=utf-8',
    HistoryType          => 'AddNote',
    HistoryComment       => 'UnitTest',
    UserID               => 1,
    NoAgentNotify        => 1,
);
$Self->True(
    $UnsetArticleID,
    'ArticleCreate() Unset'
);

$Self->True(
    $BackendObject->ValueSet(
        DynamicFieldConfig => $DynamicFieldConfig,
        ObjectID           => $SalesArticleID,
        Value              => 'Sales',
        UserID             => 1,
    ),
    'ValueSet() Sales'
);
$Self->True(
    $BackendObject->ValueSet(
        DynamicFieldConfig => $DynamicFieldConfig,
        ObjectID           => $SupportArticleID,
        Value              => 'Support',
        UserID             => 1,
    ),
    'ValueSet() Support'
);

my @ArticleBoxAll = $ArticleObject->ArticleList(
    TicketID => $TicketID,
);
$Self->Is(
    scalar @ArticleBoxAll,
    3,
    'ArticleList() returns all articles before DF filter'
);

my $SearchParam = $BackendObject->SearchFieldParameterBuild(
    DynamicFieldConfig => $DynamicFieldConfig,
    Profile            => {
        'Search_DynamicField_' . $FieldName => ['Support'],
    },
);
$Self->IsDeeply(
    $SearchParam->{Parameter},
    {
        Equals => ['Support'],
    },
    'SearchFieldParameterBuild() reads the article filter profile',
);

my $SearchSQL = $BackendObject->SearchSQLGet(
    DynamicFieldConfig => $DynamicFieldConfig,
    TableAlias         => 'dynamic_field_value',
    SearchTerm         => 'Support',
    Operator           => 'Equals',
);
$Self->True(
    $SearchSQL,
    'SearchSQLGet() for Support'
);

my $Values = $DynamicFieldValueObject->ValueSearch(
    FieldID   => $DynamicFieldConfig->{ID},
    Search    => 'Support',
    SearchSQL => $SearchSQL,
);
$Self->True(
    IsArrayRefWithData($Values),
    'ValueSearch() returns matches for Support'
);

my %MatchingArticleID = map  { $_->{ObjectID} => 1 } @{$Values};
my @Filtered          = grep { $MatchingArticleID{ $_->{ArticleID} } } @ArticleBoxAll;

$Self->IsDeeply(
    [ map { $_->{ArticleID} } @Filtered ],
    [$SupportArticleID],
    'DF Equals filter keeps only Support article for ticket',
);

# Create other ticket with same DF value.
my $OtherTicketID = $TicketObject->TicketCreate(
    Title        => "ArticleFilterDF other $RandomID",
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
    'TicketCreate() other ticket'
);

my $OtherSupportArticleID = $ArticleBackendObject->ArticleCreate(
    TicketID             => $OtherTicketID,
    SenderType           => 'agent',
    IsVisibleForCustomer => 0,
    From                 => 'agent@example.com',
    To                   => 'customer@example.com',
    Subject              => "Other Support article $RandomID",
    Body                 => 'Other Support body',
    ContentType          => 'text/plain; charset=utf-8',
    HistoryType          => 'AddNote',
    HistoryComment       => 'UnitTest',
    UserID               => 1,
    NoAgentNotify        => 1,
);
$Self->True(
    $OtherSupportArticleID,
    'ArticleCreate() other ticket Support'
);

$Self->True(
    $BackendObject->ValueSet(
        DynamicFieldConfig => $DynamicFieldConfig,
        ObjectID           => $OtherSupportArticleID,
        Value              => 'Support',
        UserID             => 1,
    ),
    'ValueSet() other ticket Support'
);

# Ticket-scoped ValueSearch.
my @TicketArticleIDs = map { $_->{ArticleID} } @ArticleBoxAll;

my $ScopedValues = $DynamicFieldValueObject->ValueSearch(
    FieldID   => $DynamicFieldConfig->{ID},
    Search    => 'Support',
    SearchSQL => $SearchSQL,
    ObjectIDs => \@TicketArticleIDs,
);
$Self->True(
    IsArrayRefWithData($ScopedValues),
    'ValueSearch() with ObjectIDs returns matches for Support',
);

my %ScopedMatchingArticleID = map { $_->{ObjectID} => 1 } @{ $ScopedValues // [] };

$Self->IsDeeply(
    [ sort { $a <=> $b } keys %ScopedMatchingArticleID ],
    [$SupportArticleID],
    'Ticket-scoped DF lookup keeps only current ticket Support article (no cross-ticket leak)',
);

$Self->False(
    $ScopedMatchingArticleID{$OtherSupportArticleID} ? 1 : 0,
    'Ticket-scoped DF lookup does not return other ticket Support article',
);

# Unscoped search across tickets.
my $UnscopedValues = $DynamicFieldValueObject->ValueSearch(
    FieldID   => $DynamicFieldConfig->{ID},
    Search    => 'Support',
    SearchSQL => $SearchSQL,
);
my %UnscopedMatchingArticleID = map { $_->{ObjectID} => 1 } @{ $UnscopedValues // [] };
$Self->True(
    $UnscopedMatchingArticleID{$SupportArticleID}
        && $UnscopedMatchingArticleID{$OtherSupportArticleID} ? 1 : 0,
    'Unscoped ValueSearch() still returns matches across tickets',
);

my $CheckboxName = "ArticleCallback$RandomID";
my $CheckboxID   = $DynamicFieldObject->DynamicFieldAdd(
    Name       => $CheckboxName,
    Label      => 'Callback',
    FieldOrder => 9992,
    FieldType  => 'Checkbox',
    ObjectType => 'Article',
    Config     => {
        DefaultValue => 0,
    },
    ValidID => 1,
    UserID  => 1,
    Reorder => 0,
);
$Self->True(
    $CheckboxID,
    'DynamicFieldAdd() Article Checkbox'
);

my $CheckboxConfig = $DynamicFieldObject->DynamicFieldGet(
    ID => $CheckboxID,
);

my $CheckboxSearchParam = $BackendObject->SearchFieldParameterBuild(
    DynamicFieldConfig => $CheckboxConfig,
    Profile            => {
        'Search_DynamicField_' . $CheckboxName => ['-1'],
    },
);
$Self->IsDeeply(
    $CheckboxSearchParam->{Parameter},
    {
        Equals => ['0'],
    },
    'Checkbox Unchecked is stored as 0 for search',
);

my $CheckboxProfileValue = $CheckboxSearchParam->{Parameter}->{Equals};
if ( ref $CheckboxProfileValue eq 'ARRAY' ) {
    VALUE:
    for my $Value ( @{$CheckboxProfileValue} ) {
        next VALUE if !defined $Value;
        next VALUE if "$Value" ne '0';
        $Value = -1;
    }
}
elsif ( defined $CheckboxProfileValue && "$CheckboxProfileValue" eq '0' ) {
    $CheckboxProfileValue = -1;
}

$Self->IsDeeply(
    $CheckboxProfileValue,
    [-1],
    'Stored Checkbox 0 is mapped back to -1 for the filter dialog',
);

1;
