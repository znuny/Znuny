# --
# Copyright (C) 2021 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package scripts::test::sample::SysConfig::Migration::SessionCookieNamesLegacy;

use strict;
use warnings;
use utf8;

sub Load {
    my ( $File, $Self ) = @_;

    return if !$File;

    $Self->{SessionName}              = 'OTRSAgentInterface';
    $Self->{CustomerPanelSessionName} = 'OTRSCustomerInterface';

    return;
}

1;
