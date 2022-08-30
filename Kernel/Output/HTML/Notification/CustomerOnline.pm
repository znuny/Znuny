# --
# Copyright (C) 2001-2021 OTRS AG, https://otrs.com/
# Copyright (C) 2021-2022 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see https://www.gnu.org/licenses/gpl-3.0.txt.
# --

package Kernel::Output::HTML::Notification::CustomerOnline;

use parent 'Kernel::Output::HTML::Base';

use strict;
use warnings;

our @ObjectDependencies = (
    'Kernel::Config',
    'Kernel::System::AuthSession',
    'Kernel::System::DateTime',
    'Kernel::Output::HTML::Layout',
);

sub Run {
    my ( $Self, %Param ) = @_;

    my $SessionObject = $Kernel::OM->Get('Kernel::System::AuthSession');

    my $SessionMaxIdleTime = $Kernel::OM->Get('Kernel::Config')->Get('SessionMaxIdleTime');

    my %Online   = ();
    my @Sessions = $SessionObject->GetAllSessionIDs();

    for my $SessionID (@Sessions) {
        my %Data = $SessionObject->GetSessionIDData(
            SessionID => $SessionID,
        );
        if (
            $Data{UserType} eq 'Customer'
            && $Data{UserLastRequest}
            && $Data{UserLastRequest} + $SessionMaxIdleTime
            > $Kernel::OM->Create('Kernel::System::DateTime')->ToEpoch()
            && $Data{UserFirstname}
            && $Data{UserLastname}
            )
        {
            $Online{ $Data{UserID} } = "$Data{UserFullname}";
            if ( $Param{Config}->{ShowEmail} ) {
                $Online{ $Data{UserID} } .= " ($Data{UserEmail})";
            }
        }
    }
    for my $UserID ( sort { $Online{$a} cmp $Online{$b} } keys %Online ) {
        if ( $Param{Message} ) {
            $Param{Message} .= ', ';
        }
        $Param{Message} .= "$Online{$UserID}";
    }
    if ( $Param{Message} ) {

        # get layout object
        my $LayoutObject = $Kernel::OM->Get('Kernel::Output::HTML::Layout');

        return $LayoutObject->Notify(
            Info => $LayoutObject->{LanguageObject}->Translate(
                'Online Customer: %s',
                $Param{Message},
            ),
        );
    }
    else {
        return '';
    }
}

1;
