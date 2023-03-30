# --
# Copyright (C) 2021 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::MailAccount::Base;

use strict;
use warnings;

sub _GetSSLOptions {
    my ( $Self, %Param ) = @_;

    return;
}

sub _GetStartTLSOptions {
    my ( $Self, %Param ) = @_;

    return;
}

sub _GetMailAccountModuleName {
    my ( $Self, %Param ) = @_;

    my $PackageName = ref $Self;
    if ( $PackageName =~ m{\AKernel::System::MailAccount::(.*)\z} ) {
        $PackageName = $1;
    }

    return $PackageName;
}

1;
