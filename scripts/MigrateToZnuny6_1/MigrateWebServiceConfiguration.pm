# --
# Copyright (C) 2001-2021 OTRS AG, https://otrs.com/
# Copyright (C) 2021 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see https://www.gnu.org/licenses/gpl-3.0.txt.
# --
## nofilter(TidyAll::Plugin::OTRS::Perl::Pod::NamePod)

package scripts::MigrateToZnuny6_1::MigrateWebServiceConfiguration;    ## no critic

use strict;
use warnings;

use parent qw(scripts::MigrateToZnuny6_1::Base);

use Kernel::System::VariableCheck qw(:all);

our @ObjectDependencies = (
    'Kernel::System::GenericInterface::Webservice',
);

=head1 NAME

Migrate web service configuration.

=cut

sub Run {
    my ( $Self, %Param ) = @_;

    my $WebserviceObject = $Kernel::OM->Get('Kernel::System::GenericInterface::Webservice');

    my $WebserviceList = $WebserviceObject->WebserviceList(
        Valid => 0,
    );
    return 1 if !IsHashRefWithData($WebserviceList);

    my %InvokerTypeMapping = (
        'Znuny4OTRSAdvanced::Generic' => 'Znuny::Generic',
        'Znuny4OTRSAdvanced::Tunnel'  => 'Znuny::Tunnel',
    );

    WEBSERVICEID:
    for my $WebserviceID ( sort keys %{$WebserviceList} ) {

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

1;

=head1 TERMS AND CONDITIONS

This software is part of the OTRS project (L<https://otrs.org/>).

This software comes with ABSOLUTELY NO WARRANTY. For details, see
the enclosed file COPYING for license information (GPL). If you
did not receive this file, see L<https://www.gnu.org/licenses/gpl-3.0.txt>.

=cut
