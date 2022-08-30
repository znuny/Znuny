# --
# Copyright (C) 2021-2022 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::SysConfig::ValueType::Entity::SLA;

## nofilter(TidyAll::Plugin::OTRS::Perl::ParamObject)

use strict;
use warnings;

use Kernel::System::VariableCheck qw(:all);

use parent qw(Kernel::System::SysConfig::ValueType::Entity);

our @ObjectDependencies = (
    'Kernel::System::SLA',
    'Kernel::System::Web::Request',
);

=head1 NAME

Kernel::System::SysConfig::ValueType::Entity::SLA - System configuration system address entity type backend.

=head1 PUBLIC INTERFACE

=head2 new()

Create an object. Do not use it directly, instead use:

    use Kernel::System::ObjectManager;
    local $Kernel::OM = Kernel::System::ObjectManager->new();
    my $EntityTypeObject = $Kernel::OM->Get('Kernel::System::SysConfig::ValueType::Entity::SLA');

=cut

sub new {
    my ( $Type, %Param ) = @_;

    my $Self = {};
    bless( $Self, $Type );

    return $Self;
}

sub EntityValueList {
    my ( $Self, %Param ) = @_;

    my $SLAObject = $Kernel::OM->Get('Kernel::System::SLA');

    my %SLAs = $SLAObject->SLAList(
        Valid  => 1,
        UserID => 1,
    );

    my @Result = map { $SLAs{$_} } sort keys %SLAs;

    return @Result;
}

sub EntityLookupFromWebRequest {
    my ( $Self, %Param ) = @_;

    my $ParamObject = $Kernel::OM->Get('Kernel::System::Web::Request');
    my $SLAObject   = $Kernel::OM->Get('Kernel::System::SLA');

    my $SLAID = $ParamObject->GetParam( Param => 'ID' ) // $ParamObject->GetParam( Param => 'SLAID' );
    return if !$SLAID;

    my $SLA = $SLAObject->SLALookup(
        SLAID => $SLAID,
    );
    return $SLA;
}

1;
