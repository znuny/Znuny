# --
# Copyright (C) 2001-2021 OTRS AG, https://otrs.com/
# Copyright (C) 2021-2022 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see https://www.gnu.org/licenses/gpl-3.0.txt.
# --

package Kernel::System::OTRSBusiness;

use strict;
use warnings;

use Kernel::System::VariableCheck qw(:all);

our @ObjectDependencies = (
    'Kernel::Config',
    'Kernel::System::Cache',
    'Kernel::System::CloudService::Backend::Run',
    'Kernel::System::DynamicField',
    'Kernel::System::DynamicField::Backend',
    'Kernel::System::Log',
    'Kernel::System::DateTime',
    'Kernel::System::DB',
    'Kernel::System::Package',
    'Kernel::System::SystemData',
);

=head1 NAME

Kernel::System::OTRSBusiness - OTRSBusiness deployment backend

=head1 PUBLIC INTERFACE

=head2 new()

create an object. Do not use it directly, instead use:

    use Kernel::System::ObjectManager;
    local $Kernel::OM = Kernel::System::ObjectManager->new();
    my $RegistrationObject = $Kernel::OM->Get('Kernel::System::OTRSBusiness');


=cut

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {};
    bless( $Self, $Type );

    #$Self->{APIVersion} = 1;

    # Get config object
    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');

    # Get OTRSBusiness::ReleaseChannel from SysConfig (Stable = 1, Development = 0)
    $Self->{OnlyStable} = $ConfigObject->Get('OTRSBusiness::ReleaseChannel') // 1;

    # Set cache params
    $Self->{CacheType} = 'OTRSBusiness';
    $Self->{CacheTTL}  = 60 * 60 * 24 * 30;    # 30 days

    # Check if cloud services are disabled
    $Self->{CloudServicesDisabled} = $ConfigObject->Get('CloudServices::Disabled') || 0;

    # If we cannot connect to cloud.otrs.com for more than the second period, show an error.
    $Self->{NoConnectErrorPeriod} = 60 * 60 * 24 * 15;    # 15 days

    # If we cannot connect to cloud.otrs.com for more than the second period, block the system.
    $Self->{NoConnectBlockPeriod} = 60 * 60 * 24 * 25;    # 25 days

    # If the contract is about to expire in less than this time, show a hint
    $Self->{ContractExpiryWarningPeriod} = 60 * 60 * 24 * 28;    # 28 days

    return $Self;
}

=head2 OTRSBusinessIsInstalled()

checks if OTRSBusiness is installed in the current system.
That does not necessarily mean that it is also active, for
example if the package is only on the database but not on
the file system.

=cut

sub OTRSBusinessIsInstalled {
    my ( $Self, %Param ) = @_;

    my $CacheObject = $Kernel::OM->Get('Kernel::System::Cache');

    # as the check for installed packages can be
    # very expensive, we want to use caching here
    my $Cache = $CacheObject->Get(
        Type => $Self->{CacheType},
        TTL  => $Self->{CacheTTL},
        Key  => 'OTRSBusinessIsInstalled',
    );

    return $Cache if defined $Cache;

    my $IsInstalled = $Self->_GetOTRSBusinessPackageFromRepository() ? 1 : 0;

    # set cache
    $CacheObject->Set(
        Type  => $Self->{CacheType},
        TTL   => $Self->{CacheTTL},
        Key   => 'OTRSBusinessIsInstalled',
        Value => $IsInstalled,
    );

    return $IsInstalled;
}

=head2 OTRSSTORMIsInstalled()

checks if OTRSStorm is installed in the current system.
That does not necessarily mean that it is also active, for
example if the package is only on the database but not on
the file system.

=cut

sub OTRSSTORMIsInstalled {
    my ( $Self, %Param ) = @_;

    my $CacheObject = $Kernel::OM->Get('Kernel::System::Cache');

    # as the check for installed packages can be
    # very expensive, we want to use caching here
    my $Cache = $CacheObject->Get(
        Type => $Self->{CacheType},
        TTL  => $Self->{CacheTTL},
        Key  => 'OTRSSTORMIsInstalled',
    );

    return $Cache if defined $Cache;

    my $IsInstalled = $Self->_GetSTORMPackageFromRepository() ? 1 : 0;

    # set cache
    $CacheObject->Set(
        Type  => $Self->{CacheType},
        TTL   => $Self->{CacheTTL},
        Key   => 'OTRSSTORMIsInstalled',
        Value => $IsInstalled,
    );

    return $IsInstalled;
}

