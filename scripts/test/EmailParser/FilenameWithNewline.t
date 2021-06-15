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

# Test that filenames with multiple newlines are properly cleaned up.
# See http://bugs.otrs.org/show_bug.cgi?id=10394.

my $Home = $Kernel::OM->Get('Kernel::Config')->Get('Home');

# test for bug#1970
my @Array;
open my $IN, '<', "$Home/scripts/test/sample/EmailParser/FilenameWithNewline.box";    ## no critic
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
    "Found files",
);

$Self->Is(
    $Attachments[2]->{'Filename'} || '',
    'Test testtestt 1231234_34_Testtesttes testes testtesttestt - testtesttes dokumentów_Sprzedaż_ testTE _..._ _TE#123123123_8c51a4c1d1ca2b12bb4efabe82f41428.eml',
    "Filename with multiple newlines removed",
);

1;
