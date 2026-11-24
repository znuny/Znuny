# --
# Copyright (C) 2001-2021 OTRS AG, https://otrs.com/
# Copyright (C) 2021 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see https://www.gnu.org/licenses/gpl-3.0.txt.
# --

# Note: This is based on Kernel::Modules::AdminCustomerUserService.
# Mainly CustomerUser has been replaced by CustomerCompany.

package Kernel::Modules::AdminCustomerCompanyService;

use strict;
use warnings;
use utf8;

use Kernel::Language qw(Translatable);

our $ObjectManagerDisabled = 1;

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {%Param};
    bless( $Self, $Type );

    return $Self;
}

sub Run {
    my ( $Self, %Param ) = @_;

    my $LayoutObject          = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $ParamObject           = $Kernel::OM->Get('Kernel::System::Web::Request');
    my $ServiceObject         = $Kernel::OM->Get('Kernel::System::Service');
    my $CustomerCompanyObject = $Kernel::OM->Get('Kernel::System::CustomerCompany');

    # set search limit
    my $SearchLimit = 200;

    # ------------------------------------------------------------ #
    # allocate customer company
    # ------------------------------------------------------------ #
    if ( $Self->{Subaction} eq 'AllocateCustomerCompany' ) {

        $Param{CustomerID}            = $ParamObject->GetParam( Param => 'CustomerID' ) || '<DEFAULT>';
        $Param{CustomerCompanySearch} = $ParamObject->GetParam( Param => 'CustomerCompanySearch' )
            || '*';

        # output header
        my $Output = $LayoutObject->Header();
        $Output .= $LayoutObject->NavigationBar();

        my %CustomerCompany = $CustomerCompanyObject->CustomerCompanyGet(
            CustomerID => $Param{CustomerID},
        );

        # get service member
        my %ServiceMemberList = $ServiceObject->CustomerCompanyServiceMemberList(
            CustomerID => $Param{CustomerID},
            Result     => 'HASH',
        );

        # List services.
        my %ServiceData = $ServiceObject->ServiceList(
            KeepChildren => 1,
            UserID       => $Self->{UserID},
        );

        $Output .= $Self->_Change(
            ID                    => $Param{CustomerID},
            Name                  => $CustomerCompany{CustomerCompanyName},
            Data                  => \%ServiceData,
            Selected              => \%ServiceMemberList,
            CustomerCompanySearch => $Param{CustomerCompanySearch},
            ServiceSearch         => $Param{ServiceSearch},
            SearchLimit           => $SearchLimit,
            Type                  => 'CustomerCompany',
        );

        $Output .= $LayoutObject->Footer();

        return $Output;
    }

    # ------------------------------------------------------------ #
    # allocate service
    # ------------------------------------------------------------ #
    elsif ( $Self->{Subaction} eq 'AllocateService' ) {

        $Param{ServiceID}             = $ParamObject->GetParam( Param => "ServiceID" );
        $Param{Subaction}             = $ParamObject->GetParam( Param => 'Subaction' );
        $Param{CustomerCompanySearch} = $ParamObject->GetParam( Param => "CustomerCompanySearch" )
            || '*';

        # output header
        my $Output = $LayoutObject->Header();
        $Output .= $LayoutObject->NavigationBar();

        # get service
        my %Service = $ServiceObject->ServiceGet(
            ServiceID => $Param{ServiceID},
            UserID    => $Self->{UserID},
        );

        # get customer company member
        my %CustomerCompanyMemberList = $ServiceObject->CustomerCompanyServiceMemberList(
            ServiceID => $Param{ServiceID},
            Result    => 'HASH',
        );

        # search customer company
        my %CustomerCompanyList = $CustomerCompanyObject->CustomerCompanyList(
            Search => $Param{CustomerCompanySearch},
        );
        my @CustomerCompanyKeyList
            = sort { $CustomerCompanyList{$a} cmp $CustomerCompanyList{$b} } keys %CustomerCompanyList;

        # set max count
        my $MaxCount = @CustomerCompanyKeyList;
        if ( $MaxCount > $SearchLimit ) {
            $MaxCount = $SearchLimit;
        }

        my %CustomerCompanyData;

        # output rows
        for my $Counter ( 1 .. $MaxCount ) {
            my $CustomerID = $CustomerCompanyKeyList[ $Counter - 1 ];
            $CustomerCompanyData{$CustomerID} = $CustomerCompanyList{$CustomerID};
        }

        $Output .= $Self->_Change(
            ID                    => $Param{ServiceID},
            Name                  => $Service{Name},
            ItemList              => \@CustomerCompanyKeyList,
            Data                  => \%CustomerCompanyData,
            Selected              => \%CustomerCompanyMemberList,
            CustomerCompanySearch => $Param{CustomerCompanySearch},
            SearchLimit           => $SearchLimit,
            Type                  => 'Service',
            %Param,
        );

        $Output .= $LayoutObject->Footer();

        return $Output;
    }

    # ------------------------------------------------------------ #
    # allocate customer company save
    # ------------------------------------------------------------ #
    elsif ( $Self->{Subaction} eq 'AllocateCustomerCompanySave' ) {

        # challenge token check for write action
        $LayoutObject->ChallengeTokenCheck();

        $Param{CustomerID}            = $ParamObject->GetParam( Param => 'ID' );
        $Param{CustomerCompanySearch} = $ParamObject->GetParam( Param => 'CustomerCompanySearch' )
            || '*';

        my @ServiceIDsSelected = $ParamObject->GetArray( Param => 'ItemsSelected' );
        my @ServiceIDsAll      = $ParamObject->GetArray( Param => 'ItemsAll' );

        # create hash with selected ids
        my %ServiceIDSelected = map { $_ => 1 } @ServiceIDsSelected;

        # check all used service ids
        for my $ServiceID (@ServiceIDsAll) {
            my $Active = $ServiceIDSelected{$ServiceID} ? 1 : 0;

            # set customer company service member
            $ServiceObject->CustomerCompanyServiceMemberAdd(
                CustomerID => $Param{CustomerID},
                ServiceID  => $ServiceID,
                Active     => $Active,
                UserID     => $Self->{UserID},
            );
        }

        # if the user would like to continue editing the customer company allocating just redirect to the edit screen
        if (
            defined $ParamObject->GetParam( Param => 'ContinueAfterSave' )
            && ( $ParamObject->GetParam( Param => 'ContinueAfterSave' ) eq '1' )
            )
        {
            return $LayoutObject->Redirect(
                OP =>
                    "Action=$Self->{Action};Subaction=AllocateCustomerCompany;CustomerID=$Param{CustomerID};CustomerCompanySearch=$Param{CustomerCompanySearch}"
            );
        }
        else {

            # otherwise return to relations overview
            return $LayoutObject->Redirect(
                OP => "Action=$Self->{Action};CustomerCompanySearch=$Param{CustomerCompanySearch}"
            );
        }
    }

    # ------------------------------------------------------------ #
    # allocate service save
    # ------------------------------------------------------------ #
    elsif ( $Self->{Subaction} eq 'AllocateServiceSave' ) {

        # challenge token check for write action
        $LayoutObject->ChallengeTokenCheck();

        $Param{ServiceID}             = $ParamObject->GetParam( Param => "ID" );
        $Param{CustomerCompanySearch} = $ParamObject->GetParam( Param => 'CustomerCompanySearch' )
            || '*';

        my @CustomerIDsSelected = $ParamObject->GetArray( Param => 'ItemsSelected' );
        my @CustomerIDsAll      = $ParamObject->GetArray( Param => 'ItemsAll' );

        # create hash with selected customer companies
        my %CustomerIDsSelected;
        for my $CustomerID (@CustomerIDsSelected) {
            $CustomerIDsSelected{$CustomerID} = 1;
        }

        # check all used customer companies
        for my $CustomerID (@CustomerIDsAll) {
            my $Active = $CustomerIDsSelected{$CustomerID} ? 1 : 0;

            # set customer company service member
            $ServiceObject->CustomerCompanyServiceMemberAdd(
                CustomerID => $CustomerID,
                ServiceID  => $Param{ServiceID},
                Active     => $Active,
                UserID     => $Self->{UserID},
            );
        }

        # if the user would like to continue editing the customer company allocating just redirect to the edit screen
        if (
            defined $ParamObject->GetParam( Param => 'ContinueAfterSave' )
            && ( $ParamObject->GetParam( Param => 'ContinueAfterSave' ) eq '1' )
            )
        {
            return $LayoutObject->Redirect(
                OP =>
                    "Action=$Self->{Action};Subaction=AllocateService;ServiceID=$Param{ServiceID};CustomerCompanySearch=$Param{CustomerCompanySearch}"
            );
        }
        else {

            # otherwise return to relations overview
            return $LayoutObject->Redirect(
                OP =>
                    "Action=$Self->{Action};CustomerCompanySearch=$Param{CustomerCompanySearch}"
            );
        }
    }

    # ------------------------------------------------------------ #
    # overview
    # ------------------------------------------------------------ #
    else {

        $Param{CustomerCompanySearch} = $ParamObject->GetParam( Param => 'CustomerCompanySearch' )
            || '*';

        # output header
        my $Output = $LayoutObject->Header();
        $Output .= $LayoutObject->NavigationBar();

        # search customer company
        my %CustomerCompanyList = $CustomerCompanyObject->CustomerCompanyList(
            Search => $Param{CustomerCompanySearch},
        );

        my @CustomerCompanyKeyList
            = sort { $CustomerCompanyList{$a} cmp $CustomerCompanyList{$b} } keys %CustomerCompanyList;

        # count results
        my $CustomerCompanyCount = @CustomerCompanyKeyList;

        # set max count
        my $MaxCustomerCompanyCount = $CustomerCompanyCount;

        if ( $MaxCustomerCompanyCount > $SearchLimit ) {
            $MaxCustomerCompanyCount = $SearchLimit;
        }

        # output rows
        my %CustomerCompanyData;
        CUSTOMERCOMPANYCOUNTER:
        for my $CustomerCompanyCounter ( 1 .. $MaxCustomerCompanyCount ) {

            # set customer company row params
            my $CustomerID = $CustomerCompanyKeyList[ $CustomerCompanyCounter - 1 ];
            next CUSTOMERCOMPANYCOUNTER if !defined $CustomerID;

            $CustomerCompanyData{$CustomerID} = $CustomerCompanyList{$CustomerID};
        }

        my %ServiceData = $ServiceObject->ServiceList(
            KeepChildren => 1,
            UserID       => $Self->{UserID},
        );

        $Output .= $Self->_Overview(
            CustomerCompanyCount   => $CustomerCompanyCount,
            CustomerCompanyKeyList => \@CustomerCompanyKeyList,
            CustomerCompanyData    => \%CustomerCompanyData,
            ServiceData            => \%ServiceData,
            SearchLimit            => $SearchLimit,
            CustomerCompanySearch  => $Param{CustomerCompanySearch},
        );

        $Output .= $LayoutObject->Footer();

        return $Output;
    }
}

