// --
// Copyright (C) 2021 Znuny GmbH, https://znuny.org/
// --
// This software comes with ABSOLUTELY NO WARRANTY. For details, see
// the enclosed file COPYING for license information (AGPL). If you
// did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
// --

/**
 * Form Module
 *
 * Handles form functionality and field manipulation.
 * Provides methods for setting form field values and form interactions.
 * Supports dynamic form field updates and form state management.
 */

/* global Env */
(function (jQuery) {
    Env.Application.Form = function (ctx, sandbox, moduleId) {
        Env.Module.call(this, ctx, sandbox, moduleId);
    };
    Env.Application.Form.prototype = new Env.Module();
    Env.Application.Form.prototype.constructor = Env.Application.Form;
    jQuery.extend(Env.Application.Form.prototype, {

        // Module configuration
        name: 'modForm',

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
        },


        setValue: function (name, value) {
            var element = jQuery("[name='"+ name +"']", this.ctx);
            element.val(value);
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