=head2 OTRSCONTROLIsInstalled()

checks if OTRSControl is installed in the current system.
That does not necessarily mean that it is also active, for
example if the package is only on the database but not on
the file system.

=cut

sub OTRSCONTROLIsInstalled {
    my ( $Self, %Param ) = @_;

    my $CacheObject = $Kernel::OM->Get('Kernel::System::Cache');

    # as the check for installed packages can be
    # very expensive, we want to use caching here
    my $Cache = $CacheObject->Get(
        Type => $Self->{CacheType},
        TTL  => $Self->{CacheTTL},
        Key  => 'OTRSCONTROLIsInstalled',
    );

    return $Cache if defined $Cache;

    my $IsInstalled = $Self->_GetCONTROLPackageFromRepository() ? 1 : 0;

    # set cache
    $CacheObject->Set(
        Type  => $Self->{CacheType},
        TTL   => $Self->{CacheTTL},
        Key   => 'OTRSCONTROLIsInstalled',
        Value => $IsInstalled,
    );

    return $IsInstalled;
}

=head2 OTRSBusinessIsAvailable()

checks with C<cloud.otrs.com> if OTRSBusiness is available for the current framework.

=cut

sub OTRSBusinessIsAvailable {
    my ( $Self, %Param ) = @_;

    return if $Self->{CloudServicesDisabled};

    my $CloudServiceObject = $Kernel::OM->Get('Kernel::System::CloudService::Backend::Run');
    my $RequestResult      = $CloudServiceObject->Request(
        RequestData => {
            OTRSBusiness => [
                {
                    Operation => 'BusinessVersionCheck',
                    Data      => {
                        OnlyStable => $Self->{OnlyStable},
                    },
                },
            ],
        },
    );

    my $OperationResult;
    if ( IsHashRefWithData($RequestResult) ) {
        $OperationResult = $CloudServiceObject->OperationResultGet(
            RequestResult => $RequestResult,
            CloudService  => 'OTRSBusiness',
            Operation     => 'BusinessVersionCheck',
        );

        if ( $OperationResult->{Success} ) {
            $Self->HandleBusinessVersionCheckCloudServiceResult(
                OperationResult => $OperationResult,
            );

            if ( $OperationResult->{Data}->{LatestVersionForCurrentFramework} ) {
                return 1;
            }
        }
    }
    return;
}

=head2 OTRSBusinessIsAvailableOffline()

retrieves the latest result of the BusinessVersionCheck cloud service
that was stored in the system_data table.

returns 1 if available.

=cut

sub OTRSBusinessIsAvailableOffline {
    my ( $Self, %Param ) = @_;

    my %BusinessVersionCheck = $Kernel::OM->Get('Kernel::System::SystemData')->SystemDataGroupGet(
        Group => 'OTRSBusiness',
    );

    return $BusinessVersionCheck{LatestVersionForCurrentFramework} ? 1 : 0;
}

=head2 OTRSBusinessIsCorrectlyDeployed()

checks if the OTRSBusiness package is correctly
deployed or if it needs to be reinstalled.

=cut

sub OTRSBusinessIsCorrectlyDeployed {
    my ( $Self, %Param ) = @_;

    my $Package = $Self->_GetOTRSBusinessPackageFromRepository();

    # Package not found -> return failure
    return if !$Package;

    # first check the regular way if the files are present and the package
    # itself is installed correctly
    return if !$Kernel::OM->Get('Kernel::System::Package')->DeployCheck(
        Name    => $Package->{Name}->{Content},
        Version => $Package->{Version}->{Content},
    );

    # check if all tables have been created correctly
    # we can't rely on any .opm file here, so we just check
    # the list of tables manually
    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    TABLES:
    for my $Table (qw(chat chat_participant chat_message)) {

        # if a table does not exist, $TablePresent will be 'undef' for this table
        my $TablePresent = $DBObject->Do(
            SQL   => "SELECT * FROM $Table",
            Limit => 1,
        );

        return if !$TablePresent;
    }

    return 1;
}

