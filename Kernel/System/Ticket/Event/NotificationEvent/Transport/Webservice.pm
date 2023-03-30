# --
# Copyright (C) 2021 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

## nofilter(TidyAll::Plugin::Znuny::Perl::ParamObject)
## nofilter(TidyAll::Plugin::Znuny::Perl::LayoutObject)

package Kernel::System::Ticket::Event::NotificationEvent::Transport::Webservice;

use strict;
use warnings;

use Kernel::System::VariableCheck qw(:all);
use Kernel::Language qw(Translatable);

use parent qw(Kernel::System::Ticket::Event::NotificationEvent::Transport::Base);

our @ObjectDependencies = (
    'Kernel::Config',
    'Kernel::GenericInterface::Requester',
    'Kernel::Output::HTML::Layout',
    'Kernel::System::GenericInterface::Webservice',
    'Kernel::System::Log',
    'Kernel::System::Ticket',
    'Kernel::System::Ticket::Article',
    'Kernel::System::Web::Request',
);

=head1 NAME

Kernel::System::Ticket::Event::NotificationEvent::Transport::Webservice - Web service transport layer

=head1 PUBLIC INTERFACE

=head2 new()

create a notification transport object. Do not use it directly, instead use:

    my $TransportObject = $Kernel::OM->Get('Kernel::System::Ticket::Event::NotificationEvent::Transport::Webservice');

=cut

sub new {
    my ( $Type, %Param ) = @_;

    my $Self = {};
    bless( $Self, $Type );

    return $Self;
}

