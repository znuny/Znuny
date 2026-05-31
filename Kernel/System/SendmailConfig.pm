# --
# Copyright (C) 2021 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::SendmailConfig;

use strict;
use warnings;

use utf8;

use Kernel::System::VariableCheck qw(:all);

our @ObjectDependencies = (
    'Kernel::Config',
    'Kernel::System::Cache',
    'Kernel::System::DB',
    'Kernel::System::JSON',
    'Kernel::System::Log',
    'Kernel::System::Main',
    'Kernel::System::OAuth2TokenConfig',
);

=head1 PUBLIC INTERFACE

=head2 new()

Don't use the constructor directly, use the ObjectManager instead:

    my $SendmailConfigObject = $Kernel::OM->Get('Kernel::System::SendmailConfig');

=cut

sub new {
    my ( $Type, %Param ) = @_;

    my $Self = {};
    bless( $Self, $Type );

    $Self->{CacheType} = 'SendmailConfig';
    $Self->{CacheTTL}  = 60 * 60 * 24 * 20;

    return $Self;
}

=head2 Add()

Adds a new sendmail config.

    my $SendmailConfigID = $SendmailConfigObject->Add(
        SendmailModule      => 'SMTPTLS',
        CMD                 => '/usr/bin/sendmail...',
        Host                => 'smtp.example.org',
        Port                => 587,
        Timeout             => 30,
        SkipSSLVerification => 0,
        IsFallbackConfig    => 0,
        AuthenticationType  => 'oauth2_token',
        AuthUser            => 'mail',
        AuthPassword        => undef,
        OAuth2TokenConfigID => 2,
        EmailAddresses      => [ # Only stored/needed if IsFallbackConfig is false
            'znuny@example.org',
            'znuny2@example.org',
        ],
        Comments => 'Comment', # optional
        ValidID  => 1,
        UserID   => 3,
    );

Returns:

    my $SendmailConfigID = 4;

=cut

sub Add {
    my ( $Self, %Param ) = @_;

    my $LogObject  = $Kernel::OM->Get('Kernel::System::Log');
    my $DBObject   = $Kernel::OM->Get('Kernel::System::DB');
    my $JSONObject = $Kernel::OM->Get('Kernel::System::JSON');

    NEEDED:
    for my $Needed (qw(ValidID UserID)) {
        next NEEDED if IsStringWithData( $Param{$Needed} );

        $LogObject->Log(
            Priority => 'error',
            Message  => "$Needed not defined!",
        );
        return;
    }

    my %ValidatedParams = $Self->_EvaluateParams(%Param);
    return if !%ValidatedParams;

    my $SQL = '
        INSERT INTO sendmail_config (
            sendmail_module, cmd, host, port, timeout, skip_ssl_verification,
            is_fallback_config, authentication_type, auth_user, auth_password,
            oauth2_token_config_id, email_addresses, comments, valid_id,
            create_time, create_by, change_time, change_by
        )
        VALUES (
            ?, ?, ?, ?, ?, ?,
            ?, ?, ?, ?,
            ?, ?, ?, ?,
            current_timestamp, ?, current_timestamp, ?
        )
    ';

    my @Bind = (
        \$ValidatedParams{SendmailModule},
        \$ValidatedParams{CMD},
        \$ValidatedParams{Host},
        \$ValidatedParams{Port},
        \$ValidatedParams{Timeout},
        \$ValidatedParams{SkipSSLVerification},
        \$ValidatedParams{IsFallbackConfig},
        \$ValidatedParams{AuthenticationType},
        \$ValidatedParams{AuthUser},
        \$ValidatedParams{AuthPassword},
        \$ValidatedParams{OAuth2TokenConfigID},
        \$ValidatedParams{EmailAddresses},
        \$ValidatedParams{Comments},
        \$ValidatedParams{ValidID},
        \$ValidatedParams{UserID},
        \$ValidatedParams{UserID},
    );

    return if !$DBObject->Do(
        SQL  => $SQL,
        Bind => \@Bind,
    );

    $Self->_ClearCaches();

    #
    # Figure out ID of created record
    #
    my %ColumnByParam = (
        CMD                 => 'cmd',
        Host                => 'host',
        Port                => 'port',
        Timeout             => 'timeout',
        SkipSSLVerification => 'skip_ssl_verification',
        IsFallbackConfig    => 'is_fallback_config',
        AuthenticationType  => 'authentication_type',
        AuthUser            => 'auth_user',
        AuthPassword        => 'auth_password',
        OAuth2TokenConfigID => 'oauth2_token_config_id',
        EmailAddresses      => 'email_addresses',
        Comments            => 'comments',
    );

    $SQL = '
        SELECT id
        FROM   sendmail_config
        WHERE  sendmail_module = ?
               AND valid_id = ?
               AND create_by = ?
               AND change_by = ?
    ';
    @Bind = (
        \$ValidatedParams{SendmailModule},
        \$ValidatedParams{ValidID},
        \$ValidatedParams{UserID},
        \$ValidatedParams{UserID},
    );

    for my $Param ( sort keys %ColumnByParam ) {
        my $Column = $ColumnByParam{$Param};

        if ( defined $ValidatedParams{$Param} ) {
            $SQL .= " AND $Column = ?";

            push @Bind, \$ValidatedParams{$Param};
        }
        else {
            $SQL .= " AND $Column IS NULL";
        }
    }

    $SQL .= ' ORDER BY id desc';

    return if !$DBObject->Prepare(
        SQL   => $SQL,
        Bind  => \@Bind,
        Limit => 1,
    );

    my $ID;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        $ID = $Row[0];
    }

    # If this is the new fallback config, remove fallback flag for all existing sendmail configs.
    if ( $Param{IsFallbackConfig} ) {
        return if !$DBObject->Prepare(
            SQL  => 'UPDATE sendmail_config SET is_fallback_config = 0 WHERE id != ?',
            Bind => [
                \$ID,
            ],
        );
    }

    return $ID;
}

