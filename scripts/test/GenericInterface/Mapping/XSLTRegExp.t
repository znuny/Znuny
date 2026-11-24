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

# Get helper object.
my $HelperObject = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');

# Get random id.
my $RandomNumber = $HelperObject->GetRandomNumber();

my $DebuggerObject = Kernel::GenericInterface::Debugger->new(
    DebuggerConfig => {
        DebugThreshold => 'debug',
        TestMode       => 1,
    },
    WebserviceID      => 1,
    CommunicationType => 'Provider',
);

my $TempDir = $Kernel::OM->Get('Kernel::Config')->Get('TempDir');

my %InjectionFiles = map { $_ => "$TempDir/XSLTRegExpInjection${_}_$RandomNumber" } qw(Pre Post Array);

my $IdentityTemplate = '<?xml version="1.0" encoding="UTF-8"?>
<xsl:transform version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
    <xsl:template match="@*|node()">
        <xsl:copy>
            <xsl:apply-templates select="@*|node()"/>
        </xsl:copy>
    </xsl:template>
</xsl:transform>';

my @MappingTests = (
    {
        Name   => 'Test RegExp code injection is not executed (Pre RegExp)',
        Config => {
            PreRegExFilter => [
                {
                    Search  => '.*',
                    Replace => q[${\system('touch ] . $InjectionFiles{Pre} . q[')}],
                },
            ],
            Template => $IdentityTemplate,
        },
        Data => {
            TicketID => $RandomNumber,
        },

        # The literal replacement is no valid XML element name.
        ResultData     => undef,
        ResultSuccess  => 0,
        ConfigSuccess  => 1,
        ForbiddenFiles => [ $InjectionFiles{Pre} ],
    },
    {
        Name   => 'Test RegExp code injection is used literally (Post RegExp)',
        Config => {
            PostRegExFilter => [
                {
                    Search  => '^(\D*)ID$',
                    Replace => q[${\system('touch ] . $InjectionFiles{Post} . q[')}$1],
                },
            ],
            Template => $IdentityTemplate,
        },
        Data => {
            TicketID => $RandomNumber,
        },
        ResultData => {
            q[${\system('touch ] . $InjectionFiles{Post} . q[')}Ticket] => $RandomNumber,
        },
        ResultSuccess  => 1,
        ConfigSuccess  => 1,
        ForbiddenFiles => [ $InjectionFiles{Post} ],
    },
    {
        Name   => 'Test RegExp array interpolation injection is used literally (Post RegExp)',
        Config => {
            PostRegExFilter => [
                {
                    Search  => '^TicketID$',
                    Replace => '@{[ system(\'touch ' . $InjectionFiles{Array} . '\') ]}',
                },
            ],
            Template => $IdentityTemplate,
        },
        Data => {
            TicketID => $RandomNumber,
        },
        ResultData => {
            '@{[ system(\'touch ' . $InjectionFiles{Array} . '\') ]}' => $RandomNumber,
        },
        ResultSuccess  => 1,
        ConfigSuccess  => 1,
        ForbiddenFiles => [ $InjectionFiles{Array} ],
    },
    {
        Name   => 'Test RegExp ${N} syntax (Post RegExp)',
        Config => {
            PostRegExFilter => [
                {
                    Search  => '^(\D*)ID$',
                    Replace => '${1}Number',
                },
            ],
            Template => $IdentityTemplate,
        },
        Data => {
            TicketID => $RandomNumber,
        },
        ResultData => {
            'TicketNumber' => $RandomNumber,
        },
        ResultSuccess => 1,
        ConfigSuccess => 1,
    },
    {
        Name   => 'Test RegExp named captures (Pre RegExp)',
        Config => {
            PreRegExFilter => [
                {
                    Search  => '^(?<number>\d+) (?<text>.+?)$',
                    Replace => '_$+{text}_$+{number}',
                },
            ],
            Template => $IdentityTemplate,
        },
        Data => {
            '16 elementname' => $RandomNumber,
        },
        ResultData => {
            '_elementname_16' => $RandomNumber,
        },
        ResultSuccess => 1,
        ConfigSuccess => 1,
    },
    {
        Name   => 'Test RegExp escaped dollar before a name (Post RegExp)',
        Config => {
            PostRegExFilter => [
                {
                    Search  => '^AdaptiveCardSchema$',
                    Replace => '\$schema',
                },
            ],
            Template => $IdentityTemplate,
        },
        Data => {
            AdaptiveCardSchema => 'http://adaptivecards.io/schemas/adaptive-card.json',
        },
        ResultData => {
            '$schema' => 'http://adaptivecards.io/schemas/adaptive-card.json',
        },
        ResultSuccess => 1,
        ConfigSuccess => 1,
    },
    {
        Name   => 'Test RegExp escaped dollar before a digit stays literal (Post RegExp)',
        Config => {
            PostRegExFilter => [
                {
                    Search  => '^(Ticket)ID$',
                    Replace => '\$1',
                },
            ],
            Template => $IdentityTemplate,
        },
        Data => {
            TicketID => $RandomNumber,
        },
        ResultData => {
            '$1' => $RandomNumber,
        },
        ResultSuccess => 1,
        ConfigSuccess => 1,
    },
    {
        Name   => 'Test RegExp partial match keeps prefix and suffix (Post RegExp)',
        Config => {
            PostRegExFilter => [
                {
                    Search  => '(o+)',
                    Replace => '[$1$2]',
                },
            ],
            Template => $IdentityTemplate,
        },
        Data => {
            Fooboo => $RandomNumber,
        },
        ResultData => {
            'F[oo]boo' => $RandomNumber,
        },
        ResultSuccess => 1,
        ConfigSuccess => 1,
    },
    {
        Name   => 'Test RegExp (Pre RegExp)',
        Config => {
            PreRegExFilter => [
                {
                    Search  => '^(\D*)ID$',
                    Replace => '$1Number',
                },
            ],
            Template => '<?xml version="1.0" encoding="UTF-8"?>
<xsl:transform version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
    <xsl:template match="@*|node()">
        <xsl:copy>
            <xsl:apply-templates select="@*|node()"/>
        </xsl:copy>
    </xsl:template>
</xsl:transform>',
        },
        Data => {
            TicketID => $RandomNumber,
        },
        ResultData => {
            TicketNumber => $RandomNumber,
        },
        ResultSuccess => 1,
        ConfigSuccess => 1,
    },
    {
        Name   => 'Test RegExp (Post RegExp)',
        Config => {
            PostRegExFilter => [
                {
                    Search  => '^(\D*)ID$',
                    Replace => '$1Number',
                },
            ],
            Template => '<?xml version="1.0" encoding="UTF-8"?>
<xsl:transform version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
    <xsl:template match="@*|node()">
        <xsl:copy>
            <xsl:apply-templates select="@*|node()"/>
        </xsl:copy>
    </xsl:template>
</xsl:transform>',
        },
        Data => {
            TicketID => $RandomNumber,
        },
        ResultData => {
            TicketNumber => $RandomNumber,
        },
        ResultSuccess => 1,
        ConfigSuccess => 1,
    },
    {
        Name   => 'Test RegExp (Pre RegExp + Post RegExp)',
        Config => {
            PreRegExFilter => [
                {
                    Search  => '^(\D*)_(\D*)$',
                    Replace => '$1$2',
                },
            ],
            PostRegExFilter => [
                {
                    Search  => '^(Queue)Name$',
                    Replace => '$1ID',
                },
            ],
            Template => '<?xml version="1.0" encoding="UTF-8"?>
<xsl:transform version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
    <xsl:template match="@*|node()">
        <xsl:copy>
            <xsl:apply-templates select="@*|node()"/>
        </xsl:copy>
    </xsl:template>
</xsl:transform>',
        },
        Data => {
            Ticket_Number => $RandomNumber,
            QueueName     => $RandomNumber,
        },
        ResultData => {
            TicketNumber => $RandomNumber,
            QueueID      => $RandomNumber,
        },
        ResultSuccess => 1,
        ConfigSuccess => 1,
    },
    {
        Name   => 'Test RegExp complex (Post RegExp)',
        Config => {
            PostRegExFilter => [
                {
                    Search  => '^(\D*)(\d)$',
                    Replace => '$1_$2',
                },
                {
                    Search  => '^_(\d*).(\d*)$',
                    Replace => '$1x$2',
                },
                {
                    Search  => '^(some)(K\D*)$',
                    Replace => '$2$1',
                },
            ],
            Template => '<?xml version="1.0" encoding="UTF-8"?>
<xsl:transform version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
    <xsl:template match="@*|node()">
        <xsl:copy>
            <xsl:apply-templates select="@*|node()"/>
        </xsl:copy>
    </xsl:template>
</xsl:transform>',
        },
        Data => {
            UnitData => {
                UnitTestKey1 => 'someValue',
                UnitTestKey2 => 'someValue',
                Data         => {
                    '_10x10' => 'someValue',
                    '_20x20' => 'someValue',
                },
            },
            OtherData => {
                OtherData1 => 'someValue',
                OtherData2 => 'someValue',
                IssueData  => [
                    {
                        someKey  => 'someValue',
                        '_20x20' => 'someValue',
                    },
                ],
            },
        },
        ResultData => {
            UnitData => {
                UnitTestKey_1 => 'someValue',
                UnitTestKey_2 => 'someValue',
                Data          => {
                    '10x10' => 'someValue',
                    '20x20' => 'someValue',
                },
            },
            OtherData => {
                OtherData_1 => 'someValue',
                OtherData_2 => 'someValue',
                IssueData   => {
                    Keysome => 'someValue',
                    '20x20' => 'someValue'
                },
            },
        },
        ResultSuccess => 1,
        ConfigSuccess => 1,
    },
    {
        Name   => 'Test RegExp complex (Post RegExp + Pre RegExp)',
        Config => {
            PostRegExFilter => [
                {
                    Search  => '^(\D*)(\d)$',
                    Replace => '$1_$2',
                },
                {
                    Search  => '^_(\d*).(\d*)$',
                    Replace => '$1x$2',
                },
                {
                    Search  => '^(some)(K\D*)$',
                    Replace => '$2$1',
                },
            ],
            PreRegExFilter => [
                {
                    Search  => '^(\D*)(ZZ)$',
                    Replace => '$1_$2',
                },
                {
                    Search  => '^[QQQ]+(Key)[QQQ]+$',
                    Replace => 'Q$1Q',
                },
            ],
            Template => '<?xml version="1.0" encoding="UTF-8"?>
<xsl:transform version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
    <xsl:template match="@*|node()">
        <xsl:copy>
            <xsl:apply-templates select="@*|node()"/>
        </xsl:copy>
    </xsl:template>
</xsl:transform>',
        },
        Data => {
            UnitTestKeyZZ => 'someValue',
            PreData       => {
                QQQKeyQQQ => 'someValue',
            },
            UnitData => {
                UnitTestKey1 => 'someValue',
                UnitTestKey2 => 'someValue',
                Data         => {
                    '_10x10' => 'someValue',
                    '_20x20' => 'someValue',
                },
            },
            OtherData => {
                OtherData1 => 'someValue',
                OtherData2 => 'someValue',
                IssueData  => [
                    {
                        someKey  => 'someValue',
                        '_10x10' => 'someValue',
                    },
                    {
                        someKey  => 'someValue',
                        '_20x20' => 'someValue',
                    },
                ],
            },
        },
        ResultData => {
            UnitTestKey_ZZ => 'someValue',
            PreData        => {
                QKeyQ => 'someValue',
            },
            UnitData => {
                UnitTestKey_1 => 'someValue',
                UnitTestKey_2 => 'someValue',
                Data          => {
                    '10x10' => 'someValue',
                    '20x20' => 'someValue',
                },
            },
            OtherData => {
                OtherData_1 => 'someValue',
                OtherData_2 => 'someValue',
                IssueData   => [
                    {
                        Keysome => 'someValue',
                        '10x10' => 'someValue',
                    },
                    {
                        Keysome => 'someValue',
                        '20x20' => 'someValue',
                    },
                ],
            },
        },
        ResultSuccess => 1,
        ConfigSuccess => 1,
    },
);

TEST:
for my $Test (@MappingTests) {

    # Create a mapping instance.
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
        Data => $Test->{Data},
    );

    # Check if function return correct status.
    $Self->Is(
        $MappingResult->{Success},
        $Test->{ResultSuccess},
        $Test->{Name} . ' (Success).',
    );

    # Check if function return correct data.
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

    for my $ForbiddenFile ( @{ $Test->{ForbiddenFiles} // [] } ) {
        $Self->False(
            -e $ForbiddenFile ? 1 : 0,
            $Test->{Name} . " file $ForbiddenFile was not created",
        );
        unlink $ForbiddenFile;
    }

    # Instantiate another object.
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

1;
