# --
# Copyright (C) 2001-2021 OTRS AG, https://otrs.com/
# Copyright (C) 2021 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see https://www.gnu.org/licenses/gpl-3.0.txt.
# --

package Kernel::System::Email::SMTP;

use strict;
use warnings;

use Net::SMTP;
use Authen::SASL qw(Perl);

our @ObjectDependencies = (
    'Kernel::Config',
    'Kernel::System::Encode',
    'Kernel::System::Log',
    'Kernel::System::OAuth2Token',
    'Kernel::System::OAuth2TokenConfig',
);

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {%Param};
    bless( $Self, $Type );

    # debug
    $Self->{Debug} = $Param{Debug} || 0;
    if ( $Self->{Debug} > 2 ) {

        # shown on STDERR
        $Self->{SMTPDebug} = 1;
    }

    ( $Self->{SMTPType} ) = ( $Type =~ m/::Email::(.*)$/i );
    $Self->{EmailModuleName} = $Self->_GetEmailModuleName();

    return $Self;
}

sub Check {
    my ( $Self, %Param ) = @_;

    $Param{CommunicationLogObject}->ObjectLogStart(
        ObjectLogType => 'Connection',
    );

    my $Return = sub {
        my %LocalParam = @_;
        $Param{CommunicationLogObject}->ObjectLogStop(
            ObjectLogType => 'Connection',
            Status        => $LocalParam{Success} ? 'Successful' : 'Failed',
        );

        return %LocalParam;
    };

    my $ReturnSuccess = sub { return $Return->( @_, Success => 1, ); };
    my $ReturnError   = sub { return $Return->( @_, Success => 0, ); };

    # get config object
    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');

    # get config data
    $Self->{FQDN}     = $ConfigObject->Get('FQDN');
    $Self->{MailHost} = $ConfigObject->Get('SendmailModule::Host')
        || die "No SendmailModule::Host found in Kernel/Config.pm";
    $Self->{SMTPPort}              = $ConfigObject->Get('SendmailModule::Port');
    $Self->{User}                  = $ConfigObject->Get('SendmailModule::AuthUser');
    $Self->{Password}              = $ConfigObject->Get('SendmailModule::AuthPassword');
    $Self->{AuthenticationType}    = $ConfigObject->Get('SendmailModule::AuthenticationType') // 'password';
    $Self->{OAuth2TokenConfigName} = $ConfigObject->Get('SendmailModule::OAuth2TokenConfigName');

    $Param{CommunicationLogObject}->ObjectLog(
        ObjectLogType => 'Connection',
        Priority      => 'Debug',
        Key           => 'Kernel::System::Email::' . $Self->{EmailModuleName},
        Value         => 'Testing connection to SMTP service (3 attempts max.).',
    );

    # 3 possible attempts to connect to the SMTP server.
    # (MS Exchange Servers have sometimes problems on port 25)
    my $SMTP;

    my $TryConnectMessage = sprintf
        "%%s: Trying to connect to '%s%s' on %s with SMTP type '%s'.",
        $Self->{MailHost},
        ( $Self->{SMTPPort} ? ':' . $Self->{SMTPPort} : '' ),
        $Self->{FQDN},
        $Self->{SMTPType};
    TRY:
    for my $Try ( 1 .. 3 ) {

        $Param{CommunicationLogObject}->ObjectLog(
            ObjectLogType => 'Connection',
            Priority      => 'Debug',
            Key           => 'Kernel::System::Email::' . $Self->{EmailModuleName},
            Value         => sprintf( $TryConnectMessage, $Try, ),
        );

        # connect to mail server
        eval {
            $SMTP = $Self->_Connect(
                MailHost  => $Self->{MailHost},
                FQDN      => $Self->{FQDN},
                SMTPPort  => $Self->{SMTPPort},
                SMTPDebug => $Self->{SMTPDebug},
            );
            return 1;
        } || do {
            my $Error = $@;
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => sprintf(
                    "SMTP, connection try %s, unexpected error captured: %s",
                    $Try,
                    $Error,
                ),
            );
        };

        last TRY if $SMTP;

        $Param{CommunicationLogObject}->ObjectLog(
            ObjectLogType => 'Connection',
            Priority      => 'Debug',
            Key           => 'Kernel::System::Email::' . $Self->{EmailModuleName},
            Value         => "$Try: Connection could not be established. Waiting for 0.3 seconds.",
        );

        # sleep 0,3 seconds;
        select( undef, undef, undef, 0.3 );    ## no critic
    }

    # return if no connect was possible
    if ( !$SMTP ) {

        $Param{CommunicationLogObject}->ObjectLog(
            ObjectLogType => 'Connection',
            Priority      => 'Error',
            Key           => 'Kernel::System::Email::' . $Self->{EmailModuleName},
            Value         => "Could not connect to host '$Self->{MailHost}'. ErrorMessage: $!",
        );

        return $ReturnError->(
            ErrorMessage => "Can't connect to $Self->{MailHost}: $!!",
        );
    }

    # Enclose SMTP in a wrapper to handle unexpected exceptions
    $SMTP = $Self->_GetSMTPSafeWrapper(
        SMTP => $SMTP,
    );

    # Set authentication to successful by default because it was the default before,
    # without the changes made here. This is needed to be able to use SMTP without any
    # configured authentication.
    my $AuthenticationSuccessful = 1;

    if (
        $Self->{AuthenticationType} eq 'password'
        && $Self->{User}
        && $Self->{Password}
        )
    {
        $Param{CommunicationLogObject}->ObjectLog(
            ObjectLogType => 'Connection',
            Priority      => 'Debug',
            Key           => 'Kernel::System::Email::' . $Self->{EmailModuleName},
            Value         => "Using SMTP authentication with user '$Self->{User}' and (hidden) password.",
        );

        $AuthenticationSuccessful = $SMTP->( 'auth', $Self->{User}, $Self->{Password} );
    }
    elsif ( $Self->{AuthenticationType} eq 'oauth2_token' ) {
        if ( !$Self->{OAuth2TokenConfigName} ) {
            return $ReturnError->(
                ErrorMessage => 'SysConfig option SendmailModule::OAuth2TokenConfigName is not set.',
                Code         => 0,
            );
        }
        my $OAuth2TokenConfigObject = $Kernel::OM->Get('Kernel::System::OAuth2TokenConfig');

        my %OAuth2TokenConfig = $OAuth2TokenConfigObject->DataGet(
            Name   => $Self->{OAuth2TokenConfigName},
            UserID => 1,
        );
        if ( !%OAuth2TokenConfig ) {
            return $ReturnError->(
                ErrorMessage => "OAuth2 token config with name '$Self->{OAuth2TokenConfigName}' could not be found.",
                Code         => 0,
            );
        }

        my $OAuth2TokenObject = $Kernel::OM->Get('Kernel::System::OAuth2Token');

        my $OAuth2Token = $OAuth2TokenObject->GetToken(
            TokenConfigID => $OAuth2TokenConfig{ $OAuth2TokenConfigObject->{Identifier} },
            UserID        => 1,
        );
        if ( !$OAuth2Token ) {
            return $ReturnError->(
                ErrorMessage =>
                    "OAuth2 token for config with name '$Self->{OAuth2TokenConfigName}' could not be retrieved.",
                Code => 0,
            );
        }

        $Param{CommunicationLogObject}->ObjectLog(
            ObjectLogType => 'Connection',
            Priority      => 'Debug',
            Key           => 'Kernel::System::Email::' . $Self->{EmailModuleName},
            Value =>
                "Using SMTP authentication with user '$Self->{User}' and OAuth2 token config '$Self->{OAuth2TokenConfigName}'.",
        );

        my $SASLObject = Authen::SASL->new(
            mechanism => 'XOAUTH2',
            callback  => {
                user         => $Self->{User},
                auth         => 'Bearer',
                access_token => $OAuth2Token,
            },
        );

        $AuthenticationSuccessful = $SMTP->( 'auth', $SASLObject );
    }

    if ( !$AuthenticationSuccessful ) {
        my $Code  = $SMTP->( 'code', );
        my $Error = $Code . ', ' . $SMTP->( 'message', );

        $SMTP->( 'quit', );

        $Param{CommunicationLogObject}->ObjectLog(
            ObjectLogType => 'Connection',
            Priority      => 'Error',
            Key           => 'Kernel::System::Email::' . $Self->{EmailModuleName},
            Value         => "SMTP authentication failed (SMTP code: $Code, ErrorMessage: $Error).",
        );

        return $ReturnError->(
            ErrorMessage => "SMTP authentication failed: $Error!",
            Code         => $Code,
        );
    }

    return $ReturnSuccess->(
        SMTP => $SMTP,
    );
}

