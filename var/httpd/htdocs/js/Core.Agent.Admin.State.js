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
* @namespace Core.Agent.Admin.State
* @memberof Core.Agent.Admin
* @author OTRS AG
* @description
*      This namespace contains the special function for AdminState module.
*/
Core.Agent.Admin.State = (function (TargetNS) {

    /*
    * @name Init
    * @memberof Core.Agent.Admin.State
    * @function
    * @description
    *      This function initializes table filter.
    */
    TargetNS.Init = function () {
        Core.UI.Table.InitTableFilter($('#FilterStates'), $('#States'));

        Core.Config.Set('EntityType', 'State');

        TargetNS.ValidationInit();
    };

    /**
    * @name ValidationInit
    * @memberof Core.Agent.Admin.State
    * @function
    * @description
    *      Adds specific validation rules to the frontend module.
    */
    TargetNS.ValidationInit = function() {
        Core.Form.Validate.AddRule("Validate_Color", {
            /*eslint-disable camelcase */
            Validate_Color: true
            /*eslint-enable camelcase */
        });
        Core.Form.Validate.AddMethod("Validate_Color", function (Value) {
            return (/^#(?:[0-9a-fA-F]{3}){1,2}$/.test(Value));
        }, "");
    };

    Core.Init.RegisterNamespace(TargetNS, 'APP_MODULE');

    return TargetNS;
}(Core.Agent.Admin.State || {}));
