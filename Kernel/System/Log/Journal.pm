# --
# Copyright (C) 2021 Znuny GmbH, https://znuny.org/
# Copyright (C) 2026 B1 Systems GmbH, https://b1-systems.de
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --
## nofilter(TidyAll::Plugin::Znuny::CodeStyle::STDERRCheck)

package Kernel::System::Log::Journal;

use utf8;
use strict;
use warnings;
use IO::Socket::UNIX;

my %KeyTranslate = (
    "Line"   => "CODE_LINE",
    "Module" => "CODE_FUNC",
);

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {};
    bless( $Self, $Type );

    # get logfile location
    $Self->{LogSockPath} = '/run/systemd/journal/socket';

    return $Self;
}

sub Serialize {
    my ( $k, $v ) = @_;
    return uc($k) . "\n" . pack( "Q<", length($v) ) . $v . "\n";
}

sub Log {
    my ( $Self, %Param ) = @_;

    my $LogSocket = IO::Socket::UNIX->new(
        Type => SOCK_DGRAM(),
        Peer => $Self->{LogSockPath},
    );

    my $LogMessage = "";
    keys(%Param);
    while ( my ( $Key, $Value ) = each(%Param) ) {
        $Key = $KeyTranslate{$Key} || $Key;
        $LogMessage .= Serialize( $Key, $Value );
    }

    print $LogSocket $LogMessage;

    close($LogSocket);

    return;
}

1;
