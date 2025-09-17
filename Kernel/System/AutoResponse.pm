# --
# Copyright (C) 2001-2021 OTRS AG, https://otrs.com/
# Copyright (C) 2021 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see https://www.gnu.org/licenses/gpl-3.0.txt.
# --

package Kernel::System::AutoResponse;

use strict;
use warnings;

use Kernel::System::VariableCheck qw(:all);
use Kernel::Language qw(Translatable);

our @ObjectDependencies = (
    'Kernel::System::DB',
    'Kernel::System::Log',
    'Kernel::System::SystemAddress',
    'Kernel::System::Valid',
    'Kernel::Language',
    'Kernel::System::Cache',
    'Kernel::System::Queue',
    'Kernel::System::YAML',
);

=head1 NAME

Kernel::System::AutoResponse - auto response lib

=head1 DESCRIPTION

All auto response functions. E. g. to add auto response or other functions.

=head1 PUBLIC INTERFACE

=head2 new()

create an object

    my $AutoResponseObject = $Kernel::OM->Get('Kernel::System::AutoResponse');

=cut

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {};
    bless( $Self, $Type );

    return $Self;
}

=head2 AutoResponseAdd()

add auto response with attributes

    my $AutoResponseID = $AutoResponseObject->AutoResponseAdd(
        Name        => 'Some::AutoResponse',
        ValidID     => 1,
        Subject     => 'Some Subject..',
        Response    => 'Auto Response Test....',
        ContentType => 'text/plain',
        AddressID   => 1,
        TypeID      => 1,
        UserID      => 123,
    );

=cut

sub AutoResponseAdd {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Argument (qw(Name ValidID Response ContentType AddressID TypeID UserID Subject)) {
        if ( !$Param{$Argument} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Argument!",
            );
            return;
        }
    }

    # check if a auto-response with this name already exits
    return if !$Self->_NameExistsCheck( Name => $Param{Name} );

    # get database object
    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    # insert into database
    return if !$DBObject->Do(
        SQL => '
            INSERT INTO auto_response
                (name, valid_id, comments, text0, text1, type_id, system_address_id,
                content_type, create_time, create_by, change_time, change_by)
            VALUES
                (?, ?, ?, ?, ?, ?, ?, ?, current_timestamp, ?, current_timestamp, ?)',
        Bind => [
            \$Param{Name}, \$Param{ValidID}, \$Param{Comment}, \$Param{Response},
            \$Param{Subject},     \$Param{TypeID}, \$Param{AddressID},
            \$Param{ContentType}, \$Param{UserID}, \$Param{UserID},
        ],
    );

    # get id
    return if !$DBObject->Prepare(
        SQL => '
            SELECT id
            FROM auto_response
            WHERE name = ?
                AND type_id = ?
                AND system_address_id = ?
                AND content_type = ?
                AND create_by = ?',
        Bind => [
            \$Param{Name}, \$Param{TypeID}, \$Param{AddressID},
            \$Param{ContentType}, \$Param{UserID},
        ],
        Limit => 1,
    );

    # fetch the result
    my $ID;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        $ID = $Row[0];
    }

    return $ID;
}

=head2 AutoResponseGet()

get auto response with attributes

    my %Data = $AutoResponseObject->AutoResponseGet(
        ID => 123,
    );

=cut

sub AutoResponseGet {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    if ( !$Param{ID} ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => 'Need ID!',
        );
        return;
    }

    # get database object
    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    # select
    return if !$DBObject->Prepare(
        SQL => '
            SELECT id, name, valid_id, comments, text0, text1, type_id, system_address_id,
                content_type, create_time, create_by, change_time, change_by
            FROM auto_response WHERE id = ?',
        Bind  => [ \$Param{ID} ],
        Limit => 1,
    );

    my %Data;
    while ( my @Data = $DBObject->FetchrowArray() ) {

        %Data = (
            ID          => $Data[0],
            Name        => $Data[1],
            ValidID     => $Data[2],
            Comment     => $Data[3],
            Response    => $Data[4],
            Subject     => $Data[5],
            TypeID      => $Data[6],
            AddressID   => $Data[7],
            ContentType => $Data[8] || 'text/plain',
            CreateTime  => $Data[9],
            CreateBy    => $Data[10],
            ChangeTime  => $Data[11],
            ChangeBy    => $Data[12],
        );
    }

    my %Types = $Self->AutoResponseTypeList();
    $Data{Type} = $Types{ $Data{TypeID} };

    return %Data;
}

