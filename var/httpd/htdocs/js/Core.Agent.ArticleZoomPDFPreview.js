// --
// Copyright (C) 2021 Znuny GmbH, https://znuny.org/
// --
// This software comes with ABSOLUTELY NO WARRANTY. For details, see
// the enclosed file COPYING for license information (AGPL). If you
// did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
// --

"use strict";

var Core = Core || {};
Core.Agent = Core.Agent || {};

/**
 * @namespace
 * @exports TargetNS as Core.Agent.ArticleZoomPDFPreview
 * @description
 *      Inline PDF preview for article attachments in AgentTicketZoom.
 */
Core.Agent.ArticleZoomPDFPreview = (function (TargetNS) {
    var ActiveArticleAttachmentLink,
        Config;

    /**
     * @name Init
     * @memberof Core.Agent.ArticleZoomPDFPreview
     * @function
     * @description
     *      Initializes PDF preview bindings.
     */
    TargetNS.Init = function () {
        Config = Core.Config.Get('ZoomArticlePDFPreview') || {};

        if (!Config.Active) {
            return;
        }

        TargetNS.Bind();

        if (Config.ShowFirstPreview) {
            TargetNS.ShowFirstPreview();
        }

        if (!Core.Config.Get('ZoomExpand')) {
            Core.App.Subscribe('Event.AJAX.ContentUpdate.Callback', function () {
                ActiveArticleAttachmentLink = undefined;
                TargetNS.Bind();
                if (Config.ShowFirstPreview) {
                    TargetNS.ShowFirstPreview();
                }
            });
        }
        return;
    };

    /**
     * @name Bind
     * @memberof Core.Agent.ArticleZoomPDFPreview
     * @function
     * @description
     *      Binds click handlers for PDF preview links.
     */
    TargetNS.Bind = function () {
        $('a.ArticleAttachmentPreview').off('click.ArticleAttachmentPreview').on('click.ArticleAttachmentPreview', function (Event) {
            var $ArticleAttachment = $(this).closest('ul.ArticleAttachments'),
                ArticleAttachmentLink = $(this).attr('href');

            Event.preventDefault();
            TargetNS.TogglePreview($ArticleAttachment, ArticleAttachmentLink);
            return false;
        });
        return;
    };

    /**
     * @name ShowFirstPreview
     * @memberof Core.Agent.ArticleZoomPDFPreview
     * @function
     * @description
     *      Shows the first article attachment PDF preview below the attachment list.
     */
    TargetNS.ShowFirstPreview = function () {
        var $FirstArticleAttachment = $('ul.ArticleAttachments a.ArticleAttachmentPreview').first(),
            $ArticleAttachment,
            ArticleAttachmentLink;

        if (!$FirstArticleAttachment.length) {
            return;
        }

        $ArticleAttachment = $FirstArticleAttachment.closest('ul.ArticleAttachments');
        ArticleAttachmentLink = $FirstArticleAttachment.attr('href');

        TargetNS.TogglePreview($ArticleAttachment, ArticleAttachmentLink);
        return;
    };

    /**
     * @name TogglePreview
     * @memberof Core.Agent.ArticleZoomPDFPreview
     * @function
     * @param {jQueryObject} $ArticleAttachment
     * @param {String} ArticleAttachmentLink
     * @description
     *      Toggles the PDF preview iframe for the given attachment link.
     */
    TargetNS.TogglePreview = function ($ArticleAttachment, ArticleAttachmentLink) {
        var Width = Config.Width || '100%',
            Height = Config.Height || '500px';

        $('.ArticleAttachmentPreviewIframe').remove();

        if (ActiveArticleAttachmentLink === ArticleAttachmentLink) {
            ActiveArticleAttachmentLink = undefined;
            return;
        }

        $ArticleAttachment.after(
            '<iframe src="' + ArticleAttachmentLink + '" class="ArticleAttachmentPreviewIframe" style="width: ' + Width + ';height: ' + Height + ';"></iframe>'
        );

        ActiveArticleAttachmentLink = ArticleAttachmentLink;
        return;
    };

    return TargetNS;
}(Core.Agent.ArticleZoomPDFPreview || {}));

Core.Init.RegisterNamespace(Core.Agent.ArticleZoomPDFPreview, 'APP_MODULE');
