# --
# Copyright (C) 2021 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::ProcessManagement::TransitionAction::ConfigItemUpdate;

use strict;
use warnings;
use utf8;

use Kernel::System::VariableCheck qw(:all);

use parent qw(Kernel::System::ProcessManagement::TransitionAction::Base);

our @ObjectDependencies = (
    'Kernel::System::CustomerUser',
    'Kernel::System::ITSMConfigItem',
    'Kernel::System::Log',
    'Kernel::System::Ticket',
    'Kernel::System::User',
    'Kernel::System::Util',
    'Kernel::System::ZnunyHelper',
);

=head1 NAME

Kernel::System::ProcessManagement::TransitionAction::ConfigItemUpdate - A module to deploy CI state

=head1 SYNOPSIS

All ConfigItemUpdate functions.

=head1 PUBLIC INTERFACE

=head2 new()

create an object. Do not use it directly, instead use:

    my $ConfigItemUpdateObject = $Kernel::OM->Get('Kernel::System::ProcessManagement::TransitionAction::ConfigItemUpdate');

=cut

sub new {
    my ( $Type, %Param ) = @_;

    my $Self = {};
    bless( $Self, $Type );

    return $Self;
}

=head2 Run()

Runs TransitionAction ConfigItemUpdate.
This function sets, updates or deletes values (of attribute) of given ConfigItemID (ConfigItemNumber).

    my $Success = $ConfigItemUpdateObject->Run(
        UserID                   => 123,

        # Ticket contains the result of TicketGet including dynamic fields
        Ticket                   => \%Ticket,   # required

        ProcessEntityID          => 'P123',
        ActivityEntityID         => 'A123',
        TransitionEntityID       => 'T123',
        TransitionActionEntityID => 'TA123',

        # Config is the hash stored in a Process::TransitionAction's config key
        Config                   => {
            ConfigItemID    => 123,             # you can also use multiple ConfigItemIDs separated by commas (123, 234, 345)
            or
            ConfigItemNumber => 123,            # you can also use multiple ConfigItemNumbers separated by commas (123, 234, 345)
            UserID           => 123,            # optional, to override the UserID from the logged user

            $Key             => $Value,         # required
        }
    );

Returns:


    my $Success = 1;     # 0

=cut