=head2 AutoResponseUpdate()

update auto response with attributes

    my $Success = $AutoResponseObject->AutoResponseUpdate(
        ID          => 123,
        Name        => 'Some::AutoResponse',
        ValidID     => 1,
        Subject     => 'Some Subject..',
        Response    => 'Auto Response Test....',
        ContentType => 'text/plain',
        AddressID   => 1,
        TypeID      => 1,
        UserID      => 123,
    );

=cut

sub AutoResponseUpdate {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Argument (qw(ID Name ValidID Response AddressID ContentType UserID Subject)) {
        if ( !$Param{$Argument} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Argument!",
            );
            return;
        }
    }

    # check if a auto-response with this name already exits
    return if !$Self->_NameExistsCheck(
        Name => $Param{Name},
        ID   => $Param{ID},
    );

    # update the database
    return if !$Kernel::OM->Get('Kernel::System::DB')->Do(
        SQL => '
            UPDATE auto_response
            SET name = ?, text0 = ?, comments = ?, text1 = ?, type_id = ?,
                system_address_id = ?, content_type = ?, valid_id = ?,
                change_time = current_timestamp, change_by = ?
            WHERE id = ?',
        Bind => [
            \$Param{Name}, \$Param{Response}, \$Param{Comment}, \$Param{Subject}, \$Param{TypeID},
            \$Param{AddressID}, \$Param{ContentType}, \$Param{ValidID},
            \$Param{UserID}, \$Param{ID},
        ],
    );

    return 1;
}

=head2 AutoResponseDelete()

deletes an auto response from the database by it's id

    $AutoResponseObject->AutoResponseDelete(
        ID     => 1,
        UserID => 1,
    );

=cut

sub AutoResponseDelete {
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
            Message  => "Can't delete auto response with ID '$Param{ID}'!",
        );
        return;
    }

    # check if auto response exists
    my %Check = $Self->AutoResponseGet(
        ID => $Param{ID},
    );
    if ( !%Check ) {
        $LogObject->Log(
            Priority => 'error',
            Message  => "Can't delete auto response with ID '$Param{ID}'. Auto response does not exist!",
        );
        return;
    }

    # delete link between auto response and queues
    my $DeleteOK = $DBObject->Do(
        SQL  => 'DELETE FROM queue_auto_response WHERE auto_response_id = ?',
        Bind => [ \$Param{ID} ],
    );

    # error handling
    if ( !$DeleteOK ) {
        $LogObject->Log(
            Priority => 'error',
            Message  => "Can't delete queue_auto_response with ID '$Param{ID}'!",
        );
        return;
    }

    # delete auto response
    $DeleteOK = $DBObject->Do(
        SQL  => 'DELETE FROM auto_response WHERE id = ?',
        Bind => [ \$Param{ID} ],
    );

    # error handling
    if ( !$DeleteOK ) {
        $LogObject->Log(
            Priority => 'error',
            Message  => "Can't delete auto_response with ID '$Param{ID}'!",
        );
        return;
    }

    $LogObject->Log(
        Priority => 'notice',
        Message  => "AutoResponseEvent AutoResponse '$Check{Name}' deleted (UserID=$Param{UserID}).",
    );

    return 1;
}

=head2 AutoResponseExport()

export an auto response

    my $ExportData = $AutoResponseObject->AutoResponseExport(
        # required either ID or ExportAll
        ID                       => $AutoResponseID,
        ExportAll                => 0,               # possible: 0, 1

        UserID                   => 1,               # required
    }

