// --
// Copyright (C) 2021 Znuny GmbH, https://znuny.org/
// --
// This software comes with ABSOLUTELY NO WARRANTY. For details, see
// the enclosed file COPYING for license information (AGPL). If you
// did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
// --
/* eslint no-eval: 0 */
// nofilter(TidyAll::Plugin::Znuny::JavaScript::ESLint)
'use strict';

var Znuny = Znuny || {};
Znuny.Form = Znuny.Form || {};

/**
 * @namespace Znuny.Form.Generic
 * @memberof Znuny.Form
 * @author Znuny GmbH
 */
Znuny.Form.Generic = (function (TargetNS) {

    var RestoreElements = {};

    /**
     * @name Init
     * @memberof Znuny.Form.Generic
     * @function
     * @description
     *       Initialize module functionality
     */
    TargetNS.Init = function () {
        var $Restore = $('[data-formelement-restore]'),
            $Filter     = $('[data-formelement-filter]'),
            $Allocation = $('[data-formelement-allocation]'),
            $Checkboxes = $('[data-formelement-select-all-checkboxes]');

        // This binds a click event (Add) to the document and all child elements within it.
        // This means that elements that are not yet present already get the correct bind.
        $(document).off("click.data-formelement-add").on("click.data-formelement-add", '[data-formelement-add]', function () {
            TargetNS.Add(
                $(this)
            );
            return false;
        });

        // This binds a click event (Remove) to the document and all child elements within it.
        // This means that elements that are not yet present already get the correct bind.
        $(document).off("click.data-formelement-remove").on("click.data-formelement-remove", '[data-formelement-remove]', function () {
            TargetNS.Remove(
                $(this)
            );
            return false;
        });

        // This binds a click event (Restore) to the document and all child elements within it.
        // This means that elements that are not yet present already get the correct bind.
        $(document).off("click.data-formelement-restore").on("click.data-formelement-restore", '[data-formelement-restore]', function () {
            TargetNS.Restore(
                $(this)
            );
            return false;
        });

        $Restore.each(function(){
            Core.UI.InputFields.Deactivate();

            var DestinationName   = $(this).data('formelementRestoreDestinationName'),
                $Destination      = $('[data-formelement-restore-destination="' + DestinationName + '"]'),
                $DestinationClone = $Destination.clone();

            Core.UI.InputFields.Activate();
            RestoreElements[DestinationName] = $DestinationClone;
        });

        $Filter.each(function(){
            var DestinationName   = $(this).data('formelementFilterDestinationName'),
                $Destination      = $('[data-formelement-filter-destination="' + DestinationName + '"]');
            Core.UI.Table.InitTableFilter($(this), $Destination);
        });

        $Allocation.each(function(){
            var DestinationName = $(this).data('formelementAllocationDestinationName'),
                $Destination     = $('[data-formelement-allocation-destination="' + DestinationName + '"]'),
                FunctionReceive  = $(this).data('formelementAllocationFunctionReceive'),
                FunctionRemove   = $(this).data('formelementAllocationFunctionRemove'),
                FunctionSortStop = $(this).data('formelementAllocationFunctionSortStop');

            var ReceiveCallback  = eval(FunctionReceive),
                RemoveCallback   = eval(FunctionRemove),
                SortStopCallback = eval(FunctionSortStop);

            // Core.UI.AllocationList.Init(ListSelector, ConnectorSelector, ReceiveCallback, RemoveCallback, SortStopCallback);
            Core.UI.AllocationList.Init($(this), $Destination, ReceiveCallback, RemoveCallback, SortStopCallback);
        });

        $Checkboxes.bind('click', function () {
            var DestinationName   = $(this).data('formelementSelectAllCheckboxesDestinationName'),
                $Destination      = $('[data-formelement-select-all-checkboxes-destination="' + DestinationName + '"]'),
                $Source = $(this);
            Core.Form.SelectAllCheckboxes($Source, $Destination);
        });


    };

    /**
     * @name Add
     * @memberof Znuny.Form.Generic
     * @function
     * @returns {Boolean} Returns false
     * @param {Object} AddElement - Object of the clicked add element.
     *
     * data-formelement-add                                              # if empty use following data attributes:
     * data-formelement-add-destination-name="AdditionalDFStorage"       # name of destination element
     * data-formelement-add-source-name="AdditionalDFStorageTemplate"    # name of source element (template)
     * data-formelement-add-counter-name="AdditionalDFStorageCounter"    # name of counter element (maybe input field to count entries)
     * data-formelement-add-method='append'                              # method to add this source element (append|prepend|after|before)

     * @description
     *      This function adds a new value to the possible values list
     */
    TargetNS.Add = function (AddElement) {
        var Param = {},
            Method,
            $Source,
            $Destination,
            $Counter,
            $SourceClone,
            Counter;

        $.each(AddElement.data(), function(Key, Value) {
            Param[Key] = Value || '';
        });

        Method = Param['formelementAddMethod'] || 'append';

        $Source      = $('[data-formelement-add-source="'      + Param['formelementAddSourceName']      + '"]');
        $Destination = $('[data-formelement-add-destination="' + Param['formelementAddDestinationName'] + '"]');
        $Counter     = $('[data-formelement-add-counter="'     + Param['formelementAddCounterName']     + '"]');

        Core.UI.InputFields.Deactivate();
        $SourceClone = $Source.clone();
        Counter      = $Counter.val();

        // increment key counter
        Counter++;

        $SourceClone.addClass('ValueRow');
        $SourceClone.removeClass('Hidden ValueTemplate');
        $SourceClone.removeAttr("data-formelement-add-source");

        // copy values and change IDs and names
        $SourceClone.find(':input, a, button').each(function() {
            var ID = $(this).attr('id'),
                CounterID;

            if (Counter){
                CounterID = ID + '_' + Counter;

                $(this).attr('id', CounterID);
                $(this).attr('name', CounterID);

                // set error controls
                $(this).parent().find('#' + ID + 'Error').attr('id', CounterID + 'Error');
                $(this).parent().find('#' + ID + 'Error').attr('name', CounterID + 'Error');

                $(this).parent().find('#' + ID + 'ServerError').attr('id', CounterID + 'ServerError');
                $(this).parent().find('#' + ID + 'ServerError').attr('name', CounterID + 'ServerError');
            }

            // add event handler to remove button
            if($(this).is('[data-formelement-remove]') && $(this).data('formelementRemove') == Param['formelementAdd']) {
                var DestinationName        = $(this).data('formelementRemoveDestinationName'),
                    DestinationNameCounter = DestinationName + '_' + Counter;

                $(this).removeAttr("data-formelement-remove-destination-name");
                $(this).attr('data-formelement-remove-destination-name', DestinationNameCounter);
                $(this).data('formelementRemoveDestinationName', DestinationNameCounter);

                $SourceClone.removeAttr("data-formelement-remove-destination");
                $SourceClone.attr('data-formelement-remove-destination', DestinationNameCounter);
                $SourceClone.data('formelementRemoveDestination', DestinationNameCounter);

                // bind click function to remove button
                $(this).off('click.data-formelement-remove').on('click.data-formelement-remove', function () {
                    TargetNS.Remove($(this));
                    return false;
                });
            }
        });

        $SourceClone.find('label').each(function(){
            var For = $(this).attr('for');
            $(this).attr('for', For + '_' + Counter);
        });

        // append to container
        $Destination[Method]($SourceClone);

        // set new counter
        $Counter.val(Counter);

        // Modernize
        Core.UI.InputFields.Activate();

        Param['Counter'] = Counter;
        Param['Clone']   = $SourceClone;

        Core.App.Publish('Znuny.Form.Generic.Add', [Param]);

        return false;
    };


    /**
     * @name Remove
     * @memberof Znuny.Form.Generic
     * @function
     * @returns {Boolean} Returns false
     * @param {Object} RemoveElement - Object of the clicked remove element.
     *
     * data-formelement-remove                                              # if empty use following data attributes:
     * data-formelement-remove-destination='AdditionalDFStorage'            # name of destination element
     * data-formelement-remove-destination-name='AdditionalDFStorage'       # name of destination element
     *
     * data-formelement-remove='.Header'                                    # if string contains class syntax - remove all elements with this class
     * data-formelement-remove='#Header'                                    # if string contains id syntax - remove all elements with this id
     *
     * @description
     *      This function removes a value from possible values list,
     *      removes elements via class or id selector.
     */
    TargetNS.Remove = function (RemoveElement){
        var $Destination,
            Param = {},
            Counter;

        $.each(RemoveElement.data(), function(Key, Value) {
            Param[Key] = Value || '';
        });

        // removes element from data-formelement-remove-destination-name = 'AdditionalDFStorage'
        if (
            Param['formelementRemoveDestinationName']
            && Param['formelementRemoveDestinationName'].length
            && $('[data-formelement-remove-destination="' + Param['formelementRemoveDestinationName'] + '"]').length
        ){
            $Destination = $('[data-formelement-remove-destination="' + Param['formelementRemoveDestinationName'] + '"]');
        }

        // removes elements from data-formelement-remove = '.Header'
        else if (Param['formelementRemove'].length &&  Param['formelementRemove'].startsWith(".") || Param['formelementRemove'].startsWith("#")) {
            $Destination = $(Param['formelementRemove']);
        }

        if (Param['formelementRemoveCounterName'] && $('[data-formelement-remove-counter="' + Param['formelementRemoveCounterName'] + '"]')){
            var $Counter = $('[data-formelement-remove-counter="' + Param['formelementRemoveCounterName'] + '"]');
            Counter      = $Counter.val();
            Counter--;

             // set new counter
            $Counter.val(Counter);
        }

        if ($Destination){
            $Destination.remove();

            Param['Counter'] = Counter;
            Core.App.Publish('Znuny.Form.Generic.Remove', [Param]);
        }


        return false;
    };

    /**
     * @name Restore
     * @memberof Znuny.Form.Generic
     * @function
     * @returns {Boolean} Returns false
     * @param {Object} RestoreElement - Object of the clicked restore element
     *
     * data-formelement-restore                                              # if empty use following data attributes:
     * data-formelement-restore-destination-name='AdditionalDFStorage'       # name of restore destination element
     *
     * @description
     *      This function restores the values list
     */
    TargetNS.Restore = function(RestoreElement) {
        var Param = {},
            DestinationName,
            $Destination;

        $.each(RestoreElement.data(), function(Key, Value) {
            Param[Key] = Value || '';
        });

        DestinationName = Param['formelementRestoreDestinationName'];
        $Destination    = $('[data-formelement-restore-destination="' + DestinationName + '"]');

        if (RestoreElements[DestinationName] && $Destination){
            $Destination.html(RestoreElements[DestinationName].html());
        }
        Core.UI.InputFields.Activate();
        return false;
    };

    Core.Init.RegisterNamespace(TargetNS, 'APP_MODULE');

    return TargetNS;
}(Znuny.Form.Generic || {}));
