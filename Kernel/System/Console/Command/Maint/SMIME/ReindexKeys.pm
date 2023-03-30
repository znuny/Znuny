# --
# Copyright (C) 2021 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::Console::Command::Maint::SMIME::ReindexKeys;

use strict;
use warnings;

use parent qw(Kernel::System::Console::BaseCommand);

our @ObjectDependencies = (
    'Kernel::System::Crypt::SMIME',
    'Kernel::Config'
);

sub Configure {
    my ( $Self, %Param ) = @_;

    $Self->Description('Reindex S/MIME keys.');
    $Self->AddArgument(
        Name        => 'key-type',
        Description => "Key types that will be re-indexed (all | private | public).",
        Required    => 1,
        HasValue    => 0,
        ValueRegex  => qr/\A(all|private|public)\z/,
    );

    return;
}

sub Run {
    my ( $Self, %Param ) = @_;

    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');
    my $CryptObject  = $Kernel::OM->Get('Kernel::System::Crypt::SMIME');
    my $KeyType      = $Self->GetArgument('key-type');

    if ( !$ConfigObject->Get('SMIME') ) {
        $Self->Print("<yellow>'S/MIME' is not activated in SysConfig, can't continue!</yellow>\n");
        return $Self->ExitCodeOk();
    }

    $Self->Print("<yellow>Re-indexing S/MIME keys...</yellow>\n");

    if ( $KeyType eq 'public' || $KeyType eq 'all' ) {
        my $ReIndexCertificate = $CryptObject->ReIndexCertificate( CanReHash => 1 );
        if ( $ReIndexCertificate->{Success} ) {
            $Self->Print( 'Public: ' . $ReIndexCertificate->{Details} );
        }
        else {
            $Self->Print("<red>$ReIndexCertificate->{Details}</red>");
        }
    }

    if ( $KeyType eq 'private' || $KeyType eq 'all' ) {
        my $ReIndexPrivate = $CryptObject->ReIndexPrivate( CanNormalize => 1 );
        if ( $ReIndexPrivate->{Success} ) {
            $Self->Print( 'Private: ' . $ReIndexPrivate->{Details} );
        }
        else {
            $Self->Print("<red>$ReIndexPrivate->{Details}</red>");
        }
    }

    $Self->Print("<green>Done.</green>\n");
    return $Self->ExitCodeOk();
}

1;
