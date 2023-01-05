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
use Kernel::System::DynamicField::Webservice::ResponseValues;

$Kernel::OM->ObjectParamAdd(
    'Kernel::System::UnitTest::Helper' => {
        RestoreDatabase => 1,
    },
);

my $ZnunyHelperObject         = $Kernel::OM->Get('Kernel::System::ZnunyHelper');
my $LayoutObject              = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
my $DynamicFieldObject        = $Kernel::OM->Get('Kernel::System::DynamicField');
my $DynamicFieldBackendObject = $Kernel::OM->Get('Kernel::System::DynamicField::Backend');
my $ParamObject               = $Kernel::OM->Get('Kernel::System::Web::Request');
my $UnitTestWebserviceObject  = $Kernel::OM->Get('Kernel::System::UnitTest::Webservice');
my $WebserviceObject          = $Kernel::OM->Get('Kernel::System::GenericInterface::Webservice');
my $DynamicFieldWebserviceResponseValuesObject
    = $Kernel::OM->Get('Kernel::System::DynamicField::Webservice::ResponseValues');

my $WebserviceName = 'DynamicFieldWebservice';
my $DynamicField   = $WebserviceName . 'ResponseValues';

$ZnunyHelperObject->_WebserviceCreate(
    Webservices => {
        $WebserviceName => 'scripts/test/sample/Webservice/' . $WebserviceName . '.yml',
    }
);
my $Webservice = $WebserviceObject->WebserviceGet(
    Name => $WebserviceName,
);

$Self->True(
    $Webservice,
    "WebserviceGet() - $WebserviceName",
);

my @DynamicFields = (
    {
        Name       => $DynamicField,
        Label      => $DynamicField,
        ObjectType => 'Ticket',
        FieldType  => 'WebserviceDropdown',
        Config     => {
            DefaultValue  => '',
            Link          => '',
            InvokerSearch => 'TestSearch',
            InvokerGet    => 'TestGet',
            Webservice    => $WebserviceName
        },
    },
);
my $Success = $ZnunyHelperObject->_DynamicFieldsCreate(@DynamicFields);

$Self->True(
    $Success,
    '_DynamicFieldsCreate',
);

my $DynamicFieldConfig = $DynamicFieldObject->DynamicFieldGet(
    Name => $DynamicField,
);

$UnitTestWebserviceObject->Mock(
    TestSearch => [
        {
            Data   => {},
            Result => {
                Success => 1,
                Data    => {

                    response => {
                        returncode    => 200,
                        returnmessage => 'Success',
                    },
                    values => [
                        {
                            ID    => 1,
                            Name  => 'Znuny',
                            Value => 'Rocks',
                        }
                    ],
                },
            },
        },
    ],
    TestGet => [
        {
            Data   => {},
            Result => {
                Success => 1,
                Data    => {
                    Key   => 'Znuny',
                    Value => 'Znuny',
                },
            },
        },
    ],
);

# Request
my $Data = $DynamicFieldWebserviceResponseValuesObject->Request(
    SearchTerms => 'Znuny',
    UserID      => 1,
    %{ $DynamicFieldConfig->{Config} },
);

$Self->IsDeeply(
    $Data,
    [
        {
            'ID'    => 1,
            'Name'  => 'Znuny',
            'Value' => 'Rocks'
        },
    ],
    '_Request',
);

1;
