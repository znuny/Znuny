# --
# Copyright (C) 2001-2021 OTRS AG, https://otrs.com/
# Copyright (C) 2021 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see https://www.gnu.org/licenses/gpl-3.0.txt.
# --

package Kernel::System::Signature;

use strict;
use warnings;

use Kernel::System::VariableCheck qw(:all);
use Kernel::Language qw(Translatable);

our @ObjectDependencies = (
    'Kernel::System::DB',
    'Kernel::System::Log',
    'Kernel::System::Valid',
    'Kernel::Language',
    'Kernel::System::Queue',
    'Kernel::System::YAML',
);

=head1 NAME

Kernel::System::Signature - signature lib

=head1 DESCRIPTION

All signature functions.

=head1 PUBLIC INTERFACE

=head2 new()

Don't use the constructor directly, use the ObjectManager instead:

    my $SignatureObject = $Kernel::OM->Get('Kernel::System::Signature');

=cut

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {};
    bless( $Self, $Type );

    return $Self;
}

=head2 SignatureAdd()

add new signatures

    my $ID = $SignatureObject->SignatureAdd(
        Name        => 'New Signature',
        Text        => "--\nSome Signature Infos",
        ContentType => 'text/plain; charset=utf-8',
        Comment     => 'some comment',
        ValidID     => 1,
        UserID      => 123,
    );

=cut

sub SignatureAdd {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Needed (qw(Name Text ContentType ValidID UserID)) {
        if ( !$Param{$Needed} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Needed!"
            );
            return;
        }
    }

    # get database object
    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    return if !$DBObject->Do(
        SQL => 'INSERT INTO signature (name, text, content_type, comments, valid_id, '
            . ' create_time, create_by, change_time, change_by)'
            . ' VALUES (?, ?, ?, ?, ?, current_timestamp, ?, current_timestamp, ?)',
        Bind => [
            \$Param{Name}, \$Param{Text}, \$Param{ContentType}, \$Param{Comment},
            \$Param{ValidID}, \$Param{UserID}, \$Param{UserID},
        ],
    );

    # get new signature id
    $DBObject->Prepare(
        SQL  => 'SELECT id FROM signature WHERE name = ?',
        Bind => [ \$Param{Name} ],
    );

    my $ID;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        $ID = $Row[0];
    }

    return $ID;
}

=head2 SignatureGet()

get signatures attributes

    my %Signature = $SignatureObject->SignatureGet(
        ID => 123,
    );

=cut

sub SignatureGet {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    if ( !$Param{ID} ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => "Need ID!"
        );
        return;
    }

    # get database object
    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    # sql
    return if !$DBObject->Prepare(
        SQL => 'SELECT id, name, text, content_type, comments, valid_id, change_time, create_time '
            . ' FROM signature WHERE id = ?',
        Bind => [ \$Param{ID} ],
    );

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
            Message  => "SignatureID '$Param{ID}' not found!"
        );
        return;
    }

    return %Data;
}

=head2 SignatureUpdate()

update signature attributes

    $SignatureObject->SignatureUpdate(
        ID          => 123,
        Name        => 'New Signature',
        Text        => "--\nSome Signature Infos",
        ContentType => 'text/plain; charset=utf-8',
        Comment     => 'some comment',
        ValidID     => 1,
        UserID      => 123,
    );

=cut

sub SignatureUpdate {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Needed (qw(ID Name Text ContentType ValidID UserID)) {
        if ( !$Param{$Needed} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Needed!"
            );
            return;
        }
    }

    # sql
    return if !$Kernel::OM->Get('Kernel::System::DB')->Do(
        SQL => 'UPDATE signature SET name = ?, text = ?, content_type = ?, comments = ?, '
            . ' valid_id = ?, change_time = current_timestamp, change_by = ? WHERE id = ?',
        Bind => [
            \$Param{Name}, \$Param{Text}, \$Param{ContentType}, \$Param{Comment},
            \$Param{ValidID}, \$Param{UserID}, \$Param{ID},
        ],
    );

    return 1;
}

