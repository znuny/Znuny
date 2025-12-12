// --
// Copyright (C) 2021 Znuny GmbH, https://znuny.org/
// --
// This software comes with ABSOLUTELY NO WARRANTY. For details, see
// the enclosed file COPYING for license information (AGPL). If you
// did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
// --

/**
 * Messages Module
 *
 * Handles alert display and management.
 * Provides functionality for displaying alerts with messages and action links.
 * Supports both legacy DOM-based alerts and JSON-based alerts with multiple actions.
 */

/* global Env */
(function (jQuery) {
    Env.Application.Messages = function (ctx, sandbox, moduleId) {
        Env.Module.call(this, ctx, sandbox, moduleId);
    };
    Env.Application.Messages.prototype = new Env.Module();
    Env.Application.Messages.prototype.constructor = Env.Application.Messages;
    jQuery.extend(Env.Application.Messages.prototype, {

        // Module configuration
        name: 'modMessages',

        /**
         * Hook function to load the module specific dependencies.
         *
         * @method dependencies
         */
        dependencies: function () {
            // No dependencies to load
        },

        /**
         * Hook function to do module specific stuff before binding the events.
         *
         * @method onInit
         */
        onInit: function () {
            // First try to get alert data from JSON
            this.processMessagesData();

            // If no JSON data found, extract from DOM (legacy mode)
            if (!this.alertData) {
                this.extractMessagesData();
            }
        },

        /**
         * Hook function to initialize the module and bind events.
         *
         * @method onStart
         */
        onStart: function () {
            this.bindEvents();
        },

        addMessage: function (html, type, hideAfter) {
            var that, $messages, closeIconPath, closeTranslation, closeHtml, $message, modules, i;

            that = this;
            $messages = jQuery('.messages', this.ctx);
            closeIconPath = jQuery('.inner', this.ctx).attr('data-close-icon-path');
            closeTranslation = jQuery('.inner', this.ctx).attr('data-close-translation');
            closeHtml = '<span class="messageClose"><img src="'+ closeIconPath +'" alt="'+ closeTranslation+'"/></span>';
            $message = jQuery('<div class="message message' + this.capitalizeFirstLetter(type) + '" data-hide-after="' + hideAfter + '">' + html + closeHtml + '</div>');
            $messages.append($message);
            hideAfter = hideAfter || 0;

            modules = that.sandbox.application.registerModules($messages);
            for (i = 0; i < modules.length; i++) {
                that.sandbox.application.start(modules[i]);
            }
            this.bindEvents();

            // add active class after short time
            setTimeout(function() {
                jQuery('.message', that.ctx).addClass('messageActive');
            }, "200");

            // If hideAfter is specified and greater than 0, set up a timer to hide the message
            if (hideAfter > 0) {
                setTimeout(function () {
                    $message.fadeOut('slow', function () {
                        $message.remove();
                    });
                }, hideAfter * 1000); // Convert seconds to milliseconds
            }
        },


        capitalizeFirstLetter: function (string) {
            return string.charAt(0).toUpperCase() + string.slice(1);
        },

        /**
         * Bind event handlers
         *
         * @method bindEvents
         */
        bindEvents: function () {

            jQuery('.messageClose', this.ctx).on('click', function () {
                var $message = jQuery(this).closest('.message');
                $message.remove();
            });

            // TODO: Wait for QA. If QA is error-free, this can be deleted.
            // Bind close button events for messages
            // jQuery(this.ctx).on('click', '.message .close', function (e) {
            //     e.preventDefault();
            //     var $message = jQuery(this).closest('.message');
            //     $message.fadeOut('slow', function () {
            //         $message.remove();
            //     });
            // });
        },

        /**
         * Process messages data from JSON
         *
         * @method processMessagesData
         * @return {Boolean} Success status
         */
        processMessagesData: function () {
            var $alertDataScript, alertData, messageHtml, i, action;

            // Look for alert data in JSON format
            $alertDataScript = jQuery('.alertData', this.ctx);

            if ($alertDataScript.length) {
                try {
                    // Parse the JSON data
                    alertData = JSON.parse($alertDataScript.text());
                    this.alertData = alertData;

                    // Create message HTML
                    messageHtml = '<p>' + alertData.message + '</p>';

                    // Add action buttons if present
                    if (alertData.actions && alertData.actions.length) {
                        messageHtml += '<div class="message-actions">';

                        // Add each action button
                        for (i = 0; i < alertData.actions.length; i++) {
                            action = alertData.actions[i];
                            if (action && action.url){
                                messageHtml += '<a href="' + action.url + '" class="' + (action.classes || '') + '">' + action.text + '</a>';
                            }else{
                                messageHtml += action.text;
                            }
                        }

                        messageHtml += '</div>';
                    }

                    // Add close button
                    messageHtml += '<a class="close" href="#"><i class="fa fa-times"></i></a>';

                    // Add the message
                    this.addMessage(messageHtml, alertData.type || 'notice', alertData.hideAfter || 0);

                    return true;
                } catch (e) {
                    console.error('Error parsing alert data JSON:', e);
                }
            }

            return false;
        },

        /**
         * Extract messages data from DOM (legacy mode)
         *
         * @method extractMessagesData
         * @return {Boolean} Success status
         */
        extractMessagesData: function () {
            var $messages;

            // Look for legacy message elements
            $messages = jQuery('.message', this.ctx);

            if ($messages.length) {
                $messages.each(function (index, element) {
                    var $message, hideAfter;

                    $message = jQuery(element);

                    // Get hideAfter value if present
                    hideAfter = parseInt($message.attr('data-hide-after') || '0', 10);

                    // If hideAfter is specified and greater than 0, set up a timer to hide the message
                    if (hideAfter > 0) {
                        setTimeout(function () {
                            $message.fadeOut('slow', function () {
                                $message.remove();
                            });
                        }, hideAfter * 1000); // Convert seconds to milliseconds
                    }
                });

                return true;
            }

            return false;
        },

    });
})(jQuery);
