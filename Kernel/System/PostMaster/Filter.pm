# --
# Copyright (C) 2001-2021 OTRS AG, https://otrs.com/
# Copyright (C) 2021 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see https://www.gnu.org/licenses/gpl-3.0.txt.
# --

package Kernel::System::PostMaster::Filter;

use strict;
use warnings;

use Kernel::Language              qw(Translatable);
use Kernel::System::VariableCheck qw(:all);

our @ObjectDependencies = (
    'Kernel::Config',
    'Kernel::System::DB',
    'Kernel::System::Log',
    'Kernel::System::YAML',
    'Kernel::Language',
    'Kernel::System::DynamicField',
);

=head1 NAME

Kernel::System::PostMaster::Filter

=head1 DESCRIPTION

All postmaster database filters

=head1 PUBLIC INTERFACE

=head2 new()

Don't use the constructor directly, use the ObjectManager instead:

    my $PostMasterFilterObject = $Kernel::OM->Get('Kernel::System::PostMaster::Filter');

=cut

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {};
    bless( $Self, $Type );

    return $Self;
}

=head2 FilterList()

get all filter

    my %FilterList = $PostMasterFilterObject->FilterList();

=cut

sub FilterList {
    my ( $Self, %Param ) = @_;

    # get database object
    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    return if !$DBObject->Prepare(
        SQL => 'SELECT f_name FROM postmaster_filter',
    );

    my %Data;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        $Data{ $Row[0] } = $Row[0];
    }

    return %Data;
}

=head2 FilterAdd()

add a filter

    $PostMasterFilterObject->FilterAdd(
        Name           => 'some name',
        StopAfterMatch => 0,
        Match = [
            {
                Key   => 'Subject',
                Value => '^ADV: 123',
            },
            # ...
        ],
        Not = [
            {
                Key   => 'Subject',
                Value => '1',
            },
            # ...
        ],
        Set = [
            {
                Key   => 'X-OTRS-Queue',
                Value => 'Some::Queue',
            },
            # ...
        ],
    );

=cut

sub FilterAdd {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Needed (qw(Name StopAfterMatch Match Set)) {
        if ( !defined $Param{$Needed} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Needed!"
            );
            return;
        }
    }

    # get database object
    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    my @Not = @{ $Param{Not} || [] };

    for my $Type (qw(Match Set)) {

        my @Data = @{ $Param{$Type} };

        for my $Index ( 0 .. ( scalar @Data ) - 1 ) {

            return if !$DBObject->Do(
                SQL =>
                    'INSERT INTO postmaster_filter (f_name, f_stop, f_type, f_key, f_value, f_not)'
                    . ' VALUES (?, ?, ?, ?, ?, ?)',
                Bind => [
                    \$Param{Name},         \$Param{StopAfterMatch}, \$Type,
                    \$Data[$Index]->{Key}, \$Data[$Index]->{Value}, \$Not[$Index]->{Value},
                ],
            );
        }
    }

    return 1;
}

=head2 FilterDelete()

delete a filter

    $PostMasterFilterObject->FilterDelete(
        Name => '123',
    );

=cut

sub FilterDelete {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Needed (qw(Name)) {
        if ( !defined $Param{$Needed} ) {
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
        SQL  => 'DELETE FROM postmaster_filter WHERE f_name = ?',
        Bind => [ \$Param{Name} ],
    );

    return 1;
}

=head2 FilterGet()

get filter properties, returns HASH ref Match and Set

    my %Data = $PostMasterFilterObject->FilterGet(
        Name => '132',
    );

=cut

sub FilterGet {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Needed (qw(Name)) {
        if ( !defined $Param{$Needed} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Needed!"
            );
            return;
        }
    }

    # get database object
    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    return if !$DBObject->Prepare(
        SQL =>
            'SELECT f_type, f_key, f_value, f_name, f_stop, f_not'
            . ' FROM postmaster_filter'
            . ' WHERE f_name = ?'
            . ' ORDER BY f_key, f_value',
        Bind => [ \$Param{Name} ],
    );

    my %Data;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        push @{ $Data{ $Row[0] } }, {
            Key   => $Row[1],
            Value => $Row[2],
        };
        $Data{Name}           = $Row[3];
        $Data{StopAfterMatch} = $Row[4];

        if ( $Row[0] eq 'Match' ) {
            push @{ $Data{Not} }, {
                Key   => $Row[1],
                Value => $Row[5],
            };
        }
    }

    return %Data;
}

