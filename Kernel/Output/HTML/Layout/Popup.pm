# --
# Copyright (C) 2001-2021 OTRS AG, https://otrs.com/
# Copyright (C) 2021 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see https://www.gnu.org/licenses/gpl-3.0.txt.
# --

package Kernel::Output::HTML::Layout::Popup;

use strict;
use warnings;

our $ObjectManagerDisabled = 1;

=head1 NAME

Kernel::Output::HTML::Layout::Popup - CSS/JavaScript

=head1 DESCRIPTION

All valid functions.

=head1 PUBLIC INTERFACE

=head2 AddPopupProfiles()

Adds user or global popup profiles to JS object 'PopupProfiles'.

    my $Success = $LayoutObject->AddPopupProfiles();

    or

    $Self->{LayoutObject}->AddPopupProfiles();

Returns:

    my $Success = 1;

=cut

sub AddPopupProfiles {
    my ( $Self, %Param ) = @_;

    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');
    my $UserObject   = $Kernel::OM->Get('Kernel::System::User');
    my $JSONObject   = $Kernel::OM->Get('Kernel::System::JSON');

    $Param{UserID} //= $Self->{UserID};

    my $PopupProfiles = $ConfigObject->Get('Frontend::PopupProfiles');
    return 1 if $Self->{PopupProfiles};

    my %PopupProfiles;
    for my $Key ( sort keys %{$PopupProfiles} ) {
        %PopupProfiles = ( %PopupProfiles, %{ $PopupProfiles->{$Key} } );
    }

    if ( $Param{UserID} ) {
        my %Preferences = $UserObject->GetPreferences(
            UserID => $Param{UserID},
        );

        KEY:
        for my $Name (qw(WindowURLParams Left Top Width Height)) {
            my $Key = 'UserPopupProfile' . $Name;

            next KEY if !$Preferences{$Key};
            $PopupProfiles{Default}->{$Name} = $Preferences{$Key};
        }
    }

    my $JSONPopupProfile = $JSONObject->Encode(
        Data     => $PopupProfiles{Default},
        SortKeys => 1,
        Pretty   => 0,
    );

    my $PopupProfilesJS = "
    Core.UI.Popup.ProfileAdd(
        'Default', $JSONPopupProfile
    );";

    my $Success = $Self->AddJSOnDocumentCompleteIfNotExists(
        Key  => 'PopupProfiles',
        Code => $PopupProfilesJS,
    );

    return 1;
}

=head2 PopupClose()

Generate a small HTML page which closes the pop-up window and
executes an action in the main window.

    # load specific URL in main window
    $LayoutObject->PopupClose(
        URL => "Action=AgentTicketZoom;TicketID=$TicketID"
    );

    or

    # reload main window
    $Self->{LayoutObject}->PopupClose(
        Reload => 1,
    );

=cut

sub PopupClose {
    my ( $Self, %Param ) = @_;

    my $LogObject = $Kernel::OM->Get('Kernel::System::Log');

    if ( !$Param{URL} && !$Param{Reload} ) {
        $LogObject->Log(
            Priority => 'error',
            Message  => 'Need URL or Reload!'
        );
        return;
    }

    # Generate the call Header() and Footer(
    my $Output = $Self->Header( Type => 'Small' );

    if ( $Param{URL} ) {

        # add session if no cookies are enabled
        if ( $Self->{SessionID} && !$Self->{SessionIDCookie} ) {
            $Param{URL} .= ';' . $Self->{SessionName} . '=' . $Self->{SessionID};
        }

        # send data to JS
        $Self->AddJSData(
            Key   => 'PopupClose',
            Value => 'LoadParentURLAndClose',
        );
        $Self->AddJSData(
            Key   => 'PopupURL',
            Value => $Param{URL},
        );
    }
    else {

        # send data to JS
        $Self->AddJSData(
            Key   => 'PopupClose',
            Value => 'ReloadParentAndClose',
        );
    }

    $Output .= $Self->Footer( Type => 'Small' );
    return $Output;
}

1;

=head1 TERMS AND CONDITIONS

This software is part of the OTRS project (L<https://otrs.org/>).

This software comes with ABSOLUTELY NO WARRANTY. For details, see
the enclosed file COPYING for license information (GPL). If you
did not receive this file, see L<https://www.gnu.org/licenses/gpl-3.0.txt>.

=cut
