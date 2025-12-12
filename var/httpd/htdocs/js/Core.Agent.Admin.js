// --
// Copyright (C) 2001-2021 OTRS AG, https://otrs.com/
// Copyright (C) 2021 Znuny GmbH, https://znuny.org/
// --
// This software comes with ABSOLUTELY NO WARRANTY. For details, see
// the enclosed file COPYING for license information (GPL). If you
// did not receive this file, see https://www.gnu.org/licenses/gpl-3.0.txt.
// --

"use strict";

var Core = Core || {};
Core.Agent = Core.Agent || {};
Core.Agent.Admin = Core.Agent.Admin || {};

/**
 * @namespace Core.Agent.Admin
 * @memberof Core.Agent.Admin
 * @author OTRS AG
 * @description
 *      This namespace contains the special module functions for the admin overview module.
 */
Core.Agent.Admin = (function (TargetNS) {
    /**
     * @name Init
     * @memberof Core.Agent.Admin
     * @function
     * @description
     *      Initializes Overview screen.
     */
    TargetNS.Init = function () {
        var Action = Core.Config.Get('Action'),
        Pattern = new RegExp('^Admin.', 'i');

        // run InitFavourite only for Admin action
        if (Action === "Admin") {
            TargetNS.InitFavourite();
        }

        // run InitFilterInvalidTableEntries for every Admin* action
        if (Pattern.test(Action) === true || Action == 'AgentStatistics') {
            TargetNS.InitFilterInvalidTableEntries();
        }

        Core.UI.Table.InitTableFilter($('#Filter'), $('.Filterable'), undefined, true);
        $('#Filter').focus();

        TargetNS.InitDialogQuickDeploy();
    };

        /**
    * @private
    * @name InitFavourite
    * @memberof Core.Agent.Admin
    * @function
    * @description
    *      This function handles all about the Favourites-functionality on Admin Dashboard.
    */
    TargetNS.InitFavourite = function () {
        var Favourites = Core.Config.Get('Favourites');

        window.setTimeout(function() {
            $('.SidebarColumn #Filter').focus();
        }, 100);

        $('.AddAsFavourite').off('click.AddAsFavourite').on('click.AddAsFavourite', function(Event) {

            var $TriggerObj = $(this),
                Module = $(this).data('module'),
                ModuleName = $TriggerObj.closest('a').find('span.Title').clone().children().remove().end().text();

            // Remove white space at start and at the end of string.
            ModuleName = ModuleName.replace(/^\s*(.*?)\s*$/, "$1");

            if ($TriggerObj.hasClass('Clicked')) {
                return false;
            }

            Event.stopPropagation();
            $(this).addClass('Clicked');
            Favourites.push(Module);

            Core.Agent.PreferencesUpdate('AdminNavigationBarFavourites', JSON.stringify(Favourites), function() {

                var FavouriteHTML = '',
                    RowIndex,
                    FavouriteRows = [ModuleName];

                $TriggerObj.addClass('Clicked');

                // also add the entry to the sidebar favourites list dynamically
                FavouriteHTML = Core.Template.Render('Agent/Admin/Favourite', {
                    'Link'  : $TriggerObj.closest('a').attr('href'),
                    'Name'  : ModuleName,
                    'Module': Module
                });

                // Fade the original icon out and display a success icon
                $TriggerObj.find('i').fadeOut(function() {
                    $(this).closest('li').find('.AddAsFavourite').append('<i class="fa fa-check" style="display: none;"></i>').find('i.fa-check').fadeIn().delay(1000).fadeOut(function() {
                        $(this)
                            .closest('.AddAsFavourite')
                            .hide()
                            .find('i.fa-check')
                            .remove();
                        $('.ItemListGrid').find('[data-module="' + Module + '"]').addClass('IsFavourite');
                    });
                    $(this).hide();
                });

                $('.DataTable.Favourites tbody tr').each(function() {
                    FavouriteRows.push($(this).find('td:first a').html());
                });

                FavouriteRows.sort(function (a, b) {
                    return a.localeCompare(b);
                });

                RowIndex = FavouriteRows.indexOf(ModuleName);
                if (RowIndex < 0) {
                    $('.DataTable.Favourites').append($(FavouriteHTML));
                }
                else if (RowIndex == 0) {
                    $('.DataTable.Favourites').prepend($(FavouriteHTML));
                }
                else {
                    $(FavouriteHTML).insertAfter($(".DataTable.Favourites tbody tr")[RowIndex - 1]);
                }

                $('.DataTable.Favourites').show();

            });
            return false;
        });

        $('.DataTable.Favourites').on('click', '.RemoveFromFavourites', function() {

            var Module = $(this).data('module'),
                Index = Favourites.indexOf(Module),
                $TriggerObj = $(this),
                $ListItemObj = $('.ItemListGrid').find('[data-module="' + Module + '"]');

            if ($ListItemObj.hasClass('IsFavourite') && Index > -1) {
                Favourites.splice(Index, 1);
                Core.Agent.PreferencesUpdate('AdminNavigationBarFavourites', JSON.stringify(Favourites), function() {
                    $TriggerObj.closest('tr').fadeOut(function() {
                        var $TableObj = $(this).closest('table');
                        $(this).remove();
                        if (!$TableObj.find('tr').length) {
                            $TableObj.hide();
                        }

                        // also remove the corresponding class from the entry in the grid view and list view
                        $ListItemObj.removeClass('IsFavourite').removeClass('Clicked').show().find('i.fa-star-o').show();
                    });
                });
            }

            return false;
        });
    }

    /**
    * @private
    * @name InitFilterInvalidTableEntries
    * @memberof Core.Agent.Admin
    * @function
    * @description
    *      If the filter has been activated, this function hides all invalid entries in the table.
    */
    TargetNS.InitFilterInvalidTableEntries = function () {
        $('#ValidFilter').on('click', function() {
            $('.Invalid').toggle();
            $('#ValidFilter').parent().toggleClass("ValidFilterActive");
        });
    }

    /**
    * @public
    * @name InitDialogQuickDeploy
    * @memberof Core.Agent.Admin
    * @function
    * @description
    *      Register click handling for the quick deploy notification/button.
    */
    TargetNS.InitDialogQuickDeploy = function () {
        $(document).off('click.QuickDeploy', '#QuickDeploy').on('click.QuickDeploy', '#QuickDeploy', function() {

            var URL = Core.Config.Get('Baselink') + 'Action=AdminSystemConfigurationDeployment;Subaction=AJAXDeployment',
                Data = {
                    DeploymentMode: 'QuickDeploy'
                },
                DialogTemplate = Core.Template.Render('SysConfig/DialogQuickDeploy'),
                $DialogObj = $(DialogTemplate),
                $DialogContentObj,
                $DialogFooterObj;

            Core.UI.Dialog.ShowContentDialog($DialogObj, Core.Language.Translate('Quick Deploy'), '35%', 'Center', true);

            $DialogContentObj = $('#DialogQuickDeploy');
            $DialogFooterObj = $DialogContentObj.next('.ContentFooter');

            $DialogFooterObj.find('.ButtonsFinish').hide();

            // close dialog on "cancel" button click
            $('.ContentFooter #Cancel').on('click', function () {
                Core.UI.Dialog.CloseDialog($('.Dialog:visible'));
            });

            $DialogContentObj.addClass('Deploying').find('.Overlay').fadeIn();
            $DialogContentObj.find('.Overlay i.Active').fadeIn();

            Core.AJAX.FunctionCall(
                URL,
                Data,
                function(Response) {

                    // success
                    if (Response && Response.Result && Response.Result.Success == 1) {

                        $DialogContentObj.find('.Overlay i.Active').hide();
                        $DialogContentObj.find('.Overlay i.Success').fadeIn();
                        $DialogContentObj.find('em').text(
                            Core.Language.Translate("Deployment successful. You're being redirected...")
                        );

                        window.setTimeout(function() {

                            if (!Response.RedirectURL) {
                                Core.App.InternalRedirect({
                                    'Action' : 'AdminSystemConfiguration'
                                });
                            }
                            else {
                                window.location.href = Core.Config.Get('Baselink') + Response.RedirectURL;
                            }
                        }, 1000);
                    }
                    // error
                    else {

                        $DialogFooterObj.removeClass('Hidden');
                        $DialogFooterObj.find('.ButtonsFinish').show();
                        $DialogContentObj.find('.Overlay i.Active').hide();
                        $DialogContentObj.find('.Overlay i.Error').fadeIn();

                        $DialogContentObj.find('em').text(
                            Core.Language.Translate('There was an error. Please save all settings you are editing and check the logs for more information.')
                        );
                    }

                    if (Response && Response.Result && Response.Result.Error !== undefined) {
                        $DialogContentObj.find('em').after(
                            Response.Result.Error
                        );
                    }
                }
            );

            return false;
        });
    }

    Core.Init.RegisterNamespace(TargetNS, 'APP_MODULE');

    return TargetNS;
}(Core.Agent.Admin || {}));
