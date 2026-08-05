# --
# Copyright (C) 2001-2021 OTRS AG, https://otrs.com/
# Copyright (C) 2021 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see https://www.gnu.org/licenses/gpl-3.0.txt.
# --

## nofilter(TidyAll::Plugin::Znuny::Perl::PerlCritic)
package Kernel::System::Console::Command::Maint::Log::CommunicationLog;

use strict;
use warnings;

use parent qw(Kernel::System::Console::BaseCommand);

our @ObjectDependencies = (
    'Kernel::Config',
    'Kernel::System::DateTime',
    'Kernel::System::CommunicationLog::DB',
);

sub Configure {
    my ( $Self, %Param ) = @_;

    $Self->Description('Management of communication logs.');
    $Self->AddOption(
        Name        => 'force-delete',
        Description => "Delete even if still processing.",
        Required    => 0,
        HasValue    => 0,
    );
    $Self->AddOption(
        Name        => 'purge',
        Description =>
            'Purge successful communications older than a week and all communications older than a month. These durations are specified in SysConfig.',
        Required => 0,
        HasValue => 0,
    );
    $Self->AddOption(
        Name        => 'delete-by-hours-old',
        Description => 'Delete logs older than these number of hours. Example: --delete-by-hours-old=\'7\'',
        Required    => 0,
        HasValue    => 1,
        ValueRegex  => qr/^\d+$/smx,
    );
    $Self->AddOption(
        Name        => 'delete-by-date',
        Description => 'Delete from specific date. Example: --delete-by-date=\'2001-12-01\'',
        Required    => 0,
        HasValue    => 1,
        ValueRegex  => qr/^\d\d\d\d-\d\d-\d\d$/smx,
    );
    $Self->AddOption(
        Name        => 'delete-by-id',
        Description => 'Delete logs from CommunicationID. Example: --delete-by-id=\'abcdefg12345\'',
        Required    => 0,
        HasValue    => 1,
        ValueRegex  => qr/^.+$/smx,
    );
    $Self->AddOption(
        Name        => 'delete-by-status',
        Description =>
            'Delete logs by status. Possible values: Processing|Successful|Warning|Failed. Example: --delete-by-status=\'Processing\'',
        Required   => 0,
        HasValue   => 1,
        ValueRegex => qr/^\!{0,1}(?:Processing|Successful|Warning|Failed)$/smx,
    );
    $Self->AddOption(
        Name        => 'verbose',
        Description =>
            'Display debug information (can be used with --purge). Example: --purge --verbose',
        Required => 0,
        HasValue => 0,
    );

    return;
}

sub PreRun {
    my ( $Self, %Param ) = @_;

    my %Options;
    for my $Option (qw(delete-by-id delete-by-date delete-by-hours-old purge)) {
        $Options{$Option} = 1 if $Self->GetOption($Option);
    }

    if ( scalar keys %Options > 1 ) {
        $Self->Print( $Self->GetUsageHelp() );
        die "Only one type of action allowed per execution!\n";
    }

    if ( !%Options && !$Self->GetOption('delete-by-status') ) {
        $Self->Print( $Self->GetUsageHelp() );
        die
            "Either --purge, --delete-by-id, --delete-by-date, --delete-by-hours-old or --delete-by-status must be given!\n";
    }

    if ( $Options{'delete-by-status'} ) {
        my $Force = $Self->GetOption('force-delete');
        if ($Force) {
            $Self->Print( $Self->GetUsageHelp() );
            die "'force-delete' option is not allowed in combination with 'delete-by-status'!";
        }
        if ( $Options{'purge'} ) {
            $Self->Print( $Self->GetUsageHelp() );
            die "'purge' option is not allowed in combination with 'delete-by-status'!";
        }
    }

    return;
}

sub Run {
    my ( $Self, %Param ) = @_;

    my $Purge          = $Self->GetOption('purge');
    my $DeleteID       = $Self->GetOption('delete-by-id');
    my $DeleteDate     = $Self->GetOption('delete-by-date');
    my $DeleteHoursOld = $Self->GetOption('delete-by-hours-old');
    my $ForceDelete    = $Self->GetOption('force-delete');
    my $DeleteStatus   = $Self->GetOption('delete-by-status');

    my $Success = 0;

    if ($DeleteID) {
        $Success = $Self->Delete(
            ID     => $DeleteID,
            Force  => $ForceDelete,
            Status => $DeleteStatus,
        );
    }

    elsif ($DeleteDate) {
        $Success = $Self->Delete(
            Date   => $DeleteDate,
            Force  => $ForceDelete,
            Status => $DeleteStatus,
        );
    }

    elsif ($DeleteHoursOld) {
        $Success = $Self->Delete(
            HoursOld => $DeleteHoursOld,
            Force    => $ForceDelete,
            Status   => $DeleteStatus,
        );
    }

    elsif ($Purge) {
        $Success = $Self->Delete(
            Purge => 1,
        );
    }

    elsif ($DeleteStatus) {
        $Success = $Self->Delete(
            Status => $DeleteStatus,
        );
    }

    if ($Success) {
        $Self->Print("\n<green>Done.</green>\n");
        return $Self->ExitCodeOk();
    }

    $Self->PrintError("Failed.\n\n");
    return $Self->ExitCodeError();
}

