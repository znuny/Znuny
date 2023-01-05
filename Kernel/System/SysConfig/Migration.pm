# --
# Copyright (C) 2021 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::SysConfig::Migration;

use strict;
use warnings;

use Kernel::System::VariableCheck qw(:all);

our @ObjectDependencies = (
    'Kernel::Config',
    'Kernel::System::Log',
    'Kernel::System::Main',
    'Kernel::System::Storable',
    'Kernel::System::SysConfig',
);

=head1 NAME

Kernel::System::SysConfig::Migration - System configuration settings migration tools.

=head1 PUBLIC INTERFACE

=head2 new()

Create an object. Do not use it directly, instead use:

    use Kernel::System::ObjectManager;
    local $Kernel::OM = Kernel::System::ObjectManager->new();
    my $SysConfigMigrationObject = $Kernel::OM->Get('Kernel::System::SysConfig::Migration');

=cut

sub new {
    my ( $Type, %Param ) = @_;

    my $Self = {};
    bless( $Self, $Type );

    return $Self;
}

=head2 MigrateSysConfigSettings()

Migrates config values from old SysConfig name to a new and updates modified settings with new values if needed.
The values are taken from a backed up ZZZAAuto.pm which contains the old config.

# Rename

    # changed 'Znuny4OTRSDatabaseBackend###Export###CSV###Separator' to 'DBCRUD###Export###CSV###Separator'
    my $Success = $SysConfigMigrationObject->MigrateSysConfigSettings(
        FilePath  => '/opt/otrs/Kernel/Config/Files/ZZZAAuto.pm',
        FileClass => 'Kernel::Config::Files::ZZZAAuto',
        Data      => {
            'Znuny4OTRSDatabaseBackend###Export###CSV###Separator' => {
                UpdateName => 'DBCRUD###Export###CSV###Separator',
            },
        }
    );

# String

    my $Success = $SysConfigMigrationObject->MigrateSysConfigSettings(
        Data => {
            'Ticket::Hook' => {
                UpdateEffectiveValue => {
                    'Ticket#' => 'Znuny###',
                },
            }
        }
    );

# Array

    # Added EffectiveValue, updated old version to new and delete an old EffectiveValue.
    my $Success = $SysConfigMigrationObject->MigrateSysConfigSettings(
        Data => {
            'Loader::Agent::CommonJS###000-Framework' => {
                AddEffectiveValue => [
                    'thirdparty/canvg-1.4/canvg.js',
                ],
                UpdateEffectiveValue => {
                    'thirdparty/jquery-jstree-3.3.4/jquery.jstree.js' => 'thirdparty/jquery-jstree-3.3.7/jquery.jstree.js',
                    'thirdparty/jquery-3.2.1/jquery.js'               => 'thirdparty/jquery-3.5.1/jquery.js',
                },
                DeleteEffectiveValue => [
                    'thirdparty/jquery-3.4.1/jquery.js',
                ]
            }
        }
    );

    # OR

    # Set EffectiveValue
    my $Success = $SysConfigMigrationObject->MigrateSysConfigSettings(
        Data => {
            'Loader::Agent::CommonJS###000-Framework' => {
                EffectiveValue => [
                    'thirdparty/canvg-1.4/canvg.js',
                ],
            }
        }
    );

# Hash

    # Added EffectiveValue, updated old version to new and delete an old EffectiveValue.
    my $Success = $SysConfigMigrationObject->MigrateSysConfigSettings(
        Data => {
            'Ticket::InvalidOwner::StateChange' => {
                AddEffectiveValue => {
                    'open' => 'open',
                },
                UpdateEffectiveValue => {
                    'pending reminder' => {
                        Key   => 'new reminder',
                        Value => 'reminder',
                    },
                },
                DeleteEffectiveValue => [
                    'pending auto',
                ]
            }
        }
    );

Returns:

    my $Success = 1;

=cut

