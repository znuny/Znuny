# --
# Copyright (C) 2001-2021 OTRS AG, https://otrs.com/
# Copyright (C) 2021 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see https://www.gnu.org/licenses/gpl-3.0.txt.
# --
## nofilter(TidyAll::Plugin::Znuny::Perl::CacheCleanup)

package Kernel::System::UnitTest::Helper;

use strict;
use warnings;

use utf8;

use File::Path qw(rmtree);

# Load DateTime so that we can override functions for the FixedTimeSet().
use DateTime;

use Kernel::System::PostMaster;
use Kernel::System::SysConfig;
use Kernel::System::VariableCheck qw(:all);

our @ObjectDependencies = (
    'Kernel::Config',
    'Kernel::System::Cache',
    'Kernel::System::CommunicationLog',
    'Kernel::System::CustomerUser',
    'Kernel::System::DB',
    'Kernel::System::DateTime',
    'Kernel::System::DynamicField',
    'Kernel::System::DynamicField::Backend',
    'Kernel::System::Encode',
    'Kernel::System::Group',
    'Kernel::System::Log',
    'Kernel::System::Main',
    'Kernel::System::Service',
    'Kernel::System::SysConfig',
    'Kernel::System::Ticket',
    'Kernel::System::Ticket::Article',
    'Kernel::System::UnitTest',
    'Kernel::System::UnitTest::Driver',
    'Kernel::System::User',
    'Kernel::System::XML',
    'Kernel::System::ZnunyHelper',
);

=head1 NAME

Kernel::System::UnitTest::Helper - unit test helper functions


=head2 new()

construct a helper object.

    use Kernel::System::ObjectManager;
    local $Kernel::OM = Kernel::System::ObjectManager->new(
        'Kernel::System::UnitTest::Helper' => {
            RestoreDatabase => 1,                   # runs the test in a transaction,
                                                    # and roll it back in the destructor
                                                    #
                                                    # NOTE: Rollback does not work for
                                                    # changes in the database layout. If you
                                                    # want to do this in your tests, you cannot
                                                    # use this option and must handle the rollback
                                                    # yourself.
        },
    );
    my $HelperObject = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');

=cut

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {};
    bless( $Self, $Type );

    $Self->{Debug} = $Param{Debug} || 0;

    $Self->{UnitTestDriverObject} = $Self->UnitTestObjectGet();

    # Override Perl's built-in time handling mechanism to set a fixed time if needed.
    $Self->_MockPerlTimeHandling();

    # Remove any leftover custom files from aborted previous runs.
    $Self->CustomFileCleanup();

    # set environment variable to skip SSL certificate verification if needed
    if ( $Param{SkipSSLVerify} ) {

        # remember original value
        $Self->{PERL_LWP_SSL_VERIFY_HOSTNAME} = $ENV{PERL_LWP_SSL_VERIFY_HOSTNAME};

        # set environment value to 0
        $ENV{PERL_LWP_SSL_VERIFY_HOSTNAME} = 0;    ## no critic

        $Self->{RestoreSSLVerify} = 1;
        $Self->{UnitTestDriverObject}->True( 1, 'Skipping SSL certificates verification' );
    }

    # switch article dir to a temporary one to avoid collisions
    if ( $Param{UseTmpArticleDir} ) {
        $Self->UseTmpArticleDir();
    }

    if ( $Param{RestoreDatabase} ) {
        $Self->{RestoreDatabase} = 1;
        my $StartedTransaction = $Self->BeginWork();
        $Self->{UnitTestDriverObject}->True( $StartedTransaction, 'Started database transaction.' );
    }

    # Disable scheduling of asynchronous tasks using C<AsynchronousExecutor> component of System daemon.
    if ( $Param{DisableAsyncCalls} ) {
        $Self->DisableAsyncCalls();
    }

    $Self->_DisableDefaultSysConfigSettings();

    if ( $Param{DisableSysConfigs} ) {
        $Self->DisableSysConfigs(
            %Param
        );
    }

    return $Self;
}

=head2 GetRandomID()

creates a random ID that can be used in tests as a unique identifier.

It is guaranteed that within a test this function will never return a duplicate.

Please note that these numbers are not really random and should only be used
to create test data.

    my $RandomID = $HelperObject->GetRandomID();

Returns:

    my $RandomID = 'test2735808026700610';

=cut

sub GetRandomID {
    my ( $Self, %Param ) = @_;

    return 'test' . $Self->GetRandomNumber();
}

=head2 GetRandomNumber()

creates a random Number that can be used in tests as a unique identifier.

It is guaranteed that within a test this function will never return a duplicate.

Please note that these numbers are not really random and should only be used
to create test data.

    my $RandomNumber = $HelperObject->GetRandomNumber();

Returns:

    my $RandomNumber = '2735808026700610';

=cut

# Use package variables here (instead of attributes in $Self)
# to make it work across several unit tests that run during the same second.
my %GetRandomNumberPrevious;

sub GetRandomNumber {

    my $PIDReversed = reverse $$;
    my $PID         = reverse sprintf '%.6d', $PIDReversed;

    my $Prefix = $PID . substr time(), -5, 5;

    return $Prefix . sprintf( '%.05d', ( $GetRandomNumberPrevious{$Prefix}++ || 0 ) );
}

=head2 TestUserCreate()

creates a test user that can be used in tests. It will
be set to invalid automatically during L</DESTROY()>. Returns
the login name of the new user, the password is the same.

    my $TestUserLogin = $HelperObject->TestUserCreate(
        Groups    => ['admin', 'users'],         # optional, list of groups to add this user to (rw rights)
        Language  => 'de',                       # optional, defaults to 'en' if not set
        KeepValid => 1,                          # optional, defaults to 0
    );

Returns:

    my $TestUserLogin = 'test2755008034702000';


To get UserLogin and UserID:

    my ( $TestUserLogin, $TestUserID ) = $HelperObject->TestUserCreate(
        Groups    => ['admin', 'users'],
        Language  => 'de',
        KeepValid => 1,
    );

    my $TestUserLogin = 'test2755008034702000';
    my $TestUserID    = '123';

=cut

sub TestUserCreate {
    my ( $Self, %Param ) = @_;

    my $ZnunyHelperObject = $Kernel::OM->Get('Kernel::System::ZnunyHelper');

    # Disable email checks to create new user.
    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');
    local $ConfigObject->{CheckEmailAddresses} = 0;

    # Create test user.
    my $TestUserLogin = $Self->GetRandomID();
    my $TestUserID    = $ZnunyHelperObject->_UserCreateIfNotExists(
        UserFirstname => $TestUserLogin,
        UserLastname  => $TestUserLogin,
        UserLogin     => $TestUserLogin,
        UserPw        => $TestUserLogin,
        UserEmail     => $TestUserLogin . '@localunittest.com',
        ValidID       => 1,
        ChangeUserID  => 1,
        %Param,
    );

    # Remember UserID of the test user to later set it to invalid
    #   in the destructor.
    $Self->{TestUsers} //= [];
    push @{ $Self->{TestUsers} }, $TestUserID;

    if ( $Param{KeepValid} ) {
        $Self->{TestUsersKeepValid} //= [];
        push @{ $Self->{TestUsersKeepValid} }, $TestUserID;
    }

    $Self->{UnitTestDriverObject}->True( 1, "Created test user $TestUserID" );

    # Add user to groups.
    GROUP_NAME:
    for my $GroupName ( @{ $Param{Groups} || [] } ) {

        my $GroupObject = $Kernel::OM->Get('Kernel::System::Group');

        my $GroupID = $GroupObject->GroupLookup( Group => $GroupName );
        die "Cannot find group $GroupName" if ( !$GroupID );

        $GroupObject->PermissionGroupUserAdd(
            GID        => $GroupID,
            UID        => $TestUserID,
            Permission => {
                ro        => 1,
                move_into => 1,
                create    => 1,
                owner     => 1,
                priority  => 1,
                rw        => 1,
            },
            UserID => 1,
        ) || die "Could not add test user $TestUserLogin to group $GroupName";

        $Self->{UnitTestDriverObject}->True( 1, "Added test user $TestUserLogin to group $GroupName" );
    }

    # Set user language.
    my $UserLanguage = $Param{Language} || 'en';
    $Kernel::OM->Get('Kernel::System::User')->SetPreferences(
        UserID => $TestUserID,
        Key    => 'UserLanguage',
        Value  => $UserLanguage,
    );
    $Self->{UnitTestDriverObject}->True( 1, "Set user UserLanguage to $UserLanguage" );

    return wantarray ? ( $TestUserLogin, $TestUserID ) : $TestUserLogin;
}

=head2 TestCustomerUserCreate()

creates a test customer user that can be used in tests. It will
be set to invalid automatically during L</DESTROY()>. Returns
the login name of the new customer user, the password is the same.

    my $TestCustomerUserLogin = $HelperObject->TestCustomerUserCreate(
        Language  => 'de',   # optional, defaults to 'en' if not set
        KeepValid => 1,      # optional, defaults to 0
    );

Returns:

    my $TestCustomerUserLogin = 'test2735808026700610';

=cut

sub TestCustomerUserCreate {
    my ( $Self, %Param ) = @_;

    my $ZnunyHelperObject = $Kernel::OM->Get('Kernel::System::ZnunyHelper');

    # Disable email checks to create new user.
    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');
    local $ConfigObject->{CheckEmailAddresses} = 0;

    # Create test customer user.
    my $TestUserLogin = $Self->GetRandomID();
    my $TestUser      = $ZnunyHelperObject->_CustomerUserCreateIfNotExists(
        Source         => 'CustomerUser',
        UserFirstname  => $TestUserLogin,
        UserLastname   => $TestUserLogin,
        UserCustomerID => $TestUserLogin,
        UserLogin      => $TestUserLogin,
        UserPassword   => $TestUserLogin,
        UserEmail      => $TestUserLogin . '@localunittest.com',
        ValidID        => 1,
        UserID         => 1,
        %Param,
    );

    # Remember UserID of the test user to later set it to invalid
    #   in the destructor.
    $Self->{TestCustomerUsers} //= [];
    push @{ $Self->{TestCustomerUsers} }, $TestUser;

    if ( $Param{KeepValid} ) {
        $Self->{TestCustomerUsersKeepValid} //= [];
        push @{ $Self->{TestCustomerUsersKeepValid} }, $TestUser;
    }

    $Self->{UnitTestDriverObject}->True( 1, "Created test customer user $TestUser" );

    # Set customer user language.
    my $UserLanguage = $Param{Language} || 'en';
    $Kernel::OM->Get('Kernel::System::CustomerUser')->SetPreferences(
        UserID => $TestUser,
        Key    => 'UserLanguage',
        Value  => $UserLanguage,
    );
    $Self->{UnitTestDriverObject}->True( 1, "Set customer user UserLanguage to $UserLanguage" );

    return $TestUser;
}

