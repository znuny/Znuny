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
 * @namespace Core.Agent.TicketCompose
 * @memberof Core.Agent
 * @author OTRS AG
 * @description
 *      This namespace contains the special module functions for TicketCompose.
 */
Core.Agent.TicketCompose = (function (TargetNS) {

    /**
     * @name Init
     * @memberof Core.Agent.TicketCompose
     * @function
     * @description
     *      This function initializes .
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

        Znuny.Form.Input.FieldIDMapping('AgentTicketCompose',
            {
                Body:           'RichText',
                Customer:       'ToCustomer',
                CustomerUserID: 'ToCustomer',
                ServiceID:      'ServiceID',
                SLAID:          'SLAID',
                TypeID:         'TypeID',
                PriorityID:     'NewPriorityID'
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

        // change next ticket state
        $('#StateID').on('change', function () {
            Core.AJAX.FormUpdate($(this).parents('form'), 'AJAXUpdate', 'StateID', UpdateFields);
        });

        // check subject
        CheckSubject();
        $('#Subject').on('change', CheckSubject);

        // change article compose options
        if (typeof ArticleComposeOptions !== 'undefined') {
            $.each(ArticleComposeOptions, function (Key, Value) {
                $('#'+Value.Name).on('change', function () {
                    Core.AJAX.FormUpdate($('#Compose'), 'AJAXUpdate', Value.Name, Value.Fields);
                });
            });
        }
    };

    function CheckSubject () {
        var CurrentSubject = $('#Subject').val();
        var TicketID       = $('input[name=TicketID]').val();

        $('#SubjectWarning').remove();

        if (!TicketID) {
            return;
        }

        $.ajax({
            url: Core.Config.Get('Baselink'),
            type: 'POST',
            data: {
                Action: Core.Config.Get('Action'),
                Subaction: 'CheckSubject',
                Subject: CurrentSubject,
                TicketID: TicketID,
            },
            success : function(Response) {
                if (Response.Empty) {
                    $('#AppWrapper').prepend('<div class="MessageBox Notice" id="SubjectWarning"><p>' + Response.Message + '</div>');
                }
            }
        });
    }

    Core.Init.RegisterNamespace(TargetNS, 'APP_MODULE');

    return TargetNS;
}(Core.Agent.TicketCompose || {}));
