# --
# Copyright (C) 2021 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::UnitTest::TicketToUnitTest::TicketObject::DynamicField;

use strict;
use warnings;

our @ObjectDependencies = (
    'Kernel::System::DynamicField',
    'Kernel::System::Main',
);

use Kernel::System::VariableCheck qw(:all);
use parent qw( Kernel::System::UnitTest::TicketToUnitTest::Base );

sub Run {
    my ( $Self, %Param ) = @_;

    my $DynamicFieldObject = $Kernel::OM->Get('Kernel::System::DynamicField');
    my $MainObject         = $Kernel::OM->Get('Kernel::System::Main');

    return '' if !IsArrayRefWithData( $Param{DynamicField} );

    my $Output = sprintf <<OUTPUT;

# DynamicField setup

OUTPUT

    for my $DynamicField ( @{ $Param{DynamicField} } ) {

        my $DynamicFieldConfig = $DynamicFieldObject->DynamicFieldGet(
            Name => $DynamicField,
        );

        my $ConfigDump = $MainObject->Dump( $DynamicFieldConfig->{Config} );
        $ConfigDump =~ s/\$VAR1 =//;
        $ConfigDump =~ s/\;//;

        $Output .= <<OUTPUT;
## DynamicField '$DynamicFieldConfig->{Name}'

\$ZnunyHelperObject->_DynamicFieldsCreateIfNotExists(
    {
        Name       => '$DynamicFieldConfig->{Name}',
        Label      => '$DynamicFieldConfig->{Label}',
        ObjectType => '$DynamicFieldConfig->{ObjectType}',
        FieldType  => '$DynamicFieldConfig->{FieldType}',
        Config     => $ConfigDump
    },
);

OUTPUT

    }

    return $Output;

}

1;
