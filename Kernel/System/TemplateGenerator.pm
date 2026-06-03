# --
# Copyright (C) 2001-2021 OTRS AG, https://otrs.com/
# Copyright (C) 2021 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see https://www.gnu.org/licenses/gpl-3.0.txt.
# --

package Kernel::System::TemplateGenerator;
## nofilter(TidyAll::Plugin::Znuny::CodeStyle::STDERRCheck)
## nofilter(TidyAll::Plugin::Znuny::Perl::LayoutObject)

use strict;
use warnings;
use utf8;

use Kernel::Language;
use Mail::Address;

use Kernel::System::VariableCheck qw(:all);

our @ObjectDependencies = (
    'Kernel::Config',
    'Kernel::Output::HTML::Layout',
    'Kernel::System::AutoResponse',
    'Kernel::System::CommunicationChannel',
    'Kernel::System::CustomerUser',
    'Kernel::System::DateTime',
    'Kernel::System::DynamicField',
    'Kernel::System::DynamicField::Backend',
    'Kernel::System::HTMLUtils',
    'Kernel::System::Log',
    'Kernel::System::Queue',
    'Kernel::System::Salutation',
    'Kernel::System::Signature',
    'Kernel::System::StandardTemplate',
    'Kernel::System::SystemAddress',
    'Kernel::System::Ticket',
    'Kernel::System::Ticket::Article',
    'Kernel::System::User',
);

=head1 NAME

Kernel::System::TemplateGenerator - signature lib

=head1 DESCRIPTION

All signature functions.

=head1 PUBLIC INTERFACE

=head2 new()

Don't use the constructor directly, use the ObjectManager instead:

    my $TemplateGeneratorObject = $Kernel::OM->Get('Kernel::System::TemplateGenerator');

=cut

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {};
    bless( $Self, $Type );

    $Self->{RichText} = $Kernel::OM->Get('Kernel::Config')->Get('Frontend::RichText');

    return $Self;
}

=head2 Salutation()

generate salutation

    my $Salutation = $TemplateGeneratorObject->Salutation(
        TicketID => 123,
        UserID   => 123,
        Data     => $ArticleHashRef,
    );

returns
    Text
    ContentType

=cut

sub Salutation {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Needed (qw(TicketID Data UserID)) {
        if ( !$Param{$Needed} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Needed!"
            );
            return;
        }
    }

    # Get ticket.
    my %Ticket = $Kernel::OM->Get('Kernel::System::Ticket')->TicketGet(
        TicketID      => $Param{TicketID},
        DynamicFields => 1,
    );

    # Get queue.
    my %Queue = $Kernel::OM->Get('Kernel::System::Queue')->QueueGet(
        ID => $Ticket{QueueID},
    );

    # Get salutation.
    my %Salutation = $Kernel::OM->Get('Kernel::System::Salutation')->SalutationGet(
        ID => $Queue{SalutationID},
    );

    # do text/plain to text/html convert
    if ( $Self->{RichText} && $Salutation{ContentType} =~ /text\/plain/i ) {
        $Salutation{ContentType} = 'text/html';
        $Salutation{Text}        = $Kernel::OM->Get('Kernel::System::HTMLUtils')->ToHTML(
            String                 => $Salutation{Text},
            DoNotReplaceHardBreaks => 1,
        );
    }

    # do text/html to text/plain convert
    if ( !$Self->{RichText} && $Salutation{ContentType} =~ /text\/html/i ) {
        $Salutation{ContentType} = 'text/plain';
        $Salutation{Text}        = $Kernel::OM->Get('Kernel::System::HTMLUtils')->ToAscii(
            String => $Salutation{Text},
        );
    }

    # get list unsupported tags for standard template
    my @ListOfUnSupportedTag = qw(OTRS_AGENT_SUBJECT OTRS_AGENT_BODY OTRS_CUSTOMER_BODY OTRS_CUSTOMER_SUBJECT);

    my $SalutationText = $Self->_RemoveUnSupportedTag(
        Text                 => $Salutation{Text} || '',
        ListOfUnSupportedTag => \@ListOfUnSupportedTag,
    );

    # replace place holder stuff
    $SalutationText = $Self->_Replace(
        RichText   => $Self->{RichText},
        Text       => $SalutationText,
        TicketData => \%Ticket,
        Data       => $Param{Data},
        UserID     => $Param{UserID},
        Recipient  => $Param{Recipient},
    );

    # add urls
    if ( $Self->{RichText} ) {
        $SalutationText = $Kernel::OM->Get('Kernel::System::HTMLUtils')->LinkQuote(
            String => $SalutationText,
        );
    }

    return $SalutationText;
}

=head2 Signature()

generate salutation

    my $Signature = $TemplateGeneratorObject->Signature(
        TicketID => 123,
        UserID   => 123,
        Data     => $ArticleHashRef,
    );

or

    my $Signature = $TemplateGeneratorObject->Signature(
        QueueID => 123,
        UserID  => 123,
        Data    => $ArticleHashRef,
    );

returns
    Text
    ContentType

=cut

sub Signature {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Needed (qw(Data UserID)) {
        if ( !$Param{$Needed} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Needed!"
            );
            return;
        }
    }

    # need ticket id or queue id
    if ( !$Param{TicketID} && !$Param{QueueID} ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => 'Need TicketID or QueueID!'
        );
        return;
    }

    # Get ticket data.
    my %Ticket;
    if ( $Param{TicketID} ) {
        %Ticket = $Kernel::OM->Get('Kernel::System::Ticket')->TicketGet(
            TicketID      => $Param{TicketID},
            DynamicFields => 1,
        );
    }

    # Get queue.
    my %Queue = $Kernel::OM->Get('Kernel::System::Queue')->QueueGet(
        ID => $Ticket{QueueID} || $Param{QueueID},
    );

    # Get signature.
    my %Signature = $Kernel::OM->Get('Kernel::System::Signature')->SignatureGet(
        ID => $Queue{SignatureID},
    );

    # do text/plain to text/html convert
    if ( $Self->{RichText} && $Signature{ContentType} =~ /text\/plain/i ) {
        $Signature{ContentType} = 'text/html';
        $Signature{Text}        = $Kernel::OM->Get('Kernel::System::HTMLUtils')->ToHTML(
            String                 => $Signature{Text},
            DoNotReplaceHardBreaks => 1,
        );
    }

    # do text/html to text/plain convert
    if ( !$Self->{RichText} && $Signature{ContentType} =~ /text\/html/i ) {
        $Signature{ContentType} = 'text/plain';
        $Signature{Text}        = $Kernel::OM->Get('Kernel::System::HTMLUtils')->ToAscii(
            String => $Signature{Text},
        );
    }

    # get list unsupported tags for standard template
    my @ListOfUnSupportedTag = qw(OTRS_AGENT_SUBJECT OTRS_AGENT_BODY OTRS_CUSTOMER_BODY OTRS_CUSTOMER_SUBJECT);

    my $SignatureText = $Self->_RemoveUnSupportedTag(
        Text                 => $Signature{Text} || '',
        ListOfUnSupportedTag => \@ListOfUnSupportedTag,
    );

    # replace place holder stuff
    $SignatureText = $Self->_Replace(
        RichText   => $Self->{RichText},
        Text       => $SignatureText,
        TicketData => \%Ticket,
        Data       => $Param{Data},
        QueueID    => $Param{QueueID},
        UserID     => $Param{UserID},
    );

    # add urls
    if ( $Self->{RichText} ) {
        $SignatureText = $Kernel::OM->Get('Kernel::System::HTMLUtils')->LinkQuote(
            String => $SignatureText,
        );
    }

    return $SignatureText;
}

=head2 Sender()

generate sender address (FROM string) for emails

    my $Sender = $TemplateGeneratorObject->Sender(
        QueueID => 123,
        UserID  => 123,
    );

returns:

    John Doe at Super Support <service@example.com>

and it returns the quoted real name if necessary

    "John Doe, Support" <service@example.tld>

=cut

sub Sender {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Needed (qw( UserID QueueID)) {
        if ( !$Param{$Needed} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Needed!"
            );
            return;
        }
    }

    # get sender attributes
    my %Address = $Kernel::OM->Get('Kernel::System::Queue')->GetSystemAddress(
        QueueID => $Param{QueueID},
    );

    # get config object
    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');

    # check config for agent real name
    my $UseAgentRealName = $ConfigObject->Get('Ticket::DefineEmailFrom');
    if ( $UseAgentRealName && $UseAgentRealName =~ /^(AgentName|AgentNameSystemAddressName)$/ ) {

        # get data from current agent
        my %UserData = $Kernel::OM->Get('Kernel::System::User')->GetUserData(
            UserID        => $Param{UserID},
            NoOutOfOffice => 1,
        );

        # set real name with user name
        if ( $UseAgentRealName eq 'AgentName' ) {

            # check for user data
            if ( $UserData{UserFullname} ) {

                # rewrite RealName
                $Address{RealName} = "$UserData{UserFullname}";
            }
        }

        # set real name with user name
        if ( $UseAgentRealName eq 'AgentNameSystemAddressName' ) {

            # check for user data
            if ( $UserData{UserFullname} ) {

                # rewrite RealName
                my $Separator = ' ' . $ConfigObject->Get('Ticket::DefineEmailFromSeparator')
                    || '';
                $Address{RealName} = $UserData{UserFullname} . $Separator . ' ' . $Address{RealName};
            }
        }
    }

    # prepare realname quote
    if ( $Address{RealName} =~ /([.]|,|@|\(|\)|:)/ && $Address{RealName} !~ /^("|')/ ) {
        $Address{RealName} =~ s/"//g;    # remove any quotes that are already present
        $Address{RealName} = '"' . $Address{RealName} . '"';
    }
    my $Sender = "$Address{RealName} <$Address{Email}>";

    return $Sender;
}

