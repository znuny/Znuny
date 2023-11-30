# --
# Copyright (C) 2001-2021 OTRS AG, https://otrs.com/
# Copyright (C) 2021 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see https://www.gnu.org/licenses/gpl-3.0.txt.
# --

package Kernel::Output::HTML::Dashboard::CustomerIDList;

use strict;
use warnings;

use Kernel::Language qw(Translatable);

our $ObjectManagerDisabled = 1;

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {%Param};
    bless( $Self, $Type );

    # get needed parameters
    for my $Needed (qw(Config Name UserID)) {
        die "Got no $Needed!" if ( !$Self->{$Needed} );
    }

    # get param object
    my $ParamObject = $Kernel::OM->Get('Kernel::System::Web::Request');

    # get current filter
    my $Name           = $ParamObject->GetParam( Param => 'Name' ) || '';
    my $PreferencesKey = 'UserDashboardCustomerIDListFilter' . $Self->{Name};

    $Self->{PrefKey} = 'UserDashboardPref' . $Self->{Name} . '-Shown';

    $Self->{PageShown} = $Kernel::OM->Get('Kernel::Output::HTML::Layout')->{ $Self->{PrefKey} }
        || $Self->{Config}->{Limit};

    $Self->{StartHit} = int( $ParamObject->GetParam( Param => 'StartHit' ) || 1 );

    return $Self;
}

sub Preferences {
    my ( $Self, %Param ) = @_;

    my @Params = (
        {
            Desc  => Translatable('Shown customer ids'),
            Name  => $Self->{PrefKey},
            Block => 'Option',

            #            Block => 'Input',
            Data => {
                5  => ' 5',
                10 => '10',
                15 => '15',
                20 => '20',
                25 => '25',
            },
            SelectedID  => $Self->{PageShown},
            Translation => 0,
        },
    );

    return @Params;
}

sub Config {
    my ( $Self, %Param ) = @_;

    return (
        %{ $Self->{Config} },

        # remember, do not allow to use page cache
        # (it's not working because of internal filter)
        CacheTTL => undef,
        CacheKey => undef,
    );
}

