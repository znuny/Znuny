# --
# Copyright (C) 2001-2021 OTRS AG, https://otrs.com/
# Copyright (C) 2021 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see https://www.gnu.org/licenses/gpl-3.0.txt.
# --

package Kernel::System::Salutation;

use strict;
use warnings;

use Kernel::System::VariableCheck qw(:all);
use Kernel::Language qw(Translatable);

our @ObjectDependencies = (
    'Kernel::System::Cache',
    'Kernel::System::DB',
    'Kernel::System::Log',
    'Kernel::System::Valid',
    'Kernel::Language',
    'Kernel::System::Cache',
    'Kernel::System::Queue',
    'Kernel::System::YAML',
);

=head1 NAME

Kernel::System::Salutation - salutation lib

=head1 DESCRIPTION

All salutation functions.

=head1 PUBLIC INTERFACE

=head2 new()

Don't use the constructor directly, use the ObjectManager instead:

    my $SalutationObject = $Kernel::OM->Get('Kernel::System::Salutation');

=cut

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {};
    bless( $Self, $Type );

    $Self->{CacheType} = 'Salutation';
    $Self->{CacheTTL}  = 60 * 60 * 24 * 20;

    return $Self;
}

=head2 SalutationAdd()

add new salutations

    my $ID = $SalutationObject->SalutationAdd(
        Name        => 'New Salutation',
        Text        => "--\nSome Salutation Infos",
        ContentType => 'text/plain; charset=utf-8',
        Comment     => 'some comment',
        ValidID     => 1,
        UserID      => 123,
    );

=cut

sub SalutationAdd {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Needed (qw(Name Text ValidID UserID ContentType)) {
        if ( !$Param{$Needed} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Needed!",
            );
            return;
        }
    }

    # get database object
    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    return if !$DBObject->Do(
        SQL => 'INSERT INTO salutation (name, text, content_type, comments, valid_id, '
            . ' create_time, create_by, change_time, change_by) VALUES '
            . ' (?, ?, ?, ?, ?, current_timestamp, ?, current_timestamp, ?)',
        Bind => [
            \$Param{Name}, \$Param{Text}, \$Param{ContentType}, \$Param{Comment},
            \$Param{ValidID}, \$Param{UserID}, \$Param{UserID},
        ],
    );

    # get new salutation id
    $DBObject->Prepare(
        SQL   => 'SELECT id FROM salutation WHERE name = ?',
        Bind  => [ \$Param{Name} ],
        Limit => 1,
    );

    my $ID;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        $ID = $Row[0];
    }

    return if !$ID;

    # reset cache
    $Kernel::OM->Get('Kernel::System::Cache')->CleanUp(
        Type => $Self->{CacheType},
    );

    return $ID;
}

=head2 SalutationGet()

get salutations attributes

    my %Salutation = $SalutationObject->SalutationGet(
        ID => 123,
    );

=cut

sub SalutationGet {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    if ( !$Param{ID} ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => "Need ID!",
        );
        return;
    }

    # check cache
    my $Cache = $Kernel::OM->Get('Kernel::System::Cache')->Get(
        Type => $Self->{CacheType},
        Key  => 'SalutationGet' . $Param{ID},
    );
    return %{$Cache} if $Cache;

    # get database object
    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    # get the salutation
    return if !$DBObject->Prepare(
        SQL => 'SELECT id, name, text, content_type, comments, valid_id, change_time, create_time '
            . 'FROM salutation WHERE id = ?',
        Bind => [ \$Param{ID} ],
    );

    # fetch the result
    my %Data;
    while ( my @Data = $DBObject->FetchrowArray() ) {
        %Data = (
            ID          => $Data[0],
            Name        => $Data[1],
            Text        => $Data[2],
            ContentType => $Data[3] || 'text/plain',
            Comment     => $Data[4],
            ValidID     => $Data[5],
            ChangeTime  => $Data[6],
            CreateTime  => $Data[7],
        );
    }

    # no data found
    if ( !%Data ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => "SalutationID '$Param{ID}' not found!",
        );
        return;
    }

    # set cache
    $Kernel::OM->Get('Kernel::System::Cache')->Set(
        Type  => $Self->{CacheType},
        TTL   => $Self->{CacheTTL},
        Key   => 'SalutationGet' . $Param{ID},
        Value => \%Data,
    );

    return %Data;
}

