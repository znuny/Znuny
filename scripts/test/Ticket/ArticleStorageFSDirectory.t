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

my $ConfigObject = $Kernel::OM->Get('Kernel::Config');
my $Home         = $ConfigObject->Get('Home');

my @MissingDirectories = (
    "$Home/var/tmp/znuny-article-missing-$$",
    "/tmp/znuny-article-missing-$$",
);

DIRECTORY:
for my $Directory (@MissingDirectories) {

    $Self->False(
        -e $Directory,
        "Missing directory test path does not exist yet: $Directory",
    );

    $ConfigObject->Set(
        Key   => 'Ticket::Article::Backend::MIMEBase::ArticleDataDir',
        Value => $Directory,
    );

    my $ArticleStorageObject = eval {
        $Kernel::OM->Create(
            'Kernel::System::Ticket::Article::Backend::MIMEBase::ArticleStorageFS',
        );
    };
    my $CreateError = $@;

    $Self->False(
        $ArticleStorageObject,
        "ArticleStorageFS was not created for missing directory $Directory",
    );

    $Self->True(
        $CreateError,
        "ArticleStorageFS died for missing directory $Directory",
    );

    $Self->False(
        -e $Directory,
        "Missing ArticleDataDir was not created: $Directory",
    );
}

1;
