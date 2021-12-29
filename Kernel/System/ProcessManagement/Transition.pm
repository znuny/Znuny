# --
# Copyright (C) 2001-2021 OTRS AG, https://otrs.com/
# Copyright (C) 2021 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see https://www.gnu.org/licenses/gpl-3.0.txt.
# --

package Kernel::System::ProcessManagement::Transition;

use strict;
use warnings;

use Kernel::Language qw(Translatable);
use Kernel::System::VariableCheck qw(:all);

our @ObjectDependencies = (
    'Kernel::Config',
    'Kernel::System::Log',
    'Kernel::System::Main',
);

=head1 NAME

Kernel::System::ProcessManagement::Transition - Transition lib

=head1 DESCRIPTION

All Process Management Transition functions.

=head1 PUBLIC INTERFACE

=head2 new()

Don't use the constructor directly, use the ObjectManager instead:

    my $TransitionObject = $Kernel::OM->Get('Kernel::System::ProcessManagement::Transition');

=cut

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {};
    bless( $Self, $Type );

    # get config object
    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');

    # get the debug parameters
    $Self->{TransitionDebug} = $ConfigObject->Get('ProcessManagement::Transition::Debug::Enabled') || 0;
    $Self->{TransitionDebugLogPriority}
        = $ConfigObject->Get('ProcessManagement::Transition::Debug::LogPriority') || 'debug';

    my $TransitionDebugConfigFilters = $ConfigObject->Get('ProcessManagement::Transition::Debug::Filter') || {};

    for my $FilterName ( sort keys %{$TransitionDebugConfigFilters} ) {

        my %Filter = %{ $TransitionDebugConfigFilters->{$FilterName} };

        for my $FilterItem ( sort keys %Filter ) {
            $Self->{TransitionDebugFilters}->{$FilterItem} = $Filter{$FilterItem};
        }
    }

    return $Self;
}

=head2 TransitionGet()

    Get Transition info

    my $Transition = $TransitionObject->TransitionGet(
        TransitionEntityID => 'T1',
    );

    Returns:

    $Transition = {
        Name       => 'Transition 1',
        CreateTime => '08-02-2012 13:37:00',
        ChangeBy   => '2',
        ChangeTime => '09-02-2012 13:37:00',
        CreateBy   => '3',
        Condition  => {
            Type   => 'and',
            Cond1  => {
                Type   => 'and',
                Fields => {
                    DynamicField_Make    => [ '2' ],
                    DynamicField_VWModel => {
                        Type  => 'String',
                        Match => 'Golf',
                    },
                    DynamicField_A => {
                        Type  => 'Hash',
                        Match => {
                            Value  => 1,
                        },
                    },
                    DynamicField_B => {
                        Type  => 'Regexp',
                        Match => qr{ [\n\r\f] }xms
                    },
                    DynamicField_C => {
                        Type  => 'Module',
                        Match =>
                            'Kernel::System::ProcessManagement::TransitionValidation::MyModule',
                    },
                    Queue =>  {
                        Type  => 'Array',
                        Match => [ 'Raw' ],
                    },
                    # ...
                }
            }
            # ...
        },
    };

=cut

sub TransitionGet {
    my ( $Self, %Param ) = @_;

    my $LogObject = $Kernel::OM->Get('Kernel::System::Log');

    NEEDED:
    for my $Needed (qw(TransitionEntityID)) {
        next NEEDED if defined $Param{$Needed};
        $LogObject->Log(
            Priority => 'error',
            Message  => "Need $Needed!",
        );
        return;
    }

    my $Transition = $Kernel::OM->Get('Kernel::Config')->Get('Process::Transition');

    if ( !IsHashRefWithData($Transition) ) {
        $LogObject->Log(
            Priority => 'error',
            Message  => 'Need Transition config!',
        );
        return;
    }

    if ( !IsHashRefWithData( $Transition->{ $Param{TransitionEntityID} } ) ) {
        $LogObject->Log(
            Priority => 'error',
            Message  => "No data for Transition '$Param{TransitionEntityID}' found!",
        );
        return;
    }

    return $Transition->{ $Param{TransitionEntityID} };
}

=head2 TransitionCheck()

Checks if one or more Transition Conditions are true.

    my $TransitionCheck = $TransitionObject->TransitionCheck(
        TransitionEntityID => 'T1',
        or
        TransitionEntityID => ['T1', 'T2', 'T3'],
        Data       => {
            Queue         => 'Raw',
            DynamicField1 => 'Value',
            Subject       => 'Testsubject',
            ...
        },
    );

Returns:
    If called on a single TransitionEntityID

    $Checked = 1;       # 0

Returns:
    If called on an array of TransitionEntityIDs

    $Checked = 'T1'     # 0 if no Transition was true

=cut

