# --
# Copyright (C) 2021 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

use strict;
use warnings;
use utf8;

use vars (qw($Self));

my $LayoutObject = $Kernel::OM->Get('Kernel::Output::HTML::Layout');

# Payload that must not break out of a script tag via the weaker JSDataInsert path.
my $Breakout = '</script><script>alert(1)</script>';

$LayoutObject->AddJSData(
    Key   => 'Datepicker',
    Value => {
        VacationDays => {
            TimeVacationDays => {
                1 => {
                    1 => $Breakout,
                },
            },
        },
        IsRTL => 0,
    },
);
$LayoutObject->AddJSData(
    Key   => 'SearchAttributes',
    Value => ['Fulltext'],
);
$LayoutObject->AddJSData(
    Key   => 'CalendarWeekDayStart',
    Value => 1,
);

$LayoutObject->Block(
    Name => 'SearchAJAX',
    Data => {},
);

my $Output = $LayoutObject->Output(
    TemplateFile => 'AgentTicketSearch',
    Data         => {},
    AJAX         => 1,
);

$Self->True(
    index( $Output, '\\u003c' ) > -1,
    'AJAX AgentTicketSearch embeds JS config with unicode < escaping',
);

$Self->True(
    index( $Output, '\\u003e' ) > -1,
    'AJAX AgentTicketSearch embeds JS config with unicode > escaping',
);

$Self->True(
    index( $Output, '\\u003cscript\\u003e' ) > -1,
    'AJAX AgentTicketSearch unicode-escapes script open tags in JS config',
);

$Self->False(
    scalar( $Output =~ m{Core\.Config\.AddConfig\(\{.*?<script}s ),
    'AJAX AgentTicketSearch does not embed raw script tags via JSDataInsert',
);

1;
