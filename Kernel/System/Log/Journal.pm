# --
# Copyright (C) 2001-2021 OTRS AG, https://otrs.com/
# Copyright (C) 2021 Znuny GmbH, https://znuny.org/
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
use feature 'signatures';

our @ObjectDependencies = (
    'Kernel::Config',
);

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {};
    bless( $Self, $Type );

    # get config object
    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');

    # get logfile location
    $Self->{LogSockPath} = $ConfigObject->Get('LogModule::JournalLogPath') || '/run/systemd/journal/socket';

    return $Self;
}

sub Serialize ($k, $v) {
    return uc($k) . "\n" . pack("Q<", length($v)) . $v . "\n";
}

sub Log {
    my ( $Self, %Param ) = @_;

    my $LogSocket = IO::Socket::UNIX->new(
        Type => SOCK_DGRAM(),
        Peer => $Self->{LogSockPath},
    ) or {
        print STDERR "\n";
        print STDERR " Can't connect to $Self->{LogSockPath}: $!\n";
        print STDERR "\n";
        return;
    }

    my $LogMessage = ""
    keys(%Param)
    while(my($key, $value) = each(%Param)) {
        $LogMessage = $LogMessage . Serialize($key, $value)
    }

    print $LogSocket $LogMessage;

    close($LogSocket);

    return;
}

1;