sub TransitionCheck {
    my ( $Self, %Param ) = @_;

    my $LogObject  = $Kernel::OM->Get('Kernel::System::Log');
    my $MainObject = $Kernel::OM->Get('Kernel::System::Main');

    # Check if we have TransitionEntityID and Data.
    NEEDED:
    for my $Needed (qw(TransitionEntityID Data)) {
        next NEEDED if defined $Param{$Needed};
        $LogObject->Log(
            Priority => 'error',
            Message  => "Need $Needed!",
        );
        return;
    }

    # Check if TransitionEntityID is not empty (either Array or String with length).
    if ( !length $Param{TransitionEntityID} ) {
        $LogObject->Log(
            Priority => 'error',
            Message  => "Need TransitionEntityID or TransitionEntityID array!",
        );
        return;
    }

    # Check if debug filters apply (ticket).
    if ( $Self->{TransitionDebug} ) {

        DEBUGFILTER:
        for my $DebugFilter ( sort keys %{ $Self->{TransitionDebugFilters} } ) {
            next DEBUGFILTER if $DebugFilter eq 'TransitionEntityID';
            next DEBUGFILTER if !$Self->{TransitionDebugFilters}->{$DebugFilter};
            next DEBUGFILTER if ref $Param{Data} ne 'HASH';

            if ( $DebugFilter =~ m{<OTRS_TICKET_([^>]+)>}msx ) {
                my $TicketParam = $1;

                if (
                    defined $Param{Data}->{$TicketParam}
                    && $Param{Data}->{$TicketParam}
                    )
                {
                    if ( ref $Param{Data}->{$TicketParam} eq 'ARRAY' ) {
                        for my $Item ( @{ $Param{Data}->{$TicketParam} } ) {

                            # If matches for one item go to next filter (debug keeps active).
                            if ( $Self->{TransitionDebugFilters}->{$DebugFilter} eq $Item ) {
                                next DEBUGFILTER;
                            }
                        }

                        # If no matches then deactivate debug.
                        $Self->{TransitionDebug} = 0;
                        last DEBUGFILTER;
                    }

                    elsif (
                        $Self->{TransitionDebugFilters}->{$DebugFilter} ne
                        $Param{Data}->{$TicketParam}
                        )
                    {
                        $Self->{TransitionDebug} = 0;
                        last DEBUGFILTER;
                    }

                    elsif ( !defined $Param{Data}->{$TicketParam} ) {
                        $Self->{TransitionDebug} = 0;
                        last DEBUGFILTER;
                    }
                }
            }
        }
    }

    # If we got just a string, make $Param{TransitionEntityID} an Array with the string on position
    #   0 to facilitate handling
    if ( !IsArrayRefWithData( $Param{TransitionEntityID} ) ) {
        $Param{TransitionEntityID} = [ $Param{TransitionEntityID} ];
    }

    # Check if we have Data to check against transitions conditions.
    if ( !IsHashRefWithData( $Param{Data} ) ) {
        $LogObject->Log(
            Priority => 'error',
            Message  => "Data has no values!",
        );
        return;
    }

    # Get all transitions.
    my $Transitions = $Kernel::OM->Get('Kernel::Config')->Get('Process::Transition');

    # Check if there are Transitions.
    if ( !IsHashRefWithData($Transitions) ) {
        $LogObject->Log(
            Priority => 'error',
            Message  => 'Need transition config!',
        );
        return;
    }

    $Self->{TransitionDebugOrig} = $Self->{TransitionDebug};

    my %TransitionValidation = $Self->TransitionValidationTypeListGet();

    # Loop through all submitted TransitionEntityID's.
    TRANSITIONENTITYID:
    for my $TransitionEntityID ( @{ $Param{TransitionEntityID} } ) {

        $Self->{TransitionDebug} = $Self->{TransitionDebugOrig};

        # Check if debug filters apply (Transition) (only if TransitionDebug is active).
        if (
            $Self->{TransitionDebug}
            && defined $Self->{TransitionDebugFilters}->{'TransitionEntityID'}
            && $Self->{TransitionDebugFilters}->{'TransitionEntityID'} ne $TransitionEntityID
            )
        {
            $Self->{TransitionDebug} = 0;
        }

        # Check if the submitted TransitionEntityID has a config.
        if ( !IsHashRefWithData( $Transitions->{$TransitionEntityID} ) ) {
            $LogObject->Log(
                Priority => 'error',
                Message  => "No config data for transition $TransitionEntityID found!",
            );
            return;
        }

        # Check if we have TransitionConditions.
        if ( !IsHashRefWithData( $Transitions->{$TransitionEntityID}->{Condition} ) ) {
            $LogObject->Log(
                Priority => 'error',
                Message  => "No conditions for transition $TransitionEntityID found!",
            );
            return;
        }

        my $ConditionLinking = $Transitions->{$TransitionEntityID}->{ConditionLinking} || '';

        # If we don't have a ConditionLinking set it to 'and' by default compatibility with OTRS 3.3.x
        if ( !$ConditionLinking ) {
            $ConditionLinking = $Transitions->{$TransitionEntityID}->{Condition}->{Type} || 'and';
        }
        if (
            !$Transitions->{$TransitionEntityID}->{Condition}->{ConditionLinking}
            && !$Transitions->{$TransitionEntityID}->{Condition}->{Type}
            )
        {

            $Self->DebugLog(
                MessageType => 'Custom',
                Message =>
                    "Transition:'$Transitions->{$TransitionEntityID}->{Name}' No Condition Linking"
                    . " as Condition->Type or Condition->ConditionLinking was found, using 'and' as"
                    . " default!",
            );
        }

        # If there is something else than 'and', 'or', 'xor' log defect Transition Config.
        if (
            $ConditionLinking ne 'and'
            && $ConditionLinking ne 'or'
            && $ConditionLinking ne 'xor'
            )
        {
            $LogObject->Log(
                Priority => 'error',
                Message  => "Invalid Condition->Type in $TransitionEntityID!",
            );
            return;
        }
        my ( $ConditionSuccess, $ConditionFail ) = ( 0, 0 );

        CONDITIONNAME:
        for my $ConditionName (
            sort { $a cmp $b }
            keys %{ $Transitions->{$TransitionEntityID}->{Condition} }
            )
        {

            next CONDITIONNAME if $ConditionName eq 'Type' || $ConditionName eq 'ConditionLinking';

            # Get the condition.
            my $ActualCondition = $Transitions->{$TransitionEntityID}->{Condition}->{$ConditionName};

            # Check if we have Fields in our Condition.
            if ( !IsHashRefWithData( $ActualCondition->{Fields} ) )
            {
                $LogObject->Log(
                    Priority => 'error',
                    Message  => "No Fields in Transition $TransitionEntityID->Condition->$ConditionName"
                        . " found!",
                );
                return;
            }

            # If we don't have a Condition->$ConditionName->Type, set it to 'and' by default.
            my $CondType = $ActualCondition->{Type} || 'and';
            if ( !$ActualCondition->{Type} ) {
                $Self->DebugLog(
                    MessageType => 'Custom',
                    Message =>
                        "Transition:'$Transitions->{$TransitionEntityID}->{Name}' Condition:'$ConditionName'"
                        . " No Condition Type found, using 'and' as default",
                );
            }

            # If there is something else than 'and', 'or', 'xor' log defect Transition Config.
            if ( $CondType ne 'and' && $CondType ne 'or' && $CondType ne 'xor' ) {
                $LogObject->Log(
                    Priority => 'error',
                    Message  => "Invalid Condition->$ConditionName->Type in $TransitionEntityID!",
                );
                return;
            }

            my ( $FieldSuccess, $FieldFail ) = ( 0, 0 );

            FIELDLNAME:
            for my $FieldName ( sort keys %{ $ActualCondition->{Fields} } ) {

                # If we have just a String transform it into string check condition.
                if ( ref $ActualCondition->{Fields}->{$FieldName} eq '' ) {
                    $ActualCondition->{Fields}->{$FieldName} = {
                        Type  => 'String',
                        Match => $ActualCondition->{Fields}->{$FieldName},
                    };
                }

                # If we have an Array ref in "Fields" we deal with just values
                #   -> transform it into a { Type => 'Array', Match => [1,2,3,4] } structure
                #   to unify testing later on.
                if ( ref $ActualCondition->{Fields}->{$FieldName} eq 'ARRAY' ) {
                    $ActualCondition->{Fields}->{$FieldName} = {
                        Type  => 'Array',
                        Match => $ActualCondition->{Fields}->{$FieldName},
                    };
                }

                # If we don't have a Condition->$ConditionName->Fields->Field->Type set it to
                #   'String' by default.
                my $FieldType = $ActualCondition->{Fields}->{$FieldName}->{Type} || 'String';
                if ( !$ActualCondition->{Fields}->{$FieldName}->{Type} ) {
                    $Self->DebugLog(
                        MessageType => 'Custom',
                        Message =>
                            "Transition:'$Transitions->{$TransitionEntityID}->{Name}'"
                            . " Condition:'$ConditionName' Field:'$FieldName'"
                            . " No Field Type found, using 'String' as default",
                    );
                }

                my @ComplexTypes  = ( 'Array', 'Hash' );
                my $IsComplexType = grep { $FieldType eq $_ } @ComplexTypes;

                if ( $FieldType && %TransitionValidation && !$TransitionValidation{$FieldType} && !$IsComplexType ) {
                    $LogObject->Log(
                        Priority => 'error',
                        Message  => "Invalid Condition->Type in $TransitionEntityID!",
                    );
                    return;
                }

                my $ValidateModuleObject;
                if ( !$IsComplexType ) {

                    my $Module = $TransitionValidation{ $ActualCondition->{Fields}->{$FieldName}->{Type} }->{Module};

                    if ( $ActualCondition->{Fields}->{$FieldName}->{Type} eq 'Module' ) {
                        $Module = $ActualCondition->{Fields}->{$FieldName}->{Match};
                    }

                    # check if transition validation module exists
                    if ( !$MainObject->Require($Module) ) {
                        $LogObject->Log(
                            Priority => 'error',
                            Message  => "Can't load transition validation "
                                . $ActualCondition->{Fields}->{$FieldName}->{Type}
                                . " module for Transition->$TransitionEntityID->Condition->$ConditionName->"
                                . "Fields->$FieldName validation!",
                        );
                        return;
                    }

                    $ValidateModuleObject = $Module->new(
                        %{$Self},
                        %Param,
                    );
                }

                if ( $ActualCondition->{Fields}->{$FieldName}->{Type} eq 'String' ) {

                    # Handle "Data" Param to ValidateModule's "Validate" subroutine.
                    my $Match = $ValidateModuleObject->Validate(
                        Data               => $Param{Data},
                        FieldName          => $FieldName,
                        Transition         => $Transitions->{$TransitionEntityID},
                        TransitionName     => $Transitions->{$TransitionEntityID}->{Name},
                        TransitionEntityID => $TransitionEntityID,
                        Condition          => $ActualCondition->{Fields}->{$FieldName},
                        ConditionName      => $ConditionName,
                        ConditionType      => $CondType,
                        ConditionLinking   => $ConditionLinking,
                    );

                    if ($Match) {
                        $FieldSuccess++;

                        # Successful check if we just need one matching Condition to make this
                        #   Transition valid.
                        if ( $ConditionLinking eq 'or' && $CondType eq 'or' ) {

                            $Self->DebugLog(
                                MessageType      => 'Success',
                                TransitionName   => $Transitions->{$TransitionEntityID}->{Name},
                                ConditionName    => $ConditionName,
                                ConditionType    => $CondType,
                                ConditionLinking => $ConditionLinking,
                            );

                            return $TransitionEntityID;
                        }

                        next CONDITIONNAME if $ConditionLinking ne 'or' && $CondType eq 'or';
                    }
                    else {
                        $FieldFail++;

                        my $UnmatchedValue = $Param{Data}->{$FieldName};
                        if ( ref $Param{Data}->{$FieldName} eq 'ARRAY' ) {
                            $UnmatchedValue = 'Any of [' . join( ', ', @{ $Param{Data}->{$FieldName} } ) . ']';
                        }

                        $Self->DebugLog(
                            MessageType    => 'NoMatch',
                            TransitionName => $Transitions->{$TransitionEntityID}->{Name},
                            ConditionName  => $ConditionName,
                            FieldName      => $FieldName,
                            MatchType      => 'String',
                            MatchValue     => $UnmatchedValue,
                            MatchCondition => $ActualCondition->{Fields}->{$FieldName}->{Match}
                        );

                        # Failed check if we have all 'and' conditions.
                        next TRANSITIONENTITYID if $ConditionLinking eq 'and' && $CondType eq 'and';

                        # Try next Condition if all Condition Fields have to be true.
                        next CONDITIONNAME if $CondType eq 'and';
                    }
                    next FIELDLNAME;
                }
                elsif ( $ActualCondition->{Fields}->{$FieldName}->{Type} eq 'Array' ) {

                  # 1. go through each Condition->$ConditionName->Fields->$Field->Value (map).
                  # 2. assign the value to $CheckValue.
                  # 3. grep through $Data->{$FieldName} to find the "toCheck" value inside the Data->{$FieldName} Array.
                  # 4. Assign all found Values to @CheckResults.
                    my $CheckValue;
                    my @CheckResults = map {
                        $CheckValue = $_;
                        grep { $CheckValue eq $_ } @{ $Param{Data}->{$FieldName} }
                        }
                        @{ $ActualCondition->{Fields}->{$FieldName}->{Match} };

                    # If the found amount is the same as the "toCheck" amount we succeeded.
                    if (
                        scalar @CheckResults
                        == scalar @{ $ActualCondition->{Fields}->{$FieldName}->{Match} }
                        )
                    {
                        $FieldSuccess++;

                        $Self->DebugLog(
                            MessageType    => 'Match',
                            TransitionName => $Transitions->{$TransitionEntityID}->{Name},
                            ConditionName  => $ConditionName,
                            FieldName      => $FieldName,
                            MatchType      => 'Array',
                        );

                        # Successful check if we just need one matching Condition to make this Transition valid.
                        if ( $ConditionLinking eq 'or' && $CondType eq 'or' ) {

                            $Self->DebugLog(
                                MessageType      => 'Success',
                                TransitionName   => $Transitions->{$TransitionEntityID}->{Name},
                                ConditionName    => $ConditionName,
                                ConditionType    => $CondType,
                                ConditionLinking => $ConditionLinking,

                            );

                            return $TransitionEntityID;
                        }

                        next CONDITIONNAME if $ConditionLinking ne 'or' && $CondType eq 'or';
                    }
                    else {
                        $FieldFail++;

                        $Self->DebugLog(
                            MessageType    => 'NoMatch',
                            TransitionName => $Transitions->{$TransitionEntityID}->{Name},
                            ConditionName  => $ConditionName,
                            FieldName      => $FieldName,
                            MatchType      => 'Array',
                        );

                        # Failed check if we have all 'and' conditions.
                        next TRANSITIONENTITYID if $ConditionLinking eq 'and' && $CondType eq 'and';

                        # Try next Condition if all Condition Fields have to be true.
                        next CONDITIONNAME if $CondType eq 'and';
                    }
                    next FIELDLNAME;
                }
                elsif ( $ActualCondition->{Fields}->{$FieldName}->{Type} eq 'Hash' ) {

                    # If our Check doesn't contain a hash.
                    if ( ref $ActualCondition->{Fields}->{$FieldName}->{Match} ne 'HASH' ) {
                        $LogObject->Log(
                            Priority => 'error',
                            Message =>
                                "$TransitionEntityID->Condition->$ConditionName->Fields->$FieldName: Match must"
                                . " be a hash!",
                        );
                        return;
                    }

                    # If we have no data or Data isn't a hash, test failed.
                    if (
                        !$Param{Data}->{$FieldName}
                        || ref $Param{Data}->{$FieldName} ne 'HASH'
                        )
                    {
                        $FieldFail++;
                        next FIELDLNAME;
                    }

                    # Find all Data Hash values that equal to the Condition Match Values.
                    my @CheckResults = grep {
                        $Param{Data}->{$FieldName}->{$_} eq
                            $ActualCondition->{Fields}->{$FieldName}->{Match}->{$_}
                    } keys %{ $ActualCondition->{Fields}->{$FieldName}->{Match} };

                    # If the amount of Results equals the amount of Keys in our hash this part matched.
                    if (
                        scalar @CheckResults
                        == scalar keys %{ $ActualCondition->{Fields}->{$FieldName}->{Match} }
                        )
                    {

                        $FieldSuccess++;

                        $Self->DebugLog(
                            MessageType    => 'Match',
                            TransitionName => $Transitions->{$TransitionEntityID}->{Name},
                            ConditionName  => $ConditionName,
                            FieldName      => $FieldName,
                            MatchType      => 'Hash',
                        );

                        # Successful check if we just need one matching Condition to make this Transition valid.
                        if ( $ConditionLinking eq 'or' && $CondType eq 'or' ) {

                            $Self->DebugLog(
                                MessageType      => 'Success',
                                TransitionName   => $Transitions->{$TransitionEntityID}->{Name},
                                ConditionName    => $ConditionName,
                                ConditionType    => $CondType,
                                ConditionLinking => $ConditionLinking,
                            );

                            return $TransitionEntityID;
                        }

                        next CONDITIONNAME if $ConditionLinking ne 'or' && $CondType eq 'or';

                    }
                    else {
                        $FieldFail++;

                        $Self->DebugLog(
                            MessageType    => 'NoMatch',
                            TransitionName => $Transitions->{$TransitionEntityID}->{Name},
                            ConditionName  => $ConditionName,
                            FieldName      => $FieldName,
                            MatchType      => 'Hash',
                        );

                        # Failed check if we have all 'and' conditions.
                        next TRANSITIONENTITYID if $ConditionLinking eq 'and' && $CondType eq 'and';

                        # Try next Condition if all Condition Fields have to be true.
                        next CONDITIONNAME if $CondType eq 'and';
                    }
                    next FIELDLNAME;
                }
                elsif ( $ActualCondition->{Fields}->{$FieldName}->{Type} eq 'Regexp' ) {

                    # Handle "Data" Param to ValidateModule's "Validate" subroutine.
                    my $Match = $ValidateModuleObject->Validate(
                        Data               => $Param{Data},
                        FieldName          => $FieldName,
                        Transition         => $Transitions->{$TransitionEntityID},
                        TransitionName     => $Transitions->{$TransitionEntityID}->{Name},
                        TransitionEntityID => $TransitionEntityID,
                        Condition          => $ActualCondition->{Fields}->{$FieldName},
                        ConditionName      => $ConditionName,
                        ConditionType      => $CondType,
                        ConditionLinking   => $ConditionLinking,
                    );

                    if ($Match) {
                        $FieldSuccess++;

                        # Successful check if we just need one matching Condition to make this Transition valid.
                        if ( $ConditionLinking eq 'or' && $CondType eq 'or' ) {

                            $Self->DebugLog(
                                MessageType      => 'Success',
                                TransitionName   => $Transitions->{$TransitionEntityID}->{Name},
                                ConditionName    => $ConditionName,
                                ConditionType    => $CondType,
                                ConditionLinking => $ConditionLinking,
                            );

                            return $TransitionEntityID;
                        }

                        next CONDITIONNAME if $ConditionLinking ne 'or' && $CondType eq 'or';
                    }
                    else {
                        $FieldFail++;

                        my $UnmatchedValue = $Param{Data}->{$FieldName};
                        if ( ref $Param{Data}->{$FieldName} eq 'ARRAY' ) {
                            $UnmatchedValue = 'Any of [' . join( ', ', @{ $Param{Data}->{$FieldName} } ) . ']';
                        }

                        $Self->DebugLog(
                            MessageType    => 'NoMatch',
                            TransitionName => $Transitions->{$TransitionEntityID}->{Name},
                            ConditionName  => $ConditionName,
                            FieldName      => $FieldName,
                            MatchType      => 'Regexp',
                            MatchValue     => $UnmatchedValue,
                            MatchCondition => $ActualCondition->{Fields}->{$FieldName}->{Match}
                        );

                        # Failed check if we have all 'and' conditions.
                        next TRANSITIONENTITYID if $ConditionLinking eq 'and' && $CondType eq 'and';

                        # Try next Condition if all Condition Fields have to be true.
                        next CONDITIONNAME if $CondType eq 'and';
                    }
                    next FIELDLNAME;
                }
                elsif ( $ActualCondition->{Fields}->{$FieldName}->{Type} eq 'Module' ) {

                    # Handle "Data" Param to ValidateModule's "Validate" subroutine.
                    # use ValidateModule 'Module' to run another ValidateModule
                    my $Match = $ValidateModuleObject->Validate(
                        Data               => $Param{Data},
                        FieldName          => $FieldName,
                        Transition         => $Transitions->{$TransitionEntityID},
                        TransitionName     => $Transitions->{$TransitionEntityID}->{Name},
                        TransitionEntityID => $TransitionEntityID,
                        Condition          => $ActualCondition->{Fields}->{$FieldName},
                        ConditionName      => $ConditionName,
                        ConditionType      => $CondType,
                        ConditionLinking   => $ConditionLinking,
                    );

                    if ($Match) {
                        $FieldSuccess++;

                        # Successful check if we just need one matching Condition to make this Transition valid.
                        if ( $ConditionLinking eq 'or' && $CondType eq 'or' ) {

                            $Self->DebugLog(
                                MessageType      => 'Success',
                                TransitionName   => $Transitions->{$TransitionEntityID}->{Name},
                                ConditionName    => $ConditionName,
                                ConditionType    => $CondType,
                                ConditionLinking => $ConditionLinking,
                            );

                            return $TransitionEntityID;
                        }

                        next CONDITIONNAME if $ConditionLinking ne 'or' && $CondType eq 'or';
                    }
                    else {
                        $FieldFail++;

                        $Self->DebugLog(
                            MessageType    => 'NoMatch',
                            TransitionName => $Transitions->{$TransitionEntityID}->{Name},
                            ConditionName  => $ConditionName,
                            FieldName      => $FieldName,
                            MatchType      => 'Module',
                            Module         => $ActualCondition->{Fields}->{$FieldName}->{Type}
                        );

                        # Failed check if we have all 'and' conditions.
                        next TRANSITIONENTITYID if $ConditionLinking eq 'and' && $CondType eq 'and';

                        # Try next Condition if all Condition Fields have to be true.
                        next CONDITIONNAME if $CondType eq 'and';
                    }
                    next FIELDLNAME;
                }

                # runs all TransitionValidation except String, Array, Hash, Regexp, Module
                elsif (
                    $TransitionValidation{ $ActualCondition->{Fields}->{$FieldName}->{Type} }->{Module}
                    && $ValidateModuleObject
                    )
                {

                    # Handle "Data" Param to ValidateModule's "Validate" subroutine.
                    # use ValidateModule 'Module' to run another ValidateModule
                    my $Match = $ValidateModuleObject->Validate(
                        Data               => $Param{Data},
                        FieldName          => $FieldName,
                        Transition         => $Transitions->{$TransitionEntityID},
                        TransitionName     => $Transitions->{$TransitionEntityID}->{Name},
                        TransitionEntityID => $TransitionEntityID,
                        Condition          => $ActualCondition->{Fields}->{$FieldName},
                        ConditionName      => $ConditionName,
                        ConditionType      => $CondType,
                        ConditionLinking   => $ConditionLinking,
                    );

                    if ($Match) {
                        $FieldSuccess++;

                        # Successful check if we just need one matching Condition to make this Transition valid.
                        if ( $ConditionLinking eq 'or' && $CondType eq 'or' ) {

                            $Self->DebugLog(
                                MessageType      => 'Success',
                                TransitionName   => $Transitions->{$TransitionEntityID}->{Name},
                                ConditionName    => $ConditionName,
                                ConditionType    => $CondType,
                                ConditionLinking => $ConditionLinking,
                            );

                            return $TransitionEntityID;
                        }

                        next CONDITIONNAME if $ConditionLinking ne 'or' && $CondType eq 'or';
                    }
                    else {
                        $FieldFail++;

                        $Self->DebugLog(
                            MessageType    => 'NoMatch',
                            TransitionName => $Transitions->{$TransitionEntityID}->{Name},
                            ConditionName  => $ConditionName,
                            FieldName      => $FieldName,
                            MatchType      => 'Module',
                            Module         => $ActualCondition->{Fields}->{$FieldName}->{Type}
                        );

                        # Failed check if we have all 'and' conditions.
                        next TRANSITIONENTITYID if $ConditionLinking eq 'and' && $CondType eq 'and';

                        # Try next Condition if all Condition Fields have to be true.
                        next CONDITIONNAME if $CondType eq 'and';
                    }
                    next FIELDLNAME;
                }
            }

            # FIELDLNAME End.
            if ( $CondType eq 'and' ) {

                # if we had no failing check this condition matched.
                if ( !$FieldFail ) {

                    # Successful check if we just need one matching Condition to make this Transition valid.
                    if ( $ConditionLinking eq 'or' ) {

                        $Self->DebugLog(
                            MessageType      => 'Success',
                            TransitionName   => $Transitions->{$TransitionEntityID}->{Name},
                            ConditionName    => $ConditionName,
                            ConditionType    => $CondType,
                            ConditionLinking => $ConditionLinking,
                        );

                        return $TransitionEntityID;
                    }
                    $ConditionSuccess++;
                }
                else {
                    $ConditionFail++;

                    # Failed check if we have all 'and' conditions.
                    next TRANSITIONENTITYID if $ConditionLinking eq 'and';
                }
            }
            elsif ( $CondType eq 'or' )
            {

                # If we had at least one successful check, this condition matched.
                if ( $FieldSuccess > 0 ) {

                    # Successful check if we just need one matching Condition to make this Transition valid.
                    if ( $ConditionLinking eq 'or' ) {

                        $Self->DebugLog(
                            MessageType      => 'Success',
                            TransitionName   => $Transitions->{$TransitionEntityID}->{Name},
                            ConditionName    => $ConditionName,
                            ConditionType    => $CondType,
                            ConditionLinking => $ConditionLinking,
                        );

                        return $TransitionEntityID;
                    }
                    $ConditionSuccess++;
                }
                else {
                    $ConditionFail++;

                    # Failed check if we have all 'and' conditions.
                    next TRANSITIONENTITYID if $ConditionLinking eq 'and';
                }
            }
            elsif ( $CondType eq 'xor' )
            {

                # if we had exactly one successful check, this condition matched.
                if ( $FieldSuccess == 1 ) {

                    # Successful check if we just need one matching Condition to make this Transition valid.
                    if ( $ConditionLinking eq 'or' ) {

                        $Self->DebugLog(
                            MessageType      => 'Success',
                            TransitionName   => $Transitions->{$TransitionEntityID}->{Name},
                            ConditionName    => $ConditionName,
                            ConditionType    => $CondType,
                            ConditionLinking => $ConditionLinking,
                        );

                        return $TransitionEntityID;
                    }
                    $ConditionSuccess++;
                }
                else {
                    $ConditionFail++;
                }
            }
        }

        # CONDITIONNAME End.
        if ( $ConditionLinking eq 'and' ) {

            # If we had no failing conditions this transition matched.
            if ( !$ConditionFail ) {

                $Self->DebugLog(
                    MessageType      => 'Success',
                    TransitionName   => $Transitions->{$TransitionEntityID}->{Name},
                    ConditionLinking => $ConditionLinking,
                );

                return $TransitionEntityID;
            }
        }
        elsif ( $ConditionLinking eq 'or' )
        {

            # If we had at least one successful condition, this transition matched.
            if ( $ConditionSuccess > 0 ) {

                $Self->DebugLog(
                    MessageType      => 'Success',
                    TransitionName   => $Transitions->{$TransitionEntityID}->{Name},
                    ConditionLinking => $ConditionLinking,
                );

                return $TransitionEntityID;
            }
        }
        elsif ( $ConditionLinking eq 'xor' )
        {

            # If we had exactly one successful condition, this transition matched.
            if ( $ConditionSuccess == 1 ) {

                $Self->DebugLog(
                    MessageType      => 'Success',
                    TransitionName   => $Transitions->{$TransitionEntityID}->{Name},
                    ConditionLinking => $ConditionLinking,
                );

                return $TransitionEntityID;
            }
        }
    }

    # TRANSITIONENTITYID End.
    # If no transition matched till here, we failed.
    return;

}