=head2 SalutationUpdate()

update salutation attributes

    $SalutationObject->SalutationUpdate(
        ID          => 123,
        Name        => 'New Salutation',
        Text        => "--\nSome Salutation Infos",
        ContentType => 'text/plain; charset=utf-8',
        Comment     => 'some comment',
        ValidID     => 1,
        UserID      => 123,
    );

=cut

sub SalutationUpdate {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Needed (qw(ID Name Text ContentType ValidID UserID)) {
        if ( !$Param{$Needed} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Needed!",
            );
            return;
        }
    }

    # get database object
    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    # sql
    return if !$DBObject->Do(
        SQL => 'UPDATE salutation SET name = ?, text = ?, content_type = ?, comments = ?, '
            . 'valid_id = ?, change_time = current_timestamp, change_by = ? WHERE id = ?',
        Bind => [
            \$Param{Name}, \$Param{Text}, \$Param{ContentType}, \$Param{Comment},
            \$Param{ValidID}, \$Param{UserID}, \$Param{ID},
        ],
    );

    # reset cache
    $Kernel::OM->Get('Kernel::System::Cache')->CleanUp(
        Type => $Self->{CacheType},
    );

    return 1;
}

=head2 SalutationDelete()

delete a salutation from the database by it's id

    my $Success = $SalutationObject->SalutationDelete(
        ID     => 1,
        UserID => 1,
    );

=cut

sub SalutationDelete {
    my ( $Self, %Param ) = @_;

    my $LogObject   = $Kernel::OM->Get('Kernel::System::Log');
    my $DBObject    = $Kernel::OM->Get('Kernel::System::DB');
    my $CacheObject = $Kernel::OM->Get('Kernel::System::Cache');

    for my $Argument (qw(ID UserID)) {
        if ( !$Param{$Argument} ) {
            $LogObject->Log(
                Priority => 'error',
                Message  => "Need $Argument!",
            );
            return;
        }
    }

    if ( $Param{ID} == 1 ) {
        $LogObject->Log(
            Priority => 'error',
            Message  => "Can't delete salutation with ID '$Param{ID}'!",
        );
        return;
    }

    # check if salutation exists
    my %Check = $Self->SalutationGet(
        ID => $Param{ID},
    );
    if ( !%Check ) {
        $LogObject->Log(
            Priority => 'error',
            Message  => "Can't delete salutation with ID '$Param{ID}'. Salutation does not exist!",
        );
        return;
    }

    my $QueueSearchLimit = 10;

    return if !$DBObject->Prepare(
        SQL   => "SELECT id FROM queue WHERE salutation_id = ?",
        Bind  => [ \$Param{ID} ],
        Limit => $QueueSearchLimit,
    );

    my @SalutationLinkedQueues;

    while ( my @Row = $DBObject->FetchrowArray() ) {
        push @SalutationLinkedQueues, $Row[0];
    }

    my $SalutationIsLinkedToQueueCount = scalar @SalutationLinkedQueues;

    if ($SalutationIsLinkedToQueueCount) {
        my $LinkedQueuesStrg = join ', ', @SalutationLinkedQueues;
        my $ErrorMessage
            = "Can't delete salutation with ID '$Param{ID}'! It is linked to queues with IDs $LinkedQueuesStrg";

        $ErrorMessage .= ' and more.' if ( $SalutationIsLinkedToQueueCount == $QueueSearchLimit );

        $LogObject->Log(
            Priority => 'error',
            Message  => $ErrorMessage,
        );

        return;
    }

    # delete salutation
    my $DeleteOK = $DBObject->Do(
        SQL  => 'DELETE FROM salutation WHERE id = ?',
        Bind => [ \$Param{ID} ],
    );

    # error handling
    if ( !$DeleteOK ) {
        $LogObject->Log(
            Priority => 'error',
            Message  => "Can't delete salutation with ID '$Param{ID}'!",
        );
        return;
    }

    $LogObject->Log(
        Priority => 'notice',
        Message  => "SalutationEvent Salutation '$Check{Name}' deleted (UserID=$Param{UserID}).",
    );

    # reset cache
    $Kernel::OM->Get('Kernel::System::Cache')->CleanUp(
        Type => $Self->{CacheType},
    );

    return 1;
}

