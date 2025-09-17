# --
# Copyright (C) 2001-2021 OTRS AG, https://otrs.com/
# Copyright (C) 2021 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see https://www.gnu.org/licenses/gpl-3.0.txt.
# --

package Kernel::System::NotificationEvent;

use strict;
use warnings;

use Kernel::Language qw(Translatable);
use Kernel::System::VariableCheck qw(:all);

our @ObjectDependencies = (
    'Kernel::System::DB',
    'Kernel::System::Log',
    'Kernel::System::Valid',
    'Kernel::System::YAML',
    'Kernel::System::Cache',
    'Kernel::Language',
);

=head1 NAME

Kernel::System::NotificationEvent - to manage the notifications

=head1 DESCRIPTION

All functions to manage the notification and the notification jobs.

=head1 PUBLIC INTERFACE

=head2 new()

Don't use the constructor directly, use the ObjectManager instead:

    my $NotificationEventObject = $Kernel::OM->Get('Kernel::System::NotificationEvent');

=cut

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {};
    bless( $Self, $Type );

    $Self->{CacheType} = 'NotificationEvent';
    $Self->{CacheTTL}  = 60 * 60 * 24 * 20;
    return $Self;
}

=head2 NotificationList()

returns a hash of all notifications

    my %List = $NotificationEventObject->NotificationList(
        Type    => 'Ticket', # type of notifications; default: 'Ticket'
        Details => 1,        # include notification detailed data. possible (0|1) # ; default: 0
        All     => 1,        # optional: if given all notification types will be returned, even if type is given (possible: 0|1)
    );

=cut

sub NotificationList {
    my ( $Self, %Param ) = @_;

    $Param{Type} ||= 'Ticket';
    $Param{Details} = $Param{Details} ? 1 : 0;
    $Param{All}     = $Param{All}     ? 1 : 0;

    my $CacheObject = $Kernel::OM->Get('Kernel::System::Cache');

    my $CacheKey    = $Self->{CacheType} . '::' . $Param{Type} . '::' . $Param{Details} . '::' . $Param{All};
    my $CacheResult = $CacheObject->Get(
        Type => $Self->{CacheType},
        Key  => $CacheKey,
    );

    if ( ref $CacheResult eq 'HASH' ) {
        return %{$CacheResult};
    }

    # get database object
    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    $DBObject->Prepare( SQL => 'SELECT id FROM notification_event' );

    my @NotificationList;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        push @NotificationList, $Row[0];
    }

    my %Result;

    ITEMID:
    for my $ItemID ( sort @NotificationList ) {

        my %NotificationData = $Self->NotificationGet(
            ID     => $ItemID,
            UserID => 1,
        );

        $NotificationData{Data}->{NotificationType} ||= ['Ticket'];

        if ( !$Param{All} ) {
            next ITEMID if $NotificationData{Data}->{NotificationType}->[0] ne $Param{Type};
        }

        if ( $Param{Details} ) {
            $Result{$ItemID} = \%NotificationData;
        }
        else {
            $Result{$ItemID} = $NotificationData{Name};
        }
    }

    $CacheObject->Set(
        Type  => $Self->{CacheType},
        Key   => $CacheKey,
        Value => \%Result,
        TTL   => $Self->{CacheTTL},
    );

    return %Result;
}

=head2 NotificationGet()

returns a hash of the notification data

    my %Notification = $NotificationEventObject->NotificationGet(
        Name => 'NotificationName',
    );

    my %Notification = $NotificationEventObject->NotificationGet(
        ID => 1,
    );

Returns:

    %Notification = (
        ID      => 123,
        Name    => 'Agent::Move',
        Data => {
            Events => [ 'TicketQueueUpdate' ],
            # ...
            Queue => [ 'SomeQueue' ],
        },
        Message => {
            en => {
                Subject     => 'Hello',
                Body        => 'Hello World',
                ContentType => 'text/plain',
            },
            de => {
                Subject     => 'Hallo',
                Body        => 'Hallo Welt',
                ContentType => 'text/plain',
            },
        },
        Comment    => 'An optional comment',
        ValidID    => 1,
        CreateTime => '2010-10-27 20:15:00',
        CreateBy   => 2,
        ChangeTime => '2010-10-27 20:15:00',
        ChangeBy   => 1,
        UserID     => 3,
    );

