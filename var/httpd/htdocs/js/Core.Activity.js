// --
// Copyright (C) 2021 Znuny GmbH, https://znuny.org/
// --
// This software comes with ABSOLUTELY NO WARRANTY. For details, see
// the enclosed file COPYING for license information (AGPL). If you
// did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
// --

"use strict";

var Core = Core || {};

/**
 * @namespace Core.Activity
 * @memberof Core
 * @author Znuny GmbH
 * @description
 *      This namespace contains the special module functions for activity.
 */

Core.Activity = (function (TargetNS) {

    /**
     * @name Activity
     * @memberof Core.Activity
     * @function
     * @description
     *      Initializes the module.
     */
    TargetNS.Init = function () {
        var $Activity;

        // clear all
        $('#ActivityDeleteAll').off("click.activity-delete-all").on("click.activity-delete-all", function () {
            TargetNS.DeleteAll(function (Response){
                if (!Response || !Response.Success) {
                    $Activity.find('i').removeClass('AJAXLoader').addClass('fa-close');
                    return;
                }

                $('li.Activity').remove();
            });
        });

        // mark as seen all
        $('#ActivityMarkAsSeenAll').off("click.activity-mark-as-all").on("click.activity-mark-as-all", function () {
            TargetNS.MarkAsSeenAll();
        });

        // remove all
        $(document).off("click.activity-delete").on("click.activity-delete", '.activity-delete', function () {
            var ActivityID = $(this).data('activity-id'),
                $Activity  = $('li.Activity[data-activity-id="' + ActivityID + '"]');

            $(this).find('i').removeClass('fa-close').addClass('AJAXLoader');

            TargetNS.Delete(ActivityID, function (Response){
                if (!Response || !Response.Success) {
                    $Activity.find('i').removeClass('AJAXLoader').addClass('fa-close');
                    return;
                }

                $Activity.remove();
            });
        });

        TargetNS.BindActivityLink();
    };

    /**
     * @name BindActivityLink
     * @memberof Core.Activity
     * @function
     * @description
     *      Binds click event to all activity links.
     */
    TargetNS.BindActivityLink = function () {

        // remove all click activity link events
        $(document).off('click.activity-link');

        // add all click activity link events again to make sure all new events exists
        $('.activity-link').unshiftOn('click.activity-link', function () {
            var ActivityID = $(this).parent().data('activity-id');

            Core.Activity.MarkAsSeen(ActivityID);

            window.location.href = $(this).attr('href');
        });
    };


    /**
     * @name Add
     * @memberof Core.Activity
     * @function
     * @param {Object} Data
     *      {String} Type  - of the activity
     *      {String} Title - of the activity
     *      {String} Text  - of the activity
     *      {String} State - of the activity
     *      {String} Link  - of the activity
     * @param {Function} Callback - function which should be executed at the end
     * @description
     *      Adds a new activity.
     * @example
     *      Core.Activity.Add({Type: 'Ticket',Title: 'New Activity', Text: 'This is my activity text.', State: 'new', Link: 'index.pl?Action=AgentTicketZoom;TicketID=1'});
     */

    TargetNS.Add = function (Data, Callback) {
        var URL = Core.Config.Get('Baselink'),
            $Activity,
            Validate,
            Attributes = [
                'Type',
                'Title',
                'Text',
                'State',
                'Link',
            ];

        Data.Action    = 'Activity';
        Data.Subaction = 'Add';

        $.each(Attributes, function(Index, Attribute) {
            if (!Data[Attribute]) {
                Core.UI.Dialog.ShowAlert(
                    Core.Language.Translate('An error occurred'),
                    Core.Language.Translate('The activity could not be created. %s is needed.', Attribute)
                );
                Validate = 0;
                return false;
            }
            Validate = 1;
        });

        if (!Validate){
            return false;
        }

        Core.AJAX.FunctionCall(URL, Data, function (Response) {
            if (!Response || !Response.Success || !Response.ActivityID) {
                Core.UI.Dialog.ShowAlert(
                    Core.Language.Translate('An error occurred'),
                    Core.Language.Translate('The activity could not be created.')
                );
                return;
            }

            Response['LinkTarget'] = Core.Config.Get('UserActivityLinkTarget');
            $Activity = Core.Template.Render('Activity/Activity', Response);
            $('.ActivityList').prepend($Activity);

            if (typeof Callback !== 'undefined') {
                Callback(Response);
            }

            TargetNS.BindActivityLink();
            TargetNS.UpdateActivityList();
        });

        return true;
    };

    /**
     * @name Update
     * @memberof Core.Activity
     * @function
     * @param {String} ActivityID - of the activity
     * @param {Object} Data
     *      {String} Type  - of the activity
     *      {String} Title - of the activity
     *      {String} Text  - of the activity
     *      {String} State - of the activity
     *      {String} Link  - of the activity
     * @param {Function} Callback - function which should be executed at the end
     * @description
     *      Updates an activity.
     * @example
     *      Core.Activity.Update(1, { Type: 'Ticket', Title: 'New Activity', Text:'This is my activity text.', State: 'seen', Link: 'index.pl?Action=AgentTicketZoom;TicketID=1'}, Callback);
     */
    TargetNS.Update = function (ActivityID, Data, Callback) {
        var URL = Core.Config.Get('Baselink'),
            $Activity;

        Data['ActivityID'] = ActivityID;
        Data['Action']     = 'Activity';
        Data['Subaction']  = 'Update';

        Core.AJAX.FunctionCall(URL, Data, function (Response) {
            if (!Response || !Response.Success) {
                Core.UI.Dialog.ShowAlert(
                    Core.Language.Translate('An error occurred'),
                    Core.Language.Translate('The activity could not be updated.')
                );
                return;
            }

            $Activity = Core.Template.Render('Activity/Activity', Response);
            $('li.Activity[data-activity-id="' + ActivityID + '"]').replaceWith($Activity);

            if (typeof Callback !== 'undefined') {
                Callback(Response);
            }

            TargetNS.UpdateActivityList();
        });
    };

    /**
     * @name UpdateActivityList
     * @memberof Core.Activity
     * @function
     * @description
     *      Updates the activity list.
     */
    TargetNS.UpdateActivityList = function () {

        var ActivityCounter = $('ul.ActivityList li').length,
            ActivityNewCounter = $('ul.ActivityList li[data-activity-state="new"]').length;

        $('#ActivityCounter').text('(' + ActivityCounter + ')');
        $('#ActivityBellState').removeClass('activity-new');

        if (ActivityNewCounter >= 1){
            $('#ActivityBellState').addClass('activity-new');
        }
    };

    /**
     * @name Delete
     * @memberof Core.Activity
     * @function
     * @param {String} ActivityID - of the activity
     * @param {Function} Callback - function which should be executed at the end
     * @description
     *      Deletes the given activity.
     */
    TargetNS.Delete = function (ActivityID, Callback) {
        var URL = Core.Config.Get('Baselink'),
            Data = {
                Action:     'Activity',
                Subaction:  'Delete',
                ActivityID: ActivityID,
            };

        Core.AJAX.FunctionCall(URL, Data, function (Response) {
            if (!Response || !Response.Success) {
                Core.UI.Dialog.ShowAlert(
                    Core.Language.Translate('An error occurred'),
                    Core.Language.Translate('The activity could not be deleted.')
                );
                return;
            }

            if (typeof Callback !== 'undefined') {
                Callback(Response);
            }

            TargetNS.UpdateActivityList();
        });
    };

    /**
     * @name DeleteAll
     * @memberof Core.Activity
     * @function
     * @param {Function} Callback - function which should be executed at the end
     * @description
     *      Deletes all activities of the current user.
     */
    TargetNS.DeleteAll = function (Callback) {
        var URL = Core.Config.Get('Baselink'),
            Data = {
                Action:    'Activity',
                Subaction: 'DeleteAll',
            };

        Core.AJAX.FunctionCall(URL, Data, function (Response) {
            if (!Response || !Response.Success) {
                Core.UI.Dialog.ShowAlert(
                    Core.Language.Translate('An error occurred'),
                    Core.Language.Translate('The activity could not be deleted.')
                );
                return;
            }

            if (typeof Callback !== 'undefined') {
                Callback(Response);
            }

            TargetNS.UpdateActivityList();
        });
    };

    /**
     * @name MarkAsNew
     * @memberof Core.Activity
     * @function
     * @param {String} ActivityID - of the activity
     * @param {Function} Callback - function which should be executed at the end
     * @description
     *      Marks the given activity as new.
     */
    TargetNS.MarkAsNew = function (ActivityID, Callback) {
        var Data = {
            State: 'new',
        };

        TargetNS.Update(ActivityID, Data, function (Response){
            if (!Response || !Response.Success) {
                Core.UI.Dialog.ShowAlert(
                    Core.Language.Translate('An error occurred'),
                    Core.Language.Translate('The activity could not be marked as new.')
                );
                return;
            }

            if (typeof Callback !== 'undefined') {
                Callback(Response);
            }

            TargetNS.UpdateActivityList();
        });
    };

    /**
     * @name MarkAsNew
     * @memberof Core.Activity
     * @function
     * @param {String} ActivityID - of the activity
     * @param {Function} Callback - function which should be executed at the end
     * @description
     *      Marks the given activity as seen.
     */
    TargetNS.MarkAsSeen = function (ActivityID, Callback) {
        var Data = {
            State: 'seen',
        };

        TargetNS.Update(ActivityID, Data, function (Response){
            if (!Response || !Response.Success) {
                Core.UI.Dialog.ShowAlert(
                    Core.Language.Translate('An error occurred'),
                    Core.Language.Translate('The activity could not be marked as seen.')
                );
                return;
            }

            if (typeof Callback !== 'undefined') {
                Callback(Response);
            }

            TargetNS.UpdateActivityList();
        });
    };

    /**
     * @name MarkAsSeenAll
     * @memberof Core.Activity
     * @function
     * @param {Function} Callback - function which should be executed at the end
     * @description
     *      Marks all activities of the user as seen.
     */
    TargetNS.MarkAsSeenAll = function (Callback) {
        var URL = Core.Config.Get('Baselink'),
            Data = {
                Action:    'Activity',
                Subaction: 'MarkAsSeenAll',
            };

        Core.AJAX.FunctionCall(URL, Data, function (Response) {
            if (!Response || !Response.Success) {
                Core.UI.Dialog.ShowAlert(
                    Core.Language.Translate('An error occurred'),
                    Core.Language.Translate('The activities could not be marked as seen.')
                );
                return;
            }

            $('.ActivityState').removeClass('activity-new');
            $('li.Activity').attr('data-activity-state', 'seen');

            if (typeof Callback !== 'undefined') {
                Callback(Response);
            }

            TargetNS.UpdateActivityList();
        });
    };

    Core.Init.RegisterNamespace(TargetNS, 'APP_MODULE');

    return TargetNS;
}(Core.Activity || {}));
