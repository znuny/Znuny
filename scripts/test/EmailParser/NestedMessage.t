# --
# Copyright (C) 2001-2021 OTRS AG, https://otrs.com/
# Copyright (C) 2021 Znuny GmbH, https://znuny.org/
# Copyright (C) 2021 Informatyka Boguslawski sp. z o.o. sp.k., http://www.ib.pl/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see https://www.gnu.org/licenses/gpl-3.0.txt.
# --

use strict;
use warnings;
use utf8;

use vars (qw($Self));

use Kernel::System::EmailParser;

my $Home = $Kernel::OM->Get('Kernel::Config')->Get('Home');

# test for bug#1970
my @Array;
open my $IN, '<', "$Home/scripts/test/sample/EmailParser/NestedMessage-Test1.box";    ## no critic
while (<$IN>) {
    push @Array, $_;
}
close $IN;

# create local object
my $EmailParserObject = Kernel::System::EmailParser->new(
    Email => \@Array,
);

my @Attachments = $EmailParserObject->GetAttachments();
$Self->Is(
    scalar @Attachments,
    3,
    "Found 3 files (plain, html and attachment for nested message)",
);

$Self->Is(
    $Attachments[2]->{Filename} || '',
    '_Presse-Greenpeace_ Morgen wird Greenpeace-Einspruch gegenEmbryonen-Paten_962fb2b3711f7f233945657da34d17da.eml',
    "Nested message filename",
);

1;
