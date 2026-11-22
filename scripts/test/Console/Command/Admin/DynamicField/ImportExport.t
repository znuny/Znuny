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
use Encode;

use vars (qw($Self));

$Kernel::OM->ObjectParamAdd(
    'Kernel::System::UnitTest::Helper' => {
        RestoreDatabase => 1,
    },
);
my $HelperObject = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');
my $YAMLObject   = $Kernel::OM->Get('Kernel::System::YAML');

my @Tests = (
    {
        Name            => 'based on default sample file',
        ImportArguments => [
            './scripts/test/sample/DynamicField/Export/Export.yaml',
        ],
        ExportYAMLArguments => [
            'yaml',
        ],
        ExportPerlArguments => [
            'perl',
        ],
        ExpectedExitCode       => 0,
        ExpectedTestNumberData => {
            'Config' => {
                'DefaultValue' => '',
                'Link'         => '',
                'LinkPreview'  => '',
                'RegExList'    => [],
            },
            'FieldType'  => 'Text',
            'Label'      => 'Test Number',
            'Name'       => 'TestNumber',
            'ObjectType' => 'Ticket',
        },
        'RemoveFields' => {
            'TestNumber' => [
                'FieldOrder',
            ],
        },
    },
    {
        Name            => 'based on sample file (--include-all-config-keys)',
        ImportArguments => [
            './scripts/test/sample/DynamicField/Export/ExportIncludeAllConfigKeys.yaml',
        ],
        ExportYAMLArguments => [
            'yaml',
            '--include-all-config-keys',
        ],
        ExportPerlArguments => [
            'perl',
            '--include-all-config-keys',
        ],
        ExpectedExitCode       => 0,
        ExpectedTestNumberData => {
            'Config' => {
                'DefaultValue' => '',
                'Link'         => '',
                'LinkPreview'  => '',
                'RegExList'    => [],
            },
            'InternalField' => 0,
            'ValidID'       => 1,
            'FieldType'     => 'Text',
            'Label'         => 'Test Number',
            'Name'          => 'TestNumber',
            'ObjectType'    => 'Ticket',
        },
        'RemoveFields' => {
            'TestNumber' => [
                'FieldOrder',
                'ChangeTime',
                'CreateTime',
                'ID',
            ],
        },
    },
    {
        Name            => 'based on sample file (--include-internal-fields)',
        ImportArguments => [
            './scripts/test/sample/DynamicField/Export/ExportIncludeInternalFields.yaml',
        ],
        ExportYAMLArguments => [
            'yaml',
            '--include-internal-fields',
        ],
        ExportPerlArguments => [
            'perl',
            '--include-internal-fields',
        ],
        ExpectedExitCode       => 0,
        ExpectedTestNumberData => {
            'Config' => {
                'DefaultValue' => '',
                'Link'         => '',
                'LinkPreview'  => '',
                'RegExList'    => []
            },
            'FieldType'  => 'Text',
            'Label'      => 'Test Number',
            'Name'       => 'TestNumber',
            'ObjectType' => 'Ticket'
        },
        ExpectedProcessManagementProcessIDData => {
            'Config' => {
                'DefaultValue' => '',
            },
            'FieldType'     => 'ProcessID',
            'InternalField' => 1,
            'Label'         => 'Process',
            'Name'          => 'ProcessManagementProcessID',
            'ObjectType'    => 'Ticket',
        },
        'RemoveFields' => {
            'TestNumber' => [
                'FieldOrder',
            ],
            'ProcessManagementProcessID' => [
                'FieldOrder'
            ],
        },
    },
    {
        Name            => 'based on sample file (--include-all-config-keys and --include-internal-fields)',
        ImportArguments => [
            './scripts/test/sample/DynamicField/Export/ExportIncludeInternalFieldsAllConfigKeys.yaml',
        ],
        ExportYAMLArguments => [
            'yaml',
            '--include-all-config-keys',
            '--include-internal-fields',
        ],
        ExportPerlArguments => [
            'perl',
            '--include-all-config-keys',
            '--include-internal-fields',
        ],
        ExpectedExitCode       => 0,
        ExpectedTestNumberData => {
            'Config' => {
                'DefaultValue' => '',
                'Link'         => '',
                'LinkPreview'  => '',
                'RegExList'    => []
            },
            'InternalField' => 0,
            'ValidID'       => 1,
            'FieldType'     => 'Text',
            'Label'         => 'Test Number',
            'Name'          => 'TestNumber',
            'ObjectType'    => 'Ticket',
        },
        ExpectedProcessManagementProcessIDData => {
            'Config' => {
                'DefaultValue' => '',
            },
            'InternalField' => 1,
            'ValidID'       => 1,
            'ID'            => 1,
            'FieldType'     => 'ProcessID',
            'Label'         => 'Process',
            'Name'          => 'ProcessManagementProcessID',
            'ObjectType'    => 'Ticket',
        },
        'RemoveFields' => {
            'TestNumber' => [
                'FieldOrder',
                'ChangeTime',
                'CreateTime',
                'ID',
            ],
            'ProcessManagementProcessID' => [
                'FieldOrder',
                'ChangeTime',
                'CreateTime',
            ],
        },
    },
);

