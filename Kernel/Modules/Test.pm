# --
# Copyright (C) 2001-2021 OTRS AG, https://otrs.com/
# Copyright (C) 2021 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see https://www.gnu.org/licenses/gpl-3.0.txt.
# --

package Kernel::Modules::Test;

use strict;
use warnings;

our $ObjectManagerDisabled = 1;

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {%Param};
    bless( $Self, $Type );

    return $Self;
}

sub Run {
    my ( $Self, %Param ) = @_;

    my $LayoutObject = $Kernel::OM->Get('Kernel::Output::HTML::Layout');

    # get test page header
    my $Output = $LayoutObject->Header( Title => 'OTRS Test Page' );

    # example blocks
    $LayoutObject->Block(
        Name => 'Row',
        Data => {
            Text    => 'Some Text for the first line',
            Counter => 1,
        },
    );
    $LayoutObject->Block(
        Name => 'Row',
        Data => {
            Text    => 'Some Text for the next line',
            Counter => 2,
        },
    );
    for my $Counter ( 1 .. 2 ) {

        # fist block
        $LayoutObject->Block(
            Name => 'System',
            Data => {
                Type    => 'System',
                Counter => $Counter,
            },
        );

        # sub block of System
        $LayoutObject->Block(
            Name => 'User',
            Data => {
                Type    => 'User',
                Counter => $Counter,
            },
        );

        # sub blocks of User
        $LayoutObject->Block(
            Name => 'UserID',
            Data => {
                Type    => 'UserID',
                Counter => $Counter,
            },
        );

        # just if $_ > 1
        if ( $Counter > 1 ) {
            $LayoutObject->Block(
                Name => 'UserID',
                Data => {
                    Type    => 'UserID',
                    Counter => $Counter,
                },
            );
        }

        # add this block 3 times
        for my $Counter2 ( 4 .. 6 ) {
            $LayoutObject->Block(
                Name => 'UserIDA',
                Data => {
                    Type    => 'UserIDA',
                    Counter => $Counter2,
                },
            );
        }
    }

    # add the times block at least
    $LayoutObject->Block(
        Name => 'Times',
        Data => {
            Type    => 'Times',
            Counter => 443,
        },
    );

    # get test page
    $Output .= $LayoutObject->Output(
        TemplateFile => 'Test',
        Data         => \%Param
    );

    # get test page footer
    $Output .= $LayoutObject->Footer();

    # return test page
    return $Output;
}

1;
