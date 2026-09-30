// --
// Copyright (C) 2021 Znuny GmbH, https://znuny.org/
// --
// This software comes with ABSOLUTELY NO WARRANTY. For details, see
// the enclosed file COPYING for license information (AGPL). If you
// did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
// --

/*eslint-disable no-window*/

/**
 * Alert Module
 *
 * Handles alert display and management.
 * Provides functionality for displaying alerts with messages and action links.
 * Supports both legacy DOM-based alerts and JSON-based alerts with multiple actions.
 */

/* global Env */
(function (jQuery) {
    Env.Application.Alert = function (ctx, sandbox, moduleId) {
        Env.Module.call(this, ctx, sandbox, moduleId);
    };
    Env.Application.Alert.prototype = new Env.Module();
    Env.Application.Alert.prototype.constructor = Env.Application.Alert;
    jQuery.extend(Env.Application.Alert.prototype, {

        // Module configuration
        name: 'modAlert',

        // Alert data
        alertData: null,

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
            this.processAlertData();
        },

        /**
         * Hook function to initialize the module and bind events.
         *
         * @method onStart
         */
        onStart: function () {
            var html, notificationModule, notificationId;

            this.bindEvents();

            if (this.alertData) {
                // Find the Notification module first
                notificationModule = this.findNotificationModule();
                if (notificationModule) {
                    // Generate notificationId from alert data (use id if provided, otherwise generate from message text using Notification module)
                    if (this.alertData.id) {
                        notificationId = this.alertData.id;
                    } else if (notificationModule.generateNotificationId) {
                        notificationId = notificationModule.generateNotificationId(this.alertData.message);
                    }

                    // Check if notification was already closed before creating it
                    if (notificationModule.isNotificationClosed && notificationModule.isNotificationClosed(notificationId)) {
                        // Notification was closed, don't display it
                        return;
                    }

                    html = this.createAlert(this.alertData);

                    // Send the generated HTML to Notification module with notificationId and KeepClosedForSession flag
                    notificationModule.addMessage(html, this.alertData.type || 'notice', this.alertData.hideAfter || 0, notificationId, this.alertData.keepClosedForSession);
                }
            }
        },

        /**
         * Process alert data from JSON
         *
         * @method processAlertData
         */
        processAlertData: function() {
            var $alertDataScript, alertData;

            $alertDataScript = jQuery('.alertData', this.ctx);
            if (!$alertDataScript.length) {
                return;
            }

            try {
                alertData = JSON.parse($alertDataScript.text());

                // Store the alert data for future use
                this.alertData = alertData;

                // Add type property if not present
                if (!this.alertData.type) {
                    this.alertData.type = "notice";
                }

                // Ensure actions is always an array
                if (!this.alertData.actions) {
                    this.alertData.actions = [];
                }

            } catch (e) {
                console.error('Error parsing alert data JSON:', e); // eslint-disable-line no-console
            }
        },

        /**
         * Bind event handlers
         *
         * @method bindEvents
         */
        bindEvents: function() {
            // UndoClosePopup handling is done by Core.UI.Popup via event delegation
        },

        /**
         * Find the Notification module instance
         *
         * @method findNotificationModule
         * @return {Object|null} The Notification module instance or null if not found
         */
        findNotificationModule: function() {
            var $notificationModule, moduleId;

            // Look for the Notification module in the DOM
            $notificationModule = jQuery('.mod.modNotification');

            if ($notificationModule.length) {
                // Get the module ID
                moduleId = $notificationModule.attr('data-moduleid');

                // Get the module instance from the sandbox
                if (moduleId) {
                    return this.sandbox.getModule(moduleId);
                }
            }
        },

        capitalizeFirstLetter: function (string) {
            return string.charAt(0).toUpperCase() + string.slice(1);
        },

        /**
         * Decode HTML entities and sanitize to allow only safe tags
         *
         * @method decodeAndSanitizeHTML
         * @param {String} html - The HTML string with entities
         * @return {String} Decoded and sanitized HTML
         */
        decodeAndSanitizeHTML: function(html) {
            var txt, decoded, temp, sanitized;

            // First decode HTML entities
            txt = document.createElement('textarea');
            txt.innerHTML = html;
            decoded = txt.value;

            // Create a temporary div to parse the HTML
            temp = document.createElement('div');
            temp.innerHTML = decoded;

            // Sanitize: only allow safe tags and attributes
            sanitized = this.sanitizeNode(temp);

            return sanitized;
        },

        /**
         * Recursively sanitize a DOM node, allowing only safe tags and attributes
         *
         * @method sanitizeNode
         * @param {Node} node - The DOM node to sanitize
         * @return {String} Sanitized HTML string
         */
        sanitizeNode: function(node) {
            var result = '', i, child, tagName, href, target;

            // Whitelist of allowed tags
            var allowedTags = {
                'a': ['href', 'target'],
                'strong': [],
                'b': [],
                'em': [],
                'i': [],
                'u': [],
                'br': [],
                'span': []
            };

            for (i = 0; i < node.childNodes.length; i++) {
                child = node.childNodes[i];

                // Text node - keep as is
                if (child.nodeType === 3) {
                    result += child.textContent;
                }
                // Element node - check if allowed
                else if (child.nodeType === 1) {
                    tagName = child.tagName.toLowerCase();

                    if (allowedTags[tagName]) {
                        result += '<' + tagName;

                        // Add allowed attributes
                        if (tagName === 'a') {
                            href = child.getAttribute('href');
                            if (href) {
                                // Prevent javascript: URLs
                                if (!href.match(/^javascript:/i)) {
                                    result += ' href="' + href.replace(/"/g, '&quot;') + '"';
                                }
                            }
                            target = child.getAttribute('target');
                            if (target) {
                                result += ' target="' + target.replace(/"/g, '&quot;') + '"';
                            }
                        }

                        result += '>';

                        // Recursively process child nodes
                        if (child.childNodes.length > 0) {
                            result += this.sanitizeNode(child);
                        }

                        result += '</' + tagName + '>';
                    } else {
                        // Tag not allowed - just extract text content
                        result += child.textContent;
                    }
                }
            }

            return result;
        },

        /**
         * Create a single alert from JSON data
         *
         * @method createAlert
         * @param {Object} data - The alert data
         * @return {String} HTML for the alert
         */
        createAlert: function(data) {
            var type, html, self, message, inlineMultipleActions, separatorText, actionClasses, actionId;

            if (!data) {
                return '';
            }

            // Add default type if not present
            type = data.type || 'notice';
            self = this;

            // Decode HTML entities and sanitize to only allow safe tags
            message = this.decodeAndSanitizeHTML(data.message);

            html = '<div class="mod modAlert">';
            html += '<div class="inner">';
            html += '<div class="alert alertType' + this.capitalizeFirstLetter(type) + '">';
            html += '<div class="alertContent">' + message + '</div>';

            if (data.actions && !Array.isArray(data.actions)) {
                throw new Error('Invalid "data" parameter: "actions" sub-property needs to be passed as an array!');
            }
            // Handle multiple actions
            if (data.actions && data.actions.length) {
                inlineMultipleActions = data.actions.length > 1;
                separatorText = data.actionSeparator || 'or';

                html += '<div class="alertActions' + (inlineMultipleActions ? ' alertActionsInline' : '') + '">';
                data.actions.forEach(function (action, index) {

                    if (action.url) {
                        actionClasses = 'btn-primary alertButton alertButton' + self.capitalizeFirstLetter(action.type || 'submit'),
                            actionId = '';

                        if (action.class) {
                            actionClasses += ' ' + (Array.isArray(action.class) ? action.class.join(' ') : action.class);
                        }

                        if (action.id) {
                            actionId = ' id="' + action.id + '"';
                        }

                        html += '<a class="' + actionClasses + '" href="' + action.url + '"' + actionId + '>';
                        html += action.text || 'Action';
                        html += '</a>';

                        // Insert separator between inline actions
                        if (inlineMultipleActions && index < data.actions.length - 1) {
                            html += '<span class="alertActionSeparator">' + separatorText + '</span>';
                        }
                    }
                });
                html += '</div>';
            }
            html += '</div>';
            html += '</div>';
            html += '</div>';

            return html;
        }
    });
})(jQuery);