=cut

sub NotificationGet {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    if ( !$Param{Name} && !$Param{ID} ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => 'Need Name or ID!',
        );
        return;
    }

    # get database object
    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    # general query structure
    my $SQL = '
        SELECT id, name, valid_id, comments, create_time, create_by, change_time, change_by
        FROM notification_event
        WHERE ';

    if ( $Param{Name} ) {

        $DBObject->Prepare(
            SQL  => $SQL . 'name = ?',
            Bind => [ \$Param{Name} ],
        );
    }
    else {
        $DBObject->Prepare(
            SQL  => $SQL . 'id = ?',
            Bind => [ \$Param{ID} ],
        );
    }

    # get notification event data
    my %Data;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        $Data{ID}         = $Row[0];
        $Data{Name}       = $Row[1];
        $Data{ValidID}    = $Row[2];
        $Data{Comment}    = $Row[3];
        $Data{CreateTime} = $Row[4];
        $Data{CreateBy}   = $Row[5];
        $Data{ChangeTime} = $Row[6];
        $Data{ChangeBy}   = $Row[7];
    }

    return if !%Data;

    # get notification event item data
    $DBObject->Prepare(
        SQL => '
            SELECT event_key, event_value
            FROM notification_event_item
            WHERE notification_id = ?
            ORDER BY event_key, event_value ASC',
        Bind => [ \$Data{ID} ],
    );

    while ( my @Row = $DBObject->FetchrowArray() ) {
        push @{ $Data{Data}->{ $Row[0] } }, $Row[1];
    }

    # get notification event message data
    $DBObject->Prepare(
        SQL => '
            SELECT subject, text, content_type, language
            FROM notification_event_message
            WHERE notification_id = ?',
        Bind => [ \$Data{ID} ],
    );

    while ( my @Row = $DBObject->FetchrowArray() ) {

        # add to message hash with the language as key
        $Data{Message}->{ $Row[3] } = {
            Subject     => $Row[0],
            Body        => $Row[1],
            ContentType => $Row[2],
        };
    }

    return %Data;
}

=head2 NotificationAdd()

adds a new notification to the database

    my $ID = $NotificationEventObject->NotificationAdd(
        Name => 'Agent::OwnerUpdate',
        Data => {
            Events => [ 'TicketQueueUpdate' ],
            # ...
            Queue => [ 'SomeQueue' ],
        },
        Message => {
            en => {
                Subject     => 'Hello',
                Body        => 'Hello World',
                ContentType => 'text/plain',
            },
            de => {
                Subject     => 'Hallo',
                Body        => 'Hallo Welt',
                ContentType => 'text/plain',
            },
        },
        Comment => 'An optional comment', # (optional)
        ValidID => 1,
        UserID  => 123,
    );

=cut

