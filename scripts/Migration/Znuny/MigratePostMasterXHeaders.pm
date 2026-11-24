# --
# Copyright (C) 2021 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --
## nofilter(TidyAll::Plugin::Znuny::Perl::Pod::NamePod)

package scripts::Migration::Znuny::MigratePostMasterXHeaders;    ## no critic

use strict;
use warnings;
use utf8;

use parent qw(scripts::Migration::Base);

our @ObjectDependencies = (
    'Kernel::System::DB',
    'Kernel::System::Storable',
    'Kernel::System::SysConfig',
);

=head1 SYNOPSIS

Migrates PostMaster X-Headers from X-OTRS-* to X-Znuny-*.

=cut

sub Run {
    my ( $Self, %Param ) = @_;

    return if !$Self->_MigrateSysConfigSettings();
    return if !$Self->_MigratePostMasterFilters();

    return 1;
}

sub _MigrateSysConfigSettings {
    my ( $Self, %Param ) = @_;

    my $SysConfigObject = $Kernel::OM->Get('Kernel::System::SysConfig');
    my $StorableObject  = $Kernel::OM->Get('Kernel::System::Storable');

    my @SettingNames = (
        'PostmasterX-Header',
        'KeepStateHeader',
    );

    my @ConfigurationList = $SysConfigObject->ConfigurationList(
        IncludeInvisible => 1,
    );

    SETTING:
    for my $Setting (@ConfigurationList) {
        next SETTING if !$Setting->{Name};
        next SETTING if $Setting->{Name} !~ m{\APostMaster::Pre(?:Create)?FilterModule###};

        push @SettingNames, $Setting->{Name};
    }

    my @Settings;
    SETTING:
    for my $SettingName (@SettingNames) {
        my %Setting = $SysConfigObject->SettingGet(
            Name    => $SettingName,
            NoCache => 1,
            NoLog   => 1,
        );
        next SETTING if !%Setting;

        # Clone only references, Clone() fails on plain strings like KeepStateHeader.
        my $EffectiveValue = ref $Setting{EffectiveValue}
            ? $StorableObject->Clone( Data => $Setting{EffectiveValue} )
            : $Setting{EffectiveValue};

        my $MigratedEffectiveValue = $Self->_PostMasterXHeadersMigrate(
            Value => $EffectiveValue,
        );

        next SETTING if !$MigratedEffectiveValue->{Changed};

        push @Settings, {
            Name           => $SettingName,
            EffectiveValue => $MigratedEffectiveValue->{Value},
            IsValid        => $Setting{IsValid},
        };
    }

    return 1 if !@Settings;

    return $SysConfigObject->SettingsSet(
        Settings => \@Settings,
        Comments => 'Migrate PostMaster X-Headers from X-OTRS to X-Znuny.',
        UserID   => 1,
    );
}

sub _MigratePostMasterFilters {
    my ( $Self, %Param ) = @_;

    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    return if !$DBObject->Prepare(
        SQL  => 'SELECT id, f_key FROM postmaster_filter WHERE f_key LIKE ?',
        Bind => [ \'X-OTRS-%' ],
    );

    my @Rows;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        push @Rows, {
            ID  => $Row[0],
            Key => $Row[1],
        };
    }

    ROW:
    for my $Row (@Rows) {
        my $Key = $Row->{Key};
        $Key =~ s{\AX-OTRS-}{X-Znuny-}i;

        next ROW if $Key eq $Row->{Key};

        return if !$DBObject->Do(
            SQL  => 'UPDATE postmaster_filter SET f_key = ? WHERE id = ?',
            Bind => [ \$Key, \$Row->{ID} ],
        );
    }

    return 1;
}

=head2 _PostMasterXHeadersMigrate()

Migrates X-OTRS-* values to X-Znuny-* values.

    my $MigratedValue = $MigrateToZnunyObject->_PostMasterXHeadersMigrate(
        Value => $Value,
    );

=cut

sub _PostMasterXHeadersMigrate {
    my ( $Self, %Param ) = @_;

    my $Value = $Param{Value};

    if ( ref $Value eq 'ARRAY' ) {
        my @MigratedValues;
        my $Changed;

        ITEM:
        for my $Item ( @{$Value} ) {
            my $MigratedItem = $Self->_PostMasterXHeadersMigrate(
                Value => $Item,
            );
            push @MigratedValues, $MigratedItem->{Value};
            $Changed ||= $MigratedItem->{Changed};
        }

        if ( @MigratedValues == grep { !ref $_ } @MigratedValues ) {
            my %Seen;
            @MigratedValues = grep { !$Seen{$_}++ } @MigratedValues;
        }

        return {
            Value   => \@MigratedValues,
            Changed => $Changed,
        };
    }

    if ( ref $Value eq 'HASH' ) {
        my %MigratedValue;
        my $Changed;

        ITEM:
        for my $Key ( sort keys %{$Value} ) {
            my $MigratedKey = $Key;
            $MigratedKey =~ s{\AX-OTRS-}{X-Znuny-}i;

            my $MigratedItem = $Self->_PostMasterXHeadersMigrate(
                Value => $Value->{$Key},
            );

            $MigratedValue{$MigratedKey} = $MigratedItem->{Value};
            $Changed ||= $MigratedItem->{Changed} || $MigratedKey ne $Key;
        }

        return {
            Value   => \%MigratedValue,
            Changed => $Changed,
        };
    }

    if ( defined $Value && !ref $Value ) {
        my $MigratedValue = $Value;
        $MigratedValue =~ s{\bX-OTRS-}{X-Znuny-}g;

        return {
            Value   => $MigratedValue,
            Changed => $MigratedValue ne $Value,
        };
    }

    return {
        Value   => $Value,
        Changed => 0,
    };
}

1;
