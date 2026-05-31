# --
# Copyright (C) 2021 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

## no critic (Modules::RequireExplicitPackage)
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
my $HelperObject = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');

my $SendmailConfigObject = $Kernel::OM->Get('Kernel::System::SendmailConfig');
my $ConfigObject         = $Kernel::OM->Get('Kernel::Config');
my $DBObject             = $Kernel::OM->Get('Kernel::System::DB');

# Get test user ID
my $TestUserID = 1;

#
# General note:
# Timeout and SkipSSLVerification not supported in 6.5 version, only from 7.3
# but in here to have similar test code.
#

# Test Add()
my $TestCases = [
    {
        Name   => 'Add() - Basic SMTP config',
        Params => {
            SendmailModule      => 'SMTP',
            Host                => 'smtp.example.org',
            Port                => 25,
            Timeout             => 30,
            SkipSSLVerification => 0,
            IsFallbackConfig    => 0,
            EmailAddresses      => ['test@example.org'],
            ValidID             => 1,
            UserID              => $TestUserID,
        },
        ExpectedResult => 1,
    },
    {
        Name   => 'Add() - SMTPTLS config with authentication',
        Params => {
            SendmailModule      => 'SMTPTLS',
            Host                => 'smtp.example.org',
            Port                => 587,
            Timeout             => 30,
            SkipSSLVerification => 0,
            IsFallbackConfig    => 0,
            AuthenticationType  => 'password',
            AuthUser            => 'mail@example.org',
            AuthPassword        => 'secret',
            EmailAddresses      => [ 'test2@example.org', 'test3@example.org' ],
            Comments            => 'Test comment',
            ValidID             => 1,
            UserID              => $TestUserID,
        },
        ExpectedResult => 1,
    },
    {
        Name   => 'Add() - Fallback config',
        Params => {
            SendmailModule      => 'SMTP',
            Host                => 'fallback.example.org',
            Port                => 25,
            Timeout             => 30,
            SkipSSLVerification => 0,
            IsFallbackConfig    => 1,
            ValidID             => 1,
            UserID              => $TestUserID,
        },
        ExpectedResult => 1,
    },
    {
        Name   => 'Add() - Missing ValidID',
        Params => {
            SendmailModule      => 'SMTP',
            Host                => 'smtp.example.org',
            Port                => 25,
            Timeout             => 30,
            SkipSSLVerification => 0,
            IsFallbackConfig    => 0,
            EmailAddresses      => ['test@example.org'],
            UserID              => $TestUserID,
        },
        ExpectedResult => undef,
    },
    {
        Name   => 'Add() - Missing UserID',
        Params => {
            SendmailModule      => 'SMTP',
            Host                => 'smtp.example.org',
            Port                => 25,
            Timeout             => 30,
            SkipSSLVerification => 0,
            IsFallbackConfig    => 0,
            EmailAddresses      => ['test@example.org'],
            ValidID             => 1,
        },
        ExpectedResult => undef,
    },
    {
        Name   => 'Add() - Missing SendmailModule',
        Params => {
            Host                => 'smtp.example.org',
            Port                => 25,
            Timeout             => 30,
            SkipSSLVerification => 0,
            IsFallbackConfig    => 0,
            EmailAddresses      => ['test@example.org'],
            ValidID             => 1,
            UserID              => $TestUserID,
        },
        ExpectedResult => undef,
    },
];

my @CreatedIDs;
for my $Test ( @{$TestCases} ) {
    my $SendmailConfigID = $SendmailConfigObject->Add(
        %{ $Test->{Params} },
    );

    if ( $Test->{ExpectedResult} ) {
        $Self->True(
            scalar $SendmailConfigID,
            "$Test->{Name} - should return ID",
        );
        if ($SendmailConfigID) {
            push @CreatedIDs, $SendmailConfigID;
        }
    }
    else {
        $Self->False(
            scalar $SendmailConfigID,
            "$Test->{Name} - should return undef",
        );
    }
}

# Test Get()
my $TestCaseIndex = 0;
for my $SendmailConfigID (@CreatedIDs) {
    my $SendmailConfig = $SendmailConfigObject->Get(
        ID => $SendmailConfigID,
    );

    $Self->True(
        IsHashRefWithData($SendmailConfig),
        'Get() must return hash ref with data.',
    );

    my $TestCase = $TestCases->[$TestCaseIndex];

    # Timeout and SkipSSLVerification not supported in 6.5
    delete $SendmailConfig->{Timeout};
    delete $SendmailConfig->{SkipSSLVerification};
    delete $TestCase->{Params}->{Timeout};
    delete $TestCase->{Params}->{SkipSSLVerification};
    delete $TestCase->{Params}->{UserID};

    for my $Field ( sort keys %{ $TestCase->{Params} } ) {
        my $ExpectedValue = $TestCase->{Params}->{$Field};
        my $Value         = $SendmailConfig->{$Field};

        if ( ref $ExpectedValue eq 'ARRAY' ) {
            $ExpectedValue = [ sort @{$ExpectedValue} ];
            $Value         = [ sort @{$Value} ];

            $Self->IsDeeply(
                $Value,
                $ExpectedValue,
                "Get() Value of field $Field must match expected one.",
            );
        }
        else {
            $Self->Is(
                scalar $Value,
                scalar $ExpectedValue,
                "Get() Value of field $Field must match expected one.",
            );
        }
    }

    $TestCaseIndex++;
}

# Test GetAll()
my $AllConfigs = $SendmailConfigObject->GetAll();

$Self->True(
    IsArrayRefWithData($AllConfigs),
    'GetAll() must return array ref with data.',
);