sub NotificationAdd {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Argument (qw(Name Data Message ValidID UserID)) {
        if ( !$Param{$Argument} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Argument!",
            );
            return;
        }
    }

    # check if job name already exists
    my %Check = $Self->NotificationGet(
        Name => $Param{Name},
    );
    if (%Check) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => "A notification with the name '$Param{Name}' already exists.",
        );
        return;
    }

    # check message parameter
    if ( !IsHashRefWithData( $Param{Message} ) ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => "Need Message!",
        );
        return;
    }

    # check each argument for each message language
    for my $Language ( sort keys %{ $Param{Message} } ) {

        for my $Argument (qw(Subject Body ContentType)) {

            # error if message data is incomplete
            if ( !$Param{Message}->{$Language}->{$Argument} ) {
                $Kernel::OM->Get('Kernel::System::Log')->Log(
                    Priority => 'error',
                    Message  => "Need Message argument '$Argument' for language '$Language'!",
                );
                return;
            }

            # fix some bad stuff from some browsers (Opera)!
            $Param{Message}->{$Language}->{Body} =~ s/(\n\r|\r\r\n|\r\n|\r)/\n/g;
        }
    }

    # get database object
    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    # insert data into db
    return if !$DBObject->Do(
        SQL => '
            INSERT INTO notification_event
                (name, valid_id, comments, create_time, create_by, change_time, change_by)
            VALUES (?, ?, ?, current_timestamp, ?, current_timestamp, ?)',
        Bind => [
            \$Param{Name}, \$Param{ValidID}, \$Param{Comment},
            \$Param{UserID}, \$Param{UserID},
        ],
    );

    # get id
    $DBObject->Prepare(
        SQL  => 'SELECT id FROM notification_event WHERE name = ?',
        Bind => [ \$Param{Name} ],
    );

    my $ID;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        $ID = $Row[0];
    }

    # error handling
    if ( !$ID ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => "Could not get ID for just added notification '$Param{Name}'!",
        );
        return;
    }

    # insert notification event item data
    for my $Key ( sort keys %{ $Param{Data} } ) {

        ITEM:
        for my $Item ( @{ $Param{Data}->{$Key} } ) {

            next ITEM if !defined $Item;
            next ITEM if $Item eq '';

            return if !$DBObject->Do(
                SQL => '
                    INSERT INTO notification_event_item
                        (notification_id, event_key, event_value)
                    VALUES (?, ?, ?)',
                Bind => [ \$ID, \$Key, \$Item ],
            );
        }
    }

    # insert notification event message data
    for my $Language ( sort keys %{ $Param{Message} } ) {

        my %Message = %{ $Param{Message}->{$Language} };

        return if !$DBObject->Do(
            SQL => '
                INSERT INTO notification_event_message
                    (notification_id, subject, text, content_type, language)
                VALUES (?, ?, ?, ?, ?)',
            Bind => [
                \$ID,
                \$Message{Subject},
                \$Message{Body},
                \$Message{ContentType},
                \$Language,
            ],
        );
    }

    $Kernel::OM->Get('Kernel::System::Cache')->CleanUp(
        Type => $Self->{CacheType},
    );

    return $ID;
}

=head2 NotificationUpdate()

update a notification in database

    my $Ok = $NotificationEventObject->NotificationUpdate(
        ID      => 123,
        Name    => 'Agent::OwnerUpdate',
        Data => {
            Events => [ 'TicketQueueUpdate' ],
            # ...
            Queue => [ 'SomeQueue' ],
        },
        Message => {
            en => {
                Subject     => 'Hello',
                Body        => 'Hello World',
                ContentType => 'text/plain',
            },
            de => {
                Subject     => 'Hallo',
                Body        => 'Hallo Welt',
                ContentType => 'text/plain',
            },
        },
        Comment => 'An optional comment',  # (optional)
        ValidID => 1,
        UserID  => 123,
    );

=cut

