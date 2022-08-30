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

Core.Language = (function (Namespace) {
    Namespace.RunUnitTests = function(){

        var TranslationData = {
            'yes':                          'ja',
            'no':                           'nein',
            'This is %s':                   'Das ist %s',
            'Complex %s with %s arguments': 'Komplexer %s mit %s Argumenten'
        },
        LanguageMetaData = {
            'DateFormat':           '%D.%M.%Y %T',
            'DateFormatLong':       '%T - %D.%M.%Y',
            'DateFormatShort':      '%D.%M.%Y',
            'DateInputFormat':      '%D.%M.%Y',
            'DateInputFormatLong':  '%D.%M.%Y - %T'
        };

        QUnit.module('Core.Language');

        QUnit.test('Translations', function(Assert){
            Core.Language.Load(LanguageMetaData, TranslationData);
            Assert.equal(Core.Language.Translate('yes'), 'ja');
            Assert.equal(Core.Language.Translate('no'), 'nein');
            Assert.equal(Core.Language.Translate('This is %s', 'OTRS'), 'Das ist OTRS');
            Assert.equal(Core.Language.Translate('This is %s', 'yes'), 'Das ist yes');
            Assert.equal(Core.Language.Translate('Complex %s with %s arguments', 'Text', 'vielen'), 'Komplexer Text mit vielen Argumenten');
        });
    };

    return Namespace;
}(Core.Language || {}));