=head2 BeginWork()

Starts a database transaction (in order to isolate the test from the static database).

    $HelperObject->BeginWork();

=cut

sub BeginWork {
    my ( $Self, %Param ) = @_;
    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');
    $DBObject->Connect();
    return $DBObject->{dbh}->begin_work();
}

=head2 Rollback()

Rolls back the current database transaction.

    $HelperObject->Rollback();

=cut

sub Rollback {
    my ( $Self, %Param ) = @_;
    my $DatabaseHandle = $Kernel::OM->Get('Kernel::System::DB')->{dbh};

    # if there is no database handle, there's nothing to rollback
    if ($DatabaseHandle) {
        return $DatabaseHandle->rollback();
    }
    return 1;
}

=head2 GetTestHTTPHostname()

Returns a host name for HTTP based tests, possibly including the port.

    my $Hostname = $HelperObject->GetTestHTTPHostname();

Returns:
    my $Hostname = 'localhost';

=cut

sub GetTestHTTPHostname {
    my ( $Self, %Param ) = @_;

    my $Host = $Kernel::OM->Get('Kernel::Config')->Get('TestHTTPHostname');
    return $Host if $Host;

    my $FQDN = $Kernel::OM->Get('Kernel::Config')->Get('FQDN');

    # try to resolve fqdn host
    if ( $FQDN ne 'yourhost.example.com' && gethostbyname($FQDN) ) {
        $Host = $FQDN;
    }

    # try to resolve localhost instead
    if ( !$Host && gethostbyname('localhost') ) {
        $Host = 'localhost';
    }

    # use hardcoded localhost ip address
    if ( !$Host ) {
        $Host = '127.0.0.1';
    }

    return $Host;
}

my $FixedTime;

=head2 FixedTimeSet()

makes it possible to override the system time as long as this object lives.
You can pass an optional time parameter that should be used, if not,
the current system time will be used.

All calls to methods of Kernel::System::Time and Kernel::System::DateTime will
use the given time afterwards.

    # with Timestamp
    my $Timestamp = $HelperObject->FixedTimeSet(366475757);

    # with previously created DateTime object
    my $Timestamp = $HelperObject->FixedTimeSet($DateTimeObject);

    # set to current date and time
    my $Timestamp = $HelperObject->FixedTimeSet();

Returns:

    # date/time as seconds
    my $Timestamp = 1454420017;

=cut

sub FixedTimeSet {
    my ( $Self, $TimeToSave ) = @_;

    if ( $TimeToSave && ref $TimeToSave eq 'Kernel::System::DateTime' ) {
        $FixedTime = $TimeToSave->ToEpoch();
    }
    else {
        $FixedTime = $TimeToSave // CORE::time();
    }

    return $FixedTime;
}

=head2 FixedTimeUnset()

Restores the regular system time behavior.

    $HelperObject->FixedTimeUnset();

=cut

sub FixedTimeUnset {
    my ($Self) = @_;

    undef $FixedTime;
    return;
}

=head2 FixedTimeAddSeconds()

Adds a number of seconds to the fixed system time which was previously
set by FixedTimeSet(). You can pass a negative value to go back in time.

    $HelperObject->FixedTimeAddSeconds(5);

=cut

sub FixedTimeAddSeconds {
    my ( $Self, $SecondsToAdd ) = @_;

    return if !defined $FixedTime;
    $FixedTime += $SecondsToAdd;
    return;
}

# See http://perldoc.perl.org/5.10.0/perlsub.html#Overriding-Built-in-Functions
## nofilter(TidyAll::Plugin::Znuny::Perl::Time)

sub _MockPerlTimeHandling {
    no warnings 'redefine';    ## no critic
    *CORE::GLOBAL::time = sub {
        return defined $FixedTime ? $FixedTime : CORE::time();
    };
    *CORE::GLOBAL::localtime = sub {
        my ($Time) = @_;
        if ( !defined $Time ) {
            $Time = defined $FixedTime ? $FixedTime : CORE::time();
        }
        return CORE::localtime($Time);
    };
    *CORE::GLOBAL::gmtime = sub {
        my ($Time) = @_;
        if ( !defined $Time ) {
            $Time = defined $FixedTime ? $FixedTime : CORE::time();
        }
        return CORE::gmtime($Time);
    };

    # Newer versions of DateTime provide a function _core_time() to override for time simulations.
    *DateTime::_core_time = sub {    ## no critic
        return defined $FixedTime ? $FixedTime : CORE::time();
    };

    # Make sure versions of DateTime also use _core_time() it by overriding now() as well.
    *DateTime::now = sub {
        my $Self = shift;
        return $Self->from_epoch(
            epoch => $Self->_core_time(),
            @_
        );
    };

    # This is needed to reload objects that directly use the native time functions
    #   to get a hold of the overrides.
    my @Objects = (
        'Kernel::System::Time',
        'Kernel::System::DB',
        'Kernel::System::Cache::FileStorable',
        'Kernel::System::PID',
    );

    for my $Object (@Objects) {
        my $FilePath = $Object;
        $FilePath =~ s{::}{/}xmsg;
        $FilePath .= '.pm';
        if ( $INC{$FilePath} ) {
            no warnings 'redefine';    ## no critic
            delete $INC{$FilePath};
            require $FilePath;         ## nofilter(TidyAll::Plugin::Znuny::Perl::Require)
        }
    }

    return 1;
}

=head2 DESTROY()

performs various clean-ups.

=cut

sub DESTROY {
    my $Self = shift;

    # some users or customer users should be kept valid (development)
    USERTYPE:
    for my $UserType (qw( User CustomerUser )) {
        my $Key          = "Test$UserType";
        my $KeyKeepValid = "${Key}KeepValid";

        next USERTYPE if !IsArrayRefWithData( $Self->{$KeyKeepValid} );

        my @SetInvalid;
        USER:
        for my $User ( @{ $Self->{$Key} } ) {
            next USER if grep { $_ eq $User } @{ $Self->{$KeyKeepValid} };

            push @SetInvalid, $User;
        }

        $Self->{$Key} = \@SetInvalid;
    }

    # reset time freeze
    FixedTimeUnset();

    # FixedDateTimeObjectUnset();

    if ( $Self->{DestroyLog} ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => "Helper is destroyed!"
        );
    }

    # Cleanup temporary database if it was set up.
    $Self->TestDatabaseCleanup() if $Self->{ProvideTestDatabase};

    # Remove any custom files.
    $Self->CustomFileCleanup();

    # restore environment variable to skip SSL certificate verification if needed
    if ( $Self->{RestoreSSLVerify} ) {

        $ENV{PERL_LWP_SSL_VERIFY_HOSTNAME} = $Self->{PERL_LWP_SSL_VERIFY_HOSTNAME};    ## no critic

        $Self->{RestoreSSLVerify} = 0;

        $Self->{UnitTestDriverObject}->True( 1, 'Restored SSL certificates verification' );
    }

    # restore database, clean caches
    if ( $Self->{RestoreDatabase} ) {
        my $RollbackSuccess = $Self->Rollback();
        $Kernel::OM->Get('Kernel::System::Cache')->CleanUp();
        $Self->{UnitTestDriverObject}
            ->True( $RollbackSuccess, 'Rolled back all database changes and cleaned up the cache.' );
    }

    # disable email checks to create new user
    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');
    local $ConfigObject->{CheckEmailAddresses} = 0;

    # cleanup temporary article directory
    if ( $Self->{TmpArticleDir} && -d $Self->{TmpArticleDir} ) {
        File::Path::rmtree( $Self->{TmpArticleDir} );
    }

    # invalidate test users
    if ( ref $Self->{TestUsers} eq 'ARRAY' && @{ $Self->{TestUsers} } ) {
        TESTUSERS:
        for my $TestUser ( @{ $Self->{TestUsers} } ) {

            my %User = $Kernel::OM->Get('Kernel::System::User')->GetUserData(
                UserID => $TestUser,
            );

            if ( !$User{UserID} ) {

                # if no such user exists, there is no need to set it to invalid;
                # happens when the test user is created inside a transaction
                # that is later rolled back.
                next TESTUSERS;
            }

            # make test user invalid
            my $Success = $Kernel::OM->Get('Kernel::System::User')->UserUpdate(
                %User,
                ValidID      => 2,
                ChangeUserID => 1,
            );

            $Self->{UnitTestDriverObject}->True( $Success, "Set test user $TestUser to invalid" );
        }
    }

    # invalidate test customer users
    if ( ref $Self->{TestCustomerUsers} eq 'ARRAY' && @{ $Self->{TestCustomerUsers} } ) {
        TESTCUSTOMERUSERS:
        for my $TestCustomerUser ( @{ $Self->{TestCustomerUsers} } ) {

            my %CustomerUser = $Kernel::OM->Get('Kernel::System::CustomerUser')->CustomerUserDataGet(
                User => $TestCustomerUser,
            );

            if ( !$CustomerUser{UserLogin} ) {

                # if no such customer user exists, there is no need to set it to invalid;
                # happens when the test customer user is created inside a transaction
                # that is later rolled back.
                next TESTCUSTOMERUSERS;
            }

            my $Success = $Kernel::OM->Get('Kernel::System::CustomerUser')->CustomerUserUpdate(
                %CustomerUser,
                ID      => $CustomerUser{UserID},
                ValidID => 2,
                UserID  => 1,
            );

            $Self->{UnitTestDriverObject}->True(
                $Success, "Set test customer user $TestCustomerUser to invalid"
            );
        }
    }

    # Only manually delete created tickets and dynamic fields if RestoreDatabase flag is not set.
    # Otherwise the already deleted tickets will be tried to delete again, resulting
    # in many error messages.
    return if $Self->{RestoreDatabase};

    my $MainObject = $Kernel::OM->Get('Kernel::System::Main');

    my $TicketObjectLoaded = $MainObject->Require(
        'Kernel::System::Ticket',
    );

    $Self->{UnitTestDriverObject}->True(
        $TicketObjectLoaded,
        'Loaded TicketObject via MainObject',
    );

    my $TicketObject      = $Kernel::OM->Get('Kernel::System::Ticket');
    my $ZnunyHelperObject = $Kernel::OM->Get('Kernel::System::ZnunyHelper');

    if ( IsArrayRefWithData( $Self->{TestTickets} ) ) {
        TICKETID:
        for my $TicketID ( sort @{ $Self->{TestTickets} } ) {
            next TICKETID if !$TicketID;

            $TicketObject->TicketDelete(
                TicketID => $TicketID,
                UserID   => 1,
            );
        }
    }

    return if !IsArrayRefWithData( $Self->{TestDynamicFields} );

    $ZnunyHelperObject->_DynamicFieldsDelete( @{ $Self->{TestDynamicFields} } );

    return;
}

