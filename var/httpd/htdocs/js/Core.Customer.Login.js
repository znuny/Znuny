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
Core.Customer = Core.Customer || {};

/**
 * @namespace Core.Customer.Login
 * @memberof Core.Customer
 * @author OTRS AG
 * @description
 *      This namespace contains all functions for the Customer login.
 */
Core.Customer.Login = (function (TargetNS) {
    if (!Core.Debug.CheckDependency('Core.Customer.Login', 'Core.UI', 'Core.UI')) {
        return false;
    }

    /**
     * @name Init
     * @memberof Core.Customer.Login
     * @function
     * @returns {Boolean} False if browser is not supported
     * @description
     *      This function initializes the login functions.
     */
    TargetNS.Init = function () {
        var Now = new Date(),
            Diff = Now.getTimezoneOffset(),
            FormID,
            $ContainerLinks = $('[data-container-link]'),
            LoginFailed     = Core.Config.Get('LoginFailed'),
            SignupError     = Core.Config.Get('SignupError');

        // Browser is too old
        if (!Core.Customer.SupportedBrowser) {
            $('#Login').hide();
            $('#Reset').hide();
            $('#Signup').hide();
            $('#PreLogin').hide();
            $('#OldBrowser').show();
            return false;
        }

        // enable login form
        Core.Form.EnableForm($('#Login form, #Reset form, #Signup form'));

        $('#TimeZoneOffset').val(Diff);

        if ($('#PreLogin').length) {
            $('#PreLogin form').submit();
            return false;
        }

        // Fill the reset-password input field with the same value the user types in the login screen
        // so that the user doesn't have to type in his user name again if he already did
        $('#User').blur(function () {
            if ($(this).val()) {
                // clear the username-value and hide the field's label
                $('#ResetUser').val($(this).val()).prev('label').hide();
            }
        });

        // show active container div, hide the rest
        $ContainerLinks.on('click', function() {
            FormID = $(this).data('containerLink');
            TargetNS.ActivateForm(FormID);
        });

        // shake login box on authentication failure
        if (typeof LoginFailed !== 'undefined' && parseInt(LoginFailed, 10) === 1) {
            Core.UI.Animate($('#Login'), 'Shake');
        }

        // navigate to Signup when SignupError exists
        if (typeof SignupError !== 'undefined' && parseInt(SignupError, 10) === 1) {
            TargetNS.ActivateForm('Signup');
        }
    };

    /**
     * @name ActivateForm
     * @memberof Core.Customer.Login
     * @function
     * @param {String} FormID - Name of form container
     * @description
     *      This function shows the given form contain and
     *      hides the rest.
     */
    TargetNS.ActivateForm = function (FormID) {
        $('#Container > div').addClass('Hidden');
        $('#' + FormID).removeClass('Hidden');
    }

    Core.Init.RegisterNamespace(TargetNS, 'APP_MODULE');

    return TargetNS;
}(Core.Customer.Login || {}));
