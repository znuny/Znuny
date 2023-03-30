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

        // Bind event on Simulate RTL button
        $('.DebugRTL').on('click', function () {
            Core.Debug.SimulateRTLPage();
        });

        // Initialize toolbar
        TargetNS.InitToolBar();

    };

    /**
     * @private
     * @name InitToolBar
     * @memberof Core.Agent.Header
     * @function
     * @description
     *      This function initialize toolbar
     */
    TargetNS.InitToolBar = function () {
        var CurrentToolbarHeight;

        if (!$("#ToolBar").length){
            return;
        }

        // Initialize header refresh
        TargetNS.InitToolBarOverview();

        // Initialize all toolbar search backends
        TargetNS.InitToolBarSearch();

        // Get initial ToolBar height on page load
        CurrentToolbarHeight = $("#ToolBar .toolbar-row").outerHeight();

        // Check ToolBar visibility status and toggle accordingly
        function CheckToolBarVisibility() {
            if ($("#ToolBar").hasClass("hide")) {
                // Get ToolBar current height and use it to hide up
                $("#ToolBar").css("margin-top", -$("#ToolBar .toolbar-row").outerHeight());
                Core.Agent.PreferencesUpdate('UserToolBar', 0);
            }
            else {
                $("#ToolBar").css("margin-top", 0);
                Core.Agent.PreferencesUpdate('UserToolBar', 1);
            }
        }

        // Toggle ToolBar visibility on toggle button click
        $("#ToolBar-toggle").on("click", function() {
            $("#ToolBar").toggleClass("hide");
            CheckToolBarVisibility();
        });

        // Check for ToolBar height change on window resize
        $("#ToolBar").on("resize", function() {
            var NewToolbarHeight = $("#ToolBar .toolbar-row").outerHeight();
            if(NewToolbarHeight !== CurrentToolbarHeight && $("#ToolBar").hasClass("hide")) {
                CurrentToolbarHeight = NewToolbarHeight;
                CheckToolBarVisibility();
            }
        });
    }

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
        if (!$("#ToolBar").length){
            return;
        }

        $('#ToolBarSearchTerm').on('click', function () {
            $("#ToolBarSearchTerm").next('#AJAXLoaderToolBarSearchTerm').remove();
        });

        $('input[type=radio][name=ToolBarSearchBackend]').change(function() {
            $('#ToolBarSearchTerm').focus();
            Backend = this.value;
            TargetNS.InitToolBarSearchBackend(Backend);
            $('#ToolBarSearchTerm').attr('title', $(this).attr('title'));
            $('#ToolBarSearchTerm').attr('placeholder', $(this).attr('title'));
        });
        TargetNS.InitToolBarSearchBackend(Backend);
    }

    /**
     * @private
     * @name InitToolBarSearchBackend
     * @memberof Core.Agent.Header
     * @function
     * @param {Name} Backend
     * @description
     *      This function initialize toolbar search
     */
    TargetNS.InitToolBarSearchBackend = function (Backend) {
        Core.Agent.PreferencesUpdate('UserToolBarSearchBackend', Backend);

        if ($('#ToolBarSearchTerm').attr('autocomplete')){
            $('#ToolBarSearchTerm').autocomplete("destroy");
            $('#ToolBarSearchTerm').removeData('autocomplete');
        }

        if (Backend == 'ToolBarSearchBackendFulltext'){

            $("form[name='ToolBarSearch']").unbind();

            // Initialize full text search
            Core.Agent.Search.InitToolbarFulltextSearch();
        }
        else if (Backend == 'ToolBarSearchBackendCustomerID'){

            // Initialize auto complete searches
            Core.Agent.CustomerInformationCenterSearch.InitAutocomplete($('#ToolBarSearchTerm'), "SearchCustomerID");

            $("form[name='ToolBarSearch']").submit(function(Event){
                Event.preventDefault();
                Event.stopPropagation();
            });
        }
        else if (Backend == 'ToolBarSearchBackendCustomerUser'){
            // Initialize auto complete searches
            Core.Agent.CustomerUserInformationCenterSearch.InitAutocomplete($('#ToolBarSearchTerm'), "SearchCustomerUser");

            $("form[name='ToolBarSearch']").submit(function(Event){
                Event.preventDefault();
                Event.stopPropagation();
            });
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
        var RefreshTimeToolbar = Core.Config.Get('RefreshTimeToolbar'),
            RefreshTime = Core.Config.Get('Refresh');

        if (!$("#ToolBar").length) {
            return;
        }
        if (RefreshTime || !RefreshTimeToolbar) {
            return;
        }

        Core.Config.Set('RefreshSecondsToolbar', parseInt(RefreshTimeToolbar, 10) || 0);
        if (!Core.Config.Get('RefreshSecondsToolbar')) {
            return;
        }

        Core.Config.Set(
            'TimerToolbar',
            window.setTimeout(
                function() {
                    var Data = {
                        Action:    'AgentDashboard',
                        Subaction: 'ToolbarFetch',
                    };

                    Core.AJAX.FunctionCall(
                        Core.Config.Get('Baselink'),
                        Data,
                        function (Response) {

                            $('.toolbar-row').remove();
                            $('#ToolBar').prepend(Response);

                            Core.UI.InputFields.Init();
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