returns AutoResponse hashes in an array with data:

    my $ExportData = [
        {
            'ContentType' => 'text/plain',
            'ChangeTime' => '2024-07-16 13:17:20',
            'Address' => 'some-mail@outlook.com',
            'ValidID' => 1,
            'Type' => 'auto reject',
            'Queues' => {},
            'TypeID' => 2,
            'Subject' => 'Your email has been rejected! (RE: <OTRS_CUSTOMER_SUBJECT[24]>)',
            'AddressID' => 1,
            'Name' => 'default reject (after follow-up and rejected of a closed ticket)',
            'CreateBy' => 1,
            'Response' => 'Your previous ticket is closed.

-- Your follow-up has been rejected. --

Please create a new ticket.

Your Znuny Team
',
            'Comment' => '',
            'ChangeBy' => 1,
            'ID' => 587,
            'CreateTime' => '2024-07-16 13:15:50'
        },
        {
            'ContentType' => 'text/html',
            'ChangeTime' => '2024-07-16 13:16:27',
            'Address' => 'some-mail@outlook.com',
            'ValidID' => 1,
            'Type' => 'auto follow up',
            'Queues' => {},
            'TypeID' => 3,
            'Subject' => 'RE: <OTRS_CUSTOMER_SUBJECT[24]>',
            'AddressID' => 1,
            'Name' => 'default follow-up (after a ticket follow-up has been added) (copy)',
            'CreateBy' => 1,
            'Response' => 'Thanks for your follow-up email<br />
<br />
You wrote:<br />
&lt;OTRS_CUSTOMER_EMAIL[6]&gt;<br />
<br />
Your email will be answered by a human ASAP.<br />
<br />
Have fun with Znuny!<br />
<br />
Your Znuny Team',
            'Comment' => '',
            'ChangeBy' => 1,
            'ID' => 590,
            'CreateTime' => '2024-07-16 13:16:27'
        }
    ];


=cut

sub AutoResponseExport {
    my ( $Self, %Param ) = @_;

    my $LogObject = $Kernel::OM->Get('Kernel::System::Log');

    my $AutoResponseData;

    if ( $Param{ExportAll} ) {
        my %AutoResponseList = $Self->AutoResponseList(
            Valid => 0,
        );

        my @Data;
        for my $ItemID ( sort keys %AutoResponseList ) {
            my %AutoResponseSingleData = $Self->AutoResponseExportDataGet(
                ID => $ItemID,
            );

            push @Data, \%AutoResponseSingleData if %AutoResponseSingleData;
        }
        $AutoResponseData = \@Data;
    }
    elsif ( $Param{ID} ) {
        my %AutoResponseSingleData = $Self->AutoResponseExportDataGet(
            ID => $Param{ID},
        );

        return if !%AutoResponseSingleData;

        $AutoResponseData = [ \%AutoResponseSingleData ];
    }
    else {
        $LogObject->Log(
            Priority => 'error',
            Message  => 'Need either "ExportAll" or "ID" parameter!',
        );
        return;
    }

    return $AutoResponseData;
}

=head2 AutoResponseImport()

import an auto response via YAML content

    my $ImportResult = $AutoResponseObject->AutoResponseImport(
        Content                        => $YAMLContent, # mandatory, YAML format
        OverwriteExistingAutoResponses => 0,            # optional, possible: 0, 1
        UserID                         => 1,            # mandatory
    );

Returns:

    $Result = {
        Success          => 1,                                  # 1 if success or undef if operation could not
                                                                # be performed
        Message          => 'The Message to show.',             # error message
        Added            => 'AutoResponse1, AutoResponse2',     # string of AutoResponses correctly added
        Updated          => 'AutoResponse3, AutoResponse4',     # string of AutoResponses correctly updated
        NotUpdated       => 'AutoResponse5, AutoResponse6',     # string of AutoResponses not updated due to existing entity
                                                                # with the same name
        Errors           => 'AutoResponse5',                    # string of AutoResponses that could not be added or updated
        AdditionalErrors => ['Some error occured!', 'Error2!'], # list of additional error not necessarily related to specified AutoResponse
    };

=cut

