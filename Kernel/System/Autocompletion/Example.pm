# --
# Copyright (C) 2021 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::Autocompletion::Example;

use strict;
use warnings;

use Kernel::System::VariableCheck qw(:all);

use parent qw(Kernel::System::Autocompletion::Base);

our @ObjectDependencies = (
    'Kernel::System::Log',
    'Kernel::System::Queue',
);

=head2 GetData()

    Example autocompletion module.
    It implements autocompletion for queues.
    Search for a queue's name (trigger is !EX, if Frontend::RichText::Autocompletion::Modules##Example is enabled)
    and it will return some data of the queue.

    my $Data = $AutocompletionObject->GetData(
        SearchString => 'Raw',
        UserID       => 2,
    );

    Returns:

    my $Data = [
        {
            id                   => 3,
            selection_list_title => 'Raw',
            inserted_value       => 'Raw (3)',
        },
    ];

=cut

sub GetData {
    my ( $Self, %Param ) = @_;

    my $LogObject   = $Kernel::OM->Get('Kernel::System::Log');
    my $QueueObject = $Kernel::OM->Get('Kernel::System::Queue');

    NEEDED:
    for my $Needed (qw(SearchString UserID)) {
        next NEEDED if defined $Param{$Needed};

        $LogObject->Log(
            Priority => 'error',
            Message  => "Parameter '$Needed' is needed!",
        );
        return;
    }

    my %Queues = $QueueObject->QueueList();

    my @Data;
    QUEUEID:
    for my $QueueID ( sort keys %Queues ) {
        my $Queue = $Queues{$QueueID};

        next QUEUEID if $Queue !~ m{\Q$Param{SearchString}\E}i;

        my $Data = $Self->_MapData(
            ID                 => $QueueID,
            SelectionListTitle => $Queue,
            InsertedValue      => "$Queue ($QueueID)",
        );
        next QUEUEID if !IsHashRefWithData($Data);

        push @Data, $Data;
    }

    return \@Data;
}

1;
