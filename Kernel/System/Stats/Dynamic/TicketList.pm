# --
# Copyright (C) 2001-2021 OTRS AG, https://otrs.com/
# Copyright (C) 2021-2022 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see https://www.gnu.org/licenses/gpl-3.0.txt.
# --

package Kernel::System::Stats::Dynamic::TicketList;

use strict;
use warnings;

use List::Util qw( first );

use Kernel::System::VariableCheck qw(:all);
use Kernel::Language qw(Translatable);

our @ObjectDependencies = (
    'Kernel::Config',
    'Kernel::Language',
    'Kernel::System::DB',
    'Kernel::System::DynamicField',
    'Kernel::System::DynamicField::Backend',
    'Kernel::System::Lock',
    'Kernel::System::Log',
    'Kernel::System::Priority',
    'Kernel::System::Queue',
    'Kernel::System::Service',
    'Kernel::System::SLA',
    'Kernel::System::State',
    'Kernel::System::Stats',
    'Kernel::System::Ticket',
    'Kernel::System::Ticket::Article',
    'Kernel::System::DateTime',
    'Kernel::System::Type',
    'Kernel::System::User',
    'Kernel::Output::HTML::Layout',
);

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {};
    bless( $Self, $Type );

    # get the dynamic fields for ticket object
    $Self->{DynamicField} = $Kernel::OM->Get('Kernel::System::DynamicField')->DynamicFieldListGet(
        Valid      => 1,
        ObjectType => ['Ticket'],
    );

    return $Self;
}

sub GetObjectName {
    my ( $Self, %Param ) = @_;

    return 'Ticketlist';
}

sub GetObjectBehaviours {
    my ( $Self, %Param ) = @_;

    my %Behaviours = (
        ProvidesDashboardWidget => 0,
    );

    return %Behaviours;
}

