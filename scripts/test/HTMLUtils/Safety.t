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

# get HTMLUtils object
my $HTMLUtilsObject = $Kernel::OM->Get('Kernel::System::HTMLUtils');

# Safety tests
my @Tests = (
    {
        Input  => 'Some Text',
        Result => {
            Output  => 'Some Text',
            Replace => 0,
        },
        Name => 'Safety - simple'
    },
    {
        Input  => '<b>Some Text</b>',
        Result => {
            Output  => '<b>Some Text</b>',
            Replace => 0,
        },
        Name => 'Safety - simple'
    },
    {
        Input  => '<a href="javascript:alert(1)">Some Text</a>',
        Result => {
            Output  => '<a href="">Some Text</a>',
            Replace => 1,
        },
        Name => 'Safety - simple'
    },
    {
        Input => '<a href = " javascript : alert(
            \'Hi!\'
        )" >Some Text</a>',
        Result => {
            Output  => '<a href = "" >Some Text</a>',
            Replace => 1,
        },
        Name => 'Safety - simple'
    },
    {
        Input =>
            '<a href="https://www.yoururl.tld/sub/online-assessment/index.php" target="_blank">https://www.yoururl.tld/sub/online-assessment/index.php</a>',
        Result => {
            Output =>
                '<a href="https://www.yoururl.tld/sub/online-assessment/index.php" target="_blank">https://www.yoururl.tld/sub/online-assessment/index.php</a>',
            Replace => 0,
        },
        Name => 'Safety - simple'
    },
    {
        Input =>
            "<a href='https://www.yoururl.tld/sub/online-assessment/index.php' target='_blank'>https://www.yoururl.tld/sub/online-assessment/index.php</a>",
        Result => {
            Output =>
                "<a href='https://www.yoururl.tld/sub/online-assessment/index.php' target='_blank'>https://www.yoururl.tld/sub/online-assessment/index.php</a>",
            Replace => 0,
        },
        Name => 'Safety - simple'
    },
    {
        Input  => '<a href="http://example.com/" onclock="alert(1)">Some Text</a>',
        Result => {
            Output  => '<a href="http://example.com/">Some Text</a>',
            Replace => 1,
        },
        Name => 'Safety - simple'
    },
    {
        Input =>
            '<a href="http://example.com/" onclock="alert(1)">Some Text <img src="http://example.com/logo.png"/></a>',
        Result => {
            Output  => '<a href="http://example.com/">Some Text </a>',
            Replace => 1,
        },
        Name => 'Safety - simple'
    },
    {
        Input => '<script type="text/javascript" id="topsy_global_settings">
var topsy_style = "big";
</script><script type="text/javascript" id="topsy-js-elem" src="http://example.com/topsy.js?init=topsyWidgetCreator"></script>
<script type="text/javascript" src="/pub/js/podpress.js"></script>
',
        Result => {
            Output => '

',
            Replace => 1,
        },
        Name => 'Safety - script tag'
    },
    {
        Input => '<center>
<applet code="AEHousman.class" width="300" height="150">
Not all browsers can run applets.  If you see this, yours can not.
You should be able to continue reading these lessons, however.
</applet>
</center>',
        Result => {
            Output => '<center>

</center>',
            Replace => 1,
        },
        Name => 'Safety - applet tag'
    },
    {
        Input => '<center>
<object width="384" height="236" align="right" vspace="5" hspace="5"><param name="movie" value="http://www.youtube.com/v/l1JdGPVMYNk&hl=en_US&fs=1&hd=1"></param><param name="allowFullScreen" value="true"></param><param name="allowscriptaccess" value="always"></param><embed src="http://www.youtube.com/v/l1JdGPVMYNk&hl=en_US&fs=1&hd=1" type="application/x-shockwave-flash" allowscriptaccess="always" allowfullscreen="true" width="384" height="236"></embed></object>
</center>',
        Result => {
            Output => '<center>

</center>',
            Replace => 1,
        },
        Name => 'Safety - object tag'
    },
    {
        Input => '<center>
\'\';!--"<XSS>=&{()}
</center>',
        Result => {
            Output => '<center>
\'\';!--"<XSS>=&{()}
</center>',
            Replace => 0,
        },
        Name => 'Safety - simple'
    },
    {
        Input => '<center>
<SCRIPT SRC=http://ha.ckers.org/xss.js></SCRIPT>
</center>',
        Result => {
            Output => '<center>

</center>',
            Replace => 1,
        },
        Name => 'Safety - script/src tag'
    },
    {
        Input => '<center>
<SCRIPT SRC=http://ha.ckers.org/xss.js><!-- some comment --></SCRIPT>
</center>',
        Result => {
            Output => '<center>

</center>',
            Replace => 1,
        },
        Name => 'Safety - script/src tag'
    },
    {
        Input => '<center>
<IMG SRC="javascript:alert(\'XSS\');">
</center>',
        Result => {
            Output => '<center>
<IMG SRC="">
</center>',
            Replace => 1,
        },
        Name => 'Safety - img tag'
    },
    {
        Input => '<center>
<IMG SRC=" javascript:    alert(
 \'XSS\'    );" >
</center>',
        Result => {
            Output => '<center>
<IMG SRC="" >
</center>',
            Replace => 1,
        },
        Name => 'Safety - img tag'
    },
    {
        Input => '<center>
<IMG SRC=javascript:alert(\'XSS\');>
</center>',
        Result => {
            Output => '<center>
<IMG SRC="">
</center>',
            Replace => 1,
        },
        Name => 'Safety - img tag'
    },
    {
        Input => '<center>
<IMG SRC=JaVaScRiPt:alert(\'XSS\')>
</center>',
        Result => {
            Output => '<center>
<IMG SRC="">
</center>',
            Replace => 1,
        },
        Name => 'Safety - img tag'
    },
    {
        Input => '<center>
<IMG SRC=javascript:alert(&quot;XSS&quot;)>
</center>',
        Result => {
            Output => '<center>
<IMG SRC="">
</center>',
            Replace => 1,
        },
        Name => 'Safety - img tag'
    },
    {
        Input => '<center>
<IMG """><SCRIPT>alert("XSS")</SCRIPT>">
</center>',
        Result => {
            Output => '<center>
<IMG """>">
</center>',
            Replace => 1,
        },
        Name => 'Safety - script/img tag'
    },
    {
        Input => '<center>
<SCRIPT/XSS SRC="http://ha.ckers.org/xss.js"></SCRIPT>
</center>',
        Result => {
            Output => '<center>

</center>',
            Replace => 1,
        },
        Name => 'Safety - script tag'
    },
    {
        Input => '<center>
<SCRIPT/SRC="http://ha.ckers.org/xss.js"></SCRIPT>
</center>',
        Result => {
            Output => '<center>

</center>',
            Replace => 1,
        },
        Name => 'Safety - script tag'
    },
    {
        Input => '<center>
<<SCRIPT>alert("XSS");//<</SCRIPT>
</center>',
        Result => {
            Output => '<center>
<
</center>',
            Replace => 1,
        },
        Name => 'Safety - script tag'
    },
    {
        Input => '<center>
<SCRIPT SRC=http://ha.ckers.org/xss.js?<B>
</center>',
        Result => {
            Output => '<center>
/center>',
            Replace => 1,
        },
        Name => 'Safety - script tag'
    },
    {
        Input => '<center>
<SCRIPT SRC=//ha.ckers.org/.j>
</center>',
        Result => {
            Output => '<center>
/center>',
            Replace => 1,
        },
        Name => 'Safety - script tag'
    },
    {
        Input => '<center>
<iframe src=http://ha.ckers.org/scriptlet.html >
</center>',
        Result => {
            Output => '<center>

</center>',
            Replace => 1,
        },
        Name => 'Safety - iframe'
    },
    {
        Input => '<center>
<BODY ONLOAD=alert(\'XSS\')>
</center>',
        Result => {
            Output => '<center>
<BODY>
</center>',
            Replace => 1,
        },
        Name => 'Safety - onload'
    },
    {
        Input => '<center>
<TABLE BACKGROUND="javascript:alert(\'XSS\')">
</center>',
        Result => {
            Output => '<center>
<TABLE BACKGROUND="">
</center>',
            Replace => 1,
        },
        Name => 'Safety - background'
    },
    {
        Input => '<center>
<TABLE BACKGROUND="   javascript:    alert(
    \'XSS\'
    ) " >
</center>',
        Result => {
            Output => '<center>
<TABLE BACKGROUND="" >
</center>',
            Replace => 1,
        },
        Name => 'Safety - background'
    },
    {
        Input => '<center>
<SCRIPT a=">" SRC="http://ha.ckers.org/xss.js"></SCRIPT>
</center>',
        Result => {
            Output => '<center>

</center>',
            Replace => 1,
        },
        Name => 'Safety - script'
    },
    {
        Input => '<center>
<SCRIPT =">" SRC="http://ha.ckers.org/xss.js"></SCRIPT>
</center>',
        Result => {
            Output => '<center>

</center>',
            Replace => 1,
        },
        Name => 'Safety - script'
    },
    {
        Input => '<center>
<SCRIPT "a=\'>\'"
 SRC="http://ha.ckers.org/xss.js"></SCRIPT>
</center>',
        Result => {
            Output => '<center>

</center>',
            Replace => 1,
        },
        Name => 'Safety - script'
    },
    {
        Input => '<center>
<SCRIPT>document.write("<SCRI");</SCRIPT>PT
 SRC="http://ha.ckers.org/xss.js"></SCRIPT>
</center>',
        Result => {
            Output => '<center>
PT
 SRC="http://ha.ckers.org/xss.js"></SCRIPT>
</center>',
            Replace => 1,
        },
        Name => 'Safety - script'
    },
    {
        Input => '<center>
<A
 HREF="javascript:document.location=\'http://www.example.com/\'">XSS</A>
</center>',
        Result => {
            Output => '<center>
<A
 HREF="">XSS</A>
</center>',
            Replace => 1,
        },
        Name => 'Safety - script'
    },
    {
        Input => '<center>
<A
 HREF="   javascript:   document.location = \'http://www.example.com/\'">XSS</A>
</center>',
        Result => {
            Output => '<center>
<A
 HREF="">XSS</A>
</center>',
            Replace => 1,
        },
        Name => 'Safety - script'
    },
    {
        Input => '<center>
  <body style="background: #fff; color: #000;" onmouseover     ="var ga = document.createElement(\'script\'); ga.type = \'text/javascript\'; ga.src = (\'https:\' == document.location.protocol ? \'https://\' : \'http://\') + \'ajax.googleapis.com/ajax/libs/jquery/1.4.2/jquery.min.js\'; document.body.appendChild(ga); setTimeout(function() { jQuery(\'body\').append(jQuery(\'<div />\').attr(\'id\', \'hack-me\').css(\'display\', \'none\')); jQuery(\'#hack-me\').load(\'/otrs/index.pl?Action=AgentPreferences\', null, function() { jQuery.ajax({url: \'/otrs/index.pl\', type: \'POST\', data: ({Action: \'AgentPreferences\', ChallengeToken: jQuery(\'input[name=ChallengeToken]:first\', \'#hack-me\').val(), Group: \'Language\', \'Subaction\': \'Update\', UserLanguage: \'zh_CN\'})}); }); }, 500);">
</center>',
        Result => {
            Output => '<center>
  <body style="background: #fff; color: #000;" ga = document.createElement(\'script\'); ga.type = \'text/javascript\'; ga.src = (\'https:\' == document.location.protocol ? \'https://\' : \'http://\') + \'ajax.googleapis.com/ajax/libs/jquery/1.4.2/jquery.min.js\'; document.body.appendChild(ga); setTimeout(function() { jQuery(\'body\').append(jQuery(\'<div />\').attr(\'id\', \'hack-me\').css(\'display\', \'none\')); jQuery(\'#hack-me\').load(\'/otrs/index.pl?Action=AgentPreferences\', null, function() { jQuery.ajax({url: \'/otrs/index.pl\', type: \'POST\', data: ({Action: \'AgentPreferences\', ChallengeToken: jQuery(\'input[name=ChallengeToken]:first\', \'#hack-me\').val(), Group: \'Language\', \'Subaction\': \'Update\', UserLanguage: \'zh_CN\'})}); }); }, 500);">
</center>',
            Replace => 1,
        },
        Name => 'Safety - script'
    },
    {
        Input =>
            '<html><head><style type="text/css"> #some_css {color: #FF0000} </style><body>Important Text about "javascript"!<style type="text/css"> #some_more_css{ color: #00FF00 } </style> Some more text.</body></html>',
        Result => {
            Output =>
                '<html><head><style type="text/css"> #some_css {color: #FF0000} </style><body>Important Text about "javascript"!<style type="text/css"> #some_more_css{ color: #00FF00 } </style> Some more text.</body></html>',
            Replace => 0,
        },
        Name =>
            'Safety - Test for bug#7972 - Some mails may not present HTML part when using rich viewing.'
    },
    {
        Input =>
            '<html><head><style type="text/javascript"> alert("some evil stuff!);</style><body>Important Text about "javascript"!<style type="text/css"> #some_more_css{ color: #00FF00 } </style> Some more text.</body></html>',
        Result => {
            Output =>
                '<html><head><body>Important Text about "javascript"!<style type="text/css"> #some_more_css{ color: #00FF00 } </style> Some more text.</body></html>',
            Replace => 1,
        },
        Name =>
            'Safety - Additional test for bug#7972 - Some mails may not present HTML part when using rich viewing.'
    },
    {
        Name  => 'Safety - UTF7 tags',
        Input => <<EOF,
script:+ADw-script+AD4-alert(1);+ADw-/script+AD4-
applet:+ADw-applet+AD4-alert(1);+ADw-/applet+AD4-
embed:+ADw-embed src=test+AD4-
object:+ADw-object+AD4-alert(1);+ADw-/object+AD4-
EOF
        Result => {
            Output => <<EOF,
script:
applet:
embed:
object:
EOF
            Replace => 1,
        },
    },
    {
        Input => <<EOF,
<div style="width: expression(alert(\'XSS\');); height: 200px;" style="width: 400px">
<div style='width: expression(alert("XSS");); height: 200px;' style='width: 400px'>
EOF
        Result => {
            Output => <<EOF,
<div style="width: 400px">
<div style='width: 400px'>
EOF
            Replace => 1,
        },
        Name => 'Safety - Filter out MS CSS expressions'
    },
    {
        Input => <<EOF,
<div><XSS STYLE="xss:expression(alert('XSS'))"></div>
EOF
        Result => {
            Output => <<EOF,
<div><XSS></div>
EOF
            Replace => 1,
        },
        Name => 'Safety - Microsoft CSS expression on invalid tag'
    },
    {
        Input => <<EOF,
<div class="svg"><svg some-attribute evil="true"><someevilsvgcontent></svg></div>
EOF
        Result => {
            Output => <<EOF,
<div class="svg"></div>
EOF
            Replace => 1,
        },
        Name => 'Safety - Filter out SVG'
    },
    {
        Input => <<EOF,
<div><script ></script ><applet ></applet ></div >
EOF
        Result => {
            Output => <<EOF,
<div></div >
EOF
            Replace => 1,
        },
        Name => 'Safety - Closing tag with space'
    },
    {
        Input => <<EOF,
<style type="text/css">
div > span {
    width: 200px;
}
</style>
<style type="text/css">
div > span {
    width: expression(evilJS());
}
</style>
<style type="text/css">
div > span > div {
    width: 200px;
}
</style>
EOF
        Result => {
            Output => <<EOF,
<style type="text/css">
div > span {
    width: 200px;
}
</style>

<style type="text/css">
div > span > div {
    width: 200px;
}
</style>
EOF
            Replace => 1,
        },
        Name => 'Safety - Style tags with CSS expressions are filtered out'
    },
    {
        Input => <<EOF,
<s<script>...</script><script>...<cript type="text/javascript">
document.write("Hello World!");
</s<script>//<cript>
EOF
        Result => {
            Output => <<EOF,

EOF
            Replace => 1,
        },
        Name => 'Safety - Nested script tags'
    },
    {
        Input => <<EOF,
<img src="/img1.png"/>
<iframe src="  javascript:alert('XSS Exploit');"></iframe>
<img src="/img2.png"/>
EOF
        Result => {
            Output => <<EOF,
<img src="/img1.png"/>
<iframe src=""></iframe>
<img src="/img2.png"/>
EOF
            Replace => 1,
        },
        Name => 'Safety - javascript source with space'
    },
    {
        Input => <<EOF,
<img src="/img1.png"/>
<iframe src='  javascript:alert(
    "XSS Exploit"
);'></iframe>
<img src="/img2.png"/>
EOF
        Result => {
            Output => <<EOF,
<img src="/img1.png"/>
<iframe src=""></iframe>
<img src="/img2.png"/>
EOF
            Replace => 1,
        },
        Name => 'Safety - javascript source with space'
    },
    {
        Input => <<EOF,
<img src="/img1.png"/>
<iframe src=javascript:alert('XSS_Exploit');></iframe>
<img src="/img2.png"/>
EOF
        Result => {
            Output => <<EOF,
<img src="/img1.png"/>
<iframe src=""></iframe>
<img src="/img2.png"/>
EOF
            Replace => 1,
        },
        Name => 'Safety - javascript source without delimiters'
    },
    {
        Input => <<EOF,
<img src="/img1.png"/>
<iframe src="" data-src="javascript:alert('XSS Exploit');"></iframe>
<img src="/img2.png"/>
EOF
        Result => {
            Output => <<EOF,
<img src="/img1.png"/>
<iframe src="" data-src="javascript:alert('XSS Exploit');"></iframe>
<img src="/img2.png"/>
EOF
            Replace => 0,
        },
        Name => 'Safety - javascript source in data tag, keep'
    },
    {
        Input => <<EOF,
Some
<META HTTP-EQUIV="Refresh" CONTENT="2;
URL=http://www.rbrasileventos.com.br/9asdasd/">
Content
EOF
        Result => {
            Output => <<EOF,
Some

Content
EOF
            Replace => 1,
        },
        Name => 'Safety - meta refresh tag removed'
    },
    {
        Input => <<EOF,
<img/onerror="alert(\'XSS1\')"src=a>
EOF
        Result => {
            Output => <<EOF,
<img>
EOF
            Replace => 1,
        },
        Name => 'Safety - / as attribute delimiter'
    },
    {
        Input => <<EOF,
<iframe src=javasc&#x72ipt:alert(\'XSS2\') >
EOF
        Result => {
            Output => <<EOF,
<iframe src="" >
EOF
            Replace => 1,
        },
        Name => 'Safety - entity encoding in javascript attribute'
    },
    {
        Input => <<EOF,
<iframe/src=javasc&#x72ipt:alert(\'XSS2\') >
EOF
        Result => {
            Output => <<EOF,
<iframe/src="" >
EOF
            Replace => 1,
        },
        Name => 'Safety - entity encoding in javascript attribute with / separator'
    },
    {
        Input => <<EOF,
<img src="http://example.com/image.png"/>
EOF
        Result => {
            Output => <<EOF,

EOF
            Replace => 1,
        },
        Name => 'Safety - external image'
    },
    {
        Input => <<EOF,
<img/src="http://example.com/image.png"/>
EOF
        Result => {
            Output => <<EOF,

EOF
            Replace => 1,
        },
        Name => 'Safety - external image with / separator'
    },
);

