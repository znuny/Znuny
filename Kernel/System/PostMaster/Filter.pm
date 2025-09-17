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

our @ObjectDependencies = (
    'Kernel::System::DB',
    'Kernel::System::Log',
);

=head1 NAME

Kernel::System::PostMaster::Filter

=head1 DESCRIPTION

All postmaster database filters

=head1 PUBLIC INTERFACE

=head2 new()

Don't use the constructor directly, use the ObjectManager instead:

    my $PMFilterObject = $Kernel::OM->Get('Kernel::System::PostMaster::Filter');

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

    my %FilterList = $PMFilterObject->FilterList();

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

    $PMFilterObject->FilterAdd(
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
                    \$Param{Name}, \$Param{StopAfterMatch}, \$Type,
                    \$Data[$Index]->{Key}, \$Data[$Index]->{Value}, \$Not[$Index]->{Value},
                ],
            );
        }
    }

    return 1;
}

=head2 FilterDelete()

delete a filter

    $PMFilterObject->FilterDelete(
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

    my %Data = $PMFilterObject->FilterGet(
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

    my $ID = $PMFilterObject->FilterLookup(
        Name => 'postmaster_filter',
    );

    # OR

    my $Name = $PMFilterObject->FilterLookup(
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

    my $ExportData = $PostMasterObject->FilterExport(
        # required either ID or ExportAll
        Name                     => 'postmaster1'  # required
                                                   # or
        ID                       => $PostMasterID, # required
                                                   # or
        ExportAll                => 0,             # required, possible: 0, 1

        UserID                   => 1,             # required
    }

returns PostMaster filters hashes in an array with data:

    my $ExportData =
    [
        {
          'Name' => 'postmaster1',
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
        }, {
          'Match' => [{
            'Value' => '3',
            'Key' => 'Precedence'
          }],
          'Not' => [{
            'Key' => 'Precedence',
            'Value' => undef
          }],
          'Name' => 'postmaster2',
          'Set' => [{
            'Value' => '3',
            'Key' => 'X-OTRS-AttachmentExists'
          }],
          'StopAfterMatch' => 0
        }
    ]

=cut

sub FilterExport {
    my ( $Self, %Param ) = @_;

    my $LogObject = $Kernel::OM->Get('Kernel::System::Log');

    my $PostMasterData;

    if ( $Param{ExportAll} ) {
        my %PostMasterList = $Self->FilterList();

        my @Data;
        for my $ItemName ( sort keys %PostMasterList ) {
            my %PostMasterSingleData = $Self->FilterExportDataGet(
                Name => $ItemName,
            );

            push @Data, \%PostMasterSingleData if %PostMasterSingleData;
        }
        $PostMasterData = \@Data;
    }
    elsif ( $Param{ID} || $Param{Name} ) {

        my $Name = $Param{Name};
        if ( !$Name ) {
            $Name = $Self->FilterLookup(
                ID => $Param{ID},
            );
        }

        return if !$Name;

        my %PostMasterSingleData = $Self->FilterExportDataGet(
            Name => $Name,
        );

        return if !%PostMasterSingleData;

        $PostMasterData = [ \%PostMasterSingleData ];
    }
    else {
        $LogObject->Log(
            Priority => 'error',
            Message  => 'Need either "ExportAll" or "ID" or "Name" parameter!',
        );
        return;
    }

    return $PostMasterData;
}

=head2 FilterExportDataGet()

get data to export PostMaster filter

    my %PostMasterData = $PostMasterObject->FilterExportDataGet(
        Name => 'postmaster1', # mandatory
    );

Returns:

    my %PostMasterData = (
      'Name' => 'postmaster1',
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

    my %PostMaster = $Self->FilterGet(
        Name => $Param{Name},
    );

    return %PostMaster;
}

1;

=head1 TERMS AND CONDITIONS

This software is part of the OTRS project (L<https://otrs.org/>).

This software comes with ABSOLUTELY NO WARRANTY. For details, see
the enclosed file COPYING for license information (GPL). If you
did not receive this file, see L<https://www.gnu.org/licenses/gpl-3.0.txt>.

=cut
