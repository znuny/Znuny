# --
# Copyright (C) 2001-2021 OTRS AG, https://otrs.com/
# Copyright (C) 2021 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see https://www.gnu.org/licenses/gpl-3.0.txt.
# --

use strict;
use warnings;
use utf8;

use vars (qw($Self));
use Kernel::System::VariableCheck qw(:all);

# get helper object
$Kernel::OM->ObjectParamAdd(
    'Kernel::System::UnitTest::Helper' => {
        RestoreDatabase => 1,
    },
);
my $HelperObject = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');
my $ConfigObject = $Kernel::OM->Get('Kernel::Config');
my $UserObject   = $Kernel::OM->Get('Kernel::System::User');
my $TicketObject = $Kernel::OM->Get('Kernel::System::Ticket');

my $CalendarEventsObject = $Kernel::OM->Get('Kernel::System::CalendarEvents');
my $ArticleObject        = $Kernel::OM->Get('Kernel::System::Ticket::Article');
my $ArticleBackendObject = $ArticleObject->BackendForChannel( ChannelName => 'Email' );

$Self->{BasicTags} = {
    ProdID       => "PRODID",
    DTStart      => "DTSTART",
    DTEnd        => "DTEND",
    DTStamp      => "DTSTAMP",
    UID          => "UID",
    Attendee     => "ATTENDEE",
    Created      => "CREATED",
    Description  => "DESCRIPTION",
    Summary      => "SUMMARY",
    LastModified => "LAST-MODIFIED",
    Organizer    => "ORGANIZER",
    Attendee     => "ATTENDEE",
    Location     => "LOCATION",
    TZID         => "TZID",
    TZOffsetFrom => "TZOFFSETFROM",
    TZOffsetTo   => "TZOFFSETTO",
    TZName       => "TZNAME",
    TDTStart     => "TDTSTART",
    RRule        => "RRULE",
};

$Self->{AttachmentDataProperties} = {
    Organizer => {
        Default => [
            'organizer1@mail.com'
        ],
    },
    UID => {
        Default => [
            '2AD840A9B960C4A369C1F6040010000000C200E00074C5B7101A82E0080000000090A64A98E413D8010077ACF613F0000080000000000000',
        ],
    },
    Attendee => {
        Default => [
            'attendee1@mail.com',
            'attendee2@mail.com',
        ],
    },
    Description => {

        # google specific description
        Google => [
            'Let\'s test raw symbols:\\n\\n\\n. Now ? (?!)\n\n-
 ::~:~::~:~:~:~:~:~:~:~:~:~:~:~:~:~:~:~:~:~:~:~:~:~:~:~:~:~:~:~:~:~:~:~:~:~:
 ~:~::~:~::-\nDo not edit this section of the description.\n\nView your even
 t at https://calendar.google.com/calendar/event?action=VIEW&eid=Xasddsdgj3F
 hZTBwaTZnaGo4ZDRzbDJiamZkZyBzbGF3bmllZHRlc3R2tyMjE4bDdqaWxybWU5cAbQ&tok=MjM
 jc2xhd25pZW1MjJmNWJmNDA5M2M1OWMR0ZXN0MkBnbWFpbC5jb21hMTNlZmU4MWI5NmIzYmE2N2
 NkMThmODcy&ctz=Europe%2FWarsaw&hl=en&es=1.\n-::~:~::~:~:~:~:~:~:~:~:~:~:~:~
 :~:~:~:~:~:~:~:~:~:~:~:~:~:~:~:~:~:~:~:~:~:~:~:~::~:~::-'
        ],
        Default => [
            'Default description value.',
        ],
    },
    Location => {
        Default => [
            'Default location value.'
        ],
    },
    DTStart => {
        Default => [
            '20220510T100000Z',
        ],
    },
    DTEnd => {
        Default => [
            '20220510T123000Z',
        ],
    },
    DTStamp => {
        Default => [
            '20220209T114135Z',
        ],
    },
    ProdID => {
        Default => [
            'ProdID default value.',
        ],
    },
    Created => {
        Default => [
            '20220209T114050Z',
        ],
    },
    LastModified => {
        Default => [
            '20220209T114133Z'
        ],
    },
    Summary => {
        Default => [
            'Default summary.'
        ],
    },
    TZID => {
        Default => [
            'Europe/Warsaw'
        ],
    },
    TZOffsetFrom => {
        Default => [
            '+0100'
        ],
    },
    TZOffsetTo => {
        Default => [
            '+0200'
        ],
    },
    TZName => {
        Default => [
            'CES'
        ],
    },
    TDTStart => {
        Default => [
            '19700329T020000'
        ],
    },
    RRule => {
        Default => [
            'FREQ=YEARLY;BYDAY=-1SU;BYMONTH=3'
        ],
    },
    TZNAME => {
        Default => [
            'CES'
        ],
    }
};

=head2 OrganizerBuild()

build organizer ics tag string

    my $String = $OrganizerBuild->(
        Property => $Property,
        Value    => $Value
    );

=cut

