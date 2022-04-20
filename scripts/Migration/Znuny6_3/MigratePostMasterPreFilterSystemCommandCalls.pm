# --
# Copyright (C) 2021-2022 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package scripts::Migration::Znuny6_3::MigratePostMasterPreFilterSystemCommandCalls;    ## no critic

use strict;
use warnings;

use IO::Interactive qw(is_interactive);

use parent qw(scripts::Migration::Base);

use version;

use Kernel::System::VariableCheck qw(:all);

our @ObjectDependencies = (
    'Kernel::Config',
    'Kernel::System::SysConfig',
);

sub Run {
    my ( $Self, %Param ) = @_;

    my $SysConfigObject = $Kernel::OM->Get('Kernel::System::SysConfig');

    my $UserID = 1;

    my $PostMasterPreFilters = $Self->_GetPostMasterPreFilterConfig();

    my $PostMasterPreFiltersToRemove = $Self->_GetPostMasterPreFiltersToRemove();
    return 1 if !IsArrayRefWithData($PostMasterPreFiltersToRemove);

    my @SettingsSetParams;
    for my $PostMasterPreFilter ( sort @{$PostMasterPreFiltersToRemove} ) {
        push @SettingsSetParams, {
            Name           => "PostMaster::PreFilterModule###$PostMasterPreFilter",
            EffectiveValue => $PostMasterPreFilters->{$PostMasterPreFilter},
            IsValid        => 0,
        };
    }

    $SysConfigObject->SettingsSet(
        UserID   => $UserID,
        Comments => 'Deactivated PostMaster pre-filters that call system commands.',
        Settings => \@SettingsSetParams,
    );

    return 1;
}

sub CheckPreviousRequirement {
    my ( $Self, %Param ) = @_;

    my $PostMasterPreFiltersToRemove = $Self->_GetPostMasterPreFiltersToRemove();
    return 1 if !IsArrayRefWithData($PostMasterPreFiltersToRemove);

    print "\n        The following PostMaster pre-filters use system command calls.\n";
    print "        These are not allowed anymore and will be removed.\n";

    for my $PostMasterPreFilter ( sort @{$PostMasterPreFiltersToRemove} ) {
        print "            $PostMasterPreFilter\n";
    }

    if ( is_interactive() ) {
        print '        Do you want to continue? [Y]es/[N]o: ';

        my $Answer = <>;
        $Answer =~ s{\s}{}g;

        return if $Answer !~ m{\Ay(es)?\z}i;
    }

    return 1;
}

sub _GetPostMasterPreFiltersToRemove {
    my ( $Self, %Param ) = @_;

    my $PostMasterPreFilters = $Self->_GetPostMasterPreFilterConfig();

    my @PostMasterPreFiltersToRemove
        = grep { $PostMasterPreFilters->{$_}->{Module} eq 'Kernel::System::PostMaster::Filter::CMD' }
        sort keys %{$PostMasterPreFilters};

    return \@PostMasterPreFiltersToRemove;
}

sub _GetPostMasterPreFilterConfig {
    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');

    my $PostMasterPreFilters = $ConfigObject->Get('PostMaster::PreFilterModule') // {};
    return $PostMasterPreFilters;
}

1;
