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
 * @exports TargetNS as Core.Agent.Attachments
 * @description
 *      This namespace contains the special functions for ticket attachments.
 */
Core.Agent.Attachments = (function (TargetNS) {
    var InlineFilesVisible = true;

    TargetNS.InitTicketAttachmentZipArchiveDownload = function() {
        const $Checkboxes = $('#DownloadZipArchive :checkbox[name="ArticleFileIDString"]'),
            $SelectedButton = $('.SelectedAttachments');

        TargetNS.InitShowMoreButton();

        // Only offer "Selected attachments" while at least one box is ticked.
        // Hide it again as soon as the last one is cleared.
        const UpdateSelectedButton = function () {
            $SelectedButton.toggleClass('Hidden', !$Checkboxes.filter(':checked').length);
        };

        $Checkboxes.off('change.AttachmentZip').on('change.AttachmentZip', UpdateSelectedButton);
        UpdateSelectedButton();

        // Guard against a stale visible button (e.g. after an aborted download).
        $('#ZnunyTicketAttachmentsZipDownloadSelected').off('click.AttachmentZip').on('click.AttachmentZip', function () {
            if (!$Checkboxes.filter(':checked').length) {
                Core.UI.Dialog.ShowAlert(Core.Language.Translate('Please select attachments for download.'));
                return false;
            }
        });

        // "All attachments" selects every box and submits on its own; it used to
        // click the Selected button, which left the UI out of sync whenever the
        // download response kept the page around.
        $('#ZnunyTicketAttachmentsZipDownloadAll').off('click.AttachmentZip').on('click.AttachmentZip', function () {
            $Checkboxes.prop('checked', true).trigger('change');
        });
    };

    TargetNS.InitShowMoreButton = function () {

        $('.ShowMoreButton').on('click', function () {
            $('.ShowMore').toggleClass('Hidden');
            if($('.ShowMoreButton').hasClass('More')) {
                $('.ShowMoreButton').removeClass('More')
                $(this).find('span').text(Core.Language.Translate("Show less"));
            } else {
                $('.ShowMoreButton').addClass('More')
                $(this).find('span').text(Core.Language.Translate("Show more"));
            }
        });
    }


    TargetNS.InitTicketAttachmentReuseSelection = function () {
        var ReusedArticleFileIDsString,
            ReusedArticleFileIDs = [],
            Index;

        TargetNS.InitShowMoreButton();
        //
        // Draft: Initially set check-boxes for attachment IDs that are stored in field
        // ReusedArticleFileIDs.
        //
        ReusedArticleFileIDsString = $('#ReusedArticleFileIDs').val();

        if (ReusedArticleFileIDsString && ReusedArticleFileIDsString.length) {
            ReusedArticleFileIDs = ReusedArticleFileIDsString.split(';');
        }

        for (Index = 0; Index < ReusedArticleFileIDs.length; Index++) {

            // Don't use trigger here, it would mess around with the dynamic field which is not necessary at
            // this point.
            $(':checkbox[name="ArticleFileIDString"][value="' + ReusedArticleFileIDs[Index] + '"]:not(:checked)').prop('checked', true);
        }

        $(':checkbox[name="ArticleFileIDString"]').on('click', function() {
            var $SelectedAttachments = $(':checkbox[name="ArticleFileIDString"]:checked'),
                SelectedArticleFileIDStringPairs = '';

            $SelectedAttachments.each(function () {
                if (SelectedArticleFileIDStringPairs.length) {
                    SelectedArticleFileIDStringPairs += ';';
                }

                SelectedArticleFileIDStringPairs += $(this).val();
            });

            $('#ReusedArticleFileIDs').val(SelectedArticleFileIDStringPairs);
        });

        $('#ZnunyTicketAttachmentsSelectAll').on('click', function() {
            var $SelectedAttachments = $(':checkbox[name="ArticleFileIDString"]:checked'),
                $NotSelectedAttachments = $(':checkbox[name="ArticleFileIDString"]:not(:checked)');

            // Select all attachments.
            if ($NotSelectedAttachments.length) {
                $NotSelectedAttachments.each(function() {
                    $(this).trigger('click');
                });
            }
            // Unselect all attachments if all are selected.
            else {
                $SelectedAttachments.each(function() {
                    $(this).trigger('click');
                });
            }
        });
    }

    TargetNS.InitAgentTicketAttachmentList = function () {
        Core.UI.Table.InitTableFilter($('#FilterFiles'), $('#AttachmentList'));

        // Table sorting
        Core.UI.Table.Sort.Init($('#AttachmentList'));

        // functionality to hide or show inline files in the table
        $('.HideInlineFiles').on('click', function() {
            InlineFilesVisible = !InlineFilesVisible;

            TargetNS.ToggleInlineFiles();
        });

        // checkbox to mark or unmark all checkboxes
        $('#FileMarkAll').on('change', function() {
            $('td.FileAsZip input[type=checkbox]:visible')
                .prop('checked', $(this).prop('checked'))
                .trigger('change');
        });

        // handler to show or hide the download as zip button
        // based on the marked checkboxes
        $('#AttachmentList tbody td input[type=checkbox]').on('change', function() {
            if ($('#AttachmentList tbody td input[type=checkbox]:checked').length > 0) {
                $('.TableButtons').show();
                return;
            }

            $('.TableButtons').hide();
        });

        // by default download as zip is hidden
        $('.TableButtons').hide();

        // event handler to hide inline files after filtering if needed
        Core.App.Subscribe('Event.UI.Table.InitTableFilter.Change', TargetNS.ToggleInlineFiles);

        return true;
    };

    TargetNS.ToggleInlineFiles = function () {

        // hide or show inline files
        if (InlineFilesVisible) {

            // show inline files
            $('#AttachmentList tbody tr.InlineFile').show();
            return;
        }

        // hide inlines files
        $('#AttachmentList tbody tr.InlineFile').hide();

        // remove checked flags of the checkboxes
        $('td.FileAsZip input[type=checkbox]:hidden')
            .prop('checked', false)
            .trigger('change');
    };

    Core.Init.RegisterNamespace(TargetNS, 'APP_MODULE');

    return TargetNS;
}(Core.Agent.Attachments || {}));
