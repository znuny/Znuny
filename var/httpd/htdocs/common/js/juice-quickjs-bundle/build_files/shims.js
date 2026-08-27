// Copyright (C) 2021 Znuny GmbH, https://znuny.org/
// This software comes with ABSOLUTELY NO WARRANTY. For details, see
// the enclosed file COPYING for license information (AGPL). If you
// did not receive this file, see http://www.gnu.org/licenses/agpl.txt.

// nofilter(TidyAll::Plugin::Znuny::JavaScript::ESLint)
export let Buffer = {
    isBuffer: () => false,
    from: (s) => s,
};
export let process = {
    env: { NODE_ENV: 'production' },
    nextTick: (fn, ...args) => fn(...args),
    version: 'v0.0.0',
};

const B64 = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';

export function atob(Input) {
    const Str = String(Input).replace(/=+$/, '');
    let Output = '';
    let Bits = 0, Acc = 0;
    for (const Ch of Str) {
        const Idx = B64.indexOf(Ch);
        if (Idx === -1) continue;
        Acc = (Acc << 6) | Idx;
        Bits += 6;
        if (Bits >= 8) {
            Bits -= 8;
            Output += String.fromCharCode((Acc >> Bits) & 0xff);
        }
    }
    return Output;
}

export function btoa(Input) {
    const Str = String(Input);
    let Output = '';
    for (let I = 0; I < Str.length; I += 3) {
        const A = Str.charCodeAt(I);
        const B = Str.charCodeAt(I + 1);
        const C = Str.charCodeAt(I + 2);
        Output += B64[A >> 2];
        Output += B64[((A & 3) << 4) | (B >> 4)];
        Output += I + 1 < Str.length ? B64[((B & 15) << 2) | (C >> 6)] : '=';
        Output += I + 2 < Str.length ? B64[C & 63] : '=';
    }
    return Output;
}