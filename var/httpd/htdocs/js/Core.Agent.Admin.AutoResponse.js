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
Core.Agent.Admin = Core.Agent.Admin || {};

/**
 * @namespace Core.Agent.Admin.AutoResponse
 * @memberof Core.Agent.Admin
 * @author OTRS AG
 * @description
 *      This namespace contains the special module function for AutoResponse module.
 */
Core.Agent.Admin.AutoResponse = (function (TargetNS) {

    /**
     * @name Init
     * @memberof Core.Agent.Admin.AutoResponse
     * @function
     * @description
     *      This function initializes the table filter.
     */
    TargetNS.Init = function () {
        Core.UI.Table.InitTableFilter($("#FilterAutoResponses"), $("#AutoResponses"));

        // delete auto response
        TargetNS.InitAutoResponseDelete();
    };

    /**
     * @name AutoResponseDelete
     * @memberof Core.Agent.Admin.AutoResponse
     * @function
     * @description
     *      This function deletes an auto response on button click.
     */
    TargetNS.InitAutoResponseDelete = function () {
        $('.AutoResponseDelete').on('click', function () {
            var AutoResponseDelete = $(this);

            Core.UI.Dialog.ShowContentDialog(
                $('#DeleteAutoResponseDialogContainer'),
                Core.Language.Translate('Delete this %s', 'auto response'),
                '240px',
                'Center',
                true,
                [
                    {
                        Class: 'Primary',
                        Label: Core.Language.Translate("Confirm"),
                        Function: function() {
                            $('.Dialog .InnerContent .Center').text(Core.Language.Translate("Deleting the %s and its data. This may take a while...", "auto response"));
                            $('.Dialog .Content .ContentFooter').remove();

                            Core.AJAX.FunctionCall(
                                Core.Config.Get('Baselink'),
                                AutoResponseDelete.data('query-string'),
                                function() {
                                    Core.App.InternalRedirect({
                                        Action: 'AdminAutoResponse'
                                    });
                                }
                            );
                        }
                    },
                    {
                        Label: Core.Language.Translate("Cancel"),
                        Function: function () {
                            Core.UI.Dialog.CloseDialog($('#DeleteAutoResponseDialog'));
                        }
                    }
                ]
            );
            return false;
        });
    };

    Core.Init.RegisterNamespace(TargetNS, 'APP_MODULE');

    return TargetNS;
}(Core.Agent.Admin.AutoResponse || {}));