sub SendNotification {
    my ( $Self, %Param ) = @_;

    my $LogObject        = $Kernel::OM->Get('Kernel::System::Log');
    my $ConfigObject     = $Kernel::OM->Get('Kernel::Config');
    my $ArticleObject    = $Kernel::OM->Get('Kernel::System::Ticket::Article');
    my $RequesterObject  = $Kernel::OM->Get('Kernel::GenericInterface::Requester');
    my $WebserviceObject = $Kernel::OM->Get('Kernel::System::GenericInterface::Webservice');
    my $LayoutObject     = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $TicketObject     = $Kernel::OM->Get('Kernel::System::Ticket');

    NEEDED:
    for my $Needed (qw(TicketID UserID Notification Recipient)) {
        next NEEDED if defined $Param{$Needed};

        $LogObject->Log(
            Priority => 'error',
            Message  => "Need $Needed!",
        );

        return;
    }

    NEEDED:
    for my $Needed (qw(Notification Recipient)) {
        next NEEDED if ref $Param{$Needed} eq 'HASH';

        $LogObject->Log(
            Priority => 'error',
            Message  => "$Needed needs to be a hash!",
        );

        return;
    }

    $Self->{EventData} = undef;

    my %Notification = %{ $Param{Notification} };

    my $TransportParams;
    TRANSPORTPARAM:
    for my $TransportParam (
        qw(
        TransportWebserviceAsynchronous TransportWebserviceID TransportWebserviceInvokerName
        TransportWebserviceAdditionalRecipients TransportWebserviceArticleIsVisibleForCustomer
        )
        )
    {
        next TRANSPORTPARAM if !defined $Notification{Data}->{$TransportParam};

        $TransportParams->{$TransportParam} = $Notification{Data}->{$TransportParam}->[0];
    }

    return if !defined $TransportParams->{TransportWebserviceID};
    return if !defined $TransportParams->{TransportWebserviceInvokerName};

    my $Webservices       = $WebserviceObject->WebserviceList();
    my $WebserviceIsValid = $Webservices->{ $TransportParams->{TransportWebserviceID} };
    if ( !$WebserviceIsValid ) {
        $LogObject->Log(
            Priority => 'info',
            Message  => "Skipped web service notification '$Notification{Name}' because "
                . "web service with ID $TransportParams->{TransportWebserviceID} is not valid or could not be found."
        );
        return;
    }

    my $RecipientInformation         = $ConfigObject->Get('WebserviceNotifications::RecipientInformation');
    my $AgentRecipientInformation    = $RecipientInformation->{Agent} // [];
    my $CustomerRecipientInformation = $RecipientInformation->{Customer} // [];
    my $AdditionalRecipientKeyName   = $RecipientInformation->{AdditionalRecipientKeyName} || 'Recipient';

    # Remove certain keys/values from recipient.
    # Note: UserPassword is a configurable customer user field. Only the default field name 'UserPassword'
    # is supported right now.
    for my $Key (qw(UserPw UserPassword)) {
        delete $Param{Recipient}->{$Key};
    }

    my %Recipient = %{ $Param{Recipient} };

    my $FromEmail        = $ConfigObject->Get('NotificationSenderEmail');
    my $NotificationFrom = $ConfigObject->Get('NotificationSenderName') . ' <' . $FromEmail . '>';
    my $NotificationTo   = $Recipient{UserEmail} // '';
    my $RequestData      = {};

    if ( $Recipient{Type} eq 'Agent' ) {
        for my $EnabledParam ( @{$AgentRecipientInformation} ) {
            $RequestData->{$EnabledParam} = ${Recipient}{$EnabledParam} // '';
        }
    }
    elsif ( $Recipient{Type} eq 'Customer' ) {
        for my $EnabledParam ( @{$CustomerRecipientInformation} ) {
            $RequestData->{$EnabledParam} = $Recipient{$EnabledParam} // '';
        }

        if (
            !$RequestData->{$AdditionalRecipientKeyName}
            && $Recipient{$AdditionalRecipientKeyName}
            )
        {
            $RequestData->{$AdditionalRecipientKeyName} = $Recipient{$AdditionalRecipientKeyName};
            $Param{Recipient}->{Type} = 'Additional';
        }
    }
    else {
        $LogObject->Log(
            Priority => 'info',
            Message =>
                "Skipped web service notification '$Notification{Name}' because of wrong recipient type '$Param{Recipient}->{Type}'.",
        );
        return;
    }

    $RequestData->{NotificationPlainBody} = $Notification{Body};

    if ( defined $Notification{ContentType} && $Notification{ContentType} eq 'text/html' ) {
        my $RecipientLanguageObject = $LayoutObject->{LanguageObject};
        if ( $Recipient{UserLanguage} ) {
            $RecipientLanguageObject = Kernel::Language->new(
                UserLanguage => $Recipient{UserLanguage},
            );
        }

        local $LayoutObject->{LanguageObject} = $RecipientLanguageObject;

        $Notification{Body} = $LayoutObject->Output(
            TemplateFile => "NotificationEvent/Email/Default",
            Data         => {
                TicketID => $Param{TicketID},
                Body     => $Notification{Body},
                Subject  => $Notification{Subject},
            },
        );
    }

    $RequestData->{NotificationSubject}     = $Notification{Subject};
    $RequestData->{NotificationBody}        = $Notification{Body};
    $RequestData->{NotificationContentType} = $Notification{ContentType};

    $RequestData->{Attachments}  = $Param{Attachments};
    $RequestData->{TicketID}     = $Param{TicketID};
    $RequestData->{TicketNumber} = $TicketObject->TicketNumberLookup(
        TicketID => $Param{TicketID},
    );
    $RequestData->{Recipient} = $Param{Recipient};

    my $Result = $RequesterObject->Run(
        WebserviceID => $TransportParams->{TransportWebserviceID},
        Invoker      => $TransportParams->{TransportWebserviceInvokerName},
        Asynchronous => $TransportParams->{TransportWebserviceAsynchronous},
        Data         => $RequestData,
    );

    if ( !IsHashRefWithData($Result) || !$Result->{Success} ) {
        $LogObject->Log(
            Priority => 'error',
            Message =>
                "Failed to send web service notification '$Notification{Name}' to '$NotificationTo' ($Recipient{Type}).",
        );
        return;
    }

    if ( $Recipient{Type} eq 'Customer' || $Recipient{Type} eq 'Additional' ) {
        my $ArticleBackendObject = $ArticleObject->BackendForChannel( ChannelName => 'Internal' );
        $ArticleBackendObject->ArticleCreate(
            TicketID             => $Param{TicketID},
            SenderType           => 'system',
            IsVisibleForCustomer => $TransportParams->{TransportWebserviceArticleIsVisibleForCustomer} || 0,
            HistoryType          => 'SendCustomerNotification',
            HistoryComment       => "\%\%$NotificationTo",
            From                 => $NotificationFrom,
            To                   => $NotificationTo,
            Subject              => $Notification{Subject},
            Body                 => $Notification{Body},
            MimeType             => $Notification{ContentType},
            Type                 => $Notification{ContentType},
            Charset              => 'utf-8',
            UserID               => $Param{UserID},
            Loop                 => 1,
            Attachment           => $Param{Attachments},
        );
    }

    $LogObject->Log(
        Priority => 'info',
        Message  => "Sent Webservice notification: '$Notification{Name}' to '$NotificationTo' ($Recipient{Type}).",
    );

    $Self->{EventData} = {
        Event => 'WebserviceNotification',
        Data  => {
            TicketID => $Param{TicketID},
        },
        UserID => $Param{UserID},
    };

    return 1;
}

sub GetTransportRecipients {
    my ( $Self, %Param ) = @_;

    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');
    my $LogObject    = $Kernel::OM->Get('Kernel::System::Log');

    NEEDED:
    for my $Needed (qw(Notification)) {
        next NEEDED if defined $Param{$Needed};

        $LogObject->Log(
            Priority => 'error',
            Message  => "Need $Needed",
        );
        return;
    }

    my $RecipientInformation       = $ConfigObject->Get('WebserviceNotifications::RecipientInformation');
    my $AdditionalRecipientKeyName = $RecipientInformation->{AdditionalRecipientKeyName} || 'Recipient';

    my @Recipients;
    return @Recipients
        if !IsArrayRefWithData( $Param{Notification}->{Data}->{TransportWebserviceAdditionalRecipients} );

    my $RecipientEmailAddresses = $Param{Notification}->{Data}->{TransportWebserviceAdditionalRecipients}->[0];

    # replace OTRS placeholders in recipient email addresses
    $RecipientEmailAddresses = $Self->_ReplaceTicketAttributes(
        Ticket => $Param{Ticket},
        Field  => $RecipientEmailAddresses,
    );

    my @RecipientEmailAddresses = grep { defined $_ && length $_ } split /[;,\s]+/, $RecipientEmailAddresses;

    for my $RecipientEmailAddress (@RecipientEmailAddresses) {
        push @Recipients, {
            Realname                    => '',
            Type                        => 'Customer',
            $AdditionalRecipientKeyName => $RecipientEmailAddress,
            IsVisibleForCustomer        => $Param{Notification}->{Data}->{IsVisibleForCustomer},
        };
    }

    return @Recipients;
}

