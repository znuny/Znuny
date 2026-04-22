# --
# Copyright (C) 2001-2021 OTRS AG, https://otrs.com/
# Copyright (C) 2021 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see https://www.gnu.org/licenses/gpl-3.0.txt.
# --
## nofilter(TidyAll::Plugin::Znuny::Perl::Pod::NamePod)
## nofilter(TidyAll::Plugin::Znuny::Perl::ObjectManagerDirectCall)

package scripts::Migration;    ## no critic

use strict;
use warnings;
use utf8;

use Time::HiRes ();

our @ObjectDependencies = (
    'Kernel::System::Main',
    'Kernel::System::SysConfig',
);

=head1 SYNOPSIS

Migrates Znuny.

=head1 PUBLIC INTERFACE

=head2 new()

Don't use the constructor directly, use the ObjectManager instead:

    my $MigrateToZnunyObject = $Kernel::OM->Get('scripts::Migration');

=cut

sub new {
    my ( $Type, %Param ) = @_;

    my $Self = {};
    bless( $Self, $Type );

    return $Self;
}

sub Run {
    my ( $Self, %Param ) = @_;

    my $SysConfigObject = $Kernel::OM->Get('Kernel::System::SysConfig');

    # Enable auto-flushing of STDOUT.
    $| = 1;    ## no critic

    # Enable timing feature in case it is call.
    my $TimingEnabled = $Param{CommandlineOptions}->{Timing} || 0;

    my $GeneralStartTime;
    if ($TimingEnabled) {
        $GeneralStartTime = Time::HiRes::time();
    }

    print "\n Migration started ... \n";

    my $ZZZAAutoBackedUp = $SysConfigObject->CreateZZZAAutoBackup();
    if ( !$ZZZAAutoBackedUp ) {
        print "\n\nError backing up ZZZAAuto file.\n";
        return;
    }

    my $SuccessfulMigration = 1;
    my @Components          = ( 'CheckPreviousRequirement', 'Run', 'FollowUp' );

    COMPONENT:
    for my $Component (@Components) {
        $SuccessfulMigration = $Self->_ExecuteComponent(
            Component => $Component,
            %Param,
        );
        last COMPONENT if !$SuccessfulMigration;
    }

    if ($SuccessfulMigration) {
        print "\n\n\n Migration completed! \n\n";
    }
    else {
        print "\n\n\n Not possible to complete migration. Check previous messages for more information.\n\n";
    }

    if ($TimingEnabled) {
        my $GeneralStopTime      = Time::HiRes::time();
        my $GeneralExecutionTime = sprintf( "%.6f", $GeneralStopTime - $GeneralStartTime );
        print "    Migration took $GeneralExecutionTime seconds.\n\n";
    }

    $SysConfigObject->DeleteZZZAAutoBackup();

    return $SuccessfulMigration;
}

sub _ExecuteComponent {
    my ( $Self, %Param ) = @_;

    if ( !$Param{Component} ) {
        print " Error: Need Component!\n\n";
        return;
    }

    my $Component = $Param{Component};

    # Enable timing feature in case it is call.
    my $TimingEnabled = $Param{CommandlineOptions}->{Timing} || 0;

    # Get migration tasks.
    my @Tasks = $Self->_TasksGet();

    # Get the number of total steps by counting only tasks with Run function.
    my $Steps = 0;
    TASK:
    for my $Task (@Tasks) {
        next TASK if !$Task;
        next TASK if !$Task->{Module};

        my $ModuleName = "$Task->{Module}";

        # ObjectParamAdd
        $Kernel::OM->ObjectParamAdd(
            "$Task->{Module}" => {
                Opts => $Self->{Opts},
            },
        );

        $Self->{TaskObjects}->{$ModuleName} //= $Kernel::OM->Create($ModuleName);

        if ( $Self->{TaskObjects}->{$ModuleName} && $Self->{TaskObjects}->{$ModuleName}->can($Component) ) {
            $Steps++;
        }
    }

    my $CurrentStep         = 1;
    my $SuccessfulMigration = 1;

    # Show initial message for current component
    if ( $Steps && $Component eq 'CheckPreviousRequirement' ) {
        print "\n Checking requirements... \n\n";
    }
    elsif ( $Steps && $Component eq 'Run' ) {
        print "\n Executing tasks... \n\n";
    }
    elsif ( $Steps && $Component eq 'FollowUp' ) {
        print "\n Executing follow-up tasks... \n\n";
    }

    TASK:
    for my $Task (@Tasks) {

        next TASK if !$Task;
        next TASK if !$Task->{Module};

        my $ModuleName = "$Task->{Module}";
        if ( !$Kernel::OM->Get('Kernel::System::Main')->Require($ModuleName) ) {
            $SuccessfulMigration = 0;
            last TASK;
        }

        my $TaskStartTime;
        if ($TimingEnabled) {
            $TaskStartTime = Time::HiRes::time();
        }

        if ( !$Self->{TaskObjects}->{$ModuleName} ) {
            print "\n    Error: Could not create object for: $ModuleName.\n\n";
            $SuccessfulMigration = 0;
            last TASK;
        }

        my $Success = 1;

        # Execute Run-Component
        if ( $Self->{TaskObjects}->{$ModuleName}->can($Component) ) {
            print "    Step $CurrentStep of $Steps: $Task->{Message} ...\n";
            $Success = $Self->{TaskObjects}->{$ModuleName}->$Component(%Param);
        }

        # Do not handle timing if task has no appropriate component.
        else {
            next TASK;
        }

        if ($TimingEnabled) {
            my $StopTaskTime      = Time::HiRes::time();
            my $ExecutionTaskTime = sprintf( "%.6f", $StopTaskTime - $TaskStartTime );
            print "        Time taken for task \"$Task->{Message}\": $ExecutionTaskTime seconds\n\n";
        }

        if ( !$Success ) {
            $SuccessfulMigration = 0;
            last TASK;
        }

        # Only increment step counter if the component was actually executed
        if ( $Self->{TaskObjects}->{$ModuleName}->can($Component) ) {
            $CurrentStep++;
        }
    }

    return $SuccessfulMigration;
}