sub Run {
    my ( $Self, %Param ) = @_;

    return if !$Param{CustomerUserID};

    my $ConfigObject          = $Kernel::OM->Get('Kernel::Config');
    my $CustomerUserObject    = $Kernel::OM->Get('Kernel::System::CustomerUser');
    my $CustomerCompanyObject = $Kernel::OM->Get('Kernel::System::CustomerCompany');
    my $GroupObject           = $Kernel::OM->Get('Kernel::System::Group');
    my $LayoutObject          = $Kernel::OM->Get('Kernel::Output::HTML::Layout');

    # get all customer ids of this customer user
    my @CustomerIDs = $CustomerUserObject->CustomerIDs(
        User => $Param{CustomerUserID},
    );

    # add page nav bar
    my $Total = scalar @CustomerIDs;

    my $LinkPage = 'Subaction=Element;Name='
        . $Self->{Name} . ';'
        . 'CustomerUserID='
        . $LayoutObject->LinkEncode( $Param{CustomerUserID} ) . ';';

    my %PageNav = $LayoutObject->PageNavBar(
        StartHit    => $Self->{StartHit},
        PageShown   => $Self->{PageShown},
        AllHits     => $Total || 1,
        Action      => 'Action=' . $LayoutObject->{Action},
        Link        => $LinkPage,
        AJAXReplace => 'Dashboard' . $Self->{Name},
        IDPrefix    => 'Dashboard' . $Self->{Name},
        AJAX        => $Param{AJAX},
    );

    $LayoutObject->Block(
        Name => 'ContentLargeCustomerIDNavBar',
        Data => {
            %{ $Self->{Config} },
            Name => $Self->{Name},
            %PageNav,
        },
    );

    # show change customer relations button if the agent has permission
    my $ChangeCustomerReleationsAccess = $LayoutObject->Permission(
        Action => 'AdminCustomerUserCustomer',
        Type   => 'rw',                          # ro|rw possible
    );

    if ($ChangeCustomerReleationsAccess) {
        $LayoutObject->Block(
            Name => 'ContentLargeCustomerIDAdd',
            Data => {
                CustomerUserID => $Param{CustomerUserID},
            },
        );
    }

    # show links to edit customer id if the agent has permission
    my $EditCustomerIDPermission = $LayoutObject->Permission(
        Action => 'AdminCustomerCompany',
        Type   => 'rw',
    );

    # show link to create new phone ticket if the agent has permission
    my $AgentTicketPhonePermission = $LayoutObject->Permission(
        Action => 'AgentTicketPhone',
        Type   => 'rw',
    );

    # show link to create new email ticket if the agent has permission
    my $AgentTicketEmailPermission = $LayoutObject->Permission(
        Action => 'AgentTicketEmail',
        Type   => 'rw',
    );

    # check the permission for the SwitchToCustomer feature
    my $SwitchToCustomerPermission = 0;
    if ( $ConfigObject->Get('SwitchToCustomer') ) {

        # get the group id which is allowed to use the switch to customer feature
        my $PermissionGroup         = $ConfigObject->Get('SwitchToCustomer::PermissionGroup');
        my $SwitchToCustomerGroupID = $GroupObject->GroupLookup(
            Group => $PermissionGroup,
        );

        # get user groups, where the user has the rw privilege
        my %Groups = $GroupObject->PermissionUserGet(
            UserID => $Self->{UserID},
            Type   => 'rw',
        );

        # if the user is a member in this group he can access the feature
        if ( $Groups{$SwitchToCustomerGroupID} ) {
            $SwitchToCustomerPermission = 1;
        }
    }

    @CustomerIDs = splice @CustomerIDs, $Self->{StartHit} - 1, $Self->{PageShown};

    for my $CustomerID (@CustomerIDs) {

        # get customer company data
        my %CustomerCompany = $CustomerCompanyObject->CustomerCompanyGet(
            CustomerID => $CustomerID,
        );

        $LayoutObject->Block(
            Name => 'ContentLargeCustomerIDListRow',
            Data => {
                %Param,
                %CustomerCompany,
                CustomerID                 => $CustomerID,
                EditCustomerIDPermission   => %CustomerCompany ? $EditCustomerIDPermission : 0,
                AgentTicketPhonePermission => $AgentTicketPhonePermission,
                AgentTicketEmailPermission => $AgentTicketEmailPermission,
                SwitchToCustomerPermission => $SwitchToCustomerPermission,
            },
        );

        # get ticket object
        my $TicketObject = $Kernel::OM->Get('Kernel::System::Ticket');

        my $TicketCountOpen = $TicketObject->TicketSearch(
            StateType  => 'Open',
            CustomerID => $CustomerID,
            Result     => 'COUNT',
            Permission => $Self->{Config}->{Permission},
            UserID     => $Self->{UserID},
            CacheTTL   => $Self->{Config}->{CacheTTLLocal} * 60,
        ) || 0;

        my $CustomerIDSQL = $Kernel::OM->Get('Kernel::System::DB')->QueryStringEscape( QueryString => $CustomerID );

        $LayoutObject->Block(
            Name => 'ContentLargeCustomerIDListRowCustomerIDTicketsOpen',
            Data => {
                %Param,
                Count         => $TicketCountOpen,
                CustomerID    => $CustomerID,
                CustomerIDSQL => $CustomerIDSQL,
            },
        );

        my $TicketCountClosed = $TicketObject->TicketSearch(
            StateType  => 'Closed',
            CustomerID => $CustomerID,
            Result     => 'COUNT',
            Permission => $Self->{Config}->{Permission},
            UserID     => $Self->{UserID},
            CacheTTL   => $Self->{Config}->{CacheTTLLocal} * 60,
        ) || 0;

        $LayoutObject->Block(
            Name => 'ContentLargeCustomerIDListRowCustomerIDTicketsClosed',
            Data => {
                %Param,
                Count         => $TicketCountClosed,
                CustomerID    => $CustomerID,
                CustomerIDSQL => $CustomerIDSQL,
            },
        );
    }

    # show "none" if there are no customers
    if ( !@CustomerIDs ) {
        $LayoutObject->Block(
            Name => 'ContentLargeCustomerIDListNone',
            Data => {},
        );
    }

    # check for refresh time
    my $Refresh = '';
    if ( $Self->{UserRefreshTime} ) {
        $Refresh = 60 * $Self->{UserRefreshTime};
        my $NameHTML = $Self->{Name};
        $NameHTML =~ s{-}{_}xmsg;

        # send data to JS
        $LayoutObject->AddJSData(
            Key   => 'CustomerIDRefresh',
            Value => {
                %{ $Self->{Config} },
                Name        => $Self->{Name},
                NameHTML    => $NameHTML,
                RefreshTime => $Refresh,
                CustomerID  => $Param{CustomerID},
            },
        );
    }

    my $Content = $LayoutObject->Output(
        TemplateFile => 'AgentDashboardCustomerIDList',
        Data         => {
            %{ $Self->{Config} },
            Name                       => $Self->{Name},
            EditCustomerIDPermission   => $EditCustomerIDPermission,
            AgentTicketPhonePermission => $AgentTicketPhonePermission,
            AgentTicketEmailPermission => $AgentTicketEmailPermission,
            SwitchToCustomerPermission => $SwitchToCustomerPermission,
        },
        AJAX => $Param{AJAX},
    );

    return $Content;
}

1;