=head2 ConfigSettingChange()

temporarily change a configuration setting system wide to another value,
both in the current ConfigObject and also in the system configuration on disk.

This will be reset when the Helper object is destroyed.

Please note that this will not work correctly in clustered environments.

    $HelperObject->ConfigSettingChange(
        Valid => 1,            # (optional) enable or disable setting
        Key   => 'MySetting',  # setting name
        Value => { ... } ,     # setting value
    );

=cut

sub ConfigSettingChange {
    my ( $Self, %Param ) = @_;

    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');
    my $MainObject   = $Kernel::OM->Get('Kernel::System::Main');

    my $Valid = $Param{Valid} // 1;
    my $Key   = $Param{Key};
    my $Value = $Param{Value};

    die "Need 'Key'" if !defined $Key;

    my $RandomNumber = $Self->GetRandomNumber();

    my $KeyDump = $Key;
    $KeyDump =~ s|'|\\'|smxg;
    $KeyDump = "\$Self->{'$KeyDump'}";
    $KeyDump =~ s|\#{3}|'}->{'|smxg;

    # Also set at runtime in the ConfigObject. This will be destroyed at the end of the unit test.
    $ConfigObject->Set(
        Key   => $Key,
        Value => $Valid ? $Value : undef,
    );

    my $ValueDump;
    if ($Valid) {
        $ValueDump = $MainObject->Dump($Value);
        $ValueDump =~ s/\$VAR1/$KeyDump/;
    }
    else {
        $ValueDump = "delete $KeyDump;";
    }

    my $PackageName = "ZZZZUnitTest$RandomNumber";

    my $Content = <<"EOF";
# OTRS config file (automatically generated)
# VERSION:1.1
package Kernel::Config::Files::$PackageName;
use strict;
use warnings;
no warnings 'redefine';
use utf8;
sub Load {
    my (\$File, \$Self) = \@_;
    $ValueDump
}
1;
EOF

    my $Home     = $ConfigObject->Get('Home');
    my $FileName = "$Home/Kernel/Config/Files/$PackageName.pm";

    $MainObject->FileWrite(
        Location => $FileName,
        Mode     => 'utf8',
        Content  => \$Content,
    ) || die "Could not write $FileName";

    return 1;
}

=head2 CustomCodeActivate()

Temporarily include custom code in the system. For example, you may use this to redefine a
subroutine from another class. This change will persist for remainder of the test.

All code will be removed when the Helper object is destroyed.

Please note that this will not work correctly in clustered environments.

    $HelperObject->CustomCodeActivate(
        Code => q^
sub Kernel::Config::Files::ZZZZUnitTestIdentifier::Load {} # no-op, avoid warning logs
use Kernel::System::WebUserAgent;
package Kernel::System::WebUserAgent;
use strict;
use warnings;
{
    no warnings 'redefine';
    sub Request {
        my $JSONString = '{"Results":{},"ErrorMessage":"","Success":1}';
        return (
            Content => \$JSONString,
            Status  => '200 OK',
        );
    }
}
1;^,
        Identifier => 'News',   # (optional) Code identifier to include in file name
    );

=cut

sub CustomCodeActivate {
    my ( $Self, %Param ) = @_;

    my $Code       = $Param{Code};
    my $Identifier = $Param{Identifier} || $Self->GetRandomNumber();

    die "Need 'Code'" if !defined $Code;

    my $PackageName = "ZZZZUnitTest$Identifier";

    my $Home     = $Kernel::OM->Get('Kernel::Config')->Get('Home');
    my $FileName = "$Home/Kernel/Config/Files/$PackageName.pm";
    $Kernel::OM->Get('Kernel::System::Main')->FileWrite(
        Location => $FileName,
        Mode     => 'utf8',
        Content  => \$Code,
    ) || die "Could not write $FileName";

    return 1;
}

=head2 CustomFileCleanup()

Removes all custom files from C<ConfigSettingChange()> and C<CustomCodeActivate()>.

    $HelperObject->CustomFileCleanup();

=cut

sub CustomFileCleanup {
    my ( $Self, %Param ) = @_;

    my $Home  = $Kernel::OM->Get('Kernel::Config')->Get('Home');
    my @Files = $Kernel::OM->Get('Kernel::System::Main')->DirectoryRead(
        Directory => "$Home/Kernel/Config/Files",
        Filter    => "ZZZZUnitTest*.pm",
    );
    for my $File (@Files) {
        $Kernel::OM->Get('Kernel::System::Main')->FileDelete(
            Location => $File,
        ) || die "Could not delete $File";
    }
    return 1;
}

=head2 UseTmpArticleDir()

Switch the article storage directory to a temporary one to prevent collisions;

    $HelperObject->UseTmpArticleDir();

=cut

sub UseTmpArticleDir {
    my ( $Self, %Param ) = @_;

    my $Home = $Kernel::OM->Get('Kernel::Config')->Get('Home');

    my $TmpArticleDir;
    TRY:
    for my $Try ( 1 .. 100 ) {

        $TmpArticleDir = $Home . '/var/tmp/unittest-article-' . $Self->GetRandomNumber();

        next TRY if -e $TmpArticleDir;
        last TRY;
    }

    $Self->ConfigSettingChange(
        Valid => 1,
        Key   => 'Ticket::Article::Backend::MIMEBase::ArticleDataDir',
        Value => $TmpArticleDir,
    );

    $Self->{TmpArticleDir} = $TmpArticleDir;

    return 1;
}

=head2 DisableAsyncCalls()

Disable scheduling of asynchronous tasks using C<AsynchronousExecutor> component of System daemon.

    $HelperObject->DisableAsyncCalls();

=cut

sub DisableAsyncCalls {
    my ( $Self, %Param ) = @_;

    $Self->ConfigSettingChange(
        Valid => 1,
        Key   => 'DisableAsyncCalls',
        Value => 1,
    );

    return 1;
}

=head2 _DisableDefaultSysConfigSettings()

These SysConfig options are disabled by default.

=cut

sub _DisableDefaultSysConfigSettings {
    my ( $Self, %Param ) = @_;

    my @DisableSysConfigs = (
        'Ticket::EventModulePost###999-NotifyOnEmptyProcessTickets',
        'Ticket::EventModulePost###Mentions',
    );

    $Self->DisableSysConfigs(
        DisableSysConfigs => \@DisableSysConfigs,
    );

    return 1;
}

=head2 DisableSysConfigs()

Disables SysConfigs for current UnitTest.

    $HelperObject->DisableSysConfigs(
        DisableSysConfigs => [
            'Ticket::Responsible'
            'DashboardBackend###0442-RSS'
        ],
    );

    $Kernel::OM->ObjectParamAdd(
        'Kernel::System::UnitTest::Helper' => {
            DisableSysConfigs => [
                'Ticket::Responsible'
                'DashboardBackend###0442-RSS'
            ],
        },
    );

=cut

sub DisableSysConfigs {
    my ( $Self, %Param ) = @_;

    my $LogObject = $Kernel::OM->Get('Kernel::System::Log');

    NEEDED:
    for my $Needed (qw(DisableSysConfigs)) {

        next NEEDED if defined $Param{$Needed};

        $LogObject->Log(
            Priority => 'error',
            Message  => "Parameter '$Needed' is needed!",
        );
        return;
    }

    for my $SysConfig ( @{ $Param{DisableSysConfigs} } ) {
        $Self->ConfigSettingChange(
            Valid => 0,
            Key   => $SysConfig,
        );
    }

    return 1;
}

=head2 ProvideTestDatabase()

Provide temporary database for the test. Please first define test database settings in C<Config.pm>, i.e:

    $Self->{TestDatabase} = {
        DatabaseDSN  => 'DBI:mysql:database=otrs_test;host=127.0.0.1;',
        DatabaseUser => 'otrs_test',
        DatabasePw   => 'otrs_test',
    };

The method call will override global database configuration for duration of the test, i.e. temporary database will
receive all calls sent over system C<DBObject>.

All database contents will be automatically dropped when the Helper object is destroyed.

    $HelperObject->ProvideTestDatabase(
        DatabaseXMLString => $XML,      # (optional) database XML schema to execute
                                        # or
        DatabaseXMLFiles => [           # (optional) List of XML files to load and execute
            '/opt/otrs/scripts/database/schema.xml',
            '/opt/otrs/scripts/database/initial_insert.xml',
        ],
    );

This method returns 'undef' in case the test database is not configured. If it is configured, but the supplied XML cannot be read or executed, this method will C<die()> to interrupt the test with an error.

=cut