my $OrganizerBuild = sub {
    my (%Param) = @_;

    if ( $Param{Property} && $Self->{BasicTags}->{ $Param{Property} } ) {

        # basic tag build
        # default value
        if ( !defined( $Param{Value}->[0] ) ) {
            my $DefaultValue = $Self->{AttachmentDataProperties}->{ $Param{Property} }->{Default}->[0];
            return "$Self->{BasicTags}->{$Param{Property}}" .
                ";CN=$DefaultValue" .
                ":mailto:$DefaultValue";
        }

        # specified value
        else {
            my $String = '';
            for my $Value ( @{ $Param{Value} } ) {
                $String .= "$Self->{BasicTags}->{$Param{Property}}" .
                    ";CN=$Value" .
                    ":mailto:$Value\n";
            }
            chomp $String;
            return $String;
        }
    }
};

=head2 AttendeeBuild()

build attendee ics tag string

    my $String = $AttendeeBuild->(
        Property => $Property,
        Value    => $Value
    );

=cut

my $AttendeeBuild = sub {
    my (%Param) = @_;

    if ( $Param{Property} && $Self->{BasicTags}->{ $Param{Property} } ) {
        my $Data;
        my $String = '';

        # basic tag build
        # default value
        if ( !defined( $Param{Value}->[0] ) ) {
            my $DefaultValue = $Self->{AttachmentDataProperties}->{ $Param{Property} }->{Default};
            $Data = $DefaultValue;
        }

        # specified value
        else {
            $Data = $Param{Value};
        }
        for my $Value ( @{$Data} ) {
            $String .= "$Self->{BasicTags}->{$Param{Property}}" .
                ";CUTYPE=INDIVIDUAL;ROLE=REQ-PARTICIPANT;PARTSTAT=NEEDS" .
                "-ACTION;RSVP=TRUE;CN=$Value" .
                ";X-NUM-GUESTS=0:mailto:$Value\n";
        }
        chomp $String;
        return $String;
    }
};

=head2 ICSTagBuild()

builds ICS calendar event tag

    my $String = $ICSTagBuild->(
        Property => $Property,
        Value    => $Value
    );

=cut

my $ICSTagBuild = sub {
    my (%Param) = @_;

    if ( $Param{Property} && $Self->{BasicTags}->{ $Param{Property} } ) {
        if ( $Param{Property} eq 'Organizer' ) {
            return $OrganizerBuild->(%Param);
        }

        if ( $Param{Property} eq 'Attendee' ) {
            return $AttendeeBuild->(%Param);
        }

        # basic tag build
        # default value
        if ( !defined( $Param{Value}->[0] ) ) {
            return "$Self->{BasicTags}->{$Param{Property}}" .
                ":$Self->{AttachmentDataProperties}->{$Param{Property}}->{Default}->[0]";
        }

        # specified value
        else {
            return "$Self->{BasicTags}->{$Param{Property}}" .
                ":$Param{Value}->[0]";
        }
    }
};

=head2 BasicInvite()

build basic ICS invite content

    my $Content = $BasicInvite->(
        ProdID       => $ProdID,
        DTStart      => $DTStart,
        DTEnd        => $DTEnd,
        DTStamp      => $DTStamp,
        UID          => $UID,
        Created      => $Created,
        Description  => $Description,
        Summary      => $Summary,
        LastModified => $LastModified,
        Organizer    => $Organizer,
        Attendee     => $Attendee,
        TZID         => $TZID,
        TZOffsetFrom => $TZOffsetFrom,
        TZOffsetTo   => $TZOffsetTo,
        TZName       => $TZName,
        TDTStart     => $TDTStart,
        RRule        => $RRule,
        Location     => $Location,
    );

=cut

my $BasicInvite = sub {
    my (%Param) = @_;

    my %Properties;

    # build properties as a valid tag
    for my $Property ( sort keys %{ $Self->{BasicTags} } ) {
        $Properties{$Property} = $ICSTagBuild->(
            Property => $Property,
            Value    => $Param{$Property},
        );
    }

    return
        "BEGIN:VCALENDAR
$Properties{ProdID}
VERSION:2.0
CALSCALE:GREGORIAN
METHOD:REQUEST
BEGIN:VTIMEZONE
$Properties{TZID}
BEGIN:DAYLIGHT
$Properties{TZOffsetFrom}
$Properties{TZOffsetTo}
$Properties{TZName}
$Properties{TDTStart}
$Properties{RRule}
END:DAYLIGHT
END:VTIMEZONE
BEGIN:VEVENT
$Properties{DTStart}
$Properties{DTEnd}
$Properties{DTStamp}
$Properties{Organizer}
$Properties{UID}
$Properties{Attendee}
$Properties{Created}
$Properties{Description}
$Properties{LastModified}
$Properties{Location}
SEQUENCE:1
STATUS:CONFIRMED
$Properties{Summary}
TRANSP:OPAQUE
END:VEVENT
END:VCALENDAR";
};

my $AdditionalInvites->{PropertiesToEncode} = $BasicInvite->(
    Attendee    => [ 'André Bernard', 'Bartholomé Moreau' ],
    Description => [
        "Je m’appelle Césaire. J'utilise le système OTRS qui est très bon. Je vous invite à une réunion où nous programmerons ensemble."
    ],
    Summary   => ["Pour résumer."],
    Organizer => ['Césaire Simon'],
    Location  => ['Angoulême']
);

$AdditionalInvites->{EmptyProperties} = $BasicInvite->(
    Attendee    => [''],
    Description => [''],
    Summary     => [''],
    Organizer   => [''],
    Location    => ['']
);

$AdditionalInvites->{BasicInvite} = $BasicInvite->();

