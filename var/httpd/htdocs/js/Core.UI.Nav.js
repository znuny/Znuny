// --
// Copyright (C) 2021 Znuny GmbH, https://znuny.org/
// --
// This software comes with ABSOLUTELY NO WARRANTY. For details, see
// the enclosed file COPYING for license information (AGPL). If you
// did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
// --

var Core = Core || {};
Core.UI = Core.UI || {};

/**
 * @namespace Core.UI.Nav
 * @memberof Core.UI
 * @description
 *  Turns a flat list of items (with hierarchical paths) into a single-row nav bar
 *  with dropdowns and an active-path highlight. The same code is used for queues,
 *  services, or any other view that provides the same markup contract.
 *
 *  Markup (inside a .HierarchicalNav.level-filter-view host; may also use .QueueOverview / .ServiceOverview for legacy styling):
 *  - A hidden <ul> with all links, either
 *    - <ul class="HierarchicalNavAllItems Hidden">, or
 *    - <ul id="QueueNavAllQueues" class="Hidden"> (queue overview legacy)
 *  - On each <a>: optional data-item-path, or legacy data-queue-path; else the visible name is the path.
 *  - On the host: data-selected-path (or legacy data-selected-queue) for the active branch.
 *  - Optional: original flat list in .NavOverviewList (hidden by CSS when nav replaces content).
 */