=head2 OTRSBusinessIsReinstallable()

checks if the OTRSBusiness package can be reinstalled
(if it supports the current framework version). If not,
an update might be needed.

=cut

sub OTRSBusinessIsReinstallable {
    my ( $Self, %Param ) = @_;

    my $Package = $Self->_GetOTRSBusinessPackageFromRepository();

    # Package not found -> return failure
    return if !$Package;

    my %Check = $Kernel::OM->Get('Kernel::System::Package')->AnalyzePackageFrameworkRequirements(
        Framework => $Package->{Framework},
    );
    return $Check{Success};
}

=head2 OTRSBusinessIsUpdateable()

checks with C<cloud.otrs.com> if the OTRSBusiness package is available in a newer version
than the one currently installed. The result of this check will be stored in the
system_data table for offline usage.

=cut

sub OTRSBusinessIsUpdateable {
    my ( $Self, %Param ) = @_;

    return 0 if $Self->{CloudServicesDisabled};

    my $Package = $Self->_GetOTRSBusinessPackageFromRepository();
    return if !$Package;

    my $CloudServiceObject = $Kernel::OM->Get('Kernel::System::CloudService::Backend::Run');
    my $RequestResult      = $CloudServiceObject->Request(
        RequestData => {
            OTRSBusiness => [
                {
                    Operation => 'BusinessVersionCheck',
                    Data      => {
                        OnlyStable => $Self->{OnlyStable},
                    },
                },
            ],
        },
    );

    my $OperationResult;
    if ( IsHashRefWithData($RequestResult) ) {
        $OperationResult = $CloudServiceObject->OperationResultGet(
            RequestResult => $RequestResult,
            CloudService  => 'OTRSBusiness',
            Operation     => 'BusinessVersionCheck',
        );

        if ( $OperationResult && $OperationResult->{Success} ) {

            $Self->HandleBusinessVersionCheckCloudServiceResult( OperationResult => $OperationResult );

            if ( $OperationResult->{Data}->{LatestVersionForCurrentFramework} ) {
                return $Kernel::OM->Get('Kernel::System::Package')->_CheckVersion(
                    VersionNew       => $OperationResult->{Data}->{LatestVersionForCurrentFramework},
                    VersionInstalled => $Package->{Version}->{Content},
                    Type             => 'Max',
                );
            }
        }
    }

    return 0;
}

=head2 OTRSBusinessVersionCheckOffline()

retrieves the latest result of the BusinessVersionCheck cloud service
that was stored in the system_data table.

    my %Result = $OTRSBusinessObject->OTRSBusinessVersionCheckOffline();

returns

    $Result = (
        OTRSBusinessUpdateAvailable      => 1,  # if applicable
        FrameworkUpdateAvailable         => 1,  # if applicable
    );

=cut

sub OTRSBusinessVersionCheckOffline {
    my ( $Self, %Param ) = @_;

    my $Package = $Self->_GetOTRSBusinessPackageFromRepository();

    return if !$Package;

    my %EntitlementData = $Kernel::OM->Get('Kernel::System::SystemData')->SystemDataGroupGet(
        Group => 'OTRSBusiness',
    );

    my %Result = (
        FrameworkUpdateAvailable => $EntitlementData{FrameworkUpdateAvailable} // '',
    );

    if ( $EntitlementData{LatestVersionForCurrentFramework} ) {
        $Result{OTRSBusinessUpdateAvailable} = $Kernel::OM->Get('Kernel::System::Package')->_CheckVersion(
            VersionNew       => $EntitlementData{LatestVersionForCurrentFramework},
            VersionInstalled => $Package->{Version}->{Content},
            Type             => 'Max',
        );
    }

    return %Result;
}

=head2 OTRSBusinessGetDependencies()

checks if there are any active dependencies on OTRSBusiness.

=cut

