# --
# Copyright (C) 2001-2021 OTRS AG, https://otrs.com/
# Copyright (C) 2021-2022 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see https://www.gnu.org/licenses/gpl-3.0.txt.
# --

package Kernel::Modules::AdminCustomerUserService;

use strict;
use warnings;

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

    my $LayoutObject       = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $ParamObject        = $Kernel::OM->Get('Kernel::System::Web::Request');
    my $ServiceObject      = $Kernel::OM->Get('Kernel::System::Service');
    my $CustomerUserObject = $Kernel::OM->Get('Kernel::System::CustomerUser');

    # set search limit
    my $SearchLimit = 200;

    # ------------------------------------------------------------ #
    # allocate customer user
    # ------------------------------------------------------------ #
    if ( $Self->{Subaction} eq 'AllocateCustomerUser' ) {

        # get params
        $Param{CustomerUserLogin} = $ParamObject->GetParam( Param => 'CustomerUserLogin' )
            || '<DEFAULT>';
        $Param{CustomerUserSearch} = $ParamObject->GetParam( Param => 'CustomerUserSearch' )
            || '*';

        # output header
        my $Output = $LayoutObject->Header();
        $Output .= $LayoutObject->NavigationBar();

        # get service member
        my %ServiceMemberList = $ServiceObject->CustomerUserServiceMemberList(
            CustomerUserLogin => $Param{CustomerUserLogin},
            Result            => 'HASH',
            DefaultServices   => 0,
        );

        # List services.
        my %ServiceData = $ServiceObject->ServiceList(
            KeepChildren => 1,
            UserID       => $Self->{UserID},
        );

        if ( $Param{CustomerUserLogin} eq '<DEFAULT>' ) {
            $Param{Name} = q{};
        }
        else {
            $Param{Name} = $CustomerUserObject->CustomerName( UserLogin => $Param{CustomerUserLogin} )
                . " ($Param{CustomerUserLogin})";
        }

        $Output .= $Self->_Change(
            ID                 => $Param{CustomerUserLogin},
            Name               => $Param{Name},
            Data               => \%ServiceData,
            Selected           => \%ServiceMemberList,
            CustomerUserSearch => $Param{CustomerUserSearch},
            ServiceSearch      => $Param{ServiceSearch},
            SearchLimit        => $SearchLimit,
            Type               => 'CustomerUser',
        );

        $Output .= $LayoutObject->Footer();

        return $Output;
    }

    # ------------------------------------------------------------ #
    # allocate service
    # ------------------------------------------------------------ #
    elsif ( $Self->{Subaction} eq 'AllocateService' ) {

        # get params
        $Param{ServiceID} = $ParamObject->GetParam( Param => "ServiceID" );

        $Param{Subaction} = $ParamObject->GetParam( Param => 'Subaction' );

        $Param{CustomerUserSearch} = $ParamObject->GetParam( Param => "CustomerUserSearch" )
            || '*';

        # output header
        my $Output = $LayoutObject->Header();
        $Output .= $LayoutObject->NavigationBar();

        # get service
        my %Service = $ServiceObject->ServiceGet(
            ServiceID => $Param{ServiceID},
            UserID    => $Self->{UserID},
        );

        # get customer user member
        my %CustomerUserMemberList = $ServiceObject->CustomerUserServiceMemberList(
            ServiceID       => $Param{ServiceID},
            Result          => 'HASH',
            DefaultServices => 0,
        );

        # search customer user
        my %CustomerUserList = $CustomerUserObject->CustomerSearch(
            Search => $Param{CustomerUserSearch},
        );
        my @CustomerUserKeyList = sort { $CustomerUserList{$a} cmp $CustomerUserList{$b} } keys %CustomerUserList;

        # set max count
        my $MaxCount = @CustomerUserKeyList;
        if ( $MaxCount > $SearchLimit ) {
            $MaxCount = $SearchLimit;
        }

        my %CustomerData;

        # output rows
        for my $Counter ( 1 .. $MaxCount ) {

            # get service
            my %User = $CustomerUserObject->CustomerUserDataGet(
                User => $CustomerUserKeyList[ $Counter - 1 ],
            );
            my $UserName = $CustomerUserObject->CustomerName(
                UserLogin => $CustomerUserKeyList[ $Counter - 1 ]
            );
            my $CustomerUser = "$UserName <$User{UserEmail}> ($User{UserCustomerID})";
            $CustomerData{ $User{UserID} } = $CustomerUser;
        }

        $Output .= $Self->_Change(
            ID                 => $Param{ServiceID},
            Name               => $Service{Name},
            ItemList           => \@CustomerUserKeyList,
            Data               => \%CustomerData,
            Selected           => \%CustomerUserMemberList,
            CustomerUserSearch => $Param{CustomerUserSearch},
            SearchLimit        => $SearchLimit,
            Type               => 'Service',
            %Param,
        );

        $Output .= $LayoutObject->Footer();

        return $Output;
    }

    # ------------------------------------------------------------ #
    # allocate customer user save
    # ------------------------------------------------------------ #
    elsif ( $Self->{Subaction} eq 'AllocateCustomerUserSave' ) {

        # challenge token check for write action
        $LayoutObject->ChallengeTokenCheck();

        # get params
        $Param{CustomerUserLogin} = $ParamObject->GetParam( Param => 'ID' );

        $Param{CustomerUserSearch} = $ParamObject->GetParam( Param => 'CustomerUserSearch' )
            || '*';

        my @ServiceIDsSelected = $ParamObject->GetArray( Param => 'ItemsSelected' );
        my @ServiceIDsAll      = $ParamObject->GetArray( Param => 'ItemsAll' );

        # create hash with selected ids
        my %ServiceIDSelected = map { $_ => 1 } @ServiceIDsSelected;

        # check all used service ids
        for my $ServiceID (@ServiceIDsAll) {
            my $Active = $ServiceIDSelected{$ServiceID} ? 1 : 0;

            # set customer user service member
            $ServiceObject->CustomerUserServiceMemberAdd(
                CustomerUserLogin => $Param{CustomerUserLogin},
                ServiceID         => $ServiceID,
                Active            => $Active,
                UserID            => $Self->{UserID},
            );
        }

        # if the user would like to continue editing the customer user allocating just redirect to the edit screen
        if (
            defined $ParamObject->GetParam( Param => 'ContinueAfterSave' )
            && ( $ParamObject->GetParam( Param => 'ContinueAfterSave' ) eq '1' )
            )
        {
            return $LayoutObject->Redirect(
                OP =>
                    "Action=$Self->{Action};Subaction=AllocateCustomerUser;CustomerUserLogin=$Param{CustomerUserLogin};CustomerUserSearch=$Param{CustomerUserSearch}"
            );
        }
        else {

            # otherwise return to relations overview
            return $LayoutObject->Redirect(
                OP => "Action=$Self->{Action};CustomerUserSearch=$Param{CustomerUserSearch}"
            );
        }
    }

    # ------------------------------------------------------------ #
    # allocate service save
    # ------------------------------------------------------------ #
    elsif ( $Self->{Subaction} eq 'AllocateServiceSave' ) {

        # challenge token check for write action
        $LayoutObject->ChallengeTokenCheck();

        # get params
        $Param{ServiceID} = $ParamObject->GetParam( Param => "ID" );

        $Param{CustomerUserSearch} = $ParamObject->GetParam( Param => 'CustomerUserSearch' )
            || '*';

        my @CustomerUserLoginsSelected = $ParamObject->GetArray( Param => 'ItemsSelected' );
        my @CustomerUserLoginsAll      = $ParamObject->GetArray( Param => 'ItemsAll' );

        # create hash with selected customer users
        my %CustomerUserLoginsSelected;
        for my $CustomerUserLogin (@CustomerUserLoginsSelected) {
            $CustomerUserLoginsSelected{$CustomerUserLogin} = 1;
        }

        # check all used customer users
        for my $CustomerUserLogin (@CustomerUserLoginsAll) {
            my $Active = $CustomerUserLoginsSelected{$CustomerUserLogin} ? 1 : 0;

            # set customer user service member
            $ServiceObject->CustomerUserServiceMemberAdd(
                CustomerUserLogin => $CustomerUserLogin,
                ServiceID         => $Param{ServiceID},
                Active            => $Active,
                UserID            => $Self->{UserID},
            );
        }

        # if the user would like to continue editing the customer user allocating just redirect to the edit screen
        if (
            defined $ParamObject->GetParam( Param => 'ContinueAfterSave' )
            && ( $ParamObject->GetParam( Param => 'ContinueAfterSave' ) eq '1' )
            )
        {
            return $LayoutObject->Redirect(
                OP =>
                    "Action=$Self->{Action};Subaction=AllocateService;ServiceID=$Param{ServiceID};CustomerUserSearch=$Param{CustomerUserSearch}"
            );
        }
        else {

            # otherwise return to relations overview
            return $LayoutObject->Redirect(
                OP =>
                    "Action=$Self->{Action};CustomerUserSearch=$Param{CustomerUserSearch}"
            );
        }
    }

    # ------------------------------------------------------------ #
    # overview
    # ------------------------------------------------------------ #
    else {

        # get params
        $Param{CustomerUserSearch} = $ParamObject->GetParam( Param => 'CustomerUserSearch' )
            || '*';

        # output header
        my $Output = $LayoutObject->Header();
        $Output .= $LayoutObject->NavigationBar();

        # search customer user
        my %CustomerUserList = $CustomerUserObject->CustomerSearch(
            Search => $Param{CustomerUserSearch},
        );
        my @CustomerUserKeyList = sort { $CustomerUserList{$a} cmp $CustomerUserList{$b} } keys %CustomerUserList;

        # count results
        my $CustomerUserCount = @CustomerUserKeyList;

        # set max count
        my $MaxCustomerCount = $CustomerUserCount;

        if ( $MaxCustomerCount > $SearchLimit ) {
            $MaxCustomerCount = $SearchLimit;
        }

        # output rows
        my %UserRowParam;
        for my $Counter ( 1 .. $MaxCustomerCount ) {

            # set customer user row params
            if ( defined( $CustomerUserKeyList[ $Counter - 1 ] ) ) {

                # Get user details
                my %User = $CustomerUserObject->CustomerUserDataGet(
                    User => $CustomerUserKeyList[ $Counter - 1 ]
                );
                my $UserName = $CustomerUserObject->CustomerName(
                    UserLogin => $CustomerUserKeyList[ $Counter - 1 ]
                );
                $UserRowParam{ $User{UserID} } = "$UserName <$User{UserEmail}> ($User{UserCustomerID})";
            }
        }

        my %ServiceData = $ServiceObject->ServiceList(
            KeepChildren => 1,
            UserID       => $Self->{UserID},
        );

        $Output .= $Self->_Overview(
            CustomerUserCount   => $CustomerUserCount,
            CustomerUserKeyList => \@CustomerUserKeyList,
            CustomerUserData    => \%UserRowParam,
            ServiceData         => \%ServiceData,
            SearchLimit         => $SearchLimit,
            CustomerUserSearch  => $Param{CustomerUserSearch},
        );

        $Output .= $LayoutObject->Footer();

        return $Output;
    }
}

