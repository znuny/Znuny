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
use MIME::Base64;
use Kernel::Modules::AJAXAttachment;

$Kernel::OM->ObjectParamAdd(
    'Kernel::System::UnitTest::Helper' => {
        RestoreDatabase => 1,
    },
);

my $ConfigObject        = $Kernel::OM->Get('Kernel::Config');
my $HelperObject        = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');
my $UploadCacheObject   = $Kernel::OM->Get('Kernel::System::Web::UploadCache');
my $UnitTestParamObject = $Kernel::OM->Get('Kernel::System::UnitTest::Param');
my $LayoutObject        = $Kernel::OM->Get('Kernel::Output::HTML::Layout');

my $ZipContent = MIME::Base64::decode(<<EOF);
UEsDBAoAAAAAAKqQH10h39v0AQAAAAEAAAABABwAMFVUCQADL5iVaiyYlWp1eAsAAQToAwAABOgD
AAAwUEsBAh4DCgAAAAAAqpAfXSHf2/QBAAAAAQAAAAEAGAAAAAAAAQAAALCBAAAAADBVVAUAAy+Y
lWp1eAsAAQToAwAABOgDAABQSwUGAAAAAAEAAQBHAAAAPAAAAAAA
EOF

$LayoutObject->{UserID} = 1;

$ConfigObject->Set(
    Key   => 'SessionCSRFProtection',
    Value => 0,
);

my $AttachmentConfig = $ConfigObject->Get('Attachment') || {};
$AttachmentConfig->{PreviewContentTypes} = {
    'application/pdf' => 'pdf',
    'text/plain'      => 'plain',
    'image/png'       => 'png',
};
$ConfigObject->Set(
    Key   => 'Attachment',
    Value => $AttachmentConfig,
);

my $FormID = $UploadCacheObject->FormIDCreate();

my $ModuleObject = Kernel::Modules::AJAXAttachment->new(
    Subaction => 'Preview',
    UserID    => 1,
);

my $AddPreviewFile = sub {
    my %Param = @_;

    $UploadCacheObject->FormIDAddFile(
        FormID      => $FormID,
        Filename    => $Param{Filename},
        Content     => $Param{Content},
        ContentType => $Param{ContentType},
        Disposition => 'attachment',
    );

    my @Files = $UploadCacheObject->FormIDGetAllFilesMeta(
        FormID => $FormID,
    );

    FILE:
    for my $File ( reverse @Files ) {
        next FILE if $File->{Filename} ne $Param{Filename};
        return $File->{FileID};
    }

    return;
};

my $RunPreview = sub {
    my %Param = @_;

    $UnitTestParamObject->ParamSet(
        Name  => 'FormID',
        Value => $Param{FormID} // $FormID,
    );
    $UnitTestParamObject->ParamSet(
        Name  => 'FileID',
        Value => $Param{FileID},
    );

    return $ModuleObject->Run();
};

my $PDFContent = "%PDF-1.4\n1 0 obj<<>>endobj\ntrailer<<>>\n%%EOF\n";
my $PDFFileID  = $AddPreviewFile->(
    Filename    => 'preview.pdf',
    Content     => $PDFContent,
    ContentType => 'application/pdf',
);

my $PDFResult = $RunPreview->( FileID => $PDFFileID );

$Self->True(
    index( $PDFResult, "Content-Disposition: inline;" ) != -1,
    'Preview of PDF uses Content-Disposition inline',
);
$Self->True(
    index( $PDFResult, 'Content-Type: application/pdf' ) != -1,
    'Preview of PDF keeps the original content type',
);
$Self->True(
    index( $PDFResult, $PDFContent ) != -1,
    'Preview of PDF returns the file content',
);
$Self->True(
    index( $PDFResult, "Content-Security-Policy:" ) != -1,
    'Preview of PDF sends a sandbox Content-Security-Policy',
);
$Self->False(
    index( $PDFResult, 'data:application/pdf' ) != -1,
    'Preview of PDF does not use a data URL',
);

my $PlainFileID = $AddPreviewFile->(
    Filename    => 'preview.txt',
    Content     => 'plain preview text',
    ContentType => 'text/plain; charset=utf-8',
);

my $PlainResult = $RunPreview->( FileID => $PlainFileID );

$Self->True(
    index( $PlainResult, 'plain preview text' ) != -1,
    'Preview allows content types with a charset parameter',
);

my $ZipFileID = $AddPreviewFile->(
    Filename    => 'preview.zip',
    Content     => $ZipContent,
    ContentType => 'application/zip',
);

my $ZipResult = $RunPreview->( FileID => $ZipFileID );

$Self->False(
    index( $ZipResult, $ZipContent ) != -1,
    'Preview of a non-allowlisted type does not return the file content',
);
$Self->True(
    index( $ZipResult, 'Content-Type: text/html' ) != -1 || index( $ZipResult, 'cannot be previewed' ) != -1,
    'Preview of a non-allowlisted type returns an error',
);

my $MissingResult = $RunPreview->( FileID => 99999 );

$Self->False(
    index( $MissingResult, $PDFContent ) != -1,
    'Preview of an unknown FileID does not return another file',
);

$UploadCacheObject->FormIDRemove(
    FormID => $FormID,
);

1;