sub OTRSBusinessGetDependencies {
    my ( $Self, %Param ) = @_;

    my @Packages = $Kernel::OM->Get('Kernel::System::Package')->RepositoryList();

    my @DependentPackages;
    PACKAGE:
    for my $Package (@Packages) {

        next PACKAGE if !IsHashRefWithData($Package);
        next PACKAGE if !IsArrayRefWithData( $Package->{PackageRequired} );

        DEPENDENCY:
        for my $Dependency ( @{ $Package->{PackageRequired} } ) {

            next DEPENDENCY if !IsHashRefWithData($Dependency);
            next DEPENDENCY if !$Dependency->{Content};
            next DEPENDENCY if $Dependency->{Content} ne 'OTRSBusiness';

            push @DependentPackages, {
                Name        => $Package->{Name}->{Content},
                Vendor      => $Package->{Vendor}->{Content},
                Version     => $Package->{Version}->{Content},
                Description => $Package->{Description},
            };

            last DEPENDENCY;
        }
    }

    return \@DependentPackages;
}

=head2 OTRSBusinessEntitlementCheck()

determines the OTRSBusiness entitlement status of this system as reported by C<cloud.otrs.com>
and stores it in the system_data cache.

Returns 1 if the cloud call was successful.

=cut

sub OTRSBusinessEntitlementCheck {
    my ( $Self, %Param ) = @_;

    # If OTRSSTORM package is installed, system is able to do a Cloud request even if CloudService is disabled.
    if (
        !$Self->OTRSSTORMIsInstalled()
        && $Self->{CloudServicesDisabled}
        )
    {
        return;
    }

    my $CloudServiceObject = $Kernel::OM->Get('Kernel::System::CloudService::Backend::Run');
    my $RequestResult      = $CloudServiceObject->Request(
        RequestData => {
            OTRSBusiness => [
                {
                    Operation => 'BusinessPermission',
                    Data      => {},
                },
            ],
        },
    );

    my $OperationResult;
    if ( IsHashRefWithData($RequestResult) ) {
        $OperationResult = $CloudServiceObject->OperationResultGet(
            RequestResult => $RequestResult,
            CloudService  => 'OTRSBusiness',
            Operation     => 'BusinessPermission',
        );
    }

    # OK, so we got a successful cloud call result. Then we will use it and remember it.
    if ( IsHashRefWithData($OperationResult) && $OperationResult->{Success} ) {

        # Store it in the SystemData so that it is also available for the notification modules,
        #   even before the first run of RegistrationUpdate.
        $Self->HandleBusinessPermissionCloudServiceResult(
            OperationResult => $OperationResult,
        );
        return 1;
    }

    if ( !IsHashRefWithData($RequestResult) || !$RequestResult->{Success} ) {
        my $Message = "BusinessPermission - Can't contact cloud.otrs.com server";
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => $Message
        );
    }

    if ( !IsHashRefWithData($OperationResult) || !$OperationResult->{Success} ) {
        my $Message = "BusinessPermission - could not perform BusinessPermission check";
        if ( IsHashRefWithData($OperationResult) ) {
            $Message .= $OperationResult->{ErrorMessage};
        }
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => $Message
        );
    }

    return 0;
}

=head2 OTRSBusinessEntitlementStatus()

Returns the current entitlement status.

    my $Status = $OTRSBusinessObject->OTRSBusinessEntitlementStatus(
        CallCloudService => 1,              # 0 or 1, call the cloud service before looking at the cache
    );

    $Status = 'entitled';      # everything is OK
    $Status = 'warning';       # last check was OK, and we are in the waiting period - show warning
    $Status = 'warning-error'; # last check was OK, and we are past waiting period - show error message
    $Status = 'forbidden';     # not entitled (either because the server said so or because the last check was too long ago)

=cut

