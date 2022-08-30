#!/usr/bin/env perl
# --
# Copyright (C) 2001-2021 OTRS AG, https://otrs.com/
# Copyright (C) 2021-2022 Znuny GmbH, https://znuny.org/
# --
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program. If not, see https://www.gnu.org/licenses/gpl-3.0.txt.
# --

use strict;
use warnings;
use utf8;

## nofilter(TidyAll::Plugin::OTRS::Perl::Dumper)

# use ../ as lib location
use File::Basename;
use FindBin qw($RealBin);
use lib dirname($RealBin);

use JSON;
use REST::Client;

# This is the HOST for the web service the format is:
# <HTTP_TYPE>:://<OTRS_FQDN>/nph-genericinterface.pl
my $Host = 'http://localhost/otrs/nph-genericinterface.pl';

my $RestClient = REST::Client->new(
    {
        host => $Host,
    }
);

# These are the Controllers and Providers the format is:
# /Webservice/<WEB_SERVICE_NAME>/<RESOURCE>/<REQUEST_VALUE>
# or
# /WebserviceID/<WEB_SERVICE_ID>/<RESOURCE>/<REQUEST_VALUE>
#
# See the documentation on how to setup Providers.
#
# This example will retrieve the Ticket with the TicketID = 1 (<REQUEST_VALUE>)
my $GetControllerAndRequest = '/Webservice/GenericTicketConnectorREST/Ticket/1';

# This example is the base URL for Ticket Create
my $CreateControllerAndRequest = '/Webservice/GenericTicketConnectorREST/Ticket';

# This example will update the Ticket with the TicketID = 1 (<REQUEST_VALUE>)
my $UpdateControllerAndRequest = '/Webservice/GenericTicketConnectorREST/Ticket/1';

# This is the base URL for Ticket Search
my $SearchControllerAndRequest = '/Webservice/GenericTicketConnectorREST/Ticket';

# This is the base URL for Ticket history with the TicketID = 1 (<REQUEST_VALUE>)
my $HistoryControllerAndRequest = '/Webservice/GenericTicketConnectorREST/TicketHistory/1';

# TicketGet Example
# See the documentation of OTRSGenericInterfaceREST on how to setup
#   - web service
#   - transport
#   - operations
my $GetParams = {
    UserLogin => "some agent user login",       # to be filled with valid agent login
    Password  => "some agent user password",    # to be filled with valid agent password
};

# Build GetParams as part of the URL for REST-GET requests
my $QueryParams = $RestClient->buildQuery( %{$GetParams} );
$GetControllerAndRequest .= $QueryParams;

$RestClient->GET($GetControllerAndRequest);

my $GetResponseCode = $RestClient->responseCode();

if ( $GetResponseCode ne '200' ) {
    print "Get request failed, response code was: $GetResponseCode\n";
}
else {

    # If the request was answered correctly, we receive a JSON string here.
    my $ResponseContent = $RestClient->responseContent();

    my $Data = decode_json $ResponseContent;

    # Just to print out the returned Data structure:
    use Data::Dumper;
    print "Get response was:\n";
    print Dumper($Data);

}

# TicketSearch Example
# See the documentation of OTRSGenericInterfaceREST on how to setup
#   - web service
#   - transport
#   - operations
my $SearchParams = {
    UserLogin => "some agent user login",       # to be filled with valid agent login
    Password  => "some agent user password",    # to be filled with valid agent password
    Queues    => ['Raw'],
};

# Build SearchParams as part of the URL for REST-GET requests
$QueryParams = $RestClient->buildQuery( %{$SearchParams} );
$SearchControllerAndRequest .= $QueryParams;

$RestClient->GET($SearchControllerAndRequest);

# If the host isn't reachable, wrong configured or couldn't serve the requested page:
my $SearchResponseCode = $RestClient->responseCode();

if ( $SearchResponseCode ne '200' ) {
    print "Search request failed, response code was: $SearchResponseCode\n";
}
else {

    # If the request was answered correctly, we receive a JSON string here.
    my $ResponseContent = $RestClient->responseContent();

    my $Data = decode_json $ResponseContent;

    # Just to print out the returned Data structure:
    use Data::Dumper;
    print "Search Response was:\n";
    print Dumper($Data);

}

