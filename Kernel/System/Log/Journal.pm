# --
# Copyright (C) 2026 B1 Systems GmbH, https://b1-systems.de
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see https://www.gnu.org/licenses/gpl-3.0.txt.
# --
## nofilter(TidyAll::Plugin::Znuny::CodeStyle::STDERRCheck)

package Kernel::System::Log::Journal;

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
      )
      or {
          print STDERR "\n Can not connect to "
        . $Self->{LogSockPath}
        . ": $!\n\n";
        return;
      };

    my $LogMessage = "";
    keys(%Param);
    while ( my ( $key, $value ) = each(%Param) ) {
        $key = $KeyTranslate{$key} || $key;
        $LogMessage .= Serialize( $key, $value );
    }

    print $LogSocket $LogMessage;

    close($LogSocket);

    return;
}

1;
