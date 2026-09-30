# --
# Copyright (C) 2001-2021 OTRS AG, https://otrs.com/
# Copyright (C) 2021 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see https://www.gnu.org/licenses/gpl-3.0.txt.
# --

package Kernel::Modules::AgentTicketWatchView;

use strict;
use warnings;
use utf8;

our $ObjectManagerDisabled = 1;

use Kernel::System::VariableCheck qw(:all);
use Kernel::Language              qw(Translatable);

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {%Param};
    bless( $Self, $Type );

    return $Self;
}

sub Run {
    my ( $Self, %Param ) = @_;

    # get needed objects
    my $ParamObject        = $Kernel::OM->Get('Kernel::System::Web::Request');
    my $ConfigObject       = $Kernel::OM->Get('Kernel::Config');
    my $LayoutObject       = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $SessionObject      = $Kernel::OM->Get('Kernel::System::AuthSession');
    my $DynamicFieldObject = $Kernel::OM->Get('Kernel::System::DynamicField');

    # get config parameter
    my $Config = $ConfigObject->Get("Ticket::Frontend::$Self->{Action}");

    my $SortBy = $ParamObject->GetParam( Param => 'SortBy' )
        || $Config->{'SortBy::Default'}
        || 'Age';
    my $OrderBy = $ParamObject->GetParam( Param => 'OrderBy' )
        || $Config->{'Order::Default'}
        || 'Up';

    # store last screen
    $SessionObject->UpdateSessionID(
        SessionID => $Self->{SessionID},
        Key       => 'LastScreenView',
        Value     => $Self->{RequestedURL},
    );

    # store last queue screen
    $SessionObject->UpdateSessionID(
        SessionID => $Self->{SessionID},
        Key       => 'LastScreenOverview',
        Value     => $Self->{RequestedURL},
    );

    # get user object
    my $UserObject = $Kernel::OM->Get('Kernel::System::User');

    # get filters stored in the user preferences
    my %Preferences = $UserObject->GetPreferences(
        UserID => $Self->{UserID},
    );

    my $JSONObject       = $Kernel::OM->Get('Kernel::System::JSON');
    my $StoredFiltersKey = 'UserStoredFilterColumns-' . $Self->{Action};
    my $StoredFilters    = $JSONObject->Decode(
        Data => $Preferences{$StoredFiltersKey},
    );

    # delete stored filters if needed
    if ( $ParamObject->GetParam( Param => 'DeleteFilters' ) ) {
        $StoredFilters = {};
    }

    # get the column filters from the web request or user preferences
    my %ColumnFilter;
    my %GetColumnFilter;

    COLUMNNAME:
    for my $ColumnName (
        qw(Owner Responsible State Queue Priority Type Lock Service SLA CustomerID CustomerUserID)
        )
    {
        # get column filter from web request
        my @FilterValues = $ParamObject->GetArray( Param => 'ColumnFilter' . $ColumnName );

        # if filter is not present in the web request, try with the user preferences
        if ( !@FilterValues ) {
            if ( $ColumnName eq 'CustomerID' ) {
                @FilterValues = @{ $StoredFilters->{$ColumnName} || [] };
            }
            elsif ( $ColumnName eq 'CustomerUserID' ) {
                @FilterValues = @{ $StoredFilters->{CustomerUserLogin} || [] };
            }
            else {
                @FilterValues = @{ $StoredFilters->{ $ColumnName . 'IDs' } || [] };
            }
        }

        if (@FilterValues) {
            my @ExpandedValues;
            for my $Value (@FilterValues) {
                push @ExpandedValues, $Value;
            }
            my %Seen;
            @FilterValues = grep { defined $_ && $_ ne '' && $_ ne 'DeleteFilter' && !$Seen{$_}++ } @ExpandedValues;
        }
        else {
            @FilterValues = ();
        }
        next COLUMNNAME if !@FilterValues;

        if ( $ColumnName eq 'CustomerID' ) {
            push @{ $ColumnFilter{$ColumnName} },           @FilterValues;
            push @{ $ColumnFilter{ $ColumnName . 'Raw' } }, @FilterValues;
            $GetColumnFilter{$ColumnName} = \@FilterValues;
        }
        elsif ( $ColumnName eq 'CustomerUserID' ) {
            push @{ $ColumnFilter{CustomerUserLogin} },    @FilterValues;
            push @{ $ColumnFilter{CustomerUserLoginRaw} }, @FilterValues;
            $GetColumnFilter{$ColumnName} = \@FilterValues;
        }
        else {
            push @{ $ColumnFilter{ $ColumnName . 'IDs' } }, @FilterValues;
            $GetColumnFilter{$ColumnName} = \@FilterValues;
        }
    }

    # get all dynamic fields
    $Self->{DynamicField} = $DynamicFieldObject->DynamicFieldListGet(
        Valid      => 1,
        ObjectType => ['Ticket'],
    );

    DYNAMICFIELD:
    for my $DynamicFieldConfig ( @{ $Self->{DynamicField} } ) {
        next DYNAMICFIELD if !IsHashRefWithData($DynamicFieldConfig);
        next DYNAMICFIELD if !$DynamicFieldConfig->{Name};

        # get filter from web request
        my @FilterValues = $ParamObject->GetArray(
            Param => 'ColumnFilterDynamicField_' . $DynamicFieldConfig->{Name}
        );

        # if no filter from web request, try from user preferences
        if ( !@FilterValues ) {
            my $StoredValue = $StoredFilters->{ 'DynamicField_' . $DynamicFieldConfig->{Name} }->{Equals};
            @FilterValues = ref $StoredValue eq 'ARRAY' ? @{$StoredValue} : ($StoredValue);
        }

        if (@FilterValues) {
            my @ExpandedValues;
            for my $Value (@FilterValues) {
                push @ExpandedValues, $Value;
            }
            my %Seen;
            @FilterValues = grep { defined $_ && $_ ne '' && $_ ne 'DeleteFilter' && !$Seen{$_}++ } @ExpandedValues;
        }
        else {
            @FilterValues = ();
        }
        next DYNAMICFIELD if !@FilterValues;

        $ColumnFilter{ 'DynamicField_' . $DynamicFieldConfig->{Name} } = {
            Equals => \@FilterValues,
        };
        $GetColumnFilter{ 'DynamicField_' . $DynamicFieldConfig->{Name} } = \@FilterValues;
    }

    # starting with page ...
    my $Refresh = '';
    if ( $Self->{UserRefreshTime} ) {
        $Refresh = 60 * $Self->{UserRefreshTime};
    }
    my $Output;
    if ( $Self->{Subaction} ne 'AJAXFilterUpdate' ) {
        $Output = $LayoutObject->Header(
            Refresh => $Refresh,
        );
        $Output .= $LayoutObject->NavigationBar();
    }

    # Notify if there are tickets which are not updated.
    $Output .= $LayoutObject->NotifyNonUpdatedTickets() // '';

    # get locked  viewable tickets...
    my $SortByS = $SortBy;
    if ( $SortByS eq 'CreateTime' ) {
        $SortByS = 'Age';
    }

    # check if feature is active
    my $Access = 0;
    if ( $ConfigObject->Get('Ticket::Watcher') ) {
        my @Groups;
        if ( $ConfigObject->Get('Ticket::WatcherGroup') ) {
            @Groups = @{ $ConfigObject->Get('Ticket::WatcherGroup') };
        }

        # check access
        if ( !@Groups ) {
            $Access = 1;
        }
        else {
            my $GroupObject = $Kernel::OM->Get('Kernel::System::Group');
            GROUP:
            for my $Group (@Groups) {
                my $HasPermission = $GroupObject->PermissionCheck(
                    UserID    => $Self->{UserID},
                    GroupName => $Group,
                    Type      => 'rw',
                );
                if ($HasPermission) {
                    $Access = 1;
                    last GROUP;
                }
            }
        }
    }

    if ( !$Access ) {
        $LayoutObject->FatalError(
            Message => Translatable('Feature not enabled!'),
        );
    }

    my $UserIDForSearch = $Config->{TicketSearchWithAdminUser} ? 1 : $Self->{UserID};

    my %Filters = (
        All => {
            Name   => Translatable('All'),
            Prio   => 1000,
            Search => {
                OrderBy      => $OrderBy,
                SortBy       => $SortByS,
                WatchUserIDs => [ $Self->{UserID} ],
                UserID       => $UserIDForSearch,
                Permission   => 'ro',
            },
        },
        New => {
            Name   => Translatable('New Article'),
            Prio   => 1001,
            Search => {
                WatchUserIDs  => [ $Self->{UserID} ],
                NotTicketFlag => {
                    Seen => 1,
                },
                TicketFlagUserID => $Self->{UserID},
                OrderBy          => $OrderBy,
                SortBy           => $SortByS,
                UserID           => $UserIDForSearch,
                Permission       => 'ro',
            },
        },
        Reminder => {
            Name   => Translatable('Pending'),
            Prio   => 1002,
            Search => {
                StateType    => [ 'pending reminder', 'pending auto' ],
                WatchUserIDs => [ $Self->{UserID} ],
                OrderBy      => $OrderBy,
                SortBy       => $SortByS,
                UserID       => $UserIDForSearch,
                Permission   => 'ro',
            },
        },
        ReminderReached => {
            Name   => Translatable('Reminder Reached'),
            Prio   => 1003,
            Search => {
                StateType                     => ['pending reminder'],
                TicketPendingTimeOlderMinutes => 1,
                WatchUserIDs                  => [ $Self->{UserID} ],
                OrderBy                       => $OrderBy,
                SortBy                        => $SortByS,
                UserID                        => $UserIDForSearch,
                Permission                    => 'ro',
            },
        },
    );

    my $Filter = $ParamObject->GetParam( Param => 'Filter' ) || 'All';

    # check if filter is valid
    if ( !$Filters{$Filter} ) {
        $LayoutObject->FatalError(
            Message => $LayoutObject->{LanguageObject}->Translate( 'Invalid Filter: %s!', $Filter ),
        );
    }

    # do shown tickets lookup
    my $Limit = 10_000;

    my $ElementChanged = $ParamObject->GetParam( Param => 'ElementChanged' ) || '';
    my $HeaderColumn   = $ElementChanged;
    $HeaderColumn =~ s{\A ColumnFilter }{}msxg;
    my @OriginalViewableTickets;
    my @ViewableTickets;

    # get ticket object
    my $TicketObject = $Kernel::OM->Get('Kernel::System::Ticket');

    # get ticket values
    if (
        !IsStringWithData($HeaderColumn)
        || (
            IsStringWithData($HeaderColumn)
            && (
                $ConfigObject->Get('OnlyValuesOnTicket') ||
                $HeaderColumn eq 'CustomerID' ||
                $HeaderColumn eq 'CustomerUserID'
            )
        )
        )
    {

        @OriginalViewableTickets = $TicketObject->TicketSearch(
            %{ $Filters{$Filter}->{Search} },
            Limit  => $Limit,
            Result => 'ARRAY',
        );

        @ViewableTickets = $TicketObject->TicketSearch(
            %{ $Filters{$Filter}->{Search} },
            %ColumnFilter,
            Result => 'ARRAY',
            Limit  => $Limit,
        );
    }

    my $View = $ParamObject->GetParam( Param => 'View' ) || '';

    if ( $Self->{Subaction} eq 'AJAXFilterUpdate' ) {

        my $FilterContent = $LayoutObject->TicketListShow(
            FilterContentOnly   => 1,
            HeaderColumn        => $HeaderColumn,
            ElementChanged      => $ElementChanged,
            OriginalTicketIDs   => \@OriginalViewableTickets,
            Action              => 'AgentTicketStatusView',
            Env                 => $Self,
            View                => $View,
            EnableColumnFilters => 1,
        );

        if ( !$FilterContent ) {
            $LayoutObject->FatalError(
                Message => $LayoutObject->{LanguageObject}
                    ->Translate( 'Can\'t get filter content data of %s!', $HeaderColumn ),
            );
        }

        return $LayoutObject->Attachment(
            ContentType => 'application/json; charset=' . $LayoutObject->{Charset},
            Content     => $FilterContent,
            Type        => 'inline',
            NoCache     => 1,
        );
    }
    elsif ( $Self->{Subaction} eq 'AJAXUnsubscribeTickets' ) {

        my $TicketIDs = $ParamObject->GetParam(
            Param => 'TicketIDs',
        ) // '';
        my @TicketIDs = split /,/, $TicketIDs;
        my $Success   = 1;

        TICKETID:
        for my $TicketID ( sort @TicketIDs ) {
            my $Unsubscribed = $TicketObject->TicketWatchUnsubscribe(
                TicketID    => $TicketID,
                WatchUserID => $Self->{UserID},
                UserID      => $Self->{UserID},
            );
            next TICKETID if $Unsubscribed;

            $Success = 0;
        }

        my %Content = (
            Success => $Success,
        );
        my $JSONEncodedContent = $JSONObject->Encode(
            Data => \%Content,
        );

        return $LayoutObject->Attachment(
            ContentType => 'application/json; charset=' . $LayoutObject->{Charset},
            Content     => $JSONEncodedContent,
            Type        => 'inline',
            NoCache     => 1,
        );
    }
    else {

        # store column filters
        my $StoredFilters = \%ColumnFilter;

        my $StoredFiltersKey = 'UserStoredFilterColumns-' . $Self->{Action};
        $UserObject->SetPreferences(
            UserID => $Self->{UserID},
            Key    => $StoredFiltersKey,
            Value  => $JSONObject->Encode( Data => $StoredFilters ),
        );
    }

    my %NavBarFilter;
    for my $FilterColumn ( sort keys %Filters ) {
        my $Count = $TicketObject->TicketSearch(
            %{ $Filters{$FilterColumn}->{Search} },
            %ColumnFilter,
            Result => 'COUNT',
        ) || 0;

        $NavBarFilter{ $Filters{$FilterColumn}->{Prio} } = {
            Count  => $Count,
            Filter => $FilterColumn,
            %{ $Filters{$FilterColumn} },
            %ColumnFilter,
        };
    }

    my $ColumnFilterLink = '';
    COLUMNNAME:
    for my $ColumnName ( sort keys %GetColumnFilter ) {
        next COLUMNNAME if !$ColumnName;
        next COLUMNNAME if !defined $GetColumnFilter{$ColumnName};

        my $Value  = $GetColumnFilter{$ColumnName};
        my @Values = ref $Value eq 'ARRAY' ? @{$Value} : ( defined $Value ? $Value : () );
        @Values = grep { defined $_ && $_ ne '' } @Values;
        next COLUMNNAME if !@Values;

        for my $Value (@Values) {
            $ColumnFilterLink
                .= ';' . $LayoutObject->Ascii2Html( Text => 'ColumnFilter' . $ColumnName )
                . '=' . $LayoutObject->LinkEncode($Value);
        }
    }

    # show ticket's
    my $LinkPage = 'Filter='
        . $LayoutObject->Ascii2Html( Text => $Filter )
        . ';View=' . $LayoutObject->Ascii2Html( Text => $View )
        . ';SortBy=' . $LayoutObject->Ascii2Html( Text => $SortBy )
        . ';OrderBy=' . $LayoutObject->Ascii2Html( Text => $OrderBy )
        . $ColumnFilterLink
        . ';';
    my $LinkSort = 'Filter='
        . $LayoutObject->Ascii2Html( Text => $Filter )
        . ';View=' . $LayoutObject->Ascii2Html( Text => $View )
        . $ColumnFilterLink
        . ';';
    my $LinkFilter = 'SortBy=' . $LayoutObject->Ascii2Html( Text => $SortBy )
        . ';OrderBy=' . $LayoutObject->Ascii2Html( Text => $OrderBy )
        . ';View=' . $LayoutObject->Ascii2Html( Text => $View )
        . ';';
    my $LastColumnFilter = $ParamObject->GetParam( Param => 'LastColumnFilter' ) || '';

    if ( !$LastColumnFilter && $ColumnFilterLink ) {

        # is planned to have a link to go back here
        $LastColumnFilter = 1;
    }

    $Output .= $LayoutObject->TicketListShow(
        TicketIDs         => \@ViewableTickets,
        OriginalTicketIDs => \@OriginalViewableTickets,
        GetColumnFilter   => \%GetColumnFilter,
        LastColumnFilter  => $LastColumnFilter,
        Action            => 'AgentTicketWatchView',
        RequestedURL      => $Self->{RequestedURL},

        Total => scalar @ViewableTickets,

        View => $View,

        Filter     => $Filter,
        Filters    => \%NavBarFilter,
        LinkFilter => $LinkFilter,

        TitleName  => Translatable('My Watched Tickets'),
        TitleValue => $Filters{$Filter}->{Name},
        Bulk       => 1,

        Env      => $Self,
        LinkPage => $LinkPage,
        LinkSort => $LinkSort,

        OrderBy             => $OrderBy,
        SortBy              => $SortBy,
        EnableColumnFilters => 1,
        ColumnFilterForm    => {
            Filter => $Filter || '',
        },

        # do not print the result earlier, but return complete content
        Output => 1,
    );

    $Output .= $LayoutObject->Footer();
    return $Output;
}

1;
