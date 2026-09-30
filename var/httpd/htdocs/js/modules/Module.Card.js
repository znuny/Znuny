// --
// Copyright (C) 2021 Znuny GmbH, https://znuny.org/
// --
// This software comes with ABSOLUTELY NO WARRANTY. For details, see
// the enclosed file COPYING for license information (AGPL). If you
// did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
// --

/**
 * Card Module
 *
 * Handles collapsible card functionality.
 * Provides expand/collapse behavior for card components with smooth animations.
 * Supports click-to-toggle functionality for card titles.
 */

/* global Env */
(function (jQuery) {
    Env.Application.Card = function (ctx, sandbox, moduleId) {
        Env.Module.call(this, ctx, sandbox, moduleId);
    };
    Env.Application.Card.prototype = new Env.Module();
    Env.Application.Card.prototype.constructor = Env.Application.Card;
    jQuery.extend(Env.Application.Card.prototype, {

        // Module configuration
        name:       'modCard',
        closeClass: 'Collapsed',
        openClass:  'Expanded',

        /**
         * Hook function to load the module specific dependencies.
         *
         * @method dependencies
         */
        dependencies: function () {
        },

        /**
         * Hook function to do module specific stuff before binding the events (i.e. fetching some data).
         *
         * @method onInit
         */
        onStart: function () {
            this.bindEvents();
        },

        bindEvents: function () {
            var that = this;

            // Toggle expand/collapse state
            function toggleCard() {
                var $Inner = jQuery('.inner:first', that.ctx);
                if ($Inner.hasClass(that.closeClass)) {
                    that.open();
                } else {
                    that.close();
                }

                Core.App.Publish('Event.UI.ToggleWidget', [$Inner]);
            }

            // Trigger button click
            jQuery('.cardTitleTrigger', this.ctx).click(function (e) {
                e.stopPropagation();
                toggleCard();
            });

            // Card title click – skip if trigger or interactive element clicked
            jQuery('.cardTitle', this.ctx).on('click', function (e) {
                // Skip if trigger clicked
                if (jQuery(e.target).closest('.cardTitleTrigger').length) {
                    return;
                }
                // Skip if interactive element (link, button, input, select, etc.) clicked
                if (jQuery(e.target).closest('a, button, input, select, [role="button"]').length) {
                    return;
                }
                toggleCard();
            });
        },

        // Collapse card content
        close: function () {
            var element;

            jQuery('.inner:first', this.ctx).addClass(this.closeClass);
            jQuery('.inner:first', this.ctx).removeClass(this.openClass);
            element = jQuery('.cardContent', this.ctx)[0];
            element.style.maxHeight = '0px';

        },

        // Expand card content
        open: function () {
            var element, scrollHeight;

            element = jQuery('.cardContent', this.ctx)[0];
            // Add padding for animation
            scrollHeight = element.scrollHeight + 40;
            element.style.maxHeight = scrollHeight + 'px';
            jQuery('.inner:first', this.ctx).removeClass(this.closeClass);
            jQuery('.inner:first', this.ctx).addClass(this.openClass);

            setTimeout(function () {
                element.style.maxHeight = 'unset';
            }, 250);
        },


        /**
         * Hook function to do module specific stuff before binding the events (i.e. fetching some data).
         *
         * @method onInit
         */

        onInit: function () {
        },

    });
})(jQuery);
