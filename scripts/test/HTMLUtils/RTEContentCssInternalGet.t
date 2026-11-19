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

my $ConfigObject    = $Kernel::OM->Get('Kernel::Config');
my $HTMLUtilsObject = $Kernel::OM->Get('Kernel::System::HTMLUtils');

my $ConfiguredPaths = $ConfigObject->Get('Frontend::RichText::CSS::Content::Path')->{InternalArticleStyles};
my @OriginalPaths   = @{$ConfiguredPaths};

my $FirstCSS = $HTMLUtilsObject->RTEContentCssInternalGet(
    UserType => 'Agent',
);
my $SecondCSS = $HTMLUtilsObject->RTEContentCssInternalGet(
    UserType => 'Agent',
);

$Self->IsDeeply(
    $ConfigObject->Get('Frontend::RichText::CSS::Content::Path')->{InternalArticleStyles},
    \@OriginalPaths,
    'InternalArticleStyles paths stay unchanged',
);

$Self->True(
    ref $FirstCSS eq 'SCALAR' && ${$FirstCSS} =~ m{\.ck-content},
    'RTEContentCssInternalGet() first call contains .ck-content',
);
$Self->True(
    ref $SecondCSS eq 'SCALAR' && ${$SecondCSS} =~ m{\.ck-content},
    'RTEContentCssInternalGet() second call contains .ck-content',
);

1;