sub TransportSettingsDisplayGet {
    my ( $Self, %Param ) = @_;

    my $LayoutObject     = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $WebserviceObject = $Kernel::OM->Get('Kernel::System::GenericInterface::Webservice');

    KEY:
    for my $Key (qw(TransportWebserviceAdditionalRecipients)) {
        next KEY if !IsArrayRefWithData( $Param{Data}->{$Key} );
        $Param{$Key} = $Param{Data}->{$Key}->[0];
    }

    my $Webservices          = $WebserviceObject->WebserviceList();
    my $SelectedWebserviceID = $Param{Data}->{TransportWebserviceID}->[0] // '';

    $Param{TransportWebserviceIDSelection} = $LayoutObject->BuildSelection(
        Data         => $Webservices,
        Name         => 'TransportWebserviceID',
        Translation  => 0,
        PossibleNone => 1,
        SelectedID   => $SelectedWebserviceID,
        Class        => 'Modernize W50pc',
        OnChange     => 'Core.Agent.Admin.WebserviceNotification.UpdateInvokers();',
    );

    my $Invokers = [];
    if ($SelectedWebserviceID) {
        $Invokers = $Self->GetWebserviceInvokers(
            WebserviceID => $SelectedWebserviceID,
        );
    }

    $Param{TransportWebserviceInvokerNameSelection} = $LayoutObject->BuildSelection(
        Data         => $Invokers,
        Name         => 'TransportWebserviceInvokerName',
        Translation  => 0,
        PossibleNone => 1,
        SelectedID   => $Param{Data}->{TransportWebserviceInvokerName} // '',
        Class        => 'Modernize W50pc',
    );

    my $Output = $LayoutObject->Output(
        TemplateFile => 'AdminNotificationEventTransportWebserviceSettings',
        Data         => \%Param,
    );

    return $Output;
}

sub TransportParamSettingsGet {
    my ( $Self, %Param ) = @_;

    my $LogObject   = $Kernel::OM->Get('Kernel::System::Log');
    my $ParamObject = $Kernel::OM->Get('Kernel::System::Web::Request');

    NEEDED:
    for my $Needed (qw(GetParam)) {
        next NEEDED if defined $Param{$Needed};

        $LogObject->Log(
            Priority => 'error',
            Message  => "Need $Needed",
        );

        return;
    }

    PARAMETER:
    for my $Parameter (
        qw(
        TransportWebserviceAsynchronous TransportWebserviceID TransportWebserviceInvokerName
        TransportWebserviceAdditionalRecipients TransportWebserviceArticleIsVisibleForCustomer
        )
        )
    {
        my @Data = $ParamObject->GetArray( Param => $Parameter );
        next PARAMETER if !@Data;
        $Param{GetParam}->{Data}->{$Parameter} = \@Data;
    }

    return 1;
}

sub IsUsable {
    my ( $Self, %Param ) = @_;

    my $WebserviceObject = $Kernel::OM->Get('Kernel::System::GenericInterface::Webservice');
    my $Webservices      = $WebserviceObject->WebserviceList();

    # This transport module is usable only if valid web services are present.
    my $IsUsable = %{$Webservices} ? 1 : 0;
    return $IsUsable;
}

=head2 GetWebserviceInvokers()

Provides invoker list for the HTML selection.

    my $Invokers = $WebserviceTransportObject->GetWebserviceInvokers(
        WebserviceID => $ServiceID,
    );

returns:

    $Invokers = [ 'Invoker 1', 'Invoker 2', ... ]

=cut

sub GetWebserviceInvokers {
    my ( $Self, %Param ) = @_;

    my $LogObject        = $Kernel::OM->Get('Kernel::System::Log');
    my $WebserviceObject = $Kernel::OM->Get('Kernel::System::GenericInterface::Webservice');

    NEEDED:
    for my $Needed (qw(WebserviceID)) {
        next NEEDED if defined $Param{$Needed};

        $LogObject->Log(
            Priority => 'error',
            Message  => "Need $Needed",
        );

        return;
    }

    my $Webservice = $WebserviceObject->WebserviceGet(
        ID => $Param{WebserviceID}
    );

    my @Invokers = keys %{ $Webservice->{Config}->{Requester}->{Invoker} // {} };
    return \@Invokers;
}

1;
