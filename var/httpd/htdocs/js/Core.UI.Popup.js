// --
// Copyright (C) 2001-2021 OTRS AG, https://otrs.com/
// Copyright (C) 2021-2022 Znuny GmbH, https://znuny.org/
// --
// This software comes with ABSOLUTELY NO WARRANTY. For details, see
// the enclosed file COPYING for license information (GPL). If you
// did not receive this file, see https://www.gnu.org/licenses/gpl-3.0.txt.
// --

/*eslint-disable no-window*/

"use strict";

var Core = Core || {};
Core.UI = Core.UI || {};

/**
 * @namespace Core.UI.Popup
 * @memberof Core.UI
 * @author OTRS AG
 * @description
 *      Popup windows.
 */
Core.UI.Popup = (function (TargetNS) {
    /**
     * @private
     * @name OpenPopups
     * @memberof Core.UI.Popup
     * @member {Object}
     * @description
     *      All open popups.
     */
    var OpenPopups = {},

    /**
     * @private
     * @name PopupProfiles
     * @memberof Core.UI.Popup
     * @member {Object}
     * @description
     *      Defined popup profiles.
     */
        PopupProfiles,

    /**
     * @private
     * @name PopupDefaultProfile
     * @memberof Core.UI.Popup
     * @member {Object}
     * @description
     *      Default profile.
     */
        PopupDefaultProfile = 'Default',

    /**
     * @private
     * @name RegisterPopupTimeOut
     * @memberof Core.UI.Popup
     * @member {Object}
     * @description
     *      Time to wait before a popup is registered at the parent window.
     */
        RegisterPopupTimeOut = 1000,

    /**
     * @private
     * @name WindowMode
     * @memberof Core.UI.Popup
     * @member {String}
     * @description
     *      Defines the mode to open popups.
     *      If the screen size is <1024px (ScreenL), we do not open popup windows,
     *      but add fullsize iframes to the page.
     *      Mode can be 'Popup' or 'Iframe'.
     */
        WindowMode = 'Popup';

    if (!Core.Debug.CheckDependency('Core.UI.Dialog', 'Core.Config', 'Core.Config')) {
        return false;
    }

    PopupProfiles = {
        'Default': {
            WindowURLParams: "dependent=yes,location=no,menubar=no,resizable=yes,scrollbars=yes,status=no,toolbar=no",
            Left: 100,
            Top: 100,
            Width: 1040,
            Height: 700
        }
    };

    /**
     * @private
     * @name CheckOpenPopups
     * @memberof Core.UI.Popup
     * @function
     * @description
     *      Check which popup windows are still open.
     */
    function CheckOpenPopups() {
        $.each(OpenPopups, function (Key, Value) {
            if (Value.closed) {
                delete OpenPopups[Key];
            }
        });
    }

    /**
     * @private
     * @name CheckOpenPopups
     * @memberof Core.UI.Popup
     * @function
     * @returns {Object} Open popups of given type.
     * @param {String} Type - The type of a window, e.g. 'Action'.
     * @description
     *      Check which popup window are still open.
     */
    function GetPopupObjectByType(Type) {
        return OpenPopups[Type];
    }

    /**
     * @private
     * @name GetWindowParentObject
     * @memberof Core.UI.Popup
     * @function
     * @returns {Object} Parent window object.
     * @description
     *      Get the window parent object of the current popup.
     */
    function GetWindowParentObject() {
        // we have a normal popup, opener is defined
        // In Chrome/Webkit/Android window.opener is null instead of undefined
        // In IE (Win Phone) window.opener is undefined
        // typeof null === object
        if (window.opener !== null && typeof window.opener !== 'undefined') {
            // Special handling for IE11
            // Because of permission problems, IE11 returns a valid window object
            // but without the needed JS object "Core". window.parent contains that element
            if (typeof window.opener.Core !== 'undefined') {
                return window.opener;
            }
            else {
                return window.parent;
            }
        }
        else {
            return window.parent;
        }
    }

    /**
     * @private
     * @name CurrentIsPopupWindow
     * @memberof Core.UI.Popup
     * @function
     * @returns {String} Returns the type of popup if one, undefined otherwise.
     * @description
     *      Checks if current window is an OTRS popup.
     */
    function CurrentIsPopupWindow() {
        var PopupType;

        if (window.name.match(/OTRSPopup_([^_]+)_.+/)) {
            PopupType = RegExp.$1;
        }

        return PopupType;
    }

    /**
     * @name CurrentIsPopupWindow
     * @memberof Core.UI.Popup
     * @function
     * @returns {String} Returns the type of popup if one, undefined otherwise.
     * @description
     *      Checks if current window is an OTRS popup.
     */
    TargetNS.CurrentIsPopupWindow = function () {
        return CurrentIsPopupWindow();
    };

    /**
     * @name ProfileAdd
     * @memberof Core.UI.Popup
     * @function
     * @param {String} Key - Name of the Profile (UID).
     * @param {String} Values - Profile string as expected by window.open(),
     *                         e. g. "dependent=yes,height=700,left=100,top=100,location=no,menubar=no,resizable=yes,scrollbars=yes,status=no,toolbar=no,width=1000".
     * @description
     *      Adds a popup profile.
     */
    TargetNS.ProfileAdd = function (Key, Values) {
        PopupProfiles[Key] = Values;
    };

    /**
     * @name ProfileList
     * @memberof Core.UI.Popup
     * @function
     * @returns {Object} PopupProfiles object.
     * @description
     *      Get the list of registered popup profiles.
     */
    TargetNS.ProfileList = function () {
        return PopupProfiles;
    };

    /**
     * @name RegisterPopupEvent
     * @memberof Core.UI.Popup
     * @function
     * @description
     *      Register the pop-up event for a window.
     */
    TargetNS.RegisterPopupEvent = function () {
        $(window).on('Popup', function (Event, Type, Param) {
            if (Type && typeof Type !== 'undefined') {
                if (Type === 'Reload') {
                    window.location.reload();
                }
                else if (Type === 'URL') {
                    if (Param && typeof Param.URL !== 'undefined') {
                        window.location.href = Param.URL;
                    }
                }
            }
        });
    };

    /**
     * @name FirePopupEvent
     * @memberof Core.UI.Popup
     * @function
     * @param {String} Type - The event type that will be launched.
     * @param {Object} Param  - The element that contain information about the new screen address.
     * @param {Boolean} ExecuteInMobileMode - Do not execute this on mobile devices.
     * @description
     *      This function starts the pop-up event.
     */
    TargetNS.FirePopupEvent = function (Type, Param, ExecuteInMobileMode) {
        if (ExecuteInMobileMode === false && !$('body').hasClass('Visible-ScreenXL') && (!localStorage.getItem("DesktopMode") || parseInt(localStorage.getItem("DesktopMode"), 10) <= 0)) {
            return;
        }

        $(window).off('beforeunload.Popup');
        Core.App.UnbindWindowUnloadEvent('Popup');
        $(window).trigger('Popup', [Type, Param]);
    };

    /**
     * @name CheckPopupsOnUnload
     * @memberof Core.UI.Popup
     * @function
     * @returns {String} A Warning text.
     * @description
     *      This review if some popup windows are open, then try to send a warning.
     */
    TargetNS.CheckPopupsOnUnload = function () {
        var Size = 0;
        CheckOpenPopups();
        $.each(OpenPopups, function (Key, Value) {
            // IE(7) treats windows in new tabs (opened with right-click) also as popups
            // Therefore we check if the popup is a real OTRS popup.
            // IE9 can't read the WindowType property from the window object,
            // so we check for the correct popup window name now.
            if (Value.name.match(/OTRSPopup_.+/)) {
                Size++;
            }
        });
        if (Size) {
            return Core.Language.Translate('If you now leave this page, all open popup windows will be closed, too!');
        }
    };

    /**
     * @name ClosePopupsOnUnload
     * @memberof Core.UI.Popup
     * @function
     * @description
     *      This function close the active popup windows.
     */
    TargetNS.ClosePopupsOnUnload = function () {
        CheckOpenPopups();
        $.each(OpenPopups, function (Key, Value) {
            // IE(7) treats windows in new tabs (opened with right-click) also as popups
            // Therefore we check if the popup is a real OTRS popup.
            // IE9 can't read the WindowType property from the window object,
            // so we check for the correct popup window name now.
            if (Value.name.match(/OTRSPopup_.+/)) {
                TargetNS.ClosePopup(Value);
            }
        });
    };

    /**
     * @name RegisterPopupAtParentWindow
     * @memberof Core.UI.Popup
     * @function
     * @param {Object} WindowObject - Real window object.
     * @param {String} Type - the window type.
     * @description
     *      This function set the type for a popup window.
     */
    TargetNS.RegisterPopupAtParentWindow = function (WindowObject) {
        var Type;

        /OTRSPopup_([^_]+)_.*/.exec(WindowObject.name);
        Type = RegExp.$1;

        if (typeof OpenPopups[Type] === 'undefined') {
            OpenPopups[Type] = WindowObject;
        }
        else {
            if (OpenPopups[Type] !== WindowObject) {
                OpenPopups[Type] = WindowObject;
            }
        }
    };

    /**
     * @name InitRegisterPopupAtParentWindow
     * @memberof Core.UI.Popup
     * @function
     * @description
     *      This function set a timeout and after that try to register a popup at a parent window.
     */
    TargetNS.InitRegisterPopupAtParentWindow = function () {
        window.setTimeout(function () {
            var PopupType = CurrentIsPopupWindow(),
                ParentWindow;

            if (typeof PopupType !== 'undefined') {
                ParentWindow = GetWindowParentObject();
            }

            // if the window has a name, it's most probably the popup itself, see bug#12185.
            // This can happen if the parent window gets reloaded while the popup window tries
            // to register itself to it. When there is no parent, GetWindowParentObject() will return
            // the current window which is the popup itself. This leads to a situation where the popup window
            // registers itself as popup in its own namespace, which will then lead to a confirmation
            // message asking the user if they really want to navigate away from the current page when trying
            // to close the popup by either submitting a form, closing it manually or using a close link.
            if (ParentWindow &&
                !ParentWindow.name &&
                ParentWindow.Core &&
                ParentWindow.Core.UI &&
                ParentWindow.Core.UI.Popup
            ) {
                try {
                    ParentWindow.Core.UI.Popup.RegisterPopupAtParentWindow(window, PopupType);
                }
                catch (Event) {
                    // no code here
                    $.noop(Event);
                }
            }
            Core.UI.Popup.InitRegisterPopupAtParentWindow();
        }, RegisterPopupTimeOut);
    };

    /**
     * @name GetPopupObject
     * @memberof Core.UI.Popup
     * @function
     * @returns {Object} The window object of the popup or undefined.
     * @param {String} Type - The type of a window, e.g. 'Action'.
     * @description
     *      Get window object by popup type.
     */
    TargetNS.GetPopupObject = function (Type) {
        return GetPopupObjectByType(Type);
    };

    /**
     * @name GetWindowMode
     * @memberof Core.UI.Popup
     * @function
     * @returns {String} The window mode ('Popup' or 'Iframe') or undefined.
     * @description
     *      Get the window mode.
     */
    TargetNS.GetWindowMode = function () {
        if (WindowMode === 'Popup' || WindowMode === 'Iframe') {
            return WindowMode;
        }
        else {
            return undefined;
        }
    };

    /**
     * @name SetWindowMode
     * @memberof Core.UI.Popup
     * @function
     * @param {String} Mode - The new window mode ('Popup' or 'Iframe').
     * @description
     *      Set the window mode.
     */
    TargetNS.SetWindowMode = function (Mode) {
        if (Mode === 'Popup' || Mode === 'Iframe') {
            WindowMode = Mode;
        }
        else {
            WindowMode = undefined;
        }
    };

    /**
     * @name Resize
     * @memberof Core.UI.Popup
     * @function
     * @param {String} Type - The type of a window, e.g. 'Action'.
     * @param {String} Width - Width in pixels.
     * @param {String} Height - Height in pixels.
     * @description
     *      This function resizes an opened window.
     */
    TargetNS.Resize = function (Type, Width, Height) {
        var PopupObject = GetPopupObjectByType(Type);
        // do not resize in iframe mode
        if (WindowMode === 'Iframe') {
            return;
        }
        if (typeof PopupObject !== 'undefined') {
            PopupObject.resizeTo(Width, Height);
        }
    };

    /**
     * @name OpenPopup
     * @memberof Core.UI.Popup
     * @function
     * @param {String} URL - The URL to be open in the new window.
     * @param {String} Type - The type of a window, e.g. 'Action'.
     * @param {String} Profile - The profile of a window, which defines the window parameters. Optional, default is 'Default'.
     * @param {Int}    Unlinked - Optional parameter, if it's 1, popup will not be linked with the parent
     * @description
     *      This function opens a popup window. Every popup is of a specific type and there can only be one window of a type at a time.
     */
    TargetNS.OpenPopup = function (URL, Type, Profile, Unlinked) {
        var PopupObject,
            PopupProfile,
            NewWindow,
            WindowName,
            ConfirmClosePopup = true,
            PopupFeatures;

        // If we are in a mobile environment on opening the popup, open it as an iframe
        if (Core.App.Responsive.IsSmallerOrEqual(Core.App.Responsive.GetScreenSize(), 'ScreenL') && (!localStorage.getItem("DesktopMode") || parseInt(localStorage.getItem("DesktopMode"), 10) <= 0)) {
            TargetNS.SetWindowMode('Iframe');
        }
        else {
            TargetNS.SetWindowMode('Popup');
        }

        CheckOpenPopups();
        if (URL) {
            PopupObject = GetPopupObjectByType(Type);

            // perform only if popups are not unlinked
            if (!Unlinked) {
                if (typeof PopupObject !== 'undefined') {
                    ConfirmClosePopup = window.confirm(Core.Language.Translate('A popup of this screen is already open. Do you want to close it and load this one instead?'));
                    if (ConfirmClosePopup) {
                        TargetNS.ClosePopup(PopupObject);
                    }
                }
            }

            // Only load new popup if the user accepted that the old popup is closed
            if (ConfirmClosePopup) {
                PopupProfile = PopupProfiles[Profile] ? Profile : PopupDefaultProfile;
                /*
                 * Special treatment for the window name. At least in some browsers, window names
                 *  are global, so only one popup window with a particular name may exist across
                 *  all browser tabs. To avoid conflicts with that, we use 'randomized' names
                 *  by including the current time in the name string. This name is also needed
                 *  to save the Type parameter.
                 */

                 /* if Unlined is passed and eq 1 add, diferent name of the popup
                 * it will ensure that popup is nor linked with the parent window
                 */
                if (Unlinked && Unlinked === 1) {
                    WindowName = 'PopupOTRS_' + Type + '_' + Date.parse(new Date());
                }
                else {
                    WindowName = 'OTRSPopup_' + Type + '_' + Date.parse(new Date());
                }

                if (WindowMode === 'Popup') {
                    PopupFeatures = PopupProfiles[PopupProfile].WindowURLParams;
                    // Get the position of the current screen on browsers which support it (non-IE) and
                    //  use it to open the popup on the same screen
                    PopupFeatures += ',left=' + ((window.screen.left || 0) + PopupProfiles[PopupProfile].Left);
                    PopupFeatures += ',width=' + PopupProfiles[PopupProfile].Width;

                    // Bug#11205 (http://bugs.otrs.org/show_bug.cgi?id=11205)
                    // On small screens (still wide enough to open a popup)
                    // it can happen, that the popup window is higher than the screen height
                    // In this case, reduce the popup height to fit into the screen
                    // We don't have to do that for the width, because a smaller screen width
                    // would result in a "responsive popup" aka iframe.
                    if (window.screen.availHeight < PopupProfiles[PopupProfile].Height + PopupProfiles[PopupProfile].Top) {
                        PopupFeatures += ',height=' + (window.screen.availHeight - PopupProfiles[PopupProfile].Top - 20);
                        // Adjust top position to have the same distance between top and bottom line.
                        PopupFeatures += ',top=' + ((window.screen.top || 0) + (PopupProfiles[PopupProfile].Top / 2));
                    }
                    else {
                        PopupFeatures += ',height=' + PopupProfiles[PopupProfile].Height;
                        PopupFeatures += ',top=' + ((window.screen.top || 0) + PopupProfiles[PopupProfile].Top);
                    }

                    NewWindow = window.open(URL, WindowName, PopupFeatures);

                    // check for popup blockers.
                    // currently, popup windows cannot easily be detected in chrome, because it will
                    //      load the entire content in an invisible window.
                    if (!NewWindow || NewWindow.closed || typeof NewWindow.closed === 'undefined') {
                        window.alert(Core.Language.Translate('Could not open popup window. Please disable any popup blockers for this application.'));
                    }
                    else {
                        OpenPopups[Type] = NewWindow;
                    }

                }
                else if (WindowMode === 'Iframe') {
                    // jump to the top
                    window.scrollTo(0, 0);

                    // prevent scrolling of the main window
                    $('html').addClass('NoScroll');

                    // add iframe overlay
                    $('body').append('<iframe data-popuptype="' + Type + '" name="' + WindowName + '" class="PopupIframe" src="' + URL + '"></iframe>');
                    $('iframe.PopupIframe').height($(window).height());
                }
            }
        }
    };

    /**
     * @name HasOpenPopups
     * @memberof Core.UI.Popup
     * @function
     * @returns {Boolean} True, if popups are open on the page, false otherwise.
     * @description
     *      Checks if there are open popups on the page.
     */
    TargetNS.HasOpenPopups = function() {
        var HasOpenPopups = false,
            Popup;

        CheckOpenPopups();
        for (Popup in OpenPopups) {
            if (OpenPopups.hasOwnProperty(Popup)) {
                HasOpenPopups = true;
                break;
            }
         }

        return HasOpenPopups;
    };

    /**
     * @name ClosePopup
     * @memberof Core.UI.Popup
     * @function
     * @param {String|Object} PopupType - The type of a popup or the window object. If not defined, the current popup windoe is closed.
     * @description
     *      This function closes an opened popup.
     *      If no parameter is given, we are in the popup itself and want to close it.
     *      If a parameter is defined we are in the parent window and want to close a specific popup window.
     *      There are four possible states for this function:
     *      1) In parent window, trying to close a "real" popup
     *      2) In parent window, trying to close an iframe-popup ("responsive mode")
     *      3) In the popup itself, closing itself ("real" popup)
     *      4) In the popup itself, closing itself (iframe-popup, "responsive mode")
     */
    TargetNS.ClosePopup = function (PopupType) {
        var PopupObject,
            ParentObject,
            PlaceOfExecution,
            LocalWindowMode;

        // If PopupType is defined, we are in the parent window and want to close a specific popup
        // Otherwise we are in the popup itself
        if (typeof PopupType === 'undefined') {
            PlaceOfExecution = 'Popup';

            // get PopupType of active popup
            PopupType = CurrentIsPopupWindow();

            // the PopupObject is the active window
            PopupObject = window;

            // the parent window object is reached differently, if popup or iframe
            ParentObject = GetWindowParentObject();
        }
        else {
            PlaceOfExecution = 'Parent';

            // if parameter PopupType is a string, we need to get the window object
            if (typeof PopupType === 'string') {
                // This only works in parent window
                PopupObject = GetPopupObjectByType(PopupType);
                ParentObject = window;
            }
            // in some circumstances the parameter PopupType is an window object instead of a string
            else {
                PopupObject = PopupType;

                // we can now find out the type of the popup based on the popup object
                if (PopupObject && typeof PopupObject.name !== 'undefined' && PopupObject.name.match(/OTRSPopup_([^_]+)_.+/)) {
                    PopupType = RegExp.$1;
                }

                // we are still in the parent window
                ParentObject = window;
            }
        }

        if (typeof PopupObject !== 'undefined' && typeof ParentObject !== 'undefined') {
            // Retrieve correct WindowMode (which is only correctly set in the parent window)
            if (PlaceOfExecution === 'Parent') {
                LocalWindowMode = TargetNS.GetWindowMode();
            }
            else if (PlaceOfExecution === 'Popup') {
                LocalWindowMode = ParentObject.Core.UI.Popup.GetWindowMode();
            }

            // if we are in a real popup, we can now savely close the popup.
            if (LocalWindowMode === 'Popup') {
                PopupObject.close();
            }
            // closing the Iframe is a little bit more complicated
            else if (LocalWindowMode === 'Iframe') {
                $('iframe.PopupIframe[data-popuptype=' + PopupType + ']', ParentObject.document).remove();
                $('html', ParentObject.document).removeClass('NoScroll');
            }
        }

        CheckOpenPopups();
    };

    /**
     * @name ExecuteInParentWindow
     * @memberof Core.UI.Popup
     * @function
     * @param {Function} FunctionToExecute - The callback function to execute in the parent window.
     * @param {Array} [FunctionParameters] - Optional function parameters as array.
     * @description
     *      Takes a callback function and hands it over to the parent window (to be executed there).
     *      This is needed to call a function in the parent window from the popup window. The popup window
     *      can be a real popup or an iframe, so it is not as easy as calling window.opener.
     *      IMPORTANT: The FunctionToExecute always needs the ParentWindowObject as first Parameter,
     *      which is used inside this function.
     */
    TargetNS.ExecuteInParentWindow = function (FunctionToExecute, FunctionParameters) {
        var ParentWindow = GetWindowParentObject();

        if (typeof ParentWindow === 'undefined' || ParentWindow === null) {
            return;
        }

        if (typeof FunctionParameters === 'undefined') {
            FunctionParameters = [ParentWindow];
        }
        else {
            FunctionParameters.unshift(ParentWindow);
        }

        if (typeof FunctionToExecute !== 'undefined' && $.isFunction(FunctionToExecute)) {
            // call the function with a new this context (first param)
            // and additional params where the first one is also the parent window object (for use within the function)
            FunctionToExecute.apply(ParentWindow, FunctionParameters);
        }
    };

    /**
     * @name Init
     * @memberof Core.UI.Popup
     * @function
     * @description
     *      The init function.
     */
    TargetNS.Init = function () {

        var PopupURL,
            PopupClose = Core.Config.Get('PopupClose');

        if (PopupClose === 'LoadParentURLAndClose') {
            PopupURL = Core.Config.Get('PopupURL');
            if (TargetNS.CurrentIsPopupWindow()) {
                TargetNS.ExecuteInParentWindow(function(WindowObject) {
                    WindowObject.Core.UI.Popup.FirePopupEvent('URL', { URL: Core.Config.Get('Baselink') + PopupURL });
                });
                TargetNS.ClosePopup();
            }
            else {
                window.location.href = Core.Config.Get('Baselink') + PopupURL;
            }
        }
        else if (PopupClose === 'ReloadParentAndClose') {
            TargetNS.ExecuteInParentWindow(function(WindowObject) {
                WindowObject.Core.UI.Popup.FirePopupEvent('Reload');
            });
            TargetNS.ClosePopup();
        }

        $(window).on('beforeunload.Popup', function () {
            return Core.UI.Popup.CheckPopupsOnUnload();
        });
        Core.App.BindWindowUnloadEvent('Popup', Core.UI.Popup.ClosePopupsOnUnload);
        Core.UI.Popup.RegisterPopupEvent();

        // if this window is a popup itself, register another function
        if (CurrentIsPopupWindow()) {
            Core.UI.Popup.InitRegisterPopupAtParentWindow();
            $('.CancelClosePopup').on('click', function () {
                TargetNS.ClosePopup();
            });
            $('.UndoClosePopup').on('click', function () {
                var RedirectURL = $(this).attr('href'),
                    ParentWindow = GetWindowParentObject();
                ParentWindow.Core.UI.Popup.FirePopupEvent('URL', { URL: RedirectURL });
                TargetNS.ClosePopup();
            });

            // add a class to the body element, if this popup is a real popup
            if (window.opener) {
                $('body').addClass('RealPopup');
            }
        }
    };

    Core.Init.RegisterNamespace(TargetNS, 'APP_GLOBAL');

    return TargetNS;
}(Core.UI.Popup || {}));

/*eslint-enable no-window*/
