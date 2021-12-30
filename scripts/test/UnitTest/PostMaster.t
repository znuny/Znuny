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

my $ZnunyHelperObject    = $Kernel::OM->Get('Kernel::System::ZnunyHelper');
my $ConfigObject         = $Kernel::OM->Get('Kernel::Config');
my $SysConfigObject      = $Kernel::OM->Get('Kernel::System::SysConfig');
my $UnitTestHelperObject = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');

#
# Tests for _PostmasterXHeaderAdd and _PostmasterXHeaderRemove
#
my @RandomHeaderNames;
for ( 0 .. 1 ) {
    push @RandomHeaderNames, 'X-OTRS-Test-' . $UnitTestHelperObject->GetRandomNumber();
}
my @Tests = (
    {
        Name           => 'Header parameter is undef',
        Headers        => undef,
        ExpectedResult => 0,
    },
    {
        Name           => 'Header parameter is empty array ref',
        Headers        => undef,
        ExpectedResult => 0,
    },
    {
        Name           => 'Header parameter is string',
        Headers        => $RandomHeaderNames[0],
        ExpectedResult => 1,
    },
    {
        Name           => 'Header parameter is array ref with one element',
        Headers        => [ $RandomHeaderNames[0], ],
        ExpectedResult => 1,
    },
    {
        Name           => 'Header parameter is array ref with two elements',
        Headers        => [ $RandomHeaderNames[0], $RandomHeaderNames[1], ],
        ExpectedResult => 1,
    },
);

my $OriginalConfiguredHeaders = $ConfigObject->Get('PostmasterX-Header');
my %OriginalConfiguredHeaders = map { $_ => 1 } @{$OriginalConfiguredHeaders};

TEST:
for my $Test (@Tests) {

    #
    # Add headers
    #

    my $AddResult = $ZnunyHelperObject->_PostmasterXHeaderAdd(
        Header => $Test->{Headers},
    );
    $AddResult = $AddResult ? 1 : 0;

    $Self->Is(
        $AddResult,
        $Test->{ExpectedResult},
        $Test->{Name} . ': Result of _PostmasterXHeaderAdd() must match expected one.',
    );

    next TEST if $AddResult != $Test->{ExpectedResult};

    # Write config changes
    $ZnunyHelperObject->_RebuildConfig();

    # refetch config object because it was discarded by _PackageSetupInit
    $ConfigObject = $Kernel::OM->Get('Kernel::Config');

    my %ExpectedHeaders = %OriginalConfiguredHeaders;
    if ( IsArrayRefWithData( $Test->{Headers} ) ) {
        for my $Header ( @{ $Test->{Headers} } ) {
            $ExpectedHeaders{$Header} = 1;
        }
    }
    elsif ( IsStringWithData( $Test->{Headers} ) ) {
        $ExpectedHeaders{ $Test->{Headers} } = 1;
    }

    my $ChangedConfiguredHeaders = $ConfigObject->Get('PostmasterX-Header');
    my %ChangedConfiguredHeaders = map { $_ => 1 } @{$ChangedConfiguredHeaders};

    $Self->IsDeeply(
        \%ChangedConfiguredHeaders,
        \%ExpectedHeaders,
        $Test->{Name} . ': Headers must match expected ones after _PostmasterXHeaderAdd().'
    );

    #
    # Remove headers
    #

    my $RemoveResult = $ZnunyHelperObject->_PostmasterXHeaderRemove(
        Header => $Test->{Headers},
    );
    $RemoveResult = $RemoveResult ? 1 : 0;

    $Self->Is(
        $RemoveResult,
        $Test->{ExpectedResult},
        $Test->{Name} . ': Result of _PostmasterXHeaderRemove() must match expected one.',
    );

    next TEST if $RemoveResult != $Test->{ExpectedResult};

    # Write config changes
    $ZnunyHelperObject->_RebuildConfig();

    # refetch config object because it was discarded by _PackageSetupInit
    $ConfigObject = $Kernel::OM->Get('Kernel::Config');

    $ChangedConfiguredHeaders = $ConfigObject->Get('PostmasterX-Header');
    %ChangedConfiguredHeaders = map { $_ => 1 } @{$ChangedConfiguredHeaders};

    $Self->IsDeeply(
        \%ChangedConfiguredHeaders,
        \%OriginalConfiguredHeaders,
        $Test->{Name} . ': Headers must match expected ones after _PostmasterXHeaderRemove().',
    );
}

1;
