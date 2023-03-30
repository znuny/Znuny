# --
# Copyright (C) 2021 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::Ticket::Permission::MentionCheck;

use strict;
use warnings;

our @ObjectDependencies = (
    'Kernel::System::Log',
    'Kernel::System::Mention',
);

sub new {
    my ( $Type, %Param ) = @_;

    my $Self = {};
    bless( $Self, $Type );

    return $Self;
}

sub Run {
    my ( $Self, %Param ) = @_;

    my $LogObject     = $Kernel::OM->Get('Kernel::System::Log');
    my $MentionObject = $Kernel::OM->Get('Kernel::System::Mention');

    NEEDED:
    for my $Needed (qw(TicketID UserID Type)) {
        next NEEDED if defined $Param{$Needed};

        $LogObject->Log(
            Priority => 'error',
            Message  => "Need $Needed!",
        );
        return;
    }

    # Return no access if it's wrong permission type.
    return if $Param{Type} ne 'ro';

    # Give access if user mention found.
    my $Mentions = $MentionObject->GetTicketMentions( TicketID => $Param{TicketID} ) // [];
    return 1 if grep { $_->{UserID} == $Param{UserID} } @{$Mentions};

    return 0;
}

1;
