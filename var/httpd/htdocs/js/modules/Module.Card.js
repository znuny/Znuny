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
        name: 'modCard',
        closeClass : 'cardClosed',

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
            jQuery('.cardTitleTrigger', this.ctx).click(function () {
                if (jQuery('.inner:first', that.ctx).hasClass(that.closeClass)) {
                    that.open();
                } else {
                    that.close();
                }
            });
        },

        close: function () {
            var element;

            jQuery('.inner:first', this.ctx).addClass(this.closeClass);
            element = jQuery('.cardContent', this.ctx)[0];
            element.style.maxHeight = '0px';

        },

        open: function () {
            var element, scrollHeight;

            element = jQuery('.cardContent', this.ctx)[0];
            // we have to add the padding value
            scrollHeight = element.scrollHeight + 40;
            element.style.maxHeight = scrollHeight + 'px';
            jQuery('.inner:first', this.ctx).removeClass(this.closeClass);

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
