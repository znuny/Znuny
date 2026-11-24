# --
# Copyright (C) 2001-2021 OTRS AG, https://otrs.com/
# Copyright (C) 2021 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see https://www.gnu.org/licenses/gpl-3.0.txt.
# --

use strict;
use warnings;
use utf8;

use vars (qw($Self));

use Kernel::GenericInterface::Debugger;
use Kernel::GenericInterface::Mapping;

my $Home = $Kernel::OM->Get('Kernel::Config')->Get('Home');

my $DebuggerObject = Kernel::GenericInterface::Debugger->new(
    DebuggerConfig => {
        DebugThreshold => 'debug',
        TestMode       => 1,
    },
    WebserviceID      => 1,
    CommunicationType => 'Provider',
);

my $ConfigObject = $Kernel::OM->Get('Kernel::Config');
my $MainObject   = $Kernel::OM->Get('Kernel::System::Main');
my $HelperObject = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');

my $RandomID = $HelperObject->GetRandomID();
my $TempDir  = $Kernel::OM->Get('Kernel::Config')->Get('TempDir');

my $SecretContent = "SecretContent$RandomID";
my $SecretFile    = "$TempDir/XSLTSecret$RandomID.xml";
$MainObject->FileWrite(
    Location => $SecretFile,
    Content  => \"<Secret>$SecretContent</Secret>",
);

# A valid style sheet outside of Kernel/GenericInterface/Mapping. Importing it must be denied,
#   even though it is a style sheet, because only the shipped style sheets may be imported.
my $SecretXSLFile = "$TempDir/XSLTSecret$RandomID.xsl";
$MainObject->FileWrite(
    Location => $SecretXSLFile,
    Content  => \qq{<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<xsl:template match="/RootElement"><NewRootElement><Secret>$SecretContent</Secret></NewRootElement></xsl:template>
</xsl:stylesheet>},
);

# A plain text file, because external entities can read any text file, not only XML files.
my $SecretTextFile = "$TempDir/XSLTSecret$RandomID.txt";
$MainObject->FileWrite(
    Location => $SecretTextFile,
    Content  => \"$SecretContent plain text",
);

my $WrittenFile = "$TempDir/XSLTWritten$RandomID.xml";

# Resources which must not be loaded via xsl:import or xsl:include.
#   They are resolved while parsing the style sheet, where the security callbacks
#   for document() and exsl:document are not applied.
#   The supported import of the shipped style sheets is tested further below
#   ('Test replacement with custom functions').
my @ForbiddenImports = (
    {
        Name => 'style sheet in temp directory',
        Href => $SecretXSLFile,
    },
    {
        Name => 'style sheet in temp directory via file URI',
        Href => "file://$SecretXSLFile",
    },
    {
        Name => 'system configuration file',
        Href => "$Home/Kernel/Config/Files/XML/Framework.xml",
    },
    {
        Name => 'path leaving the mapping directory',
        Href => "$Home/Kernel/GenericInterface/Mapping/../../Config.pm",
    },
    {
        Name => 'network URL',
        Href => "http://127.0.0.1:1/$RandomID.xsl",
    },
);

# Create one test for xsl:import and one for xsl:include for every forbidden resource.
my @ForbiddenImportTests;
for my $ForbiddenImport (@ForbiddenImports) {
    for my $Element (qw(import include)) {
        push @ForbiddenImportTests, {
            Name   => "Test xsl:$Element of $ForbiddenImport->{Name} is denied",
            Config => {
                Template => qq{<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<xsl:$Element href="$ForbiddenImport->{Href}" />
<xsl:output method="xml" encoding="utf-8" indent="yes"/>
<xsl:template match="/RootElement">
<NewRootElement><NewKey>NewValue</NewKey></NewRootElement>
</xsl:template>
</xsl:stylesheet>},
            },
            Data => {
                Key => 'Value',
            },
            ResultData       => undef,
            ResultSuccess    => 0,
            ConfigSuccess    => 1,
            ForbiddenContent => $SecretContent,
        };
    }
}

