# --
# Copyright (C) 2021-2022 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::LastViews;

use strict;
use warnings;

our @ObjectDependencies = (
    'Kernel::Config',
    'Kernel::System::AuthSession',
    'Kernel::System::Log',
    'Kernel::System::Time',
);

use Kernel::System::VariableCheck qw(:all);

=head1 NAME

Kernel::System::LastViews - LastViews lib

=head1 PUBLIC INTERFACE

=head2 new()

    Don't use the constructor directly, use the ObjectManager instead:

    my $LastViewsObject = $Kernel::OM->Get('Kernel::System::LastViews');

=cut

sub new {
    my ( $Type, %Param ) = @_;

    my $Self = {};
    bless( $Self, $Type );

    $Self->{SessionKey} = 'UserLastViews';

    @{ $Self->{ActionIgnore} } = (
        'AgentTicketArticleContent',
        'AgentTicketSearch',
        'CustomerTicketArticleContent',
    );

    @{ $Self->{SubactionIgnore} } = (
        'LoadWidget',
        'MarkAsSeen',
        'AJAXNavigationTree',
        'CheckSettings',
    );

    return $Self;
}

=head2 Get()

Returns data of LastView (Request).

    my %LastView = $LastViewsObject->Get(
        %{ $Param{Request} },
    );

Returns:

    my %LastView = (
        Type     => 'TicketOverview',
        Name     => 'Queue',
        Frontend => 'Agent',
        Icon     => 'fa fa-table',
        PopUp    => 0,                  # 0 or 1
        Params   => {
            QueueID => '2',
            View    => '2',
            Filter  => 'Unlocked',
        },
        FrontendIcon => 'fa fa-user',
        URL          => 'Action=AgentTicketQueue;QueueID=2;View=;Filter=Unlocked',
        Action       => 'AgentTicketQueue',
        TimeStamp    => '2020-04-16 23:59:59',
    );

=cut