sub GetObjectAttributes {
    my ( $Self, %Param ) = @_;

    # get needed objects
    my $ConfigObject   = $Kernel::OM->Get('Kernel::Config');
    my $UserObject     = $Kernel::OM->Get('Kernel::System::User');
    my $QueueObject    = $Kernel::OM->Get('Kernel::System::Queue');
    my $TicketObject   = $Kernel::OM->Get('Kernel::System::Ticket');
    my $StateObject    = $Kernel::OM->Get('Kernel::System::State');
    my $PriorityObject = $Kernel::OM->Get('Kernel::System::Priority');
    my $LockObject     = $Kernel::OM->Get('Kernel::System::Lock');

    my $ValidAgent = 0;
    if (
        defined $ConfigObject->Get('Stats::UseInvalidAgentInStats')
        && ( $ConfigObject->Get('Stats::UseInvalidAgentInStats') == 0 )
        )
    {
        $ValidAgent = 1;
    }

    # Get user list without the out of office message, because of the caching in the statistics
    #   and not meaningful with a date selection.
    my %UserList = $UserObject->UserList(
        Type          => 'Long',
        Valid         => $ValidAgent,
        NoOutOfOffice => 1,
    );

    # get state list
    my %StateList = $StateObject->StateList(
        UserID => 1,
    );

    # get state type list
    my %StateTypeList = $StateObject->StateTypeList(
        UserID => 1,
    );

    # get queue list
    my %QueueList = $QueueObject->GetAllQueues();

    # get priority list
    my %PriorityList = $PriorityObject->PriorityList(
        UserID => 1,
    );

    # get lock list
    my %LockList = $LockObject->LockList(
        UserID => 1,
    );

    my %Limit = (
        5         => 5,
        10        => 10,
        20        => 20,
        50        => 50,
        100       => 100,
        unlimited => Translatable('unlimited'),
    );

    my %TicketAttributes = %{ $Self->_TicketAttributes() };
    my %OrderBy          = map { $_ => $TicketAttributes{$_} } grep { $_ ne 'Number' } keys %TicketAttributes;

    # get dynamic field backend object
    my $DynamicFieldBackendObject = $Kernel::OM->Get('Kernel::System::DynamicField::Backend');

    # remove non sortable (and orderable) Dynamic Fields
    DYNAMICFIELD:
    for my $DynamicFieldConfig ( @{ $Self->{DynamicField} } ) {
        next DYNAMICFIELD if !IsHashRefWithData($DynamicFieldConfig);
        next DYNAMICFIELD if !$DynamicFieldConfig->{Name};

        # check if dynamic field is sortable
        my $IsSortable = $DynamicFieldBackendObject->HasBehavior(
            DynamicFieldConfig => $DynamicFieldConfig,
            Behavior           => 'IsSortable',
        );

        # remove dynamic fields from the list if is not sortable
        if ( !$IsSortable ) {
            delete $OrderBy{ 'DynamicField_' . $DynamicFieldConfig->{Name} };
        }
    }

    my %SortSequence = (
        Up   => Translatable('ascending'),
        Down => Translatable('descending'),
    );

    my @ObjectAttributes = (
        {
            Name             => Translatable('Attributes to be printed'),
            UseAsXvalue      => 1,
            UseAsValueSeries => 0,
            UseAsRestriction => 0,
            Element          => 'TicketAttributes',
            Block            => 'MultiSelectField',
            Translation      => 1,
            Values           => \%TicketAttributes,
            Sort             => 'IndividualKey',
            SortIndividual   => $Self->_SortedAttributes(),
        },
        {
            Name             => Translatable('Order by'),
            UseAsXvalue      => 0,
            UseAsValueSeries => 1,
            UseAsRestriction => 0,
            Element          => 'OrderBy',
            Block            => 'SelectField',
            Translation      => 1,
            Values           => \%OrderBy,
            Sort             => 'IndividualKey',
            SortIndividual   => $Self->_SortedAttributes(),
        },
        {
            Name             => Translatable('Sort sequence'),
            UseAsXvalue      => 0,
            UseAsValueSeries => 1,
            UseAsRestriction => 0,
            Element          => 'SortSequence',
            Block            => 'SelectField',
            Translation      => 1,
            Values           => \%SortSequence,
        },
        {
            Name             => Translatable('Limit'),
            UseAsXvalue      => 0,
            UseAsValueSeries => 0,
            UseAsRestriction => 1,
            Element          => 'Limit',
            Block            => 'SelectField',
            Translation      => 1,
            Values           => \%Limit,
            Sort             => 'IndividualKey',
            SortIndividual   => [ '5', '10', '20', '50', '100', 'unlimited', ],
        },
        {
            Name             => Translatable('Queue'),
            UseAsXvalue      => 0,
            UseAsValueSeries => 0,
            UseAsRestriction => 1,
            Element          => 'QueueIDs',
            Block            => 'MultiSelectField',
            Translation      => 0,
            TreeView         => 1,
            Values           => \%QueueList,
        },
        {
            Name             => Translatable('State'),
            UseAsXvalue      => 0,
            UseAsValueSeries => 0,
            UseAsRestriction => 1,
            Element          => 'StateIDs',
            Block            => 'MultiSelectField',
            Values           => \%StateList,
        },
        {
            Name             => Translatable('State Historic'),
            UseAsXvalue      => 0,
            UseAsValueSeries => 0,
            UseAsRestriction => 1,
            Element          => 'StateIDsHistoric',
            Block            => 'MultiSelectField',
            Values           => \%StateList,
        },
        {
            Name             => Translatable('State Type'),
            UseAsXvalue      => 0,
            UseAsValueSeries => 0,
            UseAsRestriction => 1,
            Element          => 'StateTypeIDs',
            Block            => 'MultiSelectField',
            Values           => \%StateTypeList,
        },
        {
            Name             => Translatable('State Type Historic'),
            UseAsXvalue      => 0,
            UseAsValueSeries => 0,
            UseAsRestriction => 1,
            Element          => 'StateTypeIDsHistoric',
            Block            => 'MultiSelectField',
            Values           => \%StateTypeList,
        },
        {
            Name             => Translatable('Priority'),
            UseAsXvalue      => 0,
            UseAsValueSeries => 0,
            UseAsRestriction => 1,
            Element          => 'PriorityIDs',
            Block            => 'MultiSelectField',
            Values           => \%PriorityList,
        },
        {
            Name             => Translatable('Created in Queue'),
            UseAsXvalue      => 0,
            UseAsValueSeries => 0,
            UseAsRestriction => 1,
            Element          => 'CreatedQueueIDs',
            Block            => 'MultiSelectField',
            Translation      => 0,
            TreeView         => 1,
            Values           => \%QueueList,
        },
        {
            Name             => Translatable('Created Priority'),
            UseAsXvalue      => 0,
            UseAsValueSeries => 0,
            UseAsRestriction => 1,
            Element          => 'CreatedPriorityIDs',
            Block            => 'MultiSelectField',
            Values           => \%PriorityList,
        },
        {
            Name             => Translatable('Created State'),
            UseAsXvalue      => 0,
            UseAsValueSeries => 0,
            UseAsRestriction => 1,
            Element          => 'CreatedStateIDs',
            Block            => 'MultiSelectField',
            Values           => \%StateList,
        },
        {
            Name             => Translatable('Lock'),
            UseAsXvalue      => 0,
            UseAsValueSeries => 0,
            UseAsRestriction => 1,
            Element          => 'LockIDs',
            Block            => 'MultiSelectField',
            Values           => \%LockList,
        },
        {
            Name             => Translatable('Title'),
            UseAsXvalue      => 0,
            UseAsValueSeries => 0,
            UseAsRestriction => 1,
            Element          => 'Title',
            Block            => 'InputField',
        },
        {
            Name             => Translatable('From'),
            UseAsXvalue      => 0,
            UseAsValueSeries => 0,
            UseAsRestriction => 1,
            Element          => 'MIMEBase_From',
            Block            => 'InputField',
        },
        {
            Name             => Translatable('To'),
            UseAsXvalue      => 0,
            UseAsValueSeries => 0,
            UseAsRestriction => 1,
            Element          => 'MIMEBase_To',
            Block            => 'InputField',
        },
        {
            Name             => Translatable('Cc'),
            UseAsXvalue      => 0,
            UseAsValueSeries => 0,
            UseAsRestriction => 1,
            Element          => 'MIMEBase_Cc',
            Block            => 'InputField',
        },
        {
            Name             => Translatable('Subject'),
            UseAsXvalue      => 0,
            UseAsValueSeries => 0,
            UseAsRestriction => 1,
            Element          => 'MIMEBase_Subject',
            Block            => 'InputField',
        },
        {
            Name             => Translatable('Text'),
            UseAsXvalue      => 0,
            UseAsValueSeries => 0,
            UseAsRestriction => 1,
            Element          => 'MIMEBase_Body',
            Block            => 'InputField',
        },
        {
            Name             => Translatable('Create Time'),
            UseAsXvalue      => 0,
            UseAsValueSeries => 0,
            UseAsRestriction => 1,
            Element          => 'CreateTime',
            TimePeriodFormat => 'DateInputFormat',             # 'DateInputFormatLong',
            Block            => 'Time',
            Values           => {
                TimeStart => 'TicketCreateTimeNewerDate',
                TimeStop  => 'TicketCreateTimeOlderDate',
            },
        },
        {
            Name             => Translatable('Last changed times'),
            UseAsXvalue      => 0,
            UseAsValueSeries => 0,
            UseAsRestriction => 1,
            Element          => 'LastChangeTime',
            TimePeriodFormat => 'DateInputFormat',                    # 'DateInputFormatLong',
            Block            => 'Time',
            Values           => {
                TimeStart => 'TicketLastChangeTimeNewerDate',
                TimeStop  => 'TicketLastChangeTimeOlderDate',
            },
        },
        {
            Name             => Translatable('Change times'),
            UseAsXvalue      => 0,
            UseAsValueSeries => 0,
            UseAsRestriction => 1,
            Element          => 'ChangeTime',
            TimePeriodFormat => 'DateInputFormat',              # 'DateInputFormatLong',
            Block            => 'Time',
            Values           => {
                TimeStart => 'TicketChangeTimeNewerDate',
                TimeStop  => 'TicketChangeTimeOlderDate',
            },
        },
        {
            Name             => Translatable('Pending until time'),
            UseAsXvalue      => 0,
            UseAsValueSeries => 0,
            UseAsRestriction => 1,
            Element          => 'PendingUntilTime',
            TimePeriodFormat => 'DateInputFormat',                    # 'DateInputFormatLong',
            Block            => 'Time',
            Values           => {
                TimeStart => 'TicketPendingTimeNewerDate',
                TimeStop  => 'TicketPendingTimeOlderDate',
            },
        },
        {
            Name             => Translatable('Close Time'),
            UseAsXvalue      => 0,
            UseAsValueSeries => 0,
            UseAsRestriction => 1,
            Element          => 'CloseTime',
            TimePeriodFormat => 'DateInputFormat',            # 'DateInputFormatLong',
            Block            => 'Time',
            Values           => {
                TimeStart => 'TicketCloseTimeNewerDate',
                TimeStop  => 'TicketCloseTimeOlderDate',
            },
        },
        {
            Name             => Translatable('Historic Time Range'),
            UseAsXvalue      => 0,
            UseAsValueSeries => 0,
            UseAsRestriction => 1,
            Element          => 'HistoricTimeRange',
            TimePeriodFormat => 'DateInputFormat',                     # 'DateInputFormatLong',
            Block            => 'Time',
            Values           => {
                TimeStart => 'HistoricTimeRangeTimeNewerDate',
                TimeStop  => 'HistoricTimeRangeTimeOlderDate',
            },
        },
        {
            Name             => Translatable('Escalation'),
            UseAsXvalue      => 0,
            UseAsValueSeries => 0,
            UseAsRestriction => 1,
            Element          => 'EscalationTime',
            TimePeriodFormat => 'DateInputFormatLong',        # 'DateInputFormat',
            Block            => 'Time',
            Values           => {
                TimeStart => 'TicketEscalationTimeNewerDate',
                TimeStop  => 'TicketEscalationTimeOlderDate',
            },
        },
        {
            Name             => Translatable('Escalation - First Response Time'),
            UseAsXvalue      => 0,
            UseAsValueSeries => 0,
            UseAsRestriction => 1,
            Element          => 'EscalationResponseTime',
            TimePeriodFormat => 'DateInputFormatLong',                              # 'DateInputFormat',
            Block            => 'Time',
            Values           => {
                TimeStart => 'TicketEscalationResponseTimeNewerDate',
                TimeStop  => 'TicketEscalationResponseTimeOlderDate',
            },
        },
        {
            Name             => Translatable('Escalation - Update Time'),
            UseAsXvalue      => 0,
            UseAsValueSeries => 0,
            UseAsRestriction => 1,
            Element          => 'EscalationUpdateTime',
            TimePeriodFormat => 'DateInputFormatLong',                      # 'DateInputFormat',
            Block            => 'Time',
            Values           => {
                TimeStart => 'TicketEscalationUpdateTimeNewerDate',
                TimeStop  => 'TicketEscalationUpdateTimeOlderDate',
            },
        },
        {
            Name             => Translatable('Escalation - Solution Time'),
            UseAsXvalue      => 0,
            UseAsValueSeries => 0,
            UseAsRestriction => 1,
            Element          => 'EscalationSolutionTime',
            TimePeriodFormat => 'DateInputFormatLong',                        # 'DateInputFormat',
            Block            => 'Time',
            Values           => {
                TimeStart => 'TicketEscalationSolutionTimeNewerDate',
                TimeStop  => 'TicketEscalationSolutionTimeOlderDate',
            },
        },
    );

    if ( $ConfigObject->Get('Ticket::Service') ) {

        # get service list
        my %Service = $Kernel::OM->Get('Kernel::System::Service')->ServiceList(
            KeepChildren => $ConfigObject->Get('Ticket::Service::KeepChildren'),
            UserID       => 1,
        );

        # get sla list
        my %SLA = $Kernel::OM->Get('Kernel::System::SLA')->SLAList(
            UserID => 1,
        );

        my @ObjectAttributeAdd = (
            {
                Name             => Translatable('Service'),
                UseAsXvalue      => 0,
                UseAsValueSeries => 0,
                UseAsRestriction => 1,
                Element          => 'ServiceIDs',
                Block            => 'MultiSelectField',
                Translation      => 0,
                TreeView         => 1,
                Values           => \%Service,
            },
            {
                Name             => Translatable('SLA'),
                UseAsXvalue      => 0,
                UseAsValueSeries => 0,
                UseAsRestriction => 1,
                Element          => 'SLAIDs',
                Block            => 'MultiSelectField',
                Translation      => 0,
                Values           => \%SLA,
            },
        );

        unshift @ObjectAttributes, @ObjectAttributeAdd;
    }

    if ( $ConfigObject->Get('Ticket::Type') ) {

        # get ticket type list
        my %Type = $Kernel::OM->Get('Kernel::System::Type')->TypeList(
            UserID => 1,
        );

        my %ObjectAttribute1 = (
            Name             => Translatable('Type'),
            UseAsXvalue      => 0,
            UseAsValueSeries => 0,
            UseAsRestriction => 1,
            Element          => 'TypeIDs',
            Block            => 'MultiSelectField',
            Translation      => 0,
            Values           => \%Type,
        );

        unshift @ObjectAttributes, \%ObjectAttribute1;
    }

    if ( $ConfigObject->Get('Stats::UseAgentElementInStats') ) {

        my @ObjectAttributeAdd = (
            {
                Name             => Translatable('Agent/Owner'),
                UseAsXvalue      => 0,
                UseAsValueSeries => 0,
                UseAsRestriction => 1,
                Element          => 'OwnerIDs',
                Block            => 'MultiSelectField',
                Translation      => 0,
                Values           => \%UserList,
            },
            {
                Name             => Translatable('Created by Agent/Owner'),
                UseAsXvalue      => 0,
                UseAsValueSeries => 0,
                UseAsRestriction => 1,
                Element          => 'CreatedUserIDs',
                Block            => 'MultiSelectField',
                Translation      => 0,
                Values           => \%UserList,
            },
            {
                Name             => Translatable('Responsible'),
                UseAsXvalue      => 0,
                UseAsValueSeries => 0,
                UseAsRestriction => 1,
                Element          => 'ResponsibleIDs',
                Block            => 'MultiSelectField',
                Translation      => 0,
                Values           => \%UserList,
            },
        );

        push @ObjectAttributes, @ObjectAttributeAdd;
    }

    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    if ( $ConfigObject->Get('Stats::CustomerIDAsMultiSelect') ) {

        # Get CustomerID
        # (This way also can be the solution for the CustomerUserID)
        $DBObject->Prepare(
            SQL => "SELECT DISTINCT customer_id FROM ticket",
        );

        # fetch the result
        my %CustomerID;
        while ( my @Row = $DBObject->FetchrowArray() ) {
            if ( $Row[0] ) {
                $CustomerID{ $Row[0] } = $Row[0];
            }
        }

        my %ObjectAttribute = (
            Name             => Translatable('Customer ID'),
            UseAsXvalue      => 0,
            UseAsValueSeries => 0,
            UseAsRestriction => 1,
            Element          => 'CustomerID',
            Block            => 'MultiSelectField',
            Values           => \%CustomerID,
        );

        push @ObjectAttributes, \%ObjectAttribute;
    }
    else {

        my @CustomerIDAttributes = (
            {
                Name             => Translatable('CustomerID (complex search)'),
                UseAsXvalue      => 0,
                UseAsValueSeries => 0,
                UseAsRestriction => 1,
                Element          => 'CustomerID',
                Block            => 'InputField',
            },
            {
                Name             => Translatable('CustomerID (exact match)'),
                UseAsXvalue      => 0,
                UseAsValueSeries => 0,
                UseAsRestriction => 1,
                Element          => 'CustomerIDRaw',
                Block            => 'InputField',
            },
        );

        push @ObjectAttributes, @CustomerIDAttributes;
    }

    if ( $ConfigObject->Get('Stats::CustomerUserLoginsAsMultiSelect') ) {

        # Get all CustomerUserLogins which are related to a tiket.
        $DBObject->Prepare(
            SQL => "SELECT DISTINCT customer_user_id FROM ticket",
        );

        # fetch the result
        my %CustomerUserIDs;
        while ( my @Row = $DBObject->FetchrowArray() ) {
            if ( $Row[0] ) {
                $CustomerUserIDs{ $Row[0] } = $Row[0];
            }
        }

        my %ObjectAttribute = (
            Name             => Translatable('Assigned to Customer User Login'),
            UseAsXvalue      => 0,
            UseAsValueSeries => 0,
            UseAsRestriction => 1,
            Element          => 'CustomerUserLoginRaw',
            Block            => 'MultiSelectField',
            Values           => \%CustomerUserIDs,
        );

        push @ObjectAttributes, \%ObjectAttribute;
    }
    else {

        my @CustomerUserAttributes = (
            {
                Name             => Translatable('Assigned to Customer User Login (complex search)'),
                UseAsXvalue      => 0,
                UseAsValueSeries => 0,
                UseAsRestriction => 1,
                Element          => 'CustomerUserLogin',
                Block            => 'InputField',
            },
            {
                Name               => Translatable('Assigned to Customer User Login (exact match)'),
                UseAsXvalue        => 0,
                UseAsValueSeries   => 0,
                UseAsRestriction   => 1,
                Element            => 'CustomerUserLoginRaw',
                Block              => 'InputField',
                CSSClass           => 'CustomerAutoCompleteSimple',
                HTMLDataAttributes => {
                    'customer-search-type' => 'CustomerUser',
                },
            },
        );

        push @ObjectAttributes, @CustomerUserAttributes;
    }

    # Add always the field for the customer user login accessible tickets as auto complete field.
    my %ObjectAttribute = (
        Name               => Translatable('Accessible to Customer User Login (exact match)'),
        UseAsXvalue        => 0,
        UseAsValueSeries   => 0,
        UseAsRestriction   => 1,
        Element            => 'CustomerUserID',
        Block              => 'InputField',
        CSSClass           => 'CustomerAutoCompleteSimple',
        HTMLDataAttributes => {
            'customer-search-type' => 'CustomerUser',
        },
    );
    push @ObjectAttributes, \%ObjectAttribute;

    if ( $ConfigObject->Get('Ticket::ArchiveSystem') ) {

        my %ObjectAttribute = (
            Name             => Translatable('Archive Search'),
            UseAsXvalue      => 0,
            UseAsValueSeries => 0,
            UseAsRestriction => 1,
            Element          => 'SearchInArchive',
            Block            => 'SelectField',
            Translation      => 1,
            Values           => {
                ArchivedTickets    => Translatable('Archived tickets'),
                NotArchivedTickets => Translatable('Unarchived tickets'),
                AllTickets         => Translatable('All tickets'),
            },
        );

        push @ObjectAttributes, \%ObjectAttribute;
    }

    # cycle trough the activated Dynamic Fields for this screen
    DYNAMICFIELD:
    for my $DynamicFieldConfig ( @{ $Self->{DynamicField} } ) {
        next DYNAMICFIELD if !IsHashRefWithData($DynamicFieldConfig);

        # skip all fields not designed to be supported by statistics
        my $IsStatsCondition = $DynamicFieldBackendObject->HasBehavior(
            DynamicFieldConfig => $DynamicFieldConfig,
            Behavior           => 'IsStatsCondition',
        );

        next DYNAMICFIELD if !$IsStatsCondition;

        my $PossibleValuesFilter;

        my $IsACLReducible = $DynamicFieldBackendObject->HasBehavior(
            DynamicFieldConfig => $DynamicFieldConfig,
            Behavior           => 'IsACLReducible',
        );

        if ($IsACLReducible) {

            # get PossibleValues
            my $PossibleValues = $DynamicFieldBackendObject->PossibleValuesGet(
                DynamicFieldConfig => $DynamicFieldConfig,
            );

            # convert possible values key => value to key => key for ACLs using a Hash slice
            my %AclData = %{ $PossibleValues || {} };
            @AclData{ keys %AclData } = keys %AclData;

            # set possible values filter from ACLs
            my $ACL = $TicketObject->TicketAcl(
                Action        => 'AgentStats',
                Type          => 'DynamicField_' . $DynamicFieldConfig->{Name},
                ReturnType    => 'Ticket',
                ReturnSubType => 'DynamicField_' . $DynamicFieldConfig->{Name},
                Data          => \%AclData || {},
                UserID        => 1,
            );
            if ($ACL) {
                my %Filter = $TicketObject->TicketAclData();

                # convert Filer key => key back to key => value using map
                %{$PossibleValuesFilter} = map { $_ => $PossibleValues->{$_} } keys %Filter;
            }
        }

        # get dynamic field stats parameters
        my $DynamicFieldStatsParameter = $DynamicFieldBackendObject->StatsFieldParameterBuild(
            DynamicFieldConfig   => $DynamicFieldConfig,
            PossibleValuesFilter => $PossibleValuesFilter,
        );

        if ( IsHashRefWithData($DynamicFieldStatsParameter) ) {

            # backward compatibility
            if ( !$DynamicFieldStatsParameter->{Block} ) {
                $DynamicFieldStatsParameter->{Block} = 'InputField';
                if ( IsHashRefWithData( $DynamicFieldStatsParameter->{Values} ) ) {
                    $DynamicFieldStatsParameter->{Block} = 'MultiSelectField';
                }
            }

            if ( $DynamicFieldStatsParameter->{Block} eq 'Time' ) {

                # create object attributes (date/time fields)
                my $TimePeriodFormat = $DynamicFieldStatsParameter->{TimePeriodFormat} || 'DateInputFormatLong';

                my %ObjectAttribute = (
                    Name             => $DynamicFieldStatsParameter->{Name},
                    UseAsXvalue      => 0,
                    UseAsValueSeries => 0,
                    UseAsRestriction => 1,
                    Element          => $DynamicFieldStatsParameter->{Element},
                    TimePeriodFormat => $TimePeriodFormat,
                    Block            => $DynamicFieldStatsParameter->{Block},
                    TimePeriodFormat => $TimePeriodFormat,
                    Values           => {
                        TimeStart =>
                            $DynamicFieldStatsParameter->{Element}
                            . '_GreaterThanEquals',
                        TimeStop =>
                            $DynamicFieldStatsParameter->{Element}
                            . '_SmallerThanEquals',
                    },
                );
                push @ObjectAttributes, \%ObjectAttribute;
            }
            elsif ( $DynamicFieldStatsParameter->{Block} eq 'MultiSelectField' ) {

                # create object attributes (multiple values)
                my %ObjectAttribute = (
                    Name             => $DynamicFieldStatsParameter->{Name},
                    UseAsXvalue      => 0,
                    UseAsValueSeries => 0,
                    UseAsRestriction => 1,
                    Element          => $DynamicFieldStatsParameter->{Element},
                    Block            => $DynamicFieldStatsParameter->{Block},
                    Values           => $DynamicFieldStatsParameter->{Values},
                    Translation      => $DynamicFieldStatsParameter->{TranslatableValues} || 0,
                    IsDynamicField   => 1,
                    ShowAsTree       => $DynamicFieldConfig->{Config}->{TreeView} || 0,
                );
                push @ObjectAttributes, \%ObjectAttribute;
            }
            else {

                # create object attributes (text fields)
                my %ObjectAttribute = (
                    Name             => $DynamicFieldStatsParameter->{Name},
                    UseAsXvalue      => 0,
                    UseAsValueSeries => 0,
                    UseAsRestriction => 1,
                    Element          => $DynamicFieldStatsParameter->{Element},
                    Block            => $DynamicFieldStatsParameter->{Block},
                );
                push @ObjectAttributes, \%ObjectAttribute;
            }
        }
    }

    return @ObjectAttributes;
}