Core.UI.Nav = (function (TargetNS) {

    /**
     * @private
     * Hierarchical path separator in names (e.g. IT::Service::A).
     */
    var PathSeparator = '::';

    /**
     * Inits all hierarchical nav widgets on the page that have a non-empty source list.
     * Queue overview continues to work with .QueueOverview and #QueueNavAllQueues.
     */
    TargetNS.Init = function () {

        $('.level-filter-view, .nav-layout-side').filter(function () {
            // $Widget is the current widget element in this iteration.
            var $Widget = $(this);
            var NavLayout = $Widget.attr('data-nav-layout');

            // Top keeps the server-rendered level list.
            // TopHover builds the hover bar. Sidebar builds the tree.
            // Widgets without the attribute (service view) stay on the previous path.
            if (NavLayout === 'Sidebar') {
                if (!$Widget.find('.Content').first().length) {
                    return false;
                }
                return !!GetSourceList($Widget).find('li a').length;
            }
            if (NavLayout && NavLayout !== 'TopHover') {
                return false;
            }
            if (!GetSourceList($Widget).find('li a').length) {
                return false;
            }
            if (!$Widget.find('.Content').first().length) {
                return false;
            }
            return true;
        }).each(function () {
            var $Widget = $(this);

            if ($Widget.attr('data-nav-layout') === 'Sidebar') {
                RunSideWidget($Widget);
                return;
            }
            RunOneWidget($Widget);
        });
    };
    /**
     * @private
     * Build a tree from a flat list. Parent-child is determined by PathSeparator in the path.
     * @param {Object[]} items Each: Path, Name, Href, Count
     * @return {Object[]} root nodes
     */
    function BuildTree(items) {
        var NodeMap = {};
        var Roots   = [];

        $.each(items, function (i, Item) {
            NodeMap[Item.Path] = {
                Path:     Item.Path,
                Name:     Item.Name,
                Href:     Item.Href,
                Count:    Item.Count,
                Children: []
            };
        });

        $.each(items, function (i, Item) {
            var Node       = NodeMap[Item.Path];
            var Parts      = Item.Path.split(PathSeparator);
            var ParentPath = '';

            if (Parts.length <= 1) {
                Roots.push(Node);
            } else {
                ParentPath = Parts.slice(0, -1).join(PathSeparator);
                if (NodeMap[ParentPath]) {
                    NodeMap[ParentPath].Children.push(Node);
                } else {
                    Roots.push(Node);
                }
            }
        });

        return Roots;
    }

    /**
     * @private
     * @param {jQuery} $A anchor from the source list
     * @return {String} full path
     */
    function GetItemPath($A) {
        var P = $A.attr('data-item-path');
        if (P === undefined || P === null || P === '') {
            P = $A.attr('data-queue-path');
        }
        return P;
    }

    /**
     * @private
     * @param {jQuery} $Widget
     * @return {jQuery} ul containing all flat links, or empty
     */
    function GetSourceList($Widget) {
        var $ul = $Widget.find('ul.HierarchicalNavAllItems');
        if (!$ul.length) {
            $ul = $Widget.find('#QueueNavAllQueues');
        }
        return $ul;
    }

    /**
     * @private
     * @param {jQuery} $Widget
     * @return {String} selected full path
     */
    function GetSelectedPath($Widget) {
        var S = $Widget.attr('data-selected-path');
        if (S === undefined || S === null || S === '') {
            S = $Widget.attr('data-selected-queue');
        }
        return S || '';
    }

    /**
     * @private
     * @param {Object[]} Nodes
     * @param {String} Path
     * @return {Object|null}
     */
    function FindNodeByPath(Nodes, Path) {
        var i, Found;

        for (i = 0; i < Nodes.length; i++) {
            if (Nodes[i].Path === Path) {
                return Nodes[i];
            }
            Found = FindNodeByPath(Nodes[i].Children, Path);
            if (Found) {
                return Found;
            }
        }
        return null;
    }

    /**
     * @private
     * Siblings of the selected item (children of its parent).
     * @param {Object[]} Roots
     * @param {String} SelectedPath
     * @return {Object[]}
     */
    function GetSiblingNodes(Roots, SelectedPath) {
        var Parts, ParentPath, ParentNode;

        if (!SelectedPath || SelectedPath.indexOf(PathSeparator) === -1) {
            return [];
        }

        Parts      = SelectedPath.split(PathSeparator);
        ParentPath = Parts.slice(0, -1).join(PathSeparator);
        ParentNode = FindNodeByPath(Roots, ParentPath);

        if (!ParentNode) {
            return [];
        }
        return ParentNode.Children;
    }

    /**
     * @private
     * @param {Object} Node
     * @return {jQuery}
     */
    function RenderPillLink(Node) {
        return $('<a class="nav-link"></a>')
            .attr('href', Node.Href)
            .append($('<span></span>').text(Node.Name))
            .append(' ')
            .append($('<span class="nav-count"></span>').text(Node.Count));
    }

    function RenderSubBar(Siblings, SelectedPath) {
        var $Sub, $Item;

        if (!Siblings.length) {
            return null;
        }

        $Sub = $('<ul class="nav-sub-bar"></ul>');

        $.each(Siblings, function (i, Node) {
            var HasChildren = Node.Children.length > 0;
            var $Toggle;

            $Item = $('<li class="nav-sub-item nav-item"></li>');
            if (Node.Path === SelectedPath) {
                $Item.addClass('nav-active-leaf');
            }

            $Item.append(RenderPillLink(Node));

            if (HasChildren) {
                $Toggle = $('<button class="nav-toggle" type="button"></button>')
                    .append($('<i class="fa fa-caret-down nav-caret"></i>'));
                $Item.addClass('nav-has-dropdown');
                $Item.append(
                    $('<div class="nav-menu-trigger"></div>').append($Toggle)
                );
                $Item.append(RenderDropdown(Node.Children));
            }

            $Sub.append($Item);
        });

        return $Sub;
    }

    function RenderDropdown(Children) {
        var $Ul = $('<ul class="nav-dropdown"></ul>');

        $.each(Children, function (i, Node) {
            var HasChildren = Node.Children.length > 0;
            var $Li         = $('<li></li>').addClass(
                'nav-dropdown-item' + (HasChildren ? ' nav-has-sub' : '')
            );
            var $A          = $('<a></a>')
                .attr('href', Node.Href)
                .append($('<span></span>').text(Node.Name))
                .append(' ')
                .append($('<span class="nav-count"></span>').text(Node.Count));
            var $Toggle;

            $Li.append($A);

            if (HasChildren) {
                $Toggle = $('<button class="nav-toggle" type="button"></button>')
                    .append($('<i class="fa fa-caret-right nav-caret"></i>'));
                $Li.append(
                    $('<div class="nav-menu-trigger"></div>')
                        .append($Toggle)
                        .append(RenderDropdown(Node.Children))
                );
            }

            $Ul.append($Li);
        });

        return $Ul;
    }

    function RenderNavBar(Roots) {
        var $Nav = $('<ul class="nav-bar"></ul>');

        $.each(Roots, function (i, Node) {
            var HasChildren = Node.Children.length > 0;
            var $Item       = $('<li class="nav-item"></li>');
            var $Link;
            var $Toggle;

            if (i > 0) {
                $Nav.append($('<li class="nav-sep"></li>'));
            }

            if (HasChildren) {
                $Link = $('<a class="nav-link"></a>')
                    .attr('href', Node.Href)
                    .append($('<span></span>').text(Node.Name))
                    .append(' ')
                    .append($('<span class="nav-count"></span>').text(Node.Count));

                $Toggle = $('<button class="nav-toggle" type="button"></button>')
                    .append($('<i class="fa fa-caret-down nav-caret"></i>'));

                $Item.addClass('nav-has-dropdown');
                $Item.append($Link);
                $Item.append(
                    $('<div class="nav-menu-trigger"></div>').append($Toggle)
                );
                $Item.append(RenderDropdown(Node.Children));
            } else {
                $Link = $('<a class="nav-link"></a>').attr('href', Node.Href);
                $Link
                    .append($('<span></span>').text(Node.Name))
                    .append(' ')
                    .append($('<span class="nav-count"></span>').text(Node.Count));
                $Item.append($Link);
            }

            $Nav.append($Item);
        });

        return $Nav;
    }

    function MarkActivePath(SelectedPath, $Content) {
        var Parts;

        if (!SelectedPath) {
            return;
        }

        Parts = SelectedPath.split(PathSeparator);

        $Content.find('.nav-bar > .nav-item').each(function () {
            var $Item = $(this);
            var Name;

            if ($Item.children('.nav-link').length) {
                Name = $Item.children('.nav-link').find('span:first').text().trim();
            } else {
                Name = '';
            }

            if (Name === Parts[0]) {
                if (Parts.length === 1) {
                    $Item.addClass('nav-active-leaf');
                } else {
                    $Item.addClass('nav-active-root');
                }
            }
        });

        $Content.find('.nav-dropdown-item a').each(function () {
            var $A                = $(this);
            var PathParts         = [];
            var $NavItem;
            var RootName;
            var ReconstructedPath;

            $A.parents('.nav-dropdown-item').addBack('.nav-dropdown-item').each(function () {
                PathParts.unshift($(this).children('a').find('span:first').text());
            });

            $NavItem = $A.closest('.nav-bar > .nav-item');
            if ($NavItem.length) {
                RootName = $NavItem.children('.nav-link').find('span:first').text().trim();
                PathParts.unshift(RootName);
            }

            ReconstructedPath = PathParts.join(PathSeparator);
            if (ReconstructedPath === SelectedPath) {
                $A.addClass('nav-active-leaf');
                $A.closest('.nav-dropdown-item').addClass('nav-active-row');
                $A.closest('.nav-bar > .nav-item').addClass('nav-active-root');
            }
        });
    }

    function EnhanceBreadcrumb(FlatItems, $Widget) {
        var $BreadCrumbDiv = $Widget
            .closest('.OverviewBox')
            .find('h1 .overview-breadcrumb');
        var PathToHref     = {};
        var IndicatorText  = '';
        var SegmentNames   = [];
        var $Ul;

        if (!$BreadCrumbDiv.length) {
            $BreadCrumbDiv = $('.OverviewBox h1 .overview-breadcrumb').first();
        }
        if (!$BreadCrumbDiv.length) {
            return;
        }

        $.each(FlatItems, function (i, F) {
            PathToHref[F.Path] = F.Href;
        });

        // Text after the breadcrumb segments (e.g. "(including subqueues)" or a similar sub-items hint)
        $BreadCrumbDiv.contents().filter(function () {
            return this.nodeType === 3;
        }).each(function () {
            IndicatorText += $.trim(this.textContent);
        });

        $BreadCrumbDiv.children('div').each(function (idx) {
            if (idx % 2 === 0) {
                SegmentNames.push($(this).text());
            }
        });

        if (!SegmentNames.length) {
            return;
        }

        $Ul = $('<ul class="HierarchicalNavBreadCrumb"></ul>');

        $.each(SegmentNames, function (i, Segment) {
            var $Li         = $('<li></li>');
            var PartialPath = SegmentNames.slice(0, i + 1).join(PathSeparator);
            var IsLast      = (i === SegmentNames.length - 1);
            var Href;

            if (i > 0) {
                $Li.append($('<i class="fa fa-angle-right"></i>'));
            }

            if (IsLast) {
                $Li.append($('<span></span>').text(Segment));
                if (IndicatorText) {
                    $Li.append(
                        $('<span class="nav-subitems"></span>').text('\u00a0' + IndicatorText)
                    );
                }
            } else {
                Href = PathToHref[PartialPath] || '#';
                $Li.append($('<a></a>').attr('href', Href).text(Segment));
            }

            $Ul.append($Li);
        });

        $BreadCrumbDiv.empty().append($Ul);
    }

    /**
     * @private
     * Right edge of the viewport, or of a clipping ancestor, whichever is tighter.
     * @param {Element} Element
     * @return {Number}
     */
    function VisibleRightLimit(Element) {
        var Limit = window.innerWidth;
        var Node  = Element.parentElement;
        var Style;
        var Overflow;

        while (Node && Node !== document.body) {
            Style    = window.getComputedStyle(Node);
            Overflow = Style.overflowX;

            if (Overflow === 'hidden' || Overflow === 'auto' || Overflow === 'scroll') {
                Limit = Math.min(Limit, Node.getBoundingClientRect().right);
            }
            Node = Node.parentElement;
        }

        return Limit;
    }

    /**
     * @private
     * @param {jQuery} $Dropdown
     * @param {Object} Rect
     * @return {Boolean}
     */
    function OverlapsAncestorMenu($Dropdown, Rect) {
        var Overlaps = false;

        $Dropdown.parents('.nav-dropdown').each(function () {
            var Other = this.getBoundingClientRect();

            if (Rect.right > Other.left + 2 && Rect.left < Other.right - 2) {
                Overlaps = true;
                return false;
            }
        });

        return Overlaps;
    }

    /**
     * @private
     * Open a dropdown to the left when it would leave the visible area or cover another open menu.
     * @param {jQuery} $Dropdown
     */
    function AlignDropdown($Dropdown) {
        var WasHidden;
        var Rect;
        var FlippedRect;
        var Limit;
        var $ParentMenu;
        var ParentLeft;
        var Extra;
        var MarginRight;

        if (!$Dropdown || !$Dropdown.length) {
            return;
        }

        $Dropdown.removeClass('nav-open-left');
        $Dropdown.css('marginRight', '');
        WasHidden = $Dropdown.css('display') === 'none';
        if (WasHidden) {
            $Dropdown.css('display', 'block');
        }

        Rect  = $Dropdown[0].getBoundingClientRect();
        Limit = VisibleRightLimit($Dropdown[0]);

        if (Rect.width && (Rect.right > Limit - 8 || OverlapsAncestorMenu($Dropdown, Rect))) {
            $Dropdown.addClass('nav-open-left');
            FlippedRect = $Dropdown[0].getBoundingClientRect();

            // Sit beside the parent menu, not on top of its rows.
            $ParentMenu = $Dropdown.parents('.nav-dropdown').first();
            if ($ParentMenu.length) {
                ParentLeft = $ParentMenu[0].getBoundingClientRect().left;
                Extra      = FlippedRect.right - ParentLeft + 4;
                if (Extra > 0) {
                    $Dropdown.css('marginRight', Extra + 'px');
                    FlippedRect = $Dropdown[0].getBoundingClientRect();
                }
            }

            if (FlippedRect.left < 8) {
                MarginRight = parseFloat($Dropdown.css('marginRight')) || 0;
                $Dropdown.css('marginRight', Math.max(0, MarginRight - (8 - FlippedRect.left)) + 'px');
                FlippedRect = $Dropdown[0].getBoundingClientRect();
            }

            if (FlippedRect.left < 8 && FlippedRect.left < (Limit - Rect.right)) {
                $Dropdown.removeClass('nav-open-left');
                $Dropdown.css('marginRight', '');
            }
        }

        if (WasHidden) {
            $Dropdown.css('display', '');
        }
    }

    /**
     * @private
     * Top-level menu hangs off the pill. Nested menus hang off the arrow trigger.
     * @param {jQuery} $Trigger
     * @return {jQuery}
     */
    function DropdownHost($Trigger) {
        if ($Trigger.children('.nav-dropdown').length) {
            return $Trigger;
        }

        return $Trigger.closest('.nav-has-dropdown');
    }

    /**
     * @private
     * @param {jQuery} $Host
     */
    function CloseDropdownHost($Host) {
        var $Dropdown = $Host.children('.nav-dropdown');

        $Host.removeClass('nav-open');
        $Dropdown.removeData('NavEntered');
        $Dropdown.find('.nav-open').removeClass('nav-open');
        $Dropdown.find('.nav-dropdown').removeData('NavEntered');
    }

    /**
     * @private
     * @param {jQuery} $Widget
     * @param {jQuery} $Host
     */
    function CloseUnrelatedDropdowns($Widget, $Host) {
        $Widget.find('.nav-open').each(function () {
            var $Open = $(this);

            if ($Open.is($Host)) {
                return;
            }
            if ($.contains($Open[0], $Host[0])) {
                return;
            }
            CloseDropdownHost($Open);
        });
    }

    /**
     * @private
     * Arrow hover opens the submenu and keeps it open until the pointer
     * has entered that submenu and left it again.
     * @param {jQuery} $Widget
     */
    function BindDropdownPlacement($Widget) {
        $Widget.off('mouseenter.NavDropdown mouseleave.NavDropdown');
        $Widget.on('mouseenter.NavDropdown', '.nav-menu-trigger', function () {
            var $Host     = DropdownHost($(this));
            var $Dropdown = $Host.children('.nav-dropdown');

            if (!$Dropdown.length) {
                return;
            }

            CloseUnrelatedDropdowns($Widget, $Host);
            $Dropdown.data('NavEntered', 0);
            $Host.addClass('nav-open');
            AlignDropdown($Dropdown);
        });
        $Widget.on('mouseenter.NavDropdown', '.nav-dropdown', function () {
            $(this).data('NavEntered', 1);
        });
        $Widget.on('mouseleave.NavDropdown', '.nav-dropdown', function () {
            var $Dropdown = $(this);
            var $Host;

            if (!$Dropdown.data('NavEntered')) {
                return;
            }

            $Host = $Dropdown.parent();
            if (!$Host.hasClass('nav-open')) {
                $Host = $Dropdown.closest('.nav-open');
            }
            CloseDropdownHost($Host);
        });
    }

    /**
     * @private
     * @param {jQuery} $Source
     * @return {Object[]}
     */
    function CollectItems($Source) {
        var FlatItems = [];

        $Source.find('li a').each(function () {
            var $A      = $(this);
            var RawText = $A.text().trim();
            var CountM  = RawText.match(/\(([^)]+)\)$/);
            var Count   = CountM ? CountM[1] : '0';
            var Name    = RawText.replace(/\s*\([^)]*\)$/, '').trim();
            var Path    = GetItemPath($A) || Name;
            var Classes = ($A.attr('class') || '').split(/\s+/);

            FlatItems.push({
                Path:    Path,
                Name:    Name,
                Href:    $A.attr('href'),
                Count:   Count,
                Classes: $.grep(Classes, function (ClassName) {
                    return !!ClassName;
                })
            });
        });

        return FlatItems;
    }

    /**
     * @private
     * @param {jQuery} $Widget
     * @return {Object}
     */
    function ReadSideState($Widget) {
        var Raw = $Widget.attr('data-nav-state') || '';
        var State;

        if (!Raw) {
            return {
                open:      [],
                collapsed: 0
            };
        }

        try {
            State = JSON.parse(Raw);
        }
        catch (Error) {
            State = null;
        }

        if (!State || !$.isArray(State.open)) {
            return {
                open:      [],
                collapsed: 0
            };
        }

        // "0" is truthy in JS and falsy in Perl. Only 1 / "1" is collapsed.
        return {
            open:      State.open,
            collapsed: (State.collapsed === 1 || State.collapsed === '1' || State.collapsed === true) ? 1 : 0
        };
    }

    /**
     * @private
     * Ancestors of the selected item stay open so the current queue is visible.
     * @param {String} SelectedPath
     * @param {String[]} OpenPaths
     * @return {Object} map path -> 1
     */
    function OpenPathMap(SelectedPath, OpenPaths) {
        var Map = {};
        var Parts;
        var Index;

        $.each(OpenPaths, function (i, Path) {
            if (Path) {
                Map[Path] = 1;
            }
        });

        if (!SelectedPath) {
            return Map;
        }

        Parts = SelectedPath.split(PathSeparator);
        for (Index = 1; Index < Parts.length; Index++) {
            Map[Parts.slice(0, Index).join(PathSeparator)] = 1;
        }

        return Map;
    }

    /**
     * @private
     * @param {Object[]} Nodes
     * @param {String} SelectedPath
     * @param {Object} OpenMap
     * @param {Number} Depth
     * @return {jQuery}
     */
    function RenderSideNodes(Nodes, SelectedPath, OpenMap, Depth) {
        var $List = $('<ul class="nav-side-children"></ul>');

        if (!Depth) {
            $List = $('<ul class="nav-side-tree-list" role="tree"></ul>');
        }
        else {
            $List.attr('role', 'group');
        }

        $.each(Nodes, function (i, Node) {
            var HasChildren = Node.Children.length > 0;
            var IsOpen      = !!OpenMap[Node.Path];
            var IsCurrent   = Node.Path === SelectedPath;
            var $Node       = $('<li class="nav-side-node" role="treeitem"></li>');
            var $Row        = $('<div class="nav-side-row"></div>');
            var $Link       = $('<a class="nav-side-link"></a>');
            var $Toggle;

            $Node.attr('data-path', Node.Path);
            $Node.attr('aria-level', Depth + 1);
            $Row.css('paddingLeft', (Depth * 16) + 'px');

            if (HasChildren) {
                $Toggle = $('<button type="button" class="nav-side-toggle"></button>')
                    .attr('aria-label', IsOpen ? Core.Language.Translate('Collapse') : Core.Language.Translate('Expand'))
                    .append($('<i class="fa fa-caret-right nav-caret"></i>'));
                $Node.attr('aria-expanded', IsOpen ? 'true' : 'false');
                if (IsOpen) {
                    $Node.addClass('is-open');
                }
            }
            else {
                $Toggle = $('<span class="nav-side-toggle nav-side-toggle-spacer"></span>');
            }

            $Link.attr('href', Node.Href);
            if (Node.Classes && Node.Classes.length) {
                $Link.addClass(Node.Classes.join(' '));
            }
            if (IsCurrent) {
                $Link.addClass('nav-side-current');
                $Node.addClass('nav-side-current');
            }
            $Link.append($('<span class="nav-side-name"></span>').text(Node.Name));
            $Link.append($('<span class="nav-side-count"></span>').text('(' + Node.Count + ')'));

            $Row.append($Toggle).append($Link);
            $Node.append($Row);

            if (HasChildren) {
                $Node.append(RenderSideNodes(Node.Children, SelectedPath, OpenMap, Depth + 1));
            }

            $List.append($Node);
        });

        return $List;
    }

    /**
     * @private
     * @param {jQuery} $Widget
     */
    function SaveSideState($Widget) {
        var Open = [];
        var Collapsed = $Widget.closest('.NavLayout').hasClass('IsCollapsed') ? 1 : 0;
        var State;

        if ($Widget.find('.nav-side-filter').val()) {
            return;
        }

        $Widget.find('.nav-side-node.is-open').each(function () {
            Open.push($(this).attr('data-path'));
        });

        State = JSON.stringify({
            open:      Open,
            collapsed: Collapsed
        });

        $Widget.attr('data-nav-state', State);

        if (Core.Config.Get('DemoSystem')) {
            return;
        }

        Core.Agent.PreferencesUpdate($Widget.attr('data-nav-state-key') || 'UserNavLayoutQueueState', State);
    }

    /**
     * @private
     * @param {jQuery} $Widget
     */
    function ScheduleSideSave($Widget) {
        var Timer = $Widget.data('NavSaveTimer');

        if (Timer) {
            window.clearTimeout(Timer);
        }

        $Widget.data('NavSaveTimer', window.setTimeout(function () {
            SaveSideState($Widget);
        }, 400));
    }

    /**
     * @private
     * @param {jQuery} $Widget
     * @param {String} Query
     */
    function FilterSideTree($Widget, Query) {
        var Needle = $.trim(Query).toLowerCase();

        $Widget.find('.nav-side-node').removeClass('is-filter-hidden is-filter-open');

        if (!Needle) {
            return;
        }

        $Widget.find('.nav-side-node').each(function () {
            var $Node = $(this);
            var Name  = $Node.children('.nav-side-row').find('.nav-side-name').text().toLowerCase();
            var Path  = ($Node.attr('data-path') || '').toLowerCase();
            var Match = Name.indexOf(Needle) !== -1 || Path.indexOf(Needle) !== -1;

            if (!Match) {
                $Node.addClass('is-filter-hidden');
            }
        });

        $Widget.find('.nav-side-node').not('.is-filter-hidden').each(function () {
            $(this).parents('.nav-side-node').removeClass('is-filter-hidden').addClass('is-filter-open');
        });
    }

    /**
     * @private
     * @param {jQuery} $Node
     * @param {Boolean} Open
     */
    function SetSideNodeOpen($Node, Open) {
        var $Toggle = $Node.children('.nav-side-row').find('.nav-side-toggle');

        $Node.toggleClass('is-open', Open);
        $Node.attr('aria-expanded', Open ? 'true' : 'false');
        $Toggle.attr('aria-label', Open ? Core.Language.Translate('Collapse') : Core.Language.Translate('Expand'));
    }

    /**
     * @private
     * @param {jQuery} $Widget
     */
    function BindSideKeyboard($Widget) {
        $Widget.on('keydown.NavSide', '.nav-side-tree', function (Event) {
            var $Current = $(Event.target).closest('.nav-side-node');
            var $Rows    = $Widget.find('.nav-side-node:visible');
            var Index    = $Rows.index($Current);
            var $Next;

            if (!$Current.length || Index < 0) {
                return;
            }

            if (Event.which === 40 && Index < $Rows.length - 1) {
                $Next = $Rows.eq(Index + 1);
            }
            else if (Event.which === 38 && Index > 0) {
                $Next = $Rows.eq(Index - 1);
            }
            else if (Event.which === 39) {
                if ($Current.children('.nav-side-children').length && !$Current.hasClass('is-open')) {
                    SetSideNodeOpen($Current, true);
                    ScheduleSideSave($Widget);
                }
                else {
                    $Next = $Current.find('.nav-side-node:visible').first();
                }
            }
            else if (Event.which === 37) {
                if ($Current.hasClass('is-open')) {
                    SetSideNodeOpen($Current, false);
                    ScheduleSideSave($Widget);
                }
                else {
                    $Next = $Current.parent().closest('.nav-side-node');
                }
            }
            else {
                return;
            }

            if ($Next && $Next.length) {
                $Next.children('.nav-side-row').find('.nav-side-link').focus();
            }

            Event.preventDefault();
        });
    }

    /**
     * @private
     * Phones and tablets use an overlay. The desktop collapsed flag stays untouched.
     * @return {Boolean}
     */
    function IsMobileNav() {
        return window.matchMedia('(max-width: 1024px)').matches;
    }

    /**
     * @private
     * @param {jQuery} $Widget
     */
    function SetMobileSummary($Widget) {
        var $Header = $Widget.children('.Header');
        var $Summary = $Header.children('.nav-side-summary');
        var Selected = GetSelectedPath($Widget);
        var Name = '';

        if (!$Header.length) {
            return;
        }

        if (!$Summary.length) {
            $Summary = $('<span class="nav-side-summary"></span>');
            $Header.append($Summary);
        }

        if (Selected) {
            Name = Selected.split(PathSeparator).pop();
        }

        $Summary.text(Name);
    }

    /**
     * @private
     * @param {jQuery} $Widget
     */
    function SyncMobileChrome($Widget) {
        var $Layout = $Widget.closest('.NavLayout');
        var $Header = $Widget.children('.Header');
        var $Collapse = $Layout.children('.SidebarColumn').children('.nav-side-collapse');
        var Open;

        if (!$Layout.length || !$Header.length) {
            return;
        }

        if (!IsMobileNav()) {
            $Layout.removeClass('NavMobile NavMobileOpen');
            $Header.removeAttr('role');
            $Header.removeAttr('tabindex');
            $Header.removeAttr('aria-expanded');
            return;
        }

        $Layout.addClass('NavMobile');
        Open = $Layout.hasClass('NavMobileOpen');
        $Header.attr('role', 'button');
        $Header.attr('tabindex', '0');
        $Header.attr('aria-expanded', Open ? 'true' : 'false');
        $Collapse.attr('aria-expanded', Open ? 'true' : 'false');
        $Collapse.attr('aria-label', Open ? Core.Language.Translate('Collapse') : Core.Language.Translate('Expand'));
    }

    /**
     * @private
     * @param {jQuery} $Widget
     */
    function ToggleSideLayout($Widget) {
        var $Layout = $Widget.closest('.NavLayout');
        var $Collapse = $Layout.children('.SidebarColumn').children('.nav-side-collapse');
        var Collapsed;

        if (!$Layout.length) {
            return;
        }

        if (IsMobileNav()) {
            $Layout.toggleClass('NavMobileOpen');
            SyncMobileChrome($Widget);
            return;
        }

        $Layout.toggleClass('IsCollapsed');
        Collapsed = $Layout.hasClass('IsCollapsed');
        $Collapse.attr('aria-label', Collapsed ? Core.Language.Translate('Expand') : Core.Language.Translate('Collapse'));
        $Collapse.attr('aria-expanded', Collapsed ? 'false' : 'true');
        ScheduleSideSave($Widget);
    }

    /**
     * @private
     * Close the overlay from the backdrop, outside clicks, and Escape.
     */
    function BindMobileOnce() {
        if (TargetNS.MobileBound) {
            return;
        }

        TargetNS.MobileBound = 1;

        $(document).on('click.NavSideMobile', function (Event) {
            if (!IsMobileNav()) {
                return;
            }

            if ($(Event.target).closest('.NavLayout.NavMobileOpen > .SidebarColumn').length) {
                return;
            }

            $('.NavLayout.NavMobileOpen').each(function () {
                var $Layout = $(this);

                $Layout.removeClass('NavMobileOpen');
                SyncMobileChrome($Layout.find('.nav-layout-side').first());
            });
        });

        $(document).on('keydown.NavSideMobile', function (Event) {
            if (Event.which !== 27 || !IsMobileNav()) {
                return;
            }

            $('.NavLayout.NavMobileOpen').each(function () {
                var $Layout = $(this);

                $Layout.removeClass('NavMobileOpen');
                SyncMobileChrome($Layout.find('.nav-layout-side').first());
            });
        });
    }

    /**
     * @private
     * @param {jQuery} $Widget root host (.nav-layout-side)
     */
    function RunSideWidget($Widget) {
        var $Content = $Widget.find('.Content').first();
        var SelectedPath;
        var FlatItems;
        var Tree;
        var State;
        var OpenMap;
        var $Filter;
        var $Collapse;
        var $Trigger;
        var $Column;

        if (!$Content.length) {
            return;
        }

        FlatItems = CollectItems(GetSourceList($Widget));
        if (!FlatItems.length) {
            return;
        }

        SelectedPath = GetSelectedPath($Widget);
        Tree         = BuildTree(FlatItems);
        State        = ReadSideState($Widget);
        OpenMap      = OpenPathMap(SelectedPath, State.open);

        $Collapse = $('<button type="button" class="nav-side-collapse"></button>')
            .attr('aria-label', State.collapsed ? Core.Language.Translate('Expand') : Core.Language.Translate('Collapse'))
            .attr('title', Core.Language.Translate('Toggle sidebar'))
            .append($('<i class="fa fa-caret-left"></i>'));

        $Trigger = $('<div class="nav-side-trigger"></div>')
            .attr('title', Core.Language.Translate('Toggle sidebar'));

        $Column = $Widget.closest('.NavLayout').children('.SidebarColumn');
        if ($Column.length) {
            $Column.append($Collapse).append($Trigger);
        }

        $Filter = $('<input type="text" class="nav-side-filter" />')
            .attr('placeholder', Core.Language.Translate('Filter'))
            .attr('aria-label', Core.Language.Translate('Filter'));

        $Content.empty().append($Filter).append(
            $('<div class="nav-side-tree"></div>').append(RenderSideNodes(Tree, SelectedPath, OpenMap, 0))
        );

        $Widget.on('click.NavSide', '.nav-side-toggle', function (Event) {
            var $Node = $(this).closest('.nav-side-node');

            Event.preventDefault();
            SetSideNodeOpen($Node, !$Node.hasClass('is-open'));
            ScheduleSideSave($Widget);
        });

        $Collapse.on('click.NavSide', function (Event) {
            Event.preventDefault();
            Event.stopPropagation();
            ToggleSideLayout($Widget);
        });

        $Trigger.on('click.NavSide', function () {
            $Collapse.trigger('click');
        });

        $Widget.on('click.NavSide', '> .Header', function () {
            if (!IsMobileNav()) {
                return;
            }
            $Collapse.trigger('click');
        });

        $Widget.on('keydown.NavSide', '> .Header', function (Event) {
            if (!IsMobileNav()) {
                return;
            }
            if (Event.which !== 13 && Event.which !== 32) {
                return;
            }
            Event.preventDefault();
            $Collapse.trigger('click');
        });

        $Widget.on('input.NavSide', '.nav-side-filter', function () {
            FilterSideTree($Widget, $(this).val());
        });

        $(window).on('resize.NavSide', function () {
            SyncMobileChrome($Widget);
        });

        BindSideKeyboard($Widget);
        BindMobileOnce();
        SetMobileSummary($Widget);
        SyncMobileChrome($Widget);
        EnhanceBreadcrumb(FlatItems, $Widget);
    }

    /**
     * @private
     * @param {jQuery} $Widget root host (.level-filter-view with a source <ul> of links)
     */
    function RunOneWidget($Widget) {
        var $Content     = $Widget.find('.Content').first();
        var $Source;
        var SelectedPath;
        var FlatItems;
        var Tree;
        var $Nav;
        var $SubBar;

        if (!$Content.length) {
            return;
        }

        $Source = GetSourceList($Widget);
        if (!$Source.length) {
            return;
        }

        SelectedPath = GetSelectedPath($Widget);
        FlatItems    = CollectItems($Source);

        if (!FlatItems.length) {
            return;
        }

        Tree = BuildTree(FlatItems);
        $Nav = RenderNavBar(Tree);
        $SubBar = RenderSubBar(GetSiblingNodes(Tree, SelectedPath), SelectedPath);

        $Content.empty().append($Nav);
        if ($SubBar) {
            $Content.append($SubBar);
        }

        MarkActivePath(SelectedPath, $Content);
        EnhanceBreadcrumb(FlatItems, $Widget);
        BindDropdownPlacement($Widget);
    }

    Core.Init.RegisterNamespace(TargetNS, 'APP_MODULE');
    return TargetNS;

}(Core.UI.Nav || {}));
