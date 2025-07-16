# --
# Copyright (C) 2001-2021 OTRS AG, https://otrs.com/
# Copyright (C) 2021 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see https://www.gnu.org/licenses/gpl-3.0.txt.
# --

# This nofilter is in here because it would mess around with the copyright strings
# contained in the attachment of the last test below.
## nofilter(TidyAll::Plugin::Znuny::Legal::UpdateZnunyCopyright)

use strict;
use warnings;
use utf8;

use vars (qw($Self));

use Kernel::System::EmailParser;

my $Home = $Kernel::OM->Get('Kernel::Config')->Get('Home');

my @Tests = (
    {
        Name     => "plain email with ascii and utf-8 part",
        RawEmail => "$Home/scripts/test/sample/EmailParser/MultipartMixedPlain.eml",
        Body     => 'first part



second part äöø',
        Attachments => [

            # Look for the concatenated plain body part that was converted to utf-8.
            {
                'Charset' => 'utf-8',
                'Content' => 'first part



second part äöø',
                'ContentID'       => undef,
                'ContentLocation' => undef,
                'ContentType'     => 'text/plain; charset=utf-8',
                'Disposition'     => undef,
                'Filename'        => 'file-1',
                'Filesize'        => 32,
                'MimeType'        => 'text/plain'
            },

            # Look for the attachment.
            {
                'Charset'            => '',
                'Content'            => "1\n",
                'ContentDisposition' => "attachment; filename=1.txt\n",
                'ContentID'          => undef,
                'ContentLocation'    => undef,
                'ContentType'        => 'text/plain; name="1.txt"',
                'Disposition'        => 'attachment; filename=1.txt',
                'Filename'           => '1.txt',
                'Filesize'           => 2,
                'MimeType'           => 'text/plain'
            }
        ],
    },
    {
        Name     => "HTML email with ascii and utf-8 part",
        RawEmail => "$Home/scripts/test/sample/EmailParser/MultipartMixedHTML.eml",
        Body     => 'first part



second part äöø',
        Attachments => [

            # Look for the plain body part.
            {
                'Charset' => 'utf-8',
                'Content' => 'first part



second part äöø',
                'ContentAlternative' => 1,
                'ContentID'          => undef,
                'ContentLocation'    => undef,
                'ContentType'        => 'text/plain; charset=utf-8',
                'Disposition'        => undef,
                'Filename'           => 'file-1',
                'Filesize'           => 32,
                'MimeType'           => 'text/plain'
            },

            # Look for the concatenated HTML body part that was converted to utf-8.
            {
                'Charset' => 'utf-8',
                'Content' =>
                    '<html><head><meta http-equiv="Content-Type" content="text/html charset=utf-8"></head><body style="word-wrap: break-word; -webkit-nbsp-mode: space; -webkit-line-break: after-white-space;" class=""><b class="">first</b> part<div class=""><br class=""></div><div class=""></div></body></html><html><head><meta http-equiv="Content-Type" content="text/html charset=utf-8"></head><body style="word-wrap: break-word; -webkit-nbsp-mode: space; -webkit-line-break: after-white-space;" class=""><div class=""></div><div class=""><br class=""></div><div class="">second part äöø</div></body></html>',
                'ContentAlternative' => 1,
                'ContentID'          => undef,
                'ContentLocation'    => undef,
                'ContentType'        => 'text/html; charset=utf-8',
                'Disposition'        => undef,
                'Filename'           => 'file-2',
                'Filesize'           => 590,
                'MimeType'           => 'text/html'
            },

            # Look for the attachment.
            {
                'Charset'            => '',
                'Content'            => "1\n",
                'ContentAlternative' => 1,
                'ContentDisposition' => "attachment; filename=1.txt\n",
                'ContentID'          => undef,
                'ContentLocation'    => undef,
                'ContentType'        => 'text/plain; name="1.txt"',
                'Disposition'        => 'attachment; filename=1.txt',
                'Filename'           => '1.txt',
                'Filesize'           => 2,
                'MimeType'           => 'text/plain'
            }
        ],
    },
    {
        Name     => "mixed email with plain and HTML part",
        RawEmail => "$Home/scripts/test/sample/EmailParser/MultipartMixedPlainHTML.eml",
        Body     => 'Hello,

This is the forwarded message...

--
Met vriendelijke groeten,
Erik Thijs

Hi,
 
This mail is composed in html format.

 
Cheers,
Erik
',
        Attachments => [
            {
                'Charset' => 'utf-8',
                'Content' => 'Hello,

This is the forwarded message...

--
Met vriendelijke groeten,
Erik Thijs

Hi,
 
This mail is composed in html format.

 
Cheers,
Erik
',
                'ContentID'       => undef,
                'ContentLocation' => undef,
                'ContentType'     => 'text/plain; charset=utf-8',
                'Disposition'     => 'inline',
                'Filename'        => 'file-1',
                'Filesize'        => 145,
                'MimeType'        => 'text/plain'
            },
        ],
    },
    {
        Name     => "mixed email with HTML and plain part",
        RawEmail => "$Home/scripts/test/sample/EmailParser/MultipartMixedHTMLPlain.eml",
        Body     => 'Hi,
 
This mail is composed in html format.

 
Cheers,
Erik

Hello,

This is the forwarded message...

--
Met vriendelijke groeten,
Erik Thijs

',
        Attachments => [
            {
                'Charset' => 'utf-8',
                'Content' => '<html>
<head>
<style><!--
.hmmessage P
{
margin:0px;
padding:0px
}
body.hmmessage
{
font-size: 10pt;
font-family:Tahoma
}
--></style>
</head>
<body class=\'hmmessage\'>
Hi,<BR>
&nbsp;<BR>
This <FONT color=#ff0000>mail </FONT>is <FONT color=#00b050>composed </FONT>in <FONT color=#0070c0>html </FONT>format.<BR>

&nbsp;<BR>
Cheers,<BR>
<FONT style="BACKGROUND-COLOR: #ffff00">Erik</FONT><BR></body></html>
<!DOCTYPE html><html><head><meta http-equiv="Content-Type" content="text/html; charset=utf-8"/><style class="RTEContentCssInternal">:root{--ck-color-mention-background:hsla(341,100%,30%,0.1);--ck-color-mention-text:hsl(341,100%,30%);}.ck-content .mention{background:var(--ck-color-mention-background);color:var(--ck-color-mention-text);}.ck-content code{background-color:hsla(0,0%,78%,0.3);padding:.15em;border-radius:2px;}.ck-content blockquote{overflow:hidden;padding-right:1.5em;padding-left:1.5em;margin-left:0;margin-right:0;font-style:italic;border-left:solid 5px hsl(0,0%,80%);}.ck-content[dir="rtl"] blockquote{border-left:0;border-right:solid 5px hsl(0,0%,80%);}.ck-content pre{padding:1em;color:hsl(0,0%,20.8%);background:hsla(0,0%,78%,0.3);border:1px solid hsl(0,0%,77%);border-radius:2px;text-align:left;direction:ltr;tab-size:4;white-space:pre-wrap;font-style:normal;min-width:200px;}.ck-content pre code{background:unset;padding:0;border-radius:0;}.ck-content .text-tiny{font-size:.7em;}.ck-content .text-small{font-size:.85em;}.ck-content .text-big{font-size:1.4em;}.ck-content .text-huge{font-size:1.8em;}:root{--ck-highlight-marker-yellow:hsl(60,97%,73%);--ck-highlight-marker-green:hsl(120,93%,68%);--ck-highlight-marker-pink:hsl(345,96%,73%);--ck-highlight-marker-blue:hsl(201,97%,72%);--ck-highlight-pen-red:hsl(0,85%,49%);--ck-highlight-pen-green:hsl(112,100%,27%);}.ck-content .marker-yellow{background-color:var(--ck-highlight-marker-yellow);}.ck-content .marker-green{background-color:var(--ck-highlight-marker-green);}.ck-content .marker-pink{background-color:var(--ck-highlight-marker-pink);}.ck-content .marker-blue{background-color:var(--ck-highlight-marker-blue);}.ck-content .pen-red{color:var(--ck-highlight-pen-red);background-color:transparent;}.ck-content .pen-green{color:var(--ck-highlight-pen-green);background-color:transparent;}.ck-content hr{margin:15px 0;height:4px;background:hsl(0,0%,87%);border:0;}:root{--ck-color-image-caption-background:hsl(0,0%,97%);--ck-color-image-caption-text:hsl(0,0%,20%);}.ck-content .image > figcaption{display:table-caption;caption-side:bottom;word-break:break-word;color:var(--ck-color-image-caption-text);background-color:var(--ck-color-image-caption-background);padding:.6em;font-size:.75em;outline-offset:-1px;}@media (forced-colors:active){.ck-content .image > figcaption{background-color:unset;color:unset;}}.ck-content img.image_resized{height:auto;}.ck-content .image.image_resized{max-width:100%;display:block;box-sizing:border-box;}.ck-content .image.image_resized img{width:100%;}.ck-content .image.image_resized > figcaption{display:block;}:root{--ck-image-style-spacing:1.5em;--ck-inline-image-style-spacing:calc(var(--ck-image-style-spacing) / 2);}.ck-content .image.image-style-block-align-left,.ck-content .image.image-style-block-align-right{max-width:calc(100% - var(--ck-image-style-spacing));}.ck-content .image.image-style-align-left,.ck-content .image.image-style-align-right{clear:none;}.ck-content .image.image-style-side{float:right;margin-left:var(--ck-image-style-spacing);max-width:50%;}.ck-content .image.image-style-align-left{float:left;margin-right:var(--ck-image-style-spacing);}.ck-content .image.image-style-align-right{float:right;margin-left:var(--ck-image-style-spacing);}.ck-content .image.image-style-block-align-right{margin-right:0;margin-left:auto;}.ck-content .image.image-style-block-align-left{margin-left:0;margin-right:auto;}.ck-content .image-style-align-center{margin-left:auto;margin-right:auto;}.ck-content .image-style-align-left{float:left;margin-right:var(--ck-image-style-spacing);}.ck-content .image-style-align-right{float:right;margin-left:var(--ck-image-style-spacing);}.ck-content p + .image.image-style-align-left,.ck-content p + .image.image-style-align-right,.ck-content p + .image.image-style-side{margin-top:0;}.ck-content .image-inline.image-style-align-left,.ck-content .image-inline.image-style-align-right{margin-top:var(--ck-inline-image-style-spacing);margin-bottom:var(--ck-inline-image-style-spacing);}.ck-content .image-inline.image-style-align-left{margin-right:var(--ck-inline-image-style-spacing);}.ck-content .image-inline.image-style-align-right{margin-left:var(--ck-inline-image-style-spacing);}.ck-content .image{display:table;clear:both;text-align:center;margin:0.9em auto;min-width:50px;}.ck-content .image img{display:block;margin:0 auto;max-width:100%;min-width:100%;height:auto;}.ck-content .image-inline{display:inline-flex;max-width:100%;align-items:flex-start;}.ck-content .image-inline picture{display:flex;}.ck-content .image-inline picture,.ck-content .image-inline img{flex-grow:1;flex-shrink:1;max-width:100%;}.ck-content ol{list-style-type:decimal;}.ck-content ol ol{list-style-type:lower-latin;}.ck-content ol ol ol{list-style-type:lower-roman;}.ck-content ol ol ol ol{list-style-type:upper-latin;}.ck-content ol ol ol ol ol{list-style-type:upper-roman;}.ck-content ul{list-style-type:disc;}.ck-content ul ul{list-style-type:circle;}.ck-content ul ul ul{list-style-type:square;}.ck-content ul ul ul ul{list-style-type:square;}:root{--ck-todo-list-checkmark-size:16px;}.ck-content .todo-list{list-style:none;}.ck-content .todo-list li{position:relative;margin-bottom:5px;}.ck-content .todo-list li .todo-list{margin-top:5px;}.ck-content .todo-list .todo-list__label > input{-webkit-appearance:none;display:inline-block;position:relative;width:var(--ck-todo-list-checkmark-size);height:var(--ck-todo-list-checkmark-size);vertical-align:middle;border:0;left:-25px;margin-right:-15px;right:0;margin-left:0;}.ck-content[dir=rtl] .todo-list .todo-list__label > input{left:0;margin-right:0;right:-25px;margin-left:-15px;}.ck-content .todo-list .todo-list__label > input::before{display:block;position:absolute;box-sizing:border-box;content:\'\';width:100%;height:100%;border:1px solid hsl(0,0%,20%);border-radius:2px;transition:250ms ease-in-out box-shadow;}@media (prefers-reduced-motion:reduce){.ck-content .todo-list .todo-list__label > input::before{transition:none;}}.ck-content .todo-list .todo-list__label > input::after{display:block;position:absolute;box-sizing:content-box;pointer-events:none;content:\'\';left:calc( var(--ck-todo-list-checkmark-size) / 3);top:calc( var(--ck-todo-list-checkmark-size) / 5.3);width:calc( var(--ck-todo-list-checkmark-size) / 5.3);height:calc( var(--ck-todo-list-checkmark-size) / 2.6);border-style:solid;border-color:transparent;border-width:0 calc( var(--ck-todo-list-checkmark-size) / 8) calc( var(--ck-todo-list-checkmark-size) / 8) 0;transform:rotate(45deg);}.ck-content .todo-list .todo-list__label > input[checked]::before{background:hsl(126,64%,41%);border-color:hsl(126,64%,41%);}.ck-content .todo-list .todo-list__label > input[checked]::after{border-color:hsl(0,0%,100%);}.ck-content .todo-list .todo-list__label .todo-list__label__description{vertical-align:middle;}.ck-content .todo-list .todo-list__label.todo-list__label_without-description input[type=checkbox]{position:absolute;}.ck-content .media{clear:both;margin:0.9em 0;display:block;min-width:15em;}.ck-content .page-break{position:relative;clear:both;padding:5px 0;display:flex;align-items:center;justify-content:center;}.ck-content .page-break::after{content:\'\';position:absolute;border-bottom:2px dashed hsl(0,0%,77%);width:100%;}.ck-content .page-break__label{position:relative;z-index:1;padding:.3em .6em;display:block;text-transform:uppercase;border:1px solid hsl(0,0%,77%);border-radius:2px;font-family:Helvetica,Arial,Tahoma,Verdana,Sans-Serif;font-size:0.75em;font-weight:bold;color:hsl(0,0%,20%);background:hsl(0,0%,100%);box-shadow:2px 2px 1px hsla(0,0%,0%,0.15);-webkit-user-select:none;-moz-user-select:none;-ms-user-select:none;user-select:none;}@media print{.ck-content .page-break{padding:0;}.ck-content .page-break::after{display:none;}.ck-content *:has(+ .page-break){margin-bottom:0;}}.ck-content[dir="rtl"] .table th{text-align:right;}.ck-content[dir="ltr"] .table th{text-align:left;}.ck-content figure.table:not(.layout-table){display:table;}.ck-content figure.table:not(.layout-table) > table{width:100%;height:100%;}.ck-content figure.table:not(.layout-table),.ck-content table.table:not(.layout-table){margin:0.9em auto;}.ck-content table.table:not(.layout-table),.ck-content figure.table:not(.layout-table) > table{border-collapse:collapse;border-spacing:0;border:1px double hsl(0,0%,70%);}.ck-content table.table:not(.layout-table) > thead > tr > th,.ck-content figure.table:not(.layout-table) > table > thead > tr > th,.ck-content table.table:not(.layout-table) > tbody > tr > th,.ck-content figure.table:not(.layout-table) > table > tbody > tr > th{font-weight:bold;background:hsla(0,0%,0%,5%);}.ck-content table.table:not(.layout-table) > thead > tr > td,.ck-content figure.table:not(.layout-table) > table > thead > tr > td,.ck-content table.table:not(.layout-table) > tbody > tr > td,.ck-content figure.table:not(.layout-table) > table > tbody > tr > td,.ck-content table.table:not(.layout-table) > thead > tr > th,.ck-content figure.table:not(.layout-table) > table > thead > tr > th,.ck-content table.table:not(.layout-table) > tbody > tr > th,.ck-content figure.table:not(.layout-table) > table > tbody > tr > th{min-width:2em;padding:.4em;border:1px solid hsl(0,0%,75%);}@media print{.ck-content figure.table > table{height:initial;}}.ck-content table.table.layout-table,.ck-content figure.table.layout-table{margin-top:0;margin-bottom:0;}.ck-content table.table.layout-table,.ck-content figure.table.layout-table > table{border-spacing:0;}:root{--ck-color-selector-caption-background:hsl(0,0%,97%);--ck-color-selector-caption-text:hsl(0,0%,20%);}.ck-content .table > figcaption{display:table-caption;caption-side:top;word-break:break-word;text-align:center;color:var(--ck-color-selector-caption-text);background-color:var(--ck-color-selector-caption-background);padding:.6em;font-size:.75em;outline-offset:-1px;}@media (forced-colors:active){.ck-content .table > figcaption{background-color:unset;color:unset;}}.ck-content .table .ck-table-resized{table-layout:fixed;}.ck-content .table td,.ck-content .table th{overflow-wrap:break-word;}.ck-content html,.ck-content body,.ck-content div,.ck-content span,.ck-content applet,.ck-content object,.ck-content iframe,.ck-content h1,.ck-content h2,.ck-content h3,.ck-content h4,.ck-content h5,.ck-content h6,.ck-content p,.ck-content blockquote,.ck-content pre,.ck-content a,.ck-content abbr,.ck-content acronym,.ck-content address,.ck-content big,.ck-content cite,.ck-content code,.ck-content del,.ck-content dfn,.ck-content em,.ck-content font,.ck-content img,.ck-content ins,.ck-content kbd,.ck-content q,.ck-content s,.ck-content samp,.ck-content small,.ck-content strike,.ck-content strong,.ck-content sub,.ck-content sup,.ck-content tt,.ck-content var,.ck-content dl,.ck-content dt,.ck-content dd,.ck-content ol,.ck-content ul,.ck-content li,.ck-content fieldset,.ck-content form,.ck-content label,.ck-content legend,.ck-content table,.ck-content caption,.ck-content tbody,.ck-content tfoot,.ck-content thead,.ck-content tr,.ck-content th,.ck-content td,.ck-content hr{margin:0;padding:0;border:0;outline:0;font-weight:inherit;font-style:inherit;font-size:inherit;font-family:inherit;vertical-align:baseline;background-image:none;direction:inherit;}body.ck-content{line-height:1;color:black;background:white;text-align:left;margin:0;padding:0;}.ck-content ol,.ck-content ul{list-style:none;}.ck-content table{border-collapse:collapse;border-spacing:0;}.ck-content caption,.ck-content th,.ck-content td{text-align:left;font-weight:normal;}.ck-content blockquote:before,.ck-content blockquote:after,.ck-content q:before,.ck-content q:after{content:"";}.ck-content blockquote,.ck-content q{quotes:"" "";}.ck-content a{text-decoration:none;}.ck-content strong{font-weight:bold;}.ck-content select{margin-top:-1px;}.ck-content html,.ck-content body,.ck-content div,.ck-content span,.ck-content applet,.ck-content object,.ck-content iframe,.ck-content h1,.ck-content h2,.ck-content h3,.ck-content h4,.ck-content h5,.ck-content h6,.ck-content p,.ck-content blockquote,.ck-content pre,.ck-content a,.ck-content abbr,.ck-content acronym,.ck-content address,.ck-content big,.ck-content cite,.ck-content code,.ck-content del,.ck-content dfn,.ck-content em,.ck-content font,.ck-content img,.ck-content ins,.ck-content kbd,.ck-content q,.ck-content s,.ck-content samp,.ck-content small,.ck-content strike,.ck-content strong,.ck-content sub,.ck-content sup,.ck-content tt,.ck-content var,.ck-content dl,.ck-content dt,.ck-content dd,.ck-content ol,.ck-content ul,.ck-content li,.ck-content fieldset,.ck-content form,.ck-content label,.ck-content legend,.ck-content table,.ck-content caption,.ck-content tbody,.ck-content tfoot,.ck-content thead,.ck-content tr,.ck-content th,.ck-content td,.ck-content hr,.ck-content input,.ck-content textarea{box-sizing:border-box;}</style><style class="RTEContentCssDefault">.ck.ck-content{font-family:Geneva,Helvetica,Arial,sans-serif; font-size: 12px; line-height: 1.5;}</style></head><body class="ck ck-content"><p>Hello,</p>
<p></p>
<p>This is the forwarded message...</p>
<p></p>
<p>--</p>
<p>Met vriendelijke groeten,</p>
<p>Erik Thijs</p>
<p></p>
</body></html>',
                'ContentID'       => undef,
                'ContentLocation' => undef,
                'ContentType'     => 'text/html; charset=utf-8',
                'Disposition'     => 'inline',
                'Filename'        => 'file-1.html',
                'Filesize'        => 13653,
                'MimeType'        => 'text/html'
            },
        ],
    },
);

for my $Test (@Tests) {
    my @Array;
    open my $IN, '<', $Test->{RawEmail};    ## no critic
    while (<$IN>) {
        push @Array, $_;
    }
    close $IN;

    # create local object
    my $EmailParserObject = Kernel::System::EmailParser->new(
        Email => \@Array,
    );

    my $Body = $EmailParserObject->GetMessageBody();

    $Self->Is(
        $Body,
        $Test->{Body},
        "$Test->{Name} - body",
    );

    my @Attachments = $EmailParserObject->GetAttachments();

    # Turn on utf-8 flag for parts that were not converted but are still utf-8 for correct comparison.
    for my $Attachment (@Attachments) {
        if ( $Attachment->{Charset} eq 'utf-8' ) {
            Encode::_utf8_on( $Attachment->{Content} );
        }
    }

    $Self->IsDeeply(
        \@Attachments,
        $Test->{Attachments},
        "$Test->{Name} - attachments"
    );
}

1;