=head2 FilterLookup()

lookup for PostMaster filter id or name

    my $ID = $PostMasterFilterObject->FilterLookup(
        Name => 'postmaster_filter',
    );

    # OR

    my $Name = $PostMasterFilterObject->FilterLookup(
        ID => 10,
    );

=cut

sub FilterLookup {
    my ( $Self, %Param ) = @_;

    my $DBObject  = $Kernel::OM->Get('Kernel::System::DB');
    my $LogObject = $Kernel::OM->Get('Kernel::System::Log');

    my $LookupValue;
    if ( $Param{Name} ) {
        return if !$DBObject->Prepare(
            SQL => 'SELECT id
                    FROM postmaster_filter
                    WHERE f_name = ?',
            Bind  => [ \$Param{Name} ],
            Limit => 1,
        );

        my @Row = $DBObject->FetchrowArray();
        $LookupValue = $Row[0];
    }
    elsif ( $Param{ID} ) {
        return if !$DBObject->Prepare(
            SQL => 'SELECT f_name
                    FROM postmaster_filter
                    WHERE id = ?',
            Bind  => [ \$Param{ID} ],
            Limit => 1,
        );

        my @Row = $DBObject->FetchrowArray();
        $LookupValue = $Row[0];
    }
    else {
        $LogObject->Log(
            Priority => 'error',
            Message  => 'Need either "ID" or "Name" parameter!',
        );
        return;
    }

    return $LookupValue;
}

=head2 FilterExport()

export a PostMaster filter

    my $ExportData = $PostMasterFilterObject->FilterExport(
        # required either Name or ExportAll
        Name                     => 'postmaster1', # required
                                                   # or
        ExportAll                => 0,             # required, possible: 0, 1
    );

returns PostMaster filters hashes in an array with data:

    my $ExportData =
    [
        {
            'Name' => 'postmaster1',
            'StopAfterMatch' => 0,
            'Match' => [{
                'Value' => '2',
                'Key' => 'Message-ID'
            }],
            'Set' => [{
                'Value' => '2',
                'Key' => 'X-OTRS-AttachmentExists'
            }],
            'Not' => [{
                'Value' => undef,
                'Key' => 'Message-ID'
            }]
        },
        {
            'Name' => 'postmaster2',
            'StopAfterMatch' => 1,
            'Match' => [{
                'Value' => '3',
                'Key' => 'Precedence'
            }],
            'Set' => [{
                'Value' => '3',
                'Key' => 'X-OTRS-AttachmentExists'
            }],
            'Not' => [{
                'Key' => 'Precedence',
                'Value' => undef
            }],
        }
    ]

=cut

sub FilterExport {
    my ( $Self, %Param ) = @_;

    my $LogObject = $Kernel::OM->Get('Kernel::System::Log');

    my $PostMasterFilterData;

    if ( $Param{ExportAll} ) {
        my %PostMasterFilterList = $Self->FilterList();

        my @Data;
        for my $ItemName ( sort keys %PostMasterFilterList ) {
            my %PostMasterFilterSingleData = $Self->FilterExportDataGet(
                Name => $ItemName,
            );

            push @Data, \%PostMasterFilterSingleData if %PostMasterFilterSingleData;
        }
        $PostMasterFilterData = \@Data;
    }
    elsif ( $Param{Name} ) {

        my $Name = $Param{Name};
        return if !$Name;

        my %PostMasterFilterSingleData = $Self->FilterExportDataGet(
            Name => $Name,
        );

        return if !%PostMasterFilterSingleData;

        $PostMasterFilterData = [ \%PostMasterFilterSingleData ];
    }
    else {
        $LogObject->Log(
            Priority => 'error',
            Message  => 'Need either "ExportAll" or "Name" parameter!',
        );
        return;
    }

    return $PostMasterFilterData;
}

=head2 FilterImport()

import a filter YAML file/content

    my $FilterImport = $PostMasterFilterObject->FilterImport(
        Content                  => $YAMLContent, # mandatory, YAML format
        OverwriteExistingFilters => 0,            # optional, possible: 0, 1
    );

Returns:

    $FilterImport = {
        Success          => 1,                                  # 1 if success or undef if operation could not
                                                                # be performed
        Message          => 'The Message to show.',             # error message
        Added            => 'Filter1, Filter2',                 # string list of Filters correctly added
        Updated          => 'Filter3, Filter4',                 # string list of Filters correctly updated
        NotUpdated       => 'Filter5, Filter6',                 # string of Filters not updated due to existing entity
                                                                # with the same name
        Errors           => 'Filter5',                          # string list of Filters that could not be added or updated
        AdditionalErrors => ['Some error occured!', 'Error2!'], # list of additional error not necessarily related to specified Filter
    };

