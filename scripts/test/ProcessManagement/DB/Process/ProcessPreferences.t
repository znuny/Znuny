# --
# Copyright (C) 2001-2021 OTRS AG, https://otrs.com/
# Copyright (C) 2021 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see https://www.gnu.org/licenses/gpl-3.0.txt.
# --

## no critic (Modules::RequireExplicitPackage)
use strict;
use warnings;
use utf8;

use vars (qw($Self));

use Kernel::System::VariableCheck qw(:all);

# get needed objects
my $CacheObject     = $Kernel::OM->Get('Kernel::System::Cache');
my $ConfigObject    = $Kernel::OM->Get('Kernel::Config');
my $ProcessObject   = $Kernel::OM->Get('Kernel::System::ProcessManagement::DB::Process');
my $VirtualFSObject = $Kernel::OM->Get('Kernel::System::VirtualFS');
my $YAMLObject      = $Kernel::OM->Get('Kernel::System::YAML');

# get helper object
$Kernel::OM->ObjectParamAdd(
    'Kernel::System::UnitTest::Helper' => {
        RestoreDatabase => 1,
    },
);
my $HelperObject = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');

my $RandomID = $HelperObject->GetRandomID();
my $UserID   = 1;

my $PrefKey = 'UnitTestIcon';

$ConfigObject->Set(
    Key   => 'ProcessPreferences###ZZZ-UnitTest-Icon',
    Value => {
        Module      => 'Kernel::Output::HTML::ProcessPreferences::Generic',
        Label       => 'Icon',
        Desc        => 'Process icon.',
        PrefKey     => $PrefKey,
        ClusterName => 'Category',
        Block       => 'File',
        MaxFiles    => 1,
        FileTypes   => 'png,jpg,jpeg,gif',
    },
);

my $ProcessEntityID = 'P-Test-' . $RandomID;
my $ProcessID       = $ProcessObject->ProcessAdd(
    EntityID      => $ProcessEntityID,
    Name          => 'Process ' . $RandomID,
    StateEntityID => 'S1',
    Layout        => {},
    Config        => {
        Description => 'a Description',
        Path        => {},
    },
    UserID => $UserID,
);

$Self->True(
    $ProcessID,
    'ProcessAdd() must return the ID of the added process.',
);

# Binary content with bytes that must survive the export and the import.
my $IconContent  = "\x89PNG\r\n\x1a\n" . join( '', map { chr $_ } 0 .. 255 );
my $IconFilename = 'VirtualFS::' . $ProcessEntityID . '::' . $PrefKey . '::unittest.png';

my $FileAdded = $VirtualFSObject->Write(
    Content     => \$IconContent,
    Filename    => $IconFilename,
    Mode        => 'binary',
    Preferences => {
        ContentType => 'image/png',
        Filename    => 'unittest.png',
        Filesize    => length $IconContent,
        FilesizeRaw => length $IconContent,
    },
);

$Self->True(
    $FileAdded,
    'Write() of VirtualFS must return true for the icon of the process.',
);

my $PreferencesSet = $ProcessObject->ProcessPreferencesSet(
    ProcessEntityID => $ProcessEntityID,
    Key             => $PrefKey,
    Value           => $IconFilename,
);

$Self->True(
    $PreferencesSet,
    'ProcessPreferencesSet() must return true for the icon of the process.',
);

# Fill the cache like the agent and admin interface do, before the process is exported.
$ProcessObject->ProcessGet(
    ID     => $ProcessID,
    UserID => $UserID,
);

my $Export = $ProcessObject->ProcessExport(
    ID     => $ProcessID,
    UserID => $UserID,
);

my $ExportedIconContent = $Export->{Process}->{$PrefKey}->[0]->{Content};

$Self->Is(
    ref $ExportedIconContent,
    '',
    'ProcessExport() must contain the icon as Base64 string, not as reference.',
);

$Self->True(
    scalar( $ExportedIconContent =~ m{\A [A-Za-z0-9+/=\s]+ \z}xms ),
    'ProcessExport() must contain the icon as Base64 string.',
);

# The cache must still contain the data for regular usage.
my $ProcessAfterExport = $ProcessObject->ProcessGet(
    ID     => $ProcessID,
    UserID => $UserID,
);

$Self->Is(
    ref $ProcessAfterExport->{$PrefKey}->[0]->{Content},
    'SCALAR',
    'ProcessGet() must contain the icon as content reference after the process has been exported.',
);

my $ExportYAML = $YAMLObject->Dump(
    Data => $Export,
);

my %Import = $ProcessObject->ProcessImport(
    Content => $ExportYAML,
    UserID  => $UserID,
);

$Self->True(
    $Import{Success},
    'ProcessImport() must return success for a process with an icon.',
);

my $ProcessList = $ProcessObject->ProcessList(
    UseEntities => 1,
    UserID      => $UserID,
);

my @ImportedProcessEntityIDs = grep {
    $_ ne $ProcessEntityID
        && $ProcessList->{$_} eq 'Process ' . $RandomID
} sort keys %{$ProcessList};

$Self->Is(
    scalar @ImportedProcessEntityIDs,
    1,
    'ProcessImport() must have added exactly one process.',
);

my %ImportedPreferences = $ProcessObject->ProcessPreferencesGet(
    ProcessEntityID => $ImportedProcessEntityIDs[0],
);

my $ImportedIconContent = $ImportedPreferences{$PrefKey}->[0]->{Content};

$Self->True(
    IsHashRefWithData( $ImportedPreferences{$PrefKey}->[0]->{Preferences} ),
    'ProcessImport() must have stored the file preferences of the icon.',
);

$Self->Is(
    ref $ImportedIconContent eq 'SCALAR' ? ${$ImportedIconContent} : undef,
    $IconContent,
    'ProcessImport() must have stored the icon with its original content.',
);

$CacheObject->CleanUp();

1;
