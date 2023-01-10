# --
# Copyright (C) 2021 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --
## nofilter(TidyAll::Plugin::Znuny::Perl::ParamObject)

package Kernel::System::Ticket::Acl::TicketAttributeRelations;

use strict;
use warnings;

our @ObjectDependencies = (
    'Kernel::Config',
    'Kernel::System::Log',
    'Kernel::System::Ticket',
    'Kernel::System::TicketAttributeRelations',
    'Kernel::System::Web::Request',
);

use Kernel::System::VariableCheck qw(:all);

sub new {
    my ( $Type, %Param ) = @_;

    my $Self = {};
    bless( $Self, $Type );

    return $Self;
}

sub Run {
    my ( $Self, %Param ) = @_;

    my $LogObject                      = $Kernel::OM->Get('Kernel::System::Log');
    my $ConfigObject                   = $Kernel::OM->Get('Kernel::Config');
    my $ParamObject                    = $Kernel::OM->Get('Kernel::System::Web::Request');
    my $TicketObject                   = $Kernel::OM->Get('Kernel::System::Ticket');
    my $TicketAttributeRelationsObject = $Kernel::OM->Get('Kernel::System::TicketAttributeRelations');

    NEEDED:
    for my $Needed (qw(Config Acl)) {
        next NEEDED if $Param{$Needed};

        $LogObject->Log(
            Priority => 'error',
            Message  => "Need $Needed!"
        );
        return;
    }

    my $UserID = 1;

    my $AlwaysPossibleNone = $ConfigObject->Get('Core::TicketAttributeRelations::AlwaysPossibleNone') // 1;
    my %Backends           = %{ $ConfigObject->Get('Core::TicketAttributeRelations::Backend') // {} };

    my $TicketAttributeRelations = $TicketAttributeRelationsObject->GetAllTicketAttributeRelations(
        UserID => $UserID,
    );
    return 1 if !IsArrayRefWithData($TicketAttributeRelations);

    my @TicketAttributeRelations = sort { $a->{Priority} <=> $b->{Priority} } @{$TicketAttributeRelations};

    my $ACLRelatedAttributeData = {};
    my $ACLEmptyAttributes      = {};

    my $Subaction  = $ParamObject->GetParam( Param => 'Subaction' ) // '';
    my $AJAXUpdate = $Subaction eq 'AJAXUpdate' ? 1 : 0;

    my %Ticket;
    if ( $Param{Checks}->{Ticket}->{TicketID} ) {
        %Ticket = $TicketObject->TicketGet(
            TicketID      => $Param{Checks}->{Ticket}->{TicketID},
            DynamicFields => 1,
            UserID        => 1,
        );
    }

    TICKETATTRIBUTERELATIONS:
    for my $TicketAttributeRelations (@TicketAttributeRelations) {
        my $Attribute1 = $TicketAttributeRelations->{Attribute1};
        my $Attribute2 = $TicketAttributeRelations->{Attribute2};

        my @ChecksAttributeValues = $Self->_GetAsArray(
            Data => $Param{Checks}->{Ticket}->{$Attribute1},
        );

        my @TicketValues = $Self->_GetAsArray(
            Data => $Ticket{$Attribute1},
        );

        my @ACLActionAttribute1Values;
        if (@ChecksAttributeValues) {
            @ACLActionAttribute1Values = @ChecksAttributeValues;
        }

        # TicketACL is not working correctly in AgentTicketFreeText.
        # The problem is that Param->Checks->Ticket->Attribute_... is not returning the correct saved ticket data
        # so it makes no sense to check it. But in AgentTicketFreeText we need the saved ticket data of the ticket
        # so we make sure that it's not an AJAX request and then we use the ticket data as fallback.
        elsif ( !$AJAXUpdate && @TicketValues ) {
            @ACLActionAttribute1Values = @TicketValues;
        }

        # Check if checked attribute is set empty in previous ACL settings.
        my $ACLEmptyAttribute1 = $ACLEmptyAttributes->{$Attribute1} ? 1 : 0;

        # If no attribute values are set or the related attributes of previous ACL settings are
        # empty, then we have to set an empty ACL for this attribute relation.
        if ( ( !@ACLActionAttribute1Values || $ACLEmptyAttribute1 ) && !$TicketAttributeRelations->{Restrictive} ) {

            # Save attribute 2 as empty attribute for following ACL settings.
            $ACLEmptyAttributes->{$Attribute2} = 1;
        }
        else {

            # Loop over all given settings and check if the values of the ACL action
            # are possible in this case.
            #
            # This is needed to be sure if there are more than 2 related attributes that all
            # shown attribute values are valid.
            # So remove all invalid ACL action attribute values which would
            # be not possible for the configuration of the related attributes.
            my @ACLActionAttribute1PossibleValues;
            VALUE:
            for my $Value (@ACLActionAttribute1Values) {
                my @RelatedData = @{ $ACLRelatedAttributeData->{$Attribute1} || [] };

                if (@RelatedData) {
                    my $RelatedValueFound = grep { $_ eq $Value } @RelatedData;
                    next VALUE if !$RelatedValueFound;
                }

                push @ACLActionAttribute1PossibleValues, $Value;
            }

            # Loop over all data for attribute 1 and
            # create a list of all attribute values for attribute 2.
            my @ACLData;
            DATA:
            for my $Data ( @{ $TicketAttributeRelations->{Data} || [] } ) {
                my $Attribute1Value = $Data->{$Attribute1};
                my $Attribute2Value = $Data->{$Attribute2};

                # Skip all attribute values which are not possible for the ACL action.
                my $ACLActionValueFound = grep { $_ eq $Attribute1Value } @ACLActionAttribute1PossibleValues;
                next DATA if !$ACLActionValueFound;

                # Prevent duplicate values for the ACL data.
                my $ACLValueFound = grep { $_ eq $Attribute2Value } @ACLData;
                next DATA if $ACLValueFound;

                push @ACLData, $Attribute2Value;
            }

            # Restrictive mode restricts values multiple times,
            # e.g. you can have one ACL list with queue 1, 2, 3
            # and another one which restricts on 1, 2.
            # So the result will be that only 1, 2 are displayed.
            # The order of the ACL lists is important for correct restrictions.
            # If we have no values for the restriction we just add all values
            # and further ACL lists will remove the values which are not contained in both lists.
            my $ACLRelatedAttributeData2Count = scalar @{ $ACLRelatedAttributeData->{$Attribute2} || [] };
            if ( $TicketAttributeRelations->{Restrictive} && $ACLRelatedAttributeData2Count ) {
                my %ValuesBefore = map { $_ => 1 } @{ $ACLRelatedAttributeData->{$Attribute2} };
                my %ValuesNew    = map { $_ => 1 } @ACLData;

                my @NewAttributeData2;
                VALUE:
                for my $Value ( sort keys %ValuesBefore, sort keys %ValuesNew ) {
                    if ( $Value ne '' ) {
                        next VALUE if !$ValuesBefore{$Value};
                        next VALUE if !$ValuesNew{$Value};
                    }

                    push @NewAttributeData2, $Value;
                }

                @{ $ACLRelatedAttributeData->{$Attribute2} } = @NewAttributeData2;
            }
            else {

                # Add values for the ACL configuration.
                $ACLRelatedAttributeData->{$Attribute2} ||= ( $AlwaysPossibleNone ? [''] : [] );

                # This is the default mode
                push @{ $ACLRelatedAttributeData->{$Attribute2} }, @ACLData;
            }
        }
    }

    my $ACLCounter = 10_000;
    my %ACLAttributeSet;

    my $AttributeACLActions = $ConfigObject->Get('Core::TicketAttributeRelations::ACLActions') // [];

    # Loop over all ACL data (sorted by priority) and output ACLs.
    TICKETATTRIBUTERELATIONS:
    for my $TicketAttributeRelations (@TicketAttributeRelations) {
        my $Attribute1 = $TicketAttributeRelations->{Attribute1};
        my $Attribute2 = $TicketAttributeRelations->{Attribute2};

        # Check if attribute is already set in ACL.
        next TICKETATTRIBUTERELATIONS if $ACLAttributeSet{$Attribute2};

        my $PossibleData = $ACLRelatedAttributeData->{$Attribute2} || ( $AlwaysPossibleNone ? [''] : [] );

        $Param{Acl}->{ $ACLCounter . '-TicketAttributeRelations' } = {
            'Properties' => {
                'Frontend' => {

                    # Add restriction for frontends, else it will make trouble
                    # in AgentTicketSearch and AdminGenericAgent.
                    'Action' => $AttributeACLActions,
                },
            },
            'Possible' => {
                'Ticket' => {
                    $Attribute2 => $PossibleData,
                },
            },
            'PossibleAdd'        => {},
            'PossibleNot'        => {},
            'PropertiesDatabase' => {},
            'StopAfterMatch'     => 0,
        };

        $ACLAttributeSet{$Attribute2} = 1;
        $ACLCounter++;
    }

    return 1;
}

sub _GetAsArray {
    my ( $Self, %Param ) = @_;

    my @Data;
    if ( IsArrayRefWithData( $Param{Data} ) ) {
        @Data = @{ $Param{Data} };
    }
    elsif ( IsStringWithData( $Param{Data} ) ) {
        @Data = ( $Param{Data} );
    }

    return @Data;
}

1;
