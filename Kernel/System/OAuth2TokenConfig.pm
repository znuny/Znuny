# --
# Copyright (C) 2021-2022 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --
package Kernel::System::OAuth2TokenConfig;

use strict;
use warnings;

use Kernel::System::VariableCheck qw(:all);

our @ObjectDependencies = (
    'Kernel::Config',
    'Kernel::System::MailAccount',
    'Kernel::System::OAuth2Token',
);

use parent qw(Kernel::System::DBCRUD);

=head1 NAME

Kernel::System::OAuth2TokenConfig - OAuth2TokenConfig lib

=head1 SYNOPSIS

All OAuth2TokenConfig functions

=head1 PUBLIC INTERFACE

=head2 new()

create an object

    my $OAuth2TokenConfigObject = $Kernel::OM->Get('Kernel::System::OAuth2TokenConfig');

=cut

=head2 InitConfig()

init config for object

    my $Success = $OAuth2TokenConfigObject->InitConfig();

Returns:

    my $Success = 1;

=cut

sub InitConfig {
    my ( $Self, %Param ) = @_;

    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');

    $Self->{Columns} = {
        ID => {
            Column       => 'id',
            SearchTarget => 0,
        },
        Name => {
            Column       => 'name',
            SearchTarget => 0,
            ImportID     => 1,
        },
        Config => {
            Column       => 'config',
            SearchTarget => 0,
            ContentJSON  => 1,
            DisableWhere => 1,
        },
        ValidID => {
            Column       => 'valid_id',
            SearchTarget => 0,
        },
        CreateTime => {
            Column       => 'create_time',
            SearchTarget => 0,
            TimeStampAdd => 1,
        },
        CreateBy => {
            Column       => 'create_by',
            SearchTarget => 0,
        },
        ChangeTime => {
            Column          => 'change_time',
            SearchTarget    => 0,
            TimeStampUpdate => 1,
            TimeStampAdd    => 1,
        },
        ChangeBy => {
            Column       => 'change_by',
            SearchTarget => 0,
        },
    };

    # base table configuration
    $Self->{Name}           = 'OAuth2TokenConfig';
    $Self->{Identifier}     = 'ID';
    $Self->{DatabaseTable}  = 'oauth2_token_config';
    $Self->{DefaultSortBy}  = 'Name';
    $Self->{DefaultOrderBy} = 'ASC';
    $Self->{CacheType}      = 'OAuth2TokenConfig';
    $Self->{CacheTTL}       = $ConfigObject->Get( 'DBCRUD::' . $Self->{Name} . '::CacheTTL' ) || 60 * 60 * 8;

    $Self->{UserIDCheck} = 1;

    $Self->{AutoCreateMissingUUIDDatabaseTableColumns} = 1;

    # base function activation
    $Self->{FunctionDataAdd}           = 1;
    $Self->{FunctionDataUpdate}        = 1;
    $Self->{FunctionDataGet}           = 1;
    $Self->{FunctionDataListGet}       = 1;
    $Self->{FunctionDataDelete}        = 1;
    $Self->{FunctionDataSearch}        = 1;
    $Self->{FunctionDataExport}        = 1;
    $Self->{FunctionDataImport}        = 1;
    $Self->{HistoryFunctionDataUpdate} = 0;

    return 1;
}

sub DataDelete {
    my ( $Self, %Param ) = @_;

    my $OAuth2TokenObject = $Kernel::OM->Get('Kernel::System::OAuth2Token');

    # Delete token
    if ( defined $Param{ $Self->{Identifier} } ) {
        my $TokenDeleted = $OAuth2TokenObject->DataDelete(
            TokenConfigID => $Param{ $Self->{Identifier} },
            UserID        => $Param{UserID},
        );
        return if !$TokenDeleted;
    }

    return $Self->SUPER::DataDelete(%Param);
}

=head2 UsedOAuth2TokenConfigListGet()

Returns a list of used OAuth2 token configs as array.

    my @UsedOAuth2TokenConfigListGet = $OAuth2TokenConfigObject->UsedOAuth2TokenConfigListGet(
        Scope => 'MailAccount'      # optional, default 'undef', (MailAccount);
    );

Returns:

    my @UsedOAuth2TokenConfigListGet = (
        {
            ID      => 1,
            Scope   => 'MailAccount',
            ScopeID => '1',
            Name    => 'Google Mail Token Config',
            Config  => {
                ClientID      => 2,
                Scope         => https://mail.google.com/,
                ClientSecret  => 3,
                TemplateName  => Google Mail
                Notifications => {
                    NotifyOnExpiredRefreshToken => 1,
                    NotifyOnExpiredToken        => 1
                },
            },
            ValidID    => 1,
            CreateTime => 2016-04-16 12:34:56,
            CreateBy   => 1,
            ChangeTime => 2016-04-16 12:34:56,
            ChangeBy   => 1,
        },
    );

=cut

sub UsedOAuth2TokenConfigListGet {
    my ( $Self, %Param ) = @_;

    my %UsedOAuth2TokenConfigIDs;
    my @UsedOAuth2TokenConfigListGet;

    if ( !$Param{Scope} || $Param{Scope} eq 'MailAccount' ) {

        my $MailAccountObject = $Kernel::OM->Get('Kernel::System::MailAccount');
        my @MailAccounts      = $MailAccountObject->MailAccountGetAll();

        MAILACCOUNT:
        for my $MailAccount (@MailAccounts) {

            next MAILACCOUNT if !$MailAccount->{OAuth2TokenConfigID};

            $UsedOAuth2TokenConfigIDs{MailAccount}->{ $MailAccount->{ID} } = $MailAccount->{OAuth2TokenConfigID};
        }
    }

    return if !%UsedOAuth2TokenConfigIDs;

    my @OAuth2TokenConfigs = $Self->DataListGet(
        UserID => 1,
    );

    return if !@OAuth2TokenConfigs;

    for my $Scope ( sort keys %UsedOAuth2TokenConfigIDs ) {
        CONFIG:
        for my $ScopeID ( sort keys %{ $UsedOAuth2TokenConfigIDs{$Scope} } ) {

            my $OAuth2TokenConfigID = $UsedOAuth2TokenConfigIDs{$Scope}->{$ScopeID};

            my ($Config) = grep { $OAuth2TokenConfigID eq $_->{ID} } @OAuth2TokenConfigs;

            next CONFIG if !$Config;

            my %Config = %{$Config};

            $Config{Scope}   = $Scope;
            $Config{ScopeID} = $ScopeID;

            push @UsedOAuth2TokenConfigListGet, \%Config;
        }
    }
    return @UsedOAuth2TokenConfigListGet;
}

1;