=head2 SalutationExport()

export a salutation

    my $ExportData = $SalutationObject->SalutationExport(
        # required either ID or ExportAll
        ID                       => $SalutationID,
        ExportAll                => 0,               # possible: 0, 1

        UserID                   => 1,               # required
    }

returns Salutation hashes in an array with data:

    my $ExportData =
    [
        {
            'Text' => 'Dear &lt;OTRS_CUSTOMER_REALNAME&gt;,<br />
<br />
Thank you for your request.<br />
&nbsp;',
            'ValidID' => 1,
            'ChangeTime' => '2024-07-17 10:50:54',
            'Name' => 'system standard salutation (en)',
            'ContentType' => 'text/html',
            'Comment' => 'Standard Salutation.',
            'Queues' => {},
            'ID' => 1,
            'CreateTime' => '2024-02-06 14:49:56'
        },
        {
            'Text' => 'Dear &lt;OTRS_CUSTOMER_REALNAME&gt;,<br />
<br />
Thank you for your request.<br />
&nbsp;',
            'ValidID' => 1,
            'ChangeTime' => '2024-07-17 12:43:03',
            'Name' => 'system standard salutation (en) (copy)',
            'ContentType' => 'text/html',
            'Comment' => 'Standard Salutation.',
            'Queues' => {},
            'ID' => 3,
            'CreateTime' => '2024-07-17 11:52:45'
        }
    ];


=cut

sub SalutationExport {
    my ( $Self, %Param ) = @_;

    my $LogObject = $Kernel::OM->Get('Kernel::System::Log');

    my $SalutationData;

    if ( $Param{ExportAll} ) {
        my %SalutationList = $Self->SalutationList(
            Valid => 0,
        );

        my @Data;
        for my $ItemID ( sort keys %SalutationList ) {
            my %SalutationSingleData = $Self->SalutationExportDataGet(
                ID => $ItemID,
            );

            push @Data, \%SalutationSingleData if %SalutationSingleData;
        }
        $SalutationData = \@Data;
    }
    elsif ( $Param{ID} ) {
        my %SalutationSingleData = $Self->SalutationExportDataGet(
            ID => $Param{ID},
        );

        return if !%SalutationSingleData;

        $SalutationData = [ \%SalutationSingleData ];
    }
    else {
        $LogObject->Log(
            Priority => 'error',
            Message  => 'Need either "ExportAll" or "ID" parameter!',
        );
        return;
    }

    return $SalutationData;
}

=head2 SalutationImport()

import a salutation via YAML content

    my $ImportResult = $SalutationObject->SalutationImport(
        Content                      => $YAMLContent, # mandatory, YAML format
        OverwriteExistingSalutations => 0,            # optional, possible: 0, 1
        UserID                       => 1,            # mandatory
    );

Returns:

    $Result = {
        Success            => 1,                                  # 1 if success or undef if operation could not
                                                                  # be performed
        Message            => 'The Message to show.',             # error message
        Added              => 'Salutation1, Salutation2',         # string of Salutations correctly added
        Updated            => 'Salutation3, Salutation4',         # string of Salutations correctly updated
        NotUpdated         => 'Salutation5, Salutation6',         # string of Salutations not updated due to existing entity
                                                                  # with the same name
        Errors             => 'Salutation5',                      # string of Salutations that could not be added or updated
        AdditionalErrors   => ['Some error occured!', 'Error2!'], # list of additional error not necessarily related to specified salutation
    };

=cut

