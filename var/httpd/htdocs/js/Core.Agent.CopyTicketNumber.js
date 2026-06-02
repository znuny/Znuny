// --
// Copyright (C) 2021 Znuny GmbH, https://znuny.org/
// --
// This software comes with ABSOLUTELY NO WARRANTY. For details, see
// the enclosed file COPYING for license information (AGPL). If you
// did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
// --

"use strict";

var Core   = Core || {};
Core.Agent = Core.Agent || {};

/**
 * @namespace
 * @exports TargetNS as Core.Agent.CopyTicketNumber
 * @description
 *      This namespace contains the special functions for ZnunyCopyTicketNumber.
 */
Core.Agent.CopyTicketNumber = (function (TargetNS) {

    /**
     * @description
     *     Initialize the copy ticket number functionality
     */
    TargetNS.Init = function () {
        TargetNS.AddCopyIcon();
        TargetNS.BindEvents();
    };

    /**
     * @description
     *     Add copy icon before the ticket number in the headline
     */
    TargetNS.AddCopyIcon = function () {
        var $Headline = $('h1.ticketHeaderTitleHeadline'),
            TicketNumber,
            TicketTitle,
            $CopyIcon,
            $HoverMenu,
            CopyIconHTML,
            HoverMenuHTML;

        if (!$Headline.length) {
            return;
        }

        // Check if copy icon already exists
        if ($Headline.find('.CopyTicketIcon').length) {
            return;
        }

        TicketNumber = $Headline.data('ticket-number');
        TicketTitle  = $Headline.data('ticket-title') || '';

        if (!TicketNumber) {
            return;
        }

        // Create copy icon with hover menu
        CopyIconHTML  = Core.Template.Render('Agent/TicketZoom/CopyTicketNumber/Icon', {});
        HoverMenuHTML = Core.Template.Render('Agent/TicketZoom/CopyTicketNumber/Menu', {
            'TicketNumber': TicketNumber,
            'TicketTitle':  TicketTitle,
        });

        // Convert HTML strings to jQuery objects
        $CopyIcon  = $(CopyIconHTML);
        $HoverMenu = $(HoverMenuHTML);

        // Add the hover menu to the copy icon
        if (!$CopyIcon.length || !$HoverMenu.length) {
            console.error('Failed to render copy icon or hover menu template.');
            return;
        }

        $CopyIcon.append($HoverMenu);

        // Insert the copy icon inside the h1 element to preserve the grid layout
        $Headline.prepend($CopyIcon);
    };

    /**
     * @description
     *     Bind events for the copy functionality
     */
    TargetNS.BindEvents = function () {
        $('.CopyOption').on('click', function (Event) {
            var Action       = $(this).data('action'),
                TicketNumber = $(this).data('number'),
                TicketTitle  = $(this).data('title');

            Event.preventDefault();
            Event.stopPropagation();

            if (Action === 'copy-number') {
                TargetNS.CopyToClipboard(TicketNumber);
            } else if (Action === 'copy-number-title') {
                TargetNS.CopyToClipboard(TicketNumber + ' — ' + TicketTitle);
            }
        });
    };

    /**
     * @param {String} Text
     * @description
     *     Copy text to clipboard
     */
    TargetNS.CopyToClipboard = function (Text) {
        if (navigator.clipboard && window.isSecureContext) {
            // Use modern clipboard API
            navigator.clipboard.writeText(Text).then(function () {
                TargetNS.ShowCopySuccess();
            }).catch(function () {
                TargetNS.FallbackCopy(Text);
            });
        } else {
            // Fallback for older browsers
            TargetNS.FallbackCopy(Text);
        }
    };

    /**
     * @param {String} Text
     * @description
     *     Fallback copy method for older browsers
     */
    TargetNS.FallbackCopy = function (Text) {
        var TextArea = document.createElement('textarea');

        TextArea.value          = Text;
        TextArea.style.position = 'fixed';
        TextArea.style.left     = '-999999px';
        TextArea.style.top      = '-999999px';
        document.body.appendChild(TextArea);
        TextArea.focus();
        TextArea.select();

        try {
            document.execCommand('copy');
            TargetNS.ShowCopySuccess();
        } catch (Error) {
            console.error('Copy failed:', Error);
        }

        document.body.removeChild(TextArea);
    };

    /**
     * Show copy success message
     */
    TargetNS.ShowCopySuccess = function () {

        var SuccessMessage = Core.Language.Translate('Copied to clipboard!');

        Core.UI.ShowNotification(
            SuccessMessage,
            'Success',
            '', // no link
            function() {
                setTimeout(function () {
                    Core.UI.HideNotification(
                        SuccessMessage,
                        'Success'
                    );
                }, 2000);
            },
            'CopyTicketNumber',
            'fa-bell'
        );
    };

    Core.Init.RegisterNamespace(TargetNS, 'APP_MODULE');

    return TargetNS;
}(Core.Agent.CopyTicketNumber || {}));
