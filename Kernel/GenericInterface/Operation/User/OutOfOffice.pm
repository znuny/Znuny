# --
# Copyright (C) 2021 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::GenericInterface::Operation::User::OutOfOffice;

use strict;
use warnings;

use Kernel::System::User;
use Kernel::System::VariableCheck qw(:all);

use parent qw(Kernel::GenericInterface::Operation::Common);

our $ObjectManagerDisabled = 1;

=head1 NAME

Kernel::GenericInterface::Operation::User::OutOfOffice

=head1 PUBLIC INTERFACE

=head2 new()

usually, you want to create an instance of this
by using Kernel::GenericInterface::Operation->new();

=cut

sub new {
    my ( $Type, %Param ) = @_;

    my $Self = {};
    bless( $Self, $Type );

    for my $Needed (qw( DebuggerObject WebserviceID )) {
        if ( !$Param{$Needed} ) {
            return {
                Success      => 0,
                ErrorMessage => "Got no $Needed!"
            };
        }

        $Self->{$Needed} = $Param{$Needed};
    }

    return $Self;
}

=head2 Run()

Sets out-of-office information for a specific user.

    my $Result = $OperationObject->Run(
        Data => {
            UserEmail   => 'root@localhost',
            StartDate   => '2014-07-31',
            EndDate     => '2014-08-07',
            OutOfOffice => 1,
        },
    );

    OR

    my $Result = $OperationObject->Run(
        Data => {
            SessionID                   => 'AValidSessionIDValue',                          # the ID of the user session
            UserLogin                   => 'Agent',                                         # if no SessionID is given UserLogin is required
            Password                    => 'some password',                                 # user password
            OutOfOfficeEntriesCSVString => 'Original CSV string with out-of-office data',

            # These are the parsed entries of the CSV string above.
            OutOfOfficeEntries => [
                {
                    UserEmail   => 'root@localhost',
                    OutOfOffice => 0,
                },
                {
                    UserLogin   => 'root',
                    StartDate   => '2014-07-31',
                    EndDate     => '2014-08-07',
                    OutOfOffice => 1,
                },
                {
                    UserSearch   => 'root',
                    StartDate   => '2014-07-31',
                    EndDate     => '2014-08-07',
                    OutOfOffice => 1,
                },
                # ...
            ],
        },
    );

    $Result = {
        Success         => 1,                                   # 0 or 1
        ErrorMessage    => '',                                  # in case of error
        Data            => {                                    # result data payload after Operation
            Success => 1,
            Error   => {                                        # should not return errors
                    ErrorCode    => 'OutOfOffice.ErrorCode',
                    ErrorMessage => 'Error Description'
            },
        },
    };

=cut

