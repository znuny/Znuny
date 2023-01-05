// --
// Copyright (C) 2021 Znuny GmbH, https://znuny.org/
// --
// This software comes with ABSOLUTELY NO WARRANTY. For details, see
// the enclosed file COPYING for license information (AGPL). If you
// did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
// --

"use strict";

var Core         = Core || {};
Core.Agent       = Core.Agent || {};
Core.Agent.Admin = Core.Agent.Admin || {};

/**
 * @namespace Core.Agent.Admin.WebserviceNotification
 * @memberof Core.Agent.Admin
 */
Core.Agent.Admin.WebserviceNotification = (function (TargetNS) {

    /**
     * @name UpdateInvokers
     * @memberof Core.Agent.Admin.WebserviceNotifications
     * @function
     * @description
     *      Updates the invoker selection.
     */
    TargetNS.UpdateInvokers = function() {
        var AJAXData,
            WebserviceID    = $("#TransportWebserviceID").val(),
            InvokerSelector = $('#TransportWebserviceInvokerName'),
            InvokerSearchBox= $('#TransportWebserviceInvokerName_Search');

        AJAXData = {
            Action       : 'AJAXNotificationEventTransportWebservice',
            Subaction    : 'GetWebserviceInvokers',
            WebserviceID : WebserviceID,
        };

        Core.AJAX.FunctionCall(
            Core.Config.Get('Baselink'),
            AJAXData,
            function (Response) {
                InvokerSelector.empty();
                InvokerSelector.append('<option value="">-</option>');

                if (Response && Array.isArray(Response.Data) && Response.Data.length) {
                    $.each(Response.Data, function(Key, Value) {
                        InvokerSelector.append('<option value="' + Value + '">' + Value + '</option>');
                    });

                    InvokerSearchBox.removeAttr('readonly');
                }
                else {
                    InvokerSearchBox.attr('readonly', 'readonly');
                }

                InvokerSelector.trigger('redraw.InputField')
            }
        );
    };

    Core.Init.RegisterNamespace(TargetNS, 'APP_MODULE');

    return TargetNS;
}(Core.Agent.Admin.WebserviceNotification || {}));
