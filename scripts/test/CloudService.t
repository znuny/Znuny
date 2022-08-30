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

use Kernel::System::VariableCheck qw(:all);

my $Index = 0;

my @Tests = (
    {
        Name    => 'Test ' . $Index . '.- No RequestData',
        Success => '0',
    },
    {
        Name        => 'Test ' . $Index . '.- RequestData is not an array, HASH',
        RequestData => {},
        Success     => '0',
    },
    {
        Name        => 'Test ' . $Index . '.- RequestData is not an array, STRING',
        RequestData => 'Array',
        Success     => '0',
    },
    {
        Name        => 'Test ' . $Index . '.- RequestData without web service',
        RequestData => {
            '' => [
                {
                    InstanceName => 'AnyName',            # optional
                    Operation    => "ConfigurationSet",
                    Data         => {

                        # ... request operation data ...
                    },
                },
            ],
        },
        Success => '0',
    },
    {
        Name        => 'Test ' . $Index . '.- RequestData without Operation',
        RequestData => {
            CloudServiceTest => [
                {
                    InstanceName => 'AnyName',    # optional
                    Data         => {

                        # ... request operation data ...
                    },
                },
            ],
        },
        Success => '0',
    },
    {
        Name        => 'Test ' . $Index . '.- Wrong Data structure - STRING',
        RequestData => {
            CloudServiceTest => [
                {
                    InstanceName => 'MyInstance',               # optional
                    Operation    => "ConfigurationSet",
                    Data         => 'NoCorrectDataStructure',
                },
            ],
        },
        Success => '0',
    },
    {
        Name        => 'Test ' . $Index . '.- Wrong Data structure - ARRAY',
        RequestData => {
            CloudServiceTest => [
                {
                    InstanceName => 'MyInstance',             # optional
                    Operation    => "ConfigurationSet",
                    Data         => [ 'a', 'b', 'c', 'd' ],
                },
            ],
        },
        Success => '0',
    },
    {
        Name        => 'Test ' . $Index . '.- Correct Request data structure - Not a real CloudService',
        RequestData => {
            CloudServiceTest => [
                {
                    InstanceName => 'AnyName',            # optional
                    Operation    => "ConfigurationSet",
                    Data         => {

                        # ... request operation data ...
                    },
                },
            ],
        },
        Success => '1',
    },

);

my $CloudServiceObject = $Kernel::OM->Get('Kernel::System::CloudService::Backend::Run');

for my $Test (@Tests) {

    my $RequestResult = $CloudServiceObject->Request(
        %{$Test},
    );

    if ( $Test->{Success} ) {

        if ( defined $RequestResult ) {
            $Self->Is(
                ref $RequestResult,
                'HASH',
                "$Test->{Name} - Operation result Data structure",
            );

            # check result for each cloud service is available
            for my $CloudServiceName ( sort keys %{ $Test->{RequestData} } ) {

                $Self->True(
                    $RequestResult->{$CloudServiceName},
                    "$Test->{Name} - A result for each Cloud Service should be present - $CloudServiceName.",
                );

                $Self->Is(
                    scalar @{ $RequestResult->{$CloudServiceName} },
                    scalar @{ $Test->{RequestData}->{$CloudServiceName} },
                    "$Test->{Name} - Each operation should return a result.",
                );
            }
        }
        else {

            $Self->True(
                1,
                "$Test->{Name} - A result from Cloud Service is not availble perhaps web response was not successful because Internet connection.",
            );
        }
    }
    else {
        $Self->Is(
            $RequestResult,
            undef,
            "$Test->{Name} - Operation executed with Fail",
        );
    }
}

1;
