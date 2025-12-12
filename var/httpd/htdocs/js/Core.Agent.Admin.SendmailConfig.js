// --
// Copyright (C) 2021 Znuny GmbH, https://znuny.org/
// --
// This software comes with ABSOLUTELY NO WARRANTY. For details, see
// the enclosed file COPYING for license information (AGPL). If you
// did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
// --

"use strict";

var Core  = Core || {},
    Znuny = Znuny || {};

Core.Agent = Core.Agent || {};
Core.Agent.Admin = Core.Agent.Admin || {};

Znuny.Form       = Znuny.Form || {};
Znuny.Form.Input = Znuny.Form.Input || {};

/**
 * @namespace Core.Agent.Admin.SendmailConfig
 * @memberof Core.Agent.Admin
 * @author OTRS AG
 * @description
 *      This namespace contains the special module functions for MultiSendmail module.
 */
 Core.Agent.Admin.SendmailConfig = (function (TargetNS) {

    /**
    * @name Init
    * @memberof Core.Agent.Admin.SendmailConfig
    * @function
    * @description
    *      Password and OAuth2 token selection field will be shown/hidden depending
    *      on authentication type selection.
    */
    TargetNS.Init = function () {
        TargetNS.InitOverview();
        TargetNS.InitEdit();
    };

    /**
     * @name InitEdit
     * @memberof Core.Agent.Admin.SendmailConfig
     * @function
     * @description
     *      Init of editing dialogs.
     */
    TargetNS.InitEdit = function() {
        var OriginalAuthenticationOptions = $('#AuthenticationType').html(),
            SendmailModules = Core.Config.Get('SendmailModules');

        function ShowField(FieldID) {
            Znuny.Form.Input.Show(FieldID);

            // Workaround: Znuny.Form.Input does not handle the outer field-wrapper div
            $('#' + FieldID).closest('div.field-wrapper').show();
        }

        function HideField(FieldID) {
            Znuny.Form.Input.Hide(FieldID);

            // Workaround: Znuny.Form.Input does not handle the outer field-wrapper div
            $('#' + FieldID).closest('div.field-wrapper').hide();
        }

        function ResetConfigOptionFields() {
            var FieldIDs = [
                'CMD', 'Host', 'Port', 'Timeout', 'SkipSSLVerification', 'AuthenticationType',
                'AuthUser', 'AuthPassword', 'OAuth2TokenConfigID'
            ];

            $.each(FieldIDs, function(Index, FieldID) {
                HideField(FieldID);
                Znuny.Form.Input.Mandatory(FieldID, false);
            });

            // Reset available options for authentication types
            $('#AuthenticationType').html(OriginalAuthenticationOptions);

            Core.UI.InputFields.Activate();
        }

        function ShowConfigOptionFields(SendmailModule) {
            if (!SendmailModules[SendmailModule]) return;

            $.each(SendmailModules[SendmailModule], function(FieldID, ConfigOptions) {
                var CurrentValue;

                // Remove unavailable authentication types for this sendmail module.
                if (
                    FieldID === 'AuthenticationType'
                    && ConfigOptions.PossibleValues
                ) {
                    $('#AuthenticationType option').each(function() {
                        var OptionValue = $(this).val();

                        if (!OptionValue) return;

                        if (!ConfigOptions.PossibleValues[OptionValue]) {
                            $(this).remove();
                        }
                    });
                }

                CurrentValue = Znuny.Form.Input.Get(FieldID);
                if (
                    ConfigOptions['DefaultValue']
                    && !CurrentValue
                ) {
                    Znuny.Form.Input.Set(FieldID, ConfigOptions.DefaultValue);
                }

                if (ConfigOptions.Required) {
                    Znuny.Form.Input.Mandatory(FieldID, true);
                }

                ShowField(FieldID);
            });

            // Trigger change on authentication type, so credential fields can
            // be shown/hidden accordingly.
            $('#AuthenticationType').trigger('change');

            Core.UI.InputFields.Activate();
        }

        $('#SendmailModule').on('change', function(){
            var SendmailModule = $(this).val();

            ResetConfigOptionFields();
            ShowConfigOptionFields(SendmailModule);
        }).trigger('change');

        // Selection of authentication method
        $('#AuthenticationType').on('change', function() {
            var AuthenticationType = $(this).val(),
                SendmailModule = $('#SendmailModule').val(),
                ConfigOptions = SendmailModules[SendmailModule],
                AuthConfigOptions;

            $.each(['AuthUser', 'AuthPassword', 'OAuth2TokenConfigID'], function(Index, FieldID) {
                HideField(FieldID);
                Znuny.Form.Input.Mandatory(FieldID, false);
            });

            if (!ConfigOptions) return;
            if (!ConfigOptions.AuthenticationType) return;

            if (!ConfigOptions.AuthenticationType.PossibleValues) return;
            AuthConfigOptions = ConfigOptions.AuthenticationType.PossibleValues[AuthenticationType];
            if (!AuthConfigOptions) return;

            $.each(AuthConfigOptions, function(FieldID, ConfigOptions) {
                ShowField(FieldID);

                if (ConfigOptions.Required) {
                    Znuny.Form.Input.Mandatory(FieldID, true);
                }
            });

            Core.UI.InputFields.Activate();
        }).trigger('change');

        // Selection of fallback option
        $('#IsFallbackConfig').on('change', function() {
            var IsFallbackConfig = $(this).prop('checked');

            if (IsFallbackConfig) {
                HideField('EmailAddresses');
                Znuny.Form.Input.Mandatory('EmailAddresses', false);
            }
            else {
                ShowField('EmailAddresses');

                // Somehow does not work if set directly to true the first time.
                Znuny.Form.Input.Mandatory('EmailAddresses', false);
                Znuny.Form.Input.Mandatory('EmailAddresses', true);
            }

            Core.UI.InputFields.Activate();
        }).trigger('change');
    }

    /**
     * @name InitOverview
     * @memberof Core.Agent.Admin.SendmailConfig
     * @function
     * @description
     *      Init of overview.
     */
    TargetNS.InitOverview = function() {
        Core.UI.Table.InitTableFilter($("#FilterSendmailConfigs"), $("#SendmailConfigs"));

        $('.SendmailConfigDelete').on('click', function () {
            var DeleteURL = $(this).attr('data-url');

            Core.UI.Dialog.ShowDialog({
                Modal:        true,
                Title:        Core.Language.Translate('Delete outbound email profile'),
                HTML:         "<p>" + Core.Language.Translate('Do you really want to delete this outbound email profile?') + "</p>",
                PositionTop:  '150px',
                PositionLeft: 'Center',
                Buttons: [
                    {
                        Label: Core.Language.Translate('Cancel'),
                        Function: function () {
                            Core.UI.Dialog.CloseDialog($('.Dialog:visible'));
                        }
                    },
                    {
                        Label: Core.Language.Translate('Confirm'),
                        Function: function () {
                            Core.UI.Dialog.CloseDialog($('.Dialog:visible'));
                            window.location.href = DeleteURL;
                        },
                        Class: 'Primary'
                    }
                ],
                AllowAutoGrow: true
            });
        });
    };

    Core.Init.RegisterNamespace(TargetNS, 'APP_MODULE');

    return TargetNS;
}(Core.Agent.Admin.SendmailConfig || {}));