=head2 Template()

generate template

    my $Template = $TemplateGeneratorObject->Template(
        TemplateID => 123,
        TicketID   => 123,                  # Optional
        Data       => $ArticleHashRef,      # Optional
        UserID     => 123,
    );

Returns:

    $Template => 'Some text';

=cut

sub Template {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Needed (qw(TemplateID UserID)) {
        if ( !$Param{$Needed} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Needed!"
            );
            return;
        }
    }

    my $StandardTemplateObject = $Kernel::OM->Get('Kernel::System::StandardTemplate');

    my %Template = $StandardTemplateObject->StandardTemplateGet(
        ID => $Param{TemplateID},
    );

    # Convert comma separated TemplateType to array for better searching.
    my @TemplateTypes = split( /\s*,\s*/, $Template{TemplateType} );
    $Template{TemplateType} = \@TemplateTypes;

    # do text/plain to text/html convert
    if (
        $Self->{RichText}
        && $Template{ContentType} =~ /text\/plain/i
        && $Template{Template}
        )
    {
        $Template{ContentType} = 'text/html';
        $Template{Template}    = $Kernel::OM->Get('Kernel::System::HTMLUtils')->ToHTML(
            String                 => $Template{Template},
            DoNotReplaceHardBreaks => 1,
        );
    }

    # do text/html to text/plain convert
    if (
        !$Self->{RichText}
        && $Template{ContentType} =~ /text\/html/i
        && $Template{Template}
        )
    {
        $Template{ContentType} = 'text/plain';
        $Template{Template}    = $Kernel::OM->Get('Kernel::System::HTMLUtils')->ToAscii(
            String => $Template{Template},
        );
    }

    # Get user language.
    my $Language;
    my %Ticket;
    if ( defined $Param{TicketID} ) {

        # Get ticket data.
        %Ticket = $Kernel::OM->Get('Kernel::System::Ticket')->TicketGet(
            TicketID      => $Param{TicketID},
            DynamicFields => 1,
        );

        # Get recipient.
        my %User = $Kernel::OM->Get('Kernel::System::CustomerUser')->CustomerUserDataGet(
            User => $Ticket{CustomerUserID},
        );
        $Language = $User{UserLanguage};
    }

    # If template type is 'Create' and there is customer user information, treat it as a ticket param in order to
    # correctly replace customer user tags.
    my $IsCreateTemplate = grep { $_ eq 'Create' } @{ $Template{TemplateType} };
    if ( $IsCreateTemplate && $Param{CustomerUserID} ) {
        $Ticket{CustomerUserID} = $Param{CustomerUserID};
    }

    # if customer language is not defined, set default language
    $Language //= $Kernel::OM->Get('Kernel::Config')->Get('DefaultLanguage') || 'en';

    # get list unsupported tags for standard template
    my @ListOfUnSupportedTag = qw(OTRS_AGENT_SUBJECT OTRS_AGENT_BODY OTRS_CUSTOMER_BODY OTRS_CUSTOMER_SUBJECT);

    my %SupportedTypes = (
        Answer  => 1,
        Forward => 1,
        Note    => 1,
    );
    my $IsSupportedType = grep { $SupportedTypes{$_} } @{ $Template{TemplateType} };

    my $TemplateText = $Template{Template} || '';
    my @TemplateType = @{ $Template{TemplateType} };

    # Remove unsupported tags only for some template types.
    if ( !$IsSupportedType ) {
        $TemplateText = $Self->_RemoveUnSupportedTag(
            Text                 => $Template{Template} || '',
            ListOfUnSupportedTag => \@ListOfUnSupportedTag,
        );

        # Reset template type for unsupported tag.
        @TemplateType = ();
    }

    # replace place holder stuff
    $TemplateText = $Self->_Replace(
        RichText   => $Self->{RichText},
        Text       => $TemplateText || '',
        TicketData => \%Ticket,
        Data       => $Param{Data} || {},
        UserID     => $Param{UserID},
        Language   => $Language,
        Template   => \@TemplateType,
    );

    if ( $Self->{RichText} ) {
        $TemplateText =~ s/&amp;nbsp;/&nbsp;/g;
        $TemplateText =~ s/&lt;/</g;
        $TemplateText =~ s/&gt;/>/g;
        $TemplateText =~ s/&quot;/"/g;
        $TemplateText =~ s/&apos;/'/g;
    }

    return $TemplateText;
}

=head2 GenericAgentArticle()

generate internal or external notes

    my $GenericAgentArticle = $TemplateGeneratorObject->GenericAgentArticle(
        Notification => $NotificationDataHashRef,
        TicketID     => 123,
        UserID       => 123,
        Data         => $ArticleHashRef,             # Optional
    );

=cut

sub GenericAgentArticle {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Needed (qw(TicketID Notification UserID)) {
        if ( !$Param{$Needed} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Needed!"
            );
            return;
        }
    }

    my %Template = %{ $Param{Notification} };

    # get ticket object
    my $TicketObject = $Kernel::OM->Get('Kernel::System::Ticket');

    # Get ticket data.
    my %Ticket = $TicketObject->TicketGet(
        TicketID      => $Param{TicketID},
        DynamicFields => 1,
    );

    # do text/plain to text/html convert
    if (
        $Self->{RichText}
        && $Template{ContentType} =~ /text\/plain/i
        && $Template{Body}
        )
    {
        $Template{ContentType} = 'text/html';
        $Template{Body}        = $Kernel::OM->Get('Kernel::System::HTMLUtils')->ToHTML(
            String                 => $Template{Body},
            DoNotReplaceHardBreaks => 1,
        );
    }

    # do text/html to text/plain convert
    if (
        !$Self->{RichText}
        && $Template{ContentType} =~ /text\/html/i
        && $Template{Body}
        )
    {
        $Template{ContentType} = 'text/plain';
        $Template{Body}        = $Kernel::OM->Get('Kernel::System::HTMLUtils')->ToAscii(
            String => $Template{Body},
        );
    }

    # replace place holder stuff
    $Template{Body} = $Self->_Replace(
        RichText   => $Self->{RichText},
        Text       => $Template{Body},
        Recipient  => $Param{Recipient},
        Data       => $Param{Data} || {},
        TicketData => \%Ticket,
        UserID     => $Param{UserID},
    );
    $Template{Subject} = $Self->_Replace(
        RichText   => 0,
        Text       => $Template{Subject},
        Recipient  => $Param{Recipient},
        Data       => $Param{Data} || {},
        TicketData => \%Ticket,
        UserID     => $Param{UserID},
    );

    $Template{Subject} = $TicketObject->TicketSubjectBuild(
        TicketNumber => $Ticket{TicketNumber},
        Subject      => $Template{Subject} || '',
        Type         => 'New',
    );

    # add URLs and verify to be full HTML document
    if ( $Self->{RichText} ) {

        $Template{Body} = $Kernel::OM->Get('Kernel::System::HTMLUtils')->LinkQuote(
            String => $Template{Body},
        );
    }

    return %Template;
}

=head2 Attributes()

generate attributes

    my %Attributes = $TemplateGeneratorObject->Attributes(
        TicketID   => 123,
        ArticleID  => 123,
        ResponseID => 123,
        UserID     => 123,
        Action     => 'Forward', # Possible values are Reply and Forward, Reply is default.
    );

returns
    StandardResponse
    Salutation
    Signature

=cut

sub Attributes {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Needed (qw(TicketID Data UserID)) {
        if ( !$Param{$Needed} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Needed!"
            );
            return;
        }
    }

    # get ticket object
    my $TicketObject = $Kernel::OM->Get('Kernel::System::Ticket');

    # get queue
    my %Ticket = $TicketObject->TicketGet(
        TicketID      => $Param{TicketID},
        DynamicFields => 0,
    );

    # prepare subject ...
    $Param{Data}->{Subject} = $TicketObject->TicketSubjectBuild(
        TicketNumber => $Ticket{TicketNumber},
        Subject      => $Param{Data}->{Subject} || '',
        Action       => $Param{Action}          || '',
    );

    # get sender address
    $Param{Data}->{From} = $Self->Sender(
        QueueID => $Ticket{QueueID},
        UserID  => $Param{UserID},
    );

    return %{ $Param{Data} };
}

=head2 AutoResponse()

generate response

    my %AutoResponse = $TemplateGeneratorObject->AutoResponse(
        TicketID         => 123,
        OrigHeader       => {},
        AutoResponseType => 'auto reply',
        UserID           => 123,
        UserType         => 'Agent', # optional
    );

=cut

