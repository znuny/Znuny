# --
# Copyright (C) 2001-2021 OTRS AG, https://otrs.com/
# Copyright (C) 2021 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see https://www.gnu.org/licenses/gpl-3.0.txt.
# --

package Kernel::System::Console::Command::Admin::Article::StorageSwitch;

use strict;
use warnings;

use parent qw(Kernel::System::Console::BaseCommand);

use File::Basename;
use Time::HiRes qw(usleep);

our @ObjectDependencies = (
    'Kernel::Config',
    'Kernel::System::Main',
    'Kernel::System::DateTime',
    'Kernel::System::PID',
    'Kernel::System::Ticket',
);

sub Configure {
    my ( $Self, %Param ) = @_;

    my @Backends     = $Self->_GetStorageBackends();
    my $BackendRegex = join '|', @Backends;

    $Self->Description('Migrate article files from one storage backend to another on the fly.');
    $Self->AddOption(
        Name        => 'target',
        Description => "Specify the target backend to migrate to ($BackendRegex).",
        Required    => 1,
        HasValue    => 1,
        ValueRegex  => qr/^(?:$BackendRegex)$/smx,
    );
    $Self->AddOption(
        Name        => 'source',
        Description => "Specify the source backend to migrate from ($BackendRegex).",
        Required    => 0,
        HasValue    => 1,
        ValueRegex  => qr/^(?:$BackendRegex)$/smx,
    );
    $Self->AddOption(
        Name        => 'tickets-closed-before-date',
        Description => "Only process tickets closed before given ISO date.",
        Required    => 0,
        HasValue    => 1,
        ValueRegex  => qr/^\d{4}-\d{2}-\d{2}[ ]\d{2}:\d{2}:\d{2}$/smx,
    );
    $Self->AddOption(
        Name        => 'tickets-closed-before-days',
        Description => "Only process tickets closed more than ... days ago.",
        Required    => 0,
        HasValue    => 1,
        ValueRegex  => qr/^\d+$/smx,
    );
    $Self->AddOption(
        Name        => 'tickets-created-before-date',
        Description => "Only process tickets created before given ISO date.",
        Required    => 0,
        HasValue    => 1,
        ValueRegex  => qr/^\d{4}-\d{2}-\d{2}[ ]\d{2}:\d{2}:\d{2}$/smx,
    );
    $Self->AddOption(
        Name        => 'tickets-created-before-days',
        Description => "Only process tickets created more than ... days ago.",
        Required    => 0,
        HasValue    => 1,
        ValueRegex  => qr/^\d+$/smx,
    );
    $Self->AddOption(
        Name        => 'tolerant',
        Description => "Continue after failures.",
        Required    => 0,
        HasValue    => 0,
    );
    $Self->AddOption(
        Name        => 'micro-sleep',
        Description => "Specify microseconds to sleep after every ticket to reduce system load (e.g. 1000).",
        Required    => 0,
        HasValue    => 1,
        ValueRegex  => qr/^\d+$/smx,
    );
    $Self->AddOption(
        Name        => 'force-pid',
        Description => "Start even if another process is still registered in the database.",
        Required    => 0,
        HasValue    => 0,
    );

    my $Name = $Self->Name();

    $Self->AdditionalHelp(<<"EOF");
The <green>$Name</green> command migrates article data from one storage backend to another on the fly, for example from DB to FS:

 <green>otrs.Console.pl $Self->{Name} --target ArticleStorageFS</green>

You can specify limits for the tickets migrated with <yellow>--tickets-closed-before-date</yellow> and <yellow>--tickets-closed-before-days</yellow>.

To reduce load on the database for a running system, you can use the <yellow>--micro-sleep</yellow> parameter. The command will pause for the specified amount of microseconds after each ticket.

 <green>otrs.Console.pl $Self->{Name} --target ArticleStorageFS --micro-sleep 1000</green>
EOF
    return;
}

sub PreRun {
    my ($Self) = @_;

    my $PIDCreated = $Kernel::OM->Get('Kernel::System::PID')->PIDCreate(
        Name  => $Self->Name(),
        Force => $Self->GetOption('force-pid'),
        TTL   => 60 * 60 * 24 * 3,
    );
    if ( !$PIDCreated ) {
        my $Error = "Unable to register the process in the database. Is another instance still running?\n";
        $Error .= "You can use --force-pid to override this check.\n";
        die $Error;
    }

    return;
}