=head2 SignatureDelete()

delete a signature from the database by it's id

    my $Success = $SignatureObject->SignatureDelete(
        ID     => 1,
        UserID => 1,
    );

=cut

sub SignatureDelete {
    my ( $Self, %Param ) = @_;

    my $LogObject = $Kernel::OM->Get('Kernel::System::Log');
    my $DBObject  = $Kernel::OM->Get('Kernel::System::DB');

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
            Message  => "Can't delete signature with ID '$Param{ID}'!",
        );
        return;
    }

    # check if signature exists
    my %Check = $Self->SignatureGet(
        ID => $Param{ID},
    );
    if ( !%Check ) {
        $LogObject->Log(
            Priority => 'error',
            Message  => "Can't delete signature with ID '$Param{ID}'. Signature does not exist!",
        );
        return;
    }

    my $QueueSearchLimit = 10;

    return if !$DBObject->Prepare(
        SQL   => "SELECT id FROM queue WHERE signature_id = ?",
        Bind  => [ \$Param{ID} ],
        Limit => $QueueSearchLimit,
    );

    my @SignatureLinkedQueues;

    while ( my @Row = $DBObject->FetchrowArray() ) {
        push @SignatureLinkedQueues, $Row[0];
    }

    my $SignatureIsLinkedToQueueCount = scalar @SignatureLinkedQueues;

    if ($SignatureIsLinkedToQueueCount) {
        my $LinkedQueuesStrg = join ', ', @SignatureLinkedQueues;
        my $ErrorMessage
            = "Can't delete signature with ID '$Param{ID}'! It is linked to queues with IDs $LinkedQueuesStrg";

        $ErrorMessage .= ' and more.' if ( $SignatureIsLinkedToQueueCount == $QueueSearchLimit );

        $LogObject->Log(
            Priority => 'error',
            Message  => $ErrorMessage,
        );

        return;
    }

    # delete signature
    my $DeleteOK = $DBObject->Do(
        SQL  => 'DELETE FROM signature WHERE id = ?',
        Bind => [ \$Param{ID} ],
    );

    # error handling
    if ( !$DeleteOK ) {
        $LogObject->Log(
            Priority => 'error',
            Message  => "Can't delete signature with ID '$Param{ID}'!",
        );
        return;
    }

    $LogObject->Log(
        Priority => 'notice',
        Message  => "SignatureEvent Signature '$Check{Name}' deleted (UserID=$Param{UserID}).",
    );

    return 1;
}

=head2 SignatureExport()

export a signature

    my $ExportData = $SignatureObject->SignatureExport(
        # required either ID or ExportAll
        ID                       => $SignatureID,
        ExportAll                => 0,               # possible: 0, 1

        UserID                   => 1,               # required
    }

returns Signature hashes in an array with data:

    my $ExportData =
    [
        {
            'ID' => 1,
            'Name' => 'system standard signature (en)',
            'Text' => '
Your Ticket-Team

<OTRS_Agent_UserFirstname> <OTRS_Agent_UserLastname>

--
Super Support - Waterford Business Park
5201 Blue Lagoon Drive - 8th Floor & 9th Floor - Miami, 33126 USA
Email: hot@example.com - Web: http://www.example.com/
--',
            'CreateTime' => '2024-02-06 14:49:56',
            'Queues' => {},
            'Comment'     => 'Standard Signature.',
            'ValidID'     => 1,
            'ChangeTime'  => '2024-02-06 14:49:56',
            'ContentType' => 'text/plain; charset=utf-8'
        },
        {
            'ID' => 2,
            'Name' => 'system standard signature (pl)',
            'Text' => '
Your Ticket-Team

<OTRS_Agent_UserFirstname> <OTRS_Agent_UserLastname>

--
Super Support - Waterford Business Park
5201 Blue Lagoon Drive - 8th Floor & 9th Floor - Miami, 33126 USA
Email: hot@example.com - Web: http://www.example.com/
--',
            'CreateTime' => '2024-07-22 11:58:32',
            'Queues'     => {},
            'Comment'     => 'Standard Signature.',
            'ValidID'     => 1,
            'ChangeTime'  => '2024-07-22 11:58:32',
            'ContentType' => 'text/plain; charset=utf-8'
        }
    ];