sub Get {
    my ( $Self, %Param ) = @_;

    my $SessionObject = $Kernel::OM->Get('Kernel::System::AuthSession');
    my $TimeObject    = $Kernel::OM->Get('Kernel::System::Time');
    my $ConfigObject  = $Kernel::OM->Get('Kernel::Config');
    my $LogObject     = $Kernel::OM->Get('Kernel::System::Log');

    NEEDED:
    for my $Needed (qw(LastViewsParams RequestedURL Action)) {
        next NEEDED if defined $Param{$Needed};
        $LogObject->Log(
            Priority => 'error',
            Message  => "Parameter '$Needed' is needed in Get!",
        );
        return;
    }

    my $Config    = $ConfigObject->Get('LastViews');
    my $TimeStamp = $TimeObject->CurrentTimestamp();

    my %LastView = (
        Type     => 'UNKNOWN',
        Frontend => 'UNKNOWN',
        Name     => 'UNKNOWN',
        Icon     => 'Question',
    );

    # general frontend
    if ( $Param{Action} =~ m{\A(Admin|Agent|Customer|Public)(.*)} ) {
        $LastView{Type}     = $1;
        $LastView{Frontend} = $1;
        $LastView{Icon}     = $1;
        $LastView{Name}     = $2;
    }

    # general types
    VIEW:
    for my $View (qw(FAQ Customer CustomerUser Statistics Calendar Appointment Preferences)) {
        next VIEW if $Param{Action} !~ m{\A(?:Agent|Customer)$View};

        $LastView{Type} = $View;
        $LastView{Icon} = $View;
    }

    # Ticket Views
    if ( $Param{Action} =~ m{\A(?:Agent|Customer)Ticket(.*)} ) {
        $LastView{Type} = 'Ticket';
        $LastView{Icon} = 'Ticket';
        $LastView{Name} = $1;
    }

    # TicketOverview
    if ( $Param{Action} =~ m{^(?:Agent|Customer)Ticket(Queue|Service|Status|Escalation|Owner|Overview)} ) {
        $LastView{Type} = 'TicketOverview';
        $LastView{Icon} = 'Overview';
        $LastView{Name} = $1;
    }
    if ( $Param{Action} =~ m{^Agent(Dashboard)} ) {
        $LastView{Type} = 'TicketOverview';
        $LastView{Icon} = 'Overview';
        $LastView{Name} = $1;
    }

    # TicketCreate
    if ( $Param{Action} =~ m{\A(?:Agent|Customer)Ticket(Phone|Email|Process)\z} ) {
        $LastView{Type} = 'TicketCreate';
        $LastView{Icon} = $1;
        $LastView{Name} = $1;
    }
    if ( $Param{Action} =~ m{\A(?:Agent|Customer)(TicketMessage)\z} ) {
        $LastView{Type} = 'TicketCreate';
        $LastView{Icon} = 'Ticket';
        $LastView{Name} = $1;
    }

    my %ActionMapping = $Self->GetActionMapping();

    # used if you have a config for this action
    if ( %ActionMapping && $ActionMapping{ $Param{Action} } ) {
        KEY:
        for my $Key ( %{ $ActionMapping{ $Param{Action} } } ) {
            next KEY if !$ActionMapping{ $Param{Action} }->{$Key};

            $LastView{$Key} = $ActionMapping{ $Param{Action} }->{$Key};
        }
    }

    my %IconMap = %{ $Config->{IconMapping} };

    $LastView{Icon} = $IconMap{ $LastView{Icon} };
    my $FrontendIcon = $IconMap{ $LastView{Frontend} };
    my %PopUpActions = $Self->GetPopUpActions();

    %LastView = (
        Type         => $LastView{Type},
        Name         => $LastView{Name},
        Frontend     => $LastView{Frontend},
        Icon         => $LastView{Icon},
        PopUp        => $PopUpActions{ $Param{Action} } || '',
        Params       => $Param{LastViewsParams},
        FrontendIcon => $FrontendIcon,
        URL          => $Param{RequestedURL},
        Action       => $Param{Action},
        TimeStamp    => $TimeStamp,
    );

    return %LastView;
}

=head2 GetList()

Returns a list of all last views from session

    my @LastViews = $LastViewsObject->GetList(
        SessionID => 123,
        Types     => ['Ticket', 'Admin'],   # optional
    );

Returns:

    my @LastViews = 1;

=cut

sub GetList {
    my ( $Self, %Param ) = @_;

    my $LogObject     = $Kernel::OM->Get('Kernel::System::Log');
    my $SessionObject = $Kernel::OM->Get('Kernel::System::AuthSession');

    NEEDED:
    for my $Needed (qw(SessionID)) {
        next NEEDED if defined $Param{$Needed};

        $LogObject->Log(
            Priority => 'error',
            Message  => "Parameter '$Needed' is needed in GetList!",
        );
        return;
    }

    my %Data = $SessionObject->GetSessionIDData(
        SessionID => $Param{SessionID},
    );

    my $SessionKey = $Param{SessionKey} || $Self->{SessionKey};
    return if !$Data{$SessionKey};

    my @LastViews = @{ $Data{$SessionKey} };
    return @LastViews if !$Param{Types};

    my @LastViewsTemp;
    LASTVIEW:
    for my $LastView (@LastViews) {
        next LASTVIEW if !$LastView->{Type};

        my $TypeExists = grep { $LastView->{Type} eq $_ } @{ $Param{Types} };
        next LASTVIEW if !$TypeExists;

        push @LastViewsTemp, $LastView;
    }

    @LastViews = @LastViewsTemp;

    return @LastViews;
}

=head2 GetActionMapping()

returns action mappings.

    my %ActionMapping = $LastViewsObject->GetActionMapping();

Returns:

    my %ActionMapping = (
        AgentTicketPhone => {
            Type     => 'TicketCreate',
            Frontend => 'Agent',
            Icon     => 'Phone',
            Name     => 'Phone',
        },
    );

=cut

