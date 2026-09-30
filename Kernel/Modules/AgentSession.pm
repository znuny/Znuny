# --
# Copyright (C) 2021 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::Modules::AgentSession;

use strict;
use warnings;
use utf8;

our $ObjectManagerDisabled = 1;

use Kernel::Language qw(Translatable);

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {%Param};
    bless( $Self, $Type );

    return $Self;
}

sub Run {
    my ( $Self, %Param ) = @_;

    my $ConfigObject  = $Kernel::OM->Get('Kernel::Config');
    my $LogObject     = $Kernel::OM->Get('Kernel::System::Log');
    my $LayoutObject  = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $ParamObject   = $Kernel::OM->Get('Kernel::System::Web::Request');
    my $SessionObject = $Kernel::OM->Get('Kernel::System::AuthSession');

    # ------------------------------------------------------------ #
    # update session via AJAX
    # ------------------------------------------------------------ #
    if ( $Self->{Subaction} eq 'UpdateAJAX' ) {

        # challenge token check for write action
        $LayoutObject->ChallengeTokenCheck();

        my $Key   = $ParamObject->GetParam( Param => 'Key' );
        my $Value = $ParamObject->GetParam( Param => 'Value' );

        if ( !$Key ) {
            $LogObject->Log(
                Priority => 'error',
                Message  => 'AgentSession: Got no Key parameter!',
            );

            my $JSON = $LayoutObject->JSONEncode(
                Data => {
                    Success => 0,
                    Message => 'Key parameter is required',
                },
            );
            return $LayoutObject->Attachment(
                ContentType => 'application/json; charset=' . $LayoutObject->{Charset},
                Content     => $JSON,
                Type        => 'inline',
                NoCache     => 1,
            );
        }

        #
        # Check config AgentSession::AJAXUpdate::AllowedKeys
        # if the key is allowed to be set via AJAX
        #
        my $KeyAllowed  = 1;
        my $AllowedKeys = $ConfigObject->Get('AgentSession::AJAXUpdate::AllowedKeys') // {};

        if ( %{$AllowedKeys} ) {
            $KeyAllowed = 0;
            CONTEXT:
            for my $Context ( sort keys %{$AllowedKeys} ) {
                ALLOWEDKEYREGEX:
                for my $AllowedKeyRegex ( @{ $AllowedKeys->{$Context} // [] } ) {
                    next ALLOWEDKEYREGEX if $Key !~ m{$AllowedKeyRegex};

                    $KeyAllowed = 1;
                    last CONTEXT;
                }
            }
        }

        my $Success = 0;

        if ($KeyAllowed) {

            # Update session only (no preferences)
            $Success = $SessionObject->UpdateSessionID(
                SessionID => $Self->{SessionID},
                Key       => $Key,
                Value     => $Value,
            );

            if ( !$Success ) {
                $LogObject->Log(
                    Priority => 'error',
                    Message  => "AgentSession: Failed to update session key '$Key'",
                );
            }
        }
        else {
            $LogObject->Log(
                Priority => 'debug',
                Message  =>
                    "AgentSession: Session key '$Key' is not configured in AgentSession::AJAXUpdate::AllowedKeys to be allowed to be set via UpdateAJAX.",
            );
        }

        my $JSON = $LayoutObject->JSONEncode(
            Data => {
                Success => $Success,
            },
        );
        return $LayoutObject->Attachment(
            ContentType => 'application/json; charset=' . $LayoutObject->{Charset},
            Content     => $JSON,
            Type        => 'inline',
            NoCache     => 1,
        );
    }

    # ------------------------------------------------------------ #
    # default: return error
    # ------------------------------------------------------------ #
    my $JSON = $LayoutObject->JSONEncode(
        Data => {
            Success => 0,
        },
    );
    return $LayoutObject->Attachment(
        ContentType => 'application/json; charset=' . $LayoutObject->{Charset},
        Content     => $JSON,
        Type        => 'inline',
        NoCache     => 1,
    );
}

1;
