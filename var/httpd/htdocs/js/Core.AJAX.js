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

/**
 * @namespace Core.AJAX
 * @memberof Core
 * @author OTRS AG
 * @description
 *      This namespace contains the functionality for AJAX calls.
 */
Core.AJAX = (function (TargetNS) {
    /**
     * @private
     * @name AJAXLoaderPrefix
     * @memberof Core.AJAX
     * @member {String}
     * @description
     *      AJAXLoaderPrefix
     */
    var AJAXLoaderPrefix = 'AJAXLoader',
    /**
     * @private
     * @name ActiveAJAXCalls
     * @memberof Core.AJAX
     * @member {Object}
     * @description
     *      ActiveAJAXCalls
     */
        ActiveAJAXCalls = {};

    if (!Core.Debug.CheckDependency('Core.AJAX', 'Core.Exception', 'Core.Exception')) {
        return;
    }

    if (!Core.Debug.CheckDependency('Core.AJAX', 'Core.App', 'Core.App')) {
        return;
    }

    /**
     * @private
     * @name HandleAJAXError
     * @memberof Core.AJAX
     * @function
     * @param {Object} XHRObject - Meta data returned by the ajax request
     * @param {String} Status - Status information of the ajax request
     * @param {String} Error - Error information of the ajax request
     * @description
     *      Handles failing ajax request (only used as error callback in $.ajax calls)
     */
    function HandleAJAXError(XHRObject, Status, Error) {
        var ErrorMessage = Core.Language.Translate('Error during AJAX communication. Status: %s, Error: %s', Status, Error);

        // Check for expired sessions.
        if (RedirectAfterSessionTimeOut(XHRObject)) {
            return;
        }

        // Ignore aborted AJAX calls.
        if (Status === 'abort') {
            return;
        }

        // Collect debug information if configured.
        if (Core.Config.Get('AjaxDebug') && typeof XHRObject === 'object') {
            ErrorMessage += "\n\nResponse status: " + XHRObject.status + " (" + XHRObject.statusText + ")\n";
            ErrorMessage += "Response headers: " + XHRObject.getAllResponseHeaders() + "\n";
            ErrorMessage += "Response content: " + XHRObject.responseText;
        }

        if (!XHRObject.status) {

            // If we didn't receive a status, the request didn't get any result, which is most likely a connection issue.
            Core.Exception.HandleFinalError(new Core.Exception.ApplicationError(ErrorMessage, 'ConnectionError'));
            return;
        }

        // We are out of the OTRS App scope, that's why an exception would not be caught. Therefore we handle the error manually.
        Core.Exception.HandleFinalError(new Core.Exception.ApplicationError(ErrorMessage, 'CommunicationError'));
    }


    /**
     * @public
     * @name ToggleAJAXLoader
     * @memberof Core.AJAX
     * @function
     * @param {String} FieldID - Id of the field which is updated via ajax
     * @param {Boolean} Show - Show or hide the AJAX loader image
     * @description
     *      Shows and hides an ajax loader for every element which is updates via ajax.
     */
    TargetNS.ToggleAJAXLoader = function (FieldID, Show) {
        var $Element = $('#' + FieldID),
            $Loader = $('#' + AJAXLoaderPrefix + FieldID),
            LoaderHTML = '<span id="' + AJAXLoaderPrefix + FieldID + '" class="AJAXLoader"></span>';

        // Ignore hidden fields
        if ($Element.is('[type=hidden]')) {
            return;
        }
        // Element not present, reset counter and ignore
        if (!$Element.length) {
                ActiveAJAXCalls[FieldID] = 0;
                return;
        }

        // Init counter value, if needed.
        // This counter stores the number of running AJAX requests for each field.
        // The loader image will be shown if it is > 0.
        if (typeof ActiveAJAXCalls[FieldID] === 'undefined') {
            ActiveAJAXCalls[FieldID] = 0;
        }

        // Calculate counter
        if (Show) {
            ActiveAJAXCalls[FieldID]++;
        }
        else {
            ActiveAJAXCalls[FieldID]--;
            if (ActiveAJAXCalls[FieldID] <= 0) {
                ActiveAJAXCalls[FieldID] = 0;
            }
        }

        // Show or hide the loader
        if (ActiveAJAXCalls[FieldID] > 0) {
            if (!$Loader.length) {
                $Element.after(LoaderHTML);
            }
            else {
                $Loader.show();
            }
        }
        else {
            $Loader.hide();
        }
    }

    /**
     * @private
     * @name SerializeData
     * @memberof Core.AJAX
     * @function
     * @returns {String} Query string of the data.
     * @param {Object} Data - The data that should be converted
     * @description
     *      Converts a given hash into a query string.
     */
    function SerializeData(Data) {
        var QueryString = '';
        $.each(Data, function (Key, Value) {
            QueryString += ';' + encodeURIComponent(Key) + '=' + encodeURIComponent(Value);
        });
        return QueryString;
    }

    /**
     * @private
     * @name GetSessionInformation
     * @memberof Core.AJAX
     * @function
     * @returns {Object} Hash with session data, if needed.
     * @description
     *      Collects session data in a hash if available.
     */
    function GetSessionInformation() {
        var Data = {};
        if (!Core.Config.Get('SessionIDCookie')) {
            Data[Core.Config.Get('SessionName')] = Core.Config.Get('SessionID');
            Data[Core.Config.Get('CustomerPanelSessionName')] = Core.Config.Get('SessionID');
        }
        Data.ChallengeToken = Core.Config.Get('ChallengeToken');
        return Data;
    }

    /**
     * @private
     * @name GetAdditionalDefaultData
     * @memberof Core.AJAX
     * @function
     * @returns {Object} Hash with additional session and action data.
     * @description
     *      Collects additional data that are needed for the ajax requests.
     */
    function GetAdditionalDefaultData() {
        var Data = {};
        Data = GetSessionInformation();
        Data.Action = Core.Config.Get('Action');
        return Data;
    }

    /**
     * @private
     * @name UpdateTicketAttachments
     * @memberof Core.AJAX
     * @function
     * @param {Object} Attachments - Array of hashes, each hash have the needed attachment information.
     * @description
     *      Removes all selected attachments and adds the ones passed in the Attachments object.
     */
    function UpdateTicketAttachments(Attachments) {

        // delete existing attachments
        $('.AttachmentList tbody').empty();

        // go through all attachments and append them to the attachment table
        $(Attachments).each(function() {

            var AttachmentItem = Core.Template.Render('AjaxDnDUpload/AttachmentItem', {
                'Filename' : this.Filename,
                'Filetype' : this.ContentType,
                'Filesize' : this.Filesize,
                'FileID'   : this.FileID,
            });

            $(AttachmentItem).prependTo($('.AttachmentList tbody')).fadeIn();
        });

        // make sure to display the attachment table only if any attachments
        // are actually in it.
        if ($('.AttachmentList tbody tr').length) {
            $('.AttachmentList').show();
        }
        else {
            $('.AttachmentList').hide();
        }
    }

    /**
     * @private
     * @name UpdateTextarea
     * @memberof Core.AJAX
     * @function
     * @param {Object} $Element - the field selector.
     * @param {Object} Value - the field value. The keys are the IDs of the fields to be updated.
     * @description
     *      Inserts value in textarea components or RichText editors for the ajax requests.
     */
    function UpdateTextarea($Element, Value) {
        var $ParentBody,
            ParentBody,
            Range,
            StartRange = 0,
            NewPosition = 0,
            CKEditorObj = parent.CKEDITOR;

        if ($Element.length) {
            $ParentBody = $Element;
            ParentBody = $ParentBody[0];

            // for regular popups, parent is a reference to the popup itself, which is why parent.CKEDITOR is a reference to the CKEDITOR
            // object of the popup window. But if we're on a mobile environment, the popup would instead open as an iframe, which would cause
            // parent.CKEDITOR to be the CKEDITOR object of the parent window which contains the iframe. This is why we want to use only
            // CKEDITOR in this case (see bug#12680).
            if (Core.App.Responsive.IsSmallerOrEqual(Core.App.Responsive.GetScreenSize(), 'ScreenL') && (!localStorage.getItem("DesktopMode") || parseInt(localStorage.getItem("DesktopMode"), 10) <= 0)) {
                CKEditorObj = CKEDITOR;
            }

            // add the text to the RichText editor
            if (CKEditorObj && CKEditorObj.instances.RichText) {
                CKEditorObj.instances.RichText.focus();
                window.setTimeout(function () {

                    // In some circumstances, this command throws an error (although inserting the HTML works)
                    // Because the intended functionality also works, we just wrap it in a try-catch-statement
                    try {

                        // set new text
                        CKEditorObj.instances.RichText.setData(Value);
                    }
                    catch (Error) {
                        $.noop();
                    }
                }, 100);
                return;
            }

            // insert body and/or link to textarea (if possible to cursor position otherwise to the top)
            else {

                // Get previously saved cursor position of textarea
                if ($Element.parent().data('Cursor')) {
                    StartRange = parent.$Element.data('Cursor').StartRange;
                }

                // Add new text to textarea
                $ParentBody.val(Value);
                NewPosition = StartRange + Value.length;

                // Jump to new cursor position (after inserted text)
                if (ParentBody.selectionStart) {
                    ParentBody.selectionStart = NewPosition;
                    ParentBody.selectionEnd = NewPosition;
                }
                else if (document.selection) {
                    Range = document.selection.createRange().duplicate();
                    Range.moveStart('character', NewPosition);
                    Range.select();
                }

                return;
            }
        }
        else {
            alert(Core.Language.Translate('This window must be called from compose window.'));
            return;
        }
    }

    /**
     * @private
     * @name UpdateFormElements
     * @memberof Core.AJAX
     * @function
     * @param {Object} Data - The new field data. The keys are the IDs of the fields to be updated.
     * @description
     *      Updates the given fields with the given data.
     */
    function UpdateFormElements(Data) {
        if (typeof Data !== 'object') {
            return;
        }
        $.each(Data, function (DataKey, DataValue) {
            var $Element = $('#' + DataKey);

            // special case to update ticket attachments
            if (DataKey === 'TicketAttachments') {
                UpdateTicketAttachments(DataValue);
                return;
            }

            if ((!$Element.length || !DataValue) && !$Element.is('textarea')) {
                return;
            }

            // Select elements
            if ($Element.is('select')) {
                $Element.empty();
                $.each(DataValue, function (Index, Value) {
                    var NewOption,
                        OptionText = Core.App.EscapeHTML(Value[1]);

                    NewOption = new Option(OptionText, Value[0], Value[2], Value[3]);

                    // Check if option must be disabled.
                    if (Value[4]) {
                        NewOption.disabled = true;
                    }

                    // Overwrite option text, because of wrong html quoting of text content.
                    // (This is needed for IE.)
                    NewOption.innerHTML = OptionText;
                    $Element.append(NewOption);

                });

                // Trigger custom redraw event for InputFields
                if ($Element.hasClass('Modernize')) {
                    $Element.trigger('redraw.InputField');
                }

                return;
            }

            // text area elements like the ticket body
            if ($Element.is('textarea')) {
                UpdateTextarea($Element, DataValue);
                return;
            }

            // Other form elements
            $Element.val(DataValue);

            // Trigger custom redraw event for InputFields
            if ($Element.hasClass('Modernize')) {
                $Element.trigger('redraw.InputField');
            }
        });
    }

    /**
     * @private
     * @name RedirectAfterSessionTimeOut
     * @memberof Core.AJAX
     * @function
     * @returns {Boolean} Returns false, if Redirect is not necessary.
     * @param {Object} XHRObject - The original AJAX object.
     * @description
     *      Checks if session is timed out and redirects to the login to avoid
     *      ajax errors.
     */
    function RedirectAfterSessionTimeOut(XHRObject) {
        var Headers = XHRObject.getAllResponseHeaders(),
            OldUrl = location.href,
            NewUrl = Core.Config.Get('Baselink') + "RequestedURL=" + encodeURIComponent(OldUrl);

        if (Headers.match(/X-OTRS-Login: /i)) {
            location.href = NewUrl;
            return true;
        }

        return false;
    }

    /**
     * @name SerializeForm
     * @memberof Core.AJAX
     * @function
     * @returns {String} The query string.
     * @param {jQueryObject} $Element - The jQuery object of the form  or any element within this form that should be serialized
     * @param {Object} [Ignore] - Elements (Keys) which should not be included in the serialized form string (optional)
     * @description
     *      Serializes the form data into a query string.
     */
    TargetNS.SerializeForm = function ($Element, Ignore) {
        var QueryString = "";
        if (typeof Ignore === 'undefined') {
            Ignore = {};
        }
        if (isJQueryObject($Element) && $Element.length) {
            $Element.closest('form').find('input:not(:file), textarea, select').filter(':not([disabled=disabled])').each(function () {
                var Name = $(this).attr('name') || '';

                // only look at fields with name
                // only add element to the string, if there is no key in the data hash with the same name
                if (!Name.length || typeof Ignore[Name] !== 'undefined'){
                    return;
                }

                if ($(this).is(':checkbox, :radio')) {
                    if ($(this).is(':checked')) {
                        QueryString += encodeURIComponent(Name) + '=' + encodeURIComponent($(this).val() || 'on') + ";";
                    }
                }
                else if ($(this).is('select')) {
                    $.each($(this).find('option:selected'), function(){
                        QueryString += encodeURIComponent(Name) + '=' + encodeURIComponent($(this).val() || '') + ";";
                    });
                }
                else {
                    QueryString += encodeURIComponent(Name) + '=' + encodeURIComponent($(this).val() || '') + ";";
                }
            });
        }
        return QueryString;
    };

    /**
     * @name FormUpdate
     * @memberof Core.AJAX
     * @function
     * @returns {Object} The jqXHR object.
     * @param {jQueryObject} $EventElement - The jQuery object of the element(s) which are included in the form that should be submitted.
     * @param {String} Subaction - The subaction parameter for the perl module.
     * @param {String} ChangedElement - The name of the element which was changed by the user.
     * @param {Object} FieldsToUpdate - DEPRECATED.
     *                      This used to be the names of the fields that should be updated with the server answer,
     *                      but is not needed any more and will be removed in a future version of OTRS.
     * @param {Function} [SuccessCallback] - Callback function to be executed on AJAX success (optional).
     * @description
     *      Submits a special form via ajax and updates the form with the data returned from the server
     */
    TargetNS.FormUpdate = function ($EventElement, Subaction, ChangedElement, FieldsToUpdate, SuccessCallback) {
        var URL = Core.Config.Get('Baselink'),
            Data = GetAdditionalDefaultData(),
            QueryString;

        Data.Subaction = Subaction;
        Data.ElementChanged = ChangedElement;
        QueryString = TargetNS.SerializeForm($EventElement, Data) + SerializeData(Data);

        if (FieldsToUpdate) {
            $.each(FieldsToUpdate, function (Index, Value) {
                TargetNS.ToggleAJAXLoader(Value, true);
            });
        }

        return $.ajax({
            type: 'POST',
            url: URL,
            data: QueryString,
            dataType: 'json',
            success: function (Response, Status, XHRObject) {

                Core.App.Publish('Core.App.AjaxErrorResolved');

                if (RedirectAfterSessionTimeOut(XHRObject)) {
                    return false;
                }

                if (!Response) {
                    // We are out of the OTRS App scope, that's why an exception would not be caught. Therefore we handle the error manually.
                    Core.Exception.HandleFinalError(new Core.Exception.ApplicationError("Invalid JSON from: " + URL, 'CommunicationError'));
                }
                else {
                    UpdateFormElements(Response, FieldsToUpdate);
                    if (typeof SuccessCallback === 'function') {
                        SuccessCallback();
                    }
                    Core.App.Publish('Event.AJAX.FormUpdate.Callback', [Response]);
                }
            },
            complete: function () {
                if (FieldsToUpdate) {
                    $.each(FieldsToUpdate, function (Index, Value) {
                        TargetNS.ToggleAJAXLoader(Value, false);
                    });
                }
            },
            error: function(XHRObject, Status, Error) {
                HandleAJAXError(XHRObject, Status, Error)
            }
        });
    };

    /**
     * @name ContentUpdate
     * @memberof Core.AJAX
     * @function
     * @returns {Object} The jqXHR object.
     * @param {jQueryObject} $ElementToUpdate - The jQuery object of the element(s) which should be updated
     * @param {String} URL - The URL which is called via Ajax
     * @param {Function} Callback - The additional callback function which is called after the request returned from the server
     * @description
     *      Calls an URL via Ajax and updates a html element with the answer html of the server.
     */
    TargetNS.ContentUpdate = function ($ElementToUpdate, URL, Callback) {
        var QueryString, QueryIndex = URL.indexOf("?"), GlobalResponse;

        if (QueryIndex >= 0) {
            QueryString = URL.substr(QueryIndex + 1);
            URL = URL.substr(0, QueryIndex);
        }
        QueryString += SerializeData(GetSessionInformation());

        return $.ajax({
            type: 'POST',
            url: URL,
            data: QueryString,
            dataType: 'html',
            success: function (Response, Status, XHRObject) {

                Core.App.Publish('Core.App.AjaxErrorResolved');

                if (RedirectAfterSessionTimeOut(XHRObject)) {
                    return false;
                }

                if (!Response) {
                    // We are out of the OTRS App scope, that's why an exception would not be caught. Therefore we handle the error manually.
                    Core.Exception.HandleFinalError(new Core.Exception.ApplicationError("No content from: " + URL, 'CommunicationError'));
                }
                else if ($ElementToUpdate && isJQueryObject($ElementToUpdate) && $ElementToUpdate.length) {
                    GlobalResponse = Response;
                    $ElementToUpdate.html(Response);
                }
                else {
                    // We are out of the OTRS App scope, that's why an exception would not be caught. Therefore we handle the error manually.
                    Core.Exception.HandleFinalError(new Core.Exception.ApplicationError("No such element id: " + $ElementToUpdate.attr('id') + " in page!", 'CommunicationError'));
                }
            },
            complete: function () {
                if ($.isFunction(Callback)) {
                    Callback();
                }
                Core.App.Publish('Event.AJAX.ContentUpdate.Callback', [GlobalResponse]);
            },
            error: function(XHRObject, Status, Error) {
                HandleAJAXError(XHRObject, Status, Error)
            }
        });
    };

    /**
     * @name FunctionCall
     * @memberof Core.AJAX
     * @function
     * @returns {Object} The jqXHR object.
     * @param {String} URL - The URL which is called via Ajax.
     * @param {Object} Data - The data hash or data query string.
     * @param {Function} Callback - The callback function which is called after the request returned from the server.
     * @param {String} [DataType=json] Defines the datatype, default 'json', could also be 'html'
     * @description
     *      Calls an URL via Ajax and executes a given function after the request returned from the server.
     */
    TargetNS.FunctionCall = function (URL, Data, Callback, DataType) {
        if (typeof Data === 'string') {
            Data += SerializeData(GetSessionInformation());
        } else {
            Data = $.extend(Data, GetSessionInformation());
        }

        return $.ajax({
            type: 'POST',
            url: URL,
            data: Data,
            dataType: (typeof DataType === 'undefined') ? 'json' : DataType,
            success: function (Response, Status, XHRObject) {

                Core.App.Publish('Core.App.AjaxErrorResolved');

                if (RedirectAfterSessionTimeOut(XHRObject)) {
                    return false;
                }

                // call the callback
                if ($.isFunction(Callback)) {
                    Callback(Response);
                    // publish to event channel
                    Core.App.Publish('Event.AJAX.FunctionCall.Callback', [Response]);
                }
                else {
                    // We are out of the OTRS App scope, that's why an exception would not be caught. Therefore we handle the error manually.
                    Core.Exception.HandleFinalError(new Core.Exception.ApplicationError("Invalid callback method: " + ((typeof Callback === 'undefined') ? 'undefined' : Callback.toString())));
                }
            },
            error: function(XHRObject, Status, Error) {
                HandleAJAXError(XHRObject, Status, Error)
            }
        });
    };

    TargetNS.FunctionCallSynchronous = function (URL, Data, Callback, DataType) {

        // store the original state
        // this is basically an example how to access
        // the current state of the $.ajaxSetup values
        var OriginalAsyncState = $.ajaxSetup()['async'];

        // make a custom callback that gets passed to the standard Core.AJAX.FunctionCall
        // that resets back to asynchronous AJAX calls as before and executes the regualar
        // given Callback function as usual
        var ResetCallback = function (Response) {

            // set requests back to asynchronous
            $.ajaxSetup({
                async: OriginalAsyncState
            });

            // call given callback function as usual
            Callback(Response);
        };

        // set this request as synchronous
        $.ajaxSetup({
            async: false
        });

        // start the wanted request by the framework functionality with our
        // manipulated callback function and disabled async flag
        Core.AJAX.FunctionCall(URL, Data, ResetCallback, DataType);
    };

    return TargetNS;
}(Core.AJAX || {}));