my $AllowedStyleSheet = '<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<xsl:output method="xml" encoding="utf-8" indent="yes"/>
<xsl:template match="/RootElement">
<NewRootElement><NewKey>Imported</NewKey></NewRootElement>
</xsl:template>
</xsl:stylesheet>';

my @MappingTests = (
    {
        Name   => 'Test document() local file read is denied',
        Config => {
            Template => qq{<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<xsl:output method="xml" encoding="utf-8" indent="yes"/>
<xsl:template match="/RootElement">
<NewRootElement><File><xsl:copy-of select="document('$SecretFile')"/></File></NewRootElement>
</xsl:template>
</xsl:stylesheet>},
        },
        Data => {
            Key => 'Value',
        },
        ResultData       => undef,
        ResultSuccess    => 0,
        ConfigSuccess    => 1,
        ForbiddenContent => $SecretContent,
    },
    {
        Name   => 'Test document() local file read via file URI is denied',
        Config => {
            Template => qq{<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<xsl:output method="xml" encoding="utf-8" indent="yes"/>
<xsl:template match="/RootElement">
<NewRootElement><File><xsl:copy-of select="document('file://$SecretFile')"/></File></NewRootElement>
</xsl:template>
</xsl:stylesheet>},
        },
        Data => {
            Key => 'Value',
        },
        ResultData       => undef,
        ResultSuccess    => 0,
        ConfigSuccess    => 1,
        ForbiddenContent => $SecretContent,
    },
    {
        Name   => 'Test document() of system configuration file is denied',
        Config => {
            Template => qq{<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<xsl:output method="xml" encoding="utf-8" indent="yes"/>
<xsl:template match="/RootElement">
<NewRootElement><File><xsl:copy-of select="document('$Home/Kernel/Config/Files/XML/Framework.xml')"/></File></NewRootElement>
</xsl:template>
</xsl:stylesheet>},
        },
        Data => {
            Key => 'Value',
        },
        ResultData       => undef,
        ResultSuccess    => 0,
        ConfigSuccess    => 1,
        ForbiddenContent => 'otrs_config',
    },
    {
        Name   => 'Test document() network read is denied',
        Config => {
            Template => qq{<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<xsl:output method="xml" encoding="utf-8" indent="yes"/>
<xsl:template match="/RootElement">
<NewRootElement><File><xsl:copy-of select="document('http://127.0.0.1:1/$RandomID')"/></File></NewRootElement>
</xsl:template>
</xsl:stylesheet>},
        },
        Data => {
            Key => 'Value',
        },
        ResultData    => undef,
        ResultSuccess => 0,
        ConfigSuccess => 1,
    },
    {
        Name   => 'Test document() of a mapping style sheet is allowed',
        Config => {
            Template => qq{<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<xsl:output method="xml" encoding="utf-8" indent="yes"/>
<xsl:template match="/RootElement">
<NewRootElement><Loaded><xsl:value-of select="document('$Home/Kernel/GenericInterface/Mapping/OTRSFunctions.xsl')/*[1]/\@version"/></Loaded></NewRootElement>
</xsl:template>
</xsl:stylesheet>},
        },
        Data => {
            Key => 'Value',
        },
        ResultData => {
            Loaded => '1.0',
        },
        ResultSuccess => 1,
        ConfigSuccess => 1,
    },
    {
        Name                   => 'Test xsl:import of an allowed HTTPS prefix',
        AllowedIncludePrefixes => [
            'https://znuny.example/xslt/',
        ],
        WebUserAgentResponses => {
            'https://znuny.example/xslt/allowed.xsl' => {
                Status  => '200 OK',
                Content => \$AllowedStyleSheet,
            },
        },
        Config => {
            Template => '<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<xsl:import href="https://znuny.example/xslt/allowed.xsl"/>
<xsl:output method="xml" encoding="utf-8" indent="yes"/>
</xsl:stylesheet>',
        },
        Data => {
            Key => 'Value',
        },
        ResultData => {
            NewKey => 'Imported',
        },
        ResultSuccess => 1,
        ConfigSuccess => 1,
    },
    {
        Name                   => 'Test xsl:import outside the configured HTTPS prefix is denied',
        AllowedIncludePrefixes => [
            'https://znuny.example/xslt/allowed.xsl',
        ],
        WebUserAgentResponses => {
            'https://znuny.example/xslt/other.xsl' => {
                Status  => '200 OK',
                Content => \$AllowedStyleSheet,
            },
        },
        Config => {
            Template => '<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<xsl:import href="https://znuny.example/xslt/other.xsl"/>
<xsl:output method="xml" encoding="utf-8" indent="yes"/>
<xsl:template match="/RootElement">
<NewRootElement><NewKey>Local</NewKey></NewRootElement>
</xsl:template>
</xsl:stylesheet>',
        },
        Data => {
            Key => 'Value',
        },
        ResultData    => undef,
        ResultSuccess => 0,
        ConfigSuccess => 1,
    },
    {
        Name                   => 'Test xsl:import with a different case is denied',
        AllowedIncludePrefixes => [
            'https://znuny.example/xslt/',
        ],
        WebUserAgentResponses => {
            'https://Znuny.example/xslt/allowed.xsl' => {
                Status  => '200 OK',
                Content => \$AllowedStyleSheet,
            },
        },
        Config => {
            Template => '<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<xsl:import href="https://Znuny.example/xslt/allowed.xsl"/>
<xsl:output method="xml" encoding="utf-8" indent="yes"/>
</xsl:stylesheet>',
        },
        Data => {
            Key => 'Value',
        },
        ResultData    => undef,
        ResultSuccess => 0,
        ConfigSuccess => 1,
    },
    {
        Name                   => 'Test xsl:import of a neighboring host is denied',
        AllowedIncludePrefixes => [
            'https://znuny.example/xslt/',
        ],
        WebUserAgentResponses => {
            'https://znuny.example.evil/xslt/allowed.xsl' => {
                Status  => '200 OK',
                Content => \$AllowedStyleSheet,
            },
        },
        Config => {
            Template => '<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<xsl:import href="https://znuny.example.evil/xslt/allowed.xsl"/>
<xsl:output method="xml" encoding="utf-8" indent="yes"/>
</xsl:stylesheet>',
        },
        Data => {
            Key => 'Value',
        },
        ResultData    => undef,
        ResultSuccess => 0,
        ConfigSuccess => 1,
    },
    {
        Name                   => 'Test an include prefix that does not start with https:// is ignored',
        AllowedIncludePrefixes => [
            'http://znuny.example/xslt/',
        ],
        WebUserAgentResponses => {
            'http://znuny.example/xslt/allowed.xsl' => {
                Status  => '200 OK',
                Content => \$AllowedStyleSheet,
            },
        },
        Config => {
            Template => '<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<xsl:import href="http://znuny.example/xslt/allowed.xsl"/>
<xsl:output method="xml" encoding="utf-8" indent="yes"/>
</xsl:stylesheet>',
        },
        Data => {
            Key => 'Value',
        },
        ResultData    => undef,
        ResultSuccess => 0,
        ConfigSuccess => 1,
    },
    {
        Name                   => 'Test xsl:import follows a redirect that stays inside the prefix',
        AllowedIncludePrefixes => [
            'https://znuny.example/xslt/',
        ],
        WebUserAgentResponses => {
            'https://znuny.example/xslt/start.xsl' => {
                Status   => '302 Found',
                Location => 'https://znuny.example/xslt/allowed.xsl',
            },
            'https://znuny.example/xslt/allowed.xsl' => {
                Status  => '200 OK',
                Content => \$AllowedStyleSheet,
            },
        },
        Config => {
            Template => '<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<xsl:import href="https://znuny.example/xslt/start.xsl"/>
<xsl:output method="xml" encoding="utf-8" indent="yes"/>
</xsl:stylesheet>',
        },
        Data => {
            Key => 'Value',
        },
        ResultData => {
            NewKey => 'Imported',
        },
        ResultSuccess => 1,
        ConfigSuccess => 1,
    },
    {
        Name                   => 'Test xsl:import denies a redirect outside the prefix',
        AllowedIncludePrefixes => [
            'https://znuny.example/xslt/',
        ],
        WebUserAgentResponses => {
            'https://znuny.example/xslt/start.xsl' => {
                Status   => '302 Found',
                Location => 'https://evil.example/secret.xsl',
            },
            'https://evil.example/secret.xsl' => {
                Status  => '200 OK',
                Content => \$AllowedStyleSheet,
            },
        },
        Config => {
            Template => '<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<xsl:import href="https://znuny.example/xslt/start.xsl"/>
<xsl:output method="xml" encoding="utf-8" indent="yes"/>
</xsl:stylesheet>',
        },
        Data => {
            Key => 'Value',
        },
        ResultData    => undef,
        ResultSuccess => 0,
        ConfigSuccess => 1,
    },
    {
        Name   => 'Test exsl:document file write is denied',
        Config => {
            Template => qq{<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0"
 xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
 xmlns:exsl="http://exslt.org/common"
 extension-element-prefixes="exsl">
<xsl:output method="xml" encoding="utf-8" indent="yes"/>
<xsl:template match="/RootElement">
<exsl:document href="$WrittenFile"><Written/></exsl:document>
<NewRootElement><NewKey>NewValue</NewKey></NewRootElement>
</xsl:template>
</xsl:stylesheet>},
        },
        Data => {
            Key => 'Value',
        },
        ResultData     => undef,
        ResultSuccess  => 0,
        ConfigSuccess  => 1,
        ForbiddenFiles => [$WrittenFile],
    },
    @ForbiddenImportTests,

    # External entities in the template could read local files or URLs while loading the template.
    {
        Name   => 'Test external entity of XML file in template is denied',
        Config => {
            Template => qq{<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE xsl:stylesheet [<!ENTITY secret SYSTEM "file://$SecretFile">]>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<xsl:output method="xml" encoding="utf-8" indent="yes"/>
<xsl:template match="/RootElement">
<NewRootElement><File>&secret;</File></NewRootElement>
</xsl:template>
</xsl:stylesheet>},
        },
        Data => {
            Key => 'Value',
        },
        ResultData       => undef,
        ResultSuccess    => 0,
        ConfigSuccess    => 1,
        ForbiddenContent => $SecretContent,
    },
    {
        Name   => 'Test external entity of plain text file in template is denied',
        Config => {
            Template => qq{<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE xsl:stylesheet [<!ENTITY secret SYSTEM "$SecretTextFile">]>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<xsl:output method="xml" encoding="utf-8" indent="yes"/>
<xsl:template match="/RootElement">
<NewRootElement><File>&secret;</File></NewRootElement>
</xsl:template>
</xsl:stylesheet>},
        },
        Data => {
            Key => 'Value',
        },
        ResultData       => undef,
        ResultSuccess    => 0,
        ConfigSuccess    => 1,
        ForbiddenContent => $SecretContent,
    },

    # The mapped data is passed to XML::Simple, which treats a string without XML markup as a file name
    #   and expands entities of a DOCTYPE. With method="text", a template can produce both.
    {
        Name   => 'Test text output used as file name is denied',
        Config => {
            Template => qq{<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<xsl:output method="text" encoding="utf-8"/>
<xsl:template match="/RootElement"><xsl:text>$SecretFile</xsl:text></xsl:template>
</xsl:stylesheet>},
        },
        Data => {
            Key => 'Value',
        },
        ResultData       => undef,
        ResultSuccess    => 0,
        ConfigSuccess    => 1,
        ForbiddenContent => $SecretContent,
    },
    {
        Name   => 'Test text output with external entity is denied',
        Config => {
            Template => qq{<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<xsl:output method="text" encoding="utf-8"/>
<xsl:template match="/RootElement"><xsl:text>&lt;!DOCTYPE NewRootElement [&lt;!ENTITY secret SYSTEM "file://$SecretTextFile"&gt;]&gt;&lt;NewRootElement&gt;&lt;File&gt;&amp;secret;&lt;/File&gt;&lt;/NewRootElement&gt;</xsl:text></xsl:template>
</xsl:stylesheet>},
        },
        Data => {
            Key => 'Value',
        },
        ResultData       => undef,
        ResultSuccess    => 0,
        ConfigSuccess    => 1,
        ForbiddenContent => $SecretContent,
    },

    # Well-formed XML produced with method="text" must still be accepted.
    {
        Name   => 'Test well-formed text output is accepted',
        Config => {
            Template => qq{<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<xsl:output method="text" encoding="utf-8"/>
<xsl:template match="/RootElement"><xsl:text>&lt;NewRootElement&gt;&lt;NewKey&gt;NewValue&lt;/NewKey&gt;&lt;/NewRootElement&gt;</xsl:text></xsl:template>
</xsl:stylesheet>},
        },
        Data => {
            Key => 'Value',
        },
        ResultData => {
            NewKey => 'NewValue',
        },
        ResultSuccess => 1,
        ConfigSuccess => 1,
    },
    {
        Name   => 'Test invalid xml',
        Config => {
            Template => 'this is no xml',
        },
        Data => {
            Key => 'Value',
        },
        ResultData    => undef,
        ResultSuccess => 0,
        ConfigSuccess => 1,
    },
    {
        Name   => 'Test no xslt',
        Config => {
            Template => '<?xml version="1.0" encoding="UTF-8"?>
<valid-xml-but-no-xslt/>',
        },
        Data => {
            Key => 'Value',
        },
        ResultData    => undef,
        ResultSuccess => 0,
        ConfigSuccess => 1,
    },
    {
        Name   => 'Test invalid xslt',
        Config => {
            Template => '<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<xsl:output method="html" encoding="utf-8" indent="yes"/>
<xsl:template match="/RootElement">
</xsl:template>
</xsl:stylesheet>',
        },
        Data => {
            Key => 'Value',
        },
        ResultData    => undef,
        ResultSuccess => 0,
        ConfigSuccess => 1,
    },
    {
        Name   => 'Test empty data',
        Config => {
            Template => '',
        },
        Data          => undef,
        ResultData    => {},
        ResultSuccess => 1,
        ConfigSuccess => 1,
    },
    {
        Name   => 'Test empty config',
        Config => {},
        Data   => {
            Key => 'Value',
        },
        ResultData => {
            Key => 'Value',
        },
        ResultSuccess => 1,
        ConfigSuccess => 0,
    },
    {
        Name   => 'Test invalid hash key name',
        Config => {
            Template => '<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<xsl:output method="xml" encoding="utf-8" indent="yes"/>
<xsl:template match="/RootElement">
<NewKey>NewValue</NewKey>
</xsl:template>
</xsl:stylesheet>',
        },
        Data => {
            '<Key>' => 'Value',
        },
        ResultData    => undef,
        ResultSuccess => 0,
        ConfigSuccess => 1,
    },
    {
        Name   => 'Test invalid replacement',
        Config => {
            Template => '<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<xsl:output method="xml" encoding="utf-8" indent="yes"/>
<xsl:template match="/RootElement">
<Wrapper><Level1><Level2><Level3>Value</Level1></Level2></Level3></Wrapper>
</xsl:template>
</xsl:stylesheet>',
        },
        Data => {
            Key => 'Value',
        },
        ResultData    => undef,
        ResultSuccess => 0,
        ConfigSuccess => 1,
    },
    {
        Name   => 'Test array as data',
        Config => {
            Template => qq{<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0"
 xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
 xmlns:otrs="http://otrs.org"
 extension-element-prefixes="otrs">
<xsl:import href="$Home/Kernel/GenericInterface/Mapping/OTRSFunctions.xsl" />
<xsl:output method="xml" encoding="utf-8" indent="yes"/>
<xsl:template match="/RootElement">
<NewRootElement>
    <xsl:for-each select="/RootElement/Array1">
    <FirstLevelArray>
        <xsl:text>Amended</xsl:text>
        <xsl:value-of select="." />
    </FirstLevelArray>
    </xsl:for-each>
</NewRootElement>
</xsl:template>
</xsl:stylesheet>},
        },
        Data => (
            'ArrayPart1',
            'ArrayPart2',
            'ArrayPart3',
        ),
        ResultData    => undef,
        ResultSuccess => 0,
        ConfigSuccess => 1,
    },
    {
        Name   => 'Test simple overwrite',
        Config => {
            Template => '<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<xsl:output method="xml" encoding="utf-8" indent="yes"/>
<xsl:template match="/RootElement">
<NewRootElement><NewKey>NewValue</NewKey></NewRootElement>
</xsl:template>
</xsl:stylesheet>',
        },
        Data => {
            Key => 'Value',
        },
        ResultData => {
            NewKey => 'NewValue',
        },
        ResultSuccess => 1,
        ConfigSuccess => 1,
    },

    {
        Name   => 'Test simple overwrite (whitespaces trimmed)',
        Config => {
            Template => '<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<xsl:output method="xml" encoding="utf-8" indent="yes"/>
<xsl:template match="/RootElement">
<NewRootElement><NewKey>
        NewValue
</NewKey></NewRootElement>
</xsl:template>
</xsl:stylesheet>',
        },
        Data => {
            Key => 'Value',
        },
        ResultData => {
            NewKey => 'NewValue',
        },
        ResultSuccess => 1,
        ConfigSuccess => 1,
    },

    {
        Name   => 'Test replacement with custom functions',
        Config => {
            Template => qq{<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0"
 xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
 xmlns:otrs="http://otrs.org"
 extension-element-prefixes="otrs">
<xsl:import href="$Home/Kernel/GenericInterface/Mapping/OTRSFunctions.xsl" />
<xsl:output method="xml" encoding="utf-8" indent="yes"/>
<xsl:template match="/RootElement">
<NewRootElement>
    <xsl:for-each select="/RootElement/Structure1/Array1">
    <FirstLevelArray>
        <xsl:text>Amended</xsl:text>
        <xsl:value-of select="." />
    </FirstLevelArray>
    </xsl:for-each>
    <NewStructure>
        <DateFromISO>
            <xsl:variable name="dateiso" select="/RootElement/DateISO" />
            <xsl:value-of select="otrs:date-iso-to-xsd(\$dateiso)" />
        </DateFromISO>
        <DateToISO>
            <xsl:variable name="datexsd" select="/RootElement/DateXSD" />
            <xsl:value-of select="otrs:date-xsd-to-iso(\$datexsd)" />
        </DateToISO>
        <NewKey1>
            <xsl:value-of select="/RootElement/Key1" />
        </NewKey1>
        <NewKey2>
            <xsl:value-of select="/RootElement/Structure1/Key2" />
        </NewKey2>
    </NewStructure>
</NewRootElement>
</xsl:template>
</xsl:stylesheet>},
        },
        Data => {
            DateISO    => '2010-12-31 23:58:59',
            DateXSD    => '2011-11-30T22:57:58Z',
            Key1       => 'Value1',
            Structure1 => {
                Array1 => [
                    'ArrayPart1',
                    'ArrayPart2',
                    'ArrayPart3',
                ],
                Key2 => 'Value2',
            },
        },
        ResultData => {
            FirstLevelArray => [
                'AmendedArrayPart1',
                'AmendedArrayPart2',
                'AmendedArrayPart3',
            ],
            NewStructure => {
                DateFromISO => '2010-12-31T23:58:59Z',
                DateToISO   => '2011-11-30 22:57:58',
                NewKey1     => 'Value1',
                NewKey2     => 'Value2',
            },
        },
        ResultSuccess => 1,
        ConfigSuccess => 1,
    },
    {
        Name   => 'Test DataInclude functionality',
        Config => {
            DataInclude => [
                'RequesterRequestInput',
                'RequesterResponseMapOutput',
            ],
            Template => qq{<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0"
 xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
 xmlns:otrs="http://otrs.org"
 extension-element-prefixes="otrs">
<xsl:import href="$Home/Kernel/GenericInterface/Mapping/OTRSFunctions.xsl" />
<xsl:output method="xml" encoding="utf-8" indent="yes"/>
<xsl:template match="/RootElement">
<NewRootElement>
    <DataInclude><xsl:value-of select="/RootElement/DataInclude/RequesterResponseMapOutput/Value" /></DataInclude>
    <DataInclude><xsl:value-of select="/RootElement/DataInclude/RequesterRequestInput/Value" /></DataInclude>
</NewRootElement>
</xsl:template>
</xsl:stylesheet>},
        },
        Data => {
            Key => 'Value',
        },
        DataInclude => {
            RequesterRequestInput         => { Value => 1 },
            RequesterRequestPrepareOutput => { Value => 2 },
            RequesterResponseMapOutput    => { Value => 3 }
        },
        ResultData => {
            DataInclude => [
                3,
                1,
            ],
        },
        ResultSuccess => 1,
        ConfigSuccess => 1,
    },
);