sub MigrateSysConfigSettings {
    my ( $Self, %Param ) = @_;

    my $SysConfigObject = $Kernel::OM->Get('Kernel::System::SysConfig');
    my $StorableObject  = $Kernel::OM->Get('Kernel::System::Storable');
    my $LogObject       = $Kernel::OM->Get('Kernel::System::Log');
    my $MainObject      = $Kernel::OM->Get('Kernel::System::Main');
    my $ConfigObject    = $Kernel::OM->Get('Kernel::Config');

    NEEDED:
    for my $Needed (qw(Data)) {
        next NEEDED if defined $Param{$Needed};

        $LogObject->Log(
            Priority => 'error',
            Message  => "Parameter '$Needed' is needed!",
        );
        return;
    }

    my $Home = $ConfigObject->{Home};

    $Param{FilePath}  //= "$Home/Kernel/Config/Files/ZZZAAuto.pm";
    $Param{FileClass} //= 'Kernel::Config::Files::ZZZAAuto';

    my %ConfigBackup;
    delete $INC{ $Param{FilePath} };
    $MainObject->Require( $Param{FileClass} );
    $Param{FileClass}->Load( \%ConfigBackup );

    my @MigratedSettings;
    my %Data    = %{ $Param{Data} };
    my $Success = 1;

    SETTING:
    for my $SettingName ( sort keys %Data ) {
        my $Name = $SettingName;
        if ( $Data{$SettingName}->{UpdateName} ) {
            $Name = $Data{$SettingName}->{UpdateName};
        }

        my %Setting = $SysConfigObject->SettingGet(
            Name    => $Name,
            NoLog   => 1,
            NoCache => 1,
        );

        # get current EffectiveValue from backed up config
        my $EffectiveValueBackUp = $Setting{EffectiveValue};
        my @SettingNameParts     = split /###/, $SettingName;
        if ( @SettingNameParts == 1 ) {
            $Setting{EffectiveValue} = $ConfigBackup{$SettingName};
        }
        elsif ( @SettingNameParts == 2 ) {
            $Setting{EffectiveValue} = $ConfigBackup{ $SettingNameParts[0] }->{ $SettingNameParts[1] };
        }
        elsif ( @SettingNameParts == 3 ) {
            $Setting{EffectiveValue}
                = $ConfigBackup{ $SettingNameParts[0] }->{ $SettingNameParts[1] }->{ $SettingNameParts[2] };
        }

        $Setting{EffectiveValue} //= $EffectiveValueBackUp;

        my %NewSetting = (
            Name           => $Name,
            EffectiveValue => $Setting{EffectiveValue},
            IsValid        => 1,
        );

        # simple array structure
        if ( IsArrayRefWithData( $Setting{EffectiveValue} ) ) {

            # Create a local clone of the value to prevent any modification.
            my $EffectiveValue = $StorableObject->Clone(
                Data => $Setting{EffectiveValue},
            );

            # AddEffectiveValue
            if (
                $Data{$SettingName}->{AddEffectiveValue}
                && IsArrayRefWithData( $Data{$SettingName}->{AddEffectiveValue} )
                )
            {

                push @{$EffectiveValue}, @{ $Data{$SettingName}->{AddEffectiveValue} };
                $NewSetting{EffectiveValue} = $EffectiveValue;
            }

            # UpdateEffectiveValue
            if (
                $Data{$SettingName}->{UpdateEffectiveValue}
                && IsHashRefWithData( $Data{$SettingName}->{UpdateEffectiveValue} )
                )
            {
                for my $Index ( 0 .. $#{$EffectiveValue} ) {
                    for my $OldValue ( sort keys %{ $Data{$SettingName}->{UpdateEffectiveValue} } ) {
                        if ( $EffectiveValue->[$Index] eq $OldValue ) {
                            $EffectiveValue->[$Index] = $Data{$SettingName}->{UpdateEffectiveValue}->{$OldValue};
                        }
                    }
                }
                $NewSetting{EffectiveValue} = $EffectiveValue;
            }

            # DeleteEffectiveValue
            if (
                $Data{$SettingName}->{DeleteEffectiveValue}
                && IsArrayRefWithData( $Data{$SettingName}->{DeleteEffectiveValue} )
                )
            {

                for my $DeleteEffectiveValue ( @{ $Data{$SettingName}->{DeleteEffectiveValue} } ) {
                    @{$EffectiveValue} = grep { $DeleteEffectiveValue ne $_ } @{$EffectiveValue};
                }
                $NewSetting{EffectiveValue} = $EffectiveValue;
            }

            # EffectiveValue
            if ( IsArrayRefWithData( $Data{$SettingName}->{EffectiveValue} ) ) {
                $NewSetting{EffectiveValue} = $Data{$SettingName}->{EffectiveValue};
                if ( $Setting{IsModified} ) {
                    $LogObject->Log(
                        Priority => 'error',
                        Message  => "This SysConfig '$SettingName' was updated, although the modified mode is active.",
                    );
                }
            }
            push @MigratedSettings, \%NewSetting;

        }

        # simple hash structure
        elsif ( IsHashRefWithData( $Setting{EffectiveValue} ) ) {

            # Create a local clone of the value to prevent any modification.
            my $EffectiveValue = $StorableObject->Clone(
                Data => $Setting{EffectiveValue},
            );

            # AddEffectiveValue
            if (
                $Data{$SettingName}->{AddEffectiveValue}
                && IsHashRefWithData( $Data{$SettingName}->{AddEffectiveValue} )
                )
            {
                %{ $NewSetting{EffectiveValue} } = (
                    %{$EffectiveValue},
                    %{ $Data{$SettingName}->{AddEffectiveValue} },
                );
            }

            # UpdateEffectiveValue
            if (
                $Data{$SettingName}->{UpdateEffectiveValue}
                && IsHashRefWithData( $Data{$SettingName}->{UpdateEffectiveValue} )
                )
            {

                for my $Item ( sort keys %{$EffectiveValue} ) {
                    UPDATEKEY:
                    for my $UpdateKey ( sort keys %{ $Data{$SettingName}->{UpdateEffectiveValue} } ) {

                        next UPDATEKEY if $Item ne $UpdateKey;

                        my $NewKey   = $Data{$SettingName}->{UpdateEffectiveValue}->{$UpdateKey}->{Key};
                        my $NewValue = $Data{$SettingName}->{UpdateEffectiveValue}->{$UpdateKey}->{Value};
                        $EffectiveValue->{$Item}->{$NewKey} = $NewValue;
                    }
                }

                $NewSetting{EffectiveValue} = $EffectiveValue;
            }

            # DeleteEffectiveValue
            if (
                $Data{$SettingName}->{DeleteEffectiveValue}
                && IsArrayRefWithData( $Data{$SettingName}->{DeleteEffectiveValue} )
                )
            {
                DELETE:
                for my $DeleteEffectiveValue ( @{ $Data{$SettingName}->{DeleteEffectiveValue} } ) {
                    next DELETE if !$NewSetting{EffectiveValue}->{$DeleteEffectiveValue};
                    delete $NewSetting{EffectiveValue}->{$DeleteEffectiveValue};
                }
            }

            # EffectiveValue
            if ( $Data{$SettingName}->{EffectiveValue} && IsHashRefWithData( $Data{$SettingName}->{EffectiveValue} ) ) {
                $NewSetting{EffectiveValue} = $Data{$SettingName}->{EffectiveValue};
            }
            push @MigratedSettings, \%NewSetting;
        }

        # simple value structure
        else {
            # AddEffectiveValue and DeleteEffectiveValue are not supported or needed for simple structures

            # UpdateEffectiveValue
            if (
                $Data{$SettingName}->{UpdateEffectiveValue}
                && IsHashRefWithData( $Data{$SettingName}->{UpdateEffectiveValue} )
                )
            {

                for my $OldValue ( sort keys %{ $Data{$SettingName}->{UpdateEffectiveValue} } ) {
                    if ( $Setting{EffectiveValue} eq $OldValue ) {
                        $NewSetting{EffectiveValue} = $Data{$SettingName}->{UpdateEffectiveValue}->{$OldValue};
                    }
                }
            }

            # EffectiveValue
            if ( $Data{$SettingName}->{EffectiveValue} ) {
                $NewSetting{EffectiveValue} = $Data{$SettingName}->{EffectiveValue};

                if ( $Setting{IsModified} ) {
                    $LogObject->Log(
                        Priority => 'error',
                        Message  => "This SysConfig '$SettingName' was updated, although the modified mode is active.",
                    );
                }
            }
            push @MigratedSettings, \%NewSetting;
        }
    }

    if ( IsArrayRefWithData( \@MigratedSettings ) ) {
        my $Result = $SysConfigObject->SettingsSet(
            UserID   => 1,
            Comments => "Deploy migrated settings.",
            Settings => \@MigratedSettings,
        );
        if ( !$Result ) {
            $Success = 0;
        }
    }

    return $Success;
}

1;
