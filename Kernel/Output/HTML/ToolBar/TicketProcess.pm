# --
# Copyright (C) 2021-2022 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::Output::HTML::ToolBar::TicketProcess;

use parent 'Kernel::Output::HTML::Base';

use strict;
use warnings;

use Kernel::System::VariableCheck qw(:all);

our @ObjectDependencies = (
    'Kernel::Config',
    'Kernel::Output::HTML::Layout',
    'Kernel::System::Log',
    'Kernel::System::ProcessManagement::Process',
);

sub Run {
    my ( $Self, %Param ) = @_;

    my $LogObject = $Kernel::OM->Get('Kernel::System::Log');

    for my $Needed (qw(Config)) {
        if ( !$Param{$Needed} ) {
            $LogObject->Log(
                Priority => 'error',
                Message  => "Need $Needed!"
            );
            return;
        }
    }

    # check if frontend module is used
    my $Action = $Param{Config}->{Action};
    if ($Action) {
        return if !$Kernel::OM->Get('Kernel::Config')->Get('Frontend::Module')->{$Action};
    }

    my $ProcessObject = $Kernel::OM->Get('Kernel::System::ProcessManagement::Process');

    my $ProcessList = $ProcessObject->ProcessList(
        ProcessState => ['Active'],
        Silent       => 1,
    );

    return if ( !IsHashRefWithData($ProcessList) );

    my $LayoutObject = $Kernel::OM->Get('Kernel::Output::HTML::Layout');

    # get item definition
    my $Text      = $LayoutObject->{LanguageObject}->Translate( $Param{Config}->{Name} );
    my $URL       = $LayoutObject->{Baselink} . $Param{Config}->{Link};
    my $Priority  = $Param{Config}->{Priority};
    my $AccessKey = $Param{Config}->{AccessKey};
    my $CssClass  = $Param{Config}->{CssClass};
    my $Icon      = $Param{Config}->{Icon};

    my %Return;
    $Return{$Priority} = {
        Block       => 'ToolBarItem',
        Description => $Text,
        Class       => $CssClass,
        Icon        => $Icon,
        Link        => $URL,
        AccessKey   => $AccessKey,
    };
    return %Return;
}

1;
