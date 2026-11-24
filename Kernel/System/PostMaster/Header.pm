# --
# Copyright (C) 2021 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::PostMaster::Header;

use strict;
use warnings;
use utf8;

=head1 NAME

Kernel::System::PostMaster::Header - PostMaster header helper

=cut

sub new {
    my ($Type) = @_;

    my $Self = {};
    bless( $Self, $Type );

    return $Self;
}

sub IsOTRSHeader {
    my ( $Self, %Param ) = @_;

    return if !defined $Param{Header};
    return $Param{Header} =~ m{\AX-OTRS-}i ? 1 : 0;
}

sub IsZnunyHeader {
    my ( $Self, %Param ) = @_;

    return if !defined $Param{Header};
    return $Param{Header} =~ m{\AX-Znuny-}i ? 1 : 0;
}

sub OTRSHeaderGet {
    my ( $Self, %Param ) = @_;

    return                if !defined $Param{Header};
    return $Param{Header} if !$Self->IsZnunyHeader( Header => $Param{Header} );

    my $Header = $Param{Header};
    $Header =~ s{\AX-Znuny-}{X-OTRS-}i;

    return $Header;
}

sub ZnunyHeaderGet {
    my ( $Self, %Param ) = @_;

    return                if !defined $Param{Header};
    return $Param{Header} if !$Self->IsOTRSHeader( Header => $Param{Header} );

    my $Header = $Param{Header};
    $Header =~ s{\AX-OTRS-}{X-Znuny-}i;

    return $Header;
}

sub HeaderAliasesGet {
    my ( $Self, %Param ) = @_;

    return if !defined $Param{Header};

    my @Headers = ( $Param{Header} );

    if ( $Self->IsOTRSHeader( Header => $Param{Header} ) ) {
        push @Headers, $Self->ZnunyHeaderGet( Header => $Param{Header} );
    }
    elsif ( $Self->IsZnunyHeader( Header => $Param{Header} ) ) {
        push @Headers, $Self->OTRSHeaderGet( Header => $Param{Header} );
    }

    my %Seen;
    return grep { !$Seen{$_}++ } @Headers;
}

sub HeaderListWithAliasesGet {
    my ( $Self, %Param ) = @_;

    return if ref $Param{Headers} ne 'ARRAY';

    my @Headers;
    HEADER:
    for my $Header ( @{ $Param{Headers} } ) {
        next HEADER if !defined $Header;

        push @Headers, $Self->HeaderAliasesGet( Header => $Header );
    }

    my %Seen;
    return grep { !$Seen{$_}++ } @Headers;
}

sub HeaderHashNormalize {
    my ( $Self, %Param ) = @_;

    return if ref $Param{Header} ne 'HASH';

    my $Header         = $Param{Header};
    my $PreviousHeader = ref $Param{PreviousHeader} eq 'HASH' ? $Param{PreviousHeader} : {};

    my %OTRSHeaders;
    HEADER:
    for my $HeaderName ( sort keys %{$Header}, keys %{$PreviousHeader} ) {
        next HEADER if !$Self->IsOTRSHeader( Header => $HeaderName ) && !$Self->IsZnunyHeader( Header => $HeaderName );

        my $OTRSHeader = $Self->OTRSHeaderGet( Header => $HeaderName );
        $OTRSHeaders{$OTRSHeader} = 1;
    }

    HEADER:
    for my $OTRSHeader ( sort keys %OTRSHeaders ) {
        my $ZnunyHeader = $Self->ZnunyHeaderGet( Header => $OTRSHeader );

        my $OTRSValue  = $Header->{$OTRSHeader};
        my $ZnunyValue = $Header->{$ZnunyHeader};

        my $UseValue;
        if ( %{$PreviousHeader} ) {
            my $OTRSValuePrevious  = $PreviousHeader->{$OTRSHeader};
            my $ZnunyValuePrevious = $PreviousHeader->{$ZnunyHeader};

            my $OTRSChanged  = ( $OTRSValue  // '' ) ne ( $OTRSValuePrevious  // '' );
            my $ZnunyChanged = ( $ZnunyValue // '' ) ne ( $ZnunyValuePrevious // '' );

            if ($ZnunyChanged) {
                $UseValue = $ZnunyValue;
            }
            elsif ($OTRSChanged) {
                $UseValue = $OTRSValue;
            }
        }

        if ( !defined $UseValue ) {
            $UseValue = defined $ZnunyValue && length $ZnunyValue ? $ZnunyValue : $OTRSValue;
        }

        next HEADER if !defined $UseValue;

        $Header->{$OTRSHeader}  = $UseValue;
        $Header->{$ZnunyHeader} = $UseValue;
    }

    return 1;
}

1;