sub ProvideTestDatabase {
    my ( $Self, %Param ) = @_;

    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');

    my $TestDatabase = $ConfigObject->Get('TestDatabase');
    return if !$TestDatabase;

    for my $Needed (qw(DatabaseDSN DatabaseUser DatabasePw)) {
        if ( !$TestDatabase->{$Needed} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need  $Needed in TestDatabase!",
            );
            return;
        }
    }

    my %EscapedSettings;
    for my $Key (qw(DatabaseDSN DatabaseUser DatabasePw)) {

        # Override database connection settings in memory.
        $ConfigObject->Set(
            Key   => "Test$Key",
            Value => $TestDatabase->{$Key},
        );

        # Escape quotes in database settings.
        $EscapedSettings{$Key} = $TestDatabase->{$Key};
        $EscapedSettings{$Key} =~ s/'/\\'/g;
    }

    # Override database connection settings system wide.
    my $Identifier  = 'TestDatabase';
    my $PackageName = "ZZZZUnitTest$Identifier";
    $Self->CustomCodeActivate(
        Code => qq^
# OTRS config file (automatically generated)
# VERSION:1.1
package Kernel::Config::Files::$PackageName;
use strict;
use warnings;
no warnings 'redefine';
use utf8;
sub Load {
    my (\$File, \$Self) = \@_;
    \$Self->{TestDatabaseDSN}  = '$EscapedSettings{DatabaseDSN}';
    \$Self->{TestDatabaseUser} = '$EscapedSettings{DatabaseUser}';
    \$Self->{TestDatabasePw}   = '$EscapedSettings{DatabasePw}';
}
1;^,
        Identifier => $Identifier,
    );

    # Discard already instanced database object.
    $Kernel::OM->ObjectsDiscard( Objects => ['Kernel::System::DB'] );

    # Delete cache.
    $Kernel::OM->Get('Kernel::System::Cache')->CleanUp();

    $Self->{ProvideTestDatabase} = 1;

    # Clear test database.
    my $Success = $Self->TestDatabaseCleanup();
    if ( !$Success ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => 'Error clearing temporary database!',
        );
        die 'Error clearing temporary database!';
    }

    # Load supplied XML files.
    if ( IsArrayRefWithData( $Param{DatabaseXMLFiles} ) ) {
        $Param{DatabaseXMLString} //= '';

        my $Index = 0;
        my $Count = scalar @{ $Param{DatabaseXMLFiles} };

        XMLFILE:
        for my $XMLFile ( @{ $Param{DatabaseXMLFiles} } ) {
            next XMLFILE if !$XMLFile;

            # Load XML contents.
            my $XML = $Kernel::OM->Get('Kernel::System::Main')->FileRead(
                Location => $XMLFile,
            );
            if ( !$XML ) {
                $Kernel::OM->Get('Kernel::System::Log')->Log(
                    Priority => 'error',
                    Message  => "Could not load '$XMLFile'!",
                );
                die "Could not load '$XMLFile'!";
            }

            # Concatenate the file contents, but make sure to remove duplicated XML tags first.
            #   - First file should get only end tag removed.
            #   - Last file should get only start tags removed.
            #   - Any other file should get both start and end tags removed.
            $XML = ${$XML};
            if ( $Index != 0 ) {
                $XML =~ s/<\?xml .*? \?>//xm;
                $XML =~ s/<database .*? >//xm;
            }
            if ( $Index != $Count - 1 ) {
                $XML =~ s/<\/database .*? >//xm;
            }
            $Param{DatabaseXMLString} .= $XML;

            $Index++;
        }
    }

    # Execute supplied XML.
    if ( $Param{DatabaseXMLString} ) {
        my $Success = $Self->DatabaseXMLExecute( XML => $Param{DatabaseXMLString} );
        if ( !$Success ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => 'Error executing supplied XML!',
            );
            die 'Error executing supplied XML!';
        }
    }

    return 1;
}

=head2 TestDatabaseCleanup()

Clears temporary database used in the test. Always call C<ProvideTestDatabase()> called first, in
order to set it up.

Please note that all database contents will be dropped, USE WITH CARE!

    $HelperObject->TestDatabaseCleanup();

=cut

sub TestDatabaseCleanup {
    my ( $Self, %Param ) = @_;

    if ( !$Self->{ProvideTestDatabase} ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => 'Please call ProvideTestDatabase() first!',
        );
        return;
    }

    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    # Get a list of all tables in database.
    my @Tables = $DBObject->ListTables();

    if ( scalar @Tables ) {
        my $TableList = join ', ', sort @Tables;
        my $DBType    = $DBObject->{'DB::Type'};

        if ( $DBType eq 'mysql' ) {

            # Turn off checking foreign key constraints temporarily.
            $DBObject->Do( SQL => 'SET foreign_key_checks = 0' );

            # Drop all found tables in the database in same statement.
            $DBObject->Do( SQL => "DROP TABLE $TableList" );

            # Turn back on checking foreign key constraints.
            $DBObject->Do( SQL => 'SET foreign_key_checks = 1' );
        }
        elsif ( $DBType eq 'postgresql' ) {

            # Drop all found tables in the database in same statement.
            $DBObject->Do( SQL => "DROP TABLE $TableList" );
        }
        elsif ( $DBType eq 'oracle' ) {

            # Drop each found table in the database in a separate statement.
            for my $Table (@Tables) {
                $DBObject->Do( SQL => "DROP TABLE $Table CASCADE CONSTRAINTS" );
            }

            # Get complete list of user sequences.
            my @Sequences;
            return if !$DBObject->Prepare(
                SQL => 'SELECT sequence_name FROM user_sequences ORDER BY sequence_name',
            );
            while ( my @Row = $DBObject->FetchrowArray() ) {
                push @Sequences, $Row[0];
            }

            # Drop all found sequences as well.
            for my $Sequence (@Sequences) {
                $DBObject->Do( SQL => "DROP SEQUENCE $Sequence" );
            }

            # Check if all sequences have been dropped.
            @Sequences = ();
            return if !$DBObject->Prepare(
                SQL => 'SELECT sequence_name FROM user_sequences ORDER BY sequence_name',
            );
            while ( my @Row = $DBObject->FetchrowArray() ) {
                push @Sequences, $Row[0];
            }
            return if scalar @Sequences;
        }

        # Check if all tables have been dropped.
        @Tables = $DBObject->ListTables();
        return if scalar @Tables;
    }

    return 1;
}

=head2 DatabaseXMLExecute()

Execute supplied XML against current database. Content of supplied XML or XMLFilename parameter must be valid OTRS
database XML schema.

    $HelperObject->DatabaseXMLExecute(
        XML => $XML,                 # OTRS database XML schema to execute
    );

Alternatively, it can also load an XML file to execute:

    $HelperObject->DatabaseXMLExecute(
        XMLFile => '/path/to/file',  # OTRS database XML file to execute
    );

=cut

sub DatabaseXMLExecute {
    my ( $Self, %Param ) = @_;

    if ( !$Param{XML} && !$Param{XMLFile} ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => 'Need XML or XMLFile!',
        );
        return;
    }

    my $XML = $Param{XML};

    if ( !$XML ) {

        $XML = $Kernel::OM->Get('Kernel::System::Main')->FileRead(
            Location => $Param{XMLFile},
        );
        if ( !$XML ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Could not load '$Param{XMLFile}'!",
            );
            die "Could not load '$Param{XMLFile}'!";
        }
        $XML = ${$XML};
    }

    my @XMLArray = $Kernel::OM->Get('Kernel::System::XML')->XMLParse( String => $XML );
    if ( !@XMLArray ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => 'Could not parse XML!',
        );
        die 'Could not parse XML!';
    }

    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    my @SQLPre = $DBObject->SQLProcessor(
        Database => \@XMLArray,
    );
    if ( !@SQLPre ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => 'Could not generate SQL!',
        );
        die 'Could not generate SQL!';
    }

    my @SQLPost = $DBObject->SQLProcessorPost();

    for my $SQL ( @SQLPre, @SQLPost ) {
        my $Success = $DBObject->Do( SQL => $SQL );
        if ( !$Success ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => 'Database action failed: ' . $DBObject->Error(),
            );
            die 'Database action failed: ' . $DBObject->Error();
        }
    }

    return 1;
}

=head2 DynamicFieldSet()

This function will set a dynamic field value for a object.

    my $Success = $HelperObject->DynamicFieldSet(
        Field      => 'DF1',
        ObjectID   => 123,
        Value      => '123',
    );

or

    my $Success = $HelperObject->DynamicFieldSet(
        Field          => 'DF1',
        ObjectID       => 123,
        Value          => '123',
        UserID         => 123, # optional
    );

Returns:

    my $Success = 1;

=cut

sub DynamicFieldSet {
    my ( $Self, %Param ) = @_;

    my $LogObject          = $Kernel::OM->Get('Kernel::System::Log');
    my $DynamicFieldObject = $Kernel::OM->Get('Kernel::System::DynamicField');
    my $BackendObject      = $Kernel::OM->Get('Kernel::System::DynamicField::Backend');

    # check needed stuff
    NEEDED:
    for my $Needed (qw(Field ObjectID Value)) {

        next NEEDED if defined $Param{$Needed};

        $LogObject->Log(
            Priority => 'error',
            Message  => "Parameter '$Needed' is needed!",
        );
        return;
    }

    my $Field          = $Param{Field};
    my $ObjectID       = $Param{ObjectID};
    my $Value          = $Param{Value};
    my $UnitTestObject = $Param{UnitTestObject};
    my $UserID         = $Param{UserID} || 1;

    my $DynamicFieldConfig = $DynamicFieldObject->DynamicFieldGet(
        Name => $Field,
    );
    return if !IsHashRefWithData($DynamicFieldConfig);

    my $Success = $BackendObject->ValueSet(
        DynamicFieldConfig => $DynamicFieldConfig,
        ObjectID           => $ObjectID,
        Value              => $Value,
        UserID             => $UserID,
    );

    $Self->{UnitTestDriverObject}->True(
        $Success,
        "HelperObject->DynamicFieldSet('$Field', '$Value') was successful."
    );

    return $Success;
}

=head2 FixedTimeSetByDate()

This function is a convenience wrapper around the FixedTimeSet function of this object which makes it
possible to set a fixed time by using Year, Month, Day and optional Hour, Minute, Second parameters.

    $HelperObject->FixedTimeSetByDate(
        Year   => 2016,
        Month  => 4,
        Day    => 28,
        Hour   => 10, # default 0
        Minute => 0,  # default 0
        Second => 0,  # default 0
    );

=cut

sub FixedTimeSetByDate {
    my ( $Self, %Param ) = @_;

    my $LogObject = $Kernel::OM->Get('Kernel::System::Log');

    # check needed stuff
    NEEDED:
    for my $Needed (qw(Year Month Day)) {

        next NEEDED if defined $Param{$Needed};

        $LogObject->Log(
            Priority => 'error',
            Message  => "Parameter '$Needed' is needed!",
        );
        return;
    }

    for my $Default (qw(Hour Minute Second)) {
        $Param{$Default} ||= 0;
    }

    my $DateTimeObject = $Kernel::OM->Create(
        'Kernel::System::DateTime',
        ObjectParams => \%Param,
    );

    $Self->FixedTimeSet( $DateTimeObject->ToEpoch() );

    return 1;
}