sub AutoResponse {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Needed (qw(TicketID AutoResponseType OrigHeader UserID)) {
        if ( !$Param{$Needed} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Needed!"
            );
            return;
        }
    }

    # get ticket object
    my $TicketObject = $Kernel::OM->Get('Kernel::System::Ticket');

    # Get ticket data.
    my %Ticket = $TicketObject->TicketGet(
        TicketID      => $Param{TicketID},
        DynamicFields => 1,
    );

    # get auto default responses
    my %AutoResponse = $Kernel::OM->Get('Kernel::System::AutoResponse')->AutoResponseGetByTypeQueueID(
        QueueID => $Ticket{QueueID},
        Type    => $Param{AutoResponseType},
    );

    return if !%AutoResponse;

    # get old article for quoting
    my $ArticleObject = $Kernel::OM->Get('Kernel::System::Ticket::Article');
    my @ArticleList   = $ArticleObject->ArticleList(
        TicketID   => $Param{TicketID},
        SenderType => 'customer',
        OnlyLast   => 1,
    );

    if ( !@ArticleList ) {
        @ArticleList = $ArticleObject->ArticleList(
            TicketID             => $Param{TicketID},
            IsVisibleForCustomer => 1,
            OnlyLast             => 1,
        );
    }

    if (@ArticleList) {
        my %Article = $ArticleObject->BackendForArticle( %{ $ArticleList[0] } )->ArticleGet( %{ $ArticleList[0] } );

        for my $Key (qw(From To Cc Subject Body)) {
            if ( !$Param{OrigHeader}->{$Key} ) {
                $Param{OrigHeader}->{$Key} = $Article{$Key} || '';
            }
            chomp $Param{OrigHeader}->{$Key};
        }
    }

    # format body (only if longer than 86 chars)
    if ( $Param{OrigHeader}->{Body} ) {
        if ( length $Param{OrigHeader}->{Body} > 86 ) {
            my @Lines = split /\n/, $Param{OrigHeader}->{Body};
            LINE:
            for my $Line (@Lines) {
                my $LineWrapped = $Line =~ s/(^>.+|.{4,86})(?:\s|\z)/$1\n/gm;

                next LINE if $LineWrapped;

                # if the regex does not match then we need
                # to add the missing new line of the split
                # else we will lose e.g. empty lines of the body.
                # (bug#10679)
                $Line .= "\n";
            }
            $Param{OrigHeader}->{Body} = join '', @Lines;
        }
    }

    # fill up required attributes
    for my $Key (qw(Subject Body)) {
        if ( !$Param{OrigHeader}->{$Key} ) {
            $Param{OrigHeader}->{$Key} = "No $Key";
        }
    }

    # get recipient
    my %User = $Kernel::OM->Get('Kernel::System::CustomerUser')->CustomerUserDataGet(
        User => $Ticket{CustomerUserID},
    );

    # get user language
    my $Language = $User{UserLanguage} || $Kernel::OM->Get('Kernel::Config')->Get('DefaultLanguage') || 'en';

    # do text/plain to text/html convert
    if ( $Self->{RichText} && $AutoResponse{ContentType} =~ /text\/plain/i ) {
        $AutoResponse{ContentType} = 'text/html';
        $AutoResponse{Text}        = $Kernel::OM->Get('Kernel::System::HTMLUtils')->ToHTML(
            String                 => $AutoResponse{Text},
            DoNotReplaceHardBreaks => 1,
        );
    }

    # do text/html to text/plain convert
    if ( !$Self->{RichText} && $AutoResponse{ContentType} =~ /text\/html/i ) {
        $AutoResponse{ContentType} = 'text/plain';
        $AutoResponse{Text}        = $Kernel::OM->Get('Kernel::System::HTMLUtils')->ToAscii(
            String => $AutoResponse{Text},
        );
    }

    # replace place holder stuff
    $AutoResponse{Text} = $Self->_Replace(
        RichText => $Self->{RichText},
        Text     => $AutoResponse{Text},
        Data     => {
            %{ $Param{OrigHeader} },
            From => $Param{OrigHeader}->{To},
            To   => $Param{OrigHeader}->{From},
        },
        TicketData      => \%Ticket,
        UserID          => $Param{UserID},
        Language        => $Language,
        AddTimezoneInfo => {
            AutoResponse => 1,
        },
    );
    $AutoResponse{Subject} = $Self->_Replace(
        RichText => 0,
        Text     => $AutoResponse{Subject},
        Data     => {
            %{ $Param{OrigHeader} },
            From => $Param{OrigHeader}->{To},
            To   => $Param{OrigHeader}->{From},
        },
        TicketData      => \%Ticket,
        UserID          => $Param{UserID},
        Language        => $Language,
        AddTimezoneInfo => {
            AutoResponse => 1,
        },
    );

    $AutoResponse{Subject} = $TicketObject->TicketSubjectBuild(
        TicketNumber => $Ticket{TicketNumber},
        Subject      => $AutoResponse{Subject},
        Type         => 'New',
        NoCleanup    => 1,
    );

    # get sender attributes based on auto response type
    if ( $AutoResponse{SystemAddressID} ) {

        my %Address = $Kernel::OM->Get('Kernel::System::SystemAddress')->SystemAddressGet(
            ID => $AutoResponse{SystemAddressID},
        );

        $AutoResponse{SenderAddress}  = $Address{Name};
        $AutoResponse{SenderRealname} = $Address{Realname};
    }

    # get sender attributes based on queue
    else {

        my %Address = $Kernel::OM->Get('Kernel::System::Queue')->GetSystemAddress(
            QueueID => $Ticket{QueueID},
        );

        $AutoResponse{SenderAddress}  = $Address{Email};
        $AutoResponse{SenderRealname} = $Address{RealName};
    }

    # add urls and verify to be full html document
    if ( $Self->{RichText} ) {

        $AutoResponse{Text} = $Kernel::OM->Get('Kernel::System::HTMLUtils')->LinkQuote(
            String => $AutoResponse{Text},
        );

        $AutoResponse{Text} = $Kernel::OM->Get('Kernel::System::HTMLUtils')->DocumentComplete(
            Charset  => 'utf-8',
            String   => $AutoResponse{Text},
            UserType => $Param{UserType} || 'Agent',
        );
    }

    return %AutoResponse;
}

=head2 NotificationEvent()

replace all OTRS smart tags in the notification body and subject

    my %NotificationEvent = $TemplateGeneratorObject->NotificationEvent(
        TicketData            => $TicketDataHashRef,
        Recipient             => $UserDataHashRef,          # Agent or Customer data get result
        Notification          => $NotificationDataHashRef,
        CustomerMessageParams => $ArticleHashRef,           # optional
        UserID                => 123,
    );

=cut