sub SalutationImport {
    my ( $Self, %Param ) = @_;

    my $YAMLObject  = $Kernel::OM->Get('Kernel::System::YAML');
    my $LogObject   = $Kernel::OM->Get('Kernel::System::Log');
    my $QueueObject = $Kernel::OM->Get('Kernel::System::Queue');

    for my $Needed (qw(Content UserID)) {

        if ( !$Param{$Needed} ) {
            $LogObject->Log(
                Priority => 'error',
                Message  => "Need $Needed!",
            );
            return {
                Success => 0,
                Message => "$Needed is missing, can not continue.",
            };
        }
    }

    my $SalutationData = $YAMLObject->Load(
        Data => $Param{Content},
    );

    if ( ref $SalutationData ne 'ARRAY' ) {
        return {
            Success => 0,
            Message =>
                Translatable("Couldn't read salutation configuration file. Please make sure the file is valid."),
        };
    }

    my @UpdatedSalutations;
    my @NotUpdatedSalutations;
    my @AddedSalutations;
    my @SalutationErrors;

    my %CurrentSalutations = $Self->SalutationList(
        %Param,
    );
    my %ReverseCurrentSalutations = reverse %CurrentSalutations;
    my %AdditionalErrors;

    SALUTATION:
    for my $Salutation ( @{$SalutationData} ) {

        next SALUTATION if !$Salutation;
        next SALUTATION if ref $Salutation ne 'HASH';

        if ( !$Salutation->{Name} ) {
            my $StandardMessage = "One or more salutations \"Name\" parameter is missing!";
            $AdditionalErrors{DataMissing} = $StandardMessage
                if !$AdditionalErrors{DataMissing};

            $LogObject->Log(
                Priority => 'error',
                Message  => $StandardMessage,
            );

            next SALUTATION;
        }

        # link queues by name
        my $Queues = delete $Salutation->{Queues};
        my @QueuesToLink;

        my $QueueContainsError;
        my $QueueErrorMessage;

        my $ShowQueues;

        # check if queues specified in the content exists in the db
        if ( IsHashRefWithData($Queues) ) {
            for my $QueueName ( values %{$Queues} ) {
                my $QueueID;

                $QueueID = $QueueObject->QueueLookup( Queue => $QueueName ) if $QueueName;

                if ($QueueID) {
                    push @QueuesToLink, $QueueID if $QueueID;
                }
                else {
                    if ( !$QueueContainsError ) {
                        $QueueContainsError = 1;

                        if ( !$QueueName ) {
                            $QueueErrorMessage
                                = "Salutation $Salutation->{Name} import data contains linked queues that do not have a name.";
                        }
                        else {
                            $ShowQueues = 1;
                            $QueueErrorMessage
                                = "Salutation $Salutation->{Name} import data contains linked queues that do not exist.";
                        }

                        $QueueErrorMessage .= " Invalid queues: $QueueName" if $ShowQueues;
                    }
                    else {
                        $QueueErrorMessage .= ", $QueueName" if $ShowQueues;
                    }
                }
            }

            if ($QueueErrorMessage) {
                $LogObject->Log(
                    Priority => 'error',
                    Message =>
                        $QueueErrorMessage . '.',
                );
                push @SalutationErrors, $Salutation->{Name};
                next SALUTATION;
            }
        }

        my $Success;
        my $LinkedDataSuccess = 1;
        my $SalutationExists  = $ReverseCurrentSalutations{ $Salutation->{Name} };

        if ( $Param{OverwriteExistingSalutations} && $SalutationExists ) {
            my $SalutationID = $ReverseCurrentSalutations{ $Salutation->{Name} };
            $Success = $Self->SalutationUpdate(
                %{$Salutation},
                ID     => $SalutationID,
                UserID => $Param{UserID},
            );

            if ($Success) {
                $LinkedDataSuccess = $Self->SalutationQueueLinkBySalutation(
                    QueueIDs => \@QueuesToLink,
                    ID       => $SalutationID,
                    UserID   => 1,
                );

                push @UpdatedSalutations, $Salutation->{Name};
            }
        }
        else {
            if ($SalutationExists) {
                push @NotUpdatedSalutations, $Salutation->{Name};
                next SALUTATION;
            }

            my $SalutationID = $Self->SalutationAdd(
                %{$Salutation},
                UserID => $Param{UserID},
            );

            $Success = $SalutationID;

            if ($SalutationID) {
                $LinkedDataSuccess = $Self->SalutationQueueLinkBySalutation(
                    QueueIDs => \@QueuesToLink,
                    ID       => $SalutationID,
                    UserID   => 1,
                );

                push @AddedSalutations, $Salutation->{Name};
            }
        }

        # indicate error when entity wasn't imported at all or there are some
        # issues with linked data from the import file or for some
        # other reason data can't be linked correctly
        if ( !$Success || $QueueContainsError || !$LinkedDataSuccess ) {
            push @SalutationErrors, $Salutation->{Name};
        }
    }

    my @SalutationAdditionalErrors;

    for my $ErrorKey ( sort keys %AdditionalErrors ) {
        my $ErrorMessage = $AdditionalErrors{$ErrorKey};

        push @SalutationAdditionalErrors, $ErrorMessage;
    }

    return {
        Success          => 1,
        Added            => join( ', ', @AddedSalutations ) || '',
        Updated          => join( ', ', @UpdatedSalutations ) || '',
        NotUpdated       => join( ', ', @NotUpdatedSalutations ) || '',
        Errors           => join( ', ', @SalutationErrors ) || '',
        AdditionalErrors => \@SalutationAdditionalErrors,
    };
}

