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

my $TicketObject  = $Kernel::OM->Get('Kernel::System::Ticket');
my $ArticleObject = $Kernel::OM->Get('Kernel::System::Ticket::Article');
my $CacheObject   = $Kernel::OM->Get('Kernel::System::Cache');

$Kernel::OM->ObjectParamAdd(
    'Kernel::System::UnitTest::Helper' => {
        RestoreDatabase  => 1,
        UseTmpArticleDir => 1,
    },
);

# ArticleColorInit

my $Success = $ArticleObject->ArticleColorInit();
$Self->True(
    $Success,
    'ArticleColorInit()',
);

# ArticleColorList

$CacheObject->CleanUp();

my @ArticleColorList = $ArticleObject->ArticleColorList();

# Delete ChangeTime, ChangeBy, CreateTime, CreateBy
for my $ArticleColor (@ArticleColorList) {
    delete $ArticleColor->{ChangeTime};
    delete $ArticleColor->{ChangeBy};
    delete $ArticleColor->{CreateTime};
    delete $ArticleColor->{CreateBy};
    delete $ArticleColor->{ID};
}

$Self->IsDeeply(
    \@ArticleColorList,
    [
        {
            'Color'                => '#FFCCCCFF',
            'CommunicationChannel' => 'Chat',
            'IsVisibleForCustomer' => 'NotVisibleForCustomer',
            'Name'                 => 'agent::Chat::NotVisibleForCustomer',
            'SenderType'           => 'agent'
        },
        {
            'Color'                => '#D1E8D1FF',
            'CommunicationChannel' => 'Chat',
            'IsVisibleForCustomer' => 'VisibleForCustomer',
            'Name'                 => 'agent::Chat::VisibleForCustomer',
            'SenderType'           => 'agent'
        },
        {
            'Color'                => '#FFCCCCFF',
            'CommunicationChannel' => 'Email',
            'IsVisibleForCustomer' => 'NotVisibleForCustomer',
            'Name'                 => 'agent::Email::NotVisibleForCustomer',
            'SenderType'           => 'agent'
        },
        {
            'Color'                => '#D1E8D1FF',
            'CommunicationChannel' => 'Email',
            'IsVisibleForCustomer' => 'VisibleForCustomer',
            'Name'                 => 'agent::Email::VisibleForCustomer',
            'SenderType'           => 'agent'
        },
        {
            'Color'                => '#FFCCCCFF',
            'CommunicationChannel' => 'Internal',
            'IsVisibleForCustomer' => 'NotVisibleForCustomer',
            'Name'                 => 'agent::Internal::NotVisibleForCustomer',
            'SenderType'           => 'agent'
        },
        {
            'Color'                => '#CCCCCCFF',
            'CommunicationChannel' => 'Internal',
            'IsVisibleForCustomer' => 'VisibleForCustomer',
            'Name'                 => 'agent::Internal::VisibleForCustomer',
            'SenderType'           => 'agent'
        },
        {
            'Color'                => '#FFCCCCFF',
            'CommunicationChannel' => 'Phone',
            'IsVisibleForCustomer' => 'NotVisibleForCustomer',
            'Name'                 => 'agent::Phone::NotVisibleForCustomer',
            'SenderType'           => 'agent'
        },
        {
            'Color'                => '#D1E8D1FF',
            'CommunicationChannel' => 'Phone',
            'IsVisibleForCustomer' => 'VisibleForCustomer',
            'Name'                 => 'agent::Phone::VisibleForCustomer',
            'SenderType'           => 'agent'
        },
        {
            'Color'                => '#FFCCCCFF',
            'CommunicationChannel' => 'Web',
            'IsVisibleForCustomer' => 'NotVisibleForCustomer',
            'Name'                 => 'agent::Web::NotVisibleForCustomer',
            'SenderType'           => 'agent'
        },
        {
            'Color'                => '#D1E8D1FF',
            'CommunicationChannel' => 'Web',
            'IsVisibleForCustomer' => 'VisibleForCustomer',
            'Name'                 => 'agent::Web::VisibleForCustomer',
            'SenderType'           => 'agent'
        },
        {
            'Color'                => '#FFCCCCFF',
            'CommunicationChannel' => 'Chat',
            'IsVisibleForCustomer' => 'NotVisibleForCustomer',
            'Name'                 => 'system::Chat::NotVisibleForCustomer',
            'SenderType'           => 'system'
        },
        {
            'Color'                => '#FFF7BEFF',
            'CommunicationChannel' => 'Chat',
            'IsVisibleForCustomer' => 'VisibleForCustomer',
            'Name'                 => 'system::Chat::VisibleForCustomer',
            'SenderType'           => 'system'
        },
        {
            'Color'                => '#FFCCCCFF',
            'CommunicationChannel' => 'Email',
            'IsVisibleForCustomer' => 'NotVisibleForCustomer',
            'Name'                 => 'system::Email::NotVisibleForCustomer',
            'SenderType'           => 'system'
        },
        {
            'Color'                => '#FFF7BEFF',
            'CommunicationChannel' => 'Email',
            'IsVisibleForCustomer' => 'VisibleForCustomer',
            'Name'                 => 'system::Email::VisibleForCustomer',
            'SenderType'           => 'system'
        },
        {
            'Color'                => '#FFCCCCFF',
            'CommunicationChannel' => 'Internal',
            'IsVisibleForCustomer' => 'NotVisibleForCustomer',
            'Name'                 => 'system::Internal::NotVisibleForCustomer',
            'SenderType'           => 'system'
        },
        {
            'Color'                => '#FFF7BEFF',
            'CommunicationChannel' => 'Internal',
            'IsVisibleForCustomer' => 'VisibleForCustomer',
            'Name'                 => 'system::Internal::VisibleForCustomer',
            'SenderType'           => 'system'
        },
        {
            'Color'                => '#FFCCCCFF',
            'CommunicationChannel' => 'Phone',
            'IsVisibleForCustomer' => 'NotVisibleForCustomer',
            'Name'                 => 'system::Phone::NotVisibleForCustomer',
            'SenderType'           => 'system'
        },
        {
            'Color'                => '#FFF7BEFF',
            'CommunicationChannel' => 'Phone',
            'IsVisibleForCustomer' => 'VisibleForCustomer',
            'Name'                 => 'system::Phone::VisibleForCustomer',
            'SenderType'           => 'system'
        },
        {
            'Color'                => '#FFCCCCFF',
            'CommunicationChannel' => 'Web',
            'IsVisibleForCustomer' => 'NotVisibleForCustomer',
            'Name'                 => 'system::Web::NotVisibleForCustomer',
            'SenderType'           => 'system'
        },
        {
            'Color'                => '#FFF7BEFF',
            'CommunicationChannel' => 'Web',
            'IsVisibleForCustomer' => 'VisibleForCustomer',
            'Name'                 => 'system::Web::VisibleForCustomer',
            'SenderType'           => 'system'
        },
        {
            'Color'                => '#FFCCCCFF',
            'CommunicationChannel' => 'Chat',
            'IsVisibleForCustomer' => 'NotVisibleForCustomer',
            'Name'                 => 'customer::Chat::NotVisibleForCustomer',
            'SenderType'           => 'customer'
        },
        {
            'Color'                => '#D4DEFCFF',
            'CommunicationChannel' => 'Chat',
            'IsVisibleForCustomer' => 'VisibleForCustomer',
            'Name'                 => 'customer::Chat::VisibleForCustomer',
            'SenderType'           => 'customer'
        },
        {
            'Color'                => '#FFCCCCFF',
            'CommunicationChannel' => 'Email',
            'IsVisibleForCustomer' => 'NotVisibleForCustomer',
            'Name'                 => 'customer::Email::NotVisibleForCustomer',
            'SenderType'           => 'customer'
        },
        {
            'Color'                => '#D4DEFCFF',
            'CommunicationChannel' => 'Email',
            'IsVisibleForCustomer' => 'VisibleForCustomer',
            'Name'                 => 'customer::Email::VisibleForCustomer',
            'SenderType'           => 'customer'
        },
        {
            'Color'                => '#FFCCCCFF',
            'CommunicationChannel' => 'Internal',
            'IsVisibleForCustomer' => 'NotVisibleForCustomer',
            'Name'                 => 'customer::Internal::NotVisibleForCustomer',
            'SenderType'           => 'customer'
        },
        {
            'Color'                => '#D4DEFCFF',
            'CommunicationChannel' => 'Internal',
            'IsVisibleForCustomer' => 'VisibleForCustomer',
            'Name'                 => 'customer::Internal::VisibleForCustomer',
            'SenderType'           => 'customer'
        },
        {
            'Color'                => '#FFCCCCFF',
            'CommunicationChannel' => 'Phone',
            'IsVisibleForCustomer' => 'NotVisibleForCustomer',
            'Name'                 => 'customer::Phone::NotVisibleForCustomer',
            'SenderType'           => 'customer'
        },
        {
            'Color'                => '#D4DEFCFF',
            'CommunicationChannel' => 'Phone',
            'IsVisibleForCustomer' => 'VisibleForCustomer',
            'Name'                 => 'customer::Phone::VisibleForCustomer',
            'SenderType'           => 'customer'
        },
        {
            'Color'                => '#FFCCCCFF',
            'CommunicationChannel' => 'Web',
            'IsVisibleForCustomer' => 'NotVisibleForCustomer',
            'Name'                 => 'customer::Web::NotVisibleForCustomer',
            'SenderType'           => 'customer'
        },
        {
            'Color'                => '#D4DEFCFF',
            'CommunicationChannel' => 'Web',
            'IsVisibleForCustomer' => 'VisibleForCustomer',
            'Name'                 => 'customer::Web::VisibleForCustomer',
            'SenderType'           => 'customer'
        }
    ],
    "ArticleSenderTypeList()",
);

# ArticleColorSet

$Success = $ArticleObject->ArticleColorSet(
    Name   => 'customer::Phone::VisibleForCustomer',
    Color  => '#FF8A25',
    UserID => 1,
);

# ArticleColorGet

my %ArticleColor = $ArticleObject->ArticleColorGet(
    Name => 'customer::Phone::VisibleForCustomer',
);

$Self->Is(
    $ArticleColor{Color},
    '#FF8A25',
    'ArticleColorGet()',
);

# cleanup is done by RestoreDatabase.

1;
