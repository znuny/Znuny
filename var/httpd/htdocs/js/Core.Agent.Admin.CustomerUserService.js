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
 * @namespace Core.Agent.Admin.CustomerUserService
 * @memberof Core.Agent.Admin
 * @author OTRS AG
 * @description
 *      This namespace contains the special module function for CustomerUserService selection.
 */
Core.Agent.Admin.CustomerUserService = (function (TargetNS) {

    var DefaultServiceData = {};

    /**
     * @name HideShowDefaultServices
     * @memberof Core.Agent.Admin.CustomerUserService
     * @function
     * @description
     *      Hides or shows default services when other services are selected.
     * @returns {Boolean} Returns true when the allocate-service view is skipped.
     */
    TargetNS.HideShowDefaultServices = function () {

        // skip if we are in the 'AllocateService' view
        if (
            $('input[name=Subaction]').length
            && $('input[name=Subaction]').val() === 'AllocateService'
            )
        {
            return true;
        }

        // A manually selected service removes inherited default service marks.
        if ($('tbody input[type=checkbox]:enabled:checked').length > 0) {

            $('tbody input[type=checkbox][disabled=disabled]').each(function () {

                if ($(this).data('inherit') !== 'DefaultService') {
                    return true;
                }

                DefaultServiceData[$(this).parent().prev().text().trim()] = $(this).parent().next().text().trim();

                $(this).removeAttr('disabled');
                $(this).parent().next().text('');

                if (!$('#SelectAllItemsSelected').prop('checked')) {
                    $(this).prop('checked', false);
                }
            });
        }
        else {

            $('tbody input[type=checkbox]:enabled').each(function () {

                if ($(this).data('inherit') !== 'DefaultService') {
                    return true;
                }

                $(this).attr('disabled', 'disabled');
                $(this).prop('checked', true);
                $(this).parent().next().text(DefaultServiceData[$(this).parent().prev().text().trim()]);
            });
        }
    };

    /**
     * @name Init
     * @memberof Core.Agent.Admin.CustomerUserService
     * @function
     * @description
     *      This function initializes filter and "SelectAll" actions.
     */
    TargetNS.Init = function () {

        // Skip disabled checkboxes when selecting all.
        Core.Form.InitSelectAllCheckboxes($('table td input[type="checkbox"][name=ItemsSelected]:not(:disabled)'), $('#SelectAllItemsSelected'));

        $('input[type="checkbox"][name=ItemsSelected]:not(:disabled)').on('click', function () {
            Core.Form.SelectAllCheckboxes($(this), $('#SelectAllItemsSelected'));
            TargetNS.HideShowDefaultServices();
        });

        $('#SelectAllItemsSelected').on('click', TargetNS.HideShowDefaultServices);

        Core.UI.Table.InitTableFilter($("#FilterServices"), $("#Service"));
    };

    Core.Init.RegisterNamespace(TargetNS, 'APP_MODULE');

    return TargetNS;
}(Core.Agent.Admin.CustomerUserService || {}));