my $Organizer   = $Self->{AttachmentDataProperties}->{Organizer};
my $UID         = $Self->{AttachmentDataProperties}->{UID};
my $Attendee    = $Self->{AttachmentDataProperties}->{Attendee};
my $Location    = $Self->{AttachmentDataProperties}->{Location};
my $Description = $Self->{AttachmentDataProperties}->{Description};
my $Summary     = $Self->{AttachmentDataProperties}->{Summary};

my $AttachmentsData = [
    {
        Name        => 'Basic invite',
        Filename    => 'invite0.ics',
        Content     => $AdditionalInvites->{BasicInvite},
        ContentType => 'text/calendar;',
        ExpectedResult =>
            {
            'Data' => {
                'Calendars' => [
                    {
                        'Index'    => 1,
                        'Name'     => 'Calendar 1',
                        'ProdID'   => 'ProdID default value.',
                        'Timezone' => 'Europe/Warsaw'
                    }
                ],
                'Events' => [
                    {
                        'Attendee' => [
                            'attendee1@mail.com',
                            'attendee2@mail.com'
                        ],
                        'Dates' => [
                            {
                                'End' => {
                                    'Day'    => 10,
                                    'Hour'   => 12,
                                    'Minute' => 30,
                                    'Month'  => 5,
                                    'Second' => 0,
                                    'Year'   => 2022
                                },
                                'Start' => {
                                    'Day'    => 10,
                                    'Hour'   => 10,
                                    'Minute' => 0,
                                    'Month'  => 5,
                                    'Second' => 0,
                                    'Year'   => 2022
                                }
                            }
                        ],
                        'Description' => 'Default description value.',
                        'Details'     => {
                            'AllDay'    => undef,
                            'Frequency' => 'Daily',
                            'Type'      => 'Span'
                        },
                        'Location'         => 'Default location value.',
                        'Organizer'        => 'organizer1@mail.com',
                        'OriginalTimeZone' => 'Europe/Warsaw',
                        'Summary'          => 'Default summary.',
                        'TimeZone'         => 'UTC',
                        'UID' =>
                            '2AD840A9B960C4A369C1F6040010000000C200E00074C5B7101A82E0080000000090A64A98E413D8010077ACF613F0000080000000000000'
                    }
                ]
            },
            'Index' => '1'
            },
    },
    {
        Name     => 'Google invite',
        Filename => 'invite1.ics',
        Content  => "BEGIN:VCALENDAR
PRODID:-//Google Inc//Google Calendar 70.9054//EN
VERSION:2.0
CALSCALE:GREGORIAN
METHOD:REQUEST
BEGIN:VEVENT
DTSTART:20220726T160000Z
DTEND:20220726T163000Z
DTSTAMP:20220722T094347Z
ORGANIZER;CN=$Organizer->{Default}->[0]:mailto:$Organizer->{Default}->[0]
UID:$UID->{Default}->[0]\@google.com
ATTENDEE;CUTYPE=INDIVIDUAL;ROLE=REQ-PARTICIPANT;PARTSTAT=NEEDS-ACTION;RSVP=
 TRUE;CN=$Attendee->{Default}->[0];X-NUM-GUESTS=0:mailto:$Attendee->{Default}->[0]
ATTENDEE;CUTYPE=INDIVIDUAL;ROLE=REQ-PARTICIPANT;PARTSTAT=ACCEPTED;RSVP=TRUE
 ;CN=$Attendee->{Default}->[1];X-NUM-GUESTS=0:mailto:$Attendee->{Default}->[1]
X-GOOGLE-CONFERENCE:https://meet.google.com/meet-code
X-MICROSOFT-CDO-OWNERAPPTID:-9999999999
CREATED:20220722T094346Z
DESCRIPTION:$Description->{Google}->[0]
LAST-MODIFIED:20220722T094346Z
LOCATION: $Location->{Default}->[0]
SEQUENCE:0
STATUS:CONFIRMED
SUMMARY: $Summary->{Default}->[0]
TRANSP:OPAQUE
END:VEVENT
END:VCALENDAR
",
        ContentType    => 'text/calendar;',
        ExpectedResult => {
            'Index' => '2',
            'Data'  => {
                'Events' => [
                    {
                        'Attendee' => [ 'attendee1@mail.com', 'attendee2@mail.com' ],
                        'TimeZone' => 'UTC',
                        'UID' =>
                            '2AD840A9B960C4A369C1F6040010000000C200E00074C5B7101A82E0080000000090A64A98E413D8010077ACF613F0000080000000000000@google.com',
                        'Summary'   => ' Default summary.',
                        'Organizer' => 'organizer1@mail.com',
                        'Details'   => {
                            'Frequency' => 'Daily',
                            'Type'      => 'Span',
                            'AllDay'    => undef
                        },
                        'OriginalTimeZone' => 'Europe/Warsaw',
                        'Dates'            => [
                            {
                                'End' => {
                                    'Year'   => 2022,
                                    'Hour'   => 16,
                                    'Month'  => 7,
                                    'Day'    => 26,
                                    'Second' => 0,
                                    'Minute' => 30
                                },
                                'Start' => {
                                    'Year'   => 2022,
                                    'Hour'   => 16,
                                    'Month'  => 7,
                                    'Day'    => 26,
                                    'Second' => 0,
                                    'Minute' => 0
                                }
                            }
                        ],
                        'Location'    => ' Default location value.',
                        'Description' => 'Let\'s test raw symbols:


. Now ? (?!)

'
                    }
                ],
                'Calendars' => [
                    {
                        'Timezone' => 'Europe/Warsaw',
                        'Index'    => 1,
                        'ProdID'   => '-//Google Inc//Google Calendar 70.9054//EN',
                        'Name'     => 'Calendar 1'
                    }
                ]
            }
        },
    },
    {
        Name     => 'Microsoft invite',
        Filename => 'invite2.ics',
        Content  => "BEGIN:VCALENDAR
PRODID:-//Microsoft Corporation//Outlook 16.0 MIMEDIR//EN
VERSION:2.0
METHOD:REQUEST
X-MS-OLK-FORCEINSPECTOROPEN:TRUE
BEGIN:VTIMEZONE
TZID:Pacific Standard Time
BEGIN:STANDARD
DTSTART:16011104T020000
RRULE:FREQ=YEARLY;BYDAY=1SU;BYMONTH=11
TZOFFSETFROM:-0700
TZOFFSETTO:-0800
END:STANDARD
BEGIN:DAYLIGHT
DTSTART:16010311T020000
RRULE:FREQ=YEARLY;BYDAY=2SU;BYMONTH=3
TZOFFSETFROM:-0800
TZOFFSETTO:-0700
END:DAYLIGHT
END:VTIMEZONE
BEGIN:VEVENT
ATTENDEE;CN=$Attendee->{Default}->[0];RSVP=TRUE:mailto:$Attendee->{Default}->[0]
ATTENDEE;CN=$Attendee->{Default}->[1];ROLE=OPT-PARTICIPANT;RSVP=TRUE:mailto:$Attendee->{Default}->[1]
CLASS:PUBLIC
CREATED:20220131T105203Z
DESCRIPTION: $Description->{Default}->[0]
DTEND;TZID=\"Pacific Standard Time\":20220202T113000
DTSTAMP:20220131T105203Z
DTSTART;TZID=\"Pacific Standard Time\":20220202T110000
LAST-MODIFIED:20220131T105203Z
LOCATION:$Location->{Default}->[0]
ORGANIZER;CN=$Organizer->{Default}->[0]:mailto:$Organizer->{Default}->[0]
PRIORITY:9
SEQUENCE:3
SUMMARY;LANGUAGE=en-us:$Summary->{Default}->[0]
TRANSP:OPAQUE
UID:$UID->{Default}->[0]" . '
X-ALT-DESC;FMTTYPE=text/html:<html xmlns:v="urn:schemas-microsoft-com:vml"
    xmlns:o="urn:schemas-microsoft-com:office:office" xmlns:w="urn:schemas-mic
    rosoft-com:office:word" xmlns:m="http://schemas.microsoft.com/office/2004/
    12/omml" xmlns="http://www.w3.org/TR/REC-html40"><head><meta http-equiv=Co
    ntent-Type content="text/html\; charset=us-ascii"><meta name=Generator con
    tent="Microsoft Word 15 (filtered medium)"><style><!--\n/* Font Definition
    s */\n@font-face\n  {font-family:"Cambria Math"\;\n panose-1:2 4 5 3 5 4 6
    3 2 4\;}\n@font-face\n  {font-family:Calibri\;\n    panose-1:2 15 5 2 2 2 4 3
    2 4\;}\n/* Style Definitions */\np.MsoNormal\, li.MsoNormal\, div.MsoNorma
    l\n {margin:0in\;\n font-size:11.0pt\;\n    font-family:"Calibri"\,sans-serif
    \;}\nspan.Stylwiadomocie-mail18\n   {mso-style-type:personal-compose\;\n    fon
    t-family:"Calibri"\,sans-serif\;\n  color:windowtext\;}\n.MsoChpDefault\n   {
    mso-style-type:export-only\;\n  font-size:10.0pt\;}\n@page WordSection1\n   {
    size:8.5in 11.0in\;\n   margin:1.0in 1.0in 1.0in 1.0in\;}\ndiv.WordSection1\
    n   {page:WordSection1\;}\n--></style><!--[if gte mso 9]><xml>\n<o:shapedefa
    ults v:ext="edit" spidmax="1026" />\n</xml><![endif]--><!--[if gte mso 9]>
    <xml>\n<o:shapelayout v:ext="edit">\n<o:idmap v:ext="edit" data="1" />\n</
    o:shapelayout></xml><![endif]--></head><body lang=EN-US link="#0563C1" vli
    nk="#954F72" style=\'word-wrap:break-word\'><div class=WordSection1><p class
    =MsoNormal><o:p>&nbsp\;</o:p></p></div></body></html> ' .
            "X-MICROSOFT-CDO-BUSYSTATUS:TENTATIVE
X-MICROSOFT-CDO-IMPORTANCE:0
X-MICROSOFT-CDO-INTENDEDSTATUS:BUSY
X-MICROSOFT-DISALLOW-COUNTER:FALSE
X-MS-OLK-APPTLASTSEQUENCE:2
X-MS-OLK-APPTSEQTIME:20220131T104458Z
X-MS-OLK-AUTOSTARTCHECK:FALSE
X-MS-OLK-CONFTYPE:0
BEGIN:VALARM
TRIGGER:-PT15M
ACTION:DISPLAY
DESCRIPTION:Reminder
END:VALARM
END:VEVENT
END:VCALENDAR
",
        ContentType => 'application/hbs-vcs;',

        ExpectedResult =>
            {
            'Data' => {
                'Calendars' => [
                    {
                        'Index' => 1,
                        'Name'  => 'Calendar 1',
                        'ProdID' =>
                            '-//Microsoft Corporation//Outlook 16.0 MIMEDIR//EN',
                        'Timezone' => 'America/Los_Angeles'
                    }
                ],
                'Events' => [
                    {
                        'Attendee' => [ 'attendee1@mail.com', 'attendee2@mail.com' ],
                        'Dates'    => [
                            {
                                'End' => {
                                    'Day'    => 2,
                                    'Hour'   => 19,
                                    'Minute' => 30,
                                    'Month'  => 2,
                                    'Second' => 0,
                                    'Year'   => 2022
                                },
                                'Start' => {
                                    'Day'    => 2,
                                    'Hour'   => 19,
                                    'Minute' => 0,
                                    'Month'  => 2,
                                    'Second' => 0,
                                    'Year'   => 2022
                                }
                            }
                        ],
                        'Description' => ' Default description value.',
                        'Details'     => {
                            'AllDay'    => undef,
                            'Frequency' => 'Daily',
                            'Type'      => 'Span'
                        },
                        'Location'         => 'Default location value.',
                        'Organizer'        => 'organizer1@mail.com',
                        'OriginalTimeZone' => 'America/Los_Angeles',
                        'Summary'          => 'Default summary.',
                        'TimeZone'         => 'UTC',
                        'UID' =>
                            '2AD840A9B960C4A369C1F6040010000000C200E00074C5B7101A82E0080000000090A64A98E413D8010077ACF613F0000080000000000000'
                    }
                ]
            },
            'Index' => '3'
            },
    },
    {
        Name     => 'Thunderbird invite',
        Filename => 'invite3.ics',
        Content  => "
BEGIN:VCALENDAR
PRODID:-//Mozilla.org/NONSGML Mozilla Calendar V1.1//EN
VERSION:2.0
METHOD:REQUEST
BEGIN:VTIMEZONE
TZID:Europe/Warsaw
BEGIN:DAYLIGHT
TZOFFSETFROM:+0100
TZOFFSETTO:+0200
TZNAME:CEST
DTSTART:19700329T020000
RRULE:FREQ=YEARLY;BYDAY=-1SU;BYMONTH=3
END:DAYLIGHT
BEGIN:STANDARD
TZOFFSETFROM:+0200
TZOFFSETTO:+0100
TZNAME:CET
DTSTART:19701025T030000
RRULE:FREQ=YEARLY;BYDAY=-1SU;BYMONTH=10
END:STANDARD
END:VTIMEZONE
BEGIN:VEVENT
CREATED:20220209T115543Z
LAST-MODIFIED:20220209T115627Z
DTSTAMP:20220209T115627Z
UID:5ad4aa23-4z81-468f-96f6-5a4ff3bv2376
SUMMARY:$Summary->{Default}->[0]
ORGANIZER;PARTSTAT=NEEDS-ACTION;ROLE=REQ-PARTICIPANT:mailto:$Organizer->{Default}->[0]
ATTENDEE;CN=Znuny System - test;PARTSTAT=NEEDS-ACTION;ROLE=REQ-PARTI
 CIPANT:mailto:$Attendee->{Default}->[0]
DTSTART;TZID=Europe/Warsaw:20220517T130000
DTEND;TZID=Europe/Warsaw:20220517T140000
TRANSP:OPAQUE
LOCATION:$Location->{Default}->[0]
END:VEVENT
END:VCALENDAR
        ",
        ContentType => 'application/vnd.swiftview-ics;',
        ExpectedResult =>
            {
            'Data' => {
                'Calendars' => [
                    {
                        'Index'    => 1,
                        'Name'     => 'Calendar 1',
                        'ProdID'   => '-//Mozilla.org/NONSGML Mozilla Calendar V1.1//EN',
                        'Timezone' => 'Europe/Warsaw'
                    }
                ],
                'Events' => [
                    {
                        'Attendee' => [
                            'Znuny System - test'
                        ],
                        'Dates' => [
                            {
                                'End' => {
                                    'Day'    => 17,
                                    'Hour'   => 12,
                                    'Minute' => 0,
                                    'Month'  => 5,
                                    'Second' => 0,
                                    'Year'   => 2022
                                },
                                'Start' => {
                                    'Day'    => 17,
                                    'Hour'   => 11,
                                    'Minute' => 0,
                                    'Month'  => 5,
                                    'Second' => 0,
                                    'Year'   => 2022
                                }
                            }
                        ],
                        'Description' => undef,
                        'Details'     => {
                            'AllDay'    => undef,
                            'Frequency' => 'Daily',
                            'Type'      => 'Span'
                        },
                        'Location'         => 'Default location value.',
                        'OriginalTimeZone' => 'Europe/Warsaw',
                        'Summary'          => 'Default summary.',
                        'TimeZone'         => 'UTC',
                        'UID'              => '5ad4aa23-4z81-468f-96f6-5a4ff3bv2376'
                    }
                ]
            },
            'Index' => '4'
            },
    },
    {
        Name        => 'Basic invite with properties to encode',
        Filename    => 'invite4.ics',
        Content     => $AdditionalInvites->{PropertiesToEncode},
        ContentType => 'application/vnd.swiftview-ics;',
        ExpectedResult =>
            {
            'Data' => {
                'Calendars' => [
                    {
                        'Index'    => 1,
                        'Name'     => 'Calendar 1',
                        'ProdID'   => 'ProdID default value.',
                        'Timezone' => 'Europe/Warsaw'
                    }
                ],
                'Events' => [
                    {
                        'Attendee' => [ 'André Bernard', 'Bartholomé Moreau' ],
                        'Dates'    => [
                            {
                                'End' => {
                                    'Day'    => 10,
                                    'Hour'   => 12,
                                    'Minute' => 30,
                                    'Month'  => 5,
                                    'Second' => 0,
                                    'Year'   => 2022
                                },
                                'Start' => {
                                    'Day'    => 10,
                                    'Hour'   => 10,
                                    'Minute' => 0,
                                    'Month'  => 5,
                                    'Second' => 0,
                                    'Year'   => 2022
                                }
                            }
                        ],
                        'Description' =>
                            'Je m’appelle Césaire. J\'utilise le système OTRS qui est très bon. Je vous invite à une réunion où nous programmerons ensemble.',
                        'Details' => {
                            'AllDay'    => undef,
                            'Frequency' => 'Daily',
                            'Type'      => 'Span'
                        },
                        'Location'         => 'Angoulême',
                        'Organizer'        => 'Césaire Simon',
                        'OriginalTimeZone' => 'Europe/Warsaw',
                        'Summary'          => 'Pour résumer.',
                        'TimeZone'         => 'UTC',
                        'UID' =>
                            '2AD840A9B960C4A369C1F6040010000000C200E00074C5B7101A82E0080000000090A64A98E413D8010077ACF613F0000080000000000000'
                    }
                ]
            },
            'Index' => '5'
            },
    },
    {
        Name        => 'Basic invite with some empty properties',
        Filename    => 'invite5.ics',
        Content     => $AdditionalInvites->{EmptyProperties},
        ContentType => 'text/x-vcalendar;',
        ExpectedResult =>
            {
            'Data' => {
                'Calendars' => [
                    {
                        'Index'    => 1,
                        'Name'     => 'Calendar 1',
                        'ProdID'   => 'ProdID default value.',
                        'Timezone' => 'Europe/Warsaw'
                    }
                ],
                'Events' => [
                    {
                        'Attendee' => [''],
                        'Dates'    => [
                            {
                                'End' => {
                                    'Day'    => 10,
                                    'Hour'   => 12,
                                    'Minute' => 30,
                                    'Month'  => 5,
                                    'Second' => 0,
                                    'Year'   => 2022
                                },
                                'Start' => {
                                    'Day'    => 10,
                                    'Hour'   => 10,
                                    'Minute' => 0,
                                    'Month'  => 5,
                                    'Second' => 0,
                                    'Year'   => 2022
                                }
                            }
                        ],
                        'Description' => '',
                        'Details'     => {
                            'AllDay'    => undef,
                            'Frequency' => 'Daily',
                            'Type'      => 'Span'
                        },
                        'Location'         => '',
                        'OriginalTimeZone' => 'Europe/Warsaw',
                        'Summary'          => '',
                        'TimeZone'         => 'UTC',
                        'UID' =>
                            '2AD840A9B960C4A369C1F6040010000000C200E00074C5B7101A82E0080000000090A64A98E413D8010077ACF613F0000080000000000000'
                    }
                ]
            },
            'Index' => '6'
            },
    },
    {
        Name           => 'No invite inside content',
        Filename       => 'invite6.ics',
        Content        => 'Not invite related content.',
        ContentType    => 'text/x-vcalendar;',
        ExpectedResult => undef,
    },
    {
        Name           => 'Invite with invalid content type',
        Filename       => 'invite7.ics',
        Content        => $AdditionalInvites->{BasicInvite},
        ContentType    => 'text/html;',
        ExpectedResult => undef,
    },

];