sub _Change {
    my ( $Self, %Param ) = @_;

    my $SearchLimit = $Param{SearchLimit};
    my %Data        = %{ $Param{Data} };
    my $Type        = $Param{Type} || 'CustomerCompany';
    my $NeType      = $Type eq 'Service' ? 'CustomerCompany' : 'Service';
    my %VisibleType = (
        CustomerCompany => 'Customer',
        Service         => 'Service',
    );
    my %Subaction = (
        CustomerCompany => 'Change',
        Service         => 'ServiceEdit',
    );
    my %IDStrg = (
        CustomerCompany => 'ID',
        Service         => 'ServiceID',
    );

    my @ItemList = ();

    my $LayoutObject = $Kernel::OM->Get('Kernel::Output::HTML::Layout');

    if ( $VisibleType{$NeType} eq 'Customer' ) {
        $Param{BreadcrumbTitle} = Translatable('Allocate Customer Companies to Service');
    }
    else {
        $Param{BreadcrumbTitle} = Translatable('Allocate Services to Customer Company');
    }

    $LayoutObject->Block(
        Name => 'Overview',
        Data => {
            %Param,
            OverviewLink => $Self->{Action} . ';CustomerCompanySearch=' . $Param{CustomerCompanySearch},
        },
    );
    $LayoutObject->Block( Name => 'ActionList' );
    $LayoutObject->Block(
        Name => 'ActionOverview',
        Data => {
            CustomerCompanySearch => $Param{CustomerCompanySearch},
        },
    );

    if ( $NeType eq 'CustomerCompany' ) {
        @ItemList = @{ $Param{ItemList} };

        # output search block
        $LayoutObject->Block(
            Name => 'Search',
            Data => {
                %Param,
                CustomerCompanySearch => $Param{CustomerCompanySearch},
            },
        );
        $LayoutObject->Block(
            Name => 'SearchAllocateService',
            Data => {
                %Param,
                Subaction => $Param{Subaction},
                ServiceID => $Param{ServiceID},
            },
        );
    }
    else {
        $LayoutObject->Block( Name => 'Filter' );
    }

    $LayoutObject->Block(
        Name => 'AllocateItem',
        Data => {
            ID              => $Param{ID},
            ActionHome      => 'Admin' . $Type,
            Type            => $Type,
            NeType          => $NeType,
            VisibleType     => $VisibleType{$Type},
            VisibleNeType   => $VisibleType{$NeType},
            SubactionHeader => $Subaction{$Type},
            IDHeaderStrg    => $IDStrg{$Type},
            Subaction       => $Self->{Subaction},
            %Param,
        },
    );

    my $ColSpan = 2;

    if ( $NeType eq 'CustomerCompany' ) {

        # output count block
        if ( !@ItemList ) {
            $LayoutObject->Block(
                Name => 'AllocateItemCountLimit',
                Data => { ItemCount => 0 },
            );

            $LayoutObject->Block(
                Name => 'NoDataFoundMsgList',
                Data => {
                    ColSpan => $ColSpan,
                },
            );
        }
        elsif ( @ItemList > $SearchLimit ) {
            $LayoutObject->Block(
                Name => 'AllocateItemCountLimit',
                Data => { ItemCount => ">" . $SearchLimit },
            );
        }
        else {
            $LayoutObject->Block(
                Name => 'AllocateItemCount',
                Data => { ItemCount => scalar @ItemList },
            );
        }
    }

    # Service sorting.
    my %ServiceData;
    if ( $NeType eq 'Service' ) {
        %ServiceData = %Data;

        # add suffix for correct sorting
        for my $DataKey ( sort keys %Data ) {
            $Data{$DataKey} .= '::';
        }

        if ( !%ServiceData ) {
            $LayoutObject->Block(
                Name => 'NoDataFoundMsgList',
                Data => {
                    ColSpan => $ColSpan,
                },
            );
        }
    }

    # output rows
    for my $ID ( sort { uc( $Data{$a} ) cmp uc( $Data{$b} ) } keys %Data ) {

        # set checked
        my $Checked = $Param{Selected}->{$ID} ? "checked='checked'" : '';

        # Recover original Service Name
        if ( $NeType eq 'Service' ) {
            $Data{$ID} = $ServiceData{$ID};
        }

        # output row block
        $LayoutObject->Block(
            Name => 'AllocateItemRow',
            Data => {
                ActionNeHome => 'Admin' . $NeType,
                Name         => $Data{$ID},
                ID           => $ID,
                Checked      => $Checked,
                SubactionRow => $Subaction{$NeType},
                IDRowStrg    => $IDStrg{$NeType},

            },
        );
    }

    # generate output
    return $LayoutObject->Output(
        TemplateFile => 'AdminCustomerCompanyService',
        Data         => \%Param,
    );
}

