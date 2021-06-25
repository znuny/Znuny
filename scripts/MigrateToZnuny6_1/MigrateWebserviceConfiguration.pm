# --
# Copyright (C) 2021 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --
## nofilter(TidyAll::Plugin::OTRS::Perl::Pod::NamePod)

package scripts::MigrateToZnuny6_1::MigrateWebserviceConfiguration;    ## no critic

use strict;
use warnings;

use parent qw(scripts::MigrateToZnuny6_1::Base);

use Kernel::System::VariableCheck qw(:all);

our @ObjectDependencies = (
    'Kernel::Config',
    'Kernel::System::DB',
    'Kernel::System::GenericInterface::Webservice',
    'Kernel::System::ZnunyHelper',
);

=head1 NAME

Migrate web service configuration.

=cut

sub Run {
    my ( $Self, %Param ) = @_;

    $Self->_MigrateConfiguredInvokerTypes(%Param);
    $Self->_MigrateWebserviceNames(%Param);
    $Self->_CreateMissingWebservices(%Param);

    return 1;
}

sub _MigrateConfiguredInvokerTypes {
    my ( $Self, %Param ) = @_;

    my $WebserviceObject = $Kernel::OM->Get('Kernel::System::GenericInterface::Webservice');

    my $Webservices = $WebserviceObject->WebserviceList(
        Valid => 0,
    );
    return 1 if !IsHashRefWithData($Webservices);

    my %InvokerTypeMapping = (
        'Znuny4OTRSAdvanced::Generic' => 'Znuny::Generic',
        'Znuny4OTRSAdvanced::Tunnel'  => 'Znuny::Tunnel',
    );

    WEBSERVICEID:
    for my $WebserviceID ( sort keys %{$Webservices} ) {
        my $WebserviceData = $WebserviceObject->WebserviceGet(
            ID => $WebserviceID,
        );
        next WEBSERVICEID if !IsHashRefWithData($WebserviceData);

        # Migrate web service invoker types.
        if ( IsHashRefWithData( $WebserviceData->{Config}->{Requester}->{Invoker} ) ) {
            INVOKER:
            for my $Invoker ( sort keys %{ $WebserviceData->{Config}->{Requester}->{Invoker} } ) {
                my $InvokerConfig = $WebserviceData->{Config}->{Requester}->{Invoker}->{$Invoker};
                next INVOKER if !defined $InvokerConfig->{Type};
                next INVOKER if !exists $InvokerTypeMapping{ $InvokerConfig->{Type} };

                $InvokerConfig->{Type} = $InvokerTypeMapping{ $InvokerConfig->{Type} };
            }
        }

        $WebserviceObject->WebserviceUpdate(
            ID      => $WebserviceID,
            Name    => $WebserviceData->{Name},
            Config  => $WebserviceData->{Config},
            ValidID => $WebserviceData->{ValidID},
            UserID  => 1,
        );
    }

    return 1;
}

sub _MigrateWebserviceNames {
    my ( $Self, %Param ) = @_;

    my $DBObject         = $Kernel::OM->Get('Kernel::System::DB');
    my $WebserviceObject = $Kernel::OM->Get('Kernel::System::GenericInterface::Webservice');

    my $Webservices = $WebserviceObject->WebserviceList(
        Valid => 0,
    );
    return 1 if !IsHashRefWithData($Webservices);

    my %WebserviceIDsByName = reverse %{$Webservices};

    my %WebserviceNameMapping = (
        'Znuny4OTRS-TimeAccountingWebservice' => 'TimeAccounting',
    );

    CURRENTWEBSERVICENAME:
    for my $CurrentWebserviceName ( sort keys %WebserviceNameMapping ) {

        # No web service with matching name found.
        next CURRENTWEBSERVICENAME if !$WebserviceIDsByName{$CurrentWebserviceName};

        my $NewWebserviceName = $WebserviceNameMapping{$CurrentWebserviceName};

        # A web service with the new name already exists.
        if ( $WebserviceIDsByName{$NewWebserviceName} ) {
            print
                "        Web service $CurrentWebserviceName cannot be renamed to $NewWebserviceName because this name is already used by another web service.\n";
            next CURRENTWEBSERVICENAME;
        }

        # Rename web service.
        my $RenamingOK = $DBObject->Do(
            SQL => '
                UPDATE gi_webservice_config SET name = ?
                WHERE id = ?
            ',
            Bind => [
                \$NewWebserviceName,
                \$WebserviceIDsByName{$CurrentWebserviceName},
            ],
        );

        next CURRENTWEBSERVICENAME if $RenamingOK;

        print "        Error renaming web service $CurrentWebserviceName to $NewWebserviceName.\n";
    }

    return 1;
}

sub _CreateMissingWebservices {
    my ( $Self, %Param ) = @_;

    my $ConfigObject      = $Kernel::OM->Get('Kernel::Config');
    my $WebserviceObject  = $Kernel::OM->Get('Kernel::System::GenericInterface::Webservice');
    my $ZnunyHelperObject = $Kernel::OM->Get('Kernel::System::ZnunyHelper');

    my $Webservices = $WebserviceObject->WebserviceList(
        Valid => 0,
    ) // {};

    my %WebserviceIDsByName = reverse %{$Webservices};

    my $Home = $ConfigObject->Get('Home');

    my %WebservicesToCreate = (
        TimeAccounting => $Home . '/scripts/webservices/TimeAccounting.yml',
    );

    WEBSERVICENAME:
    for my $WebserviceName ( sort keys %WebservicesToCreate ) {
        if ( $WebserviceIDsByName{$WebserviceName} ) {
            print
                "        Web service with name $WebserviceName already exists. Please check if it's the correct one.\n";
            next WEBSERVICENAME;
        }

        my $YAMLFilePath = $WebservicesToCreate{$WebserviceName};

        $ZnunyHelperObject->_WebserviceCreateIfNotExists(
            Webservices => {
                $WebserviceName => $YAMLFilePath,
            },
        );
    }

    return 1;
}

1;