sub Send {
    my ( $Self, %Param ) = @_;

    $Param{CommunicationLogObject}->ObjectLog(
        ObjectLogType => 'Message',
        Priority      => 'Info',
        Key           => 'Kernel::System::Email::' . $Self->{EmailModuleName},
        Value         => 'Received message for sending, validating message contents.',
    );

    # check needed stuff
    for my $Needed (qw(Header Body ToArray)) {
        if ( !$Param{$Needed} ) {

            $Param{CommunicationLogObject}->ObjectLog(
                ObjectLogType => 'Message',
                Priority      => 'Error',
                Key           => 'Kernel::System::Email::' . $Self->{EmailModuleName},
                Value         => "Need $Needed!",
            );

            return $Self->_SendError(
                %Param,
                ErrorMessage => "Need $Needed!",
            );
        }
    }
    if ( !$Param{From} ) {
        $Param{From} = '';
    }

    # connect to smtp server
    my %Result = $Self->Check(%Param);

    if ( !$Result{Success} ) {
        return $Self->_SendError( %Param, %Result, );
    }

    # set/get SMTP handle
    my $SMTP = $Result{SMTP};

    $Param{CommunicationLogObject}->ObjectLog(
        ObjectLogType => 'Message',
        Priority      => 'Debug',
        Key           => 'Kernel::System::Email::' . $Self->{EmailModuleName},
        Value         => "Sending envelope from (mail from: $Param{From}) to server.",
    );

    # set envelope from, return if from was not accepted by the server
    if ( !$SMTP->( 'mail', $Param{From}, ) ) {

        my $FullErrorMessage = sprintf(
            "Envelope from '%s' not accepted by the server: %s, %s!",
            $Param{From},
            $SMTP->( 'code', ),
            $SMTP->( 'message', ),
        );

        $Param{CommunicationLogObject}->ObjectLog(
            ObjectLogType => 'Message',
            Priority      => 'Error',
            Key           => 'Kernel::System::Email::' . $Self->{EmailModuleName},
            Value         => $FullErrorMessage,
        );

        return $Self->_SendError(
            %Param,
            ErrorMessage => $FullErrorMessage,
            SMTP         => $SMTP,
        );
    }

    TO:
    for my $To ( @{ $Param{ToArray} } ) {

        $Param{CommunicationLogObject}->ObjectLog(
            ObjectLogType => 'Message',
            Priority      => 'Debug',
            Key           => 'Kernel::System::Email::' . $Self->{EmailModuleName},
            Value         => "Sending envelope to (rcpt to: $To) to server.",
        );

        # Check if the recipient is valid
        next TO if $SMTP->( 'to', $To, );

        my $FullErrorMessage = sprintf(
            "Envelope to '%s' not accepted by the server: %s, %s!",
            $To,
            $SMTP->( 'code', ),
            $SMTP->( 'message', ),
        );

        $Param{CommunicationLogObject}->ObjectLog(
            ObjectLogType => 'Message',
            Priority      => 'Error',
            Key           => 'Kernel::System::Email::' . $Self->{EmailModuleName},
            Value         => $FullErrorMessage,
        );

        return $Self->_SendError(
            %Param,
            ErrorMessage => $FullErrorMessage,
            SMTP         => $SMTP,
        );
    }

    my $ToString = join ',', @{ $Param{ToArray} };

    # get encode object
    my $EncodeObject = $Kernel::OM->Get('Kernel::System::Encode');

    # encode utf8 header strings (of course, there should only be 7 bit in there!)
    $EncodeObject->EncodeOutput( $Param{Header} );

    # encode utf8 body strings
    $EncodeObject->EncodeOutput( $Param{Body} );

    # send data
    $Param{CommunicationLogObject}->ObjectLog(
        ObjectLogType => 'Message',
        Priority      => 'Debug',
        Key           => 'Kernel::System::Email::' . $Self->{EmailModuleName},
        Value         => "Sending message data to server.",
    );

    # Send email data by chunks because when in SSL mode, each SSL
    # frame has a maximum of 16kB (Bug #12957).
    # We send always the first 4000 characters until '$Data' is empty.
    # If any error occur while sending data to the smtp server an exception
    # is thrown and '$DataSent' will be undefined.
    my $DataSent = eval {
        my $Data      = ${ $Param{Header} } . "\n" . ${ $Param{Body} };
        my $ChunkSize = 4000;

        $SMTP->( 'data', ) || die "error starting data sending";

        while ( my $DataLength = length $Data ) {
            my $TmpChunkSize = ( $ChunkSize > $DataLength ) ? $DataLength : $ChunkSize;
            my $Chunk        = substr $Data, 0, $TmpChunkSize;

            $SMTP->( 'datasend', $Chunk, ) || die "error sending data chunk";

            $Data = substr $Data, $TmpChunkSize;
        }

        $SMTP->( 'dataend', ) || die "error ending data sending";

        return 1;
    };

    if ( !$DataSent ) {
        my $FullErrorMessage = sprintf(
            "Could not send message to server: %s, %s!",
            $SMTP->( 'code', ),
            $SMTP->( 'message', ),
        );

        $Param{CommunicationLogObject}->ObjectLog(
            ObjectLogType => 'Message',
            Priority      => 'Error',
            Key           => 'Kernel::System::Email::' . $Self->{EmailModuleName},
            Value         => $FullErrorMessage,
        );

        return $Self->_SendError(
            %Param,
            ErrorMessage => $FullErrorMessage,
            SMTP         => $SMTP,
        );
    }

    # debug
    if ( $Self->{Debug} > 2 ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'notice',
            Message  => "Sent email to '$ToString' from '$Param{From}'.",
        );
    }

    $Param{CommunicationLogObject}->ObjectLog(
        ObjectLogType => 'Message',
        Priority      => 'Info',
        Key           => 'Kernel::System::Email::' . $Self->{EmailModuleName},
        Value         => "Email successfully sent from '$Param{From}' to '$ToString'.",
    );

    return $Self->_SendSuccess(
        SMTP => $SMTP,
        %Param
    );
}