sub NotificationUpdate {
    my ( $Self, %Param ) = @_;

    # Check needed stuff.
    for my $Argument (qw(ID Name Data ValidID UserID)) {

        if ( !$Param{$Argument} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Argument!",
            );
            return;
        }
    }

    # Check message parameter.
    if (
        !$Param{PossibleEmptyMessage}
        && !IsHashRefWithData( $Param{Message} )
        )
    {

        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => "Need Message!",
        );
        return;
    }

    # Check each argument for each message language.
    for my $Language ( sort keys %{ $Param{Message} // {} } ) {

        for my $Argument (qw(Subject Body ContentType)) {

            # Error if message data is incomplete.
            if ( !$Param{Message}->{$Language}->{$Argument} ) {
                $Kernel::OM->Get('Kernel::System::Log')->Log(
                    Priority => 'error',
                    Message  => "Need Message argument '$Argument' for language '$Language'!",
                );
                return;
            }

            # Fix some bad stuff from some browsers (Opera)!
            $Param{Message}->{$Language}->{Body} =~ s/(\n\r|\r\r\n|\r\n|\r)/\n/g;
        }
    }

    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    # Update data in db/
    return if !$DBObject->Do(
        SQL => '
            UPDATE notification_event
            SET name = ?, valid_id = ?, comments = ?, change_time = current_timestamp, change_by = ?
            WHERE id = ?',
        Bind => [
            \$Param{Name},    \$Param{ValidID},
            \$Param{Comment}, \$Param{UserID},
            \$Param{ID},
        ],
    );

    # Delete existing notification event item data.
    $DBObject->Do(
        SQL  => 'DELETE FROM notification_event_item WHERE notification_id = ?',
        Bind => [ \$Param{ID} ],
    );

    # Add new notification event item data.
    for my $Key ( sort keys %{ $Param{Data} } ) {

        ITEM:
        for my $Item ( @{ $Param{Data}->{$Key} } ) {

            next ITEM if !defined $Item;
            next ITEM if $Item eq '';

            $DBObject->Do(
                SQL => '
                    INSERT INTO notification_event_item
                        (notification_id, event_key, event_value)
                    VALUES (?, ?, ?)',
                Bind => [
                    \$Param{ID},
                    \$Key,
                    \$Item,
                ],
            );
        }
    }

    # Delete existing notification event message data.
    $DBObject->Do(
        SQL  => 'DELETE FROM notification_event_message WHERE notification_id = ?',
        Bind => [ \$Param{ID} ],
    );

    # Insert new notification event message data.
    for my $Language ( sort keys %{ $Param{Message} // {} } ) {

        my %Message = %{ $Param{Message}->{$Language} };

        $DBObject->Do(
            SQL => '
                INSERT INTO notification_event_message
                    (notification_id, subject, text, content_type, language)
                VALUES (?, ?, ?, ?, ?)',
            Bind => [
                \$Param{ID},
                \$Message{Subject},
                \$Message{Body},
                \$Message{ContentType},
                \$Language,
            ],
        );
    }

    $Kernel::OM->Get('Kernel::System::Cache')->CleanUp(
        Type => $Self->{CacheType},
    );

    return 1;
}

=head2 NotificationDelete()

deletes an notification from the database

    $NotificationEventObject->NotificationDelete(
        ID     => 1,
        UserID => 123,
    );

=cut

sub NotificationDelete {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Argument (qw(ID UserID)) {
        if ( !$Param{$Argument} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Argument!",
            );
            return;
        }
    }

    # check if job name exists
    my %Check = $Self->NotificationGet(
        ID => $Param{ID},
    );
    if ( !%Check ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => "Can't delete notification with ID '$Param{ID}'. Notification does not exist!",
        );
        return;
    }

    # get database object
    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    # delete notification event item
    my $DeleteOK = $DBObject->Do(
        SQL  => 'DELETE FROM notification_event_item WHERE notification_id = ?',
        Bind => [ \$Param{ID} ],
    );

    # error handling
    if ( !$DeleteOK ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => "Can't delete notification_event_item with ID '$Param{ID}'!",
        );
        return;
    }

    # delete notification event message
    $DeleteOK = $DBObject->Do(
        SQL  => 'DELETE FROM notification_event_message WHERE notification_id = ?',
        Bind => [ \$Param{ID} ],
    );

    # error handling
    if ( !$DeleteOK ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => "Can't delete notification_event_message with ID '$Param{ID}'!",
        );
        return;
    }

    # delete notification event
    $DeleteOK = $DBObject->Do(
        SQL  => 'DELETE FROM notification_event WHERE id = ?',
        Bind => [ \$Param{ID} ],
    );

    # error handling
    if ( !$DeleteOK ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => "Can't delete notification_event with ID '$Param{ID}'!",
        );
        return;
    }

    $Kernel::OM->Get('Kernel::System::Cache')->CleanUp(
        Type => $Self->{CacheType},
    );

    # success
    $Kernel::OM->Get('Kernel::System::Log')->Log(
        Priority => 'notice',
        Message  => "NotificationEvent notification '$Check{Name}' deleted (UserID=$Param{UserID}).",
    );

    return 1;
}

=head2 NotificationEventCheck()

returns array of notification affected by event

    my @IDs = $NotificationEventObject->NotificationEventCheck(
        Event => 'ArticleCreate',
    );

=cut

sub NotificationEventCheck {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    if ( !$Param{Event} ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => 'Need Name!',
        );
        return;
    }

    # get needed objects
    my $DBObject    = $Kernel::OM->Get('Kernel::System::DB');
    my $ValidObject = $Kernel::OM->Get('Kernel::System::Valid');

    my @ValidIDs      = $ValidObject->ValidIDsGet();
    my $ValidIDString = join ', ', @ValidIDs;

    $DBObject->Prepare(
        SQL => "
            SELECT DISTINCT(nei.notification_id)
            FROM notification_event ne, notification_event_item nei
            WHERE ne.id = nei.notification_id
                AND ne.valid_id IN ( $ValidIDString )
                AND nei.event_key = 'Events'
                AND nei.event_value = ?
            ORDER BY nei.notification_id ASC",
        Bind => [ \$Param{Event} ],
    );

    my @IDs;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        push @IDs, $Row[0];
    }

    return @IDs;
}

