# --
# Copyright (C) 2001-2021 OTRS AG, https://otrs.com/
# Copyright (C) 2021-2022 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see https://www.gnu.org/licenses/gpl-3.0.txt.
# --

package Kernel::Output::HTML::Layout::AJAX;

use strict;
use warnings;

use Kernel::System::JSON ();

our $ObjectManagerDisabled = 1;

=head1 NAME

Kernel::Output::HTML::Layout::AJAX - all AJAX-related HTML functions

=head1 DESCRIPTION

All AJAX-related HTML functions

=head1 PUBLIC INTERFACE

=head2 BuildSelectionJSON()

build a JSON output which can be used for e. g. data for pull downs

    my $JSON = $LayoutObject->BuildSelectionJSON(
        [
            {
                Data          => $ArrayRef,      # use $HashRef, $ArrayRef or $ArrayHashRef (see below)
                Name          => 'TheName',      # name of element
                SelectedID    => [1, 5, 3],      # (optional) use integer or arrayref (unable to use with ArrayHashRef)
                SelectedValue => 'test',         # (optional) use string or arrayref (unable to use with ArrayHashRef)
                Sort          => 'NumericValue', # (optional) (AlphanumericValue|NumericValue|AlphanumericKey|NumericKey|TreeView) unable to use with ArrayHashRef
                SortReverse   => 0,              # (optional) reverse the list
                Translation   => 1,              # (optional) default 1 (0|1) translate value
                PossibleNone  => 0,              # (optional) default 0 (0|1) add a leading empty selection
                Max => 100,                      # (optional) default 100 max size of the shown value
            },
            {
                # ...
            }
        ]
    );

=cut

sub BuildSelectionJSON {
    my ( $Self, $Array ) = @_;
    my %DataHash;

    for my $Data ( @{$Array} ) {
        my %Param = %{$Data};

        # log object
        my $LogObject = $Kernel::OM->Get('Kernel::System::Log');

        # check needed stuff
        for my $Needed (qw(Name)) {
            if ( !defined $Param{$Needed} ) {
                $LogObject->Log(
                    Priority => 'error',
                    Message  => "Need $Needed!"
                );
                return;
            }
        }

        if ( !defined( $Param{Data} ) ) {
            if ( !$Param{PossibleNone} ) {
                $LogObject->Log(
                    Priority => 'error',
                    Message  => "Need Data!"
                );
                return;
            }
            $DataHash{''} = '-';
        }
        elsif ( ref $Param{Data} eq '' ) {
            $DataHash{ $Param{Name} } = $Param{Data};
        }
        elsif ( defined $Param{KeepData} && $Param{KeepData} ) {
            $DataHash{ $Param{Name} } = $Param{Data};
        }
        else {

            # create OptionRef
            my $OptionRef = $Self->_BuildSelectionOptionRefCreate(
                %Param,
                HTMLQuote => 0,
            );

            # create AttributeRef
            my $AttributeRef = $Self->_BuildSelectionAttributeRefCreate(%Param);

            # create DataRef
            my $DataRef = $Self->_BuildSelectionDataRefCreate(
                Data         => $Param{Data},
                AttributeRef => $AttributeRef,
                OptionRef    => $OptionRef,
            );

            # create data structure
            if ( $AttributeRef && $DataRef ) {
                my @DataArray;
                for my $Row ( @{$DataRef} ) {
                    my $Key = '';
                    if ( defined $Row->{Key} ) {
                        $Key = $Row->{Key};
                    }
                    my $Value = '';
                    if ( defined $Row->{Value} ) {
                        $Value = $Row->{Value};
                    }

                    # DefaultSelected parameter for JavaScript New Option
                    my $DefaultSelected = Kernel::System::JSON::False();

                    # to set a disabled option (Disabled is not included in JavaScript New Option)
                    my $Disabled = Kernel::System::JSON::False();

                    if ( $Row->{Selected} ) {
                        $DefaultSelected = Kernel::System::JSON::True();
                    }
                    elsif ( $Row->{Disabled} ) {
                        $DefaultSelected = Kernel::System::JSON::False();
                        $Disabled        = Kernel::System::JSON::True();
                    }

                    # Selected parameter for JavaScript NewOption
                    my $Selected = $DefaultSelected;
                    push @DataArray, [ $Key, $Value, $DefaultSelected, $Selected, $Disabled ];
                }
                $DataHash{ $AttributeRef->{name} } = \@DataArray;
            }
        }
    }

    return $Self->JSONEncode(
        Data => \%DataHash,
    );
}

1;

=head1 TERMS AND CONDITIONS

This software is part of the OTRS project (L<https://otrs.org/>).

This software comes with ABSOLUTELY NO WARRANTY. For details, see
the enclosed file COPYING for license information (GPL). If you
did not receive this file, see L<https://www.gnu.org/licenses/gpl-3.0.txt>.

=cut