sub Run {
    my ($Self) = @_;

    # disable ticket events
    $Kernel::OM->Get('Kernel::Config')->{'Ticket::EventModulePost'} = {};

    # extended input validation
    my %SearchParams;

    if ( $Self->GetOption('tickets-closed-before-date') ) {
        %SearchParams = (
            StateType                => 'Closed',
            TicketCloseTimeOlderDate => $Self->GetOption('tickets-closed-before-date'),
        );
    }
    elsif ( $Self->GetOption('tickets-closed-before-days') ) {
        my $Days = $Self->GetOption('tickets-closed-before-days');

        my $OlderDTObject = $Kernel::OM->Create('Kernel::System::DateTime');
        $OlderDTObject->Subtract( Days => $Days );

        %SearchParams = (
            StateType                => 'Closed',
            TicketCloseTimeOlderDate => $OlderDTObject->ToString(),
        );
    }

    if ( $Self->GetOption('tickets-created-before-date') ) {
        $SearchParams{TicketCreateTimeOlderDate} = $Self->GetOption('tickets-created-before-date');
    }
    elsif ( $Self->GetOption('tickets-created-before-days') ) {
        my $Days = $Self->GetOption('tickets-created-before-days');

        my $OlderDTObject = $Kernel::OM->Create('Kernel::System::DateTime');
        $OlderDTObject->Subtract( Days => $Days );

        $SearchParams{TicketCreateTimeOlderDate} = $OlderDTObject->ToString();
    }

    # If Archive system is enabled, take into account archived tickets as well.
    # See bug#13945 (https://bugs.otrs.org/show_bug.cgi?id=13945).
    if ( $Kernel::OM->Get('Kernel::Config')->{'Ticket::ArchiveSystem'} ) {
        $SearchParams{ArchiveFlags} = [ 'y', 'n' ];
    }

    my $TicketObject = $Kernel::OM->Get('Kernel::System::Ticket');

    my @TicketIDs = $TicketObject->TicketSearch(
        %SearchParams,
        Result     => 'ARRAY',
        OrderBy    => 'Up',
        Limit      => 1_000_000_000,
        UserID     => 1,
        Permission => 'ro',
    );

    my $Count      = 0;
    my $CountTotal = scalar @TicketIDs;

    my $Target        = $Self->GetOption('target');
    my %Target2Source = (
        ArticleStorageFS => 'ArticleStorageDB',
        ArticleStorageDB => 'ArticleStorageFS',
    );

    my $Source = $Target2Source{$Target} // $Self->GetOption('source');

    if ( !$Source ) {
        $Self->Print("<red>Need source option.</red>\n");

        return $Self->ExitCodeError();
    }

    my $MicroSleep = $Self->GetOption('micro-sleep');
    my $Tolerant   = $Self->GetOption('tolerant');

    TICKETID:
    for my $TicketID (@TicketIDs) {

        $Count++;

        $Self->Print("$Count/$CountTotal (TicketID:$TicketID)\n");

        my $Success = $TicketObject->TicketArticleStorageSwitch(
            TicketID    => $TicketID,
            Source      => $Source,
            Destination => $Target,
            UserID      => 1,
        );

        return $Self->ExitCodeError() if !$Tolerant && !$Success;

        Time::HiRes::usleep($MicroSleep) if ($MicroSleep);
    }

    $Self->Print("<green>Done.</green>\n");

    return $Self->ExitCodeOk();

}

sub PostRun {
    my ($Self) = @_;

    return $Kernel::OM->Get('Kernel::System::PID')->PIDDelete( Name => $Self->Name() );
}

sub _GetStorageBackends {
    my ($Self) = @_;

    my $MainObject = $Kernel::OM->Get('Kernel::System::Main');

    my $Base = 'Kernel/System/Ticket/Article/Backend/MIMEBase';
    my $Home = $Kernel::OM->Get('Kernel::Config')->Get('Home');

    my %Backends;
    for my $Prefix ( '/', '/Custom/' ) {
        my @Files = $MainObject->DirectoryRead(
            Directory => $Home . $Prefix . $Base,
            Filter    => '*.pm',
            Silent    => 1,
        );

        FILE:
        for my $File (@Files) {
            my $Basename = basename $File, '.pm';

            next FILE if 'Base' eq $Basename;

            $Backends{$Basename} = 1;
        }
    }

    my @BackendList = sort keys %Backends;
    return @BackendList;
}

1;
