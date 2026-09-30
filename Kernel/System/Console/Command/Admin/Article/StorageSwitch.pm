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
use utf8;

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

# Serves to automatically build time related options
my %BeforeAfterOpts = (
    before => {
        Search      => 'Older',
        Days        => 'min',
        Description => 'at least',
    },
    after => {
        Search      => 'Newer',
        Days        => 'max',
        Description => 'no more than',
    }
);

sub Configure {
    my ( $Self, %Param ) = @_;

    my @Backends = $Self->_GetStorageBackends();
    if ( @Backends < 2 ) {
        $Self->Print("<red>ERROR: you need at least two storage backends installed!</red>\n");
        $Self->Print("<red>Please check your installation, Znuny comes with two backends already.</red>\n");
        return $Self->ExitCodeError();
    }
    my $BackendHelp
        = @Backends > 2 ? join( ", ", @Backends[ 0, -2 ] ) . ' or ' . $Backends[-1] : join( ' or ', @Backends );
    my $BackendRegex = join '|', @Backends;

    $Self->Description('Migrate article files from one storage backend to another on the fly.');
    $Self->AddOption(
        Name        => 'target',
        Description => "Specify the target backend to migrate to ($BackendRegex).",
        Description => "Specify the target backend to migrate to ($BackendHelp).",
        Required    => 1,
        HasValue    => 1,
        ValueRegex  => qr/^(?:$BackendRegex)$/smx,
    );
    $Self->AddOption(
        Name        => 'source',
        Description => "Specify the source backend to migrate from ($BackendRegex).",
        Description => "Specify the source backend to migrate from ($BackendHelp).",
        Required    => 1,
        HasValue    => 1,
        ValueRegex  => qr/^(?:$BackendRegex)$/smx,
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

    # Generate all combinations of --{created,closed}-{before,after}-{date,days}
    for my $CreateClose (qw( create close)) {
        BEFOREAFTER:
        for my $BeforeAfter (qw( before after )) {
            my $OptionDate = sprintf( 'tickets-%sd-%s-date', $CreateClose, $BeforeAfter );
            my $OptionDays = sprintf( 'tickets-%sd-%s-days', $CreateClose, $BeforeAfterOpts{$BeforeAfter}{Days} );
            my $DescDate   = sprintf(
                'Only process tickets %sd %s the given ISO date.',
                $CreateClose,
                $BeforeAfter
            );
            my $DescDays = sprintf(
                'Only process tickets %sd %s this many days ago.',
                $CreateClose,
                $BeforeAfterOpts{$BeforeAfter}{Description}
            );
            $Self->AddOption(
                Name        => $OptionDate,
                Description => $DescDate,
                Required    => 0,
                HasValue    => 1,
                ValueRegex  => qr/ ^ \d{4}-\d{2}-\d{2} (?: [ ] \d{2}:\d{2}:\d{2} )? $/x,
            );
            $Self->AddOption(
                Name        => $OptionDays,
                Description => $DescDays,
                Required    => 0,
                HasValue    => 1,
                ValueRegex  => qr/ ^ \d+ $ /x,
            );
        }
    }

    my $Name = $Self->Name();

    $Self->AdditionalHelp(<<"EOF");
The <green>$Name</green> command migrates article data from one storage backend to another on the fly, for example from DB to FS:
The <green>$Name</green> command migrates article data from one storage backend
to another on the fly, for example from DB to FS:

 <green>znuny.Console.pl $Self->{Name} --target ArticleStorageFS</green>

You can specify limits for the tickets migrated with <yellow>--tickets-closed-before-date</yellow> and <yellow>--tickets-closed-before-days</yellow>.
You can specify time limits for the tickets to migrate with the
<yellow>--tickets-created-*</yellow> and <yellow>--tickets-closed-*</yellow>
options above. An ISO datetime can be specified either in full as in
"2020-01-01 12:00:00" or with the time omitted, it will default to "00:00:00".

To reduce load on the database for a running system, you can use the <yellow>--micro-sleep</yellow> parameter. The command will pause for the specified amount of microseconds after each ticket.

 <green>znuny.Console.pl $Self->{Name} --target ArticleStorageFS --micro-sleep 1000</green>
To reduce load on the database for a running system, you can use the
<yellow>--micro-sleep</yellow> parameter. The command will pause for the
specified amount of microseconds after each ticket.
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

    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');

    # Disable ticket events
    $ConfigObject->Set(
        Key   => 'Ticket::EventModulePost',
        Value => {},
    );

    # Disable caching
    $ConfigObject->Set(
        Key   => 'Cache::ArticleStorageCache',
        Value => 0,
    );

    my %SearchParams;
    for my $CreateClose (qw( create close )) {
        BEFOREAFTER:
        for my $BeforeAfter (qw( before after )) {
            my $OptionDate = sprintf( 'tickets-%sd-%s-date', ${CreateClose}, ${BeforeAfter} );
            my $OptionDays = sprintf( 'tickets-%sd-%s-days', ${CreateClose}, $BeforeAfterOpts{$BeforeAfter}{Days} );
            my $ValueDate  = $Self->GetOption($OptionDate);
            my $ValueDays  = $Self->GetOption($OptionDays);
            my $DateTimeObject;
            if ($ValueDays) {
                if ($ValueDate) {
                    $Self->Print("<red>--$OptionDate and --$OptionDays are mutually exclusive!</red>\n");
                    return $Self->ExitCodeError();
                }
                $DateTimeObject = $Kernel::OM->Create('Kernel::System::DateTime');
                $DateTimeObject->Subtract( Days => $ValueDays );
            }
            elsif ($ValueDate) {
                $ValueDate .= ' 00:00:00' if length($ValueDate) == 10;
                $DateTimeObject = $Kernel::OM->Create(
                    'Kernel::System::DateTime',
                    ObjectParams => {
                        String => $ValueDate,
                    }
                );
                if ( !$DateTimeObject ) {
                    $Self->Print("<red>Could not parse datetime '$ValueDate'!</red>\n");
                    return $Self->ExitCodeError();
                }
            }
            else {
                next BEFOREAFTER;
            }
            my $SearchKey = sprintf(
                'Ticket%sTime%sDate',
                ucfirst($CreateClose),
                $BeforeAfterOpts{$BeforeAfter}{Search},
            );

            # Search only closed tickets if any tickets-closed-* arg was given
            $SearchParams{StateType} = 'Closed' if $CreateClose eq 'create';
            $SearchParams{$SearchKey} = $DateTimeObject->ToString();
        }
        my $OlderKey = sprintf( 'Ticket%sTimeOlderDate', ucfirst($CreateClose) );
        my $NewerKey = sprintf( 'Ticket%sTimeNewerDate', ucfirst($CreateClose) );
        if (
            $SearchParams{$OlderKey} &&
            $SearchParams{$NewerKey} &&
            $SearchParams{$OlderKey} le $SearchParams{$NewerKey}
            )
        {
            $Self->Print(
                "<red>Searching for tickets ${CreateClose}d before $SearchParams{$OlderKey} and after $SearchParams{$NewerKey}.\n"
                    .
                    "This will not find anything. Please check your time limit arguments!</red>\n"
            );
            return $Self->ExitCodeError();
        }
    }

    # If Archive system is enabled, take into account archived tickets as well.
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