=head2 Update()

Updates a sendmail config.

    my $UpdateSuccessful = $SendmailConfigObject->Update(
        ID                  => 5,
        SendmailModule      => 'SMTPTLS',
        CMD                 => '/usr/bin/sendmail...',
        Host                => 'smtp.example.org',
        Port                => 587,
        Timeout             => 30,
        SkipSSLVerification => 0,
        IsFallbackConfig    => 0,
        AuthenticationType  => 'oauth2_token',
        AuthUser            => 'mail',
        AuthPassword        => undef,
        OAuth2TokenConfigID => 2,
        EmailAddresses      => [ # Only stored/needed if IsFallbackConfig is false
            'znuny@example.org',
            'znuny2@example.org',
        ],
        Comments => 'Comment', # optional
        ValidID  => 1,
        UserID   => 3,
    );

Returns:

    my $UpdateSuccessful = 1;

=cut

sub Update {
    my ( $Self, %Param ) = @_;

    my $LogObject  = $Kernel::OM->Get('Kernel::System::Log');
    my $DBObject   = $Kernel::OM->Get('Kernel::System::DB');
    my $JSONObject = $Kernel::OM->Get('Kernel::System::JSON');

    NEEDED:
    for my $Needed (qw(ID ValidID UserID)) {
        next NEEDED if IsStringWithData( $Param{$Needed} );

        $LogObject->Log(
            Priority => 'error',
            Message  => "$Needed not defined!",
        );
        return;
    }

    my %ValidatedParams = $Self->_EvaluateParams(%Param);

    my $SQL = '
        UPDATE sendmail_config
        SET    sendmail_module = ?,
               cmd = ?,
               host = ?,
               port = ?,
               timeout = ?,
               skip_ssl_verification = ?,
               is_fallback_config = ?,
               authentication_type = ?,
               auth_user = ?,
               auth_password = ?,
               oauth2_token_config_id = ?,
               email_addresses = ?,
               comments = ?,
               valid_id = ?,
               change_time = current_timestamp,
               change_by = ?
        WHERE  id = ?
    ';

    my @Bind = (
        \$ValidatedParams{SendmailModule},
        \$ValidatedParams{CMD},
        \$ValidatedParams{Host},
        \$ValidatedParams{Port},
        \$ValidatedParams{Timeout},
        \$ValidatedParams{SkipSSLVerification},
        \$ValidatedParams{IsFallbackConfig},
        \$ValidatedParams{AuthenticationType},
        \$ValidatedParams{AuthUser},
        \$ValidatedParams{AuthPassword},
        \$ValidatedParams{OAuth2TokenConfigID},
        \$ValidatedParams{EmailAddresses},
        \$ValidatedParams{Comments},
        \$ValidatedParams{ValidID},
        \$ValidatedParams{UserID},
        \$ValidatedParams{ID},
    );

    return if !$DBObject->Do(
        SQL  => $SQL,
        Bind => \@Bind,
    );

    # If this is the new fallback config, remove fallback flag for all existing sendmail configs.
    if ( $Param{IsFallbackConfig} ) {
        return if !$DBObject->Prepare(
            SQL  => 'UPDATE sendmail_config SET is_fallback_config = 0 WHERE id != ?',
            Bind => [
                \$Param{ID},
            ],
        );
    }

    $Self->_ClearCaches();

    return 1;
}