=cut

sub SignatureExport {
    my ( $Self, %Param ) = @_;

    my $LogObject = $Kernel::OM->Get('Kernel::System::Log');

    my $SignatureData;

    if ( $Param{ExportAll} ) {
        my %SignatureList = $Self->SignatureList(
            Valid => 0,
        );

        my @Data;
        for my $ItemID ( sort keys %SignatureList ) {
            my %SignatureSingleData = $Self->SignatureExportDataGet(
                ID => $ItemID,
            );

            push @Data, \%SignatureSingleData if %SignatureSingleData;
        }
        $SignatureData = \@Data;
    }
    elsif ( $Param{ID} ) {
        my %SignatureSingleData = $Self->SignatureExportDataGet(
            ID => $Param{ID},
        );

        return if !%SignatureSingleData;

        $SignatureData = [ \%SignatureSingleData ];
    }
    else {
        $LogObject->Log(
            Priority => 'error',
            Message  => 'Need either "ExportAll" or "ID" parameter!',
        );
        return;
    }

    return $SignatureData;
}

=head2 SignatureImport()

import a signature via YAML content

    my $ImportResult = $SignatureObject->SignatureImport(
        Content                     => $YAMLContent, # mandatory, YAML format
        OverwriteExistingSignatures => 0,            # optional, possible: 0, 1
        UserID                      => 1,            # mandatory
    );

Returns:

    $Result = {
        Success           => 1,                                  # 1 if success or undef if operation could not
                                                                 # be performed
        Message           => 'The Message to show.',             # error message
        Added             => 'Signature1, Signature2',           # string of Signatures correctly added
        Updated           => 'Signature3, Signature4',           # string of Signatures correctly updated
        NotUpdated        => 'Signature5, Signature6',           # string of Signatures not updated due to existing entity
                                                                 # with the same name
        Errors            => 'Signature',                        # string of Signatures that could not be added or updated
        AdditionalErrors  => ['Some error occured!', 'Error2!'], # list of additional error not necessarily related to specified Signature
    };

=cut

