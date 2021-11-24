# --
# Copyright (C) 2021 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

use strict;
use warnings;
use utf8;

use vars (qw($Self));

use Kernel::System::VariableCheck qw(:all);

$Kernel::OM->ObjectParamAdd(
    'Kernel::System::UnitTest::Helper' => {
        RestoreDatabase => 1,
    },
);

my $HelperObject              = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');
my $TicketObject              = $Kernel::OM->Get('Kernel::System::Ticket');
my $ValidObject               = $Kernel::OM->Get('Kernel::System::Valid');
my $ZnunyHelperObject         = $Kernel::OM->Get('Kernel::System::ZnunyHelper');
my $UtilObject                = $Kernel::OM->Get('Kernel::System::Util');
my $DynamicFieldBackendObject = $Kernel::OM->Get('Kernel::System::DynamicField::Backend');
my $DynamicFieldObject        = $Kernel::OM->Get('Kernel::System::DynamicField');

my $IsITSMInstalled = $UtilObject->IsITSMInstalled();
if ( !$IsITSMInstalled ) {
    $Self->True(
        1,
        'Skipping test because ITSM is not installed.',
    );
    return 1;
}

my $ConfigItemObject       = $Kernel::OM->Get('Kernel::System::ITSMConfigItem');
my $GeneralCatalogObject   = $Kernel::OM->Get('Kernel::System::GeneralCatalog');
my $TransitionActionObject = $Kernel::OM->Get('Kernel::System::ProcessManagement::TransitionAction::ConfigItemUpdate');
my $UnitTestITSMConfigItemObject = $Kernel::OM->Get('Kernel::System::UnitTest::ITSMConfigItem');

# Create test config item.
my $ValidID = $ValidObject->ValidLookup(
    Valid => 'valid',
);

my $ClassListRef = $GeneralCatalogObject->ItemList(
    Class => 'ITSM::ConfigItem::Class',
    Valid => $ValidID,
);
my %ClassList = reverse %{ $ClassListRef || {} };

my $ClassID = $ClassList{'Computer'};

my $Definition = $ConfigItemObject->DefinitionGet(
    ClassID => $ClassID,
);

$Self->True(
    IsHashRefWithData($Definition),
    'Config item class "Computer" must be found.',
);

