# --
# Copyright (C) 2001-2021 OTRS AG, https://otrs.com/
# Copyright (C) 2021 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see https://www.gnu.org/licenses/gpl-3.0.txt.
# --

package Kernel::Modules::AdminMailAccount;

use strict;
use warnings;

use Kernel::Language qw(Translatable);

our $ObjectManagerDisabled = 1;

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {%Param};
    bless( $Self, $Type );

    return $Self;
}

sub Run {
    my ( $Self, %Param ) = @_;

    my $LayoutObject      = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $ParamObject       = $Kernel::OM->Get('Kernel::System::Web::Request');
    my $MailAccountObject = $Kernel::OM->Get('Kernel::System::MailAccount');

    my %GetParam = ();
    my @Params   = (
        qw(
            ID Login Password Host Type TypeAdd Comment ValidID QueueID IMAPFolder Trusted DispatchingBy
            AuthenticationType OAuth2TokenConfigID
            )
    );
    for my $Parameter (@Params) {
        $GetParam{$Parameter} = $ParamObject->GetParam( Param => $Parameter );
    }

    # ------------------------------------------------------------ #
    # Run
    # ------------------------------------------------------------ #
    if ( $Self->{Subaction} eq 'Run' ) {

        # challenge token check for write action
        $LayoutObject->ChallengeTokenCheck();

        # Lock process with PID to prevent race conditions with console command
        # Maint::PostMaster::MailAccountFetch executed by the OTRS daemon or manually.
        # Please see bug#13235
        my $PIDObject = $Kernel::OM->Get('Kernel::System::PID');

        my $PIDCreated = $PIDObject->PIDCreate(
            Name => 'MailAccountFetch',
            TTL  => 600,                  # 10 minutes
        );

        if ( !$PIDCreated ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Unable to register the process in the database. Is another instance still running?"
            );
            return $LayoutObject->Redirect( OP => 'Action=AdminMailAccount;Locked=1' );
        }

        my %Data = $MailAccountObject->MailAccountGet(%GetParam);
        if ( !%Data ) {

            $PIDObject->PIDDelete( Name => 'MailAccountFetch' );
            return $LayoutObject->ErrorScreen();
        }

        my $Ok = $MailAccountObject->MailAccountFetch(
            %Data,
            Limit  => 15,
            UserID => $Self->{UserID},
        );

        $PIDObject->PIDDelete( Name => 'MailAccountFetch' );

        if ( !$Ok ) {
            return $LayoutObject->ErrorScreen();
        }
        return $LayoutObject->Redirect( OP => 'Action=AdminMailAccount;Ok=1' );
    }

    # ------------------------------------------------------------ #
    # delete
    # ------------------------------------------------------------ #
    elsif ( $Self->{Subaction} eq 'Delete' ) {

        # challenge token check for write action
        $LayoutObject->ChallengeTokenCheck();

        my $Delete = $MailAccountObject->MailAccountDelete(%GetParam);
        if ( !$Delete ) {
            return $LayoutObject->ErrorScreen();
        }
        return $LayoutObject->Attachment(
            ContentType => 'text/html',
            Content     => $Delete,
            Type        => 'inline',
            NoCache     => 1,
        );
    }

    # ------------------------------------------------------------ #
    # add new mail account
    # ------------------------------------------------------------ #
    elsif ( $Self->{Subaction} eq 'AddNew' ) {
        my $Output = $LayoutObject->Header();
        $Output .= $LayoutObject->NavigationBar();
        $Self->_MaskAddMailAccount(
            Action => 'AddNew',
            %GetParam,
        );
        $Output .= $LayoutObject->Output(
            TemplateFile => 'AdminMailAccount',
            Data         => \%Param,
        );
        $Output .= $LayoutObject->Footer();
        return $Output;
    }

    # ------------------------------------------------------------ #
    # add action
    # ------------------------------------------------------------ #
    elsif ( $Self->{Subaction} eq 'AddAction' ) {

        # challenge token check for write action
        $LayoutObject->ChallengeTokenCheck();

        my %Errors;

        # check needed data
        for my $Needed (qw(Login Host)) {
            if ( !$GetParam{$Needed} ) {
                $Errors{ $Needed . 'AddInvalid' } = 'ServerError';
            }
        }
        for my $Needed (qw(AuthenticationType TypeAdd ValidID)) {
            if ( !$GetParam{$Needed} ) {
                $Errors{ $Needed . 'Invalid' } = 'ServerError';
            }
        }

        if (
            $GetParam{AuthenticationType} eq 'password'
            && ( !defined $GetParam{Password} || !length $GetParam{Password} )
            )
        {
            $Errors{'PasswordAddInvalid'} = 'ServerError';
        }
        elsif (
            $GetParam{AuthenticationType} eq 'oauth2_token'
            && ( !defined $GetParam{OAuth2TokenConfigID} || !length $GetParam{OAuth2TokenConfigID} )
            )
        {
            $Errors{'OAuth2TokenConfigIDInvalid'} = 'ServerError';
        }

        # if no errors occurred
        if ( !%Errors ) {

            # Since the password field is mandatory in database, set a fake password.
            if ( $GetParam{AuthenticationType} eq 'oauth2_token' ) {
                $GetParam{Password} = 'OAuth2Token';
            }
            elsif ( $GetParam{AuthenticationType} eq 'password' ) {
                $GetParam{OAuth2TokenConfigID} = undef;
            }

            # add mail account
            my $ID = $MailAccountObject->MailAccountAdd(
                %GetParam,
                Type   => $GetParam{'TypeAdd'},
                UserID => $Self->{UserID},
            );
            if ($ID) {
                $Self->_Overview();
                my $Output = $LayoutObject->Header();
                $Output .= $LayoutObject->NavigationBar();
                $Output .= $LayoutObject->Notify( Info => Translatable('Mail account added!') );
                $Output .= $LayoutObject->Output(
                    TemplateFile => 'AdminMailAccount',
                    Data         => \%Param,
                );
                $Output .= $LayoutObject->Footer();
                return $Output;
            }
        }

        # something has gone wrong
        my $Output = $LayoutObject->Header();
        $Output .= $LayoutObject->NavigationBar();
        $Output .= $LayoutObject->Notify( Priority => 'Error' );
        $Self->_MaskAddMailAccount(
            Action => 'AddNew',
            Errors => \%Errors,
            %GetParam,
        );
        $Output .= $LayoutObject->Output(
            TemplateFile => 'AdminMailAccount',
            Data         => \%Param,
        );
        $Output .= $LayoutObject->Footer();
        return $Output;
    }

    # ------------------------------------------------------------ #
    # update
    # ------------------------------------------------------------ #
    elsif ( $Self->{Subaction} eq 'Update' ) {
        my %Data   = $MailAccountObject->MailAccountGet(%GetParam);
        my $Output = $LayoutObject->Header();
        $Output .= $LayoutObject->NavigationBar();
        $Self->_MaskUpdateMailAccount(
            Action => 'Update',
            %Data,
        );
        $Output .= $LayoutObject->Output(
            TemplateFile => 'AdminMailAccount',
            Data         => \%Param,
        );
        $Output .= $LayoutObject->Footer();
        return $Output;
    }

    # ------------------------------------------------------------ #
    # update action
    # ------------------------------------------------------------ #
    elsif ( $Self->{Subaction} eq 'UpdateAction' ) {

        # challenge token check for write action
        $LayoutObject->ChallengeTokenCheck();

        my %Errors;

        # check needed data
        for my $Needed (qw(Login Host)) {
            if ( !$GetParam{$Needed} ) {
                $Errors{ $Needed . 'EditInvalid' } = 'ServerError';
            }
        }
        for my $Needed (qw(AuthenticationType Type ValidID DispatchingBy QueueID)) {
            if ( !$GetParam{$Needed} ) {
                $Errors{ $Needed . 'Invalid' } = 'ServerError';
            }
        }
        if ( !$GetParam{Trusted} ) {
            $Errors{TrustedInvalid} = 'ServerError' if ( $GetParam{Trusted} != 0 );
        }

        if (
            $GetParam{AuthenticationType} eq 'password'
            && ( !defined $GetParam{Password} || !length $GetParam{Password} )
            )
        {
            $Errors{'PasswordEditInvalid'} = 'ServerError';
        }
        elsif (
            $GetParam{AuthenticationType} eq 'oauth2_token'
            && ( !defined $GetParam{OAuth2TokenConfigID} || !length $GetParam{OAuth2TokenConfigID} )
            )
        {
            $Errors{'OAuth2TokenConfigIDInvalid'} = 'ServerError';
        }

        # if no errors occurred
        if ( !%Errors ) {

            if ( $GetParam{Password} eq 'dummy-password-placeholder' ) {
                my %OriginalData = $MailAccountObject->MailAccountGet(%GetParam);
                $GetParam{Password} = $OriginalData{Password};
            }

            # Since the password field is mandatory in database, set a fake password.
            if ( $GetParam{AuthenticationType} eq 'oauth2_token' ) {
                $GetParam{Password} = 'OAuth2Token';
            }
            elsif ( $GetParam{AuthenticationType} eq 'password' ) {
                $GetParam{OAuth2TokenConfigID} = undef;
            }

            # update mail account
            my $Update = $MailAccountObject->MailAccountUpdate(
                %GetParam,
                UserID => $Self->{UserID},
            );
            if ($Update) {

                # if the user would like to continue editing the mail account just redirect to the edit screen
                if (
                    defined $ParamObject->GetParam( Param => 'ContinueAfterSave' )
                    && ( $ParamObject->GetParam( Param => 'ContinueAfterSave' ) eq '1' )
                    )
                {
                    my $ID = $ParamObject->GetParam( Param => 'ID' ) || '';
                    return $LayoutObject->Redirect(
                        OP => "Action=$Self->{Action};Subaction=Update;ID=$ID"
                    );
                }
                else {

                    # otherwise return to overview
                    return $LayoutObject->Redirect( OP => "Action=$Self->{Action}" );
                }
            }
        }

        # something has gone wrong
        my $Output = $LayoutObject->Header();
        $Output .= $LayoutObject->NavigationBar();
        $Output .= $LayoutObject->Notify( Priority => 'Error' );
        $Self->_MaskUpdateMailAccount(
            Action => 'Update',
            Errors => \%Errors,
            %GetParam,
        );
        $Output .= $LayoutObject->Output(
            TemplateFile => 'AdminMailAccount',
            Data         => \%Param,
        );
        $Output .= $LayoutObject->Footer();
        return $Output;
    }

    # ------------------------------------------------------------ #
    # overview
    # ------------------------------------------------------------ #
    else {
        $Self->_Overview();

        my $Ok     = $ParamObject->GetParam( Param => 'Ok' );
        my $Locked = $ParamObject->GetParam( Param => 'Locked' );

        my $Output = $LayoutObject->Header();
        $Output .= $LayoutObject->NavigationBar();

        if ($Ok) {
            $Output .= $LayoutObject->Notify( Info => Translatable('Finished') );
        }
        if ($Locked) {
            $Output .= $LayoutObject->Notify(
                Info => Translatable('Email account fetch already fetched by another process. Please try again later!'),
            );
        }

        $Output .= $LayoutObject->Output(
            TemplateFile => 'AdminMailAccount',
            Data         => \%Param,
        );
        $Output .= $LayoutObject->Footer();
        return $Output;
    }
}