sub SignatureImport {
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

    my $SignatureData = $YAMLObject->Load(
        Data => $Param{Content},
    );

    if ( ref $SignatureData ne 'ARRAY' ) {
        return {
            Success => 0,
            Message =>
                Translatable("Couldn't read signature configuration file. Please make sure the file is valid."),
        };
    }

    my @UpdatedSignatures;
    my @NotUpdatedSignatures;
    my @AddedSignatures;
    my @SignatureErrors;

    my %CurrentSignatures = $Self->SignatureList(
        %Param,
    );
    my %ReverseCurrentSignatures = reverse %CurrentSignatures;
    my %AdditionalErrors;

    SIGNATURE:
    for my $Signature ( @{$SignatureData} ) {

        next SIGNATURE if !$Signature;
        next SIGNATURE if ref $Signature ne 'HASH';

        if ( !$Signature->{Name} ) {
            my $StandardMessage = "One or more signatures \"Name\" parameter is missing!";
            $AdditionalErrors{DataMissing} = $StandardMessage
                if !$AdditionalErrors{DataMissing};

            $LogObject->Log(
                Priority => 'error',
                Message  => $StandardMessage,
            );

            next SIGNATURE;
        }

        # link queues by name
        my $Queues = delete $Signature->{Queues};
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
                                = "Signature $Signature->{Name} import data contains linked queues that do not have a name.";
                        }
                        else {
                            $ShowQueues = 1;
                            $QueueErrorMessage
                                = "Signature $Signature->{Name} import data contains linked queues that do not exist.";
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
                push @SignatureErrors, $Signature->{Name};
                next SIGNATURE;
            }
        }

        my $Success;
        my $LinkedDataSuccess = 1;
        my $SignatureExists   = $ReverseCurrentSignatures{ $Signature->{Name} };

        if ( $Param{OverwriteExistingSignatures} && $SignatureExists ) {
            my $SignatureID = $ReverseCurrentSignatures{ $Signature->{Name} };
            $Success = $Self->SignatureUpdate(
                %{$Signature},
                ID     => $SignatureID,
                UserID => $Param{UserID},
            );

            if ($Success) {
                $LinkedDataSuccess = $Self->SignatureQueueLinkBySignature(
                    QueueIDs => \@QueuesToLink,
                    ID       => $SignatureID,
                    UserID   => 1,
                );

                push @UpdatedSignatures, $Signature->{Name};
            }
        }
        else {
            if ($SignatureExists) {
                push @NotUpdatedSignatures, $Signature->{Name};
                next SIGNATURE;
            }

            my $SignatureID = $Self->SignatureAdd(
                %{$Signature},
                UserID => $Param{UserID},
            );

            $Success = $SignatureID;

            if ($SignatureID) {
                $LinkedDataSuccess = $Self->SignatureQueueLinkBySignature(
                    QueueIDs => \@QueuesToLink,
                    ID       => $SignatureID,
                    UserID   => 1,
                );

                push @AddedSignatures, $Signature->{Name};
            }
        }

        # indicate error when entity wasn't imported at all or there are some
        # issues with linked data from the import file or for some
        # other reason data can't be linked correctly
        if ( !$Success || $QueueContainsError || !$LinkedDataSuccess ) {
            push @SignatureErrors, $Signature->{Name};
        }
    }

    my @SignatureAdditionalErrors;

    for my $ErrorKey ( sort keys %AdditionalErrors ) {
        my $ErrorMessage = $AdditionalErrors{$ErrorKey};

        push @SignatureAdditionalErrors, $ErrorMessage;
    }

    return {
        Success          => 1,
        Added            => join( ', ', @AddedSignatures ) || '',
        Updated          => join( ', ', @UpdatedSignatures ) || '',
        NotUpdated       => join( ', ', @NotUpdatedSignatures ) || '',
        Errors           => join( ', ', @SignatureErrors ) || '',
        AdditionalErrors => \@SignatureAdditionalErrors,
    };
}

=head2 SignatureCopy()

copy a signature

    my $NewSignatureID = $SignatureObject->SignatureCopy(
        ID     => 1, # mandatory
        UserID => 1, # mandatory
    );

=cut

sub SignatureCopy {
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

    my %SignatureData = $Self->SignatureGet(
        ID     => $Param{ID},
        UserID => $Param{UserID},
    );
    return if !IsHashRefWithData( \%SignatureData );

    # create new signature name
    my $SignatureName = $LanguageObject->Translate( '%s (copy)', $SignatureData{Name} );

    my $NewSignatureID = $Self->SignatureAdd(
        %SignatureData,
        Name   => $SignatureName,
        UserID => $Param{UserID},
    );

    return $NewSignatureID;
}

=head2 SignatureExportDataGet()

get data to export signature

    my %SignatureData = $SignatureObject->SignatureExportDataGet(
        ID               => 1, # mandatory
    );

Returns:

    my %SignatureData = (
        'ContentType' => 'text/plain; charset=utf-8',
        'ValidID' => 1,
        'Comment' => 'Standard Signature.',
        'CreateTime' => '2024-07-22 11:58:32',
        'Queues' => {
            '6' => 'Queuetest1192009180100007',
            '21' => 'Queuetest1450009665400005',
        },
        'ID' => 2,
        'Text' => '
Your Ticket-

<OTRS_Agent_UserFirstname> <OTRS_Agent_UserLastname>

--
Super Support - Waterford Business Park
5201 Blue Lagoon Drive - 8th Floor & 9th Floor - Miami, 33126 USA
Email: hot@example.com - Web: http://www.example.com/
--',
        'Name' => 'system standard signature (pl)',
        'ChangeTime' => '2024-07-22 12:13:18'
    )