=head2 TransitionValidationTypeList()

Returns a list of possible transition validations.

    my %TransitionValidationTypeList = $TransitionObject->TransitionValidationTypeList();

Returns:

    my %TransitionValidationTypeList = TransitionValidationTypeList(
        'String' => 'String',
        'Regexp' => 'Regular expression',
        'Module' => 'Transition validation module',
    );

=cut

sub TransitionValidationTypeList {
    my ( $Self, %Param ) = @_;

    my %TransitionValidationTypeListGet = $Self->TransitionValidationTypeListGet();

    my %TransitionValidationTypeList;
    TYPE:
    for my $Type ( sort keys %TransitionValidationTypeListGet ) {
        next TYPE if !$TransitionValidationTypeListGet{$Type};
        $TransitionValidationTypeList{$Type}
            = $TransitionValidationTypeListGet{$Type}->{Label} || $TransitionValidationTypeListGet{$Type}->{Name};
    }

    return %TransitionValidationTypeList;
}

=head2 TransitionValidationTypeListGet()

Returns a list of possible transition validations.

    my %TransitionValidationTypeListGet = $TransitionObject->TransitionValidationTypeListGet();

Returns:

    my %TransitionValidationTypeListGet = (
        'String' => {
            Name   => 'String',
            Label  => 'String',
            Module => 'Kernel::System::ProcessManagement::TransitionValidation::String',
        },
        'Regexp' => {
            Name   => 'Regexp',
            Label  => 'Regular expression',
            Module => 'Kernel::System::ProcessManagement::TransitionValidation::Regexp',
        },
        'Module' => {
            Name   => 'Module',
            Label  => 'Transition validation module',
            Module => 'Kernel::System::ProcessManagement::TransitionValidation::Module',
        },
    );

