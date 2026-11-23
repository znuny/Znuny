# --
# Copyright (C) 2021 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::Auth::SAML::Request;

use strict;
use warnings;
use utf8;

our $ObjectManagerDisabled = 1;

use Kernel::System::VariableCheck qw(:all);

use LWP::UserAgent;
use Net::SAML2;

sub new {
    my ( $Type, %Param ) = @_;

    my $Self = {};
    bless( $Self, $Type );

    $Self->{Count}  = $Param{Count};
    $Self->{Config} = $Param{Config};

    return $Self;
}

sub CreateURL {
    my ( $Self, %Param ) = @_;

    my $LogObject = $Kernel::OM->Get('Kernel::System::Log');

    $Self->{RequestID} = undef;

    my $IdP = $Self->_BuildIdP();
    return if !$IdP;

    my $SSOUrl = $IdP->sso_url('urn:oasis:names:tc:SAML:2.0:bindings:HTTP-Redirect');

    my $AuthnRequest = Net::SAML2::Protocol::AuthnRequest->new(
        issuer              => $Self->{Config}->{Issuer},
        destination         => $SSOUrl,
        assertion_url       => $Self->{Config}->{RequestAssertionConsumerURL} . ";IsSAMLLogin=1;Count=$Self->{Count};",
        nameidpolicy_format => $Self->{Config}->{RequestNameIDFormat}
            || 'urn:oasis:names:tc:SAML:1.1:nameid-format:unspecified',
    );
    if ( !$AuthnRequest ) {
        $LogObject->Log(
            Priority => 'error',
            Message  => "Error creating AuthnRequest object for SAML auth config (count: $Self->{Count}).",
        );
        return;
    }

    $Self->{RequestID} = $AuthnRequest->id();

    my $Redirect = $Self->_BuildRedirectBinding(
        IdP => $IdP,
        Url => $SSOUrl,
    );
    return if !$Redirect;

    my $URL;
    if ( $Self->{Config}->{RequestSignKey} ) {
        $URL = $Redirect->sign( $AuthnRequest->as_xml() );
    }
    else {
        $URL = $Redirect->get_redirect_uri( $AuthnRequest->as_xml() );
    }

    return $URL;
}

=head2 CreateLogoutURL()

Builds a signed (or unsigned, if no signing key is configured) SAML
LogoutRequest redirect URL for the given session's NameID/SessionIndex, for
SP-initiated Single Logout. Returns undef (without logging an error) if the
Identity Provider's metadata doesn't advertise a Single Logout Service - in
that case there is simply nothing to redirect to.

    my $URL = $RequestObject->CreateLogoutURL(
        NameID       => '...',
        NameIDFormat => '...', # optional
        SessionIndex => '...',
    );

=cut

sub CreateLogoutURL {
    my ( $Self, %Param ) = @_;

    my $LogObject = $Kernel::OM->Get('Kernel::System::Log');

    $Self->{LogoutRequestID} = undef;

    return if !$Param{NameID};
    return if !$Param{SessionIndex};

    my $IdP = $Self->_BuildIdP();
    return if !$IdP;

    my $SLOUrl = $IdP->slo_url('urn:oasis:names:tc:SAML:2.0:bindings:HTTP-Redirect');
    return if !$SLOUrl;

    my $LogoutRequest = Net::SAML2::Protocol::LogoutRequest->new(
        issuer      => $Self->{Config}->{Issuer},
        destination => $SLOUrl,
        nameid      => $Param{NameID},
        session     => $Param{SessionIndex},
        ( $Param{NameIDFormat} ? ( nameid_format => $Param{NameIDFormat} ) : () ),
    );
    if ( !$LogoutRequest ) {
        $LogObject->Log(
            Priority => 'error',
            Message  => "Error creating LogoutRequest object for SAML auth config (count: $Self->{Count}).",
        );
        return;
    }

    my $Redirect = $Self->_BuildRedirectBinding(
        IdP => $IdP,
        Url => $SLOUrl,
    );
    return if !$Redirect;

    my $URL;
    if ( $Self->{Config}->{RequestSignKey} ) {
        $URL = $Redirect->sign( $LogoutRequest->as_xml() );
    }
    else {
        $URL = $Redirect->get_redirect_uri( $LogoutRequest->as_xml() );
    }

    return if !$URL;

    $Self->{LogoutRequestID} = $LogoutRequest->id();

    return $URL;
}

=head2 GetLogoutRequestID()

Returns the ID of the LogoutRequest built by the last CreateLogoutURL()
call, for replay protection (to be compared against the IdP's
LogoutResponse InResponseTo).

=cut

sub GetLogoutRequestID {
    my ( $Self, %Param ) = @_;

    return $Self->{LogoutRequestID};
}

sub GetID {
    my ( $Self, %Param ) = @_;

    return $Self->{RequestID};
}

=head2 VerifyLogoutRedirect()