sub GetStatTablePreview {
    my ( $Self, %Param ) = @_;

    return $Self->GetStatTable(
        %Param,
        Preview => 1,
    );
}

sub GetStatTable {
    my ( $Self, %Param ) = @_;
    my %TicketAttributes    = map { $_ => 1 } @{ $Param{XValue}{SelectedValues} };
    my $SortedAttributesRef = $Self->_SortedAttributes();
    my $Preview             = $Param{Preview};

    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    # check if a enumeration is requested
    my $AddEnumeration = 0;
    if ( $TicketAttributes{Number} ) {
        $AddEnumeration = 1;
        delete $TicketAttributes{Number};
    }

    # set default values if no sort or order attribute is given
    my $OrderRef = first { $_->{Element} eq 'OrderBy' } @{ $Param{ValueSeries} };
    my $OrderBy  = $OrderRef ? $OrderRef->{SelectedValues}[0] : 'Age';
    my $SortRef  = first { $_->{Element} eq 'SortSequence' } @{ $Param{ValueSeries} };
    my $Sort     = $SortRef ? $SortRef->{SelectedValues}[0] : 'Down';
    my $Limit    = $Param{Restrictions}{Limit};

    # check if we can use the sort and order function of TicketSearch
    my $OrderByIsValueOfTicketSearchSort = $Self->_OrderByIsValueOfTicketSearchSort(
        OrderBy => $OrderBy,
    );

    # escape search attributes for ticket search
    my %AttributesToEscape = (
        'CustomerID' => 1,
        'Title'      => 1,
    );

    # Map the CustomerID search parameter to CustomerIDRaw search parameter for the
    #   exact search match, if the 'Stats::CustomerIDAsMultiSelect' is active.
    if ( $Kernel::OM->Get('Kernel::Config')->Get('Stats::CustomerIDAsMultiSelect') ) {
        $Param{Restrictions}->{CustomerIDRaw} = $Param{Restrictions}->{CustomerID};
    }

    ATTRIBUTE:
    for my $Key ( sort keys %{ $Param{Restrictions} } ) {

        next ATTRIBUTE if !$AttributesToEscape{$Key};

        if ( ref $Param{Restrictions}->{$Key} ) {
            if ( ref $Param{Restrictions}->{$Key} eq 'ARRAY' ) {
                $Param{Restrictions}->{$Key} = [
                    map { $DBObject->QueryStringEscape( QueryString => $_ ) }
                        @{ $Param{Restrictions}->{$Key} }
                ];
            }
        }
        else {
            $Param{Restrictions}->{$Key} = $DBObject->QueryStringEscape(
                QueryString => $Param{Restrictions}->{$Key}
            );
        }
    }

    # get dynamic field backend object
    my $DynamicFieldBackendObject = $Kernel::OM->Get('Kernel::System::DynamicField::Backend');

    my %DynamicFieldRestrictions;
    for my $ParameterName ( sort keys %{ $Param{Restrictions} } ) {
        if (
            $ParameterName =~ m{ \A DynamicField_ ( [a-zA-Z\d]+ ) (?: _ ( [a-zA-Z\d]+ ) )? \z }xms
            )
        {
            my $FieldName = $1;
            my $Operator  = $2;

            # loop over the dynamic fields configured
            DYNAMICFIELD:
            for my $DynamicFieldConfig ( @{ $Self->{DynamicField} } ) {
                next DYNAMICFIELD if !IsHashRefWithData($DynamicFieldConfig);
                next DYNAMICFIELD if !$DynamicFieldConfig->{Name};

                # skip all fields that do not match with current field name
                # without the 'DynamicField_' prefix
                next DYNAMICFIELD if $DynamicFieldConfig->{Name} ne $FieldName;

                # skip all fields not designed to be supported by statistics
                my $IsStatsCondition = $DynamicFieldBackendObject->HasBehavior(
                    DynamicFieldConfig => $DynamicFieldConfig,
                    Behavior           => 'IsStatsCondition',
                );

                next DYNAMICFIELD if !$IsStatsCondition;
                next DYNAMICFIELD if !$Param{Restrictions}->{$ParameterName};

                # get new search parameter
                my $DynamicFieldStatsSearchParameter = $DynamicFieldBackendObject->StatsSearchFieldParameterBuild(
                    DynamicFieldConfig => $DynamicFieldConfig,
                    Value              => $Param{Restrictions}->{$ParameterName},
                    Operator           => $Operator,
                );

                # add new search parameter
                if ( !IsHashRefWithData( $DynamicFieldRestrictions{"DynamicField_$FieldName"} ) ) {
                    $DynamicFieldRestrictions{"DynamicField_$FieldName"} =
                        $DynamicFieldStatsSearchParameter;
                }

                # extend search parameter
                elsif ( IsHashRefWithData($DynamicFieldStatsSearchParameter) ) {
                    $DynamicFieldRestrictions{"DynamicField_$FieldName"} = {
                        %{ $DynamicFieldRestrictions{"DynamicField_$FieldName"} },
                        %{$DynamicFieldStatsSearchParameter},
                    };
                }
            }
        }
    }

    if ($OrderByIsValueOfTicketSearchSort) {

        # don't be irritated of the mixture OrderBy <> Sort and SortBy <> OrderBy
        # the meaning is in TicketSearch is different as in common handling
        $Param{Restrictions}{OrderBy} = $Sort;
        $Param{Restrictions}{SortBy}  = $OrderByIsValueOfTicketSearchSort;
        $Param{Restrictions}{Limit}   = !$Limit || $Limit eq 'unlimited' ? 100_000_000 : $Limit;
    }
    else {
        $Param{Restrictions}{Limit} = 100_000_000;
    }

    # get state object
    my $StateObject = $Kernel::OM->Get('Kernel::System::State');

    # OlderTicketsExclude for historic searches
    # takes tickets that were closed before the
    # start of the searched time periode
    my %OlderTicketsExclude;

    # NewerTicketExclude for historic searches
    # takes tickets that were created after the
    # searched time periode
    my %NewerTicketsExclude;
    my %StateList = $StateObject->StateList( UserID => 1 );

    # get time object
    my $DateTimeObject = $Kernel::OM->Create('Kernel::System::DateTime');

    # UnixTimeStart & End:
    # The Time periode the historic search is executed
    # if no time periode has been selected we take
    # Unixtime 0 as StartTime and SystemTime as EndTime
    my $UnixTimeStart = 0;
    my $UnixTimeEnd   = $DateTimeObject->ToEpoch();

    if ( $Kernel::OM->Get('Kernel::Config')->Get('Ticket::ArchiveSystem') ) {
        $Param{Restrictions}->{SearchInArchive} ||= '';
        if ( $Param{Restrictions}->{SearchInArchive} eq 'AllTickets' ) {
            $Param{Restrictions}->{ArchiveFlags} = [ 'y', 'n' ];
        }
        elsif ( $Param{Restrictions}->{SearchInArchive} eq 'ArchivedTickets' ) {
            $Param{Restrictions}->{ArchiveFlags} = ['y'];
        }
        else {
            $Param{Restrictions}->{ArchiveFlags} = ['n'];
        }
    }

    # get ticket object
    my $TicketObject = $Kernel::OM->Get('Kernel::System::Ticket');

    if ( !$Preview && $Param{Restrictions}->{HistoricTimeRangeTimeNewerDate} ) {

        # Find tickets that were closed before the start of our
        # HistoricTimeRangeTimeNewerDate, these have to be excluded.
        # In order to reduce it quickly we reformat the result array
        # to a hash.
        my @OldToExclude = $TicketObject->TicketSearch(
            UserID                   => 1,
            Result                   => 'ARRAY',
            Permission               => 'ro',
            TicketCloseTimeOlderDate => $Param{Restrictions}->{HistoricTimeRangeTimeNewerDate},
            ArchiveFlags             => $Param{Restrictions}->{ArchiveFlags},
            Limit                    => 100_000_000,
        );
        %OlderTicketsExclude = map { $_ => 1 } @OldToExclude;

        $DateTimeObject->Set( String => $Param{Restrictions}->{HistoricTimeRangeTimeNewerDate} );
        $UnixTimeStart = $DateTimeObject->ToEpoch();
    }
    if ( !$Preview && $Param{Restrictions}->{HistoricTimeRangeTimeOlderDate} ) {

        # Find tickets that were closed after the end of our
        # HistoricTimeRangeTimeOlderDate, these have to be excluded
        # in order to reduce it quickly we reformat the result array
        # to a hash.
        my @NewToExclude = $TicketObject->TicketSearch(
            UserID                    => 1,
            Result                    => 'ARRAY',
            Permission                => 'ro',
            TicketCreateTimeNewerDate => $Param{Restrictions}->{HistoricTimeRangeTimeOlderDate},
            ArchiveFlags              => $Param{Restrictions}->{ArchiveFlags},
            Limit                     => 100_000_000,
        );
        %NewerTicketsExclude = map { $_ => 1 } @NewToExclude;

        $DateTimeObject->Set( String => $Param{Restrictions}->{HistoricTimeRangeTimeOlderDate} );
        $UnixTimeEnd = $DateTimeObject->ToEpoch();
    }

    # get the involved tickets
    my @TicketIDs;

    if ($Preview) {
        @TicketIDs = $TicketObject->TicketSearch(
            UserID     => 1,
            Result     => 'ARRAY',
            Permission => 'ro',
            Limit      => 10,
        );
    }
    else {
        @TicketIDs = $TicketObject->TicketSearch(
            UserID     => 1,
            Result     => 'ARRAY',
            Permission => 'ro',
            %{ $Param{Restrictions} },
            %DynamicFieldRestrictions,
        );
    }

    # if we had Tickets we need to reduce the found tickets
    # to those not beeing in %OlderTicketsExclude
    # as well as not in %NewerTicketsExclude
    if ( %OlderTicketsExclude || %NewerTicketsExclude ) {
        @TicketIDs = grep {
            !defined $OlderTicketsExclude{$_}
                && !defined $NewerTicketsExclude{$_}
        } @TicketIDs;
    }

    # if we have to deal with history states
    if (
        !$Preview
        && (
            $Param{Restrictions}->{HistoricTimeRangeTimeNewerDate}
            || $Param{Restrictions}->{HistoricTimeRangeTimeOlderDate}
            || (
                defined $Param{Restrictions}->{StateTypeIDsHistoric}
                && ref $Param{Restrictions}->{StateTypeIDsHistoric} eq 'ARRAY'
            )
            || (
                defined $Param{Restrictions}->{StateIDsHistoric}
                && ref $Param{Restrictions}->{StateIDsHistoric} eq 'ARRAY'
            )
        )
        && @TicketIDs
        )
    {

        my $SQLTicketIDInCondition = $DBObject->QueryInCondition(
            Key       => 'ticket_id',
            Values    => \@TicketIDs,
            QuoteType => 'Integer',
            BindMode  => 0,
        );

        # start building the SQL query from back to front
        # what's fixed is the history_type_id we have to search for
        # 1 is ticketcreate
        # 27 is state update
        my $SQL = $SQLTicketIDInCondition . ' AND history_type_id IN (1,27) ORDER BY ticket_id ASC';

        my %StateIDs;

        # if we have certain state types we have to search for
        # build a hash holding all ticket StateIDs => StateNames
        # we are searching for
        if (
            defined $Param{Restrictions}->{StateTypeIDsHistoric}
            && ref $Param{Restrictions}->{StateTypeIDsHistoric} eq 'ARRAY'
            )
        {

            # getting the StateListType:
            # my %ListType = (
            #     1 => "new",
            #     2 => "open",
            #     3 => "closed",
            #     4 => "pending reminder",
            #     5 => "pending auto",
            #     6 => "removed",
            #     7 => "merged",
            # );
            my %ListType = $StateObject->StateTypeList(
                UserID => 1,
            );

            # Takes the Array of StateTypeID's
            # example: (1, 3, 5, 6, 7)
            # maps the ID's to the StateTypeNames
            # results in a Hash containing the StateTypeNames
            # example:
            # %StateTypeHash = {
            #                  'closed' => 1,
            #                  'removed' => 1,
            #                  'pending auto' => 1,
            #                  'merged' => 1,
            #                  'new' => 1
            #               };
            my %StateTypeHash = map { $ListType{$_} => 1 }
                @{ $Param{Restrictions}->{StateTypeIDsHistoric} };

            # And now get the StatesByType
            # Result is a Hash {ID => StateName,}
            my @StateTypes = keys %StateTypeHash;
            %StateIDs = $StateObject->StateGetStatesByType(
                StateType => [ keys %StateTypeHash ],
                Result    => 'HASH',
            );
        }

        # if we had certain states selected, add them to the
        # StateIDs Hash
        if (
            defined $Param{Restrictions}->{StateIDsHistoric}
            && ref $Param{Restrictions}->{StateIDsHistoric} eq 'ARRAY'
            )
        {

            # Validate the StateIDsHistoric list by
            # checking if they are in the %StateList hash
            # then taking all ValidState ID's and return a hash
            # holding { StateID => Name }
            my %Tmp = map { $_ => $StateList{$_} }
                grep { $StateList{$_} } @{ $Param{Restrictions}->{StateIDsHistoric} };
            %StateIDs = ( %StateIDs, %Tmp );
        }

        $SQL = 'SELECT ticket_id, state_id, create_time FROM ticket_history WHERE ' . $SQL;

        $DBObject->Prepare( SQL => $SQL );

        # Structure:
        # Stores the last TicketState:
        # TicketID => [StateID, CreateTime]
        my %FoundTickets;

        # fetch the result
        while ( my @Row = $DBObject->FetchrowArray() ) {
            if ( $Row[0] ) {
                my $TicketID = $Row[0];
                my $StateID  = $Row[1];
                $DateTimeObject->Set( String => $Row[2] );
                my $RowTimeUnix = $DateTimeObject->ToEpoch();

                # Entries before StartTime
                if ( $RowTimeUnix < $UnixTimeStart ) {

                    # if the ticket was already stored
                    if ( $FoundTickets{$TicketID} ) {

                        # if the current state is in the searched states
                        # update the record
                        if ( $StateIDs{$StateID} ) {
                            $FoundTickets{$TicketID} = [ $StateID, $RowTimeUnix ];
                        }

                        # if it is not in the searched states
                        # a state change happend ->
                        # delete the record
                        else {
                            delete $FoundTickets{$TicketID};
                        }
                    }

                    # if the ticket was NOT already stored
                    # and the state is in the searched states
                    # store the record
                    elsif ( $StateIDs{$StateID} ) {
                        $FoundTickets{$TicketID} = [ $StateID, $RowTimeUnix ];
                    }
                }

                # Entries between Start and EndTime
                if (
                    $RowTimeUnix >= $UnixTimeStart
                    && $RowTimeUnix <= $UnixTimeEnd
                    )
                {

                    # if we found a record
                    # with the searched states
                    # add it to the FoundTickets
                    if ( $StateIDs{$StateID} ) {
                        $FoundTickets{$TicketID} = [ $StateID, $RowTimeUnix ];
                    }
                }
            }
        }

        # if we had tickets that matched our query
        # use them to get the details for the statistic
        if (%FoundTickets) {
            @TicketIDs = sort { $a <=> $b } keys %FoundTickets;
        }

        # if no Tickets were remaining,
        # after reducing the total amount by the ones
        # that had none of the searched states,
        # empty @TicketIDs
        else {
            @TicketIDs = ();
        }
    }

    # find out if the extended version of TicketGet is needed,
    my $Extended = $Self->_ExtendedAttributesCheck(
        TicketAttributes => \%TicketAttributes,
    );

    # find out if dynamic fields are required
    my $NeedDynamicFields = 0;
    DYNAMICFIELDSNEEDED:
    for my $ParameterName ( sort keys %TicketAttributes ) {
        if ( $ParameterName =~ m{\A DynamicField_ }xms ) {
            $NeedDynamicFields = 1;
            last DYNAMICFIELDSNEEDED;
        }
    }

    my $StatsObject = $Kernel::OM->Get('Kernel::System::Stats');

    # generate the ticket list
    my @StatArray;
    for my $TicketID (@TicketIDs) {
        my @ResultRow;
        my %Ticket = $TicketObject->TicketGet(
            TicketID      => $TicketID,
            UserID        => 1,
            Extended      => $Extended,
            DynamicFields => $NeedDynamicFields,
        );

        # Format Ticket 'Age' param into human readable format.
        $Ticket{Age} = $StatsObject->_HumanReadableAgeGet(
            Age => $Ticket{Age},
        );

        # add the accounted time if needed
        if ( $TicketAttributes{AccountedTime} ) {
            $Ticket{AccountedTime} = $TicketObject->TicketAccountedTimeGet( TicketID => $TicketID );
        }

        # add the number of articles if needed
        if ( $TicketAttributes{NumberOfArticles} ) {
            $Ticket{NumberOfArticles} = $Kernel::OM->Get('Kernel::System::Ticket::Article')->ArticleList(
                TicketID => $TicketID,
                UserID   => 1
            );
        }

        $Ticket{Closed}                      ||= '';
        $Ticket{SolutionTime}                ||= '';
        $Ticket{SolutionDiffInMin}           ||= 0;
        $Ticket{SolutionInMin}               ||= 0;
        $Ticket{SolutionTimeEscalation}      ||= 0;
        $Ticket{FirstResponse}               ||= '';
        $Ticket{FirstResponseDiffInMin}      ||= 0;
        $Ticket{FirstResponseInMin}          ||= 0;
        $Ticket{FirstResponseTimeEscalation} ||= 0;
        $Ticket{FirstLock}                   ||= '';
        $Ticket{UpdateTimeDestinationDate}   ||= '';
        $Ticket{UpdateTimeDestinationTime}   ||= 0;
        $Ticket{UpdateTimeWorkingTime}       ||= 0;
        $Ticket{UpdateTimeEscalation}        ||= 0;
        $Ticket{SolutionTimeDestinationDate} ||= '';
        $Ticket{EscalationDestinationIn}     ||= '';
        $Ticket{EscalationDestinationDate}   ||= '';
        $Ticket{EscalationTimeWorkingTime}   ||= 0;
        $Ticket{NumberOfArticles}            ||= 0;

        for my $ParameterName ( sort keys %Ticket ) {
            if ( $ParameterName =~ m{\A DynamicField_ ( [a-zA-Z\d]+ ) \z}xms ) {

                # loop over the dynamic fields configured
                DYNAMICFIELD:
                for my $DynamicFieldConfig ( @{ $Self->{DynamicField} } ) {
                    next DYNAMICFIELD if !IsHashRefWithData($DynamicFieldConfig);
                    next DYNAMICFIELD if !$DynamicFieldConfig->{Name};

                    # skip all fields that does not match with current field name ($1)
                    # without the 'DynamicField_' prefix
                    next DYNAMICFIELD if $DynamicFieldConfig->{Name} ne $1;

                    # prevent unitilization errors
                    if ( !defined $Ticket{$ParameterName} ) {
                        $Ticket{$ParameterName} = '';
                        next DYNAMICFIELD;
                    }

                    # convert from stored keys to values for certain Dynamic Fields like
                    # Dropdown, Checkbox and Multiselect
                    my $ValueLookup = $DynamicFieldBackendObject->ValueLookup(
                        DynamicFieldConfig => $DynamicFieldConfig,
                        Key                => $Ticket{$ParameterName},
                    );

                    # get field value in plain text
                    my $ValueStrg = $DynamicFieldBackendObject->ReadableValueRender(
                        DynamicFieldConfig => $DynamicFieldConfig,
                        Value              => $ValueLookup,
                    );

                    if ( $ValueStrg->{Value} ) {

                        # change raw value from ticket to a plain text value
                        $Ticket{$ParameterName} = $ValueStrg->{Value};

                        ## nofilter(TidyAll::Plugin::OTRS::Perl::LayoutObject)
                        if ( $DynamicFieldConfig->{Name} =~ /ProcessManagementProcessID|ProcessManagementActivityID/ ) {
                            my $DisplayValue = $DynamicFieldBackendObject->DisplayValueRender(
                                DynamicFieldConfig => $DynamicFieldConfig,
                                Value              => $ValueStrg->{Value},
                                ValueMaxChars      => 20,
                                LayoutObject       => $Kernel::OM->Get('Kernel::Output::HTML::Layout'),
                                HTMLOutput         => 0,
                            );
                            $Ticket{$ParameterName} = $DisplayValue->{Value};
                        }

                    }
                }
            }
        }

        ATTRIBUTE:
        for my $Attribute ( @{$SortedAttributesRef} ) {
            next ATTRIBUTE if !$TicketAttributes{$Attribute};

            # convert from OTRS time zone to given time zone
            if (
                $Param{TimeZone}
                && $Param{TimeZone} ne Kernel::System::DateTime->OTRSTimeZoneGet()
                && $Ticket{$Attribute}
                && $Ticket{$Attribute} =~ /\A(\d{4})-(\d{2})-(\d{2})\s(\d{2}):(\d{2}):(\d{2})\z/
                )
            {

                $Ticket{$Attribute} = $StatsObject->_FromOTRSTimeZone(
                    String   => $Ticket{$Attribute},
                    TimeZone => $Param{TimeZone},
                );
                $Ticket{$Attribute} .= " ($Param{TimeZone})";
            }

            if ( $Attribute eq 'Owner' || $Attribute eq 'Responsible' ) {
                $Ticket{$Attribute} = $Kernel::OM->Get('Kernel::System::User')->UserName(
                    User          => $Ticket{$Attribute},
                    NoOutOfOffice => 1,
                );
            }

            push @ResultRow, $Ticket{$Attribute};
        }
        push @StatArray, \@ResultRow;
    }

    # use a individual sort if the sort mechanism of the TicketSearch is not usable
    if ( !$OrderByIsValueOfTicketSearchSort ) {
        @StatArray = $Self->_IndividualResultOrder(
            StatArray          => \@StatArray,
            OrderBy            => $OrderBy,
            Sort               => $Sort,
            SelectedAttributes => \%TicketAttributes,
            Limit              => $Limit,
        );
    }

    # add a enumeration in front of each row
    if ($AddEnumeration) {
        my $Counter = 0;
        for my $Row (@StatArray) {
            unshift @{$Row}, ++$Counter;
        }
    }

    return @StatArray;
}

