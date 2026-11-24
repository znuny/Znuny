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

## no critic (Perl::Critic::Policy::Variables::RequireLocalizedPunctuationVars)

# Unauthenticated requests to the provider must not be able to execute code or read files
#   via a malicious XSLT mapping, because the inbound mapping runs before the operation authenticates.

my $ConfigObject     = $Kernel::OM->Get('Kernel::Config');
my $MainObject       = $Kernel::OM->Get('Kernel::System::Main');
my $HelperObject     = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');
my $WebserviceObject = $Kernel::OM->Get('Kernel::System::GenericInterface::Webservice');
my $ProviderObject   = $Kernel::OM->Get('Kernel::GenericInterface::Provider');

my $RandomID = $HelperObject->GetRandomID();
my $TempDir  = $ConfigObject->Get('TempDir');

my $InjectionFile = "$TempDir/ProviderXSLTInjection$RandomID";
my $SecretContent = "SecretContent$RandomID";
my $SecretFile    = "$TempDir/ProviderXSLTSecret$RandomID.xml";
$MainObject->FileWrite(
    Location => $SecretFile,
    Content  => \"<Secret>$SecretContent</Secret>",
);

my $IdentityTemplate = '<?xml version="1.0" encoding="UTF-8"?>
<xsl:transform version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
    <xsl:template match="@*|node()">
        <xsl:copy>
            <xsl:apply-templates select="@*|node()"/>
        </xsl:copy>
    </xsl:template>
</xsl:transform>';

my @Tests = (
    {
        Name          => 'Harmless XSLT mapping is applied',
        OperationType => 'Test::Test',
        MappingConfig => {
            PreRegExFilter => [
                {
                    Search  => '^(\D+)ID$',
                    Replace => '$1Number',
                },
            ],
            Template => $IdentityTemplate,
        },
        ResponseSuccess  => 1,
        ResponseContains => 'TicketNumber=1',
    },
    {
        Name          => 'RegEx code injection is not executed before authentication',
        OperationType => 'Session::SessionCreate',
        MappingConfig => {
            PreRegExFilter => [
                {
                    Search  => '.*',
                    Replace => q[${\system('touch ] . $InjectionFile . q[')}],
                },
            ],
            Template => $IdentityTemplate,
        },
        ResponseSuccess => 0,
        ForbiddenFile   => $InjectionFile,
    },
    {
        Name          => 'XSLT document() file read is not returned to unauthenticated requests',
        OperationType => 'Test::Test',
        MappingConfig => {
            Template => qq{<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<xsl:output method="xml" encoding="utf-8" indent="yes"/>
<xsl:template match="/RootElement">
<NewRootElement><File><xsl:value-of select="document('$SecretFile')"/></File></NewRootElement>
</xsl:template>
</xsl:stylesheet>},
        },
        ResponseSuccess  => 0,
        ForbiddenContent => $SecretContent,
    },
);

for my $Test (@Tests) {

    my $WebserviceName = "XSLTMappingSecurity$RandomID$Test->{OperationType}";
    $WebserviceName =~ s{\W}{}xmsg;

    my $WebserviceID = $WebserviceObject->WebserviceAdd(
        Config => {
            Debugger => {
                DebugThreshold => 'debug',
            },
            Provider => {
                Transport => {
                    Type   => 'HTTP::Test',
                    Config => {
                        Fail => 0,
                    },
                },
                Operation => {
                    test_operation => {
                        Type           => $Test->{OperationType},
                        MappingInbound => {
                            Type   => 'XSLT',
                            Config => $Test->{MappingConfig},
                        },
                    },
                },
            },
        },
        Name    => $WebserviceName,
        ValidID => 1,
        UserID  => 1,
    );

    $Self->True(
        $WebserviceID,
        "$Test->{Name} WebserviceAdd()",
    );

    my $RequestData  = 'TicketID=1';
    my $ResponseData = '';

    {
        local %ENV;

        $ENV{REQUEST_URI}    = "http://localhost/znuny/nph-genericinterface.pl/WebserviceID/$WebserviceID";
        $ENV{REQUEST_METHOD} = 'POST';
        $ENV{CONTENT_TYPE}   = 'application/x-www-form-urlencoded; charset=utf-8;';
        $ENV{CONTENT_LENGTH} = length $RequestData;

        local *STDIN;
        open STDIN, '<:utf8', \$RequestData;    ## no critic

        local *STDOUT;
        open STDOUT, '>:utf8', \$ResponseData;    ## no critic

        CGI::initialize_globals();
        $Kernel::OM->ObjectsDiscard( Objects => ['Kernel::System::Web::Request'] );

        $ProviderObject->Run();
    }

    my $ExpectedStatus = $Test->{ResponseSuccess} ? 'HTTP/1.0 200 OK' : 'HTTP/1.0 500 ';
    $Self->True(
        index( $ResponseData, $ExpectedStatus ) > -1,
        "$Test->{Name} response status '$ExpectedStatus'",
    );

    if ( $Test->{ResponseContains} ) {
        $Self->True(
            index( $ResponseData, $Test->{ResponseContains} ) > -1,
            "$Test->{Name} response contains '$Test->{ResponseContains}'",
        );
    }

    if ( $Test->{ForbiddenContent} ) {
        $Self->False(
            index( $ResponseData, $Test->{ForbiddenContent} ) > -1 ? 1 : 0,
            "$Test->{Name} response does not contain forbidden content",
        );
    }

    if ( $Test->{ForbiddenFile} ) {
        $Self->False(
            -e $Test->{ForbiddenFile} ? 1 : 0,
            "$Test->{Name} file $Test->{ForbiddenFile} was not created",
        );
        unlink $Test->{ForbiddenFile};
    }

    my $Success = $WebserviceObject->WebserviceDelete(
        ID     => $WebserviceID,
        UserID => 1,
    );

    $Self->True(
        $Success,
        "$Test->{Name} WebserviceDelete()",
    );
}

unlink $SecretFile;

$Kernel::OM->Get('Kernel::System::Cache')->CleanUp();

1;