=cut

sub TransitionValidationTypeListGet {
    my ( $Self, %Param ) = @_;

    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');
    my $MainObject   = $Kernel::OM->Get('Kernel::System::Main');
    my $LogObject    = $Kernel::OM->Get('Kernel::System::Log');

    my $Directory = $ConfigObject->Get('Home') . '/Kernel/System/ProcessManagement/TransitionValidation';

    my @TransitionValidation = $MainObject->DirectoryRead(
        Directory => $Directory,
        Filter    => '*.pm',
    );

    my %TransitionValidationTypeListGet;
    ITEM:
    for my $Item (@TransitionValidation) {

        # remove .pm
        $Item =~ s/^.*\/(.+?)\.pm$/$1/;

        # ignore Base and ValidateDemo
        next ITEM if $Item eq 'Base';
        next ITEM if $Item eq 'ValidateDemo';

        my $Module = 'Kernel::System::ProcessManagement::TransitionValidation::' . $Item;

        # check if transition validation module exists
        if ( !$MainObject->Require($Module) ) {
            $LogObject->Log(
                Priority => 'error',
                Message  => "Can't load TransitionValidation "
                    . $Module
                    . " for validation!",
            );
            return;
        }

        my $ValidateModuleObject = $Module->new(
            %{$Self},
            %Param,
        );

        $TransitionValidationTypeListGet{$Item} = {
            Name   => Translatable($Item),
            Label  => Translatable( $ValidateModuleObject->{Label} ) || Translatable($Item),
            Module => $Module,
        };
    }

    return %TransitionValidationTypeListGet;
}