=head2 FixedTimeSetByTimeStamp()

This function is a convenience wrapper around the FixedTimeSet function of this object which makes it
possible to set a fixed time by using parameters for the TimeObject TimeStamp2SystemTime function.

    $HelperObject->FixedTimeSetByTimeStamp('2004-08-14 22:45:00');

=cut

sub FixedTimeSetByTimeStamp {
    my ( $Self, $TimeStamp ) = @_;

    my $LogObject = $Kernel::OM->Get('Kernel::System::Log');

    # check needed stuff
    if ( !$TimeStamp ) {
        $LogObject->Log(
            Priority => 'error',
            Message  => "TimeStamp is needed!",
        );
        return;
    }

    my $DateTimeObject = $Kernel::OM->Create(
        'Kernel::System::DateTime',
        ObjectParams => {
            String => $TimeStamp,
        }
    );

    $Self->FixedTimeSet( $DateTimeObject->ToEpoch() );

    return 1;
}

=head2 CheckNumberOfEventExecution()

This function checks the number of executions of an Event via the TicketHistory

    my $Result = $HelperObject->CheckNumberOfEventExecution(
        TicketID => $TicketID,
        Comment  => 'after article create',
        Events   => {
            AnExampleHistoryEntry      => 2,
            AnotherExampleHistoryEntry => 0,
        },
    );

=cut

sub CheckNumberOfEventExecution {
    my ( $Self, %Param ) = @_;

    my $MainObject = $Kernel::OM->Get('Kernel::System::Main');

    my $TicketObjectLoaded = $MainObject->Require(
        'Kernel::System::Ticket',
    );

    $Self->{UnitTestDriverObject}->True(
        $TicketObjectLoaded,
        'Loaded TicketObject via MainObject',
    );

    my $TicketObject = $Kernel::OM->Get('Kernel::System::Ticket');

    my $Comment = $Param{Comment} || '';

    my @Lines = $TicketObject->HistoryGet(
        TicketID => $Param{TicketID},
        UserID   => 1,
    );

    for my $Event ( sort keys %{ $Param{Events} } ) {

        my $NumEvents = $Param{Events}->{$Event};

        my @EventLines = grep { $_->{Name} =~ m{\s*\Q$Event\E$} } @Lines;

        $Self->{UnitTestDriverObject}->Is(
            scalar @EventLines,
            $NumEvents,
            "check num of $Event events, $Comment",
        );

        # keep current number for reference
        $Param{Events}->{$Event} = scalar @EventLines;
    }

    return 1;
}

=head2 SetupTestEnvironment()

This function calls a list of other helper functions to setup a test environment with various test data.

    my $Result = $HelperObject->SetupTestEnvironment(
        ... # Parameters get passed to the FillTestEnvironment and ConfigureViews function
    );

    $Result = {
        ... # Combined result of the ActivateDefaultDynamicFields, FillTestEnvironment and ConfigureViews functions
    }

=cut

sub SetupTestEnvironment {
    my ( $Self, %Param ) = @_;

    $Self->FullFeature();

    my %Result;
    $Result{DynamicFields} = $Self->ActivateDefaultDynamicFields();

    my $TestSystemData = $Self->FillTestEnvironment(%Param);

    if ( IsHashRefWithData($TestSystemData) ) {

        %Result = (
            %Result,
            %{$TestSystemData},
        );
    }

    my $ViewData = $Self->ConfigureViews(
        AgentTicketNote => {
            Note             => 1,
            NoteMandatory    => 1,
            Owner            => 1,
            OwnerMandatory   => 1,
            Priority         => 1,
            PriorityDefault  => '3 normal',
            Queue            => 1,
            Responsible      => 1,
            Service          => 1,
            ServiceMandatory => 1,
            SLAMandatory     => 1,
            State            => 1,
            StateType        => [ 'open', 'closed', 'pending reminder', 'pending auto' ],
            TicketType       => 1,
            Title            => 1,
        },
        %Param
    );

    if ( IsHashRefWithData($ViewData) ) {

        %Result = (
            %Result,
            %{$ViewData},
        );
    }

    return \%Result;
}

=head2 ConfigureViews()

Toggles settings for a given view like AgentTicketNote or CustomerTicketMessage.

    my $Result = $HelperObject->ConfigureViews(
        AgentTicketNote => {
            Note             => 1,
            NoteMandatory    => 1,
            Owner            => 1,
            OwnerMandatory   => 1,
            Priority         => 1,
            PriorityDefault  => '3 normal',
            Queue            => 1,
            Responsible      => 1,
            Service          => 1,
            ServiceMandatory => 1,
            SLAMandatory     => 1,
            State            => 1,
            StateType        => ['open', 'closed', 'pending reminder', 'pending auto'],
            TicketType       => 1,
            Title            => 1,
        },
        CustomerTicketMessage => {
            Priority         => 1,
            Queue            => 1,
            Service          => 1,
            ServiceMandatory => 1,
            SLA              => 1,
            SLAMandatory     => 1,
            TicketType       => 1,
        },
    );

    $Result = {
        AgentTicketNote => {
            Note             => 1,
            NoteMandatory    => 1,
            Owner            => 1,
            OwnerMandatory   => 1,
            Priority         => 1,
            PriorityDefault  => '3 normal',
            Queue            => 1,
            Responsible      => 1,
            Service          => 1,
            ServiceMandatory => 1,
            SLAMandatory     => 1,
            State            => 1,
            StateType        => ['open', 'closed', 'pending reminder', 'pending auto'],
            TicketType       => 1,
            Title            => 1,
            HistoryType      => 'Phone',
            ...
        },
        CustomerTicketMessage => {
            Priority         => 1,
            Queue            => 1,
            Service          => 1,
            ServiceMandatory => 1,
            SLA              => 1,
            SLAMandatory     => 1,
            TicketType       => 1,
            ArticleType      => 'note-external',
            ...
        },
    }

=cut

sub ConfigureViews {
    my ( $Self, %Param ) = @_;

    my $ConfigObject    = $Kernel::OM->Get('Kernel::Config');
    my $SysConfigObject = $Kernel::OM->Get('Kernel::System::SysConfig');

    return if !%Param;

    my %Result;
    my @Changes;
    VIEW:
    for my $View ( sort %Param ) {

        next VIEW if !IsStringWithData($View);

        my $ConfigKey = "Ticket::Frontend::$View";
        my $OldConfig = $ConfigObject->Get($ConfigKey);
        my $NewConfig = $Param{$View};

        next VIEW if !IsHashRefWithData($OldConfig);
        next VIEW if !IsHashRefWithData($NewConfig);

        my %UpdatedConfig = (
            %{$OldConfig},
            %{$NewConfig},
        );

        for my $KeySuffix ( sort keys %{$NewConfig} ) {
            push(
                @Changes,
                {
                    Name           => $ConfigKey . '###' . $KeySuffix,
                    EffectiveValue => $NewConfig->{$KeySuffix},
                    IsValid        => 1,
                }
            );
        }

        $Result{$View} = \%UpdatedConfig;
    }

    $SysConfigObject->SettingsSet(
        Settings => \@Changes,
        UserID   => 1,
    );

    return \%Result;
}

=head2 ActivateDynamicFields()

This function activates the given DynamicFields in each agent view.

    $HelperObject->ActivateDynamicFields(
        'UnitTestDropdown',
        'UnitTestCheckbox',
        'UnitTestText',
        'UnitTestMultiSelect',
        'UnitTestTextArea',
        'UnitTestDate',
        'UnitTestDateTime',
    );

=cut

sub ActivateDynamicFields {
    my ( $Self, @DynamicFields ) = @_;

    my $ZnunyHelperObject = $Kernel::OM->Get('Kernel::System::ZnunyHelper');

    my %ActivateDynamicFields = map { $_ => 1 } @DynamicFields;

    my %Screens = (
        AgentTicketClose                              => \%ActivateDynamicFields,
        AgentTicketFreeText                           => \%ActivateDynamicFields,
        AgentTicketNote                               => \%ActivateDynamicFields,
        AgentTicketOwner                              => \%ActivateDynamicFields,
        AgentTicketPending                            => \%ActivateDynamicFields,
        AgentTicketPriority                           => \%ActivateDynamicFields,
        AgentTicketResponsible                        => \%ActivateDynamicFields,
        AgentTicketBounce                             => \%ActivateDynamicFields,
        AgentTicketCompose                            => \%ActivateDynamicFields,
        AgentTicketCustomer                           => \%ActivateDynamicFields,
        AgentTicketEmail                              => \%ActivateDynamicFields,
        AgentTicketEmailOutbound                      => \%ActivateDynamicFields,
        AgentTicketForward                            => \%ActivateDynamicFields,
        AgentTicketMerge                              => \%ActivateDynamicFields,
        AgentTicketMove                               => \%ActivateDynamicFields,
        AgentTicketPhone                              => \%ActivateDynamicFields,
        AgentTicketPhoneCommon                        => \%ActivateDynamicFields,
        AgentTicketSearch                             => \%ActivateDynamicFields,
        'AgentTicketSearch###Defaults###DynamicField' => \%ActivateDynamicFields,

    );

    $ZnunyHelperObject->_DynamicFieldsScreenEnable(%Screens);

    return 1;
}

=head2 ActivateDefaultDynamicFields()