sub Run {
    my ( $Self, %Param ) = @_;

    my $LogObject    = $Kernel::OM->Get('Kernel::System::Log');
    my $TicketObject = $Kernel::OM->Get('Kernel::System::Ticket');
    my $UserObject   = $Kernel::OM->Get('Kernel::System::User');
    my $UtilObject   = $Kernel::OM->Get('Kernel::System::Util');

    my $IsITSMInstalled = $UtilObject->IsITSMInstalled();
    if ( !$IsITSMInstalled ) {
        $LogObject->Log(
            Priority => 'error',
            Message  => 'Transition action ConfigItemUpdate requires ITSM to be installed.',
        );

        # Don't report as error to process management.
        return 1;
    }

    my $ConfigItemObject = $Kernel::OM->Get('Kernel::System::ITSMConfigItem');

    # define a common message to output in case of any error
    my $CommonMessage = "Process: $Param{ProcessEntityID} Activity: $Param{ActivityEntityID}"
        . " Transition: $Param{TransitionEntityID}"
        . " TransitionAction: $Param{TransitionActionEntityID} - ";

    # check for missing or wrong params
    my $Success = $Self->_CheckParams(
        %Param,
        CommonMessage => $CommonMessage,
    );
    return if !$Success;

    # override UserID if specified as a parameter in the TA config
    $Param{UserID} = $Self->_OverrideUserID(%Param);

    # special case for DyanmicField UserID, convert form DynamicField_UserID to UserID
    if ( defined $Param{Config}->{DynamicField_UserID} ) {
        $Param{Config}->{UserID} = $Param{Config}->{DynamicField_UserID};
        delete $Param{Config}->{DynamicField_UserID};
    }

    # use ticket attributes if needed
    $Self->_ReplaceTicketAttributes(%Param);
    $Self->_ReplaceAdditionalAttributes(%Param);

    my @ConfigItemIDs     = split /\s*,\s*/, $Param{Config}->{ConfigItemID}     || '';
    my @ConfigItemNumbers = split /\s*,\s*/, $Param{Config}->{ConfigItemNumber} || '';

    if ( @ConfigItemIDs || @ConfigItemNumbers ) {
        for my $ConfigItemNumber (@ConfigItemNumbers) {
            my $ConfigItemID = $ConfigItemObject->ConfigItemLookup(
                ConfigItemNumber => $ConfigItemNumber,
            );
            push @ConfigItemIDs, $ConfigItemID;
        }

        return 1 if !@ConfigItemIDs;

        # unique ConfigItemIDs
        my %ConfigItemIDs = map { $_ => $_ } @ConfigItemIDs;
        @ConfigItemIDs = keys %ConfigItemIDs;

        for my $ConfigItemID (@ConfigItemIDs) {
            $Self->ConfigItemAttributesSet(
                %{ $Param{Config} },
                ConfigItemID => $ConfigItemID,
                UserID       => $Param{UserID},
            );
        }

        return 1;
    }

    # look up number to ID
    if ( !$Param{Config}->{ConfigItemID} && $Param{Config}->{ConfigItemNumber} ) {
        $Param{Config}->{ConfigItemID} = $ConfigItemObject->ConfigItemLookup(
            ConfigItemNumber => $Param{Config}->{ConfigItemNumber},
        );
    }

    $Self->ConfigItemAttributesSet(
        %{ $Param{Config} },
        ConfigItemID => $Param{Config}->{ConfigItemID},
        UserID       => $Param{UserID},
    );

    return 1;
}

=head2 ConfigItemAttributesSet()

Deploys new CI attributes - creates a new CI Version.

    my $Success = $ConfigItemUpdateObject->ConfigItemAttributesSet(
        ConfigItemID               => 1,
        or
        ConfigItemNumber           => 1,

        # default ConfigItem data
        DeplStateName              => 'Production',
        InciStateName              => 'Operational',

        # StringifiedXMLData
        'CPU::'                    => 'NEW-CPU, NEW-CPU2',
        'HardDisk::1'              => 'NEW-HardDisk1',
        'HardDisk::1::Capacity::1' => '12',
        'HardDisk::2'              => 'NEW-HardDisk2',
        'HardDisk::2::Capacity::1' => '44',
        'Ram::1'                   => 'NEW-Ram',
        'Ram::2'                   => 'NEW-Ram2',
        'Vendor::1'                => 'NEW-Vendor',

        UserID                     => 123,
    );

Returns:

    my $Success = 1;

=cut

sub ConfigItemAttributesSet {
    my ( $Self, %Param ) = @_;

    my $LogObject         = $Kernel::OM->Get('Kernel::System::Log');
    my $ConfigItemObject  = $Kernel::OM->Get('Kernel::System::ITSMConfigItem');
    my $ZnunyHelperObject = $Kernel::OM->Get('Kernel::System::ZnunyHelper');

    NEEDED:
    for my $Needed (qw(ConfigItemID UserID)) {
        next NEEDED if defined $Param{$Needed};

        $LogObject->Log(
            Priority => 'error',
            Message  => "Parameter '$Needed' is needed!",
        );
        return;
    }

    # get all possible ConfigItem params, depends on the current StringifiedXMLData
    my %ConfigItemParams = $Self->ConfigItemAttributesGet(
        %Param,
    );
    return if !%ConfigItemParams;

    my $VersionID = $ZnunyHelperObject->_ITSMConfigItemVersionAdd(
        ConfigItemID => $Param{ConfigItemID},
        %ConfigItemParams,
    );

    return $VersionID;
}

