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
<!DOCTYPE html><html><head><meta http-equiv="Content-Type" content="text/html; charset=utf-8"/><style class="RTEContentCssInternal">:root{--ck-content-color-mention-background:hsla(341,100%,30%,0.1);--ck-content-color-mention-text:hsl(341,100%,30%);}.ck.ck-content .mention{background:var(--ck-content-color-mention-background);color:var(--ck-content-color-mention-text);}.ck.ck-content code{background-color:hsla(0,0%,78%,0.3);padding:.15em;border-radius:2px;}.ck.ck-content blockquote{overflow:hidden;padding-right:1.5em;padding-left:1.5em;margin-left:0;margin-right:0;font-style:italic;border-left:solid 5px hsl(0,0%,80%);}.ck.ck-content[dir="rtl"] blockquote{border-left:0;border-right:solid 5px hsl(0,0%,80%);}.ck.ck-content pre{padding:1em;color:hsl(0,0%,20.8%);background:hsla(0,0%,78%,0.3);border:1px solid hsl(0,0%,77%);border-radius:2px;text-align:left;direction:ltr;tab-size:4;white-space:pre-wrap;font-style:normal;min-width:200px;}.ck.ck-content pre code{background:unset;padding:0;border-radius:0;}:root{--ck-content-font-family:Helvetica,Arial,Tahoma,Verdana,Sans-Serif;--ck-content-font-size:medium;--ck-content-font-color:#000;--ck-content-line-height:1.5;--ck-content-word-break:break-word;}.ck.ck-content{font-family:var(--ck-content-font-family);font-size:var(--ck-content-font-size);color:var(--ck-content-font-color);line-height:var(--ck-content-line-height);word-break:var(--ck-content-word-break);}:root{--ck-content-font-size-tiny:0.7em;--ck-content-font-size-small:0.85em;--ck-content-font-size-big:1.4em;--ck-content-font-size-huge:1.8em;}.ck.ck-content .text-tiny{font-size:var(--ck-content-font-size-tiny);}.ck.ck-content .text-small{font-size:var(--ck-content-font-size-small);}.ck.ck-content .text-big{font-size:var(--ck-content-font-size-big);}.ck.ck-content .text-huge{font-size:var(--ck-content-font-size-huge);}:root{--ck-content-highlight-marker-yellow:hsl(60,97%,73%);--ck-content-highlight-marker-green:hsl(120,93%,68%);--ck-content-highlight-marker-pink:hsl(345,96%,73%);--ck-content-highlight-marker-blue:hsl(201,97%,72%);--ck-content-highlight-pen-red:hsl(0,85%,49%);--ck-content-highlight-pen-green:hsl(112,100%,27%);}.ck.ck-content .marker-yellow{background-color:var(--ck-content-highlight-marker-yellow);}.ck.ck-content .marker-green{background-color:var(--ck-content-highlight-marker-green);}.ck.ck-content .marker-pink{background-color:var(--ck-content-highlight-marker-pink);}.ck.ck-content .marker-blue{background-color:var(--ck-content-highlight-marker-blue);}.ck.ck-content .pen-red{color:var(--ck-content-highlight-pen-red);background-color:transparent;}.ck.ck-content .pen-green{color:var(--ck-content-highlight-pen-green);background-color:transparent;}.ck.ck-content hr{margin:15px 0;height:4px;background:hsl(0,0%,87%);border:0;}:root{--ck-content-color-image-caption-background:hsl(0,0%,97%);--ck-content-color-image-caption-text:hsl(0,0%,20%);}.ck.ck-content .image > figcaption{display:table-caption;caption-side:bottom;word-break:normal;overflow-wrap:anywhere;color:var(--ck-content-color-image-caption-text);background-color:var(--ck-content-color-image-caption-background);padding:.6em;font-size:.75em;outline-offset:-1px;}@media (forced-colors:active){.ck.ck-content .image > figcaption{background-color:unset;color:unset;}}.ck.ck-content img.image_resized{height:auto;}.ck.ck-content .image.image_resized{max-width:100%;display:block;box-sizing:border-box;}.ck.ck-content .image.image_resized img{width:100%;}.ck.ck-content .image.image_resized > figcaption{display:block;}:root{--ck-content-image-style-spacing:1.5em;--ck-content-inline-image-style-spacing:calc(var(--ck-content-image-style-spacing) / 2);}.ck.ck-content .image.image-style-block-align-left,.ck.ck-content .image.image-style-block-align-right{max-width:calc(100% - var(--ck-content-image-style-spacing));}.ck.ck-content .image.image-style-align-left,.ck.ck-content .image.image-style-align-right{clear:none;}.ck.ck-content .image.image-style-side{float:right;margin-left:var(--ck-content-image-style-spacing);max-width:50%;}.ck.ck-content .image.image-style-align-left{float:left;margin-right:var(--ck-content-image-style-spacing);}.ck.ck-content .image.image-style-align-right{float:right;margin-left:var(--ck-content-image-style-spacing);}.ck.ck-content .image.image-style-block-align-right{margin-right:0;margin-left:auto;}.ck.ck-content .image.image-style-block-align-left{margin-left:0;margin-right:auto;}.ck.ck-content .image-style-align-center{margin-left:auto;margin-right:auto;}.ck.ck-content .image-style-align-left{float:left;margin-right:var(--ck-content-image-style-spacing);}.ck.ck-content .image-style-align-right{float:right;margin-left:var(--ck-content-image-style-spacing);}.ck.ck-content p + .image.image-style-align-left,.ck.ck-content p + .image.image-style-align-right,.ck.ck-content p + .image.image-style-side{margin-top:0;}.ck.ck-content .image-inline.image-style-align-left,.ck.ck-content .image-inline.image-style-align-right{margin-top:var(--ck-content-inline-image-style-spacing);margin-bottom:var(--ck-content-inline-image-style-spacing);}.ck.ck-content .image-inline.image-style-align-left{margin-right:var(--ck-content-inline-image-style-spacing);}.ck.ck-content .image-inline.image-style-align-right{margin-left:var(--ck-content-inline-image-style-spacing);}.ck.ck-content .image{display:table;clear:both;text-align:center;margin:0.9em auto;min-width:50px;}.ck.ck-content .image img{display:block;margin:0 auto;max-width:100%;min-width:100%;height:auto;}.ck.ck-content .image-inline{display:inline-flex;max-width:100%;align-items:flex-start;}.ck.ck-content .image-inline picture{display:flex;}.ck.ck-content .image-inline picture,.ck.ck-content .image-inline img{flex-grow:1;flex-shrink:1;max-width:100%;}:root{--ck-content-list-marker-color:var(--ck-content-font-color);--ck-content-list-marker-font-family:var(--ck-content-font-family);--ck-content-list-marker-font-size:var(--ck-content-font-size);}.ck.ck-content li > p:first-of-type{margin-top:0;}.ck.ck-content li > p:only-child{margin-top:0;margin-bottom:0;}.ck.ck-content li.ck-list-marker-bold::marker{font-weight:bold;}.ck.ck-content li.ck-list-marker-italic::marker{font-style:italic;}.ck.ck-content li.ck-list-marker-color::marker{color:var(--ck-content-list-marker-color);}.ck.ck-content li.ck-list-marker-font-family::marker{font-family:var(--ck-content-list-marker-font-family);}.ck.ck-content li.ck-list-marker-font-size::marker{font-size:var(--ck-content-list-marker-font-size);}.ck.ck-content li.ck-list-marker-font-size-tiny::marker{font-size:var(--ck-content-font-size-tiny);}.ck.ck-content li.ck-list-marker-font-size-small::marker{font-size:var(--ck-content-font-size-small);}.ck.ck-content li.ck-list-marker-font-size-big::marker{font-size:var(--ck-content-font-size-big);}.ck.ck-content li.ck-list-marker-font-size-huge::marker{font-size:var(--ck-content-font-size-huge);}.ck.ck-content ol{list-style-type:decimal;}.ck.ck-content ol ol{list-style-type:lower-latin;}.ck.ck-content ol ol ol{list-style-type:lower-roman;}.ck.ck-content ol ol ol ol{list-style-type:upper-latin;}.ck.ck-content ol ol ol ol ol{list-style-type:upper-roman;}.ck.ck-content ul{list-style-type:disc;}.ck.ck-content ul ul{list-style-type:circle;}.ck.ck-content ul ul ul{list-style-type:square;}.ck.ck-content ul ul ul ul{list-style-type:square;}:root{--ck-content-todo-list-checkmark-size:16px;}.ck.ck-content .todo-list{list-style:none;}.ck.ck-content .todo-list li{position:relative;margin-bottom:5px;}.ck.ck-content .todo-list li .todo-list{margin-top:5px;}.ck.ck-content .todo-list .todo-list__label > input{-webkit-appearance:none;display:inline-block;position:relative;width:var(--ck-content-todo-list-checkmark-size);height:var(--ck-content-todo-list-checkmark-size);vertical-align:middle;border:0;left:-25px;margin-right:-15px;right:0;margin-left:0;}.ck.ck-content[dir=rtl] .todo-list .todo-list__label > input{left:0;margin-right:0;right:-25px;margin-left:-15px;}.ck.ck-content .todo-list .todo-list__label > input::before{display:block;position:absolute;box-sizing:border-box;content:\'\';width:100%;height:100%;border:1px solid hsl(0,0%,20%);border-radius:2px;transition:250ms ease-in-out box-shadow;}@media (prefers-reduced-motion:reduce){.ck.ck-content .todo-list .todo-list__label > input::before{transition:none;}}.ck.ck-content .todo-list .todo-list__label > input::after{display:block;position:absolute;box-sizing:content-box;pointer-events:none;content:\'\';left:calc( var(--ck-content-todo-list-checkmark-size) / 3);top:calc( var(--ck-content-todo-list-checkmark-size) / 5.3);width:calc( var(--ck-content-todo-list-checkmark-size) / 5.3);height:calc( var(--ck-content-todo-list-checkmark-size) / 2.6);border-style:solid;border-color:transparent;border-width:0 calc( var(--ck-content-todo-list-checkmark-size) / 8) calc( var(--ck-content-todo-list-checkmark-size) / 8) 0;transform:rotate(45deg);}.ck.ck-content .todo-list .todo-list__label > input[checked]::before{background:hsl(126,64%,41%);border-color:hsl(126,64%,41%);}.ck.ck-content .todo-list .todo-list__label > input[checked]::after{border-color:hsl(0,0%,100%);}.ck.ck-content .todo-list .todo-list__label .todo-list__label__description{vertical-align:middle;}.ck.ck-content .todo-list .todo-list__label.todo-list__label_without-description input[type=checkbox]{position:absolute;}.ck.ck-content .media{clear:both;margin:0.9em 0;display:block;min-width:15em;}.ck.ck-content .page-break{position:relative;clear:both;padding:5px 0;display:flex;align-items:center;justify-content:center;}.ck.ck-content .page-break::after{content:\'\';position:absolute;border-bottom:2px dashed hsl(0,0%,77%);width:100%;}.ck.ck-content .page-break__label{position:relative;z-index:1;padding:.3em .6em;display:block;text-transform:uppercase;border:1px solid hsl(0,0%,77%);border-radius:2px;font-size:0.75em;font-weight:bold;color:hsl(0,0%,20%);background:hsl(0,0%,100%);box-shadow:2px 2px 1px hsla(0,0%,0%,0.15);-webkit-user-select:none;-moz-user-select:none;-ms-user-select:none;user-select:none;}@media print{.ck.ck-content .page-break{padding:0;}.ck.ck-content .page-break::after{display:none;}.ck.ck-content *:has(+ .page-break){margin-bottom:0;}}.ck.ck-content[dir="rtl"] .table th{text-align:right;}.ck.ck-content[dir="ltr"] .table th{text-align:left;}.ck.ck-content figure.table:not(.layout-table){display:table;}.ck.ck-content figure.table:not(.layout-table) > table{width:100%;height:100%;}.ck.ck-content .table:not(.layout-table){margin:0.9em auto;}.ck.ck-content table.table:not(.layout-table),.ck.ck-content figure.table:not(.layout-table) > table{border-collapse:collapse;border-spacing:0;border:1px double hsl(0,0%,70%);}.ck.ck-content table.table:not(.layout-table) > thead > tr > th,.ck.ck-content figure.table:not(.layout-table) > table > thead > tr > th,.ck.ck-content table.table:not(.layout-table) > tbody > tr > th,.ck.ck-content figure.table:not(.layout-table) > table > tbody > tr > th{font-weight:bold;background:hsla(0,0%,0%,5%);}.ck.ck-content table.table:not(.layout-table) > thead > tr > td,.ck.ck-content figure.table:not(.layout-table) > table > thead > tr > td,.ck.ck-content table.table:not(.layout-table) > tbody > tr > td,.ck.ck-content figure.table:not(.layout-table) > table > tbody > tr > td,.ck.ck-content table.table:not(.layout-table) > thead > tr > th,.ck.ck-content figure.table:not(.layout-table) > table > thead > tr > th,.ck.ck-content table.table:not(.layout-table) > tbody > tr > th,.ck.ck-content figure.table:not(.layout-table) > table > tbody > tr > th{min-width:2em;padding:0.4em;border:1px solid hsl(0,0%,75%);}.ck.ck-content table.table:not(.layout-table) > thead > tr > td > p:first-of-type,.ck.ck-content figure.table:not(.layout-table) > table > thead > tr > td > p:first-of-type,.ck.ck-content table.table:not(.layout-table) > tbody > tr > td > p:first-of-type,.ck.ck-content figure.table:not(.layout-table) > table > tbody > tr > td > p:first-of-type,.ck.ck-content table.table:not(.layout-table) > thead > tr > th > p:first-of-type,.ck.ck-content figure.table:not(.layout-table) > table > thead > tr > th > p:first-of-type,.ck.ck-content table.table:not(.layout-table) > tbody > tr > th > p:first-of-type,.ck.ck-content figure.table:not(.layout-table) > table > tbody > tr > th > p:first-of-type{margin-top:0;}.ck.ck-content table.table:not(.layout-table) > thead > tr > td > p:last-of-type,.ck.ck-content figure.table:not(.layout-table) > table > thead > tr > td > p:last-of-type,.ck.ck-content table.table:not(.layout-table) > tbody > tr > td > p:last-of-type,.ck.ck-content figure.table:not(.layout-table) > table > tbody > tr > td > p:last-of-type,.ck.ck-content table.table:not(.layout-table) > thead > tr > th > p:last-of-type,.ck.ck-content figure.table:not(.layout-table) > table > thead > tr > th > p:last-of-type,.ck.ck-content table.table:not(.layout-table) > tbody > tr > th > p:last-of-type,.ck.ck-content figure.table:not(.layout-table) > table > tbody > tr > th > p:last-of-type{margin-bottom:0;}@media print{.ck.ck-content figure.table:not(.layout-table):has(> table){display:block;}.ck.ck-content figure.table:not(.layout-table) > table{height:initial;}}.ck.ck-content table.table.layout-table,.ck.ck-content figure.table.layout-table{margin-top:0;margin-bottom:0;}.ck.ck-content table.table.layout-table,.ck.ck-content figure.table.layout-table > table{border-spacing:0;}:root{--ck-content-color-table-caption-background:hsl(0,0%,97%);--ck-content-color-table-caption-text:hsl(0,0%,20%);}.ck.ck-content .table > figcaption{display:table-caption;caption-side:top;word-break:normal;overflow-wrap:anywhere;text-align:center;color:var(--ck-content-color-table-caption-text);background-color:var(--ck-content-color-table-caption-background);padding:.6em;font-size:.75em;outline-offset:-1px;}@media (forced-colors:active){.ck.ck-content .table > figcaption{background-color:unset;color:unset;}}.ck.ck-content .table .ck-table-resized{table-layout:fixed;}.ck.ck-content .table td,.ck.ck-content .table th{overflow-wrap:break-word;}.ck-content *{all:revert;}.ck.ck-content{line-height:1;color:black;background:white;text-align:left;margin:0;padding:0;}.ck.ck-content table{border-collapse:collapse;border-spacing:0;}.ck.ck-content caption,.ck.ck-content th,.ck.ck-content td{text-align:left;font-weight:normal;}.ck.ck-content blockquote:before,.ck.ck-content blockquote:after,.ck.ck-content q:before,.ck.ck-content q:after{content:"";}.ck.ck-content blockquote,.ck.ck-content q{quotes:"" "";}.ck.ck-content a{text-decoration:none;}.ck.ck-content strong{font-weight:bold;}.ck.ck-content select{margin-top:-1px;margin-top:2px;}.ck.ck-editor__editable_inline ol,.ck.ck-editor__editable_inline ul,.ck.ck-editor__editable_inline dl{*margin-right:0px;padding:0 40px;}.ck.ck-editor .ck.ck-editor__editable_inline{padding:2px 10px 2px 10px !important;}body.ck.ck-content hr{margin:30px 0;height:4px;background:hsl(0,0%,87%);border:0;}.ck.ck-content html,.ck.ck-content body,.ck.ck-content div,.ck.ck-content span,.ck.ck-content applet,.ck.ck-content object,.ck.ck-content iframe,.ck.ck-content h1,.ck.ck-content h2,.ck.ck-content h3,.ck.ck-content h4,.ck.ck-content h5,.ck.ck-content h6,.ck.ck-content p,.ck.ck-content blockquote,.ck.ck-content pre,.ck.ck-content a,.ck.ck-content abbr,.ck.ck-content acronym,.ck.ck-content address,.ck.ck-content big,.ck.ck-content cite,.ck.ck-content code,.ck.ck-content del,.ck.ck-content dfn,.ck.ck-content em,.ck.ck-content font,.ck.ck-content img,.ck.ck-content ins,.ck.ck-content kbd,.ck.ck-content q,.ck.ck-content s,.ck.ck-content samp,.ck.ck-content small,.ck.ck-content strike,.ck.ck-content strong,.ck.ck-content sub,.ck.ck-content sup,.ck.ck-content tt,.ck.ck-content var,.ck.ck-content dl,.ck.ck-content dt,.ck.ck-content dd,.ck.ck-content ol,.ck.ck-content ul,.ck.ck-content li,.ck.ck-content fieldset,.ck.ck-content form,.ck.ck-content label,.ck.ck-content legend,.ck.ck-content table,.ck.ck-content caption,.ck.ck-content tbody,.ck.ck-content tfoot,.ck.ck-content thead,.ck.ck-content tr,.ck.ck-content th,.ck.ck-content td,.ck.ck-content hr,.ck.ck-content input,.ck.ck-content textarea{box-sizing:border-box;}</style><style class="RTEContentCssDefault">.ck.ck-content{font-family:Geneva,Helvetica,Arial,sans-serif; font-size: 12px; line-height: 1.5;}</style></head><body class="ck ck-content"><p>Hello,</p>
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
                'Filesize'        => 16920,
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