=head2 NotificationExport()

export a notification

    my $ExportData = $NotificationEventObject->NotificationExport(
        # required either ID or ExportAll
        ID                       => $NotificationID,
        ExportAll                => 0,               # possible: 0, 1

        UserID                   => 1,               # required
        Type                     => 'Ticket',        # optional, default: 'Ticket'
        All                      => 1                # optional, default: undef
    }

returns Notification hashes in an array with data:

    my $ExportData =
    [
        {
            'ChangeTime' => '2024-02-06 14:49:56',
            'ValidID' => 1,
            'ID' => 16,
            'CreateBy' => 1,
            'Data' => {
                'Transports' => [
                    'Email'
                ],
                'LanguageID' => [
                    'en'
                ],
                'VisibleForAgent' => [
                    '1'
                ],
                'Events' => [
                    'UserMention'
                ],
                'ArticleAttachmentInclude' => [
                    '0'
                ],
                'AgentEnabledByDefault' => [
                    'Email'
                ],
                'TransportEmailTemplate' => [
                    'Default'
                ]
            },
            'Name' => 'Mention notification',
            'ChangeBy' => 1,
            'Comment' => '',
            'CreateTime' => '2024-02-06 14:49:56',
            'Message' => {
                'en' => {
                    'ContentType' => 'text/plain',
                    'Body' => 'Hi <OTRS_NOTIFICATION_RECIPIENT_UserFirstname>,

you have been mentioned in ticket <OTRS_TICKET_NUMBER>.
<OTRS_AGENT_BODY[5]>

<OTRS_CONFIG_HttpType>://<OTRS_CONFIG_FQDN>/<OTRS_CONFIG_ScriptAlias>index.pl?Action=AgentTicketZoom;TicketID=<OTRS_TICKET_TicketID>

-- <OTRS_CONFIG_NotificationSenderName>',
                    'Subject' => 'Mention in ticket: <OTRS_TICKET_Title>'
                },
                'de' => {
                    'ContentType' => 'text/plain',
                    'Body' => "Hallo <OTRS_NOTIFICATION_RECIPIENT_UserFirstname> <OTRS_NOTIFICATION_RECIPIENT_UserLastname>,

Sie wurden erw\x{e4}hnt in Ticket <OTRS_TICKET_NUMBER>.
<OTRS_AGENT_BODY[5]>

<OTRS_CONFIG_HttpType>://<OTRS_CONFIG_FQDN>/<OTRS_CONFIG_ScriptAlias>index.pl?Action=AgentTicketZoom;TicketID=<OTRS_TICKET_TicketID>

-- <OTRS_CONFIG_NotificationSenderName>",
                    'Subject' => "Erw\x{e4}hnung in Ticket: <OTRS_TICKET_Title>"
                }
            }
        }
    ]

=cut

sub NotificationExport {
    my ( $Self, %Param ) = @_;

    my $LogObject = $Kernel::OM->Get('Kernel::System::Log');

    my $NotificationData;

    if ( $Param{ExportAll} ) {
        my %NotificationList = $Self->NotificationList(
            Type => $Param{Type},
            All  => $Param{All},
        );

        my @Data;
        for my $ItemID ( sort keys %NotificationList ) {
            my %NotificationSingleData = $Self->NotificationExportDataGet(
                ID => $ItemID,
            );

            push @Data, \%NotificationSingleData if %NotificationSingleData;
        }
        $NotificationData = \@Data;
    }
    elsif ( $Param{ID} ) {
        my %NotificationSingleData = $Self->NotificationExportDataGet(
            ID => $Param{ID},
        );

        return if !%NotificationSingleData;

        $NotificationData = [ \%NotificationSingleData ];
    }
    else {
        $LogObject->Log(
            Priority => 'error',
            Message  => 'Need either "ExportAll" or "ID" parameter!',
        );
        return;
    }

    return $NotificationData;
}

=head2 NotificationImport()