sub NotificationEvent {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Needed (qw(TicketData Notification Recipient UserID)) {
        if ( !$Param{$Needed} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Needed!",
            );
            return;
        }
    }

    if ( !IsHashRefWithData( $Param{Notification} ) ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => "Notification is invalid!",
        );
        return;
    }

    my %Notification = %{ $Param{Notification} };

    # exchanging original reference prevent it to grow up
    if ( ref $Param{CustomerMessageParams} && ref $Param{CustomerMessageParams} eq 'HASH' ) {
        my %LocalCustomerMessageParams = %{ $Param{CustomerMessageParams} };
        $Param{CustomerMessageParams} = \%LocalCustomerMessageParams;
    }

    my $ArticleObject = $Kernel::OM->Get('Kernel::System::Ticket::Article');

    # Get last article from customer.
    my @CustomerArticles = $ArticleObject->ArticleList(
        TicketID   => $Param{TicketData}->{TicketID},
        SenderType => 'customer',
        OnlyLast   => 1,
    );

    my %CustomerArticle;

    ARTICLE:
    for my $Article (@CustomerArticles) {
        next ARTICLE if !$Article->{ArticleID};

        %CustomerArticle = $ArticleObject->BackendForArticle( %{$Article} )->ArticleGet(
            %{$Article},
            DynamicFields => 0,
        );
    }

    # Get last article from agent.
    my @AgentArticles = $ArticleObject->ArticleList(
        TicketID   => $Param{TicketData}->{TicketID},
        SenderType => 'agent',
        OnlyLast   => 1,
    );

    my %AgentArticle;

    AGENTARTICLE:
    for my $Article (@AgentArticles) {
        next AGENTARTICLE if !$Article->{ArticleID};

        %AgentArticle = $ArticleObject->BackendForArticle( %{$Article} )->ArticleGet(
            %{$Article},
            DynamicFields => 0,
        );

        # Include the transmission status, if article is an email.
        my %CommunicationChannel = $Kernel::OM->Get('Kernel::System::CommunicationChannel')->ChannelGet(
            ChannelID => $Article->{CommunicationChannelID},
        );
        if ( $CommunicationChannel{ChannelName} eq 'Email' ) {
            my $TransmissionStatus = $ArticleObject->BackendForArticle( %{$Article} )->ArticleTransmissionStatus(
                ArticleID => $Article->{ArticleID},
            );
            if ( $TransmissionStatus && $TransmissionStatus->{Message} ) {
                $AgentArticle{TransmissionStatusMessage} = $TransmissionStatus->{Message};
            }
        }
    }

    my $LayoutObject = $Kernel::OM->Get('Kernel::Output::HTML::Layout');

    ARTICLE:
    for my $ArticleData ( \%CustomerArticle, \%AgentArticle ) {
        next ARTICLE if !$ArticleData->{TicketID};
        next ARTICLE if !$ArticleData->{ArticleID};

        # Get article preview in plain text and store it as Body key.
        $ArticleData->{Body} = $LayoutObject->ArticlePreview(
            TicketID   => $ArticleData->{TicketID},
            ArticleID  => $ArticleData->{ArticleID},
            ResultType => 'plain',
            UserID     => $Param{UserID},
        );

        # get accounted time
        my $AccountedTime = $ArticleObject->ArticleAccountedTimeGet(
            ArticleID => $ArticleData->{ArticleID},
        );

        # set the accounted time as part of the articles information
        $ArticleData->{TimeUnit} = $AccountedTime;
    }

    # Populate the hash 'CustomerMessageParams' with all the customer-article data
    # and overwrite it with 'CustomerMessageParams' passed in the Params (bug #13325).
    $Param{CustomerMessageParams} = {
        %CustomerArticle,
        %{ $Param{CustomerMessageParams} || {} },
    };

    # get system default language
    my $DefaultLanguage = $Kernel::OM->Get('Kernel::Config')->Get('DefaultLanguage') || 'en';

    my $Languages = [ $Param{Recipient}->{UserLanguage}, $DefaultLanguage, 'en' ];

    my $Language;
    LANGUAGE:
    for my $Item ( @{$Languages} ) {
        next LANGUAGE if !$Item;
        next LANGUAGE if !$Notification{Message}->{$Item};

        # set language
        $Language = $Item;
        last LANGUAGE;
    }

    # if no language, then take the first one available
    if ( !$Language ) {
        my @NotificationLanguages = sort keys %{ $Notification{Message} };
        $Language = $NotificationLanguages[0];
    }

    # copy the correct language message attributes to a flat structure
    for my $Attribute (qw(Subject Body ContentType)) {
        $Notification{$Attribute} = $Notification{Message}->{$Language}->{$Attribute};
    }

    # Get customer article fields.
    my %CustomerArticleFields;

    if (%CustomerArticle) {
        %CustomerArticleFields = $LayoutObject->ArticleFields(
            TicketID  => $CustomerArticle{TicketID},
            ArticleID => $CustomerArticle{ArticleID},
            UserID    => $Param{UserID},
        );
    }

    ARTICLE_FIELD:
    for my $ArticleField ( sort keys %CustomerArticleFields ) {
        next ARTICLE_FIELD if !defined $CustomerArticleFields{$ArticleField}->{Value};

        if ( !defined $Param{CustomerMessageParams}->{$ArticleField} ) {
            $Param{CustomerMessageParams}->{$ArticleField} = $CustomerArticleFields{$ArticleField}->{Value};
        }
        chomp $Param{CustomerMessageParams}->{$ArticleField};
    }

    # format body (only if longer the 86 chars)
    if ( $Param{CustomerMessageParams}->{Body} ) {
        if ( length $Param{CustomerMessageParams}->{Body} > 86 ) {
            my @Lines = split /\n/, $Param{CustomerMessageParams}->{Body};
            LINE:
            for my $Line (@Lines) {
                my $LineWrapped = $Line =~ s/(^>.+|.{4,86})(?:\s|\z)/$1\n/gm;

                next LINE if $LineWrapped;

                # if the regex does not match then we need
                # to add the missing new line of the split
                # else we will lose e.g. empty lines of the body.
                # (bug#10679)
                $Line .= "\n";
            }
            $Param{CustomerMessageParams}->{Body} = join '', @Lines;
        }
    }

    # fill up required attributes
    for my $Text (qw(Subject Body)) {
        if ( !$Param{CustomerMessageParams}->{$Text} ) {

            # Set to last customer article attribute if it is empty string.
            # For example, if Body is empty string (not undef!), it is maybe sent from NotificationOwnerUpdate event
            # and overrides last customer article body (in %CustomerArticle) above - see bug#14678.
            $Param{CustomerMessageParams}->{$Text} = $CustomerArticle{$Text} || "No $Text";
        }
    }

    my $Start = '<';
    my $End   = '>';
    if ( $Notification{ContentType} =~ m{text\/html} ) {
        $Start = '&lt;';
        $End   = '&gt;';
    }

    # replace <OTRS_CUSTOMER_DATA_*> tags early from CustomerMessageParams, the rests will be replaced
    # by ticket customer user
    KEY:
    for my $Key ( sort keys %{ $Param{CustomerMessageParams} || {} } ) {

        next KEY if !$Param{CustomerMessageParams}->{$Key};

        $Notification{Body}    =~ s/${Start}OTRS_CUSTOMER_DATA_$Key${End}/$Param{CustomerMessageParams}->{$Key}/gi;
        $Notification{Subject} =~ s/<OTRS_CUSTOMER_DATA_$Key>/$Param{CustomerMessageParams}->{$Key}{$Key}/gi;
    }

    # do text/plain to text/html convert
    if ( $Self->{RichText} && $Notification{ContentType} =~ /text\/plain/i ) {
        $Notification{ContentType} = 'text/html';
        $Notification{Body}        = $Kernel::OM->Get('Kernel::System::HTMLUtils')->ToHTML(
            String                 => $Notification{Body},
            DoNotReplaceHardBreaks => 1,
        );
    }

    # do text/html to text/plain convert
    if ( !$Self->{RichText} && $Notification{ContentType} =~ /text\/html/i ) {
        $Notification{ContentType} = 'text/plain';
        $Notification{Body}        = $Kernel::OM->Get('Kernel::System::HTMLUtils')->ToAscii(
            String => $Notification{Body},
        );
    }

    # get notify texts
    for my $Text (qw(Subject Body)) {
        if ( !$Notification{$Text} ) {
            $Notification{$Text} = "No Notification $Text for $Param{Type} found!";
        }
    }

    # replace place holder stuff
    $Notification{Body} = $Self->_Replace(
        RichText        => $Self->{RichText},
        Text            => $Notification{Body},
        Recipient       => $Param{Recipient},
        Data            => $Param{CustomerMessageParams},
        DataAgent       => \%AgentArticle,
        TicketData      => $Param{TicketData},
        UserID          => $Param{UserID},
        Language        => $Language,
        AddTimezoneInfo => {
            NotificationEvent => 1,
        },
    );

    $Notification{Subject} = $Self->_Replace(
        RichText        => 0,
        Text            => $Notification{Subject},
        Recipient       => $Param{Recipient},
        Data            => $Param{CustomerMessageParams},
        DataAgent       => \%AgentArticle,
        TicketData      => $Param{TicketData},
        UserID          => $Param{UserID},
        Language        => $Language,
        AddTimezoneInfo => {
            NotificationEvent => 1,
        },
    );

    # Keep the "original" (unmodified) subject and body for later use.
    $Notification{OriginalSubject} = $Notification{Subject};
    $Notification{OriginalBody}    = $Notification{Body};

    $Notification{Subject} = $Kernel::OM->Get('Kernel::System::Ticket')->TicketSubjectBuild(
        TicketNumber => $Param{TicketData}->{TicketNumber},
        Subject      => $Notification{Subject} || '',
        Type         => 'New',
    );

    # add URLs and verify to be full HTML document
    if ( $Self->{RichText} ) {

        $Notification{Body} = $Kernel::OM->Get('Kernel::System::HTMLUtils')->LinkQuote(
            String => $Notification{Body},
        );
    }

    return %Notification;
}

=begin Internal:

Private functions used by this package (not part of the documented public API).

=end Internal:

=head2 _Replace()

replace the placeholders in the text

=cut