$AdditionalInvites->{InviteWithUnrelatedContent} = $BasicInvite->();
$AdditionalInvites->{InviteWithUnrelatedContent} = "Hello! You have an invitation to the meeting.\n"
    . $AdditionalInvites->{InviteWithUnrelatedContent};

$AdditionalInvites->{InviteWithNoTimezone} = $BasicInvite->(
    TZID => [''],
);

my $StringData = [
    {
        Name        => 'Basic invite as string param',
        Filename    => 'invite8.ics',
        Content     => $AdditionalInvites->{BasicInvite},
        ContentType => 'text/x-vcalendar;',
        ExpectedResult =>
            {
            'String' => [
                {
                    'Data' => {
                        'Calendars' => [
                            {
                                'Index'    => 1,
                                'Name'     => 'Calendar 1',
                                'ProdID'   => 'ProdID default value.',
                                'Timezone' => 'Europe/Warsaw'
                            }
                        ],
                        'Events' => [
                            {
                                'Attendee' =>
                                    [ 'attendee1@mail.com', 'attendee2@mail.com' ],
                                'Dates' => [
                                    {
                                        'End' => {
                                            'Day'    => 10,
                                            'Hour'   => 12,
                                            'Minute' => 30,
                                            'Month'  => 5,
                                            'Second' => 0,
                                            'Year'   => 2022
                                        },
                                        'Start' => {
                                            'Day'    => 10,
                                            'Hour'   => 10,
                                            'Minute' => 0,
                                            'Month'  => 5,
                                            'Second' => 0,
                                            'Year'   => 2022
                                        }
                                    }
                                ],
                                'Description' => 'Default description value.',
                                'Details'     => {
                                    'AllDay'    => undef,
                                    'Frequency' => 'Daily',
                                    'Type'      => 'Span'
                                },
                                'Location'         => 'Default location value.',
                                'Organizer'        => 'organizer1@mail.com',
                                'OriginalTimeZone' => 'Europe/Warsaw',
                                'Summary'          => 'Default summary.',
                                'TimeZone'         => 'UTC',
                                'UID' =>
                                    '2AD840A9B960C4A369C1F6040010000000C200E00074C5B7101A82E0080000000090A64A98E413D8010077ACF613F0000080000000000000'
                            }
                        ]
                    },
                    'Index' => 0
                }
            ]
            },
    },
    {
        Name        => 'Invite with unrelated content',
        Filename    => 'invite9.ics',
        Content     => $AdditionalInvites->{InviteWithUnrelatedContent},
        ContentType => 'text/x-vcalendar;',
        ExpectedResult =>
            {
            'String' => [
                {
                    'Data' => {
                        'Calendars' => [
                            {
                                'Index'    => 1,
                                'Name'     => 'Calendar 1',
                                'ProdID'   => 'ProdID default value.',
                                'Timezone' => 'Europe/Warsaw'
                            }
                        ],
                        'Events' => [
                            {
                                'Attendee' =>
                                    [ 'attendee1@mail.com', 'attendee2@mail.com' ],
                                'Dates' => [
                                    {
                                        'End' => {
                                            'Day'    => 10,
                                            'Hour'   => 12,
                                            'Minute' => 30,
                                            'Month'  => 5,
                                            'Second' => 0,
                                            'Year'   => 2022
                                        },
                                        'Start' => {
                                            'Day'    => 10,
                                            'Hour'   => 10,
                                            'Minute' => 0,
                                            'Month'  => 5,
                                            'Second' => 0,
                                            'Year'   => 2022
                                        }
                                    }
                                ],
                                'Description' => 'Default description value.',
                                'Details'     => {
                                    'AllDay'    => undef,
                                    'Frequency' => 'Daily',
                                    'Type'      => 'Span'
                                },
                                'Location'         => 'Default location value.',
                                'Organizer'        => 'organizer1@mail.com',
                                'OriginalTimeZone' => 'Europe/Warsaw',
                                'Summary'          => 'Default summary.',
                                'TimeZone'         => 'UTC',
                                'UID' =>
                                    '2AD840A9B960C4A369C1F6040010000000C200E00074C5B7101A82E0080000000090A64A98E413D8010077ACF613F0000080000000000000'
                            }
                        ]
                    },
                    'Index' => 0
                }
            ]
            },
    },
    {
        Name           => 'Invite with no timezone',
        Filename       => 'invite10.ics',
        Content        => $AdditionalInvites->{InviteWithNoTimezone},
        ContentType    => 'text/x-vcalendar;',
        ExpectedResult => {},
    },
];

