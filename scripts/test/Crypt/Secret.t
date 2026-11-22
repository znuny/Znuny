# --
# Copyright (C) 2021 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

use strict;
use warnings;
use utf8;

use MIME::Base64 ();

use vars (qw($Self));

my $MainObject   = $Kernel::OM->Get('Kernel::System::Main');
my $SecretObject = $Kernel::OM->Get('Kernel::System::Crypt::Secret');
my $ConfigObject = $Kernel::OM->Get('Kernel::Config');
my $HelperObject = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');

# Remember and clean up environment/config so this test doesn't leak state.
local $ENV{ZNUNY_CONFIG_SECRET_KEY} = undef;
$ConfigObject->Set(
    Key   => 'ConfigSecretKeyFile',
    Value => undef,
);

# Values that are not wrapped as {AES256:...} must always be returned unchanged,
# regardless of whether a key is configured.
for my $PlainValue ( 'some-pass', '', '{not-an-aes-value}', '{4142abcd}' ) {
    $Self->Is(
        $SecretObject->Decrypt( Value => $PlainValue ),
        $PlainValue,
        "Decrypt() passthrough for non-AES256 value '$PlainValue'",
    );
}

$Self->Is(
    $SecretObject->Decrypt( Value => undef ),
    undef,
    'Decrypt() passthrough for undef value',
);

# Without any encryption key configured, Encrypt()/Decrypt() of an AES256 value must fail (return undef).
$Self->Is(
    $SecretObject->Encrypt( Value => 'some-pass' ),
    undef,
    'Encrypt() fails without a configured key',
);

