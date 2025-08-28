// --
// Copyright (C) 2021 Znuny GmbH, https://znuny.org/
// --
// This software comes with ABSOLUTELY NO WARRANTY. For details, see
// the enclosed file COPYING for license information (AGPL). If you
// did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
// --

"use strict";

var Core   = Core || {};
Core.Agent = Core.Agent || {};

/**
 * @namespace
 * @exports TargetNS as Core.Agent.TicketProcessCategory
 * @description
 *      This namespace contains the special functions for TicketProcessCategory.
 */
Core.Agent.TicketProcessCategory = (function (TargetNS) {

    /**
    * @private
    * @name Init
    * @memberof Core.Agent.TicketProcessCategory
    * @function
    * @description
    *      This function initializes the TicketProcessCategory.
    */
    TargetNS.Init = function () {
        TargetNS.InitBindings();
        TargetNS.InitFilter();
        TargetNS.InitFavourite();
    }

    /**
    * @private
    * @name InitBindings
    * @memberof Core.Agent.TicketProcessCategory
    * @function
    * @description
    *      This function initializes the bindings for TicketProcessCategory.
    */
    TargetNS.InitBindings = function () {
        $('a.AsPopup').on('click', function () {
            Core.UI.Popup.OpenPopup($(this).attr('href'), 'TicketProcess');

            return false;
        });
    }

        /**
    * @private
    * @name InitFilter
    * @memberof Core.Agent.TicketProcessCategory
    * @function
    * @description
    *      This function initializes the filter for TicketProcessCategory.
    */
    TargetNS.InitFilter = function () {

        // Filter processes by category.
        TargetNS.InitCategoryFilter();

        $("#Filter").on('click', function() {
            $(".CategoryFilter").removeClass('Active');
            $(".ItemListGrid").removeClass('Hidden');
            $(".ItemListGrid").show();
        });

        // Filter processes by search.
        Core.UI.Table.InitTableFilter($('#Filter'), $('.Filterable'), undefined, true);
    }

    /**
    * @private
    * @name InitCategoryFilter
    * @memberof Core.Agent.TicketProcessCategory
    * @function
    * @description
    *      This function initializes the category filter for TicketProcessCategory.
    */
    TargetNS.InitCategoryFilter = function () {
        $(".CategoryFilter").on('click', function() {
            var Value = $(this).data('category'),
                Category = 1;

            if (Value == 'IsFavourite') {
                Category = 0;
            }

            $(".CategoryFilter").removeClass('Active');
            $(".ItemListGrid").removeClass('Hidden');
            $(".ItemListGrid").show();

            $("#Filter").val('');

            Filter(Value, Category);
            $(this).addClass('Active');
        });
    }

    function Filter (Value, Category) {
        var AllHidden = 1;

        Value    = Value || '';
        Category = Category || 0;

        // Hide all processes and show only the ones that match the search.
        $(".Preview").filter(function() {
            Value = Value.toLowerCase() || '';

            if (Category) {
                $(this).parent().toggle($(this).find('.Category').text().toLowerCase().indexOf(Value) > -1);
            } else {
                $(this).parent().toggle($(this).text().toLowerCase().indexOf(Value) > -1);
            }
        });

        // Check if all processes are hidden.
        $(".ItemListGrid").children().each(function() {
            if (!$(this).is(":hidden")) {
                AllHidden = 0;

                return false;
            }
        });

        // Add 'No process found.' if all processes are hidden.
        if (AllHidden) {
            $(".FilterMessageWidget").removeClass('Hidden');
            $(".ItemListGrid").addClass('Hidden');
        } else {
            $(".FilterMessageWidget").addClass('Hidden');
            $(".ItemListGrid").removeClass('Hidden');
        }

        return true;
    }

    /**
    * @private
    * @name InitFavourite
    * @memberof Core.Agent.TicketProcessCategory
    * @function
    * @description
    *      This function handles all about the Favourites-functionality on TicketProcessCategory.
    */
        TargetNS.InitFavourite = function () {
        // Use event delegation to handle dynamically added elements
        $(document).off('click.AddFavourite').on('click.AddFavourite', '.AddFavourite', function(Event) {
            var $TriggerObj = $(this),
                ProcessID = $(this).data('id'),
                Favourites = Core.Config.Get('Favourites') || [];

            if ($TriggerObj.hasClass('Clicked')) {
                return false;
            }

            Event.stopPropagation();
            $(this).addClass('Clicked');

            Favourites.push(ProcessID);

            // Remove duplicates
            Favourites = Favourites.filter(function(item, index, self) {
                return self.indexOf(item) === index;
            });

            // Update the user preferences
            Core.Agent.PreferencesUpdate('TicketProcessCategoryFavourites', JSON.stringify(Favourites), function() {
                $TriggerObj.addClass('Clicked');

                // Add the category filter if it does not exist yet
                if (!$('.SidebarColumn .Content .Favourites').length) {
                    $('.SidebarColumn .Content').prepend('<a href="#" class="CategoryFilter Level-1 Favourites" data-category="IsFavourite"><i class="fa fa-star"></i> ' + Core.Language.Translate('Favourites') + ' <i class="fa fa-star"></i></a>');
                    // Re-initialize category filter to bind the new element
                    TargetNS.InitCategoryFilter();
                }

                // Simple DOM manipulation without complex animations

                // Add the category filter if it does not exist yet
                if (!$('.SidebarColumn .Content .Favourites').length) {
                    $('.SidebarColumn .Content').prepend('<a href="#" class="CategoryFilter Level-1 Favourites" data-category="IsFavourite"><i class="fa fa-star"></i> ' + Core.Language.Translate('Favourites') + ' <i class="fa fa-star"></i></a>');
                    // Re-initialize category filter to bind the new element
                    TargetNS.InitCategoryFilter();
                }

                // Simple class changes without animations
                $TriggerObj.addClass('RemoveFavourite');
                $TriggerObj.removeClass('AddFavourite');
                $TriggerObj.closest('li').addClass('IsFavourite');
                $TriggerObj.closest('li').find('.Information').append('<span class="IsFavourite InvisibleText">IsFavourite</span>');


                Core.Config.Set('Favourites', Favourites);

            });

            return false;
        });

        $(document).off('click.RemoveFavourite').on('click.RemoveFavourite', '.RemoveFavourite', function() {
            var $TriggerObj = $(this),
                ProcessID = $(this).data('id'),
                Favourites = Core.Config.Get('Favourites') || [];

            // Remove the process from the favourites list
            Favourites = $.grep(Favourites, function(num) {
                return num.toString() !== ProcessID.toString();
            });

            Core.Agent.PreferencesUpdate('TicketProcessCategoryFavourites', JSON.stringify(Favourites), function() {
                $TriggerObj.find('i').fadeOut(function() {
                    $(this).closest('li').find('.RemoveFavourite').append('<i class="fa fa-check" style="display: none;"></i>').find('i.fa-check').fadeIn().delay(1000).fadeOut(function() {
                        $(this)
                            .closest('.RemoveFavourite')
                            .hide()
                            .find('i.fa-check')
                            .remove();
                        });

                    $(this).hide();
                    $TriggerObj.addClass('AddFavourite');
                    $TriggerObj.removeClass('RemoveFavourite');
                    $TriggerObj.removeClass('Clicked'); // Remove the Clicked class
                    $TriggerObj.closest('li').removeClass('IsFavourite');
                    $TriggerObj.closest('li').find('.Information').find('.IsFavourite').remove();

                    $TriggerObj.find('i.fa-star').show();
                    $TriggerObj.find('i.fa-star-o').show();

                    // Remove the category filter if there are no favourites left
                    if (Favourites.length === 0) {
                        $('.SidebarColumn .Content .Favourites').remove();
                    }

                    Core.Config.Set('Favourites', Favourites);
                });
            });

            return false;
        });
    }

    Core.Init.RegisterNamespace(TargetNS, 'FINISH');

    return TargetNS;

}(Core.Agent.TicketProcessCategory || {}));
