# --
# Copyright (C) 2001-2021 OTRS AG, https://otrs.com/
# Copyright (C) 2021-2022 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see https://www.gnu.org/licenses/gpl-3.0.txt.
# --

package Kernel::Output::HTML::TicketOverview::Preview;

use strict;
use warnings;

use Kernel::System::VariableCheck qw(:all);
use Kernel::Language qw(Translatable);

our @ObjectDependencies = (
    'Kernel::Config',
    'Kernel::Output::HTML::Layout',
    'Kernel::System::CommunicationChannel',
    'Kernel::System::CustomerUser',
    'Kernel::System::DynamicField',
    'Kernel::System::DynamicField::Backend',
    'Kernel::System::Group',
    'Kernel::System::Log',
    'Kernel::System::Main',
    'Kernel::System::Queue',
    'Kernel::System::Ticket',
    'Kernel::System::Ticket::Article',
    'Kernel::System::User',
);

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = \%Param;
    bless( $Self, $Type );

    # get UserID param
    $Self->{UserID} = $Param{UserID} || die "Got no UserID!";

    return $Self;
}

sub ActionRow {
    my ( $Self, %Param ) = @_;

    # get needed objects
    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');
    my $LayoutObject = $Kernel::OM->Get('Kernel::Output::HTML::Layout');

    # check if bulk feature is enabled
    my $BulkFeature = 0;
    if ( $Param{Bulk} && $ConfigObject->Get('Ticket::Frontend::BulkFeature') ) {
        my @Groups;
        if ( $ConfigObject->Get('Ticket::Frontend::BulkFeatureGroup') ) {
            @Groups = @{ $ConfigObject->Get('Ticket::Frontend::BulkFeatureGroup') };
        }
        if ( !@Groups ) {
            $BulkFeature = 1;
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
                    $BulkFeature = 1;
                    last GROUP;
                }
            }
        }
    }

    $LayoutObject->Block(
        Name => 'DocumentActionRow',
        Data => \%Param,
    );

    if ($BulkFeature) {
        $LayoutObject->Block(
            Name => 'DocumentActionRowBulk',
            Data => {
                %Param,
                Name => Translatable('Bulk'),
            },
        );
    }

    # run ticket overview document item menu modules
    if (
        $Param{Config}->{OverviewMenuModules}
        && ref $ConfigObject->Get('Ticket::Frontend::OverviewMenuModule') eq 'HASH'
        )
    {

        my %Menus = %{ $ConfigObject->Get('Ticket::Frontend::OverviewMenuModule') };
        MENUMODULE:
        for my $Menu ( sort keys %Menus ) {

            next MENUMODULE if !IsHashRefWithData( $Menus{$Menu} );
            next MENUMODULE if ( $Menus{$Menu}->{View} && $Menus{$Menu}->{View} ne $Param{View} );

            # load module
            if ( !$Kernel::OM->Get('Kernel::System::Main')->Require( $Menus{$Menu}->{Module} ) ) {
                return $LayoutObject->FatalError();
            }
            my $Object = $Menus{$Menu}->{Module}->new( %{$Self} );

            # run module
            my $Item = $Object->Run(
                %Param,
                Config => $Menus{$Menu},
            );
            next MENUMODULE if !IsHashRefWithData($Item);

            if ( $Item->{Block} eq 'DocumentActionRowItem' ) {

                # add session id if needed
                if ( !$LayoutObject->{SessionIDCookie} && $Item->{Link} ) {
                    $Item->{Link}
                        .= ';'
                        . $LayoutObject->{SessionName} . '='
                        . $LayoutObject->{SessionID};
                }

                # create id
                $Item->{ID} = $Item->{Name};
                $Item->{ID} =~ s/(\s|&|;)//ig;

                my $Link = $Item->{Link};
                if ( $Item->{Target} ) {
                    $Link = '#';
                }

                my $Class = '';
                if ( $Item->{PopupType} ) {
                    $Class = 'AsPopup PopupType_' . $Item->{PopupType};
                }

                $LayoutObject->Block(
                    Name => $Item->{Block},
                    Data => {
                        ID          => $Item->{ID},
                        Name        => $LayoutObject->{LanguageObject}->Translate( $Item->{Name} ),
                        Link        => $LayoutObject->{Baselink} . $Item->{Link},
                        Description => $Item->{Description},
                        Block       => $Item->{Block},
                        Class       => $Class,
                    },
                );
            }
            elsif ( $Item->{Block} eq 'DocumentActionRowHTML' ) {

                next MENUMODULE if !$Item->{HTML};

                $LayoutObject->Block(
                    Name => $Item->{Block},
                    Data => $Item,
                );
            }
        }
    }

    my $Output = $LayoutObject->Output(
        TemplateFile => 'AgentTicketOverviewPreview',
        Data         => \%Param,
    );

    return $Output;
}

