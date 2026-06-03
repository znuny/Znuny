// --
// Copyright (C) 2021 Znuny GmbH, https://znuny.org/
// --
// This software comes with ABSOLUTELY NO WARRANTY. For details, see
// the enclosed file COPYING for license information (AGPL). If you
// did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
// --

/**
 * CustomerSelector Module
 *
 * Handles customer selection, search, and management in forms.
 * Provides functionality for searching customers, adding/removing customers,
 * and managing customer selection in forms.
 */

/* global Env */
(function (jQuery) {
    Env.Application.CustomerSelector = function (ctx, sandbox, moduleId) {
        Env.Module.call(this, ctx, sandbox, moduleId);
    };
    Env.Application.CustomerSelector.prototype = new Env.Module();
    Env.Application.CustomerSelector.prototype.constructor = Env.Application.CustomerSelector;
    jQuery.extend(Env.Application.CustomerSelector.prototype, {

        // Module configuration
        name: 'modCustomerSelector',

        // DOM elements and selectors
        suggestUrl: '',
        inputField: null,
        suggestElement: null,
        suggestElementActiveClass: 'customerSelectorFieldSuggestActive',
        suggestItemHighlightedClass: 'customerSelectorFieldSuggestItemHighlighted',

        // Customer selection settings
        selectedCustomerAllow: false,
        selectedCustomerFieldName: '',
        removeIconPath: '',

        // Form integration
        formModule: null,

        // Input field attributes
        inputNameAttribute: '',
        inputTextNameAttribute: '',
        inputType: 'customer', // customer, cc or bcc
        inputCounterNameAttribute: 'CustomerTicketCounterToCustomer',
        inputSelectedNameAttribute: 'CustomerSelected',
        customerQueueAttribute: '',

        // State tracking
        customerCounter: 0,
        addressBookSubscriptionHandle: null,
        lastSearch: '',
        lastAjaxSearch: null,

        /**
         * Hook function to load the module specific dependencies.
         *
         * @method dependencies
         *
         */
        dependencies: function () {
            // No dependencies to load
        },

        /**
         * Hook function to do module specific stuff before binding the events.
         *
         * @method onInit
         *
         */
        onInit: function () {
            this.setValues();
            this.defineCustomerInputFields();
        },

        /**
         * Hook function to initialize the module and bind events.
         *
         * @method onStart
         *
         */
        onStart: function () {
            this.bindEvents();
            this.extractAndRenderCustomers();
            this.bindSelectedCustomerEvents();
        },

        /**
         * Extracts customer data from HTML and re-renders it
         *
         * @method extractAndRenderCustomers
         *
         */
        extractAndRenderCustomers: function() {
            var customers, $inner, that;

            // Extract customer data from existing HTML
            customers = this.extractCustomerData();
            that = this;

            // Store the customer data as JSON for future use
            $inner = jQuery('.inner', this.ctx);
            $inner.attr('data-customers', JSON.stringify(customers));

            // Clear existing customer HTML
            jQuery('.customerSelectorFieldInputSelectedCustomer', this.ctx).remove();

            // Render customers from the extracted data
            if (Array.isArray(customers) && customers.length > 0) {
                customers.forEach(function (customer) {
                    that.addCustomer(customer.value, customer.name, {
                        isSelected: customer.selected,
                        isDisabled: customer.disabled,
                        errors: customer.errors
                    });
                });
            }
        },

        /**
         * Extracts customer data from JSON
         *
         * @method extractCustomerData
         * @return {Array} Array of customer objects
         */
        extractCustomerData: function() {
            var customers, customerDataScript, cleanedJson, customerData, extractedCustomers, configGetKey;

            customers = [];

            // Get customer data from JSON
            try {
                customerDataScript = jQuery('.customerData', this.ctx).first().text();
                if (customerDataScript) {
                    // Clean up the JSON string before parsing
                    cleanedJson = customerDataScript
                        .replace(/,\s*]/g, ']') // Remove trailing commas before closing brackets
                        .replace(/,\s*\n\s*]/g, '\n]') // Remove trailing commas with newlines before closing brackets
                        .trim();

                    customerData = JSON.parse(cleanedJson);
                    if (Array.isArray(customerData) && customerData.length > 0) {
                        extractedCustomers = customerData.map(function (customer) {
                            var hasErrors = Boolean(customer.disabled);

                            return {
                            value: customer.customerKey,
                            name: customer.customerElement,
                            selected: customer.selected,
                            disabled: customer.disabled,
                            errors: hasErrors ? customer.errors : {}
                            };
                        });

                        return extractedCustomers;
                    }
                }
            } catch (e) {
                console.error('Error parsing customer data JSON:', e); // eslint-disable-line no-unused-vars
                // Try again with more aggressive cleaning if the first attempt failed
                try {
                    cleanedJson = customerDataScript
                        .replace(/,\s*]/g, ']') // Remove trailing commas before closing brackets
                        .replace(/,\s*\n\s*]/g, '\n]') // Remove trailing commas with newlines before closing brackets
                        .replace(/,\s*$/, '') // Remove trailing commas at the end of the string
                        .replace(/\n\s*\n/g, '\n') // Remove empty lines
                        .replace(/\s+/g, ' ') // Replace multiple whitespace with a single space
                        .trim();

                    customerData = JSON.parse(cleanedJson);
                    if (Array.isArray(customerData) && customerData.length > 0) {
                        extractedCustomers = customerData.map(function (customer) {
                            var hasErrors = Boolean(customer.disabled);

                            return {
                                value: customer.customerKey,
                                name: customer.customerElement,
                                selected: customer.selected,
                                disabled: customer.disabled,
                                errors: hasErrors ? customer.errors : {}
                            };
                        });

                        return extractedCustomers;
                    }
                } catch (innerError) {
                    console.error('Error parsing customer data JSON (second attempt):', innerError); // eslint-disable-line no-unused-vars
                }
            }

            // get data-recipient-field
            configGetKey = jQuery('.inner', this.ctx).attr('data-core-config-get-key');
            if (typeof configGetKey === 'string' && configGetKey.length) {
                customerData = Core.Config.Get(configGetKey);

                if (Array.isArray(customerData) && customerData.length > 0) {
                    extractedCustomers = customerData.map(function (customer) {
                        var hasErrors = Boolean(customer.disabled);

                        return {
                            value: customer.CustomerKey,
                            name: customer.CustomerTicketText,
                            selected: customer.selected || false,
                            disabled: customer.disabled || false,
                            errors: hasErrors ? customer.errors : {}
                        };
                    });

                    return extractedCustomers;
                }
            }

            return customers;
        },

        /**
         * Initialize module values from DOM attributes
         *
         * @method setValues
         *
         */
        setValues: function () {
            var $inner = jQuery('.inner', this.ctx);

            this.suggestUrl = $inner.attr('data-url');
            this.inputField = jQuery('.customerSelectorFieldInputElement', this.ctx);
            this.suggestElement = jQuery('.customerSelectorFieldSuggest', this.ctx);

            this.inputCounterNameAttribute = $inner.attr('data-input-counter-name');
            this.selectedCustomerAllow = $inner.attr('data-selected-customer-allow') === 'true';
            this.selectedCustomerFieldName = $inner.attr('data-selected-customer-field-name');
            this.removeIconPath = $inner.attr('data-remove-icon-path');
            this.inputNameAttribute = $inner.attr('data-input-name') || 'CustomerKey_';
            this.inputTextNameAttribute = $inner.attr('data-input-text-name') || 'CustomerTicketText_';
            this.inputType = $inner.attr('data-input-type') || 'customer';
            this.customerQueueAttribute = $inner.attr('data-input-customer-queue') || $inner.attr('data-customer-queue');
            this.customerCounter = 0;
        },

        /**
         * Bind main module events
         *
         * @method bindEvents
         *
         */
        bindEvents: function () {
            this.linkFormModule();
            this.bindInputEvents();
            this.bindAddressBookEvents();
        },

        /**
         * Bind events for the input field
         *
         * @method bindInputEvents
         *
         */
        bindInputEvents: function () {
            // Handle keyup events for search functionality
            this.inputField.keyup(this.debounce(function (event) {
                // On every key but not on ESC, Enter, Up, or Down arrow
                if (event.which !== 27 && event.which !== 13 && event.which !== 38 && event.which !== 40) {
                    this.search(event.target.value);
                } else if (event.which === 27) { // ESC key
                    this.hideSuggest();
                }
            }.bind(this), 200));

            // Add keyboard navigation for suggestion items
            this.inputField.keydown(function (event) {
                this.handleKeyboardNavigation(event);
            }.bind(this));

            // Handle change events (e.g., when triggered programmatically)
            this.inputField.on('change', function () {
                var inputValue = this.inputField.val().trim();

                // Only add customer if there's a value and suggestions are not visible
                // (to avoid conflicts with user interaction)
                if (inputValue !== '' && !this.suggestElement.hasClass(this.suggestElementActiveClass)) {
                    this.addCustomer(inputValue, inputValue, {});
                    this.hideSuggest();
                    this.clearInput();
                }
            }.bind(this));
        },

        /**
         * Bind events for the address book button
         *
         * @method bindAddressBookEvents
         *
         */
        bindAddressBookEvents: function () {
            var addressBookElement = jQuery('.customerSelectorFieldInputAddressBook', this.ctx);

            if (addressBookElement.length) {
                addressBookElement.on('click', function (event) {
                    var $element = jQuery(event.currentTarget);
                    this.openCustomerUserAddressBook(
                        $element.data('recipient-field'),
                        $element.data('recipient-field-label'),
                        $element.data('recipient-type')
                    );
                    return false;
                }.bind(this));
            }
        },

        /**
         * Create hidden input fields for customer data
         *
         * @method defineCustomerInputFields
         *
         */
        defineCustomerInputFields: function () {
            var counterInputHtml, selectedInputHtml;

            // Create a hidden input field for the CustomerTicketCounter
            counterInputHtml = '<input type="hidden" id="' + this.inputCounterNameAttribute + '" name="' + this.inputCounterNameAttribute + '" value="0">';
            jQuery(this.ctx).append(counterInputHtml);
            this.counterInput = jQuery('#' + this.inputCounterNameAttribute, this.ctx);

            // Only create fields if the input type is 'customer'
            if (this.inputType !== 'customer') {
                return;
            }

            // Create a hidden input field for the CustomerSelected parameter
            selectedInputHtml = '<input type="hidden" id="' + this.inputSelectedNameAttribute + '" name="' + this.inputSelectedNameAttribute + '" value="">';
            jQuery(this.ctx).append(selectedInputHtml);
            this.selectedInput = jQuery('#' + this.inputSelectedNameAttribute, this.ctx);
        },

        /**
         * Serialize data for URL parameters
         *
         * @method serializeData
         * @param {Object} data - Data to serialize
         * @return {String} Serialized data string
         */
        serializeData: function (data) {
            var queryString = '';
            jQuery.each(data, function (key, value) {
                queryString += ';' + encodeURIComponent(key) + '=' + encodeURIComponent(value);
            });
            return queryString;
        },

        /**
         * Open the customer user address book dialog
         *
         * @method openCustomerUserAddressBook
         * @param {String} recipientField - Field to receive the selected customer
         * @param {String} recipientFieldLabel - Label for the recipient field
         * @param {String} recipientType - Type of recipient
         *
         */
        openCustomerUserAddressBook: function (recipientField, recipientFieldLabel, recipientType) {
            var that, addressBookUrl, iframeHtml;

            // Unsubscribe from the event if already subscribed
            if (this.addressBookSubscriptionHandle) {
                Core.App.Unsubscribe(this.addressBookSubscriptionHandle);
                this.addressBookSubscriptionHandle = null;
            }

            // Subscribe to the event that will be triggered when customers are selected in the address book
            that = this;
            this.addressBookSubscriptionHandle = Core.App.Subscribe(
                'Event.CustomerUserAddressBook.AddTicketCustomer.Callback.' + recipientField,
                function (userLogin, customerTicketText) {
                    // Add the selected customer to the customer selector
                    that.addCustomer(userLogin, customerTicketText, {});
                }
            );

            // Build the URL for the address book iframe
            addressBookUrl = Core.Config.Get('CGIHandle') +
                '?Action=AgentCustomerUserAddressBook;RecipientField=' + recipientField +
                ';RecipientFieldLabel=' + recipientFieldLabel +
                ';RecipientType=' + recipientType;

            addressBookUrl += this.serializeData(Core.App.GetSessionInformation());

            // Create the iframe HTML and show the dialog
            iframeHtml = '<iframe class="TextOption CustomerUserAddressBook" src="' + addressBookUrl + '"></iframe>';

            Core.UI.Dialog.ShowContentDialog(iframeHtml, Core.Language.Translate('Customer user address book'), '10px', 'Center', true);
        },

        /**
         * Link to the parent form module
         *
         * @method linkFormModule
         *
         */
        linkFormModule: function () {
            var formElement = jQuery('.inner', this.ctx).closest('.modForm');
            this.formModule = this.sandbox.getModule(formElement.attr('data-moduleid'));
        },

        /**
         * Adds a new customer to the selection
         *
         * @method addCustomer
         * @param {String} value - The customer ID or value
         * @param {String} name - The customer name or display text
         * @param {Object} options - Additional options for the customer
         * @param {Boolean} options.isSelected - Whether the customer should be selected
         * @param {Boolean} options.isDisabled - Whether the customer should be disabled
         * @param {Boolean} options.skipDefaultCustomerActivation - Whether the customer default
         * value should be skipped during field activation
         * @param {Object} options.errors - Error information for the customer
         *
         */
        addCustomer: function (value, name, options) {
            var originalName, escapedName, hasErrors, isFirstCustomer, shouldBeActive, cssClasses, inputFields, customerHtml;

            options = options || {};

            // Store original name and create escaped version for display
            originalName = name;
            escapedName = this.escapeHtml(name);

            // Check if the customer has errors
            hasErrors = options.errors && Object.keys(options.errors).some(function (key) {
                return options.errors[key] !== false;
            });

            // Determine if this customer should be active
            isFirstCustomer = this.getCustomerCount() === 0;
            shouldBeActive = this.shouldCustomerBeActive(options.isSelected, isFirstCustomer, options.isDisabled, hasErrors, options.skipDefaultCustomerActivation);

            // Generate CSS classes based on customer state
            cssClasses = this.getCustomerCssClasses(shouldBeActive, options.isDisabled);

            // Check if the counter is correct by examining existing customers
            this.ensureCorrectCounter();

            // Increment counter and create input field names
            this.customerCounter++;
            inputFields = this.createInputFieldNames();

            // Generate HTML for the customer element
            customerHtml = this.generateCustomerHtml({
                value: value,
                escapedName: escapedName,
                originalName: originalName,
                cssClasses: cssClasses,
                inputFields: inputFields,
                options: options
            });

            // Add the customer element to the DOM
            this.addCustomerToDom(customerHtml);

            // Set the customer as active if needed
            if (shouldBeActive) {
                this.activateNewCustomer(value);
            }
        },

        /**
         * Replaces all customers with the provided list
         *
         * @method setCustomers
         * @param {Array} customers - Array of customer objects
         * @param {String} customers[].CustomerKey - The customer user login
         * @param {String} customers[].CustomerTicketText - The customer user full text, usually displayed with an email value
         * @param {Boolean} [customers[].CustomerIsSelected] - Whether the customer should be selected
         */
        setCustomers: function (customers) {
            var activeIndex, customer, i;

            customers = customers || [];

            // Determine which customer should be active
            activeIndex = -1;

            // Set active field only for input type "customer"
            if(this.inputType === 'customer'){
                for (i = customers.length - 1; i >= 0; i--) {
                    if (customers[i].CustomerIsSelected) {
                        activeIndex = i;
                        break;
                    }
                }
            }

            // Remove all customers
            this.removeAllCustomers();

            // Add customers making sure only one will be activated (for input type "customer")
            for (i = 0; i < customers.length; i++) {
                customer = customers[i];
                this.addCustomer(customer.CustomerKey, customer.CustomerTicketText, {
                    isSelected: i === activeIndex,
                    skipDefaultCustomerActivation: true
                });
            }
        },

        /**
        * Removes all customer elements and resets the counter
        *
        * @method removeAllCustomers
        */
        removeAllCustomers: function () {
            jQuery('.customerSelectorFieldInputSelectedCustomer', this.ctx).remove();
            this.customerCounter = 0;
            this.updateCustomerCounterInput();
        },

        /**
         * Gets all valid customer elements (without errors)
         *
         * @method getValidCustomers
         * @return {jQuery} jQuery object containing valid customer elements
         */
        getValidCustomers: function() {
            return jQuery('.customerSelectorFieldInputSelectedCustomer', this.ctx).filter(function() {
                return jQuery(this).find('.customerSelectorFieldInputSelectedCustomerErrors').length === 0;
            });
        },

        /**
         * Gets the current count of all customer elements
         *
         * @method getCustomerCount
         * @return {Number} The number of customer elements
         */
        getCustomerCount: function() {
            return jQuery('.customerSelectorFieldInputSelectedCustomer', this.ctx).length;
        },

        /**
         * Gets the current count of valid customer elements (without errors)
         *
         * @method getValidCustomerCount
         * @return {Number} The number of valid customer elements
         */
        getValidCustomerCount: function() {
            return this.getValidCustomers().length;
        },

        /**
         * Determines if a customer should be active based on selection state and position
         *
         * @method shouldCustomerBeActive
         * @param {Boolean} isSelected - Whether the customer is explicitly selected
         * @param {Boolean} isFirstCustomer - Whether this is the first customer in the list
         * @param {Boolean} isDisabled - Whether the customer is disabled
         * @param {Boolean} hasErrors - Whether the customer has validation errors
         * @param {Boolean} skipDefaultCustomerActivation - Whether the customer default
         * value should be skipped during field activation
         * @return {Boolean} Whether the customer should be active
         */
        shouldCustomerBeActive: function(isSelected, isFirstCustomer, isDisabled, hasErrors, skipDefaultCustomerActivation) {
            // A customer should not be active if it has errors or is disabled
            return (isSelected || (this.selectedCustomerAllow && isFirstCustomer && !skipDefaultCustomerActivation)) && !isDisabled && !hasErrors;
        },

        /**
         * Generates CSS classes for a customer element based on its state
         *
         * @method getCustomerCssClasses
         * @param {Boolean} isActive - Whether the customer is active
         * @param {Boolean} isDisabled - Whether the customer is disabled
         * @return {Object} Object containing CSS classes and ARIA attributes
         */
        getCustomerCssClasses: function(isActive, isDisabled) {
            return {
                activeClass: isActive ? 'customerSelectorFieldInputSelectedCustomerActive' : '',
                disabledClass: isDisabled ? 'customerSelectorFieldInputSelectedCustomerDisabled' : '',
                ariaSelected: isActive ? 'true' : 'false'
            };
        },

        /**
         * Creates input field names based on the current counter
         *
         * @method createInputFieldNames
         * @return {Object} Object containing input field names
         */
        createInputFieldNames: function() {
            return {
                inputName: this.inputNameAttribute + this.customerCounter,
                textInputName: this.inputTextNameAttribute + this.customerCounter
            };
        },

        /**
         * Escapes HTML in a string if it's not already escaped
         *
         * @method escapeHtml
         * @param {String} str - The string to escape
         * @return {String} The escaped string
         */
        escapeHtml: function(str) {
            // Check if the string already contains HTML entities
            if (str.indexOf('&lt;') !== -1 || str.indexOf('&gt;') !== -1 || str.indexOf('&quot;') !== -1) {
                // String is already escaped, return as is
                return str;
            }
            // String is not escaped, apply escaping
            return str.replace(/</g, "&lt;").replace(/>/g, "&gt;");
        },

        /**
         * Generates HTML for a customer element
         *
         * @method generateCustomerHtml
         * @param {Object} params - Parameters for HTML generation
         * @return {String} The generated HTML
         */
        generateCustomerHtml: function(params) {
            var selectHtml, errorsHtml, hasErrors, inputFieldsHtml, customerQueueHtml, queueInputName;

            selectHtml = this.generateSelectionButtonHtml();
            errorsHtml = this.generateErrorMessagesHtml(params.options.errors);

            // Check if the customer has errors
            hasErrors = params.options.errors && Object.keys(params.options.errors).some(function (key) {
                return params.options.errors[key] !== false;
            });

            // Generate input fields HTML only if the customer doesn't have errors
            inputFieldsHtml = '';
            customerQueueHtml = '';

            if (!hasErrors) {
                // Add input fields for customer data (escape value for HTML attributes to prevent broken markup with quotes/angle brackets in addresses)
                inputFieldsHtml = '<input type="hidden" name="' + params.inputFields.inputName + '" value="' + this.escapeHtmlAttr(params.value || '') + '">' + '<input type="hidden" name="' + params.inputFields.textInputName + '" value="' + this.escapeHtmlAttr(params.originalName || '') + '">';

                // Generate customer queue input HTML if the attribute is set
                if (this.customerQueueAttribute) {
                    queueInputName = this.customerQueueAttribute + this.customerCounter;
                    customerQueueHtml = '<input type="hidden" name="' + queueInputName + '" value="' + this.escapeHtmlAttr(params.originalName) + '">';
                }
            }

            return '<span class="customerSelectorFieldInputSelectedCustomer ' + params.cssClasses.activeClass + ' ' + params.cssClasses.disabledClass + '"' +
                ' data-value="' + this.escapeHtmlAttr(params.value || '') + '"' +
                ' role="option"' +
                ' aria-selected="' + params.cssClasses.ariaSelected + '">' + selectHtml +
                '<span class="customerName">' + params.escapedName + '</span>' +
                '<button type="button" class="customerSelectorFieldInputSelectedCustomerRemove" aria-label="Remove this customer">' +
                '<img src="' + this.removeIconPath + '" alt="Remove"/>' +
                '</button>' +
                inputFieldsHtml +
                customerQueueHtml +
                errorsHtml +
            '</span>';
        },

        /**
         * Generates HTML for the selection button if customer selection is allowed
         *
         * @method generateSelectionButtonHtml
         * @return {String} The generated HTML
         */
        generateSelectionButtonHtml: function() {
            return this.selectedCustomerAllow
                ? '<span class="customerSelectorFieldInputSelectedCustomerSelect" role="button" aria-label="Select this customer"></span>'
                : '';
        },

        /**
         * Generates HTML for error messages
         *
         * @method generateErrorMessagesHtml
         * @param {Object} errors - Error information
         * @return {String} The generated HTML
         */
        generateErrorMessagesHtml: function(errors) {
            var hasErrors, errorsHtml;

            if (!errors) {
                return '';
            }

            // Check if any error is not false
            hasErrors = Object.keys(errors).some(function (key) {
                return errors[key] !== false;
            });
            if (!hasErrors) {
                return '';
            }

            errorsHtml = '<div class="customerSelectorFieldInputSelectedCustomerErrors" role="alert">';

            // Loop through all error keys and add messages for active errors
            Object.keys(errors).forEach(function (key) {
                // If the error is active (not false) and it's a string (pre-translated message)
                if (errors[key] !== false && typeof errors[key] === 'string') {
                    errorsHtml += '<p>' + this.escapeHtmlAttr(errors[key]) + '</p>';
                }
            });

            errorsHtml += '</div>';
            return errorsHtml;
        },

        /**
         * Updates the customer counter input with the current count of valid customers
         *
         * @method updateCustomerCounterInput
         *
         */
        updateCustomerCounterInput: function() {
            var customerCount;

            if (this.counterInput) {
                // Only count valid customers (without errors)
                customerCount = this.getValidCustomerCount();
                this.counterInput.val(customerCount);
            }
        },

        /**
         * Adds a customer element to the DOM and updates related state
         *
         * @method addCustomerToDom
         * @param {String} html - The HTML to add
         *
         */
        addCustomerToDom: function(html) {
            // Add the customer element to the DOM
            this.inputField.before(html);

            // Rebind events for the new elements
            this.bindSelectedCustomerEvents();

            // Update the customer counter input
            this.updateCustomerCounterInput();
        },

        /**
         * Selects the first valid customer (without errors)
         *
         * @method selectFirstValidCustomer
         *
         */
        selectFirstValidCustomer: function() {
            // Get all valid customers (without errors)
            var validCustomers = this.getValidCustomers();
            var firstValidCustomer = validCustomers.first();

            // If there's at least one valid customer
            if (firstValidCustomer.length > 0) {
                this.setCustomerActive(firstValidCustomer);
            } else {
                // If no valid customers, clear the form value
                this.formModule.setValue(this.selectedCustomerFieldName, '');
                this.reloadCustomerInfo('');
            }
        },

        /**
         * Activates a newly added customer
         *
         * @method activateNewCustomer
         * @param {String} value - The customer ID or value
         *
         */
        activateNewCustomer: function(value) {
            var newCustomer = jQuery('.customerSelectorFieldInputSelectedCustomer[data-value="' + value + '"]', this.ctx).first();

            // Check if the customer has errors before activating
            var hasErrors = newCustomer.find('.customerSelectorFieldInputSelectedCustomerErrors').length > 0;

            // Only activate if the customer doesn't have errors
            if (!hasErrors) {
                this.setCustomerActive(newCustomer);
            }
        },

        /**
         * Escapes HTML attribute special characters if not already escaped
         *
         * @method escapeHtmlAttr
         * @param {String} str - The string to escape
         * @return {String} The escaped string
         */
        escapeHtmlAttr: function (str) {
            // Check if the string already contains HTML entities
            if (str.indexOf('&amp;') !== -1 || str.indexOf('&quot;') !== -1 ||
                str.indexOf('&lt;') !== -1 || str.indexOf('&gt;') !== -1) {
                // String is already escaped, return as is
                return str;
            }
            // String is not escaped, apply escaping
            return str
                .replace(/&/g, '&amp;')
                .replace(/"/g, '&quot;')
                .replace(/</g, '&lt;')
                .replace(/>/g, '&gt;');
        },

        /**
         * Clears the input field value
         *
         * @method clearInput
         *
         */
        clearInput: function () {
            this.inputField.val('');
        },

        /**
         * Hides the suggestion dropdown
         *
         * @method hideSuggest
         *
         */
        hideSuggest: function () {
            this.suggestElement.removeClass(this.suggestElementActiveClass);
        },

        /**
         * Binds event handlers to suggestion items
         *
         * @method bindSuggestEvents
         *
         */
        bindSuggestEvents: function () {
            var $suggestItems = jQuery('.customerSelectorFieldSuggestItem', this.ctx);

            // Add click event to select a customer
            $suggestItems.click(function (event) {
                var $item = jQuery(event.currentTarget);
                var value = $item.data('value');
                var name = $item.text();

                this.addCustomer(value, name, {});
                this.hideSuggest();
                this.clearInput();
            }.bind(this));

            // Add hover events to highlight items
            $suggestItems.hover(
                // Mouse enter
                function() {
                    // Remove highlight from all items
                    $suggestItems.removeClass(this.suggestItemHighlightedClass);
                    // Add highlight to this item
                    jQuery(this).addClass(this.suggestItemHighlightedClass);
                }.bind(this),

                // Mouse leave
                function() {
                    // Remove highlight from this item
                    jQuery(this).removeClass(this.suggestItemHighlightedClass);
                }.bind(this)
            );
        },

        /**
         * Sets a customer as active.
         *
         * @method setCustomerActive
         * @param {jQuery} customerElement - The customer element to set as active
         *
         */
        setCustomerActive: function (customerElement) {
            var hasErrors, value, index;

            // Check if the customer has errors
            hasErrors = customerElement.find('.customerSelectorFieldInputSelectedCustomerErrors').length > 0;

            // Only proceed if the customer doesn't have errors
            if (!hasErrors) {
                // Remove active class from all customers
                jQuery('.customerSelectorFieldInputSelectedCustomer', this.ctx)
                    .removeClass('customerSelectorFieldInputSelectedCustomerActive');

                // Add active class to the specified customer
                customerElement.addClass('customerSelectorFieldInputSelectedCustomerActive');

                // Get the value of the specified customer
                value = customerElement.attr('data-value');

                // Update the form value
                this.formModule.setValue(this.selectedCustomerFieldName, value);

                // Update the CustomerSelected parameter with the customer index
                if (this.selectedInput) {
                    // Find the index of the customer in the list
                    index = 0;
                    jQuery('.customerSelectorFieldInputSelectedCustomer', this.ctx).each(function(i, element) {
                        if (jQuery(element).is(customerElement)) {
                            index = i + 1; // 1-based index
                            return false; // break the loop
                        }
                    });
                    this.selectedInput.val(index);
                }

                // Activate selection customer ID
                this.activateSelectionCustomerID(value);

                // Reload customer info
                this.reloadCustomerInfo(value);
            }
        },

        /**
         * Activates the selection customer ID
         *
         * @method activateSelectionCustomerID
         *
         */
        activateSelectionCustomerID: function() {
            if ($('#TemplateSelectionCustomerID').length && $('#SelectionCustomerID').hasClass('Disabled')) {
                $('#SelectionCustomerID').prop('disabled', false)
                $('#SelectionCustomerID').prop('title', Core.Language.Translate('Select a customer ID to assign to this ticket.'));
                $('#SelectionCustomerID').removeClass('Disabled');
            }
        },

        /**
         * Deactivates the selection customer ID
         *
         * @method deactivateSelectionCustomerID
         *
         */
        deactivateSelectionCustomerID: function() {
            if($('#TemplateSelectionCustomerID').length) {
                $('#SelectionCustomerID').prop('disabled', true)
                $('#SelectionCustomerID').prop('title', Core.Language.Translate('First select a customer user, then select a customer ID to assign to this ticket.'));
                $('#SelectionCustomerID').addClass('Disabled');
            }
        },

        /**
         * Safely reloads customer info if the function exists
         *
         * @method reloadCustomerInfo
         * @param {String} value - Customer ID
         *
         */
        reloadCustomerInfo: function(value) {
            try {
                if (Core &&
                    Core.Agent &&
                    Core.Agent.CustomerSearch &&
                    typeof Core.Agent.CustomerSearch.ReloadCustomerInfo === 'function') {
                    Core.Agent.CustomerSearch.ReloadCustomerInfo(value);
                }
            } catch (e) {
                // Silently handle errors
                console.error('Error reloading customer info:', e); // eslint-disable-line no-unused-vars
            }
        },

        /**
         * Bind events for selected customer elements
         *
         * @method bindSelectedCustomerEvents
         *
         */
        bindSelectedCustomerEvents: function () {
            // Handle remove button clicks
            jQuery('.customerSelectorFieldInputSelectedCustomerRemove', this.ctx).click(function (event) {
                // Get the parent customer element
                var customerElement = jQuery(event.currentTarget).closest('.customerSelectorFieldInputSelectedCustomer');

                // Remove the customer element
                customerElement.remove();

                // Deactivate selection customer ID
                this.deactivateSelectionCustomerID();

                // Update the counter values of remaining customers
                this.updateCustomerCounters();

                // Update the customer counter input
                this.updateCustomerCounterInput();

                // If selecting a customer is allowed, select the first valid customer
                if (this.selectedCustomerAllow) {
                    this.selectFirstValidCustomer();
                }
            }.bind(this));

            // Handle selection button clicks
            jQuery('.customerSelectorFieldInputSelectedCustomerSelect', this.ctx).click(function (event) {
                var customerElement, hasErrors;

                // Only proceed if selecting a customer is allowed
                if (this.selectedCustomerAllow) {
                    // Get the parent customer element
                    customerElement = jQuery(event.currentTarget).closest('.customerSelectorFieldInputSelectedCustomer');

                    // Check if the customer has errors
                    hasErrors = customerElement.find('.customerSelectorFieldInputSelectedCustomerErrors').length > 0;

                    // Only set the customer as active if it doesn't have errors
                    if (!hasErrors) {
                        // Set the customer as active
                        this.setCustomerActive(customerElement);
                    }
                }
            }.bind(this));
        },

        /**
         * Search for customers and display results
         *
         * @method search
         * @param {String} value - The search term
         *
         */
        search: function (value) {
            var url;

            // Don't search for terms shorter than 3 characters
            if (value.length < 3) {
                this.hideSuggest();
                return;
            }

            this.lastSearch = value;
            url = this.suggestUrl + ';Term=' + value;

            // Cancel previous AJAX request if it exists
            if (this.lastAjaxSearch && this.lastAjaxSearch.abort) {
                this.lastAjaxSearch.abort();
            }

            // Make AJAX request for search results
            this.lastAjaxSearch = jQuery.ajax({
                url: url,
                type: 'GET',
                cache: false,
                processData: false,
                contentType: false,
                success: function (data) {
                    var filteredData, size, html;

                    // Filter out customers that are already selected
                    filteredData = this.filterCustomers(data);
                    size = Object.keys(filteredData).length;

                    // If no results, hide the suggestion dropdown
                    if (size < 1) {
                        this.suggestElement.removeClass(this.suggestElementActiveClass);
                        this.suggestElement.html('');
                        return;
                    }

                    // Build HTML for suggestion items
                    html = '<ul>';
                    jQuery.each(filteredData, function (i, item) {
                        var itemLabel = item.Label.replace(/</g, "&lt;").replace(/>/g, "&gt;");
                        html += '<li class="ui-menu-item customerSelectorFieldSuggestItem" data-value="' + item.Value + '">' + itemLabel + '</li>';
                    });
                    html += '</ul>';

                    // Update the suggestion dropdown and show it
                    this.suggestElement.html(html);
                    this.bindSuggestEvents();
                    this.suggestElement.addClass(this.suggestElementActiveClass);
                }.bind(this),
                error: function (xhr, status, error) {
                    // Only log errors if not aborted
                    if (status !== 'abort') {
                        console.error('Error searching for customers:', error); // eslint-disable-line no-unused-vars
                    }
                }.bind(this)
            });
        },

        /**
         * Filters out customers that are already selected
         *
         * @method filterCustomers
         * @param {Array} data - Array of customer objects
         * @return {Array} Filtered array of customer objects
         */
        filterCustomers: function (data) {
            var activeCustomers = [];

            // Get all currently selected customers
            jQuery('.customerSelectorFieldInputSelectedCustomer', this.ctx).each(function () {
                var value = jQuery(this).attr('data-value');
                if (value) {
                    activeCustomers.push(value);
                }
            });

            // If no active customers, return the original data
            if (activeCustomers.length === 0) {
                return data;
            }

            // Filter out customers that are already selected
            return data.filter(function (customer) {
                return !activeCustomers.includes(customer.Value);
            });
        },

        /**
         * Debounce function to limit the rate at which a function can fire
         *
         * @method debounce
         * @param {Function} func - Function to debounce
         * @param {Number} delay - Delay in milliseconds
         * @return {Function} Debounced function
         */
        debounce: function (func, delay) {
            var timeout;
            return function () {
                var context = this;
                var args = arguments;
                clearTimeout(timeout);
                timeout = setTimeout(function () {
                    func.apply(context, args);
                }, delay);
            };
        },

        /**
         * Handle keyboard navigation for suggestion items
         *
         * @method handleKeyboardNavigation
         * @param {Event} event - The keyboard event
         *
         */
        handleKeyboardNavigation: function (event) {
            var keyCode = event.which;

            // Handle different key presses
            switch (keyCode) {
                case 13: // Enter key
                    this.handleEnterKey(event);
                    break;
                case 27: // ESC key
                    this.handleEscKey(event);
                    break;
                case 38: // Up arrow
                case 40: // Down arrow
                    this.handleArrowKeys(event, keyCode);
                    break;
            }
        },

        /**
         * Handle Enter key press
         *
         * @method handleEnterKey
         * @param {Event} event - The keyboard event
         *
         */
        handleEnterKey: function (event) {
            var currentItem, inputValue;

            event.preventDefault();

            // Check if the suggestion dropdown is visible
            if (this.suggestElement.hasClass(this.suggestElementActiveClass)) {
                currentItem = jQuery('.customerSelectorFieldSuggestItem.' + this.suggestItemHighlightedClass, this.ctx);

                // If an item is highlighted, select it
                if (currentItem.length) {
                    this.selectSuggestionItem(currentItem);
                    return;
                }
            }

            // If no item is highlighted or suggestion dropdown is not visible,
            // but there's text in the input field, add it as a new contact
            inputValue = this.inputField.val().trim();
            if (inputValue !== '') {
                this.addCustomer(inputValue, inputValue, {});
                this.hideSuggest();
                this.clearInput();
            }
        },

        /**
         * Handle ESC key press
         *
         * @method handleEscKey
         * @param {Event} event - The keyboard event
         *
         */
        handleEscKey: function (event) {
            event.preventDefault();
            this.hideSuggest();
        },

        /**
         * Handle arrow key navigation
         *
         * @method handleArrowKeys
         * @param {Event} event - The keyboard event
         * @param {Number} keyCode - The key code (38 for up, 40 for down)
         *
         */
        handleArrowKeys: function (event, keyCode) {
            var items, currentItem, index, newIndex;

            // Only handle navigation if the suggestion dropdown is visible
            if (!this.suggestElement.hasClass(this.suggestElementActiveClass)) {
                return;
            }

            event.preventDefault();

            items = jQuery('.customerSelectorFieldSuggestItem', this.ctx);
            if (items.length === 0) {
                return;
            }

            currentItem = jQuery('.customerSelectorFieldSuggestItem.' + this.suggestItemHighlightedClass, this.ctx);
            index = currentItem.length ? items.index(currentItem) : -1;

            // Calculate the new index based on the key pressed
            if (keyCode === 40) { // Down arrow
                newIndex = (index === -1 || index === items.length - 1) ? 0 : index + 1;
            } else { // Up arrow
                newIndex = (index === -1 || index === 0) ? items.length - 1 : index - 1;
            }

            // Update the highlighted item
            items.removeClass(this.suggestItemHighlightedClass);
            jQuery(items[newIndex]).addClass(this.suggestItemHighlightedClass);
            this.scrollItemIntoView(items[newIndex]);
        },

        /**
         * Select a suggestion item
         *
         * @method selectSuggestionItem
         * @param {jQuery} item - The suggestion item to select
         *
         */
        selectSuggestionItem: function (item) {
            var value = item.data('value');
            var name = item.text();

            this.addCustomer(value, name, {});
            this.hideSuggest();
            this.clearInput();
        },

        /**
         * Scrolls an item into view within the suggest element
         *
         * @method scrollItemIntoView
         * @param {HTMLElement} item - The item to scroll into view
         *
         */
        scrollItemIntoView: function (item) {
            var $item = jQuery(item);
            var $container = this.suggestElement;

            // Get item position relative to container
            var itemTop = $item.position().top;
            var itemHeight = $item.outerHeight();
            var containerHeight = $container.height();
            var scrollTop = $container.scrollTop();

            // If item is above the visible area, scroll up to it
            if (itemTop < 0) {
                $container.scrollTop(scrollTop + itemTop);
            }
            // If item is below the visible area, scroll down to it
            else if (itemTop + itemHeight > containerHeight) {
                $container.scrollTop(scrollTop + itemTop - containerHeight + itemHeight);
            }
        },

        /**
         * Ensures the customer counter is correct by examining existing customers
         *
         * @method ensureCorrectCounter
         *
         */
        ensureCorrectCounter: function() {
            var validCustomers, highestCounter, that;

            // Get all valid customer elements (without errors)
            validCustomers = this.getValidCustomers();
            that = this;

            // If no valid customers, reset counter to 0
            if (validCustomers.length === 0) {
                this.customerCounter = 0;
                return;
            }

            // Find the highest counter value used in the input field names
            highestCounter = 0;

            validCustomers.each(function (index, element) {
                var $element, inputNameElement, inputName, counterMatch, counterValue;

                $element = jQuery(element);
                inputNameElement = $element.find('input[name^="' + that.inputNameAttribute + '"]');

                if (inputNameElement.length) {
                    inputName = inputNameElement.attr('name');
                    // Extract the counter value from the input name (e.g., "CustomerKey_3" -> 3)
                    counterMatch = inputName.match(new RegExp('^' + that.inputNameAttribute + '(\\d+)$'));

                    if (counterMatch && counterMatch[1]) {
                        counterValue = parseInt(counterMatch[1], 10);
                        if (!isNaN(counterValue) && counterValue > highestCounter) {
                            highestCounter = counterValue;
                        }
                    }
                }
            });

            // Update the customerCounter to match the highest counter value
            this.customerCounter = highestCounter;
        },

        /**
         * Updates the counter values of all customer elements
         *
         * @method updateCustomerCounters
         *
         */
        updateCustomerCounters: function() {
            var validCustomers, counter, that;

            // Get all valid customer elements (without errors)
            validCustomers = this.getValidCustomers();
            that = this;

            // Reset the counter
            counter = 1;

            // Update each customer's input field names
            validCustomers.each(function (index, element) {
                var $element, oldInputName, oldTextInputName, oldQueueInputName, value, textValue, newInputName, newTextInputName, queueValue, newQueueInputName;

                $element = jQuery(element);

                // Update input field names
                oldInputName = $element.find('input[name^="' + that.inputNameAttribute + '"]');
                oldTextInputName = $element.find('input[name^="' + that.inputTextNameAttribute + '"]');
                oldQueueInputName = that.customerQueueAttribute ?
                    $element.find('input[name^="' + that.customerQueueAttribute + '"]') : null;

                if (oldInputName.length) {
                    // Get the current values
                    value = oldInputName.val();
                    textValue = oldTextInputName.val();

                    // Create new input field names
                    newInputName = that.inputNameAttribute + counter;
                    newTextInputName = that.inputTextNameAttribute + counter;

                    // Update the input field names and values
                    oldInputName.attr('name', newInputName).val(value);
                    oldTextInputName.attr('name', newTextInputName).val(textValue);

                    // Update queue input if it exists
                    if (oldQueueInputName && oldQueueInputName.length) {
                        queueValue = oldQueueInputName.val();
                        newQueueInputName = that.customerQueueAttribute + counter;
                        oldQueueInputName.attr('name', newQueueInputName).val(queueValue);
                    }

                    // Increment counter for the next customer
                    counter++;
                }
            });
        }
    });
})(jQuery);