=head2 ConfigItemAttributesGet()

Returns a valid data structure for a new ConfigItem version.

    my %ConfigItemParams = $ConfigItemUpdateObject->ConfigItemAttributesGet(
        ConfigItemID => 1,
        or
        ConfigItemNumber => 1,

        # default ConfigItem data
        DeplStateName              => 'Production',
        InciStateName              => 'Operational',

        # StringifiedXMLData
        'CPU::'                    => 'NEW-CPU, NEW-CPU2',
        'HardDisk::1'              => 'NEW-HardDisk1',
        'HardDisk::1::Capacity::1' => '12',
        'HardDisk::2'              => 'NEW-HardDisk2',
        'HardDisk::2::Capacity::1' => '44',
        'Ram::1'                   => 'NEW-Ram',
        'Ram::2'                   => 'NEW-Ram2',
        'Vendor'                   => 'NEW-Vendor',
        'Description::1'           => '<OTRS_TICKET_Title>',
        'SerialNumber::1'          => '<OTRS_Ticket_DynamicField_SerialNumber>',

        UserID                     => 123,
    );

Returns:

    my %ConfigItemParams = (
        ConfigItemID  => 1,
        DeplStateName => 'Production',
        InciStateName => 'Operational',
        XMLData => {
            'CPU' => [
                {
                    'Content' => 'NEW-CPU'
                },
                {
                    'Content' => 'NEW-CPU2'
                }
            ],
            'HardDisk' => [
                {
                    'Capacity' => [
                        {
                            'Content' => '12'
                        }
                    ],
                    'Content' => 'NEW-HardDisk1'
                },
                {
                    'Capacity' => [
                        {
                            'Content' => '44'
                        }
                    ],
                    'Content' => 'NEW-HardDisk2'
                }
            ],
            [...],
        }
    );

=cut

sub ConfigItemAttributesGet {
    my ( $Self, %Param ) = @_;

    my $LogObject         = $Kernel::OM->Get('Kernel::System::Log');
    my $ConfigItemObject  = $Kernel::OM->Get('Kernel::System::ITSMConfigItem');
    my $ZnunyHelperObject = $Kernel::OM->Get('Kernel::System::ZnunyHelper');

    NEEDED:
    for my $Needed (qw(ConfigItemID UserID)) {
        next NEEDED if defined $Param{$Needed};

        $LogObject->Log(
            Priority => 'error',
            Message  => "Parameter '$Needed' is needed!",
        );
        return;
    }

    my $Separator = $Param{Separator} || ',';

    # get old values which are needed for version add
    my %Version = $ZnunyHelperObject->_ITSMConfigItemVersionGet(
        ConfigItemID    => $Param{ConfigItemID},
        XMLDataMultiple => 1,
    );

    return if !%Version;

    my %ConfigItemParams = %Param;
    my %StringifiedXMLData;

    # remove not needed attributes
    my @RemoveAttributes = ( 'ConfigItemNumber', 'UserID' );
    ATTRIBUTE:
    for my $Attribute (@RemoveAttributes) {
        next ATTRIBUTE if !$ConfigItemParams{$Attribute};
        delete $ConfigItemParams{$Attribute};
    }

    # add needed / default attributes
    my @ConfigItemAttributes = (
        'ConfigItemID', 'Name',        'ClassName',     'ClassID',
        'DeplStateID',  'InciStateID', 'DeplStateName', 'InciStateName'
    );

    ATTRIBUTE:
    for my $Attribute ( sort keys %ConfigItemParams ) {
        if ( $Attribute !~ m{\:\:}ms ) {

            next ATTRIBUTE if grep { $Attribute eq $_ } @ConfigItemAttributes;
            $StringifiedXMLData{ $Attribute . '::' } = $ConfigItemParams{$Attribute};
        }
        else {
            $StringifiedXMLData{$Attribute} = $ConfigItemParams{$Attribute};
        }
        delete $ConfigItemParams{$Attribute};
    }

    ATTRIBUTE:
    for my $Attribute (@ConfigItemAttributes) {
        next ATTRIBUTE if $ConfigItemParams{$Attribute};
        next ATTRIBUTE if !$Version{$Attribute};
        $ConfigItemParams{$Attribute} = $Version{$Attribute};
    }

    ATTRIBUTE:
    for my $Attribute ( sort keys %StringifiedXMLData ) {
        next ATTRIBUTE if $Attribute !~ m{\:\:$}ms;

        my @Attributes = split /\s*$Separator\s*/, $StringifiedXMLData{$Attribute};

        my $Counter = 0;
        for my $Value (@Attributes) {
            $Counter++;
            $StringifiedXMLData{ $Attribute . $Counter } = $Value;
        }
        delete $StringifiedXMLData{$Attribute};
    }

    my $Definition = $ConfigItemObject->DefinitionGet(
        ClassID => $Version{ClassID},
    );

    my $OriginalStringifiedXMLData;
    if ( $Version{XMLData} && IsHashRefWithData( $Version{XMLData} ) ) {
        $OriginalStringifiedXMLData = $Self->XMLData2StringifiedXMLData(
            XMLData => $Version{XMLData},
        );
    }

    my $XMLData = $Self->StringifiedXMLData2XMLData(
        OriginalStringifiedXMLData => $OriginalStringifiedXMLData || {},
        XMLDefinition              => $Definition->{DefinitionRef},
        StringifiedXMLData         => \%StringifiedXMLData,
        ConfigItemID               => $Param{ConfigItemID},
    );

    $ConfigItemParams{XMLData} = $XMLData;
    return %ConfigItemParams;
}

