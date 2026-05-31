# --
# Copyright (C) 2021 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package scripts::Migration::Znuny::MigrateAdditionalTicketAttributeSelectionSettings;    ## no critic

use strict;
use warnings;
use utf8;

use parent qw(scripts::Migration::Base);

our @ObjectDependencies = (
    'Kernel::Config',
    'Kernel::System::SysConfig::Migration',
    'Kernel::System::Main',
    'Kernel::System::Package',
);

=head1 SYNOPSIS

Migrates additional ticket attribute selection settings.

These settings were added in Znuny 7.3 to allow for the selection of additional ticket attributes.

Priority was previously enabled by default but is now disabled by default.

This migration will enable the priority setting for the following views
- Forward
- Compose
- Phone Inbound
- Phone Outbound
- Email Inbound
- Email Outbound

=cut

=head2 _GetMigrateSysConfigSettings()

Returns the SysConfig settings to be migrated.

    my %MigrateSysConfigSettings = $MigrateToZnunyObject->_GetMigrateSysConfigSettings();

Returns:

    my %MigrateSysConfigSettings = ();

=cut

sub _GetMigrateSysConfigSettings {
    my ( $Self, %Param ) = @_;

    my %MigrateSysConfigSettings = (
        "Ticket::Frontend::AgentTicketForward###Priority" => {
            EffectiveValue => 1,
        },
        "Ticket::Frontend::AgentTicketCompose###Priority" => {
            EffectiveValue => 1,
        },
        "Ticket::Frontend::AgentTicketPhoneInbound###Priority" => {
            EffectiveValue => 1,
        },
        "Ticket::Frontend::AgentTicketPhoneOutbound###Priority" => {
            EffectiveValue => 1,
        },
        "Ticket::Frontend::AgentTicketEmailOutbound###Priority" => {
            EffectiveValue => 1,
        },
    );

    return %MigrateSysConfigSettings;
}

sub Run {
    my ( $Self, %Param ) = @_;

    my $SysConfigMigrationObject = $Kernel::OM->Get('Kernel::System::SysConfig::Migration');
    my $ConfigObject             = $Kernel::OM->Get('Kernel::Config');
    my $MainObject               = $Kernel::OM->Get('Kernel::System::Main');
    my $PackageObject            = $Kernel::OM->Get('Kernel::System::Package');

    my $PackageIsInstalled1 = $PackageObject->PackageIsInstalled(
        Name => 'Znuny4OTRS-AdditionalTicketAttributeSelection',
    );

    my $PackageIsInstalled2 = $PackageObject->PackageIsInstalled(
        Name => 'Znuny-AdditionalTicketAttributeSelection',
    );

    if ( !$PackageIsInstalled1 && !$PackageIsInstalled2 ) {
        print "\n\n Package Znuny(4OTRS)-AdditionalTicketAttributeSelection is not installed. Skipping migration.\n";
        return 1;
    }

    my $Home      = $ConfigObject->Get('Home');
    my $FileClass = 'Kernel::Config::Files::ZZZAAuto';
    my $FilePath  = "$Home/Kernel/Config/Backups/ZZZAAuto.pm";

    if ( !-f $FilePath ) {
        print "\n\n Error: ZZZAAuto backup file not found.\n";
        return;
    }

    my %MigrateSysConfigSettings = $Self->_GetMigrateSysConfigSettings();
    return 1 if !%MigrateSysConfigSettings;

    # Check if the settings are already migrated
    # Load the settings from the backup file
    my %ConfigBackup;
    $MainObject->Require($FileClass);
    $FileClass->Load( \%ConfigBackup );

    my %MigrateSysConfigSettingsToMigrate = %MigrateSysConfigSettings;
    for my $Setting ( sort keys %MigrateSysConfigSettings ) {

        # Frontend = Ticket::Frontend::AgentTicketForward
        # Attribute = Priority
        my ( $Frontend, $Attribute ) = split /###/, $Setting;

        # If the setting exists in the backup file and value exists
        # then the value can only be 0 (because the default value was previously 1) and we don't need to migrate.
        # If no value is available, we should migrate the setting with the previously default value of 1.

        if (
            $ConfigBackup{$Frontend}
            && $ConfigBackup{$Frontend}->{$Attribute}
            && $ConfigBackup{$Frontend}->{$Attribute} eq '0'
            )
        {
            delete $MigrateSysConfigSettingsToMigrate{$Setting};
        }
        else {
            $MigrateSysConfigSettingsToMigrate{$Setting} = $MigrateSysConfigSettings{$Setting};
        }
    }

    my $Success = $SysConfigMigrationObject->MigrateSysConfigSettings(
        FileClass => $FileClass,
        FilePath  => $FilePath,
        Data      => \%MigrateSysConfigSettingsToMigrate,
    );

    return 1;
}

1;