=cut

sub SignatureExportDataGet {
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

    my %Signature = $Self->SignatureGet(
        ID => $Param{ID},
    );

    return if !%Signature;

    my %SignatureQueuesList = $Self->SignatureQueuesList(
        ID => $Param{ID},
    );

    my %ExportData = ( %Signature, Queues => \%SignatureQueuesList );

    return %ExportData;
}

=head2 SignatureExportFilenameGet()

get export file name based on signature name

    my $Filename = $SignatureObject->SignatureExportFilenameGet(
        Name => 'Signature_1',
        Format => 'YAML',
    );

=cut

sub SignatureExportFilenameGet {
    my ( $Self, %Param ) = @_;

    my $Extension = '';
    if ( $Param{Format} =~ /yml|yaml/i ) {
        $Extension = '.yaml';
    }
    return "Export_Signature$Extension" if !$Param{Name};

    my $DisplayName = 'Export_Signature_' . $Param{Name};
    $DisplayName =~ s{[^a-zA-Z0-9-_]}{_}xmsg;
    $DisplayName =~ s{_{2,}}{_}g;
    $DisplayName =~ s{_$}{};

    return "$DisplayName$Extension";
}

=head2 SignatureQueuesList()

get a list of the queues that have been linked to signature

    my %SignatureQueues = $SignatureObject->SignatureQueuesList(
        ID => 1, # mandatory
    );

Returns:

    my %Queues = (
        1 => 'queue1',
        2 => 'queue2',
    )

=cut

sub SignatureQueuesList {
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
             WHERE signature_id = ?
             ',
        Bind => [ \$Param{ID} ],
    );

    my %Queues;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        $Queues{ $Row[0] } = $Row[1];
    }

    return %Queues;
}

=head2 SignatureQueueLinkBySignature()

assign a list of queues to a signature

    my $Success = $SignatureObject->SignatureQueueLinkBySignature(
        QueueIDs => [1,2,3],
        ID       => 1,
        UserID   => 1,
    );

=cut

sub SignatureQueueLinkBySignature {
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

    my %SignatureData = $Self->SignatureGet(
        ID => $Param{ID},
    );

    # return failed status if signature does not exists
    return if !$SignatureData{ID};

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

            # update queue to be linked with new signature
            %Queue,
            SignatureID => $SignatureData{ID},
            UserID      => $Param{UserID},
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

=head2 SignatureList()

get signature list

    my %List = $SignatureObject->SignatureList(
        Valid => 0,  # optional, defaults to 1
    );

returns:

    %List = (
        '1' => 'Some Name',
        '2' => 'Some Name',
        '3' => 'Some Name',
    );

=cut

sub SignatureList {
    my ( $Self, %Param ) = @_;

    # set default value
    my $Valid = $Param{Valid} // 1;

    # create the valid list
    my $ValidIDs = join ', ', $Kernel::OM->Get('Kernel::System::Valid')->ValidIDsGet();

    # build SQL
    my $SQL = 'SELECT id, name FROM signature';

    # add WHERE statement in case Valid param is set to '1', for valid system address
    if ($Valid) {
        $SQL .= ' WHERE valid_id IN (' . $ValidIDs . ')';
    }

    # get database object
    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    # get data from database
    return if !$DBObject->Prepare(
        SQL => $SQL,
    );

    # fetch the result
    my %SignatureList;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        $SignatureList{ $Row[0] } = $Row[1];
    }

    return %SignatureList;
}

1;

=head1 TERMS AND CONDITIONS

This software is part of the OTRS project (L<https://otrs.org/>).

This software comes with ABSOLUTELY NO WARRANTY. For details, see
the enclosed file COPYING for license information (GPL). If you
did not receive this file, see L<https://www.gnu.org/licenses/gpl-3.0.txt>.

=cut
