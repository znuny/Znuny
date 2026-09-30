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
Core.Agent.Admin = Core.Agent.Admin || {};

/**
 * @namespace
 * @exports TargetNS as Core.Agent.Admin.DBCRUD
 * @description
 *      This namespace contains the special functions for DBCRUD.
 */
Core.Agent.Admin.DBCRUD = (function (TargetNS) {

    TargetNS.Init = function () {
        TargetNS.Copy();
        TargetNS.Delete();
    }

    TargetNS.Copy = function() {
        $('.Copy').on('click', function () {
            var ObjectCopy = $(this);
            Core.AJAX.FunctionCall(
                Core.Config.Get('Baselink'),
                ObjectCopy.data('query-string'),
                function(Response) {

                    if (!Response.Action) {
                        Response.Action = Core.Config.Get('Action');
                    }

                    Core.App.InternalRedirect(Response);
                }
            );

            return false;
        });
    };

    TargetNS.Delete = function() {
        $('.Delete').on('click', function () {
            var ObjectDelete = $(this);

            Core.UI.Dialog.ShowContentDialog(
                $('#DeleteDialogContainer'),
                Core.Language.Translate('Delete'),
                '240px',
                'Center',
                true,
                [
                    {
                        Type: 'Secondary',
                        Label: Core.Language.Translate("Cancel"),
                        Function: function () {
                            Core.UI.Dialog.CloseDialog($('#DeleteDialog'));
                        }
                    },
                    {
                        Type: 'Warning',
                        Label: Core.Language.Translate('Delete'),
                        Function: function() {
                            $('.Dialog .InnerContent .Center').text(Core.Language.Translate("Deleting the object and its data. This may take a while..."));
                            $('.Dialog .Content .ContentFooter').remove();

                            Core.AJAX.FunctionCall(
                                Core.Config.Get('Baselink'),
                                ObjectDelete.data('query-string'),
                                function() {
                                    Core.App.InternalRedirect({
                                        Action: Core.Config.Get('Action')
                                    });
                                }
                            );
                        }
                    },

                ]
            );
            return false;
        });
    };

    Core.Init.RegisterNamespace(TargetNS, 'APP_MODULE');

    return TargetNS;
}(Core.Agent.Admin.DBCRUD || {}));