import an Notification YAML file/content

    my $NotificationImport = $NotificationEventObject->NotificationImport(
        Content                        => $YAMLContent, # mandatory, YAML format
        OverwriteExistingNotifications => 0,            # optional, possible: 0, 1
        UserID                         => 1,            # mandatory
    );

Returns:

    $NotificationImport = {
        Success          => 1,                                  # 1 if success or undef if operation could not
                                                                # be performed
        Message          => 'The Message to show.',             # error message
        Added            => 'Notification1, Notification2',     # string list of Notifications correctly added
        Updated          => 'Notification3, Notification4',     # string list of Notifications correctly updated
        NotUpdated       => 'Notification5, Notification6',     # string of Notifications not updated due to existing entity
                                                                # with the same name
        Errors           => 'Notification5',                    # string list of Notifications that could not be added or updated
        AdditionalErrors => ['Some error occured!', 'Error2!'], # list of additional error not necessarily related to specified Notification

        # for compatibility with existing code
        AddedNotifications   => 'Notification1, Notification2',     # string list of Notifications correctly added
        UpdatedNotifications => 'Notification3, Notification4',     # string list of Notifications correctly updated
        NotificationErrors   => 'Notification5',                    # string list of Notifications that could not be added or updated
    };

=cut

sub NotificationImport {
    my ( $Self, %Param ) = @_;

    my $LogObject  = $Kernel::OM->Get('Kernel::System::Log');
    my $YAMLObject = $Kernel::OM->Get('Kernel::System::YAML');

    for my $Needed (qw(Content UserID)) {

        # check needed stuff
        if ( !$Param{$Needed} ) {
            $LogObject->Log(
                Priority => 'error',
                Message  => "Need $Needed!",
            );
            return {
                Success => 0,
                Message => "$Needed is missing can not continue.",
            };
        }
    }

    my $NotificationData = $YAMLObject->Load(
        Data => $Param{Content},
    );

    if ( ref $NotificationData ne 'ARRAY' ) {
        return {
            Success => 0,
            Message =>
                Translatable("Couldn't read Notification configuration file. Please make sure the file is valid."),
        };
    }

    # Check notification message length for every language.
    for my $Language ( sort keys %{ $NotificationData->[0]->{Message} } ) {
        my $Check = $Self->NotificationBodyCheck(
            Content => $NotificationData->[0]->{Message}->{$Language}->{Body},
            UserID  => $Param{UserID},
        );

        if ( !$Check ) {
            return {
                Success => 0,
                Message =>
                    Translatable('Imported notification has body text with more than 4000 characters.'),
            };
        }
    }

    my @UpdatedNotifications;
    my @NotUpdatedNotifications;
    my @AddedNotifications;
    my @NotificationErrors;

    my %CurrentNotifications = $Self->NotificationList(
        %Param,
        UserID => $Param{UserID},
        All    => 1,
    );
    my %ReverseCurrentNotifications = reverse %CurrentNotifications;
    my %AdditionalErrors;

    NOTIFICATION:
    for my $Notification ( @{$NotificationData} ) {

        next NOTIFICATION if !$Notification;
        next NOTIFICATION if ref $Notification ne 'HASH';

        if ( !$Notification->{Name} ) {
            my $StandardMessage = "One or more notifications \"Name\" parameter is missing!";
            $AdditionalErrors{DataMissing} = $StandardMessage
                if !$AdditionalErrors{DataMissing};

            $LogObject->Log(
                Priority => 'error',
                Message  => $StandardMessage,
            );

            next NOTIFICATION;
        }

        my $NotificationExists = $ReverseCurrentNotifications{ $Notification->{Name} };

        if ( $Param{OverwriteExistingNotifications} && $NotificationExists ) {
            my $Success = $Self->NotificationUpdate(
                %{$Notification},
                ID     => $ReverseCurrentNotifications{ $Notification->{Name} },
                UserID => $Param{UserID},
            );

            if ($Success) {
                push @UpdatedNotifications, $Notification->{Name};
            }
            else {
                push @NotificationErrors, $Notification->{Name};
            }
        }
        else {
            if ($NotificationExists) {
                push @NotUpdatedNotifications, $Notification->{Name};
                next NOTIFICATION;
            }

            # now add the Notification
            my $Success = $Self->NotificationAdd(
                %{$Notification},
                UserID => $Param{UserID},
            );

            if ($Success) {
                push @AddedNotifications, $Notification->{Name};
            }
            else {
                push @NotificationErrors, $Notification->{Name};
            }
        }
    }

    my @NotificationAdditionalErrors;

    for my $ErrorKey ( sort keys %AdditionalErrors ) {
        my $ErrorMessage = $AdditionalErrors{$ErrorKey};

        push @NotificationAdditionalErrors, $ErrorMessage;
    }

    return {
        Success => 1,

        Added      => join( ', ', @AddedNotifications )      || '',
        Updated    => join( ', ', @UpdatedNotifications )    || '',
        NotUpdated => join( ', ', @NotUpdatedNotifications ) || '',
        Errors     => join( ', ', @NotificationErrors )      || '',
        AdditionalErrors => \@NotificationAdditionalErrors,

        # For compatibility with existing code
        AddedNotifications   => join( ', ', @AddedNotifications )   || '',
        UpdatedNotifications => join( ', ', @UpdatedNotifications ) || '',

        # Compatibility "NotificationErrors" are different as it counts
        # not updated notifications as errors
        NotificationErrors => join( ', ', ( @NotificationErrors, @NotUpdatedNotifications ) ) || '',
    };
}

