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

my $HelperObject = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');
my $ConfigObject = $Kernel::OM->Get('Kernel::Config');
my $DBObject     = $Kernel::OM->Get('Kernel::System::DB');
my $XMLObject    = $Kernel::OM->Get('Kernel::System::XML');
my $ValidObject  = $Kernel::OM->Get('Kernel::System::Valid');

my $RandomID              = $HelperObject->GetRandomID();
my $CustomerUserTableName = 'ut_' . $RandomID;
my $CustomerID            = 'Customer-' . $RandomID;

my $Backend2Email          = 'backend2-' . $RandomID . '@example.com';
my $Backend2EmailMixedCase = 'Backend2-' . $RandomID . '@Example.com';
my $Backend1Email          = 'backend1-' . $RandomID . '@example.com';
my $InvalidEmail           = 'invalid-' . $RandomID . '@example.com';
my $FlagOffEmail           = 'flagoff-' . $RandomID . '@example.com';

my $Backend2Login = 'Backend2-' . $RandomID;
my $Backend1Login = 'Backend1-' . $RandomID;
my $InvalidLogin  = 'Backend2Invalid-' . $RandomID;
my $ShadowLogin   = 'Backend1Shadow-' . $RandomID;
my $FlagOffLogin  = 'Backend2FlagOff-' . $RandomID;

my @CreatedLogins;
my $CleanupDone;

my $CustomerUserConfig          = $ConfigObject->Get('CustomerUser');
my $OriginalUniqCheck           = $CustomerUserConfig->{CustomerUserEmailUniqCheck};
my $OriginalCheckEmailAddresses = $ConfigObject->Get('CheckEmailAddresses');

my $CustomerUserObject;

my $ReloadCustomerUserObject = sub {
    $Kernel::OM->ObjectsDiscard(
        Objects => ['Kernel::System::CustomerUser'],
    );
    $CustomerUserObject = $Kernel::OM->Get('Kernel::System::CustomerUser');
    return 1;
};

my $AddCustomerUser = sub {
    my (%Param) = @_;

    my $UserLogin = $CustomerUserObject->CustomerUserAdd(
        UserFirstname  => 'Firstname',
        UserLastname   => 'Lastname',
        UserCustomerID => $CustomerID,
        UserPassword   => 'some_pass',
        ValidID        => 1,
        UserID         => 1,
        %Param,
    );

    if ( $UserLogin && ( !$Param{Source} || $Param{Source} eq 'CustomerUser' ) ) {
        push @CreatedLogins, $UserLogin;
    }

    return $UserLogin;
};

my $Cleanup = sub {
    return if $CleanupDone;

    $CleanupDone = 1;

    my $CleanupOK = 1;

    for my $Login (@CreatedLogins) {
        my $Deleted = $DBObject->Do(
            SQL  => 'DELETE FROM customer_user WHERE login = ?',
            Bind => [ \$Login ],
        );
        if ( !$Deleted ) {
            $CleanupOK = 0;
        }
    }

    my $XML      = "<TableDrop Name='$CustomerUserTableName'/>";
    my @XMLARRAY = $XMLObject->XMLParse(
        String => $XML,
    );
    my @SQL = $DBObject->SQLProcessor(
        Database => \@XMLARRAY,
    );
    if ( !@SQL ) {
        $CleanupOK = 0;
    }

    for my $SQL (@SQL) {
        my $Dropped = $DBObject->Do( SQL => $SQL );
        if ( !$Dropped ) {
            $CleanupOK = 0;
        }
    }

    $CustomerUserConfig->{CustomerUserEmailUniqCheck} = $OriginalUniqCheck;
    $ConfigObject->Set(
        Key   => 'CustomerUser',
        Value => $CustomerUserConfig,
    );
    $ConfigObject->Set(
        Key   => 'CustomerUser1',
        Value => undef,
    );
    $ConfigObject->Set(
        Key   => 'CheckEmailAddresses',
        Value => $OriginalCheckEmailAddresses,
    );

    my $CacheObject = $Kernel::OM->Get('Kernel::System::Cache');
    $CacheObject->CleanUp(
        Type => 'CustomerUser_CustomerSearch',
    );
    $CacheObject->CleanUp(
        Type => 'CustomerUser1_CustomerSearch',
    );

    $Kernel::OM->ObjectsDiscard(
        Objects => ['Kernel::System::CustomerUser'],
    );

    return $CleanupOK;
};

$ConfigObject->Set(
    Key   => 'CheckEmailAddresses',
    Value => 0,
);

my $XMLTable = '<Table Name="' . $CustomerUserTableName . '">
    <Column Name="id" Required="true" PrimaryKey="true" AutoIncrement="true" Type="INTEGER"/>
    <Column Name="login" Required="true" Size="200" Type="VARCHAR"/>
    <Column Name="email" Required="true" Size="150" Type="VARCHAR"/>
    <Column Name="customer_id" Required="true" Size="150" Type="VARCHAR"/>
    <Column Name="pw" Required="false" Size="255" Type="VARCHAR"/>
    <Column Name="title" Required="false" Size="50" Type="VARCHAR"/>
    <Column Name="first_name" Required="true" Size="100" Type="VARCHAR"/>
    <Column Name="last_name" Required="true" Size="100" Type="VARCHAR"/>
    <Column Name="valid_id" Required="true" Type="SMALLINT"/>
    <Column Name="create_time" Required="true" Type="DATE"/>
    <Column Name="create_by" Required="true" Type="INTEGER"/>
    <Column Name="change_time" Required="true" Type="DATE"/>
    <Column Name="change_by" Required="true" Type="INTEGER"/>