sub GetHeaderLine {
    my ( $Self, %Param ) = @_;
    my %SelectedAttributes = map { $_ => 1 } @{ $Param{XValue}{SelectedValues} };

    my $TicketAttributes    = $Self->_TicketAttributes();
    my $SortedAttributesRef = $Self->_SortedAttributes();
    my @HeaderLine;

    # get language object
    my $LanguageObject = $Kernel::OM->Get('Kernel::Language');

    ATTRIBUTE:
    for my $Attribute ( @{$SortedAttributesRef} ) {
        next ATTRIBUTE if !$SelectedAttributes{$Attribute};
        push @HeaderLine, $LanguageObject->Translate( $TicketAttributes->{$Attribute} );
    }
    return \@HeaderLine;
}

sub ExportWrapper {
    my ( $Self, %Param ) = @_;

    # get needed objects
    my $UserObject     = $Kernel::OM->Get('Kernel::System::User');
    my $QueueObject    = $Kernel::OM->Get('Kernel::System::Queue');
    my $StateObject    = $Kernel::OM->Get('Kernel::System::State');
    my $PriorityObject = $Kernel::OM->Get('Kernel::System::Priority');

    # wrap ids to used spelling
    for my $Use (qw(UseAsValueSeries UseAsRestriction UseAsXvalue)) {
        ELEMENT:
        for my $Element ( @{ $Param{$Use} } ) {
            next ELEMENT if !$Element || !$Element->{SelectedValues};
            my $ElementName = $Element->{Element};
            my $Values      = $Element->{SelectedValues};

            if ( $ElementName eq 'QueueIDs' || $ElementName eq 'CreatedQueueIDs' ) {
                ID:
                for my $ID ( @{$Values} ) {
                    next ID if !$ID;
                    $ID->{Content} = $QueueObject->QueueLookup( QueueID => $ID->{Content} );
                }
            }
            elsif ( $ElementName eq 'StateIDs' || $ElementName eq 'CreatedStateIDs' ) {
                my %StateList = $StateObject->StateList( UserID => 1 );
                ID:
                for my $ID ( @{$Values} ) {
                    next ID if !$ID;
                    $ID->{Content} = $StateList{ $ID->{Content} };
                }
            }
            elsif ( $ElementName eq 'PriorityIDs' || $ElementName eq 'CreatedPriorityIDs' ) {
                my %PriorityList = $PriorityObject->PriorityList( UserID => 1 );
                ID:
                for my $ID ( @{$Values} ) {
                    next ID if !$ID;
                    $ID->{Content} = $PriorityList{ $ID->{Content} };
                }
            }
            elsif (
                $ElementName eq 'OwnerIDs'
                || $ElementName eq 'CreatedUserIDs'
                || $ElementName eq 'ResponsibleIDs'
                )
            {
                ID:
                for my $ID ( @{$Values} ) {
                    next ID if !$ID;
                    $ID->{Content} = $UserObject->UserLookup( UserID => $ID->{Content} );
                }
            }

            # Locks and statustype don't have to wrap because they are never different
        }
    }
    return \%Param;
}

