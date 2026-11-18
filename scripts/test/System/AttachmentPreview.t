# --
# Copyright (C) 2021 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

## no critic (RequireExplicitPackage)
use strict;
use warnings;
use utf8;

use vars (qw($Self));

my $HelperObject            = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');
my $AttachmentPreviewObject = $Kernel::OM->Get('Kernel::System::AttachmentPreview');

$HelperObject->ConfigSettingChange(
    Valid => 1,
    Key   => 'Attachment###PreviewContentTypes',
    Value => {
        'application/pdf' => 'pdf',
        'image/png'       => 'png',
        'image/jpeg'      => 'jpeg',
        'text/plain'      => 'plain',
    },
);

$Self->True(
    $AttachmentPreviewObject->IsPreviewable( ContentType => 'image/png' ),
    'PNG is previewable',
);

$Self->True(
    $AttachmentPreviewObject->IsPreviewable( ContentType => 'image/png; name="x.png"' ),
    'PNG with Content-Type parameter is previewable',
);

$Self->True(
    $AttachmentPreviewObject->IsPreviewable( ContentType => 'image/jpg' ),
    'image/jpg alias is previewable',
);

$Self->True(
    $AttachmentPreviewObject->IsPreviewable(
        ContentType => 'application/octet-stream',
        Filename    => 'scan.PDF',
    ),
    'PDF by filename is previewable',
);

$Self->False(
    $AttachmentPreviewObject->IsPreviewable(
        ContentType => 'application/zip',
        Filename    => 'files.zip',
    ),
    'ZIP is not previewable',
);

$Self->True(
    $AttachmentPreviewObject->IsPDF(
        ContentType => 'application/pdf; name="a.pdf"',
    ),
    'PDF by Content-Type',
);

$Self->True(
    $AttachmentPreviewObject->IsPDF(
        ContentType => 'application/octet-stream',
        Filename    => 'a.pdf',
    ),
    'PDF by filename',
);

$Self->False(
    $AttachmentPreviewObject->IsPDF(
        ContentType => 'image/png',
        Filename    => 'a.png',
    ),
    'PNG is not a PDF',
);

$Self->True(
    $AttachmentPreviewObject->IsPDF(
        ContentType => 'application/pdf',
        Filename    => 'monitor.pdf',
    ),
    'PDF by Content-Type and filename',
);

$Self->True(
    $AttachmentPreviewObject->IsPreviewable(
        ContentType => 'image/png',
        Filename    => 'shot.png',
    ),
    'PNG with filename is previewable',
);

1;
