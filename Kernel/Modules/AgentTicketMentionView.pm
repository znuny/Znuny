# --
# Copyright (C) 2001-2021 OTRS AG, https://otrs.com/
# Copyright (C) 2021-2022 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see https://www.gnu.org/licenses/gpl-3.0.txt.
# --

package Kernel::Modules::AgentTicketMentionView;

use strict;
use warnings;

use Kernel::System::VariableCheck qw(:all);
use Kernel::Language qw(Translatable);

our $ObjectManagerDisabled = 1;

sub new {
    my ( $Type, %Param ) = @_;

    my $Self = {%Param};
    bless( $Self, $Type );

    return $Self;
}

sub Run {
    my ( $Self, %Param ) = @_;

    my $ConfigObject  = $Kernel::OM->Get('Kernel::Config');
    my $ParamObject   = $Kernel::OM->Get('Kernel::System::Web::Request');
    my $SessionObject = $Kernel::OM->Get('Kernel::System::AuthSession');
    my $JSONObject    = $Kernel::OM->Get('Kernel::System::JSON');
    my $UserObject    = $Kernel::OM->Get('Kernel::System::User');
    my $LayoutObject  = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $TicketObject  = $Kernel::OM->Get('Kernel::System::Ticket');
    my $MentionObject = $Kernel::OM->Get('Kernel::System::Mention');

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

    # get filters stored in the user preferences
    my %Preferences = $UserObject->GetPreferences(
        UserID => $Self->{UserID},
    );
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
        my $FilterValue = $ParamObject->GetParam( Param => 'ColumnFilter' . $ColumnName )
            || '';

        # if filter is not present in the web request, try with the user preferences
        if ( !IsStringWithData($FilterValue) ) {
            if ( $ColumnName eq 'CustomerID' ) {
                $FilterValue = $StoredFilters->{$ColumnName}->[0] // '';
            }
            elsif ( $ColumnName eq 'CustomerUserID' ) {
                $FilterValue = $StoredFilters->{CustomerUserLogin}->[0] // '';
            }
            else {
                $FilterValue = $StoredFilters->{ $ColumnName . 'IDs' }->[0] // '';
            }
        }
        next COLUMNNAME if !IsStringWithData($FilterValue);
        next COLUMNNAME if $FilterValue eq 'DeleteFilter';

        if ( $ColumnName eq 'CustomerID' ) {
            push @{ $ColumnFilter{$ColumnName} }, $FilterValue;
            push @{ $ColumnFilter{ $ColumnName . 'Raw' } }, $FilterValue;
            $GetColumnFilter{$ColumnName} = $FilterValue;
        }
        elsif ( $ColumnName eq 'CustomerUserID' ) {
            push @{ $ColumnFilter{CustomerUserLogin} },    $FilterValue;
            push @{ $ColumnFilter{CustomerUserLoginRaw} }, $FilterValue;
            $GetColumnFilter{$ColumnName} = $FilterValue;
        }
        else {
            push @{ $ColumnFilter{ $ColumnName . 'IDs' } }, $FilterValue;
            $GetColumnFilter{$ColumnName} = $FilterValue;
        }
    }

    # get all dynamic fields
    $Self->{DynamicField} = $Kernel::OM->Get('Kernel::System::DynamicField')->DynamicFieldListGet(
        Valid      => 1,
        ObjectType => ['Ticket'],
    );

    DYNAMICFIELDCONFIG:
    for my $DynamicFieldConfig ( @{ $Self->{DynamicField} } ) {
        next DYNAMICFIELDCONFIG if !IsHashRefWithData($DynamicFieldConfig);
        next DYNAMICFIELDCONFIG if !$DynamicFieldConfig->{Name};

        # get filter from web request
        my $FilterValue = $ParamObject->GetParam(
            Param => 'ColumnFilterDynamicField_' . $DynamicFieldConfig->{Name}
        );

        # if no filter from web request, try from user preferences
        if ( !IsStringWithData($FilterValue) ) {
            $FilterValue = $StoredFilters->{ 'DynamicField_' . $DynamicFieldConfig->{Name} }->{Equals};
        }

        next DYNAMICFIELDCONFIG if !IsStringWithData($FilterValue);
        next DYNAMICFIELDCONFIG if $FilterValue eq 'DeleteFilter';

        $ColumnFilter{ 'DynamicField_' . $DynamicFieldConfig->{Name} } = {
            Equals => $FilterValue,
        };
        $GetColumnFilter{ 'DynamicField_' . $DynamicFieldConfig->{Name} } = $FilterValue;
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

    my %Filters = (
        All => {
            Name   => Translatable('All'),
            Prio   => 1000,
            Search => {
                OrderBy    => $OrderBy,
                SortBy     => $SortByS,
                UserID     => 1,
                Permission => 'ro',
            },
        },
        New => {
            Name   => Translatable('New mention'),
            Prio   => 1001,
            Search => {
                NotTicketFlag => {
                    Seen => 1,
                },
                TicketFlagUserID => $Self->{UserID},
                OrderBy          => $OrderBy,
                SortBy           => $SortByS,
                UserID           => 1,
                Permission       => 'ro',
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

    # shown tickets lookup
    my $Limit = 10_000;

    my $ElementChanged = $ParamObject->GetParam( Param => 'ElementChanged' ) || '';

    my $HeaderColumn = $ElementChanged;
    $HeaderColumn =~ s{\A ColumnFilter }{}msxg;

    my @OriginalViewableTickets;
    my @ViewableTickets;
    my $ViewableTicketCount = 0;

    my $Mentions = $MentionObject->GetUserMentions(
        UserID => $Self->{UserID},
    ) // [];

    my @MentionedTicketIDs = map { $_->{TicketID} } @{$Mentions};

    # get ticket values
    if (
        @MentionedTicketIDs
        && (
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
        )
    {
        @OriginalViewableTickets = $TicketObject->TicketSearch(
            %{ $Filters{$Filter}->{Search} },
            Limit    => $Limit,
            Result   => 'ARRAY',
            TicketID => \@MentionedTicketIDs,
            UserID   => 1,                     # Needed if user doesn't have permissions for ticket but is mentioned in.
        );

        @ViewableTickets = $TicketObject->TicketSearch(
            %{ $Filters{$Filter}->{Search} },
            %ColumnFilter,
            Result   => 'ARRAY',
            Limit    => 1_000,
            TicketID => \@MentionedTicketIDs,
            UserID   => 1,                     # Needed if user doesn't have permissions for ticket but is mentioned in.
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

    # store column filters
    $StoredFilters    = \%ColumnFilter;
    $StoredFiltersKey = 'UserStoredFilterColumns-' . $Self->{Action};

    $UserObject->SetPreferences(
        UserID => $Self->{UserID},
        Key    => $StoredFiltersKey,
        Value  => $JSONObject->Encode( Data => $StoredFilters ),
    );

    if ( $ViewableTicketCount > $Limit ) {
        $ViewableTicketCount = $Limit;
    }

    my %NavBarFilter;
    for my $Filter ( sort keys %Filters ) {
        my $Count = 0;
        if (@MentionedTicketIDs) {
            $Count = $TicketObject->TicketSearch(
                TicketID => \@MentionedTicketIDs,
                %{ $Filters{$Filter}->{Search} },
                %ColumnFilter,
                Result => 'COUNT',
            );
        }

        $NavBarFilter{ $Filters{$Filter}->{Prio} } = {
            Count  => $Count,
            Filter => $Filter,
            %{ $Filters{$Filter} },
            %ColumnFilter,
        };
    }

    my $ColumnFilterLink = '';

    COLUMNNAME:
    for my $ColumnName ( sort keys %GetColumnFilter ) {
        next COLUMNNAME if !$ColumnName;
        next COLUMNNAME if !$GetColumnFilter{$ColumnName};
        $ColumnFilterLink
            .= ';' . $LayoutObject->Ascii2Html( Text => 'ColumnFilter' . $ColumnName )
            . '=' . $LayoutObject->LinkEncode( $GetColumnFilter{$ColumnName} );
    }

    # show tickets
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
        TicketIDs           => \@ViewableTickets,
        OriginalTicketIDs   => \@OriginalViewableTickets,
        GetColumnFilter     => \%GetColumnFilter,
        LastColumnFilter    => $LastColumnFilter,
        Action              => 'AgentTicketMentionView',
        RequestedURL        => $Self->{RequestedURL},
        Total               => scalar @ViewableTickets,
        View                => $View,
        Filter              => $Filter,
        Filters             => \%NavBarFilter,
        LinkFilter          => $LinkFilter,
        TitleName           => Translatable('My Mentions'),
        TitleValue          => $Filters{$Filter}->{Name},
        Bulk                => 1,
        Unmention           => 1,
        Env                 => $Self,
        LinkPage            => $LinkPage,
        LinkSort            => $LinkSort,
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
