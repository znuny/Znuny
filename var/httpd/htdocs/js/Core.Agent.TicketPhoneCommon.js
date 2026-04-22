// --
// Copyright (C) 2001-2021 OTRS AG, https://otrs.com/
// Copyright (C) 2021 Znuny GmbH, https://znuny.org/
// --
// This software comes with ABSOLUTELY NO WARRANTY. For details, see
// the enclosed file COPYING for license information (GPL). If you
// did not receive this file, see https://www.gnu.org/licenses/gpl-3.0.txt.
// --

"use strict";

var Core = Core || {},
    Znuny = Znuny || {};
Core.Agent = Core.Agent || {};

/**
 * @namespace Core.Agent.TicketPhoneCommon
 * @memberof Core.Agent
 * @author OTRS AG
 * @description
 *      This namespace contains special module functions for TicketPhoneCommon.
 */
Core.Agent.TicketPhoneCommon = (function (TargetNS) {

    /**
     * @name Init
     * @memberof Core.Agent.TicketPhoneCommon
     * @function
     * @description
     *      This function initializes the module functionality.
     */
    TargetNS.Init = function () {

        var UpdateFields = Core.Config.Get('DynamicFieldNames');

        Znuny.Form.Input.FieldIDMapping('AgentTicketPhoneOutbound',
            {
                Body:       'RichText',
                StateID:    'NextStateID',
                ServiceID:  'ServiceID',
                SLAID:      'SLAID',
                TypeID:     'TypeID',
                PriorityID: 'NewPriorityID'
            }
        );

        UpdateFields.push('TypeID');
        UpdateFields.push('ServiceID');
        UpdateFields.push('SLAID');

        $('#TypeID').on('change', function () {
            Core.AJAX.FormUpdate($(this).parents('form'), 'AJAXUpdate', 'TypeID', UpdateFields);
        });

        $('#ServiceID').on('change', function () {
            Core.AJAX.FormUpdate($(this).parents('form'), 'AJAXUpdate', 'ServiceID', UpdateFields);
        });

        $('#SLAID').on('change', function () {
            Core.AJAX.FormUpdate($(this).parents('form'), 'AJAXUpdate', 'SLAID', UpdateFields);
        });

        // Bind event to StandardTemplate field.
        $('#StandardTemplateID').on('change', function () {
            var $Form = $(this).closest('form');
            Core.Agent.TicketAction.ConfirmTemplateOverwrite('RichText', $(this), function () {
                Core.AJAX.FormUpdate($Form, 'AJAXUpdate', 'StandardTemplateID', ['RichTextField']);
            });
            return false;
        });

        // Bind event to State field.
        $('#NextStateID').on('change', function () {
            UpdateFields.push('StandardTemplateID');
            Core.AJAX.FormUpdate($(this).parents('form'), 'AJAXUpdate', 'NextStateID', UpdateFields);
        });
    };

    Core.Init.RegisterNamespace(TargetNS, 'APP_MODULE');

    return TargetNS;
}(Core.Agent.TicketPhoneCommon || {}));