sub OTRSBusinessEntitlementStatus {
    my ( $Self, %Param ) = @_;

    # If the system is not registered, it cannot have an OB permission.
    #   Also, the BusinessPermissionChecks will not work any more, so the permission
    #   would expire after our waiting period. But in this case we can immediately deny
    #   the permission.
    my $RegistrationState = $Kernel::OM->Get('Kernel::System::SystemData')->SystemDataGet(
        Key => 'Registration::State',
    );
    if ( !$RegistrationState || $RegistrationState ne 'registered' ) {
        return 'forbidden';
    }

    # Cloud service is called and if cannot be connected, it must return 'forbidden'.
    if ( $Param{CallCloudService} ) {
        my $Check = $Self->OTRSBusinessEntitlementCheck();
        return 'forbidden' if $Check == 0;
    }

    # OK. Let's look at the system_data cache now and use it if appropriate
    my %EntitlementData = $Kernel::OM->Get('Kernel::System::SystemData')->SystemDataGroupGet(
        Group => 'OTRSBusiness',
    );

    if ( !%EntitlementData || !$EntitlementData{BusinessPermission} ) {
        return 'forbidden';
    }

    # Check when the last successful BusinessPermission check was made.
    my $DateTimeObject = $Kernel::OM->Create(
        'Kernel::System::DateTime',
        ObjectParams => {
            String => $EntitlementData{LastUpdateTime},
        },
    );

    my $Delta = $Kernel::OM->Create('Kernel::System::DateTime')->Delta(
        DateTimeObject => $DateTimeObject,
    );

    if ( $Delta->{AbsoluteSeconds} > $Self->{NoConnectBlockPeriod} ) {
        return 'forbidden';
    }
    if ( $Delta->{AbsoluteSeconds} > $Self->{NoConnectErrorPeriod} ) {
        return 'warning-error';
    }

    # If we cannot connect to cloud.otrs.com for more than the first period, show a warning.
    my $NoConnectWarningPeriod = 60 * 60 * 24 * 5;    # 5 days
    if ( $Self->OTRSSTORMIsInstalled() ) {
        $NoConnectWarningPeriod = 60 * 60 * 24 * 10;    # 10 days
    }

    if ( $Delta->{AbsoluteSeconds} > $NoConnectWarningPeriod ) {
        return 'warning';
    }

    return 'entitled';
}

=head2 OTRSBusinessContractExpiryDateCheck()

checks for the warning period before the contract expires

    my $ExpiryDate = $OTRSBusinessObject->OTRSBusinessContractExpiryDateCheck();

returns the ExpiryDate if a warning should be displayed

    $ExpiryDate = undef;                    # everything is OK, no warning
    $ExpiryDate = '2012-12-12 12:12:12'     # contract is about to expire, issue warning

=cut

sub OTRSBusinessContractExpiryDateCheck {
    my ( $Self, %Param ) = @_;

    if ( $Param{CallCloudService} ) {
        $Self->OTRSBusinessEntitlementCheck();
    }

    # OK. Let's look at the system_data cache now and use it if appropriate
    my %EntitlementData = $Kernel::OM->Get('Kernel::System::SystemData')->SystemDataGroupGet(
        Group => 'OTRSBusiness',
    );

    if ( !%EntitlementData || !$EntitlementData{ExpiryDate} ) {
        return;
    }

    my $ExpiryDateTimeObj = $Kernel::OM->Create(
        'Kernel::System::DateTime',
        ObjectParams => {
            String => $EntitlementData{ExpiryDate},
        }
    );

    my $DateTimeObject = $Kernel::OM->Create('Kernel::System::DateTime');

    my $Delta = $ExpiryDateTimeObj->Delta(
        DateTimeObject => $DateTimeObject
    );

    if ( $Delta->{AbsoluteSeconds} < $Self->{ContractExpiryWarningPeriod} ) {
        return $EntitlementData{ExpiryDate};
    }

    return;
}

sub HandleBusinessPermissionCloudServiceResult {
    my ( $Self, %Param ) = @_;

    my $OperationResult = $Param{OperationResult};

    return if !$OperationResult->{Success};

    # We store the current time as LastUpdateTime so that we know when the last
    #   permission check could be successfully made with the server. This is needed
    #   to determine if the results can still be used later, if a connection to
    #   cloud.otrs.com cannot be made temporarily.
    my %StoreData = (
        BusinessPermission            => $OperationResult->{Data}->{BusinessPermission}            // 0,
        ExpiryDate                    => $OperationResult->{Data}->{ExpiryDate}                    // '',
        LastUpdateTime                => $Kernel::OM->Create('Kernel::System::DateTime')->ToString(),
        AgentSessionLimit             => $OperationResult->{Data}->{AgentSessionLimit}             // 0,
        AgentSessionLimitPriorWarning => $OperationResult->{Data}->{AgentSessionLimitPriorWarning} // 0,
    );

    my $SystemDataObject = $Kernel::OM->Get('Kernel::System::SystemData');

    KEY:
    for my $Key ( sort keys %StoreData ) {
        next KEY if !defined $StoreData{$Key};

        my $FullKey = 'OTRSBusiness::' . $Key;

        if ( defined $SystemDataObject->SystemDataGet( Key => $FullKey ) ) {
            $SystemDataObject->SystemDataUpdate(
                Key    => $FullKey,
                Value  => $StoreData{$Key},
                UserID => 1,
            );
        }
        else {
            $SystemDataObject->SystemDataAdd(
                Key    => $FullKey,
                Value  => $StoreData{$Key},
                UserID => 1,
            );
        }
    }

    return 1;
}

