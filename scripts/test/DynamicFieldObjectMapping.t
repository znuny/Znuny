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

use Kernel::System::VariableCheck qw(:all);

my $DynamicFieldObject = $Kernel::OM->Get('Kernel::System::DynamicField');

# get helper object
$Kernel::OM->ObjectParamAdd(
    'Kernel::System::UnitTest::Helper' => {
        RestoreDatabase => 1,
    },
);
my $HelperObject = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');

# create some object IDs
my %ObjectIDByObjectName;
for my $Count ( 1 .. 5 ) {
    my $ObjectName = $HelperObject->GetRandomID();
    my $ObjectID   = $DynamicFieldObject->ObjectMappingCreate(
        ObjectName => $ObjectName,
        ObjectType => 'CustomerUser',
    );

    $Self->True(
        $ObjectID,
        "Creation of object mapping must succeed for object name $ObjectName.",
    );

    $ObjectIDByObjectName{$ObjectName} = $ObjectID;
}

# check that created mappings can be retrieved with ObjectMappingGet()
my $RetrievedObjectIDByObjectName = $DynamicFieldObject->ObjectMappingGet(
    ObjectName => [ keys %ObjectIDByObjectName ],
    ObjectType => 'CustomerUser',
);

$Self->IsDeeply(
    $RetrievedObjectIDByObjectName,
    \%ObjectIDByObjectName,
    'Retrieved object mappings must match expected ones.',
);

# add a mapping for a specific object name
my $ObjectName = $HelperObject->GetRandomID();
my $ObjectID   = $DynamicFieldObject->ObjectMappingCreate(
    ObjectName => $ObjectName,
    ObjectType => 'CustomerUser',
);

$Self->True(
    $ObjectID,
    "Creation of object mapping must succeed for object name $ObjectName.",
);

# try to fetch an object ID for a non-existing object name
$RetrievedObjectIDByObjectName = $DynamicFieldObject->ObjectMappingGet(
    ObjectName => $HelperObject->GetRandomID(),
    ObjectType => 'CustomerUser',
);

$Self->False(
    IsHashRefWithData($RetrievedObjectIDByObjectName) ? 1 : 0,
    'Trying to fetch non-existing object mapping must fail.',
);

# check that created mappings can be retrieved with ObjectMappingGet()
my %ObjectNameByObjectID          = reverse %ObjectIDByObjectName;
my $RetrievedObjectNameByObjectID = $DynamicFieldObject->ObjectMappingGet(
    ObjectID   => [ keys %ObjectNameByObjectID ],
    ObjectType => 'CustomerUser',
);

$Self->IsDeeply(
    $RetrievedObjectNameByObjectID,
    \%ObjectNameByObjectID,
    'Retrieved object mappings must match expected ones.',
);

# change object name
# use object name/ID from above
my $NewObjectName = $HelperObject->GetRandomID();
my $Success       = $DynamicFieldObject->ObjectMappingNameChange(
    OldObjectName => $ObjectName,
    NewObjectName => $NewObjectName,
    ObjectType    => 'CustomerUser',
);

$Self->True(
    $Success,
    'Change of object name must succeed.'
);

# fetch object mapping for new name, ID must be the same as before
$RetrievedObjectIDByObjectName = $DynamicFieldObject->ObjectMappingGet(
    ObjectName => $NewObjectName,
    ObjectType => 'CustomerUser',
);

$Self->True(
    defined $RetrievedObjectIDByObjectName->{$NewObjectName}
        && $RetrievedObjectIDByObjectName->{$NewObjectName} == $ObjectID,
    'Object ID must be the same after changing its name.'
);

# fetching object mapping for old name must fail
$RetrievedObjectIDByObjectName = $DynamicFieldObject->ObjectMappingGet(
    ObjectName => $ObjectName,
    ObjectType => 'CustomerUser',
);

$Self->True(
    !defined $RetrievedObjectIDByObjectName->{$NewObjectName},
    'Fetching object mapping for old object name must fail.'
);

# cleanup is done by RestoreDatabase

1;