sub AutoResponseImport {
    my ( $Self, %Param ) = @_;

    my $SystemAddressObject = $Kernel::OM->Get('Kernel::System::SystemAddress');
    my $YAMLObject          = $Kernel::OM->Get('Kernel::System::YAML');
    my $LogObject           = $Kernel::OM->Get('Kernel::System::Log');
    my $QueueObject         = $Kernel::OM->Get('Kernel::System::Queue');

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

    my $AutoResponseData = $YAMLObject->Load(
        Data => $Param{Content},
    );

    if ( ref $AutoResponseData ne 'ARRAY' ) {
        return {
            Success => 0,
            Message =>
                Translatable("Couldn't read auto response configuration file. Please make sure the file is valid."),
        };
    }

    my @UpdatedAutoResponses;
    my @NotUpdatedAutoResponses;
    my @AddedAutoResponses;
    my @AutoResponseErrors;

    my %CurrentAutoResponses = $Self->AutoResponseList(
        %Param,
    );
    my %ReverseCurrentAutoResponses = reverse %CurrentAutoResponses;

    my %AutoResponseType = $Self->AutoResponseTypeList(
        Valid => 0,
    );

    my %ReverseAutoResponseType = reverse %AutoResponseType;
    my %AdditionalErrors;

    AUTO_RESPONSE:
    for my $AutoResponse ( @{$AutoResponseData} ) {

        next AUTO_RESPONSE if !$AutoResponse;
        next AUTO_RESPONSE if ref $AutoResponse ne 'HASH';

        for my $Parameter (qw (Name Address)) {
            if ( !$AutoResponse->{$Parameter} ) {
                my $StandardMessage = "One or more auto responses \"$Parameter\" parameter is missing!";
                $AdditionalErrors{DataMissing} = $StandardMessage
                    if !$AdditionalErrors{DataMissing};

                my $LogMessage;
                if ( $AutoResponse->{Name} ) {
                    $LogMessage =
                        "Auto response \"$AutoResponse->{Name}\" parameter \"$Parameter\" is missing!";
                    push @AutoResponseErrors, $AutoResponse->{Name};
                }
                else {
                    $LogMessage = $StandardMessage;
                }

                $LogObject->Log(
                    Priority => 'error',
                    Message  => $LogMessage,
                );

                next AUTO_RESPONSE;
            }
        }

        # link system address by name
        my $SystemAddressID = $SystemAddressObject->SystemAddressLookup(
            Name => $AutoResponse->{Address},
        );

        if ( !$SystemAddressID ) {
            $LogObject->Log(
                Priority => 'error',
                Message  => "Specified system address $AutoResponse->{Address} does not exist!",
            );
            push @AutoResponseErrors, $AutoResponse->{Name};
            next AUTO_RESPONSE;
        }

        $AutoResponse->{AddressID} = $SystemAddressID;

        # link type by name
        my $TypeID = $ReverseAutoResponseType{ $AutoResponse->{Type} };

        if ( !$TypeID ) {
            $LogObject->Log(
                Priority => 'error',
                Message  => "Specified auto response type $AutoResponse->{Type} does not exist!",
            );
            push @AutoResponseErrors, $AutoResponse->{Name};
            next AUTO_RESPONSE;
        }

        $AutoResponse->{TypeID} = $TypeID;

        # link queues by name
        my $Queues = delete $AutoResponse->{Queues};
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
                                = "Auto response $AutoResponse->{Name} import data contains linked queues that do not have a name.";
                        }
                        else {
                            $ShowQueues = 1;
                            $QueueErrorMessage
                                = "Auto response $AutoResponse->{Name} import data contains linked queues that do not exist.";
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
                push @AutoResponseErrors, $AutoResponse->{Name};
                next AUTO_RESPONSE;
            }
        }

        my $Success;
        my $LinkedDataSuccess  = 1;
        my $AutoResponseExists = $ReverseCurrentAutoResponses{ $AutoResponse->{Name} };

        if ( $Param{OverwriteExistingAutoResponses} && $AutoResponseExists ) {
            my $AutoResponseID = $ReverseCurrentAutoResponses{ $AutoResponse->{Name} };
            $Success = $Self->AutoResponseUpdate(
                %{$AutoResponse},
                ID     => $AutoResponseID,
                UserID => $Param{UserID},
            );

            if ($Success) {
                $LinkedDataSuccess = $Self->AutoResponseQueueLinkByAutoResponse(
                    QueueIDs => \@QueuesToLink,
                    ID       => $AutoResponseID,
                    UserID   => 1,
                );

                push @UpdatedAutoResponses, $AutoResponse->{Name};
            }
        }
        else {
            if ($AutoResponseExists) {
                push @NotUpdatedAutoResponses, $AutoResponse->{Name};
                next AUTO_RESPONSE;
            }

            # now add the AutoResponse
            my $AutoResponseID = $Self->AutoResponseAdd(
                %{$AutoResponse},
                UserID => $Param{UserID},
            );

            $Success = $AutoResponseID;

            if ($AutoResponseID) {
                $LinkedDataSuccess = $Self->AutoResponseQueueLinkByAutoResponse(
                    QueueIDs => \@QueuesToLink,
                    ID       => $AutoResponseID,
                    UserID   => 1,
                );

                push @AddedAutoResponses, $AutoResponse->{Name};
            }
        }

        # indicate error when entity wasn't imported at all or there are some
        # issues with linked data from the import file or for some
        # other reason data can't be linked correctly
        if ( !$Success || $QueueContainsError || !$LinkedDataSuccess ) {
            push @AutoResponseErrors, $AutoResponse->{Name};
        }
    }

    my @AutoResponseAdditionalErrors;

    for my $ErrorKey ( sort keys %AdditionalErrors ) {
        my $ErrorMessage = $AdditionalErrors{$ErrorKey};

        push @AutoResponseAdditionalErrors, $ErrorMessage;
    }

    return {
        Success          => 1,
        Added            => join( ', ', @AddedAutoResponses ) || '',
        Updated          => join( ', ', @UpdatedAutoResponses ) || '',
        NotUpdated       => join( ', ', @NotUpdatedAutoResponses ) || '',
        Errors           => join( ', ', @AutoResponseErrors ) || '',
        AdditionalErrors => \@AutoResponseAdditionalErrors,
    };
}