sub SortOrderBar {
    my ( $Self, %Param ) = @_;
    return '';
}

sub Run {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Item (qw(TicketIDs PageShown StartHit)) {
        if ( !$Param{$Item} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Item!",
            );
            return;
        }
    }

    # get needed objects
    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');
    my $LayoutObject = $Kernel::OM->Get('Kernel::Output::HTML::Layout');

    # check if bulk feature is enabled
    my $BulkFeature = 0;
    if ( $Param{Bulk} && $ConfigObject->Get('Ticket::Frontend::BulkFeature') ) {
        my @Groups;
        if ( $ConfigObject->Get('Ticket::Frontend::BulkFeatureGroup') ) {
            @Groups = @{ $ConfigObject->Get('Ticket::Frontend::BulkFeatureGroup') };
        }
        if ( !@Groups ) {
            $BulkFeature = 1;
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
                    $BulkFeature = 1;
                    last GROUP;
                }
            }
        }
    }

    $LayoutObject->Block(
        Name => 'DocumentHeader',
        Data => \%Param,
    );

    my $OutputMeta = $LayoutObject->Output(
        TemplateFile => 'AgentTicketOverviewPreview',
        Data         => \%Param,
    );
    my $OutputRaw = '';
    if ( !$Param{Output} ) {
        $LayoutObject->Print( Output => \$OutputMeta );
    }
    else {
        $OutputRaw .= $OutputMeta;
    }
    my $Output        = '';
    my $Counter       = 0;
    my $CounterOnSite = 0;
    my @TicketIDsShown;

    my $ArticleObject             = $Kernel::OM->Get('Kernel::System::Ticket::Article');
    my $PreviewArticleSenderTypes = $ConfigObject->Get('Ticket::Frontend::Overview::PreviewArticleSenderTypes');
    my %PreviewArticleSenderTypeIDs;
    if ( IsHashRefWithData($PreviewArticleSenderTypes) ) {

        KEY:
        for my $Key ( %{$PreviewArticleSenderTypes} ) {
            next KEY if !$PreviewArticleSenderTypes->{$Key};

            my $ID = $ArticleObject->ArticleSenderTypeLookup( SenderType => $Key );
            if ($ID) {
                $PreviewArticleSenderTypeIDs{$ID} = 1;
            }
        }
    }

    # check if there are tickets to show
    if ( scalar @{ $Param{TicketIDs} } ) {

        for my $TicketID ( @{ $Param{TicketIDs} } ) {
            $Counter++;
            if (
                $Counter >= $Param{StartHit}
                && $Counter < ( $Param{PageShown} + $Param{StartHit} )
                )
            {
                push @TicketIDsShown, $TicketID;
                my $Output = $Self->_Show(
                    TicketID                    => $TicketID,
                    Counter                     => $CounterOnSite,
                    Bulk                        => $BulkFeature,
                    Config                      => $Param{Config},
                    Output                      => $Param{Output} || '',
                    PreviewArticleSenderTypeIDs => \%PreviewArticleSenderTypeIDs,
                );
                $CounterOnSite++;
                if ( !$Param{Output} ) {
                    $LayoutObject->Print( Output => $Output );
                }
                else {
                    $OutputRaw .= ${$Output};
                }
            }
        }

        # send data to JS
        $LayoutObject->AddJSData(
            Key   => 'ReplyFieldsFormID',
            Value => $Self->{ReplyFieldsFormID},
        );
        $LayoutObject->AddJSData(
            Key   => 'ActionRowTickets',
            Value => $Self->{ActionRowTickets},
        );
    }
    else {
        $LayoutObject->Block( Name => 'NoTicketFound' );
    }

    if ($BulkFeature) {
        $LayoutObject->Block(
            Name => 'DocumentFooter',
            Data => \%Param,
        );
        for my $TicketID (@TicketIDsShown) {
            $LayoutObject->Block(
                Name => 'DocumentFooterBulkItem',
                Data => \%Param,
            );
        }
        my $OutputMeta = $LayoutObject->Output(
            TemplateFile => 'AgentTicketOverviewPreview',
            Data         => \%Param,
        );
        if ( !$Param{Output} ) {
            $LayoutObject->Print( Output => \$OutputMeta );
        }
        else {
            $OutputRaw .= $OutputMeta;
        }
    }
    return $OutputRaw;
}

