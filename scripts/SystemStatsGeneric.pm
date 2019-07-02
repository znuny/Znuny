# --
# Copyright (C) 2001-2019 OTRS AG, https://otrs.com/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see https://www.gnu.org/licenses/gpl-3.0.txt.
# --
#
# Description: copy this file into Kernel/Modules/ and change the
# config options ($Title, $DetailText, $SQL, ...) below.
#
# Add a html link to your OTRS agent frontend, e. g.
# <a href="$Env{"Baselink"}Action=SystemStatsGeneric">Your Stats</a>
# and you will get your printable pure SQL stats.
#
# If you want a CSV file add the param CSV=1 to your html link e. g.
# <a href="$Env{"Baselink"}Action=SystemStatsGeneric&CSV=1">Your CVS Stats File</a>
#
# --

package Kernel::Modules::SystemStatsGeneric;

use strict;
use warnings;

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {%Param};
    bless( $Self, $Type );

    # check all needed objects
    for (qw(ParamObject DBObject QueueObject LayoutObject ConfigObject LogObject TimeObject)) {
        die "Got no $_" if !$Self->{$_};
    }
    $Self->{CSV} = $Self->{ParamObject}->GetParam( Param => 'CSV' ) || 0;
    return $Self;
}

sub Run {
    my ( $Self, %Param ) = @_;

    # ------------------------------------------------------------------------------ #
    # Config options!
    # ------------------------------------------------------------------------------ #
    my $Title      = 'Name of Stats';
    my $DetailText = 'Some text about the content! $Data{"Records"} database records - ($Text{"Stand"}: $Env{"Time"})';
    my $CSVFile    = 'csv-file';
    my $SQLLimit   = 5000;
    my $SQL        = qq|SELECT * FROM users|;
    my $Group      = 'stats';

    # ------------------------------------------------------------------------------ #

    # permission check (user need to be rw in group stats)
    if ( !$Self->{"UserIsGroup[$Group]"} || $Self->{"UserIsGroup[$Group]"} ne 'Yes' ) {
        return $Self->{LayoutObject}->NoPermission(
            Message => "You have to be in the $Group group!"
        );
    }

    # starting with page ...
    my $CSVBody    = '';
    my $OutputBody = '';
    my $Records    = 0;
    my @HeadData   = ();
    my @GlobalData = ();

    # get table columns names
    my $sth = $Self->{DBObject}->{dbh}->prepare($SQL);
    $sth->execute;
    my $names = $sth->{NAME};
    @HeadData = @{$names};

    # get table columns data
    $Self->{DBObject}->Prepare(
        SQL   => $SQL,
        Limit => $SQLLimit
    );
    while ( my @Row = $Self->{DBObject}->FetchrowArray() ) {
        push( @GlobalData, \@Row );
    }

    # fillup colomn names
    if ( !$Self->{CSV} ) {
        $OutputBody .= '<table border="0" width="100%" cellspacing="0" cellpadding="3">';
        $OutputBody .= "<tr>\n";
    }
    for my $col (@HeadData) {
        if ( $Self->{CSV} ) {
            $CSVBody .= "$col;";
        }
        else {
            $OutputBody .= "<th class=\"item\">$col</th>\n";
        }
    }
    if ( $Self->{CSV} ) {
        $CSVBody .= "\n";
    }
    else {
        $OutputBody .= "</tr>\n";
    }

    # fillup columns data
    for my $RowTmp (@GlobalData) {
        $Records++;
        my @Row = @{$RowTmp};
        if ( !$Self->{CSV} ) {
            $OutputBody .= "<tr>\n";
        }
        for (@Row) {
            if ( $Self->{CSV} ) {
                $CSVBody .= "$_;";
            }
            else {
                $OutputBody .= "<td class=\"small\">$_</td>\n";
            }
        }
        if ( $Self->{CSV} ) {
            $CSVBody .= "\n";
        }
        else {
            $OutputBody .= "</tr>\n";
        }
    }

    # return HTML or CSV page
    if ( $Self->{CSV} ) {
        my $CSV = $Self->{LayoutObject}->Output(
            Data => {
                Title      => $Title,
                DetailText => $DetailText,
                Records    => $Records
            },
            Template =>
                '$Data{"Title"};$Text{"generated by"} $Env{"UserFirstname"} $Env{"UserLastname"} ($Env{"UserEmail"}) - $Env{"Time"}'
        ) . ";\n";
        $CSV .= $Self->{LayoutObject}->Output(
            Data => {
                Title      => $Title,
                DetailText => $DetailText,
                Records    => $Records
            },
            Template => $DetailText,
        ) . ";\n";

        # return csv to download
        my ( $s, $m, $h, $D, $M, $Y ) = $Self->{TimeObject}->SystemTime2Date(
            SystemTime => $Self->{TimeObject}->SystemTime(),
        );
        return $Self->{LayoutObject}->Attachment(
            Filename    => "$CSVFile" . "_" . "$Y-$M-$D" . "_" . "$h-$m.csv",
            ContentType => "text/csv",
            Content     => "\n" . $CSV . $CSVBody,
        );
    }
    else {
        my $Output = $Self->{LayoutObject}->PrintHeader(
            Title => $Title,
            Width => 900
        );
        $Output .= $Self->{LayoutObject}->Output(
            Data => {
                Title      => $Title,
                DetailText => $DetailText,
                Records    => $Records
            },
            Template => '
        <table border="0" cellspacing="1" cellpadding="0" width="100%">
            <tr>
                <td><font size="+1"><b>$Data{"Title"}</font></b></td>
            </tr>
        </table>
        <br>
        <p>
            $Data{"DetailText"}
        </p>
        '
        );

        # return html
        $Output .= $OutputBody . $Self->{LayoutObject}->Output( Template => '</table><br>' );
        $Output .= $Self->{LayoutObject}->PrintFooter();
        return $Output;
    }
}
1;