=cut

sub FilterImport {
    my ( $Self, %Param ) = @_;

    my $LogObject  = $Kernel::OM->Get('Kernel::System::Log');
    my $YAMLObject = $Kernel::OM->Get('Kernel::System::YAML');

    for my $Needed (qw(Content)) {

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

    my $FilterData = $YAMLObject->Load(
        Data => $Param{Content},
    );

    if ( ref $FilterData ne 'ARRAY' ) {
        return {
            Success => 0,
            Message =>
                Translatable("Couldn't read Filter configuration YAML file. Please make sure the file is valid."),
        };
    }

    my @UpdatedFilters;
    my @NotUpdatedFilters;
    my @AddedFilters;
    my @FilterErrors;

    my %CurrentFilters        = $Self->FilterList();
    my %ReverseCurrentFilters = reverse %CurrentFilters;
    my %AdditionalErrors;

    FILTER:
    for my $Filter ( @{$FilterData} ) {

        next FILTER if !$Filter;
        next FILTER if ref $Filter ne 'HASH';

        if ( !$Filter->{Name} ) {
            my $StandardMessage = "One or more filters \"Name\" parameter is missing!";
            $AdditionalErrors{DataMissing} = $StandardMessage
                if !$AdditionalErrors{DataMissing};

            $LogObject->Log(
                Priority => 'error',
                Message  => $StandardMessage,
            );

            next FILTER;
        }

        my $FilterExists = $ReverseCurrentFilters{ $Filter->{Name} };
        my %Errors       = $Self->FilterInsertErrorsCheck(
            %{$Filter},
        );

        my $AddSuccess;
        if ( $Param{OverwriteExistingFilters} && $FilterExists ) {
            if ( !%Errors ) {
                my $DeleteSuccess = $Self->FilterDelete( Name => $Filter->{Name} );
                $AddSuccess = $Self->FilterAdd(
                    %{$Filter}
                ) if $DeleteSuccess;
            }

            if ($AddSuccess) {
                push @UpdatedFilters, $Filter->{Name};
            }
            else {
                push @FilterErrors, $Filter->{Name};
            }
        }
        else {
            if ($FilterExists) {
                push @NotUpdatedFilters, $Filter->{Name};
                next FILTER;
            }

            # add Filter only if validation was successful
            if ( !%Errors ) {
                my $DeleteSuccess = $Self->FilterDelete( Name => $Filter->{Name} );
                $AddSuccess = $Self->FilterAdd(
                    %{$Filter},
                ) if $DeleteSuccess;
            }

            if ($AddSuccess) {
                push @AddedFilters, $Filter->{Name};
            }
            else {
                push @FilterErrors, $Filter->{Name};
            }
        }

        # log errors
        if (%Errors) {
            my $ErrorKeyStrg = '';
            my $LimitReached;

            # create string from errors keys to better
            # understand where exactly problem occured
            KEY:
            for my $Key ( sort keys %Errors ) {
                $ErrorKeyStrg .= $Key . ':' . $Errors{$Key} . ',';

                # do not allow more than 300 symbols while logging error keys
                if ( length $ErrorKeyStrg > 300 ) {
                    $LimitReached = 1;
                    last KEY;
                }
            }

            chop $ErrorKeyStrg;
            if ($LimitReached) {
                $ErrorKeyStrg .= ' and more..';
            }

            my $ErrorMessage = "Invalid configuration for Filter with name: $Filter->{Name}. ($ErrorKeyStrg)";

            $LogObject->Log(
                Priority => 'error',
                Message  => $ErrorMessage,
            );
        }
    }

    my @FilterAdditionalErrors;

    for my $ErrorKey ( sort keys %AdditionalErrors ) {
        my $ErrorMessage = $AdditionalErrors{$ErrorKey};

        push @FilterAdditionalErrors, $ErrorMessage;
    }

    return {
        Success => 1,

        Added            => join( ', ', @AddedFilters )      || '',
        Updated          => join( ', ', @UpdatedFilters )    || '',
        NotUpdated       => join( ', ', @NotUpdatedFilters ) || '',
        Errors           => join( ', ', @FilterErrors )      || '',
        AdditionalErrors => \@FilterAdditionalErrors,
    };
}

=head2 FilterCopy()

copy a filter

    my $NewFilterName = $PostMasterFilterObject->FilterCopy(
        Name    => 'filter1', # mandatory
    );

=cut

sub FilterCopy {
    my ( $Self, %Param ) = @_;

    my $LogObject      = $Kernel::OM->Get('Kernel::System::Log');
    my $LanguageObject = $Kernel::OM->Get('Kernel::Language');

    NEEDED:
    for my $Needed (qw(Name)) {

        next NEEDED if defined $Param{$Needed};

        $LogObject->Log(
            Priority => 'error',
            Message  => "Parameter '$Needed' is needed!",
        );
        return;
    }

    my %FilterData = $Self->FilterGet(
        Name => $Param{Name},
    );
    return if !IsHashRefWithData( \%FilterData );

    # create new filter name
    my $FilterName = $LanguageObject->Translate( '%s (copy)', $FilterData{Name} );

    my $Success = $Self->FilterAdd(
        %FilterData,
        Name => $FilterName,
    );

    return $Success ? $FilterName : $Success;
}

=head2 FilterExportDataGet()

get data to export PostMaster filter

    my %PostMasterFilterData = $PostMasterFilterObject->FilterExportDataGet(
        Name => 'postmaster_filter1', # mandatory
    );

Returns:

    my %PostMasterFilterData = (
        'Name' => 'postmaster_filter1',
        'StopAfterMatch' => 0,
        'Set' => [{
            'Value' => '2',
            'Key' => 'X-OTRS-AttachmentExists'
        }],
        'Match' => [{
            'Value' => '2',
            'Key' => 'Message-ID'
        }],
        'Not' => [{
            'Value' => undef,
            'Key' => 'Message-ID'
        }]
    )

=cut

sub FilterExportDataGet {
    my ( $Self, %Param ) = @_;

    my $LogObject = $Kernel::OM->Get('Kernel::System::Log');

    NEEDED:
    for my $Needed (qw(Name)) {

        next NEEDED if defined $Param{$Needed};

        $LogObject->Log(
            Priority => 'error',
            Message  => "Parameter '$Needed' is needed!",
        );
        return;
    }

    my %PostMasterFilter = $Self->FilterGet(
        Name => $Param{Name},
    );

    return %PostMasterFilter;
}

=head2 FilterExportFilenameGet()

get export file name based on filter name

    my $Filename = $PostMasterFilterObject->FilterExportFilenameGet(
        Name => 'Filter_1',
        Format => 'YAML',
    );

=cut

sub FilterExportFilenameGet {
    my ( $Self, %Param ) = @_;

    my $Extension = '';
    if ( $Param{Format} =~ /yml|yaml/i ) {
        $Extension = '.yaml';
    }
    return "Export_PostMasterFilter$Extension" if !$Param{Name};

    my $DisplayName = 'Export_PostMasterFilter_' . $Param{Name};
    $DisplayName =~ s{[^a-zA-Z0-9-_]}{_}xmsg;
    $DisplayName =~ s{_{2,}}{_}g;
    $DisplayName =~ s{_$}{};

    return "$DisplayName$Extension";
}

=head2 FilterInsertErrorsCheck()

Perform checks for insert filter action.
Recommended to use before every add/update function or
as additional layer of validation.

    my %Errors = $PostMasterFilterObject->FilterInsertErrorsCheck(
        Match => [],
        Set => [],
        Name => 'filter',
        StopAfterMatch => 0,
    );

=cut

sub FilterInsertErrorsCheck {
    my ( $Self, %Param ) = @_;

    my @Match = @{ $Param{Match} || [] };
    my @Set   = @{ $Param{Set}   || [] };

    my %Errors;

    my %Headers = $Self->FilterHeadersGet();

    if (@Match) {
        my $InvalidCount = 0;
        MATCHITEM:
        for my $MatchItem (@Match) {
            $InvalidCount++;

            my $MatchValue = $MatchItem->{Value};
            my $MatchKey   = $MatchItem->{Key};

            if ( !length $MatchKey ) {
                $Errors{"MatchHeader${InvalidCount}Invalid"} = 'Missing';
            }
            elsif ( !$Headers{Match}{$MatchKey} ) {
                $Errors{"MatchHeader${InvalidCount}Invalid"} = 'InvalidMatchHeaderValue';
            }
            if ( !length $MatchValue ) {
                $Errors{"MatchValue${InvalidCount}Invalid"} = 'Missing';
            }

            next MATCHITEM if
                $Errors{"MatchHeader${InvalidCount}Invalid"} || $Errors{"MatchValue${InvalidCount}Invalid"};

            if ( !eval { my $Regex = qr/$MatchValue/; 1; } ) {
                $Errors{"MatchHeader${InvalidCount}Invalid"} = 'InvalidValueRegex';
                $Errors{"MatchValue${InvalidCount}Invalid"}  = 'InvalidRegex';
            }
        }
    }
    else {
        $Errors{MatchHeader1Invalid} = 'Missing';
        $Errors{MatchValue1Invalid}  = 'Missing';
    }

    if (@Set) {
        my $InvalidCount = 0;

        SETITEM:
        for my $SetItem (@Set) {
            $InvalidCount++;

            my $SetKey   = $SetItem->{Key};
            my $SetValue = $SetItem->{Value};

            if ( !length $SetKey ) {
                $Errors{"SetHeader${InvalidCount}Invalid"} = 'Missing';
            }
            elsif ( !$Headers{Set}{$SetKey} ) {
                $Errors{"SetHeader${InvalidCount}Invalid"} = 'InvalidSetHeaderValue';
            }
            if ( !length $SetValue ) {
                $Errors{"SetValue${InvalidCount}Invalid"} = 'Missing';
            }
        }
    }
    else {
        $Errors{SetHeader1Invalid} = 'Missing';
        $Errors{SetValue1Invalid}  = 'Missing';
    }

    if ( !$Param{Name} || $Param{Name} eq '' ) {
        $Errors{NameInvalid} = 'Missing';
    }

    if (
        !defined $Param{StopAfterMatch} || (
            $Param{StopAfterMatch} ne '1' && $Param{StopAfterMatch} ne '0'
        )
        )
    {
        $Errors{StopAfterMatchInvalid} = 'Missing';
    }

    return %Errors;
}

=head2 FilterHeadersGet()

get valid PostMaster headers

    my %Headers = $PostMasterFilterObject->FilterHeadersGet();

=cut

sub FilterHeadersGet {
    my ( $Self, %Param ) = @_;

    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');

    # all headers
    my @Headers = @{ $ConfigObject->Get('PostmasterX-Header') };

    # add Dynamic Field headers
    my $DynamicFields = $Kernel::OM->Get('Kernel::System::DynamicField')->DynamicFieldList(
        Valid      => 1,
        ObjectType => [ 'Ticket', 'Article' ],
        ResultType => 'HASH',
    );

    for my $DynamicField ( values %$DynamicFields ) {
        push @Headers, 'X-OTRS-DynamicField-' . $DynamicField;
        push @Headers, 'X-OTRS-FollowUp-DynamicField-' . $DynamicField;
    }

    my %MatchHeader = map { $_ => $_ } @Headers;

    $MatchHeader{Body} = 'Body';

    # otrs header
    my %SetHeader;
    for my $HeaderKey ( sort keys %MatchHeader ) {
        if ( $HeaderKey =~ /^x-otrs/i ) {
            $SetHeader{$HeaderKey} = $HeaderKey;
        }
    }

    return (
        Match => \%MatchHeader,
        Set   => \%SetHeader,
    );
}

=head2 NameExistsCheck()

return 1 if another filter with this name already exists

    $AlreadyExist = $PostMasterFilterObject->NameExistsCheck(
        Name => 'filter1', # mandatory
    );

=cut

sub NameExistsCheck {
    my ( $Self, %Param ) = @_;

    my $LogObject = $Kernel::OM->Get('Kernel::System::Log');

    NEEDED:
    for my $Needed (qw(Name)) {

        next NEEDED if defined $Param{$Needed};

        $LogObject->Log(
            Priority => 'error',
            Message  => "Parameter '$Needed' is needed!",
        );
        return;
    }

    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    return if !$DBObject->Prepare(
        SQL  => 'SELECT id FROM postmaster_filter WHERE f_name = ?',
        Bind => [ \$Param{Name} ],
    );

    while ( my @Row = $DBObject->FetchrowArray() ) {
        return 1;
    }
    return 0;
}

1;

=head1 TERMS AND CONDITIONS

This software is part of the OTRS project (L<https://otrs.org/>).

This software comes with ABSOLUTELY NO WARRANTY. For details, see
the enclosed file COPYING for license information (GPL). If you
did not receive this file, see L<https://www.gnu.org/licenses/gpl-3.0.txt>.

=cut