sub _Overview {
    my ( $Self, %Param ) = @_;

    my $LayoutObject      = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $MailAccountObject = $Kernel::OM->Get('Kernel::System::MailAccount');

    my %Backend = $MailAccountObject->MailAccountBackendList();

    $LayoutObject->Block(
        Name => 'Overview',
        Data => \%Param,
    );

    $LayoutObject->Block( Name => 'ActionList' );
    $LayoutObject->Block( Name => 'ActionAdd' );
    $LayoutObject->Block( Name => 'Filter' );

    $LayoutObject->Block(
        Name => 'OverviewResult',
        Data => \%Param,
    );

    my %List                = $MailAccountObject->MailAccountList( Valid => 0 );
    my %AuthenticationTypes = $MailAccountObject->GetAuthenticationTypes();

    # if there are any mail accounts, they are shown
    if (%List) {
        for my $ListKey ( sort { $List{$a} cmp $List{$b} } keys %List ) {
            my %Data = $MailAccountObject->MailAccountGet( ID => $ListKey );
            if ( !$Backend{ $Data{Type} } ) {
                $Data{Type} .= '(not installed!)';
            }

            my @List = $Kernel::OM->Get('Kernel::System::Valid')->ValidIDsGet();
            $Data{ShownValid} = $Kernel::OM->Get('Kernel::System::Valid')->ValidLookup(
                ValidID => $Data{ValidID},
            );

            $LayoutObject->Block(
                Name => 'OverviewResultRow',
                Data => {
                    %Data,
                    AuthenticationTypes => \%AuthenticationTypes,
                },
            );
        }
    }

    # otherwise a no data found msg is displayed
    else {
        $LayoutObject->Block(
            Name => 'NoDataFoundMsg',
            Data => {},
        );
    }
    return 1;
}

