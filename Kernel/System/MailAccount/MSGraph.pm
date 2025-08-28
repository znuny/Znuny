# --
# Copyright (C) 2021 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --
package Kernel::System::MailAccount::MSGraph;

use strict;
use warnings;

use utf8;

use Kernel::System::VariableCheck qw(:all);

use parent qw(Kernel::System::MailAccount::Base);

use Kernel::System::PostMaster;

our @ObjectDependencies = (
    'Kernel::Config',
    'Kernel::System::CommunicationLog',
    'Kernel::System::Encode',
    'Kernel::System::JSON',
    'Kernel::System::Log',
    'Kernel::System::MSGraph',
    'Kernel::System::Main',
    'Kernel::System::OAuth2Token',
    'Kernel::System::PostMaster',
);

sub new {
    my ( $Type, %Param ) = @_;

    my $Self = {%Param};
    bless( $Self, $Type );

    $Self->{MailAccountModuleName} = ref $Self;

    return $Self;
}

sub Connect {
    my ( $Self, %Param ) = @_;

    # There's no connect for Graph, so just return success.
    return (
        Successful => 1,
        Type       => ref $Self,
    );
}

sub Fetch {
    my ( $Self, %Param ) = @_;

    my $CommunicationLogObject = $Kernel::OM->Create(
        'Kernel::System::CommunicationLog',
        ObjectParams => {
            Transport   => 'Email',
            Direction   => 'Incoming',
            AccountType => $Param{Type},
            AccountID   => $Param{ID},
        },
    );

    my $CommunicationLogStatus = 'Successful';

    RUN:
    for my $Run ( 1 .. 200 ) {
        $CommunicationLogObject->ObjectLogStart(
            ObjectLogType => 'Connection',
        );

        my $FetchMessagesOK = $Self->_FetchMessages(
            %Param,
            CommunicationLogObject => $CommunicationLogObject,
        );
        if ($FetchMessagesOK) {
            $CommunicationLogObject->ObjectLogStop(
                ObjectLogType => 'Connection',
                Status        => 'Successful',
            );
        }
        else {
            $CommunicationLogStatus = 'Failed';

            $CommunicationLogObject->ObjectLogStop(
                ObjectLogType => 'Connection',
                Status        => 'Failed',
            );
        }

        last RUN if !$Self->{Rerun};
    }

    $CommunicationLogObject->CommunicationStop(
        Status => $CommunicationLogStatus,
    );

    return 1;
}