=head2 Delete()

Deletes a sendmail config.

    my $SendmailConfigDeleted = $SendmailConfigObject->Delete(
        ID => 123,
    );

Returns:

    my $SendmailConfigDeleted = 1;

=cut

sub Delete {
    my ( $Self, %Param ) = @_;

    my $LogObject = $Kernel::OM->Get('Kernel::System::Log');
    my $DBObject  = $Kernel::OM->Get('Kernel::System::DB');

    NEEDED:
    for my $Needed (qw(ID)) {
        next NEEDED if IsStringWithData( $Param{$Needed} );

        $LogObject->Log(
            Priority => 'error',
            Message  => "$Needed not defined!",
        );
        return;
    }

    my $SQL = '
        DELETE FROM sendmail_config
        WHERE       id = ?
    ';

    my @Bind = (
        \$Param{ID},
    );

    return if !$DBObject->Do(
        SQL  => $SQL,
        Bind => \@Bind,
    );

    $Self->_ClearCaches();

    return 1;
}

=head2 Get()

Returns the sendmail config for the given ID.

    my $SendmailConfig = $SendmailConfigObject->Get(
        ID => 4,
    );

Returns:

    my $SendmailConfig = {
        ID                    => 123,
        SendmailModule        => 'SMTPTLS',
        CMD                   => '/usr/bin/sendmail...',
        Host                  => 'smtp.example.org',
        Port                  => 587,
        Timeout               => 30,
        SkipSSLVerification   => 0,
        IsFallbackConfig      => 0,
        AuthenticationType    => 'oauth2_token',
        AuthUser              => 'mail',
        AuthPassword          => undef,
        OAuth2TokenConfigID   => 2,
        OAuth2TokenConfigName => '...',
        EmailAddresses        => [
            'znuny@example.org',
            'znuny2@example.org',
        ],
        Comments   => 'Comment',
        ValidID    => 1,
        CreateTime => '2025-08-29 12:34:56',
        ChangeTime => '2025-08-29 15:12:09',
    };

=cut