sub _MaskUpdateMailAccount {
    my ( $Self, %Param ) = @_;

    my $LayoutObject = $Kernel::OM->Get('Kernel::Output::HTML::Layout');

    # get valid list
    my %ValidList        = $Kernel::OM->Get('Kernel::System::Valid')->ValidList();
    my %ValidListReverse = reverse %ValidList;

    # build ValidID string
    $Param{ValidOption} = $LayoutObject->BuildSelection(
        Data       => \%ValidList,
        Name       => 'ValidID',
        SelectedID => $Param{ValidID} || $ValidListReverse{valid},
        Class      => 'Modernize Validate_Required ' . ( $Param{Errors}->{'ValidIDInvalid'} || '' ),
    );

    $Param{TypeOption} = $LayoutObject->BuildSelection(
        Data       => { $Kernel::OM->Get('Kernel::System::MailAccount')->MailAccountBackendList() },
        Name       => 'Type',
        SelectedID => $Param{Type} || $Param{TypeAdd} || '',
        Class      => 'Modernize Validate_Required ' . ( $Param{Errors}->{'TypeInvalid'} || '' ),
    );

    $Param{AuthenticationTypeSelection} = $Self->_BuildAuthenticationTypeSelection(
        SelectedAuthenticationType => $Param{AuthenticationType},
        Errors                     => $Param{Errors},
    );

    $Param{OAuth2TokenConfigSelection} = $Self->_BuildOAuth2TokenConfigSelection(
        SelectedOAuth2TokenConfigID => $Param{OAuth2TokenConfigID},
        Errors                      => $Param{Errors},
    );

    $Param{TrustedOption} = $LayoutObject->BuildSelection(
        Data       => $Kernel::OM->Get('Kernel::Config')->Get('YesNoOptions'),
        Name       => 'Trusted',
        SelectedID => $Param{Trusted} || 0,
        Class      => 'Modernize ' . ( $Param{Errors}->{'TrustedInvalid'} || '' ),
    );

    $Param{DispatchingOption} = $LayoutObject->BuildSelection(
        Data => {
            From  => Translatable('Dispatching by email To: field.'),
            Queue => Translatable('Dispatching by selected Queue.'),
        },
        Name       => 'DispatchingBy',
        SelectedID => $Param{DispatchingBy},
        Class      => 'Modernize Validate_Required ' . ( $Param{Errors}->{'DispatchingByInvalid'} || '' ),
    );

    $Param{QueueOption} = $LayoutObject->AgentQueueListOption(
        Data           => { $Kernel::OM->Get('Kernel::System::Queue')->QueueList( Valid => 1 ) },
        Name           => 'QueueID',
        SelectedID     => $Param{QueueID},
        OnChangeSubmit => 0,
        Class          => 'Modernize Validate_Required ' . ( $Param{Errors}->{'QueueIDInvalid'} || '' ),
    );
    $LayoutObject->Block(
        Name => 'Overview',
        Data => { %Param, },
    );
    $LayoutObject->Block(
        Name => 'ActionList',
    );
    $LayoutObject->Block(
        Name => 'ActionOverview',
    );
    $LayoutObject->Block(
        Name => 'OverviewUpdate',
        Data => {
            %Param,
            %{ $Param{Errors} },
        },
    );

    return 1;
}

