# --
# Copyright (C) 2021 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::Email::SMTPS;

use strict;
use warnings;

use parent qw(Kernel::System::Email::SMTP);

our @ObjectDependencies;

sub _GetSMTPDefaultPort {
    my ( $Self, %Param ) = @_;

    return 465;
}

sub _GetSSLOptions {
    my ( $Self, %Param ) = @_;

    my %SSLOptions = (
        SSL             => 1,
        SSL_verify_mode => 0,
    );

    return %SSLOptions;
}

1;
