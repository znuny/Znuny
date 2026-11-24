# --
# Copyright (C) 2021 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package scripts::Migration::Znuny::UpgradeDatabaseStructure::ServiceCustomerCompany;    ## no critic

use strict;
use warnings;

use utf8;

use parent qw(scripts::Migration::Base);

our @ObjectDependencies;

sub Run {
    my ( $Self, %Param ) = @_;

    return if !$Self->_CreateServiceCustomerCompanyTable(%Param);

    return 1;
}

sub _CreateServiceCustomerCompanyTable {
    my ( $Self, %Param ) = @_;

    my @XMLStrings = (
        '<Table Name="service_customer_company">
            <Column Name="id" Required="true" PrimaryKey="true" AutoIncrement="true" Type="BIGINT"/>
            <Column Name="customer_id" Required="true" Size="200" Type="VARCHAR"/>
            <Column Name="service_id" Required="true" Type="INTEGER"/>
            <Column Name="create_time" Required="true" Type="DATE"/>
            <Column Name="create_by" Required="true" Type="INTEGER"/>
            <Index Name="service_customer_company_customer_id">
                <IndexColumn Name="customer_id" Size="10"/>
            </Index>
            <Index Name="service_customer_company_service_id">
                <IndexColumn Name="service_id"/>
            </Index>
            <ForeignKey ForeignTable="service">
                <Reference Local="service_id" Foreign="id"/>
            </ForeignKey>
            <ForeignKey ForeignTable="users">
                <Reference Local="create_by" Foreign="id"/>
            </ForeignKey>
        </Table>',
        '<TableAlter Name="service_customer_company">
            <ColumnAdd Name="id" Required="true" PrimaryKey="true" AutoIncrement="true" Type="BIGINT"/>
        </TableAlter>',
    );

    return if !$Self->ExecuteXMLDBArray(
        XMLArray => \@XMLStrings,
    );

    return 1;
}

1;