sub HandleBusinessVersionCheckCloudServiceResult {
    my ( $Self, %Param ) = @_;

    my $OperationResult = $Param{OperationResult};

    return if !$OperationResult->{Success};

    my %StoreData = (
        LatestVersionForCurrentFramework => $OperationResult->{Data}->{LatestVersionForCurrentFramework} // '',
        FrameworkUpdateAvailable         => $OperationResult->{Data}->{FrameworkUpdateAvailable}         // '',
    );

    my $SystemDataObject = $Kernel::OM->Get('Kernel::System::SystemData');

    for my $Key ( sort keys %StoreData ) {
        my $FullKey = 'OTRSBusiness::' . $Key;

        if ( defined $SystemDataObject->SystemDataGet( Key => $FullKey ) ) {
            $SystemDataObject->SystemDataUpdate(
                Key    => $FullKey,
                Value  => $StoreData{$Key},
                UserID => 1,
            );
        }
        else {
            $SystemDataObject->SystemDataAdd(
                Key    => $FullKey,
                Value  => $StoreData{$Key},
                UserID => 1,
            );
        }
    }

    return 1;
}

sub _OTRSBusinessFileGet {
    my ( $Self, %Param ) = @_;

    return if $Self->{CloudServicesDisabled};

    my $CloudServiceObject = $Kernel::OM->Get('Kernel::System::CloudService::Backend::Run');
    my $RequestResult      = $CloudServiceObject->Request(
        RequestData => {
            OTRSBusiness => [
                {
                    Operation => 'BusinessFileGet',
                    Data      => {
                        OnlyStable => $Self->{OnlyStable},
                    },
                },
            ],
        },
    );

    my $OperationResult;
    if ( IsHashRefWithData($RequestResult) ) {
        $OperationResult = $CloudServiceObject->OperationResultGet(
            RequestResult => $RequestResult,
            CloudService  => 'OTRSBusiness',
            Operation     => 'BusinessFileGet',
        );

        if ( $OperationResult->{Success} && $OperationResult->{Data}->{Package} ) {
            return $OperationResult->{Data}->{Package};
        }
    }

    return;
}

=head2 OTRSBusinessInstall()

downloads and installs OTRSBusiness.

=cut

sub OTRSBusinessInstall {
    my ( $Self, %Param ) = @_;

    my %Response = (
        Success => 0,
    );

    my $PackageString = $Self->_OTRSBusinessFileGet();
    return %Response if !$PackageString;

    my $PackageObject = $Kernel::OM->Get('Kernel::System::Package');

    # Parse package structure.
    my %Structure = $PackageObject->PackageParse(
        String    => $PackageString,
        FromCloud => 1,
    );

    my %FrameworkCheck = $PackageObject->AnalyzePackageFrameworkRequirements(
        Framework => $Structure{Framework},
        NoLog     => 1,
    );

    if ( !$FrameworkCheck{Success} ) {
        $FrameworkCheck{ShowBlock} = 'IncompatibleInfo';
        return %FrameworkCheck;
    }

    my $Install = $Kernel::OM->Get('Kernel::System::Package')->PackageInstall(
        String    => $PackageString,
        FromCloud => 1,
    );

    return %Response if !$Install;

    # now that we know that OTRSBusiness has been installed,
    # we can just preset the cache instead of just swiping it.
    $Kernel::OM->Get('Kernel::System::Cache')->Set(
        Type  => $Self->{CacheType},
        TTL   => $Self->{CacheTTL},
        Key   => 'OTRSBusinessIsInstalled',
        Value => 1,
    );

    $Response{Success} = 1;

    return %Response;
}