=head2 AutoResponseCopy()

copy an auto response without linking it to any queue

    my $NewAutoResponseID = $AutoResponseObject->AutoResponseCopy(
        ID     => 1, # mandatory
        UserID => 1, # mandatory
    );

=cut

sub AutoResponseCopy {
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

    my %AutoResponseData = $Self->AutoResponseGet(
        ID     => $Param{ID},
        UserID => $Param{UserID},
    );
    return if !IsHashRefWithData( \%AutoResponseData );

    # create new auto response name
    my $AutoResponseName = $LanguageObject->Translate( '%s (copy)', $AutoResponseData{Name} );

    my $NewAutoResponseID = $Self->AutoResponseAdd(
        %AutoResponseData,
        Name   => $AutoResponseName,
        UserID => $Param{UserID},
    );

    return $NewAutoResponseID;
}

=head2 AutoResponseGetByTypeQueueID()

get a hash with data from Auto Response and it's corresponding System Address

    my %QueueAddressData = $AutoResponseObject->AutoResponseGetByTypeQueueID(
        QueueID => 3,
        Type    => 'auto reply/new ticket',
    );

Return::

    my %QueueAddressData(

        # Auto Response Data
        'Text'            => 'Your ZNUNY TeamZNUNY! answered by a human asap.',
        'Subject'         => 'New ticket has been created! (RE: <ZNUNY_CUSTOMER_SUBJECT[24]>)',
        'ContentType'     => 'text/plain',
        'SystemAddressID' => '1',
        'AutoResponseID'  => '1',

        # System Address Data
        'ID'              => '1',
        'Name'            => 'znuny@localhost',
        'Address'         => 'znuny@localhost',
        'Realname'        => 'ZNUNY System',
        'Comment'         => 'Standard Address.',
        'ValidID'         => '1',
        'QueueID'         => '1',
        'CreateTime'      => '2010-03-16 21:24:03',
        'ChangeTime'      => '2010-03-16 21:24:03',

    );

=cut

sub AutoResponseGetByTypeQueueID {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Argument (qw(QueueID Type)) {
        if ( !$Param{$Argument} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Argument!",
            );
            return;
        }
    }

    # get database object
    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    # SQL query
    return if !$DBObject->Prepare(
        SQL => "
            SELECT ar.text0, ar.text1, ar.content_type, ar.system_address_id, ar.id
            FROM auto_response_type art, auto_response ar, queue_auto_response qar
            WHERE ar.valid_id IN ( ${\(join ', ', $Kernel::OM->Get('Kernel::System::Valid')->ValidIDsGet())} )
                AND qar.queue_id = ?
                AND art.id = ar.type_id
                AND qar.auto_response_id = ar.id
                AND art.name = ?",
        Bind => [
            \$Param{QueueID},
            \$Param{Type},
        ],
        Limit => 1,
    );

    # fetch the result
    my %Data;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        $Data{Text}            = $Row[0];
        $Data{Subject}         = $Row[1];
        $Data{ContentType}     = $Row[2] || 'text/plain';
        $Data{SystemAddressID} = $Row[3];
        $Data{AutoResponseID}  = $Row[4];
    }

    # return if no auto response is configured
    return if !%Data;

    # get sender attributes
    my %Address = $Kernel::OM->Get('Kernel::System::SystemAddress')->SystemAddressGet(
        ID => $Data{SystemAddressID},
    );

    # COMPAT: 2.1
    $Data{Address} = $Address{Name};

    # return both, sender attributes and auto response attributes
    return ( %Address, %Data );
}

