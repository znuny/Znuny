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
 * @exports TargetNS as Core.Agent.TicketNoteToLinkedTicket
 * @description
 *      This namespace contains the special functions for TicketNoteToLinkedTicket.
 */
Core.Agent.TicketNoteToLinkedTicket = (function (TargetNS) {

    TargetNS.Init = function () {
        RemoveArticleActionNoteToLinkedTicket();
        return true;
    }

    // This will only be executed for link object view mode "Complex", see Perl ArticleAction
    // module TicketNoteToLinkedTicket.pm.
    function RemoveArticleActionNoteToLinkedTicket() {
        var $TicketDeleteLinks = $('#WidgetTicket > .Content > #Ticket > .DataTable a.LinkObjectLink');

        // Remove article action menu item if no ticket links are left.
        if (!$TicketDeleteLinks.length) {
            $('a.PopupType_TicketAction[href*="?Action=AgentTicketNoteToLinkedTicket;"]').closest('li').remove();

            return true;
        }

        window.setTimeout(
            RemoveArticleActionNoteToLinkedTicket,
            500
        )
    }

    return TargetNS;
}(Core.Agent.TicketNoteToLinkedTicket || {}));