sub Get {
    my ( $Self, %Param ) = @_;

    my $LogObject               = $Kernel::OM->Get('Kernel::System::Log');
    my $DBObject                = $Kernel::OM->Get('Kernel::System::DB');
    my $JSONObject              = $Kernel::OM->Get('Kernel::System::JSON');
    my $CacheObject             = $Kernel::OM->Get('Kernel::System::Cache');
    my $OAuth2TokenConfigObject = $Kernel::OM->Get('Kernel::System::OAuth2TokenConfig');

    NEEDED:
    for my $Needed (qw(ID)) {
        next NEEDED if $Param{$Needed};

        $LogObject->Log(
            Priority => 'error',
            Message  => "Parameter $Needed has to be given.",
        );
        return;
    }

    my $CacheKey = "Get::$Param{ID}";
    my $Cache    = $CacheObject->Get(
        Type => $Self->{CacheType},
        Key  => $CacheKey,
    );
    return $Cache if defined $Cache;

    my $SQL = '
        SELECT  id, sendmail_module, cmd, host, port, timeout, skip_ssl_verification,
                is_fallback_config, authentication_type, auth_user, auth_password,
                oauth2_token_config_id, email_addresses, comments, valid_id,
                create_time, change_time
        FROM    sendmail_config
        WHERE   id = ?
    ';

    my @Bind = (
        \$Param{ID},
    );

    return if !$DBObject->Prepare(
        SQL   => $SQL,
        Bind  => \@Bind,
        Limit => 1,
    );

    my %SendmailConfig;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        my $EmailAddresses           = [];
        my $EmailAddressesJSONString = $Row[12];
        if ( IsStringWithData($EmailAddressesJSONString) ) {
            $EmailAddresses = $JSONObject->Decode(
                Data => $EmailAddressesJSONString,
            );
        }

        %SendmailConfig = (
            ID                    => $Row[0],
            SendmailModule        => $Row[1],
            CMD                   => $Row[2],
            Host                  => $Row[3],
            Port                  => $Row[4],
            Timeout               => $Row[5],
            SkipSSLVerification   => $Row[6],
            IsFallbackConfig      => $Row[7],
            AuthenticationType    => $Row[8],
            AuthUser              => $Row[9],
            AuthPassword          => $Row[10],
            OAuth2TokenConfigID   => $Row[11],
            OAuth2TokenConfigName => undef,
            EmailAddresses        => $EmailAddresses,
            Comments              => $Row[13],
            ValidID               => $Row[14],
            CreateTime            => $Row[15],
            ChangeTime            => $Row[16],
        );
    }
    return if !%SendmailConfig;

    # Fetch OAuth2 token config names because SQL queries cannot be nested
    # because of "fetchrow_array failed: fetch() without execute()"
    if ( $SendmailConfig{OAuth2TokenConfigID} ) {
        my %OAuth2TokenConfig = $OAuth2TokenConfigObject->DataGet(
            ID     => $SendmailConfig{OAuth2TokenConfigID},
            UserID => 1,
        );

        if (%OAuth2TokenConfig) {
            $SendmailConfig{OAuth2TokenConfigName} = $OAuth2TokenConfig{Name};
        }
    }

    $CacheObject->Set(
        Type  => $Self->{CacheType},
        TTL   => $Self->{CacheTTL},
        Key   => $CacheKey,
        Value => \%SendmailConfig,
    );

    return \%SendmailConfig;
}

=head2 GetAll()

Returns all sendmail configurations, sorted by ID.

    my $SendmailConfigs = $SendmailConfigObject->GetAll();

Returns:

    my $SendmailConfigs = [
        {
            ID                    => 123,
            SendmailModule        => 'SMTPTLS',
            CMD                   => '/usr/bin/sendmail...',
            Host                  => 'smtp.example.org',
            Port                  => 587,
            Timeout               => 30,
            SkipSSLVerification   => 0,
            IsFallbackConfig      => 0,
            AuthenticationType    => 'oauth2_token',
            AuthUser              => 'mail',
            AuthPassword          => undef,
            OAuth2TokenConfigID   => 2,
            OAuth2TokenConfigName => '...',
            EmailAddresses        => [
                'znuny@example.org',
                'znuny2@example.org',
            ],
            Comments   => 'Comment',
            ValidID    => 1,
            CreateTime => '2025-08-29 12:34:56',
            ChangeTime => '2025-08-29 15:12:09',
        },
        # ...
    ];

=cut