sub _MaskAddMailAccount {
    my ( $Self, %Param ) = @_;

    my $LayoutObject = $Kernel::OM->Get('Kernel::Output::HTML::Layout');

    # get valid list
    my %ValidList        = $Kernel::OM->Get('Kernel::System::Valid')->ValidList();
    my %ValidListReverse = reverse %ValidList;

    # build ValidID string
    $Param{ValidOption} = $LayoutObject->BuildSelection(
        Data       => \%ValidList,
        Name       => 'ValidID',
        SelectedID => $Param{ValidID} || $ValidListReverse{valid},
        Class      => 'Modernize Validate_Required ' . ( $Param{Errors}->{'ValidIDInvalid'} || '' ),
    );

    $Param{TypeOptionAdd} = $LayoutObject->BuildSelection(
        Data       => { $Kernel::OM->Get('Kernel::System::MailAccount')->MailAccountBackendList() },
        Name       => 'TypeAdd',
        SelectedID => $Param{Type} || $Param{TypeAdd} || '',
        Class      => 'Modernize Validate_Required ' . ( $Param{Errors}->{'TypeAddInvalid'} || '' ),
    );

    $Param{AuthenticationTypeSelection} = $Self->_BuildAuthenticationTypeSelection(
        SelectedAuthenticationType => $Param{AuthenticationType},
        Errors                     => $Param{Errors},
    );

    $Param{OAuth2TokenConfigSelection} = $Self->_BuildOAuth2TokenConfigSelection(
        SelectedOAuth2TokenConfigID => $Param{OAuth2TokenConfigID},
        Errors                      => $Param{Errors},
    );

    $Param{TrustedOption} = $LayoutObject->BuildSelection(
        Data       => $Kernel::OM->Get('Kernel::Config')->Get('YesNoOptions'),
        Name       => 'Trusted',
        Class      => 'Modernize ' . ( $Param{Errors}->{'TrustedInvalid'} || '' ),
        SelectedID => $Param{Trusted} || 0,
    );

    $Param{DispatchingOption} = $LayoutObject->BuildSelection(
        Data => {
            From  => Translatable('Dispatching by email To: field.'),
            Queue => Translatable('Dispatching by selected Queue.'),
        },
        Name       => 'DispatchingBy',
        SelectedID => $Param{DispatchingBy},
        Class      => 'Modernize Validate_Required ' . ( $Param{Errors}->{'DispatchingByInvalid'} || '' ),
    );

    $Param{QueueOption} = $LayoutObject->AgentQueueListOption(
        Data           => { $Kernel::OM->Get('Kernel::System::Queue')->QueueList( Valid => 1 ) },
        Name           => 'QueueID',
        SelectedID     => $Param{QueueID},
        OnChangeSubmit => 0,
        Class          => 'Modernize Validate_Required ' . ( $Param{Errors}->{'QueueIDInvalid'} || '' ),
    );
    $LayoutObject->Block(
        Name => 'Overview',
        Data => { %Param, },
    );
    $LayoutObject->Block(
        Name => 'ActionList',
    );
    $LayoutObject->Block(
        Name => 'ActionOverview',
    );
    $LayoutObject->Block(
        Name => 'OverviewAdd',
        Data => {
            %Param,
            %{ $Param{Errors} },
        },
    );

    return 1;
}