sub DebugLog {
    my ( $Self, %Param ) = @_;

    my $LogObject    = $Kernel::OM->Get('Kernel::System::Log');
    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');

    $Param{TransitionName} //= '';

    my $Message = "Transition:'$Param{TransitionName}'";

    if ( $Param{MessageType} eq 'Match' || $Param{MessageType} eq 'NoMatch' ) {

        my $MatchedString = $Param{MessageType} eq 'Match' ? 'Matched' : 'Not matched';

        $Message = " Condition:'$Param{ConditionName}' $MatchedString Field:'$Param{FieldName}'";

        if ( $Param{MatchType} eq 'Module' ) {
            $Message .= " with transition validation module '$Param{Module}'";
        }
        else {
            $Message .= " as $Param{MatchType}";
        }

        if ( $Param{MatchValue} && $Param{MatchCondition} ) {
            $Message .= " ($Param{MatchValue} matches $Param{MatchCondition})";
        }
    }
    elsif ( $Param{MessageType} eq 'Success' ) {

        if ( $Param{ConditionName} && $Param{ConditionType} ) {
            $Message = " Condition:'$Param{ConditionName}': Success on condition linking: '$Param{ConditionLinking}'"
                . "  and condition type: '$Param{ConditionType}'";
        }
        else {
            $Message = " Success on condition linking:'$Param{ConditionLinking}'";
        }
    }

    # for MessageType 'Custom' or any other, use the given message
    else {
        return if !$Param{Message};
        $Message = $Param{Message};
    }

    if ( !$Self->{TransitionDebugLogPriority} ) {
        $Self->{TransitionDebugLogPriority}
            = $ConfigObject->Get('ProcessManagement::Transition::Debug::LogPriority') || 'debug';
    }
    $LogObject->Log(
        Priority => $Param{Priority} || $Self->{TransitionDebugLogPriority},
        Message  => $Message,
    );

    return 1;
}

1;

=head1 TERMS AND CONDITIONS

This software is part of the OTRS project (L<https://otrs.org/>).

This software comes with ABSOLUTELY NO WARRANTY. For details, see
the enclosed file COPYING for license information (GPL). If you
did not receive this file, see L<https://www.gnu.org/licenses/gpl-3.0.txt>.

=cut
