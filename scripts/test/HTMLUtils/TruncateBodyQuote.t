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

# get HTMLUtils object
my $HTMLUtilsObject = $Kernel::OM->Get('Kernel::System::HTMLUtils');

# DocumentLinesLimit tests
my @Tests = (
    {
        Body => 'Some description text ...<br />
1. ...<br />
2. ...<br />
3. ...<br />
4. ...<br />
5. ...<br />
6. ...<br />
7. ...<br />
8. ...<br />
9. ...<br />
10. ...<br />
11. ...<br />
12. ...<br />
Description text end',
        Result =>
            'Some description text ...<br />
1. ...<br />
2. ...<br />
3. ...<br />
4. ...<br />
<div class="LimitEnabledCharacters"> [...]</div>',
        Limit      => 5,
        HTMLOutput => 1,
        Name       => 'DocumentLinesLimit - RTE',
    },
    {
        Body => 'Some description text ...
1. ...
2. ...
3. ...
4. ...
5. ...
6. ...
7. ...
8. ...
9. ...
10. ...
11. ...
12. ...
Description text end
',
        Result => 'Some description text ...
1. ...
2. ...
3. ...
4. ...
[...]',
        Limit      => 5,
        HTMLOutput => 0,
        Name       => 'DocumentLinesLimit - no RTE',
    },
);

for my $Test (@Tests) {
    my $Body = $HTMLUtilsObject->TruncateBodyQuote(
        Body       => $Test->{Body},
        Limit      => $Test->{Limit},
        HTMLOutput => $Test->{HTMLOutput},
    );

    $Self->Is(
        $Body,
        $Test->{Result},
        $Test->{Name},
    );
}

1;
