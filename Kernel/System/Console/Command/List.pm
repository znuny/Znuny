# --
# Copyright (C) 2001-2021 OTRS AG, https://otrs.com/
# Copyright (C) 2021 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see https://www.gnu.org/licenses/gpl-3.0.txt.
# --

package Kernel::System::Console::Command::List;

use strict;
use warnings;
use List::Util qw(max);

use Kernel::System::Console::InterfaceConsole;

use parent qw(Kernel::System::Console::BaseCommand);

our @ObjectDependencies = (
    'Kernel::Config',
    'Kernel::System::Main',
);

sub Configure {
    my ( $Self, %Param ) = @_;

    $Self->Description('List available commands.');

    return;
}

sub Run {
    my ( $Self, %Param ) = @_;

    my $ProductName    = $Kernel::OM->Get('Kernel::Config')->Get('ProductName');
    my $ProductVersion = $Kernel::OM->Get('Kernel::Config')->Get('Version');

    my $UsageText = "<green>$ProductName</green> (<yellow>$ProductVersion</yellow>)\n\n";
    $UsageText .= "<yellow>Usage:</yellow>\n";
    $UsageText .= " otrs.Console.pl command [options] [arguments]\n";
    $UsageText .= "\n<yellow>Options:</yellow>\n";

    OPTION:
    for my $Option ( @{ $Self->{_GlobalOptions} // [] } ) {
        next OPTION if $Option->{Invisible};
        my $OptionShort = "[--$Option->{Name}]";
        $UsageText .= sprintf " <green>%-40s</green> - %s", $OptionShort, $Option->{Description} . "\n";
    }
    $UsageText .= "\n<yellow>Available commands:</yellow>\n";

    my $PreviousCommandNameSpace = '';

    my @Commands         = $Self->ListAllCommands();
    my $MaxCommandLength = max map {length} @Commands;
    $MaxCommandLength -= length('Kernel::System::Console::Command::');

    COMMAND:
    for my $Command (@Commands) {
        my $CommandObject = $Kernel::OM->Get($Command);
        my $CommandName   = $CommandObject->Name();

        # Group by top-level namespace
        my ($CommandNamespace) = $CommandName =~ m/^([^:]+)::/smx;
        $CommandNamespace //= '';
        if ( $CommandNamespace ne $PreviousCommandNameSpace ) {
            $UsageText .= "<yellow>$CommandNamespace</yellow>\n";
            $PreviousCommandNameSpace = $CommandNamespace;
        }
        $UsageText .= sprintf(
            " <green>%-" . $MaxCommandLength . "s</green> - %s\n",
            $CommandName, $CommandObject->Description()
        );
    }

    $Self->Print($UsageText);

    return $Self->ExitCodeOk();
}

=head2 ListAllCommands()

Returns all available commands, sorted first by directory and then by file name.

    my @Commands = $CommandObject->ListAllCommands();

Returns:

    my @Commands = (
        'Kernel::System::Console::Command::Help',
        'Kernel::System::Console::Command::List',
        ...
    );

=cut

sub ListAllCommands {
    my ( $Self, %Param ) = @_;

    my @CommandFiles = $Kernel::OM->Get('Kernel::System::Main')->DirectoryRead(
        Directory => $Kernel::OM->Get('Kernel::Config')->Get('Home') . '/Kernel/System/Console/Command',
        Filter    => '*.pm',
        Recursive => 1,
    );

    my @Commands;

    COMMANDFILE:
    for my $CommandFile (@CommandFiles) {
        next COMMANDFILE if ( $CommandFile =~ m{/Internal/}xms );
        $CommandFile =~ s{^.*(Kernel/System.*)[.]pm$}{$1}xmsg;
        $CommandFile =~ s{/+}{::}xmsg;
        push @Commands, $CommandFile;
    }

    # Sort first by directory, then by File
    my $Sort = sub {
        my ( $DirA, $FileA ) = split( /::(?=[^:]+$)/smx, $a );
        my ( $DirB, $FileB ) = split( /::(?=[^:]+$)/smx, $b );
        return $DirA cmp $DirB || $FileA cmp $FileB;
    };

    @Commands = sort $Sort @Commands;

    return @Commands;
}

1;