# for multi param testing, that is: Attachments and String in one Parse() function call
my $AttachmentsWithStringInvite = {
    Name       => 'Multi param parse',
    Attachment => {
        Count => 0,
    },
    String => {
        Filename    => 'invite11.ics',
        Content     => $AdditionalInvites->{BasicInvite},
        ContentType => 'text/x-vcalendar;',
    },
    ExpectedResult => {
        'Attachments' => [ $AttachmentsData->[0]->{ExpectedResult} ],
        'String'      => [
            {
                'Data' => {
                    'Calendars' => [
                        {
                            'Index'    => 1,
                            'Name'     => 'Calendar 1',
                            'ProdID'   => 'ProdID default value.',
                            'Timezone' => 'Europe/Warsaw'
                        }
                    ],
                    'Events' => [
                        {
                            'Attendee' => [
                                'attendee1@mail.com',
                                'attendee2@mail.com'
                            ],
                            'Dates' => [
                                {
                                    'End' => {
                                        'Day'    => 10,
                                        'Hour'   => 12,
                                        'Minute' => 30,
                                        'Month'  => 5,
                                        'Second' => 0,
                                        'Year'   => 2022
                                    },
                                    'Start' => {
                                        'Day'    => 10,
                                        'Hour'   => 10,
                                        'Minute' => 0,
                                        'Month'  => 5,
                                        'Second' => 0,
                                        'Year'   => 2022
                                    }
                                }
                            ],
                            'Description' => 'Default description value.',
                            'Details'     => {
                                'AllDay'    => undef,
                                'Frequency' => 'Daily',
                                'Type'      => 'Span'
                            },
                            'Location'         => 'Default location value.',
                            'Organizer'        => 'organizer1@mail.com',
                            'OriginalTimeZone' => 'Europe/Warsaw',
                            'Summary'          => 'Default summary.',
                            'TimeZone'         => 'UTC',
                            'UID' =>
                                '2AD840A9B960C4A369C1F6040010000000C200E00074C5B7101A82E0080000000090A64A98E413D8010077ACF613F0000080000000000000'
                        }
                    ]
                },
                'Index' => 0
            }
        ]
    },
};