Verifies the signature on an inbound SAML LogoutResponse redirect (the
Identity Provider's reply to CreateLogoutURL()) and parses it. Uses the same
per-slot IdP trust material (cacert) as everywhere else - no new trust
surface. Returns undef (after logging) on any verification/parse failure.

If ExpectedLogoutRequestID is given, also checks it against the parsed
response's InResponseTo (replay protection, mirroring the existing
ExpectedSAMLRequestID check for login) - logs a warning on mismatch, but
still returns the parsed LogoutResponse either way, since nothing here acts
on the result beyond logging (the session was already removed before this
redirect was sent).

    my $LogoutResponse = $RequestObject->VerifyLogoutRedirect(
        QueryString              => $ENV{QUERY_STRING},
        ExpectedLogoutRequestID  => $LogoutRequestID, # optional
    );

=cut

sub VerifyLogoutRedirect {
    my ( $Self, %Param ) = @_;

    my $LogObject = $Kernel::OM->Get('Kernel::System::Log');

    return if !$Param{QueryString};

    my $IdP = $Self->_BuildIdP();
    return if !$IdP;

    my $Redirect = Net::SAML2::Binding::Redirect->new(
        cert  => $IdP->cert('signing'),
        param => 'SAMLResponse',
    );

    my ($XML) = eval { $Redirect->verify( $Param{QueryString} ) };
    if ( !$XML ) {
        $LogObject->Log(
            Priority => 'error',
            Message  => "Error verifying SAML LogoutResponse redirect (count: $Self->{Count}): "
                . ( $@ || 'unknown error' ),
        );
        return;
    }

    my $LogoutResponse = eval { Net::SAML2::Protocol::LogoutResponse->new_from_xml( xml => $XML ) };
    if ( !$LogoutResponse ) {
        $LogObject->Log(
            Priority => 'error',
            Message  => "Error parsing SAML LogoutResponse (count: $Self->{Count}): " . ( $@ || 'unknown error' ),
        );
        return;
    }

    if ( $Param{ExpectedLogoutRequestID} && $LogoutResponse->in_response_to ne $Param{ExpectedLogoutRequestID} ) {
        $LogObject->Log(
            Priority => 'notice',
            Message  => "SAML LogoutResponse InResponseTo (count: $Self->{Count}) does not match the expected"
                . " LogoutRequest ID - possibly a replayed or stale redirect.",
        );
    }

    return $LogoutResponse;
}

sub _BuildIdP {
    my ( $Self, %Param ) = @_;

    my $LogObject = $Kernel::OM->Get('Kernel::System::Log');

    my %IdPParams;
    if ( $Self->{Config}->{IdPCACert} ) {
        $IdPParams{cacert} = $Self->{Config}->{IdPCACert};
    }

    my $IdP;
    if ( $Self->{Config}->{RequestMetaDataURL} ) {
        $IdPParams{url} = $Self->{Config}->{RequestMetaDataURL};

        # Net::SAML2 applies ssl_opts only when it creates the user agent itself.
        # Proxy settings and SSL options are therefore set on the user agent.
        $IdPParams{ua} = $Self->_GetMetadataUserAgent();

        $IdP = Net::SAML2::IdP->new_from_url(%IdPParams);
    }
    else {
        $IdPParams{xml} = $Self->{Config}->{RequestMetaDataXML};

        $IdP = Net::SAML2::IdP->new_from_xml(%IdPParams);
    }

    if ( !$IdP ) {
        $LogObject->Log(
            Priority => 'error',
            Message  => "Error creating IdP object for SAML auth config (count: $Self->{Count}).",
        );
        return;
    }

    return $IdP;
}

sub _BuildRedirectBinding {
    my ( $Self, %Param ) = @_;

    my %RedirectParams = (
        cert  => $Param{IdP}->cert('signing'),
        param => 'SAMLRequest',
        url   => $Param{Url},
    );

    if ( $Self->{Config}->{RequestSignKey} ) {
        $RedirectParams{key} = $Self->{Config}->{RequestSignKey};

        if ( $Self->{Config}->{RequestSignSigAlg} ) {
            $RedirectParams{sig_hash} = $Self->{Config}->{RequestSignSigAlg};
        }
    }
    else {
        $RedirectParams{insecure} = 1;
    }

    return Net::SAML2::Binding::Redirect->new(%RedirectParams);
}

sub _GetMetadataUserAgent {
    my ( $Self, %Param ) = @_;

    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');

    my $UserAgent = LWP::UserAgent->new();

    my $Proxy = $ConfigObject->Get('WebUserAgent::Proxy') || '';
    if ($Proxy) {
        $UserAgent->proxy( [ 'http', 'https', 'ftp' ], $Proxy );
    }

    my $NoProxy = $ConfigObject->Get('WebUserAgent::NoProxy');
    if ( defined $NoProxy && length $NoProxy ) {
        my @Hosts;
        HOST:
        for my $Host ( split /\s*;\s*/, $NoProxy ) {
            next HOST if !defined $Host || !length $Host;

            push @Hosts, $Host;
        }

        $UserAgent->no_proxy(@Hosts) if @Hosts;
    }

    my %SSLOptions;
    if ( IsHashRefWithData( $Self->{Config}->{RequestMetaDataURLSSLOptions} ) ) {
        %SSLOptions = %{ $Self->{Config}->{RequestMetaDataURLSSLOptions} };
    }

    if ( $ConfigObject->Get('WebUserAgent::DisableSSLVerification') ) {
        $SSLOptions{verify_hostname} = 0;
    }

    if (%SSLOptions) {
        $UserAgent->ssl_opts(%SSLOptions);
    }

    return $UserAgent;
}

1;