This function adds one of each default dynamic fields to the system and activates them for each agent view.

    my $Result = $HelperObject->ActivateDefaultDynamicFields();

    $Result = [
        {
            Name          => 'UnitTestText',
            Label         => "UnitTestText",
            ObjectType    => 'Ticket',
            FieldType     => 'Text',
            InternalField => 0,
            Config        => {
                DefaultValue => '',
                Link         => '',
            },
        },
        {
            Name          => 'UnitTestCheckbox',
            Label         => "UnitTestCheckbox",
            ObjectType    => 'Ticket',
            FieldType     => 'Checkbox',
            InternalField => 0,
            Config        => {
                DefaultValue => "0",
            },
        },
        {
            Name          => 'UnitTestDropdown',
            Label         => "UnitTestDropdown",
            ObjectType    => 'Ticket',
            FieldType     => 'Dropdown',
            InternalField => 0,
            Config        => {
                PossibleValues => {
                    Key  => "Value",
                    Key1 => "Value1",
                    Key2 => "Value2",
                    Key3 => "Value3",
                },
                DefaultValue       => "Key2",
                TreeView           => '0',
                PossibleNone       => '0',
                TranslatableValues => '0',
                Link               => '',
            },
        },
        {
            Name          => 'UnitTestTextArea',
            Label         => "UnitTestTextArea",
            ObjectType    => 'Ticket',
            FieldType     => 'TextArea',
            InternalField => 0,
            Config        => {
                DefaultValue => '',
                Rows         => '',
                Cols         => '',
            },
        },
        {
            Name          => 'UnitTestMultiSelect',
            Label         => "UnitTestMultiSelect",
            ObjectType    => 'Ticket',
            FieldType     => 'Multiselect',
            InternalField => 0,
            Config        => {
                PossibleValues => {
                    Key  => "Value",
                    Key1 => "Value1",
                    Key2 => "Value2",
                    Key3 => "Value3",
                },
                DefaultValue       => "Key2",
                TreeView           => '0',
                PossibleNone       => '0',
                TranslatableValues => '0',
            },
        },
        {
            Name          => 'UnitTestDate',
            Label         => "UnitTestDate",
            ObjectType    => 'Ticket',
            FieldType     => 'Date',
            InternalField => 0,
            Config        => {
                DefaultValue  => "0",
                YearsPeriod   => "0",
                YearsInFuture => "5",
                YearsInPast   => "5",
                Link          => '',
            },
        },
        {
            Name          => 'UnitTestDateTime',
            Label         => "UnitTestDateTime",
            ObjectType    => 'Ticket',
            FieldType     => 'DateTime',
            InternalField => 0,
            Config        => {
                DefaultValue  => "0",
                YearsPeriod   => "0",
                YearsInFuture => "5",
                YearsInPast   => "5",
                Link          => '',
            },
        },
    ];

=cut

sub ActivateDefaultDynamicFields {
    my ( $Self, %Param ) = @_;

    my $ZnunyHelperObject = $Kernel::OM->Get('Kernel::System::ZnunyHelper');

    my @DynamicFields = (
        {
            Name          => 'UnitTestText',
            Label         => "UnitTestText",
            ObjectType    => 'Ticket',
            FieldType     => 'Text',
            InternalField => 0,
            Config        => {
                DefaultValue => '',
                Link         => '',
            },
        },
        {
            Name          => 'UnitTestCheckbox',
            Label         => "UnitTestCheckbox",
            ObjectType    => 'Ticket',
            FieldType     => 'Checkbox',
            InternalField => 0,
            Config        => {
                DefaultValue => "0",
            },
        },
        {
            Name          => 'UnitTestDropdown',
            Label         => "UnitTestDropdown",
            ObjectType    => 'Ticket',
            FieldType     => 'Dropdown',
            InternalField => 0,
            Config        => {
                PossibleValues => {
                    Key  => "Value",
                    Key1 => "Value1",
                    Key2 => "Value2",
                    Key3 => "Value3",
                },
                DefaultValue       => "Key2",
                TreeView           => '0',
                PossibleNone       => '0',
                TranslatableValues => '0',
                Link               => '',
            },
        },
        {
            Name          => 'UnitTestTextArea',
            Label         => "UnitTestTextArea",
            ObjectType    => 'Ticket',
            FieldType     => 'TextArea',
            InternalField => 0,
            Config        => {
                DefaultValue => '',
                Rows         => '',
                Cols         => '',
            },
        },
        {
            Name          => 'UnitTestMultiSelect',
            Label         => "UnitTestMultiSelect",
            ObjectType    => 'Ticket',
            FieldType     => 'Multiselect',
            InternalField => 0,
            Config        => {
                PossibleValues => {
                    Key  => "Value",
                    Key1 => "Value1",
                    Key2 => "Value2",
                    Key3 => "Value3",
                },
                DefaultValue       => "Key2",
                TreeView           => '0',
                PossibleNone       => '0',
                TranslatableValues => '0',
            },
        },
        {
            Name          => 'UnitTestDate',
            Label         => "UnitTestDate",
            ObjectType    => 'Ticket',
            FieldType     => 'Date',
            InternalField => 0,
            Config        => {
                DefaultValue  => "0",
                YearsPeriod   => "0",
                YearsInFuture => "5",
                YearsInPast   => "5",
                Link          => '',
            },
        },
        {
            Name          => 'UnitTestDateTime',
            Label         => "UnitTestDateTime",
            ObjectType    => 'Ticket',
            FieldType     => 'DateTime',
            InternalField => 0,
            Config        => {
                DefaultValue  => "0",
                YearsPeriod   => "0",
                YearsInFuture => "5",
                YearsInPast   => "5",
                Link          => '',
            },
        },
    );

    $ZnunyHelperObject->_DynamicFieldsCreateIfNotExists(@DynamicFields);

    my @DynamicFieldNames = map { $_->{Name} } @DynamicFields;

    $Self->{TestDynamicFields} ||= [];
    for my $DynamicFieldName (@DynamicFieldNames) {
        push @{ $Self->{TestDynamicFields} }, $DynamicFieldName;
    }

    $Self->ActivateDynamicFields(@DynamicFieldNames);

    return \@DynamicFields;
}

=head2 FullFeature()

Activates Type, Service and Responsible feature.

    $HelperObject->FullFeature();

=cut

sub FullFeature {
    my ( $Self, %Param ) = @_;

    my $SysConfigObject = $Kernel::OM->Get('Kernel::System::SysConfig');

    return $SysConfigObject->SettingsSet(
        Settings => [
            {
                Name           => 'Ticket::Type',
                IsValid        => 1,
                EffectiveValue => 1,
            },
            {
                Name           => 'Ticket::Service',
                IsValid        => 1,
                EffectiveValue => 1,
            },
            {
                Name           => 'Ticket::Responsible',
                IsValid        => 1,
                EffectiveValue => 1
            },
        ],
        UserID => 1,
    );
}

=head2 FillTestEnvironment()

Fills the system with test data. Data creation can be manipulated with own parameters passed.
Default parameters contain various special chars.

    # would do nothing -> return an empty HashRef
    my $Result = $HelperObject->FillTestEnvironment(
        User         => 0, # optional, default 5
        CustomerUser => 0, # optional, default 5
        Service      => 0, # optional, default 1 (true)
        SLA          => 0, # optional, default 1 (true)
        Type         => 0, # optional, default 1 (true)
        Queue        => 0, # optional, default 1 (true)
    );

    # create everything with defaults, except Type
    my $Result = $HelperObject->FillTestEnvironment(
        Type => {
            'Type 1::Sub Type' => 1,
            ...
        }
    );

    # create everything with defaults, except 20 agents
    my $Result = $HelperObject->FillTestEnvironment(
        User => 20,
    );

    Return structure looks like this:

    $Result = {
        User => [
        ],
        CustomerUser => [
        ],
        Queue => [
        ],
        Service => [
        ],
        SLA => [
        ],
        Type => [
        ]
    };

=cut

sub FillTestEnvironment {
    my ( $Self, %Param ) = @_;

    my $ZnunyHelperObject = $Kernel::OM->Get('Kernel::System::ZnunyHelper');
    my $ServiceObject     = $Kernel::OM->Get('Kernel::System::Service');

    # first the user creation
    my %UserTypeCountsDefault = (
        User         => 5,
        CustomerUser => 5,
    );

    my %UserTypeCounts;
    for my $UserType ( sort keys %UserTypeCountsDefault ) {

        if (
            !defined $Param{$UserType}
            || !IsPositiveInteger( $Param{$UserType} )
            )
        {
            $UserTypeCounts{$UserType} = $UserTypeCountsDefault{$UserType};
        }
        elsif ( IsPositiveInteger( $Param{$UserType} ) ) {
            $UserTypeCounts{$UserType} = $Param{$UserType};
        }
    }

    my %AdditionalUserCreateData = (
        User => {
            Groups => ['users'],
        }
    );

    my %Result;
    USERTYPE:
    for my $UserType ( sort keys %UserTypeCounts ) {

        my $UserTypeCount = $UserTypeCounts{$UserType};

        next USERTYPE if !$UserTypeCount;

        my $FunctionName = "Test${UserType}DataGet";
        $Result{$UserType} = [];

        my %CreateData;
        if ( IsHashRefWithData( $AdditionalUserCreateData{$UserType} ) ) {
            %CreateData = %{ $AdditionalUserCreateData{$UserType} };
        }

        for my $Counter ( 1 .. $UserTypeCount ) {

            my %UserTypeData = $Self->$FunctionName(%CreateData);

            push @{ $Result{$UserType} }, \%UserTypeData;
        }
    }

    # now the ticket attributes
    my %AttributeTestStructure = (
        'A::Level - 1::A'  => 0,
        'A::Level - 1::B'  => 0,
        'A::Level - 2::Ä' => 0,
        'A::Level - 2::Ö' => 0,
        'B::Level - !::Ü' => 0,
        'B::Level - !::ß' => 0,
        'B::Level - ?::Y'  => 0,
        'B::Level - ?::Z'  => 0,
        'C::Level - &::%'  => 0,
        'C::Level - &::$'  => 0,
        'C::Level - "::^'  => 0,
        'C::Level - "::\'' => 0,
        'D::Level - #::>'  => 0,
        'D::Level - #::<'  => 0,
        'D::Level - "::+'  => 0,
        'D::Level - "::='  => 0,
        'E::Level - *::@'  => 0,
        'E::Level - *::"'  => 0,
        'E::Level - "::()' => 0,
        'E::Level - "::{}' => 0,
        'F'                => 0,
    );

    my %WantedTicketAttributes;
    my @PossibleTicketAttributes = qw(Service SLA Type Queue);
    for my $WantedTicketAttribute (@PossibleTicketAttributes) {

        if (
            !defined $Param{$WantedTicketAttribute}
            || !IsHashRefWithData( $Param{$WantedTicketAttribute} )
            )
        {
            my %TmpAttributeTestStructure = %AttributeTestStructure;
            $WantedTicketAttributes{$WantedTicketAttribute} = \%TmpAttributeTestStructure;
        }
        elsif ( IsHashRefWithData( $Param{$WantedTicketAttribute} ) ) {
            $WantedTicketAttributes{$WantedTicketAttribute} = $Param{$WantedTicketAttribute};
        }
    }

    my %AdditionalAttributeCreateData = (
        Queue => {
            GroupID => 1,    # users
        },
        SLA => {
            ServiceIDs => [],
        },
    );

    ATTRIBUTE:
    for my $Attribute (@PossibleTicketAttributes) {

        next ATTRIBUTE if !IsHashRefWithData( $WantedTicketAttributes{$Attribute} );

        my %AttributeCreateData = %{ $WantedTicketAttributes{$Attribute} };

        my %AttributeResultData;
        ITEM:
        for my $AttributeCreateItem ( sort keys %AttributeCreateData ) {

            my $AttributeEntry = "$Attribute $AttributeCreateItem";
            my $FunctionName   = "_${Attribute}CreateIfNotExists";

            my %CreateData = (
                Name => $AttributeEntry,
            );
            if ( IsHashRefWithData( $AdditionalAttributeCreateData{$Attribute} ) ) {

                %CreateData = (
                    %CreateData,
                    %{ $AdditionalAttributeCreateData{$Attribute} },
                );
            }

            $AttributeResultData{$AttributeEntry} = $ZnunyHelperObject->$FunctionName(%CreateData);
        }

        $Result{$Attribute} = \%AttributeResultData;

        next ATTRIBUTE if $Attribute ne 'Service';

        my %ServiceList = $ServiceObject->ServiceList(
            UserID => 1,
        );
        my @ServiceIDs = keys %ServiceList;

        $AdditionalAttributeCreateData{SLA}->{ServiceIDs} = \@ServiceIDs;

        # add services as defalut service for all customers
        for my $ServiceID (@ServiceIDs) {

            $ServiceObject->CustomerUserServiceMemberAdd(
                CustomerUserLogin => '<DEFAULT>',
                ServiceID         => $ServiceID,
                Active            => 1,
                UserID            => 1,
            );
        }
    }

    return \%Result;
}