sub GetAll {
    my ( $Self, %Param ) = @_;

    my $DBObject                = $Kernel::OM->Get('Kernel::System::DB');
    my $JSONObject              = $Kernel::OM->Get('Kernel::System::JSON');
    my $CacheObject             = $Kernel::OM->Get('Kernel::System::Cache');
    my $OAuth2TokenConfigObject = $Kernel::OM->Get('Kernel::System::OAuth2TokenConfig');

    my $CacheKey = 'GetAll';
    my $Cache    = $CacheObject->Get(
        Type => $Self->{CacheType},
        Key  => $CacheKey,
    );
    return $Cache if defined $Cache;

    my $SQL = '
        SELECT    id, sendmail_module, cmd, host, port, timeout, skip_ssl_verification,
                  is_fallback_config, authentication_type, auth_user, auth_password,
                  oauth2_token_config_id, email_addresses, comments, valid_id,
                  create_time, change_time
        FROM      sendmail_config
        ORDER BY  id ASC
    ';

    return if !$DBObject->Prepare(
        SQL => $SQL,
    );

    my @SendmailConfigs;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        my $EmailAddresses           = [];
        my $EmailAddressesJSONString = $Row[12];
        if ( IsStringWithData($EmailAddressesJSONString) ) {
            $EmailAddresses = $JSONObject->Decode(
                Data => $EmailAddressesJSONString,
            );
        }

        push @SendmailConfigs, {
            ID                    => $Row[0],
            SendmailModule        => $Row[1],
            CMD                   => $Row[2],
            Host                  => $Row[3],
            Port                  => $Row[4],
            Timeout               => $Row[5],
            SkipSSLVerification   => $Row[6],
            IsFallbackConfig      => $Row[7],
            AuthenticationType    => $Row[8],
            AuthUser              => $Row[9],
            AuthPassword          => $Row[10],
            OAuth2TokenConfigID   => $Row[11],
            OAuth2TokenConfigName => undef,
            EmailAddresses        => $EmailAddresses,
            Comments              => $Row[13],
            ValidID               => $Row[14],
            CreateTime            => $Row[15],
            ChangeTime            => $Row[16],
        };
    }

    # Fetch OAuth2 token config names because SQL queries cannot be nested
    # because of "fetchrow_array failed: fetch() without execute()"
    SENDMAILCONFIG:
    for my $SendmailConfig (@SendmailConfigs) {
        next SENDMAILCONFIG if !$SendmailConfig->{OAuth2TokenConfigID};

        my %OAuth2TokenConfig = $OAuth2TokenConfigObject->DataGet(
            ID     => $SendmailConfig->{OAuth2TokenConfigID},
            UserID => 1,
        );

        if (%OAuth2TokenConfig) {
            $SendmailConfig->{OAuth2TokenConfigName} = $OAuth2TokenConfig{Name};
        }
    }

    $CacheObject->Set(
        Type  => $Self->{CacheType},
        TTL   => $Self->{CacheTTL},
        Key   => $CacheKey,
        Value => \@SendmailConfigs,
    );

    return \@SendmailConfigs;
}

=head2 GetByEmailAddress()

Returns the sendmail config for the given email address.

    my $SendmailConfig = $SendmailConfigObject->GetByEmailAddress(
        EmailAddress => 'znuny@example.org',

        # optional, defaults to 0:
        # Return fallback config (if any) if no config found for email address
        UseFallback => 1,
    );

Returns:

    my $SendmailConfig = {
        ID                  => 123,
        SendmailModule      => 'SMTPTLS',
        CMD                 => '/usr/bin/sendmail...',
        Host                => 'smtp.example.org',
        Port                => 587,
        Timeout             => 30,
        SkipSSLVerification => 0,
        IsFallbackConfig    => 0,
        AuthenticationType  => 'oauth2_token',
        AuthUser            => 'mail',
        AuthPassword        => undef,
        OAuth2TokenConfigID => 2,
        EmailAddresses      => [
            'znuny@example.org',
            'znuny2@example.org',
        ],
        Comments   => 'Comment',
        ValidID    => 1,
        CreateTime => '2025-08-29 12:34:56',
        ChangeTime => '2025-08-29 15:12:09',
    };

=cut

