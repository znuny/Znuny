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

# get HTMLUtils object
my $HTMLUtilsObject = $Kernel::OM->Get('Kernel::System::HTMLUtils');

# DocumentComplete tests
my @Tests = (
    {
        Input  => 'Some Text',
        Result => 'Some Text',
        Name   => 'DocumentComplete - simple'
    },
    {
        Input  => 'Some Text',
        Result => 'Some Text',
        Name   => 'DocumentComplete - simple'
    },
);

for my $Test (@Tests) {
    my $Ascii = $HTMLUtilsObject->DocumentComplete(
        Charset => 'iso-8859-1',
        String  => $Test->{Input},
    );

    # Quote the expected text to avoid problems with special characters.
    $Test->{Result} = quotemeta( $Test->{Result} );

    # Check if the result contains the expected HTML structure between <body> tags.
    my $Contains = $Ascii =~ m{$Test->{Result}};

    $Self->True(
        $Contains,
        "$Test->{Name} - $Ascii",
    );

}

1;
