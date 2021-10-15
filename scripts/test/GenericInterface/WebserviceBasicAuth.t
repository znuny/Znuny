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

# get needed objects
my $ZnunyHelperObject = $Kernel::OM->Get('Kernel::System::ZnunyHelper');
my $HelperObject      = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');
my $WebserviceObject  = $Kernel::OM->Get('Kernel::System::GenericInterface::Webservice');
my $ConfigObject      = $Kernel::OM->Get('Kernel::Config');
my $CacheObject       = $Kernel::OM->Get('Kernel::System::Cache');
my $LayoutObject      = $Kernel::OM->Get('Kernel::Output::HTML::Layout');

$ConfigObject->{'WebService_BasicAuth_Password'} = 'testpass';
$ConfigObject->{'WebService_BasicAuth_User'}     = 'testuser';

my $ID = $WebserviceObject->WebserviceAdd(
    Name   => 'special test',
    Config => {
        'Debugger' => {
            'DebugThreshold' => 'debug',
            'TestMode'       => '0'
        },
        'Provider' => {
            'Transport' => {
                'Type' => ''
            },
        },
        'Description'  => '',
        'RemoteSystem' => '',
        'Requester'    => {
            'Transport' => {
                'Type'   => 'HTTP::REST',
                'Config' => {
                    'Timeout'                  => '120',
                    'Host'                     => 'https://znuny.com',
                    'InvokerControllerMapping' => {
                        'Endpoints' => {
                            'Controller' => '/v1.0/endpoints.json',
                            'Command'    => 'GET'
                        },
                        'Version' => {
                            'Controller' => '/version.json',
                            'Command'    => 'GET'
                        },
                    },
                    'Authentication' => {
                        'BasicAuthPassword' => '&lt;OTRS_CONFIG_WebService_BasicAuth_Password&gt;',
                        'AuthType'          => 'BasicAuth',
                        'BasicAuthUser'     => '<OTRS_CONFIG_WebService_BasicAuth_User>'
                    },
                    'DefaultCommand' => 'GET'
                },
            },
            'Invoker' => {
                'Endpoints' => {
                    'Description' => '',
                    'Type'        => 'Test::Endpoints'
                },
                'Version' => {
                    'Type'        => 'Test::Version',
                    'Description' => ''
                },
            },
        },
    },
    ValidID => 1,
    UserID  => 1,
);

my $WebserviceConfig = $WebserviceObject->WebserviceGet(
    Name => 'special test',
);

$Self->Is(
    $WebserviceConfig->{Config}->{Requester}->{Transport}->{Config}->{Authentication}->{BasicAuthUser},
    'testuser',
    'Replaced of config variables worked for basic auth user',
);
$Self->Is(
    $WebserviceConfig->{Config}->{Requester}->{Transport}->{Config}->{Authentication}->{BasicAuthPassword},
    'testpass',
    'Replaced of config variables worked for basic auth password',
);

# clear cache in memory to simulate new request on cache
$CacheObject->{Cache} = {};

$WebserviceConfig = $WebserviceObject->WebserviceGet(
    Name => 'special test',
);

$Self->Is(
    $WebserviceConfig->{Config}->{Requester}->{Transport}->{Config}->{Authentication}->{BasicAuthUser},
    'testuser',
    'Replaced of config variables worked for basic auth user',
);
$Self->Is(
    $WebserviceConfig->{Config}->{Requester}->{Transport}->{Config}->{Authentication}->{BasicAuthPassword},
    'testpass',
    'Replaced of config variables worked for basic auth password',
);

# For the admin interface we want to see the old data
$LayoutObject->{Action} = 'AdminGenericInterfaceWebservice';

$WebserviceConfig = $WebserviceObject->WebserviceGet(
    Name => 'special test',
);

$Self->Is(
    $WebserviceConfig->{Config}->{Requester}->{Transport}->{Config}->{Authentication}->{BasicAuthUser},
    '<OTRS_CONFIG_WebService_BasicAuth_User>',
    'Replaced of config variables should not be replaced for the admin interface e.g. user',
);
$Self->Is(
    $WebserviceConfig->{Config}->{Requester}->{Transport}->{Config}->{Authentication}->{BasicAuthPassword},
    '&lt;OTRS_CONFIG_WebService_BasicAuth_Password&gt;',
    'Replaced of config variables should not be replaced for the admin interface e.g. password',
);

1;