=head2 SalutationCopy()

copy a salutation

    my $NewSalutationID = $SalutationObject->SalutationCopy(
        ID     => 1, # mandatory
        UserID => 1, # mandatory
    );

=cut

sub SalutationCopy {
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

    my %SalutationData = $Self->SalutationGet(
        ID     => $Param{ID},
        UserID => $Param{UserID},
    );
    return if !IsHashRefWithData( \%SalutationData );

    # create new salutation name
    my $SalutationName = $LanguageObject->Translate( '%s (copy)', $SalutationData{Name} );

    my $NewSalutationID = $Self->SalutationAdd(
        %SalutationData,
        Name   => $SalutationName,
        UserID => $Param{UserID},
    );

    return $NewSalutationID;
}

=head2 SalutationExportDataGet()

get data to export salutation

    my %SalutationData = $SalutationObject->SalutationExportDataGet(
        ID               => 1, # mandatory
    );

Returns:

    my %SalutationData = (
        'ContentType' => 'text/html',
        'Comment' => 'Standard Salutation.',
        'ValidID' => 1,
        'CreateTime' => '2024-02-06 14:49:56',
        'Queues' => {
            '6' => 'Queuetest1192009180100007',
            '21' => 'Queuetest1450009665400005',
        },
        'ID' => 1,
        'Text' => 'Dear &lt;OTRS_CUSTOMER_REALNAME&gt;,<br />
<br />
Thank you for your request.<br />
&nbsp;',
        'ChangeTime' => '2024-07-19 14:27:34',
        'Name' => 'system standard salutation (en)'
    )

=cut

sub SalutationExportDataGet {
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

    my %Salutation = $Self->SalutationGet(
        ID => $Param{ID},
    );

    return if !%Salutation;

    my %SalutationQueuesList = $Self->SalutationQueuesList(
        ID => $Param{ID},
    );

    my %ExportData = ( %Salutation, Queues => \%SalutationQueuesList );

    return %ExportData;
}

=head2 SalutationExportFilenameGet()

get export file name based on salutation name

    my $Filename = $SalutationObject->SalutationExportFilenameGet(
        Name => 'Salutation_1',
        Format => 'YAML',
    );

=cut

sub SalutationExportFilenameGet {
    my ( $Self, %Param ) = @_;

    my $Extension = '';
    if ( $Param{Format} =~ /yml|yaml/i ) {
        $Extension = '.yaml';
    }
    return "Export_Salutation$Extension" if !$Param{Name};

    my $DisplayName = 'Export_Salutation_' . $Param{Name};
    $DisplayName =~ s{[^a-zA-Z0-9-_]}{_}xmsg;
    $DisplayName =~ s{_{2,}}{_}g;
    $DisplayName =~ s{_$}{};

    return "$DisplayName$Extension";
}

=head2 SalutationQueuesList()

get a list of the queues that have been linked to salutation

    my %SalutationQueues = $SalutationObject->SalutationQueuesList(
        ID => 1, # mandatory
    );

Returns:

    my %Queues = (
        1 => 'queue1',
        2 => 'queue2',
    )

=cut

sub SalutationQueuesList {
    my ( $Self, %Param ) = @_;

    my $DBObject  = $Kernel::OM->Get('Kernel::System::DB');
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

    return if !$DBObject->Prepare(
        SQL =>
            'SELECT id, name
             FROM queue
             WHERE salutation_id = ?
             ',
        Bind => [ \$Param{ID} ],
    );

    my %Queues;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        $Queues{ $Row[0] } = $Row[1];
    }

    return %Queues;
}

