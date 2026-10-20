# --
# Copyright (C) 2021 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::Crypt::Secret;

use strict;
use warnings;
use utf8;

use Encode       ();
use Fcntl        qw(S_IRWXG S_IRWXO);
use MIME::Base64 qw(encode_base64 decode_base64);
use Digest::SHA  qw(sha256);

our @ObjectDependencies = (
    'Kernel::Config',
    'Kernel::System::Log',
    'Kernel::System::Main',
);

=head1 NAME

Kernel::System::Crypt::Secret - encrypt/decrypt secrets stored in Kernel/Config.pm

=head1 DESCRIPTION

Some credentials (e.g. C<DatabasePw>, the various LDAP C<SearchUserPw>
settings) must be read before SysConfig is available and therefore have to be
stored literally in F<Kernel/Config.pm>. This module allows such values to be
stored as real, key-based ciphertext instead of plain text.

An encrypted value looks like this and can be pasted directly into
F<Kernel/Config.pm> in place of the plain text value:

    {AES256:<base64 IV>:<base64 ciphertext and authentication tag>}

Values are encrypted with AES-256 in GCM mode, so a wrong key or a manipulated
value is always detected by L</Decrypt()>.

Use C<bin/znuny.Console.pl Maint::Secret::Encrypt> to create one.

Values that are not wrapped in C<{AES256:...}> are returned unchanged by
L</Decrypt()>, so this can safely be called on any config value, encrypted or
not.

=head2 Encryption key

The encryption key is derived from a passphrase which is deliberately NOT
stored in F<Kernel/Config.pm> (otherwise nothing would be gained). It is read
from, in order of precedence:

=over 4

=item 1. The C<ZNUNY_CONFIG_SECRET_KEY> environment variable.

=item 2. A file whose path is configured via C<$Self-E<gt>{ConfigSecretKeyFile}>
in F<Kernel/Config.pm>. This file should live outside the web root, be owned
by the webserver user and have permissions C<0600>.

=back

Use C<bin/znuny.Console.pl Maint::Secret::KeyGenerate> to create a new
random passphrase.

=head2 Threat model

This protects secrets at rest in F<Kernel/Config.pm> (e.g. against being
accidentally committed to version control, included in backups, or read by
someone who can view the file but not the key). It does NOT protect against
an attacker who can read arbitrary files as the webserver user, since that
user needs access to the key at runtime as well. Keep the key file (or the
environment variable) at least as well protected as F<Kernel/Config.pm>
itself, ideally better (e.g. excluded from routine backups/dumps of the config
directory).

=head2 Requirements

Encryption/decryption requires the CPAN module L<CryptX> (for
C<Crypt::AuthEnc::GCM>), which is not bundled with Znuny. Install it e.g. via
C<cpanm CryptX> or your OS package manager. Random IVs and keys are generated
with L<Crypt::URandom>, which is bundled with Znuny.

Values are UTF-8 encoded before encryption, so any character can be used.

=cut

sub new {
    my ( $Type, %Param ) = @_;

    my $Self = {};
    bless( $Self, $Type );

    # Byte lengths of the GCM nonce and authentication tag.
    $Self->{IVLength}  = 12;
    $Self->{TagLength} = 16;

    return $Self;
}

=head2 Encrypt()

Encrypts a plain text value for storage in Kernel/Config.pm.

    my $CipherText = $SecretObject->Encrypt(
        Value => 'some-pass',
    );

Returns C<undef> and logs an error if no key is configured or CryptX is not
installed.

=cut

sub Encrypt {
    my ( $Self, %Param ) = @_;

    my $LogObject  = $Kernel::OM->Get('Kernel::System::Log');
    my $MainObject = $Kernel::OM->Get('Kernel::System::Main');

    return undef         if !defined $Param{Value};    ## no critic (Subroutines::ProhibitExplicitReturnUndef)
    return $Param{Value} if !length $Param{Value};

    my $Key = $Self->_GetKey();
    if ( !$Key ) {
        $LogObject->Log(
            Priority => 'error',
            Message  => 'Cannot encrypt config value: no encryption key configured. '
                . 'Set the ZNUNY_CONFIG_SECRET_KEY environment variable or '
                . '$Self->{ConfigSecretKeyFile} in Kernel/Config.pm.',
        );
        return undef;    ## no critic (Subroutines::ProhibitExplicitReturnUndef)
    }

    MODULE:
    for my $Module (qw(Crypt::AuthEnc::GCM Crypt::URandom)) {
        next MODULE if $MainObject->Require(
            $Module,
            Silent => 1,
        );

        $LogObject->Log(
            Priority => 'error',
            Message  => "Cannot encrypt config value: $Module is not installed.",
        );
        return undef;    ## no critic (Subroutines::ProhibitExplicitReturnUndef)
    }

    my $PlainBytes = Encode::encode( 'UTF-8', $Param{Value} );
    my $IV         = Crypt::URandom::urandom( $Self->{IVLength} );
    my ( $CipherBytes, $Tag ) = Crypt::AuthEnc::GCM::gcm_encrypt_authenticate( 'AES', $Key, $IV, '', $PlainBytes );

    return '{AES256:' . encode_base64( $IV, '' ) . ':' . encode_base64( $CipherBytes . $Tag, '' ) . '}';
}

=head2 Decrypt()