=head2 OTRSBusinessReinstall()

re-installs OTRSBusiness from local repository.

=cut

sub OTRSBusinessReinstall {
    my ( $Self, %Param ) = @_;

    my $Package = $Self->_GetOTRSBusinessPackageFromRepository();

    # Package not found -> return failure
    return if !$Package;

    my $PackageString = $Kernel::OM->Get('Kernel::System::Package')->RepositoryGet(
        Name    => $Package->{Name}->{Content},
        Version => $Package->{Version}->{Content},
    );

    return $Kernel::OM->Get('Kernel::System::Package')->PackageReinstall(
        String => $PackageString,
    );
}

=head2 OTRSBusinessUpdate()

downloads and updates OTRSBusiness.

=cut

sub OTRSBusinessUpdate {
    my ( $Self, %Param ) = @_;

    my %Response = (
        Success => 0,
    );
    my $PackageString = $Self->_OTRSBusinessFileGet();
    return if !$PackageString;

    my $PackageObject = $Kernel::OM->Get('Kernel::System::Package');

    # Parse package structure.
    my %Structure = $PackageObject->PackageParse(
        String    => $PackageString,
        FromCloud => 1,
    );

    my %FrameworkCheck = $PackageObject->AnalyzePackageFrameworkRequirements(
        Framework => $Structure{Framework},
        NoLog     => 1,
    );

    if ( !$FrameworkCheck{Success} ) {
        $FrameworkCheck{ShowBlock} = 'IncompatibleInfo';
        return %FrameworkCheck;
    }

    my $Upgrade = $Kernel::OM->Get('Kernel::System::Package')->PackageUpgrade(
        String    => $PackageString,
        FromCloud => 1,
    );

    return %Response if !$Upgrade;

    $Response{Success} = 1;
    return %Response;
}

=head2 OTRSBusinessUninstall()

removes OTRSBusiness from the system.

=cut

sub OTRSBusinessUninstall {
    my ( $Self, %Param ) = @_;

    my $Package = $Self->_GetOTRSBusinessPackageFromRepository();

    # Package not found -> return failure
    return if !$Package;

    # TODO: the following code is now Deprecated and should be removed in further versions of OTRS
    # get a list of all dynamic fields for ticket and article
    my $DynamicFieldObject = $Kernel::OM->Get('Kernel::System::DynamicField');
    my $DynamicFieldList   = $DynamicFieldObject->DynamicFieldListGet(
        Valid      => 0,
        ObjectType => [ 'Ticket', 'Article' ],
    );

    # filter only dynamic fields added by OTRSBusiness
    my %OTRSBusinessDynamicFieldTypes = (
        ContactWithData => 1,
        Database        => 1,
    );

    my $DynamicFieldBackendObject = $Kernel::OM->Get('Kernel::System::DynamicField::Backend');

    DYNAMICFIELD:
    for my $DynamicFieldConfig ( @{$DynamicFieldList} ) {
        next DYNAMICFIELD if !IsHashRefWithData($DynamicFieldConfig);
        next DYNAMICFIELD if !$OTRSBusinessDynamicFieldTypes{ $DynamicFieldConfig->{FieldType} };

        # remove data from the field
        my $ValuesDeleteSuccess = $DynamicFieldBackendObject->AllValuesDelete(
            DynamicFieldConfig => $DynamicFieldConfig,
            UserID             => 1,
        );

        if ( !$ValuesDeleteSuccess ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Values from dynamic field $DynamicFieldConfig->{Name} could not be deleted!",
            );
        }

        my $Success = $DynamicFieldObject->DynamicFieldDelete(
            ID      => $DynamicFieldConfig->{ID},
            UserID  => 1,
            Reorder => 1,
        );

        if ( !$Success ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Dynamic field $DynamicFieldConfig->{Name} could not be deleted!",
            );
        }
    }

    # TODO: end Deprecated

    my $PackageString = $Kernel::OM->Get('Kernel::System::Package')->RepositoryGet(
        Name    => $Package->{Name}->{Content},
        Version => $Package->{Version}->{Content},
    );

    my $Uninstall = $Kernel::OM->Get('Kernel::System::Package')->PackageUninstall(
        String => $PackageString,
    );

    return $Uninstall if !$Uninstall;

    # now that we know that OTRSBusiness has been uninstalled,
    # we can just preset the cache instead of just swiping it.
    $Kernel::OM->Get('Kernel::System::Cache')->Set(
        Type  => $Self->{CacheType},
        TTL   => $Self->{CacheTTL},
        Key   => 'OTRSBusinessIsInstalled',
        Value => 0,
    );

    return $Uninstall;
}