# TicketCreate Example
# See the documentation of OTRSGenericInterfaceREST on how to setup
# - web service
# - transport
# - operations
my $CreateOrUpdateParams = {
    UserLogin => "some agent user login",       # to be filled with valid agent login
    Password  => "some agent user password",    # to be filled with valid agent password
    Ticket    => {
        Title        => 'some ticket title',
        Queue        => 'Raw',
        Lock         => 'unlock',
        Type         => 'Unclassified',
        State        => 'new',
        Priority     => '3 normal',
        Owner        => 'some agent user login',
        CustomerUser => 'customer-1',
    },
    Article => {
        Subject     => 'some subject',
        Body        => 'some body',
        ContentType => 'text/plain; charset=utf8',
    },
};

my $CreateJSONParams = encode_json $CreateOrUpdateParams;

my @CreateRequestParam = (
    $CreateControllerAndRequest,
    $CreateJSONParams
);

# We have to use REST-POST requests in order to send UserLogin and Password correctly
# though other REST methods would fit better.
$RestClient->POST(@CreateRequestParam);

# If the host isn't reachable, wrong configured or couldn't serve the requested page:
my $CreateResponseCode = $RestClient->responseCode();

if ( $CreateResponseCode ne '200' ) {
    print "Create request failed, response code was: $CreateResponseCode\n";
}
else {

    # If the request was answered correctly, we receive a JSON string here.
    my $ResponseContent = $RestClient->responseContent();

    my $Data = decode_json $ResponseContent;

    # Just to print out the returned Data structure:
    use Data::Dumper;
    print "Create Response was:\n";
    print Dumper($Data);

}

# TicketUpdate Example
# See the documentation of OTRSGenericInterfaceREST on how to setup
#   - web service
#   - transport
#   - operations
my $UpdateJSONParams = encode_json $CreateOrUpdateParams;

my @UpdateRequestParam = (
    $UpdateControllerAndRequest,
    $UpdateJSONParams
);

# We have to use REST-PATCH requests in order to send UserLogin and Password correctly
# though other REST methods would fit better.
$RestClient->PATCH(@UpdateRequestParam);

# If the host isn't reachable, wrong configured or couldn't serve the requested page:
my $UpdateResponseCode = $RestClient->responseCode();
if ( $UpdateResponseCode ne '200' ) {
    print "Update request failed, response code was: $UpdateResponseCode\n";
}
else {

    # If the request was answered correctly, we receive a JSON string here.
    my $ResponseContent = $RestClient->responseContent();

    my $Data = decode_json $ResponseContent;

    # Just to print out the returned Data structure:
    use Data::Dumper;
    print "Update response was:\n";
    print Dumper($Data);

}

# TicketHistoryGet Example
# See the documentation of OTRSGenericInterfaceREST on how to setup
#   - web service
#   - transport
#   - operations
my $HistoryParams = {
    UserLogin => "some agent user login",       # to be filled with valid agent login
    Password  => "some agent user password",    # to be filled with valid agent password
    TicketID  => [1],
};

# Build SearchParams as part of the URL for REST-GET requests
$QueryParams = $RestClient->buildQuery( %{$HistoryParams} );
$HistoryControllerAndRequest .= $QueryParams;

$RestClient->GET($HistoryControllerAndRequest);

# If the host isn't reachable, wrong configured or couldn't serve the requested page:
my $HistoryResponseCode = $RestClient->responseCode();

if ( $HistoryResponseCode ne '200' ) {
    print "History request failed, response code was: $HistoryResponseCode\n";
}
else {

    # If the request was answered correctly, we receive a JSON string here.
    my $ResponseContent = $RestClient->responseContent();

    my $Data = decode_json $ResponseContent;

    # Just to print out the returned Data structure:
    use Data::Dumper;
    print "History Response was:\n";
    print Dumper($Data);

}
