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

# get needed objects
my $ConfigObject = $Kernel::OM->Get('Kernel::Config');

my $HomeDir            = $ConfigObject->Get('Home');
my @BackendModuleFiles = $Kernel::OM->Get('Kernel::System::Main')->DirectoryRead(
    Directory => $HomeDir . '/Kernel/System/Cache/',
    Filter    => '*.pm',
    Silent    => 1,
);

my $CacheType = "UnitTest_Cache_Configure";

MODULEFILE:
for my $ModuleFile (@BackendModuleFiles) {

    next MODULEFILE if !$ModuleFile;

    # extract module name
    my ($Module) = $ModuleFile =~ m{ \/+ ([a-zA-Z0-9]+) \.pm $ }xms;

    next MODULEFILE if !$Module;

    $ConfigObject->Set(
        Key   => 'Cache::Module',
        Value => "Kernel::System::Cache::$Module",
    );

    # create a local cache object
    my $CacheObject = $Kernel::OM->Get('Kernel::System::Cache');
    $CacheObject->Configure(
        CacheInMemory  => 1,
        CacheInBackend => 1,
    );

    die "Could not setup $Module" if !$CacheObject;

    # flush the cache to have a clear test environment
    $CacheObject->CleanUp();

    # set value in memory and in backend
    $CacheObject->Set(
        Type  => $CacheType,
        Key   => "Key1",
        Value => 1,
        TTL   => 60 * 60 * 24 * 3,
    );

    # get value from memory only
    $Self->Is(
        scalar $CacheObject->Get(
            Type           => $CacheType,
            Key            => 'Key1',
            CacheInBackend => 0,
        ),
        1,
        "Cached value from memory",
    );

    # get value from backend only
    $Self->Is(
        scalar $CacheObject->Get(
            Type          => $CacheType,
            Key           => 'Key1',
            CacheInMemory => 0,
        ),
        1,
        "Cached value from backend",
    );

    # disable both options
    $Self->Is(
        scalar $CacheObject->Get(
            Type           => $CacheType,
            Key            => 'Key1',
            CacheInMemory  => 0,
            CacheInBackend => 0,
        ),
        undef,
        "Cached value from no backend",
    );

    # Set value, but in no backend. Subsequent tests make sure it is
    #   actually removed.
    $CacheObject->Set(
        Type           => $CacheType,
        Key            => "Key1",
        Value          => 1,
        TTL            => 60 * 60 * 24 * 3,
        CacheInMemory  => 0,
        CacheInBackend => 0,
    );

    # get value from memory only
    $Self->Is(
        scalar $CacheObject->Get(
            Type           => $CacheType,
            Key            => 'Key1',
            CacheInBackend => 0,
        ),
        undef,
        "Removed value from memory",
    );

    # get value from backend only
    $Self->Is(
        scalar $CacheObject->Get(
            Type          => $CacheType,
            Key           => 'Key1',
            CacheInMemory => 0,
        ),
        undef,
        "Removed value from backend",
    );

    # flush the cache
    $CacheObject->CleanUp();
}

1;
