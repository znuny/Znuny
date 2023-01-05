// --
// Copyright (C) 2021 Znuny GmbH, https://znuny.org/
// --
// This software comes with ABSOLUTELY NO WARRANTY. For details, see
// the enclosed file COPYING for license information (AGPL). If you
// did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
// --

"use strict";

var Core = Core || {},
    Znuny = Znuny || {};

Core.Agent = Core.Agent || {};
Core.Agent.AppointmentCalendar = Core.Agent.AppointmentCalendar || {};
Core.Agent.AppointmentCalendar.Plugin = Core.Agent.AppointmentCalendar.Plugin || {};
Core.Agent.AppointmentCalendar.Plugin.Ticket = Core.Agent.AppointmentCalendar.Plugin.Ticket || {};
Core.Agent.AppointmentCalendar.Plugin.TicketCreate = Core.Agent.AppointmentCalendar.Plugin.TicketCreate || {};

Znuny.Form = Znuny.Form || {};
Znuny.Form.Input = Znuny.Form.Input || {};

/**
 * @namespace Core.Agent.AppointmentCalendar.Plugin.TicketCreate
 * @memberof Core.Agent
 * @author Znuny
 * @description
 *      This namespace contains the appointment calendar plugin ticket create functions.
 */
Core.Agent.AppointmentCalendar.Plugin.TicketCreate = (function (TargetNS) {

    var PluginKey         = 'TicketCreate',
        PluginKeySelector = 'Plugin_' + PluginKey + '_';

    /**
     * @name Init
     * @memberof Core.Agent.AppointmentCalendar.Plugin.TicketCreate
     * @description
     *      Initializes the appointment calendar control.
     */
    TargetNS.Init = function () {
        Core.App.Subscribe('Core.Agent.AppointmentCalendar.AgentAppointmentEdit', function () {
            var Fields = ['QueueID', 'OwnerID', 'ResponsibleUserID', 'StateID', 'PriorityID', 'LockID', 'TypeID', 'ServiceID', 'SLAID'],
                ModifiedFields,
                Action;

            if ($('#' + PluginKeySelector + 'TicketCreateTimeType').length > 0) {

                // init for input fields
                ToggleFields();
                TogglePendingState();

                // show or hide Attributes
                $('#' + PluginKeySelector + 'TicketCreateTimeType').on('change.PluginKeyTicketCreate', function() {
                    ToggleFields();
                });

                Core.Agent.CustomerSearch.Init($('.CustomerAutoComplete'));

                // unbind click dialog - needed to select CustomerUser
                $('.ui-autocomplete').unbind('click.PluginKeyTicketCreate').bind('click.PluginKeyTicketCreate', function() {
                    $(document).unbind('click.Dialog');
                });

                // Bind events to specific fields
                $.each(Fields, function(Index, ChangedElement) {
                    ModifiedFields = Core.Data.CopyObject(Fields);
                    ModifiedFields.splice(Index, 1);
                    InitFieldUpdate(ChangedElement, ModifiedFields);
                });

                Core.App.Subscribe('Event.Agent.CustomerSearch.Callback', function(Response) {

                    $('#' + PluginKeySelector + 'CustomerUserID').val(Response.key);
                    Action =  Core.Config.Get('Action');
                    Core.Config.Set('Action', 'AgentAppointmentEdit');

                    Core.AJAX.FormUpdate($('#' + PluginKeySelector + 'Attributes'), 'AJAXUpdate', PluginKeySelector + 'CustomerUserID', ModifiedFields);

                    Core.Config.Set('Action', Action);
                });

                $('#' + PluginKeySelector + 'CustomerAutoComplete').off('change.CustomerAutoComplete').on('change.CustomerAutoComplete', function() {
                    if ($('#' + PluginKeySelector + 'CustomerAutoComplete').val() == ''){

                        $('#' + PluginKeySelector + 'CustomerUserID').val('');
                        $('#CustomerID').val('');
                        Core.Config.Set('Action', 'AgentAppointmentEdit');
                        Core.AJAX.FormUpdate($('#' + PluginKeySelector + 'Attributes'), 'AJAXUpdate', PluginKeySelector + 'CustomerUserID', ModifiedFields);
                        Core.Config.Set('Action', Action);
                    }
                });

                Core.App.Subscribe('Event.AJAX.FormUpdate.Callback', function() {
                    Core.App.Publish('Event.UI.InputFields.Resize');
                });

                return;
            }
        });
    }


    function InitFieldUpdate (ChangedElement, ModifiedFields) {
        $('#' + PluginKeySelector + ChangedElement).on('change', function () {
            var Action =  Core.Config.Get('Action');
            Core.Config.Set('Action', 'AgentAppointmentEdit');
            Core.AJAX.FormUpdate($('#' + PluginKeySelector + 'Attributes'), 'AJAXUpdate', PluginKeySelector + ChangedElement, ModifiedFields);

            TogglePendingState();
            Core.Config.Set('Action', Action);
        });
    }

    function ToggleFields () {

        if ($('#' + PluginKeySelector + 'TicketCreateTimeType').val() !== 'Never') {
            $('#' + PluginKeySelector + 'Attributes').show();
            Znuny.Form.Input.Mandatory(PluginKeySelector + 'QueueID', true);
            Znuny.Form.Input.Mandatory(PluginKeySelector + 'TypeID', true);

        }else {
            $('#' + PluginKeySelector + 'Attributes').hide();
            Znuny.Form.Input.Mandatory(PluginKeySelector + 'QueueID', false);
            Znuny.Form.Input.Mandatory(PluginKeySelector + 'TypeID', false);
        }

        if ($('#' + PluginKeySelector + 'TicketCreateTimeType').val() === 'Relative') {
            $('#' + PluginKeySelector + 'TicketCreateTimeRelative').show();
            Znuny.Form.Input.Mandatory(PluginKeySelector + 'TicketCreateOffset', true);

        }else {
            $('#' + PluginKeySelector + 'TicketCreateTimeRelative').hide();
            Znuny.Form.Input.Mandatory(PluginKeySelector + 'TicketCreateOffset', false);
        }

        Core.UI.InputFields.Init();
    }

    function TogglePendingState () {

        var PendingStatesJSON = $('#' + PluginKeySelector + 'PendingStateIDs').val(),
        StateID               = $('#' + PluginKeySelector + 'StateID').val(),
        PendingStates,
        StateFound = false;

        if (PendingStatesJSON){
            PendingStates = JSON.parse(PendingStatesJSON);
        }

        // check if state exists in the pending state list.
        $.each(PendingStates, function(index, PendingStateID) {
            if (PendingStateID != StateID) return true;
            StateFound = true;
            return false;
        });

        if (StateFound) {
            // Field label
            $('#' + PluginKeySelector + 'PendingStateIDs').parent().prev().show();
            // Field div
            $('#' + PluginKeySelector + 'PendingStateIDs').parent().show();
        }
        else {
            // Field label
            $('#' + PluginKeySelector + 'PendingStateIDs').parent().prev().hide();
            // Field div
            $('#' + PluginKeySelector + 'PendingStateIDs').parent().hide();
        }
        Core.UI.InputFields.Init();

        return true;
    }

    Core.Init.RegisterNamespace(TargetNS, 'APP_MODULE');

    return TargetNS;

}(Core.Agent.AppointmentCalendar.Plugin.TicketCreate || {}));