=head2 XMLData2StringifiedXMLData()

Converts XMLdata structure (used by $ZnunyHelperObject => _ITSMConfigItemVersionAdd()) to stringified XMLData 'CPU::1'.
This function should be integrated into Znuny::ITSM.

    my $StringifiedXMLData = $ConfigItemUpdateObject->XMLData2StringifiedXMLData(
        Prefix  => $Prefix,
        XMLData => {
            'NIC' => [
                {
                    'Content'    => 'NicName1',
                    'IPoverDHCP' => [
                        {
                            'Content' => 'Yes',
                        }
                    ],
                    'IPAddress' => [
                        {
                            'Content' => '123',
                        },
                    ],
                },
                {
                    'Content'   => 'NicName2',
                    'IPoverDHCP' => [
                        {
                            'Content' => 'No',
                        }
                    ],
                    'IPAddress' => [
                        {
                            'Content' => '456',
                        }
                    ],
                }
            ],
        }
    );

Returns:

    my $StringifiedXMLData = {
        NIC::1                => 'NicName1',
        NIC::1::IPAddress::1  => '123',
        NIC::1::IPoverDHCP::1 => 'Yes',
        NIC::2                => 'NicName2',
        NIC::2::IPAddress::1  => '456',
        NIC::2::IPoverDHCP::1 => 'No',
    };

=cut

sub XMLData2StringifiedXMLData {
    my ( $Self, %Param ) = @_;

    my $LogObject = $Kernel::OM->Get('Kernel::System::Log');

    if ( !$Param{XMLData} ) {
        $LogObject->Log(
            Priority => 'error',
            Message  => "Needed parameter 'XMLData'.",
        );
        return;
    }

    my %XMLData = %{ Storable::dclone( $Param{XMLData} ) };
    my $Data;

    ITEM:
    for my $Item ( sort keys %XMLData ) {
        next ITEM if !IsArrayRefWithData( $XMLData{$Item} );

        my $CounterInsert = 1;
        for my $SubItem ( @{ $XMLData{$Item} } ) {
            my $Key = $Item . '::' . $CounterInsert;
            if ( $Param{Prefix} ) {
                $Key = $Param{Prefix} . '::' . $Key;
            }

            if ( $SubItem->{Content} ) {
                $Data->{$Key} = $SubItem->{Content};
                delete $SubItem->{Content};
            }

            my $SubXMLData = $Self->XMLData2StringifiedXMLData(
                XMLData => $SubItem,
                Prefix  => $Key,
            );

            if ($SubXMLData) {
                %{$Data} = (
                    %{$Data},
                    %{$SubXMLData},
                );
            }
            $CounterInsert++;
        }
    }

    return $Data;
}

