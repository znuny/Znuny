// --
// Copyright (C) 2001-2021 OTRS AG, https://otrs.com/
// Copyright (C) 2021 Znuny GmbH, https://znuny.org/
// --
// This software comes with ABSOLUTELY NO WARRANTY. For details, see
// the enclosed file COPYING for license information (GPL). If you
// did not receive this file, see https://www.gnu.org/licenses/gpl-3.0.txt.
// --

"use strict";

var Core = Core || {};
Core.Agent = Core.Agent || {};

/**
 * @namespace Core.Agent.TicketEmailResend
 * @memberof Core.Agent
 * @author OTRS AG
 * @description
 *      This namespace contains the special module functions for TicketEmailResend.
 */
Core.Agent.TicketEmailResend = (function (TargetNS) {

    /**
     * @name Init
     * @memberof Core.Agent.TicketEmailResend
     * @function
     * @description
     *      This function initializes .
     */
    TargetNS.Init = function () {
        var ArticleComposeOptions = Core.Config.Get('ArticleComposeOptions');

        // Change article compose options.
        if (typeof ArticleComposeOptions !== 'undefined') {
            $.each(ArticleComposeOptions, function (Key, Value) {
                $('#'+Value.Name).on('change', function () {
                    Core.AJAX.FormUpdate($('#ComposeTicket'), 'AJAXUpdate', Value.Name, Value.Fields);
                });
            });
        }
    };

    Core.Init.RegisterNamespace(TargetNS, 'APP_MODULE');

    return TargetNS;
}(Core.Agent.TicketEmailResend || {}));