sub _BuildAuthenticationTypeSelection {
    my ( $Self, %Param ) = @_;

    my $LayoutObject      = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $MailAccountObject = $Kernel::OM->Get('Kernel::System::MailAccount');

    my %AuthenticationTypes = $MailAccountObject->GetAuthenticationTypes();

    my $SelectionHTML = $LayoutObject->BuildSelection(
        Data        => \%AuthenticationTypes,
        Name        => 'AuthenticationType',
        SelectedID  => $Param{SelectedAuthenticationType} // 'password',
        Class       => 'Modernize Validate_Required ' . ( $Param{Errors}->{'AuthenticationTypeInvalid'} // '' ),
        Translation => 1,
    );

    return $SelectionHTML;
}

sub _BuildOAuth2TokenConfigSelection {
    my ( $Self, %Param ) = @_;

    my $LayoutObject            = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $ValidObject             = $Kernel::OM->Get('Kernel::System::Valid');
    my $OAuth2TokenConfigObject = $Kernel::OM->Get('Kernel::System::OAuth2TokenConfig');

    my %ValidList        = $ValidObject->ValidList();
    my %ValidListReverse = reverse %ValidList;

    my @ValidOAuth2TokenConfigs = $OAuth2TokenConfigObject->DataListGet(
        ValidID => $ValidListReverse{valid},
        UserID  => $Self->{UserID},
    );

    my %ValidOAuth2TokenConfigs = map {
        $_->{ $OAuth2TokenConfigObject->{Identifier} } => $_->{Name}
    } @ValidOAuth2TokenConfigs;

    my $SelectionHTML = $LayoutObject->BuildSelection(
        Data       => \%ValidOAuth2TokenConfigs,
        Name       => 'OAuth2TokenConfigID',
        SelectedID => $Param{SelectedOAuth2TokenConfigID} // '',
        Class      => 'Modernize ' . ( $Param{Errors}->{'OAuth2TokenConfigIDInvalid'} || '' ),
        PossibleNone => 1,    # to be able to set it to empty if a configured token config has gone invalid.
    );

    return $SelectionHTML;
}

1;
