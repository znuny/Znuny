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
 * @namespace Core.Agent.TicketEmailOutbound
 * @memberof Core.Agent
 * @author OTRS AG
 * @description
 *      This namespace contains special module functions for TicketEmailOutbound.
 */
Core.Agent.TicketEmailOutbound = (function (TargetNS) {

    /**
     * @name Init
     * @memberof Core.Agent.TicketEmailOutbound
     * @function
     * @description
     *      This function initializes the module functionality.
     */
    TargetNS.Init = function () {

        var ArticleComposeOptions = Core.Config.Get('ArticleComposeOptions'),
            UpdateFields = Core.Config.Get('DynamicFieldNames') || [];

        // Move FieldExplanation elements next to their labels, store text as tooltip
        // used for Tooltips on labels (email security elements)
        $('.Field p.FieldExplanation').each(function() {
            var $Label = $(this).closest('.col-12').find('> label');
            if ($Label.length) {
                $(this).attr('data-tooltip', $(this).text().trim());
                $(this).detach().insertAfter($Label);
            }
        });

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

        // remove customers
        $('.CustomerTicketRemove').on('click', function () {
            Core.Agent.CustomerSearch.RemoveCustomerTicket($(this));
            return false;
        });

        // set a template
        $('#StandardTemplateID').on('change', function () {
            var $Form = $(this).closest('form');

            Core.Agent.TicketAction.ConfirmTemplateOverwrite('RichText', $(this), function () {
                Core.AJAX.FormUpdate($Form, 'AJAXUpdate', 'StandardTemplateID', ['RichTextField']);
            });
            return false;
        });

        // update dynamic fields in form
        $('#ComposeStateID').on('change', function () {
            Core.AJAX.FormUpdate($(this).parents('form'), 'AJAXUpdate', 'ComposeStateID', UpdateFields);
        });

        // change article compose options
        if (typeof ArticleComposeOptions !== 'undefined') {
            $.each(ArticleComposeOptions, function (Key, Value) {
                $('#'+Value.Name).on('change', function () {
                    Core.AJAX.FormUpdate($(this).parents('form'), 'AJAXUpdate', Value.Name, Value.Fields);
                });
            });
        }
    };

    Core.Init.RegisterNamespace(TargetNS, 'APP_MODULE');

    return TargetNS;
}(Core.Agent.TicketEmailOutbound || {}));
