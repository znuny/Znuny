# --
# Copyright (C) 2021 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::GenericInterface::Mapping::Znuny;

use strict;
use warnings;

use Kernel::System::VariableCheck qw(:all);

our $ObjectManagerDisabled = 1;

=head1 NAME

Kernel::GenericInterface::Mapping::Znuny - GenericInterface Znuny data mapping backend

=head1 SYNOPSIS

Advanced mapping functionalities.

=head1 PUBLIC INTERFACE

=head2 new()

usually, you want to create an instance of this
by using Kernel::GenericInterface::Mapping->new();

=cut

sub new {
    my ( $Type, %Param ) = @_;

    my $Self = {};
    bless( $Self, $Type );

    for my $Needed (qw(DebuggerObject MappingConfig)) {
        if ( !$Param{$Needed} ) {
            return {
                Success      => 0,
                ErrorMessage => "Got no $Needed!"
            };
        }
        $Self->{$Needed} = $Param{$Needed};
    }

    # check mapping config
    if ( !IsHashRefWithData( $Param{MappingConfig} ) ) {
        return $Self->{DebuggerObject}->Error(
            Summary => 'Got no MappingConfig as hash ref with content!',
        );
    }

    # check config - if we have a map config, it has to be a non-empty hash ref
    if (
        defined $Param{MappingConfig}->{Config}
        && !IsHashRefWithData( $Param{MappingConfig}->{Config} )
        )
    {
        return $Self->{DebuggerObject}->Error(
            Summary => 'Got MappingConfig with Data, but Data is no hash ref with content!',
        );
    }

    # check configuration
    my $ConfigCheck = $Self->_ConfigCheck( Config => $Self->{MappingConfig}->{Config} );
    return $ConfigCheck if !$ConfigCheck->{Success};

    return $Self;
}

=head2 Map()

provides 1:1 and regex mapping for keys and values
also the use of a default for untapped keys and values is possible

we need the config to be in the following format

    $Self->{MappingConfig}->{Config} = {
        KeyMapExact => {           # optional. key/value pairs for direct replacement
            'old_value'         => 'new_value',
            'another_old_value' => 'another_new_value',
            'maps_to_same_value => 'another_new_value',
        },
        KeyMapRegEx => {           # optional. replace keys with value if current key matches regex
            'Stat(e|us)'  => 'state',
            '[pP]riority' => 'prio',
        },
        KeyMapDefault => {         # required. replace keys if the have not been replaced before
            MapType => 'Keep',     # possible values are
                                   # 'Keep' (leave unchanged)
                                   # 'Ignore' (drop key/value pair)
                                   # 'MapTo' (use provided value as default)
            MapTo => 'new_value',  # only used if 'MapType' is 'MapTo'. then required
        },
        ValueMap => {
            'new_key_name' => {    # optional. Replacement for a specific key
                ValueMapExact => { # optional. key/value pairs for direct replacement
                    'old_value'         => 'new_value',
                    'another_old_value' => 'another_new_value',
                    'maps_to_same_value => 'another_new_value',
                },
                ValueMapRegEx => { # optional. replace keys with value if current key matches regex
                    'Stat(e|us)'  => 'state',
                    '[pP]riority' => 'prio',
                },
            },
        },
        ValueMapDefault => {       # required. replace keys if the have not been replaced before
            MapType => 'Keep',     # possible values are
                                   # 'Keep' (leave unchanged)
                                   # 'Ignore' (drop key/value pair)
                                   # 'MapTo' (use provided value as default)
            MapTo => 'new_value',  # only used if 'MapType' is 'MapTo'. then required
        },
    };

    my $ReturnData = $MappingObject->Map(
        Data => {
            'original_key' => 'original_value',
            'another_key'  => 'next_value',
        },
    );

    my $ReturnData = {
        'changed_key'          => 'changed_value',
        'original_key'         => 'another_changed_value',
        'another_original_key' => 'default_value',
        'default_key'          => 'changed_value',
    };

=cut

