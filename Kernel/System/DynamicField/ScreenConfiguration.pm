# --
# Copyright (C) 2021 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::DynamicField::ScreenConfiguration;

use strict;
use warnings;

use Kernel::System::VariableCheck qw(:all);

our @ObjectDependencies = (
    'Kernel::Config',
    'Kernel::System::DynamicField',
    'Kernel::System::Log',
    'Kernel::System::Package',
    'Kernel::System::ZnunyHelper',
);

=head1 NAME

Kernel::System::DynamicField::ScreenConfiguration

=head1 PUBLIC INTERFACE

=head2 new()

create an object. Do not use it directly, instead use:

    use Kernel::System::ObjectManager;
    local $Kernel::OM = Kernel::System::ObjectManager->new();
    my $DynamicFieldScreenConfigurationObject = $Kernel::OM->Get('Kernel::System::DynamicField::ScreenConfiguration');

=cut

sub new {
    my ( $Type, %Param ) = @_;

    my $Self = {};
    bless( $Self, $Type );

    return $Self;
}

=head2 GetDynamicFieldObjectTypes()

Returns all possible dynamic field object types.

    my @DynamicFieldObjectTypes = $DynamicFieldScreenConfigurationObject->GetDynamicFieldObjectTypes(
        Screen => 'Ticket::Frontend::AgentTicketMove###DynamicField'        # optional, returns object types only for this screen
    );

Returns:

    my @DynamicFieldObjectTypes = (
        'Ticket',
        'Article',
    );

=cut

sub GetDynamicFieldObjectTypes {
    my ( $Self, %Param ) = @_;

    my $ConfigObject  = $Kernel::OM->Get('Kernel::Config');
    my $PackageObject = $Kernel::OM->Get('Kernel::System::Package');

    my $ConfigKeysOfScreensByObjectType
        = $ConfigObject->Get('DynamicFields::ScreenConfiguration::ConfigKeysOfScreensByObjectType');

    my %DynamicFieldObjectTypes;
    REGISTRATION:
    for my $Registration ( sort keys %{$ConfigKeysOfScreensByObjectType} ) {
        if ( $Registration =~ m{\AITSM} ) {
            my $IsInstalled = $PackageObject->PackageIsInstalled(
                Name => $Registration,
            );
            next REGISTRATION if !$IsInstalled;
        }

        my %Registration = %{ $ConfigKeysOfScreensByObjectType->{$Registration} };
        OBJECTTYPE:
        for my $ObjectType ( sort keys %Registration ) {
            next OBJECTTYPE if !IsHashRefWithData( $Registration{$ObjectType} );

            if ( $Param{Screen} ) {
                next OBJECTTYPE if !$Registration{$ObjectType}->{ $Param{Screen} };
            }
            $DynamicFieldObjectTypes{$ObjectType} = $Registration{$ObjectType};
        }
    }

    my @DynamicFieldObjectTypes = sort keys %DynamicFieldObjectTypes;

    return @DynamicFieldObjectTypes;
}

=head2 GetConfigKeysOfScreensByObjectType()

Returns all possible dynamic field screens of given object type.

    my %DynamicFieldScreenConfigKeys = $DynamicFieldScreenConfigurationObject->GetConfigKeysOfScreensByObjectType(
        ObjectType => 'Ticket',
        Screens    => \%Screens        # optional -  return these screens but only with the correct ObjectType
    );

Returns:

    my %DynamicFieldScreenConfigKeys = (
        'Ticket::Frontend::AgentTicketPrint###DynamicField' => 'AgentTicketPrint',
        'Ticket::Frontend::AgentTicketZoom###DynamicField'  => 'AgentTicketZoom',
    );

=cut