SKIP_NO_CRYPTX:
{
    if ( !$MainObject->Require( 'Crypt::AuthEnc::GCM', Silent => 1 ) ) {
        $Self->True(
            1,
            'Skipping AES round-trip tests: CryptX (Crypt::AuthEnc::GCM) is not installed.',
        );
        last SKIP_NO_CRYPTX;
    }

    local $ENV{ZNUNY_CONFIG_SECRET_KEY} = 'unit-test-key-one';

    my $PlainText  = 'S3cr3t Pässw0rd!';
    my $CipherText = $SecretObject->Encrypt( Value => $PlainText );

    $Self->True(
        ( $CipherText && $CipherText =~ m/ \A \{AES256: [^:]+ : [^}]+ \} \z /xms ) ? 1 : 0,
        'Encrypt() returns a value in the expected {AES256:...} format',
    );

    $Self->Is(
        $SecretObject->Decrypt( Value => $CipherText ),
        $PlainText,
        'Decrypt() round-trips the value encrypted with the same key',
    );

    # Encrypting the same value twice must not produce the same ciphertext (random IV).
    my $CipherText2 = $SecretObject->Encrypt( Value => $PlainText );
    $Self->IsNotDeeply(
        $CipherText,
        $CipherText2,
        'Encrypt() uses a random IV (repeated encryption yields different ciphertext)',
    );
    $Self->Is(
        $SecretObject->Decrypt( Value => $CipherText2 ),
        $PlainText,
        'Decrypt() round-trips the second ciphertext as well',
    );

    # Decrypting with a different key must fail, not silently return garbage as-is.
    local $ENV{ZNUNY_CONFIG_SECRET_KEY} = 'unit-test-key-two';
    $Self->Is(
        $SecretObject->Decrypt( Value => $CipherText ),
        undef,
        'Decrypt() fails when the configured key does not match the one used for encryption',
    );

    my $GeneratedKey = $SecretObject->GenerateKey();
    $Self->True(
        ( $GeneratedKey && $GeneratedKey =~ m{ \A [0-9a-f]{64} \z }xms ) ? 1 : 0,
        'GenerateKey() returns a 256 bit (64 hex char) key',
    );
    $Self->IsNot(
        $SecretObject->GenerateKey(),
        $GeneratedKey,
        'GenerateKey() returns a different key on each call',
    );

    local $ENV{ZNUNY_CONFIG_SECRET_KEY} = 'unit-test-key-one';

    $Self->Is(
        $SecretObject->Encrypt( Value => '' ),
        '',
        'Encrypt() returns an empty value unchanged',
    );
    $Self->Is(
        $SecretObject->Encrypt( Value => undef ),
        undef,
        'Encrypt() returns undef for undef value',
    );

    my $LongPlainText  = 'x' x 1000;
    my $LongCipherText = $SecretObject->Encrypt( Value => $LongPlainText );
    $Self->Is(
        $SecretObject->Decrypt( Value => $LongCipherText ),
        $LongPlainText,
        'Round trip of a multi block value',
    );

    my $ExactBlockPlainText  = '0123456789abcdef';
    my $ExactBlockCipherText = $SecretObject->Encrypt( Value => $ExactBlockPlainText );
    $Self->Is(
        $SecretObject->Decrypt( Value => $ExactBlockCipherText ),
        $ExactBlockPlainText,
        'Round trip of a value with exactly one block (16 bytes)',
    );

    my $SpecialPlainText  = q{p'a"s$s{w}o:r\\d};
    my $SpecialCipherText = $SecretObject->Encrypt( Value => $SpecialPlainText );
    $Self->True(
        ( $SpecialCipherText =~ m/ \A \{AES256: [A-Za-z0-9+\/=]+ : [A-Za-z0-9+\/=]+ \} \z /xms ) ? 1 : 0,
        'Ciphertext only contains base64 characters, so it is safe for single quoted Perl strings',
    );
    $Self->Is(
        $SecretObject->Decrypt( Value => $SpecialCipherText ),
        $SpecialPlainText,
        'Round trip of a value with quotes, braces and colons',
    );

    # Characters above U+00FF can't be passed to the cipher as is, they need to be encoded first.
    my $WidePlainText  = 'Pass€wörd 密码';
    my $WideCipherText = eval { $SecretObject->Encrypt( Value => $WidePlainText ) };
    $Self->True(
        $WideCipherText ? 1 : 0,
        'Encrypt() handles characters above U+00FF' . ( $@ ? " (died: $@)" : '' ),
    );
    $Self->Is(
        $WideCipherText ? $SecretObject->Decrypt( Value => $WideCipherText ) : undef,
        $WidePlainText,
        'Round trip of a value with characters above U+00FF',
    );

    for my $MalformedValue (
        '{AES256:!!!!:!!!!}',
        '{AES256:' . MIME::Base64::encode_base64( 'short-iv', '' ) . ':' . MIME::Base64::encode_base64( 'x' x 16, '' )
        . '}',
        '{AES256:' . MIME::Base64::encode_base64( 'i' x 16, '' ) . ':' . MIME::Base64::encode_base64( 'odd', '' ) . '}',
        )
    {
        $Self->Is(
            scalar eval { $SecretObject->Decrypt( Value => $MalformedValue ) },
            undef,
            "Decrypt() fails for malformed value '$MalformedValue'",
        );
    }

    # Manipulated IV/ciphertext must be detected instead of returning a modified plain text.
    my ( $IVBase64, $CipherBase64 ) = $CipherText =~ m/ \A \{AES256: ( [^:]+ ) : ( [^}]+ ) \} \z /xms;
    my $IV = MIME::Base64::decode_base64($IVBase64);
    substr( $IV, 0, 1 ) = chr( ord( substr( $IV, 0, 1 ) ) ^ 1 );
    my $TamperedCipherText = '{AES256:' . MIME::Base64::encode_base64( $IV, '' ) . ':' . $CipherBase64 . '}';
    $Self->Is(
        $SecretObject->Decrypt( Value => $TamperedCipherText ),
        undef,
        'Decrypt() fails for a manipulated IV',
    );

    # Key file
    local $ENV{ZNUNY_CONFIG_SECRET_KEY} = undef;

    my $KeyFile         = $ConfigObject->Get('TempDir') . '/SecretTest' . $HelperObject->GetRandomID() . '.key';
    my $KeyFileLocation = $MainObject->FileWrite(
        Location   => $KeyFile,
        Content    => \"unit-test-key-one\n",
        Permission => '600',
    );
    $Self->True(
        $KeyFileLocation ? 1 : 0,
        'Key file written',
    );

    $ConfigObject->Set(
        Key   => 'ConfigSecretKeyFile',
        Value => $KeyFile,
    );

    $Self->Is(
        $SecretObject->Decrypt( Value => $CipherText ),
        $PlainText,
        'Decrypt() with key file (trailing newline is removed) decrypts value encrypted with the same key from env',
    );

    my $FileCipherText = $SecretObject->Encrypt( Value => $PlainText );
    $Self->Is(
        $SecretObject->Decrypt( Value => $FileCipherText ),
        $PlainText,
        'Round trip with key file',
    );

    local $ENV{ZNUNY_CONFIG_SECRET_KEY} = 'unit-test-key-two';
    $Self->Is(
        $SecretObject->Decrypt( Value => $FileCipherText ),
        undef,
        'Environment variable takes precedence over key file',
    );

    local $ENV{ZNUNY_CONFIG_SECRET_KEY} = '';
    $Self->Is(
        $SecretObject->Decrypt( Value => $FileCipherText ),
        $PlainText,
        'Empty environment variable falls back to key file',
    );

    $MainObject->FileWrite(
        Location   => $KeyFile,
        Content    => \'',
        Permission => '600',
    );
    $Self->Is(
        $SecretObject->Encrypt( Value => $PlainText ),
        undef,
        'Encrypt() fails with empty key file',
    );

    $MainObject->FileDelete(
        Location => $KeyFile,
    );
    $Self->Is(
        $SecretObject->Encrypt( Value => $PlainText ),
        undef,
        'Encrypt() fails if key file does not exist',
    );
    $Self->Is(
        $SecretObject->Decrypt( Value => $FileCipherText ),
        undef,
        'Decrypt() fails if key file does not exist',
    );

    $ConfigObject->Set(
        Key   => 'ConfigSecretKeyFile',
        Value => undef,
    );

    # Kernel::System::DB decrypts {AES256:...} DatabasePw
    local $ENV{ZNUNY_CONFIG_SECRET_KEY} = 'unit-test-key-one';

    my $DatabasePw = $SecretObject->Encrypt( Value => 'some-pass' );
    my $DBObject   = $Kernel::OM->Create(
        'Kernel::System::DB',
        ObjectParams => {
            DatabasePw => $DatabasePw,
        },
    );
    $Self->Is(
        $DBObject->{PW},
        'some-pass',
        'Kernel::System::DB decrypts {AES256:...} DatabasePw',
    );
}

1;