sub GetActionMapping {
    my ( $Self, %Param ) = @_;

    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');

    my $Config = $ConfigObject->Get('LastViews');

    my %ActionMapping;

    my %Registration = %{ $Config->{ActionMapping} };
    for my $ActionMapping ( sort keys %Registration ) {
        %ActionMapping = (
            %ActionMapping,
            %{ $Registration{$ActionMapping} },
        );
    }
    return %ActionMapping;
}

=head2 GetPopUpActions()

returns all popup actions.

    my %PopUpActions = $LastViewsObject->GetPopUpActions();

Returns:

    my %PopUpActions = (
        'AgentTicketMerge'     => 'TicketAction',
        'AgentTicketCustomer' => 'TicketAction',
        'AgentTicketPriority' => 'TicketAction',
        'AgentTicketNote'     => 'TicketAction',
        'AgentLinkObject'     => 'TicketAction',
    );

=cut

sub GetPopUpActions {
    my ( $Self, %Param ) = @_;

    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');

    my %PopUpActions;

    my %MenuModules;
    $MenuModules{MenuModules}    = $ConfigObject->Get('Ticket::Frontend::MenuModule');
    $MenuModules{PreMenuModules} = $ConfigObject->Get('Ticket::Frontend::PreMenuModule');

    for my $Type ( sort keys %MenuModules ) {
        MODULE:
        for my $Module ( sort keys %{ $MenuModules{$Type} } ) {
            my $MenuModule = $MenuModules{$Type}->{$Module};
            next MODULE if !$MenuModule->{PopupType};

            $PopUpActions{ $MenuModule->{Action} } = $MenuModule->{PopupType};
        }
    }

    return %PopUpActions;
}

=head2 GetActionIgnore()

returns all actions to skip.

    my @ActionIgnore = $LastViewsObject->GetActionIgnore();

Returns:

    my @ActionIgnore = (
        'AgentTicketArticleContent'
    );

=cut

sub GetActionIgnore {
    my ( $Self, %Param ) = @_;

    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');

    my $Config = $ConfigObject->Get('LastViews');

    my @ActionIgnore = @{ $Self->{ActionIgnore} };
    return @ActionIgnore if !IsHashRefWithData( $Config->{ActionIgnore} );

    my %Registration = %{ $Config->{ActionIgnore} };
    for my $ActionIgnore ( sort keys %Registration ) {
        push @ActionIgnore, @{ $Registration{$ActionIgnore} };
    }

    my %ActionIgnore = map { $_ => $_ } @ActionIgnore;
    @ActionIgnore = sort keys %ActionIgnore;

    return @ActionIgnore;
}

=head2 GetSubactionIgnore()

returns all sub-actions to skip.

    my @SubactionIgnore = $LastViewsObject->GetSubactionIgnore();

Returns:

    my @SubactionIgnore = (
        'AgentTicketArticleContent'
    );

=cut

sub GetSubactionIgnore {
    my ( $Self, %Param ) = @_;

    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');
    my $Config       = $ConfigObject->Get('LastViews');

    my @SubactionIgnore = @{ $Self->{SubactionIgnore} };
    return @SubactionIgnore if !IsHashRefWithData( $Config->{SubactionIgnore} );

    my %Registration = %{ $Config->{SubactionIgnore} };
    for my $SubactionIgnore ( sort keys %Registration ) {
        push @SubactionIgnore, @{ $Registration{$SubactionIgnore} };
    }

    my %SubactionIgnore = map { $_ => $_ } @SubactionIgnore;
    @SubactionIgnore = sort keys %SubactionIgnore;

    return @SubactionIgnore;
}

=head2 Update()

Updates the last view list - added latest view to list.

    my $Success = $LastViewsObject->Update(
        SessionID => $Self->{SessionID},
        Request   => \%Request,
    );

Returns:

    my $Success = 1;

=cut