sub GetConfigKeysOfScreensByObjectType {
    my ( $Self, %Param ) = @_;

    my $LogObject     = $Kernel::OM->Get('Kernel::System::Log');
    my $ConfigObject  = $Kernel::OM->Get('Kernel::Config');
    my $PackageObject = $Kernel::OM->Get('Kernel::System::Package');

    NEEDED:
    for my $Needed (qw(ObjectType)) {
        next NEEDED if defined $Param{$Needed};

        $LogObject->Log(
            Priority => 'error',
            Message  => "Parameter '$Needed' is needed in !",
        );
        return;
    }

    my $ConfigKeysOfScreensByObjectType
        = $ConfigObject->Get('DynamicFields::ScreenConfiguration::ConfigKeysOfScreensByObjectType')
        // {};
    my %ConfigKeysOfScreensByObjectType;

    REGISTRATION:
    for my $Registration ( sort keys %{$ConfigKeysOfScreensByObjectType} ) {
        if ( $Registration =~ m{^ITSM.*}xmsi ) {
            my $IsInstalled = $PackageObject->PackageIsInstalled(
                Name => $Registration,
            );
            next REGISTRATION if !$IsInstalled;
        }

        my %Registration = %{ $ConfigKeysOfScreensByObjectType->{$Registration} };
        for my $ObjectType ( sort keys %Registration ) {
            $ConfigKeysOfScreensByObjectType{$ObjectType} ||= {};

            %{ $ConfigKeysOfScreensByObjectType{$ObjectType} } = (
                %{ $ConfigKeysOfScreensByObjectType{$ObjectType} },
                %{ $Registration{$ObjectType} },
            );
        }
    }

    my %ScreenConfigKeysOfDynamicFieldForObjectType = %{ $ConfigKeysOfScreensByObjectType{ $Param{ObjectType} } };
    return %ScreenConfigKeysOfDynamicFieldForObjectType if !IsHashRefWithData( $Param{Screens} );

    my %ScreenConfigKeysForSelectedScreens;
    SCREEN:
    for my $Screen ( sort keys %{ $Param{Screens} } ) {
        next SCREEN if !$ScreenConfigKeysOfDynamicFieldForObjectType{$Screen};
        $ScreenConfigKeysForSelectedScreens{$Screen} = $ScreenConfigKeysOfDynamicFieldForObjectType{$Screen};
    }

    return %ScreenConfigKeysForSelectedScreens;
}

=head2 GetConfigKeysOfScreensWithoutMandatoryDynamicFieldSupport()

Returns a list of screen config keys for which dynamic fields cannot be configured as mandatory.
Example: 'Ticket::Frontend::AgentTicketZoom###DynamicField' has no option '2' (mandatory)

    my $ConfigKeysOfScreensWithoutMandatoryDynamicFieldSupport = $DynamicFieldScreenConfigurationObject->GetConfigKeysOfScreensWithoutMandatoryDynamicFieldSupport(
        Result => 'ARRAY',              # HASH or ARRAY, defaults to ARRAY
    );

Result as hash:

    my $ConfigKeysOfScreensWithoutMandatoryDynamicFieldSupport = {
       'Ticket::Frontend::AgentTicketZoom###DynamicField'              => 'AgentTicketZoom',
       'Ticket::Frontend::AgentTicketZoom###ProcessWidgetDynamicField' => 'ProcessWidgetDynamicField'
       # [...]
    };

Result as array:

    my $ConfigKeysOfScreensWithoutMandatoryDynamicFieldSupport = [
       'Ticket::Frontend::AgentTicketZoom###DynamicField',
       'Ticket::Frontend::AgentTicketZoom###ProcessWidgetDynamicField',
       # [...]
    ];

=cut