sub _FetchMessages {
    my ( $Self, %Param ) = @_;

    my $ConfigObject           = $Kernel::OM->Get('Kernel::Config');
    my $EncodeObject           = $Kernel::OM->Get('Kernel::System::Encode');
    my $LogObject              = $Kernel::OM->Get('Kernel::System::Log');
    my $CommunicationLogObject = $Param{CommunicationLogObject};
    my $JSONObject             = $Kernel::OM->Get('Kernel::System::JSON');
    my $OAuth2TokenObject      = $Kernel::OM->Get('Kernel::System::OAuth2Token');

    NEEDED:
    for my $Needed (qw(Login Password Host Trusted QueueID)) {
        next NEEDED if defined $Param{$Needed};

        $LogObject->Log(
            Priority => 'error',
            Message  => "Parameter $Needed is needed.",
        );

        return;
    }

    $Self->{Rerun} = 0;

    my $AuthenticationType = $Param{AuthenticationType} // '';

    if ( $Param{AuthenticationType} ne 'oauth2_token' ) {
        $CommunicationLogObject->ObjectLog(
            ObjectLogType => 'Connection',
            Priority      => 'Error',
            Key           => ref $Self,
            Value         => "AuthenticationType must be 'oauth2_token'.",
        );

        return;
    }

    if ( !defined $Param{OAuth2TokenConfigID} ) {
        $CommunicationLogObject->ObjectLog(
            ObjectLogType => 'Connection',
            Priority      => 'Error',
            Key           => ref $Self,
            Value         => 'OAuth2TokenConfigID is missing.',
        );

        return;
    }

    my $OAuth2Token = $OAuth2TokenObject->GetToken(
        TokenConfigID => $Param{OAuth2TokenConfigID},
        UserID        => 1,
    );
    if ( !$OAuth2Token ) {
        $CommunicationLogObject->ObjectLog(
            ObjectLogType => 'Connection',
            Priority      => 'Error',
            Key           => ref $Self,
            Value         => "OAuth2 token with ID $Param{OAuth2TokenConfigID} could not be retrieved.",
        );

        return;
    }

    my $CMD   = $Param{CMD};
    my $Debug = $Param{Debug};
    my $Limit = $Param{Limit} // 5000;

    my $Folder   = IsStringWithData( $Param{IMAPFolder} ) ? $Param{IMAPFolder} : 'INBOX';
    my $FolderID = $Self->_GetFolderID(
        %Param,
        CommunicationLogObject => $CommunicationLogObject,
        OAuth2Token            => $OAuth2Token,
        Folder                 => $Folder,
    );

    if ( !$FolderID ) {
        my $AllFoldersByID = $Self->_ListAllFolderNamesByID(
            %Param,
            CommunicationLogObject => $CommunicationLogObject,
            OAuth2Token            => $OAuth2Token,
        ) // {};

        my @AllFolderNamesSorted = sort values %{$AllFoldersByID};
        my $AllFolderNamesSorted = join ', ', @AllFolderNamesSorted;

        $CommunicationLogObject->ObjectLog(
            ObjectLogType => 'Connection',
            Priority      => 'Error',
            Key           => ref $Self,
            Value         => "No folder ID found for folder $Folder. Available folders: $AllFolderNamesSorted.",
        );

        return;
    }

    $CommunicationLogObject->ObjectLog(
        ObjectLogType => 'Connection',
        Priority      => 'Debug',
        Key           => ref $Self,
        Value         => "Fetching messages from '$Param{Host}' ($Param{Login}).",
    );

    my $Messages = $Self->_ListMessages(
        %Param,
        CommunicationLogObject => $CommunicationLogObject,
        OAuth2Token            => $OAuth2Token,
        FolderID               => $FolderID,
        OnlyUnread             => 0,
        Limit                  => $Limit,
    );

    # No array: error
    return if ref $Messages ne 'ARRAY';

    my $NumberOfMessages = scalar @{$Messages};

    if ($CMD) {
        print "$Self->{MailAccountModuleName}: I found $NumberOfMessages messages on $Param{Login}/$Param{Host}.\n";
    }

    # No elements in aray: No mails, OK.
    return 1 if !IsArrayRefWithData($Messages);

    my $MaxEmailSize             = $ConfigObject->Get('PostMasterMaxEmailSize')     || 1024 * 6;
    my $PostmasterReconnectLimit = $ConfigObject->Get('PostMasterReconnectMessage') || 20;
    my $MessageCounter           = 0;

    my $MessagesWithError = 0;
    MESSAGE:
    for my $Message ( @{$Messages} ) {
        $MessageCounter++;

        my $FetchDelay = ( $MessageCounter % 20 == 0 ? 1 : 0 );
        if ( $MessageCounter && $FetchDelay && $CMD ) {
            print
                "$Self->{MailAccountModuleName}: Safety protection: waiting 1 second before processing next mail...\n";

            sleep 1;
        }

        # This is only still in here on request for using setting PostMasterReconnectMessage as a way to temporarily
        # limit the number of fetched messages.
        if ( $MessageCounter > $PostmasterReconnectLimit ) {
            $Self->{Rerun} = 1;

            if ($CMD) {
                print
                    "$Self->{MailAccountModuleName}: Reconnecting session after $PostmasterReconnectLimit messages...\n";
            }

            last MESSAGE;
        }

        if ($CMD) {
            print
                "$Self->{MailAccountModuleName}: Message $MessageCounter/$NumberOfMessages ($Param{Login}/$Param{Host})\n";
        }

        my $MIMEMessage = $Self->_GetMessage(
            %Param,
            CommunicationLogObject => $CommunicationLogObject,
            OAuth2Token            => $OAuth2Token,
            MessageID              => $Message->{id},
        );

        $CommunicationLogObject->ObjectLogStart(
            ObjectLogType => 'Message',
        );

        my $MessageSize = int( ( length $MIMEMessage ) / 1024 );
        if ( $MessageSize > $MaxEmailSize ) {
            my $ErrorMessage
                = "$Self->{MailAccountModuleName}: Can't fetch message with ID $Message->{id} from $Param{Login}/$Param{Host}. "
                . "Email too big ($MessageSize KB - max $MaxEmailSize KB)!";

            $CommunicationLogObject->ObjectLog(
                ObjectLogType => 'Message',
                Priority      => 'Error',
                Key           => ref $Self,
                Value         => $ErrorMessage,
            );

            $CommunicationLogObject->ObjectLogStop(
                ObjectLogType => 'Message',
                Status        => 'Failed',
            );

            $MessagesWithError++;

            next MESSAGE;
        }

        $CommunicationLogObject->ObjectLog(
            ObjectLogType => 'Connection',
            Priority      => 'Debug',
            Key           => ref $Self,
            Value         => "Message with ID $Message->{id} successfully received.",
        );

        # If this is not being done, MIME::Parser::parse_data will complain with an error
        # 'unable to open in-memory file handle'.
        $EncodeObject->EncodeOutput( \$MIMEMessage );

        my $PostMasterObject = $Kernel::OM->Create(
            'Kernel::System::PostMaster',
            ObjectParams => {
                Email                  => \$MIMEMessage,
                Trusted                => $Param{Trusted},
                Debug                  => $Debug,
                CommunicationLogObject => $CommunicationLogObject,
            },
        );

        my @Return = eval {
            return $PostMasterObject->Run( QueueID => $Param{QueueID} || 0 );
        };
        my $Exception = $@;

        my $MessageStatus = 'Successful';

        if ( !$Return[0] ) {
            $MessagesWithError++;

            if ($Exception) {
                $LogObject->Log(
                    Priority => 'error',
                    Message  => 'Exception while processing mail: ' . $Exception,
                );
            }

            my $File = $Self->_SpoolFailedMessage(
                Email => $MIMEMessage,
            );

            my $ErrorMessage = "$Self->{MailAccountModuleName}: Can't process message, see log sub system ("
                . "$File, report it on https://github.com/znuny/Znuny/issues)!";

            $CommunicationLogObject->ObjectLog(
                ObjectLogType => 'Message',
                Priority      => 'Error',
                Key           => ref $Self,
                Value         => $ErrorMessage,
            );

            $MessageStatus = 'Failed';
        }

        # Delete message
        my $MessageDeleted = $Self->_DeleteMessage(
            %Param,
            CommunicationLogObject => $CommunicationLogObject,
            OAuth2Token            => $OAuth2Token,
            MessageID              => $Message->{id},
        );
        if ( !$MessageDeleted ) {
            $CommunicationLogObject->ObjectLog(
                ObjectLogType => 'Message',
                Priority      => 'Error',
                Key           => ref $Self,
                Value         => "Message with ID $Message->{id} could not be deleted from $Param{Login}/$Param{Host}.",
            );

            $MessageStatus = 'Failed';
        }

        undef $PostMasterObject;

        $CommunicationLogObject->ObjectLogStop(
            ObjectLogType => 'Message',
            Status        => $MessageStatus,
        );
    }

    if ( $Debug || $MessageCounter ) {
        $CommunicationLogObject->ObjectLog(
            ObjectLogType => 'Connection',
            Priority      => 'Debug',
            Key           => ref $Self,
            Value =>
                "$Self->{MailAccountModuleName}: Fetched $MessageCounter messages from $Param{Login}/$Param{Host}.",
        );
    }

    return if $MessagesWithError;

    return 1;
}

