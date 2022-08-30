# --
# Copyright (C) 2001-2021 OTRS AG, https://otrs.com/
# Copyright (C) 2021-2022 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see https://www.gnu.org/licenses/gpl-3.0.txt.
# --

package Kernel::System::ReferenceData;

use strict;
use warnings;

use Locale::Country qw(all_country_names);

our @ObjectDependencies = (
    'Kernel::Config',
    'Kernel::System::Log',
);

=head1 NAME

Kernel::System::ReferenceData - ReferenceData lib

=head1 DESCRIPTION

Contains reference data. For now, this is limited to just a list of ISO country
codes.

=head1 PUBLIC INTERFACE

=head2 new()

Don't use the constructor directly, use the ObjectManager instead:

    my $ReferenceDataObject = $Kernel::OM->Get('Kernel::System::ReferenceData');

=cut

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {};
    bless( $Self, $Type );

    return $Self;
}

=head2 CountryList()

return a list of countries as a hash reference. The countries are based on ISO
3166-2 and are provided by the Perl module Locale::Code::Country, or optionally
from the SysConfig setting ReferenceData::OwnCountryList.

    my $CountryList = $ReferenceDataObject->CountryList(
       Result => 'CODE', # optional: returns CODE => Country pairs conform ISO 3166-2.
    );

=cut

sub CountryList {
    my ( $Self, %Param ) = @_;

    if ( !defined $Param{Result} || $Param{Result} ne 'CODE' ) {
        $Param{Result} = undef;
    }

    my $Countries = $Kernel::OM->Get('Kernel::Config')->Get('ReferenceData::OwnCountryList');

    if ( $Param{Result} && $Countries ) {

        # return Code => Country pairs from SysConfig
        return $Countries;
    }
    elsif ($Countries) {

        # return Country => Country pairs from SysConfig
        my %CountryJustNames = map { $_ => $_ } values %$Countries;
        return \%CountryJustNames;
    }

    my @CountryNames = all_country_names();

    if ( !@CountryNames ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => 'Country name list is empty!',
        );
    }

    if ( $Param{Result} ) {

        # return Code => Country pairs from ISO list
        my %Countries;
        for my $Country (@CountryNames) {
            $Countries{$Country} = country2code( $Country, 1 );
        }
        return \%Countries;
    }

    # return Country => Country pairs from ISO list
    my %CountryNames = map { $_ => $_ } @CountryNames;

    return \%CountryNames;
}

1;

=head1 TERMS AND CONDITIONS

This software is part of the OTRS project (L<https://otrs.org/>).

This software comes with ABSOLUTELY NO WARRANTY. For details, see
the enclosed file COPYING for license information (GPL). If you
did not receive this file, see L<https://www.gnu.org/licenses/gpl-3.0.txt>.

=cut
