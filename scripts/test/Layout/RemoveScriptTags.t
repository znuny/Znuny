# --
# Copyright (C) 2001-2021 OTRS AG, https://otrs.com/
# Copyright (C) 2021-2022 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see https://www.gnu.org/licenses/gpl-3.0.txt.
# --

use strict;
use warnings;
use utf8;

use vars (qw($Self));

# get layout object
my $LayoutObject = $Kernel::OM->Get('Kernel::Output::HTML::Layout');

# Tests for _RemoveScriptTags method
my @Tests = (
    {
        Input  => '',
        Result => '',
        Name   => '_RemoveScriptTags - empty test',
    },
    {
        Input  => '<script type="text/javascript"></script>',
        Result => '',
        Name   => '_RemoveScriptTags - just tags test',
    },
    {
        Input => '
<script type="text/javascript">
    123
    // 456
    789
</script>',
        Result => '

    123
    // 456
    789
',
        Name => '_RemoveScriptTags - some content test',
    },
    {
        Input => '
<script type="text/javascript">//<![CDATA[
    OTRS.UI.Tables.InitTableFilter($(\'#FilterCustomers\'), $(\'#Customers\'));
    OTRS.UI.Tables.InitTableFilter($(\'#FilterGroups\'), $(\'#Groups\'));
//]]></script>
        ',
        Result => '

    OTRS.UI.Tables.InitTableFilter($(\'#FilterCustomers\'), $(\'#Customers\'));
    OTRS.UI.Tables.InitTableFilter($(\'#FilterGroups\'), $(\'#Groups\'));

        ',
        Name => '_RemoveScriptTags - complete content test',
    },
    {
        Input => <<'EOF',
<!--DocumentReadyActionRowAdd-->
<script type="text/javascript">  //<![CDATA[
   alert();
//]]></script>
<!--/DocumentReadyActionRowAdd-->
<!--DocumentReadyStart-->
<script type="text/javascript">//  <![CDATA[
   alert();
//]]></script>
<!--/DocumentReadyStart-->
EOF
        Result => <<"EOF",

   alert();
\n
   alert();

EOF
        Name => '_RemoveScriptTags - complete content test with block comments',
    },
    {
        Input => <<'EOF',
<script type="text/javascript">  //<![CDATA[
<!--DocumentReadyActionRowAdd-->
   alert();
<!--/DocumentReadyActionRowAdd-->
//]]></script>
EOF
        Result => <<"EOF",

   alert();

EOF
        Name =>
            '_RemoveScriptTags - complete content test with block comments inside the script tags',
    },
);

for my $Test (@Tests) {
    my $LRST = $LayoutObject->_RemoveScriptTags(
        Code => $Test->{Input},
    );
    $Self->Is(
        $LRST,
        $Test->{Result},
        $Test->{Name},
    );
}

1;
