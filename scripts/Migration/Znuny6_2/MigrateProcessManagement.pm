# --
# Copyright (C) 2021 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --
## nofilter(TidyAll::Plugin::OTRS::Perl::Pod::NamePod)

package scripts::Migration::Znuny6_2::MigrateProcessManagement;    ## no critic

use strict;
use warnings;

use parent qw(scripts::Migration::Base);

use Kernel::System::VariableCheck qw(:all);

our @ObjectDependencies = (
    'Kernel::System::DynamicField',
    'Kernel::System::ProcessManagement::DB::Transition',
    'Kernel::System::ProcessManagement::DB::TransitionAction',
);

=head1 SYNOPSIS

Migrate ProcessManagement configuration.

=cut

sub Run {
    my ( $Self, %Param ) = @_;

    return if !$Self->_MigrateTransitionActions(%Param);
    return if !$Self->_MigrateTransitionValidations(%Param);
    return if !$Self->_CreateProcessManagementAttachmentDynamicField(%Param);

    return 1;
}

sub _MigrateTransitionActions {
    my ( $Self, %Param ) = @_;

    my $TransitionActionObject = $Kernel::OM->Get('Kernel::System::ProcessManagement::DB::TransitionAction');

    my $TransitionActionList = $TransitionActionObject->TransitionActionListGet(
        UserID => 1,
    );

    my %TransitionActionNameMapping = (
        'Znuny4OTRSAppointmentCreate'          => 'AppointmentCreate',
        'Znuny4OTRSArticleSend'                => 'ArticleSend',
        'Znuny4OTRSConfigItemUpdate'           => 'ConfigItemUpdate',
        'Znuny4OTRSDynamicFieldIncrement'      => 'DynamicFieldIncrement',
        'Znuny4OTRSDynamicFieldPendingTimeSet' => 'DynamicFieldPendingTimeSet',
        'Znuny4OTRSDynamicFieldRemove'         => 'DynamicFieldRemove',
        'Znuny4OTRSLinkAdd'                    => 'LinkAdd',
        'Znuny4OTRSTicketPrioritySet'          => 'TicketPrioritySet',
        'Znuny4OTRSTicketWatch'                => 'TicketWatch',
        'Znuny4OTRSCI'                         => 'ConfigItemUpdate',
    );

    TRANSITIONACTION:
    for my $TransitionAction ( @{$TransitionActionList} ) {
        next TRANSITIONACTION if !$TransitionAction->{Config};
        next TRANSITIONACTION if !$TransitionAction->{Config}->{Module};

        my $TransitionActionModule = $TransitionAction->{Config}->{Module};
        $TransitionActionModule =~ s{Kernel::System::ProcessManagement::TransitionAction::}{}smxg;

        next TRANSITIONACTION if !$TransitionActionNameMapping{$TransitionActionModule};

        $TransitionAction->{Config}->{Module} = 'Kernel::System::ProcessManagement::TransitionAction::'
            . $TransitionActionNameMapping{$TransitionActionModule};
        $TransitionActionObject->TransitionActionUpdate(
            %{$TransitionAction},
            UserID => 1,
        );
    }

    return 1;
}

sub _MigrateTransitionValidations {
    my ( $Self, %Param ) = @_;

    my $TransitionObject = $Kernel::OM->Get('Kernel::System::ProcessManagement::DB::Transition');

    my $TransitionList = $TransitionObject->TransitionListGet(
        UserID => 1,
    );

    my %Operators = (
        '>'  => 'GreaterThan',
        '<'  => 'LessThan',
        '>=' => 'GreaterThanOrEqual',
        '<=' => 'LessThanOrEqual',
        '==' => 'Equal',
        '!=' => 'NotEqual',
        '=~' => 'Contains',
        '!~' => 'NotContains',
    );

    TRANSITION:
    for my $Transition ( @{$TransitionList} ) {
        my $Update;
        for my $ConditionID ( sort keys %{ $Transition->{Config}->{Condition} } ) {
            FIELD:
            for my $FieldName ( sort keys %{ $Transition->{Config}->{Condition}->{$ConditionID}->{Fields} } ) {

                my $Field = $Transition->{Config}->{Condition}->{$ConditionID}->{Fields}->{$FieldName};
                next FIELD
                    if $Field->{Match} ne
                    'Kernel::System::ProcessManagement::TransitionValidation::Znuny4OTRSValidateByOperator';

                $Field->{Type}  = $Operators{ $Field->{Operator} };
                $Field->{Match} = $Field->{Value};
                delete $Field->{Operator};
                delete $Field->{Value};

                $Update = 1;
            }
        }

        next TRANSITION if !$Update;
        $TransitionObject->TransitionUpdate(
            %{$Transition},
            UserID => 1,
        );
    }

    return 1;
}

sub _CreateProcessManagementAttachmentDynamicField {
    my ( $Self, %Param ) = @_;

    my $DynamicFieldName = 'ProcessManagementAttachment';

    my $DynamicFieldObject = $Kernel::OM->Get('Kernel::System::DynamicField');
    my $DynamicFieldConfig = $DynamicFieldObject->DynamicFieldGet(
        Name => $DynamicFieldName,
    );
    return 1 if IsHashRefWithData($DynamicFieldConfig);

    my $DynamicFieldID = $DynamicFieldObject->DynamicFieldAdd(
        InternalField => 1,
        Name          => $DynamicFieldName,
        Label         => 'Attachment',
        FieldOrder    => 1,
        FieldType     => 'TextArea',
        ObjectType    => 'Ticket',
        Config        => {
            DefaultValue => '',
        },
        Reorder => 1,
        ValidID => 1,
        UserID  => 1,
    );
    return if !$DynamicFieldID;

    return 1;
}

1;