sub Map {
    my ( $Self, %Param ) = @_;

    my $ReturnSingleHash;
    my @RawHashRefs;
    if ( IsArrayRefWithData( $Param{Data} ) ) {

        HASH:
        for my $CurrentArrayElement ( @{ $Param{Data} } ) {

            next HASH if !IsHashRefWithData($CurrentArrayElement);

            push @RawHashRefs, $CurrentArrayElement;
        }
    }
    elsif ( IsHashRefWithData( $Param{Data} ) ) {
        push @RawHashRefs, $Param{Data};
        $ReturnSingleHash = 1;
    }

    # return if data is empty
    if ( !scalar @RawHashRefs ) {
        return {
            Success => 1,
            Data    => {},
        };
    }

    # prepare short config variable
    my $Config = $Self->{MappingConfig}->{Config};

    # no config means we just return input data
    if ( !$Config ) {

        my $ReturnValue;
        if ($ReturnSingleHash) {
            $ReturnValue = $Param{Data};
        }
        else {
            $ReturnValue = \@RawHashRefs;
        }

        return {
            Success => 1,
            Data    => $ReturnValue,
        };
    }

    my @MappedHashRefs;
    for my $RawHashRef (@RawHashRefs) {

        # pass the data to the recursive mapping process
        my %ReturnData = $Self->_MapRecursive(
            Data   => $RawHashRef,
            Config => $Config,
        );

        if ( IsHashRefWithData( $Config->{StaticValue} ) ) {
            @ReturnData{ keys %{ $Config->{StaticValue} } } = values %{ $Config->{StaticValue} };
        }

        if ($ReturnSingleHash) {
            return {
                Success => 1,
                Data    => \%ReturnData,
            };
        }

        push @MappedHashRefs, \%ReturnData;
    }

    return {
        Success => 1,
        Data    => \@MappedHashRefs,
    };
}

=head2 _ConfigCheck()

does checks to make sure the config is sane

    my $Return = $MappingObject->_ConfigCheck(
        Config => { # config as defined for Map
            ...
        },
    );

in case of an error

    $Return => {
        Success      => 0,
        ErrorMessage => 'An error occurred',
    };

in case of a success

    $Return = {
        Success => 1,
    };

=cut