sub _Change {
    my ( $Self, %Param ) = @_;

    my $SearchLimit = $Param{SearchLimit};
    my %Data        = %{ $Param{Data} };
    my $Type        = $Param{Type} || 'CustomerUser';
    my $NeType      = $Type eq 'Service' ? 'CustomerUser' : 'Service';
    my %VisibleType = (
        CustomerUser => 'Customer',
        Service      => 'Service',
    );
    my %Subaction = (
        CustomerUser => 'Change',
        Service      => 'ServiceEdit',
    );
    my %IDStrg = (
        CustomerUser => 'ID',
        Service      => 'ServiceID',
    );

    my @ItemList = ();

    my $LayoutObject = $Kernel::OM->Get('Kernel::Output::HTML::Layout');

    if ( $VisibleType{$NeType} eq 'Customer' ) {
        $Param{BreadcrumbTitle} = Translatable('Allocate Customer Users to Service');
    }
    else {
        $Param{BreadcrumbTitle} = Translatable('Allocate Services to Customer User');
    }

    # overview
    $LayoutObject->Block(
        Name => 'Overview',
        Data => {
            %Param,
            OverviewLink => $Self->{Action} . ';CustomerUserSearch=' . $Param{CustomerUserSearch},
        },
    );
    $LayoutObject->Block( Name => 'ActionList' );
    $LayoutObject->Block(
        Name => 'ActionOverview',
        Data => {
            CustomerUserSearch => $Param{CustomerUserSearch},
        },
    );

    if ( $NeType eq 'CustomerUser' ) {
        @ItemList = @{ $Param{ItemList} };

        # output search block
        $LayoutObject->Block(
            Name => 'Search',
            Data => {
                %Param,
                CustomerUserSearch => $Param{CustomerUserSearch},
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

    if ( $NeType eq 'CustomerUser' ) {

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
        TemplateFile => 'AdminCustomerUserService',
        Data         => \%Param,
    );
}

sub _Overview {
    my ( $Self, %Param ) = @_;

    my $CustomerUserCount   = $Param{CustomerUserCount};
    my @CustomerUserKeyList = @{ $Param{CustomerUserKeyList} };
    my $SearchLimit         = $Param{SearchLimit};
    my %CustomerUserData    = %{ $Param{CustomerUserData} };
    my %ServiceData         = %{ $Param{ServiceData} };

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
            CustomerUserSearch => $Param{CustomerUserSearch},
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
            CustomerUserCount => $CustomerUserCount,
        },
    );

    # output customer user count block
    if ( !@CustomerUserKeyList ) {
        $LayoutObject->Block(
            Name => 'ResultCustomerUserCountLimit',
            Data => { CustomerUserCount => 0 },
        );

        $LayoutObject->Block(
            Name => 'NoDataFoundMsg',
        );
    }
    elsif ( @CustomerUserKeyList > $SearchLimit ) {
        $LayoutObject->Block(
            Name => 'ResultCustomerUserCountLimit',
            Data => { CustomerUserCount => ">" . $SearchLimit },
        );
    }
    else {
        $LayoutObject->Block(
            Name => 'ResultCustomerUserCount',
            Data => { CustomerUserCount => scalar @CustomerUserKeyList },
        );
    }

    for my $ID (
        sort { uc( $CustomerUserData{$a} ) cmp uc( $CustomerUserData{$b} ) }
        keys %CustomerUserData
        )
    {

        # output user row block
        $LayoutObject->Block(
            Name => 'ResultUserRow',
            Data => {
                %Param,
                ID   => $ID,
                Name => $CustomerUserData{$ID},
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
        TemplateFile => 'AdminCustomerUserService',
        Data         => \%Param,
    );
}

1;
