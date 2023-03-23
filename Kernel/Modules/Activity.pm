# --
# Copyright (C) 2021 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::Modules::Activity;

use strict;
use warnings;

use Kernel::Language qw(Translatable);

our @ObjectDependencies = (
    'Kernel::Output::HTML::Layout',
    'Kernel::System::Activity',
    'Kernel::System::JSON',
    'Kernel::System::Web::Request',
);

sub new {
    my ( $Type, %Param ) = @_;

    my $Self = {%Param};
    bless( $Self, $Type );

    return $Self;
}

sub Run {
    my ( $Self, %Param ) = @_;

    my $JSONObject     = $Kernel::OM->Get('Kernel::System::JSON');
    my $LayoutObject   = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $ActivityObject = $Kernel::OM->Get('Kernel::System::Activity');

    my %Data = (
        Success => 0,
    );
    my $Success;
    my %GetParams = $Self->_GetParams();

    if ( $GetParams{Subaction} eq "Add" ) {
        $Data{ActivityID} = $ActivityObject->Add(
            %GetParams,
            UserID   => $Self->{UserID},
            CreateBy => $Self->{UserID},
        );

        $Data{Success} = 1 if $Data{ActivityID};

        my %Activity = $ActivityObject->Get(
            UserID => $Self->{UserID},
            ID     => $Data{ActivityID},
        );

        %Data = ( %Data, %Activity );
    }
    elsif ( $GetParams{Subaction} eq "Update" ) {
        $Data{Success} = $ActivityObject->DataUpdate(
            %GetParams,
            ID     => $GetParams{ActivityID},
            UserID => $Self->{UserID},
        );

        my %Activity = $ActivityObject->Get(
            ID     => $GetParams{ActivityID},
            UserID => $Self->{UserID},
        );
        %Data = ( %Data, %Activity );
    }
    elsif ( $GetParams{Subaction} eq "Delete" ) {
        $Data{Success} = $ActivityObject->DataDelete(
            ID     => $GetParams{ActivityID},
            UserID => $Self->{UserID},
        );
    }
    elsif ( $GetParams{Subaction} eq "DeleteAll" ) {
        $Data{Success} = $ActivityObject->DataDelete(
            UserID => $Self->{UserID},
        );
    }
    elsif ( $GetParams{Subaction} eq "MarkAsSeenAll" ) {
        my @Activities = $ActivityObject->DataListGet(
            %Param,
            UserID => $Self->{UserID},
        );

        $Data{Success} = 1;
        for my $Activity (@Activities) {
            my $Success = $ActivityObject->DataUpdate(
                State  => 'seen',
                ID     => $Activity->{ID},
                UserID => $Self->{UserID},
            );

            $Data{Success} = 0 if !$Success;
        }
    }

    my $JSONEncodedData = $JSONObject->Encode(
        Data => \%Data,
    );

    return $LayoutObject->Attachment(
        ContentType => 'application/json; charset=' . $LayoutObject->{Charset},
        Content     => $JSONEncodedData,
        Type        => 'inline',
        NoCache     => 1,
    );
}

=head2 _GetParams()

Gets the params of an admin interface submit.

    my %GetParams = $Self->_GetParams();

Returns:

    my %GetParams = (
        String => 1,
        ...
    );

=cut

sub _GetParams {
    my ( $Self, %Param ) = @_;

    my $ParamObject = $Kernel::OM->Get('Kernel::System::Web::Request');

    my @ParamNames = $ParamObject->GetParamNames();

    my %GetParams;

    PARAMNAME:
    for my $ParamName (@ParamNames) {
        $GetParams{$ParamName} = $ParamObject->GetParam( Param => $ParamName );

        my @Params = $ParamObject->GetArray(
            Param => $ParamName,
            Raw   => 1,
        );

        next PARAMNAME if !@Params;
        next PARAMNAME if @Params <= 1;

        $GetParams{$ParamName} = \@Params;
    }

    return %GetParams;
}

1;
