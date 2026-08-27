// Copyright (C) 2021 Znuny GmbH, https://znuny.org/
// This software comes with ABSOLUTELY NO WARRANTY. For details, see
// the enclosed file COPYING for license information (AGPL). If you
// did not receive this file, see http://www.gnu.org/licenses/agpl.txt.

// nofilter(TidyAll::Plugin::Znuny::JavaScript::ESLint)
import juice from 'juice/client';

globalThis.inlineContent = function (Html, Css) {
    return juice.inlineContent(Html, Css, {
        removeStyleTags: true,
        preserveMediaQueries: false,
        applyAttributesTableElements: true,
    });
};