# --
# Copyright (C) 2021 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --
## nofilter(TidyAll::Plugin::Znuny::CodeStyle::STDERRCheck)

package Kernel::System::Console::BaseExportImportCommand;

use strict;
use warnings;
use utf8;

use Getopt::Long();
use IO::Interactive();
use Encode::Locale();
use Kernel::System::VariableCheck qw(:all);

use parent qw(Kernel::System::Console::BaseCommand);

our @ObjectDependencies = (
    'Kernel::Config',
    'Kernel::System::Cache',
    'Kernel::System::Log',
);

our $SuppressANSI = 0;

=head1 NAME

Kernel::System::Console::BaseExportImportCommand - command base class

=head1 DESCRIPTION

Base export/import class for related console commands.

=head1 PUBLIC INTERFACE

=head2 PreRun()

perform additional validations/preparations before Run(). Override this method in your commands.

If this method returns, execution will be continued. If it throws an exception with die(), the program aborts at this point, and Run() will not be called.

=cut

sub PreRun {
    my ( $Self, %Param ) = @_;

    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');
    my $Type         = $Self->GetOption('type');

    my $Check = $Self->_ActionObjectCheck(
        Object => $Type,
    );

    my $ActionLc = lc $Self->{_Action};

    if ( !$Check ) {
        die "Could not find a valid module to $ActionLc data\n";    ## no critic
    }

    if ( $Check != 1 && $Check->{ErrorMessage} ) {
        die $Check->{ErrorMessage};                                 ## no critic
    }

    my $ObjectConfig = $Self->{ $Self->{_SettingKey} }->{$Type};
    $Self->{CurrentModuleHandlerObject} = $ObjectConfig->{ModuleHandlerObject};

    my $FunctionName = $Self->{_Action} . 'CommandInit';
    my $InitSuccess  = $Self->{CurrentModuleHandlerObject}->$FunctionName( CommandObject => $Self );

    die "Could not initialize $ActionLc command for type: $Type!" if !$InitSuccess;    ## no critic

    $FunctionName = $Self->{_Action} . 'Configure';

    # set command configuration for specified type
    my %ConfigureData = $Self->{CurrentModuleHandlerObject}->$FunctionName();

    my $IsOption;
    my $NewConfig;

    for my $Name ( sort keys %ConfigureData ) {
        my $Config = $ConfigureData{$Name};
        $Config->{Name}                            = $Name;
        $IsOption->{ $Config->{Priority} }         = delete $Config->{IsOption};
        $NewConfig->{ delete $Config->{Priority} } = $Config;
    }

    for my $Priority ( sort keys %{$NewConfig} ) {
        if ( $IsOption->{$Priority} ) {
            $Self->AddOption(
                %{ $NewConfig->{$Priority} }
            );
        }
        else {
            $Self->AddArgument(
                %{ $NewConfig->{$Priority} }
            );
        }
    }

    # show help for specified type
    if ( $Self->{ParsedGlobalOptions}->{help} ) {
        print "\n" . $Self->GetUsageHelp();
        return 2;
    }

    # perform default checks for specified type
    $Self->{_ParsedARGV} = $Self->_ParseCommandlineArguments( $Self->{_CommandlineArguments} );

    if ( !%{ $Self->{_ParsedARGV} // {} } ) {
        print STDERR "\n" . $Self->GetUsageHelp();
        return 2;
    }

    $FunctionName = $Self->{_Action} . 'PreCheck';

    # perform module handler related checks
    my $PreCheckResult = $Self->{CurrentModuleHandlerObject}->$FunctionName( ObjectConfig => $ObjectConfig );

    if ( !$PreCheckResult->{Success} ) {
        print STDERR "\n" . $Self->GetUsageHelp();
        die $PreCheckResult->{ErrorMessage} || 'Undefined error occured on command pre-checks!';    ## no critic
    }

    return;
}

=head2 Execute()

this method will parse/validate the command line arguments supplied by the user.
If that was ok, the Run() method of the command will be called.

=cut

sub Execute {
    my ( $Self, @CommandlineArguments ) = @_;

    # Normally, nothing was logged until this point, so the LogObject does not exist yet.
    #   Change the LogPrefix so that it indicates which command causes the log entry.
    #   In future we might need to check if it was created and update it on the fly.
    $Kernel::OM->ObjectParamAdd(
        'Kernel::System::Log' => {
            LogPrefix => 'Znuny-znuny.Console.pl-' . $Self->Name(),
        },
    );

    if (
        IsArrayRefWithData( $Self->{_GlobalOptions} )
        &&
        $Self->{_GlobalOptions}->[0]->{Name} &&
        $Self->{_GlobalOptions}->[0]->{Name} eq 'help'
        )
    {
        $Self->{_GlobalOptions}->[0]->{Description}
            = 'Display help for this command, or in combination with --type for type specific help.';
    }

    $Self->{ParsedGlobalOptions} = $Self->_ParseGlobalOptions( \@CommandlineArguments );

    # Don't allow to run these scripts as root.
    if ( !$Self->{ParsedGlobalOptions}->{'allow-root'} && $> == 0 ) {    # $EFFECTIVE_USER_ID
        $Self->PrintError(
            "You cannot run znuny.Console.pl as root. Please run it as the 'znuny' user or with the help of su:"
        );
        $Self->Print("  <yellow>su -c \"bin/znuny.Console.pl MyCommand\" -s /bin/bash otrs</yellow>\n");
        return $Self->ExitCodeError();
    }

    # Disable in-memory cache to avoid problems with long running scripts.
    $Kernel::OM->Get('Kernel::System::Cache')->Configure(
        CacheInMemory => 0,
    );

    # Only run if the command was setup ok.
    if ( !$Self->{_ConfigureSuccessful} ) {
        $Self->PrintError("Aborting because the command was not successfully configured.");
        return $Self->ExitCodeError();
    }

    # First handle the optional global options.
    if ( $Self->{ParsedGlobalOptions}->{'no-ansi'} ) {
        $Self->ANSI(0);
    }

    if ( $Self->{ParsedGlobalOptions}->{quiet} ) {
        $Self->{Quiet} = 1;
    }

    # show global help
    if ( $Self->{ParsedGlobalOptions}->{help} && !grep { $_ eq '--type' } @CommandlineArguments ) {
        print "\n" . $Self->GetUsageHelp();
        return $Self->ExitCodeError();
    }

    # Parse command line arguments and bail out in case of error,
    # of course with a helpful usage screen.
    @{ $Self->{_CommandlineArguments} } = @CommandlineArguments;
    $Self->{_ParsedARGV} = $Self->_ParseCommandlineArguments(
        \@CommandlineArguments,
        _IgnoreUnknownArgCheck => 1,
    );
    if ( !%{ $Self->{_ParsedARGV} // {} } ) {
        print STDERR "\n" . $Self->GetUsageHelp();
        return $Self->ExitCodeError();
    }

    # If we have an interactive console, make sure that the output can handle UTF-8.
    if (
        IO::Interactive::is_interactive()
        && !$Kernel::OM->Get('Kernel::Config')->Get('SuppressConsoleEncodingCheck')
        )
    {
        my $ConsoleEncoding = lc $Encode::Locale::ENCODING_CONSOLE_OUT;    ## no critic

        if ( $ConsoleEncoding ne 'utf-8' ) {
            $Self->PrintError(
                "The terminal encoding should be set to 'utf-8', but is '$ConsoleEncoding'. Some characters might not be displayed correctly."
            );
        }
    }

    my $PreRunResult;
    eval { $PreRunResult = $Self->PreRun(); };
    if ($@) {
        $Self->PrintError($@);
        return $Self->ExitCodeError();
    }
    if ( $PreRunResult && $PreRunResult eq 2 ) {
        return $Self->ExitCodeError();
    }

    # Make sure we get a proper exit code to return to the shell.
    my $ExitCode;
    eval {
        # Make sure that PostRun() works even if a user presses ^C.
        local $SIG{INT} = sub {
            $Self->PostRun();
            exit $Self->ExitCodeError();
        };
        $ExitCode = $Self->Run();
    };
    if ($@) {
        $Self->PrintError($@);
        $ExitCode = $Self->ExitCodeError();
    }

    eval { $Self->PostRun(); };
    if ($@) {
        $Self->PrintError($@);
        $ExitCode ||= $Self->ExitCodeError();    # switch from 0 (ok) to error
    }

    if ( !defined $ExitCode ) {
        $Self->PrintError("Command $Self->{Name} did not return a proper exit code.");
        $ExitCode = $Self->ExitCodeError();
    }

    return $ExitCode;
}

=head2 _ParseCommandlineArguments()

parses and validates the command line arguments provided by the user according to
the configured arguments and options of the command.

Returns a hash with argument and option values if all needed values were supplied
and correct, or undef otherwise.

=cut

sub _ParseCommandlineArguments {
    my ( $Self, $Arguments, %Param ) = @_;

    Getopt::Long::Configure('pass_through');
    Getopt::Long::Configure('no_auto_abbrev');

    my %OptionValues;

    my %KnownOptions;

    OPTION:
    for my $Option ( @{ $Self->{_Options} // [] }, @{ $Self->{_GlobalOptions} } ) {
        $KnownOptions{ '--' . $Option->{Name} } = 1;

        my $Lookup = $Option->{Name};
        if ( $Option->{HasValue} ) {
            $Lookup .= '=s';
            if ( $Option->{Multiple} ) {
                $Lookup .= '@';
            }
        }

        # Option with multiple values
        if ( $Option->{HasValue} && $Option->{Multiple} ) {

            my @Values;

            Getopt::Long::GetOptionsFromArray(
                $Arguments,
                $Lookup => \@Values,
            );

            if ( !@Values ) {
                if ( !$Option->{Required} ) {
                    next OPTION;
                }

                $Self->PrintError("please provide option '--$Option->{Name}'.");
                return;
            }

            for my $Value (@Values) {
                if ( $Option->{HasValue} && $Value !~ $Option->{ValueRegex} ) {
                    $Self->PrintError("please provide a valid value for option '--$Option->{Name}'.");
                    return;
                }
            }

            $OptionValues{ $Option->{Name} } = \@Values;
        }

        # Option with no or a single value
        else {

            my $Value;

            Getopt::Long::GetOptionsFromArray(
                $Arguments,
                $Lookup => \$Value,
            );

            if ( !defined $Value ) {
                if ( !$Option->{Required} ) {
                    next OPTION;
                }

                $Self->PrintError("please provide option '--$Option->{Name}'.");
                return;
            }

            if ( $Option->{HasValue} && $Value !~ $Option->{ValueRegex} ) {
                $Self->PrintError("please provide a valid value for option '--$Option->{Name}'.");
                return;
            }

            $OptionValues{ $Option->{Name} } = $Value;
        }
    }

    # Check for remaining known options that could not be parsed.
    my @RemainingKnownOptions = grep { exists $KnownOptions{$_} } @{$Arguments};
    if (@RemainingKnownOptions) {
        my $OptionsString = join ', ', sort @RemainingKnownOptions;
        $Self->PrintError("the following options have an unexpected or missing value: $OptionsString.");
        return;
    }

    my %ArgumentValues;

    ARGUMENT:
    for my $Argument ( @{ $Self->{_Arguments} // [] } ) {
        if ( !@{$Arguments} ) {
            if ( !$Argument->{Required} ) {
                next ARGUMENT;
            }

            $Self->PrintError("please provide a value for argument '$Argument->{Name}'.");
            return;
        }

        my $Value = shift @{$Arguments};

        if ( $Value !~ $Argument->{ValueRegex} ) {
            $Self->PrintError("please provide a valid value for argument '$Argument->{Name}'.");
            return;
        }

        $ArgumentValues{ $Argument->{Name} } = $Value;
    }

    # check for superfluous arguments
    if ( @{$Arguments} && !$Param{_IgnoreUnknownArgCheck} ) {
        my $Error = "found unknown arguments on the command line ('";
        $Error .= join "', '", @{$Arguments};
        $Error .= "').\n";
        $Self->PrintError($Error);
        return;
    }

    return {
        Options   => \%OptionValues,
        Arguments => \%ArgumentValues,
    };
}

sub _ActionObjectsGet {
    my ( $Self, %Param ) = @_;

    my $ConfigObject  = $Kernel::OM->Get('Kernel::Config');
    my $CommandConfig = $ConfigObject->Get("Admin::Object::$Self->{_Action}::Command");

    my $SettingsKey = $Self->{_SettingKey};

    return if !IsHashRefWithData($CommandConfig);
    return if !IsHashRefWithData( $CommandConfig->{$SettingsKey} );

    my %Objects;
    PRIORITY:
    for my $Priority ( sort keys %{ $CommandConfig->{$SettingsKey} } ) {
        my $ObjectsData = $CommandConfig->{$SettingsKey}->{$Priority};
        next PRIORITY if !IsHashRefWithData($ObjectsData);

        for my $ObjectName ( sort keys %{$ObjectsData} ) {
            $Objects{$ObjectName} = $ObjectsData->{$ObjectName};
        }
    }

    my $ObjectsData;
    NAME:
    for my $Name ( sort keys %Objects ) {
        my $ModuleHandlerObject;
        my $ModuleHandler = $Objects{$Name}->{ModuleHandler};
        next NAME if !$ModuleHandler;

        eval {
            $ModuleHandlerObject = $Kernel::OM->Get("Kernel::System::Command::ExportImport::$ModuleHandler");
        };

        $ObjectsData->{$Name} = {
            Config                  => $Objects{$Name},
            ModuleHandlerObject     => $ModuleHandlerObject,
            ModuleHandlerObjectName => $ModuleHandler,
        } if !$@ && $ModuleHandlerObject;
    }

    return $ObjectsData;
}

sub _ActionObjectCheck {
    my ( $Self, %Param ) = @_;

    my $LogObject = $Kernel::OM->Get('Kernel::System::Log');

    my $SettingsKey = $Self->{_SettingKey};

    my $ActionObjects = $Self->{$SettingsKey};
    return if !IsHashRefWithData($ActionObjects);
    my $ObjectData              = $ActionObjects->{ $Param{Object} };
    my $ModuleHandlerObjectName = $ObjectData->{ModuleHandlerObjectName};
    my $ModuleHandlerObject     = $ObjectData->{ModuleHandlerObject};

    return if !$ModuleHandlerObject;

    if ( !$ModuleHandlerObject->{Types}->{ $Param{Object} } ) {
        return {
            ErrorMessage => "Unsupported module or errors occured: \"$ModuleHandlerObjectName\"!"
        };
    }

    if (
        !$ModuleHandlerObject->can("$Self->{_Action}PreCheck")
        ||
        !$ModuleHandlerObject->can("$Self->{_Action}Handle") ||
        !$ModuleHandlerObject->can("$Self->{_Action}CommandInit")
        )
    {
        my $ActionLc = lc $Self->{_Action};
        return {
            ErrorMessage => "Module \"$ModuleHandlerObjectName\" does not provide a possibility to $ActionLc data!"
        };
    }

    return 1;
}

sub _ProcessConfiguration {
    my ( $Self, %Param ) = @_;

    my $SettingKey = $Self->{_SettingKey};
    my %ConfigurationProcessed;

    # get configured objects possible arguments/options
    MODULE:
    for my $Module ( sort keys %{ $Self->{$SettingKey} } ) {
        my $ModuleHandlerObject     = $Self->{$SettingKey}->{$Module}->{ModuleHandlerObject};
        my $ModuleHandlerObjectName = $Self->{$SettingKey}->{$Module}->{ModuleHandlerObjectName};

        $ModuleHandlerObject->{Types}->{$Module} = 1;

        next MODULE if $ConfigurationProcessed{$ModuleHandlerObjectName};

        $ModuleHandlerObject->{ModuleHandlerObjectName} = $ModuleHandlerObjectName;
        $ConfigurationProcessed{$ModuleHandlerObjectName} = 1;
    }
    return 1;
}

1;