=head1 _ListMessages()

Gets info about all messages available, sorted by date/time received (oldest first).

    my $Messages = $MSGraphObject->_ListMessages(
        CommunicationLogObject => $CommunicationLogObject,
        Login                  => 'someone@example.org',
        OAuth2Token            => '...',
        Host                   => 'graph.microsoft.com',
        FolderID               => '...', # optional
        Limit                  => 1000, # optional, limit of number of listed messages
        OnlyUnread             => 1, # optional, defaults to 0
        Timeout                => 60, # optional, timeout for request
        SkipSSLVerification    => 0, # optional
);

    my $Messages = {
        {
            'id'               => 'AAMkADVjNGE3ZmFiLTI0NDQtNGYxNi04MDE5LTVlMWE5OTI4N2NhNQBGAAAAAABqsFDtBjxeTZxyLO6ibCUwBwC9tuupNeC7RbgCe6mWxgY4AAAAAAEJAAC9tuupNeC7RbgCe6mWxgY4AAAIvCcqAAA=',
            'receivedDateTime' => '2024-09-20T17:21:13Z',
            'isRead'           => 1,
            'subject'          => '[Ticket#20240920450000012] Locked Ticket Follow-Up: Test 1 - Addon',
            '@odata.etag'      => 'W/"CQAAABYAAAC9tuupNeC7RbgCe6mWxgY4AAAIuNtN"'
        },
        # ...
    };

