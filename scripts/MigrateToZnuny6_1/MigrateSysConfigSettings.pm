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

use parent qw(scripts::MigrateToZnuny6_1::Base);

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
    # Handle renamed SysConfig options.
    #
    my %RenamedSysConfigOptions = (

        # Znuny4OTRS-AdvancedGI
        'Znuny4OTRS::AdvancedGI::Invoker::Generic::PrepareRequest::Base64EncodedFields' =>
            ['GenericInterface::Invoker::Znuny::Generic::PrepareRequest::Base64EncodedFields'],
        'Znuny4OTRS::AdvancedGI::Invoker::Generic::PrepareRequest::OmittedFields' =>
            ['GenericInterface::Invoker::Znuny::Generic::PrepareRequest::OmittedFields'],

        # Znuny4OTRS-DynamicFieldWebservice
        'Znuny4OTRSDynamicFieldWebservice::HideDynamicFieldsWithoutDisplayedValue' =>
            ['Ticket::Frontend::AgentTicketZoom###HideWebserviceDynamicFieldsWithoutDisplayValue'],

        # Znuny4OTRS-AdvancedDynamicFields
        'Znuny4OTRSAdvancedDynamicFields::DynamicFieldValid' => [    # will be put into two new SysConfig options
            'DynamicFields::ScreenConfiguration::ShowOnlyValidDynamicFields',
            'DynamicFields::ImportExport::ShowOnlyValidDynamicFields',
        ],
        'DynamicFieldTypeScreens###Framework' =>
            ['DynamicFields::ScreenConfiguration::ConfigKeysOfScreensByObjectType###Framework'],
        'DynamicFieldNonRequiredScreens###Framework' =>
            ['DynamicFields::ScreenConfiguration::ConfigKeysOfScreensWithoutMandatoryDynamicFieldSupport###Framework'],

        # Znuny4OTRS-AdvancedOutOfOffice
        'AdvancedOutOfOffice::DisplayAgentOutOfOfficeMessage'
            => ['OutOfOffice::DisplayAgentOutOfOfficeMessage'],
        'AdvancedOutOfOffice::DisplayAgentLoggedInMessage'
            => ['OutOfOffice::DisplayAgentLoggedInMessage'],
        'AdvancedOutOfOffice::DisplayAgentLoggedOutMessage'
            => ['OutOfOffice::DisplayAgentLoggedOutMessage'],

        # Znuny4OTRS-LastViews
        'Znuny4OTRSLastViews'                                  => ['LastViews'],
        'PreferencesGroups###Znuny4OTRSLastViewsLimit'         => ['PreferencesGroups###LastViewsLimit'],
        'PreferencesGroups###Znuny4OTRSLastViewsPosition'      => ['PreferencesGroups###LastViewsPosition'],
        'PreferencesGroups###Znuny4OTRSLastViewsType'          => ['PreferencesGroups###LastViewsType'],
        'CustomerPreferencesGroups###Znuny4OTRSLastViewsLimit' => ['CustomerPreferencesGroups###LastViewsLimit'],
        'CustomerPreferencesGroups###Znuny4OTRSLastViewsType'  => ['CustomerPreferencesGroups###LastViewsType'],
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
