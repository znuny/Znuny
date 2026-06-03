// --
// Copyright (C) 2021 Znuny GmbH, https://znuny.org/
// --
// This software comes with ABSOLUTELY NO WARRANTY. For details, see
// the enclosed file COPYING for license information (AGPL). If you
// did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
// --

/**
 * Notification Module
 *
 * Handles alert display and management.
 * Provides functionality for displaying alerts with messages and action links.
 * Supports both legacy DOM-based alerts and JSON-based alerts with multiple actions.
 */

/* global Env */
(function (jQuery) {
    Env.Application.Notification = function (ctx, sandbox, moduleId) {
        Env.Module.call(this, ctx, sandbox, moduleId);
    };
    Env.Application.Notification.prototype = new Env.Module();
    Env.Application.Notification.prototype.constructor = Env.Application.Notification;
    jQuery.extend(Env.Application.Notification.prototype, {

        // Module configuration
        name: 'modNotification',

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

            // Load closed notifications from session
            this.getClosedNotifications();

            // First try to get alert data from JSON
            this.processNotificationsData();

            // If no JSON data found, extract from DOM (legacy mode)
            if (!this.alertData) {
                this.extractNotificationsData();
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

        addMessage: function (html, type, hideAfter, notificationId, keepClosedForSession) {
            var that, $messages, closeIconPath, closeTranslation, closeHtml, $message, modules, i, messageText, $tempDiv;

            that = this;
            $messages = jQuery('.messages', this.ctx);
            closeIconPath = jQuery('.inner', this.ctx).attr('data-close-icon-path');
            closeTranslation = jQuery('.inner', this.ctx).attr('data-close-translation');
            closeHtml = '<span class="notificationClose"><img src="'+ closeIconPath +'" alt="'+ closeTranslation+'"/></span>';

            // Generate notificationId if not provided
            if (!notificationId) {
                // Extract message text from HTML
                $tempDiv = jQuery('<div>').html(html);
                messageText = $tempDiv.find('p').first().text().trim() || $tempDiv.text().trim();
                notificationId = this.generateNotificationId(messageText);
            }

            // Set keepClosedForSession to 0 if not provided
            keepClosedForSession = keepClosedForSession || 0;

            $message = jQuery('<div class="message message' + this.capitalizeFirstLetter(type) + '" data-hide-after="' + hideAfter + '" data-notification-id="' + notificationId + '" data-keep-closed-for-session="' + keepClosedForSession + '">' + html + closeHtml + '</div>');
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
            var that = this;

            jQuery('.notificationClose', this.ctx).on('click', function () {
                var $message = jQuery(this).closest('.message'),
                    notificationId = $message.attr('data-notification-id'),
                    keepClosedForSession = $message.attr('data-keep-closed-for-session');

                if (notificationId && keepClosedForSession === '1') {
                    // Save closed notification ID to session only if KeepClosedForSession is set
                    that.addClosedNotification(notificationId);
                }

                $message.remove();
            });
        },

        /**
         * Process notifications data from JSON
         *
         * @method processNotificationsData
         * @return {Boolean} Success status
         */
        processNotificationsData: function () {
            var $alertDataScript, alertData, messageHtml, i, action, notificationId;

            // Look for alert data in JSON format
            $alertDataScript = jQuery('.alertData', this.ctx);

            if ($alertDataScript.length) {
                try {
                    // Parse the JSON data
                    alertData = JSON.parse($alertDataScript.text());
                    this.alertData = alertData;

                    // Get notification ID from alertData or generate from message text
                    notificationId = alertData.id || this.generateNotificationId(alertData.message);

                    // Check if notification was already closed
                    if (this.isNotificationClosed(notificationId)) {
                        // Notification was closed, don't display it
                        return false;
                    }

                    // Create message HTML
                    messageHtml = '<p>' + alertData.message + '</p>';

                    // Add action buttons if present
                    if (alertData.actions && alertData.actions.length) {
                        messageHtml += '<div class="message-actions">';

                        // Add each action button
                        for (i = 0; i < alertData.actions.length; i++) {
                            action = alertData.actions[i];

                            // Add action button if url contains `Action=`
                            if (action && action.url){
                                messageHtml += '<a href="' + action.url + '" class="' + (action.classes || '') + '">' + action.text + '</a>';
                            }
                            // Add action text if url does not contain `Action=`
                            else {
                                messageHtml += action.text;
                            }
                        }

                        messageHtml += '</div>';
                    }

                    // Add close button
                    messageHtml += '<a class="close" href="#"><i class="fa fa-times"></i></a>';

                    // Add the message with notification ID and KeepClosedForSession flag
                    this.addMessage(messageHtml, alertData.type || 'notice', alertData.hideAfter || 0, notificationId, alertData.keepClosedForSession);

                    return true;
                } catch (e) {
                    // Error parsing alert data JSON - silently fail
                }
            }

            return false;
        },

        /**
         * Extract notifications data from DOM (legacy mode)
         *
         * @method extractNotificationsData
         * @return {Boolean} Success status
         * @description
         *      This method is only called if no JSON alert data was found.
         *      It looks for legacy message elements that are already in the DOM.
         *      If no legacy messages exist, $messages will be empty, which is normal.
         */
        extractNotificationsData: function () {
            var that = this,
                $messages;

            // Look for legacy message elements that are already in the DOM
            // Note: This will be empty if notifications are created via JSON (processNotificationsData)
            // or if there are no legacy messages in the DOM
            $messages = jQuery('.message', this.ctx);

            if ($messages.length) {
                $messages.each(function (index, element) {
                    var $message, hideAfter, messageText, notificationId;

                    $message = jQuery(element);

                    // Get message text and generate ID if not present
                    messageText = $message.text().trim();
                    notificationId = $message.attr('data-notification-id') || $message.attr('data-message-id') || that.generateNotificationId(messageText);

                    // Check if notification was already closed
                    if (that.isNotificationClosed(notificationId)) {
                        // Notification was closed, remove it
                        $message.remove();
                        return;
                    }

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

        /**
         * Generate a unique notification ID from message text
         *
         * @method generateNotificationId
         * @param {String} messageText - The message text
         * @return {String} Notification ID
         */
        generateNotificationId: function (messageText) {
            var hash = 0,
                i,
                chr,
                normalizedText;

            if (!messageText || messageText.length === 0) {
                // Use a fixed ID for empty notifications so they can be recognized consistently
                return 'notification_empty';
            }

            // Normalize message text: trim and remove HTML tags for consistent hashing
            // This ensures the same message text always generates the same ID
            normalizedText = messageText.replace(/<[^>]*>/g, '').trim();

            if (normalizedText.length === 0) {
                // Use a fixed ID for empty notifications (after normalization) so they can be recognized consistently
                return 'notification_empty';
            }

            // Generate hash from normalized message text using djb2-like algorithm
            // This converts the string into a numeric hash value:
            // - charCodeAt() gets the Unicode value of each character
            // - (hash << 5) - hash is equivalent to hash * 31, which is a common multiplier
            // - Adding the character code accumulates the hash
            // - hash & hash ensures the result stays within 32-bit integer range
            for (i = 0; i < normalizedText.length; i++) {
                chr = normalizedText.charCodeAt(i);
                hash = ((hash << 5) - hash) + chr;
                hash = hash & hash; // Convert to 32bit integer
            }

            return 'notification_' + Math.abs(hash).toString(36);
        },

        /**
         * Get closed notifications from session
         *
         * @method getClosedNotifications
         */
        getClosedNotifications: function () {
            var closedNotificationsJson = Core.Config.Get('UserClosedNotifications') || '[]';

            // If it's already an array, use it directly
            if (jQuery.isArray(closedNotificationsJson)) {
                this.closedNotifications = closedNotificationsJson;
            } else {
                try {
                    this.closedNotifications = JSON.parse(closedNotificationsJson);
                } catch (e) {
                    this.closedNotifications = [];
                }
            }

            if (!jQuery.isArray(this.closedNotifications)) {
                this.closedNotifications = [];
            }
        },

        /**
         * Check if a notification is closed
         *
         * @method isNotificationClosed
         * @param {String} notificationId - The notification ID
         * @return {Boolean} True if notification is closed
         */
        isNotificationClosed: function (notificationId) {
            var isClosed = false,
                i;

            if (!this.closedNotifications) {
                this.getClosedNotifications();
            }

            if (!notificationId) {
                return false;
            }

            // Trim notificationId to avoid whitespace issues
            notificationId = String(notificationId).trim();

            // Check if notificationId is in closedNotifications array
            isClosed = false;
            for (i = 0; i < this.closedNotifications.length; i++) {
                if (String(this.closedNotifications[i]).trim() === notificationId) {
                    isClosed = true;
                    break;
                }
            }

            return isClosed;
        },

        /**
         * Add closed notification ID to closedNotifications array
         *
         * @method addClosedNotification
         * @param {String} notificationId - The notification ID to add
         */
        addClosedNotification: function (notificationId) {

            var closedNotificationsJson;

            if (!this.closedNotifications) {
                this.getClosedNotifications();
            }

            // Add notification ID if not already in array
            if (jQuery.inArray(notificationId, this.closedNotifications) === -1) {
                this.closedNotifications.push(notificationId);

                // Update session via AJAX
                if (typeof Core !== 'undefined' && Core.Agent && Core.Agent.UpdateSessionID) {
                    closedNotificationsJson = JSON.stringify(this.closedNotifications);
                    Core.Agent.UpdateSessionID('UserClosedNotifications', closedNotificationsJson,
                        function() {
                            // Success callback - notification added to closedNotifications array
                        },
                        function() {
                            // Error callback - silently fail
                        }
                    );
                }
            }
        },

    });
})(jQuery);
