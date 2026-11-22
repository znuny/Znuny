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

use CGI ();

my $ConfigObject = $Kernel::OM->Get('Kernel::Config');
$ConfigObject->Set(
    Key   => 'SessionUseCookie',
    Value => 1,
);

my %LegacySessionName = (
    ZnunyAgentInterface    => 'OTRSAgentInterface',
    ZnunyCustomerInterface => 'OTRSCustomerInterface',
);

my $ParamObject = ParamObjectCreate();

for my $SessionName ( sort keys %LegacySessionName ) {
    $Self->Is(
        $ParamObject->GetLegacySessionName(
            SessionName => $SessionName,
        ),
        $LegacySessionName{$SessionName},
        "$SessionName has the previous OTRS cookie name",
    );
}

for my $SessionName (qw(CustomAgentSession OTRSAgentInterface SessionID)) {
    $Self->Is(
        $ParamObject->GetLegacySessionName(
            SessionName => $SessionName,
        ),
        '',
        "$SessionName has no previous cookie name",
    );
}

my @SessionTests = (
    {
        Name        => 'Current parameter is used before the previous name',
        SessionName => 'ZnunyAgentInterface',
        QueryString => 'OTRSAgentInterface=legacy-id&ZnunyAgentInterface=current-id',
        Expected    => 'current-id',
    },
    {
        Name        => 'Previous cookie name is accepted for the Znuny default',
        SessionName => 'ZnunyAgentInterface',
        QueryString => 'OTRSAgentInterface=legacy-id',
        Expected    => 'legacy-id',
    },
    {
        Name        => 'Previous customer cookie name is accepted',
        SessionName => 'ZnunyCustomerInterface',
        QueryString => 'OTRSCustomerInterface=legacy-customer-id',
        Expected    => 'legacy-customer-id',
    },
    {
        Name        => 'A custom cookie name does not read the previous name',
        SessionName => 'CustomAgentSession',
        QueryString => 'OTRSAgentInterface=legacy-id',
        Expected    => '',
    },
    {
        Name        => 'Cookie value overrides the parameter',
        SessionName => 'ZnunyAgentInterface',
        QueryString => 'ZnunyAgentInterface=from-param',
        Cookie      => 'ZnunyAgentInterface=from-cookie',
        Expected    => 'from-cookie',
    },
    {
        Name        => 'Previous cookie is accepted when the current cookie is absent',
        SessionName => 'ZnunyAgentInterface',
        Cookie      => 'OTRSAgentInterface=legacy-cookie',
        Expected    => 'legacy-cookie',
    },
);

for my $Test (@SessionTests) {

    # The cookie header is read when the session id is resolved, so it has to
    # stay set for that call.
    local $ENV{REQUEST_METHOD} = 'GET';
    local $ENV{QUERY_STRING}   = $Test->{QueryString} // '';
    local $ENV{HTTP_COOKIE}    = $Test->{Cookie}      // '';
    CGI::initialize_globals();

    my $RequestObject = $Kernel::OM->Create(
        'Kernel::System::Web::Request',
        ObjectParams => {
            WebRequest => CGI->new(),
        },
    );

    my ( $SessionID, $SessionIDCookie ) = $RequestObject->GetSessionID(
        SessionName => $Test->{SessionName},
    );

    $Self->Is(
        $SessionID,
        $Test->{Expected},
        $Test->{Name},
    );

    if ( $Test->{Cookie} ) {
        $Self->Is(
            $SessionIDCookie,
            $Test->{Expected},
            "$Test->{Name} - cookie value",
        );
    }
}

my $LegacyCookie = $ParamObject->ExpireLegacySessionCookie(
    SessionName => 'ZnunyAgentInterface',
    Path        => 'znuny/',
);
$Self->True(
    $LegacyCookie && $LegacyCookie =~ m{\AOTRSAgentInterface=},
    'Previous agent cookie is expired',
);

my $CustomCookie = $ParamObject->ExpireLegacySessionCookie(
    SessionName => 'CustomAgentSession',
    Path        => 'znuny/',
);
$Self->False(
    $CustomCookie,
    'A custom cookie name expires no previous cookie',
);

sub ParamObjectCreate {
    my (%Param) = @_;

    local $ENV{REQUEST_METHOD} = 'GET';
    local $ENV{QUERY_STRING}   = $Param{QueryString} // '';
    local $ENV{HTTP_COOKIE}    = $Param{Cookie}      // '';

    CGI::initialize_globals();

    my $Object = $Kernel::OM->Create(
        'Kernel::System::Web::Request',
        ObjectParams => {
            WebRequest => CGI->new(),
        },
    );

    return $Object;
}

1;