sub ImportWrapper {
    my ( $Self, %Param ) = @_;

    # get needed objects
    my $UserObject     = $Kernel::OM->Get('Kernel::System::User');
    my $QueueObject    = $Kernel::OM->Get('Kernel::System::Queue');
    my $StateObject    = $Kernel::OM->Get('Kernel::System::State');
    my $PriorityObject = $Kernel::OM->Get('Kernel::System::Priority');

    # wrap used spelling to ids
    for my $Use (qw(UseAsValueSeries UseAsRestriction UseAsXvalue)) {
        ELEMENT:
        for my $Element ( @{ $Param{$Use} } ) {
            next ELEMENT if !$Element || !$Element->{SelectedValues};
            my $ElementName = $Element->{Element};
            my $Values      = $Element->{SelectedValues};

            if ( $ElementName eq 'QueueIDs' || $ElementName eq 'CreatedQueueIDs' ) {
                ID:
                for my $ID ( @{$Values} ) {
                    next ID if !$ID;
                    if ( $QueueObject->QueueLookup( Queue => $ID->{Content} ) ) {
                        $ID->{Content} = $QueueObject->QueueLookup( Queue => $ID->{Content} );
                    }
                    else {
                        $Kernel::OM->Get('Kernel::System::Log')->Log(
                            Priority => 'error',
                            Message  => "Import: Can' find the queue $ID->{Content}!"
                        );
                        $ID = undef;
                    }
                }
            }
            elsif ( $ElementName eq 'StateIDs' || $ElementName eq 'CreatedStateIDs' ) {
                ID:
                for my $ID ( @{$Values} ) {
                    next ID if !$ID;

                    my %State = $StateObject->StateGet(
                        Name  => $ID->{Content},
                        Cache => 1,
                    );
                    if ( $State{ID} ) {
                        $ID->{Content} = $State{ID};
                    }
                    else {
                        $Kernel::OM->Get('Kernel::System::Log')->Log(
                            Priority => 'error',
                            Message  => "Import: Can' find state $ID->{Content}!"
                        );
                        $ID = undef;
                    }
                }
            }
            elsif ( $ElementName eq 'PriorityIDs' || $ElementName eq 'CreatedPriorityIDs' ) {
                my %PriorityList = $PriorityObject->PriorityList( UserID => 1 );
                my %PriorityIDs;
                for my $Key ( sort keys %PriorityList ) {
                    $PriorityIDs{ $PriorityList{$Key} } = $Key;
                }
                ID:
                for my $ID ( @{$Values} ) {
                    next ID if !$ID;

                    if ( $PriorityIDs{ $ID->{Content} } ) {
                        $ID->{Content} = $PriorityIDs{ $ID->{Content} };
                    }
                    else {
                        $Kernel::OM->Get('Kernel::System::Log')->Log(
                            Priority => 'error',
                            Message  => "Import: Can' find priority $ID->{Content}!"
                        );
                        $ID = undef;
                    }
                }
            }
            elsif (
                $ElementName eq 'OwnerIDs'
                || $ElementName eq 'CreatedUserIDs'
                || $ElementName eq 'ResponsibleIDs'
                )
            {
                ID:
                for my $ID ( @{$Values} ) {
                    next ID if !$ID;

                    if ( $UserObject->UserLookup( UserLogin => $ID->{Content} ) ) {
                        $ID->{Content} = $UserObject->UserLookup(
                            UserLogin => $ID->{Content}
                        );
                    }
                    else {
                        $Kernel::OM->Get('Kernel::System::Log')->Log(
                            Priority => 'error',
                            Message  => "Import: Can' find user $ID->{Content}!"
                        );
                        $ID = undef;
                    }
                }
            }

            # Locks and statustype don't have to wrap because they are never different
        }
    }
    return \%Param;
}

