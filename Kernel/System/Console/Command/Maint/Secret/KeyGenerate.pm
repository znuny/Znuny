# --
# Copyright (C) 2021 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::Console::Command::Maint::Secret::KeyGenerate;

use strict;
use warnings;
use utf8;

use parent qw(Kernel::System::Console::BaseCommand);

our @ObjectDependencies = (
    'Kernel::System::Crypt::Secret',
);

sub Configure {
    my ( $Self, %Param ) = @_;

    $Self->Description(
        'Generate a random encryption key for use with Maint::Secret::Encrypt.'
    );

    return;
}

sub Run {
    my ( $Self, %Param ) = @_;

    my $SecretObject = $Kernel::OM->Get('Kernel::System::Crypt::Secret');

    my $Key = $SecretObject->GenerateKey();

    if ( !$Key ) {
        $Self->PrintError(
            "Could not generate a key. Is the Crypt::URandom module available (bundled in Kernel/cpan-lib)? "
                . "Check the log for details."
        );
        return $Self->ExitCodeError();
    }

    $Self->Print("<green>Generated key:</green>\n$Key\n\n");
    $Self->Print(
        "Store this value as the encryption key, using ONE of the following (do not store it in "
            . "Kernel/Config.pm!):\n\n"
            . "  - As an environment variable available to the webserver/cron process:\n"
            . "      export ZNUNY_CONFIG_SECRET_KEY='$Key'\n\n"
            . "  - In a key file outside of the webroot, referenced from Kernel/Config.pm, e.g.:\n"
            . "      \$Self->{ConfigSecretKeyFile} = '/etc/znuny/config_secret.key';\n"
            . "    Create the file with permissions 0600, owned by the webserver user, containing just the key.\n"
    );

    return $Self->ExitCodeOk();
}

1;
