// --
// Copyright (C) 2021 Znuny GmbH, https://znuny.org/
// --
// This software comes with ABSOLUTELY NO WARRANTY. For details, see
// the enclosed file COPYING for license information (AGPL). If you
// did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
// --

/**
 * Sidebar Module
 *
 * Handles main sidebar functionality and responsive behavior.
 * Provides open/close functionality for the main sidebar with responsive breakpoints.
 * Automatically closes sidebar on smaller screens (< 1200px).
 */

/* global Env */
(function (jQuery) {
    Env.Application.Sidebar = function (ctx, sandbox, moduleId) {
        Env.Module.call(this, ctx, sandbox, moduleId);
    };
    Env.Application.Sidebar.prototype = new Env.Module();
    Env.Application.Sidebar.prototype.constructor = Env.Application.Sidebar;
    jQuery.extend(Env.Application.Sidebar.prototype, {

        // Module configuration
        name: 'modSidebar',

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
            this.syncSidebarOpenClass();
            this.checkWidth();
        },

        bindEvents: function () {
            var that = this;
            jQuery(this.ctx).closest('.sectionSidebar').find('#TicketSidebar-toggle').on('click', function (e) {
                e.preventDefault();
                if (jQuery('.inner:first', that.ctx).hasClass('sidebarActive')) {
                    that.close();
                } else {
                    that.open();
                }
            });
            jQuery('.sidebarTrigger', this.ctx).click(function () {
                that.open();
            });

            // close sidebar if window is smaller than x pixel
            jQuery(window).on('resize', function () {
                that.checkWidth();
            });
        },

        syncSidebarOpenClass: function () {
            var $aside = jQuery(this.ctx).closest('.sectionSidebar');
            if (jQuery('.inner:first', this.ctx).hasClass('sidebarActive')) {
                $aside.addClass('sidebarOpen');
            } else {
                $aside.removeClass('sidebarOpen');
            }
        },

        checkWidth: function () {
            var that = this;
            var windowWidth = jQuery(window).width();
            if (windowWidth < 1200) {
                that.close();
            }
        },

        close: function () {
            var $toggle = jQuery(this.ctx).closest('.sectionSidebar').find('#TicketSidebar-toggle');
            $toggle.addClass('sidebar-animating');
            jQuery('.inner:first', this.ctx).removeClass('sidebarActive');
            this.syncSidebarOpenClass();
            setTimeout(function () {
                $toggle.removeClass('sidebar-animating');
            }, 310);
        },

        open: function () {
            var $toggle = jQuery(this.ctx).closest('.sectionSidebar').find('#TicketSidebar-toggle');
            $toggle.addClass('sidebar-animating');
            jQuery('.inner:first', this.ctx).addClass('sidebarActive');
            this.syncSidebarOpenClass();
            setTimeout(function () {
                $toggle.removeClass('sidebar-animating');
            }, 310);
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