sub _TicketAttributes {
    my $Self = shift;

    # get config object
    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');

    my %TicketAttributes = (
        Number       => Translatable('Number'),               # only a counter for a better readability
        TicketNumber => $ConfigObject->Get('Ticket::Hook'),

        #TicketID       => 'TicketID',
        Age   => 'Age',
        Title => 'Title',
        Queue => 'Queue',

        #QueueID        => 'QueueID',
        State => 'State',

        #StateID        => 'StateID',
        Priority => 'Priority',

        #PriorityID     => 'PriorityID',
        CustomerID => 'Customer ID',
        Changed    => Translatable('Last Changed'),
        Created    => 'Created',

        CustomerUserID => 'Customer User',
        Lock           => 'Lock',

        #LockID         => 'LockID',
        UnlockTimeout       => 'UnlockTimeout',
        AccountedTime       => 'Accounted time',        # the same wording is in AgentTicketPrint.tt
        RealTillTimeNotUsed => 'RealTillTimeNotUsed',
        NumberOfArticles    => 'Number of Articles',

        #GroupID        => 'GroupID',
        StateType => 'StateType',
        UntilTime => 'UntilTime',
        Closed    => 'Close Time',
        FirstLock => 'First Lock',

        EscalationResponseTime => 'EscalationResponseTime',
        EscalationUpdateTime   => 'EscalationUpdateTime',
        EscalationSolutionTime => 'EscalationSolutionTime',

        EscalationDestinationIn => 'EscalationDestinationIn',

        # EscalationDestinationTime => 'EscalationDestinationTime',
        EscalationDestinationDate => 'EscalationDestinationDate',
        EscalationTimeWorkingTime => 'EscalationTimeWorkingTime',
        EscalationTime            => 'EscalationTime',

        FirstResponse                    => 'FirstResponse',
        FirstResponseInMin               => 'FirstResponseInMin',
        FirstResponseDiffInMin           => 'FirstResponseDiffInMin',
        FirstResponseTimeWorkingTime     => 'FirstResponseTimeWorkingTime',
        FirstResponseTimeEscalation      => 'FirstResponseTimeEscalation',
        FirstResponseTimeNotification    => 'FirstResponseTimeNotification',
        FirstResponseTimeDestinationTime => 'FirstResponseTimeDestinationTime',
        FirstResponseTimeDestinationDate => 'FirstResponseTimeDestinationDate',
        FirstResponseTime                => 'FirstResponseTime',

        UpdateTimeEscalation      => 'UpdateTimeEscalation',
        UpdateTimeNotification    => 'UpdateTimeNotification',
        UpdateTimeDestinationTime => 'UpdateTimeDestinationTime',
        UpdateTimeDestinationDate => 'UpdateTimeDestinationDate',
        UpdateTimeWorkingTime     => 'UpdateTimeWorkingTime',
        UpdateTime                => 'UpdateTime',

        SolutionTime                => 'SolutionTime',
        SolutionInMin               => 'SolutionInMin',
        SolutionDiffInMin           => 'SolutionDiffInMin',
        SolutionTimeWorkingTime     => 'SolutionTimeWorkingTime',
        SolutionTimeEscalation      => 'SolutionTimeEscalation',
        SolutionTimeNotification    => 'SolutionTimeNotification',
        SolutionTimeDestinationTime => 'SolutionTimeDestinationTime',
        SolutionTimeDestinationDate => 'SolutionTimeDestinationDate',
        SolutionTimeWorkingTime     => 'SolutionTimeWorkingTime',
    );

    if ( $ConfigObject->Get('Ticket::Service') ) {
        $TicketAttributes{Service} = 'Service';

        #$TicketAttributes{ServiceID} = 'ServiceID',
        $TicketAttributes{SLA}   = 'SLA';
        $TicketAttributes{SLAID} = 'SLAID';
    }

    if ( $ConfigObject->Get('Ticket::Type') ) {
        $TicketAttributes{Type} = 'Type';

        #$TicketAttributes{TypeID} = 'TypeID';
    }

    if ( $ConfigObject->Get('Stats::UseAgentElementInStats') ) {
        $TicketAttributes{Owner} = 'Agent/Owner';

        #$TicketAttributes{OwnerID}        = 'OwnerID';
        # ? $TicketAttributes{CreatedUserIDs}  = 'Created by Agent/Owner';
        $TicketAttributes{Responsible} = 'Responsible';

        #$TicketAttributes{ResponsibleID}  = 'ResponsibleID';
    }

    DYNAMICFIELD:
    for my $DynamicFieldConfig ( @{ $Self->{DynamicField} } ) {
        next DYNAMICFIELD if !IsHashRefWithData($DynamicFieldConfig);
        next DYNAMICFIELD if !$DynamicFieldConfig->{Name};

        $TicketAttributes{ 'DynamicField_' . $DynamicFieldConfig->{Name} } = $DynamicFieldConfig->{Label};
    }

    return \%TicketAttributes;
}

