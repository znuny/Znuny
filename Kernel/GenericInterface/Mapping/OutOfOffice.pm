# --
# Copyright (C) 2021 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::GenericInterface::Mapping::OutOfOffice;

use strict;
use warnings;

use Kernel::System::VariableCheck qw(:all);

our $ObjectManagerDisabled = 1;

=head1 NAME

Kernel::GenericInterface::Mapping::OutOfOffice

=head1 SYNOPSIS

=head1 PUBLIC INTERFACE

=head2 new()

usually, you want to create an instance of this
by using Kernel::GenericInterface::Mapping->new();

=cut

sub new {
    my ( $Type, %Param ) = @_;

    my $Self = {};
    bless( $Self, $Type );

    for my $Needed (qw(DebuggerObject MappingConfig)) {
        if ( !$Param{$Needed} ) {
            return {
                Success      => 0,
                ErrorMessage => "Got no $Needed!"
            };
        }
        $Self->{$Needed} = $Param{$Needed};
    }

    return $Self;
}

=head2 Map()

perform data mapping

    my $Result = $MappingObject->Map(
        Data => {                                                                           # data payload before mapping
            SessionID                   => 'AValidSessionIDValue',                          # the ID of the user session
            UserLogin                   => 'Agent',                                         # if no SessionID is given UserLogin is required
            Password                    => 'some password',                                 # user password
            OutOfOfficeEntriesCSVString => 'CSV string with out-of-office entries to set',
        },
    );

    $Result = {
        Success         => 1,  # 0 or 1
        ErrorMessage    => '', # in case of error
        Data            => {                                                                # data payload of after mapping
            SessionID                   => 'AValidSessionIDValue',                          # the ID of the user session
            UserLogin                   => 'Agent',                                         # if no SessionID is given UserLogin is required
            Password                    => 'some password',                                 # user password
            OutOfOfficeEntriesCSVString => 'CSV string with out-of-office entries to set',
            OutOfOfficeEntries          => [
                {
                    UserLogin   => '...',
                    UserSearch  => '...',
                    UserEmail   => '...',
                    StartDate   => '...',
                    EndDate     => '...',
                    OutOfOffice => 1,
                },

                # ...
            ],
        },
    };

=cut

sub Map {
    my ( $Self, %Param ) = @_;

    my $CSVObject = $Kernel::OM->Get('Kernel::System::CSV');

    my $OutOfOfficeEntriesCSVString = $Param{Data}->{OutOfOfficeEntriesCSVString};
    if ( !defined $OutOfOfficeEntriesCSVString || !length $OutOfOfficeEntriesCSVString ) {
        return $Self->{DebuggerObject}->Error(
            Summary => 'Parameter OutOfOfficeEntriesCSVString is missing.',
        );
    }

    #
    # Parse CSV
    #

    # change line ending format to UNIX
    $OutOfOfficeEntriesCSVString =~ s{\r\n?}{\n}msg;

    # Add one new line to the end
    if ( $OutOfOfficeEntriesCSVString !~ m{\n\z}ms ) {
        $OutOfOfficeEntriesCSVString .= "\n";
    }
    else {
        # Remove multiple new lines at the end
        $OutOfOfficeEntriesCSVString =~ s{\n+\z}{\n}ms;
    }

    # Remove comments
    $OutOfOfficeEntriesCSVString =~ s{^#.*\n}{}gm;

    my $OutOfOfficeEntriesCSV = $CSVObject->CSV2Array(
        String    => $OutOfOfficeEntriesCSVString,
        Separator => ',',
    );

    if ( !IsArrayRefWithData($OutOfOfficeEntriesCSV) ) {
        return $Self->{DebuggerObject}->Error(
            Summary => 'Error while parsing CSV string of parameter OutOfOfficeEntriesCSVString.',
        );
    }

    my $HeaderColumns = shift @{$OutOfOfficeEntriesCSV};

    my @OutOfOfficeEntriesCSV;
    OUTOFOFFICEENTRYCSV:
    for my $OutOfOfficeEntryCSV ( @{$OutOfOfficeEntriesCSV} ) {
        next OUTOFOFFICEENTRYCSV if !IsArrayRefWithData($OutOfOfficeEntryCSV);

        my %OutOfOfficeEntryCSV;
        for my $ColumnIndex ( 0 .. $#{$HeaderColumns} ) {
            $OutOfOfficeEntryCSV{ $HeaderColumns->[$ColumnIndex] } = $OutOfOfficeEntryCSV->[$ColumnIndex];
        }

        push @OutOfOfficeEntriesCSV, \%OutOfOfficeEntryCSV;
    }

    if ( !@OutOfOfficeEntriesCSV ) {
        return $Self->{DebuggerObject}->Error(
            Summary => 'CSV in parameter OutOfOfficeEntriesCSVString does not contain any entries.',
        );
    }

    #
    # Assemble out-of-office entries
    #

    my @OutOfOfficeEntries;

    OUTOFOFFICEENTRYCSV:
    for my $OutOfOfficeEntryCSV (@OutOfOfficeEntriesCSV) {
        if ( !IsHashRefWithData($OutOfOfficeEntryCSV) ) {
            $Self->{DebuggerObject}->Notice(
                Summary => 'Out-of-office entry is not a hash with data!'
            );
            next OUTOFOFFICEENTRYCSV;
        }

        my %OutOfOfficeEntry = %{$OutOfOfficeEntryCSV};

        $OutOfOfficeEntry{UserEmail}   //= $OutOfOfficeEntry{EMail};
        $OutOfOfficeEntry{EndDate}     //= $OutOfOfficeEntry{EndTime};
        $OutOfOfficeEntry{StartDate}   //= $OutOfOfficeEntry{StartTime};
        $OutOfOfficeEntry{OutOfOffice} //= $OutOfOfficeEntry{Enabled};

        DATEPART:
        for my $DatePart (qw(EndDate StartDate)) {
            next DATEPART if !$OutOfOfficeEntry{$DatePart};
            next DATEPART if $OutOfOfficeEntry{$DatePart} !~ m{(\d{2}).(\d{2}).(\d{4}) \s \d{2}:\d{2}:\d{2}}x;

            $OutOfOfficeEntry{$DatePart} = "$3-$2-$1";
        }

        my %OutOfOfficeMapping = (
            yes => 1,
            no  => 0,
        );

        if (
            defined $OutOfOfficeEntry{OutOfOffice}
            && defined $OutOfOfficeMapping{ $OutOfOfficeEntry{OutOfOffice} }
            )
        {
            $OutOfOfficeEntry{OutOfOffice} = $OutOfOfficeMapping{ $OutOfOfficeEntry{OutOfOffice} };
        }

        push @OutOfOfficeEntries, {
            UserLogin   => $OutOfOfficeEntry{UserLogin},
            UserSearch  => $OutOfOfficeEntry{UserSearch},
            UserEmail   => $OutOfOfficeEntry{UserEmail},
            StartDate   => $OutOfOfficeEntry{StartDate},
            EndDate     => $OutOfOfficeEntry{EndDate},
            OutOfOffice => $OutOfOfficeEntry{OutOfOffice},
        };
    }

    my $Result = {
        Success => 1,
        Data    => {
            %{ $Param{Data} },    # preserve original data because it also contains login credentials
            OutOfOfficeEntries => \@OutOfOfficeEntries,
        },
    };

    return $Result;
}

1;
