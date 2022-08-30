# --
# Copyright (C) 2001-2021 OTRS AG, https://otrs.com/
# Copyright (C) 2021-2022 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see https://www.gnu.org/licenses/gpl-3.0.txt.
# --

use strict;
use warnings;
use utf8;

use vars (qw($Self));

use Kernel::GenericInterface::Debugger;
use Kernel::GenericInterface::Mapping;

my $DebuggerObject = Kernel::GenericInterface::Debugger->new(
    DebuggerConfig => {
        DebugThreshold => 'debug',
        TestMode       => 1,
    },
    WebserviceID      => 1,            # hard coded because it is not used
    CommunicationType => 'Provider',
);

# create object with false options
my $MappingObject;

$MappingObject = Kernel::GenericInterface::Mapping->new();
$Self->IsNot(
    ref $MappingObject,
    'Kernel::GenericInterface::Mapping',
    'Mapping::new() constructor failure - no arguments',
);

$MappingObject = Kernel::GenericInterface::Mapping->new(
    DebuggerObject => $DebuggerObject,
    MappingConfig  => {},
);
$Self->IsNot(
    ref $MappingObject,
    'Kernel::GenericInterface::Mapping',
    'Mapping::new() constructor failure - no MappingType',
);

$MappingObject = Kernel::GenericInterface::Mapping->new(
    DebuggerObject => $DebuggerObject,
    MappingConfig  => {
        Type => 'ThisIsCertainlyNotBeingUsed',
    },
);
$Self->IsNot(
    ref $MappingObject,
    'Kernel::GenericInterface::Mapping',
    'Mapping::new() constructor failure - wrong MappingType',
);

# call with empty config
$MappingObject = Kernel::GenericInterface::Mapping->new(
    DebuggerObject => $DebuggerObject,
    MappingConfig  => {
        Type   => 'Test',
        Config => {},
    },
);
$Self->IsNot(
    ref $MappingObject,
    'Kernel::GenericInterface::Mapping',
    'Mapping::new() constructor failure - empty config',
);

# call with invalid config
$MappingObject = Kernel::GenericInterface::Mapping->new(
    DebuggerObject => $DebuggerObject,
    MappingConfig  => {
        Type   => 'Test',
        Config => 'invalid',
    },
);
$Self->IsNot(
    ref $MappingObject,
    'Kernel::GenericInterface::Mapping',
    'Mapping::new() constructor failure - invalid config, string',
);

# call with invalid config
$MappingObject = Kernel::GenericInterface::Mapping->new(
    DebuggerObject => $DebuggerObject,
    MappingConfig  => {
        Type   => 'Test',
        Config => [],
    },
);
$Self->IsNot(
    ref $MappingObject,
    'Kernel::GenericInterface::Mapping',
    'Mapping::new() constructor failure - invalid config, array',
);

# call with invalid config
$MappingObject = Kernel::GenericInterface::Mapping->new(
    DebuggerObject => $DebuggerObject,
    MappingConfig  => {
        Type   => 'Test',
        Config => '',
    },
);
$Self->IsNot(
    ref $MappingObject,
    'Kernel::GenericInterface::Mapping',
    'Mapping::new() constructor failure - invalid config, empty string',
);

# call without config
$MappingObject = Kernel::GenericInterface::Mapping->new(
    DebuggerObject => $DebuggerObject,
    MappingConfig  => {
        Type => 'Test',
    },
);
$Self->Is(
    ref $MappingObject,
    'Kernel::GenericInterface::Mapping',
    'MappingObject creation check without config',
);

# map without data
my $ReturnData = $MappingObject->Map();
$Self->Is(
    ref $ReturnData,
    'HASH',
    'MappingObject call response type',
);
$Self->True(
    $ReturnData->{Success},
    'MappingObject call no data provided',
);

# map with empty data
$ReturnData = $MappingObject->Map(
    Data => {},
);
$Self->Is(
    ref $ReturnData,
    'HASH',
    'MappingObject call response type',
);
$Self->True(
    $ReturnData->{Success},
    'MappingObject call empty data provided',
);

# map with invalid data
$ReturnData = $MappingObject->Map(
    Data => [],
);
$Self->Is(
    ref $ReturnData,
    'HASH',
    'MappingObject call response type',
);
$Self->False(
    $ReturnData->{Success},
    'MappingObject call invalid data provided',
);

# map with some data
$ReturnData = $MappingObject->Map(
    Data => {
        'from' => 'to',
    },
);
$Self->True(
    $ReturnData->{Success},
    'MappingObject call data provided',
);

1;
