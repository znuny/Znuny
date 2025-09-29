// --
// Copyright (C) 2001-2021 OTRS AG, https://otrs.com/
// Copyright (C) 2021 Znuny GmbH, https://znuny.org/
// --
// This software comes with ABSOLUTELY NO WARRANTY. For details, see
// the enclosed file COPYING for license information (GPL). If you
// did not receive this file, see https://www.gnu.org/licenses/gpl-3.0.txt.
// --

"use strict";

var Core  = Core || {},
    Znuny = Znuny || {},
    ZnunyEditor = ZnunyEditor,
    Promise = Promise;

Core.UI = Core.UI || {};

/**
 * @namespace Core.UI.RichTextEditor
 * @memberof Core.UI
 * @author OTRS AG
 * @description
 *      Richtext Editor.
 */
Core.UI.RichTextEditor = (function (TargetNS) {
    /**
     * @private
     * @name $FormID
     * @memberof Core.UI.RichTextEditor
     * @member {jQueryObject}
     * @description
     *      Hidden input field with name FormID.
     */
    var $FormID,
        CKEditorInstances = {},

    /**
     * @private
     * @name TimeOutRTEOnChange
     * @memberof Core.UI.RichTextEditor
     * @member {Object}
     * @description
     *      Object to handle timeout.
     */
        TimeOutRTEOnChange,
    /* @private
     * @name AutocompleteConfig
     * @memberof Core.UI.RichTextEditor
     * @member {Object}
     * @description
     *      Configuration for autocomplete plugin.
     */
        AutocompleteConfig = {
            combineResultOfCompletionGroupsWithSameMarker: false,
            overwriteMentionCompletionElementTagName: 'a',
            completionGroups: [],
            overwriteCSSSelectionBackgroundColor: 'var(--main-bg-color)',
            overwriteCSSSelectionBackgroundColorSelected: '#2c9cf9',
            overwriteCSSSelectionTextColor : 'var(--main-font-color)',
            overwriteCSSSelectionTextColorSelected: 'white',
            overallSelectionDropdownLimit: 20,
        };

    /**
     * @private
     * @name CheckFormID
     * @memberof Core.UI.RichTextEditor
     * @function
     * @returns {jQueryObject} FormID element.
     * @param {jQueryObject} $EditorArea - The jQuery object of the element that has become a rich text editor.
     * @description
     *      Check in the window which hidden element has a name same to 'FormID' and return it like a JQuery object.
     */
    function CheckFormID($EditorArea) {
        if (typeof $FormID === 'undefined') {
            $FormID = $EditorArea.closest('form').find('input:hidden[name=FormID]');
        }
        return $FormID;
    }

    /**
     * @private
     * @name ReplacePlaceholders
     * @memberof Core.UI.RichTextEditor
     * @function
     * @returns {String} String with replaced placeholders.
     * @param {String} Template - String that contains placeholders to replace.
     * @param {Object} Values - Data with values to be replaced for attribute placeholder.
     * @description
     *      Replace placeholders in a string and return it.
     */
    function ReplacePlaceholders(Template, Values) {
        return Template.replace(/{(.*?)}/g, function(Match, Key) {
            return Values[Key] !== undefined ? Values[Key] : Match;
        });
    }

    /**
     * @private
     * @name InitMentionsConfig
     * @memberof Core.UI.RichTextEditor
     * @function
     * @param {Object} MentionsConfig - The mentions configuration.
     * @description
     *      Builds valid mentions config for editor.
     */
    function InitMentionsConfig(MentionsConfig) {
        // CodeMirror does not load any other plugins, so the autocomplete plugin is not available then
        // TODO: (SN) CodeMirror so far does not exists.
        // if (Core.Config.Get('RichText.Type') == 'CodeMirror') {
        //     return;
        // }

        if(typeof MentionsConfig !== 'object' || typeof MentionsConfig.Triggers !== 'object'){
            return;
        }

        /**
         * @private
         * @name MentionsDataCallback
         * @memberof Core.UI.RichTextEditor
         * @function
         * @returns {Array} Response with mention items data that were found based on search string.
         * @param {String} SearchString - Text of a mention to search for related data.
         * @description
         *      Callback function to retrieve mentions data.
         */
        function MentionsDataCallback(SearchString) {
            var Config = this,
                Trigger = Config.matchingMarker,
                DefaultAttributesConfig,
                AttributesConfig;

            var FormattedResponse = [];

            Core.AJAX.FunctionCallSynchronous(
                Core.Config.Get('Baselink'),
                {
                    Action:     'Mentions',
                    Subaction:  Config.entitySubaction,
                    SearchTerm: SearchString,
                },
                function(Response){
                    var OutputContent,
                        OutputItem,
                        EntityResponse = Response[Config.entityName];

                    if(!Array.isArray(EntityResponse)){
                        return [];
                    }

                    DefaultAttributesConfig = [
                        {
                            name: "mention-type",
                            value: Config.entityName,
                        },
                        {
                            // Attribute "href" is used only so that article mentions will be transformed
                            // correctly using HTMLUtilsObject->ToAscii() function into text
                            // that is more unique and matchable by the mentions notification regexp.
                            name: "href",
                            value: "#"
                        },
                    ];

                    // merge any additional attributes with default ones if those exists
                    if(Config.outputAttributes !== undefined && Array.isArray(Config.outputAttributes)) {
                        AttributesConfig = DefaultAttributesConfig.concat(Config.outputAttributes);
                    } else {
                        AttributesConfig = DefaultAttributesConfig;
                    }

                    $.each(EntityResponse, function(Index) {
                        var Values    = EntityResponse[Index],
                            Attributes = [];

                        // add trigger variable so that it can be used in template
                        $.extend(Values, {
                            trigger: Trigger,
                        });

                         // deep copy of AttributesConfig
                        Attributes = $.map(AttributesConfig, function(attribute) {
                            return $.extend(true, {}, attribute);
                        });

                        $.each(Attributes, function(Index) {
                            var Attribute = Attributes[Index].value;
                            // replace placeholders of attribute value if there is a need
                            if(Attributes[Index].replaceValuePlaceholder === 1){
                                Attributes[Index].value = ReplacePlaceholders(Attribute, Values);
                            }
                        });

                        // replace placeholders of dropdown item & content value
                        OutputContent = ReplacePlaceholders(Config.outputTemplate, Values);
                        OutputItem    = ReplacePlaceholders(Config.itemTemplate, Values);

                        FormattedResponse.push(
                            {
                                name: OutputItem,
                                content: OutputContent,
                                useAsHTMLReplacement: false,
                                attributes: Attributes,
                                itemAttributes: [
                                    {
                                        name: 'data-id',
                                        value: ReplacePlaceholders('{id}', Values),
                                    }
                                ],
                                entityName: Config.entityName,
                            }
                        );
                    });
                }
            );
            return FormattedResponse;
        }

        /**
         * @private
         * @name MentionsElementRenderer
         * @memberof Core.UI.RichTextEditor
         * @function
         * @returns {Object} Item changed for rendering purposes.
         * @param {Object} Item - Item data used in the mention completion group.
         * @description
         *      Customizes dropdown item element of matched mention.
         */
        function MentionsElementRenderer(Item) {
            var ItemElement = document.createElement('div'),
                ItemAttributes = Item.itemAttributes;

            ItemElement.innerHTML = Item.name;
            ItemElement.classList.add('MentionItem');
            ItemElement.classList.add(Item.entityName);

            if(ItemAttributes !== undefined && Array.isArray(ItemAttributes)){
                $.each(ItemAttributes, function(){
                    ItemElement.setAttribute(this.name, this.value);
                })
            }

            return ItemElement;
        }

        if(MentionsConfig.Triggers.Group){
            AutocompleteConfig['completionGroups'].push(
                {
                    completions: MentionsDataCallback,
                    matchingMarker: MentionsConfig.Triggers.Group,
                    completionMatchingHandler: "nameStartsWith",
                    outputTemplate: MentionsConfig.Templates.Groups.OutputTemplate,
                    itemTemplate: MentionsConfig.Templates.Groups.ItemTemplate,
                    completionElementRenderer: MentionsElementRenderer,
                    entitySubaction: 'GetGroups',
                    entityName: 'Groups',
                    offerCompletionOptionsWithMarkerMatchingOnly:false,
                    testAllPossibleMarkersOfASelection: true,
                }
            );
        }
        if(MentionsConfig.Triggers.User){
            AutocompleteConfig['completionGroups'].push(
                {
                    completions: MentionsDataCallback,
                    matchingMarker: MentionsConfig.Triggers.User,
                    completionMatchingHandler: "nameStartsWith",
                    outputTemplate: MentionsConfig.Templates.Users.OutputTemplate,
                    outputAttributes: [
                        {
                            name: "id",
                            value: "{username}",
                            replaceValuePlaceholder: 1,
                        },
                    ],
                    itemTemplate: MentionsConfig.Templates.Users.ItemTemplate,
                    completionElementRenderer: MentionsElementRenderer,
                    entitySubaction: 'GetUsers',
                    entityName: 'Users',
                    offerCompletionOptionsWithMarkerMatchingOnly:false,
                    testAllPossibleMarkersOfASelection: true,
                }
            );
        }
    }

    /**
     * @private
     * @name InitAutocompletionConfig
     * @memberof Core.UI.RichTextEditor
     * @function
     * @description
     *      Builds valid autocompletion config for editor.
     */
    function InitAutocompletionConfig() {
        var AutocompletionSettings = {};

        // CodeMirror does not load any other plugins, so the autocomplete plugin is not available then
        // TODO: (SN) CodeMirror so far does not exists.
        // if (Core.Config.Get('RichText.Type') == 'CodeMirror') {
        //     return;
        // }

        /**
         * @private
         * @name AutocompletionDataCallback
         * @memberof Core.UI.RichTextEditor
         * @function
         * @returns {Array} Response with auto completion items data that were found based on search string.
         * @param {String} SearchString - Text of a mention to search for related data.
         * @description
         *      Callback function to retrieve autocomplete data.
         */
        function AutocompletionDataCallback(SearchString) {
            var AdditionalParams,
                FormattedResponse,
                Config = this,
                Trigger = Config.matchingMarker,
                TriggerConfig = AutocompletionSettings.Triggers[Trigger];

            if(TriggerConfig === undefined) {
                return [];
            }
            // Always take the current values because those could
            // have been changed by the user in the form.
            AdditionalParams = {
                TicketID: $('input[name="TicketID"]').val(), // optional, if present
                Action: $('input[name="Action"]').val(),     // optional, if present
                QueueID: Znuny.Form.Input.Get('QueueID')     // optional, if present
            };

            if (SearchString.length < AutocompletionSettings.MinSearchLength) {
                return [];
            }

            FormattedResponse = [];

            Core.AJAX.FunctionCallSynchronous(
                Core.Config.Get('Baselink'),
                {
                    Action:           'AJAXRichTextAutocompletion',
                    Subaction:        'GetData',
                    Trigger:          Trigger,
                    SearchString:     SearchString,
                    AdditionalParams: AdditionalParams
                },
                function(Response){

                    if (!Array.isArray(Response)) {
                        return [];
                    }

                    $.each(Response, function(Index) {
                        var Values    = Response[Index],
                            OutputContent = ReplacePlaceholders(Config.outputTemplate, Values),
                            OutputItem    = ReplacePlaceholders(Config.itemTemplate, Values);

                        FormattedResponse.push(
                            {
                                name: OutputItem,
                                content: OutputContent,
                                useAsHTMLReplacement: true,
                            }
                        );
                    });
                }
            );
            return FormattedResponse;
        }

        /**
         * @private
         * @name AutocompletionElementRenderer
         * @memberof Core.UI.RichTextEditor
         * @function
         * @returns {Object} Item changed for rendering purposes.
         * @param {Object} Item - Item data used in autocomplete completion group.
         * @description
         *      Customizes dropdown item element of matched autocomplete.
         */
        function AutocompletionElementRenderer(Item) {
            var ItemElement = document.createElement('div');

            ItemElement.innerHTML = Item.name;
            ItemElement.classList.add('AutocompletionItemParent');

            return ItemElement;
        }

        Core.AJAX.FunctionCallSynchronous(
            Core.Config.Get('Baselink'),
            {
                Action:    'AJAXRichTextAutocompletion',
                Subaction: 'GetAutocompletionSettings'
            },
            function(Response) {
                if ($.isEmptyObject(Response)) {
                    return true;
                }

                AutocompletionSettings = Response;

                $.each(AutocompletionSettings.Triggers, function(Trigger) {

                    AutocompleteConfig['completionGroups'].push({
                        completions: AutocompletionDataCallback,
                        matchingMarker: Trigger,
                        completionMatchingHandler: "everything",
                        outputTemplate: AutocompletionSettings.OutputTemplate,
                        itemTemplate: AutocompletionSettings.ItemTemplate,
                        completionElementRenderer: AutocompletionElementRenderer,
                    })
                });
            }
        );
        return;
    }

    /**
     * @name SetWindowEditor
     * @memberof Core.UI.RichTextEditor
     * @function
     * @returns {Boolean} Returns false on error.
     * @param {jQueryObject} $EditorArea - The jQuery object of the element that is a rich text editor.
     * @description
     *      This sets current window editor global variable.
     *      Useful when working on single CKEditor instance.
     */
    TargetNS.SetWindowEditor = function ($EditorArea) {
        var EditorID;

        if (typeof ZnunyEditor === 'undefined') {
            return false;
        }

        if (!isJQueryObject($EditorArea) || !$EditorArea.hasClass('HasCKEInstance')) {
            return false;
        }

        EditorID = $EditorArea.attr('id');
        if(CKEditorInstances[EditorID] === undefined){
            return false;
        }

        window.editor = CKEditorInstances[EditorID];
        return true;
    }

    /**
     * @name InitEditor
     * @memberof Core.UI.RichTextEditor
     * @function
     * @returns {Boolean} Returns false on error.
     * @param {jQueryObject} $EditorArea - The jQuery object of the element that will be a rich text editor.
     * @description
     *      This function initializes the application and executes the needed functions.
     */
    TargetNS.InitEditor = function ($EditorArea) {
        var EditorID = '',
            CKEUserLanguage,
            UploadURL,
            MentionsConfig,
            ToolbarConfig,
            ToolbarItems,
            ExcludedPlugins = Core.Config.Get('RichText.ExcludedPlugins', []),
            ContentAllowed,
            HeadingOptions = [],
            HeadingOptionConfig,
            Plugins = Core.Config.Get('RichText.BuildPlugins', getDefaultPlugins()),
            AdditionalPluginsConfig = {},
            PoweredByHidden = false,
            EditorIsResizing = false,
            ResizeStartY,
            ResizeStartHeight,
            ResizeNewHeight = Core.Config.Get('RichText.Height'),
            ResizeHeightDiff,
            RTEContentCssDefault,
            RTEContentCssSkin,
            RTEContentCssInternal,
            RTEContentCSSToApply = [],
            RTEEditorAreaContent;

        if (typeof ZnunyEditor === 'undefined') {
            return false;
        }

        if (isJQueryObject($EditorArea) &&
            ($EditorArea.hasClass('HasCKEInstance') || ($EditorArea.hasClass('CKEInstanceIsLoading')))
            ) {
            return false;
        }

        if (isJQueryObject($EditorArea) && $EditorArea.length === 1) {
            EditorID = $EditorArea.attr('id');
        }

        if (EditorID === '') {
            Core.Exception.Throw('RichTextEditor: Need exactly one EditorArea!', 'TypeError');
        }

        CKEUserLanguage = Core.Config.Get('CKEUserLanguage');
        MentionsConfig  = Core.Config.Get('Mentions::RichTextEditor');

        InitAutocompletionConfig(); // No need to pass config here as it is taken from the backend via AJAX call
        InitMentionsConfig(MentionsConfig);

        // Build URL for image upload
        if (CheckFormID($EditorArea).length) {

            UploadURL = Core.Config.Get('Baselink')
                + 'Action='
                + Core.Config.Get('RichText.PictureUploadAction', 'PictureUpload')
                + '&FormID='
                + CheckFormID($EditorArea).val()
                + '&' + Core.Config.Get('SessionName')
                + '=' + Core.Config.Get('SessionID');
        }

        // render toolbar with or without Image item
        // uploading attachments still works by other
        // methods like pasting/drag & drop
        if(CheckFormID($EditorArea).length){
            ToolbarItems = Core.Config.Get('RichText.Toolbar');
            // use simple upload handler
            AdditionalPluginsConfig.simpleUpload = {
                uploadUrl: UploadURL,
                withCredentials: false,
                headers: {},
            };
        } else {
            // if Base64UploadAdapter plugin is enabled in plugins
            // it will work instead of simple upload handler
            ToolbarItems = Core.Config.Get('RichText.ToolbarWithoutImage');
        }

        ToolbarConfig = {
            items: ToolbarItems,
            shouldNotGroupWhenFull: true,
        };

        // TODO check (SN): any CKEDITOR4 previous allowed selectors are here also allowed
        // maybe not needed?
        ContentAllowed = Core.Config.Get('RichText.ContentAllowed', [
            {
                name: 'div',
                attributes: {
                    type: true
                },
                styles: true
            },
            {
                name: 'img',
                attributes: true
            },
            {
                name: 'col',
                attributes: {
                    width: true
                }
            },
            {
                name: 'style',
                attributes: true,
                styles: true
            },
            {
                name: /.*/,
                attributes: {
                    id: true
                },
                classes: true
            }
        ])

        // allow html tag of article quoted replies
        ContentAllowed.push(
            {
                name: 'div',
                attributes: {
                    type: 'cite'
                },
                styles: true
            }
        );

        HeadingOptionConfig = Core.Config.Get('RichText.FormatTags');
        if(HeadingOptionConfig !== undefined && Array.isArray(HeadingOptionConfig)){
            // try to apply correct JSON object from system configuration
            $.each(HeadingOptionConfig, function(){
                var Option = this;
                Option = '{' +  Option + '}';

                try {
                    Option = JSON.parse(Option);
                    HeadingOptions.push(Option);
                }
                catch(error) { // in case of any error clean array to apply default value later on
                    console.error(error + ' (default heading configuration will be used instead)');
                    HeadingOptions = [];
                    return false;
                }
            })
        }
        if (HeadingOptions.length == 0) {
            HeadingOptions = [
                    { model: 'paragraph', title: 'Paragraph', class: 'ck-heading_paragraph' },
                    { model: 'heading1', view: 'h1', title: 'Heading 1', class: 'ck-heading_heading1' },
                    { model: 'heading2', view: 'h2', title: 'Heading 2', class: 'ck-heading_heading2' },
                    { model: 'heading3', view: 'h3', title: 'Heading 3', class: 'ck-heading_heading3' },
                    { model: 'heading4', view: 'h4', title: 'Heading 4', class: 'ck-heading_heading4' },
                    { model: 'heading5', view: 'h5', title: 'Heading 5', class: 'ck-heading_heading5' },
                    { model: 'heading6', view: 'h6', title: 'Heading 6', class: 'ck-heading_heading6' },
                    { model: 'pre', view: 'pre', title: 'Preformatted', class: 'ck-heading_preformatted' },
            ];
        }

        if(Plugins.indexOf('Fullscreen') > 0){
            AdditionalPluginsConfig.fullscreen = {
                menuBar: {
                    isVisible: true,
                },
                toolbar: {
                    shouldNotGroupWhenFull: false,
                },
                onEnterCallback: function(container){
                    $(container).prev('.ck-body-wrapper').
                        addClass('ck-znuny-fullscreen');
                },
                onLeaveCallback: function(container){
                    $(container).prev('.ck-body-wrapper').
                        removeClass('ck-znuny-fullscreen');
                },
            };
        }

        RTEEditorAreaContent = $EditorArea.val();
        RTEEditorAreaContent = RTEEditorAreaContent.replace(/<style class="RTEContentCssInternal">[\s\S]*?<\/style>/g, '');
        RTEEditorAreaContent = RTEEditorAreaContent.replace(/<style class="RTEContentCssDefault">[\s\S]*?<\/style>/g, '');
        $EditorArea.val(RTEEditorAreaContent);

        $EditorArea.addClass('CKEInstanceIsLoading');

        ZnunyEditor
        .create(
            $EditorArea[0],
            $.extend({
                plugins: Plugins,
                extraPlugins: Core.Config.Get('RichText.ExtraPlugins', []),
                removePlugins: ExcludedPlugins,
                autocomplete: AutocompleteConfig,
                heading: {
                    options: HeadingOptions,
                },
                ui: {
                    poweredBy: {
                        position: 'border',
                        side: 'left',
                        label: '',
                        verticalOffset: 0,
                        horizontalOffset: 0,
                    }
                },
                toolbar: ToolbarConfig,
                language:   {
                    ui: CKEUserLanguage,
                    // Edited content language
                    content: CKEUserLanguage,
                },
                fontSize: {
                    options: Core.Config.Get('RichText.FontSizes', ['8px','10px','12px','14px','16px','18px','20px','22px','24px','26px','28px','30px']),
                    supportAllValues: true,
                },
                fontFamily: {
                    options: Core.Config.Get('RichText.FontNames'),
                    supportAllValues: true,
                },
                // Enable html support of legacy tags to not loose
                // content of systems with previously installed CKEditor4.
                // Some tags also needs to be possible to display for Znuny requirements.
                htmlSupport: {
                    allow: ContentAllowed,
                    disallow: Core.Config.Get('RichText.ContentDisallowed', []),
                },
                image: {
                    upload: {
                        // TODO check (SN):
                        // By default prevent other extensions types of files to be uploaded
                        // which is not perfect as it will not show an error message
                        // that image can't be uploaded..
                        types: ['png', 'gif', 'jpg', 'jpeg', 'bmp' ],
                    },
                    resizeUnit: 'px',
                    insert: {
                        type: 'block',
                    },
                styles: {
                    options: [
                        'inline',
                        'alignLeft',
                        'alignRight',
                        'alignCenter',
                        'alignBlockLeft',
                        'alignBlockRight',
                        'block',
                        'side' ]
                    },
                    toolbar: [
                        'imageStyle:inline',
                        '|',
                        'imageStyle:alignLeft',
                        'imageStyle:alignCenter',
                        'imageStyle:alignRight',
                        '|',
                        'imageStyle:alignBlockLeft',
                        'imageStyle:block',
                        'imageStyle:alignBlockRight',
                        '|',
                        'imageStyle:side',
                        '|',
                        'imageTextAlternative'
                    ],
                },
            },
            AdditionalPluginsConfig)
        )
        .then(function(editor) {
            CKEditorInstances[EditorID] = editor;
            // Mark the editor textarea as linked with an RTE instance to avoid multiple instances
            $EditorArea.addClass('HasCKEInstance');
            TargetNS.SetWindowEditor($EditorArea);

            Core.App.Publish('Event.UI.RichTextEditor.InstanceCreated', [editor]);

            // Apply rich text additional styles
            if(Core.Config.Get('RichText.Width')){
                editor.editing.view.change(function(writer) { writer.setStyle('width', Core.Config.Get('RichText.Width'), editor.editing.view.document.getRoot()); });
            }
            if(Core.Config.Get('RichText.Height')){
                editor.editing.view.change(function(writer) { writer.setStyle('height', Core.Config.Get('RichText.Height'), editor.editing.view.document.getRoot()); });
            }
            if(Core.Config.Get('RichText.MinHeight')){
                editor.editing.view.change(function(writer) { writer.setStyle('min-height', Core.Config.Get('RichText.MinHeight'), editor.editing.view.document.getRoot()); });
            }

            // Append <style> tags for configured ckeditor content css
            RTEContentCssDefault  = Core.Config.Get('RichText.ContentCssDefault') || '';
            RTEContentCssSkin     = Core.Config.Get('RichText.ContentCssSkin') || '';
            RTEContentCssInternal = Core.Config.Get('RichText.ContentCssInternal') || '';

            RTEContentCSSToApply = [
                {
                    Type: 'File',
                    CSS : RTEContentCssInternal,
                    Id : 'RTEContentCssInternalGlobal'
                },
                {
                    Type: 'File',
                    CSS : RTEContentCssSkin,
                    Id : 'RTEContentCssSkinGlobal'
                },
                {
                    Type : 'StyleTag',
                    CSS : RTEContentCssDefault,
                    Id : 'RTEContentCssDefaultGlobal',
                },
            ];

            $(RTEContentCSSToApply).each(function(Index, ContentData){
                if(typeof ContentData['CSS'] === 'string' &&
                    ContentData['CSS'] !== '' && $('#' +ContentData['Id']).length === 0){
                        if(ContentData['Type'] === 'StyleTag' && $('style#' + ContentData['Id']).length === 0){
                            document.head.innerHTML +=
                            '<style id="' + ContentData['Id'] + '">' +
                                '.ck.ck-content { ' + ContentData['CSS'] + ' }' +
                            '</style>'
                        }
                        else if(ContentData['Type'] === 'File' && $('link#' + ContentData['Id']).length === 0){
                            document.head.innerHTML +=
                            '<link id="' + ContentData['Id'] + '" ' +
                            'rel="stylesheet" type="text/css" href="' +
                            ContentData['CSS'] + '">'
                        }
                }
            });

            editor.model.document.on('change:data', function() {
                var Changes,
                    Change,
                    ImageElement,
                    Index;
                if (editor.getData() != "") {
                    $("#" + editor.ElementId).val(editor.getData());
                }

                // Listen to any image insert upload, then apply it's alignment
                // to "alignBlockLeft" as it's not possible via config of image
                // plugin
                Changes = Array.from(editor.model.document.differ.getChanges());
                for (Index = 0; Index < Changes.length; Index++) {
                    Change = Changes[Index];

                    if (Change.type === 'insert' && Change.name === 'imageBlock') {
                        editor.model.change(function(writer) {
                            ImageElement = Change.position.nodeAfter;

                            if (!ImageElement.getAttribute('imageStyle')) {
                                writer.setAttribute('imageStyle', 'alignBlockLeft', ImageElement);
                            }
                        });
                    }
                }

                // Remove the validation error tooltip if content is added to the editor
                window.clearTimeout(TimeOutRTEOnChange);
                TimeOutRTEOnChange = window.setTimeout(function () {
                    Core.Form.Validate.ValidateElement($EditorArea);
                    Core.App.Publish('Event.UI.RichTextEditor.ChangeValidationComplete', [editor]);
                }, 250);
                Core.App.Publish('Event.UI.RichTextEditor.ChangeData', [editor]);
            });
            // Needed for client side validation of RTE
            editor.ui.focusTracker.on('change:isFocused', function(evt, name, isFocused){
                if (!isFocused) {
                    $("#" + $EditorArea.attr('id')).val(editor.getData());
                    if (!$EditorArea.hasClass('Error')) {
                        Core.Form.Validate.ValidateElement($EditorArea);
                    }
                    Core.Form.ErrorTooltips.RemoveRTETooltip($EditorArea);
                    Core.App.Publish('Event.UI.RichTextEditor.Blur', [editor]);
                } else {
                    Core.App.Publish('Event.UI.RichTextEditor.Focus', [editor]);
                }
            });

            // add ck-resizer as it was in previous ckeditor version
            $(editor.ui.view.element).append('<div class="ck ck-resizer">◢</div>');
            $(editor.ui.view.element).addClass('ck-has-resizer');

            // support resizer behavior
            $(editor.ui.view.element).find('.ck.ck-resizer').on('mousedown', function(Event){
                EditorIsResizing = true;
                ResizeStartY = Event.clientY;

                ResizeStartHeight = $(editor.ui.view.editable.element).outerHeight();

                if (editor.editing.view.document.isFocused){
                    $('.ck-powered-by-balloon').removeClass('ck-balloon-panel_visible');
                    PoweredByHidden = true;
                }

                document.body.style.cursor = 'ns-resize';
                Event.preventDefault();

                $(document).off('mousemove.RichTextResize')
                    .on('mousemove.RichTextResize', function (Event) {
                    if (!EditorIsResizing) return;
                        ResizeHeightDiff = Event.clientY - ResizeStartY;
                        ResizeNewHeight = Math.max(150, Math.min(ResizeStartHeight + ResizeHeightDiff, 900));
                        $(editor.ui.view.editable.element).height(ResizeNewHeight);
                });
            });

            $(document).on('mouseup.RichTextResize', function(){
                if(PoweredByHidden === true){
                    editor.ui.update();
                    $('.ck-powered-by-balloon').addClass('ck-balloon-panel_visible');
                    PoweredByHidden = false;
                }

                editor.editing.view.change(function(writer) {
                    writer.setStyle(
                        'height',
                        (parseInt(ResizeNewHeight, 10) + 5.5) +
                        'px', editor.editing.view.document.getRoot());
                });
                EditorIsResizing = false;

                document.body.style.cursor = 'auto';
                $(document).off('mousemove.RichTextResize');
            });

            // TODO (SN): remove this commented code if below window.editor.conversion works better
            // Disable interaction with Links plugin for Mentions <a> tags
            // editor.editing.view.document.on('click', (evt, data) => {
            //     // Find the link element in the editing view at the click position
            //     const linkElement = data.domTarget.closest('a');

            //     if (linkElement && linkElement.classList.contains('mention')) {
            //         // Prevent the default link interaction
            //         data.preventDefault();
            //         // Stop the propagation of the event to avoid further handling
            //         evt.stop();
            //     }
            // }, { priority: 'highest' });
            // TODO (SN) Update: this seems to be working so probably that TODO
            // comment section should be deleted (after tests)

            window.editor.conversion.for('downcast').add(function(dispatcher){
              dispatcher.on('attribute:linkHref', function(evt, data){
                if (
                    data.attributeNewValue === '#' &&
                    (
                        (data.item.textNode &&
                         data.item.textNode._attrs &&
                         typeof data.item.textNode._attrs.has === 'function' &&
                         data.item.textNode._attrs.has('mention'))
                        ||
                        data.item.textNode === undefined
                    )
                ) {
                  evt.stop();
                }
              }, { priority: 'highest' });
            });

            $EditorArea.removeClass('CKEInstanceIsLoading');

            Core.App.Publish('Event.UI.RichTextEditor.InstanceReady', [editor]);
        })
        .catch(function(error) {
            $EditorArea.removeClass('CKEInstanceIsLoading');
            console.error(error);
            Core.App.Publish('Event.UI.RichTextEditor.InstanceCreateError', [EditorID, error]);
        });
    };

    /**
     * @name InitAllEditors
     * @memberof Core.UI.RichTextEditor
     * @function
     * @description
     *      This function initializes as a rich text editor every textarea element that contains the RichText class.
     */
    TargetNS.InitAllEditors = function () {
        if (typeof ZnunyEditor === 'undefined') {
            return;
        }

        $('textarea.RichText').each(function () {
            TargetNS.InitEditor($(this));
        });
    };

    /**
     * @name Init
     * @memberof Core.UI.RichTextEditor
     * @function
     * @description
     *      This function initializes JS functionality.
     */
    TargetNS.Init = function () {
        if (typeof ZnunyEditor === 'undefined') {
            return;
        }

        TargetNS.InitAllEditors();
    };

    /**
     * @name UpdateLinkedField
     * @memberof Core.UI.RichTextEditor
     * @function
     * @param {jQueryObject} $EditorArea - The jQuery object of the element that is a rich text editor.
     * @description
     *      This function updates the linked field for a rich text editor.
     */
    TargetNS.UpdateLinkedField = function ($EditorArea) {
        var EditorID = '',
            Data,
            StrippedContent;

        if (isJQueryObject($EditorArea) && $EditorArea.length === 1) {
            EditorID = $EditorArea.attr('id');
        }

        if (EditorID === '') {
            Core.Exception.Throw('RichTextEditor: Need exactly one EditorArea!', 'TypeError');
        }

        Data = TargetNS.GetInstance(EditorID).getData();
        StrippedContent = Data.replace(/\s+|&nbsp;|<\/?\w+[^>]*\/?>/g, '');

        if (StrippedContent.length === 0 && !Data.match(/<img/)) {
            $EditorArea.val('');
        }
        else {
            $EditorArea.val(Data);
        }
    };

    /**
     * @name IsEnabled
     * @memberof Core.UI.RichTextEditor
     * @function
     * @returns {Boolean} True if RTE is enabled, false otherwise
     * @param {jQueryObject} $EditorArea - The jQuery object of the element that is a rich text editor.
     * @description
     *      This function check if a rich text editor is enable in this moment.
     */
    TargetNS.IsEnabled = function ($EditorArea) {
        if (typeof ZnunyEditor === 'undefined') {
            return false;
        }

        if (isJQueryObject($EditorArea) && $EditorArea.length) {
            return (TargetNS.GetInstance([$EditorArea[0].id]) ? true : false);
        }
        return false;
    };

    /**
     * @name Focus
     * @memberof Core.UI.RichTextEditor
     * @function
     * @returns {Boolean} True if RTE focus was applied.
     * @param {jQueryObject} $EditorArea - The jQuery object of the element that is a rich text editor.
     * @description
     *      This function focusses the given RTE.
     */
    TargetNS.Focus = function ($EditorArea) {
        var EditorID = '';

        if (isJQueryObject($EditorArea) && $EditorArea.length === 1) {
            EditorID = $EditorArea.attr('id');
        }

        if (EditorID === '') {
            Core.Exception.Throw('RichTextEditor: Need exactly one EditorArea!', 'TypeError');
            return false;
        }

        if (CKEditorInstances[EditorID] !== undefined) {
            CKEditorInstances[EditorID].focus();
        }
        else {
            $EditorArea.focus();
        }
        return true;
    };

    /**
     * @name GetInstance
     * @memberof Core.UI.RichTextEditor
     * @function
     * @returns {Object} Instance of CKEditor.
     * @param {String} FieldID - The field identifier of the element that is a rich text editor.
     * @description
     *      This function returns an instance of RichText Editor by id.
     */
    TargetNS.GetInstance = function (FieldID) {
        return CKEditorInstances[FieldID];
    }

    /**
     * @name GetEditableArea
     * @memberof Core.UI.RichTextEditor
     * @function
     * @returns {Object} Editable area of ckeditor instance specified by field id.
     * @param {String} FieldID - The field identifier of the element that is a rich text editor.
     * @description
     *      This function returns an editable area of instance of RichText Editor by id.
     */
    TargetNS.GetEditableArea = function (FieldID) {
        if (CKEditorInstances[FieldID] !== undefined) {
            return CKEditorInstances[FieldID].ui.view.editable.element;
        }
        return undefined;
    }

    /**
     * @name SetTextCursorPosition
     * @memberof Core.UI.RichTextEditor
     * @function
     * @returns {Boolean} True if text cursor position was changed.
     * @param {String} FieldID - The field identifier of the element that is a rich text editor.
     * @param {RootElement} Element - Root element of the ckeditor that text offset will be set within,
     *  usually create it with: editor.model.document.getRoot() for main element or .getChild(Number).
     *  for specified child elements
     * @param {(Integer|String)} Offset - Position value, possible: number, 'before', 'after', 'end'
     * @description
     *      This function returns success for operation of setting text cursor position.
     */
    TargetNS.SetTextCursorPosition = function (FieldID, Element, Offset) {
        if (CKEditorInstances[FieldID] !== undefined) {
            CKEditorInstances[FieldID].model.change(function(writer) {
                writer.setSelection(writer.createPositionAt(Element, Offset));
            });
            return true;
        }
        return false;
    }

    /**
     * @name ListAllInstances
     * @memberof Core.UI.RichTextEditor
     * @function
     * @returns {Array} List of ckeditor instances.
     * @description
     *      This function returns a list of all RichText Editor instances.
     */
    TargetNS.ListAllInstances = function () {
        return CKEditorInstances;
    }

    /**
     * @name DestroyInstance
     * @memberof Core.UI.RichTextEditor
     * @function
     * @returns {Promise<void>}
     * @param {String} FieldID - The field identifier of the element that is a rich text editor.
     * @description
     *      This function destroys RichText Editor instance by id.
     */
    TargetNS.DestroyInstance = function (FieldID) {
        if(CKEditorInstances[FieldID]){
            return CKEditorInstances[FieldID].destroy()
            .then(function() {
                $('#' + FieldID).removeClass('HasCKEInstance');
                delete CKEditorInstances[FieldID];
                return FieldID;
            })
            .catch(function(error) {
                console.error(error);
                throw error;
            });
        } else {
            return Promise.reject(new Error('CKEditor instance not found.'));
        }
    }

    /**
     * @name DestroyAllInstances
     * @memberof Core.UI.RichTextEditor
     * @function
     * @returns {Promise<void>} List of ckeditor instances.
     * @description
     *      This function destroys all RichText Editor instances.
     */
    TargetNS.DestroyAllInstances = function () {
        var DestroyPromises = [];

        $.each(CKEditorInstances, function (Key) {
            DestroyPromises.push(TargetNS.DestroyInstance(Key));
        });

        return Promise.all(DestroyPromises);
    }

    function getDefaultPlugins() {
        return [
            'Alignment',
            'Autocomplete',
            'Autoformat',
            'AutoImage',
            'Base64UploadAdapter',
            'BlockQuote',
            'Bold',
            'Italic',
            'Underline',
            'Strikethrough',
            'Code',
            'Subscript',
            'Superscript',
            'CloudServices',
            'CodeBlock',
            'Essentials',
            'FindAndReplace',
            'FontBackgroundColor',
            'FontColor',
            'FontFamily',
            'FontSize',
            'Fullscreen',
            'GeneralHtmlSupport',
            'Heading',
            'HorizontalLine',
            'HtmlEmbed',
            'Image',
            'ImageBlock',
            'ImageCaption',
            'ImageResize',
            'ImageStyle',
            'ImageToolbar',
            'ImageInline',
            'ImageInsert',
            'Indent',
            'IndentBlock',
            'Link',
            'List',
            'ListProperties',
            'MediaEmbed',
            'PageBreak',
            'PasteFromOffice',
            'PictureEditing',
            'RemoveFormat',
            'SelectAll',
            'ShowBlocks',
            'SimpleUploadAdapter',
            'SourceEditing',
            'SpecialCharacters',
            'SpecialCharactersMathematical',
            'Style',
            'Table',
            'TableCaption',
            'TableCellProperties',
            'TableColumnResize',
            'TableProperties',
            'TableToolbar',
            'TextPartLanguage',
            'TextTransformation'
        ];
    }

    Core.Init.RegisterNamespace(TargetNS, 'APP_MODULE');

    return TargetNS;
}(Core.UI.RichTextEditor || {}));