# XMLData default values
my %XMLData = (
    'Type' => [
        {
            'Content' => '44'
        }
    ],
    'OperatingSystem' => [
        {
            'Content' => 'OperatingSystem-Test'
        }
    ],
    'Model' => [
        {
            'Content' => 'Model-Test'
        }
    ],
    'FQDN' => [
        {
            'Content' => 'FQDN-Test'
        }
    ],
    'Hostname' => [
        {
            'Content' => 'Hostname-Test'
        }
    ],
    'HostnamePrefix' => [
        {
            'Content' => 'http://'
        }
    ],
    'CPU' => [
        {
            'Content' => 'CPU-Test'
        }
    ],
    'Ram' => [
        {
            'Content' => 'Ram-Test'
        }
    ],
    'Owner' => [
        {
            'Content' => 's00xxxxx000'
        }
    ],
    'HostnameSuffix' => [
        {
            'Content' => ':2000/'
        }
    ],
    'GraphicAdapter' => [
        {
            'Content' => 'GraphicAdapter-Test'
        }
    ],
    'SerialNumber' => [
        {
            'Content' => 'SerialNumber-Test'
        }
    ],
    'Description' => [
        {
            'Content' => 'Description-Test'
        }
    ],
    'Vendor' => [
        {
            'Content' => 'Vendor-Test'
        }
    ],
    'HardDisk' => [
        {
            'Content'  => 'HardDisk1-Test',
            'Capacity' => [
                {
                    'Content' => '12'
                }
            ],
        },
        {
            'Content'  => 'HardDisk2-Test',
            'Capacity' => [
                {
                    'Content' => '34'
                }
            ],
        }
    ],
    'WarrantyExpirationDate' => [
        {
            'Content' => '2018-10-04'
        }
    ],
    'NIC' => [
        {
            'Content'    => 'NicName1',
            'IPoverDHCP' => [
                {
                    'Content' => '37',
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
            'IPAddress' => [
                {
                    'Content' => '456',
                }
            ],
            'IPoverDHCP' => [
                {
                    'Content' => '38',
                }
            ],
        }
    ],
);

my $VersionRef = $UnitTestITSMConfigItemObject->ConfigItemCreate(
    Name          => 'CI',
    ClassName     => 'Computer',
    DeplStateName => 'Production',
    InciStateName => 'Operational',
    XMLData       => \%XMLData
);

my $ConfigItemID = $VersionRef->{ConfigItemID};

my $VersionRef2 = $UnitTestITSMConfigItemObject->ConfigItemCreate(
    Name          => 'CI2',
    ClassName     => 'Computer',
    DeplStateName => 'Production',
    InciStateName => 'Operational',
    XMLData       => \%XMLData
);

my $ConfigItemID2 = $VersionRef2->{ConfigItemID};

# XMLData2StringifiedXMLData
my %XMLData2StringifiedXMLData = %XMLData;

my $StringifiedXMLData = $TransitionActionObject->XMLData2StringifiedXMLData(
    XMLData => \%XMLData2StringifiedXMLData,
);

$Self->IsDeeply(
    $StringifiedXMLData,
    {
        'CPU::1'                    => 'CPU-Test',
        'Description::1'            => 'Description-Test',
        'FQDN::1'                   => 'FQDN-Test',
        'GraphicAdapter::1'         => 'GraphicAdapter-Test',
        'HardDisk::1'               => 'HardDisk1-Test',
        'HardDisk::1::Capacity::1'  => '12',
        'HardDisk::2'               => 'HardDisk2-Test',
        'HardDisk::2::Capacity::1'  => '34',
        'Hostname::1'               => 'Hostname-Test',
        'HostnamePrefix::1'         => 'http://',
        'HostnameSuffix::1'         => ':2000/',
        'Model::1'                  => 'Model-Test',
        'NIC::1'                    => 'NicName1',
        'NIC::1::IPAddress::1'      => '123',
        'NIC::1::IPoverDHCP::1'     => '37',                     # Yes
        'NIC::2'                    => 'NicName2',
        'NIC::2::IPAddress::1'      => '456',
        'NIC::2::IPoverDHCP::1'     => '38',                     # No
        'OperatingSystem::1'        => 'OperatingSystem-Test',
        'Owner::1'                  => 's00xxxxx000',
        'Ram::1'                    => 'Ram-Test',
        'SerialNumber::1'           => 'SerialNumber-Test',
        'Type::1'                   => '44',
        'Vendor::1'                 => 'Vendor-Test',
        'WarrantyExpirationDate::1' => '2018-10-04'
    },
    'XMLData2StringifiedXMLData original data was successful',
);

# StringifiedXMLData2XMLData
# only convert this data without original data

my %StringifiedXMLData = ();

my $XMLData = $TransitionActionObject->StringifiedXMLData2XMLData(
    ConfigItemID       => $ConfigItemID,
    XMLDefinition      => $Definition->{DefinitionRef},
    StringifiedXMLData => {
        'NIC::1'               => 'NicName1',
        'NIC::1::IPAddress::1' => '123',
    },
);

$Self->IsDeeply(
    $XMLData,
    {
        'NIC' => [
            {
                'Content'   => 'NicName1',
                'IPAddress' => [
                    {
                        'Content' => '123'
                    }
                ]
            }
        ]
    },
    'StringifiedXMLData2XMLData without original data was successful',

);

# StringifiedXMLData2XMLData
# convert this data with original data

%StringifiedXMLData = (
    'Vendor::1'                => 'NEW-Vendor',
    'CPU::1'                   => 'NEW-CPU',
    'CPU::2'                   => 'NEW-CPU2',
    'Ram::1'                   => 'NEW-Ram',
    'Ram::2'                   => 'NEW-Ram2',
    'HardDisk::1'              => 'NEW-HardDisk1',
    'HardDisk::1::Capacity::1' => '12',
    'HardDisk::2'              => 'NEW-HardDisk2',
    'HardDisk::2::Capacity::1' => '44',
);
$XMLData = $TransitionActionObject->StringifiedXMLData2XMLData(
    OriginalStringifiedXMLData => $StringifiedXMLData,
    XMLDefinition              => $Definition->{DefinitionRef},
    StringifiedXMLData         => \%StringifiedXMLData,
    ConfigItemID               => $ConfigItemID,
);

$Self->IsDeeply(
    $XMLData,
    {
        'CPU' => [
            {
                'Content' => 'NEW-CPU'
            },
            {
                'Content' => 'NEW-CPU2'
            }
        ],
        'Description' => [
            {
                'Content' => 'Description-Test'
            }
        ],
        'FQDN' => [
            {
                'Content' => 'FQDN-Test'
            }
        ],
        'GraphicAdapter' => [
            {
                'Content' => 'GraphicAdapter-Test'
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
        'Model' => [
            {
                'Content' => 'Model-Test'
            }
        ],
        'NIC' => [
            {
                'Content'   => 'NicName1',
                'IPAddress' => [
                    {
                        'Content' => '123'
                    }
                ],
                'IPoverDHCP' => [
                    {
                        'Content' => '37'
                    }
                ]
            },
            {
                'Content'   => 'NicName2',
                'IPAddress' => [
                    {
                        'Content' => '456'
                    }
                ],
                'IPoverDHCP' => [
                    {
                        'Content' => '38'
                    }
                ]
            }
        ],
        'OperatingSystem' => [
            {
                'Content' => 'OperatingSystem-Test'
            }
        ],
        'Owner' => [
            {
                'Content' => 's00xxxxx000'
            }
        ],
        'Ram' => [
            {
                'Content' => 'NEW-Ram'
            },
            {
                'Content' => 'NEW-Ram2'
            }
        ],
        'SerialNumber' => [
            {
                'Content' => 'SerialNumber-Test'
            }
        ],
        'Type' => [
            {
                'Content' => '44'
            }
        ],
        'Vendor' => [
            {
                'Content' => 'NEW-Vendor'
            }
        ],
        'WarrantyExpirationDate' => [
            {
                'Content' => '2018-10-04'
            }
        ]
    },
    'StringifiedXMLData2XMLData with original data was successful',
);

#
# Test transition action.
#
my $TicketID = $HelperObject->TicketCreate(
    Title => 'UnitTest my title',
);

my @DynamicFields = (
    {
        Name       => 'SerialNumber',
        Label      => "SerialNumber",
        ObjectType => 'Ticket',
        FieldType  => 'Text',
        Config     => {
            DefaultValue => '',
        },
    },
);

my $Success = $ZnunyHelperObject->_DynamicFieldsCreate(@DynamicFields);

$Self->True(
    $Success,
    "_DynamicFieldsCreate()",
);
my $DynamicFieldConfig = $DynamicFieldObject->DynamicFieldGet(
    Name => 'SerialNumber',
);

my $ValueSet = $DynamicFieldBackendObject->ValueSet(
    DynamicFieldConfig => $DynamicFieldConfig,
    ObjectID           => $TicketID,
    Value              => '1234567890',
    UserID             => 1,
);

my %Ticket = $TicketObject->TicketGet(
    TicketID      => $TicketID,
    DynamicFields => 1,
    UserID        => 1,
);

my %ConfigItemData = (
    'Vendor::1'                => '',                                       # Vendor::1 - delete value for Vendor::1
    'CPU::'                    => 'NEW-2-CPU, NEW-2-CPU2',                  # CPU::1 => NEW-2-CPU | CPU::2 => NEW-2-CPU2
    'Ram::1'                   => 'NEW-2-Ram',
    'Ram::2'                   => 'NEW-2-Ram2',
    'HardDisk::1'              => 'NEW-2-HardDisk1',
    'HardDisk::1::Capacity::1' => '12',
    'HardDisk::2'              => 'NEW-2-HardDisk2',
    'HardDisk::2::Capacity::1' => '44',
    'Description::1'           => '<OTRS_TICKET_Title>',
    'SerialNumber::1'          => '<OTRS_Ticket_DynamicField_SerialNumber>',
    DeplStateName              => 'Planned',
    InciStateName              => 'Operational',
);

# ConfigItemAttributesGet
my %ConfigItemParams = $TransitionActionObject->ConfigItemAttributesGet(
    ConfigItemID => $ConfigItemID,

    # default ConfigItem data
    DeplStateName => 'Production',
    InciStateName => 'Operational',

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

    UserID => 1,
);

$Self->IsDeeply(
    \%ConfigItemParams,
    {
        'ClassID'       => $ConfigItemParams{ClassID},
        'ConfigItemID'  => $ConfigItemID,
        'DeplStateID'   => $ConfigItemParams{DeplStateID},
        'DeplStateName' => 'Production',
        'InciStateID'   => 1,
        'InciStateName' => 'Operational',
        'Name'          => 'CI',
        'XMLData'       => {
            'CPU' => [
                {
                    'Content' => 'NEW-CPU'
                },
                {
                    'Content' => 'NEW-CPU2'
                }
            ],
            'Description' => [
                {
                    'Content' => '<OTRS_TICKET_Title>'
                }
            ],
            'FQDN' => [
                {
                    'Content' => 'FQDN-Test'
                }
            ],
            'GraphicAdapter' => [
                {
                    'Content' => 'GraphicAdapter-Test'
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
            'Model' => [
                {
                    'Content' => 'Model-Test'
                }
            ],
            'NIC' => [
                {
                    'Content'   => 'NicName1',
                    'IPAddress' => [
                        {
                            'Content' => '123'
                        }
                    ],
                    'IPoverDHCP' => [
                        {
                            'Content' => '37'
                        }
                    ]
                },
                {
                    'Content'   => 'NicName2',
                    'IPAddress' => [
                        {
                            'Content' => '456'
                        }
                    ],
                    'IPoverDHCP' => [
                        {
                            'Content' => '38'
                        }
                    ]
                }
            ],
            'OperatingSystem' => [
                {
                    'Content' => 'OperatingSystem-Test'
                }
            ],
            'Owner' => [
                {
                    'Content' => 's00xxxxx000'
                }
            ],
            'Ram' => [
                {
                    'Content' => 'NEW-Ram'
                },
                {
                    'Content' => 'NEW-Ram2'
                }
            ],
            'SerialNumber' => [
                {
                    'Content' => '<OTRS_Ticket_DynamicField_SerialNumber>'
                }
            ],
            'Type' => [
                {
                    'Content' => '44'
                }
            ],
            'Vendor' => [
                {
                    'Content' => 'NEW-Vendor'
                }
            ],
            'WarrantyExpirationDate' => [
                {
                    'Content' => '2018-10-04'
                }
            ]
        }
    },
    'ConfigItemAttributesGet',
);

# Run
my $TransitionActionResult = $TransitionActionObject->Run(
    UserID                   => 1,
    Ticket                   => \%Ticket,
    ProcessEntityID          => 'P123',
    ActivityEntityID         => 'A123',
    TransitionEntityID       => 'T123',
    TransitionActionEntityID => 'TA123',
    Config                   => {
        ConfigItemID => $ConfigItemID,
        UserID       => 1,
        %ConfigItemData,
    }
);

$Self->True(
    scalar $TransitionActionResult,
    'TransitionActionObject->Run() must have been executed successfully.',
);

my %LatestConfigItemVersion = $ZnunyHelperObject->_ITSMConfigItemVersionGet(
    ConfigItemID    => $ConfigItemID,
    XMLDataMultiple => 1,
);

$Self->True(
    defined \%LatestConfigItemVersion,
    'Fetching latest config item version must have been successful.',
);

my $LatestStringifiedXMLData = $TransitionActionObject->XMLData2StringifiedXMLData(
    XMLData => $LatestConfigItemVersion{XMLData},
);

$Self->IsDeeply(
    $LatestStringifiedXMLData,
    {
        'CPU::1'                    => 'NEW-2-CPU',
        'CPU::2'                    => 'NEW-2-CPU2',
        'Description::1'            => 'UnitTest my title',
        'FQDN::1'                   => 'FQDN-Test',
        'GraphicAdapter::1'         => 'GraphicAdapter-Test',
        'HardDisk::1'               => 'NEW-2-HardDisk1',
        'HardDisk::1::Capacity::1'  => '12',
        'HardDisk::2'               => 'NEW-2-HardDisk2',
        'HardDisk::2::Capacity::1'  => '44',
        'Hostname::1'               => 'Hostname-Test',
        'HostnamePrefix::1'         => 'http://',
        'HostnameSuffix::1'         => ':2000/',
        'Model::1'                  => 'Model-Test',
        'NIC::1'                    => 'NicName1',
        'NIC::1::IPAddress::1'      => '123',
        'NIC::1::IPoverDHCP::1'     => '37',
        'NIC::2'                    => 'NicName2',
        'NIC::2::IPAddress::1'      => '456',
        'NIC::2::IPoverDHCP::1'     => '38',
        'OperatingSystem::1'        => 'OperatingSystem-Test',
        'Owner::1'                  => 's00xxxxx000',
        'Ram::1'                    => 'NEW-2-Ram',
        'Ram::2'                    => 'NEW-2-Ram2',
        'SerialNumber::1'           => '1234567890',
        'Type::1'                   => '44',
        'WarrantyExpirationDate::1' => '2018-10-04'
    },
    'Check latest StringifiedXMLData',
);

# run TransitionAction with multiple ConfigItemID
%ConfigItemData = (
    'Vendor::1'                => 'NEW-3-Vendor',
    'CPU::1'                   => 'NEW-3-CPU',
    'CPU::2'                   => 'NEW-3-CPU2',
    'Ram::1'                   => 'NEW-3-Ram',
    'Ram::2'                   => 'NEW-3-Ram2',
    'HardDisk::1'              => 'NEW-3-HardDisk1',
    'HardDisk::1::Capacity::1' => '12',
    'HardDisk::2'              => 'NEW-3-HardDisk2',
    'HardDisk::2::Capacity::1' => '44',
    'Description::1'           => '<OTRS_TICKET_Title>',
    'SerialNumber::1'          => '<OTRS_Ticket_DynamicField_SerialNumber>',
    DeploymentState            => 'Planned',
    InciStateName              => 'Incident',
);

my $ConfigItemIDs           = $ConfigItemID . ', ' . $ConfigItemID2;
my $TransitionActionResult2 = $TransitionActionObject->Run(
    UserID                   => 1,
    Ticket                   => \%Ticket,
    ProcessEntityID          => 'P123',
    ActivityEntityID         => 'A123',
    TransitionEntityID       => 'T123',
    TransitionActionEntityID => 'TA123',
    Config                   => {
        ConfigItemID => $ConfigItemIDs,
        UserID       => 1,
        %ConfigItemData,
    }
);

$Self->True(
    scalar $TransitionActionResult2,
    'TransitionActionObject->Run() must have been executed successfully.',
);

%LatestConfigItemVersion = $ZnunyHelperObject->_ITSMConfigItemVersionGet(
    ConfigItemID    => $ConfigItemID,
    XMLDataMultiple => 1,
);

$LatestStringifiedXMLData = $TransitionActionObject->XMLData2StringifiedXMLData(
    XMLData => $LatestConfigItemVersion{XMLData},
);

$Self->IsDeeply(
    $LatestStringifiedXMLData,
    {
        'CPU::1'                    => 'NEW-3-CPU',
        'CPU::2'                    => 'NEW-3-CPU2',
        'Description::1'            => 'UnitTest my title',
        'FQDN::1'                   => 'FQDN-Test',
        'GraphicAdapter::1'         => 'GraphicAdapter-Test',
        'HardDisk::1'               => 'NEW-3-HardDisk1',
        'HardDisk::1::Capacity::1'  => '12',
        'HardDisk::2'               => 'NEW-3-HardDisk2',
        'HardDisk::2::Capacity::1'  => '44',
        'Hostname::1'               => 'Hostname-Test',
        'HostnamePrefix::1'         => 'http://',
        'HostnameSuffix::1'         => ':2000/',
        'Model::1'                  => 'Model-Test',
        'NIC::1'                    => 'NicName1',
        'NIC::1::IPAddress::1'      => '123',
        'NIC::1::IPoverDHCP::1'     => '37',
        'NIC::2'                    => 'NicName2',
        'NIC::2::IPAddress::1'      => '456',
        'NIC::2::IPoverDHCP::1'     => '38',
        'OperatingSystem::1'        => 'OperatingSystem-Test',
        'Owner::1'                  => 's00xxxxx000',
        'Ram::1'                    => 'NEW-3-Ram',
        'Ram::2'                    => 'NEW-3-Ram2',
        'SerialNumber::1'           => '1234567890',
        'Type::1'                   => '44',
        'Vendor::1'                 => 'NEW-3-Vendor',
        'WarrantyExpirationDate::1' => '2018-10-04'
    },
    'multiple ConfigItemID - Check latest StringifiedXMLData',
);

%LatestConfigItemVersion = $ZnunyHelperObject->_ITSMConfigItemVersionGet(
    ConfigItemID    => $ConfigItemID2,
    XMLDataMultiple => 1,
);

$LatestStringifiedXMLData = $TransitionActionObject->XMLData2StringifiedXMLData(
    XMLData => $LatestConfigItemVersion{XMLData},
);

$Self->IsDeeply(
    $LatestStringifiedXMLData,
    {
        'CPU::1'                    => 'NEW-3-CPU',
        'CPU::2'                    => 'NEW-3-CPU2',
        'Description::1'            => 'UnitTest my title',
        'FQDN::1'                   => 'FQDN-Test',
        'GraphicAdapter::1'         => 'GraphicAdapter-Test',
        'HardDisk::1'               => 'NEW-3-HardDisk1',
        'HardDisk::1::Capacity::1'  => '12',
        'HardDisk::2'               => 'NEW-3-HardDisk2',
        'HardDisk::2::Capacity::1'  => '44',
        'Hostname::1'               => 'Hostname-Test',
        'HostnamePrefix::1'         => 'http://',
        'HostnameSuffix::1'         => ':2000/',
        'Model::1'                  => 'Model-Test',
        'NIC::1'                    => 'NicName1',
        'NIC::1::IPAddress::1'      => '123',
        'NIC::1::IPoverDHCP::1'     => '37',
        'NIC::2'                    => 'NicName2',
        'NIC::2::IPAddress::1'      => '456',
        'NIC::2::IPoverDHCP::1'     => '38',
        'OperatingSystem::1'        => 'OperatingSystem-Test',
        'Owner::1'                  => 's00xxxxx000',
        'Ram::1'                    => 'NEW-3-Ram',
        'Ram::2'                    => 'NEW-3-Ram2',
        'SerialNumber::1'           => '1234567890',
        'Type::1'                   => '44',
        'Vendor::1'                 => 'NEW-3-Vendor',
        'WarrantyExpirationDate::1' => '2018-10-04'
    },
    'multiple ConfigItemID2 - Check latest StringifiedXMLData',
);

1;
