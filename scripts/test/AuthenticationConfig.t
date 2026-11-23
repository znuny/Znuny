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

$Kernel::OM->ObjectParamAdd(
    'Kernel::System::UnitTest::Helper' => {
        RestoreDatabase => 1,
    },
);
my $HelperObject               = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');
my $ConfigObject               = $Kernel::OM->Get('Kernel::Config');
my $DBObject                   = $Kernel::OM->Get('Kernel::System::DB');
my $MainObject                 = $Kernel::OM->Get('Kernel::System::Main');
my $SystemDataObject           = $Kernel::OM->Get('Kernel::System::SystemData');
my $VirtualFSObject            = $Kernel::OM->Get('Kernel::System::VirtualFS');
my $AuthenticationConfigObject = $Kernel::OM->Get('Kernel::System::AuthenticationConfig');

my $RandomID = $HelperObject->GetRandomID();

# Registered in Framework.xml, set here so the test doesn't depend on a rebuilt configuration.
$HelperObject->ConfigSettingChange(
    Valid => 1,
    Key   => 'AuthenticationConfig::Plugin###SAML',
    Value => {
        DisplayName => 'SAML',
        Module      => 'Kernel::System::Authentication::Plugin::SAML',
    },
);

#
# Default slot
#

my $ID = $AuthenticationConfigObject->DataAdd(
    Name        => "UnitTest$RandomID",
    Type        => 'SAML',
    Context     => 'Customer',
    Slot        => '',
    AuthConfig  => { Issuer => 'https://unittest.example.org' },
    SyncEnabled => 0,
    ValidID     => 1,
    CreateBy    => 1,
    ChangeBy    => 1,
    UserID      => 1,
);
$Self->True(
    scalar $ID,
    'DataAdd() with the default slot must be successful.',
);

my $GetDBSlot = sub {
    $DBObject->Prepare(
        SQL  => 'SELECT slot FROM authentication_config WHERE id = ?',
        Bind => [ \$ID ],
    );

    my $DBSlot;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        $DBSlot = $Row[0];
    }

    return $DBSlot;
};

# Oracle stores an empty string as NULL, which the NOT NULL column rejects.
$Self->Is(
    $GetDBSlot->(),
    'D',
    'The default slot must not be stored as an empty string.',
);

my %Data = $AuthenticationConfigObject->DataGet(
    ID     => $ID,
    UserID => 1,
);
$Self->Is(
    $Data{Slot},
    '',
    'DataGet() must return the default slot as an empty string.',
);

my @List = $AuthenticationConfigObject->DataListGet(
    Context => 'Customer',
    UserID  => 1,
);
my ($ListRow) = grep { $_->{ID} == $ID } @List;
$Self->Is(
    $ListRow->{Slot},
    '',
    'DataListGet() must return the default slot as an empty string.',
);

my @FilteredList = $AuthenticationConfigObject->DataListGet(
    Slot   => '',
    UserID => 1,
);
$Self->True(
    scalar( grep { $_->{ID} == $ID } @FilteredList ),
    'DataListGet() must find the config by the default slot.',
);

my $SlotStatus = $AuthenticationConfigObject->SlotStatusList(
    Context => 'Customer',
    UserID  => 1,
);
$Self->Is(
    $SlotStatus->{''}->{AuthenticationConfigID},
    $ID,
    'SlotStatusList() must report the config in the default slot.',
);

#
# Numbered slot
#

my $Success = $AuthenticationConfigObject->DataUpdate(
    ID     => $ID,
    Slot   => '3',
    UserID => 1,
);
$Self->True(
    scalar $Success,
    'DataUpdate() to slot 3 must be successful.',
);

%Data = $AuthenticationConfigObject->DataGet(
    ID     => $ID,
    UserID => 1,
);
$Self->Is(
    $Data{Slot},
    '3',
    'DataGet() must return slot 3.',
);
$Self->Is(
    $GetDBSlot->(),
    '3',
    'Slot 3 must be stored unchanged.',
);

$AuthenticationConfigObject->DataUpdate(
    ID     => $ID,
    Slot   => '',
    UserID => 1,
);
%Data = $AuthenticationConfigObject->DataGet(
    ID     => $ID,
    UserID => 1,
);
$Self->Is(
    $Data{Slot},
    '',
    'DataGet() must return the default slot after updating back to it.',
);

#
# VFSFilenameUsedBy() and DataDelete()
#

my $SharedFilename  = "VirtualFS::AuthenticationConfig::SAML::IdPCACert::Shared$RandomID";
my $OwnFilename     = "VirtualFS::AuthenticationConfig::SAML::RequestSignKeyCert::Own$RandomID";
my $ForeignFilename = "VirtualFS::UnitTest::Foreign$RandomID";

for my $Filename ( $SharedFilename, $OwnFilename, $ForeignFilename ) {
    my $Content = 'UnitTest';
    $VirtualFSObject->Write(
        Filename => $Filename,
        Content  => \$Content,
        Mode     => 'binary',
    );
}