=head2 OTRSBusinessCommandNextUpdateTimeSet()

Set the next update time for the given command in the system data table storage.

    my $Success = $OTRSBusinessObject->OTRSBusinessCommandNextUpdateTimeSet(
        Command => 'AvailabilityCheck',
    );

Returns 1 if the next update time was set successfully.

=cut

sub OTRSBusinessCommandNextUpdateTimeSet {
    my ( $Self, %Param ) = @_;

    return if !$Param{Command};

    my $Key = "OTRSBusiness::$Param{Command}::NextUpdateTime";

    my $SystemDataObject = $Kernel::OM->Get('Kernel::System::SystemData');

    my $NextUpdateTime = $SystemDataObject->SystemDataGet(
        Key => $Key,
    );

    # set the default next update seconds offset
    my $NextUpdateSecondsOffset = 60 * 60 * 24;

    # generate a random seconds offset, if no next update time exists
    if ( !$NextUpdateTime ) {

        # create the random numbers
        my $RandomHour   = int 20 + rand 23 - 20;
        my $RandomMinute = int rand 60;

        # create the random seconds offset
        $NextUpdateSecondsOffset = 60 * 60 * $RandomHour + ( 60 * $RandomMinute );
    }

    my $DateTimeObject = $Kernel::OM->Create('Kernel::System::DateTime');
    $DateTimeObject->Add( Seconds => $NextUpdateSecondsOffset );
    my $CalculatedNextUpdateTime = $DateTimeObject->ToString();

    if ( defined $NextUpdateTime ) {
        $SystemDataObject->SystemDataUpdate(
            Key    => $Key,
            Value  => $CalculatedNextUpdateTime,
            UserID => 1,
        );
    }
    else {
        $SystemDataObject->SystemDataAdd(
            Key    => $Key,
            Value  => $CalculatedNextUpdateTime,
            UserID => 1,
        );
    }

    return 1;
}

sub _GetOTRSBusinessPackageFromRepository {
    my ( $Self, %Param ) = @_;

    my $PackageObject = $Kernel::OM->Get('Kernel::System::Package');

    my @RepositoryList = $PackageObject->RepositoryList();

    for my $Package (@RepositoryList) {
        return $Package if $Package->{Name}->{Content} eq 'OTRSBusiness';
    }

    return;
}

sub _GetSTORMPackageFromRepository {
    my ( $Self, %Param ) = @_;

    my $PackageObject = $Kernel::OM->Get('Kernel::System::Package');

    my @RepositoryList = $PackageObject->RepositoryList(
        Result => 'short',
    );

    for my $Package (@RepositoryList) {

        return $Package if $Package->{Name} eq 'OTRSSTORM';
    }

    return;
}

sub _GetCONTROLPackageFromRepository {
    my ( $Self, %Param ) = @_;

    my $PackageObject = $Kernel::OM->Get('Kernel::System::Package');

    my @RepositoryList = $PackageObject->RepositoryList(
        Result => 'short',
    );

    for my $Package (@RepositoryList) {

        return $Package if $Package->{Name} eq 'OTRSCONTROL';
    }

    return;
}

1;

=head1 TERMS AND CONDITIONS

This software is part of the OTRS project (L<https://otrs.org/>).

This software comes with ABSOLUTELY NO WARRANTY. For details, see
the enclosed file COPYING for license information (GPL). If you
did not receive this file, see L<https://www.gnu.org/licenses/gpl-3.0.txt>.

=cut