# load ArticleStorageFS
my $Backend = 'ArticleStorageFS';

$ConfigObject->Set(
    Key   => 'Ticket::Article::Backend::MIMEBase::ArticleStorage',
    Value => "Kernel::System::Ticket::Article::Backend::MIMEBase::$Backend",
);

$Kernel::OM->ObjectsDiscard(
    Objects => ['Kernel::System::Ticket::Article'],
);

$ArticleObject        = $Kernel::OM->Get('Kernel::System::Ticket::Article');
$ArticleBackendObject = $ArticleObject->BackendForChannel( ChannelName => 'Email' );

$Self->Is(
    $ArticleBackendObject->{ArticleStorageModule},
    "Kernel::System::Ticket::Article::Backend::MIMEBase::$Backend",
    'Article backend loaded the correct storage module'
);

# create ticket
my $TicketID = $TicketObject->TicketCreate(
    Title        => 'Some Ticket_Title',
    Queue        => 'Raw',
    Lock         => 'unlock',
    Priority     => '3 normal',
    State        => 'open',
    CustomerNo   => '123465',
    CustomerUser => 'unittest@otrs.com',
    OwnerID      => 1,
    UserID       => 1,
);

$Self->True(
    $TicketID,
    'TicketCreate()',
);

# create article
my $ArticleID = $ArticleBackendObject->ArticleCreate(
    TicketID             => $TicketID,
    SenderType           => 'agent',
    IsVisibleForCustomer => 0,
    From                 => 'Some Agent <email@example.com>',
    To                   => 'Some Customer <customer-a@example.com>',
    Subject              => 'some short description',
    Body                 => 'the message text',
    ContentType          => 'text/plain; charset=ISO-8859-15',
    HistoryType          => 'OwnerUpdate',
    HistoryComment       => 'Some free text!',
    UserID               => 1,
    NoAgentNotify        => 1,
);

