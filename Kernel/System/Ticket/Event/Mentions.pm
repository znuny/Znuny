# --
# Copyright (C) 2021 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --
## nofilter(TidyAll::Plugin::Znuny::Perl::LayoutObject)

package Kernel::System::Ticket::Event::Mentions;

use strict;
use warnings;

use Kernel::System::VariableCheck qw(:all);

our @ObjectDependencies = (
    'Kernel::Config',
    'Kernel::Output::HTML::Layout',
    'Kernel::System::CommunicationChannel',
    'Kernel::System::Log',
    'Kernel::System::Mention',
    'Kernel::System::Ticket::Article',
);

sub new {
    my ( $Type, %Param ) = @_;

    my $Self = {};

    bless( $Self, $Type );

    return $Self;
}

sub Run {
    my ( $Self, %Param ) = @_;

    my $LogObject                  = $Kernel::OM->Get('Kernel::System::Log');
    my $ConfigObject               = $Kernel::OM->Get('Kernel::Config');
    my $LayoutObject               = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $ArticleObject              = $Kernel::OM->Get('Kernel::System::Ticket::Article');
    my $CommunicationChannelObject = $Kernel::OM->Get('Kernel::System::CommunicationChannel');
    my $MentionObject              = $Kernel::OM->Get('Kernel::System::Mention');

    my %Article = $ArticleObject->ArticleGet(
        TicketID  => $Param{Data}->{TicketID},
        ArticleID => $Param{Data}->{ArticleID},
    );
    return 1 if !%Article;

    my %CommunicationChannel = $CommunicationChannelObject->ChannelGet(
        ChannelID => $Article{CommunicationChannelID},
    );

    # Ignore all articles that were not created by an agent.
    # Note that also phone tickets are always created by an agent, regardless of sender type.
    return 1 if $Article{SenderType} ne 'agent' && $CommunicationChannel{ChannelName} ne 'Phone';

    # Use preview body because HTML is needed.
    my $HTMLBody = $LayoutObject->ArticlePreview(
        TicketID  => $Param{Data}->{TicketID},
        ArticleID => $Param{Data}->{ArticleID},
    );
    return 1 if !IsStringWithData($HTMLBody);

    my $MentionsConfig = $ConfigObject->Get('Mentions') // {};
    my $MentionsLimit  = $MentionsConfig->{Limit}       // 20;

    my $MentionedUserIDs = $MentionObject->GetMentionedUserIDsFromString(
        HTMLString      => $HTMLBody,
        PlainTextString => $Article{Body} // '',
        Limit           => $MentionsLimit,
    );
    return 1 if !IsArrayRefWithData($MentionedUserIDs);

    MENTIONEDUSERID:
    for my $MentionedUserID ( sort @{$MentionedUserIDs} ) {

        # AddMention also triggers event UserMention which sends a notification to the user.
        my $Success = $MentionObject->AddMention(
            TicketID        => $Param{Data}->{TicketID},
            ArticleID       => $Param{Data}->{ArticleID},
            MentionedUserID => $MentionedUserID,
            UserID          => $Param{UserID},
        );
        next MENTIONEDUSERID if $Success;

        $LogObject->Log(
            Priority => 'error',
            Message  => "Error adding mention for user ID $Param{UserID} to ticket with ID $Param{Data}->{TicketID}.",
        );
    }

    return 1;
}

1;
