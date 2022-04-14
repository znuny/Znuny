# --
# Copyright (C) 2021-2022 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package scripts::Migration::Znuny6_3::MigrateMailAccountDatabaseTable;    ## no critic

use strict;
use warnings;

use parent qw(scripts::Migration::Base);

use Kernel::System::VariableCheck qw(:all);

our @ObjectDependencies = (
    'Kernel::System::DB',
    'Kernel::System::MailAccount',
);

sub Run {
    my ( $Self, %Param ) = @_;

    my $DBObject          = $Kernel::OM->Get('Kernel::System::DB');
    my $MailAccountObject = $Kernel::OM->Get('Kernel::System::MailAccount');

    my @XML;

    #
    # Add missing columns to table mail_account.
    #
    my $AuthenticationTypeColumnExists = $Self->ColumnExists(
        Table  => 'mail_account',
        Column => 'authentication_type',
    );
    if ( !$AuthenticationTypeColumnExists ) {
        push @XML, '
            <TableAlter Name="mail_account">
                <ColumnAdd Name="authentication_type" Required="false" Size="100" Default="password" Type="VARCHAR"/>
            </TableAlter>
        ';
    }

    # See issue #236: Fixed error that default value "password" was set
    # for column "account_type" instead of "authentication_type".
    push @XML, '
        <TableAlter Name="mail_account">
            <ColumnChange NameOld="account_type" NameNew="account_type" Required="true" Size="20" Type="VARCHAR"/>
        </TableAlter>
    ';
    push @XML, '
        <TableAlter Name="mail_account">
            <ColumnChange NameOld="authentication_type" NameNew="authentication_type" Required="false" Size="100" Default="password" Type="VARCHAR"/>
        </TableAlter>
    ';

    my $OAuth2TokenConfigIDColumnExists = $Self->ColumnExists(
        Table  => 'mail_account',
        Column => 'oauth2_token_config_id',
    );
    if ( !$OAuth2TokenConfigIDColumnExists ) {
        push @XML, '
            <TableAlter Name="mail_account">
                <ColumnAdd Name="oauth2_token_config_id" Required="false" Type="INTEGER"/>
                <ForeignKeyCreate ForeignTable="oauth2_token_config">
                    <Reference Local="oauth2_token_config_id" Foreign="id"/>
                </ForeignKeyCreate>
            </TableAlter>
        ';
    }

    if (@XML) {
        return if !$Self->ExecuteXMLDBArray(
            XMLArray => \@XML,
        );
    }

    #
    # Set column authentication_type for all mail accounts to "password" by default.
    # But only if column didn't exist yet. Leave existing records as they are.
    #
    if ( !$AuthenticationTypeColumnExists ) {
        my $SQL = '
            UPDATE mail_account
            SET    authentication_type = ?
        ';

        my @Bind = (
            \'password',
        );

        return if !$DBObject->Do(
            SQL  => $SQL,
            Bind => \@Bind,
        );

        # Change column authentication_type to be required.
        @XML = ( '
            <TableAlter Name="mail_account">
                <ColumnChange NameOld="authentication_type" NameNew="authentication_type" Required="true" Size="100" Default="password" Type="VARCHAR"/>
            </TableAlter>
        ' );

        return if !$Self->ExecuteXMLDBArray(
            XMLArray => \@XML,
        );
    }

    #
    # Set authentication type and OAuth2 token config IDs from existing
    # database backend table z4o_mail_account, if present.
    #
    my $MailAccountDatabaseBackendTableExists = $Self->TableExists( Table => 'z4o_mail_account' );
    return 1 if !$MailAccountDatabaseBackendTableExists;

    my $SQL = '
        SELECT mail_account_id, authentication_type, oauth2_token_config_id
        FROM   z4o_mail_account
    ';

    return if !$DBObject->Prepare(
        SQL => $SQL,
    );

    my %Znuny4OTRSMailAccountData;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        $Znuny4OTRSMailAccountData{ $Row[0] } = {
            AuthenticationType  => $Row[1],
            OAuth2TokenConfigID => $Row[2],
        };
    }

    MAILACCOUNTID:
    for my $MailAccountID ( sort keys %Znuny4OTRSMailAccountData ) {
        my %MailAccount = $MailAccountObject->MailAccountGet(
            ID => $MailAccountID,
        );

        next MAILACCOUNTID if !%MailAccount;

        $MailAccountObject->MailAccountUpdate(
            %MailAccount,
            UserID              => 1,
            AuthenticationType  => $Znuny4OTRSMailAccountData{$MailAccountID}->{AuthenticationType},
            OAuth2TokenConfigID => $Znuny4OTRSMailAccountData{$MailAccountID}->{OAuth2TokenConfigID},
        );
    }

    #
    # Drop database backend table z4o_mail_account, if present.
    #
    @XML = ( '
        <TableDrop Name="z4o_mail_account" />
    ' );

    return if !$Self->ExecuteXMLDBArray(
        XMLArray => \@XML,
    );

    return 1;
}

1;
