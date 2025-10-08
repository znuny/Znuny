# --
# Copyright (C) 2021 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::Output::CSS::ArticleColor;

use strict;
use warnings;
use utf8;

use parent 'Kernel::Output::CSS::Base';

our @ObjectDependencies = (
    'Kernel::Output::HTML::Layout',
    'Kernel::System::Ticket::Article',
);

use Kernel::System::VariableCheck qw(:all);

=head1 NAME

Kernel::Output::CSS::ArticleColor - output css article color

=head2 CreateCSS()

Creates and returns a CSS string.

    my $CSS = $CSSObject->CreateCSS();

Returns:

    my $CSS = 'CSS';

=cut

sub CreateCSS {
    my ( $Self, %Param ) = @_;

    my $ArticleObject = $Kernel::OM->Get('Kernel::System::Ticket::Article');
    my $LayoutObject  = $Kernel::OM->Get('Kernel::Output::HTML::Layout');

    my @ArticleColorList = $ArticleObject->ArticleColorList();

    return '' if !@ArticleColorList;

    my %Data;

    ARTICLECOLOR:
    for my $ArticleColor (@ArticleColorList) {

        next ARTICLECOLOR if !IsHashRefWithData($ArticleColor);
        next ARTICLECOLOR if !IsStringWithData( $ArticleColor->{Color} );

        $Data{
            '.'
                . $ArticleColor->{SenderType} . '.'
                . $ArticleColor->{CommunicationChannel} . '.'
                . $ArticleColor->{IsVisibleForCustomer}
                . ' td'
            } = {
            'background' => $ArticleColor->{Color} . ' !important',
            };
    }

    my $CSS = $LayoutObject->ConvertToCSS(
        Data => \%Data,
    ) // '';

    return $CSS;
}

1;
