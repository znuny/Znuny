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

    my $AuthnRequest = Net::SAML2::Protocol::AuthnRequest->new(
        issuer        => $Self->{Config}->{Issuer},
        destination   => $IdP->sso_url('urn:oasis:names:tc:SAML:2.0:bindings:HTTP-Redirect'),
        assertion_url => $Self->{Config}->{RequestAssertionConsumerURL} . ";IsSAMLLogin=1;Count=$Self->{Count};",
    );
    if ( !$AuthnRequest ) {
        $LogObject->Log(
            Priority => 'error',
            Message  => "Error creating AuthnRequest object for SAML auth config (count: $Self->{Count}).",
        );
        return;
    }

    $Self->{RequestID} = $AuthnRequest->id();

    my %RedirectParams = (
        cert  => $IdP->cert('signing'),
        param => 'SAMLRequest',
        url   => $IdP->sso_url('urn:oasis:names:tc:SAML:2.0:bindings:HTTP-Redirect'),
    );

    if ( $Self->{Config}->{RequestSignKey} ) {
        $RedirectParams{key} = $Self->{Config}->{RequestSignKey};
    }
    else {
        $RedirectParams{insecure} = 1;
    }

    my $Redirect = Net::SAML2::Binding::Redirect->new(%RedirectParams);

    my $URL;
    if ( $RedirectParams{insecure} ) {
        $URL = $Redirect->get_redirect_uri( $AuthnRequest->as_xml() );
    }
    else {
        $URL = $Redirect->sign( $AuthnRequest->as_xml() );
    }

    return $URL;
}

sub GetID {
    my ( $Self, %Param ) = @_;

    return $Self->{RequestID};
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