for my $Test (@Tests) {
    my %Result = $HTMLUtilsObject->Safety(
        String       => $Test->{Input},
        NoApplet     => 1,
        NoObject     => 1,
        NoEmbed      => 1,
        NoSVG        => 1,
        NoIntSrcLoad => 0,
        NoExtSrcLoad => 1,
        NoJavaScript => 1,
    );
    if ( $Test->{Result}->{Replace} ) {
        $Self->True(
            $Result{Replace},
            "$Test->{Name} replaced",
        );
    }
    else {
        $Self->False(
            $Result{Replace},
            "$Test->{Name} not replaced",
        );
    }
    $Self->Is(
        $Result{String},
        $Test->{Result}->{Output},
        $Test->{Name},
    );
}

@Tests = (
    {
        Name  => 'Safety - img tag',
        Input => <<EOF,
<img/src="http://example.com/image.png"/>
EOF
        Config => {
            NoImg => 1,
        },
        Result => {
            Output => <<EOF,

EOF
            Replace => 1,
        },
    },
    {
        Name  => 'Safety - img tag replacement',
        Input => <<EOF,
<img/src="http://example.com/image.png"/>
EOF
        Config => {
            NoImg          => 1,
            ReplacementStr => '...'
        },
        Result => {
            Output => <<EOF,
...
EOF
            Replace => 1,
        },
    },
    {
        Name  => 'Safety - Filter out SVG replacement',
        Input => <<EOF,
<div class="svg"><svg some-attribute evil="true"><someevilsvgcontent></svg></div>
EOF
        Config => {
            NoSVG          => 1,
            ReplacementStr => '...'
        },
        Result => {
            Output => <<EOF,
<div class="svg">...</div>
EOF
            Replace => 1,
        },
    },
    {
        Name  => 'Safety - object tag replacement',
        Input => '<center>
<object width="384" height="236" align="right" vspace="5" hspace="5"><param name="movie" value="http://www.youtube.com/v/l1JdGPVMYNk&hl=en_US&fs=1&hd=1"></param><param name="allowFullScreen" value="true"></param><param name="allowscriptaccess" value="always"></param><embed src="http://www.youtube.com/v/l1JdGPVMYNk&hl=en_US&fs=1&hd=1" type="application/x-shockwave-flash" allowscriptaccess="always" allowfullscreen="true" width="384" height="236"></embed></object>
</center>',
        Config => {
            NoObject       => 1,
            ReplacementStr => '...'
        },
        Result => {
            Output => '<center>
...
</center>',
            Replace => 1,
        },
    },
    {
        Name  => 'Safety - embed tag replacement',
        Input => '<center>
<object width="384" height="236" align="right" vspace="5" hspace="5"><param name="movie" value="http://www.youtube.com/v/l1JdGPVMYNk&hl=en_US&fs=1&hd=1"></param><param name="allowFullScreen" value="true"></param><param name="allowscriptaccess" value="always"></param><embed src="http://www.youtube.com/v/l1JdGPVMYNk&hl=en_US&fs=1&hd=1" type="application/x-shockwave-flash" allowscriptaccess="always" allowfullscreen="true" width="384" height="236"></object>
</center>',
        Config => {
            NoEmbed        => 1,
            ReplacementStr => '...'
        },
        Result => {
            Output => '<center>
<object width="384" height="236" align="right" vspace="5" hspace="5"><param name="movie" value="http://www.youtube.com/v/l1JdGPVMYNk&hl=en_US&fs=1&hd=1"></param><param name="allowFullScreen" value="true"></param><param name="allowscriptaccess" value="always"></param>...</object>
</center>',
            Replace => 1,
        },
    },
    {
        Name  => 'Safety - applet tag replacement',
        Input => '<center>
<applet code="AEHousman.class" width="300" height="150">
Not all browsers can run applets.  If you see this, yours can not.
You should be able to continue reading these lessons, however.
</applet>
</center>',
        Config => {
            NoApplet       => 1,
            ReplacementStr => '...'
        },
        Result => {
            Output => '<center>
...
</center>',
            Replace => 1,
        },
    },
    {
        Name   => 'Safety - bug 10530 - don\'t destroy URL which looks like an on* JS attribute',
        Input  => '<a href="http://localhost/online/foo/bar.html">www</a>',
        Config => {},
        Result => {
            Output  => '<a href="http://localhost/online/foo/bar.html">www</a>',
            Replace => 0,
        },
    },
    {
        Name   => 'Safety - bug 13561 - Handling empty strings',
        Input  => '',
        Config => {},
        Result => {
            Output  => '',
            Replace => 0,
        },
    },
    {
        Name   => 'Safety - remote poster attribute, forbidden',
        Input  => '<video controls poster="http://some.domain/vorschaubild.png"/>',
        Config => {
            NoExtSrcLoad => 1,
        },
        Result => {
            Output  => '',
            Replace => 1,
        },
    },
    {
        Name   => 'Safety - remote poster attribute, allowed',
        Input  => '<video controls poster="http://some.domain/vorschaubild.png"/>',
        Config => {
            NoExtSrcLoad => 0,
        },
        Result => {
            Output  => '<video controls poster="http://some.domain/vorschaubild.png"/>',
            Replace => 0,
        },
    },
    {
        Name  => 'Safety - malicious CSS content - remote background image, forbidden',
        Input => '<a href="localhost" style="background-image:url(http://localhost:8000/css-background)">localhost</a>',
        Config => {
            NoExtSrcLoad => 1,
        },
        Result => {
            Output  => '<a href="localhost">localhost</a>',
            Replace => 1,
        },
    },
    {
        Name  => 'Safety - malicious CSS content - remote background image, allowed',
        Input => '<a href="localhost" style="background-image:url(http://localhost:8000/css-background)">localhost</a>',
        Config => {
            NoExtSrcLoad => 0,
        },
        Result => {
            Output =>
                '<a href="localhost" style="background-image:url(http://localhost:8000/css-background)">localhost</a>',
            Replace => 0,
        },
    },
    {
        Name   => 'Safety - malicious CSS content - local background image, forbidden',
        Input  => '<a href="localhost" style="background-image:url(/local/css-background)">localhost</a>',
        Config => {
            NoIntSrcLoad => 1,
        },
        Result => {
            Output  => '<a href="localhost">localhost</a>',
            Replace => 1,
        },
    },
    {
        Name   => 'Safety - malicious CSS content - local background image, allowed',
        Input  => '<a href="localhost" style="background-image:url(/local/css-background)">localhost</a>',
        Config => {
            NoIntSrcLoad => 0,
        },
        Result => {
            Output  => '<a href="localhost" style="background-image:url(/local/css-background)">localhost</a>',
            Replace => 0,
        },
    },
    {
        Name   => 'Safety - malicious CSS content - remote css content, forbidden',
        Input  => q|<p style="content:url('http://localhost:8000/css-content');"></p>|,
        Config => {
            NoExtSrcLoad => 1,
        },
        Result => {
            Output  => '<p></p>',
            Replace => 1,
        },
    },
    {
        Name   => 'Safety - malicious CSS content - remote css content, allowed',
        Input  => q|<p style="content:url('http://localhost:8000/css-content');"></p>|,
        Config => {
            NoExtSrcLoad => 0,
        },
        Result => {
            Output  => q|<p style="content:url('http://localhost:8000/css-content');"></p>|,
            Replace => 0,
        },
    },
    {
        Name   => 'Safety - malicious CSS content - local css content, forbidden',
        Input  => q|<p style="content:url('/local/css-content');"></p>|,
        Config => {
            NoIntSrcLoad => 1,
        },
        Result => {
            Output  => '<p></p>',
            Replace => 1,
        },
    },
    {
        Name   => 'Safety - malicious CSS content - local css content, allowed',
        Input  => q|<p style="content:url('/local/css-content');"></p>|,
        Config => {
            NoIntSrcLoad => 0,
        },
        Result => {
            Output  => q|<p style="content:url('/local/css-content');"></p>|,
            Replace => 0,
        },
    },
);

for my $Test (@Tests) {
    my %Result = $HTMLUtilsObject->Safety(
        String => $Test->{Input},
        %{ $Test->{Config} },
    );
    if ( $Test->{Result}->{Replace} ) {
        $Self->True(
            $Result{Replace},
            "$Test->{Name} replaced",
        );
    }
    else {
        $Self->False(
            $Result{Replace},
            "$Test->{Name} not replaced",
        );
    }
    $Self->Is(
        $Result{String},
        $Test->{Result}->{Output},
        $Test->{Name},
    );
}

1;