sub _SortedAttributes {
    my $Self = shift;

    my @SortedAttributes = qw(
        Number
        TicketNumber
        Age
        Title
        Created
        Changed
        Closed
        Queue
        State
        Priority
        CustomerUserID
        CustomerID
        Service
        SLA
        Type
        Owner
        Responsible
        AccountedTime
        EscalationDestinationIn
        EscalationDestinationTime
        EscalationDestinationDate
        EscalationTimeWorkingTime
        EscalationTime

        FirstResponse
        FirstResponseInMin
        FirstResponseDiffInMin
        FirstResponseTimeWorkingTime
        FirstResponseTimeEscalation
        FirstResponseTimeNotification
        FirstResponseTimeDestinationTime
        FirstResponseTimeDestinationDate
        FirstResponseTime

        UpdateTimeEscalation
        UpdateTimeNotification
        UpdateTimeDestinationTime
        UpdateTimeDestinationDate
        UpdateTimeWorkingTime
        UpdateTime

        SolutionTime
        SolutionInMin
        SolutionDiffInMin
        SolutionTimeWorkingTime
        SolutionTimeEscalation
        SolutionTimeNotification
        SolutionTimeDestinationTime
        SolutionTimeDestinationDate
        SolutionTimeWorkingTime

        FirstLock
        Lock
        StateType
        UntilTime
        UnlockTimeout
        EscalationResponseTime
        EscalationSolutionTime
        EscalationUpdateTime
        RealTillTimeNotUsed
        NumberOfArticles
    );

    # cycle trought the Dynamic Fields
    DYNAMICFIELD:
    for my $DynamicFieldConfig ( @{ $Self->{DynamicField} } ) {
        next DYNAMICFIELD if !IsHashRefWithData($DynamicFieldConfig);
        next DYNAMICFIELD if !$DynamicFieldConfig->{Name};

        # add dynamic field attribute
        push @SortedAttributes, 'DynamicField_' . $DynamicFieldConfig->{Name};
    }

    return \@SortedAttributes;
}