sub _Overview {
    my ( $Self, %Param ) = @_;

    my $CustomerCompanyCount   = $Param{CustomerCompanyCount};
    my @CustomerCompanyKeyList = @{ $Param{CustomerCompanyKeyList} };
    my $SearchLimit            = $Param{SearchLimit};
    my %CustomerCompanyData    = %{ $Param{CustomerCompanyData} };
    my %ServiceData            = %{ $Param{ServiceData} };

    my $LayoutObject = $Kernel::OM->Get('Kernel::Output::HTML::Layout');

    # overview
    $LayoutObject->Block(
        Name => 'Overview',
        Data => {
            %Param,
            OverviewLink => $Self->{Action},
        },
    );
    $LayoutObject->Block( Name => 'ActionList' );

    # output search block
    $LayoutObject->Block(
        Name => 'Search',
        Data => {
            %Param,
            CustomerCompanySearch => $Param{CustomerCompanySearch},
        },
    );
    $LayoutObject->Block(
        Name => 'Default',
    );

    # output filter and default block
    $LayoutObject->Block(
        Name => 'Filter',
    );

    # output result block
    $LayoutObject->Block(
        Name => 'Result',
        Data => {
            %Param,
            CustomerCompanyCount => $CustomerCompanyCount,
        },
    );

    # output customer company count block
    if ( !@CustomerCompanyKeyList ) {
        $LayoutObject->Block(
            Name => 'ResultCustomerCompanyCountLimit',
            Data => { CustomerCompanyCount => 0 },
        );

        $LayoutObject->Block(
            Name => 'NoDataFoundMsg',
        );
    }
    elsif ( @CustomerCompanyKeyList > $SearchLimit ) {
        $LayoutObject->Block(
            Name => 'ResultCustomerCompanyCountLimit',
            Data => { CustomerCompanyCount => ">" . $SearchLimit },
        );
    }
    else {
        $LayoutObject->Block(
            Name => 'ResultCustomerCompanyCount',
            Data => { CustomerCompanyCount => scalar @CustomerCompanyKeyList },
        );
    }

    for my $ID (
        sort { uc( $CustomerCompanyData{$a} ) cmp uc( $CustomerCompanyData{$b} ) }
        keys %CustomerCompanyData
        )
    {

        # output customer company row block
        $LayoutObject->Block(
            Name => 'ResultCompanyRow',
            Data => {
                %Param,
                ID   => $ID,
                Name => $CustomerCompanyData{$ID},
            },
        );
    }

    my %ServiceDataSort = %ServiceData;

    # add suffix for correct sorting
    for my $ServiceDataKey ( sort keys %ServiceDataSort ) {
        $ServiceDataSort{$ServiceDataKey} .= '::';
    }

    # get service data
    if (%ServiceDataSort) {
        for my $ID (
            sort { uc( $ServiceDataSort{$a} ) cmp uc( $ServiceDataSort{$b} ) }
            keys %ServiceDataSort
            )
        {

            # output service row block
            $LayoutObject->Block(
                Name => 'ResultServiceRow',
                Data => {
                    %Param,
                    ID   => $ID,
                    Name => $ServiceData{$ID},
                },
            );
        }
    }

    # otherwise a no data message is displayed
    else {
        $LayoutObject->Block(
            Name => 'NoServiceFoundMsg',
            Data => {},
        );
    }

    # generate output
    return $LayoutObject->Output(
        TemplateFile => 'AdminCustomerCompanyService',
        Data         => \%Param,
    );
}

1;