sub _ConfigCheck {
    my ( $Self, %Param ) = @_;

    # just return success if config is undefined or empty hashref
    my $Config = $Param{Config};
    if ( !defined $Config ) {
        return {
            Success => 1,
        };
    }
    if ( ref $Config ne 'HASH' ) {
        return $Self->{DebuggerObject}->Error(
            Summary => 'Config is defined but not a hash reference!',
        );
    }
    if ( !IsHashRefWithData($Config) ) {
        return {
            Success => 1,
        };
    }

    # parse config options for validity
    my %OnlyStringConfigTypes = (
        KeyMapExact     => 1,
        KeyMapRegEx     => 1,
        KeyMapDefault   => 1,
        ValueMapDefault => 1,
    );
    my %RequiredConfigTypes = (
        KeyMapDefault   => 1,
        ValueMapDefault => 1,
    );
    CONFIGTYPE:
    for my $ConfigType (qw(KeyMapExact KeyMapRegEx KeyMapDefault ValueMap ValueMapDefault)) {

        # require some types
        if ( !defined $Config->{$ConfigType} ) {
            next CONFIGTYPE if !$RequiredConfigTypes{$ConfigType};
            return $Self->{DebuggerObject}->Error(
                Summary => "Got no $ConfigType, but it is required!",
            );
        }

        if (
            ref $Config->{$ConfigType} eq 'HASH'
            && !IsHashRefWithData( $Config->{$ConfigType} )
            )
        {
            next CONFIGTYPE;
        }

        # check type definition
        if ( !IsHashRefWithData( $Config->{$ConfigType} ) ) {
            return $Self->{DebuggerObject}->Error(
                Summary => "Got $ConfigType with Data, but Data is no hash ref with content!",
            );
        }

        # check keys and values of these config types
        next CONFIGTYPE if !$OnlyStringConfigTypes{$ConfigType};
        for my $ConfigKey ( sort keys %{ $Config->{$ConfigType} } ) {
            if ( !IsString($ConfigKey) ) {
                return $Self->{DebuggerObject}->Error(
                    Summary => "Got key in $ConfigType which is not a string!",
                );
            }
            if ( !IsString( $Config->{$ConfigType}->{$ConfigKey} ) ) {
                return $Self->{DebuggerObject}->Error(
                    Summary => "Got value for $ConfigKey in $ConfigType which is not a string!",
                );
            }
        }
    }

    # check default configuration in KeyMapDefault and ValueMapDefault
    my %ValidMapTypes = (
        Keep   => 1,
        Ignore => 1,
        MapTo  => 1,
    );
    CONFIGTYPE:
    for my $ConfigType (qw(KeyMapDefault ValueMapDefault)) {

        # require MapType as a string with a valid value
        if (
            !IsStringWithData( $Config->{$ConfigType}->{MapType} )
            || !$ValidMapTypes{ $Config->{$ConfigType}->{MapType} }
            )
        {
            return $Self->{DebuggerObject}->Error(
                Summary => "Got no valid MapType in $ConfigType!",
            );
        }

        # check MapTo if MapType is set to 'MapTo'
        next CONFIGTYPE if $Config->{$ConfigType}->{MapType} ne 'MapTo';
        next CONFIGTYPE if IsStringWithData( $Config->{$ConfigType}->{MapTo} );

        return $Self->{DebuggerObject}->Error(
            Summary => "Got MapType 'MapTo', but MapTo value is not valid in $ConfigType!",
        );
    }

    # check ValueMap
    for my $KeyName ( sort keys %{ $Config->{ValueMap} } ) {

        # require values to be hash ref
        if ( !IsHashRefWithData( $Config->{ValueMap}->{$KeyName} ) ) {
            return $Self->{DebuggerObject}->Error(
                Summary => "Got $KeyName in ValueMap, but it is no hash ref with content!",
            );
        }

        # possible subvalues are ValueMapExact or ValueMapRegEx and need to be hash ref if defined
        SUBKEY:
        for my $SubKeyName (qw(ValueMapExact ValueMapRegEx)) {
            my $ValueMapType = $Config->{ValueMap}->{$KeyName}->{$SubKeyName};
            next SUBKEY if !defined $ValueMapType;
            if ( !IsHashRefWithData($ValueMapType) ) {
                return $Self->{DebuggerObject}->Error(
                    Summary =>
                        "Got $SubKeyName in $KeyName in ValueMap,"
                        . ' but it is no hash ref with content!',
                );
            }

            # key/value pairs of ValueMapExact and ValueMapRegEx must be strings
            SUBVALUEMAPTYPEKEY:
            for my $ValueMapTypeKey ( sort keys %{$ValueMapType} ) {
                if ( !IsString($ValueMapTypeKey) ) {
                    return $Self->{DebuggerObject}->Error(
                        Summary =>
                            "Got key in $SubKeyName in $KeyName in ValueMap which is not a string!",
                    );
                }

                next SUBVALUEMAPTYPEKEY if IsString( $ValueMapType->{$ValueMapTypeKey} );

                return $Self->{DebuggerObject}->Error(
                    Summary =>
                        "Got value for $ValueMapTypeKey in $SubKeyName in $KeyName in ValueMap"
                        . ' which is not a string!',
                );
            }
        }
    }

    # if we arrive here, all checks were ok
    return {
        Success => 1,
    };
}