=head2 NotificationCopy()

copy a notification

    my $NewNotificationID = $NotificationEventObject->NotificationCopy(
        ID     => 1, # mandatory
        UserID => 1, # mandatory
    );

=cut

sub NotificationCopy {
    my ( $Self, %Param ) = @_;

    my $LogObject      = $Kernel::OM->Get('Kernel::System::Log');
    my $LanguageObject = $Kernel::OM->Get('Kernel::Language');

    NEEDED:
    for my $Needed (qw(ID UserID)) {

        next NEEDED if defined $Param{$Needed};

        $LogObject->Log(
            Priority => 'error',
            Message  => "Parameter '$Needed' is needed!",
        );
        return;
    }

    my %NotificationData = $Self->NotificationGet(
        ID     => $Param{ID},
        UserID => $Param{UserID},
    );
    return if !IsHashRefWithData( \%NotificationData );

    # create new notification name
    my $NotificationName = $LanguageObject->Translate( '%s (copy)', $NotificationData{Name} );

    my $NewNotificationID = $Self->NotificationAdd(
        %NotificationData,
        Name   => $NotificationName,
        UserID => $Param{UserID},
    );

    return $NewNotificationID;
}

=head2 NotificationBodyCheck()

Check if body has a proper length depending on DB type.

    my $Ok = $NotificationEventObject->NotificationBodyCheck(
        Content => $BodyContent, # mandatory
        UserID  => 1,            # mandatory
    );

=cut

sub NotificationBodyCheck {
    my ( $Self, %Param ) = @_;

    # Check needed stuff.
    if ( !$Param{Content} ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => "Need Content!",
        );
        return;
    }

    my $DBType = $Kernel::OM->Get('Kernel::System::DB')->{'DB::Type'};

    # Body field length in the database is strictly set to 4000 characters for both PostgreSQL and Oracle backends.
    #   Since this restriction was not enforced for MySQL previously, it was possible to enter longer texts in the
    #   table. Because of this, we must now for reasons on backwards compatibility limit the body size only for those
    #   backends, at least until the next major version and planned field size change.
    #   Please see both bug#12843 (original semi-reverted fix) and bug#13281 for more information.
    if (
        (
            $DBType eq 'postgresql'
            || $DBType eq 'oracle'
        )
        && length $Param{Content} > 4000
        )
    {
        return 0;
    }

    return 1;
}

=head2 NotificationExportDataGet()

get data to export notification

    my %NotificationData = $NotificationEventObject->NotificationExportDataGet(
        ID               => 1, # mandatory
    );