=head2 AutoResponseExportDataGet()

get data to export auto response

    my %AutoResponseData = $AutoResponseObject->AutoResponseExportDataGet(
        ID               => 1, # mandatory
    );

Returns:

    my %AutoResponseData = (
        'ContentType' => 'text/plain',
        'Address' => 'main@domain.com',
        'CreateTime' => '2024-07-17 10:07:32',
        'Queues' => {
            '4' => 'Misc',
            '3' => 'Junk',
            '1' => 'Postmaster'
        },
        'TypeID' => 1,
        'Subject' => 'RE: <OTRS_CUSTOMER_SUBJECT[24]>',
        'Type' => 'auto reply',
        'ChangeTime' => '2024-07-23 10:10:07',
        'Name' => 'default reply (after new ticket has been created2)',
        'Comment' => '',
        'ValidID' => 1,
        'AddressID' => 1,
        'ID' => 915,
        'Response' => 'This is a demo text which is send to every inquiry.
It could contain something like:

Thanks for your email. A new ticket has been created.

You wrote:
<OTRS_CUSTOMER_EMAIL[6]>

Your email will be answered by a human ASAP

Have fun with Znuny! :-)

Your Znuny Team
',
        'ChangeBy' => 1,
        'CreateBy' => 1
    );

=cut

sub AutoResponseExportDataGet {
    my ( $Self, %Param ) = @_;

    my $LogObject           = $Kernel::OM->Get('Kernel::System::Log');
    my $SystemAddressObject = $Kernel::OM->Get('Kernel::System::SystemAddress');

    NEEDED:
    for my $Needed (qw(ID)) {

        next NEEDED if defined $Param{$Needed};

        $LogObject->Log(
            Priority => 'error',
            Message  => "Parameter '$Needed' is needed!",
        );
        return;
    }

    my %AutoResponse = $Self->AutoResponseGet(
        ID => $Param{ID},
    );

    return if !%AutoResponse || ( exists $AutoResponse{Type} && keys %AutoResponse == 1 );

    my %AutoResponseQueuesList = $Self->AutoResponseQueuesList(
        ID => $Param{ID},
    );

    my $AddressName = $SystemAddressObject->SystemAddressLookup(
        SystemAddressID => $AutoResponse{AddressID},
    );

    $AutoResponse{Address} = $AddressName;

    my %ExportData = ( %AutoResponse, Queues => \%AutoResponseQueuesList );

    return %ExportData;
}

=head2 AutoResponseExportFilenameGet()

get export file name based on auto response name

    my $Filename = $AutoResponseObject->AutoResponseExportFilenameGet(
        Name => 'autoresponse_1',
        Format => 'YAML',
    );

=cut

sub AutoResponseExportFilenameGet {
    my ( $Self, %Param ) = @_;

    my $Extension = '';
    if ( $Param{Format} =~ /yml|yaml/i ) {
        $Extension = '.yaml';
    }
    return "Export_AutoResponse$Extension" if !$Param{Name};

    my $DisplayName = 'Export_AutoResponse_' . $Param{Name};
    $DisplayName =~ s{[^a-zA-Z0-9-_]}{_}xmsg;
    $DisplayName =~ s{_{2,}}{_}g;
    $DisplayName =~ s{_$}{};

    return "$DisplayName$Extension";
}

=head2 AutoResponseQueuesList()

get a list of the queues that have been linked to auto response

    my %AutoResponseQueues = $AutoResponseObject->AutoResponseQueuesList(
        ID => 1, # mandatory
    );

Returns:

    my %Queues = (
        1 => 'queue1',
        2 => 'queue2',
    )

=cut

sub AutoResponseQueuesList {
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
            'SELECT qar.queue_id, q.name
             FROM queue_auto_response qar, queue q
             WHERE qar.queue_id = q.id AND qar.auto_response_id = ?
             ',
        Bind => [ \$Param{ID} ],
    );

    my %Queues;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        $Queues{ $Row[0] } = $Row[1];
    }

    return %Queues;
}

=head2 AutoResponseWithoutQueue()

get a list of the Queues that do not have Auto Response

    my %AutoResponseWithoutQueue = $AutoResponseObject->AutoResponseWithoutQueue();

Return example:

    my %Queues = (
        1 => 'Some Name',
        2 => 'Some Name',
    );

=cut

