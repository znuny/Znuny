# --
# Copyright (C) 2001-2021 OTRS AG, https://otrs.com/
# Copyright (C) 2021 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see https://www.gnu.org/licenses/gpl-3.0.txt.
# --

## no critic (Modules::RequireExplicitPackage)
use strict;
use warnings;
use utf8;

use vars (qw($Self));

$Kernel::OM->ObjectParamAdd(
    'Kernel::System::UnitTest::Helper' => {
        RestoreDatabase => 1,
    },
);
my $HelperObject = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');

my $RandomID = $HelperObject->GetRandomID();

my $TestCustomerUserLogin = $HelperObject->TestCustomerUserCreate(
    Language => 'en',
);

my %ExpectedDataRaw = $Kernel::OM->Get('Kernel::System::CustomerUser')->CustomerUserDataGet(
    User => $TestCustomerUserLogin,
);

my @Tests = (
    {
        Name    => 'No Params',
        Config  => {},
        Success => 0,
    },
    {
        Name   => 'Success',
        Config => {
            Data => {
                UserLogin => $TestCustomerUserLogin,
            },
        },
        Success => 1,
    },
);

my $BackedObject = $Kernel::OM->Get('Kernel::GenericInterface::Event::ObjectType::CustomerUser');

TEST:
for my $Test (@Tests) {

    my %ObjectData = $BackedObject->DataGet( %{ $Test->{Config} } );

    my %ExpectedData;
    if ( $Test->{Success} ) {
        %ExpectedData = %ExpectedDataRaw;
    }

    $Self->IsDeeply(
        \%ObjectData,
        \%ExpectedData,
        "$Test->{Name} DataGet()"
    );
}

# Cleanup is done by RestoreDatabase.
1;