sub GetConfigKeysOfScreensWithoutMandatoryDynamicFieldSupport {
    my ( $Self, %Param ) = @_;

    my $ConfigObject  = $Kernel::OM->Get('Kernel::Config');
    my $PackageObject = $Kernel::OM->Get('Kernel::System::Package');

    $Param{Result} = lc( $Param{Result} // 'array' );

    my $ConfigKeysOfScreensWithoutMandatoryDynamicFieldSupport = $ConfigObject->Get(
        'DynamicFields::ScreenConfiguration::ConfigKeysOfScreensWithoutMandatoryDynamicFieldSupport'
    ) // {};

    my %Configs;

    REGISTRATION:
    for my $Registration ( sort keys %{$ConfigKeysOfScreensWithoutMandatoryDynamicFieldSupport} ) {
        if ( $Registration =~ m{^ITSM.*}xmsi ) {
            my $IsInstalled = $PackageObject->PackageIsInstalled(
                Name => $Registration,
            );
            next REGISTRATION if !$IsInstalled;
        }

        %Configs = (
            %Configs,
            %{ $ConfigKeysOfScreensWithoutMandatoryDynamicFieldSupport->{$Registration} },
        );
    }

    # check if config is already valid / defined
    for my $CurrentConfig ( sort keys %Configs ) {
        my ( $ConfigPath, $Key ) = split '###', $CurrentConfig;
        my $ConfigData = $ConfigObject->Get($ConfigPath);

        delete $Configs{$CurrentConfig} if !defined $ConfigData->{$Key};
    }

    return \%Configs if lc $Param{Result} ne 'array';

    my @Configs = sort keys %Configs;

    return \@Configs;
}

=head2 ValidateDynamicFieldActivation()

Validates the activation (0, 1, 2) for dynamic fields, so that setting 2 (mandatory) will be
corrected to 1 for screens which don't allow dynamic fields to be mandatory.

    my %NewConfig = $DynamicFieldScreenConfigurationObject->ValidateDynamicFieldActivation(
        Element    => $Element,
        Config     => \%Config,
        ObjectType => 'Ticket',         # optional; limits to given object types; can be array.
    );

    my %NewConfig = $DynamicFieldScreenConfigurationObject->ValidateDynamicFieldActivation(
        Element => $Element,
        Config  => {
            'Ticket::Frontend::AgentTicketNote###DynamicField' => 2,
            'Ticket::Frontend::AgentTicketZoom###DynamicField' => 2,
        }
    );

Returns:

    my %NewConfig = (
        'Ticket::Frontend::AgentTicketNote###DynamicField' => 2,
        'Ticket::Frontend::AgentTicketZoom###DynamicField' => 1,
    );

=cut

sub ValidateDynamicFieldActivation {
    my ( $Self, %Param ) = @_;

    my $LogObject          = $Kernel::OM->Get('Kernel::System::Log');
    my $ZnunyHelperObject  = $Kernel::OM->Get('Kernel::System::ZnunyHelper');
    my $ConfigObject       = $Kernel::OM->Get('Kernel::Config');
    my $DynamicFieldObject = $Kernel::OM->Get('Kernel::System::DynamicField');

    NEEDED:
    for my $Needed (qw(Element Config)) {
        next NEEDED if defined $Param{$Needed};

        $LogObject->Log(
            Priority => 'error',
            Message  => "Parameter '$Needed' is needed in !",
        );
        return;
    }

    my @ConfigKeysOfScreensWithoutMandatoryDynamicFieldSupport = @{
        $Self->GetConfigKeysOfScreensWithoutMandatoryDynamicFieldSupport(
            Result => 'ARRAY',
        )
    };

    my %NewConfig = %{ $Param{Config} };

    my $ValidDynamicFieldScreens = $ZnunyHelperObject->_ValidDynamicFieldScreenListGet(
        Result => 'ARRAY',
    );

    my $ElementType;
    for my $ValidDynamicFieldScreenType ( sort keys %{$ValidDynamicFieldScreens} ) {
        my @ValidDynamicFieldScreens = @{ $ValidDynamicFieldScreens->{$ValidDynamicFieldScreenType} };

        my $ElementIsScreen = grep { $Param{Element} eq $_ } @ValidDynamicFieldScreens;
        if ($ElementIsScreen) {
            $ElementType = 'Screen';
        }
    }

    my $ShowOnlyValidDynamicFields
        = $ConfigObject->Get('DynamicFields::ScreenConfiguration::ShowOnlyValidDynamicFields');

    my $DynamicFieldObjectTypes = $Param{ObjectType};
    if ( !defined $DynamicFieldObjectTypes ) {
        @{$DynamicFieldObjectTypes} = $Self->GetDynamicFieldObjectTypes();
    }

    my $DynamicFieldConfigs = $DynamicFieldObject->DynamicFieldListGet(
        ResultType => 'HASH',
        Valid      => $ShowOnlyValidDynamicFields,
        ObjectType => $DynamicFieldObjectTypes,
    );

    my %DynamicFields;

    DYNAMICFIELDCONFIG:
    for my $DynamicFieldConfig ( @{$DynamicFieldConfigs} ) {
        next DYNAMICFIELDCONFIG if !IsHashRefWithData($DynamicFieldConfig);

        $DynamicFields{ $DynamicFieldConfig->{Name} } = $DynamicFieldConfig->{Label};
    }

    if ( $DynamicFields{ $Param{Element} } ) {
        $ElementType = 'DynamicField';
    }

    return %NewConfig if !$ElementType;

    if ( $ElementType eq 'Screen' ) {
        my $DynamicFieldsRequirable
            = grep { $Param{Element} eq $_ } @ConfigKeysOfScreensWithoutMandatoryDynamicFieldSupport;
        return %NewConfig if !$DynamicFieldsRequirable;

        my %ChangedConfig = map { $_ => 1 }
            grep { defined $Param{Config}->{$_} && $Param{Config}->{$_} == 2 }
            sort keys %{ $Param{Config} };

        %NewConfig = (
            %{ $Param{Config} },
            %ChangedConfig,
        );
        return %NewConfig;
    }

    if ( $ElementType eq 'DynamicField' ) {
        my %ChangedConfig;

        SCREEN:
        for my $Screen ( sort keys %{ $Param{Config} } ) {
            my $DynamicFieldsRequirable
                = grep { $Screen eq $_ } @ConfigKeysOfScreensWithoutMandatoryDynamicFieldSupport;
            next SCREEN if !$DynamicFieldsRequirable;

            next SCREEN if !defined $Param{Config}->{$Screen} || $Param{Config}->{$Screen} != 2;
            $ChangedConfig{$Screen} = 1;
        }

        %NewConfig = (
            %{ $Param{Config} },
            %ChangedConfig,
        );
        return %NewConfig;
    }

    return %NewConfig;
}

1;