sub _Connect {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Needed (qw(MailHost FQDN)) {
        if ( !$Param{$Needed} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Needed!",
            );
            return;
        }
    }

    # Remove a possible port from the FQDN value
    my $FQDN = $Param{FQDN};
    $FQDN =~ s{:\d+}{}smx;

    my %SSLOptions = $Self->_GetSSLOptions();

    my $SMTPDefaultPort = $Self->_GetSMTPDefaultPort();
    my $SMTPPort        = $Param{SMTPPort} || $SMTPDefaultPort;

    # set up connection connection
    my $SMTP = Net::SMTP->new(
        $Param{MailHost},
        Hello => $FQDN,
        Port  => $SMTPPort,
        %SSLOptions,
        Timeout => 30,
        Debug   => $Param{SMTPDebug},
    );

    my %StartTLSOptions = $Self->_GetStartTLSOptions();
    if (%StartTLSOptions) {
        $SMTP->starttls(%StartTLSOptions);
    }

    return $SMTP;
}

sub _SendResult {
    my ( $Self, %Param ) = @_;

    my $SMTP = delete $Param{SMTP};
    $SMTP->( 'quit', ) if $SMTP;

    return {%Param};
}

sub _SendSuccess {
    my ( $Self, %Param ) = @_;
    return $Self->_SendResult(
        Success => 1,
        %Param
    );
}

