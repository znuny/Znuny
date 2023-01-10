# --
# Copyright (C) 2001-2021 OTRS AG, https://otrs.com/
# Copyright (C) 2021 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see https://www.gnu.org/licenses/gpl-3.0.txt.
# --

use strict;
use warnings;
use utf8;

use vars (qw($Self));

use CGI;
use Kernel::System::Web::Request;

{
    local %ENV = (
        REQUEST_METHOD => 'GET',
        QUERY_STRING   => 'a=4;b=5',
    );

    CGI->initialize_globals();
    my $ParamObject = Kernel::System::Web::Request->new();

    my @ParamNames = $ParamObject->GetParamNames();
    $Self->IsDeeply(
        [ sort @ParamNames ],
        [qw/a b/],
        'ParamNames',
    );

    my $Param = $ParamObject->GetParam( Param => 'a' );
    $Self->Is(
        $Param,
        4,
        'SingleParam',
    );

    $Param = $ParamObject->GetParam( Param => 'aia' );
    $Self->Is(
        $Param,
        undef,
        'SingleParam - not defined',
    );

    my %Params = $ParamObject->GetParams();
    $Self->IsDeeply(
        \%Params,
        {
            'b' => 5,
            'a' => 4,
        },
        'GetParams() from GET',
    );

    %Params = $ParamObject->GetParams(
        Params => ['a']
    );
    $Self->IsDeeply(
        \%Params,
        {
            'a' => 4
        },
        'GetParams() for specific Param from GET',
    );

    local $CGI::POST_MAX = 1024;    ## no critic

    $ParamObject->{Query}->{'.cgi_error'} = 'Unittest failed ;-)';

    $Self->Is(
        $ParamObject->Error(),
        'Unittest failed ;-) - POST_MAX=1KB',
        'Error()',
    );
}

{
    my $PostData = 'a=4&b=5;d=2';
    local %ENV = (
        REQUEST_METHOD => 'POST',
        CONTENT_LENGTH => length($PostData),
        QUERY_STRING   => 'c=4;c=5;b=6;x=',
    );

    local *STDIN;
    open STDIN, '<:utf8', \$PostData;    ## no critic

    CGI->initialize_globals();
    my $ParamObject = Kernel::System::Web::Request->new();

    my @ParamNames = $ParamObject->GetParamNames();
    $Self->IsDeeply(
        [ sort @ParamNames ],
        [qw/a b c d x/],
        'ParamNames',
    );

    my @Array = $ParamObject->GetArray( Param => 'a' );
    $Self->IsDeeply(
        \@Array,
        [4],
        'Param a, from POST',
    );

    @Array = $ParamObject->GetArray( Param => 'b' );
    $Self->IsDeeply(
        \@Array,
        [5],
        'Param b, from POST (GET ignored)',
    );

    @Array = $ParamObject->GetArray( Param => 'c' );
    $Self->IsDeeply(
        \@Array,
        [ 4, 5 ],
        'Param c, from GET',
    );

    @Array = $ParamObject->GetArray( Param => 'd' );
    $Self->IsDeeply(
        \@Array,
        [2],
        'Param d, from POST',
    );

    my %Params = $ParamObject->GetParams();
    $Self->IsDeeply(
        \%Params,
        {
            b => 5,
            a => 4,
            c => [ 4, 5 ],
            d => 2,
            x => '',
        },
        'GetParams() from POST',
    );

    %Params = $ParamObject->GetParams(
        Params => ['a']
    );
    $Self->IsDeeply(
        \%Params,
        {
            'a' => 4
        },
        'GetParams() for specific Param from POST',
    );
}

{
    local %ENV = (
        REQUEST_METHOD => 'GET',
        QUERY_STRING   => 'a=4;json=%7B%22jsonkey%22:%22jsonvalue%22%7D;b=5;b=6;b=7',
    );

    CGI->initialize_globals();
    my $ParamObject = Kernel::System::Web::Request->new();

    my %Params = $ParamObject->GetParams(
        JSONDecodeParams => ['json'],
        Params           => [ 'a', 'json' ]
    );

    $Self->IsDeeply(
        \%Params,
        {
            'a'    => 4,
            'json' => {
                'jsonkey' => 'jsonvalue'
            }
        },
        'GetParams() with JSON from GET',
    );

    %Params = $ParamObject->GetParams(
        JSONDecodeParams => ['json'],
    );

    $Self->IsDeeply(
        \%Params,
        {
            'a' => 4,
            'b' => [
                5,
                6,
                7
            ],
            'json' => {
                'jsonkey' => 'jsonvalue'
            }
        },
        'GetParams() all Params from GET',
    );

}

1;