Decrypts a value previously created by L</Encrypt()>. Values that are not
wrapped as C<{AES256:...}> are returned unchanged, so this is safe to call
unconditionally on any config value.

    my $PlainText = $SecretObject->Decrypt(
        Value => $ConfigObject->Get('DatabasePw'),
    );

=cut

sub Decrypt {
    my ( $Self, %Param ) = @_;

    my $LogObject  = $Kernel::OM->Get('Kernel::System::Log');
    my $MainObject = $Kernel::OM->Get('Kernel::System::Main');

    my $Value = $Param{Value};
    return $Value if !defined $Value;
    return $Value if $Value !~ m/ \A \{AES256: ( [^:]+ ) : ( [^}]+ ) \} \z /xms;

    my ( $IVBase64, $CipherBase64 ) = ( $1, $2 );

    my $Key = $Self->_GetKey();
    if ( !$Key ) {
        $LogObject->Log(
            Priority => 'error',
            Message  => 'Cannot decrypt AES256-protected config value: no encryption key configured. '
                . 'Set the ZNUNY_CONFIG_SECRET_KEY environment variable or '
                . '$Self->{ConfigSecretKeyFile} in Kernel/Config.pm.',
        );
        return undef;    ## no critic (Subroutines::ProhibitExplicitReturnUndef)
    }

    if (
        !$MainObject->Require(
            'Crypt::AuthEnc::GCM',
            Silent => 1,
        )
        )
    {
        $LogObject->Log(
            Priority => 'error',
            Message  => 'Cannot decrypt AES256-protected config value: Crypt::AuthEnc::GCM (CryptX) is not installed. '
                . "Install it, e.g. via 'cpanm CryptX'.",
        );
        return undef;    ## no critic (Subroutines::ProhibitExplicitReturnUndef)
    }

    my $IV          = decode_base64($IVBase64);
    my $CipherBytes = decode_base64($CipherBase64);

    my $PlainBytes;
    if ( length $IV == $Self->{IVLength} && length $CipherBytes >= $Self->{TagLength} ) {
        my $Tag = substr( $CipherBytes, -$Self->{TagLength}, $Self->{TagLength}, '' );
        $PlainBytes = eval {
            Crypt::AuthEnc::GCM::gcm_decrypt_verify( 'AES', $Key, $IV, '', $CipherBytes, $Tag );
        };
    }

    if ( !defined $PlainBytes ) {
        $LogObject->Log(
            Priority => 'error',
            Message  => 'Cannot decrypt AES256-protected config value: '
                . 'wrong encryption key or manipulated/malformed value.',
        );
        return undef;    ## no critic (Subroutines::ProhibitExplicitReturnUndef)
    }

    return Encode::decode( 'UTF-8', $PlainBytes );
}

=head2 GenerateKey()

Generates a new random passphrase suitable for use as the encryption key
(as an environment variable value or the content of a key file).

    my $Passphrase = $SecretObject->GenerateKey();

=cut

sub GenerateKey {
    my ( $Self, %Param ) = @_;

    my $LogObject  = $Kernel::OM->Get('Kernel::System::Log');
    my $MainObject = $Kernel::OM->Get('Kernel::System::Main');

    if (
        !$MainObject->Require(
            'Crypt::URandom',
            Silent => 1,
        )
        )
    {
        $LogObject->Log(
            Priority => 'error',
            Message  => 'Cannot generate encryption key: Crypt::URandom is not available.',
        );
        return undef;    ## no critic (Subroutines::ProhibitExplicitReturnUndef)
    }

    return unpack( 'H*', Crypt::URandom::urandom(32) );
}

sub _GetKey {
    my ($Self) = @_;

    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');
    my $LogObject    = $Kernel::OM->Get('Kernel::System::Log');
    my $MainObject   = $Kernel::OM->Get('Kernel::System::Main');

    my $Passphrase = $ENV{ZNUNY_CONFIG_SECRET_KEY};

    if ( !defined $Passphrase || !length $Passphrase ) {
        my $KeyFile = $ConfigObject->Get('ConfigSecretKeyFile');

        return undef if !$KeyFile;    ## no critic (Subroutines::ProhibitExplicitReturnUndef)

        if ( !-e $KeyFile ) {
            $LogObject->Log(
                Priority => 'error',
                Message  => "ConfigSecretKeyFile '$KeyFile' does not exist.",
            );
            return undef;    ## no critic (Subroutines::ProhibitExplicitReturnUndef)
        }

        # Warn (but don't fail) if permissions are more open than necessary.
        my $Mode = ( stat($KeyFile) )[2];
        if ( defined $Mode && ( $Mode & ( S_IRWXG | S_IRWXO ) ) ) {
            $LogObject->Log(
                Priority => 'notice',
                Message  => "ConfigSecretKeyFile '$KeyFile' is readable/writable by group or other. "
                    . "Recommended permissions are 0600.",
            );
        }

        my $Lines = $MainObject->FileRead(
            Location => $KeyFile,
            Mode     => 'binmode',
            Result   => 'ARRAY',
        );
        return undef if !$Lines;    ## no critic (Subroutines::ProhibitExplicitReturnUndef)

        $Passphrase = $Lines->[0];
        chomp $Passphrase if defined $Passphrase;
    }

    return undef if !defined $Passphrase || !length $Passphrase;    ## no critic (Subroutines::ProhibitExplicitReturnUndef)

    # Derive a fixed-length 256 bit key from the (arbitrary length) passphrase.
    return sha256($Passphrase);
}

1;
