# --
# Copyright (C) 2001-2021 OTRS AG, https://otrs.com/
# Copyright (C) 2021-2022 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see https://www.gnu.org/licenses/gpl-3.0.txt.
# --

package Kernel::System::Console::Command::Maint::Stats::Generate;

use strict;
use warnings;

use parent qw(Kernel::System::Console::BaseCommand);

our @ObjectDependencies = (
    'Kernel::Config',
    'Kernel::Language',
    'Kernel::Output::PDF::Statistics',
    'Kernel::System::CSV',
    'Kernel::System::CheckItem',
    'Kernel::System::DateTime',
    'Kernel::System::Email',
    'Kernel::System::Excel',
    'Kernel::System::Main',
    'Kernel::System::Stats',
);

sub Configure {
    my ( $Self, %Param ) = @_;

    $Self->Description(
        'Generate (and send, optional) statistics which have been configured previously in the OTRS statistics module.'
    );

    $Self->AddOption(
        Name        => 'number',
        Description => "Statistic number as shown in the overview of AgentStats.",
        Required    => 1,
        HasValue    => 1,
        ValueRegex  => qr/\d+/smx,
    );
    $Self->AddOption(
        Name => 'params',
        Description =>
            "Parameters which should be passed to the statistic (e.g. Year=1977&Month=10, not for dynamic statistics).",
        Required   => 0,
        HasValue   => 1,
        ValueRegex => qr/.*/smx,
    );
    $Self->AddOption(
        Name        => 'target-filename',
        Description => "Filename for the generated file.",
        Required    => 0,
        HasValue    => 1,
        ValueRegex  => qr/.*/smx,
    );
    $Self->AddOption(
        Name => 'target-directory',
        Description =>
            "Directory to which the generated file should be written (e.g. /output/dir/). If a target directory is provided, no email will be sent.",
        Required   => 0,
        HasValue   => 1,
        ValueRegex => qr/.*/smx,
    );
    $Self->AddOption(
        Name        => 'format',
        Description => "Target format (CSV|Excel|Print) for which the file should be generated (defaults to CSV).",
        Required    => 0,
        HasValue    => 1,
        ValueRegex  => qr/(CSV|Excel|Print|PDF)/smx,
    );
    $Self->AddOption(
        Name        => 'separator',
        Description => "Define the separator in case of CSV as target format (defaults to ';').",
        Required    => 0,
        HasValue    => 1,
        ValueRegex  => qr/.*/smx,
    );
    $Self->AddOption(
        Name => 'with-header',
        Description =>
            "Add a heading line consisting of statistics title and creation date in case of Excel or CSV as output format.",
        Required   => 0,
        HasValue   => 0,
        ValueRegex => qr/.*/smx,
    );
    $Self->AddOption(
        Name => 'timezone',
        Description =>
            "Target time zone (e.g. Europe/Berlin) for which the file should be generated.",
        Required   => 0,
        HasValue   => 1,
        ValueRegex => qr/.*/smx,
    );
    $Self->AddOption(
        Name => 'language',
        Description =>
            "Target language (e.g. de) for which the file should be generated (will be OTRS default language or english as fallback if left empty).",
        Required   => 0,
        HasValue   => 1,
        ValueRegex => qr/.*/smx,
    );
    $Self->AddOption(
        Name        => 'mail-sender',
        Description => "Email address which should appear as sender for the generated file.",
        Required    => 0,
        HasValue    => 1,
        ValueRegex  => qr/.*/smx,
    );
    $Self->AddOption(
        Name        => 'mail-recipient',
        Description => "Recipient email address to which the generated file should be send.",
        Required    => 0,
        HasValue    => 1,
        Multiple    => 1,
        ValueRegex  => qr/.*/smx,
    );
    $Self->AddOption(
        Name        => 'mail-body',
        Description => "Body content for the email which has the generated statistics file attached.",
        Required    => 0,
        HasValue    => 1,
        ValueRegex  => qr/.*/smx,
    );

    return;
}

