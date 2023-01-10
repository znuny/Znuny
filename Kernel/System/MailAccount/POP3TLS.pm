# --
# Copyright (C) 2021 Znuny GmbH, https://znuny.org/
# Copyright (C) 2001-2021 OTRS AG, https://otrs.com/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see https://www.gnu.org/licenses/gpl-3.0.txt.
# --

package Kernel::System::MailAccount::POP3TLS;

use strict;
use warnings;

use parent qw(Kernel::System::MailAccount::POP3);

our @ObjectDependencies;

# Use Net::SSLGlue::POP3 on systems with older Net::POP3 modules that cannot handle POP3TLS.
BEGIN {
    if ( !defined &Net::POP3::starttls ) {
        ## nofilter(TidyAll::Plugin::Znuny::Perl::Require)
        ## nofilter(TidyAll::Plugin::Znuny::Perl::SyntaxCheck)
        require Net::SSLGlue::POP3;
    }
}

sub _GetStartTLSOptions {
    my ( $Self, %Param ) = @_;

    my %StartTLSOptions = (
        SSL             => 1,
        SSL_verify_mode => 0,
    );

    return %StartTLSOptions;
}

1;
