# --
# Copyright (C) 2021 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::Modules::AdminArticleColor;

use strict;
use warnings;
use utf8;

use Kernel::Language qw(Translatable);

our $ObjectManagerDisabled = 1;

sub new {
    my ( $Type, %Param ) = @_;

    my $Self = {%Param};
    bless( $Self, $Type );

    $Self->{IsVisibleForCustomerYesNo} = {
        'NotVisibleForCustomer' => 'No',
        'VisibleForCustomer'    => 'Yes',
    };

    return $Self;
}

sub Run {
    my ( $Self, %Param ) = @_;

    my $LayoutObject = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $ParamObject  = $Kernel::OM->Get('Kernel::System::Web::Request');

    my %Params = $ParamObject->GetParams();

    %Param = (
        %Param,
        %Params,
    );

    # ------------------------------------------------------------ #
    # AJAXUpdate
    # ------------------------------------------------------------ #
    if ( $Self->{Subaction} eq 'AJAXUpdate' ) {
        return $Self->_AJAXUpdate(%Param);
    }

    # ------------------------------------------------------------
    # overview
    # ------------------------------------------------------------
    else {
        $Self->_Overview();
        my $Output = $LayoutObject->Header();
        $Output .= $LayoutObject->NavigationBar();
        $Output .= $LayoutObject->Output(
            TemplateFile => 'AdminArticleColor',
            Data         => \%Param,
        );
        $Output .= $LayoutObject->Footer();
        return $Output;
    }

}

sub _AJAXUpdate {
    my ( $Self, %Param ) = @_;

    my $LayoutObject  = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $LogObject     = $Kernel::OM->Get('Kernel::System::Log');
    my $ArticleObject = $Kernel::OM->Get('Kernel::System::Ticket::Article');
    my $JSONObject    = $Kernel::OM->Get('Kernel::System::JSON');

    NEEDED:
    for my $Needed (qw(Name Color)) {

        next NEEDED if defined $Param{$Needed};

        $LogObject->Log(
            Priority => 'error',
            Message  => "Parameter '$Needed' is needed!",
        );
        return;
    }

    my %ArticleColor = $ArticleObject->ArticleColorGet(
        Name => $Param{Name},
    );

    my $ArticleColorID = $ArticleObject->ArticleColorSet(
        %ArticleColor,
        Color  => $Param{Color},
        UserID => $Self->{UserID},
    );

    my $Success;
    if ( !$ArticleColorID ) {
        $LogObject->Log(
            Priority => 'error',
            Message  => "Could not set article color with name '$Param{Name}'!",
        );
        $Success = 0;

    }
    else {
        $LogObject->Log(
            Priority => 'notice',
            Message  => "Set article color with name '$Param{Name}' to color '$Param{Color}'!",
        );
        $Success = 1;
    }

    my $Data = $JSONObject->Encode(
        Data => {
            %ArticleColor,
            Color   => $Param{Color},
            Success => $Success,
        },
    );

    return $LayoutObject->Attachment(
        ContentType => 'application/json; charset=' . $LayoutObject->{Charset},
        Content     => $Data,
        Type        => 'inline',
        NoCache     => 1,
    );

}

sub _Overview {
    my ( $Self, %Param ) = @_;

    my $LayoutObject  = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $ArticleObject = $Kernel::OM->Get('Kernel::System::Ticket::Article');

    $LayoutObject->Block(
        Name => 'Overview',
        Data => \%Param,
    );

    $LayoutObject->Block( Name => 'Filter' );

    # Initialize the article color list if not already done.
    $ArticleObject->ArticleColorInit();

    # Get the article color list.
    my @ArticleColorList = $ArticleObject->ArticleColorList();

    for my $ArticleColor (@ArticleColorList) {

        $Param{ColorPicker} = $LayoutObject->ColorPicker(
            Type  => 'Input',
            Name  => $ArticleColor->{Name},
            ID    => $ArticleColor->{Name},
            Color => $ArticleColor->{Color},
            Class => 'Validate_Color ',

            format => 'hexa',
            onChange =>
                "Core.AJAX.FunctionCall('$LayoutObject->{Baselink}Action=AdminArticleColor;Subaction=AJAXUpdate', { Name: '$ArticleColor->{Name}', Color: this.valueElement.value }, function() {});",
        );

        $LayoutObject->Block(
            Name => 'OverviewRow',
            Data => {
                %{$ArticleColor},
                %Param,
                IsVisibleForCustomerYesNo =>
                    $Self->{IsVisibleForCustomerYesNo}->{ $ArticleColor->{IsVisibleForCustomer} },
            },
        );
    }

    return 1;
}

1;