sub AutoResponseWithoutQueue {
    my ( $Self, %Param ) = @_;

    # get DB object
    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    my %QueueData;

    # SQL query
    return if !$DBObject->Prepare(
        SQL =>
            'SELECT q.id, q.name
             FROM queue q
             LEFT OUTER JOIN queue_auto_response qar on q.id = qar.queue_id
             WHERE qar.queue_id IS NULL '
            . "AND q.valid_id IN (${\(join ', ', $Kernel::OM->Get('Kernel::System::Valid')->ValidIDsGet())})"
    );

    # fetch the result
    while ( my @Row = $DBObject->FetchrowArray() ) {
        $QueueData{ $Row[0] } = $Row[1];
    }

    return %QueueData;
}

=head2 AutoResponseList()

get a list of the auto responses

    my %AutoResponse = $AutoResponseObject->AutoResponseList(
        Valid   => 1,                 # (optional) default 1
        TypeID  => 1,                 # (optional) Auto Response type ID
    );

Return example:

    my %AutoResponse = (
        '1' => 'default reply (after new ticket has been created)',
        '2' => 'default reject (after follow up and rejected of a closed ticket)',
        '3' => 'default follow up (after a ticket follow up has been added)',
    );

=cut

sub AutoResponseList {
    my ( $Self, %Param ) = @_;

    # get database object
    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    my $Valid = $Param{Valid} // 1;

    # create sql
    my $SQL = "SELECT ar.id, ar.name FROM auto_response ar";
    my ( @SQLWhere, @Bind );

    if ($Valid) {
        push @SQLWhere, "ar.valid_id IN ( ${\(join ', ', $Kernel::OM->Get('Kernel::System::Valid')->ValidIDsGet())} )";
    }

    # if there is TypeID, select only AutoResponses by that AutoResponse type
    if ( defined $Param{TypeID} ) {
        push @SQLWhere, "ar.type_id = ?";
        push @Bind,     \$Param{TypeID};
    }

    if (@SQLWhere) {
        $SQL .= " WHERE " . join( ' AND ', @SQLWhere );
    }

    # select
    return if !$DBObject->Prepare(
        SQL  => $SQL,
        Bind => \@Bind,
    );

    my %Data;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        $Data{ $Row[0] } = $Row[1];
    }

    return %Data;
}

=head2 AutoResponseTypeList()

get a list of the Auto Response Types

    my %AutoResponseType = $AutoResponseObject->AutoResponseTypeList(
        Valid => 1,     # (optional) default 1
    );

Return example:

    my %AutoResponseType = (
        '1' => 'auto reply',
        '2' => 'auto reject',
        '3' => 'auto follow up',
        '4' => 'auto reply/new ticket',
        '5' => 'auto remove',
    );

=cut

sub AutoResponseTypeList {
    my ( $Self, %Param ) = @_;

    my $Valid = $Param{Valid} // 1;

    # get database object
    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    # create sql
    my $SQL = 'SELECT id, name FROM auto_response_type ';
    if ($Valid) {
        $SQL
            .= "WHERE valid_id IN ( ${\(join ', ', $Kernel::OM->Get('Kernel::System::Valid')->ValidIDsGet())} )";
    }

    # select
    return if !$DBObject->Prepare( SQL => $SQL );

    my %Data;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        $Data{ $Row[0] } = $Row[1];
    }

    return %Data;
}

=head2 AutoResponseQueue()

assigns a list of auto-responses to a queue

    my $Success = $AutoResponseObject->AutoResponseQueue(
        QueueID         => 1,
        AutoResponseIDs => [1,2,3],
        UserID          => 1,
    );

=cut

sub AutoResponseQueue {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Argument (qw(QueueID AutoResponseIDs UserID)) {
        if ( !$Param{$Argument} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Argument!",
            );
            return;
        }
    }

    # get database object
    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    # store queue:auto response relations
    return if !$DBObject->Do(
        SQL  => 'DELETE FROM queue_auto_response WHERE queue_id = ?',
        Bind => [ \$Param{QueueID} ],
    );

    NEWID:
    for my $NewID ( @{ $Param{AutoResponseIDs} } ) {

        next NEWID if !$NewID;

        $DBObject->Do(
            SQL => '
                INSERT INTO queue_auto_response (queue_id, auto_response_id,
                    create_time, create_by, change_time, change_by)
                VALUES
                    (?, ?, current_timestamp, ?, current_timestamp, ?)',
            Bind => [
                \$Param{QueueID},
                \$NewID,
                \$Param{UserID},
                \$Param{UserID},
            ],
        );
    }

    return 1;
}