sub GetByEmailAddress {
    my ( $Self, %Param ) = @_;

    my $LogObject = $Kernel::OM->Get('Kernel::System::Log');

    NEEDED:
    for my $Needed (qw(EmailAddress)) {
        next NEEDED if $Param{$Needed};

        $LogObject->Log(
            Priority => 'error',
            Message  => "Parameter $Needed has to be given.",
        );
        return;
    }

    my $SendmailConfigs = $Self->GetAll() // [];
    return if !IsArrayRefWithData($SendmailConfigs);

    my ($SendmailConfig) = grep {
        grep { lc($_) eq lc( $Param{EmailAddress} ) } @{ $_->{EmailAddresses} // [] }
    } @{$SendmailConfigs};
    return $SendmailConfig if IsHashRefWithData($SendmailConfig);

    return if !$Param{UseFallback};

    return $Self->GetFallback();
}

=head2 GetFallback()

Returns the fallback sendmail config (if one is configured).

    my $FallbackSendmailConfig = $SendmailConfigObject->GetFallback();

Returns:

    my $FallbackSendmailConfig = {
        ID                  => 123,
        SendmailModule      => 'SMTPTLS',
        CMD                 => '/usr/bin/sendmail...',
        Host                => 'smtp.example.org',
        Port                => 587,
        Timeout             => 30,
        SkipSSLVerification => 0,
        IsFallbackConfig    => 1,
        AuthenticationType  => 'oauth2_token',
        AuthUser            => 'mail',
        AuthPassword        => undef,
        OAuth2TokenConfigID => 2,
        EmailAddresses      => [],
        Comments            => 'Comment',
        ValidID             => 1,
        CreateTime          => '2025-08-29 12:34:56',
        ChangeTime          => '2025-08-29 15:12:09',
    };

=cut

sub GetFallback {
    my ( $Self, %Param ) = @_;

    my $SendmailConfigs = $Self->GetAll() // [];
    return if !IsArrayRefWithData($SendmailConfigs);

    my ($FallbackSendmailConfig) = grep { $_->{IsFallbackConfig} } @{$SendmailConfigs};
    return $FallbackSendmailConfig if IsHashRefWithData($FallbackSendmailConfig);

    return;
}

=head2 GetAvailableSendmailModules()

Returns a list of available modules for sending mails (without the MultiSendmail module) and their
available config options for the config dialog.

    my $SendmailModules = $SendmailConfigObject->GetAvailableSendmailModules();

    my $Modules = {
        SMTP => {
            Host => {
                Required     => 1,
                DefaultValue => undef,
            },
            # ...
        },
        SMTPTLS => {
            Host => {
                Required     => 1,
                DefaultValue => undef,
            },
            Port => {
                Required     => 0,
                DefaultValue => undef,
            },
            # ...
        },
        # ...
    ];

=cut

sub GetAvailableSendmailModules {
    my ( $Self, %Param ) = @_;

    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');
    my $MainObject   = $Kernel::OM->Get('Kernel::System::Main');

    my $Directory = $ConfigObject->Get('Home') . '/Kernel/System/Email/';

    my @ModuleFilePaths = $MainObject->DirectoryRead(
        Directory => $Directory,
        Filter    => '*.pm',
    );

    my %ModulesToIgnore = (
        Base          => 1,
        MultiSendmail => 1,
        MultiSMTP     => 1,
        Test          => 1,
    );

    my %Modules;
    MODULEFILEPATH:
    for my $ModuleFilePath (@ModuleFilePaths) {
        next MODULEFILEPATH if $ModuleFilePath !~ m{\A.*/(.+?)\.pm\z};
        my $ModuleName = $1;

        # Ignore specific modules.
        next MODULEFILEPATH if $ModulesToIgnore{$ModuleName};

        my $PackageName     = "Kernel::System::Email::$ModuleName";
        my $PackageRequired = $MainObject->Require(
            $PackageName,
            Silent => 1,
        );
        next MODULEFILEPATH if !$PackageRequired;

        my $EmailObject = $Kernel::OM->Get($PackageName);

        my $ConfigOptions = {};
        if ( $EmailObject->can('GetAvailableConfigOptions') ) {
            $ConfigOptions = $EmailObject->GetAvailableConfigOptions();
        }

        $Modules{$ModuleName} = $ConfigOptions;
    }

    return \%Modules;
}

=head2 GetSenderEmailAddresses()

Returns email addresses that are available to be selected for sendmail configs.
Optionally only returns those not yet used in any sendmail config.

    my $EmailAddresses = $SendmailConfigObject->GetSenderEmailAddresses(

        # optional; only those not used in any sendmail config
        OnlyUnused => 1,

        # optional together with OnlyUnused: Also return email addresses already selected in given sendmail config
        KeepForSendmailConfigID => 6,
    );

    my $EmailAddresses = {
        'system@example.org' => 'system@example.org (Admin Znuny)',
        # ...
    };

=cut

sub GetSenderEmailAddresses {
    my ( $Self, %Param ) = @_;

    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');
    my $DBObject     = $Kernel::OM->Get('Kernel::System::DB');

    my $SQL = '
        SELECT value0, value1
        FROM   system_address
    ';
    return if !$DBObject->Prepare(
        SQL => $SQL,
    );

    my %SenderEmailAddresses;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        my $EmailAddress = lc $Row[0];
        my $Name         = $Row[1];
        $SenderEmailAddresses{$EmailAddress} = "$EmailAddress ($Name)";
    }

    my $EmailAddressConfigOptions = $ConfigObject->Get('SendmailConfig::EmailAddress::ConfigOptions') // [];

    CONFIGOPTION:
    for my $ConfigOption ( @{$EmailAddressConfigOptions} ) {
        my $EmailAddress = lc( $ConfigObject->Get($ConfigOption) // '' );

        next CONFIGOPTION if !IsStringWithData($EmailAddress);
        next CONFIGOPTION if $SenderEmailAddresses{$EmailAddress};

        $SenderEmailAddresses{$EmailAddress} = "$EmailAddress ($ConfigOption)";
    }

    # Optionally filter out the ones already used in any sendmail config.
    my $OnlyUnused = $Param{OnlyUnused} // 0;
    return \%SenderEmailAddresses if !$OnlyUnused;

    my $SendmailConfigs = $Self->GetAll() // [];
    SENDMAILCONFIG:
    for my $SendmailConfig ( @{$SendmailConfigs} ) {
        next SENDMAILCONFIG if $Param{KeepForSendmailConfigID}
            && $SendmailConfig->{ID} == $Param{KeepForSendmailConfigID};

        EMAILADDRESS:
        for my $EmailAddress ( @{ $SendmailConfig->{EmailAddresses} || [] } ) {
            next EMAILADDRESS if !exists $SenderEmailAddresses{ lc $EmailAddress };
            delete $SenderEmailAddresses{ lc $EmailAddress };
        }
    }

    return \%SenderEmailAddresses;
}

=head2 GetAuthenticationTypes()

Returns the available authentication types.

    my $AuthenticationTypes = $SendmailConfigObject->GetAuthenticationTypes();

Returns:

    my $AuthenticationTypes = {
        # authentication type => name
        password              => 'Password',
        oauth2_token          => 'OAuth2 token',
    };

=cut

sub GetAuthenticationTypes {
    my ( $Self, %Param ) = @_;

    my %AuthenticationTypes = (
        password     => 'Password',
        oauth2_token => 'OAuth2 token',
    );

    return \%AuthenticationTypes;
}

=head2 _ClearCaches()

Clears all sendmail config caches.

    $SendmailConfigObject->_ClearCaches();

=cut

sub _ClearCaches {
    my ( $Self, %Param ) = @_;

    my $CacheObject = $Kernel::OM->Get('Kernel::System::Cache');

    $CacheObject->CleanUp(
        Type => $Self->{CacheType},
    );

    return 1;
}

=head2 _EvaluateParams()

Checks if the given param combination is valid and clears unneeded params
depending on given combination of params.

    my $Params = $SendmailConfigObject->_EvaluateParams(
        SendmailModule      => 'SMTPTLS',
        CMD                 => '/usr/bin/sendmail...',
        Host                => 'smtp.example.org',
        Port                => 587,
        Timeout             => 30,
        SkipSSLVerification => 0,
        IsFallbackConfig    => 0,
        AuthenticationType  => 'oauth2_token',
        AuthUser            => 'mail',
        AuthPassword        => undef,
        OAuth2TokenConfigID => 2,
        EmailAddresses      => [ # Only stored/needed if IsFallbackConfig is false
            'znuny@example.org',
            'znuny2@example.org',
        ],
        Comments => 'Comment', # optional
        ValidID  => 1,
        UserID   => 3,
    );

    Returns validated and cleaned up params hash, ready for storing in DB.
    On error, returns false value and logs the error.

=cut

sub _EvaluateParams {
    my ( $Self, %Param ) = @_;

    my $LogObject  = $Kernel::OM->Get('Kernel::System::Log');
    my $JSONObject = $Kernel::OM->Get('Kernel::System::JSON');

    NEEDED:
    for my $Needed (qw(SendmailModule)) {
        next NEEDED if IsStringWithData( $Param{$Needed} );

        $LogObject->Log(
            Priority => 'error',
            Message  => "$Needed not defined!",
        );
        return;
    }

    my $SendmailModules             = $Self->GetAvailableSendmailModules();
    my $SendmailModuleConfigOptions = $SendmailModules->{ $Param{SendmailModule} } // {};

    # First, clear options that must not be set for the selected sendmail module
    for my $Option (qw(CMD Host Port Timeout SkipSSLVerification AuthenticationType)) {
        $Param{$Option} = undef if !exists $SendmailModuleConfigOptions->{$Option};
        $Param{$Option} = undef if !IsStringWithData( $Param{$Option} );
    }

    my $AuthenticationType = $Param{AuthenticationType};
    if ( IsStringWithData($AuthenticationType) ) {
        if ( $AuthenticationType !~ m{\Apassword|oauth2_token\z} ) {
            $LogObject->Log(
                Priority => 'error',
                Message  => "Parameter 'AuthenticationType' has to be either 'password' or 'oauth2_token'.",
            );
            return;
        }

        my $AuthConfigOptions
            = $SendmailModuleConfigOptions->{AuthenticationType}->{PossibleValues}->{$AuthenticationType} // {};

        # Clear credential options that are not used for the selected authentication type
        for my $AuthOption (qw(AuthUser AuthPassword OAuth2TokenConfigID)) {
            $Param{$AuthOption} = undef if !exists $AuthConfigOptions->{$AuthOption};
        }

        AUTHOPTION:
        for my $AuthOption ( sort keys %{$AuthConfigOptions} ) {
            my $IsRequired = $AuthConfigOptions->{$AuthOption}->{Required};
            next AUTHOPTION if !$IsRequired;
            next AUTHOPTION if IsStringWithData( $Param{$AuthOption} );

            $LogObject->Log(
                Priority => 'error',
                Message  => "Parameter '$AuthOption' has to be given.",
            );
            return;
        }
    }
    else {

        # Clear credential options when no authentication type has been given
        for my $AuthOption (qw(AuthUser AuthPassword OAuth2TokenConfigID)) {
            $Param{$AuthOption} = undef;
        }
    }

    if (
        IsStringWithData( $Param{Port} )
        && (
            $Param{Port} !~ m{\A[1-9]\d?\d?\d?\d?\z}
            || $Param{Port} > 65535
        )
        )
    {
        $LogObject->Log(
            Priority => 'error',
            Message  => "Parameter 'Port' has to be a number between 1 and 65535.",
        );
        return;
    }

    if (
        IsStringWithData( $Param{Timeout} )
        && $Param{Timeout} !~ m{\A[1-9]\d?\d?\z}
        )
    {
        $LogObject->Log(
            Priority => 'error',
            Message  => "Parameter 'Timeout' has to be a number between 1 and 999.",
        );
        return;
    }

    if (
        !$Param{IsFallbackConfig}
        && !IsArrayRefWithData( $Param{EmailAddresses} )
        )
    {
        $LogObject->Log(
            Priority => 'error',
            Message  => "Parameter 'EmailAddresses' has to be given if 'IsFallbackConfig' is set to 1.",
        );
        return;
    }

    # Flags
    $Param{SkipSSLVerification} = $Param{SkipSSLVerification} ? 1 : undef;
    $Param{IsFallbackConfig}    = $Param{IsFallbackConfig}    ? 1 : undef;

    # Clear values that are not needed.
    $Param{EmailAddresses} = undef if $Param{IsFallbackConfig};
    $Param{Comments}       = undef if !IsStringWithData( $Param{Comments} );

    my $EmailAddressesJSONString = undef;
    if ( IsArrayRefWithData( $Param{EmailAddresses} ) ) {
        $EmailAddressesJSONString = $JSONObject->Encode(
            Data => $Param{EmailAddresses},
        );
    }
    $Param{EmailAddresses} = $EmailAddressesJSONString;

    return %Param;
}

1;