=cut

sub _ListMessages {
    my ( $Self, %Param ) = @_;

    my $LogObject     = $Kernel::OM->Get('Kernel::System::Log');
    my $JSONObject    = $Kernel::OM->Get('Kernel::System::JSON');
    my $MSGraphObject = $Kernel::OM->Get('Kernel::System::MSGraph');

    NEEDED:
    for my $Needed (qw(CommunicationLogObject Login OAuth2Token Host)) {
        next NEEDED if defined $Param{$Needed};

        $LogObject->Log(
            Priority => 'error',
            Message  => "Parameter '$Needed' is needed!",
        );
        return;
    }

    my $Limit = $Param{Limit} // 100;

    my @Messages;

    my $FolderURL = IsStringWithData( $Param{FolderID} )
        ? "/mailFolders/$Param{FolderID}"
        : '';

    my $Operation = $FolderURL
        . '/messages?$select=id,subject,receivedDateTime,isRead&$top=50';

    my $NextLink;

    my $Done;
    while ( !$Done ) {
        my $DecodedContent = $MSGraphObject->ExecuteOperation(
            %Param,
            RequestType => 'GET',
            Operation   => $Operation,
            NextLink    => $NextLink,
        );

        return if !IsHashRefWithData($DecodedContent);

        my @FetchedMessages = @{ $DecodedContent->{value} // [] };

        if ( $Param{OnlyUnread} ) {
            @FetchedMessages = grep { !$_->{isRead} } @FetchedMessages;
        }

        push @Messages, @FetchedMessages;

        # Max. number of emails fetched.
        if ( @Messages > $Limit ) {
            splice @Messages, $Limit;

            $Done = 1;

            # There are more mails to fetch: Trigger rerun.
            $Self->{Rerun} = 1;
        }

        # No more emails to fetch.
        $NextLink = $DecodedContent->{'@odata.nextLink'};

        $Done = 1 if !$NextLink;
    }

    # Sort messages by received date/time, oldest first.
    @Messages = reverse sort { $a->{receivedDateTime} cmp $a->{receivedDateTime} } @Messages;

    return \@Messages;
}

=head1 _GetMessage

Fetches message (as MIME) with given ID.

    my $MIMEMessage = $MSGraphObject->_GetMessage(
        CommunicationLogObject => $CommunicationLogObject,
        Login                  => 'someone@example.org',
        OAuth2Token            => '...',
        Host                   => 'graph.microsoft.com',
        MessageID              => '...',
        Timeout                => 60, # optional, timeout for request
        Proxy                  => '...', # optional, default: Config WebUserAgent::Proxy
        NoProxy                => '', # optional, default: Config WebUserAgent::NoProxy
        SkipSSLVerification    => 0, # optional
    );

    Returns MIME message.

=cut

sub _GetMessage {
    my ( $Self, %Param ) = @_;

    my $LogObject     = $Kernel::OM->Get('Kernel::System::Log');
    my $JSONObject    = $Kernel::OM->Get('Kernel::System::JSON');
    my $MSGraphObject = $Kernel::OM->Get('Kernel::System::MSGraph');

    NEEDED:
    for my $Needed (qw(CommunicationLogObject Login OAuth2Token Host MessageID)) {
        next NEEDED if defined $Param{$Needed};

        $LogObject->Log(
            Priority => 'error',
            Message  => "Parameter '$Needed' is needed!",
        );
        return;
    }

    my $Operation = '/messages/'
        . $Param{MessageID}
        . '/$value';    # flag to retríeve MIME content

    my $MIMEMessage = $MSGraphObject->ExecuteOperation(
        %Param,
        RequestType               => 'GET',
        Operation                 => $Operation,
        JSONDecodeResponseContent => 0,
    );

    return $MIMEMessage;
}

=head1 _DeleteMessage

Deletes the message with given ID.

    my $Deleted = $MSGraphObject->_DeleteMessage(
        CommunicationLogObject => $CommunicationLogObject,
        Login                  => 'someone@example.org',
        OAuth2Token            => '...',
        Host                   => 'graph.microsoft.com',
        MessageID              => '...',
        Timeout                => 60, # optional, timeout for request
        Proxy                  => '...', # optional, default: Config WebUserAgent::Proxy
        NoProxy                => '', # optional, default: Config WebUserAgent::NoProxy
        SkipSSLVerification    => 0, # optional
    );

    Returns true value on success.

=cut

sub _DeleteMessage {
    my ( $Self, %Param ) = @_;

    my $LogObject     = $Kernel::OM->Get('Kernel::System::Log');
    my $JSONObject    = $Kernel::OM->Get('Kernel::System::JSON');
    my $MSGraphObject = $Kernel::OM->Get('Kernel::System::MSGraph');

    NEEDED:
    for my $Needed (qw(CommunicationLogObject Login OAuth2Token Host MessageID)) {
        next NEEDED if defined $Param{$Needed};

        $LogObject->Log(
            Priority => 'error',
            Message  => "Parameter '$Needed' is needed!",
        );
        return;
    }

    my $Operation = '/messages/'
        . $Param{MessageID};

    my $Deleted = $MSGraphObject->ExecuteOperation(
        %Param,
        RequestType => 'DELETE',
        Operation   => $Operation,
    );

    return $Deleted;
}

=head1 _GetFolderID

Fetches folder ID for given folder.

    my $FolderID = $MSGraphObject->_GetFolderID(
        CommunicationLogObject => $CommunicationLogObject,
        Login                  => 'someone@example.org',
        OAuth2Token            => '...',
        Host                   => 'graph.microsoft.com',
        Folder                 => 'INBOX.Support.2nd Level', # Also '/' possible as separator
        Timeout                => 60, # optional, timeout for request
        Proxy                  => '...', # optional, default: Config WebUserAgent::Proxy
        NoProxy                => '', # optional, default: Config WebUserAgent::NoProxy
        SkipSSLVerification    => 0, # optional
    );

    Returns ID of folder.

=cut

sub _GetFolderID {
    my ( $Self, %Param ) = @_;

    my $LogObject = $Kernel::OM->Get('Kernel::System::Log');

    NEEDED:
    for my $Needed (qw(CommunicationLogObject Login OAuth2Token Host Folder)) {
        next NEEDED if defined $Param{$Needed};

        $LogObject->Log(
            Priority => 'error',
            Message  => "Parameter '$Needed' is needed!",
        );
        return;
    }

    my $FolderID;

    my @FolderParts = split /\.|\//, $Param{Folder};
    while ( my $FolderPart = shift @FolderParts ) {
        my $Folders = $Self->_ListFolders(
            %Param,
            ParentFolderID => $FolderID,
        );

        ( my $Folder ) = grep { lc $FolderPart eq lc $_->{displayName} } @{$Folders};

        if ( !IsHashRefWithData($Folder) ) {
            $Param{CommunicationLogObject}->ObjectLog(
                ObjectLogType => 'Connection',
                Priority      => 'Error',
                Key           => ref $Self,
                Value         => "Folder '$FolderPart' of configured folder '$Param{Folder}' not found.",
            );

            return;
        }

        $FolderID = $Folder->{id};

        $Param{CommunicationLogObject}->ObjectLog(
            ObjectLogType => 'Connection',
            Priority      => 'Debug',
            Key           => ref $Self,
            Value         => "Folder '$FolderPart' of configured folder '$Param{Folder}' found (ID $FolderID).",
        );
    }

    return $FolderID;
}

=head1 _ListFolders

Lists folders of root level or of parent folder with given ID.

    my $Folders = $MSGraphObject->_ListFolders(
        CommunicationLogObject => $CommunicationLogObject,
        Login                  => 'someone@example.org',
        OAuth2Token            => '...',
        Host                   => 'graph.microsoft.com',
        ParentFolderID         => '...', # optional; if given, lists child folders of parent folder with given ID
        Timeout                => 60, # optional, timeout for request
        Proxy                  => '...', # optional, default: Config WebUserAgent::Proxy
        NoProxy                => '', # optional, default: Config WebUserAgent::NoProxy
        SkipSSLVerification    => 0, # optional
    );

    Returns folders of root level.

=cut

sub _ListFolders {
    my ( $Self, %Param ) = @_;

    my $LogObject     = $Kernel::OM->Get('Kernel::System::Log');
    my $JSONObject    = $Kernel::OM->Get('Kernel::System::JSON');
    my $MSGraphObject = $Kernel::OM->Get('Kernel::System::MSGraph');

    NEEDED:
    for my $Needed (qw(CommunicationLogObject Login OAuth2Token Host)) {
        next NEEDED if defined $Param{$Needed};

        $LogObject->Log(
            Priority => 'error',
            Message  => "Parameter '$Needed' is needed!",
        );
        return;
    }

    my $Operation = '/mailFolders?includeHiddenFolders=true';
    if ( $Param{ParentFolderID} ) {
        $Operation = "/mailFolders/$Param{ParentFolderID}/childFolders?includeHiddenFolders=true";
    }

    my @Folders;

    my $NextLink;
    my $Done;
    while ( !$Done ) {
        my $DecodedContent = $MSGraphObject->ExecuteOperation(
            %Param,
            RequestType => 'GET',
            Operation   => $Operation,
            NextLink    => $NextLink,
        );

        return if !IsHashRefWithData($DecodedContent);

        push @Folders, @{ $DecodedContent->{value} // [] };

        # No more folders to fetch.
        $NextLink = $DecodedContent->{'@odata.nextLink'};

        $Done = 1 if !$NextLink;
    }

    if ( !@Folders ) {
        $Param{CommunicationLogObject}->ObjectLog(
            ObjectLogType => 'Connection',
            Priority      => 'Debug',
            Key           => ref $Self,
            Value         => 'No folders found.',
        );
    }

    return \@Folders;
}

sub _ListAllFolderNamesByID {
    my ( $Self, %Param ) = @_;

    my $Folders = $Self->_ListFolders(
        %Param,
        ParentFolderID => $Param{ParentFolderID},    # undef: Root level
    );

    my %FolderNamesByID;

    for my $Folder ( @{$Folders} ) {
        my $FolderName = $Folder->{displayName};
        if ( $Param{ParentFolderName} ) {
            $FolderName = $Param{ParentFolderName} . '.' . $FolderName;
        }
        $FolderNamesByID{ $Folder->{id} } = $FolderName;

        my $ChildFolderNamesByID = $Self->_ListAllFolderNamesByID(
            %Param,
            ParentFolderID   => $Folder->{id},
            ParentFolderName => $FolderName,
        );
        if ( IsHashRefWithData($ChildFolderNamesByID) ) {
            %FolderNamesByID = ( %FolderNamesByID, %{$ChildFolderNamesByID} );
        }
    }

    return \%FolderNamesByID;
}

sub _SpoolFailedMessage {
    my ( $Self, %Param ) = @_;

    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');
    my $LogObject    = $Kernel::OM->Get('Kernel::System::Log');
    my $MainObject   = $Kernel::OM->Get('Kernel::System::Main');

    NEEDED:
    for my $Needed (qw(MIMEMessage)) {
        next NEEDED if defined $Param{$Needed};

        $LogObject->Log(
            Priority => 'error',
            Message  => "Parameter '$Needed' is needed!",
        );
        return;
    }

    my $SpoolPath = $ConfigObject->Get('Home') . '/var/spool/';
    my $MD5       = $MainObject->MD5sum(
        String => \$Param{MIMEMessage},
    );
    my $Location = $SpoolPath . 'problem-email-' . $MD5;

    return $MainObject->FileWrite(
        Location   => $Location,
        Content    => \$Param{MIMEMessage},
        Mode       => 'binmode',
        Type       => 'Local',
        Permission => '640',
    );
}

1;