sub _SendError {
    my ( $Self, %Param ) = @_;

    my $SMTP = $Param{SMTP};
    if ( $SMTP && !defined $Param{Code} ) {
        $Param{Code} = $SMTP->( 'code', );
    }

    return $Self->_SendResult(
        Success => 0,
        %Param,
        SMTPError => 1,
    );
}

sub _GetSMTPSafeWrapper {
    my ( $Self, %Param, ) = @_;

    my $SMTP = $Param{SMTP};

    return sub {
        my $Operation   = shift;
        my @LocalParams = @_;

        my $ScalarResult;
        my @ArrayResult = ();
        my $Wantarray   = wantarray;

        eval {
            if ($Wantarray) {
                @ArrayResult = $SMTP->$Operation( @LocalParams, );
            }
            else {
                $ScalarResult = $SMTP->$Operation( @LocalParams, );
            }

            return 1;
        } || do {
            my $Error = $@;
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => sprintf(
                    "Error while executing 'SMTP->%s(%s)': %s",
                    $Operation,
                    join( ',', @LocalParams ),
                    $Error,
                ),
            );
        };

        return @ArrayResult if $Wantarray;
        return $ScalarResult;
    };
}

sub _GetSMTPDefaultPort {
    my ( $Self, %Param ) = @_;

    return 25;
}

sub _GetSSLOptions {
    my ( $Self, %Param ) = @_;

    return;
}

sub _GetStartTLSOptions {
    my ( $Self, %Param ) = @_;

    return;
}

sub _GetEmailModuleName {
    my ( $Self, %Param ) = @_;

    my $PackageName = ref $Self;
    if ( $PackageName =~ m{\AKernel::System::Email::(.*)\z} ) {
        $PackageName = $1;
    }

    return $PackageName;
}

1;
