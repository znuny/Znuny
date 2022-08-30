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
Core.UI = Core.UI || {};

/**
 * @namespace Core.UI.Accessibility
 * @memberof Core.UI
 * @author OTRS AG
 * @description
 *      This namespace contains all accessibility related functions.
 */
Core.UI.Accessibility = (function (TargetNS) {

    /**
     * @name Init
     * @memberof Core.UI.Accessibility
     * @function
     * @description
     *      This function initializes the W3C ARIA role attributes for the
     *      different parts of the page. It is not inside the HTML because
     *      these attributes are not part of the XHTML standard.
     */
    TargetNS.Init = function () {
        /* set W3C ARIA role attributes for screenreaders */
        $('.ARIARoleBanner')
            .attr('role', 'banner');
        $('.ARIARoleNavigation')
            .attr('role', 'navigation');
        $('.ARIARoleSearch')
            .attr('role', 'search');
        $('.ARIARoleContentinfo')
            .attr('role', 'contentinfo');
        $('.ARIARoleMain')
            .attr('role', 'main');
        $('.ARIAHasPopup')
            .attr('aria-haspopup', 'true');
        $('.Validate_Required, .Validate_DependingRequiredAND, .Validate_DependingRequiredOR')
            .attr('aria-required', 'true');

        TargetNS.AccessibleNavigation();
    };

    /**
     * @name AccessibleNavigation
     * @memberof Core.UI.Accessibility
     * @function
     * @description
     *      This function enables keyboard navigation for the
     *      css-based submenus in the main navigation.
     */
    TargetNS.AccessibleNavigation = function() {

        $('#Navigation > ul > li a').on('focus', function() {
            $(this)
                .next('ul')
                .addClass('Expanded');
        });

        $('#Navigation > ul > li > ul').on('mouseleave', function() {
            $(this).removeClass('Expanded');
        });

        $('#Navigation > ul > li > ul li a').on('focus', function() {
            $(this)
                .closest('ul')
                .addClass('Expanded');
        });

        $('#Navigation > ul > li > ul li:last-child').prev('li').find('a').on('focusout', function() {
            $(this)
                .closest('ul')
                .removeClass('Expanded');
        });
    };

    /**
     * @name AudibleAlert
     * @memberof Core.UI.Accessibility
     * @function
     * @param {String} Text - Text to be spoken to the user, may not contain markup.
     * @description
     *      This function receives a text to be spoken to users
     *      using a screenreader. This is achieved by creating an
     *      element with the aria landmark role "alert" causing it
     *      to be read immediately.
     */
    TargetNS.AudibleAlert = function (Text) {
        var AlertMessageID = 'Accessibility_AlertMessage';

        // remove possibly pre-existing alert message
        $('#' + AlertMessageID).remove();

        // add new alert message
        $('body').append('<div role="alert" id="' + AlertMessageID + '" class="ARIAAlertMessage">' + Text + '</div>');

    };

    Core.Init.RegisterNamespace(TargetNS, 'APP_GLOBAL');

    return TargetNS;
}(Core.UI.Accessibility || {}));
