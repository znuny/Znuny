// --
// Copyright (C) 2001-2021 OTRS AG, https://otrs.com/
// Copyright (C) 2021-2022 Znuny GmbH, https://znuny.org/
// --
// This software comes with ABSOLUTELY NO WARRANTY. For details, see
// the enclosed file COPYING for license information (GPL). If you
// did not receive this file, see https://www.gnu.org/licenses/gpl-3.0.txt.
// --

"use strict";

var Core = Core || {};
Core.UI = Core.UI || {};

/**
 * @namespace Core.UI.Autocomplete
 * @memberof Core.UI
 * @author OTRS AG
 * @description
 *      This namespace contains autocomplete specific functions.
 */
Core.UI.Autocomplete = (function (TargetNS) {
    /**
     * @private
     * @name ConfigFallback
     * @memberof Core.UI.Autocomplete
     * @member {Object}
     * @description
     *      The configuration fallback values.
     */
    var ConfigFallback = {
            AutoCompleteActive: 1,
            MinQueryLength: 2,
            QueryDelay: 100,
            MaxResultsDisplayed: 20
        },
    /**
     * @private
     * @name ConfigElements
     * @memberof Core.UI.Autocomplete
     * @member {Object}
     * @description
     *      The possible config parameters.
     */
        ConfigElements = ['AutoCompleteActive', 'MinQueryLength', 'QueryDelay', 'MaxResultsDisplayed', 'ButtonText'],
    /**
     * @private
     * @name Config
     * @memberof Core.UI.Autocomplete
     * @member {Object}
     * @description
     *      The actual config, after merging the fallback values.
     */
        Config = {},
    /**
     * @private
     * @name AJAXLoaderPrefix
     * @memberof Core.UI.Autocomplete
     * @member {String}
     * @description
     *      AJAXLoaderPrefix
     */
        AJAXLoaderPrefix = 'AJAXLoader';

    /**
     * @private
     * @name InitConfig
     * @memberof Core.UI.Autocomplete
     * @function
     * @return {Object} The autocompletion config.
     * @param {String} Type - Type of config, e.g. "CustomerSearch.
     * @param {String} Options - Autocompletion config options.
     * @description
     *      Gets the needed config options object.
     */
    function InitConfig(Type, Options) {
        var TypeConfig = Core.Config.Get('Autocomplete');

        $.each(ConfigElements, function (ConfigKey, ConfigElement) {
            // Option, Type, Fallback
            if (Options && typeof Options[ConfigElement] !== 'undefined') {
                Config[ConfigElement] = Options[ConfigElement];
            }
            else if (Type && TypeConfig[Type]) {
                Config[ConfigElement] = TypeConfig[Type][ConfigElement];
            }
            else {
                Config[ConfigElement] = ConfigFallback[ConfigElement];
            }
        });

        // make sure, that the value of AutoCompleteActive is casted to int
        Config.AutoCompleteActive = parseInt(Config.AutoCompleteActive, 10);

        // if button should be shown, set minlength to an unreachable value
        if (!Config.AutoCompleteActive) {
            Config.MinQueryLength = 500;
        }

        return Config;
    }

    // Override the autocomplete render function to highlight the part of the match
    // which matches the search term.
    $.ui.autocomplete.prototype._renderItem = function(ul, item) {

        var Regex = new RegExp("(" + this.term.replace(/[-[\]/{}()*+?.\\^$|]/g, "\\$&") + ")", "i"),
            Label = item.label;

        // Use not HTML for now, due next action will escape special HTML characters.
        Label = Label.replace(Regex, "OPENSTRONGTAG$1CLOSESTRONGTAG");

        Label = Core.App.EscapeHTML(Label);

        // Replace dummy tags with corresponding HTML.
        Label = Label.replace("OPENSTRONGTAG", '<strong>');
        Label = Label.replace("CLOSESTRONGTAG", '</strong>');

        return $('<li></li>')
            .data('item.autocomplete', item)
            .append('<a href="#">' + Label + '</a>')
            .appendTo(ul);
     };

    /**
     * @name GetConfig
     * @memberof Core.UI.Autocomplete
     * @function
     * @return {Object} Config option value.
     * @param {String} Key - The config option name.
     * @description
     *      gets the config value of a specific key.
     */
    TargetNS.GetConfig = function(Key) {
        return Config[Key];
    };

    /**
     * @name SearchButtonClicked
     * @memberof Core.UI.Autocomplete
     * @member {Object}
     * @description
     *      Needed for the handling of searches with ActiveAutoComplete = 0.
     */
    TargetNS.SearchButtonClicked = {};

    /**
     * @callback Core.UI.Autocomplete~SourceFunction
     * @returns {Array}  Data collected for autocompletion, every array element is an object with label and value keys.
     * @param {String} Request - The data provided by the autocomplete (e.g. the entered text).
     * @param {Function} Response - The function defined by the autocomplete to call with the selected data.
     */

    /**
     * @callback Core.UI.Autocomplete~SelectFunction
     * @param {EventObject} Event - The original browser event object.
     * @param {Object} UI - The data given from the UI (e.g. UI.item is the selected autocomplete list item).
     */

    /**
     * @name Init
     * @memberof Core.UI.Autocomplete
     * @function
     * @param {jQueryObject} $Element - The element which gets autocomplete infos.
     * @param {Core.UI.Autocomplete~SourceFunction} SourceFunction - Defines the source data for the autocomplete.
     * @param {Core.UI.Autocomplete~SelectFunction} SelectFunction - Is executed, if an entry is selected.
     * @param {String} Type of autocompletion, e.g. "CustomerSearch" etc.
     * @param {Object} Options object data with autocomplete plugin options
     * @description
     *      This function initializes autocomplete on an input element.
     */
    TargetNS.Init = function ($Element, SourceFunction, SelectFunction, Type, Options) {
        var AutocompleteConfig,
            $Loader;

        // Only start autocompletion, if $Element is valid element
        if (!isJQueryObject($Element) || !$Element.length) {
            return;
        }

        AutocompleteConfig = InitConfig(Type, Options);

        $Element.each(function () {

            var $SingleElement = $(this);

            $(this).data('request-counter', 0);

            $SingleElement.autocomplete({
                minLength: AutocompleteConfig.MinQueryLength,
                delay: AutocompleteConfig.QueryDelay,
                search: function() {
                    var FieldID = $SingleElement.attr('id'),
                        LoaderHTML = '<span id="' + AJAXLoaderPrefix + FieldID + '" class="AJAXLoader"></span>';

                    $Loader = $('#' + AJAXLoaderPrefix + Core.App.EscapeSelector(FieldID));

                    if (!$Loader.length) {
                        $SingleElement.after(LoaderHTML);
                        $Loader = $('#' + AJAXLoaderPrefix + Core.App.EscapeSelector(FieldID));
                    }

                    $SingleElement.data('request-counter', parseInt($SingleElement.data('request-counter'), 10) + 1);

                    $Loader.show();
                },
                response: function() {
                    // remove loader again if there are no results
                    $SingleElement.data('request-counter', parseInt($SingleElement.data('request-counter'), 10) - 1);
                    if (parseInt($SingleElement.data('request-counter'), 10) <= 0) {
                        $Loader.hide();
                    }
                },
                open: function() {
                    // force a higher z-index than the overlay/dialog
                    $SingleElement.autocomplete('widget').addClass('ui-overlay-autocomplete');
                    return false;
                },
                source: function (Request, Response) {
                    // if an old ajax request is already running, stop the old request and start the new one
                    if ($SingleElement.data('AutoCompleteXHR')) {
                        $SingleElement.data('AutoCompleteXHR').abort();
                        $SingleElement.removeData('AutoCompleteXHR');
                        // run the response function to hide the request animation
                        Response({});
                    }

                    if (SourceFunction) {
                        SourceFunction(Request, Response);
                    }

                    /*
                     * Your SourceFunction must return an array of the data you collected.
                     * Every array element is an object with the following keys:
                     * label: the string displayed in the suggestion menu
                     * value: the string to be inserted in the input field
                     * You can add more keys, if you want to transport data to the select function
                     * all keys will be available there via the UI.item object.
                     *
                     * If you use an ajax function inside your source, make sure to
                     * save the XHRObject in a data-value, to control the xhr automatically:
                     * $Element.data('AutoCompleteXHR', YourCallHere());
                     * This makes sure, that we can abort old ajax request, if new searches are triggered.
                     *
                     * The input value can be found in Request.term. Don't forget to send the MaxResult config
                     * to the server in your ajax request.
                     */
                },
                select: function (Event, UI) {
                    if (SelectFunction) {
                        SelectFunction(Event, UI);
                    }

                    Event.preventDefault();
                    return false;
                }
            });
        });

        if (!AutocompleteConfig.AutoCompleteActive) {
            $Element.each(function () {
                var $SelectedElement = $(this);
                $SelectedElement.after('<button id="' + Core.App.EscapeSelector($SelectedElement.attr('id')) + 'Search" type="button">' + Config.ButtonText + '</button>');
                $('#' + Core.App.EscapeSelector($SelectedElement.attr('id')) + 'Search').click(function () {
                    TargetNS.SearchButtonClicked[$SelectedElement.attr('id')] = true;
                    $SelectedElement.autocomplete("option", "minLength", 0);
                    $SelectedElement.autocomplete("search");
                    $SelectedElement.autocomplete("option", "minLength", 500);
                });
            });
        }
    };

    return TargetNS;
}(Core.UI.Autocomplete || {}));