=head2 StringifiedXMLData2XMLData()

Converts stringified XMLData 'CPU::1' for config-item into XMLdata structure (used by $ZnunyHelperObject => _ITSMConfigItemVersionAdd()).
This function should be integrated into Znuny::ITSM.

    my $XMLData = $ConfigItemUpdateObject->StringifiedXMLData2XMLData(

        # new stringified XMLData for this ConfigItem
        StringifiedXMLData => {
            'CPU::1'                   => 'NEW-CPU',
            'CPU::2'                   => 'NEW-CPU2',
            'HardDisk::1'              => 'NEW-HardDisk1',
            'HardDisk::1::Capacity::1' => '12',
            'HardDisk::2'              => 'NEW-HardDisk2',
            'HardDisk::2::Capacity::1' => '44',
            'Ram::1'                   => 'NEW-Ram',
            'Ram::2'                   => 'NEW-Ram2',
            'Vendor::1'                => 'NEW-Vendor',
        }

        # this is the definition  of this Class $Definition->{DefinitionRef},
        XMLDefinition => [
            {
                'Key' => 'NIC',
                'Input' => {
                       'MaxLength' => 100,
                       'Size'      => 50,
                       'Type'      => 'Text',
                       'Required'  => 1
                },
                'CountDefault' => 1,
                'CountMin'     => 0,
                'CountMax'     => 10,
                'Sub'          => [
                    {
                        'CountMin' => 1,
                        'CountDefault' => 1,
                        'Name' => 'IP over DHCP',
                        'CountMax' => 1,
                        'Input' => {
                            'Type'        => 'GeneralCatalog',
                            'Class'       => 'ITSM::ConfigItem::YesNo',
                            'Required'    => 1,
                            'Translation' => 1
                        },
                        'Key' => 'IPoverDHCP'
                    },
                    {
                        'Searchable'   => 1,
                        'CountMin'     => 0,
                        'CountDefault' => 0,
                        'CountMax'     => 20,
                        'Name'         => 'IP Address',
                        'Key'          => 'IPAddress',
                        'Input'        => {
                            'Type'         => 'Text',
                            'Required'     => 1,
                            'Size'         => 40,
                            'MaxLength'    => 40,
                        }
                    }
                ],
                'Name' => 'Network Adapter'
            },
        ],

        # original stringified XMLData from the latest version of this ConfigItem
        OriginalStringifiedXMLData => {
            'CPU::1'                   => 'CPU',
            'CPU::2'                   => 'CPU2',
            'HardDisk::1'              => 'HardDisk1',
            'HardDisk::1::Capacity::1' => '12',
            'HardDisk::2'              => 'HardDisk2',
            'HardDisk::2::Capacity::1' => '44',
            'Ram::1'                   => 'Ram',
            'Ram::2'                   => 'Ram2',
            'Vendor::1'                => 'Vendor',
        },
        Prefix       => $Prefix,
    );

Returns:

    $XMLData = {
        'CPU' => [
            {
                'Content' => 'CPU'
            },
            {
                'Content' => 'CPU2'
            }
        ],
        'Ram' => [
            {
                'Content' => 'Ram'
            },
            {
                'Content' => 'Ram2'
            }
        ],
        [...]
    };

=cut

