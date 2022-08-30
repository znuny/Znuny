# --
# Copyright (C) 2001-2021 OTRS AG, https://otrs.com/
# Copyright (C) 2021-2022 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see https://www.gnu.org/licenses/gpl-3.0.txt.
# --

package Kernel::Modules::AdminProcessManagement;
## nofilter(TidyAll::Plugin::OTRS::Perl::Dumper)

use strict;
use warnings;
use Data::Dumper;

use Kernel::System::VariableCheck qw(:all);
use Kernel::Language qw(Translatable);

our $ObjectManagerDisabled = 1;

sub new {
    my ( $Type, %Param ) = @_;

    my $Self = {%Param};
    bless( $Self, $Type );

    return $Self;
}

sub Run {
    my ( $Self, %Param ) = @_;

    my $ParamObject = $Kernel::OM->Get('Kernel::System::Web::Request');

    $Self->{Subaction} = $ParamObject->GetParam( Param => 'Subaction' ) || '';

    my $ProcessID = $ParamObject->GetParam( Param => 'ID' )       || '';
    my $EntityID  = $ParamObject->GetParam( Param => 'EntityID' ) || '';

    # get parameter from web browser
    my $GetParam = $Self->_GetParams();
    $GetParam->{ProcessEntityID} ||= $EntityID;

    my $EntityObject = $Kernel::OM->Get('Kernel::System::ProcessManagement::DB::Entity');

    # get the list of updated or deleted entities
    my $EntitySyncStateList = $EntityObject->EntitySyncStateList(
        UserID => $Self->{UserID}
    );

    my $SynchronizeMessage = Translatable(
        'Process Management information from database is not in sync with the system configuration, please synchronize all processes.'
    );

    if ( IsArrayRefWithData($EntitySyncStateList) ) {

        # create a notification if system is not up to date
        $Param{NotifyData} = [
            {
                Info => $SynchronizeMessage,
            },
        ];
    }

    # get needed objects
    my $LayoutObject  = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $ProcessObject = $Kernel::OM->Get('Kernel::System::ProcessManagement::DB::Process');
    my $StateObject   = $Kernel::OM->Get('Kernel::System::ProcessManagement::DB::Process::State');
    my $ConfigObject  = $Kernel::OM->Get('Kernel::Config');

    # ------------------------------------------------------------ #
    # ProcessImport
    # ------------------------------------------------------------ #
    if ( $Self->{Subaction} eq 'ProcessImport' ) {

        # challenge token check for write action
        $LayoutObject->ChallengeTokenCheck();

        my $Content;

        my $Home = $Kernel::OM->Get('Kernel::Config')->Get('Home');

        my $MainObject = $Kernel::OM->Get('Kernel::System::Main');

        my $ExampleProcess = $ParamObject->GetParam( Param => 'ExampleProcess' );
        my $FileWithoutExtension;

        if ($ExampleProcess) {

            my $ExampleProcessFilename = $ParamObject->GetParam( Param => 'ExampleProcess' );
            $ExampleProcessFilename =~ s{/+|\.{2,}}{}smx;    # remove slashes and ..

            if ( !$ExampleProcessFilename ) {
                return $Kernel::OM->Get('Kernel::Output::HTML::Layout')->FatalError(
                    Message => Translatable('Need ExampleProcesses!'),
                );
            }

            # extract file name without extension
            $ExampleProcessFilename =~ m{(.*?)\.yml$}smx;
            $FileWithoutExtension = $1;

            # run _pre.pm if available
            if ( -e "$Home/var/processes/examples/" . $FileWithoutExtension . "_pre.pm" ) {

                my $BackendName = 'var::processes::examples::' . $FileWithoutExtension . '_pre';

                my $Loaded = $MainObject->Require(
                    $BackendName,
                );

                if ($Loaded) {
                    my $BackendPre = $Kernel::OM->Get(
                        $BackendName,
                    );

                    my %Status = $BackendPre->Run();
                    if ( !$Status{Success} ) {

                        # show the error screen
                        return $LayoutObject->ErrorScreen(
                            Message => $Status{Error},
                        );
                    }
                }
            }

            $Content = $MainObject->FileRead(
                Location => "$Home/var/processes/examples/$ExampleProcessFilename",
                Mode     => 'utf8',
            );

            if ( !$Content ) {
                return $Kernel::OM->Get('Kernel::Output::HTML::Layout')->FatalError(
                    Message =>
                        $LayoutObject->{LanguageObject}->Translate( 'Could not read %s!', $ExampleProcessFilename ),
                );
            }

            $Content = ${ $Content || \'' };
        }
        else {
            my $FormID      = $ParamObject->GetParam( Param => 'FormID' ) || '';
            my %UploadStuff = $ParamObject->GetUploadAll(
                Param => 'FileUpload',
            );
            $Content = $UploadStuff{Content};
        }

        my $OverwriteExistingEntities = $ParamObject->GetParam( Param => 'OverwriteExistingEntities' );

        # import the process YAML file
        my %ProcessImport = $ProcessObject->ProcessImport(
            Content                   => $Content,
            OverwriteExistingEntities => $OverwriteExistingEntities,
            UserID                    => $Self->{UserID},
        );

        if ( !$ProcessImport{Success} ) {

            # show the error screen
            return $LayoutObject->ErrorScreen(
                Message => $ProcessImport{Message},
                Comment => $ProcessImport{Comment} || '',
            );
        }
        else {
            # Run _post.pm if available.
            if (
                $ExampleProcess
                && -e "$Home/var/processes/examples/" . $FileWithoutExtension . "_post.pm"
                )
            {
                my $BackendName = 'var::processes::examples::' . $FileWithoutExtension . '_post';

                my $Loaded = $MainObject->Require(
                    $BackendName,
                );

                if ($Loaded) {

                    my $BackendPost = $Kernel::OM->Get(
                        $BackendName,
                    );

                    my %Status = $BackendPost->Run();
                    if ( !$Status{Success} ) {

                        # show the error screen
                        return $LayoutObject->ErrorScreen(
                            Message => $Status{Error},
                        );
                    }
                }
            }

            # show the overview with success informations
            $Param{NotifyData} = [
                {
                    Info => $ProcessImport{Message},
                },
                {
                    Info => $SynchronizeMessage,
                },
            ];

            return $Self->_ShowOverview(
                %Param,
            );
        }
    }

    # ------------------------------------------------------------ #
    # ProcessExport
    # ------------------------------------------------------------ #
    elsif ( $Self->{Subaction} eq 'ProcessExport' ) {

        # check for ProcessID
        my $ProcessID = $ParamObject->GetParam( Param => 'ID' ) || '';
        if ( !$ProcessID ) {
            return $LayoutObject->ErrorScreen(
                Message => Translatable('Need ProcessID!'),
            );
        }

        my $ProcessData = $Self->_GetProcessData(
            ID => $ProcessID
        );

        # convert the processdata hash to string
        my $ProcessDataYAML = $Kernel::OM->Get('Kernel::System::YAML')->Dump( Data => $ProcessData );

        # send the result to the browser
        return $LayoutObject->Attachment(
            ContentType => 'text/html; charset=' . $LayoutObject->{Charset},
            Content     => $ProcessDataYAML,
            Type        => 'attachment',
            Filename    => 'Export_ProcessEntityID_' . $ProcessData->{Process}->{EntityID} . '.yml',
            NoCache     => 1,
        );
    }

    # ------------------------------------------------------------ #
    # ProcessPrint
    # ------------------------------------------------------------ #
    elsif ( $Self->{Subaction} eq 'ProcessPrint' ) {

        # we need to use Data::Dumper with custom Indent
        my $Indent = $Data::Dumper::Indent;
        $Data::Dumper::Indent = 1;

        # check for ProcessID
        my $ProcessID = $ParamObject->GetParam( Param => 'ID' ) || '';
        if ( !$ProcessID ) {
            return $LayoutObject->ErrorScreen(
                Message => Translatable('Need ProcessID!'),
            );
        }

        my $BooleanMapping = {
            0 => Translatable('No'),
            1 => Translatable('Yes'),
            2 => Translatable('Yes (mandatory)'),
        };

        my $ProcessData = $Self->_GetProcessData(
            ID => $ProcessID
        );

        my $Output = $LayoutObject->Header(
            Value => $Param{Title},
            Type  => 'Small',
        );

        # print all activities
        if ( $ProcessData->{Activities} && %{ $ProcessData->{Activities} } ) {

            for my $ActivityEntityID ( sort keys %{ $ProcessData->{Activities} } ) {

                $LayoutObject->Block(
                    Name => 'ActivityRow',
                    Data => {
                        %{ $ProcessData->{Activities}->{$ActivityEntityID} },
                        DialogCount =>
                            scalar
                            @{ $ProcessData->{Activities}->{$ActivityEntityID}->{ActivityDialogs} },
                    },
                );

                # list all assigned dialogs
                my $AssignedDialogs = $ProcessData->{Activities}->{$ActivityEntityID}->{Config}->{ActivityDialog};
                if ( $AssignedDialogs && %{$AssignedDialogs} ) {

                    $LayoutObject->Block(
                        Name => 'AssignedDialogs',
                    );

                    for my $AssignedDialog ( sort keys %{$AssignedDialogs} ) {

                        my $AssignedDialogEntityID = $ProcessData->{Activities}->{$ActivityEntityID}->{Config}
                            ->{ActivityDialog}->{$AssignedDialog};

                        $LayoutObject->Block(
                            Name => 'AssignedDialogsRow',
                            Data => {
                                Name => $ProcessData->{ActivityDialogs}->{$AssignedDialogEntityID}
                                    ->{Name},
                                EntityID => $AssignedDialogEntityID,
                            },
                        );
                    }
                }
            }
        }
        else {
            $LayoutObject->Block(
                Name => 'ActivityRowEmpty',
            );
        }

        # print all activity dialogs
        if ( $ProcessData->{ActivityDialogs} && %{ $ProcessData->{ActivityDialogs} } ) {

            for my $ActivityDialogEntityID ( sort keys %{ $ProcessData->{ActivityDialogs} } ) {

                $LayoutObject->Block(
                    Name => 'ActivityDialogRow',
                    Data => {
                        ShownIn => join(
                            ', ',
                            @{
                                $ProcessData->{ActivityDialogs}->{$ActivityDialogEntityID}
                                    ->{Config}->{Interface}
                            }
                        ),
                        %{ $ProcessData->{ActivityDialogs}->{$ActivityDialogEntityID} },
                    },
                );

                for my $ElementAttribute (
                    qw(DescriptionShort DescriptionLong SubmitButtonText SubmitAdviceText Permission RequiredLock)
                    )
                {

                    my $Value = $ProcessData->{ActivityDialogs}->{$ActivityDialogEntityID}->{Config}
                        ->{$ElementAttribute};

                    if ( defined $Value ) {

                        if ( $ElementAttribute eq 'RequiredLock' ) {
                            $Value = $BooleanMapping->{$Value};
                        }

                        $LayoutObject->Block(
                            Name => 'ElementAttribute',
                            Data => {
                                Key   => $ElementAttribute,
                                Value => $Value,
                            },
                        );
                    }
                }

                # list all assigned fields
                my $AssignedFields = $ProcessData->{ActivityDialogs}->{$ActivityDialogEntityID}->{Config}
                    ->{FieldOrder};
                if ( $AssignedFields && @{$AssignedFields} ) {

                    $LayoutObject->Block(
                        Name => 'AssignedFields',
                    );

                    for my $AssignedField ( @{$AssignedFields} ) {

                        $LayoutObject->Block(
                            Name => 'AssignedFieldsRow',
                            Data => {
                                Name => $AssignedField,
                            },
                        );

                        my %Values = %{
                            $ProcessData->{ActivityDialogs}->{$ActivityDialogEntityID}
                                ->{Config}->{Fields}->{$AssignedField}
                        };
                        if ( $Values{Config} ) {
                            $Values{Config} = Dumper( $Values{Config} );    ## no critic
                            $Values{Config} =~ s{ \s* \$VAR1 \s* =}{}xms;
                            $Values{Config} =~ s{\s+\{}{\{}xms;
                        }

                        for my $Key ( sort keys %Values ) {

                            if ( $Key eq 'Display' ) {
                                $Values{$Key} = $BooleanMapping->{ $Values{$Key} };
                            }

                            if ( $Values{$Key} ) {
                                $LayoutObject->Block(
                                    Name => 'AssignedFieldsRowValue',
                                    Data => {
                                        Key   => $Key,
                                        Value => $Values{$Key},
                                    },
                                );
                            }
                        }
                    }
                }
            }
        }
        else {
            $LayoutObject->Block(
                Name => 'ActivityDialogRowEmpty',
            );
        }

        # print all transitions
        if ( $ProcessData->{Transitions} && %{ $ProcessData->{Transitions} } ) {

            for my $TransitionEntityID ( sort keys %{ $ProcessData->{Transitions} } ) {

                # list config
                my $Config = $ProcessData->{Transitions}->{$TransitionEntityID}->{Config};

                $LayoutObject->Block(
                    Name => 'TransitionRow',
                    Data => {
                        %{ $ProcessData->{Transitions}->{$TransitionEntityID} },
                        ConditionLinking => $Config->{ConditionLinking},
                    },
                );

                if ( $Config && %{$Config} ) {

                    $LayoutObject->Block(
                        Name => 'Condition',
                    );

                    for my $Condition ( sort keys %{ $Config->{Condition} } ) {

                        $LayoutObject->Block(
                            Name => 'ConditionRow',
                            Data => {
                                Name => $Condition,
                            },
                        );

                        my %Values = %{ $Config->{Condition}->{$Condition} };

                        for my $Key ( sort keys %Values ) {

                            if ( $Values{$Key} ) {

                                if ( ref $Values{$Key} eq 'HASH' ) {

                                    $LayoutObject->Block(
                                        Name => 'ConditionRowSub',
                                        Data => {
                                            NameSub => $Key,
                                        },
                                    );

                                    for my $SubKey ( sort keys %{ $Values{$Key} } ) {

                                        if ( ref $Values{$Key}->{$SubKey} eq 'HASH' ) {

                                            $LayoutObject->Block(
                                                Name => 'ConditionRowSubSub',
                                                Data => {
                                                    NameSubSub => $SubKey,
                                                },
                                            );

                                            for my $SubSubKey (
                                                sort keys %{ $Values{$Key}->{$SubKey} }
                                                )
                                            {

                                                $LayoutObject->Block(
                                                    Name => 'ConditionRowSubSubValue',
                                                    Data => {
                                                        Key => $SubSubKey,
                                                        Value =>
                                                            $Values{$Key}->{$SubKey}->{$SubSubKey},
                                                    },
                                                );
                                            }
                                        }
                                        else {

                                            $LayoutObject->Block(
                                                Name => 'ConditionRowSubValue',
                                                Data => {
                                                    Key   => $SubKey,
                                                    Value => $Values{$Key}->{$SubKey},
                                                },
                                            );
                                        }
                                    }
                                }
                                else {

                                    $LayoutObject->Block(
                                        Name => 'ConditionRowValue',
                                        Data => {
                                            Key   => $Key,
                                            Value => $Values{$Key},
                                        },
                                    );
                                }
                            }
                        }
                    }
                }
            }
        }
        else {
            $LayoutObject->Block(
                Name => 'TransitionRowEmpty',
            );
        }

        # print all transition actions
        if ( $ProcessData->{TransitionActions} && %{ $ProcessData->{TransitionActions} } ) {

            for my $TransitionActionEntityID ( sort keys %{ $ProcessData->{TransitionActions} } ) {

                $LayoutObject->Block(
                    Name => 'TransitionActionRow',
                    Data => {
                        Module => $ProcessData->{TransitionActions}->{$TransitionActionEntityID}
                            ->{Config}->{Module},
                        %{ $ProcessData->{TransitionActions}->{$TransitionActionEntityID} },
                    },
                );

                # list config
                my $Config = $ProcessData->{TransitionActions}->{$TransitionActionEntityID}->{Config}
                    ->{Config};
                if ( $Config && %{$Config} ) {

                    $LayoutObject->Block(
                        Name => 'Config',
                    );

                    CONFIGITEM:
                    for my $ConfigItem ( sort keys %{$Config} ) {

                        next CONFIGITEM if !$ConfigItem;

                        $LayoutObject->Block(
                            Name => 'ConfigRow',
                            Data => {
                                Name  => $ConfigItem,
                                Value => $Config->{$ConfigItem},
                            },
                        );
                    }
                }

            }
        }
        else {
            $LayoutObject->Block(
                Name => 'TransitionActionRowEmpty',
            );
        }

        # determine skin for selection of the correct logo
        # 1. use UserSkin setting from Agent preferences, if available
        # 2. use HostBased skin setting, if available
        # 3. use default skin from configuration

        my $SkinSelectedHostBased;
        my $DefaultSkinHostBased = $ConfigObject->Get('Loader::Agent::DefaultSelectedSkin::HostBased');
        if ( $DefaultSkinHostBased && $ENV{HTTP_HOST} ) {
            REGEXP:
            for my $RegExp ( sort keys %{$DefaultSkinHostBased} ) {

                # do not use empty regexp or skin directories
                next REGEXP if !$RegExp;
                next REGEXP if !$DefaultSkinHostBased->{$RegExp};

                # check if regexp is matching
                if ( $ENV{HTTP_HOST} =~ /$RegExp/i ) {
                    $SkinSelectedHostBased = $DefaultSkinHostBased->{$RegExp};
                }
            }
        }

        my $SkinSelected = $Self->{'UserSkin'};

        # check if the skin is valid
        my $SkinValid = 0;
        if ($SkinSelected) {
            $SkinValid = $LayoutObject->SkinValidate(
                SkinType => 'Agent',
                Skin     => $SkinSelected,
            );
        }

        if ( !$SkinValid ) {
            $SkinSelected = $SkinSelectedHostBased
                || $ConfigObject->Get('Loader::Agent::DefaultSelectedSkin')
                || 'default';
        }

        my %AgentLogo;

        # check if we need to display a custom logo for the selected skin
        my $AgentLogoCustom = $ConfigObject->Get('AgentLogoCustom');
        if (
            $SkinSelected
            && $AgentLogoCustom
            && IsHashRefWithData($AgentLogoCustom)
            && $AgentLogoCustom->{$SkinSelected}
            )
        {
            %AgentLogo = %{ $AgentLogoCustom->{$SkinSelected} };
        }

        # Otherwise show default header logo, if configured
        elsif ( defined $ConfigObject->Get('AgentLogo') ) {
            %AgentLogo = %{ $ConfigObject->Get('AgentLogo') };
        }

        # get logo
        if ( $AgentLogo{URL} ) {
            $LayoutObject->Block(
                Name => 'Logo',
                Data => {
                    LogoURL => $ConfigObject->Get('Frontend::WebPath') . $AgentLogo{URL},
                },
            );
        }

        # collect path information
        my @Path;
        push @Path, $ProcessData->{Process}->{Config}->{StartActivity};

        ACTIVITY:
        for my $Activity ( @{ $ProcessData->{Process}->{Activities} } ) {
            next ACTIVITY if $Activity eq $ProcessData->{Process}->{Config}->{StartActivity};
            push @Path, $Activity;
        }

        for my $Activity (@Path) {

            for my $Transition (
                sort keys %{ $ProcessData->{Process}->{Config}->{Path}->{$Activity} }
                )
            {
                my $TransitionActionString;
                if (
                    $ProcessData->{Process}->{Config}->{Path}->{$Activity}->{$Transition}
                    ->{TransitionAction}
                    && @{
                        $ProcessData->{Process}->{Config}->{Path}->{$Activity}->{$Transition}
                            ->{TransitionAction}
                    }
                    )
                {
                    $TransitionActionString = join(
                        ', ',
                        @{
                            $ProcessData->{Process}->{Config}->{Path}->{$Activity}->{$Transition}
                                ->{TransitionAction}
                        }
                    );
                    if ($TransitionActionString) {
                        $TransitionActionString = '(' . $TransitionActionString . ')';
                    }
                }

                $LayoutObject->Block(
                    Name => 'PathItem',
                    Data => {
                        ActivityStart     => $Activity,
                        Transition        => $Transition,
                        TransitionActions => $TransitionActionString,
                        ActivityEnd =>
                            $ProcessData->{Process}->{Config}->{Path}->{$Activity}->{$Transition}
                            ->{ActivityEntityID},
                    },
                );
            }
        }

        $Output .= $LayoutObject->Output(
            TemplateFile => "AdminProcessManagementProcessPrint",
            Data         => {
                Name => $ProcessData->{Process}->{Name} . ' ('
                    . $ProcessData->{Process}->{EntityID} . ')',
                State => $ProcessData->{Process}->{State} . ' ('
                    . $ProcessData->{Process}->{StateEntityID} . ')',
                Description   => $ProcessData->{Process}->{Config}->{Description},
                StartActivity => $ProcessData->{Process}->{Config}->{StartActivity},

                %Param,
            },
        );

        $Output .= $LayoutObject->Footer();

        # reset Indent
        $Data::Dumper::Indent = $Indent;

        return $Output;
    }

    # ------------------------------------------------------------ #
    # ProcessCopy
    # ------------------------------------------------------------ #
    elsif ( $Self->{Subaction} eq 'ProcessCopy' ) {

        # challenge token check for write action
        $LayoutObject->ChallengeTokenCheck();

        # get Process data
        my $ProcessData = $ProcessObject->ProcessGet(
            ID     => $ProcessID,
            UserID => $Self->{UserID},
        );
        if ( !$ProcessData ) {
            return $LayoutObject->ErrorScreen(
                Message => $LayoutObject->{LanguageObject}->Translate( 'Unknown Process %s!', $ProcessID ),
            );
        }

        # create new process name
        my $ProcessName = $LayoutObject->{LanguageObject}->Translate( '%s (copy)', $ProcessData->{Name} );

        # generate entity ID
        my $EntityID = $EntityObject->EntityIDGenerate(
            EntityType => 'Process',
            UserID     => $Self->{UserID},
        );

        # show error if can't generate a new EntityID
        if ( !$EntityID ) {
            return $LayoutObject->ErrorScreen(
                Message => Translatable('There was an error generating a new EntityID for this Process'),
            );
        }

        # check if Inactive state estity exists
        my $StateList   = $StateObject->StateList( UserID => $Self->{UserID} );
        my %StateLookup = reverse %{$StateList};

        my $StateEntityID = $StateLookup{'Inactive'};

        # show error if  StateEntityID for Inactive does not exist
        if ( !$EntityID ) {
            return $LayoutObject->ErrorScreen(
                Message => Translatable('The StateEntityID for state Inactive does not exists'),
            );
        }

        # otherwise save configuration and return to overview screen
        my $ProcessID = $ProcessObject->ProcessAdd(
            Name          => $ProcessName,
            EntityID      => $EntityID,
            StateEntityID => $StateEntityID,
            Layout        => $ProcessData->{Layout},
            Config        => $ProcessData->{Config},
            UserID        => $Self->{UserID},
        );

        # show error if can't create
        if ( !$ProcessID ) {
            return $LayoutObject->ErrorScreen(
                Message => Translatable('There was an error creating the Process'),
            );
        }

        # set entitty sync state
        my $Success = $EntityObject->EntitySyncStateSet(
            EntityType => 'Process',
            EntityID   => $EntityID,
            SyncState  => 'not_sync',
            UserID     => $Self->{UserID},
        );

        # show error if can't set
        if ( !$Success ) {
            return $LayoutObject->ErrorScreen(
                Message => $LayoutObject->{LanguageObject}->Translate(
                    'There was an error setting the entity sync status for Process entity: %s', $EntityID
                ),
            );
        }

        # return to overview
        return $LayoutObject->Redirect( OP => "Action=$Self->{Action}" );
    }

    # ------------------------------------------------------------ #
    # ProcessNew
    # ------------------------------------------------------------ #
    elsif ( $Self->{Subaction} eq 'ProcessNew' ) {

        return $Self->_ShowEdit(
            %Param,
            Action => 'New',
        );
    }

    # ------------------------------------------------------------ #
    # ProcessNewAction
    # ------------------------------------------------------------ #
    elsif ( $Self->{Subaction} eq 'ProcessNewAction' ) {

        # challenge token check for write action
        $LayoutObject->ChallengeTokenCheck();

        # get process data
        my $ProcessData;

        # set new configuration
        $ProcessData->{Name}                  = $GetParam->{Name};
        $ProcessData->{Config}->{Description} = $GetParam->{Description};
        $ProcessData->{StateEntityID}         = $GetParam->{StateEntityID};

        # check required parameters
        my %Error;
        if ( !$GetParam->{Name} ) {

            # add server error error class
            $Error{NameServerError}        = 'ServerError';
            $Error{NameServerErrorMessage} = Translatable('This field is required');
        }

        if ( !$GetParam->{Description} ) {

            # add server error error class
            $Error{DescriptionServerError}        = 'ServerError';
            $Error{DescriptionServerErrorMessage} = Translatable('This field is required');
        }

        # check if state exists
        my $StateList = $StateObject->StateList( UserID => $Self->{UserID} );

        if ( !$StateList->{ $GetParam->{StateEntityID} } )
        {

            # add server error error class
            $Error{StateEntityIDServerError} = 'ServerError';
        }

        # if there is an error return to edit screen
        if ( IsHashRefWithData( \%Error ) ) {
            return $Self->_ShowEdit(
                %Error,
                %Param,
                ProcessData => $ProcessData,
                Action      => 'New',
            );
        }

        # generate entity ID
        my $EntityID = $EntityObject->EntityIDGenerate(
            EntityType => 'Process',
            UserID     => $Self->{UserID},
        );

        # show error if can't generate a new EntityID
        if ( !$EntityID ) {
            return $LayoutObject->ErrorScreen(
                Message => Translatable('There was an error generating a new EntityID for this Process'),
            );
        }

        # otherwise save configuration and return to overview screen
        my $ProcessID = $ProcessObject->ProcessAdd(
            Name          => $ProcessData->{Name},
            EntityID      => $EntityID,
            StateEntityID => $ProcessData->{StateEntityID},
            Layout        => {},
            Config        => $ProcessData->{Config},
            UserID        => $Self->{UserID},
        );

        # show error if can't create
        if ( !$ProcessID ) {
            return $LayoutObject->ErrorScreen(
                Message => Translatable('There was an error creating the Process'),
            );
        }

        # set entitty sync state
        my $Success = $EntityObject->EntitySyncStateSet(
            EntityType => 'Process',
            EntityID   => $EntityID,
            SyncState  => 'not_sync',
            UserID     => $Self->{UserID},
        );

        # show error if can't set
        if ( !$Success ) {
            return $LayoutObject->ErrorScreen(
                Message => $LayoutObject->{LanguageObject}->Translate(
                    'There was an error setting the entity sync status for Process entity: %s', $EntityID
                ),
            );
        }

        # redirect to process edit screen
        return $LayoutObject->Redirect(
            OP =>
                "Action=AdminProcessManagement;Subaction=ProcessEdit;ID=$ProcessID"
        );

    }

    # ------------------------------------------------------------ #
    # ProcessEdit
    # ------------------------------------------------------------ #
    elsif ( $Self->{Subaction} eq 'ProcessEdit' ) {

        # check for ProcessID
        if ( !$ProcessID ) {
            return $LayoutObject->ErrorScreen(
                Message => Translatable('Need ProcessID!'),
            );
        }

        # set screens path in session
        my @ScreensPath = (
            {
                Action    => $Self->{Action}    || '',
                Subaction => $Self->{Subaction} || '',
                ID        => $ProcessID,
                EntityID  => $EntityID,
                ProcessEntityID => $EntityID,
                Parameters      => 'ID=' . $ProcessID . ';EntityID=' . $EntityID . ';ProcessEntityID=' . $EntityID,
            }
        );

        # convert screens patch to string (JSON)
        my $JSONScreensPath = $LayoutObject->JSONEncode(
            Data => \@ScreensPath,
        );

        $Kernel::OM->Get('Kernel::System::AuthSession')->UpdateSessionID(
            SessionID => $Self->{SessionID},
            Key       => 'ProcessManagementScreensPath',
            Value     => $JSONScreensPath,
        );

        # get Process data
        my $ProcessData = $ProcessObject->ProcessGet(
            ID     => $ProcessID,
            UserID => $Self->{UserID},
        );

        # check for valid Process data
        if ( !IsHashRefWithData($ProcessData) ) {
            return $LayoutObject->ErrorScreen(
                Message =>
                    $LayoutObject->{LanguageObject}->Translate( 'Could not get data for ProcessID %s', $ProcessID ),
            );
        }

        return $Self->_ShowEdit(
            %Param,
            ProcessID   => $ProcessID,
            ProcessData => $ProcessData,
            Action      => 'Edit',
        );
    }

    # ------------------------------------------------------------ #
    # ProcessEditAction
    # ------------------------------------------------------------ #
    elsif ( $Self->{Subaction} eq 'ProcessEditAction' ) {

        # challenge token check for write action
        $LayoutObject->ChallengeTokenCheck();

        my $ProcessData;

        # set new configuration
        $ProcessData->{Name}                          = $GetParam->{Name};
        $ProcessData->{EntityID}                      = $GetParam->{EntityID};
        $ProcessData->{ProcessLayout}                 = $GetParam->{ProcessLayout};
        $ProcessData->{StateEntityID}                 = $GetParam->{StateEntityID};
        $ProcessData->{Config}->{Description}         = $GetParam->{Description};
        $ProcessData->{Config}->{Path}                = $GetParam->{Path};
        $ProcessData->{Config}->{StartActivity}       = $GetParam->{StartActivity};
        $ProcessData->{Config}->{StartActivityDialog} = $GetParam->{StartActivityDialog};

        # check required parameters
        my %Error;
        if ( !$GetParam->{Name} ) {

            # add server error error class
            $Error{NameServerError}        = 'ServerError';
            $Error{NameServerErrorMessage} = Translatable('This field is required');
        }

        if ( !$GetParam->{Description} ) {

            # add server error error class
            $Error{DescriptionServerError}        = 'ServerError';
            $Error{DescriptionServerErrorMessage} = Translatable('This field is required');
        }

        # check if state exists
        my $StateList = $StateObject->StateList( UserID => $Self->{UserID} );

        if ( !$StateList->{ $GetParam->{StateEntityID} } )
        {

            # add server error error class
            $Error{StateEntityIDServerError} = 'ServerError';
        }

        # if there is an error return to edit screen
        if ( IsHashRefWithData( \%Error ) ) {
            return $Self->_ShowEdit(
                %Error,
                %Param,
                ProcessData => $ProcessData,
                Action      => 'Edit',
            );
        }

        # otherwise save configuration and return to overview screen
        my $Success = $ProcessObject->ProcessUpdate(
            ID            => $ProcessID,
            Name          => $ProcessData->{Name},
            EntityID      => $ProcessData->{EntityID},
            StateEntityID => $ProcessData->{StateEntityID},
            Layout        => $ProcessData->{ProcessLayout},
            Config        => $ProcessData->{Config},
            UserID        => $Self->{UserID},
        );

        # show error if can't update
        if ( !$Success ) {
            return $LayoutObject->ErrorScreen(
                Message => Translatable('There was an error updating the Process'),
            );
        }

        # set entity sync state
        $Success = $EntityObject->EntitySyncStateSet(
            EntityType => 'Process',
            EntityID   => $ProcessData->{EntityID},
            SyncState  => 'not_sync',
            UserID     => $Self->{UserID},
        );

        # show error if can't set
        if ( !$Success ) {
            return $LayoutObject->ErrorScreen(
                Message => $LayoutObject->{LanguageObject}->Translate(
                    'There was an error setting the entity sync status for Process entity: %s',
                    $ProcessData->{EntityID}
                ),
            );
        }

        if (
            defined $ParamObject->GetParam( Param => 'ContinueAfterSave' )
            && ( $ParamObject->GetParam( Param => 'ContinueAfterSave' ) eq '1' )
            )
        {

            # if the user would like to continue editing the process, just redirect to the edit screen
            return $LayoutObject->Redirect(
                OP =>
                    "Action=AdminProcessManagement;Subaction=ProcessEdit;ID=$ProcessID;EntityID=$ProcessData->{EntityID}"
            );
        }
        else {

            # otherwise return to overview
            return $LayoutObject->Redirect( OP => "Action=$Self->{Action}" );
        }
    }

    # ------------------------------------------------------------ #
    # ProcessDeleteCheck AJAX
    # ------------------------------------------------------------ #
    elsif ( $Self->{Subaction} eq 'ProcessDeleteCheck' ) {

        # check for ProcessID
        return if !$ProcessID;

        my $CheckResult = $Self->_CheckProcessDelete( ID => $ProcessID );

        # build JSON output
        my $JSON = $LayoutObject->JSONEncode(
            Data => {
                %{$CheckResult},
            },
        );

        # send JSON response
        return $LayoutObject->Attachment(
            ContentType => 'application/json; charset=' . $LayoutObject->{Charset},
            Content     => $JSON,
            Type        => 'inline',
            NoCache     => 1,
        );
    }

    # ------------------------------------------------------------ #
    # ProcessDelete AJAX
    # ------------------------------------------------------------ #
    elsif ( $Self->{Subaction} eq 'ProcessDelete' ) {

        # challenge token check for write action
        $LayoutObject->ChallengeTokenCheck();

        # check for ProcessID
        return if !$ProcessID;

        my $CheckResult = $Self->_CheckProcessDelete( ID => $ProcessID );

        my $JSON;
        if ( $CheckResult->{Success} ) {

            my $Success = $ProcessObject->ProcessDelete(
                ID     => $ProcessID,
                UserID => $Self->{UserID},
            );

            my %DeleteResult = (
                Success => $Success,
            );

            if ( !$Success ) {
                $DeleteResult{Message}
                    = $LayoutObject->{LanguageObject}->Translate( 'Process: %s could not be deleted', $ProcessID );
            }
            else {

                # set entitty sync state
                my $Success = $EntityObject->EntitySyncStateSet(
                    EntityType => 'Process',
                    EntityID   => $CheckResult->{ProcessData}->{EntityID},
                    SyncState  => 'deleted',
                    UserID     => $Self->{UserID},
                );

                # show error if cant set
                if ( !$Success ) {
                    $DeleteResult{Success} = $Success;
                    $DeleteResult{Message} = $LayoutObject->{LanguageObject}->Translate(
                        'There was an error setting the entity sync status for Process entity: %s',
                        $CheckResult->{ProcessData}->{EntityID}
                    );
                }
            }

            # build JSON output
            $JSON = $LayoutObject->JSONEncode(
                Data => {
                    %DeleteResult,
                },
            );
        }
        else {

            # build JSON output
            $JSON = $LayoutObject->JSONEncode(
                Data => {
                    %{$CheckResult},
                },
            );
        }

        # send JSON response
        return $LayoutObject->Attachment(
            ContentType => 'application/json; charset=' . $LayoutObject->{Charset},
            Content     => $JSON,
            Type        => 'inline',
            NoCache     => 1,
        );
    }

    # ------------------------------------------------------------ #
    # ProcessSync
    # ------------------------------------------------------------ #
    elsif ( $Self->{Subaction} eq 'ProcessSync' ) {

        my $Location = $ConfigObject->Get('Home') . '/Kernel/Config/Files/ZZZProcessManagement.pm';

        my $ProcessDump = $ProcessObject->ProcessDump(
            ResultType => 'FILE',
            Location   => $Location,
            UserID     => $Self->{UserID},
        );

        if ($ProcessDump) {

            my $Success = $EntityObject->EntitySyncStatePurge(
                UserID => $Self->{UserID},
            );

            if ($Success) {
                return $LayoutObject->Redirect( OP => "Action=$Self->{Action}" );
            }
            else {

                # show error if can't set state
                return $LayoutObject->ErrorScreen(
                    Message => Translatable('There was an error setting the entity sync status.'),
                );
            }
        }
        else {

            # show error if can't synch
            return $LayoutObject->ErrorScreen(
                Message => Translatable('There was an error synchronizing the processes.'),
            );
        }
    }

    # ------------------------------------------------------------ #
    # EntityUsageCheck AJAX
    # ------------------------------------------------------------ #
    elsif ( $Self->{Subaction} eq 'EntityUsageCheck' ) {

        my %GetParam;
        for my $Param (qw(EntityType EntityID)) {
            $GetParam{$Param} = $ParamObject->GetParam( Param => $Param ) || '';
        }

        # check needed information
        return if !$GetParam{EntityType};
        return if !$GetParam{EntityID};

        my $EntityCheck = $Self->_CheckEntityUsage(%GetParam);

        # build JSON output
        my $JSON = $LayoutObject->JSONEncode(
            Data => {
                %{$EntityCheck},
            },
        );

        # send JSON response
        return $LayoutObject->Attachment(
            ContentType => 'application/json; charset=' . $LayoutObject->{Charset},
            Content     => $JSON,
            Type        => 'inline',
            NoCache     => 1,
        );
    }

    # ------------------------------------------------------------ #
    # EntityDelete AJAX
    # ------------------------------------------------------------ #
    elsif ( $Self->{Subaction} eq 'EntityDelete' ) {

        # challenge token check for write action
        $LayoutObject->ChallengeTokenCheck();

        my %GetParam;
        for my $Param (qw(EntityType EntityID ItemID)) {
            $GetParam{$Param} = $ParamObject->GetParam( Param => $Param ) || '';
        }

        # check needed information
        return if !$GetParam{EntityType};
        return if !$GetParam{EntityID};
        return if !$GetParam{ItemID};

        return if $GetParam{EntityType} ne 'Activity'
            && $GetParam{EntityType} ne 'ActivityDialog'
            && $GetParam{EntityType} ne 'Transition'
            && $GetParam{EntityType} ne 'TransitionAction';

        my $EntityCheck = $Self->_CheckEntityUsage(%GetParam);

        my $JSON;
        if ( !$EntityCheck->{Deleteable} ) {
            $JSON = $LayoutObject->JSONEncode(
                Data => {
                    Success => 0,
                    Message => $LayoutObject->{LanguageObject}
                        ->Translate( 'The %s:%s is still in use', $GetParam{EntityType}, $GetParam{EntityID} ),
                },
            );
        }
        else {

            # get entity
            my $Method = $GetParam{EntityType} . 'Get';
            my $Entity = $Kernel::OM->Get( 'Kernel::System::ProcessManagement::DB::' . $GetParam{EntityType} )->$Method(
                ID     => $GetParam{ItemID},
                UserID => $Self->{UserID},
            );

            if ( $Entity->{EntityID} ne $GetParam{EntityID} ) {
                $JSON = $LayoutObject->JSONEncode(
                    Data => {
                        Success => 0,
                        Message => $LayoutObject->{LanguageObject}->Translate(
                            'The %s:%s has a different EntityID',
                            $GetParam{EntityType}, $GetParam{ItemID}
                        ),
                    },
                );
            }
            else {

                # delete entity
                $Method = $GetParam{EntityType} . 'Delete';
                my $Success
                    = $Kernel::OM->Get( 'Kernel::System::ProcessManagement::DB::' . $GetParam{EntityType} )->$Method(
                    ID     => $GetParam{ItemID},
                    UserID => $Self->{UserID},
                    );

                my $Message;
                if ( !$Success ) {
                    $Success = 0;
                    $Message = $LayoutObject->{LanguageObject}
                        ->Translate( 'Could not delete %s:%s', $GetParam{EntityType}, $GetParam{ItemID} );
                }
                else {

                    # set entitty sync state
                    my $Success = $EntityObject->EntitySyncStateSet(
                        EntityType => $GetParam{EntityType},
                        EntityID   => $Entity->{EntityID},
                        SyncState  => 'deleted',
                        UserID     => $Self->{UserID},
                    );

                    # show error if cant set
                    if ( !$Success ) {
                        $Success = 0;
                        $Message = $LayoutObject->{LanguageObject}->Translate(
                            'There was an error setting the entity sync status for %s entity: %s',
                            $GetParam{EntityType}, $Entity->{EntityID}
                        );
                    }
                }

                # build JSON output
                $JSON = $LayoutObject->JSONEncode(
                    Data => {
                        Success => $Success,
                        Message => $Message,
                    },
                );
            }
        }

        # send JSON response
        return $LayoutObject->Attachment(
            ContentType => 'application/json; charset=' . $LayoutObject->{Charset},
            Content     => $JSON,
            Type        => 'inline',
            NoCache     => 1,
        );
    }

    # ------------------------------------------------------------ #
    # EntityGet AJAX
    # ------------------------------------------------------------ #
    elsif ( $Self->{Subaction} eq 'EntityGet' ) {

        my %GetParam;
        for my $Param (qw(EntityType EntityID ItemID)) {
            $GetParam{$Param} = $ParamObject->GetParam( Param => $Param ) || '';
        }

        # check needed information
        return if !$GetParam{EntityType};
        return if !$GetParam{EntityID} && !$GetParam{ItemID};

        return if $GetParam{EntityType} ne 'Activity'
            && $GetParam{EntityType} ne 'ActivityDialog'
            && $GetParam{EntityType} ne 'Transition'
            && $GetParam{EntityType} ne 'TransitionAction'
            && $GetParam{EntityType} ne 'Process';

        # get entity
        my $Method = $GetParam{EntityType} . 'Get';

        my $EntityData;
        if ( $GetParam{ItemID} && $GetParam{ItemID} ne '' ) {
            $EntityData
                = $Kernel::OM->Get( 'Kernel::System::ProcessManagement::DB::' . $GetParam{EntityType} )->$Method(
                ID     => $GetParam{ItemID},
                UserID => $Self->{UserID},
                );
        }
        else {
            $EntityData
                = $Kernel::OM->Get( 'Kernel::System::ProcessManagement::DB::' . $GetParam{EntityType} )->$Method(
                EntityID => $GetParam{EntityID},
                UserID   => $Self->{UserID},
                );
        }

        my $JSON;
        if ( !IsHashRefWithData($EntityData) ) {
            $JSON = $LayoutObject->JSONEncode(
                Data => {
                    Success => 0,
                    Message => $LayoutObject->{LanguageObject}->Translate( 'Could not get %s', $GetParam{EntityType} ),
                },
            );
        }
        else {

            # build JSON output
            $JSON = $LayoutObject->JSONEncode(
                Data => {
                    Success    => 1,
                    EntityData => $EntityData,
                },
            );
        }

        # send JSON response
        return $LayoutObject->Attachment(
            ContentType => 'application/json; charset=' . $LayoutObject->{Charset},
            Content     => $JSON,
            Type        => 'inline',
            NoCache     => 1,
        );
    }

    # ------------------------------------------------------------ #
    # UpdateSyncMessage AJAX
    # ------------------------------------------------------------ #
    elsif ( $Self->{Subaction} eq 'UpdateSyncMessage' ) {

        # get the list of updated or deleted entities
        my $EntitySyncStateList = $EntityObject->EntitySyncStateList(
            UserID => $Self->{UserID}
        );

        # prevent errors by defining $Output as an empty string instead of undef
        my $Output = '';
        if ( IsArrayRefWithData($EntitySyncStateList) ) {
            $Output = $LayoutObject->Notify(
                Info => $SynchronizeMessage,
            );
        }

        # send HTML response
        return $LayoutObject->Attachment(
            ContentType => 'text/html',
            Content     => $Output,
            Type        => 'inline',
            NoCache     => 1,
        );
    }

    # ------------------------------------------------------------ #
    # UpdateAccordion AJAX
    # ------------------------------------------------------------ #
    elsif ( $Self->{Subaction} eq 'UpdateAccordion' ) {
        my $ProcessEntityID = $ParamObject->GetParam( Param => 'ProcessEntityID' );

        # output available process elements in the accordion
        for my $Element (qw(Activity ActivityDialog Transition TransitionAction)) {

            my $ElementMethod = $Element . 'ListGet';

            # get a list of all elements with details
            my $ElementList = $Kernel::OM->Get( 'Kernel::System::ProcessManagement::DB::' . $Element )
                ->$ElementMethod( UserID => $Self->{UserID} );

            # check there are elements to display
            if ( IsArrayRefWithData($ElementList) ) {
                for my $ElementData (
                    sort { lc( $a->{Name} ) cmp lc( $b->{Name} ) }
                    @{$ElementList}
                    )
                {

                    my $AvailableIn = '';
                    if ( $Element eq "ActivityDialog" ) {
                        my $ConfigAvailableIn = $ElementData->{Config}->{Interface};

                        if ( defined $ConfigAvailableIn ) {
                            my $InterfaceLength = scalar @{$ConfigAvailableIn};
                            if ( $InterfaceLength == 2 ) {
                                $AvailableIn = 'A/C';
                            }
                            elsif ( $InterfaceLength == 1 ) {
                                $AvailableIn = substr( $ConfigAvailableIn->[0], 0, 1 );
                            }
                            else {
                                $AvailableIn = 'A';
                            }
                        }
                        else {
                            $AvailableIn = 'A';
                        }
                    }

                    # print each element in the accordion
                    $LayoutObject->Block(
                        Name => $Element . 'Row',
                        Data => {
                            ProcessEntityID => $ProcessEntityID,
                            %{$ElementData},
                            AvailableIn => $AvailableIn,    #only used for ActivityDialogs
                        },
                    );
                }
            }
            else {

                # print no data found in the accordion
                $LayoutObject->Block(
                    Name => $Element . 'NoDataRow',
                    Data => {},
                );
            }
        }

        my $Output = $LayoutObject->Output(
            TemplateFile => "AdminProcessManagementProcessAccordion",
            Data         => {
                ProcessEntityID => $ProcessEntityID,
            },
        );

        # send HTML response
        return $LayoutObject->Attachment(
            ContentType => 'text/html',
            Content     => $Output,
            Type        => 'inline',
            NoCache     => 1,
        );

    }

    # ------------------------------------------------------------ #
    # UpdateScreensPath AJAX
    # ------------------------------------------------------------ #
    elsif ( $Self->{Subaction} eq 'UpdateScreensPath' ) {

        my $Success = 1;
        my $Message = '';
        for my $Needed (qw(ProcessID ProcessEntityID)) {

            $Param{$Needed} = $ParamObject->GetParam( Param => $Needed ) || '';
            if ( !$Param{$Needed} ) {
                $Success = 0;
                $Message = $LayoutObject->{LanguageObject}->Translate( 'Need %s!', $Needed );
            }
        }

        if ($Success) {

            $Self->_PushSessionScreen(
                ID              => $Param{ProcessID},
                EntityID        => $Param{ProcessEntityID},
                ProcessEntityID => $Param{ProcessEntityID},
                Subaction       => 'ProcessEdit',
                Action          => 'AdminProcessManagement',
            );
        }

        # build JSON output
        my $JSON = $LayoutObject->JSONEncode(
            Data => {
                Success => $Success,
                Message => $Message,
            },
        );

        # send JSON response
        return $LayoutObject->Attachment(
            ContentType => 'application/json; charset=' . $LayoutObject->{Charset},
            Content     => $JSON,
            Type        => 'inline',
            NoCache     => 1,
        );
    }

    # ------------------------------------------------------------ #
    # Overview
    # ------------------------------------------------------------ #
    else {
        return $Self->_ShowOverview(
            %Param,
        );
    }
}

sub _ShowOverview {
    my ( $Self, %Param ) = @_;

    my $LayoutObject = $Kernel::OM->Get('Kernel::Output::HTML::Layout');

    my $Output = $LayoutObject->Header();
    $Output .= $LayoutObject->NavigationBar();

    # show notifications if any
    if ( $Param{NotifyData} ) {
        for my $Notification ( @{ $Param{NotifyData} } ) {
            $Output .= $LayoutObject->Notify(
                %{$Notification},
            );
        }
    }

    my @ExampleProcesses = $Kernel::OM->Get('Kernel::System::Main')->DirectoryRead(
        Directory => $Kernel::OM->Get('Kernel::Config')->Get('Home') . '/var/processes/examples',
        Filter    => '*.yml',
    );

    my %ExampleProcessData;

    for my $ExampleProcessFilename (@ExampleProcesses) {
        my $Key = $ExampleProcessFilename;
        $Key =~ s{^.*/([^/]+)$}{$1}smx;
        my $Value = $Key;
        $Value =~ s{^(.+).yml}{$1}smx;
        $Value =~ s{_}{ }smxg;
        $ExampleProcessData{$Key} = $Value;
    }

    my %Frontend;

    $Frontend{ExampleProcessList} = $Kernel::OM->Get('Kernel::Output::HTML::Layout')->BuildSelection(
        Name         => 'ExampleProcess',
        Data         => \%ExampleProcessData,
        PossibleNone => 1,
        Translation  => 0,
        Class        => 'Modernize Validate_Required',
    );
    $Frontend{OTRSBusinessIsInstalled} = $Kernel::OM->Get('Kernel::System::OTRSBusiness')->OTRSBusinessIsInstalled();

    my $ProcessObject = $Kernel::OM->Get('Kernel::System::ProcessManagement::DB::Process');

    # get a process list
    my $ProcessList = $ProcessObject->ProcessList( UserID => $Self->{UserID} );

    if ( IsHashRefWithData($ProcessList) ) {

        # Sort process list by name instead of ID (bug#12311).
        my @ProcessIDs = sort { lc $ProcessList->{$a} cmp lc $ProcessList->{$b} } keys %{$ProcessList};

        # get each process data
        for my $ProcessID (@ProcessIDs) {
            my $ProcessData = $ProcessObject->ProcessGet(
                ID     => $ProcessID,
                UserID => $Self->{UserID},
            );

            # print each process in overview table
            $LayoutObject->Block(
                Name => 'ProcessRow',
                Data => {
                    %{$ProcessData},
                    Description => $ProcessData->{Config}->{Description},
                }
            );
        }
    }
    else {

        # print no data found message
        $LayoutObject->Block(
            Name => 'ProcessNoDataRow',
            Data => {},
        );
    }

    $Output .= $LayoutObject->Output(
        TemplateFile => 'AdminProcessManagement',
        Data         => {
            %Param,
            %Frontend,
        },
    );
    $Output .= $LayoutObject->Footer();

    return $Output;
}

sub _ShowEdit {
    my ( $Self, %Param ) = @_;

    # get process information
    my $ProcessData = $Param{ProcessData} || {};

    my $LayoutObject = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $StateObject  = $Kernel::OM->Get('Kernel::System::ProcessManagement::DB::Process::State');

    if ( defined $Param{Action} && $Param{Action} eq 'Edit' ) {

        # check if process is inactive and show delete action
        my $State = $StateObject->StateLookup(
            EntityID => $ProcessData->{StateEntityID},
            UserID   => $Self->{UserID},
        );
        if ( $State eq 'Inactive' ) {
            $LayoutObject->Block(
                Name => 'ProcessDeleteAction',
                Data => {
                    %{$ProcessData},
                },
            );
        }

        # output available process elements in the accordion
        for my $Element (qw(Activity ActivityDialog Transition TransitionAction)) {

            my $ElementMethod = $Element . 'ListGet';

            # get a list of all elements with details
            my $ElementList = $Kernel::OM->Get( 'Kernel::System::ProcessManagement::DB::' . $Element )
                ->$ElementMethod( UserID => $Self->{UserID} );

            # check there are elements to display
            if ( IsArrayRefWithData($ElementList) ) {
                for my $ElementData (
                    sort { lc( $a->{Name} ) cmp lc( $b->{Name} ) }
                    @{$ElementList}
                    )
                {

                    my $AvailableIn = '';
                    if ( $Element eq "ActivityDialog" ) {
                        my $ConfigAvailableIn = $ElementData->{Config}->{Interface};

                        if ( defined $ConfigAvailableIn ) {
                            my $InterfaceLength = scalar @{$ConfigAvailableIn};
                            if ( $InterfaceLength == 2 ) {
                                $AvailableIn = 'A/C';
                            }
                            elsif ( $InterfaceLength == 1 ) {
                                $AvailableIn = substr( $ConfigAvailableIn->[0], 0, 1 );
                            }
                            else {
                                $AvailableIn = 'A';
                            }
                        }
                        else {
                            $AvailableIn = 'A';
                        }
                    }

                    # print each element in the accordion
                    $LayoutObject->Block(
                        Name => $Element . 'Row',
                        Data => {
                            %{$ElementData},
                            ProcessEntityID => $ProcessData->{EntityID} || '',
                            AvailableIn     => $AvailableIn,                     #only used for ActivityDialogs
                        },
                    );
                }
            }
            else {

                # print no data found in the accordion
                $LayoutObject->Block(
                    Name => $Element . 'NoDataRow',
                    Data => {},
                );
            }
        }
    }

    # get a list of all states
    my $StateList = $StateObject->StateList( UserID => $Self->{UserID} );

    # get the 'inactive' state for init
    my $InactiveStateID;
    for my $StateID ( sort keys %{$StateList} ) {
        if ( $StateList->{$StateID} =~ m{Inactive}xmsi ) {
            $InactiveStateID = $StateID;
        }
    }

    my $StateError = '';
    if ( $Param{StateEntityIDServerError} ) {
        $StateError = $Param{StateEntityIDServerError};
    }

    $Param{StateSelection} = $LayoutObject->BuildSelection(
        Data       => $StateList || {},
        Name       => 'StateEntityID',
        ID         => 'StateEntityID',
        SelectedID => $ProcessData->{StateEntityID}
            || $InactiveStateID,    # select inactive by default
        Sort        => 'AlphanumericKey',
        Translation => 1,
        Class       => 'Modernize W75pc ' . $StateError,
    );

    my $Output = $LayoutObject->Header();
    $Output .= $LayoutObject->NavigationBar();

    # show notifications if any
    if ( $Param{NotifyData} ) {
        for my $Notification ( @{ $Param{NotifyData} } ) {
            $Output .= $LayoutObject->Notify(
                %{$Notification},
            );
        }
    }

    # set db dump as config settings
    my $ProcessDump = $Kernel::OM->Get('Kernel::System::ProcessManagement::DB::Process')->ProcessDump(
        ResultType => 'HASH',
        UserID     => $Self->{UserID},
    );

    # send data to JS
    $LayoutObject->AddJSData(
        Key   => 'ConfigProcess',
        Value => {
            Process           => $ProcessDump->{Process},
            ProcessLayout     => $ProcessData->{Layout},
            Activity          => $ProcessDump->{Activity},
            ActivityDialog    => $ProcessDump->{ActivityDialog},
            Transition        => $ProcessDump->{Transition},
            TransitionAction  => $ProcessDump->{TransitionAction},
            PopupPathActivity => $LayoutObject->{Baselink}
                . 'Action=AdminProcessManagementActivity;Subaction=ActivityEdit;',
            PopupPathPath => $LayoutObject->{Baselink} . 'Action=AdminProcessManagementPath;Subaction=PathEdit;',
        }
    );

    $Output .= $LayoutObject->Output(
        TemplateFile => "AdminProcessManagementProcess$Param{Action}",
        Data         => {
            %Param,
            %{$ProcessData},
            ProcessEntityID => $ProcessData->{EntityID}              || '',
            Description     => $ProcessData->{Config}->{Description} || '',
        },
    );

    $Output .= $LayoutObject->Footer();

    return $Output;
}

sub _GetParams {
    my ( $Self, %Param ) = @_;

    my $GetParam;

    # get parameters from web browser
    for my $ParamName (
        qw( Name EntityID ProcessLayout Path StartActivity StartActivityDialog Description StateEntityID ProcessEntityID )
        )
    {
        $GetParam->{$ParamName} = $Kernel::OM->Get('Kernel::System::Web::Request')->GetParam( Param => $ParamName )
            || '';
    }

    my $JSONObject = $Kernel::OM->Get('Kernel::System::JSON');

    if ( $GetParam->{ProcessLayout} ) {
        $GetParam->{ProcessLayout} = $JSONObject->Decode(
            Data => $GetParam->{ProcessLayout},
        );
    }

    if ( $GetParam->{Path} ) {
        $GetParam->{Path} = $JSONObject->Decode(
            Data => $GetParam->{Path},
        );
    }

    return $GetParam;
}

sub _CheckProcessDelete {
    my ( $Self, %Param ) = @_;

    my $LayoutObject = $Kernel::OM->Get('Kernel::Output::HTML::Layout');

    # get Process data
    my $ProcessData = $Kernel::OM->Get('Kernel::System::ProcessManagement::DB::Process')->ProcessGet(
        ID     => $Param{ID},
        UserID => $Self->{UserID},
    );

    # check for valid Process data
    if ( !IsHashRefWithData($ProcessData) ) {
        return {
            Success => 0,
            Message => $LayoutObject->{LanguageObject}->Translate( 'Could not get data for ProcessID %s', $Param{ID} ),
        };
    }

    # check that the Process is in Inactive state
    my $State = $Kernel::OM->Get('Kernel::System::ProcessManagement::DB::Process::State')->StateLookup(
        EntityID => $ProcessData->{StateEntityID},
        UserID   => $Self->{UserID},
    );

    if ( $State ne 'Inactive' ) {
        return {
            Success => 0,
            Message => $LayoutObject->{LanguageObject}->Translate( 'Process: %s is not Inactive', $Param{ID} ),
        };
    }

    return {
        Success     => 1,
        ProcessData => $ProcessData,
    };
}

sub _CheckEntityUsage {
    my ( $Self, %Param ) = @_;

    my %Config = (
        Activity => {
            Parent => 'Process',
            Method => 'ProcessListGet',
            Array  => 'Activities',
        },
        ActivityDialog => {
            Parent => 'Activity',
            Method => 'ActivityListGet',
            Array  => 'ActivityDialogs',
        },
        Transition => {
            Parent => 'Process',
            Method => 'ProcessListGet',
            Array  => 'Transitions',
        },
    );

    my @Usage;

    # transition action needs to be handled on a different way than other process parts as it does
    # not depend directly on a parent part, it is nested in the process path configuration
    if ( $Param{EntityType} eq 'TransitionAction' ) {

        my $ProcessList = $Kernel::OM->Get('Kernel::System::ProcessManagement::DB::Process')->ProcessListGet(
            UserID => $Self->{UserID},
        );

        # search in all processes
        PROCESS:
        for my $Process ( @{$ProcessList} ) {

            next PROCESS if !$Process->{Config}->{Path};
            my $Path = $Process->{Config}->{Path};

            # search on each activity on the process path
            ACTIVITY:
            for my $ActivityEntityID ( sort keys %{$Path} ) {

                # search on each transition on the activity
                TRANSITION:
                for my $TransitionEntityID ( sort keys %{ $Path->{$ActivityEntityID} } ) {

                    next TRANSITION if !$Path->{$ActivityEntityID}->{$TransitionEntityID};
                    my $TransitionConfig = $Path->{$ActivityEntityID}->{$TransitionEntityID};

                    next TRANSITION if !$TransitionConfig->{TransitionAction};
                    my @TransitionActions = @{ $TransitionConfig->{TransitionAction} };

                    ENTITY:
                    for my $EntityID (@TransitionActions) {
                        if ( $EntityID eq $Param{EntityID} ) {
                            my $TransitionData
                                = $Kernel::OM->Get('Kernel::System::ProcessManagement::DB::Transition')->TransitionGet(
                                EntityID => $TransitionEntityID,
                                UserID   => $Self->{UserID},
                                );
                            my $ActivityData
                                = $Kernel::OM->Get('Kernel::System::ProcessManagement::DB::Activity')->ActivityGet(
                                EntityID => $ActivityEntityID,
                                UserID   => $Self->{UserID},
                                );

                            push @Usage, "$Process->{Name} -> $ActivityData->{Name} -> $TransitionData->{Name}";
                            last ENTITY;
                        }
                    }
                }
            }
        }
    }
    else {

        return if !$Config{ $Param{EntityType} };

        my $Parent = $Config{ $Param{EntityType} }->{Parent};
        my $Method = $Config{ $Param{EntityType} }->{Method};
        my $Array  = $Config{ $Param{EntityType} }->{Array};

        # get a list of parents with all the details
        my $List = $Kernel::OM->Get( 'Kernel::System::ProcessManagement::DB::' . $Parent )->$Method(
            UserID => 1,
        );

        # search entity id in all parents
        PARENT:
        for my $ParentData ( @{$List} ) {

            next PARENT if !$ParentData;
            next PARENT if !$ParentData->{$Array};

            ENTITY:
            for my $EntityID ( @{ $ParentData->{$Array} } ) {
                if ( $EntityID eq $Param{EntityID} ) {
                    push @Usage, $ParentData->{Name};
                    last ENTITY;
                }
            }
        }
    }

    my $Deleteable = 0;

    if ( scalar @Usage == 0 ) {
        $Deleteable = 1;
    }

    return {
        Deleteable => $Deleteable,
        Usage      => \@Usage,
    };
}

sub _PushSessionScreen {
    my ( $Self, %Param ) = @_;

    # add screen to the screen path
    push @{ $Self->{ScreensPath} }, {
        Action          => $Self->{Action} || '',
        Subaction       => $Param{Subaction},
        ID              => $Param{ID},
        EntityID        => $Param{EntityID},
        ProcessEntityID => $Param{ProcessEntityID},
    };

    # convert screens path to string (JSON)
    my $JSONScreensPath = $Kernel::OM->Get('Kernel::Output::HTML::Layout')->JSONEncode(
        Data => $Self->{ScreensPath},
    );

    # update session
    $Kernel::OM->Get('Kernel::System::AuthSession')->UpdateSessionID(
        SessionID => $Self->{SessionID},
        Key       => 'ProcessManagementScreensPath',
        Value     => $JSONScreensPath,
    );

    return 1;
}

sub _GetProcessData {

    my ( $Self, %Param ) = @_;

    my %ProcessData;

    # get needed objects
    my $LayoutObject = $Kernel::OM->Get('Kernel::Output::HTML::Layout');

    # get process data
    my $Process = $Kernel::OM->Get('Kernel::System::ProcessManagement::DB::Process')->ProcessGet(
        ID     => $Param{ID},
        UserID => $Self->{UserID},
    );
    if ( !$Process ) {
        return $LayoutObject->ErrorScreen(
            Message => $LayoutObject->{LanguageObject}->Translate( 'Unknown Process %s!', $Param{ID} ),
        );
    }
    $ProcessData{Process} = $Process;

    # get all used activities
    for my $ActivityEntityID ( @{ $Process->{Activities} } ) {

        my $Activity = $Kernel::OM->Get('Kernel::System::ProcessManagement::DB::Activity')->ActivityGet(
            EntityID => $ActivityEntityID,
            UserID   => $Self->{UserID},
        );
        $ProcessData{Activities}->{$ActivityEntityID} = $Activity;

        # get all used activity dialogs
        for my $ActivityDialogEntityID ( @{ $Activity->{ActivityDialogs} } ) {

            my $ActivityDialog
                = $Kernel::OM->Get('Kernel::System::ProcessManagement::DB::ActivityDialog')->ActivityDialogGet(
                EntityID => $ActivityDialogEntityID,
                UserID   => $Self->{UserID},
                );
            $ProcessData{ActivityDialogs}->{$ActivityDialogEntityID} = $ActivityDialog;
        }
    }

    # get all used transitions
    for my $TransitionEntityID ( @{ $Process->{Transitions} } ) {

        my $Transition = $Kernel::OM->Get('Kernel::System::ProcessManagement::DB::Transition')->TransitionGet(
            EntityID => $TransitionEntityID,
            UserID   => $Self->{UserID},
        );
        $ProcessData{Transitions}->{$TransitionEntityID} = $Transition;
    }

    # get all used transition actions
    for my $TransitionActionEntityID ( @{ $Process->{TransitionActions} } ) {

        my $TransitionAction
            = $Kernel::OM->Get('Kernel::System::ProcessManagement::DB::TransitionAction')->TransitionActionGet(
            EntityID => $TransitionActionEntityID,
            UserID   => $Self->{UserID},
            );
        $ProcessData{TransitionActions}->{$TransitionActionEntityID} = $TransitionAction;
    }

    return \%ProcessData;
}

1;
