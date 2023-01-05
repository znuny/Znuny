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
 * @namespace Core.Agent.Header
 * @memberof Core.Agent
 * @author OTRS AG
 * @description
 *      This namespace contains the functions for handling Header in framework.
 */
Core.Agent.Header = (function (TargetNS) {

    /**
     * @name Init
     * @memberof Core.Agent.Header
     * @function
     * @description
     *      Initializes the module functionality.
     */
    TargetNS.Init = function () {

        // Initialize header refresh.
        TargetNS.InitToolbarOverview();

        // Bind event on ToolBarSearchProfile field
        $('#ToolBarSearchProfile').on('change', function (Event) {
            $(Event.target).closest('form').submit();
            Event.preventDefault();
            Event.stopPropagation();
            return false;
        });

        // Initialize auto complete searches
        Core.Agent.CustomerInformationCenterSearch.InitAutocomplete($('#ToolBarCICSearchCustomerID'), "SearchCustomerID");
        Core.Agent.CustomerUserInformationCenterSearch.InitAutocomplete($('#ToolBarCICSearchCustomerUser'), "SearchCustomerUser");

        // Initialize full text search
        Core.Agent.Search.InitToolbarFulltextSearch();

        // Bind event on Simulate RTL button
        $('.DebugRTL').on('click', function () {
            Core.Debug.SimulateRTLPage();
        });

    };

    /**
     * @private
     * @name InitToolbarOverview
     * @memberof Core.Agent.Header
     * @function
     * @description
     *      This function initialize header refresh.
     */
    TargetNS.InitToolbarOverview = function () {
        var ToolbarRefreshTime = Core.Config.Get('RefreshTimeToolbar'),
            RefreshTime = Core.Config.Get('Refresh');

        if (RefreshTime || !ToolbarRefreshTime) {
            return;
        }

        Core.Config.Set('RefreshSecondsToolbar', parseInt(ToolbarRefreshTime, 10) || 0);

        if (!Core.Config.Get('RefreshSecondsToolbar')) {
            return;
        }

        Core.Config.Set(
            'TimerToolbar',
            window.setTimeout(
                function() {
                    var Data = {
                        Action:    'AgentDashboard',
                        Subaction: 'ToolbarFetch'
                    };

                    Core.AJAX.FunctionCall(
                        Core.Config.Get('Baselink'),
                        Data,
                        function (Response) {
                            $('#ToolBar li:not(.UserAvatar)').remove()
                            $('#ToolBar').append(Response)

                            Core.UI.InputFields.Init()
                            TargetNS.Init();
                        },
                        'html'
                    );
                },
                Core.Config.Get('RefreshSecondsToolbar') * 1000
            )
        );
    }

    Core.Init.RegisterNamespace(TargetNS, 'APP_MODULE');

    return TargetNS;
}(Core.Agent.Header || {}));