=head2 SalutationQueueLinkBySalutation()

assign a list of queues to a salutation

    my $Success = $SalutationObject->SalutationQueueLinkBySalutation(
        QueueIDs => [1,2,3],
        ID       => 1,
        UserID   => 1,
    );

=cut

sub SalutationQueueLinkBySalutation {
    my ( $Self, %Param ) = @_;

    my $LogObject   = $Kernel::OM->Get('Kernel::System::Log');
    my $DBObject    = $Kernel::OM->Get('Kernel::System::DB');
    my $QueueObject = $Kernel::OM->Get('Kernel::System::Queue');

    for my $Argument (qw(QueueIDs ID UserID)) {
        if ( !$Param{$Argument} ) {
            $LogObject->Log(
                Priority => 'error',
                Message  => "Need $Argument!",
            );
            return;
        }
    }

    my %SalutationData = $Self->SalutationGet(
        ID => $Param{ID},
    );

    # return failed status if salutation does not exists
    return if !$SalutationData{ID};

    # return success if there are no queues to assign
    return 1 if !IsArrayRefWithData( $Param{QueueIDs} );

    my @Queues = @{ $Param{QueueIDs} };
    for ( my $i = 0; $i < scalar @Queues; $i++ ) {
        my $QueueID = $Queues[$i];
        my $Queue   = $QueueObject->QueueLookup( QueueID => $QueueID );

        delete $Queues[$i] if !$Queue;
    }

    # filter out deleted/not existing queues
    @Queues = grep {$_} @Queues;

    # no valid queues to link
    return if !scalar @Queues;

    for my $QueueID (@Queues) {
        my %Queue = $QueueObject->QueueGet(
            ID => $QueueID,
        );

        my $Success = $QueueObject->QueueUpdate(

            # update queue to be linked with new salutation
            %Queue,
            SalutationID => $SalutationData{ID},
            UserID       => $Param{UserID},
        );

        # this error is not perfect as it will show in the logs,
        # but result of the function will still be counted as successful
        # otherwise we might add some linked data and break at linking error
        # which is worse case to handle
        $LogObject->Log(
            Priority => 'error',
            Message  => "Error occurred while linking queue with ID $QueueID to standard template with ID $Param{ID}.",
        ) if !$Success;
    }

    return 1;
}

=head2 SalutationList()

get salutation list

    my %List = $SalutationObject->SalutationList();

    my %List = $SalutationObject->SalutationList(
        Valid => 0,
    );

=cut

sub SalutationList {
    my ( $Self, %Param ) = @_;

    # check valid param
    if ( !defined $Param{Valid} ) {
        $Param{Valid} = 1;
    }

    # create cachekey
    my $CacheKey;
    if ( $Param{Valid} ) {
        $CacheKey = 'SalutationList::Valid';
    }
    else {
        $CacheKey = 'SalutationList::All';
    }

    # check cache
    my $Cache = $Kernel::OM->Get('Kernel::System::Cache')->Get(
        Type => $Self->{CacheType},
        Key  => $CacheKey,
    );
    return %{$Cache} if $Cache;

    # create sql
    my $SQL = 'SELECT id, name FROM salutation ';
    if ( $Param{Valid} ) {
        $SQL
            .= "WHERE valid_id IN ( ${\(join ', ', $Kernel::OM->Get('Kernel::System::Valid')->ValidIDsGet())} )";
    }

    # get database object
    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    return if !$DBObject->Prepare( SQL => $SQL );

    # fetch the result
    my %Data;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        $Data{ $Row[0] } = $Row[1];
    }

    # set cache
    $Kernel::OM->Get('Kernel::System::Cache')->Set(
        Type  => $Self->{CacheType},
        TTL   => $Self->{CacheTTL},
        Key   => $CacheKey,
        Value => \%Data,
    );

    return %Data;
}

1;

=head1 TERMS AND CONDITIONS

This software is part of the OTRS project (L<https://otrs.org/>).

This software comes with ABSOLUTELY NO WARRANTY. For details, see
the enclosed file COPYING for license information (GPL). If you
did not receive this file, see L<https://www.gnu.org/licenses/gpl-3.0.txt>.

=cut
