// --
// Copyright (C) 2021-2022 Znuny GmbH, https://znuny.org/
// --
// This software comes with ABSOLUTELY NO WARRANTY. For details, see
// the enclosed file COPYING for license information (AGPL). If you
// did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
// --

"use strict";

var Znuny = Znuny || {};
Znuny.DynamicField = Znuny.DynamicField || {};

/**
 * @namespace
 * @exports TargetNS as Znuny.DynamicField.Webservice
 * @description
 *      This namespace contains the special functions for dynamic field types WebserviceText and WebserviceMultiselect.
 */
Znuny.DynamicField.Webservice = (function (TargetNS) {

    TargetNS.Init = function() {

        // Subscribe to event which triggers when dynamic fields will be dynamically
        // added to the DOM. This way, the InitAutoComplete() can be executed for these fields.
        // This is being done e. g. in AdminGenericAgent when configuring the dynamic fields.
        Core.App.Subscribe('Event.DynamicField.Init', InitDynamicField);
    }

    function InitDynamicField(DynamicFieldElementID) {

        // If the dynamic field is present in the HTML retrieved from the web server,
        // InitAutocomplete() below will be automatically called.
        // However, if the dynamic field will be added dynamically, this function
        // will execute InitAutocomplete() for the field.
        var $DynamicFieldElement = $('#' + DynamicFieldElementID),
            DynamicFieldName,
            DynamicFieldType,
            SelectedValueFieldName,
            AutocompleteFieldName,
            AutocompleteMinLength,
            TicketID,
            QueryDelay,
            DefaultSearchTerm,
            IsMultiSelect = $DynamicFieldElement.attr('multiple') ? true : false;

        if (!$DynamicFieldElement.length) {
            return;
        }

        DynamicFieldName       = $DynamicFieldElement.attr('data-dynamic-field-name');
        DynamicFieldType       = $DynamicFieldElement.attr('data-dynamic-field-type');
        SelectedValueFieldName = $DynamicFieldElement.attr('data-selected-value-field-name');
        AutocompleteFieldName  = $DynamicFieldElement.attr('data-autocomplete-field-name');
        AutocompleteMinLength  = $DynamicFieldElement.attr('data-autocomplete-min-length');
        TicketID               = $DynamicFieldElement.attr('data-ticket-id');
        QueryDelay             = $DynamicFieldElement.attr('data-query-delay');
        DefaultSearchTerm      = $DynamicFieldElement.attr('data-default-search-term');

        if (
            !DynamicFieldName
            || !DynamicFieldType
            || !SelectedValueFieldName
            || !AutocompleteFieldName
            || !AutocompleteMinLength
        ) {
            return;
        }

        if (
            DynamicFieldType != 'WebserviceText'
            && DynamicFieldType != 'WebserviceMultiselect'
        ) {
            return;
        }

        if (IsMultiSelect && QueryDelay == null) {
            return;
        }

        if (IsMultiSelect) {
            TargetNS.InitMultiselect(
                DynamicFieldName, SelectedValueFieldName, AutocompleteFieldName, AutocompleteMinLength, QueryDelay, DefaultSearchTerm, TicketID
            );
            return;
        }

        TargetNS.InitAutocomplete(DynamicFieldName, SelectedValueFieldName, AutocompleteFieldName, AutocompleteMinLength, TicketID);
    }

    TargetNS.InitAdmin = function() {
        TargetNS.InitTest();

        $('#Webservice').on('change', function(){
            var $Form = $(this).closest('form');
            Core.AJAX.FormUpdate($Form, 'AJAXUpdate', 'Webservice', ['InvokerSearch', 'InvokerGet']);
        });

        $('#Backend').on('change', function(){
            var $Form = $(this).closest('form');
            Core.AJAX.FormUpdate($Form, 'AJAXUpdate', 'Backend', ['BackendDocumentation']);
        });
    };

    TargetNS.InitMultiselect = function (DynamicFieldName, SelectedValueFieldName, AutocompleteFieldName, AutocompleteMinLength, QueryDelay, DefaultSearchTerm, TicketID, AdditionalDFs) {
        var ActiveAJAXCall = false;

        // Use "live" update for the following events because the autocomplete field might not
        // be present in the DOM yet (e.g. in AdminGenericAgent).
        $('#LabelDynamicField_' + DynamicFieldName+ ' + div, #LabelSearch_DynamicField_' + DynamicFieldName+ ' + div')
            .off('click.AutocompleteMultiselect', '#' + AutocompleteFieldName)
            .on('click.AutocompleteMultiselect', '#' + AutocompleteFieldName, function() {
                if (DefaultSearchTerm){
                    AutocompleteMultiselect($(this), DefaultSearchTerm);
                }
            });

        $('#LabelDynamicField_' + DynamicFieldName+ ' + div, #LabelSearch_DynamicField_' + DynamicFieldName+ ' + div')
            .off('keyup.AutocompleteMultiselect', '#' + AutocompleteFieldName)
            .on('keyup.AutocompleteMultiselect', '#' + AutocompleteFieldName, function() {
                var $ThisAutocompleteElement = $(this);
                window.setTimeout(
                    function () {
                        if (ActiveAJAXCall){
                            return;
                        }
                        AutocompleteMultiselect($ThisAutocompleteElement);
                    },
                    QueryDelay
                );
            });

        function AutocompleteMultiselect($AutocompleteElement, SearchTerm) {
            var URL   = Core.Config.Get('Baselink'),
                Value = SearchTerm || $AutocompleteElement.val() || '',
                Data  = {
                    Action:           'AJAXDynamicFieldWebservice',
                    Subaction:        'Autocomplete',
                    DynamicFieldName: DynamicFieldName,
                    SearchTerms:      Value,
                    TicketID:         TicketID
                };

            if (Value.length < AutocompleteMinLength){
                return;
            }

            ActiveAJAXCall = true;
            Core.AJAX.ToggleAJAXLoader(SelectedValueFieldName, true);
            Core.AJAX.FunctionCall(
                URL,
                Data,
                function (Response) {
                    var CurrentValue,
                        Options  = {},
                        Selected = [],
                        SelectedIDs;

                    Core.AJAX.ToggleAJAXLoader(SelectedValueFieldName, false);
                    if (!Response) {
                        return;
                    }

                    // additional check if current search term is equal to sent search term
                    CurrentValue = SearchTerm || $AutocompleteElement.val() || '';
                    if (CurrentValue != Value){
                        ActiveAJAXCall = false;
                        AutocompleteMultiselect($AutocompleteElement);
                        return;
                    }

                    $.each(Response,function () {
                        if (this.StoredValue && this.DisplayValue){
                            Options[this.StoredValue] = this.DisplayValue;
                        }
                    });

                    SelectedIDs = Znuny.Form.Input.Get(SelectedValueFieldName);
                    if (SelectedIDs){
                        $('#' + SelectedValueFieldName + ' option').each(function(Index, Element) {
                            var Key        = $(Element).val(),
                                Value      = $(Element).text(),
                                IsSelected = SelectedIDs.includes(Key);

                            if (IsSelected){
                                Selected[Key] = Value;
                                Options[Key]  = Value;
                            }
                        });
                    }

                    // add empty option to prevent disabled field
                    if (jQuery.isEmptyObject(Options)){
                        Options  = {' ': ' '};
                    }

                    Znuny.Form.Input.Set(SelectedValueFieldName, Options, {SelectOption: true, Modernize: false, TriggerChange: true});

                    if (!jQuery.isEmptyObject(SelectedIDs)){
                        Znuny.Form.Input.Set(SelectedValueFieldName, SelectedIDs);
                    }

                    ActiveAJAXCall = false;
                },
                'json'
            );
        }

        // prepare AutoFill
        $('#' + SelectedValueFieldName).off('change.Multiselect').on('change.Multiselect', function () {
            var SelectedIDs = Znuny.Form.Input.Get(SelectedValueFieldName),
                InitAutoFill;

            if (SelectedIDs && AdditionalDFs && AdditionalDFs.length){
                $.each(AdditionalDFs, function(Index, DynamicField) {
                    var Exists = Znuny.Form.Input.Exists('DynamicField_' + DynamicField);

                    if (Exists){
                        InitAutoFill = 1;
                        return false;
                    }
                });

                if (InitAutoFill){
                    TargetNS.InitAutoFill(DynamicFieldName,SelectedIDs);
                }
            }
        });
    }

    TargetNS.InitAutocomplete = function (DynamicFieldName, SelectedValueFieldName, AutocompleteFieldName, AutocompleteMinLength, QueryDelay, MaxResultsDisplayed, DefaultSearchTerm, TicketID, AdditionalDFs) {
        var $Element             = $('#' + SelectedValueFieldName),
            $AutocompleteElement = $('#' + AutocompleteFieldName);

        // If the entered autocomplete display value differs from the one that was inserted by selecting an autocomplete
        // from the search results, empty the autocomplete field after leaving the input field so that it will become
        // clear to the user that an invalid value has been entered.
        $AutocompleteElement.on('blur', function() {
            if ($AutocompleteElement.val() !== $AutocompleteElement.attr('data-selected-autocomplete-display-value')) {
                $Element.val('');
                $AutocompleteElement.val('');
            }
        })

        // start initial search on click event
        $AutocompleteElement.off('click.autocomplete').on('click.autocomplete', function() {
            var SearchTerm = DefaultSearchTerm || $AutocompleteElement.val();
            $AutocompleteElement.autocomplete('search', SearchTerm);
        })

        Core.UI.Autocomplete.Init(
            $AutocompleteElement,
            function (Request, Response) {
                var URL  = Core.Config.Get('Baselink'),
                    Data = {
                        Action:           'AJAXDynamicFieldWebservice',
                        Subaction:        'Autocomplete',
                        DynamicFieldName: DynamicFieldName,
                        SearchTerms:      Request.term,
                        TicketID:         TicketID
                    },
                    SerializedFormData = TargetNS.SerializeForm($('#DynamicField_' + DynamicFieldName));

                Data = $.extend(Data, SerializedFormData);

                $('#AJAXLoader' + $AutocompleteElement.attr('id')).show();

                $Element.data(
                    'AutoCompleteXHR',
                    Core.AJAX.FunctionCall(
                        URL,
                        Data,
                        function (Result) {
                            var Data = [];
                            $Element.removeData('AutoCompleteXHR');

                            $.each(
                                Result,
                                function () {
                                    Data.push({
                                        label: this.DisplayValue,
                                        value: this.StoredValue
                                    });
                                }
                            );
                            Response(Data);
                        }
                    )
                );
            },
            function (Event, UI) {
                var Label = UI.item.label,
                    Value = UI.item.value,
                    InitAutoFill;

                if (typeof Label == "string") {
                    Label.trim();
                }
                if (typeof Value == "string") {
                    Value.trim();
                }

                Event.preventDefault();
                Event.stopPropagation();

                // Fixed bug where ajax loading icon does not get removed
                // after loading of the elements
                $AutocompleteElement.data('request-counter', 0);
                $('#AJAXLoader' + $AutocompleteElement.attr('id')).hide();

                $AutocompleteElement.val(Label);
                $AutocompleteElement.attr('data-selected-autocomplete-display-value', Label);
                $Element.val(Value);

                // prepare AutoFill
                if (AdditionalDFs && AdditionalDFs.length){
                    $.each(AdditionalDFs, function(Index, DynamicField) {
                        var Exists = Znuny.Form.Input.Exists('DynamicField_' + DynamicField);

                        if (Exists){
                            InitAutoFill = 1;
                            return false;
                        }
                    });
                    if (InitAutoFill){
                        TargetNS.InitAutoFill(DynamicFieldName,Value);
                    }
                }

                Core.App.Publish('Event.Agent.DynamicField.Webservice.Callback',
                    [
                        {
                            Label: Label,
                            Value: Value,
                            Field: DynamicFieldName
                        }
                    ]
                );
            },
            'DynamicFieldWebservice',
            {
                QueryDelay:          QueryDelay,
                MinQueryLength:      AutocompleteMinLength,
                MaxResultsDisplayed: MaxResultsDisplayed
            }
        );

        return true;
    };

    TargetNS.InitAutoFill = function(DynamicFieldName,Value) {
        var URL  = Core.Config.Get('Baselink'),
            Data = {
                Action:           'AJAXDynamicFieldWebservice',
                Subaction:        'AutoFill',
                DynamicFieldName: DynamicFieldName,
                SearchTerms:      Value,
            };

        Core.AJAX.FunctionCall(
            URL,
            Data,
            function (Response) {
                if (!Response) {
                    return;
                }

                $.each(Response, function(DynamicFieldName, Value) {
                    var DynamicField = 'DynamicField_' + DynamicFieldName,
                        Exists = Znuny.Form.Input.Exists(DynamicField);

                    if (Exists){
                        Znuny.Form.Input.Set(DynamicField, Value);
                    }
                });
            },
            'json'
        );

        return true;
    }

    TargetNS.InitTest = function() {
        $('button[data-action="Test"]')
            .off('click.dynamicfieldwebservice')
            .on('click.dynamicfieldwebservice', function () {
                var AutocompleteMinLength    = $('#AutocompleteMinLength').val(),
                    QueryDelay          = $('#QueryDelay').val() || 100,
                    MaxResultsDisplayed = $('#Limit').val(),
                    DefaultSearchTerm   = $('#DefaultSearchTerm').val(),
                    FieldType           = $('[name="FieldType"]').val(),
                    DynamicFieldName    = $('#Name').val(),
                    FieldName           = 'DynamicField_' + DynamicFieldName,
                    AutocompleteFieldName,
                    DynamicFieldAutocomplete,
                    URL                      = Core.Config.Get('Baselink'),
                    Config                   = [
                        'Webservice', 'InvokerSearch', 'InvokerGet', 'Backend', 'StoredValue', 'SearchKeys', 'DisplayedValues', 'DisplayedValuesSeparator', 'Limit', 'AutocompleteMinLength', 'QueryDelay', 'AdditionalDFStorage', 'InputFieldWidth', 'DefaultValue', 'Link', 'SearchTerms',                     ],
                    Data = {
                        Action:           'AJAXDynamicFieldWebservice',
                        Subaction:        'Test',
                        DynamicFieldName: DynamicFieldName,
                        FieldType:        FieldType,
                        Config:   {}
                    },
                    $Button = $(this);

                if ($Button.prop('disabled')) {
                    return;
                }

                $.each(Config, function(Index, Value) {
                    Data['Config'][Value] = $('#' + Value).val();
                });

                $Button.prop('disabled', true);

                // Hide test results
                $('#TestError, #TestSuccess, .Test')
                    .addClass('Hidden');

                Core.AJAX.FunctionCall(
                    URL,
                    Data,
                    function (Result) {
                        $Button.prop('disabled', false);

                        if (Result['Success'] != 1) {
                            $('#TestError').removeClass('Hidden');
                            return;
                        }

                        $('#TestSuccess, .Test').removeClass('Hidden');
                        $('#TestData').html(Result['TestDataHTML']);

                        Core.UI.InputFields.Activate();

                        if (FieldType == 'WebserviceText'){
                            AutocompleteFieldName    = FieldName + 'Autocomplete';
                            DynamicFieldAutocomplete = $('#' + FieldName + '[type="text"]');

                            TargetNS.InitAutocomplete(DynamicFieldName, FieldName, AutocompleteFieldName, AutocompleteMinLength, QueryDelay, MaxResultsDisplayed, DefaultSearchTerm, 0, '');

                            DynamicFieldAutocomplete.on('change', function(){
                                $('#' + FieldName).attr('type', 'text').attr('disabled','disabled').addClass('W50pc').addClass('InputField_Search').removeClass('Hidden').before(DynamicFieldAutocomplete);
                            });
                        }

                        if (FieldType == 'WebserviceMultiselect'){
                            AutocompleteFieldName = FieldName + '_Search';

                            TargetNS.InitMultiselect(DynamicFieldName, FieldName, AutocompleteFieldName, AutocompleteMinLength, QueryDelay, DefaultSearchTerm, 0, '');
                        }
                    }
                )
            });

        return true;
    }

    TargetNS.SerializeForm = function ($Element, Ignore) {
        var QueryString = {};

        if (typeof Ignore === 'undefined') {
            Ignore = {};
        }

        if (isJQueryObject($Element) && $Element.length) {
            $Element.closest('form').find('input:not(:file), textarea, select').filter(':not([disabled=disabled])').each(function () {
                var Name = $(this).attr('name') || '';

                // only look at fields with name
                // only add element to the string, if there is no key in the data hash with the same name
                if (!Name.length || typeof Ignore[Name] !== 'undefined'){
                    return;
                }

                if (!Name.match(/^DynamicField/)) return;

                QueryString[Name] = $(this).val();
            });
        }
        return QueryString;
    };

    Core.Init.RegisterNamespace(TargetNS, 'APP_MODULE');

    return TargetNS;
}(Znuny.DynamicField.Webservice || {}));
