// --
// Copyright (C) 2001-2021 OTRS AG, https://otrs.com/
// Copyright (C) 2021-2022 Znuny GmbH, https://znuny.org/
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
 * @namespace Core.Agent.Admin.RoleUser
 * @memberof Core.Agent.Admin
 * @author OTRS AG
 * @description
 *      This namespace contains the special module function for RoleUser selection.
 */
 Core.Agent.Admin.RoleUser = (function (TargetNS) {

    /*
    * @name Init
    * @memberof Core.Agent.Admin.RoleUser
    * @function
    * @description
    *      This function initializes filter and "SelectAll" actions.
    */
    TargetNS.Init = function () {
        var RelationItems = Core.Config.Get('RelationItems');

        // initialize "SelectAll" checkbox and bind click event on "SelectAll" for each relation item
        if (RelationItems) {
            $.each(RelationItems, function (index) {
                Core.Form.InitSelectAllCheckboxes($('table td input[type="checkbox"][name=' + RelationItems[index] + ']'), $('#SelectAll' + RelationItems[index]));

                $('input[type="checkbox"][name=' + RelationItems[index] + ']').click(function () {
                    Core.Form.SelectAllCheckboxes($(this), $('#SelectAll' + RelationItems[index]));
                });
            });
        }

        // initialize table filters
        Core.UI.Table.InitTableFilter($("#Filter"), $("#UserRoles"));
        Core.UI.Table.InitTableFilter($("#FilterUsers"), $("#Users"));
        Core.UI.Table.InitTableFilter($("#FilterRoles"), $("#Roles"));
    };

    Core.Init.RegisterNamespace(TargetNS, 'APP_MODULE');

    return TargetNS;
}(Core.Agent.Admin.RoleUser || {}));