$Self->True(
    $ArticleID,
    "ArticleBackendObject ArticleCreate()",
);

my @AttachmentsToIgnore;
my $AttachmentCounter = 0;

# write attachments into article
for my $Data ( @{$AttachmentsData} ) {
    my $ArticleWriteAttachment = $ArticleBackendObject->ArticleWriteAttachment(
        ArticleID   => $ArticleID,
        Filename    => $Data->{Filename},
        ContentType => $Data->{ContentType},
        ContentID   => 'testing123@example.com',
        Content     => $Data->{Content},
        UserID      => 1,
    );

    $Self->True(
        $ArticleWriteAttachment,
        "$Backend ArticleWriteAttachment()",
    );

    if ( $AttachmentCounter == $AttachmentsWithStringInvite->{Attachment}->{Count} ) {

        # get attachment index
        my %AtmIndex = $ArticleBackendObject->ArticleAttachmentIndex(
            ArticleID => $ArticleID,
        );

        my $CalendarEventsData = $CalendarEventsObject->Parse(
            TicketID    => $TicketID,
            ArticleID   => $ArticleID,
            Attachments => {
                Type => 'Article',
                Data => \%AtmIndex,
            },
            String     => $AttachmentsWithStringInvite->{String}->{Content},
            ToTimeZone => "UTC",
        );

        $Self->IsDeeply(
            $CalendarEventsData,
            $AttachmentsWithStringInvite->{ExpectedResult},
            "Parsed data check - attachment with string ($AttachmentsWithStringInvite->{Name})",
        );
    }

    # save that article was not written
    if ( !$ArticleWriteAttachment ) {
        push @AttachmentsToIgnore, $AttachmentCounter;
    }

    $AttachmentCounter++;
}