sub _FixMailto {
    my ( $Self, $Param ) = @_;

    # check for mailto links
    # since the subject and body of those mailto links are
    # uri escaped we have to uri unescape them, replace
    # possible placeholders and then re-uri escape them
    my $Text = $Param->{Text};
    $Text =~ s{
        (href="mailto:[^\?]+\?)([^"]+")
    }
    {
        my $MailToHref        = $1;
        my $MailToHrefContent = $2;

        # Nested s///egx!
        $MailToHrefContent =~ s{
            ((?:subject|body)=)(.+?)("|&)
        }
        {
            my $SubjectOrBodyPrefix  = $1;
            my $SubjectOrBodyContent = $2;
            my $SubjectOrBodySuffix  = $3;

            my $SubjectOrBodyContentUnescaped = URI::Escape::uri_unescape( $SubjectOrBodyContent );

            # TODO: now we only recurse if any placeholders are found at all,
            # but it would be better to completely eliminate recursion
            if($SubjectOrBodyContentUnescaped =~ / (?: < | %3C ) OTRS_ /xi ) {
                $SubjectOrBodyContentUnescaped = $Self->_Replace(
                    %$Param,
                    Text     => $SubjectOrBodyContentUnescaped,
                    RichText => 0,
                );
            }

            my $SubjectOrBodyContentEscaped = URI::Escape::uri_escape_utf8( $SubjectOrBodyContentUnescaped );

            $SubjectOrBodyPrefix . $SubjectOrBodyContentEscaped . $SubjectOrBodySuffix;
        }egx;

        $MailToHref =~ s/\n//g;
        $MailToHrefContent =~ s/\n//g;
        $MailToHref . $MailToHrefContent;
    }egx;

    $Text =~ s/\n//g if $Param->{RichText};
    return $Text;
}

sub _FindRecipientTimeZone {
    my ( $Self, $AddTimezoneInfo, $Ticket, $Recipient ) = @_;
    my $CustomerUserObject = $Kernel::OM->Get('Kernel::System::CustomerUser');

    my $RecipientTimeZone = $Kernel::OM->Create('Kernel::System::DateTime')->OTRSTimeZoneGet();

    my %CustomerUser;
    if ( %$Ticket && $Ticket->{CustomerUserID} ) {
        %CustomerUser = $CustomerUserObject->CustomerUserDataGet( User => $Ticket->{CustomerUserID} );
    }

    my %UserPreferences;

    if ( $AddTimezoneInfo->{NotificationEvent} ) {
        if ( $Recipient->{Type} eq 'Agent' ) {
            %UserPreferences = $Kernel::OM->Get('Kernel::System::User')->GetPreferences(
                UserID => $Recipient->{UserID},
            );
        }
        elsif ( $Recipient->{Type} eq 'Customer' && $Recipient->{UserID} ) {
            %UserPreferences = $CustomerUserObject->GetPreferences(
                UserID => $Recipient->{UserID},
            );
        }
    }
    elsif ( $AddTimezoneInfo->{AutoResponse} && $Ticket->{CustomerUserID} && %CustomerUser ) {
        %UserPreferences = $CustomerUserObject->GetPreferences(
            UserID => $Ticket->{CustomerUserID},
        );
    }
    return $UserPreferences{UserTimeZone} // $RecipientTimeZone;
}

{
    my $DynamicFields;

    # Return the field configuration all DynamicFields for tickets, as a hash keyed by the
    # lowercased field name. This is cached for the lifetime of this module.
    sub _GetTicketDynamicFields {
        my ($Self) = @_;

        if ( !$DynamicFields ) {
            my $DynamicFieldList = $Kernel::OM->Get('Kernel::System::DynamicField')->DynamicFieldListGet(
                Valid      => 1,
                ObjectType => ['Ticket'],
            ) || [];
            $DynamicFields = {
                map { lc $_->{Name} => $_ } grep { IsHashRefWithData($_) } @$DynamicFieldList
            };
        }
        return $DynamicFields;
    }
}

# Dropdown, Checkbox and MultipleSelect DynamicFields, can store values (keys) that are
# different from the the values to display
# <OTRS_TICKET_DynamicField_NameX> returns the stored key
# <OTRS_TICKET_DynamicField_NameX_Value> returns the display value
sub _ReplaceDynamicField {
    my ( $Self, $LanguageObject, $Ticket, $RecipientTimeZone, $Name ) = @_;

#say STDERR "_ReplaceDynamicField(", join( ', ', map { $_ // '<undef>' } $LanguageObject, $Ticket, $RecipientTimeZone, $Name ), ")";
    my $Result = '-';
    my $ValueRequested;
    if ( $Name =~ /(.*)_value$/i ) {
        $Name           = $1;
        $ValueRequested = 1;
    }

    # Get the config via the lowercase key; $DynamicFieldConfig->{Name} has the
    # real one
    my $DynamicFieldConfig = $Self->_GetTicketDynamicFields()->{$Name};

    #say STDERR "DynamicFieldConfig: ", ( $DynamicFieldConfig // '<undef>' );
    return '-' if !defined $DynamicFieldConfig;    # should not normally happen but seems to happen in some test cases

    my $FullName    = "DynamicField_$DynamicFieldConfig->{Name}";
    my $TicketValue = $Ticket->{$FullName};

    # TODO: empty string or '-'?
    return '-' if !defined $TicketValue;           # Return if nothing set in current ticket

    # We'll need this condition a couple of times
    my $IsDateTimeWithZone = $RecipientTimeZone && $DynamicFieldConfig->{FieldType} eq 'DateTime';

    # Translate DateTime fields to recipient's time zone
    if ($IsDateTimeWithZone) {
        my $DateTimeObject = $Kernel::OM->Create(
            'Kernel::System::DateTime',
            ObjectParams => {
                String => $TicketValue,
            },
        );
        $DateTimeObject->ToTimeZone( TimeZone => $RecipientTimeZone );
        $TicketValue = $DateTimeObject->ToString();
    }

    my $DynamicFieldBackendObject = $Kernel::OM->Get('Kernel::System::DynamicField::Backend');

    if ($ValueRequested) {
        my $DisplayValue = $DynamicFieldBackendObject->ValueLookup(
            DynamicFieldConfig => $DynamicFieldConfig,
            Key                => $TicketValue,
            LanguageObject     => $LanguageObject,
        );

        my $DisplayValueString = $DynamicFieldBackendObject->ReadableValueRender(
            DynamicFieldConfig => $DynamicFieldConfig,
            Value              => $DisplayValue,
        );

        if ($DisplayValueString) {
            $Result = $DisplayValueString->{Value};

            # Add timezone info if needed.
            if ( $IsDateTimeWithZone && length($TicketValue) ) {
                $Result .= " ($RecipientTimeZone)";
            }
        }
        return $Result;
    }

    my $ValueString = $DynamicFieldBackendObject->ReadableValueRender(
        DynamicFieldConfig => $DynamicFieldConfig,
        Value              => $TicketValue,
    );

    # replace ticket content with the value from ReadableValueRender (if any)
    if ( IsHashRefWithData($ValueString) ) {
        $Result = $ValueString->{Value};

        # Add timezone info if needed.
        if ( $IsDateTimeWithZone && length($TicketValue) ) {
            $Result .= " ($RecipientTimeZone)";
        }
    }

    return $Result;
}

# This builds a big hash as a declarative tag replacement spec.
# Top level keys are tag prefixes that must be matched after the opening
# angle bracket. Values are hashes with four possible keys, all of them
# optional:
# Hash: a hash whose keys are simply appended to the prefix and values
#       substituted for the tag.
# Special: a hash whose keys are appended to the prefix. If the
#          combination of prefix+key is found, the subref value is called
#          and must return the value to be substituted. If Brackets is
#          also set, the value found in brackets is passed as an argument
#          to the sub.
# Brackets: a boolean value indicating whether to match tags of the format
#           <OTRS_FOO_BAR[thing]> with "thing" being passed to a Special
#           sub.
# Dynamic: this will add a match-everything part after the prefix, so as to
#          be able to match tags with arbitrary names. The value must be a
#          subref that will be passed the matched part after the prefix and
#          must return the substitution value.
#
# If subs take care of HTML encoding themselves as in the case of body
# snippets, they may return a second value that is taken as a boolean; if
# truthy, no HTML encoding/filtering is done before interpolating the value
# into the template.
sub _DefaultReplacements {
    my ( $Self, %Params ) = @_;

    # Better make sure these all exist.
    my (
        $Param,        $Ticket,    $Queue,     $Owner,   $Responsible, $CurrentUser,
        $CustomerUser, $Recipient, $Callbacks, $Objects, $RecipientTimeZone
        ) = @Params{
        qw( Param Ticket Queue Owner Responsible CurrentUser CustomerUser Recipient Callbacks Objects RecipientTimeZone)
        };

    # These ticket keys get special treatment like translation or time zone
    # math, so they are explicitly listed in the Special part and need to be
    # excluded from the Hash part below
    my @SpecialTicketKeys = qw(RealTillTimeNotUsed EscalationResponseTime EscalationUpdateTime EscalationSolutionTime
        UntilTime EscalationTimeWorkingTime EscalationTime FirstResponseTimeWorkingTime FirstResponseTime UpdateTimeWorkingTime
        UpdateTime SolutionTimeWorkingTime SolutionTime Type State StateType Lock Priority);
    my %SpecialTicketKeyLookup;
    @SpecialTicketKeyLookup{@SpecialTicketKeys} = (1) x @SpecialTicketKeys;

    # Takes a hash reference, returns a new one with all keys lowercased
    my $KeysToLower = sub {
        my ($Hash) = @_;
        return {
            map { lc $_ => $Hash->{$_} } keys %$Hash
        };
    };

    my $ReplaceUnixTime = sub {
        my ( $TicketKey, $RecipientTimeZone ) = @_;

        # Return a correct (and language-specific, if defined) format for fields
        # in Unix timestamp format
        return sub {

            #say STDERR "ReplaceUnixTime $TicketKey";
            return '-' if !defined $Ticket->{$TicketKey};

            #say STDERR "=> $Ticket->{$TicketKey}";
            my $DateTime = $Kernel::OM->Create(
                'Kernel::System::DateTime',
                ObjectParams => {
                    Epoch => $Ticket->{$TicketKey},
                },
            );
            $DateTime->ToTimeZone( TimeZone => $RecipientTimeZone ) if $RecipientTimeZone;
            return $Callbacks->{LocalizeTime}->( $DateTime->ToString() );
        };
    };

    my $TimeToRecipient = sub {
        my ( $TicketKey, $RecipientTimeZone ) = @_;

        # Shift a time value to the recipient's time zone and localize it if
        # necessary
        return sub {

            #say STDERR "TimeToRecipient $TicketKey";
            return '-'                   if !defined $Ticket->{$TicketKey};
            return $Ticket->{$TicketKey} if !$RecipientTimeZone;

            #say STDERR "=> $Ticket->{$TicketKey}";
            my $DateTime = $Kernel::OM->Create(
                'Kernel::System::DateTime',
                ObjectParams => {
                    String => $Ticket->{$TicketKey},
                },
            );
            $DateTime->ToTimeZone( TimeZone => $RecipientTimeZone );
            return $Callbacks->{LocalizeTime}->( $DateTime->ToString() );
        };
    };

    my $ReadableTimeInSeconds = sub {
        my ($TicketKey) = @_;

        # Take a value in seconds and convert it to human readable form
        return sub {

            #say STDERR "ReadableTimeInSeconds $TicketKey";
            return '-' if !defined $Ticket->{$TicketKey};

            #say STDERR "=> $Ticket->{$TicketKey}";
            return $Callbacks->{ReadableTimeInSeconds}->( $Ticket->{$TicketKey} );
        }
    };

    my $Translated = sub {
        my ($TicketKey) = @_;

        # Simply translate a value, usually an enum
        return sub {

            #say STDERR "Translated $TicketKey";
            return '-' if !defined $Ticket->{$TicketKey};

            #say STDERR "=> $Ticket->{$TicketKey}";
            return $Callbacks->{Translated}->( $Ticket->{$TicketKey} );
        }
    };

    my %Replacements = (
        OTRS_AGENT => {
            Hash    => { %$CurrentUser, %{ $Param->{DataAgent} // {} } },
            Special => {
                subject => sub {
                    my ($Chars) = @_;
                    $Callbacks->{GetSubjectSnippet}->( 'DataAgent', $Chars );
                },
                map {
                    $_ => sub {
                        my ($Lines) = @_;
                        $Callbacks->{GetBodySnippet}->( 'DataAgent', $Lines );
                    }
                } qw( email note body ),
            },
            Brackets => 1,
        },

        OTRS_CUSTOMER => {
            Special => {
                subject => sub {
                    my ($Chars) = @_;
                    return $Callbacks->{GetSubjectSnippet}->( 'Data', $Chars );
                },
                realname => sub {
                    if ( $Ticket->{CustomerUserID} ) {
                        my $Name = $Objects->{CustomerUser}->CustomerName(
                            UserLogin => $Ticket->{CustomerUserID}
                        );
                        return $Name if $Name;
                    }

                    return $Recipient->{Realname} if defined $Recipient->{Realname};

                    my $From = $Param->{Data}{ReplyTo} || $Param->{Data}{To};
                    return '-' if !$From;
                    my @Addresses = Mail::Address->parse($From);
                    return '-' if !@Addresses;
                    return $Addresses[0]->name() // $Addresses[0]->address();
                },
                map {
                    $_ => sub {
                        my ($Lines) = @_;
                        return $Callbacks->{GetBodySnippet}->( 'Data', $Lines );
                    }
                } qw( email note body ),
            },
            Hash     => { %$CustomerUser, %{ $Param->{Data} } },
            Brackets => 1,    # will unintentionally allow REALNAME[foo] with brackets being ignored
        },

        OTRS_EMAIL => {
            Special => {
                date => sub {
                    my ($Timezone) = @_;
                    my $DateTimeObject = $Kernel::OM->Create('Kernel::System::DateTime');
                    if ( defined $Timezone && $DateTimeObject->IsTimeZoneValid( TimeZone => $Timezone ) ) {
                        $DateTimeObject->ToTimeZone( TimeZone => $Timezone );
                    }
                    else {
                        $Timezone = $DateTimeObject->OTRSTimeZoneGet();
                    }
                    return $DateTimeObject->Format( Format => "%A, %B %e, %Y at %T ($Timezone)" );
                },
            },
            Brackets => 1,
        },

        OTRS_FIRST => {
            Hash => {
                name => $CurrentUser->{UserFirstname},
            },
        },

        OTRS_LAST => {
            Hash => {
                name => $CurrentUser->{UserLastname},
            },
        },

        OTRS_NOTIFICATION_RECIPIENT => {
            Hash    => $Recipient,
            Special => {

                # This is needed to match OTRS_QUEUE. It will also allow
                # OTRS_NOTIFICATION_RECIPIENT_QUEUE which hopefully nobody will
                # use but it should do no harm.
                queue => sub {
                    return $Ticket->{Queue} // '-';
                },
                comment => sub {
                    my ($Lines) = @_;

                    # Default to huge number of lines because for some reason we always want quote signs
                    # This curiously specific number is the maximum quantifier
                    # in a curly-brace regexp expression.
                    $Callbacks->{GetBodySnippet}->( 'Data', $Lines // 32766 );
                },
            },
            Brackets => 1,
        },

        OTRS_OWNER => {
            Hash => $Owner,
        },

        OTRS_RESPONSIBLE => {
            Hash => $Responsible,
        },

        OTRS_TA => {

            # This is a dummy "dynamicfield" function to just leave OTRS_TA_* tags
            # (needed for process management) alone instead of catching them as
            # unknown <OTRS_*> tags
            Dynamic => sub {
                my ($Name) = @_;
                return "<OTRS_TA_$Name>";
            },
        },

        OTRS_TICKET => {
            Special => {
                last_article_id => sub {
                    return '' if !$Ticket->{TicketID};
                    my @LastTicketArticle = $Objects->{Article}->ArticleList(
                        TicketID => $Ticket->{TicketID},
                        OnlyLast => 1,
                    );
                    return ( @LastTicketArticle ? $LastTicketArticle[0]->{ArticleID} : '' );
                },
                (
                    # If you change this field list, make sure to include it in %SpecialTicketKeys above!
                    map { lc $_ => $ReplaceUnixTime->( $_, $RecipientTimeZone ) }
                        qw(RealTillTimeNotUsed EscalationResponseTime EscalationUpdateTime EscalationSolutionTime)
                ),
                (
                    # If you change this field list, make sure to include it in %SpecialTicketKeys above!
                    map { lc $_ => $ReadableTimeInSeconds->($_) }
                        qw(UntilTime EscalationTimeWorkingTime EscalationTime FirstResponseTimeWorkingTime
                        FirstResponseTime UpdateTimeWorkingTime UpdateTime SolutionTimeWorkingTime SolutionTime)
                ),
                (
                    map { lc $_ => $Translated->($_) } qw(Type State StateType Lock Priority)
                ),
                (

                    # Change time to recipient's timezone if needed
                    # and later append timezone information.
                    # For more information,
                    # see bug#13865 (https://bugs.otrs.org/show_bug.cgi?id=13865)
                    # and bug#14270 (https://bugs.otrs.org/show_bug.cgi?id=14270).
                    map { lc $_ => $TimeToRecipient->( $_, $RecipientTimeZone ) }
                    grep {
                        $Ticket->{$_} &&
                            !m{ \A DynamicField_ }x &&
                            $Ticket->{$_} =~ m{ \A (\d{4})-(\d\d)-(\d\d)\s(\d\d):(\d\d):(\d\d) \z }x
                    } keys %$Ticket
                ),
            },
            Hash => {
                id     => $Ticket->{TicketID},
                number => $Ticket->{TicketNumber},
                map { $_ => $Ticket->{$_} } (

                    # Exclude all DynamicFields and all in %SpecialTicketKeyLookup
                    ( grep { !( $SpecialTicketKeyLookup{$_} || !/^DynamicField_/ ) } keys %$Ticket ),

                    # Standard keys should always be there even if no
                    # TicketID/TicketData
                    qw( Age ArchiveFlag ChangeBy Changed CreateBy Created
                        CustomerID CustomerUserID GroupID Lock
                        LockID Owner OwnerID Priority PriorityID Queue QueueID
                        Responsible ResponsibleID SLAID ServiceID State StateID
                        StateType TicketID TicketNumber Title Type TypeID
                        UnlockTimeout
                    ),
                ),
            },
        },

        OTRS_TICKET_DYNAMICFIELD => {
            Dynamic => sub {
                my ($Name) = @_;
                $Self->_ReplaceDynamicField( $Objects->{Language}, $Ticket, $RecipientTimeZone, $Name );
            },
            Brackets => 1,
        }
    );

    # A bit of postprocessing
    for my $ReplaceSpec ( values %Replacements ) {

        # All the hash keys must be lowercase
        $ReplaceSpec->{Hash} = $KeysToLower->( $ReplaceSpec->{Hash} );

        # Add a dummy Dynamic section if not present to catch invalid tags
        $ReplaceSpec->{Dynamic} //= sub {'-'};
    }

    # Set up some aliases for tag readability
    # TODO optimize this during RE generation to avoid duplicate Hash key lists?
    $Replacements{OTRS_CURRENT}            = $Replacements{OTRS_AGENT};
    $Replacements{OTRS_CUSTOMER_DATA}      = $Replacements{OTRS_CUSTOMER};
    $Replacements{OTRS_TICKET_OWNER}       = $Replacements{OTRS_OWNER};
    $Replacements{OTRS_TICKET_RESPONSIBLE} = $Replacements{OTRS_RESPONSIBLE};
    $Replacements{OTRS}                    = $Replacements{OTRS_NOTIFICATION_RECIPIENT};

    return \%Replacements;
}

# This returns the extensive structure that specifies all tag replacements.
# Which is just the result of _DefaultReplacements() here. The extra level of
# function calls is just there to give extensions a place to hook into when
# adding/modifying tags. Overwrite this function and return whatever you want.
sub _Replacements {
    my ( $Self, %Params ) = @_;
    return $Self->_DefaultReplacements(%Params);
}

# Do the whole tag replacement dance
{
    my ( $LocalLayoutObject, $LanguageObject );
    my $PreviousLanguage = '';

    sub _Replace {
        my ( $Self, %Param ) = @_;
        my $ArticleObject      = $Kernel::OM->Get('Kernel::System::Ticket::Article');
        my $ConfigObject       = $Kernel::OM->Get('Kernel::Config');
        my $CustomerUserObject = $Kernel::OM->Get('Kernel::System::CustomerUser');
        my $HTMLUtilsObject    = $Kernel::OM->Get('Kernel::System::HTMLUtils');
        my $TicketObject       = $Kernel::OM->Get('Kernel::System::Ticket');
        my $UserObject         = $Kernel::OM->Get('Kernel::System::User');

        my ( $Start, $End, $Tag );
        my $RecipientTimeZone;
        my ( %Ticket, %Queue, %Owner, %Responsible, %CurrentUser, %CustomerUser );

        for my $Needed (qw(Text RichText Data UserID)) {
            if ( !defined $Param{$Needed} ) {
                $Kernel::OM->Get('Kernel::System::Log')->Log(
                    Priority => 'error',
                    Message  => "Need $Needed!"
                );
                return;
            }
        }

        if ( $Param{Language} && $Param{Language} ne $PreviousLanguage ) {

            # We can reuse the expensive-to-build objects as long as Language
            # hasn't changed
            $LanguageObject = Kernel::Language->new(
                UserLanguage => $Param{Language},
            );
            $LocalLayoutObject = Kernel::Output::HTML::Layout->new( LanguageObject => $LanguageObject );
            $PreviousLanguage  = $Param{Language};
        }

        # This is the template text we'll be working on
        my $Text = $Self->_FixMailto( \%Param );

        #say STDERR "_Replace($Text)";
        #say STDERR "PARAM:", YAML::XS::Dump( \%Param );

        # Tags look different depending on what kind of text we're working with
        if ( $Param{RichText} ) {
            ( $Start, $End ) = ( '&lt;', '&gt;' );
            $Param{Text} =~ s/[\n\r]//g;
        }
        else {
            ( $Start, $End ) = ( '<', '>' );
        }

        # Fill a bunch of data structures if their corresponding params are set
        if ( $Param{TicketData} ) {
            %Ticket = %{ $Param{TicketData} };
        }
        if ( $Param{QueueID} ) {
            %Queue = $Kernel::OM->Get('Kernel::System::Queue')->QueueGet(
                ID => $Param{QueueID},
            );
        }
        if ( $Ticket{OwnerID} ) {
            %Owner = $UserObject->GetUserData(
                UserID        => $Ticket{OwnerID},
                NoOutOfOffice => 1,
            );
        }
        if ( $Ticket{ResponsibleID} ) {
            %Responsible = $UserObject->GetUserData(
                UserID        => $Ticket{ResponsibleID},
                NoOutOfOffice => 1,
            );
        }
        %CurrentUser = $UserObject->GetUserData(
            UserID        => $Param{UserID},
            NoOutOfOffice => 1,
        );
        if ( $Ticket{CustomerUserID} || $Param{Data}->{CustomerUserID} ) {
            my $CustomerUserID = $Param{Data}->{CustomerUserID} || $Ticket{CustomerUserID};

            %CustomerUser = $CustomerUserObject->CustomerUserDataGet(
                User => $CustomerUserID,
            );
        }

        # Determine recipient's timezone if needed.
        if ( $Param{AddTimezoneInfo} ) {
            $RecipientTimeZone = $Self->_FindRecipientTimeZone( $Param{AddTimezoneInfo}, \%Ticket, $Param{Recipient} );
        }

        # Replace config options.
        # TODO: integrate in main RE?
        $Tag = $Start . 'OTRS_CONFIG_';
        $Text =~ s{$Tag(.+?)$End}{
            my $Key   = $1;
            my $Value = $ConfigObject->Get($Key) // '';

            # Mask sensitive config options and return the function's return value
            $Self->_MaskSensitiveValue( $Key, $Value, 1 );
        }egx;

        my %Recipient = %{ $Param{Recipient} || {} };
        if ( !%Recipient && $Param{RecipientID} ) {
            %Recipient = $UserObject->GetUserData(
                UserID        => $Param{RecipientID},
                NoOutOfOffice => 1,
            );
        }

        # Some callbacks needed for replacement generation
        my %Callbacks = (

            # Get a message body from %^Param as specified by $Where. If $Lines is
            # specified, take as many lines and quote them
            GetBodySnippet => sub {
                my ( $Where, $Lines ) = @_;
                my $SafeLines = $Lines || 2500;
                my $RichText  = !!$Param{RichText};
                return '-' if !defined $Param{$Where} || !defined $Param{$Where}{Body};

   #say STDERR "GetBodySnippet($Where, ", ( $Lines // '<undef>' ), ": SafeLines=$SafeLines Body='$Param{$Where}{Body}'";
                my ($Snippet) = $Param{$Where}{Body} =~ / ( (?: .*\n? ){0,$SafeLines} ) /x;

                #say STDERR "Snippet [Perl $^V]: '$Snippet'";
                return ( '', $RichText ) if !defined $Snippet;
                chomp $Snippet;

                # no quoting unless lines requested!
                if ( !defined $Lines ) {
                    $Snippet =~ s{ (.+) ( \n+ | \z ) }{<p>$1</p>$2}xg if $RichText;

                    #say STDERR "Returning quoted snippet: '$Snippet'";
                    return ( $Snippet, $RichText );
                }

                if ( $Param{RichText} ) {

                    # Remove HTML line breaks
                    $Snippet =~ s/(<br\/>)\s{0,20}$//gs;

                    # replace hard breaks with paragraphs before there will
                    # be added any "HTML" content like blockquote that would
                    # make it complex to replace hard breaks afterwards
                    $Snippet = $HTMLUtilsObject->ToHTMLReplaceWithParagraphs(
                        String => $Snippet,
                    );

                    # Add quote
                    $Snippet = $HTMLUtilsObject->DocumentCleanup(
                        String => "<blockquote type=\"cite\">$Snippet</blockquote>"
                    );
                }
                else {
                    # Just add ASCII quote marks at start of line
                    $Snippet =~ s/^/> /mg if !$Param{RichText};
                }

                #say STDERR "Returning quoted snippet: '$Snippet'";
                return ( $Snippet, $RichText );
            },

            # Get a subject line, optionally cut down to $Chars characters
            GetSubjectSnippet => sub {
                my ( $Where, $Chars ) = @_;
                return '-' if !$Param{$Where} || !defined $Param{$Where}{Subject};

                my $Subject = $TicketObject->TicketSubjectClean(
                    TicketNumber => $Ticket{TicketNumber},
                    Subject      => $Param{$Where}{Subject},
                );

                $Subject =~ s/^(.{$Chars}).*$/$1 [...]/ if defined $Chars;
                return $Subject;
            },

            LocalizeTime => sub {
                my ($TimeString) = @_;

                return $TimeString if !$LanguageObject;

                my $Localized = $LanguageObject->FormatTimeString(
                    $TimeString,
                    'DateFormat',
                    'NoSeconds',
                );

                return $Localized if !$RecipientTimeZone;

                # Append timezone information
                return "$Localized ($RecipientTimeZone)";
            },

            # Turn a value in seconds into something more readable
            ReadableTimeInSeconds => sub {
                my ($Seconds) = @_;
                return $Seconds if !$LocalLayoutObject;
                return $LocalLayoutObject->CustomerAge(
                    Age   => $Seconds,
                    Space => ' '
                );
            },

            Translated => sub {
                my ($Value) = @_;
                return $Value if !$LanguageObject;
                return $LanguageObject->Translate($Value);
            },
        );

        # Pass basically the entire environment
        my $Replacements = $Self->_Replacements(
            Param        => \%Param,
            Ticket       => \%Ticket,
            Queue        => \%Queue,
            Owner        => \%Owner,
            Responsible  => \%Responsible,
            CurrentUser  => \%CurrentUser,
            CustomerUser => \%CustomerUser,
            Callbacks    => \%Callbacks,
            Recipient    => \%Recipient,
            Objects      => {
                Article      => $ArticleObject,
                Config       => $ConfigObject,
                CustomerUser => $CustomerUserObject,
                Language     => $LanguageObject,
            },
            RecipientTimeZone => $RecipientTimeZone,
        );

        # Make a sub-regexp out of all hash keys and the prefix if
        # $Replacements{$_}{Hash} and/or $Replacements{$_}{Special} has keys;
        # if $Brackets is true, also add one for a "[n]" expression at the end.
        my $HashKeyAlternation = sub {
            my ($Prefix) = @_;
            my ( @HashKeys, @SpecialKeys, @Dynamic );
            my $Spec = $Replacements->{$_};

            # Keys where the value just has to be looked up
            @HashKeys = keys %{ $Spec->{Hash} } if $Spec->{Hash};

            # Keys that need special treatment via a coderef
            @SpecialKeys = keys %{ $Spec->{Special} } if $Spec->{Special};

            # Catchall for unknown name in e.g.
            # OTRS_TICKET_DynamicField_$NAME and OTRS_TICKET_DynamicField_${NAME}_Value
            @Dynamic = '.+?' if $Spec->{Dynamic};

            # This will produce garbage if @HashKeys, @SpecialKeys and @Dynamic are
            # all empty. With the auto-Dynamic above, this should never happen.

            return sprintf(
                '(?<cat> %s ) _ (?<elem> %s ) %s',
                $Prefix,
                join( '|', sort { length($b) <=> length($a) } ( @HashKeys, @SpecialKeys ), @Dynamic ),

                # TODO: use Brackets only for Special/Dynamic?
                $Spec->{Brackets} ? '(?: \[ (?<bracket> [^]]+ ) \] )?' : ''
            );
        };

        # This constructs one big-ass regexp from the %Replacements spec
        my $ReplacerRE = sprintf(
            "%s(?:\n%s\n)%s",
            $Start,
            join(
                "|\n",
                map { $HashKeyAlternation->($_) } sort { length($b) <=> length($a) } keys %$Replacements
            ),
            $End
        );

        #say STDERR "RE: $ReplacerRE";

        # Follow-up for bug#10825.
        # Set data for replacing of specific tags in Templates:
        # - OTRS_AGENT_SUBJECT, OTRS_AGENT_BODY - subject/body of the CURRENT/LATEST agent article
        # - OTRS_CUSTOMER_SUBJECT, OTRS_CUSTOMER_BODY - subject/body of the CURRENT/LATEST customer article
        # - OTRS_AGENT_SUBJECT[n]    - first n characters of the subject of the CURRENT/LATEST agent article
        # - OTRS_AGENT_BODY[n]       - first n lines of the body of the CURRENT/LATEST agent article
        # - OTRS_CUSTOMER_SUBJECT[n] - first n characters of the subject of the CURRENT/LATEST customer article
        # - OTRS_CUSTOMER_BODY[n]    - first n lines of the body of the CURRENT/LATEST customer article
        #
        # For Note template we need the last article.
        # For Answer, $Param{Data} has selected or last article data, depends whether ArticleID is sent or not.
        # For Forward, $Param{Data} has the following article data:
        # - if ArticleID is sent, data is from selected article.
        # - if ArticleID is not sent, data is from last customer/agent/any article.
        if ( $Param{Template} && $Ticket{TicketID} ) {
            if ( grep { $_ eq 'Note' } @{ $Param{Template} } ) {

                # Get last article from agent.
                my @AgentArticles = $ArticleObject->ArticleList(
                    TicketID   => $Param{TicketData}->{TicketID},
                    SenderType => 'agent',
                    OnlyLast   => 1,
                );
                if ( @AgentArticles && IsHashRefWithData( $AgentArticles[0] ) ) {
                    my %AgentArticle = $ArticleObject->BackendForArticle( %{ $AgentArticles[0] } )->ArticleGet(
                        %{ $AgentArticles[0] },
                        DynamicFields => 0,
                    );

                    $Param{DataAgent}->{Subject} = $AgentArticle{Subject};
                    $Param{DataAgent}->{Body}    = $AgentArticle{Body};
                }

                # Get last article from customer.
                my @CustomerArticles = $ArticleObject->ArticleList(
                    TicketID   => $Param{TicketData}->{TicketID},
                    SenderType => 'customer',
                    OnlyLast   => 1,
                );
                if ( @CustomerArticles && IsHashRefWithData( $CustomerArticles[0] ) ) {

                    my %CustomerArticle = $ArticleObject->BackendForArticle( %{ $CustomerArticles[0] } )->ArticleGet(
                        %{ $CustomerArticles[0] },
                        DynamicFields => 0,
                    );
                    $Param{Data}->{Subject} = $CustomerArticle{Subject};
                    $Param{Data}->{Body}    = $CustomerArticle{Body};
                }
            }
            elsif ( grep { $_ eq 'Answer' || $_ eq 'Forward' } @{ $Param{Template} } ) {

                # If $Param{Data} has agent article data, we will set subject and body in $Param{DataAgent}
                # to values from $Param{Data} in order to right replacing of OTRS_AGENT_SUBJECT/BODY tags.
                if ( $Param{Data}->{SenderType} && $Param{Data}->{SenderType} eq 'agent' ) {
                    $Param{DataAgent}->{Subject} = $Param{Data}->{Subject};
                    $Param{DataAgent}->{Body}    = $Param{Data}->{Body};
                }
            }
        }

        # Apply the replacer regexp. This does all the heavy lifting.
        my $OrigText = $Text;    # Just for error reporting
        $Text =~ s{
        $ReplacerRE
    }{
        # TODO stick this in another closure
        my ( $Prefix, $Elem, $Bracket ) = ( uc($+{cat}), lc($+{elem}), $+{bracket} );
        my $Spec = $Replacements->{$Prefix};
        my ($Value, $SkipHTMLFilter);
        #say STDERR "REPLACING: $Prefix $Elem";
        if( $Spec->{Special}{$Elem} ) {
            #say STDERR "FOUND Special";
            # This needs special treatment. Check whether a value exists and
            # if so, pass it along to the callback.
            ($Value, $SkipHTMLFilter) = $Spec->{Special}{$Elem}->( $Bracket );
            $Value = $Self->_MaskSensitiveValue( $Elem, $Value );
        }
        elsif( $Spec->{Hash} && $Spec->{Hash}{$Elem} ) {
            #say STDERR "FOUND Hash";
            # Just substitute the value found in hash or '-'
            $Value = $Spec->{Hash}{$Elem} // '-';
            $Value = $Self->_MaskSensitiveValue( $Elem, $Value );
        }
        elsif( $Spec->{Dynamic} ) {
            #say STDERR "FOUND Dynamic";
            # Arbitrary name matched for a dynamic field
            ($Value, $SkipHTMLFilter) = $Spec->{Dynamic}->($Elem, $Bracket);
        }
        else {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "BUG: unmatched key: '$Prefix' / '$Elem' in '$OrigText'",
            );
            $Value = '-';
        }
        if( $Param{RichText} && !$SkipHTMLFilter ) {
            $Value = $HTMLUtilsObject->ToHTMLReplaceWithParagraphs(
                String => $Value,
            );
        }
        $Value;
    }egix;

        return $Text;
    }
}

=head2 _RemoveUnSupportedTag()

cleanup all not supported tags

    my $Text = $TemplateGeneratorObject->_RemoveUnSupportedTag(
        Text => $SomeTextWithTags,
        ListOfUnSupportedTag => \@ListOfUnSupportedTag,
    );

=cut

sub _RemoveUnSupportedTag {

    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Item (qw(Text ListOfUnSupportedTag)) {
        if ( !defined $Param{$Item} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Item!"
            );
            return;
        }
    }

    my $Start = '<';
    my $End   = '>';
    if ( $Self->{RichText} ) {
        $Start = '&lt;';
        $End   = '&gt;';
        $Param{Text} =~ s/(\n|\r)//g;
    }

    # Cleanup all not supported tags with and without number, e.g. OTRS_CUSTOMER_BODY and OTRS_CUSTOMER_BODY[n].
    my $NotSupportedTag = $Start . "(?:" . join( "|", @{ $Param{ListOfUnSupportedTag} } ) . ")(\\[.*?\\])?" . $End;
    $Param{Text} =~ s/$NotSupportedTag/-/gi;

    return $Param{Text};
}

=head2 _MaskSensitiveValue()

Mask sensitive value, i.e. a password, a security token, etc.

    my $MaskedValue = $Self->_MaskSensitiveValue( 'DatabasePassword', 'secretvalue', 1 );

Returns masked value in case the key is matched:

   $MaskedValue = 'xxx';

=cut

{
    my $SecretRE
        = qr{ config|secret|passw|userpw|auth|token }xi;    # Match general key names, i.e. from the user preferences.
    my $PasswordRE = qr{ (?:password|pw) \d* $ }xi;         # Match forbidden config keys.

    sub _MaskSensitiveValue {
        my ( $Self, $Key, $Value, $IsConfig ) = @_;

        return '' if !$Key || !defined $Value;

        my $Match = $IsConfig ? $PasswordRE : $SecretRE;
        return 'xxx' if $Key =~ $Match;
        return $Value;
    }
}
1;

=head1 TERMS AND CONDITIONS

This software is part of the OTRS project (L<https://otrs.org/>).

This software comes with ABSOLUTELY NO WARRANTY. For details, see
the enclosed file COPYING for license information (GPL). If you
did not receive this file, see L<https://www.gnu.org/licenses/gpl-3.0.txt>.

=cut