Returns:

    my %NotificationData = (
        'ChangeTime' => '2024-02-06 14:49:56',
        'ValidID' => 1,
        'ID' => 16,
        'CreateBy' => 1,
        'Data' => {
            'Transports' => [
                'Email'
            ],
            'LanguageID' => [
                'en'
            ],
            'VisibleForAgent' => [
                '1'
            ],
            'Events' => [
                'UserMention'
            ],
            'ArticleAttachmentInclude' => [
                '0'
            ],
            'AgentEnabledByDefault' => [
                'Email'
            ],
            'TransportEmailTemplate' => [
                'Default'
            ]
        },
        'Name' => 'Mention notification',
        'ChangeBy' => 1,
        'Comment' => '',
        'CreateTime' => '2024-02-06 14:49:56',
        'Message' => {
            'en' => {
                'ContentType' => 'text/plain',
                'Body' => 'Hi <OTRS_NOTIFICATION_RECIPIENT_UserFirstname>,

you have been mentioned in ticket <OTRS_TICKET_NUMBER>.
<OTRS_AGENT_BODY[5]>

<OTRS_CONFIG_HttpType>://<OTRS_CONFIG_FQDN>/<OTRS_CONFIG_ScriptAlias>index.pl?Action=AgentTicketZoom;TicketID=<OTRS_TICKET_TicketID>

-- <OTRS_CONFIG_NotificationSenderName>',
                'Subject' => 'Mention in ticket: <OTRS_TICKET_Title>'
            },
            'de' => {
                'ContentType' => 'text/plain',
                'Body' => "Hallo <OTRS_NOTIFICATION_RECIPIENT_UserFirstname> <OTRS_NOTIFICATION_RECIPIENT_UserLastname>,

Sie wurden erw\x{e4}hnt in Ticket <OTRS_TICKET_NUMBER>.
<OTRS_AGENT_BODY[5]>

<OTRS_CONFIG_HttpType>://<OTRS_CONFIG_FQDN>/<OTRS_CONFIG_ScriptAlias>index.pl?Action=AgentTicketZoom;TicketID=<OTRS_TICKET_TicketID>

-- <OTRS_CONFIG_NotificationSenderName>",
                'Subject' => "Erw\x{e4}hnung in Ticket: <OTRS_TICKET_Title>"
            }
        }
    )

=cut

sub NotificationExportDataGet {
    my ( $Self, %Param ) = @_;

    my $LogObject = $Kernel::OM->Get('Kernel::System::Log');

    NEEDED:
    for my $Needed (qw(ID)) {

        next NEEDED if defined $Param{$Needed};

        $LogObject->Log(
            Priority => 'error',
            Message  => "Parameter '$Needed' is needed!",
        );
        return;
    }

    my %Notification = $Self->NotificationGet(
        ID => $Param{ID},
    );

    return if !%Notification;

    $Notification{Data}->{NotificationType} ||= ['Ticket'];

    return %Notification;
}

=head2 NotificationExportFilenameGet()

get export file name based on notification name & type

    my $Filename = $NotificationEventObject->NotificationExportFilenameGet(
        Type => 'Appointment',
        Name => 'notification_1',
        Format => 'YAML',
    );

=cut

sub NotificationExportFilenameGet {
    my ( $Self, %Param ) = @_;

    my $Type = $Param{Type};

    my $Extension = '';
    if ( $Param{Format} =~ /yml|yaml/i ) {
        $Extension = '.yaml';
    }

    return "Export_Notification$Extension"              if !$Type && !$Param{Name};
    return "Export_Notification_$Param{Type}$Extension" if $Type  && !$Param{Name};

    # no type specified but it can be recognized by the name
    # get notification with it's type
    if ( !$Param{Type} && $Param{Name} ) {
        my %NotificationData = $Self->NotificationGet(
            Name => $Param{Name},
        );

        $Type = $NotificationData{Data}->{NotificationType} ||= ['Ticket'];
        $Type = $Type->[0];
    }

    my $DisplayName = "Export_Notification_${Type}_" . $Param{Name};
    $DisplayName =~ s{[^a-zA-Z0-9-_]}{_}xmsg;
    $DisplayName =~ s{_{2,}}{_}g;
    $DisplayName =~ s{_$}{};

    return "$DisplayName$Extension";
}

1;

=head1 TERMS AND CONDITIONS

This software is part of the OTRS project (L<https://otrs.org/>).

This software comes with ABSOLUTELY NO WARRANTY. For details, see
the enclosed file COPYING for license information (GPL). If you
did not receive this file, see L<https://www.gnu.org/licenses/gpl-3.0.txt>.

=cut