sub _MapRecursive {
    my ( $Self, %Param ) = @_;

    my %ReturnData;
    CONFIGKEY:
    for my $OldKey ( sort keys %{ $Param{Data} } ) {

        # check if key is valid
        if ( !IsStringWithData($OldKey) ) {

            $Self->{DebuggerObject}->Notice(
                Summary => 'Got an original key that is not valid!',
            );
            next CONFIGKEY;
        }

        next CONFIGKEY if !defined $Param{Data}->{$OldKey};

        # check if we got an array ref with some hash refs in it
        if ( IsArrayRefWithData( $Param{Data}->{$OldKey} ) ) {

            my @MappedArrayData;
            for my $CurrentArrayElement ( @{ $Param{Data}->{$OldKey} } ) {

                # check if we got an HashRef
                # if so pass it to the next recursive mapping stage
                if ( IsHashRefWithData($CurrentArrayElement) ) {

                    # parse config for sub-entries
                    my %Config;
                    if ( IsHashRefWithData( $Param{Config}->{KeyMapExact} ) ) {

                        CONFIGKEY:
                        for my $ConfigKey ( sort keys %{ $Param{Config} } ) {

                            next CONFIGKEY if $ConfigKey eq 'KeyMapExact';

                            $Config{$ConfigKey} = $Param{Config}->{$ConfigKey};
                        }

                        CONFIGITEM:
                        for my $ConfigItem ( sort keys %{ $Param{Config}->{KeyMapExact} } ) {

                            # check if we have to split our mapping key
                            # for the current sub-structure
                            my $ElementName = $ConfigItem;
                            if ( $ElementName =~ m{ \A $OldKey \. ( .+ ) \z }xms ) {
                                $ElementName = $1;
                            }

                            $Config{KeyMapExact}->{$ElementName} = $Param{Config}->{KeyMapExact}->{$ConfigItem};
                        }
                    }

                    my @MappedArrayElementData;
                    push( @MappedArrayElementData, $CurrentArrayElement );

                    if (%Config) {
                        if (
                            IsStringWithData( $CurrentArrayElement->{name} )
                            && IsString( $CurrentArrayElement->{value} )
                            )
                        {
                            my %MappedNameValueArrayElementData = $Self->_MapRecursive(
                                Config => \%Config,
                                Data   => {
                                    $CurrentArrayElement->{name} => $CurrentArrayElement->{value}
                                },
                            );

                            @MappedArrayElementData = ();
                            for my $MappedKey ( sort keys %MappedNameValueArrayElementData ) {

                                push(
                                    @MappedArrayElementData,
                                    {
                                        name  => $MappedKey,
                                        value => $MappedNameValueArrayElementData{$MappedKey},
                                    }
                                );
                            }
                        }
                        else {
                            my %MappedArrayElementData = $Self->_MapRecursive(
                                Config => \%Config,
                                Data   => $CurrentArrayElement,
                            );

                            @MappedArrayElementData = ();
                            push( @MappedArrayElementData, \%MappedArrayElementData );
                        }
                    }
                    push( @MappedArrayData, @MappedArrayElementData );
                }

                # otherwise keep the untouched data
                else {
                    push( @MappedArrayData, $CurrentArrayElement );
                }
            }
            $Param{Data}->{$OldKey} = \@MappedArrayData;
        }

        # if we got an HashRef pass it to the next recursive mapping stage
        elsif ( IsHashRefWithData( $Param{Data}->{$OldKey} ) ) {

            # parse config for sub-entries
            my %Config;
            if ( IsHashRefWithData( $Param{Config}->{KeyMapExact} ) ) {

                CONFIGKEY:
                for my $ConfigKey ( sort keys %{ $Param{Config} } ) {

                    next CONFIGKEY if $ConfigKey eq 'KeyMapExact';

                    $Config{$ConfigKey} = $Param{Config}->{$ConfigKey};
                }

                CONFIGITEM:
                for my $ConfigItem ( sort keys %{ $Param{Config}->{KeyMapExact} } ) {

                    # check if we have to split our mapping key
                    # for the current sub-structure
                    my $ElementName = $ConfigItem;
                    if ( $ElementName =~ m{ \A $OldKey \. ( .+ ) \z }xms ) {
                        $ElementName = $1;
                    }

                    $Config{KeyMapExact}->{$ElementName} = $Param{Config}->{KeyMapExact}->{$ConfigItem};
                }
            }

            my %MappedHashElementData = %{ $Param{Data}->{$OldKey} };
            if (%Config) {
                %MappedHashElementData = $Self->_MapRecursive(
                    Data   => $Param{Data}->{$OldKey},
                    Config => \%Config,
                );

                if (
                    IsArrayRefWithData( $Param{Config}->{ReduceStructure} )
                    && ( grep { $OldKey eq $_ } @{ $Param{Config}->{ReduceStructure} } )
                    )
                {
                    for my $CurrentSubStructureKey ( sort keys %MappedHashElementData ) {
                        $ReturnData{$CurrentSubStructureKey} = $MappedHashElementData{$CurrentSubStructureKey};
                    }
                }
            }
            $Param{Data}->{$OldKey} = \%MappedHashElementData;
        }

        # map key
        my $NewKey;

        # first check in exact (1:1) map
        if ( $Param{Config}->{KeyMapExact} && $Param{Config}->{KeyMapExact}->{$OldKey} ) {
            $NewKey = $Param{Config}->{KeyMapExact}->{$OldKey};
        }

        # if we have no match from exact map, try regex map
        if ( !$NewKey && $Param{Config}->{KeyMapRegEx} ) {
            KEYMAPREGEX:
            for my $ConfigKey ( sort keys %{ $Param{Config}->{KeyMapRegEx} } ) {
                next KEYMAPREGEX if $OldKey !~ m{ \A $ConfigKey \z }xms;
                if ( $ReturnData{ $Param{Config}->{KeyMapRegEx}->{$ConfigKey} } ) {
                    $Self->{DebuggerObject}->Notice(
                        Summary =>
                            "The data key '$Param{Config}->{KeyMapRegEx}->{ $ConfigKey }' already exists!",
                    );
                    next CONFIGKEY;
                }
                $NewKey = $Param{Config}->{KeyMapRegEx}->{$ConfigKey};
                last KEYMAPREGEX;
            }
        }

        # if we still have no match, apply default
        if ( !$NewKey ) {

            # check map type options
            if (
                $Param{Config}->{KeyMapDefault}->{MapType} eq 'Keep'
                || $OldKey eq '__RequestHeaders'
                )
            {
                $NewKey = $OldKey;
            }
            elsif ( $Param{Config}->{KeyMapDefault}->{MapType} eq 'Ignore' ) {
                next CONFIGKEY;
            }
            elsif ( $Param{Config}->{KeyMapDefault}->{MapType} eq 'MapTo' ) {

                # check if we already have a key with the same name
                if ( $ReturnData{ $Param{Config}->{KeyMapDefault}->{MapTo} } ) {
                    $Self->{DebuggerObject}->Notice(
                        Summary =>
                            "The data key $Param{Config}->{KeyMapDefault}->{MapTo} already exists!",
                    );
                    next CONFIGKEY;
                }

                $NewKey = $Param{Config}->{KeyMapDefault}->{MapTo};
            }
        }

        # sanity check - we should have a translated key now
        if ( !$NewKey ) {
            return $Self->{DebuggerObject}->Error( Summary => "Could not map data key $NewKey!" );
        }

        # map value
        my $OldValue = $Param{Data}->{$OldKey};

        NEWKEY:
        for my $CurrentNewKey ( split /,/, $NewKey ) {

            $CurrentNewKey =~ s{^\s+}{}xms;
            $CurrentNewKey =~ s{\s+$}{}xms;

            my $LookupValue = $OldValue;
            my $IsNameValueHashStructure;
            if (
                IsHashRefWithData($OldValue)
                && IsStringWithData( $OldValue->{name} )
                && $OldValue->{name} eq $OldKey
                )
            {

                $IsNameValueHashStructure = 1;
                $LookupValue              = $OldValue->{value};
                $OldValue->{name}         = $CurrentNewKey;
            }

            # if value is no string, just pass through
            if (
                !IsString($OldValue)
                && !$IsNameValueHashStructure
                )
            {
                $ReturnData{$CurrentNewKey} = $OldValue;
                next NEWKEY;
            }

            my @OldValueList;
            my $ListSeparator = $Param{Config}->{ListSeparator}->{$OldKey};
            if ($ListSeparator) {
                @OldValueList = split /$ListSeparator/, $OldValue;
            }
            else {
                push @OldValueList, $OldValue;
            }

            # check if we have a value mapping for the specific key
            my @MappedValues;
            my @UnmappedValues;
            my $ValueMap = $Param{Config}->{ValueMap}->{$NewKey};
            OLDVALUE:
            for my $CurrentOldValue ( sort @OldValueList ) {

                if (
                    IsStringWithData($CurrentOldValue)
                    && $CurrentOldValue =~ m{ \A (\d{4} - \d{2} - \d{2}) T (\d{2} : \d{2} : \d{2}) \z }xms
                    )
                {
                    $CurrentOldValue = "$1 $2";
                }

                if ($ValueMap) {

                    # first check in exact (1:1) map
                    if ( $ValueMap->{ValueMapExact} && defined $ValueMap->{ValueMapExact}->{$CurrentOldValue} )
                    {
                        if ($IsNameValueHashStructure) {

                            $ReturnData{$CurrentNewKey} = {
                                name  => $CurrentNewKey,
                                value => $ValueMap->{ValueMapExact}->{$CurrentOldValue},
                            };
                        }
                        else {
                            $ReturnData{$CurrentNewKey} = $ValueMap->{ValueMapExact}->{$CurrentOldValue};
                        }
                        next NEWKEY;
                    }

                    # if we have no match from exact map, try regex map
                    if ( $ValueMap->{ValueMapRegEx} ) {

                        VALUEMAPREGEX:
                        for my $ConfigKey ( sort keys %{ $ValueMap->{ValueMapRegEx} } ) {

                            if ($IsNameValueHashStructure) {

                                if ( my @CapturedGroups = $CurrentOldValue->{value} =~ m{ \A $ConfigKey \z }xms ) {

                                    my $NewValue = $ValueMap->{ValueMapRegEx}->{$ConfigKey};
                                    if (
                                        @CapturedGroups
                                        && ( my @ReplaceDidgits = $NewValue =~ m{\$(\d)}gxms )
                                        )
                                    {

                                        my $OldValue = $CurrentOldValue->{value};
                                        $OldValue =~ s{ \A $ConfigKey \z }{$NewValue}xms;

                                        for my $CurrentReplaceDigit (@ReplaceDidgits) {

                                            my $ReplaceValue = $CapturedGroups[ $CurrentReplaceDigit - 1 ] || '';

                                            $OldValue =~ s{\$$CurrentReplaceDigit}{$ReplaceValue}xmsg;
                                        }

                                        $NewValue = $OldValue;
                                    }

                                    $ReturnData{$CurrentNewKey} = {
                                        name  => $CurrentNewKey,
                                        value => $NewValue,
                                    };
                                }
                            }
                            else {

                                if ( my @CapturedGroups = $CurrentOldValue =~ m{ \A $ConfigKey \z }xms ) {

                                    my $NewValue = $ValueMap->{ValueMapRegEx}->{$ConfigKey};
                                    if (
                                        @CapturedGroups
                                        && ( my @ReplaceDidgits = $NewValue =~ m{\$(\d)}gxms )
                                        )
                                    {

                                        my $OldValue = $CurrentOldValue;
                                        $OldValue =~ s{ \A $ConfigKey \z }{$NewValue}xms;

                                        for my $CurrentReplaceDigit (@ReplaceDidgits) {

                                            my $ReplaceValue = $CapturedGroups[ $CurrentReplaceDigit - 1 ] || '';

                                            $OldValue =~ s{\$$CurrentReplaceDigit}{$ReplaceValue}xmsg;
                                        }

                                        $NewValue = $OldValue;
                                    }

                                    $ReturnData{$CurrentNewKey} = $NewValue;
                                }
                            }

                            next NEWKEY;
                        }
                    }
                }

                push @UnmappedValues, $CurrentOldValue;
            }

            # if we had no mapping, apply default

            # keep current value
            if ( $Param{Config}->{ValueMapDefault}->{MapType} eq 'Keep' ) {

                # if there's allready data for this key
                # add the new data after a line break
                if (
                    $ReturnData{$CurrentNewKey}
                    && !$IsNameValueHashStructure
                    )
                {
                    $ReturnData{$CurrentNewKey} .= "\n" . $OldValue;
                }
                else {
                    $ReturnData{$CurrentNewKey} = $OldValue;
                }
                next NEWKEY;
            }

            # map to default value
            if ( $Param{Config}->{ValueMapDefault}->{MapType} eq 'MapTo' ) {

                if ($IsNameValueHashStructure) {

                    $ReturnData{$CurrentNewKey} = {
                        name  => $CurrentNewKey,
                        value => $Param{Config}->{ValueMapDefault}->{MapTo},
                    };
                }
                else {
                    $ReturnData{$CurrentNewKey} = $Param{Config}->{ValueMapDefault}->{MapTo};
                }

                next NEWKEY;
            }
        }

        # implicit ignore
        next CONFIGKEY;
    }

    return %ReturnData;
}

1;