=head2 TestUserDataGet()

Calls TestUserCreate and returns the whole UserData instead only the Login.

    my %UserData = $HelperObject->TestUserDataGet(
        Groups => ['admin', 'users'],           # optional, list of groups to add this user to (rw rights)
        Language => 'de'                        # optional, defaults to 'en' if not set
    );

    %UserData = {
        UserID        => 2,
        UserFirstname => $TestUserLogin,
        UserLastname  => $TestUserLogin,
        UserLogin     => $TestUserLogin,
        UserPw        => $TestUserLogin,
        UserEmail     => $TestUserLogin . '@localunittest.com',
    }

=cut

sub TestUserDataGet {
    my ( $Self, %Param ) = @_;

    my $UserObject = $Kernel::OM->Get('Kernel::System::User');

    # create test user and login
    $Self->TestUserCreate(%Param);

    # return user data of last created user
    return $UserObject->GetUserData(
        UserID => $Self->{TestUsers}->[-1],
    );
}

=head2 TestCustomerUserDataGet()

Calls TestCustomerUserCreate and returns the whole CustomerUserData instead only the Login.

    my %CustomerUserData = $HelperObject->TestCustomerUserDataGet(
        Language => 'de' # optional, defaults to 'en' if not set
    );

    %CustomerUserData = {
        CustomerUserID => 1,
        Source         => 'CustomerUser',
        UserFirstname  => $TestUserLogin,
        UserLastname   => $TestUserLogin,
        UserCustomerID => $TestUserLogin,
        UserLogin      => $TestUserLogin,
        UserPassword   => $TestUserLogin,
        UserEmail      => $TestUserLogin . '@localunittest.com',
        ValidID        => 1,
    }

=cut

sub TestCustomerUserDataGet {
    my ( $Self, %Param ) = @_;

    my $CustomerUserObject = $Kernel::OM->Get('Kernel::System::CustomerUser');

    # create test user and login
    $Self->TestCustomerUserCreate(%Param);

    # return customer user data of last created customer user
    return $CustomerUserObject->CustomerUserDataGet(
        User => $Self->{TestCustomerUsers}->[-1],
    );
}

=head2 TicketCreate()

Creates a Ticket with dummy data and tests the creation. All Ticket attributes are optional.

    my $TicketID = $HelperObject->TicketCreate();

    is equals:

    my $TicketID = $HelperObject->TicketCreate(
        Title        => 'UnitTest ticket',
        Queue        => 'Raw',
        Lock         => 'unlock',
        Priority     => '3 normal',
        State        => 'new',
        CustomerID   => 'UnitTestCustomer',
        CustomerUser => 'customer@example.com',
        OwnerID      => 1,
        UserID       => 1,
    );

    To overwrite:

    my $TicketID = $HelperObject->TicketCreate(
        CustomerUser => 'another_customer@example.com',
    );

    Result:
    $TicketID = 1337;

=cut

sub TicketCreate {
    my ( $Self, %Param ) = @_;

    my $MainObject = $Kernel::OM->Get('Kernel::System::Main');

    my $TicketObjectLoaded = $MainObject->Require(
        'Kernel::System::Ticket',
    );

    $Self->{UnitTestDriverObject}->True(
        $TicketObjectLoaded,
        'Loaded TicketObject via MainObject',
    );

    my $TicketObject = $Kernel::OM->Get('Kernel::System::Ticket');

    my %TicketAttributes = (
        Title        => 'UnitTest ticket',
        Queue        => 'Raw',
        Lock         => 'unlock',
        Priority     => '3 normal',
        State        => 'new',
        CustomerID   => 'UnitTestCustomer',
        CustomerUser => 'customer@example.com',
        OwnerID      => 1,
        UserID       => 1,
        %Param,
    );

    # create test ticket
    my $TicketID = $TicketObject->TicketCreate(%TicketAttributes);

    $Self->{UnitTestDriverObject}->True(
        $TicketID,
        "Ticket '$TicketAttributes{Title}' is created - ID $TicketID",
    );

    # store for later cleanup
    $Self->{TestTickets} ||= [];
    push @{ $Self->{TestTickets} }, $TicketID;

    return $TicketID;
}

=head2 ArticleCreate()

Creates an Article with dummy data and tests the creation. All Article attributes except the TicketID are optional.

    my $ArticleID = $HelperObject->ArticleCreate(
        TicketID => 1337,
    );

    is equals:

    my $ArticleID = $HelperObject->ArticleCreate(
        TicketID       => 1337,
        ArticleType    => 'note-internal',
        SenderType     => 'agent',
        Subject        => 'UnitTest subject test',
        Body           => 'UnitTest body test',
        ContentType    => 'text/plain; charset=ISO-8859-15',
        HistoryType    => 'OwnerUpdate',
        HistoryComment => 'Some free text!',
        UserID         => 1,
        NoAgentNotify  => 1,
    );

    To overwrite:

    my $ArticleID = $HelperObject->ArticleCreate(
        TicketID   => 1337,
        SenderType => 'customer',
    );

    Result:
    $ArticleID = 1337;

=cut

sub ArticleCreate {
    my ( $Self, %Param ) = @_;

    my $MainObject = $Kernel::OM->Get('Kernel::System::Main');

    my $TicketObjectLoaded = $MainObject->Require(
        'Kernel::System::Ticket::Article',
    );

    $Self->{UnitTestDriverObject}->True(
        $TicketObjectLoaded,
        'Loaded ArticleObject via MainObject',
    );

    my $ArticleObject = $Kernel::OM->Get('Kernel::System::Ticket::Article');

    my %ArticleAttributes = (
        IsVisibleForCustomer => 0,
        ChannelName          => 'Internal',
        SenderType           => 'agent',
        Subject              => 'UnitTest subject test',
        Body                 => 'UnitTest body test',
        ContentType          => 'text/plain; charset=ISO-8859-15',
        HistoryType          => 'OwnerUpdate',
        HistoryComment       => 'Some free text!',
        UserID               => 1,
        NoAgentNotify        => 1,
        %Param,
    );

    # create test ticket
    my $ArticleID = $ArticleObject->ArticleCreate(%ArticleAttributes);

    $Self->{UnitTestDriverObject}->True(
        $ArticleID,
        "Article '$ArticleAttributes{Subject}' is created - ID $ArticleID",
    );

    return $ArticleID;
}

=head2 TestUserPreferencesSet()

Sets preferences for a given Login or UserID

    my $Success = $HelperObject->TestUserPreferencesSet(
        UserID      => 123,
        Preferences => {                  # "Preferences" hashref is required
            OutOfOffice  => 1,            # example Key -> Value pair for User Preferences
            UserMobile   => undef,        # example for deleting a UserPreferences Key's value
            UserLanguage => '',           # example for deleting a UserPreferences Key's value
        },
    );

=cut

sub TestUserPreferencesSet {
    my ( $Self, %Param ) = @_;

    return if !$Param{UserID};
    return if !IsHashRefWithData( $Param{Preferences} );

    my $UserObject = $Kernel::OM->Get('Kernel::System::User');

    for my $Key ( sort keys %{ $Param{Preferences} } ) {

        $UserObject->SetPreferences(
            Key    => $Key,
            Value  => $Param{Preferences}->{$Key} // '',
            UserID => $Param{UserID},
        );
    }

    return 1;
}

=head2 PostMaster()

This functions reads in a given file and calls the PostMaster on it. It returns the result of the PostMaster.

    my @Result = $HelperObject->PostMaster(
        Location => $ConfigObject->Get('Home') . '/scripts/test/sample/Sample-1.box',
    );

    @Result = (1, $TicketID);

=cut

sub PostMaster {
    my ( $Self, %Param ) = @_;

    my $LogObject  = $Kernel::OM->Get('Kernel::System::Log');
    my $MainObject = $Kernel::OM->Get('Kernel::System::Main');

    # check needed stuff
    NEEDED:
    for my $Needed (qw(Location)) {

        next NEEDED if defined $Param{$Needed};

        $LogObject->Log(
            Priority => 'error',
            Message  => "Parameter '$Needed' is needed!",
        );
        return;
    }

    my $FileArray = $MainObject->FileRead(
        Location => $Param{Location},
        Result   => 'ARRAY',
    );

    my $CommunicationLogObject = $Kernel::OM->Create(
        'Kernel::System::CommunicationLog',
        ObjectParams => {
            Transport => 'Email',
            Direction => 'Incoming',
        },
    );
    $CommunicationLogObject->ObjectLogStart( ObjectLogType => 'Message' );

    my $PostMasterObject = Kernel::System::PostMaster->new(
        CommunicationLogObject => $CommunicationLogObject,
        Email                  => $FileArray,
    );

    return $PostMasterObject->Run();
}

