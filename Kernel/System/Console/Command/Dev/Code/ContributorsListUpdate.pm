# --
# Copyright (C) 2001-2021 OTRS AG, https://otrs.com/
# Copyright (C) 2021 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see https://www.gnu.org/licenses/gpl-3.0.txt.
# --

package Kernel::System::Console::Command::Dev::Code::ContributorsListUpdate;

use strict;
use warnings;

use IO::File;

use parent qw(Kernel::System::Console::BaseCommand);

our @ObjectDependencies = (
    'Kernel::Config',
);

sub Configure {
    my ( $Self, %Param ) = @_;

    $Self->Description('Update the list of contributors based on git commit information.');

    $Self->AddOption(
        Name        => 'generate',
        Description => "Generate (regenerate) the complete AUTHORS.md file instead of just adding new authors.",
        Required    => 0,
        HasValue    => 0,
    );

    return;
}

sub Run {
    my ( $Self, %Param ) = @_;

    chdir $Kernel::OM->Get('Kernel::Config')->Get('Home');

    # Check if we should generate the whole file
    my $Generate = $Self->GetOption('generate');

    if ($Generate) {
        my @Lines = qx{git log --format="%aN <%aE>"};
        my %Authors;
        map { chomp; $Authors{$_} = 1 if $_ !~ m/^[^<>]+ \s <>\s?$/smx } @Lines;

        my $FileHandle = IO::File->new( 'AUTHORS.md', 'w' );
        $FileHandle->print("The following persons contributed to Znuny:\n\n");

        for my $Author ( sort { lc($a) cmp lc($b) } keys %Authors ) {
            $FileHandle->print("* $Author\n");
        }
        $FileHandle->close();
        $Self->Print("<green>AUTHORS.md has been completely generated.</green>\n");
    }
    else {
        # First read existing authors
        my %ExistingAuthors;
        my $Header = "The following persons contributed to Znuny:\n\n";

        if ( -f 'AUTHORS.md' ) {
            my $FileHandle = IO::File->new( 'AUTHORS.md', 'r' );
            my $IsHeader   = 1;

            LINE:
            while ( my $Line = <$FileHandle> ) {
                if ($IsHeader) {
                    $IsHeader = 0;
                    next LINE;
                }
                if ( $Line !~ /^\* (.+)$/ ) {
                    next LINE;
                }
                $ExistingAuthors{$1} = 1;
            }
            $FileHandle->close();
        }

        # Get authors from recent commits
        my @Lines = qx{git log --format="%aN <%aE>"};
        my %NewAuthors;
        my $HasNewAuthors = 0;

        AUTHOR:
        for my $Author (@Lines) {
            chomp $Author;
            next AUTHOR if $Author =~ m/^[^<>]+ \s <>\s?$/smx;

            if ( !$ExistingAuthors{$Author} ) {
                $NewAuthors{$Author} = 1;
                $HasNewAuthors = 1;
            }
        }

        # Merge and sort all authors
        my %AllAuthors = ( %ExistingAuthors, %NewAuthors );

        if ($HasNewAuthors) {
            my $FileHandle = IO::File->new( 'AUTHORS.md', 'w' );
            $FileHandle->print($Header);

            for my $Author ( sort { lc($a) cmp lc($b) } keys %AllAuthors ) {
                $FileHandle->print("* $Author\n");
            }
            $FileHandle->close();

            for my $Author ( sort { lc($a) cmp lc($b) } keys %NewAuthors ) {
                $Self->Print("<green>Added new author: $Author</green>\n");
            }
        }
        else {
            $Self->Print("<yellow>No new authors found.</yellow>\n");
        }
    }

    return $Self->ExitCodeOk();
}

1;
