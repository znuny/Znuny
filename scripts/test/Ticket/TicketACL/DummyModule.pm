# --
# Copyright (C) 2001-2021 OTRS AG, https://otrs.com/
# Copyright (C) 2021 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see https://www.gnu.org/licenses/gpl-3.0.txt.
# --

use strict;
use warnings;

use Kernel::System::ObjectManager;

package scripts::test::Ticket::TicketACL::DummyModule;    ## no critic

our @ObjectDependencies = (
    'Kernel::System::Log',
);

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {};
    bless( $Self, $Type );

    return $Self;
}

sub Run {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Needed (qw(Config Acl)) {
        if ( !$Param{$Needed} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Needed!",
            );
            return;
        }
    }
    $Param{Acl}->{DummyModule} = {

        # match properties
        Properties => {

            # current ticket match properties
            Ticket => {
                TicketID => [ $Param{TicketID} ],
            },
        },
        PossibleNot => {
            Ticket => {
                State => ['open'],
            }
        },
    };

    return 1;
}

1;
