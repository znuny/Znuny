# --
# Copyright (C) 2001-2021 OTRS AG, https://otrs.com/
# Copyright (C) 2021-2022 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see https://www.gnu.org/licenses/gpl-3.0.txt.
# --

package scripts::test::CommunicationChannel::Test;    ## no critic

use parent 'Kernel::System::CommunicationChannel::Base';

use strict;
use warnings;

our @ObjectDependencies = ();

sub new {
    my ( $Type, %Param ) = @_;

    my $Self = {};
    bless( $Self, $Type );

    return $Self;
}

sub ArticleDataTables {
    return (
        'i_do_not_exist',
    );
}

sub ArticleDataArticleIDField {
    return 'article_id';
}

sub PackageNameGet {
    return 'TestPackage';
}

1;