my %WebUserAgentResponseByURL;
my $OriginalWebUserAgentRequest = \&Kernel::System::WebUserAgent::Request;

{
    no warnings 'redefine';    ## no critic

    *Kernel::System::WebUserAgent::Request = sub {
        my ( $WebUserAgentObject, %Param ) = @_;

        my $Response = $WebUserAgentResponseByURL{ $Param{URL} // '' };
        return ( Status => '500 No mock' ) if ref $Response ne 'HASH';

        return %{$Response};
    };
}

TEST:
for my $Test (@MappingTests) {

    $ConfigObject->Set(
        Key   => 'GenericInterface::Mapping::XSLT::AllowedIncludeURLPrefixes',
        Value => $Test->{AllowedIncludePrefixes} // [],
    );

    %WebUserAgentResponseByURL = %{ $Test->{WebUserAgentResponses} // {} };

    # create a mapping instance
    my $MappingObject = Kernel::GenericInterface::Mapping->new(
        DebuggerObject => $DebuggerObject,
        MappingConfig  => {
            Type   => 'XSLT',
            Config => $Test->{Config},
        },
    );
    if ( $Test->{ConfigSuccess} ) {
        $Self->Is(
            ref $MappingObject,
            'Kernel::GenericInterface::Mapping',
            $Test->{Name} . ' MappingObject was correctly instantiated',
        );
        next TEST if ref $MappingObject ne 'Kernel::GenericInterface::Mapping';
    }
    else {
        $Self->IsNot(
            ref $MappingObject,
            'Kernel::GenericInterface::Mapping',
            $Test->{Name} . ' MappingObject was not correctly instantiated',
        );
        next TEST;
    }

    my $MappingResult = $MappingObject->Map(
        Data        => $Test->{Data},
        DataInclude => $Test->{DataInclude},
    );

    # check if function return correct status
    $Self->Is(
        $MappingResult->{Success},
        $Test->{ResultSuccess},
        $Test->{Name} . ' (Success).',
    );

    # check if function return correct data
    $Self->IsDeeply(
        $MappingResult->{Data},
        $Test->{ResultData},
        $Test->{Name} . ' (Data Structure).',
    );

    if ( !$Test->{ResultSuccess} ) {
        $Self->True(
            $MappingResult->{ErrorMessage},
            $Test->{Name} . ' error message found',
        );
    }

    if ( $Test->{ForbiddenContent} ) {
        my $ResultDump = $MainObject->Dump( $MappingResult, 'ascii' );
        $Self->False(
            index( $ResultDump, $Test->{ForbiddenContent} ) > -1 ? 1 : 0,
            $Test->{Name} . ' result does not contain forbidden content',
        );
    }

    for my $ForbiddenFile ( @{ $Test->{ForbiddenFiles} // [] } ) {
        $Self->False(
            -e $ForbiddenFile ? 1 : 0,
            $Test->{Name} . " file $ForbiddenFile was not created",
        );
        unlink $ForbiddenFile;
    }

    # instantiate another object
    my $SecondMappingObject = Kernel::GenericInterface::Mapping->new(
        DebuggerObject => $DebuggerObject,
        MappingConfig  => {
            Type   => 'XSLT',
            Config => $Test->{Config},
        },
    );

    $Self->Is(
        ref $SecondMappingObject,
        'Kernel::GenericInterface::Mapping',
        $Test->{Name} . ' SecondMappingObject was correctly instantiated',
    );
}

{
    no warnings 'redefine';    ## no critic
    *Kernel::System::WebUserAgent::Request = $OriginalWebUserAgentRequest;
}

unlink $SecretFile, $SecretXSLFile, $SecretTextFile;

1;