sub Delete {
    my ( $Self, %Param ) = @_;

    my $Verbose               = $Self->GetOption('verbose');
    my $CommunicationLogDBObj = $Kernel::OM->Get('Kernel::System::CommunicationLog::DB');
    my $Result                = 1;

    # apply status based on force or delete-by-status parameter
    my $Status = !$Param{Force} && !$Param{Status} ? '!Processing' : $Param{Status};

    my $StatusMessage;
    if ($Status) {
        my $StatusValue;
        if ( substr( $Status, 0, 1 ) eq '!' ) {
            $StatusValue   = substr( $Status, 1, );
            $StatusMessage = "status different than $StatusValue";
        }
        else {
            $StatusValue   = $Status;
            $StatusMessage = "status $StatusValue";
        }
    }

    if ( $Param{ID} ) {

        my $Message = "Going to delete communication with ID '$Param{ID}'";
        $Message .= " and $StatusMessage" if $StatusMessage;
        $Message .= "!\n";

        $Self->Print($Message);

        $Result = $CommunicationLogDBObj->CommunicationDelete(
            CommunicationID => $Param{ID},
            Status          => $Status,
        );
    }
    elsif ( $Param{Date} ) {

        my $Message = "Going to delete all communications of date '$Param{Date}'";
        $Message .= " and $StatusMessage" if $StatusMessage;
        $Message .= "!\n";

        $Self->Print($Message);

        # delete all communications for the given date until now
        $Result = $CommunicationLogDBObj->CommunicationDelete(
            Date   => $Param{Date},
            Status => $Status,
        );
    }
    elsif ( $Param{HoursOld} ) {

        my $DateTimeObject = $Kernel::OM->Create('Kernel::System::DateTime');
        $DateTimeObject->Subtract( Hours => $Param{HoursOld} );
        my $OlderDate = $DateTimeObject->Format( Format => '%Y-%m-%d %H:%M:%S' );

        my $Message = "Going to delete all communications older than '${ OlderDate }'!\n";
        $Message .= " and $StatusMessage" if $StatusMessage;
        $Message .= "!\n";

        $Self->Print($Message);

        # delete all communications older than the given date
        $Result = $CommunicationLogDBObj->CommunicationDelete(
            OlderThan => $OlderDate,
            Status    => $Status,
        );
    }
    elsif ( $Param{Purge} ) {

        my $ConfigObj    = $Kernel::OM->Get('Kernel::Config');
        my $SuccessHours = $ConfigObj->Get('CommunicationLog::PurgeAfterHours::SuccessfulCommunications');
        my $AllHours     = $ConfigObj->Get('CommunicationLog::PurgeAfterHours::AllCommunications');

        my $DateTimeObject = $Kernel::OM->Create('Kernel::System::DateTime');

        my $SuccessDateObject = $DateTimeObject->Clone();
        $SuccessDateObject->Subtract( Hours => $SuccessHours );
        my $SuccessDate = $SuccessDateObject->Format( Format => '%Y-%m-%d %H:%M:%S' );

        $Self->Print("Going to delete all communications older than '${ SuccessDate }' with status 'Successful'!\n");

        $Result = $CommunicationLogDBObj->CommunicationDelete(
            OlderThan => $SuccessDate,
            Status    => 'Successful',
        );

        if ($Result) {
            $DateTimeObject->Subtract( Hours => $AllHours );
            my $AllHoursDate = $DateTimeObject->Format( Format => '%Y-%m-%d %H:%M:%S' );

            $Self->Print("Going to delete all communications older than '${ AllHoursDate }'!\n");
            $Result = $CommunicationLogDBObj->CommunicationDelete(
                OlderThan => $AllHoursDate,
            );
        }
    }
    elsif ( $Param{Status} ) {
        $Self->Print("Going to delete all communications with $StatusMessage!\n");

        # delete all communications with specifies status
        $Result = $CommunicationLogDBObj->CommunicationDelete(
            Status => $Status,
        );
    }

    if ( !$Result ) {
        $Self->PrintError("Could not delete communication(s)!\n");
    }

    return $Result;
}

1;
