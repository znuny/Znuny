# --
# Copyright (C) 2001-2021 OTRS AG, https://otrs.com/
# Copyright (C) 2021-2022 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see https://www.gnu.org/licenses/gpl-3.0.txt.
# --
## nofilter(TidyAll::Plugin::OTRS::Perl::Pod::NamePod)

package scripts::MigrateToZnuny6_3;    ## no critic

use strict;
use warnings;

use Time::HiRes ();
use Kernel::System::VariableCheck qw(IsHashRefWithData);

our @ObjectDependencies = (
    'Kernel::System::Main',
);

=head1 SYNOPSIS

Migrates Znuny 6.2 to Znuny 6.3.

=head1 PUBLIC INTERFACE

=head2 new()

Don't use the constructor directly, use the ObjectManager instead:

    my $MigrateToZnunyObject = $Kernel::OM->Get('scripts::MigrateToZnuny6_3');

=cut

sub new {
    my ( $Type, %Param ) = @_;

    my $Self = {};
    bless( $Self, $Type );

    return $Self;
}

sub Run {
    my ( $Self, %Param ) = @_;

    # Enable auto-flushing of STDOUT.
    $| = 1;    ## no critic

    # Enable timing feature in case it is call.
    my $TimingEnabled = $Param{CommandlineOptions}->{Timing} || 0;

    my $GeneralStartTime;
    if ($TimingEnabled) {
        $GeneralStartTime = Time::HiRes::time();
    }

    print "\n Migration started ... \n";

    my $SuccessfulMigration = 1;
    my @Components          = ( 'CheckPreviousRequirement', 'Run' );

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

    # Get the number of total steps.
    my $Steps               = scalar @Tasks;
    my $CurrentStep         = 1;
    my $SuccessfulMigration = 1;

    # Show initial message for current component
    if ( $Component eq 'Run' ) {
        print "\n Executing tasks ... \n\n";
    }
    else {
        print "\n Checking requirements ... \n\n";
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

        # Run module.
        $Kernel::OM->ObjectParamAdd(
            "$Task->{Module}" => {
                Opts => $Self->{Opts},
            },
        );

        $Self->{TaskObjects}->{$ModuleName} //= $Kernel::OM->Create($ModuleName);
        if ( !$Self->{TaskObjects}->{$ModuleName} ) {
            print "\n    Error: Could not create object for: $ModuleName.\n\n";
            $SuccessfulMigration = 0;
            last TASK;
        }

        my $Success = 1;

        # Execute Run-Component
        if ( $Component eq 'Run' ) {
            print "    Step $CurrentStep of $Steps: $Task->{Message} ...\n";
            $Success = $Self->{TaskObjects}->{$ModuleName}->$Component(%Param);
        }

        # Execute previous check, printing a different message
        elsif ( $Self->{TaskObjects}->{$ModuleName}->can($Component) ) {
            print "    Requirement check for: $Task->{Message} ...\n";
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

        $CurrentStep++;
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
            Message => 'Check required database version',
            Module  => 'scripts::Migration::Base::DatabaseVersionCheck',
        },
        {
            Message => 'Check database charset',
            Module  => 'scripts::Migration::Base::DatabaseCharsetCheck',
        },
        {
            Message => 'Check required Perl modules',
            Module  => 'scripts::Migration::Base::PerlModulesCheck',
        },
        {
            Message => 'Check installed CPAN modules for known vulnerabilities',
            Module  => 'scripts::Migration::Base::CPANAuditCheck',
        },
        {
            Message => 'Check if database has been backed up',
            Module  => 'scripts::Migration::Base::DatabaseBackupCheck',
        },

        # >>> Znuny 6.3
        {
            Message => 'Migrate dashboard widgets that execute system commands',
            Module  => 'scripts::Migration::Znuny6_3::MigrateDashboardWidgetSystemCommandCalls',
        },
        {
            Message => 'Migrate PostMaster pre-filters that execute system commands',
            Module  => 'scripts::Migration::Znuny6_3::MigratePostMasterPreFilterSystemCommandCalls',
        },
        {
            Message => 'Migrate Excel stats format definitions',
            Module  => 'scripts::Migration::Znuny6_3::MigrateExcelStatsFormatDefinitions',
        },
        {
            Message => 'Upgrade database structure',
            Module  => 'scripts::Migration::Znuny6_3::UpgradeDatabaseStructure',
        },
        {
            Message => 'Upgrade database structure for new scope attribute in ProcessManagement',
            Module  => 'scripts::Migration::Znuny6_3::MigrateProcessEntitesToScope',
        },
        {
            Message => 'Add history types',
            Module  => 'scripts::Migration::Znuny6_3::AddHistoryTypes',
        },
        {
            Message => 'Migrate SysConfig settings',
            Module  => 'scripts::Migration::Znuny6_3::MigrateSysConfigSettings',
        },
        {
            Message => 'Migrate OAuth2 token database tables',
            Module  => 'scripts::Migration::Znuny6_3::MigrateOAuth2TokenDatabaseTables',
        },
        {
            Message => 'Migrates calendar based ticket creation tables',
            Module  => 'scripts::Migration::Znuny6_3::MigrateCalendarBasedTicketCreationTables',
        },

        # This must be executed after newly integrated database backend tables have been created/updated!
        {
            Message => 'Migrate database backends',
            Module  => 'scripts::Migration::Znuny6_3::MigrateDatabaseBackends',
        },
        {
            Message => 'Migrates mail account database table',
            Module  => 'scripts::Migration::Znuny6_3::MigrateMailAccountDatabaseTable',
        },

        # <<< Znuny 6.3

        {
            Message => 'Rebuild configuration',
            Module  => 'scripts::Migration::Base::RebuildConfig',
        },

        # >>> Znuny 6.3
        # NOTE: RemoveGenericAgentSystemCommandCalls must only be executed after a config rebuild
        # has been done. Otherwise it could be that the ZZZ Perl config files have not been created yet.
        # This leads to initialization of Kernel::System::DynamicField::Backend failing
        # with missing SysConfig option 'DynamicFields::Driver' when creating Kernel::System::GenericAgent.
        # See GitLab issue #244.
        {
            Message => 'Remove Generic Agent system commands',
            Module  => 'scripts::Migration::Znuny6_3::RemoveGenericAgentSystemCommandCalls',
        },

        # NOTE: UninstallMergedPackages needs to be called only after
        # SysConfig settings of the merged packages have been migrated.
        {
            Message => 'Uninstall merged packages',
            Module  => 'scripts::Migration::Znuny6_3::UninstallMergedPackages',
        },

        # <<< Znuny 6.3

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

        # >>> Znuny 6.3
        {
            Message => 'ITSM upgrade check',
            Module  => 'scripts::Migration::Znuny6_3::ShowITSMUpgradeInstructions',
        },

        # <<< Znuny 6.3
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