=head2 AutoResponseQueueLinkByAutoResponse()

assigns a list of queues to a auto response

    my $Success = $AutoResponseObject->AutoResponseQueueLinkByAutoResponse(
        QueueIDs => [1,2,3],
        ID       => 1,
        UserID   => 1,
    );

=cut

sub AutoResponseQueueLinkByAutoResponse {
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

    my %AutoResponseData = $Self->AutoResponseGet(
        ID => $Param{ID},
    );

    # return failed status if auto response does not exists
    return if !$AutoResponseData{ID};

    # delete all previous relations between auto response and it's queues
    return if !$DBObject->Do(
        SQL  => 'DELETE FROM queue_auto_response WHERE auto_response_id = ?',
        Bind => [ \$Param{ID} ],
    );

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

    # get type of auto-response
    my $AutoResponseTypeID = $AutoResponseData{TypeID};

    # get all linked data related to queues that are about to be linked with selected auto response
    my $SQLIn = $DBObject->QueryInCondition(
        Key    => 'queue_auto_response.queue_id',
        Values => $Param{QueueIDs},
    );

    my $SQL = 'SELECT id, queue_id, auto_response_id
               FROM queue_auto_response WHERE ' . $SQLIn;

    return if !$DBObject->Prepare(
        SQL => $SQL,
    );

    my @LinkedData;

    while ( my @Data = $DBObject->FetchrowArray() ) {
        push @LinkedData, {
            ID             => $Data[0],
            QueueID        => $Data[1],
            AutoResponseID => $Data[2],
        };
    }

    # clear linked data between auto response queues that have the same auto response
    # type of auto-response that will be linked with those queues
    # there should be no case where single queue contains multiple linked auto-responses
    # of the same type
    my @AutoResponseQueueResetIDs;
    for my $Data (@LinkedData) {

        my %Data = $Self->AutoResponseGet(
            ID => $Data->{AutoResponseID},
        );

        my $TypeID = $Data{TypeID};

        if ( $TypeID == $AutoResponseTypeID ) {
            push @AutoResponseQueueResetIDs, $Data->{ID};
        }
    }

    if ( scalar @AutoResponseQueueResetIDs ) {
        my $SQLInReset = $DBObject->QueryInCondition(
            Key       => 'queue_auto_response.id',
            Values    => \@AutoResponseQueueResetIDs,
            QuoteType => 'Integer',
        );

        return if !$DBObject->Do(
            SQL => 'DELETE FROM queue_auto_response WHERE ' . $SQLInReset,
        );
    }

    # assign linked data
    NEWID:
    for my $NewID ( @{ $Param{QueueIDs} } ) {

        next NEWID if !$NewID;

        $DBObject->Do(
            SQL => '
                INSERT INTO queue_auto_response (queue_id, auto_response_id,
                    create_time, create_by, change_time, change_by)
                VALUES
                    (?, ?, current_timestamp, ?, current_timestamp, ?)',
            Bind => [
                \$NewID,
                \$Param{ID},
                \$Param{UserID},
                \$Param{UserID},
            ],
        );
    }

    return 1;
}

=begin Internal:

=head2 _NameExistsCheck()

return if another auto-response with this name already exits

    $AutoResponseObject->_NameExistsCheck(
        Name => 'Some::AutoResponse',
        ID   => 1, # optional
    );

=cut

sub _NameExistsCheck {
    my ( $Self, %Param ) = @_;

    # get database object
    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    return if !$DBObject->Prepare(
        SQL  => 'SELECT id FROM auto_response WHERE name = ?',
        Bind => [ \$Param{Name} ],
    );

    # fetch the result
    my $Flag;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        if ( !$Param{ID} || $Param{ID} ne $Row[0] ) {
            $Flag = 1;
        }
    }

    if ($Flag) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => "An auto-response with the name '$Param{Name}' already exists.",
        );
        return;
    }

    return 1;
}

=end Internal:

=cut

1;

=head1 TERMS AND CONDITIONS

This software is part of the OTRS project (L<https://otrs.org/>).

This software comes with ABSOLUTELY NO WARRANTY. For details, see
the enclosed file COPYING for license information (GPL). If you
did not receive this file, see L<https://www.gnu.org/licenses/gpl-3.0.txt>.

=cut
