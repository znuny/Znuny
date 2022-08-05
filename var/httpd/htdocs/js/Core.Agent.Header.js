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

        // toggle .toolbar-row view
        $("#ToolBar-toggle").on("click", function() {
            $(".toolbar-row-wrapper").toggleClass("hide");

            if ($(".toolbar-row-wrapper").hasClass("hide")) {
                $("#ToolBar-toggle i").addClass('expanded');                  // todo

                $("#ToolBar-toggle i").css("margin", "2px 0 0 0");            // todo move this to Core.Header.css?
                $("#ToolBar-toggle i").css("transform", "rotate(180deg)");    // todo move this to Core.Header.css?
                Core.Agent.PreferencesUpdate('UserToolBar', 0);
            }
            else {
                $("#ToolBar-toggle i").removeClass('expanded');               // todo

                $("#ToolBar-toggle i").css("margin", "0 0 2px 0");            // todo move this to Core.Header.css?
                $("#ToolBar-toggle i").css("transform", "rotate(0deg)");      // todo move this to Core.Header.css?
                Core.Agent.PreferencesUpdate('UserToolBar', 1);
            }
        });

        // Initialize header refresh
        TargetNS.InitToolBarOverview();

        // Initialize all toolbar search backends
        TargetNS.InitToolBarSearch();

        // Bind event on Simulate RTL button
        $('.DebugRTL').on('click', function () {
            Core.Debug.SimulateRTLPage();
        });

    };

    /**
     * @private
     * @name InitToolbarSearch
     * @memberof Core.Agent.Header
     * @function
     * @description
     *      This function initialize toolbar search
     */
    TargetNS.InitToolBarSearch = function () {
        var Backend = $('input[type=radio][name=ToolBarSearchBackend]:checked').val();
        $('input[type=radio][name=ToolBarSearchBackend]').change(function() {
            Backend = this.value;
            TargetNS.InitToolBarSearchBackend(Backend);
        });
        TargetNS.InitToolBarSearchBackend(Backend);
    }

    /**
     * @private
     * @name InitToolBarSearchBackend
     * @memberof Core.Agent.Header
     * @function
     * @description
     *      This function initialize toolbar search
     */
    TargetNS.InitToolBarSearchBackend = function (Backend) {
        Core.Agent.PreferencesUpdate('UserToolBarSearchBackend', Backend);

        if (Backend == 'ToolBarSearchBackendFulltext'){
            // Initialize full text search
            Core.Agent.Search.InitToolbarFulltextSearch();
        }
        else if (Backend == 'ToolBarSearchBackendCustomerID'){

            // Initialize auto complete searches
            Core.Agent.CustomerInformationCenterSearch.InitAutocomplete($('#ToolBarSearchTerm'), "SearchCustomerID");
        }
        else if (Backend == 'ToolBarSearchBackendCustomerUser'){

            // Initialize auto complete searches
            Core.Agent.CustomerUserInformationCenterSearch.InitAutocomplete($('#ToolBarSearchTerm'), "SearchCustomerUser");
        }
    }

    /**
     * @private
     * @name InitToolBarOverview
     * @memberof Core.Agent.Header
     * @function
     * @description
     *      This function initialize header refresh.
     */
    TargetNS.InitToolBarOverview = function () {
        var RefreshTime = Core.Config.Get('RefreshTimeToolbar');

        if (!RefreshTime) {
            return;
        }

        Core.Config.Set('RefreshSecondsToolbar', parseInt(RefreshTime, 10) || 0);

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
                            $.each(Response.IconsOrder, function(index,value) {
                                if (!$('li[class="' + value + '"]').length) {
                                    $('<li class ="' + value + '"></li>').insertAfter($('li[class="' + Response.IconsOrder[index-1] + '"]'));
                                }

                                if (value == "UserAvatar") {
                                    return;
                                }

                                $('li[class="' + value + '"]').html(Response.Icons[Response.IconsOrder[index]]);
                            });

                            $("#ToolBar").children().each(function(index,element) {
                                if ($.inArray(element.className, Response.IconsOrder) == -1) {
                                    $('li[class="' + element.className + '"]').remove();
                                }
                            });

                            TargetNS.InitToolBarOverview();
                        }
                    );
                },
                Core.Config.Get('RefreshSecondsToolbar') * 1000
            )
        );
    }

    Core.Init.RegisterNamespace(TargetNS, 'APP_MODULE');

    return TargetNS;
}(Core.Agent.Header || {}));
