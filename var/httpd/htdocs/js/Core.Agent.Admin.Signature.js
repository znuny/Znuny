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
 * @namespace Core.Agent.Admin.Signature
 * @memberof Core.Agent.Admin
 * @author OTRS AG
 * @description
 *      This namespace contains the special function for AdminSignature module.
 */
Core.Agent.Admin.Signature = (function (TargetNS) {

    /*
    * @name Init
    * @memberof Core.Agent.Admin.Signature
    * @function
    * @description
    *      This function initializes table filter.
    */
    TargetNS.Init = function () {
        Core.UI.Table.InitTableFilter($('#FilterSignatures'), $('#Signatures'));

        // delete signature
        TargetNS.InitSignatureDelete();
    };

    /**
     * @name SignatureDelete
     * @memberof Core.Agent.Admin.Signature
     * @function
     * @description
     *      This function deletes an signature on button click.
     */
    TargetNS.InitSignatureDelete = function () {
        $('.SignatureDelete').on('click', function () {
            var SignatureDelete = $(this);

            Core.UI.Dialog.ShowContentDialog(
                $('#DeleteSignatureDialogContainer'),
                Core.Language.Translate('Delete this %s', 'signature'),
                '240px',
                'Center',
                true,
                [
                    {
                        Class: 'Primary',
                        Label: Core.Language.Translate("Confirm"),
                        Function: function() {
                            $('.Dialog .InnerContent .Center').text(Core.Language.Translate("Deleting the %s and its data. This may take a while...", "signature"));
                            $('.Dialog .Content .ContentFooter').remove();

                            Core.AJAX.FunctionCall(
                                Core.Config.Get('Baselink'),
                                SignatureDelete.data('query-string'),
                                function() {
                                    Core.App.InternalRedirect({
                                        Action: 'AdminSignature'
                                    });
                                }
                            );
                        }
                    },
                    {
                        Label: Core.Language.Translate("Cancel"),
                        Function: function () {
                            Core.UI.Dialog.CloseDialog($('#DeleteSignatureDialog'));
                        }
                    }
                ]
            );
            return false;
        });
    };

    Core.Init.RegisterNamespace(TargetNS, 'APP_MODULE');

    return TargetNS;
}(Core.Agent.Admin.Signature || {}));