</Table>';

my @XMLARRAY = $XMLObject->XMLParse(
    String => $XMLTable,
);
my @SQL = $DBObject->SQLProcessor(
    Database => \@XMLARRAY,
);
my @SQLPost = $DBObject->SQLProcessorPost(
    Database => \@XMLARRAY,
);

my $TableCreated = 1;
for my $SQL ( @SQL, @SQLPost ) {
    my $Success = $DBObject->Do( SQL => $SQL );
    $Self->True(
        $Success,
        "Customer user table '$CustomerUserTableName' is created",
    );
    $TableCreated = 0 if !$Success;
}

if ($TableCreated) {

    my %CustomerUserConfig1 = (
        Name   => 'Database Backend 1',
        Module => 'Kernel::System::CustomerUser::DB',
        Params => {
            Table               => $CustomerUserTableName,
            SearchCaseSensitive => 0,
        },
        ReadOnly                           => 0,
        CustomerKey                        => 'login',
        CustomerID                         => 'customer_id',
        CustomerValid                      => 'valid_id',
        CustomerUserListFields             => [ 'first_name', 'last_name', 'email' ],
        CustomerUserSearchFields           => [ 'login', 'first_name', 'last_name', 'customer_id' ],
        CustomerUserSearchPrefix           => '*',
        CustomerUserSearchSuffix           => '*',
        CustomerUserSearchListLimit        => 250,
        CustomerUserPostMasterSearchFields => ['email'],
        CustomerUserNameFields             => [ 'title', 'first_name', 'last_name' ],
        CustomerUserEmailUniqCheck         => 1,
        CacheTTL                           => 0,
        Map                                => [
            [ 'UserTitle',      'Title or salutation', 'title',       1, 0, 'var', '', 0 ],
            [ 'UserFirstname',  'Firstname',           'first_name',  1, 1, 'var', '', 0 ],
            [ 'UserLastname',   'Lastname',            'last_name',   1, 1, 'var', '', 0 ],
            [ 'UserLogin',      'Username',            'login',       1, 1, 'var', '', 0 ],
            [ 'UserPassword',   'Password',            'pw',          0, 0, 'var', '', 0 ],
            [ 'UserEmail',      'Email',               'email',       1, 1, 'var', '', 0 ],
            [ 'UserCustomerID', 'CustomerID',          'customer_id', 0, 1, 'var', '', 0 ],
            [ 'ValidID',        'Valid',               'valid_id',    0, 1, 'int', '', 0 ],
        ],
    );

    $ConfigObject->Set(
        Key   => 'CustomerUser1',
        Value => \%CustomerUserConfig1,
    );
    $ReloadCustomerUserObject->();

    my $Backend2User = $AddCustomerUser->(
        Source    => 'CustomerUser1',
        UserLogin => $Backend2Login,
        UserEmail => $Backend2Email,
    );
    $Self->True(
        $Backend2User,
        "CustomerUserAdd() - $Backend2Login in CustomerUser1",
    );

    my $DuplicateUser = $AddCustomerUser->(
        Source    => 'CustomerUser',
        UserLogin => 'Backend1Dup-' . $RandomID,
        UserEmail => $Backend2Email,
    );
    $Self->False(
        $DuplicateUser,
        'CustomerUserAdd() - duplicate email in another backend is rejected',
    );

    my $DuplicateCaseUser = $AddCustomerUser->(
        Source    => 'CustomerUser',
        UserLogin => 'Backend1Case-' . $RandomID,
        UserEmail => $Backend2EmailMixedCase,
    );
    $Self->False(
        $DuplicateCaseUser,
        'CustomerUserAdd() - duplicate email with different case is rejected',
    );

    my $Backend1User = $AddCustomerUser->(
        Source    => 'CustomerUser',
        UserLogin => $Backend1Login,
        UserEmail => $Backend1Email,
    );
    $Self->True(
        $Backend1User,
        "CustomerUserAdd() - $Backend1Login with a distinct email",
    );

    my $UpdateDuplicate = $CustomerUserObject->CustomerUserUpdate(
        Source         => 'CustomerUser',
        ID             => $Backend1Login,
        UserLogin      => $Backend1Login,
        UserFirstname  => 'Firstname',
        UserLastname   => 'Lastname',
        UserCustomerID => $CustomerID,
        UserEmail      => $Backend2Email,
        ValidID        => 1,
        UserID         => 1,
    );
    $Self->False(
        $UpdateDuplicate,
        'CustomerUserUpdate() - email already used in another backend is rejected',
    );

    my $UpdateOwn = $CustomerUserObject->CustomerUserUpdate(
        Source         => 'CustomerUser',
        ID             => $Backend1Login,
        UserLogin      => $Backend1Login,
        UserFirstname  => 'Updated',
        UserLastname   => 'Lastname',
        UserCustomerID => $CustomerID,
        UserEmail      => $Backend1Email,
        ValidID        => 1,
        UserID         => 1,
    );
    $Self->True(
        $UpdateOwn,
        'CustomerUserUpdate() - unchanged unique email is allowed',
    );

    my %Backend1Data = $CustomerUserObject->CustomerUserDataGet(
        User => $Backend1Login,
    );
    $Self->Is(
        $Backend1Data{UserFirstname},
        'Updated',
        'CustomerUserUpdate() stored the firstname',
    );
    $Self->Is(
        $Backend1Data{UserEmail},
        $Backend1Email,
        'CustomerUserUpdate() kept the unique email',
    );

    my $InvalidID = $ValidObject->ValidLookup(
        Valid => 'invalid',
    );
    my $InvalidUser = $AddCustomerUser->(
        Source    => 'CustomerUser1',
        UserLogin => $InvalidLogin,
        UserEmail => $InvalidEmail,
        ValidID   => $InvalidID,
    );
    $Self->True(
        $InvalidUser,
        "CustomerUserAdd() - invalid $InvalidLogin in CustomerUser1",
    );

    my $InvalidDuplicate = $AddCustomerUser->(
        Source    => 'CustomerUser',
        UserLogin => 'Backend1Invalid-' . $RandomID,
        UserEmail => $InvalidEmail,
    );
    $Self->False(
        $InvalidDuplicate,
        'CustomerUserAdd() - email of an invalid user in another backend is rejected',
    );

    $CustomerUserConfig->{CustomerUserEmailUniqCheck} = 0;
    $ConfigObject->Set(
        Key   => 'CustomerUser',
        Value => $CustomerUserConfig,
    );
    $ReloadCustomerUserObject->();

    my $ShadowUser = $AddCustomerUser->(
        Source    => 'CustomerUser',
        UserLogin => $ShadowLogin,
        UserEmail => $Backend2Email,
    );
    $Self->True(
        $ShadowUser,
        'CustomerUserAdd() - duplicate email is allowed when the check is disabled',
    );

    $CustomerUserConfig->{CustomerUserEmailUniqCheck} = 1;
    $ConfigObject->Set(
        Key   => 'CustomerUser',
        Value => $CustomerUserConfig,
    );
    $ReloadCustomerUserObject->();

    my $TemporarilyInvalidID = $ValidObject->ValidLookup(
        Valid => 'invalid-temporarily',
    );
    my $ShadowCustomerID = 'CustomerNew-' . $RandomID;

    my $ShadowUpdate = $CustomerUserObject->CustomerUserUpdate(
        Source         => 'CustomerUser',
        ID             => $ShadowLogin,
        UserLogin      => $ShadowLogin,
        UserFirstname  => 'UpdatedShadow',
        UserLastname   => 'Lastname',
        UserCustomerID => $ShadowCustomerID,
        UserEmail      => $Backend2Email,
        ValidID        => $TemporarilyInvalidID,
        UserID         => 1,
    );
    $Self->True(
        $ShadowUpdate,
        'CustomerUserUpdate() - unchanged duplicate email still allows other updates',
    );

    my %ShadowData = $CustomerUserObject->CustomerUserDataGet(
        User => $ShadowLogin,
    );
    $Self->Is(
        $ShadowData{UserFirstname},
        'UpdatedShadow',
        'CustomerUserUpdate() stored the firstname without changing the email',
    );
    $Self->Is(
        $ShadowData{UserCustomerID},
        $ShadowCustomerID,
        'CustomerUserUpdate() stored the customer id without changing the email',
    );
    $Self->Is(
        $ShadowData{ValidID},
        $TemporarilyInvalidID,
        'CustomerUserUpdate() stored the valid id without changing the email',
    );

    $CustomerUserConfig1{CustomerUserEmailUniqCheck} = 0;
    $ConfigObject->Set(
        Key   => 'CustomerUser1',
        Value => \%CustomerUserConfig1,
    );
    $ReloadCustomerUserObject->();

    my $FlagOffUser = $AddCustomerUser->(
        Source    => 'CustomerUser1',
        UserLogin => $FlagOffLogin,
        UserEmail => $FlagOffEmail,
    );
    $Self->True(
        $FlagOffUser,
        "CustomerUserAdd() - $FlagOffLogin in CustomerUser1 with the check disabled",
    );

    my $FlagOffDuplicate = $AddCustomerUser->(
        Source    => 'CustomerUser',
        UserLogin => 'Backend1FlagOff-' . $RandomID,
        UserEmail => $FlagOffEmail,
    );
    $Self->False(
        $FlagOffDuplicate,
        'CustomerUserAdd() - email in a backend with the check disabled is still rejected',
    );
}

$Self->True(
    $Cleanup->(),
    'Removed the second customer user backend',
);

END {
    return if $CleanupDone;

    $Cleanup->();
}

1;
