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
Core.Debug = Core.Debug || {};

Core.Debug = (function (Namespace) {
    Namespace.RunUnitTests = function(){
        QUnit.module('Core.Debug');
        QUnit.test('Core.Debug.CheckDependency()', function(Assert){

            Core.Debug.DummyFunction = function(){};

            Assert.expect(4);

            Assert.equal(
                Core.Debug.CheckDependency('Core.Debug.RunUnitTests', 'Core.Debug.DummyFunction', 'existing_function', true),
                true
            );

            Assert.equal(
                Core.Debug.CheckDependency('Core.Debug.RunUnitTests', 'Core.Debug.DummyFunction2', 'existing_function', true),
                false
            );

            Assert.equal(
                Core.Debug.CheckDependency('Core.Debug.RunUnitTests', 'Core.Debug2.DummyFunction2', 'existing_function', true),
                false
                );

            Assert.equal(
                Core.Debug.CheckDependency('Core.Debug.RunUnitTests', 'nonexisting_function', 'nonexisting_function', true),
                false
            );

            delete Core.Debug.DummyFunction;
        });
    };

    return Namespace;
}(Core.Debug || {}));
