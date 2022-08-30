# --
# Copyright (C) 2001-2021 OTRS AG, https://otrs.com/
# Copyright (C) 2021-2022 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see https://www.gnu.org/licenses/gpl-3.0.txt.
# --

package Kernel::Output::HTML::ArticleAction::AgentTicketPhone;

use strict;
use warnings;

use Kernel::Language qw(Translatable);

our @ObjectDependencies = (
    'Kernel::Config',
    'Kernel::System::Log',
);

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {};
    bless( $Self, $Type );

    return $Self;
}

# optional AclActionLookup
sub CheckAccess {
    my ( $Self, %Param ) = @_;

    # Check needed stuff.
    for my $Needed (qw(Ticket Article ChannelName UserID)) {
        if ( !$Param{$Needed} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Needed!",
            );
            return;
        }
    }

    # check basic conditions
    if ( $Param{ChannelName} eq 'Chat' ) {
        return;
    }

    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');

    # check if module is registered
    return if !$ConfigObject->Get('Frontend::Module')->{AgentSplitSelection};

    # check Acl
    return if !$Param{AclActionLookup}->{AgentSplitSelection};

    return 1;
}

sub GetConfig {
    my ( $Self, %Param ) = @_;

    # Check needed stuff.
    for my $Needed (qw(Ticket Article UserID)) {
        if ( !$Param{$Needed} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Needed!",
            );
            return;
        }
    }

    my %MenuItem = (
        ItemType    => 'Link',
        Description => Translatable('Split this article'),
        Name        => Translatable('Split'),
        Class       => 'SplitSelection',
        Link =>
            "Action=AgentTicketPhone;TicketID=$Param{Ticket}->{TicketID};ArticleID=$Param{Article}->{ArticleID};LinkTicketID=$Param{Ticket}->{TicketID}",
    );

    return ( \%MenuItem );
}

1;