sub _Show {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    if ( !$Param{TicketID} ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => 'Need TicketID!',
        );
        return;
    }

    my $LayoutObject = $Kernel::OM->Get('Kernel::Output::HTML::Layout');

    # check if bulk feature is enabled
    if ( $Param{Bulk} ) {
        $LayoutObject->Block(
            Name => Translatable('Bulk'),
            Data => \%Param,
        );
    }

    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');

    my $PreviewArticleLimit = int $ConfigObject->Get('Ticket::Frontend::Overview::PreviewArticleLimit') || 5;

    my $TicketObject  = $Kernel::OM->Get('Kernel::System::Ticket');
    my $ArticleObject = $Kernel::OM->Get('Kernel::System::Ticket::Article');

    my %Ticket = $TicketObject->TicketGet(
        TicketID      => $Param{TicketID},
        DynamicFields => 0,
    );

    # Get configured number of last articles.
    my @Articles = $ArticleObject->ArticleList(
        TicketID => $Param{TicketID},
    );
    @Articles = reverse @Articles;
    if ( scalar @Articles > $PreviewArticleLimit ) {
        @Articles = @Articles[ 0 .. $PreviewArticleLimit - 1 ];
    }

    my @ArticleBody;
    my %Article;

    ARTICLE:
    for my $Article (@Articles) {

        # Check if certain article sender types should be excluded from preview.
        next ARTICLE
            if IsHashRefWithData( $Param{PreviewArticleSenderTypeIDs} )
            && !$Param{PreviewArticleSenderTypeIDs}->{ $Article->{SenderTypeID} };

        my $ArticleBackendObject = $ArticleObject->BackendForArticle( %{$Article} );

        my %ArticleData = $ArticleBackendObject->ArticleGet(
            TicketID      => $Param{TicketID},
            ArticleID     => $Article->{ArticleID},
            DynamicFields => 0,
        );
        %ArticleData = ( %ArticleData, %Ticket );

        my %ArticleFields = $LayoutObject->ArticleFields(
            TicketID  => $Param{TicketID},
            ArticleID => $Article->{ArticleID},
        );

        $ArticleData{ArticleFields} = \%ArticleFields;

        push @ArticleBody, \%ArticleData;

        if ( !%Article ) {
            %Article = %ArticleData;
        }
    }

    my $ArticleCount = scalar @ArticleBody;

    # Fallback for tickets without articles: get at least basic ticket data.
    if ( !%Article ) {
        %Article = %Ticket;
        if ( !$Article{Title} ) {
            $Article{Title} = $LayoutObject->{LanguageObject}->Translate(
                'This ticket has no title or subject'
            );
        }
        $Article{Subject} = $Article{Title};
    }

    # user info
    my %UserInfo = $Kernel::OM->Get('Kernel::System::User')->GetUserData(
        UserID => $Article{OwnerID},
    );
    %Article = ( %UserInfo, %Article );

    # get responsible info from ticket
    my %TicketResponsible = $Kernel::OM->Get('Kernel::System::User')->GetUserData(
        UserID => $Ticket{ResponsibleID},
    );

    # create human age
    $Article{Age} = $LayoutObject->CustomerAge(
        Age   => $Article{Age},
        Space => ' '
    );

    # get queue object
    my $QueueObject = $Kernel::OM->Get('Kernel::System::Queue');

    # fetch all std. templates ...
    my %StandardTemplates = $QueueObject->QueueStandardTemplateMemberList(
        QueueID       => $Article{QueueID},
        TemplateTypes => 1,
    );

    $Param{StandardResponsesStrg} = $LayoutObject->BuildSelection(
        Name  => 'ResponseID',
        Class => 'Modernize',
        Data  => $StandardTemplates{Answer} || {},
    );

    # customer info
    if ( $Param{Config}->{CustomerInfo} ) {
        if ( $Article{CustomerUserID} ) {
            $Article{CustomerName} = $Kernel::OM->Get('Kernel::System::CustomerUser')->CustomerName(
                UserLogin => $Article{CustomerUserID},
            );
        }
    }

    # get ACL restrictions
    my %PossibleActions;
    my $Counter = 0;

    # get all registered Actions
    if ( ref $ConfigObject->Get('Frontend::Module') eq 'HASH' ) {

        my %Actions = %{ $ConfigObject->Get('Frontend::Module') };

        # only use those Actions that stats with AgentTicket
        %PossibleActions = map { ++$Counter => $_ }
            grep { substr( $_, 0, length 'AgentTicket' ) eq 'AgentTicket' }
            sort keys %Actions;
    }

    my $ACL = $TicketObject->TicketAcl(
        Data          => \%PossibleActions,
        Action        => $Self->{Action},
        TicketID      => $Article{TicketID},
        ReturnType    => 'Action',
        ReturnSubType => '-',
        UserID        => $Self->{UserID},
    );

    my %AclAction = %PossibleActions;
    if ($ACL) {
        %AclAction = $TicketObject->TicketAclActionData();
    }

    # get main object
    my $MainObject = $Kernel::OM->Get('Kernel::System::Main');

    # run ticket pre menu modules
    my @ActionItems;
    if ( ref $ConfigObject->Get('Ticket::Frontend::PreMenuModule') eq 'HASH' ) {
        my %Menus = %{ $ConfigObject->Get('Ticket::Frontend::PreMenuModule') };
        MENU:
        for my $Menu ( sort keys %Menus ) {

            # load module
            if ( !$MainObject->Require( $Menus{$Menu}->{Module} ) ) {
                return $LayoutObject->FatalError();
            }
            my $Object = $Menus{$Menu}->{Module}->new(
                %{$Self},
                TicketID => $Param{TicketID},
            );

            # run module
            my $Item = $Object->Run(
                %Param,
                Ticket => \%Article,
                ACL    => \%AclAction,
                Config => $Menus{$Menu},
            );

            next MENU if !$Item;
            next MENU if ref $Item ne 'HASH';

            # add session id if needed
            if ( !$LayoutObject->{SessionIDCookie} && $Item->{Link} ) {
                $Item->{Link}
                    .= ';'
                    . $LayoutObject->{SessionName} . '='
                    . $LayoutObject->{SessionID};
            }

            # create id
            $Item->{ID} = $Item->{Name};
            $Item->{ID} =~ s/(\s|&|;)//ig;

            my $Output;
            if ( $Item->{Block} ) {
                $LayoutObject->Block(
                    Name => $Item->{Block},
                    Data => $Item,
                );
                $Output = $LayoutObject->Output(
                    TemplateFile => 'AgentTicketOverviewPreview',
                    Data         => $Item,
                );
            }
            else {
                $Output = '<li id="'
                    . $Item->{ID}
                    . '"><a href="#" title="'
                    . $LayoutObject->{LanguageObject}->Translate( $Item->{Description} )
                    . '">'
                    . $LayoutObject->{LanguageObject}->Translate( $Item->{Name} )
                    . '</a></li>';
            }

            $Output =~ s/\n+//g;
            $Output =~ s/\s+/ /g;
            $Output =~ s/<\!--.+?-->//g;

            push @ActionItems, {
                HTML        => $Output,
                ID          => $Item->{ID},
                Name        => $Item->{Name},
                Link        => $LayoutObject->{Baselink} . $Item->{Link},
                Target      => $Item->{Target},
                PopupType   => $Item->{PopupType},
                Description => $Item->{Description},
                Block       => $Item->{Block},

            };
        }
    }

    my $AdditionalClasses = $Param{Config}->{TicketActionsPerTicket} ? 'ShowInlineActions' : '';

    $LayoutObject->Block(
        Name => 'DocumentContent',
        Data => {
            %Param,
            %Article,
            Class             => 'ArticleCount' . $ArticleCount,
            AdditionalClasses => $AdditionalClasses,
            Created           => $Ticket{Created},                 # use value from ticket, not article
        },
    );

    $LayoutObject->Block(
        Name => 'OwnerResponsible',
        Data => {
            Owner               => $UserInfo{'UserLogin'},
            OwnerFullname       => $UserInfo{'UserFullname'},
            Responsible         => $TicketResponsible{'UserLogin'},
            ResponsibleFullname => $TicketResponsible{'UserFullname'},
        },
    );

    # if "Actions per Ticket" (Inline Action Row) is active
    if ( $Param{Config}->{TicketActionsPerTicket} ) {
        $LayoutObject->Block(
            Name => 'InlineActionRow',
            Data => \%Param,
        );

        # Add list entries for every action
        for my $Item (@ActionItems) {
            my $Link = $Item->{Link};
            if ( $Item->{Target} ) {
                $Link = '#';
            }

            my $Class = '';
            if ( $Item->{PopupType} ) {
                $Class = 'AsPopup PopupType_' . $Item->{PopupType};
            }

            if ( !$Item->{Block} ) {
                $LayoutObject->Block(
                    Name => 'InlineActionRowItem',
                    Data => {
                        TicketID    => $Param{TicketID},
                        QueueID     => $Article{QueueID},
                        ID          => $Item->{ID},
                        Name        => $Item->{Name},
                        Description => $Item->{Description},
                        Class       => $Class,
                        Link        => $Link,
                    },
                );
            }
            else {
                my $TicketID   = $Param{TicketID};
                my $SelectHTML = $Item->{HTML};
                $SelectHTML =~ s/id="DestQueueID"/id="DestQueueID$TicketID"/xmig;
                $SelectHTML =~ s/for="DestQueueID"/for="DestQueueID$TicketID"/xmig;
                $LayoutObject->Block(
                    Name => 'InlineActionRowItemHTML',
                    Data => {
                        HTML => $SelectHTML,
                    },
                );
            }
        }
    }

    # check if bulk feature is enabled
    if ( $Param{Bulk} ) {
        $LayoutObject->Block(
            Name => Translatable('Bulk'),
            Data => \%Param,
        );
    }

    # show ticket flags
    my @TicketMetaItems = $LayoutObject->TicketMetaItems(
        Ticket => \%Article,
    );
    for my $Item (@TicketMetaItems) {
        $LayoutObject->Block(
            Name => 'Meta',
            Data => $Item,
        );
        if ($Item) {
            $LayoutObject->Block(
                Name => 'MetaIcon',
                Data => $Item,
            );
        }
    }

    # run article modules
    if ( $Article{ArticleID} ) {
        if ( ref $ConfigObject->Get('Ticket::Frontend::ArticlePreViewModule') eq 'HASH' ) {
            my %Jobs = %{ $ConfigObject->Get('Ticket::Frontend::ArticlePreViewModule') };
            for my $Job ( sort keys %Jobs ) {

                # load module
                if ( !$MainObject->Require( $Jobs{$Job}->{Module} ) ) {
                    return $LayoutObject->FatalError();
                }
                my $Object = $Jobs{$Job}->{Module}->new(
                    %{$Self},
                    ArticleID => $Article{ArticleID},
                    UserID    => $Self->{UserID},
                    Debug     => $Self->{Debug},
                );

                # run module
                my @Data = $Object->Check(
                    Article => \%Article,
                    %Param,
                    Config => $Jobs{$Job},
                );

                for my $DataRef (@Data) {
                    if ( $DataRef->{Successful} ) {
                        $DataRef->{Result} = 'Error';
                    }
                    else {
                        $DataRef->{Result} = 'Success';
                    }

                    $LayoutObject->Block(
                        Name => 'ArticleOption',
                        Data => $DataRef,
                    );
                }

                # filter option
                $Object->Filter(
                    Article => \%Article,
                    %Param,
                    Config => $Jobs{$Job},
                );
            }
        }
    }

    # create output
    $LayoutObject->Block(
        Name => 'AgentAnswer',
        Data => {
            %Param,
            %Article,
            %AclAction,
        },
    );
    if (
        $ConfigObject->Get('Frontend::Module')->{AgentTicketCompose}
        && ( !defined $AclAction{AgentTicketCompose} || $AclAction{AgentTicketCompose} )
        )
    {
        my $Access = 1;
        my $Config = $ConfigObject->Get('Ticket::Frontend::AgentTicketCompose');
        if ( $Config->{Permission} ) {
            my $Ok = $TicketObject->Permission(
                Type     => $Config->{Permission},
                TicketID => $Param{TicketID},
                UserID   => $Self->{UserID},
                LogNo    => 1,
            );
            if ( !$Ok ) {
                $Access = 0;
            }
            if ($Access) {
                $LayoutObject->Block(
                    Name => 'AgentAnswerCompose',
                    Data => {
                        %Param,
                        %Article,
                        %AclAction,
                    },
                );
            }
        }
    }
    if (
        $ConfigObject->Get('Frontend::Module')->{AgentTicketPhoneOutbound}
        && (
            !defined $AclAction{AgentTicketPhoneOutbound}
            || $AclAction{AgentTicketPhoneOutbound}
        )
        )
    {
        my $Access = 1;
        my $Config = $ConfigObject->Get('Ticket::Frontend::AgentTicketPhoneOutbound');
        if ( $Config->{Permission} ) {
            my $OK = $TicketObject->Permission(
                Type     => $Config->{Permission},
                TicketID => $Param{TicketID},
                UserID   => $Self->{UserID},
                LogNo    => 1,
            );
            if ( !$OK ) {
                $Access = 0;
            }
        }
        if ($Access) {
            $LayoutObject->Block(
                Name => 'AgentAnswerPhoneOutbound',
                Data => {
                    %Param,
                    %Article,
                    %AclAction,
                },
            );
        }
    }

    # ticket type
    if ( $ConfigObject->Get('Ticket::Type') ) {
        $LayoutObject->Block(
            Name => 'Type',
            Data => {
                %Param,
                %Article,
            },
        );
    }

    # ticket service
    if ( $ConfigObject->Get('Ticket::Service') && $Article{Service} ) {
        $LayoutObject->Block(
            Name => 'Service',
            Data => {
                %Param,
                %Article,
            },
        );
        if ( $Article{SLA} ) {
            $LayoutObject->Block(
                Name => 'SLA',
                Data => {
                    %Param,
                    %Article,
                },
            );
        }
    }

    # CustomerID and CustomerName
    if ( defined $Article{CustomerID} ) {
        $LayoutObject->Block(
            Name => 'CustomerID',
            Data => {
                %Param,
                %Article,
            },
        );

        # test access to frontend module
        my $Access = $LayoutObject->Permission(
            Action => 'AgentTicketCustomer',
            Type   => 'rw',
        );
        if ($Access) {

            # test access to ticket
            my $Config = $ConfigObject->Get('Ticket::Frontend::AgentTicketCustomer');
            if ( $Config->{Permission} ) {
                my $OK = $TicketObject->Permission(
                    Type     => $Config->{Permission},
                    TicketID => $Param{TicketID},
                    UserID   => $Self->{UserID},
                    LogNo    => 1,
                );
                if ( !$OK ) {
                    $Access = 0;
                }
            }
        }

        # define proper tt block based on permissions
        my $CustomerIDBlock = $Access ? 'CustomerIDRW' : 'CustomerIDRO';

        $LayoutObject->Block(
            Name => $CustomerIDBlock,
            Data => {
                %Param,
                %Article,
            },
        );

        if ( defined $Article{CustomerName} ) {
            $LayoutObject->Block(
                Name => 'CustomerName',
                Data => {
                    %Param,
                    %Article,
                },
            );
        }
    }

    # show first response time if needed
    if ( defined $Article{FirstResponseTime} ) {
        $Article{FirstResponseTimeHuman} = $LayoutObject->CustomerAge(
            Age                => $Article{FirstResponseTime},
            TimeShowAlwaysLong => 1,
            Space              => ' ',
        );
        $Article{FirstResponseTimeWorkingTime} = $LayoutObject->CustomerAge(
            Age                => $Article{FirstResponseTimeWorkingTime},
            TimeShowAlwaysLong => 1,
            Space              => ' ',
        );
        if ( 60 * 60 * 1 > $Article{FirstResponseTime} ) {
            $Article{FirstResponseTimeClass} = 'Warning';
        }
        $LayoutObject->Block(
            Name => 'FirstResponseTime',
            Data => {
                %Param,
                %Article,
            },
        );
    }

    # show update time if needed
    if ( defined $Article{UpdateTime} ) {
        $Article{UpdateTimeHuman} = $LayoutObject->CustomerAge(
            Age                => $Article{UpdateTime},
            TimeShowAlwaysLong => 1,
            Space              => ' ',
        );
        $Article{UpdateTimeWorkingTime} = $LayoutObject->CustomerAge(
            Age                => $Article{UpdateTimeWorkingTime},
            TimeShowAlwaysLong => 1,
            Space              => ' ',
        );
        if ( 60 * 60 * 1 > $Article{UpdateTime} ) {
            $Article{UpdateTimeClass} = 'Warning';
        }
        $LayoutObject->Block(
            Name => 'UpdateTime',
            Data => {
                %Param,
                %Article,
            },
        );
    }

    # show solution time if needed
    if ( defined $Article{SolutionTime} ) {
        $Article{SolutionTimeHuman} = $LayoutObject->CustomerAge(
            Age                => $Article{SolutionTime},
            TimeShowAlwaysLong => 1,
            Space              => ' ',
        );
        $Article{SolutionTimeWorkingTime} = $LayoutObject->CustomerAge(
            Age                => $Article{SolutionTimeWorkingTime},
            TimeShowAlwaysLong => 1,
            Space              => ' ',
        );
        if ( 60 * 60 * 1 > $Article{SolutionTime} ) {
            $Article{SolutionTimeClass} = 'Warning';
        }
        $LayoutObject->Block(
            Name => 'SolutionTime',
            Data => {
                %Param,
                %Article,
            },
        );
    }

    # Dynamic fields
    $Counter = 0;
    my $Class = 'Middle';

    # get dynamic field config for frontend module
    my $DynamicFieldFilter = $ConfigObject->Get("Ticket::Frontend::OverviewPreview")->{DynamicField};

    # get the dynamic fields for this screen
    my $DynamicField = $Kernel::OM->Get('Kernel::System::DynamicField')->DynamicFieldListGet(
        Valid       => 1,
        ObjectType  => ['Ticket'],
        FieldFilter => $DynamicFieldFilter || {},
    );

    # cycle trough the activated Dynamic Fields for this screen
    DYNAMICFIELD:
    for my $DynamicFieldConfig ( @{$DynamicField} ) {
        next DYNAMICFIELD if !IsHashRefWithData($DynamicFieldConfig);

        # get dynamic field backend object
        my $DynamicFieldBackendObject = $Kernel::OM->Get('Kernel::System::DynamicField::Backend');

        # get field value
        my $Value = $DynamicFieldBackendObject->ValueGet(
            DynamicFieldConfig => $DynamicFieldConfig,
            ObjectID           => $Param{TicketID},
        );

        next DYNAMICFIELD if !defined $Value;

        $Counter++;

        my $ValueStrg = $DynamicFieldBackendObject->DisplayValueRender(
            DynamicFieldConfig => $DynamicFieldConfig,
            Value              => $Value,
            ValueMaxChars      => 20,
            LayoutObject       => $LayoutObject,
        );

        my $Label = $DynamicFieldConfig->{Label};

        # create a new row if counter is starting
        if ( $Counter == 1 ) {
            $LayoutObject->Block(
                Name => 'DynamicFieldTableRow',
                Data => {
                    Class => $Class,
                },
            );
        }

        # display separation row just once
        $Class = '';

        # outout dynamic field label
        $LayoutObject->Block(
            Name => 'DynamicFieldTableRowRecord',
            Data => {
                Label => $Label,
            },
        );

        if ( $ValueStrg->{Link} ) {

            # outout dynamic field value link
            $LayoutObject->Block(
                Name => 'DynamicFieldTableRowRecordLink',
                Data => {
                    Value                       => $ValueStrg->{Value},
                    Title                       => $ValueStrg->{Title},
                    Link                        => $ValueStrg->{Link},
                    $DynamicFieldConfig->{Name} => $ValueStrg->{Title},
                },
            );
        }
        else {

            # outout dynamic field value plain
            $LayoutObject->Block(
                Name => 'DynamicFieldTableRowRecordPlain',
                Data => {
                    Value => $ValueStrg->{Value},
                    Title => $ValueStrg->{Title},
                },
            );
        }

        # only 2 dynamic fields by row are allowed, reset couter if needed
        if ( $Counter == 2 ) {
            $Counter = 0;
        }

        # example of dynamic fields order customization
        # outout dynamic field label
        $LayoutObject->Block(
            Name => 'DynamicField_' . $DynamicFieldConfig->{Name} . '_TableRowRecord',
            Data => {
                Label => $Label,
            },
        );

        if ( $ValueStrg->{Link} ) {

            # outout dynamic field value link
            $LayoutObject->Block(
                Name => 'DynamicField_' . $DynamicFieldConfig->{Name} . '_TableRowRecordLink',
                Data => {
                    Value                       => $ValueStrg->{Value},
                    Title                       => $ValueStrg->{Title},
                    Link                        => $ValueStrg->{Link},
                    $DynamicFieldConfig->{Name} => $ValueStrg->{Title},
                },
            );
        }
        else {

            # outout dynamic field value plain
            $LayoutObject->Block(
                Name => 'DynamicField_' . $DynamicFieldConfig->{Name} . '_TableRowRecordPlain',
                Data => {
                    Value => $ValueStrg->{Value},
                    Title => $ValueStrg->{Title},
                },
            );
        }
    }

    # fill the rest of the Dynamic Fields row with empty cells, this will look better
    if ( $Counter > 0 && $Counter < 2 ) {

        for ( $Counter + 1 ... 2 ) {

            # outout dynamic field label
            $LayoutObject->Block(
                Name => 'DynamicFieldTableRowRecord',
                Data => {
                    Label => '',
                },
            );

            # outout dynamic field value plain
            $LayoutObject->Block(
                Name => 'DynamicFieldTableRowRecordPlain',
                Data => {
                    Value => '',
                    Title => '',
                },
            );
        }
    }

    if (@ArticleBody) {

        # check if the first article should be displayed as expanded, that is visible for the related customer
        my $PreviewIsVisibleForCustomerExpanded
            = $ConfigObject->Get('Ticket::Frontend::Overview::PreviewIsVisibleForCustomerExpanded') || 0;

        # if a certain article type should be shown as expanded, set the last article of this type as active
        if ($PreviewIsVisibleForCustomerExpanded) {

            my $ClassCount = 0;
            ARTICLEITEM:
            for my $ArticleItem (@ArticleBody) {

                next ARTICLEITEM if !$ArticleItem;
                next ARTICLEITEM if !IsHashRefWithData($ArticleItem);
                next ARTICLEITEM if !$ArticleItem->{IsVisibleForCustomer};

                $ArticleItem->{Class} = 'Active';
                last ARTICLEITEM;
            }
        }

        # Display the last article in the list as expanded (default).
        else {

            my $ArticleSelected;
            my $IgnoreSystemSender = $ConfigObject->Get('Ticket::NewArticleIgnoreSystemSender');

            ARTICLEITEM:
            for my $ArticleItem (@ArticleBody) {

                # ignore system sender type
                next ARTICLEITEM if $IgnoreSystemSender && $ArticleItem->{SenderType} eq 'system';

                $ArticleItem->{Class} = 'Active';
                $ArticleSelected = 1;
                last ARTICLEITEM;
            }

            # set selected article
            if ( !$ArticleSelected ) {
                $ArticleBody[0]->{Class} = 'Active';
            }
        }

        $LayoutObject->Block(
            Name => 'ArticlesPreviewArea',
            Data => {
                %Param,
                %Article,
                %AclAction,
            },
        );
    }

    my $CommunicationChannelObject = $Kernel::OM->Get('Kernel::System::CommunicationChannel');

    # Save communication channel data to improve performance.
    my %CommunicationChannelData;

    # show inline article
    for my $ArticleItem ( reverse @ArticleBody ) {

        $ArticleItem->{Body} = $LayoutObject->ArticlePreview(
            TicketID   => $ArticleItem->{TicketID},
            ArticleID  => $ArticleItem->{ArticleID},
            ResultType => 'plain',
        );

        # html quoting
        $ArticleItem->{Body} = $LayoutObject->Ascii2Html(
            NewLine         => $Param{Config}->{DefaultViewNewLine} || 90,
            Text            => $ArticleItem->{Body},
            VMax            => $Param{Config}->{DefaultPreViewLines} || 25,
            LinkFeature     => 1,
            HTMLResultMode  => 1,
            StripEmptyLines => $Param{Config}->{StripEmptyLines},
        );

        # Include some information about communication channel.
        if ( !$CommunicationChannelData{ $ArticleItem->{CommunicationChannelID} } ) {

            # Communication channel display name is part of the configuration.
            my %CommunicationChannel = $CommunicationChannelObject->ChannelGet(
                ChannelID => $ArticleItem->{CommunicationChannelID},
            );

            # Presence of communication channel object indicates its validity.
            my $ChannelObject = $CommunicationChannelObject->ChannelObjectGet(
                ChannelID => $ArticleItem->{CommunicationChannelID},
            );

            $CommunicationChannelData{ $ArticleItem->{CommunicationChannelID} } = {
                ChannelDisplayName => $CommunicationChannel{DisplayName},
                ChannelInvalid     => !$ChannelObject,
            };
        }

        my @ArticleActions = $LayoutObject->ArticleActions(
            TicketID  => $ArticleItem->{TicketID},
            ArticleID => $ArticleItem->{ArticleID},
            UserID    => $Self->{UserID},
            Type      => 'Static',
        );

        # Remove the 'Mark' action, which is implemented only in AgentTicketZoom.
        @ArticleActions = grep { $_->{Name} ne 'Mark' } @ArticleActions;

        $LayoutObject->Block(
            Name => 'ArticlePreview',
            Data => {
                %{$ArticleItem},
                %{ $CommunicationChannelData{ $ArticleItem->{CommunicationChannelID} } },
                MenuItems => \@ArticleActions,
            },
        );

        # check if compose link should be shown
        if (
            $ConfigObject->Get('Frontend::Module')->{AgentTicketCompose}
            && (
                !defined $AclAction{AgentTicketCompose}
                || $AclAction{AgentTicketCompose}
            )
            )
        {
            my $Access = 1;
            my $Config = $ConfigObject->Get('Ticket::Frontend::AgentTicketCompose');
            if ( $Config->{Permission} ) {
                my $Ok = $TicketObject->Permission(
                    Type     => $Config->{Permission},
                    TicketID => $Article{TicketID},
                    UserID   => $Self->{UserID},
                    LogNo    => 1,
                );
                if ( !$Ok ) {
                    $Access = 0;
                }
            }
            if ( $Config->{RequiredLock} ) {
                my $Locked = $TicketObject->LockIsTicketLocked(
                    TicketID => $Article{TicketID},
                );
                if ($Locked) {
                    my $AccessOk = $TicketObject->OwnerCheck(
                        TicketID => $Article{TicketID},
                        OwnerID  => $Self->{UserID},
                    );
                    if ( !$AccessOk ) {
                        $Access = 0;
                    }
                }
            }
        }
    }

    # add action items as js
    if ( @ActionItems && !$Param{Config}->{TicketActionsPerTicket} ) {

        # replace TT directives from string with values
        for my $ActionItem (@ActionItems) {
            $ActionItem->{Link} = $LayoutObject->Output(
                Template => $ActionItem->{Link},
                Data     => {
                    TicketID => $Article{TicketID},
                },
            );
        }

        $Self->{ActionRowTickets}->{ $Param{TicketID} } = $LayoutObject->JSONEncode( Data => \@ActionItems );
    }

    # create & return output
    my $Output = $LayoutObject->Output(
        TemplateFile => 'AgentTicketOverviewPreview',
        Data         => {
            %Param,
            %Article,
            %AclAction,
        },
    );
    return \$Output;
}

1;
