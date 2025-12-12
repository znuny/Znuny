// --
// Copyright (C) 2021 Znuny GmbH, https://znuny.org/
// --
// This software comes with ABSOLUTELY NO WARRANTY. For details, see
// the enclosed file COPYING for license information (AGPL). If you
// did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
// --

/**
 * Sidebar Widget Module
 *
 * Handles collapsible sidebar widget functionality.
 * Provides expand/collapse behavior for sidebar widgets with smooth animations.
 * Supports click-to-toggle functionality for widget titles.
 */

/* global Env */
(function (jQuery) {
    Env.Application.SidebarWidget = function (ctx, sandbox, moduleId) {
        Env.Module.call(this, ctx, sandbox, moduleId);
    };
    Env.Application.SidebarWidget.prototype = new Env.Module();
    Env.Application.SidebarWidget.prototype.constructor = Env.Application.SidebarWidget;
    jQuery.extend(Env.Application.SidebarWidget.prototype, {

        // Module configuration
        name: 'modSidebarWidget',
        closeClass: 'sidebarWidgetClosed',

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
            jQuery('.sidebarWidgetTitle', this.ctx).click(function () {
                if (jQuery('.inner:first', that.ctx).hasClass(that.closeClass)) {
                    that.open();
                } else {
                    that.close();
                }
            });
        },

        close: function () {
            var element = jQuery('.sidebarWidgetContent', this.ctx)[0];
            element.style.maxHeight = '0px';
            jQuery('.inner:first', this.ctx).addClass(this.closeClass);

        },

        open: function () {
            var element = jQuery('.sidebarWidgetContent', this.ctx)[0];
            // we have to add the padding value
            var scrollHeight = element.scrollHeight + 30;
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