sub Update {
    my ( $Self, %Param ) = @_;

    my $SessionObject = $Kernel::OM->Get('Kernel::System::AuthSession');
    my $LogObject     = $Kernel::OM->Get('Kernel::System::Log');

    NEEDED:
    for my $Needed (qw(SessionID Request)) {
        next NEEDED if defined $Param{$Needed};

        $LogObject->Log(
            Priority => 'error',
            Message  => "Parameter '$Needed' is needed in Update!",
        );
        return;
    }

    my $IsValidRequest = $Self->IsValidRequest(
        %{ $Param{Request} },
    );
    return if !$IsValidRequest;

    $Self->Delete(
        SessionID => $Param{SessionID},
        Count     => 20,
    );

    my @LastViews = $Self->GetList(
        SessionID => $Param{SessionID},
    );

    my %LastView = $Self->Get(
        %{ $Param{Request} },
    );
    return 1 if !%LastView;

    if (@LastViews) {
        my %TestData1 = %LastView;
        my %TestData2 = %{ $LastViews[-1] };

        delete $TestData1{TimeStamp};
        delete $TestData2{TimeStamp};

        my $DataIsDifferent = DataIsDifferent(
            Data1 => \%TestData1,
            Data2 => \%TestData2,
        );

        return 1 if !$DataIsDifferent;
    }

    push @LastViews, ( \%LastView );

    my $SessionKey = $Param{SessionKey} || $Self->{SessionKey};
    $SessionObject->UpdateSessionID(
        SessionID => $Param{SessionID},
        Key       => $SessionKey,
        Value     => \@LastViews,
    );

    return 1;
}

=head2 Delete()

Deletes the last view list.

    my $Success = $LastViewsObject->Delete(
        SessionID => $Param{SessionID},
        Count     => 20,                    # option - deletes all views but the latest n
    );

Returns:

    my $Success = 1;

=cut

sub Delete {
    my ( $Self, %Param ) = @_;

    my $SessionObject = $Kernel::OM->Get('Kernel::System::AuthSession');

    my @LastViews;
    if ( $Param{Count} ) {
        @LastViews = $Self->GetList(
            SessionID => $Param{SessionID},
        );
        my $LastViewsCount = scalar @LastViews;
        if ( $LastViewsCount && $LastViewsCount >= $Param{Count} ) {
            @LastViews = splice @LastViews, -$Param{Count};
        }
    }

    my $SessionKey = $Param{SessionKey} // $Self->{SessionKey};
    $SessionObject->UpdateSessionID(
        SessionID => $Param{SessionID},
        Key       => $SessionKey,
        Value     => \@LastViews,
    );

    return 1;
}

=head2 IsValidRequest()

Checks if request is valid.
Request is valid if
    - RequestedURL has an Action
    - LastScreenView is not equal to RequestedURL
    - Action is not one of 'ActionIgnore'
    - Subaction is not one of 'SubactionIgnore'


    my $IsValidRequest = $LastViewsObject->IsValidRequest(
        %Request
    );

Returns:

    my $IsValidRequest = 1;

=cut

sub IsValidRequest {
    my ( $Self, %Param ) = @_;

    my $LogObject = $Kernel::OM->Get('Kernel::System::Log');

    NEEDED:
    for my $Needed (qw(Action SessionID RequestedURL)) {
        next NEEDED if defined $Param{$Needed};
        return 0;
    }

    return 0 if $Param{LastScreenView} && $Param{LastScreenView} eq $Param{RequestedURL};
    return 0 if $Param{RequestedURL} !~ m{^Action=.+}smx;

    my @ActionIgnore = $Self->GetActionIgnore();

    my $IsIgnoreAction = grep { $Param{Action} eq $_ } @ActionIgnore;
    return 0 if $IsIgnoreAction;

    if ( $Param{Subaction} ) {
        my @SubactionIgnore   = $Self->GetSubactionIgnore();
        my $IsIgnoreSubaction = grep { $Param{Subaction} eq $_ } @SubactionIgnore;
        return 0 if $IsIgnoreSubaction;
    }

    return 1;
}

1;
