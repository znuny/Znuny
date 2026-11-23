// --
// Copyright (C) 2021 Znuny GmbH, https://znuny.org/
// --
// This software comes with ABSOLUTELY NO WARRANTY. For details, see
// the enclosed file COPYING for license information (AGPL). If you
// did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
// --

"use strict";

var Core = Core || {};
Core.Agent = Core.Agent || {};
Core.Agent.Admin = Core.Agent.Admin || {};

/**
 * @namespace Core.Agent.Admin.Authentication
 * @memberof Core.Agent.Admin
 * @author Znuny GmbH
 * @description
 *      This namespace contains the special module functions for the AdminAuthentication screens.
 */
Core.Agent.Admin.Authentication = (function (TargetNS) {

    /**
     * @name AddRow
     * @memberof Core.Agent.Admin.Authentication
     * @function
     * @returns {Boolean} Returns false.
     * @param {String} RowType - value of the data-row-type/data-add-row attribute identifying the repeatable block.
     * @description
     *      Clones the hidden .ValueTemplate row for the given RowType, gives its inputs a fresh
     *      "_<counter>" suffix and appends it to the matching row container.
     */
    TargetNS.AddRow = function (RowType) {
        var $Container = $('[data-row-container="' + RowType + '"]'),
            $Template = $('.ValueTemplate[data-row-type="' + RowType + '"]'),
            $Clone = $Template.clone(),
            Counter = $Container.children('.ValueRow').length + 1;

        // Make sure the counter is not already used (rows may have been removed out of order).
        while ($Container.find('[name$="_' + Counter + '"]').length) {
            Counter++;
        }

        $Clone.removeClass('Hidden ValueTemplate').addClass('ValueRow');

        $Clone.find(':input').each(function () {
            var $Input = $(this),
                Name = $Input.attr('name'),
                Id = $Input.attr('id');

            if (Name) {
                $Input.attr('name', Name + '_' + Counter);
            }
            if (Id) {
                $Input.attr('id', Id + '_' + Counter);
            }
        });

        $Clone.find('[data-remove-row]').on('click', function () {
            $(this).closest('.ValueRow').remove();
            return false;
        });

        $Container.append($Clone);

        // The template's select fields are deliberately left un-modernized (see the
        // controller's _BuildNameSelectionRows()) so that activating them here, on the fresh
        // clone, doesn't corrupt the hidden template for the next Add click.
        $Clone.find('select').addClass('Modernize');
        Core.UI.InputFields.Activate($Clone);

        return false;
    };

    function InitRepeatableRows() {
        $('[data-add-row]').on('click', function () {
            if ($(this).is(':disabled')) {
                return false;
            }

            TargetNS.AddRow($(this).attr('data-add-row'));
            return false;
        });

        $('[data-remove-row]').on('click', function () {
            $(this).closest('.ValueRow').remove();
            return false;
        });
    }

    function InitToggles() {
        function ToggleMetaDataSource() {
            var SourceType = $('#MetaDataSourceType').val();

            $('.MetaDataURLField').toggleClass('Hidden', SourceType !== 'URL');
            $('.MetaDataXMLField').toggleClass('Hidden', SourceType !== 'XML');

            // The SSL options belong to the URL source only.
            if (SourceType !== 'URL') {
                $('.SSLOptionsField').addClass('Hidden');
            }
        }

        // Clears everything that belongs to a metadata source, so that switching never
        // sends or saves values of the source that is no longer selected.
        function ClearMetaDataSourceFields() {
            $('#RequestMetaDataURL, #RequestMetaDataXML, #SSLCAFile, #SSLCAPath').val('');
            $('#SSLOptionsEnabled, #SSLVerifyHostname').prop('checked', false);
            $('.SSLOptionsField').addClass('Hidden');
            $('[data-metadata-verify-result]').text('').removeClass('ServerError');
            $('#WizardDiscoveredAttributes').val('');
        }

        function ApplyMetaDataSourceSwitch() {
            $('#MetaDataSourceType').val($('#MetaDataSourceSwitch').is(':checked') ? 'URL' : 'XML');
            ClearMetaDataSourceFields();
            ToggleMetaDataSource();
        }

        $('[data-metadata-source-switch]').on('change', function () {
            var $Switch = $(this),
                CurrentField = $('#MetaDataSourceType').val() === 'URL' ? '#RequestMetaDataURL' : '#RequestMetaDataXML';

            // Nothing entered yet, nothing to lose.
            if (!$.trim($(CurrentField).val() || '')) {
                ApplyMetaDataSourceSwitch();
                return;
            }

            Core.UI.Dialog.ShowDialog({
                HTML: $('<p />').text(
                    Core.Language.Translate('Switching the metadata source removes the entered metadata URL or XML and the SSL options. Continue?')
                ).prop('outerHTML'),
                Title: Core.Language.Translate('Change metadata source'),
                Modal: true,
                CloseOnClickOutside: false,
                CloseOnEscape: false,
                PositionTop: '150px',
                PositionLeft: 'Center',
                Buttons: [
                    {
                        Label: Core.Language.Translate('Cancel'),
                        Function: function () {
                            $Switch.prop('checked', !$Switch.is(':checked'));
                            Core.UI.Dialog.CloseDialog($('.Dialog:visible'));
                        }
                    },
                    {
                        Label: Core.Language.Translate('Confirm'),
                        Class: 'Primary',
                        Function: function () {
                            Core.UI.Dialog.CloseDialog($('.Dialog:visible'));
                            ApplyMetaDataSourceSwitch();
                        }
                    }
                ]
            });
        });

        ToggleMetaDataSource();

        $('#SSLOptionsEnabled').on('change', function () {
            $('.SSLOptionsField').toggleClass('Hidden', !$(this).is(':checked'));
        });

        $('#SyncEnabled').on('change', function () {
            $('.SyncField').toggleClass('Hidden', !$(this).is(':checked'));

            // Core.UI.InputFields only modernizes visible selects, so the ones in a section
            // that was hidden on page load are activated when it is shown.
            Core.UI.InputFields.Activate($('.SyncField'));
        });

        // The displayed ACS URL's "Count=" value is only rendered server-side from the
        // config's already-saved Slot. For a config that hasn't been saved yet, the browser
        // may default the Slot select to whichever option happens to be first (e.g. if the
        // default slot is already taken and not offered), which does not necessarily match
        // the empty Slot the page was rendered with - so sync it once on load too, not only
        // on change.
        function SyncACSURLCount() {
            $('[data-acs-url-count]').text($('#Slot').val());
        }

        $('#Slot').on('change', SyncACSURLCount);
        SyncACSURLCount();
    }

    function SetCertStatus($Widget, Text) {
        $Widget.find('[data-cert-status]').text(Text);
    }

    // Info and download buttons only make sense while a certificate is set.
    function SetCertActionsVisible($Widget, Role, Visible) {
        $Widget.find('[data-cert-info][data-role="' + Role + '"], [data-cert-download][data-role="' + Role + '"]')
            .toggleClass('Hidden', !Visible);
    }

    function EscapeHTML(Text) {
        return $('<div></div>').text(Text || '').html();
    }

    /**
     * @name BuildCertPoolOptionLabel
     * @memberof Core.Agent.Admin.Authentication
     * @function
     * @returns {String} A human-readable label for one CertificatePoolList() entry.
     * @param {Object} Entry - one entry as returned by the CertificatePoolList Subaction.
     * @param {String} Role - the widget's data-role (RequestSignKey/RequestSignKeyCert/IdPCACert).
     */
    function BuildCertPoolOptionLabel(Entry, Role) {
        var Label;

        if (Role === 'RequestSignKey') {

            // A bare private key has no X.509 fields of its own to show.
            Label = Entry.OrigFilename || Core.Language.Translate('Uploaded key');
        }
        else if (Entry.Subject) {
            Label = Entry.Subject;
            if (Entry.NotAfter) {
                Label += ' (' + (Entry.IsExpired
                    ? Core.Language.Translate('EXPIRED')
                    : Core.Language.Translate('expires') + ' ' + Entry.NotAfter) + ')';
            }
        }
        else {
            Label = Entry.OrigFilename || Entry.Filename;
        }

        if (Entry.UsedBy && Entry.UsedBy.length) {
            Label += ' [' + Core.Language.Translate('used by %s configuration(s)', Entry.UsedBy.length) + ']';
        }

        return Label;
    }

    function ShowRawCertificate(Filename) {
        Core.AJAX.FunctionCall(Core.Config.Get('CGIHandle'), {
            Action: 'AdminAuthentication',
            Subaction: 'ViewCertificate',
            Filename: Filename
        }, function (Response) {
            if (!Response || !Response.Success) {
                Core.UI.Dialog.ShowAlert(
                    Core.Language.Translate('Error'),
                    (Response && Response.Message) || Core.Language.Translate('Could not read the certificate.')
                );
                return;
            }

            Core.UI.Dialog.CloseDialog($('.Dialog'));

            Core.UI.Dialog.ShowContentDialog(
                '<textarea readonly="readonly" class="W100pc" rows="15">' + EscapeHTML(Response.Content) + '</textarea>',
                Core.Language.Translate('Certificate (PEM)'),
                '30%',
                'Center',
                true,
                [
                    {
                        Label: Core.Language.Translate('Close'),
                        Type: 'Secondary',
                        Function: function () {
                            Core.UI.Dialog.CloseDialog($('.Dialog'));
                        }
                    }
                ]
            );
        }, 'json');
    }

    function ShowCertificateInfo(Filename) {
        Core.AJAX.FunctionCall(Core.Config.Get('CGIHandle'), {
            Action: 'AdminAuthentication',
            Subaction: 'CertificateInfo',
            Filename: Filename
        }, function (Response) {
            var Rows,
                HTML;

            if (!Response || !Response.Success) {
                Core.UI.Dialog.ShowAlert(
                    Core.Language.Translate('Error'),
                    (Response && Response.Message) || Core.Language.Translate('Could not read the certificate.')
                );
                return;
            }

            Rows = [
                [Core.Language.Translate('Subject'), Response.Subject, false],
                [Core.Language.Translate('Issuer'), Response.Issuer, false],
                [Core.Language.Translate('Valid from'), Response.NotBefore, false],
                [Core.Language.Translate('Valid until'), Response.NotAfter, Response.IsExpired],
                [Core.Language.Translate('Serial'), Response.Serial, false],
                [Core.Language.Translate('Fingerprint (SHA-256)'), Response.Fingerprint, false]
            ];
            HTML = '<dl class="DataList CertificateInfoList">';

            $.each(Rows, function (Index, Row) {
                if (!Row[1]) {
                    return;
                }

                HTML += '<dt>' + EscapeHTML(Row[0]) + '</dt><dd' + (Row[2] ? ' class="ServerError"' : '') + '>'
                    + EscapeHTML(Row[1]) + (Row[2] ? ' (' + EscapeHTML(Core.Language.Translate('EXPIRED')) + ')' : '')
                    + '</dd>';
            });
            HTML += '</dl>';
            HTML += '<button type="button" class="CallForAction" data-cert-show-raw><span>'
                + Core.Language.Translate('Show raw PEM') + '</span></button>';

            Core.UI.Dialog.ShowContentDialog(
                HTML,
                Core.Language.Translate('Certificate details'),
                '30%',
                'Center',
                true,
                [
                    {
                        Label: Core.Language.Translate('Close'),
                        Type: 'Secondary',
                        Function: function () {
                            Core.UI.Dialog.CloseDialog($('.Dialog'));
                        }
                    }
                ]
            );

            $('[data-cert-show-raw]').on('click', function () {
                ShowRawCertificate(Filename);
                return false;
            });
        }, 'json');
    }

    function SetMetadataVerifyResult($Button, Success, Text) {
        var Source = $Button.attr('data-source'),
            $Result = $Button.closest('.Field').find('[data-metadata-verify-result][data-source="' + Source + '"]');

        $Result.text(Text).toggleClass('ServerError', !Success);
    }

    function BuildMetadataVerifySuccessText(Response) {
        var Parts = [Core.Language.Translate('Metadata is valid.')];

        Parts.push(Core.Language.Translate('Entity ID') + ': ' + Response.EntityID);

        if (Response.SSOUrl) {
            Parts.push(Core.Language.Translate('SSO URL') + ': ' + Response.SSOUrl);
        }

        Parts.push(
            Response.HasSigningCert
                ? Core.Language.Translate('Includes a signing certificate.')
                : Core.Language.Translate('No signing certificate found in the metadata.')
        );

        if (Response.Attributes && Response.Attributes.length) {
            Parts.push(Core.Language.Translate('Found %s attribute(s) in the metadata.', Response.Attributes.length));
        }

        return Parts.join(' ');
    }

    /**
     * @name ApplyDiscoveredAttributes
     * @memberof Core.Agent.Admin.Authentication
     * @function
     * @param {Array} Attributes - list of {Name, FriendlyName} found in the IdP metadata by
     *      VerifyMetadata, used as a best-effort starting point for the user attribute sync map.
     * @description
     *      On the full edit screen, adds one User attribute sync map row for each discovered
     *      attribute that isn't already present as a SAML attribute URI in some row - existing
     *      rows (whatever the admin already filled in) are never touched or overwritten, only
     *      added to. The wizard has the same section in its optional sync step, and also
     *      stashes the attribute names into a hidden field, so _Save() can seed the sync map
     *      if the admin leaves sync disabled in the wizard and enables it later on the full
     *      edit screen.
     */
    function ApplyDiscoveredAttributes(Attributes) {
        var $Container = $('[data-row-container="UserSyncMap"]'),
            $WizardField = $('#WizardDiscoveredAttributes'),
            ExistingValues = {};

        if (!Attributes || !Attributes.length) {
            return;
        }

        if ($Container.length) {
            $Container.children('.ValueRow').find('input[name^="UserSyncMapValue_"]').each(function () {
                var Value = $(this).val();
                if (Value) {
                    ExistingValues[Value] = true;
                }
            });

            $.each(Attributes, function (Index, Attribute) {
                if (ExistingValues[Attribute.Name]) {
                    return;
                }

                TargetNS.AddRow('UserSyncMap');
                $Container.children('.ValueRow').last().find('input[name^="UserSyncMapValue_"]').val(Attribute.Name);
                ExistingValues[Attribute.Name] = true;
            });
        }

        if ($WizardField.length) {
            $WizardField.val(JSON.stringify($.map(Attributes, function (Attribute) {
                return Attribute.Name;
            })));
        }
    }

    /**
     * @name BuildMetadataParams
     * @memberof Core.Agent.Admin.Authentication
     * @function
     * @returns {Object} The MetaDataSourceType/RequestMetaDataURL(or XML)/SSL* params, read
     *      from the "Identity provider metadata source" fields - shared by every action that
     *      needs to re-fetch/re-parse the same metadata (Verify, Use certificate from metadata).
     * @param {String} Source - 'URL' or 'XML'.
     */
    function BuildMetadataParams(Source) {
        var Data = {
            MetaDataSourceType: Source
        };

        if (Source === 'URL') {
            Data.RequestMetaDataURL = $('#RequestMetaDataURL').val();

            if ($('#SSLOptionsEnabled').is(':checked')) {
                Data.SSLOptionsEnabled = '1';
                Data.SSLCAFile = $('#SSLCAFile').val();
                Data.SSLCAPath = $('#SSLCAPath').val();
                Data.SSLVerifyHostname = $('#SSLVerifyHostname').is(':checked') ? '1' : '';
            }
        }
        else {
            Data.RequestMetaDataXML = $('#RequestMetaDataXML').val();
        }

        return Data;
    }

    function InitMetadataVerify() {
        $('[data-metadata-verify]').on('click', function () {
            var $Button = $(this),
                Source = $Button.attr('data-source'),
                Data = $.extend({
                    Action: 'AdminAuthentication',
                    Subaction: 'VerifyMetadata'
                }, BuildMetadataParams(Source));

            SetMetadataVerifyResult($Button, true, Core.Language.Translate('Verifying...'));

            Core.AJAX.FunctionCall(Core.Config.Get('CGIHandle'), Data, function (Response) {
                if (!Response || !Response.Success) {
                    SetMetadataVerifyResult(
                        $Button,
                        false,
                        (Response && Response.Message) || Core.Language.Translate('Metadata verification failed.')
                    );
                    return;
                }

                SetMetadataVerifyResult($Button, true, BuildMetadataVerifySuccessText(Response));
                ApplyDiscoveredAttributes(Response.Attributes);
            }, 'json');

            return false;
        });
    }

    function InitCertificateWidgets() {

        // Called on page load and again whenever a certificate/key was uploaded, generated,
        // taken from metadata or removed, so the pool always lists what is stored right now
        // and shows the currently set certificate/key as selected.
        function LoadCertPool($Select) {
            var Role = $Select.attr('data-role');

            Core.AJAX.FunctionCall(Core.Config.Get('CGIHandle'), {
                Action: 'AdminAuthentication',
                Subaction: 'CertificatePoolList',
                Role: Role,
                ID: $('#ID').val()
            }, function (Response) {
                var CurrentValue = $Select.closest('[data-cert-widget]').find('#' + Role + 'VFSFilename').val();

                if (!Response || !Response.Success) {
                    return;
                }

                // Keep only the "- Select an existing certificate/key -" placeholder.
                $Select.find('option').not(':first').remove();

                $.each(Response.Pool, function (Index, Entry) {
                    $Select.append(
                        $('<option></option>').val(Entry.Filename).text(BuildCertPoolOptionLabel(Entry, Role))
                    );
                });

                $Select.val(CurrentValue || '');

                // Already modernized by an earlier load - only the displayed options need updating.
                if ($Select.hasClass('Modernize')) {
                    $Select.trigger('redraw.InputField');
                    return;
                }

                // The select starts out without the Modernize class (see CertificateWidget.tt)
                // and only gets modernized once its options are actually populated - activating
                // it any earlier (e.g. via the page-wide Core.UI.InputFields.Activate() call in
                // Init()) would build the fancy dropdown widget from the still-empty select and
                // never notice these options being appended afterwards. Same reasoning as the
                // clone-then-activate pattern already used in AddRow() above.
                $Select.addClass('Modernize');
                Core.UI.InputFields.Activate($Select.parent());
            }, 'json');
        }

        function RefreshCertPool($Widget, Role) {
            LoadCertPool($Widget.find('[data-cert-pool-select][data-role="' + Role + '"]'));
        }

        // Uploaded and pasted certificates/keys are written to VirtualFS immediately, so the
        // hidden VFSFilename field is updated right away - no separate "pending" state to track.
        function HandleCertStored($Widget, Role, Response, FallbackMessage) {
            if (!Response || !Response.Success) {
                Core.UI.Dialog.ShowAlert(
                    Core.Language.Translate('Error'),
                    (Response && Response.Message) || FallbackMessage
                );
                return false;
            }

            $Widget.find('#' + Role + 'VFSFilename').val(Response.Filename);
            SetCertStatus($Widget, Core.Language.Translate('Certificate/key is stored in VirtualFS.'));
            SetCertActionsVisible($Widget, Role, true);
            RefreshCertPool($Widget, Role);

            return true;
        }

        $('[data-cert-pool-select]').each(function () {
            LoadCertPool($(this));
        });

        $('[data-cert-pool-select]').on('change', function () {
            var Role = $(this).attr('data-role'),
                $Widget = $(this).closest('[data-cert-widget]'),
                Filename = $(this).val();

            if (!Filename) {
                return;
            }

            $Widget.find('#' + Role + 'VFSFilename').val(Filename);
            SetCertStatus($Widget, Core.Language.Translate('Certificate/key is stored in VirtualFS.'));
            SetCertActionsVisible($Widget, Role, true);
        });

        $('[data-cert-upload]').on('change', function (Event) {
            var Role = $(this).attr('data-role'),
                $Widget = $(this).closest('[data-cert-widget]'),
                Input = Event.target,
                FormDataObject;

            if (!Input.files || !Input.files.length) {
                return;
            }

            FormDataObject = new window.FormData();
            FormDataObject.append('FileUpload', Input.files[0]);
            FormDataObject.append('Action', 'AdminAuthentication');
            FormDataObject.append('Subaction', 'UploadCertificate');
            FormDataObject.append('Role', Role);
            FormDataObject.append('ChallengeToken', Core.Config.Get('ChallengeToken'));

            $.ajax({
                url: Core.Config.Get('CGIHandle'),
                type: 'POST',
                data: FormDataObject,
                processData: false,
                contentType: false,
                dataType: 'json'
            }).done(function (Response) {
                HandleCertStored($Widget, Role, Response, Core.Language.Translate('Upload failed.'));
            });
        });

        $('[data-cert-paste-toggle]').on('click', function () {
            var Role = $(this).attr('data-role');

            $('[data-cert-paste-form][data-role="' + Role + '"]').toggleClass('Hidden');

            return false;
        });

        $('[data-cert-paste-submit]').on('click', function () {
            var Role = $(this).attr('data-role'),
                $Widget = $(this).closest('[data-cert-widget]'),
                $Text = $Widget.find('[data-cert-paste-text][data-role="' + Role + '"]'),
                Data = {
                    Action: 'AdminAuthentication',
                    Subaction: 'UploadCertificate',
                    Role: Role,
                    PastedContent: $Text.val()
                };

            if (!$.trim(Data.PastedContent)) {
                Core.UI.Dialog.ShowAlert(
                    Core.Language.Translate('Error'),
                    Core.Language.Translate('Please paste a certificate or key first.')
                );
                return false;
            }

            Core.AJAX.FunctionCall(Core.Config.Get('CGIHandle'), Data, function (Response) {
                if (!HandleCertStored($Widget, Role, Response, Core.Language.Translate('Saving the pasted certificate/key failed.'))) {
                    return;
                }

                $Text.val('');
                $('[data-cert-paste-form][data-role="' + Role + '"]').addClass('Hidden');
            }, 'json');

            return false;
        });

        $('[data-cert-generate-toggle]').on('click', function () {
            var Role = $(this).attr('data-role');
            $('[data-cert-generate-form][data-role="' + Role + '"]').toggleClass('Hidden');
            return false;
        });

        $('[data-cert-generate-submit]').on('click', function () {
            var Role = $(this).attr('data-role'),
                $Widget = $(this).closest('[data-cert-widget]'),

                // "Generate" only exists on the RequestSignKey widget and always produces a
                // matching certificate too, stored under the separate RequestSignKeyCert
                // widget - update that widget as well, not just this one.
                $CertWidget = $('[data-cert-widget][data-role="' + Role + 'Cert"]'),
                Data = {
                    Action: 'AdminAuthentication',
                    Subaction: 'GenerateCertificate',
                    Role: Role,
                    CommonName: $('#' + Role + 'GenCommonName').val(),
                    KeySize: $('#' + Role + 'GenKeySize').val(),
                    ValidityDays: $('#' + Role + 'GenValidityDays').val()
                };

            Core.AJAX.FunctionCall(Core.Config.Get('CGIHandle'), Data, function (Response) {
                if (!Response || !Response.Success) {
                    Core.UI.Dialog.ShowAlert(
                        Core.Language.Translate('Error'),
                        (Response && Response.Message) || Core.Language.Translate('Certificate generation failed.')
                    );
                    return;
                }

                // The generated key is written to VirtualFS immediately, just like an upload.
                $Widget.find('#' + Role + 'VFSFilename').val(Response.Filename);
                SetCertStatus($Widget, Core.Language.Translate('Certificate/key is stored in VirtualFS.'));
                RefreshCertPool($Widget, Role);
                $('[data-cert-generate-form][data-role="' + Role + '"]').addClass('Hidden');

                if (Response.CertFilename && $CertWidget.length) {
                    $CertWidget.find('#' + Role + 'CertVFSFilename').val(Response.CertFilename);
                    SetCertStatus($CertWidget, Core.Language.Translate('Certificate/key is stored in VirtualFS.'));
                    SetCertActionsVisible($CertWidget, Role + 'Cert', true);
                    RefreshCertPool($CertWidget, Role + 'Cert');
                }
            }, 'json');

            return false;
        });

        $('[data-cert-info]').on('click', function () {
            var Role = $(this).attr('data-role'),
                $Widget = $(this).closest('[data-cert-widget]'),
                Filename = $Widget.find('#' + Role + 'VFSFilename').val();

            if (!Filename) {
                return false;
            }

            ShowCertificateInfo(Filename);

            return false;
        });

        $('[data-cert-download]').on('click', function () {
            var Role = $(this).attr('data-role'),
                $Widget = $(this).closest('[data-cert-widget]'),
                Filename = $Widget.find('#' + Role + 'VFSFilename').val();

            if (!Filename) {
                return false;
            }

            window.location.href = Core.Config.Get('Baselink')
                + 'Action=AdminAuthentication;Subaction=DownloadCertificate;Filename=' + encodeURIComponent(Filename)
                + ';ChallengeToken=' + Core.Config.Get('ChallengeToken');

            return false;
        });

        $('[data-cert-use-metadata]').on('click', function () {
            var Role = $(this).attr('data-role'),
                $Widget = $(this).closest('[data-cert-widget]'),
                Source = $('#MetaDataSourceType').val(),
                Data;

            if (!Source) {
                Core.UI.Dialog.ShowAlert(
                    Core.Language.Translate('Error'),
                    Core.Language.Translate('Please select a metadata source (URL or XML) first.')
                );
                return false;
            }

            Data = $.extend({
                Action: 'AdminAuthentication',
                Subaction: 'UseMetadataCertificate'
            }, BuildMetadataParams(Source));

            Core.AJAX.FunctionCall(Core.Config.Get('CGIHandle'), Data, function (Response) {
                if (!Response || !Response.Success) {
                    Core.UI.Dialog.ShowAlert(
                        Core.Language.Translate('Error'),
                        (Response && Response.Message)
                            || Core.Language.Translate('Could not find a certificate in the metadata.')
                    );
                    return;
                }

                $Widget.find('#' + Role + 'VFSFilename').val(Response.Filename);
                SetCertStatus($Widget, Core.Language.Translate('Certificate/key is stored in VirtualFS.'));
                SetCertActionsVisible($Widget, Role, true);
                RefreshCertPool($Widget, Role);
            }, 'json');

            return false;
        });

        $('[data-cert-remove]').on('click', function () {
            var Role = $(this).attr('data-role'),
                $Widget = $(this).closest('[data-cert-widget]'),
                Filename = $Widget.find('#' + Role + 'VFSFilename').val();

            if (!Filename) {
                return false;
            }

            Core.AJAX.FunctionCall(Core.Config.Get('CGIHandle'), {
                Action: 'AdminAuthentication',
                Subaction: 'DeleteCertificate',
                Filename: Filename
            }, function () {
                $Widget.find('#' + Role + 'VFSFilename').val('');
                SetCertStatus($Widget, Core.Language.Translate('No certificate/key set.'));
                SetCertActionsVisible($Widget, Role, false);

                // The blob may have been deleted if nothing else used it.
                RefreshCertPool($Widget, Role);
            }, 'json');

            return false;
        });
    }

    function InitCopyButtons() {
        $('[data-copy-target]').on('click', function () {
            var $Target = $($(this).attr('data-copy-target')),
                Text = $Target.text(),
                $TextArea;

            if (!Text) {
                return false;
            }

            if (navigator.clipboard && window.isSecureContext) {
                navigator.clipboard.writeText(Text).then(function () {
                    Core.UI.ShowNotification(Core.Language.Translate('Copied to clipboard!'), 'Success');
                });
                return false;
            }

            $TextArea = $('<textarea></textarea>').val(Text).css({
                position: 'fixed',
                left: '-9999px',
                top: '-9999px'
            }).appendTo('body');

            $TextArea.trigger('focus');
            $TextArea.trigger('select');
            document.execCommand('copy');
            $TextArea.remove();

            Core.UI.ShowNotification(Core.Language.Translate('Copied to clipboard!'), 'Success');

            return false;
        });
    }

    function InitDeleteButtons() {
        $('[data-action-delete-saml-config]').on('click', function () {
            var ID = $(this).attr('data-id');

            Core.UI.Dialog.ShowContentDialog(
                '<p>' + Core.Language.Translate('Do you really want to delete this SAML configuration?') + '</p>',
                Core.Language.Translate('Delete SAML configuration'),
                '20%',
                'Center',
                true,
                [
                    {
                        Label: Core.Language.Translate('Cancel'),
                        Type: 'Secondary',
                        Function: function () {
                            Core.UI.Dialog.CloseDialog($('.Dialog'));
                        }
                    },
                    {
                        Label: Core.Language.Translate('Delete'),
                        Type: 'Warning',
                        Function: function () {
                            Core.AJAX.FunctionCall(Core.Config.Get('CGIHandle'), {
                                Action: 'AdminAuthentication',
                                Subaction: 'Delete',
                                ID: ID
                            }, function (Response) {
                                Core.UI.Dialog.CloseDialog($('.Dialog'));

                                if (!Response || !Response.Success) {
                                    Core.UI.Dialog.ShowAlert(
                                        Core.Language.Translate('Error'),
                                        (Response && Response.Message)
                                            || Core.Language.Translate('There was an error deleting the SAML configuration.')
                                    );
                                    return;
                                }

                                Core.App.InternalRedirect({
                                    Action: 'AdminAuthentication'
                                });
                            }, 'json');
                        }
                    }
                ]
            );

            return false;
        });
    }

    /**
     * @name Init
     * @memberof Core.Agent.Admin.Authentication
     * @function
     * @description
     *      This function binds events to certain actions on the AdminAuthentication screens.
     */
    /**
     * @name InitWizard
     * @memberof Core.Agent.Admin.Authentication
     * @function
     * @description
     *      Step-by-step navigation for the SAML setup wizard screen. A no-op on any other
     *      AdminAuthentication screen, since #AuthenticationWizardForm only exists there.
     */
    function InitWizard() {
        var $Form = $('#AuthenticationWizardForm'),
            $AllSteps,
            $Steps,
            $StepList,
            StepTitles = [],
            CurrentStep = 0;

        if (!$Form.length) {
            return;
        }

        $AllSteps = $Form.find('[data-wizard-step]');
        $StepList = $('[data-wizard-step-list]');

        // Steps marked with data-wizard-context (e.g. user sync, agents only) only take part
        // for that context. Rebuilds the step titles, the step count and the progress list in
        // the sidebar from the steps of the selected context.
        function BuildSteps() {
            var Context = $('input[name="WizardContext"]:checked').val();

            $Steps = $AllSteps.filter(function () {
                var StepContext = $(this).attr('data-wizard-context');
                return !StepContext || StepContext === Context;
            });

            StepTitles = [];
            $Steps.each(function () {
                StepTitles.push($(this).find('.Header h2').first().text());
            });
            $('[data-wizard-step-count]').text($Steps.length);

            $StepList.empty();
            $.each(StepTitles, function (Index, Title) {
                $('<li />')
                    .append($('<span class="StepNumber" />').text(Index + 1))
                    .append($('<span class="StepTitle" />').text(Title))
                    .appendTo($StepList);
            });
        }

        function SyncSlotField() {
            var Context = $('input[name="WizardContext"]:checked').val();

            // Trigger change so InitToggles()'s ACS URL "Count=" sync (bound to #Slot) picks
            // up the new value too - setting .val() alone does not fire native change events.
            $('#Slot').val($('#WizardSlot' + Context).val()).trigger('change');
        }

        function ToggleContext() {
            var Context = $('input[name="WizardContext"]:checked').val(),
                OtherContext = Context === 'Agent' ? 'Customer' : 'Agent',
                $SlotWrapper = $('[data-wizard-slot="' + Context + '"]');

            $SlotWrapper.removeClass('Hidden');
            $('[data-wizard-slot="' + OtherContext + '"]').addClass('Hidden');
            $('[data-wizard-acsurl="' + Context + '"]').removeClass('Hidden');
            $('[data-wizard-acsurl="' + OtherContext + '"]').addClass('Hidden');

            $('#Subaction').val(Context === 'Agent' ? 'SaveAgentAuth' : 'SaveCustomerAuth');

            // The just-revealed Slot select may have been modernized while still hidden
            // (e.g. Customer's, if Agent was the initial choice) - (re-)activate it now that
            // it is visible so the fancy dropdown renders correctly.
            Core.UI.InputFields.Activate($SlotWrapper);

            SyncSlotField();

            // Customer authentication has no sync. The server ignores SyncEnabled for it
            // anyway, but don't leave it switched on in a hidden step.
            if (Context !== 'Agent' && $('#SyncEnabled').is(':checked')) {
                $('#SyncEnabled').prop('checked', false).trigger('change');
            }

            BuildSteps();
            ShowStep(CurrentStep);
        }

        function BuildReviewSummary() {
            var Context = $('input[name="WizardContext"]:checked').val(),
                MetaDataSourceType = $('#MetaDataSourceType').val(),
                MetadataText,
                Rows = [],
                $Container = $('[data-wizard-review]').empty();

            Rows.push([
                Core.Language.Translate('Type'),
                Context === 'Agent'
                    ? Core.Language.Translate('Agent authentication')
                    : Core.Language.Translate('Customer authentication')
            ]);
            Rows.push([Core.Language.Translate('Name'), $('#Name').val()]);
            Rows.push([Core.Language.Translate('Slot'), $('#WizardSlot' + Context + ' option:selected').text()]);
            Rows.push([Core.Language.Translate('Login button text'), $('#RequestLoginButtonText').val()]);
            Rows.push([Core.Language.Translate('Issuer (SP entity ID)'), $('#Issuer').val()]);
            Rows.push([
                Core.Language.Translate('Login attribute'),
                $.trim($('#UserLoginAttribute').val()) || Core.Language.Translate('NameID (default)')
            ]);
            Rows.push([
                Core.Language.Translate('Assertion consumer URL'),
                $('[data-wizard-acsurl="' + Context + '"] code').first().text()
            ]);

            if (MetaDataSourceType === 'URL') {
                MetadataText = $('#RequestMetaDataURL').val();
            }
            else if (MetaDataSourceType === 'XML') {
                MetadataText = Core.Language.Translate('(pasted XML)');
            }
            else {
                MetadataText = Core.Language.Translate('Not configured yet');
            }
            Rows.push([Core.Language.Translate('Identity provider metadata'), MetadataText]);

            Rows.push([
                Core.Language.Translate('SP signing key'),
                $('#RequestSignKeyVFSFilename').val() ? Core.Language.Translate('Configured') : Core.Language.Translate('Not set')
            ]);
            Rows.push([
                Core.Language.Translate('SP signing certificate'),
                $('#RequestSignKeyCertVFSFilename').val() ? Core.Language.Translate('Configured') : Core.Language.Translate('Not set')
            ]);
            Rows.push([
                Core.Language.Translate('Decrypt encrypted assertions'),
                $('#ResponseEncryptionEnabled').is(':checked') ? Core.Language.Translate('Yes') : Core.Language.Translate('No')
            ]);
            Rows.push([
                Core.Language.Translate('Identity provider CA certificate'),
                $('#IdPCACertVFSFilename').val()
                    ? Core.Language.Translate('Configured')
                    : Core.Language.Translate('Not set (will be taken from the metadata when saving)')
            ]);

            if (Context === 'Agent') {
                Rows.push([
                    Core.Language.Translate('User sync'),
                    $('#SyncEnabled').is(':checked')
                        ? Core.Language.Translate(
                            'Enabled (%s attribute mappings, %s group rules, %s role rules)',
                            $('[data-row-container="UserSyncMap"] .ValueRow').length,
                            $('[data-row-container="UserSyncGroupsDefinition"] .ValueRow, [data-row-container="UserSyncAttributeGroupsDefinition"] .ValueRow').length,
                            $('[data-row-container="UserSyncRolesDefinition"] .ValueRow, [data-row-container="UserSyncAttributeRolesDefinition"] .ValueRow').length
                        )
                        : Core.Language.Translate('Disabled')
                ]);
            }

            $.each(Rows, function (Index, Row) {
                $('<div class="field-wrapper" />')
                    .append($('<label />').text(Row[0]))
                    .append($('<p class="Value" />').text(Row[1] || '-'))
                    .appendTo($Container);
            });
        }

        function ShowStep(Index) {
            $AllSteps.addClass('Hidden');
            $Steps.eq(Index).removeClass('Hidden');

            // Core.UI.InputFields only modernizes visible selects, so the selects of a step
            // are activated when the step is shown (already activated ones are skipped).
            Core.UI.InputFields.Activate($Steps.eq(Index));

            $('[data-wizard-step-number]').text(Index + 1);
            $('[data-wizard-step-title]').text(StepTitles[Index] || '');
            $StepList.children('li').each(function (ItemIndex) {
                $(this)
                    .toggleClass('Active', ItemIndex === Index)
                    .toggleClass('Done', ItemIndex < Index)
                    .attr('aria-current', ItemIndex === Index ? 'step' : null);
            });
            $('[data-wizard-back]').toggleClass('Hidden', Index === 0);
            $('[data-wizard-next]').toggleClass('Hidden', Index === $Steps.length - 1);
            $('[data-wizard-submit]').toggleClass('Hidden', Index !== $Steps.length - 1);

            if (Index === $Steps.length - 1) {
                BuildReviewSummary();
            }

            CurrentStep = Index;
        }

        function CurrentStepIsValid() {
            var $Step = $Steps.eq(CurrentStep),
                SourceType,
                Valid = true;

            $Step.find('.field-wrapper:not(.Hidden) .Validate_Required').each(function () {
                if (!$(this).val()) {
                    Valid = false;
                }
            });

            if ($Step.find('[data-metadata-source-switch]').length) {
                SourceType = $('#MetaDataSourceType').val();

                if (!SourceType) {
                    Valid = false;
                }
                else if (SourceType === 'URL' && !$('#RequestMetaDataURL').val()) {
                    Valid = false;
                }
                else if (SourceType === 'XML' && !$('#RequestMetaDataXML').val()) {
                    Valid = false;
                }
            }

            return Valid;
        }

        $('[data-wizard-context-radio]').on('change', ToggleContext);
        $('#WizardSlotAgent, #WizardSlotCustomer').on('change', SyncSlotField);

        $('[data-wizard-next]').on('click', function () {
            if (!CurrentStepIsValid()) {
                Core.UI.Dialog.ShowAlert(
                    Core.Language.Translate('Error'),
                    Core.Language.Translate('Please fill in all required fields before continuing.')
                );
                return false;
            }

            if (CurrentStep < $Steps.length - 1) {
                ShowStep(CurrentStep + 1);
            }

            return false;
        });

        $('[data-wizard-back]').on('click', function () {
            if (CurrentStep > 0) {
                ShowStep(CurrentStep - 1);
            }

            return false;
        });

        ToggleContext();
        ShowStep(0);
    }

    TargetNS.Init = function () {
        InitRepeatableRows();
        InitToggles();
        InitCertificateWidgets();
        InitCopyButtons();
        InitDeleteButtons();
        InitMetadataVerify();
        InitWizard();

        Core.UI.InputFields.Activate();

        $('#SubmitAndContinue').on('click', function () {
            $('#ContinueAfterSave').val('1');
            $('#SAMLEditForm').trigger('submit');
            return false;
        });
    };

    Core.Init.RegisterNamespace(TargetNS, 'APP_MODULE');

    return TargetNS;
}(Core.Agent.Admin.Authentication || {}));
