# --
# Copyright (C) 2021-2022 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --
## nofilter(TidyAll::Plugin::OTRS::Perl::Pod::NamePod)

package scripts::Migration::Znuny6_3::MigrateSysConfigSettings;    ## no critic

use strict;
use warnings;

use parent qw(scripts::Migration::Base);

our @ObjectDependencies = (
    'Kernel::Config',
);

=head1 SYNOPSIS

Migrates SysConfig settings.

=cut

sub Run {
    my ( $Self, %Param ) = @_;

    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');

    #
    # Handle renamed SysConfig options.
    #
    my %RenamedSysConfigOptions = (

        # Znuny(4OTRS)-DatabaseBackend
        'Znuny4OTRSDatabaseBackend###Export###DefaultFormat' => [
            'DBCRUD###Export###DefaultFormat',
        ],
        'Znuny4OTRSDatabaseBackend###Export###CSV###Separator' => [
            'DBCRUD###Export###CSV###Separator',
        ],
        'Znuny4OTRSDatabaseBackend###Export###CSV###Quote"' => [
            'DBCRUD###Export###CSV###Quote',
        ],
        'ZnunyDatabaseBackend###Export###DefaultFormat' => [
            'DBCRUD###Export###DefaultFormat',
        ],
        'ZnunyDatabaseBackend###Export###CSV###Separator' => [
            'DBCRUD###Export###CSV###Separator',
        ],
        'ZnunyDatabaseBackend###Export###CSV###Quote"' => [
            'DBCRUD###Export###CSV###Quote',
        ],

        # Znuny(4OTRS)-OwnerToolbar
        'Frontend::Module###AgentTicketOwnerView' => [
            'Frontend::Module###AgentTicketOwnerView',
        ],
        'Loader::Module::AgentTicketOwnerView###002-Znuny4OTRSOwnerToolbar' => [
            'Loader::Module::AgentTicketOwnerView###002-Ticket',
        ],
        'Frontend::Navigation###AgentTicketOwnerView###002-Znuny4OTRSOwnerToolbar' => [
            'Frontend::Navigation###AgentTicketOwnerView###002-Ticket',
        ],
        'Ticket::Frontend::AgentTicketOwnerView###SortBy::Default' => [
            'Ticket::Frontend::AgentTicketOwnerView###SortBy::Default',
        ],
        'Ticket::Frontend::AgentTicketOwnerView###Order::Default' => [
            'Ticket::Frontend::AgentTicketOwnerView###Order::Default',
        ],
        'Frontend::ToolBarModule###9-Ticket::TicketOwner' => [
            'Frontend::ToolBarModule###191-Ticket::TicketOwner',
        ],
    );

    ORIGINALSYSCONFIGOPTIONNAME:
    for my $OriginalSysConfigOptionName ( sort keys %RenamedSysConfigOptions ) {

        # Fetch original SysConfig option value.
        my ( $OriginalSysConfigOptionBaseName, @OriginalSysConfigOptionHashKeys ) = split '###',
            $OriginalSysConfigOptionName;

        my $OriginalSysConfigOptionValue = $ConfigObject->Get($OriginalSysConfigOptionBaseName);
        next ORIGINALSYSCONFIGOPTIONNAME if !defined $OriginalSysConfigOptionValue;

        if (@OriginalSysConfigOptionHashKeys) {
            for my $OriginalSysConfigOptionHashKey (@OriginalSysConfigOptionHashKeys) {
                next ORIGINALSYSCONFIGOPTIONNAME if ref $OriginalSysConfigOptionValue ne 'HASH';
                next ORIGINALSYSCONFIGOPTIONNAME
                    if !exists $OriginalSysConfigOptionValue->{$OriginalSysConfigOptionHashKey};

                $OriginalSysConfigOptionValue = $OriginalSysConfigOptionValue->{$OriginalSysConfigOptionHashKey};
            }
        }
        next ORIGINALSYSCONFIGOPTIONNAME if !defined $OriginalSysConfigOptionValue;

        my $NewSysConfigOptionNames = $RenamedSysConfigOptions{$OriginalSysConfigOptionName};
        for my $NewSysConfigOptionName ( @{$NewSysConfigOptionNames} ) {
            my $SettingUpdated = $Self->SettingUpdate(
                Name           => $NewSysConfigOptionName,
                IsValid        => 1,
                EffectiveValue => $OriginalSysConfigOptionValue,
                UserID         => 1,
            );

            if ( !$SettingUpdated ) {
                print
                    "\n    Error:Unable to migrate value of SysConfig option $OriginalSysConfigOptionName to option $NewSysConfigOptionName\n\n";
                next ORIGINALSYSCONFIGOPTIONNAME;
            }
        }
    }

    return 1;
}

1;
