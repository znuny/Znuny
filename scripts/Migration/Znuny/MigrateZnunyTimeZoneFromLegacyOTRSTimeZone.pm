# --
# Copyright (C) 2021 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --
## nofilter(TidyAll::Plugin::Znuny::Perl::Pod::NamePod)

package scripts::Migration::Znuny::MigrateZnunyTimeZoneFromLegacyOTRSTimeZone;    ## no critic

use strict;
use warnings;
use utf8;

use Kernel::System::VariableCheck qw(:all);

use parent qw(scripts::Migration::Base);

our @ObjectDependencies = (
    'Kernel::Config',
    'Kernel::System::Main',
    'Kernel::System::SysConfig',
);

=head1 SYNOPSIS

Copies a legacy C<OTRSTimeZone> value (for example from C<Kernel/Config.pm>) into
C<ZnunyTimeZone> when that setting is still at the unused UTC default. Prints a
warning when C<Kernel/Config.pm> (or C<Custom/Kernel/Config.pm>) still sets
C<OTRSTimeZone>.

Must run after C<MigrateSysConfigSettings> (UpdateName of OTRSTimeZone).

=cut

sub Run {
    my ( $Self, %Param ) = @_;

    my $ConfigObject    = $Kernel::OM->Get('Kernel::Config');
    my $MainObject      = $Kernel::OM->Get('Kernel::System::Main');
    my $SysConfigObject = $Kernel::OM->Get('Kernel::System::SysConfig');

    my $OTRSTimeZone = $ConfigObject->Get('OTRSTimeZone');
    return 1 if !IsStringWithData($OTRSTimeZone);

    my %ZnunyTimeZoneSetting = $SysConfigObject->SettingGet(
        Name  => 'ZnunyTimeZone',
        NoLog => 1,
    );

    my $ZnunyTimeZone = $ZnunyTimeZoneSetting{EffectiveValue}
        // $ConfigObject->Get('ZnunyTimeZone')
        // 'UTC';

    my $Home = $ConfigObject->Get('Home');
    my $OTRSTimeZoneInConfigPm;
    CONFIGFILE:
    for my $ConfigFilePath ( "$Home/Kernel/Config.pm", "$Home/Custom/Kernel/Config.pm" ) {
        next CONFIGFILE if !-f $ConfigFilePath;

        my $ContentRef = $MainObject->FileRead(
            Location => $ConfigFilePath,
            Result   => 'SCALAR',
        );
        next CONFIGFILE if !$ContentRef || !${$ContentRef};

        if ( ${$ContentRef} =~ m{\$Self->\{(?:'OTRSTimeZone'|"OTRSTimeZone"|OTRSTimeZone)\}} ) {
            $OTRSTimeZoneInConfigPm = $ConfigFilePath;
            last CONFIGFILE;
        }
    }

    # Already matches — still warn about Config.pm leftovers.
    if ( $ZnunyTimeZone eq $OTRSTimeZone ) {
        if ($OTRSTimeZoneInConfigPm) {
            print "\n        Warning: '$OTRSTimeZoneInConfigPm' still sets OTRSTimeZone."
                . " Rename it to ZnunyTimeZone (or remove it after checking System Configuration).\n";
        }
        return 1;
    }

    # Do not overwrite a real ZnunyTimeZone customization.
    if ( $ZnunyTimeZone ne 'UTC' && $ZnunyTimeZoneSetting{IsModified} ) {
        if ($OTRSTimeZoneInConfigPm) {
            print "\n        Warning: ZnunyTimeZone is '$ZnunyTimeZone' but '$OTRSTimeZoneInConfigPm'"
                . " still sets OTRSTimeZone to '$OTRSTimeZone'."
                . " Remove or rename the Config.pm entry to avoid confusion.\n";
        }
        return 1;
    }

    # UpdateName may have deployed the UTC default; allow overwrite of that case.
    my $Success = $Self->SettingUpdate(
        Name               => 'ZnunyTimeZone',
        EffectiveValue     => $OTRSTimeZone,
        ContinueOnModified => 1,
        Verbose            => $Param{CommandlineOptions}->{Verbose} || 0,
    );
    return if !$Success;

    print "\n        Warning: ZnunyTimeZone was set to '$OTRSTimeZone' from legacy OTRSTimeZone"
        . " so the storage time zone stays unchanged.\n";
    if ($OTRSTimeZoneInConfigPm) {
        print "        Please rename \$Self->{'OTRSTimeZone'} to \$Self->{'ZnunyTimeZone'}"
            . " in '$OTRSTimeZoneInConfigPm' (or remove it after verifying System Configuration).\n";
    }

    return 1;
}

1;
