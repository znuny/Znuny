# --
# Copyright (C) 2001-2021 OTRS AG, https://otrs.com/
# Copyright (C) 2021-2022 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see https://www.gnu.org/licenses/gpl-3.0.txt.
# --

package Kernel::System::MailAccount::POP3;

use strict;
use warnings;

use parent qw(Kernel::System::MailAccount::Base);

use Net::POP3;
use Net::POP3::XOAuth2;

our @ObjectDependencies = (
    'Kernel::Config',
    'Kernel::System::CommunicationLog',
    'Kernel::System::Log',
    'Kernel::System::Main',
    'Kernel::System::OAuth2Token',
    'Kernel::System::PostMaster',
);

sub new {
    my ( $Type, %Param ) = @_;

    my $Self = {%Param};
    bless( $Self, $Type );

    # reset limit
    $Self->{Limit} = 0;

    $Self->{MailAccountModuleName} = $Self->_GetMailAccountModuleName();

    return $Self;
}

sub Connect {
    my ( $Self, %Param ) = @_;

    my $ConfigObject      = $Kernel::OM->Get('Kernel::Config');
    my $OAuth2TokenObject = $Kernel::OM->Get('Kernel::System::OAuth2Token');

    NEEDED:
    for my $Needed (qw(Login Host Timeout Debug)) {
        next NEEDED if defined $Param{$Needed};

        return (
            Successful => 0,
            Message    => "Need $Needed!",
        );
    }

    # Check authentication type and its needed params.
    my $AuthenticationType = $Param{AuthenticationType} // 'password';

    if ( $AuthenticationType eq 'password' ) {
        if ( !defined $Param{Password} ) {
            return (
                Successful => 0,
                Message    => 'Param Password is missing.',
            );
        }
    }
    elsif ( $AuthenticationType eq 'oauth2_token' ) {
        if ( !defined $Param{OAuth2TokenConfigID} ) {
            return (
                Successful => 0,
                Message    => 'Param OAuth2TokenConfigID is missing.',
            );
        }
    }
    else {
        return (
            Successful => 0,
            Message    => "Authentication type $AuthenticationType is not supported.",
        );
    }

    my %SSLOptions = $Self->_GetSSLOptions();

    # connect to host
    my $PopObject = Net::POP3->new(
        $Param{Host},
        Timeout => $Param{Timeout},
        Debug   => $Param{Debug},
        %SSLOptions,
    );

    if ( !$PopObject ) {
        return (
            Successful => 0,
            Message    => "$Self->{MailAccountModuleName}: Can't connect to $Param{Host}"
        );
    }

    my %StartTLSOptions = $Self->_GetStartTLSOptions();
    if (%StartTLSOptions) {
        $PopObject->starttls(%StartTLSOptions);
    }

    # authentication
    my $NOM;
    if ( $AuthenticationType eq 'password' ) {
        $NOM = $PopObject->login( $Param{Login}, $Param{Password} );
    }
    elsif ( $AuthenticationType eq 'oauth2_token' ) {
        my $OAuth2Token = $OAuth2TokenObject->GetToken(
            TokenConfigID => $Param{OAuth2TokenConfigID},
            UserID        => 1,
        );
        if ( !$OAuth2Token ) {
            return (
                Successful => 0,
                Message    => 'OAuth2 token could not be retrieved.',
            );
        }

        # Check if auth header and token must be sent separately for this host.
        # This mainly is being used by Office 365 and Outlook.
        # Also see:
        # https://docs.microsoft.com/en-us/Exchange/client-developer/legacy-protocols/
        #     how-to-authenticate-an-imap-pop-smtp-application-by-using-oauth#pop-protocol-exchange
        my $SplitOAuth2MethodAndTokenHosts
            = $ConfigObject->Get('MailAccount::POP3::Auth::SplitOAuth2MethodAndToken::Hosts') // [];
        my %SplitOAuth2MethodAndTokenHosts = map { lc $_ => 1 } @{$SplitOAuth2MethodAndTokenHosts};
        my $SplitOAuth2MethodAndToken      = $SplitOAuth2MethodAndTokenHosts{ lc $Param{Host} } ? 1 : 0;

        $NOM = $PopObject->xoauth2( $Param{Login}, $OAuth2Token, $SplitOAuth2MethodAndToken );
    }

    if ( !defined $NOM ) {
        $PopObject->quit();
        return (
            Successful => 0,
            Message    => "$Self->{MailAccountModuleName}: Auth for user $Param{Login}/$Param{Host} failed!",
        );
    }

    return (
        Successful => 1,
        PopObject  => $PopObject,
        NOM        => $NOM,
        Type       => $Self->{MailAccountModuleName},
    );
}