sub _TasksGet {
    my ( $Self, %Param ) = @_;

    my @Tasks = (

        # Base
        {
            Message => 'Check required Perl version',
            Module  => 'scripts::Migration::Base::PerlVersionCheck',
        },
        {
            Message => 'Check required Perl modules',
            Module  => 'scripts::Migration::Base::PerlModulesCheck',
        },
        {
            Message => 'Check if database has been backed up',
            Module  => 'scripts::Migration::Base::DatabaseBackupCheck',
        },
        {
            Message => 'Check required database version',
            Module  => 'scripts::Migration::Base::DatabaseVersionCheck',
        },
        {
            Message => 'Check database default storage engine',
            Module  => 'scripts::Migration::Base::DatabaseDefaultStorageEngineCheck',
        },

        # 7.3 specific tasks before database migration
        {
            Message => 'Phone state settings migration notice',
            Module  => 'scripts::Migration::Znuny::MigratePhoneStateSettings',
        },

        # Base
        {
            Message => 'Rebuild configuration',
            Module  => 'scripts::Migration::Base::RebuildConfig',
        },
        {
            Message => 'Upgrade database structure',
            Module  => 'scripts::Migration::Znuny::UpgradeDatabaseStructure',
        },
        {
            Message => 'Migrate database to utf8mb4',
            Module  => 'scripts::Migration::Znuny::MigrateUTF8MB4',
        },
        {
            Message => 'Check database charset',
            Module  => 'scripts::Migration::Base::DatabaseCharsetCheck',
        },

        # 7.3 specific tasks after database migration
        # ...to be added here...
        {
            Message => 'Additional ticket attribute selection settings migration',
            Module  => 'scripts::Migration::Znuny::MigrateAdditionalTicketAttributeSelectionSettings',
        },

        # Base tasks after database migration
        {
            Message => 'Migrate DBCRUD UUID columns',
            Module  => 'scripts::Migration::Znuny::MigrateDBCRUDUUIDColumns',
        },
        {
            Message => 'Migrate SysConfig settings',
            Module  => 'scripts::Migration::Znuny::MigrateSysConfigSettings',
        },

        # NOTE: UninstallMergedPackages has to be called only after
        # SysConfig settings of the merged packages have been migrated.
        {
            Message => 'Uninstall merged packages',
            Module  => 'scripts::Migration::Znuny::UninstallMergedPackages',
        },
        {
            Message => 'Remove mention flag from archived tickets.',
            Module  => 'scripts::Migration::Znuny::RemoveMentionFlagFromArchivedTickets',
        },

        # 7.3 specific tasks after SysConfig migration
        # ...to be added here...

        # Base tasks after SysConfig migration
        {
            Message => 'Initialize default cron jobs',
            Module  => 'scripts::Migration::Base::InitializeDefaultCronjobs',
        },
        {
            Message => 'Clean up the cache',
            Module  => 'scripts::Migration::Base::CacheCleanup',
        },
        {
            Message => 'Rebuild configuration another time',
            Module  => 'scripts::Migration::Base::RebuildConfigCleanup',
        },
        {
            Message => 'Deploy ACLs',
            Module  => 'scripts::Migration::Base::ACLDeploy',
        },
        {
            Message => 'Deploy processes',
            Module  => 'scripts::Migration::Base::ProcessDeploy',
        },
        {
            Message => 'Check invalid settings',
            Module  => 'scripts::Migration::Base::InvalidSettingsCheck',
        },
    );

    return @Tasks;
}

1;

=head1 TERMS AND CONDITIONS

This software is part of the OTRS project (L<https://otrs.org/>).

This software comes with ABSOLUTELY NO WARRANTY. For details, see
the enclosed file COPYING for license information (GPL). If you
did not receive this file, see L<https://www.gnu.org/licenses/gpl-3.0.txt>.

=cut