sub StringifiedXMLData2XMLData {
    my ( $Self, %Param ) = @_;

    my $LogObject          = $Kernel::OM->Get('Kernel::System::Log');
    my $CustomerUserObject = $Kernel::OM->Get('Kernel::System::CustomerUser');

    if ( !IsArrayRefWithData( $Param{XMLDefinition} ) ) {
        $LogObject->Log(
            Priority => 'error',
            Message  => "Needed parameter 'XMLDefinition' has to be an ArrayRef.",
        );
        return;
    }

    if ( ref $Param{StringifiedXMLData} ne 'HASH' ) {
        $LogObject->Log(
            Priority => 'error',
            Message  => "Needed parameter 'StringifiedXMLData' has to be a HashRef.",
        );
        return;
    }

    my $ReturnData = {};
    ITEM:
    for my $Item ( @{ $Param{XMLDefinition} } ) {
        my $CounterInsert = 0;

        COUNTER:
        for my $Counter ( 1 .. $Item->{CountMax} ) {

            # create inputkey and addkey
            my $Key = $Item->{Key} . '::' . $Counter;
            if ( $Param{Prefix} ) {
                $Key = $Param{Prefix} . '::' . $Key;
            }

            my $ItemCountMin = $Item->{CountMin} || 0;

            if (
                ( !$Param{StringifiedXMLData}->{$Key} && !$Param{OriginalStringifiedXMLData}->{$Key} )
                && $Counter gt $ItemCountMin
                )
            {
                next COUNTER;
            }

            next COUNTER if !$Param{StringifiedXMLData}->{$Key} && !$Param{OriginalStringifiedXMLData}->{$Key};

            # fallback - use OriginalStringifiedXMLData if exists
            my $AttributeValue = $Param{StringifiedXMLData}->{$Key}
                || $Param{OriginalStringifiedXMLData}->{$Key}
                || $Item->{Input}->{ValueDefault};

            if ( defined $Param{StringifiedXMLData}->{$Key} && $Param{StringifiedXMLData}->{$Key} eq '' ) {
                $AttributeValue = $Param{StringifiedXMLData}->{$Key};
            }

            if ( IsArrayRefWithData($AttributeValue) ) {
                my $ValueCounter = $Counter - 1;

                next COUNTER if !$AttributeValue->[$ValueCounter];
                $AttributeValue = $AttributeValue->[$ValueCounter];
            }

            # this is currently the only additional attribute mapping
            elsif (
                IsStringWithData($AttributeValue)
                && IsHashRefWithData( $Item->{Input} )
                && IsStringWithData( $Item->{Input}->{Type} )
                && $Item->{Input}->{Type} eq 'Customer'
                )
            {
                my %CustomerUserList = $CustomerUserObject->CustomerSearch(
                    Search => $AttributeValue,
                );

                my @CustomerUserIDs = keys %CustomerUserList;

                # if CustomerUser exists use them as new AttributeValue
                # if not use from OriginalStringifiedXMLData
                if ( @CustomerUserIDs && scalar @CustomerUserIDs eq '1' ) {
                    $AttributeValue = shift @CustomerUserIDs;
                }
                else {
                    $AttributeValue = $Param{OriginalStringifiedXMLData}->{$Key} || $Item->{Input}->{ValueDefault};
                }
            }

            # start recursion, if "Sub" was found
            if ( $AttributeValue && $Item->{Sub} ) {
                my $SubXMLData = $Self->StringifiedXMLData2XMLData(
                    XMLDefinition              => $Item->{Sub},
                    StringifiedXMLData         => $Param{StringifiedXMLData},
                    Prefix                     => $Key,
                    OriginalStringifiedXMLData => $Param{OriginalStringifiedXMLData},
                );

                $ReturnData->{ $Item->{Key} }->[$CounterInsert] = $SubXMLData;
            }

            $ReturnData->{ $Item->{Key} }->[$CounterInsert]->{Content} = $AttributeValue;
            $CounterInsert++;
        }
    }

    return $ReturnData;
}

1;
