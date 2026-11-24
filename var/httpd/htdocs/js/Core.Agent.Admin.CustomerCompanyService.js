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
Core.Agent.Admin = Core.Agent.Admin || {};

/**
 * @namespace Core.Agent.Admin.CustomerCompanyService
 * @memberof Core.Agent.Admin
 * @author Znuny GmbH
 * @description
 *      This namespace contains the special module function for CustomerCompanyService selection.
 */
Core.Agent.Admin.CustomerCompanyService = (function (TargetNS) {

    /**
     * @name Init
     * @memberof Core.Agent.Admin.CustomerCompanyService
     * @function
     * @description
     *      This function initializes filter and "SelectAll" actions.
     */
    TargetNS.Init = function () {
        Core.Form.InitSelectAllCheckboxes($('table td input[type="checkbox"][name=ItemsSelected]'), $('#SelectAllItemsSelected'));

        $('input[type="checkbox"][name=ItemsSelected]').on('click', function () {
            Core.Form.SelectAllCheckboxes($(this), $('#SelectAllItemsSelected'));
        });

        Core.UI.Table.InitTableFilter($('#FilterServices'), $('#Service'));
    };

    Core.Init.RegisterNamespace(TargetNS, 'APP_MODULE');

    return TargetNS;
}(Core.Agent.Admin.CustomerCompanyService || {}));
