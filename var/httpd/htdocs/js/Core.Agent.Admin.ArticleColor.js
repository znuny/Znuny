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
 * @namespace Core.Agent.Admin.ArticleColor
 * @memberof Core.Agent.Admin
 * @author Znuny GmbH
 * @description
 *      This namespace contains the special module function for AdminArticleColor.
 */
Core.Agent.Admin.ArticleColor = (function (TargetNS) {

    /*
    * @name Init
    * @memberof Core.Agent.Admin.ArticleColor
    * @function
    * @description
    *      This function initializes filter.
    */
    TargetNS.Init = function () {

        Core.UI.Table.InitTableFilter($("#FilterArticle"), $("#Articles"));

        Core.Config.Set('EntityType', 'ArticleColor');
    };

    Core.Init.RegisterNamespace(TargetNS, 'APP_MODULE');

    return TargetNS;
}(Core.Agent.Admin.ArticleColor || {}));
