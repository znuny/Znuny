# --
# Copyright (C) 2001-2021 OTRS AG, https://otrs.com/
# Copyright (C) 2021-2022 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see https://www.gnu.org/licenses/gpl-3.0.txt.
# --

package Kernel::System::Console::InterfaceConsole;

use strict;
use warnings;

our @ObjectDependencies = (
    'Kernel::System::Console::Command::List',
    'Kernel::System::Main',
);

=head1 NAME

Kernel::System::Console::InterfaceConsole - console interface

=head1 DESCRIPTION

...

=head1 PUBLIC INTERFACE

=head2 new()

Don't use the constructor directly, use the ObjectManager instead:

    my $InterfaceConsoleObject = $Kernel::OM->Get('Kernel::System::Console::InterfaceConsole');

=cut

sub new {
    my ( $Type, %Param ) = @_;

    my $Self = {};
    bless( $Self, $Type );

    return $Self;
}

=head2 Run()

execute a command. Returns the shell status code to be used by exit().

    my $StatusCode = $InterfaceConsoleObject->Run( @ARGV );

=cut

sub Run {
    my ( $Self, @CommandlineArguments ) = @_;

    my $CommandName;

    # Catch bash completion calls
    if ( $ENV{COMP_LINE} ) {
        $CommandName = 'Kernel::System::Console::Command::Internal::BashCompletion';
        return $Kernel::OM->Get($CommandName)->Execute(@CommandlineArguments);
    }

    # If we don't have any arguments OR the first argument is an option and not a command name,
    #   show the overview screen instead.
    if ( !@CommandlineArguments || substr( $CommandlineArguments[0], 0, 2 ) eq '--' ) {
        $CommandName = 'Kernel::System::Console::Command::List';
        return $Kernel::OM->Get($CommandName)->Execute(@CommandlineArguments);
    }

    # Ok, let's try to find the command.
    $CommandName = 'Kernel::System::Console::Command::' . $CommandlineArguments[0];

    if ( $Kernel::OM->Get('Kernel::System::Main')->Require( $CommandName, Silent => 1 ) ) {

        # Regular case: everything was ok, execute command.
        # Remove first parameter (command itself) to not confuse further parsing
        shift @CommandlineArguments;
        return $Kernel::OM->Get($CommandName)->Execute(@CommandlineArguments);
    }

    # If the command cannot be found/loaded, also show the overview screen.
    my $CommandObject = $Kernel::OM->Get('Kernel::System::Console::Command::List');
    $CommandObject->PrintError("Could not find $CommandName.\n\n");
    $CommandObject->Execute();
    return 127;    # EXIT_CODE_COMMAND_NOT_FOUND, see http://www.tldp.org/LDP/abs/html/exitcodes.html
}

1;

=head1 TERMS AND CONDITIONS

This software is part of the OTRS project (L<https://otrs.org/>).

This software comes with ABSOLUTELY NO WARRANTY. For details, see
the enclosed file COPYING for license information (GPL). If you
did not receive this file, see L<https://www.gnu.org/licenses/gpl-3.0.txt>.

=cut