=head2 DatabaseXML()

This function takes a file location of a XML file, generates and executes the SQL

    my $Success = $HelperObject->DatabaseXML(
        Location => $ConfigObject->Get('Home') . '/scripts/development/db/schema.xml',
    );

or string

    my $Success = $HelperObject->DatabaseXML(
        String => '...',
    );

Returns:

    my $Success = 1;

=cut

sub DatabaseXML {
    my ( $Self, %Param ) = @_;

    my $MainObject = $Kernel::OM->Get('Kernel::System::Main');
    my $LogObject  = $Kernel::OM->Get('Kernel::System::Log');
    my $DBObject   = $Kernel::OM->Get('Kernel::System::DB');
    my $XMLObject  = $Kernel::OM->Get('Kernel::System::XML');

    # check needed stuff
    if ( !$Param{String} && !$Param{Location} ) {
        $LogObject->Log(
            Priority => 'error',
            Message  => "Parameter 'String' or 'Location' is needed!",
        );
        return;
    }

    my $XML;
    if ( $Param{String} ) {

        # use params as data
        $XML = $Param{String};
    }
    else {

        # read file
        $XML = $MainObject->FileRead(
            Location => $Param{Location},
        );
    }

    # convert to array
    my @XMLArray = $XMLObject->XMLParse( String => $XML );

    my @SQL = $DBObject->SQLProcessor(
        Database => \@XMLArray,
    );

    for my $SQL (@SQL) {
        return if !$DBObject->Do( SQL => $SQL );
    }

    my @SQLPost = $DBObject->SQLProcessorPost();

    for my $SQL (@SQLPost) {
        return if !$DBObject->Do( SQL => $SQL );
    }

    return 1;
}

=head2 ConsoleCommand()

This is a helper function for executing ConsoleCommands without the hassle.

    my $Result = $HelperObject->ConsoleCommand(
        CommandModule => 'Kernel::System::Console::Command::Maint::Cache::Delete',
    );

    # or

    my $Result = $HelperObject->ConsoleCommand(
        CommandModule => 'Kernel::System::Console::Command::Maint::Cache::Delete',
        Parameter     => [ '--type', 'Znuny' ],
    );

    # or

    my $Result = $HelperObject->ConsoleCommand(
        CommandModule => 'Kernel::System::Console::Command::Help',
        Parameter     => 'Lis',
    );

    $Result = {
        ExitCode => 0,      # or 1 in case of an error
        STDOUT   => '...',
        STDERR   => undef,
    }

=cut

sub ConsoleCommand {
    my ( $Self, %Param ) = @_;

    my $EncodeObject = $Kernel::OM->Get('Kernel::System::Encode');

    $Self->{UnitTestDriverObject}->True(
        scalar IsStringWithData( $Param{CommandModule} ),
        'Command module given.',
    ) || return;

    my $CommandObject = $Kernel::OM->Get( $Param{CommandModule} );

    $Self->{UnitTestDriverObject}->Is(
        ref $CommandObject,
        $Param{CommandModule},
        "CommandObject created from module name '$Param{CommandModule}'",
    ) || return;

    if ( IsStringWithData( $Param{Parameter} ) ) {
        $Param{Parameter} = [ $Param{Parameter} ];
    }
    elsif ( !IsArrayRefWithData( $Param{Parameter} ) ) {
        $Param{Parameter} = [];
    }

    my %Result;
    {
        local *STDOUT;
        local *STDERR;
        open STDOUT, '>:encoding(UTF-8)', \$Result{STDOUT};
        open STDERR, '>:encoding(UTF-8)', \$Result{STDERR};

        $Result{ExitCode} = $CommandObject->Execute( @{ $Param{Parameter} } );

        $EncodeObject->EncodeInput( \$Result{STDOUT} );
        $EncodeObject->EncodeInput( \$Result{STDERR} );
    }

    return \%Result;
}

=head2 ACLValuesGet()

This is a helper function get shown values of fields or actions after ACL restrictions

Examples:

    my %Result = $HelperObject->ACLValuesGet(
        Check    => 'Action',
        UserID   => $UserID,
        %TicketACLParams,   # see TicketACL.pm
    );

    my %Result = $HelperObject->ACLValuesGet(
        Check    => 'DynamicField_Test',
        UserID   => $UserID,
        %TicketACLParams,   # see TicketACL.pm
    );

    my %Result = $HelperObject->ACLValuesGet(
        Check  => 'Queue',
        UserID => $UserID,
        %TicketACLParams,   # see TicketACL.pm
    );

    my %Result = $HelperObject->ACLValuesGet(
        Check  => 'Type',
        UserID => $UserID,
        %TicketACLParams,   # see TicketACL.pm
    );

    my %Result = $HelperObject->ACLValuesGet(
        Check  => 'State',
        UserID => $UserID,
        %TicketACLParams,   # see TicketACL.pm
    );

    my %Result = $HelperObject->ACLValuesGet(
        Check  => 'Service',
        UserID => $UserID,
        %TicketACLParams,   # see TicketACL.pm
    );

    my %Result = $HelperObject->ACLValuesGet(
        Check  => 'Priority',
        UserID => $UserID,
        %TicketACLParams,   # see TicketACL.pm
    );

    my %Result = $HelperObject->ACLValuesGet(
        Check  => 'SLA',
        UserID => $UserID,
        %TicketACLParams,   # see TicketACL.pm
    );

=cut

sub ACLValuesGet {
    my ( $Self, %Param ) = @_;

    my $BackendObject      = $Kernel::OM->Get('Kernel::System::DynamicField::Backend');
    my $ConfigObject       = $Kernel::OM->Get('Kernel::Config');
    my $DynamicFieldObject = $Kernel::OM->Get('Kernel::System::DynamicField');
    my $TicketObject       = $Kernel::OM->Get('Kernel::System::Ticket');

    my $Check = $Param{Check};

    my %Result;
    if ( $Check =~ m{\ADynamicField_}xmsi ) {

        # get dynamic field config
        my $Field = $Check;
        $Field =~ s{\ADynamicField_}{}xmsi;

        my $DynamicFieldConfig = $DynamicFieldObject->DynamicFieldGet(
            Name => $Field,
        );

        # get PossibleValues
        my $PossibleValuesFilter;
        my $PossibleValues = $BackendObject->PossibleValuesGet(
            DynamicFieldConfig => $DynamicFieldConfig,
        );

        # check if field has PossibleValues property in its configuration
        if ( IsHashRefWithData($PossibleValues) ) {

            # convert possible values key => value to key => key for ACLs using a Hash slice
            my %AclData = %{$PossibleValues};
            @AclData{ keys %AclData } = keys %AclData;

            # set possible values filter from ACLs
            my $ACL = $TicketObject->TicketAcl(
                %Param,
                Data          => \%AclData,
                ReturnType    => 'Ticket',
                ReturnSubType => 'DynamicField_' . $DynamicFieldConfig->{Name},
            );

            if ($ACL) {
                my %Filter = $TicketObject->TicketAclData();

                # convert Filer key => key back to key => value using map
                %{$PossibleValuesFilter} = map { $_ => $PossibleValues->{$_} }
                    keys %Filter;
            }
        }

        if ( !IsHashRefWithData($PossibleValuesFilter) ) {
            %Result = %{ $PossibleValues || {} };
        }
        else {
            %Result = %{ $PossibleValuesFilter || {} };
        }
    }
    elsif ( $Check eq 'Action' ) {

        # get all registered Actions
        my %PossibleActions;
        my $Counter = 0;
        if ( ref $ConfigObject->Get('Frontend::Module') eq 'HASH' ) {

            my %Actions = %{ $ConfigObject->Get('Frontend::Module') };

            # only use those Actions that stats with Agent
            %PossibleActions = map { ++$Counter => $_ }
                grep { substr( $_, 0, length 'Agent' ) eq 'Agent' }
                sort keys %Actions;
        }

        my $ACL = $TicketObject->TicketAcl(
            %Param,
            Data          => \%PossibleActions,
            ReturnType    => 'Action',
            ReturnSubType => '-',
        );

        %Result = reverse %PossibleActions;
        if ($ACL) {
            %Result = reverse $TicketObject->TicketAclActionData();
        }
    }
    elsif ( $Check eq 'Queue' ) {
        %Result = reverse $TicketObject->TicketMoveList(%Param);
    }
    elsif ( $Check eq 'Type' ) {
        %Result = reverse $TicketObject->TicketTypeList(%Param);
    }
    elsif ( $Check eq 'State' ) {
        %Result = reverse $TicketObject->TicketStateList(%Param);
    }
    elsif ( $Check eq 'Service' ) {
        %Result = reverse $TicketObject->TicketServiceList(%Param);
    }
    elsif ( $Check eq 'Priority' ) {
        %Result = reverse $TicketObject->TicketPriorityList(%Param);
    }
    elsif ( $Check eq 'SLA' ) {
        %Result = reverse $TicketObject->TicketSLAList(%Param);
    }

    return %Result;
}

=head2 UnitTestObjectGet()

Returns the correct unit test object.

OTRS 4.0.27 introduced a new module Kernel::System::UnitTest::Driver.
The unit test functions like True, False, etc. were moved to this module.

=cut

sub UnitTestObjectGet {
    my ( $Self, %Param ) = @_;

    my $MainObject = $Kernel::OM->Get('Kernel::System::Main');

    my $UnitTestDriverAvailable = $MainObject->Require(
        'Kernel::System::UnitTest::Driver',
        Silent => 1,
    );
    if ($UnitTestDriverAvailable) {
        return $Kernel::OM->Get('Kernel::System::UnitTest::Driver');
    }

    return $Kernel::OM->Get('Kernel::System::UnitTest');
}

1;

=head1 TERMS AND CONDITIONS

This software is part of the OTRS project (L<https://otrs.org/>).

This software comes with ABSOLUTELY NO WARRANTY. For details, see
the enclosed file COPYING for license information (GPL). If you
did not receive this file, see L<https://www.gnu.org/licenses/gpl-3.0.txt>.

=cut