sub _ExtendedAttributesCheck {
    my ( $Self, %Param ) = @_;

    my @ExtendedAttributes = qw(
        FirstResponse
        FirstResponseInMin
        FirstResponseDiffInMin
        FirstResponseTimeWorkingTime
        Closed
        SolutionTime
        SolutionInMin
        SolutionDiffInMin
        SolutionTimeWorkingTime
        FirstLock
    );

    ATTRIBUTE:
    for my $Attribute (@ExtendedAttributes) {
        return 1 if $Param{TicketAttributes}{$Attribute};
    }

    return;
}

sub _OrderByIsValueOfTicketSearchSort {
    my ( $Self, %Param ) = @_;

    my %SortOptions = (
        Age                    => 'Age',
        Created                => 'Age',
        CustomerID             => 'CustomerID',
        EscalationResponseTime => 'EscalationResponseTime',
        EscalationSolutionTime => 'EscalationSolutionTime',
        EscalationTime         => 'EscalationTime',
        EscalationUpdateTime   => 'EscalationUpdateTime',
        Lock                   => 'Lock',
        Owner                  => 'Owner',
        Priority               => 'Priority',
        Queue                  => 'Queue',
        Responsible            => 'Responsible',
        SLA                    => 'SLA',
        Service                => 'Service',
        State                  => 'State',
        TicketNumber           => 'Ticket',
        TicketEscalation       => 'TicketEscalation',
        Title                  => 'Title',
        Type                   => 'Type',
    );

    # get dynamic field backend object
    my $DynamicFieldBackendObject = $Kernel::OM->Get('Kernel::System::DynamicField::Backend');

    # cycle trought the Dynamic Fields
    DYNAMICFIELD:
    for my $DynamicFieldConfig ( @{ $Self->{DynamicField} } ) {
        next DYNAMICFIELD if !IsHashRefWithData($DynamicFieldConfig);
        next DYNAMICFIELD if !$DynamicFieldConfig->{Name};

        # get dynamic field sortable condition
        my $IsSortable = $DynamicFieldBackendObject->HasBehavior(
            DynamicFieldConfig => $DynamicFieldConfig,
            Behavior           => 'IsSortable',
        );

        # add dynamic field if is sortable
        if ($IsSortable) {
            $SortOptions{ 'DynamicField_' . $DynamicFieldConfig->{Name} }
                = 'DynamicField_' . $DynamicFieldConfig->{Name};
        }
    }

    return $SortOptions{ $Param{OrderBy} } if $SortOptions{ $Param{OrderBy} };
    return;
}

sub _IndividualResultOrder {
    my ( $Self, %Param ) = @_;
    my @Unsorted = @{ $Param{StatArray} };
    my @Sorted;

    # find out the positon of the values which should be
    # used for the order
    my $Counter          = 0;
    my $SortedAttributes = $Self->_SortedAttributes();

    ATTRIBUTE:
    for my $Attribute ( @{$SortedAttributes} ) {
        next ATTRIBUTE if !$Param{SelectedAttributes}{$Attribute};
        last ATTRIBUTE if $Attribute eq $Param{OrderBy};
        $Counter++;
    }

    # order after a individual attribute
    if ( $Param{OrderBy} eq 'AccountedTime' ) {
        @Sorted = sort { $a->[$Counter] <=> $b->[$Counter] } @Unsorted;
    }
    elsif ( $Param{OrderBy} eq 'SolutionTime' ) {
        @Sorted = sort { $a->[$Counter] cmp $b->[$Counter] } @Unsorted;
    }
    elsif ( $Param{OrderBy} eq 'SolutionDiffInMin' ) {
        @Sorted = sort { $a->[$Counter] <=> $b->[$Counter] } @Unsorted;
    }
    elsif ( $Param{OrderBy} eq 'SolutionInMin' ) {
        @Sorted = sort { $a->[$Counter] <=> $b->[$Counter] } @Unsorted;
    }
    elsif ( $Param{OrderBy} eq 'SolutionTimeWorkingTime' ) {
        @Sorted = sort { $a->[$Counter] <=> $b->[$Counter] } @Unsorted;
    }
    elsif ( $Param{OrderBy} eq 'FirstResponse' ) {
        @Sorted = sort { $a->[$Counter] cmp $b->[$Counter] } @Unsorted;
    }
    elsif ( $Param{OrderBy} eq 'FirstResponseDiffInMin' ) {
        @Sorted = sort { $a->[$Counter] <=> $b->[$Counter] } @Unsorted;
    }
    elsif ( $Param{OrderBy} eq 'FirstResponseInMin' ) {
        @Sorted = sort { $a->[$Counter] <=> $b->[$Counter] } @Unsorted;
    }
    elsif ( $Param{OrderBy} eq 'FirstResponseTimeWorkingTime' ) {
        @Sorted = sort { $a->[$Counter] <=> $b->[$Counter] } @Unsorted;
    }
    elsif ( $Param{OrderBy} eq 'FirstLock' ) {
        @Sorted = sort { $a->[$Counter] cmp $b->[$Counter] } @Unsorted;
    }
    elsif ( $Param{OrderBy} eq 'StateType' ) {
        @Sorted = sort { $a->[$Counter] cmp $b->[$Counter] } @Unsorted;
    }
    elsif ( $Param{OrderBy} eq 'UntilTime' ) {
        @Sorted = sort { $a->[$Counter] <=> $b->[$Counter] } @Unsorted;
    }
    elsif ( $Param{OrderBy} eq 'UnlockTimeout' ) {
        @Sorted = sort { $a->[$Counter] <=> $b->[$Counter] } @Unsorted;
    }
    elsif ( $Param{OrderBy} eq 'EscalationResponseTime' ) {
        @Sorted = sort { $a->[$Counter] <=> $b->[$Counter] } @Unsorted;
    }
    elsif ( $Param{OrderBy} eq 'EscalationUpdateTime' ) {
        @Sorted = sort { $a->[$Counter] <=> $b->[$Counter] } @Unsorted;
    }
    elsif ( $Param{OrderBy} eq 'EscalationSolutionTime' ) {
        @Sorted = sort { $a->[$Counter] <=> $b->[$Counter] } @Unsorted;
    }
    elsif ( $Param{OrderBy} eq 'RealTillTimeNotUsed' ) {
        @Sorted = sort { $a->[$Counter] <=> $b->[$Counter] } @Unsorted;
    }
    elsif ( $Param{OrderBy} eq 'EscalationTimeWorkingTime' ) {
        @Sorted = sort { $a->[$Counter] <=> $b->[$Counter] } @Unsorted;
    }
    elsif ( $Param{OrderBy} eq 'NumberOfArticles' ) {
        @Sorted = sort { $a->[$Counter] <=> $b->[$Counter] } @Unsorted;
    }
    else {
        @Sorted = sort { $a->[$Counter] cmp $b->[$Counter] } @Unsorted;
    }

    # make a reverse sort if needed
    if ( $Param{Sort} eq 'Down' ) {
        @Sorted = reverse @Sorted;
    }

    # take care about the limit
    if ( $Param{Limit} && $Param{Limit} ne 'unlimited' ) {
        my $Count = 0;
        @Sorted = grep { ++$Count <= $Param{Limit} } @Sorted;
    }

    return @Sorted;
}

1;
