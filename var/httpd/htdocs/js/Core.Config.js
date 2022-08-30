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

/**
 * @namespace Core.Config
 * @memberof Core
 * @author OTRS AG
 * @description
 *      This namespace contains the config options and functions.
 */
Core.Config = (function (TargetNS) {
    /**
     * @private
     * @name Config
     * @memberof Core.Config
     * @member {Object}
     * @description
     *      The global config object
     */
    var Config = {},
    /**
     * @private
     * @name ConfigPrefix
     * @memberof Core.Config
     * @member {String}
     * @description
     *      The prefix for all config keys to avoid name conflicts
     */
        ConfigPrefix = '';

    if (!Core.Debug.CheckDependency('Core.Config', 'Core.Data', 'Core.Data')) {
        return false;
    }

    /**
     * @name Set
     * @memberof Core.Config
     * @function
     * @param {String} Key - The name of the config option (also combined ones like Richtext.Width)
     * @param {Object} Value - The value of the option. Can be every kind of javascript variable type.
     * @description
     *      Sets a single config value.
     */
    TargetNS.Set = function (Key, Value) {
        var Keys = Key.split('.'),
            KeyToken,
            ConfigLevel = Config,
            Count = 0;

        for (KeyToken in Keys) {
            if (Keys.hasOwnProperty(KeyToken)) {
                if (Keys.length === Count + 1) {
                    ConfigLevel[ConfigPrefix + Keys[KeyToken]] = Value;
                }
                else if (typeof ConfigLevel[ConfigPrefix + Keys[KeyToken]] === 'undefined') {
                    ConfigLevel[ConfigPrefix + Keys[KeyToken]] = {};
                    ConfigLevel = ConfigLevel[ConfigPrefix + Keys[KeyToken]];
                }
                else {
                    ConfigLevel = ConfigLevel[ConfigPrefix + Keys[KeyToken]];
                }
                Count++;
            }
        }
    };

    /**
     * @name Get
     * @memberof Core.Config
     * @function
     * @returns {Object} The value of the option. Can be every kind of javascript variable type. Returns undefined if setting could not be found.
     * @param {String} Key - The name of the config option (also combined ones like Richtext.Width).
     * @param {Object} [DefaultValue] - If nothing is saved in the config, return this default value.
     * @description
     *      Gets a single config value.
     */
    TargetNS.Get = function (Key, DefaultValue) {
        var Keys = Key.split('.'),
            KeyToken,
            ConfigLevel = Config,
            Count = 0;

        for (KeyToken in Keys) {
            if (Keys.hasOwnProperty(KeyToken)) {
                // if namespace does not exists in config object, there is nothing to search for or to return
                if (typeof ConfigLevel !== 'object') {
                    // If DefaultValue is not set, this also returns undefined
                    return DefaultValue;
                }
                // if we are in the last step of the namespace return the saved value. If nothing is saved return the default value
                if (Keys.length === Count + 1) {
                    return ConfigLevel[ConfigPrefix + Keys[KeyToken]] || DefaultValue;
                }
                // otherwise go one level deeper and try again
                else {
                    ConfigLevel = ConfigLevel[ConfigPrefix + Keys[KeyToken]];
                }
                Count++;
            }
        }
    };

    /**
     * @name AddConfig
     * @memberof Core.Config
     * @function
     * @param {Object} Data - The config data to include as a javascript object
     * @param {String} ConfigKey - The key in the config where the data structure is saved to. If undefined, the Data is added to the root of the hash.
     * @description
     *      This function includes the given data into the config hash.
     */
    TargetNS.AddConfig = function (Data, ConfigKey) {
        var ConfigOptions,
            Keys,
            KeyToken,
            ConfigLevel = Config,
            Count = 0;

        /* Because objects in javascript are called-by-reference, the given data object is just a reference.
         * Saving this to the config hash would only save the reference to the original object.
         * If this original object is changed (or if the object is changed in the config hash) it would also
         * "change" the other references.
         * We have to *really* copy the object, to be sure to have no reference to the given parameter object.
         */
        ConfigOptions = Core.Data.CopyObject(Data);

        if (typeof ConfigKey === 'undefined') {
            $.each(Data, function (Key, Value) {
                TargetNS.Set(Key,Value);
            });
        }
        else {
            Keys = ConfigKey.split('.');
            for (KeyToken in Keys) {
                if (Keys.length === Count + 1) {
                    ConfigLevel[ConfigPrefix + Keys[KeyToken]] = ConfigOptions;
                }
                else {
                    if (typeof ConfigLevel[ConfigPrefix + Keys[KeyToken]] === 'undefined') {
                        ConfigLevel = ConfigLevel[ConfigPrefix + Keys[KeyToken]];
                    }
                    else {
                        ConfigLevel = ConfigLevel[ConfigPrefix + Keys[KeyToken]];
                    }
                    Count++;
                }
            }
        }
    };

    /*
     * Different config options, that are provided from start
     */

    /**
     * @description
     *     This variable contains a hash of blacklisted browsers
     *     of the agent interface and their recognition functions.
     *     Each function returns true, if the browser is detected.
     */
    TargetNS.AddConfig({
        'Microsoft Internet Explorer 5.5': function () {
            return ($.browser.msie && $.browser.version === '5.5');
        },
        'Microsoft Internet Explorer 6': function () {
            return ($.browser.msie && $.browser.version === '6.0');
        },
        'Microsoft Internet Explorer 7': function () {
            return ($.browser.msie && $.browser.version === '7.0');
        },
        'Microsoft Internet Explorer 8': function () {
            return ($.browser.msie && $.browser.version === '8.0');
        },
        'Microsoft Internet Explorer 9': function () {
            return ($.browser.msie && $.browser.version === '9.0');
        },
        'Microsoft Internet Explorer 10': function () {
            return ($.browser.msie && $.browser.version === '10.0');
        },
        'Konqueror (without WebKit engine)': function () {
            return ($.browser.webkit && navigator.vendor === 'KDE');
        },
        // all Netscape, Mozilla, Firefox before version 31 (Gecko version 31)
        'Netscape, old Mozilla, old Firefox': function () {
            var BrowserVersion,
                BrowserDetected = false;
            if ($.browser.mozilla) {
                BrowserVersion = $.browser.version.split('.');
                if (parseInt(BrowserVersion[0], 10) < 31) {
                    BrowserDetected = true;
                }
            }
            return BrowserDetected;
        },
        // Safari version 5 and older on Mac and Windows (webkit version 534.x.x)
        'Safari Version 5 and older': function () {
            var BrowserVersion = $.browser.version.split('.');
            return ($.browser.safari && parseInt(BrowserVersion[0], 10) < 535);
        }
    }, 'BrowserBlackList::Agent');

    /**
     * @description
     *     This variable contains a hash of blacklisted browsers
     *     of the customer interface and their recognition functions.
     *     Each function returns true, if the browser is detected.
     */
    TargetNS.AddConfig({
        'Microsoft Internet Explorer 5.5': function () {
            return ($.browser.msie && $.browser.version === '5.5');
        },
        'Microsoft Internet Explorer 6': function () {
            return ($.browser.msie && $.browser.version === '6.0');
        },
        'Microsoft Internet Explorer 7': function () {
            return ($.browser.msie && $.browser.version === '7.0');
        },
        'Microsoft Internet Explorer 8': function () {
            return ($.browser.msie && $.browser.version === '8.0');
        },
        'Microsoft Internet Explorer 9': function () {
            return ($.browser.msie && $.browser.version === '9.0');
        },
        'Microsoft Internet Explorer 10': function () {
            return ($.browser.msie && $.browser.version === '10.0');
        },
        'Konqueror (without WebKit engine)': function () {
            return ($.browser.webkit && navigator.vendor === 'KDE');
        },
        // all Netscape, Mozilla, Firefox before version 31 (Gecko version 31)
        'Netscape, old Mozilla, old Firefox': function () {
            var BrowserVersion,
                BrowserDetected = false;
            if ($.browser.mozilla) {
                BrowserVersion = $.browser.version.split('.');
                if (parseInt(BrowserVersion[0], 10) < 31) {
                    BrowserDetected = true;
                }
            }
            return BrowserDetected;
        },
        // Safari version 5 and older on Mac and Windows (webkit version 534.x.x)
        'Safari Version 5 and older': function () {
            var BrowserVersion = $.browser.version.split('.');
            return ($.browser.safari && parseInt(BrowserVersion[0], 10) < 535);
        }
    }, 'BrowserBlackList::Customer');

    return TargetNS;
}(Core.Config || {}));