my %RowTemplate = (
    Type        => 'SAML',
    Context     => 'Agent',
    SyncEnabled => 0,
    ValidID     => 2,
    CreateBy    => 1,
    ChangeBy    => 1,
    UserID      => 1,
);

my $KeepID = $AuthenticationConfigObject->DataAdd(
    %RowTemplate,
    Name       => "UnitTestKeep$RandomID",
    Slot       => '8',
    AuthConfig => {
        IdPCACertVFSFilename => $SharedFilename,
    },
);
my $DeleteID = $AuthenticationConfigObject->DataAdd(
    %RowTemplate,
    Name       => "UnitTestDelete$RandomID",
    Slot       => '9',
    AuthConfig => {
        IdPCACertVFSFilename          => $SharedFilename,
        RequestSignKeyCertVFSFilename => $OwnFilename,
        RequestSignKeyVFSFilename     => $ForeignFilename,
    },
);

my $UsedBy = $AuthenticationConfigObject->VFSFilenameUsedBy(
    Filename => $SharedFilename,
    UserID   => 1,
);
$Self->IsDeeply(
    [ sort { $a <=> $b } map { $_->{ID} } @{$UsedBy} ],
    [ sort { $a <=> $b } $KeepID, $DeleteID ],
    'VFSFilenameUsedBy() without ExcludeID must return every config using the file.',
);

$AuthenticationConfigObject->DataDelete(
    ID     => $DeleteID,
    UserID => 1,
);

my $FileExists = sub {
    my @Found = $VirtualFSObject->Find( Filename => shift );
    return @Found ? 1 : 0;
};

$Self->True(
    $FileExists->($SharedFilename),
    'DataDelete() must keep a certificate another config still uses.',
);
$Self->False(
    $FileExists->($OwnFilename),
    'DataDelete() must delete a certificate no other config uses.',
);
$Self->True(
    $FileExists->($ForeignFilename),
    'DataDelete() must not delete a VirtualFS file outside of its namespace.',
);

#
# Deploy() with a config whose certificate can't be read
#

my $DeployFile = $ConfigObject->Get('Home') . '/Kernel/Config/Files/ZZZZnunyGeneratedAuthentication.pm';

my $GetDeployFileContent = sub {
    return if !-e $DeployFile;

    my $ContentRef = $MainObject->FileRead(
        Location => $DeployFile,
        Mode     => 'utf8',
    );

    return ${$ContentRef};
};

my $DeployFileContentBefore    = $GetDeployFileContent->();
my $LastDeployedRevisionBefore = $SystemDataObject->SystemDataGet(
    Key => 'AuthenticationConfig::LastDeployedRevision',
);

my $BrokenName = "UnitTestBroken$RandomID";
$AuthenticationConfigObject->DataAdd(
    %RowTemplate,
    Name       => $BrokenName,
    Slot       => '10',
    ValidID    => 1,
    AuthConfig => {
        Issuer               => 'https://unittest.example.org',
        IdPCACertVFSFilename => "VirtualFS::AuthenticationConfig::SAML::IdPCACert::Missing$RandomID",
    },
);

my @Errors;
my $Location = $AuthenticationConfigObject->Deploy(
    UserID => 1,
    Errors => \@Errors,
);

my $DeployFileContentAfter = $GetDeployFileContent->();

# Never leave a test deployment behind if Deploy() unexpectedly succeeded.
if ( ( $DeployFileContentAfter // '' ) ne ( $DeployFileContentBefore // '' ) ) {
    if ( defined $DeployFileContentBefore ) {
        $MainObject->FileWrite(
            Location => $DeployFile,
            Content  => \$DeployFileContentBefore,
            Mode     => 'utf8',
        );
    }
    else {
        unlink $DeployFile;
    }
}

$Self->False(
    $Location,
    'Deploy() must fail if a certificate can not be read.',
);

my ($BrokenError) = grep { $_->{Name} eq $BrokenName } @Errors;
$Self->Is(
    $BrokenError->{Message},
    'Could not read the IdP CA certificate.',
    'Deploy() must report the failed config and the reason.',
);
$Self->True(
    $BrokenError->{ID},
    'Deploy() must report the ID of the failed config.',
);
$Self->Is(
    $BrokenError->{Context},
    $RowTemplate{Context},
    'Deploy() must report the context of the failed config.',
);
$Self->Is(
    $DeployFileContentAfter,
    $DeployFileContentBefore,
    'Deploy() must not change the deployed file.',
);
$Self->Is(
    $SystemDataObject->SystemDataGet( Key => 'AuthenticationConfig::LastDeployedRevision' ),
    $LastDeployedRevisionBefore,
    'Deploy() must not mark the configuration as deployed.',
);
$Self->False(
    $AuthenticationConfigObject->IsDeploySynced(),
    'IsDeploySynced() must be false after a failed deploy.',
);

1;