sub PreRun {
    my ( $Self, %Param ) = @_;

    # check if the passed stat number exists
    $Self->{StatNumber} = $Self->GetOption('number');
    $Self->{StatID} = $Kernel::OM->Get('Kernel::System::Stats')->StatNumber2StatID( StatNumber => $Self->{StatNumber} );
    if ( !$Self->{StatID} ) {
        die "There is no statistic with number '$Self->{StatNumber}'.\n";
    }

    # either target directory or mail recipient needs to be defined
    if ( !$Self->GetOption('target-directory') && !$Self->GetOption('mail-recipient') ) {
        die "Need either --target-directory or at least one --mail-recipient.\n";
    }

    # if params have been passed, we build up a body containing the configured params
    # which is then used as default
    $Self->{Params}   = $Self->GetOption('params');
    $Self->{MailBody} = $Self->GetOption('mail-body') || '';
    if ( !$Self->{MailBody} && $Self->{Params} ) {
        $Self->{MailBody} .= "Stats with following options:\n\n";
        $Self->{MailBody} .= "StatNumber: " . $Self->GetOption('number') . "\n";
        my @P = split( /&/, $Self->{Params} );
        for my $Param (@P) {
            my ( $Key, $Value ) = split( /=/, $Param, 2 );
            $Self->{MailBody} .= "$Key: $Value\n";
        }
    }

    # if there is a recipient, we also need a mail body
    if ( $Self->GetOption('mail-recipient') && !$Self->{MailBody} ) {
        die
            "You defined at least one --mail-recipient which means that you also need to define a mail body using --mail-body.\n";
    }

    # if a target directory has been passed, check if it exists
    $Self->{TargetDirectory} = $Self->GetOption('target-directory');
    if ( $Self->{TargetDirectory} && !-e $Self->{TargetDirectory} ) {
        die "The target directory '$Self->{TargetDirectory}' does not exist.\n";
    }

    # set up used language
    $Self->{Language} = $Kernel::OM->Get('Kernel::Config')->Get('DefaultLanguage') || 'en';
    if ( $Self->GetOption('language') ) {
        $Self->{Language} = $Self->GetOption('language');
        $Kernel::OM->ObjectParamAdd(
            'Kernel::Language' => {
                UserLanguage => $Self->{Language},
            },
        );
    }

    # set up used format & separator
    $Self->{Format}    = $Self->GetOption('format')    || 'CSV';
    $Self->{Separator} = $Self->GetOption('separator') || ';';

    return;
}