for my $Test (@Tests) {

    # Step 1: Import yaml sample file
    my $ResultImport = $HelperObject->ConsoleCommand(
        CommandModule => 'Kernel::System::Console::Command::Admin::DynamicField::Import',
        Parameter     => $Test->{ImportArguments},
    );

    $Self->Is(
        $ResultImport->{ExitCode},
        $Test->{ExpectedExitCode},
        "Exit code: Import (YAML) " . $Test->{Name},
    );

    # Step 2: Generate new yaml export
    my $ResultYAML = $HelperObject->ConsoleCommand(
        CommandModule => 'Kernel::System::Console::Command::Admin::DynamicField::Export',
        Parameter     => $Test->{ExportYAMLArguments},
    );

    $Self->Is(
        $ResultYAML->{ExitCode},
        $Test->{ExpectedExitCode},
        "Exit code: Export (YAML) " . $Test->{Name},
    );

    # Remove unwanted control chars
    $ResultYAML->{STDOUT} =~ s{[\x00-\x08\x0B\x0C\x0E-\x1F]}{}gms;

    # YAML content check
    my $ExportData = $YAMLObject->Load(
        Data => encode_utf8( $ResultYAML->{STDOUT} )
    );

    # The field's value might vary in different systems, so get rid of it
    if ( $Test->{RemoveFields} && ref( $Test->{RemoveFields} ) eq 'HASH' ) {
        for my $DynnamicField ( sort keys %{ $Test->{RemoveFields} } ) {
            if ( $Test->{RemoveFields}->{$DynnamicField} && ref( $Test->{RemoveFields}->{$DynnamicField} ) eq 'ARRAY' )
            {
                for my $Field ( @{ $Test->{RemoveFields}->{$DynnamicField} } ) {
                    delete $ExportData->{DynamicFields}->{$DynnamicField}->{$Field};
                }
            }
        }
    }

    # Test internal field (YAML) if expected
    if ( $Test->{ExpectedProcessManagementProcessIDData} ) {
        $Self->IsDeeply(
            $ExportData->{DynamicFields}->{ProcessManagementProcessID},
            $Test->{ExpectedProcessManagementProcessIDData},
            "Content check: ProcessManagementProcessID (YAML) => " . $Test->{Name},
        );
    }

    # Check TestNumber (YAML)
    $Self->IsDeeply(
        $ExportData->{DynamicFields}->{TestNumber},
        $Test->{ExpectedTestNumberData},
        "Content check: TestNumber (YAML) " . $Test->{Name},
    );

    # Step 3: Generate new dump export
    my $ResultPerl = $HelperObject->ConsoleCommand(
        CommandModule => 'Kernel::System::Console::Command::Admin::DynamicField::Export',
        Parameter     => $Test->{ExportPerlArguments},
    );

    $Self->Is(
        $ResultPerl->{ExitCode},
        $Test->{ExpectedExitCode},
        "Exit code: Export (Perl) " . $Test->{Name},
    );

    # Remove unwanted control chars
    $ResultPerl->{STDOUT} =~ s{[\x00-\x08\x0B\x0C\x0E-\x1F]}{}gms;

    # Convert the dump into perl hash
    my $VAR1;
    ## no critic
    eval encode_utf8( $ResultPerl->{STDOUT} );
    ## use critic

    # The field's value might vary in different systems, so get rid of it
    if ( $Test->{RemoveFields} && ref( $Test->{RemoveFields} ) eq 'HASH' ) {
        for my $DynnamicField ( sort keys %{ $Test->{RemoveFields} } ) {
            if ( $Test->{RemoveFields}->{$DynnamicField} && ref( $Test->{RemoveFields}->{$DynnamicField} ) eq 'ARRAY' )
            {
                for my $Field ( @{ $Test->{RemoveFields}->{$DynnamicField} } ) {
                    delete $VAR1->{DynamicFields}->{$DynnamicField}->{$Field};
                }
            }
        }
    }

    # Test internal field (perl) if expected
    if ( $Test->{ExpectedProcessManagementProcessIDData} ) {
        $Self->IsDeeply(
            $VAR1->{DynamicFields}->{ProcessManagementProcessID},
            $Test->{ExpectedProcessManagementProcessIDData},
            "Content check: ProcessManagementProcessID (Perl) " . $Test->{Name},
        );
    }

    # Check TestNumber (perl)
    $Self->IsDeeply(
        $VAR1->{DynamicFields}->{TestNumber},
        $Test->{ExpectedTestNumberData},
        "Content check: TestNumber (Perl) " . $Test->{Name},
    );
}

1;