# get attachment index
my %AtmIndex = $ArticleBackendObject->ArticleAttachmentIndex(
    ArticleID => $ArticleID,
);

my $AttachmentCount = keys %AtmIndex;

$Self->Is(
    $AttachmentCount,
    $AttachmentCounter,
    'ArticleCount',
);

my $CalendarEventsData = $CalendarEventsObject->Parse(
    TicketID    => $TicketID,
    ArticleID   => $ArticleID,
    Attachments => {
        Type => 'Article',
        Data => \%AtmIndex,
    },
    ToTimeZone => "UTC",
);

my $ParserDataExists = IsArrayRefWithData( $CalendarEventsData->{Attachments} );

$Self->True(
    $ParserDataExists,
    'Any parsed data exists',
);

my $Index = 1;
ATTACHMENT:
for my $Attachment ( @{$AttachmentsData} ) {

    # do not test attachments that wasn't added
    if ( grep { $_ eq $Index } @AttachmentsToIgnore ) {
        next ATTACHMENT;
    }

    # data here is unique so there should be one object inside an array
    my @ParsedData = grep { $_->{Index} && $_->{Index} eq $Index } @{ $CalendarEventsData->{Attachments} };

    # some calendar events that not passed through parser will return 0
    # still check them for undef value on next test
    $Self->True(
        scalar @ParsedData == 1 || scalar @ParsedData == 0,
        'Unique index check',
    );

    $Self->IsDeeply(
        $ParsedData[0],
        $Attachment->{ExpectedResult},
        "Parsed data check - attachment ($Attachment->{Name})",
    );

    $Index++;
}

STRING:
for my $String ( @{$StringData} ) {
    my $StringCalendarEventsData = $CalendarEventsObject->Parse(
        String     => $String->{Content},
        ToTimeZone => "UTC",
    );

    $Self->IsDeeply(
        $StringCalendarEventsData,
        $String->{ExpectedResult},
        "Parsed data check - string ($String->{Name})",
    );
}

1;
