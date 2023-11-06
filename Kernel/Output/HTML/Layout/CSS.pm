# --
# Copyright (C) 2021 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::Output::HTML::Layout::CSS;

use strict;
use warnings;

use Kernel::System::VariableCheck qw(:all);

our @ObjectDependencies = (
    'Kernel::Config',
    'Kernel::System::Log',
    'Kernel::System::Main',
);

=head2 CreateDynamicCSS()

Creates and returns a CSS string from Kernel::Output::CSS modules.

    my $CSS = $LayoutObject->CreateDynamicCSS();

Returns:

    my $CSS = 'CSS';

=cut

sub CreateDynamicCSS {
    my ( $Self, %Param ) = @_;

    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');
    my $MainObject   = $Kernel::OM->Get('Kernel::System::Main');
    my $LogObject    = $Kernel::OM->Get('Kernel::System::Log');

    my $CSSDir = $ConfigObject->Get('TemplateDir') . '/CSS';
    return '' if !-e $CSSDir;

    my @CSSFiles = $MainObject->DirectoryRead(
        Directory => $CSSDir,
        Filter    => '*.pm',
    );

    my $CSS = '';

    CSSFILEPATH:
    for my $CSSFilePath (@CSSFiles) {
        next CSSFILEPATH if $CSSFilePath =~ m{/Base\.pm$};

        ( my $CSSModule = $CSSFilePath ) =~ s{\A.*\/(.+?).pm\z}{$1};
        $CSSModule =~ s{\/}{::}g;
        $CSSModule = "Kernel::Output::CSS::$CSSModule";

        my $CSSObject = $Kernel::OM->Get($CSSModule);
        next CSSFILEPATH if !$CSSObject;

        my $FunctionName   = 'CreateCSS';
        my $FunctionExists = $CSSObject->can($FunctionName);
        if ( !$FunctionExists ) {
            $LogObject->Log(
                Priority => 'notice',
                Message  => "CSS module $CSSModule does not support function $FunctionName.",
            );
            return;
        }

        $CSS .= $CSSObject->$FunctionName() // '';
    }

    return $CSS;
}

=head2 ConvertToCSS()

Converts the given Perl hash to CSS.

    my $CSS = $LayOutObject->ConvertToCSS(
        Data => {
            '.StateID-1' {
                background: #50B5FF;
            }
            '.StateID-2' {
                background: #3DD598;
            }
            '.StateID-3' {
                background: #FC5A5A;
            }
            '.StateID-4' {
                background: #FFC542;
            }
            '.StateID-5' {
                background: #8D8D9B;
            }
            '.StateID-6' {
                background: #FF8A25;
            }
            '.StateID-7' {
                background: #3DD598;
            }
            '.StateID-8' {
                background: #FC5A5A;
            }
            '.StateID-9' {
                background: #8D8D9B;
            }
        },
    );

Returns:

    my $CSS = '
        .StateID-1 {
            background: #50B5FF;
        }
        .StateID-2 {
            background: #3DD598;
        }
        .StateID-3 {
            background: #FC5A5A;
        }
        .StateID-4 {
            background: #FFC542;
        }
        .StateID-5 {
            background: #8D8D9B;
        }
        .StateID-6 {
            background: #FF8A25;
        }
        .StateID-7 {
            background: #3DD598;
        }
        .StateID-8 {
            background: #FC5A5A;
        }
        .StateID-9 {
            background: #8D8D9B;
        }
    ';

=cut

sub ConvertToCSS {
    my ( $Self, %Param ) = @_;

    my $LogObject = $Kernel::OM->Get('Kernel::System::Log');

    NEEDED:
    for my $Needed (qw(Data)) {
        next NEEDED if defined $Param{$Needed};

        $LogObject->Log(
            Priority => 'error',
            Message  => "Parameter '$Needed' is needed!",
        );
        return;
    }

    return '' if !IsHashRefWithData( $Param{Data} );

    my $CSS = '';

    my %Data = %{ $Param{Data} };
    for my $Selector ( sort keys %Data ) {
        $CSS .= $Selector . ' {';
        for my $Attribute ( sort keys %{ $Data{$Selector} } ) {
            my $Value = $Data{$Selector}->{$Attribute} // '';
            $CSS .= "\n    $Attribute: $Value;";
        }
        $CSS .= "\n}\n\n";
    }

    return $CSS;
}

=head2 CleanUpCSSSelector()

Cleans the selector string from unwanted characters.

    my $CSSSelector = $LayoutObject->CleanUpCSSSelector(
        CSSSelector => 'pending-auto-close+',
    );

Returns:

    my $CSSSelector = 'pending-auto-close';

=cut

sub CleanUpCSSSelector {
    my ( $Self, %Param ) = @_;

    $Param{CSSSelector}
        =~ s{[\~|\!|\@|\$|\%|\^|\&|\*|\(|\)|\+|\=|\,|\.|\/|\'|\;|\:|\"|\?|\>|\<|\[|\]|\\|\{|\}|\||\`|\#]}{}g;
    $Param{CSSSelector} =~ s{\s}{-}g;

    return $Param{CSSSelector};
}

1;
