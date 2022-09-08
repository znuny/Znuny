# --
# Copyright (C) 2021-2022 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::DBCRUD::Event::DBCRUD;

use strict;
use warnings;

use Kernel::System::VariableCheck qw(:all);

our @ObjectDependencies = (
    'Kernel::System::Log',
);

sub new {
    my ( $Type, %Param ) = @_;

    my $Self = {};
    bless( $Self, $Type );

    return $Self;
}

sub Run {
    my ( $Self, %Param ) = @_;

    my $LogObject = $Kernel::OM->Get('Kernel::System::Log');

    NEEDED:
    for my $Needed (qw( Data Event Config )) {

        next NEEDED if $Param{$Needed};

        $LogObject->Log(
            Priority => 'error',
            Message  => "Need $Needed!"
        );
        return;
    }

    return 1 if !$Param{Event};
    return 1 if !$Param{Data};

    my $Success;
    if ( $Param{Event} =~ m{\A(.*)(Add|Update|Delete|Export|Import|Copy)\z} ) {
        my $Object = $1;
        my $Method = 'Data' . $2 . 'Post';

        my $BackendObject = $Kernel::OM->Get( 'Kernel::System::' . $Object );
        my $CheckFunction = $BackendObject->can($Method);
        return 1 if !$CheckFunction;

        $Success = $BackendObject->$Method(
            %{ $Param{Data} },
        );
    }

    return $Success;
}

1;
