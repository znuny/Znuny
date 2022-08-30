# --
# Copyright (C) 2001-2021 OTRS AG, https://otrs.com/
# Copyright (C) 2021-2022 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see https://www.gnu.org/licenses/gpl-3.0.txt.
# --

package Kernel::Modules::AgentAppointmentList;

use strict;
use warnings;

use Kernel::System::VariableCheck qw(:all);

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

    my $Output;

    # get param object
    my $ParamObject = $Kernel::OM->Get('Kernel::System::Web::Request');

    # get names of all parameters
    my @ParamNames = $ParamObject->GetParamNames();

    # get params
    my %GetParam;

    KEY:
    for my $Key (@ParamNames) {
        next KEY if $Key eq 'AppointmentIDs';
        $GetParam{$Key} = $ParamObject->GetParam( Param => $Key );

        my %SafeGetParam = $Kernel::OM->Get('Kernel::System::HTMLUtils')->Safety(
            String       => $GetParam{$Key},
            NoApplet     => 1,
            NoObject     => 1,
            NoEmbed      => 1,
            NoSVG        => 1,
            NoImg        => 1,
            NoIntSrcLoad => 1,
            NoExtSrcLoad => 1,
            NoJavaScript => 1,
        );

        $GetParam{$Key} = $SafeGetParam{String};
    }

    my $ConfigObject      = $Kernel::OM->Get('Kernel::Config');
    my $LayoutObject      = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $CalendarObject    = $Kernel::OM->Get('Kernel::System::Calendar');
    my $AppointmentObject = $Kernel::OM->Get('Kernel::System::Calendar::Appointment');
    my $PluginObject      = $Kernel::OM->Get('Kernel::System::Calendar::Plugin');

    my $JSON = $LayoutObject->JSONEncode( Data => [] );

    $LayoutObject->ChallengeTokenCheck();

    # check request
    if ( $Self->{Subaction} eq 'ListAppointments' ) {

        if ( $GetParam{CalendarID} ) {

            for my $Timestamp (qw(StartTime EndTime)) {

                if ( $GetParam{$Timestamp} && !( $GetParam{$Timestamp} =~ /T\d{2}:\d{2}\+\d{2}:\d{2}$/ ) ) {

                    # Date format: 2020-07-27T00:01:10+02:00. In this case we need to set it to the midnight.
                    $GetParam{$Timestamp} =~ s{T.*}{ 00:00:00}s;
                }
                elsif ( $GetParam{$Timestamp} && !( $GetParam{$Timestamp} =~ /\s\d{2}:\d{2}:\d{2}$/ ) ) {

                    # Date format: 2020-07-27, missing time component. Set it to the midnight.
                    $GetParam{$Timestamp} = $GetParam{$Timestamp} . ' 00:00:00';
                }
            }

            my $StartTimeObject = $Kernel::OM->Create(
                'Kernel::System::DateTime',
                ObjectParams => {
                    String   => $GetParam{StartTime},
                    TimeZone => $Self->{UserTimeZone} // undef,
                },
            );
            my $EndTimeObject = $Kernel::OM->Create(
                'Kernel::System::DateTime',
                ObjectParams => {
                    String   => $GetParam{EndTime},
                    TimeZone => $Self->{UserTimeZone} // undef,
                },
            );

            if ( $Self->{UserTimeZone} ) {
                $StartTimeObject->ToOTRSTimeZone();
                $EndTimeObject->ToOTRSTimeZone();
            }

            $GetParam{StartTime} = $StartTimeObject->ToString();
            $GetParam{EndTime}   = $EndTimeObject->ToString();

            # reset empty parameters
            for my $Param ( sort keys %GetParam ) {
                if ( !$GetParam{$Param} ) {
                    $GetParam{$Param} = undef;
                }
            }

            my $UserHasCalendarPermission = $CalendarObject->CalendarPermissionGet(
                CalendarID => $GetParam{CalendarID},
                UserID     => $Self->{UserID},
            );

            my @Appointments;
            if ($UserHasCalendarPermission) {
                @Appointments = $AppointmentObject->AppointmentList(
                    %GetParam,
                );
            }

            # go through all appointments
            for my $Appointment (@Appointments) {

                # check for notification date
                if (
                    !$Appointment->{NotificationDate}
                    || $Appointment->{NotificationDate} eq '0000-00-00 00:00:00'
                    )
                {
                    $Appointment->{NotificationDate} = '';
                }

                my $StartTimeObject = $Kernel::OM->Create(
                    'Kernel::System::DateTime',
                    ObjectParams => {
                        String => $Appointment->{StartTime},
                    },
                );
                my $EndTimeObject = $Kernel::OM->Create(
                    'Kernel::System::DateTime',
                    ObjectParams => {
                        String => $Appointment->{EndTime},
                    },
                );

                # save time stamps for display before calculation
                $Appointment->{StartDate} = $Appointment->{StartTime};
                $Appointment->{EndDate}   = $Appointment->{EndTime};

                # End times for all day appointments are inclusive, subtract whole day.
                if ( $Appointment->{AllDay} ) {
                    $EndTimeObject->Subtract(
                        Days => 1,
                    );
                    if ( $EndTimeObject < $StartTimeObject ) {
                        $EndTimeObject = $StartTimeObject->Clone();
                    }
                    $Appointment->{EndDate} = $EndTimeObject->ToString();
                }

                # calculate local times for control
                else {
                    if ( $Self->{UserTimeZone} ) {
                        $StartTimeObject->ToTimeZone( TimeZone => $Self->{UserTimeZone} );
                        $EndTimeObject->ToTimeZone( TimeZone => $Self->{UserTimeZone} );
                    }

                    $Appointment->{StartTime} = $StartTimeObject->ToString();
                    $Appointment->{EndTime}   = $EndTimeObject->ToString();
                }

                # formatted date/time strings used in display
                $Appointment->{StartDate} = $LayoutObject->{LanguageObject}->FormatTimeString(
                    $Appointment->{StartDate},
                    'DateFormat' . ( $Appointment->{AllDay} ? 'Short' : '' )
                );
                $Appointment->{EndDate} = $LayoutObject->{LanguageObject}->FormatTimeString(
                    $Appointment->{EndDate},
                    'DateFormat' . ( $Appointment->{AllDay} ? 'Short' : '' )
                );
                if ( $Appointment->{NotificationDate} ) {
                    $Appointment->{NotificationDate} = $LayoutObject->{LanguageObject}->FormatTimeString(
                        $Appointment->{NotificationDate},
                        'DateFormat'
                    );
                }

                # include resource data
                $Appointment->{TeamName}      = '';
                $Appointment->{ResourceNames} = '';

                if (
                    $Kernel::OM->Get('Kernel::System::Main')->Require(
                        'Kernel::System::Calendar::Team',
                        Silent => 1,
                    )
                    )
                {
                    if ( $Appointment->{TeamID} ) {
                        my $TeamObject = $Kernel::OM->Get('Kernel::System::Calendar::Team');
                        my @TeamNames;
                        TEAMID:
                        for my $TeamID ( @{ $Appointment->{TeamID} } ) {
                            next TEAMID if !$TeamID;
                            my %Team = $TeamObject->TeamGet(
                                TeamID => $TeamID,
                                UserID => $Self->{UserID},
                            );
                            push @TeamNames, $Team{Name} if %Team;
                        }

                        # truncate more than three elements
                        my $TeamCount = scalar @TeamNames;
                        if ( $TeamCount > 4 ) {
                            splice @TeamNames, 3;
                            push @TeamNames, $LayoutObject->{LanguageObject}->Translate( '+%s more', $TeamCount - 3 );
                        }

                        $Appointment->{TeamNames} = join( '\n', @TeamNames );
                    }
                    if ( $Appointment->{ResourceID} ) {
                        my $UserObject = $Kernel::OM->Get('Kernel::System::User');
                        my @ResourceNames;
                        RESOURCEID:
                        for my $ResourceID ( @{ $Appointment->{ResourceID} } ) {
                            next RESOURCEID if !$ResourceID;
                            my %User = $UserObject->GetUserData(
                                UserID => $ResourceID,
                            );
                            push @ResourceNames, $User{UserFullname};
                        }

                        # truncate more than three elements
                        my $ResourceCount = scalar @ResourceNames;
                        if ( $ResourceCount > 4 ) {
                            splice @ResourceNames, 3;
                            push @ResourceNames,
                                $LayoutObject->{LanguageObject}->Translate( '+%s more', $ResourceCount - 3 );
                        }

                        $Appointment->{ResourceNames} = join( '\n', @ResourceNames );
                    }
                }

                # include plugin (link) data
                my $PluginList  = $PluginObject->PluginList();
                my %PluginParam = $PluginObject->PluginGetParam(%Param);

                PLUGINKEY:
                for my $PluginKey ( sort keys %{$PluginList} ) {

                    my %Plugin = (
                        %{ $PluginList->{$PluginKey} },
                        PluginKey => $PluginKey,
                        Param     => $PluginParam{$PluginKey},
                    );

                    my $PluginData = $PluginObject->PluginFunction(
                        PluginKey      => $PluginKey,
                        PluginFunction => 'Get',
                        PluginData     => {
                            GetParam    => \%GetParam,
                            Appointment => $Appointment,
                            Plugin      => \%Plugin,
                            UserID      => $Self->{UserID},
                        },
                    );

                    my $PluginGroup = $PluginList->{$PluginKey}->{Block};
                    $PluginData->{PluginGroup} = $PluginGroup;

                    if ( $PluginData->{Value} ) {
                        $Appointment->{PluginData}->{$PluginKey} = $PluginData;
                        $Appointment->{PluginDataGroup}->{$PluginGroup}->{$PluginKey} = $PluginData;
                    }
                }

                # check if dealing with ticket appointment
                if ( $Appointment->{TicketAppointmentRuleID} ) {
                    my $Rule = $CalendarObject->TicketAppointmentRuleGet(
                        CalendarID => $Appointment->{CalendarID},
                        RuleID     => $Appointment->{TicketAppointmentRuleID},
                    );

                    # get types from the ticket appointment rule
                    if ( IsHashRefWithData($Rule) ) {
                        $Appointment->{TicketAppointmentStartDate} = $Rule->{StartDate};
                        $Appointment->{TicketAppointmentEndDate}   = $Rule->{EndDate};
                    }
                }
            }

            # build JSON output
            $JSON = $LayoutObject->JSONEncode(
                Data => (
                    \@Appointments,
                ),
            );
        }
    }

    elsif ( $Self->{Subaction} eq 'AppointmentDays' ) {

        # append midnight to the timestamps
        for my $Timestamp (qw(StartTime EndTime)) {
            if ( $GetParam{$Timestamp} && !( $GetParam{$Timestamp} =~ /\s\d{2}:\d{2}:\d{2}$/ ) ) {
                $GetParam{$Timestamp} = $GetParam{$Timestamp} . ' 00:00:00';
            }
        }

        # reset empty parameters
        for my $Param ( sort keys %GetParam ) {
            if ( !$GetParam{$Param} ) {
                $GetParam{$Param} = undef;
            }
        }

        my %AppointmentDays = $AppointmentObject->AppointmentDays(
            %GetParam,
            UserID => $Self->{UserID},
        );

        # build JSON output
        $JSON = $LayoutObject->JSONEncode(
            Data => (
                \%AppointmentDays,
            ),
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

1;
