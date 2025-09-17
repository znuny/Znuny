# --
# Copyright (C) 2021 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::MSGraph;

use strict;
use warnings;

use utf8;

use LWP::UserAgent;
use HTTP::Headers;

use Kernel::System::VariableCheck qw(:all);

our @ObjectDependencies = (
    'Kernel::Config',
    'Kernel::System::Encode',
    'Kernel::System::JSON',
    'Kernel::System::Log',
);

sub new {
    my ( $Type, %Param ) = @_;

    my $Self = {%Param};
    bless( $Self, $Type );

    return $Self;
}

=head1 _GetGraphLogin()

Retrieves login string for API call:
If not 'me' or starting with 'users/' already, it will return 'users/' with login appended.

    my $GraphLogin = $MSGraphObject->_GetGraphLogin(
        Login => 'someone@example.org',
    );

=cut

sub _GetGraphLogin {
    my ( $Self, %Param ) = @_;

    my $LogObject = $Kernel::OM->Get('Kernel::System::Log');

    NEEDED:
    for my $Needed (qw(Login)) {
        next NEEDED if defined $Param{$Needed};

        $LogObject->Log(
            Priority => 'error',
            Message  => "Parameter '$Needed' is needed!",
        );
        return;
    }

    my $Login = $Param{Login};

    if ( $Login =~ m{\A(?:me|users/)} ) {
        return $Login;
    }

    $Login = "users/$Login";

    return $Login;
}

=head1 ExecuteOperation()

Executes a Graph operation and returns the (decoded) response.

    my $Response = $MSGraphObject->ExecuteOperation(
        CommunicationLogObject    => $CommunicationLogObject,
        Host                      => 'graph.microsoft.com',
        Login                     => 'someone@example.org',
        OAuth2Token               => '...',
        Operation                 => '/messages/id',
        RequestType               => 'GET', # optional; POST, DELETE, etc. Defaults to GET
        RequestHeaders            => {}, # optional, headers
        RequestData               => ..., # optional, payload of request
        JSONDecodeResponseContent => 1, # optional, defaults to 1

        # Optional; link returned by Graph for pagination.
        # If given, parameter Operation will be ignored.
        # Only for request type GET.
        NextLink => 'https://...',

        Timeout             => 60, # optional, timeout for request, default: WebUserAgent::Timeout // 15
        Proxy               => '...', # optional, default: Config WebUserAgent::Proxy
        NoProxy             => '', # optional, default: Config WebUserAgent::NoProxy
        SkipSSLVerification => 0, # optional, default: Config WebUserAgent::DisableSSLVerification
    );

    Returns 1 if request was successful but did not return any content.

=cut

sub ExecuteOperation {
    my ( $Self, %Param ) = @_;

    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');
    my $LogObject    = $Kernel::OM->Get('Kernel::System::Log');
    my $EncodeObject = $Kernel::OM->Get('Kernel::System::Encode');
    my $JSONObject   = $Kernel::OM->Get('Kernel::System::JSON');

    NEEDED:
    for my $Needed (qw(CommunicationLogObject Host Login OAuth2Token Operation RequestType)) {
        next NEEDED if defined $Param{$Needed};

        $LogObject->Log(
            Priority => 'error',
            Message  => "Parameter '$Needed' is needed!",
        );
        return;
    }

    my $UserAgent = LWP::UserAgent->new();

    # SkipSSLVerification
    my $SkipSSLVerification = $Param{SkipSSLVerification} // $ConfigObject->Get('WebUserAgent::DisableSSLVerification');
    if ($SkipSSLVerification) {
        $UserAgent->ssl_opts(
            verify_hostname => 0,
        );
    }

    # Headers
    my %Headers = %{ $Param{RequestHeaders} // {} };
    $Headers{Authorization} = 'Bearer ' . $Param{OAuth2Token};

    $UserAgent->default_headers(
        HTTP::Headers->new(%Headers),
    );

    # Timeout
    my $Timeout = $Param{Timeout} // $ConfigObject->Get('WebUserAgent::Timeout') // 15;
    $UserAgent->timeout($Timeout);

    # Proxy/NoProxy
    my $Proxy = $Param{Proxy} // $ConfigObject->Get('WebUserAgent::Proxy');
    if ($Proxy) {
        $UserAgent->proxy( [ 'http', 'https', 'ftp' ], $Proxy );
    }
    my $NoProxy = $Param{NoProxy} // $ConfigObject->Get('WebUserAgent::NoProxy');
    if ( IsStringWithData($NoProxy) ) {
        my @Hosts = split /\s*;\s*/, $NoProxy;
        @Hosts = grep { IsStringWithData($_) } @Hosts;

        $UserAgent->no_proxy(@Hosts) if @Hosts;
    }

    # User agent string
    my $UserAgentString = $ConfigObject->Get('Product') . ' ' . $ConfigObject->Get('Version');
    $UserAgent->agent($UserAgentString);

    my $Login = $Self->_GetGraphLogin(
        Login => $Param{Login},
    );

    my $URL = 'https://'
        . $Param{Host}
        . '/v1.0/'
        . $Login
        . $Param{Operation};

    # Pagination link returned by Graph
    if ( $Param{NextLink} ) {
        $URL = $Param{NextLink};
    }

    my $RequestMethod = lc $Param{RequestType};

    my $Response;
    if ( defined $Param{RequestData} ) {
        $Response = $UserAgent->$RequestMethod(
            $URL,
            ref $Param{RequestData}
            ?
                $Param{RequestData}
            :
                ( Content => $Param{RequestData} ),
        );
    }
    else {
        $Response = $UserAgent->$RequestMethod($URL);
    }

    my $ResponseStatus = $Response->status_line();

    my $ResponseContent = $Response->decoded_content();
    if ( IsStringWithData($ResponseContent) ) {
        $EncodeObject->EncodeInput( \$ResponseContent );
    }

    if ( !$Response->is_success() ) {
        my $ErrorMessage = "Error executing operation '$URL' (request type $Param{RequestType}).";
        if ( IsStringWithData($ResponseContent) ) {
            $ErrorMessage .= ": $ResponseStatus, $ResponseContent";
        }

        $Param{CommunicationLogObject}->ObjectLog(
            ObjectLogType => 'Connection',
            Priority      => 'Error',
            Key           => ref $Self,
            Value         => $ErrorMessage,
        );

        return;
    }

    $Param{CommunicationLogObject}->ObjectLog(
        ObjectLogType => 'Connection',
        Priority      => 'Debug',
        Key           => ref $Self,
        Value         => "Successfully executed operation '$URL' (request type $Param{RequestType}).",
    );

    my $JSONDecodeResponseContent = $Param{JSONDecodeResponseContent} // 1;

    # Return true value on success with undefined response content.
    return 1                if !IsStringWithData($ResponseContent);
    return $ResponseContent if !$JSONDecodeResponseContent;

    my $DecodedResponseContent = $JSONObject->Decode(
        Data => $ResponseContent,
    );

    if ( !IsHashRefWithData($DecodedResponseContent) ) {
        $Param{CommunicationLogObject}->ObjectLog(
            ObjectLogType => 'Connection',
            Priority      => 'Error',
            Key           => ref $Self,
            Value => "Failed decoding JSON encoded data of operation '$URL' (request type $Param{RequestType}).",
        );

        return;
    }

    return $DecodedResponseContent;
}

1;
