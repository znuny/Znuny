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

use MIME::Base64;

use Kernel::System::VariableCheck qw(:all);

$Kernel::OM->ObjectParamAdd(
    'Kernel::System::UnitTest::Helper' => {
        RestoreDatabase => 1,
    },
);

my $HelperObject = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');
my $UtilObject   = $Kernel::OM->Get('Kernel::System::Util');
my $TicketObject = $Kernel::OM->Get('Kernel::System::Ticket');

my $UserID = 1;

#
# IsITSMInstalled()
#

my $IsITSMInstalled = $UtilObject->IsITSMInstalled();

$Self->False(
    scalar $IsITSMInstalled,
    'IsITSMInstalled() must report ITSM as being not installed.',
);

$HelperObject->ConfigSettingChange(
    Valid => 1,
    Key   => 'Frontend::Module###AdminITSMCIPAllocate',
    Value => {
        'Group' => [
            'admin'
        ],
        'GroupRo'     => [],
        'Description' => 'Manage priority matrix.',
        'Title'       => 'Criticality ↔ Impact ↔ Priority',
        'NavBarName'  => 'Admin',
    },
);

$Kernel::OM->ObjectsDiscard(
    Objects => ['Kernel::System::Util'],
);

$UtilObject      = $Kernel::OM->Get('Kernel::System::Util');
$IsITSMInstalled = $UtilObject->IsITSMInstalled();

$Self->True(
    scalar $IsITSMInstalled,
    'IsITSMInstalled() must report ITSM as being installed.',
);

#
# IsFrontendContext()
#

my $IsFrontendContext = $UtilObject->IsFrontendContext();

$Self->False(
    scalar $IsFrontendContext,
    'IsFrontendContext() must report no frontend context.',
);

# Fake frontend context.
my $LayoutObject = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
$LayoutObject->{Action} = 'AgentTicketZoom';

$IsFrontendContext = $UtilObject->IsFrontendContext();

$Self->True(
    scalar $IsFrontendContext,
    'IsFrontendContext() must report frontend context.',
);

#
# Prepare a ticket for the following tests.
#

my $TicketID = $HelperObject->TicketCreate(
    Queue => 'Postmaster',
);

my $ArticleID = $HelperObject->ArticleCreate(
    TicketID => $TicketID,
);

my %TicketDeepGet = $TicketObject->TicketDeepGet(
    TicketID  => $TicketID,
    ArticleID => $ArticleID,
    UserID    => $UserID,
);

#
# Base64DeepEncode()
#

my $ResponsibleDataUserFirstnameBase64 = encode_base64(
    $TicketDeepGet{ResponsibleData}->{UserFirstname} // ''
);

my @ArticleBodiesBase64;
for my $Article ( @{ $TicketDeepGet{Articles} } ) {
    push @ArticleBodiesBase64, encode_base64( $Article->{Body} // '' );
}

my $TypeBase64 = encode_base64( $TicketDeepGet{Type} // '' );

$UtilObject->Base64DeepEncode(
    Data     => \%TicketDeepGet,
    HashKeys => [
        'ResponsibleData->UserFirstname',
        'Articles->Body',
        'Type',
    ],
);

$Self->Is(
    $TicketDeepGet{ResponsibleData}->{UserFirstname} // '',
    $ResponsibleDataUserFirstnameBase64,
    'Base64DeepEncode(): %TicketDeepGet must have expected base-64 encoded string in {ResponsibleData}->{UserFirstname}.',
);

my $ArticleIndex = 0;
for my $ArticleBodyBase64 (@ArticleBodiesBase64) {
    $Self->Is(
        $TicketDeepGet{Articles}->[$ArticleIndex]->{Body} // '',
        $ArticleBodyBase64,
        "Base64DeepEncode(): %TicketDeepGet must have expected base-64 encoded string in {Articles}->[$ArticleIndex]->{Body}.",
    );

    $ArticleIndex++;
}

$Self->Is(
    $TicketDeepGet{Type} // '',
    $TypeBase64,
    'Base64DeepEncode(): %TicketDeepGet must have expected base-64 encoded string in {Type}.',
);

# Test that base-64 encoded fields are the only difference and that remaining unchanged data is
# present. Test by reverting base-64 encoded values in %TicketDeepGet to unencoded values.
my %TicketDeepGetWithoutBase64EncodedData = $TicketObject->TicketDeepGet(
    TicketID  => $TicketID,
    ArticleID => $ArticleID,
    UserID    => $UserID,
);

$TicketDeepGet{ResponsibleData}->{UserFirstname}
    = $TicketDeepGetWithoutBase64EncodedData{ResponsibleData}->{UserFirstname};

$ArticleIndex = 0;
for my $Article ( @{ $TicketDeepGetWithoutBase64EncodedData{Articles} } ) {
    $TicketDeepGet{Articles}->[$ArticleIndex]->{Body} = $Article->{Body};

    $ArticleIndex++;
}

$TicketDeepGet{Type} = $TicketDeepGetWithoutBase64EncodedData{Type};

$Self->IsDeeply(
    \%TicketDeepGet,
    \%TicketDeepGetWithoutBase64EncodedData,
    'Base-64 encoded fields must be the only changes in %TicketDeepGet.',
);

#
# DataStructureRemoveElements()
#

%TicketDeepGet = $TicketObject->TicketDeepGet(
    TicketID  => $TicketID,
    ArticleID => $ArticleID,
    UserID    => $UserID,
);
my %TicketDeepGetWithElementsRemoved = $TicketObject->TicketDeepGet(
    TicketID  => $TicketID,
    ArticleID => $ArticleID,
    UserID    => $UserID,
);

$UtilObject->DataStructureRemoveElements(
    Data     => \%TicketDeepGetWithElementsRemoved,
    HashKeys => [
        'ResponsibleData->UserFirstname',
        'Articles->Body',
        'Type',
    ],
);

$Self->False(
    exists $TicketDeepGetWithElementsRemoved{ResponsibleData}->{UserFirstname},
    'DataStructureRemoveElements(): First name of responsible must not be present anymore.',
);

for my $Article ( @{ $TicketDeepGetWithElementsRemoved{Articles} } ) {
    $Self->False(
        exists $Article->{Body},
        'DataStructureRemoveElements(): Body of articles must not be present anymore.',
    );
}

$Self->False(
    exists $TicketDeepGetWithElementsRemoved{Type},
    'DataStructureRemoveElements(): Type of ticket must not be present anymore.',
);

# Test that the remove fields are the only difference and that remaining unchanged data is
# present. Test by removing fields from original %TicketDeepGet.
delete $TicketDeepGet{ResponsibleData}->{UserFirstname};

for my $Article ( @{ $TicketDeepGet{Articles} } ) {
    delete $Article->{Body};
}

delete $TicketDeepGet{Type};

$Self->IsDeeply(
    \%TicketDeepGet,
    \%TicketDeepGetWithElementsRemoved,
    'Removed fields must be the only changes in %TicketDeepGetWithElementsRemoved.',
);

# Now remove complete articles array.
$UtilObject->DataStructureRemoveElements(
    Data     => \%TicketDeepGetWithElementsRemoved,
    HashKeys => [
        'Articles',
    ],
);

$Self->False(
    exists $TicketDeepGetWithElementsRemoved{Articles},
    'DataStructureRemoveElements(): Articles must not be present anymore.',
);

delete $TicketDeepGet{Articles};

$Self->IsDeeply(
    \%TicketDeepGet,
    \%TicketDeepGetWithElementsRemoved,
    'Removed fields must be the only changes in %TicketDeepGetWithElementsRemoved.',
);

1;