sub Run {
    my ( $Self, %Param ) = @_;

    my $UserObject  = $Kernel::OM->Get('Kernel::System::User');
    my $GroupObject = $Kernel::OM->Get('Kernel::System::Group');

    my $Result;

    my ( $UserID, $UserType ) = $Self->Auth(%Param);

    if ( !$UserID ) {
        return $Self->ReturnError(
            ErrorCode    => 'OutOfOffice.AuthFail',
            ErrorMessage => 'OutOfOffice: Authentication failed.',
        );
    }
    if ( $UserType ne 'User' ) {
        return $Self->ReturnError(
            ErrorCode    => 'OutOfOffice.AuthFail',
            ErrorMessage => 'OutOfOffice: User needs to be an agent.',
        );
    }

    # Only users of group admin allowed.
    my %Groups = reverse $GroupObject->PermissionUserGet(
        UserID => $UserID,
        Type   => 'rw',
    );
    if ( !%Groups || !$Groups{admin} ) {
        return $Self->ReturnError(
            ErrorCode    => 'OutOfOffice.AuthFail',
            ErrorMessage => 'OutOfOffice: User needs to be in group admin.',
        );
    }

    my $OutOfOfficeEntries = $Param{Data}->{OutOfOfficeEntries};
    if ( !IsArrayRefWithData($OutOfOfficeEntries) ) {
        my $ErrorMessage = 'Payload does not contain out-of-office entries or they could not be parsed.';

        $Self->EnhancedLogging(
            Level   => 'error',
            Message => $ErrorMessage,
        );

        $Result = {
            Success      => 0,
            ErrorMessage => $ErrorMessage,
            Data         => {
                Success => 1,
                Error   => {
                    ErrorCode    => 'OutOfOffice.WrongInputStructure',
                    ErrorMessage => $ErrorMessage,
                },
            }
        };

        return $Result;
    }

    OUTOFOFFICEENTRY:
    for my $OutOfOfficeEntry ( @{$OutOfOfficeEntries} ) {
        if (
            !IsHashRefWithData($OutOfOfficeEntry)
            || (
                !IsStringWithData( $OutOfOfficeEntry->{UserEmail} )
                && !IsStringWithData( $OutOfOfficeEntry->{UserSearch} )
                && !IsStringWithData( $OutOfOfficeEntry->{UserLogin} )
            )
            )
        {
            my $ErrorMessage = 'Invalid data structure for out-of-office entry.';

            $Self->EnhancedLogging(
                Level   => 'error',
                Message => $ErrorMessage,
                Data    => {
                    Entry => $OutOfOfficeEntry,
                }
            );
            next OUTOFOFFICEENTRY;
        }

        if ( IsStringWithData( $OutOfOfficeEntry->{UserSearch} ) ) {
            $OutOfOfficeEntry->{UserSearch} =~ s{\s+}{+}g;
        }

        my %Users = $UserObject->UserSearch(
            PostMasterSearch => $OutOfOfficeEntry->{UserEmail},
            Search           => $OutOfOfficeEntry->{UserSearch},
            UserLogin        => $OutOfOfficeEntry->{UserLogin},
        );

        my @UserIDs = keys %Users;

        if ( @UserIDs != 1 ) {
            my $ErrorMessage = 'Error while looking up unique user ID.';

            $Self->EnhancedLogging(
                Level   => 'notice',
                Message => $ErrorMessage,
                Data    => {
                    Entry    => $OutOfOfficeEntry,
                    UserList => \%Users,
                }
            );
            next OUTOFOFFICEENTRY;
        }

        my $UserID    = $UserIDs[0];
        my $UserLogin = $UserObject->UserLookup(
            UserID => $UserID,
        );
        next OUTOFOFFICEENTRY if !$UserLogin;

        my %OutOfOfficePreferenceData;
        DATEPART:
        for my $DatePart (qw(Start End)) {
            last DATEPART if !IsStringWithData( $OutOfOfficeEntry->{ $DatePart . 'Date' } );
            last DATEPART if $OutOfOfficeEntry->{ $DatePart . 'Date' } !~ m{(\d{4})-(\d{2})-(\d{2})};

            $OutOfOfficePreferenceData{ 'OutOfOffice' . $DatePart . 'Year' }  = $1;
            $OutOfOfficePreferenceData{ 'OutOfOffice' . $DatePart . 'Month' } = $2;
            $OutOfOfficePreferenceData{ 'OutOfOffice' . $DatePart . 'Day' }   = $3;
        }

        $OutOfOfficePreferenceData{OutOfOffice} = $OutOfOfficeEntry->{OutOfOffice} ? 1 : 0;

        ATTRIBUTE:
        for my $Attribute (
            qw(
            OutOfOffice
            OutOfOfficeStartYear OutOfOfficeStartMonth OutOfOfficeStartDay
            OutOfOfficeEndYear OutOfOfficeEndMonth OutOfOfficeEndDay
            )
            )
        {
            next ATTRIBUTE if !defined $OutOfOfficePreferenceData{$Attribute};

            $UserObject->SetPreferences(
                UserID => $UserID,
                Key    => $Attribute,
                Value  => $OutOfOfficePreferenceData{$Attribute},
            );
        }
    }

    $Result = {
        Success => 1,
        Data    => {
            Success => 1,
        },
    };

    return $Result;
}

# combined logging for the generic interface and default Znuny log
sub EnhancedLogging {
    my ( $Self, %Param ) = @_;

    my $LogObject = $Kernel::OM->Get('Kernel::System::Log');

    if ( $Self->{DebuggerObject} ) {
        $Self->{DebuggerObject}->DebugLog(
            DebugLevel => $Param{Level},
            Summary    => $Param{Message},
            Data       => $Param{Data}
        );
    }

    # if the web service ID is present, add it as a log prefix, so the admin knows what's up
    if ( $Self->{WebserviceID} ) {
        $Param{Message} = "Web service ID '$Self->{WebserviceID}': $Param{Message}";
    }

    $LogObject->Log(
        Priority => $Param{Level},
        Message  => $Param{Message}
    );

    return 1;
}

1;
