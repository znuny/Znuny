# --
# Copyright (C) 2021 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --
## nofilter(TidyAll::Plugin::OTRS::Perl::Pod::NamePod)

package scripts::MigrateToZnuny6_1::MigrateSysConfigSettings;    ## no critic

use strict;
use warnings;

use parent qw(scripts::DBUpdateTo6::Base);

our @ObjectDependencies = (
    'Kernel::Config',
);

=head1 NAME

Migrates SysConfig settings.

=cut

sub Run {
    my ( $Self, %Param ) = @_;

    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');

    #
    # Simple cases: Renamed SysConfig options.
    #
    my %RenamedSysConfigOptions = (

        # Znuny4OTRS-AdvancedGI
        'Znuny4OTRS::AdvancedGI::Invoker::Generic::PrepareRequest::Base64EncodedFields'
            => 'GenericInterface::Invoker::Znuny::Generic::PrepareRequest::Base64EncodedFields',
        'Znuny4OTRS::AdvancedGI::Invoker::Generic::PrepareRequest::OmittedFields'
            => 'GenericInterface::Invoker::Znuny::Generic::PrepareRequest::OmittedFields',
    );

    ORIGINALSYSCONFIGOPTIONNAME:
    for my $OriginalSysConfigOptionName ( sort keys %RenamedSysConfigOptions ) {
        my $NewSysConfigOptionName = $RenamedSysConfigOptions{$OriginalSysConfigOptionName};

        my $SysConfigOptionValue = $ConfigObject->Get($OriginalSysConfigOptionName);
        next ORIGINALSYSCONFIGOPTIONNAME if !defined $SysConfigOptionValue;

        my $SettingUpdated = $Self->SettingUpdate(
            Name           => $NewSysConfigOptionName,
            IsValid        => 1,
            EffectiveValue => $SysConfigOptionValue,
            UserID         => 1,
        );

        if ( !$SettingUpdated ) {
            print
                "\n    Error:Unable to migrate value of SysConfig option $OriginalSysConfigOptionName to option $NewSysConfigOptionName\n\n";
            next ORIGINALSYSCONFIGOPTIONNAME;
        }
    }

    return 1;
}

1;