sub Run {
    my ( $Self, %Param ) = @_;

    $Self->Print("<yellow>Generating statistic number $Self->{StatNumber}...</yellow>\n");

    my $CurSysDTObject = $Kernel::OM->Create('Kernel::System::DateTime');

    my %GetParam;
    my $Stat = $Kernel::OM->Get('Kernel::System::Stats')->StatsGet(
        StatID => $Self->{StatID},
        UserID => 1,
    );

    if ( $Stat->{StatType} eq 'static' ) {
        $GetParam{Year}  = $CurSysDTObject->Get()->{Year};
        $GetParam{Month} = $CurSysDTObject->Get()->{Month};
        $GetParam{Day}   = $CurSysDTObject->Get()->{Day};

        # get params from -p
        # only for static files
        my $Params = $Kernel::OM->Get('Kernel::System::Stats')->GetParams(
            StatID => $Self->{StatID},
            UserID => 1,
        );
        for my $ParamItem ( @{$Params} ) {
            if ( !$ParamItem->{Multiple} ) {
                my $Value = $Self->GetParam(
                    Param  => $ParamItem->{Name},
                    Params => $Self->{Params}
                );
                if ( defined $Value ) {
                    $GetParam{ $ParamItem->{Name} } =
                        $Self->GetParam(
                        Param  => $ParamItem->{Name},
                        Params => $Self->{Params},
                        );
                }
                elsif ( defined $ParamItem->{SelectedID} ) {
                    $GetParam{ $ParamItem->{Name} } = $ParamItem->{SelectedID};
                }
            }
            else {
                my @Value = $Self->GetArray(
                    Param  => $ParamItem->{Name},
                    Params => $Self->{Params},
                );
                if (@Value) {
                    $GetParam{ $ParamItem->{Name} } = \@Value;
                }
                elsif ( defined $ParamItem->{SelectedID} ) {
                    $GetParam{ $ParamItem->{Name} } = [ $ParamItem->{SelectedID} ];
                }
            }
        }
    }
    elsif ( $Stat->{StatType} eq 'dynamic' ) {
        %GetParam = %{$Stat};

        # overwrite the default stats timezone with the given timezone
        my $TimeZone = $Self->GetOption('timezone');
        if ( defined $TimeZone && length $TimeZone ) {
            $GetParam{TimeZone} = $TimeZone;
        }
    }

    # run stat...
    my @StatArray = @{
        $Kernel::OM->Get('Kernel::System::Stats')->StatsRun(
            StatID   => $Self->{StatID},
            GetParam => \%GetParam,
            UserID   => 1,
        )
    };

    # generate output
    my $TitleArrayRef  = shift(@StatArray);
    my $Title          = $TitleArrayRef->[0];
    my $HeadArrayRef   = shift(@StatArray);
    my $CountStatArray = @StatArray;
    my $Time           = $CurSysDTObject->ToString();
    my @WithHeader;
    if ( $Self->GetOption('with-header') ) {
        @WithHeader = ( "Name: $Title", "Created: $Time" );
    }
    if ( !@StatArray ) {
        push( @StatArray, [ ' ', 0 ] );
    }
    my %Attachment;

    if ( $Self->{Format} eq 'Print' || $Self->{Format} eq 'PDF' ) {

        my $PDFString = $Kernel::OM->Get('Kernel::Output::PDF::Statistics')->GeneratePDF(
            Stat         => $Stat,
            Title        => $Title,
            HeadArrayRef => $HeadArrayRef,
            StatArray    => \@StatArray,
            TimeZone     => $GetParam{TimeZone},
        );

        # save the pdf with the title and timestamp as filename, or read it from param
        my $Filename;
        if ( $Self->GetOption('target-filename') ) {
            $Filename = $Self->GetOption('target-filename');
        }
        else {
            $Filename = $Kernel::OM->Get('Kernel::System::Stats')->StringAndTimestamp2Filename(
                String   => $Stat->{Title} . " Created",
                TimeZone => $GetParam{TimeZone},
            );
        }
        %Attachment = (
            Filename    => $Filename . ".pdf",
            ContentType => "application/pdf",
            Content     => $PDFString,
            Encoding    => "base64",
            Disposition => "attachment",
        );
    }
    elsif ( $Self->{Format} eq 'Excel' ) {

        # create the Excel data
        my $StatsBackendObject = $Kernel::OM->Get( $Stat->{ObjectModule} );
        my $ExcelObject        = $Kernel::OM->Get('Kernel::System::Excel');

        my %Array2ExcelParams;
        if ( $StatsBackendObject->can('Worksheets') ) {

            my $Worksheets = $StatsBackendObject->Worksheets();
            %Array2ExcelParams = (
                Worksheets => $Worksheets,
            );
        }
        else {
            my @TableData        = ( [ @{$HeadArrayRef} ], @StatArray );
            my $FormatDefinition = $ExcelObject->GetFormatDefinition(
                Stat => $Stat,
            );

            %Array2ExcelParams = (
                Data             => \@TableData,
                FormatDefinition => $FormatDefinition,
            );
        }

        my $Output = $ExcelObject->Array2Excel(
            %Array2ExcelParams,
            Stat => $Stat,
        );

        # save the Excel with the title and timestamp as filename, or read it from param
        my $Filename;
        if ( $Self->GetOption('target-filename') ) {
            $Filename = $Self->GetOption('target-filename');
        }
        else {
            $Filename = $Kernel::OM->Get('Kernel::System::Stats')->StringAndTimestamp2Filename(
                String   => $Stat->{Title} . " Created",
                TimeZone => $GetParam{TimeZone},
            );
        }

        %Attachment = (
            Filename    => $Filename . ".xlsx",
            ContentType => "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
            Content     => $Output,
            Encoding    => "base64",
            Disposition => "attachment",
        );
    }
    else {

        # Create the CSV data
        my $Output = $Kernel::OM->Get('Kernel::System::CSV')->Array2CSV(
            WithHeader => \@WithHeader,
            Head       => $HeadArrayRef,
            Data       => \@StatArray,
            Separator  => $Self->{Separator},
        );

        # save the csv with the title and timestamp as filename, or read it from param
        my $Filename;
        if ( $Self->GetOption('target-filename') ) {
            $Filename = $Self->GetOption('target-filename');
        }
        else {
            $Filename = $Kernel::OM->Get('Kernel::System::Stats')->StringAndTimestamp2Filename(
                String   => $Stat->{Title} . " Created",
                TimeZone => $GetParam{TimeZone},
            );
        }

        %Attachment = (
            Filename    => $Filename . ".csv",
            ContentType => "text/csv",
            Content     => $Output,
            Encoding    => "base64",
            Disposition => "attachment",
        );
    }

    # write output
    if ( $Self->{TargetDirectory} ) {

        my $Success = $Kernel::OM->Get('Kernel::System::Main')->FileWrite(
            Location => "$Self->{TargetDirectory}/$Attachment{Filename}",
            Content  => \$Attachment{Content},
            Mode     => 'binmode',
        );

        if ($Success) {
            $Self->Print("  Writing file <yellow>$Self->{TargetDirectory}/$Attachment{Filename}</yellow>.\n");
            $Self->Print("<green>Done.</green>\n");
            return $Self->ExitCodeOk();
        }
        else {
            $Self->PrintError("Can't write $Self->{TargetDirectory}/$Attachment{Filename}!");
            return $Self->ExitCodeError();
        }
    }

    # send email
    RECIPIENT:
    for my $Recipient ( @{ $Self->GetOption('mail-recipient') // [] } ) {

        # recipient check
        if ( !$Kernel::OM->Get('Kernel::System::CheckItem')->CheckEmail( Address => $Recipient ) ) {

            $Self->PrintError(
                "Email address $Recipient invalid, skipping address."
                    . $Kernel::OM->Get('Kernel::System::CheckItem')->CheckError()
            );
            next RECIPIENT;
        }

        my $Result = $Kernel::OM->Get('Kernel::System::Email')->Send(
            From       => $Self->GetOption('mail-sender'),
            To         => $Recipient,
            Subject    => "[Stats - $CountStatArray Records] $Title; Created: $Time",
            Body       => $Kernel::OM->Get('Kernel::Language')->Translate( $Self->{MailBody} ),
            Charset    => 'utf-8',
            Attachment => [ {%Attachment}, ],
        );
        if ( $Result->{Success} ) {
            $Self->Print("<yellow>Email sent to '$Recipient' at $Time.</yellow>\n");
        }
        else {
            $Self->Print("<red>Email sending to '$Recipient' has failed at $Time.</red>\n");
        }

    }

    $Self->Print("<green>Done.</green>\n");
    return $Self->ExitCodeOk();
}

sub GetParam {
    my ( $Self, %Param ) = @_;

    if ( !$Param{Param} ) {
        $Self->PrintError("Need 'Param' in GetParam()");
    }
    my @P = split( /&/, $Param{Params} || '' );
    for my $Param (@P) {
        my ( $Key, $Value ) = split( /=/, $Param, 2 );
        return $Value if ( $Key eq $Param{Param} );
    }
    return;
}

sub GetArray {
    my ( $Self, %Param ) = @_;

    if ( !$Param{Param} ) {
        $Self->PrintError("Need 'Param' in GetArray()");
    }
    my @P = split( /&/, $Param{Params} || '' );
    my @Array;
    for my $Param (@P) {
        my ( $Key, $Value ) = split( /=/, $Param, 2 );
        if ( $Key eq $Param{Param} ) {
            push( @Array, $Value );
        }
    }
    return @Array;
}

1;