sub _Fetch {
    my ( $Self, %Param ) = @_;

    # fetch again if still messages on the account
    MESSAGE:
    while (1) {
        return       if !$Self->_Fetch(%Param);
        last MESSAGE if $Self->{Reconnect};
    }
    return 1;
}

sub Fetch {
    my ( $Self, %Param ) = @_;

    # start a new incoming communication
    my $CommunicationLogObject = $Kernel::OM->Create(
        'Kernel::System::CommunicationLog',
        ObjectParams => {
            Transport   => 'Email',
            Direction   => 'Incoming',
            AccountType => $Param{Type},
            AccountID   => $Param{ID},
        }
    );

    $CommunicationLogObject->ObjectLogStart(
        ObjectLogType => 'Connection',
    );

    # check needed stuff
    for my $Needed (qw(Login Password Host Trusted QueueID)) {
        if ( !defined $Param{$Needed} ) {
            $CommunicationLogObject->ObjectLog(
                ObjectLogType => 'Connection',
                Priority      => 'Error',
                Key           => 'Kernel::System::MailAccount::' . $Self->{MailAccountModuleName},
                Value         => "$Needed not defined!",
            );

            $CommunicationLogObject->ObjectLogStop(
                ObjectLogType => 'Connection',
                Status        => 'Failed',
            );

            $CommunicationLogObject->CommunicationStop( Status => 'Failed' );

            return;
        }
    }

    for my $Needed (qw(Login Password Host)) {
        if ( !$Param{$Needed} ) {
            $CommunicationLogObject->ObjectLog(
                ObjectLogType => 'Connection',
                Priority      => 'Error',
                Key           => 'Kernel::System::MailAccount::' . $Self->{MailAccountModuleName},
                Value         => "Need $Needed!",
            );

            $CommunicationLogObject->ObjectLogStop(
                ObjectLogType => 'Connection',
                Status        => 'Failed',
            );

            $CommunicationLogObject->CommunicationStop( Status => 'Failed' );

            return;
        }
    }

    my $Debug = $Param{Debug} || 0;
    my $Limit = $Param{Limit} || 5000;
    my $CMD   = $Param{CMD}   || 0;

    # get config object
    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');

    # MaxEmailSize
    my $MaxEmailSize = $ConfigObject->Get('PostMasterMaxEmailSize') || 1024 * 6;

    # MaxPopEmailSession
    my $MaxPopEmailSession = $ConfigObject->Get('PostMasterReconnectMessage') || 20;

    my $FetchCounter = 0;

    $Self->{Reconnect} = 0;

    $CommunicationLogObject->ObjectLog(
        ObjectLogType => 'Connection',
        Priority      => 'Debug',
        Key           => 'Kernel::System::MailAccount::' . $Self->{MailAccountModuleName},
        Value         => "Open connection to '$Param{Host}' ($Param{Login}).",
    );

    my %Connect = ();
    eval {
        %Connect = $Self->Connect(
            Host                => $Param{Host},
            Login               => $Param{Login},
            Password            => $Param{Password},
            AuthenticationType  => $Param{AuthenticationType},     # might be undef
            OAuth2TokenConfigID => $Param{OAuth2TokenConfigID},    # might be undef
            Timeout             => 15,
            Debug               => $Debug
        );
        return 1;
    } || do {
        my $Error = $@;
        %Connect = (
            Successful => 0,
            Message =>
                "Something went wrong while trying to connect to '$Self->{MailAccountModuleName} => $Param{Login}/$Param{Host}': ${ Error }",
        );
    };

    if ( !$Connect{Successful} ) {
        $CommunicationLogObject->ObjectLog(
            ObjectLogType => 'Connection',
            Priority      => 'Error',
            Key           => 'Kernel::System::MailAccount::' . $Self->{MailAccountModuleName},
            Value         => $Connect{Message},
        );

        $CommunicationLogObject->ObjectLogStop(
            ObjectLogType => 'Connection',
            Status        => 'Failed',
        );

        $CommunicationLogObject->CommunicationStop(
            Status => 'Failed',
        );

        return;
    }

    my $POPOperation = sub {
        my $Operation = shift;
        my @Params    = @_;

        my $POPObject = $Connect{PopObject};
        my $ScalarResult;
        my @ArrayResult = ();
        my $Wantarray   = wantarray;

        eval {
            if ($Wantarray) {
                @ArrayResult = $POPObject->$Operation( @Params, );
            }
            else {
                $ScalarResult = $POPObject->$Operation( @Params, );
            }

            return 1;
        } || do {
            my $Error = $@;
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => sprintf(
                    "Error while executing 'POP->%s(%s)': %s",
                    $Operation,
                    join( ',', @Params ),
                    $Error,
                ),
            );
        };

        return @ArrayResult if $Wantarray;
        return $ScalarResult;
    };

    my $NOM      = $Connect{NOM};
    my $AuthType = $Connect{Type};

    my $ConnectionWithErrors = 0;
    my $MessagesWithError    = 0;

    # fetch messages
    if ( !$NOM ) {

        if ($CMD) {
            print "$AuthType: No messages ($Param{Login}/$Param{Host})\n";
        }

        $CommunicationLogObject->ObjectLog(
            ObjectLogType => 'Connection',
            Priority      => 'Notice',
            Key           => 'Kernel::System::MailAccount::' . $Self->{MailAccountModuleName},
            Value         => "No messages available ($Param{Login}/$Param{Host}).",
        );
    }
    else {

        my $MessageList  = $POPOperation->( 'list', );
        my $MessageCount = $NOM eq '0E0' ? 0 : $NOM;

        $CommunicationLogObject->ObjectLog(
            ObjectLogType => 'Connection',
            Priority      => 'Notice',
            Key           => 'Kernel::System::MailAccount::' . $Self->{MailAccountModuleName},
            Value         => "$MessageCount messages available for fetching ($Param{Login}/$Param{Host}).",
        );

        MESSAGE_NO:
        for my $Messageno ( sort { $a <=> $b } keys %{$MessageList} ) {

            # check if reconnect is needed
            if ( $FetchCounter >= $MaxPopEmailSession ) {

                $Self->{Reconnect} = 1;

                if ($CMD) {
                    print "$AuthType: Reconnect Session after $MaxPopEmailSession messages...\n";
                }

                $CommunicationLogObject->ObjectLog(
                    ObjectLogType => 'Connection',
                    Priority      => 'Info',
                    Key           => 'Kernel::System::MailAccount::' . $Self->{MailAccountModuleName},
                    Value         => "Reconnect session after $MaxPopEmailSession messages.",
                );

                last MESSAGE_NO;
            }

            if ($CMD) {
                print "$AuthType: Message $Messageno/$NOM ($Param{Login}/$Param{Host})\n";
            }

            # determine (human readable) message size
            my $MessageSize;

            if ( $MessageList->{$Messageno} > ( 1024 * 1024 ) ) {
                $MessageSize = sprintf "%.1f MB", ( $MessageList->{$Messageno} / ( 1024 * 1024 ) );
            }
            elsif ( $MessageList->{$Messageno} > 1024 ) {
                $MessageSize = sprintf "%.1f KB", ( $MessageList->{$Messageno} / 1024 );
            }
            else {
                $MessageSize = $MessageList->{$Messageno} . ' Bytes';
            }

            $CommunicationLogObject->ObjectLog(
                ObjectLogType => 'Connection',
                Priority      => 'Debug',
                Key           => 'Kernel::System::MailAccount::' . $Self->{MailAccountModuleName},
                Value         => "Prepare fetching of message '$Messageno/$NOM' (Size: $MessageSize) from server.",
            );

            # check maximum message size
            if ( $MessageList->{$Messageno} > ( $MaxEmailSize * 1024 ) ) {

                # convert size to KB, log error
                my $MessageSizeKB = int( $MessageList->{$Messageno} / (1024) );
                my $ErrorMessage  = "$AuthType: Can't fetch email $NOM from $Param{Login}/$Param{Host}. "
                    . "Email too big ($MessageSizeKB KB - max $MaxEmailSize KB)!";

                $CommunicationLogObject->ObjectLog(
                    ObjectLogType => 'Connection',
                    Priority      => 'Error',
                    Key           => 'Kernel::System::MailAccount::' . $Self->{MailAccountModuleName},
                    Value =>
                        "Cannot fetch message '$Messageno/$NOM' with size '$MessageSize' ($MessageSizeKB KB)."
                        . "Maximum allowed message size is '$MaxEmailSize KB'!",
                );

                $ConnectionWithErrors = 1;
            }
            else {

                # safety protection
                $FetchCounter++;
                my $FetchDelay = ( $FetchCounter % 20 == 0 ? 1 : 0 );
                if ( $FetchDelay && $CMD ) {

                    print "$AuthType: Safety protection: waiting 1 second before processing next mail...\n";

                    $CommunicationLogObject->ObjectLog(
                        ObjectLogType => 'Connection',
                        Priority      => 'Debug',
                        Key           => 'Kernel::System::MailAccount::' . $Self->{MailAccountModuleName},
                        Value => 'Safety protection: waiting 1 second before fetching next message from server.',
                    );

                    sleep 1;
                }

                # get message (header and body)
                my $Lines = $POPOperation->( 'get', $Messageno, );

                if ( !$Lines ) {

                    my $ErrorMessage = "$AuthType: Can't process mail, email no $Messageno is empty!";

                    $CommunicationLogObject->ObjectLog(
                        ObjectLogType => 'Connection',
                        Priority      => 'Error',
                        Key           => 'Kernel::System::MailAccount::' . $Self->{MailAccountModuleName},
                        Value         => "Could not fetch message '$Messageno', answer from server was empty.",
                    );

                    $ConnectionWithErrors = 1;
                }
                else {

                    $CommunicationLogObject->ObjectLog(
                        ObjectLogType => 'Connection',
                        Priority      => 'Debug',
                        Key           => 'Kernel::System::MailAccount::' . $Self->{MailAccountModuleName},
                        Value         => "Message '$Messageno' successfully received from server.",
                    );

                    $CommunicationLogObject->ObjectLogStart( ObjectLogType => 'Message' );
                    my $MessageStatus = 'Successful';

                    my $PostMasterObject = $Kernel::OM->Create(
                        'Kernel::System::PostMaster',
                        ObjectParams => {
                            %{$Self},
                            Email                  => $Lines,
                            Trusted                => $Param{Trusted} || 0,
                            Debug                  => $Debug,
                            CommunicationLogObject => $CommunicationLogObject,
                        },
                    );

                    my @Return    = eval { return $PostMasterObject->Run( QueueID => $Param{QueueID} || 0 ); };
                    my $Exception = $@ || undef;

                    if ( !$Return[0] ) {
                        $MessagesWithError += 1;

                        if ($Exception) {
                            $Kernel::OM->Get('Kernel::System::Log')->Log(
                                Priority => 'error',
                                Message  => 'Exception while processing mail: ' . $Exception,
                            );
                        }

                        my $File = $Self->_ProcessFailed( Email => $Lines );

                        my $ErrorMessage = "$AuthType: Can't process mail, mail saved ("
                            . "$File, report it on https://github.com/znuny/Znuny/issues)!";

                        $CommunicationLogObject->ObjectLog(
                            ObjectLogType => 'Message',
                            Priority      => 'Error',
                            Key           => 'Kernel::System::MailAccount::' . $Self->{MailAccountModuleName},
                            Value =>
                                "Could not process message. Raw mail saved ($File, report it on https://github.com/znuny/Znuny/issues)!",
                        );

                        $MessageStatus = 'Failed';
                    }

                    undef $PostMasterObject;

                    $CommunicationLogObject->ObjectLogStop(
                        ObjectLogType => 'Message',
                        Status        => $MessageStatus,
                    );
                }

                # mark email to delete if it got processed
                $POPOperation->( 'delete', $Messageno, );

                $CommunicationLogObject->ObjectLog(
                    ObjectLogType => 'Connection',
                    Priority      => 'Debug',
                    Key           => 'Kernel::System::MailAccount::' . $Self->{MailAccountModuleName},
                    Value         => "Message '$Messageno' marked for deletion.",
                );

                # check limit
                $Self->{Limit}++;
                if ( $Self->{Limit} >= $Limit ) {
                    $Self->{Reconnect} = 0;
                    last MESSAGE_NO;
                }

            }

            if ($CMD) {
                print "\n";
            }
        }
    }

    $CommunicationLogObject->ObjectLog(
        ObjectLogType => 'Connection',
        Priority      => 'Info',
        Key           => 'Kernel::System::MailAccount::' . $Self->{MailAccountModuleName},
        Value         => "Fetched $FetchCounter message(s) from server ($Param{Login}/$Param{Host}).",
    );

    $POPOperation->( 'quit', );

    if ($CMD) {
        print "$AuthType: Connection to $Param{Host} closed.\n\n";
    }

    $CommunicationLogObject->ObjectLog(
        ObjectLogType => 'Connection',
        Priority      => 'Debug',
        Key           => 'Kernel::System::MailAccount::' . $Self->{MailAccountModuleName},
        Value         => "Connection to '$Param{Host}' closed.",
    );

    $CommunicationLogObject->ObjectLogStop(
        ObjectLogType => 'Connection',
        Status        => $ConnectionWithErrors ? 'Failed' : 'Successful',
    );

    $CommunicationLogObject->CommunicationStop(
        Status => $ConnectionWithErrors || $MessagesWithError ? 'Failed' : 'Successful',
    );

    # return if everything is done
    return 1;
}

sub _ProcessFailed {
    my ( $Self, %Param ) = @_;

    if ( !defined $Param{Email} ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => "'Email' not defined!"
        );
        return;
    }

    # get content of email
    my $Content;
    for my $Line ( @{ $Param{Email} } ) {
        $Content .= $Line;
    }

    my $MainObject = $Kernel::OM->Get('Kernel::System::Main');

    my $Home = $Kernel::OM->Get('Kernel::Config')->Get('Home') . '/var/spool/';
    my $MD5  = $MainObject->MD5sum(
        String => \$Content,
    );
    my $Location = $Home . 'problem-email-' . $MD5;

    return $MainObject->FileWrite(
        Location   => $Location,
        Content    => \$Content,
        Mode       => 'binmode',
        Type       => 'Local',
        Permission => '640',
    );
}

1;