# Verify all created IDs are in the list
my %AllIDs = map { $_->{ID} => 1 } @{$AllConfigs};
for my $CreatedID (@CreatedIDs) {
    $Self->True(
        scalar $AllIDs{$CreatedID},
        'GetAll() must return expected ID',
    );
}

# Test GetByEmailAddress()
my $ConfigByEmail = $SendmailConfigObject->GetByEmailAddress(
    EmailAddress => 'test@example.org',
);

$Self->Is(
    $ConfigByEmail->{ID},
    $CreatedIDs[0],
    'GetByEmailAddress() must return expected config.',
);

$ConfigByEmail = $SendmailConfigObject->GetByEmailAddress(
    EmailAddress => 'test3@example.org',
);

$Self->Is(
    $ConfigByEmail->{ID},
    $CreatedIDs[1],
    'GetByEmailAddress() must return expected config.',
);

$ConfigByEmail = $SendmailConfigObject->GetByEmailAddress(
    EmailAddress => 'unknownemailaddress@example.org',
);

$Self->False(
    scalar $ConfigByEmail,
    'GetByEmailAddress() must return expected config.',
);

$ConfigByEmail = $SendmailConfigObject->GetByEmailAddress(
    EmailAddress => 'unknownemailaddress@example.org',
    UseFallback  => 1,
);

$Self->Is(
    $ConfigByEmail->{ID},
    $CreatedIDs[2],
    'GetByEmailAddress() must return expected config.',
);

# Test GetFallback()
my $FallbackConfig = $SendmailConfigObject->GetFallback();
$Self->Is(
    $FallbackConfig->{IsFallbackConfig},
    1,
    'GetFallback() must return config with IsFallbackConfig = 1.',
);

$Self->Is(
    $FallbackConfig->{ID},
    $CreatedIDs[2],
    'GetFallback() must return expected config.',
);

# Test GetAvailableSendmailModules()
my $AvailableModules = $SendmailConfigObject->GetAvailableSendmailModules();
my @AvailableModules = sort keys %{$AvailableModules};
my @ExpectedModules  = sort qw( DoNotSendEmail MSGraph Sendmail SMTP SMTPS SMTPTLS );
$Self->IsDeeply(
    \@AvailableModules,
    \@ExpectedModules,
    'GetAvailableSendmailModules() must return expected modules.',
);

# Test GetSenderEmailAddresses()
$ConfigObject->Set(
    Key   => 'SendmailConfig::EmailAddress::ConfigOptions',
    Value => [
        'AdminEmail',
        'NotificationSenderEmail',
        'PostMaster::PreFilterModule::NewTicketReject::Sender',
    ],
);

$ConfigObject->Set(
    Key   => 'AdminEmail',
    Value => 'test999@example.org',
);

$ConfigObject->Set(
    Key   => 'NotificationSenderEmail',
    Value => 'test@example.org',          # used in test config
);
$ConfigObject->Set(
    Key   => 'PostMaster::PreFilterModule::NewTicketReject::Sender',
    Value => 'test1001@example.org',
);

my $SenderEmailAddresses = $SendmailConfigObject->GetSenderEmailAddresses();
for my $ExpectedSenderEmailAddress ( 'test999@example.org', 'test@example.org', 'test1001@example.org', ) {
    $Self->True(
        exists $SenderEmailAddresses->{$ExpectedSenderEmailAddress},
        'GetSenderEmailAddresses() must report expected addresses.',
    );
}

$SenderEmailAddresses = $SendmailConfigObject->GetSenderEmailAddresses(
    OnlyUnused => 1,
);
for my $ExpectedSenderEmailAddress ( 'test999@example.org', 'test1001@example.org', ) {
    $Self->True(
        exists $SenderEmailAddresses->{$ExpectedSenderEmailAddress},
        'GetSenderEmailAddresses() must report expected addresses.',
    );
}
$Self->True(
    !exists $SenderEmailAddresses->{'test@example.org'},
    'GetSenderEmailAddresses() must not report unexpected addresses.',
);

$SenderEmailAddresses = $SendmailConfigObject->GetSenderEmailAddresses(
    OnlyUnused              => 1,
    KeepForSendmailConfigID => $CreatedIDs[0],
);

for my $ExpectedSenderEmailAddress ( 'test999@example.org', 'test@example.org', 'test1001@example.org', ) {
    $Self->True(
        exists $SenderEmailAddresses->{$ExpectedSenderEmailAddress},
        'GetSenderEmailAddresses() must report expected addresses.',
    );
}

# Test Update()
my $UpdateResult = $SendmailConfigObject->Update(
    ID                  => $CreatedIDs[0],
    SendmailModule      => 'SMTP',
    Host                => 'updated.example.org',
    Port                => 465,
    Timeout             => 60,
    SkipSSLVerification => 1,
    IsFallbackConfig    => 0,
    EmailAddresses      => ['updated@example.org'],
    Comments            => 'Updated comment',
    ValidID             => 1,
    UserID              => $TestUserID,
);

$Self->True(
    scalar $UpdateResult,
    'Update() must report success.',
);

my $UpdatedConfig = $SendmailConfigObject->Get(
    ID => $CreatedIDs[0],
);

$Self->Is(
    $UpdatedConfig->{Host},
    'updated.example.org',
    'Update() must updated config as expected.',
);

# Test Delete()
my $DeleteResult = $SendmailConfigObject->Delete(
    ID => $CreatedIDs[0],
);

$Self->True(
    scalar $DeleteResult,
    'Delete() must report success.',
);

my $DeletedConfig = $SendmailConfigObject->Get(
    ID => $CreatedIDs[0],
);

$Self->False(
    scalar $DeletedConfig,
    'Get() must not return deleted config.',
);

1;
