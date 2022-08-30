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
 * @namespace Core.UI.DnD
 * @memberof Core.UI
 * @author OTRS AG
 * @description
 *      Drag and Drop.
 */
Core.UI.DnD = (function (TargetNS) {

    if (!Core.Debug.CheckDependency('Core.UI.DnD', '$([]).sortable', 'jQuery UI sortable')) {
        return false;
    }

    /**
     * @name Sortable
     * @memberof Core.UI.DnD
     * @function
     * @param {jQueryObject} $Elements - The elements which should be made sortable.
     * @param {Object} Options - Hash which contains the config options.
     * @param {String} [Options.Handle] - To restrict the dragging start to a sub-element (e.g. a h2).
     * @param {String} [Options.Containment] - Constrains dragging to within the bounds of the specified element.
     *                                         Can be a DOM element, 'parent', 'document', 'window', or a jQuery selector.
     * @param {String} [Options.Axis] - If defined, the items can be dragged only horizontally or vertically. Possible values:'x', 'y'.
     * @param {String} [Options.Items] - To restrict the draggable child elements with a selector.
     * @param {String} [Options.Placeholder] - Class to give to the placeholder div which indicates the drop area.
     * @param {String} [Options.Tolerance] - This is the way the reordering behaves during drag.
     *                                       Possible values: 'intersect', 'pointer'. In some setups, 'pointer' is more natural.
     *                                       intersect: draggable overlaps the droppable at least 50% (this is the default value).
     *                                       pointer: mouse pointer overlaps the droppable.
     * @param {Number} [Options.Opacity] - Defines the opacity of the helper while sorting. From 0.01 to 1.
     * @param {Number} [Options.Opacity] - Only start visible dragging after a certain minimum pixel distance.
     * @description
     *      This function initializes the sortable nature on the specified Elements.
     *      Child elements with the class "CanDrag" can then be sorted with Drag and Drop.
     * @example
        Core.UI.DnD.Sortable(
        $(".SidebarColumn"),
            {
                Handle: '.Header h2',
                Containment: '.SidebarColumn',
                Axis: 'y',
                Items: '.CanDrag',
                Placeholder: 'DropPlaceholder',
                Tolerance: 'pointer',
                Distance: 15,
                Opacity: 0.9
            }
        );
     */
    TargetNS.Sortable = function ($Elements, Options) {
        $Elements.sortable({
            handle: Options.Handle,
            items: Options.Items,
            axis: Options.Axis,
            placeholder: Options.Placeholder,
            helper: Options.Helper,
            containment: Options.Containment,
            forcePlaceholderSize: true,
            distance: Options.Distance,
            opacity: Options.Opacity,
            tolerance: Options.Tolerance,
            update: Options.Update
        });
    };

    return TargetNS;
}(Core.UI.DnD || {}));
