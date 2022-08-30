# --
# Copyright (C) 2001-2021 OTRS AG, https://otrs.com/
# Copyright (C) 2021-2022 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see https://www.gnu.org/licenses/gpl-3.0.txt.
# --

package Kernel::System::SupportDataCollector::Plugin::OTRS::EmailQueue;

use strict;
use warnings;

use parent qw(Kernel::System::SupportDataCollector::PluginBase);

use Kernel::Language qw(Translatable);

our @ObjectDependencies = (
    'Kernel::System::MailQueue',
);

sub GetDisplayPath {
    return Translatable('OTRS') . '/' . Translatable('Email Sending Queue');
}

sub Run {
    my $Self = shift;

    my $MailQueue = $Kernel::OM->Get('Kernel::System::MailQueue')->List();

    my $MailAmount = scalar @{$MailQueue};

    $Self->AddResultInformation(
        Label => Translatable('Emails queued for sending'),
        Value => $MailAmount,
    );

    return $Self->GetResults();
}

1;
