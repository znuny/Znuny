# --
# Copyright (C) 2021 Znuny GmbH, https://znuny.org/
# Copyright (C) 2001-2021 OTRS AG, https://otrs.com/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see https://www.gnu.org/licenses/gpl-3.0.txt.
# --

package Kernel::System::Email::SMTPTLS;

use strict;
use warnings;

use parent qw(Kernel::System::Email::SMTP);

our @ObjectDependencies;

# Use Net::SSLGlue::SMTP on systems with older Net::SMTP modules that cannot handle SMTPTLS.
BEGIN {
    if ( !defined &Net::SMTP::starttls ) {
        ## nofilter(TidyAll::Plugin::Znuny::Perl::Require)
        ## nofilter(TidyAll::Plugin::Znuny::Perl::SyntaxCheck)
        require Net::SSLGlue::SMTP;
    }
}

sub _GetSMTPDefaultPort {
    my ( $Self, %Param ) = @_;

    return 587;
}

sub _GetStartTLSOptions {
    my ( $Self, %Param ) = @_;

    my %StartTLSOptions = (
        SSL_verify_mode => 0,
    );

    return %StartTLSOptions;
}

1;
