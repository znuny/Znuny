# --
# Copyright (C) 2021 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::Console::Command::Maint::Secret::Encrypt;

use strict;
use warnings;
use utf8;

use Encode ();

use parent qw(Kernel::System::Console::BaseCommand);

our @ObjectDependencies = (
    'Kernel::System::Crypt::Secret',
    'Kernel::System::Encode',
);

sub Configure {
    my ( $Self, %Param ) = @_;

    $Self->Description(
        'Encrypt a value (e.g. a database or LDAP bind password) for inclusion in Kernel/Config.pm, '
            . 'using real key-based AES-256 encryption. See Kernel::System::Crypt::Secret for details '
            . 'on how the encryption key is configured.'
    );
    $Self->AddArgument(
        Name        => 'value',
        Description => 'The value (e.g. password) to be encrypted.',
        Required    => 1,
        ValueRegex  => qr/.*/smx,
    );

    return;
}

sub Run {
    my ( $Self, %Param ) = @_;

    my $SecretObject = $Kernel::OM->Get('Kernel::System::Crypt::Secret');
    my $EncodeObject = $Kernel::OM->Get('Kernel::System::Encode');

    my $Value = $Self->GetArgument('value');
    chomp $Value;

    # Command line arguments are passed as UTF-8 bytes.
    if ( !Encode::is_utf8($Value) ) {
        $EncodeObject->EncodeInput( \$Value );
    }

    my $CipherText = $SecretObject->Encrypt(
        Value => $Value,
    );

    if ( !$CipherText ) {
        $Self->PrintError(
            "Could not encrypt the value. Make sure an encryption key is configured "
                . "(ZNUNY_CONFIG_SECRET_KEY environment variable or \$Self->{ConfigSecretKeyFile} in "
                . "Kernel/Config.pm - see 'Maint::Secret::KeyGenerate' to create one) and that the "
                . "CryptX module is installed. Check the log for details."
        );
        return $Self->ExitCodeError();
    }

    $Self->Print("<green>Encrypted value:</green>\n$CipherText\n\n");
    $Self->Print(
        "Paste this in place of the plain text value in Kernel/Config.pm, e.g.:\n"
            . "  \$Self->{DatabasePw} = '$CipherText';\n\n"
            . "This value can only be decrypted with the same encryption key that was used to encrypt it - "
            . "make sure that key is available wherever this configuration is used (e.g. all nodes of a "
            . "cluster).\n"
    );

    return $Self->ExitCodeOk();
}

1;
