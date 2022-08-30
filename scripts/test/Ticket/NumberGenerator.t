# --
# Copyright (C) 2001-2021 OTRS AG, https://otrs.com/
# Copyright (C) 2021-2022 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see https://www.gnu.org/licenses/gpl-3.0.txt.
# --

use strict;
use warnings;
use utf8;

use vars (qw($Self));

# get needed object
my $ConfigObject = $Kernel::OM->Get('Kernel::Config');

# check all number generators
for my $Backend (qw(AutoIncrement Date DateChecksum)) {

    # check subject formats
    for my $TicketSubjectFormat (qw(Left Right)) {

        # Make sure that the TicketObject gets recreated for each loop.
        $Kernel::OM->ObjectsDiscard( Objects => ['Kernel::System::Ticket'] );

        $ConfigObject->Set(
            Key   => 'Ticket::NumberGenerator',
            Value => 'Kernel::System::Ticket::Number::' . $Backend,
        );
        $ConfigObject->Set(
            Key   => 'Ticket::SubjectFormat',
            Value => $TicketSubjectFormat,
        );

        my $TicketObject = $Kernel::OM->Get('Kernel::System::Ticket');

        for my $TicketHook ( 'Ticket#', 'Tickétø#', 'Reg$Ex*Special+Chars' ) {

            $ConfigObject->Set(
                Key   => 'Ticket::Hook',
                Value => $TicketHook,
            );

            for my $Count ( 1 .. 5 ) {

                # Produce a ticket number for a foreign system
                $ConfigObject->Set(
                    Key   => 'SystemID',
                    Value => '01',
                );

                my $ForeignTicketNumber = $TicketObject->TicketCreateNumber();

                $Self->True(
                    scalar $ForeignTicketNumber,
                    "$Backend - $TicketSubjectFormat - $Count - TicketCreateNumber() - result $ForeignTicketNumber",
                );

                # Now Produce a ticket number for our local system
                $ConfigObject->Set(
                    Key   => 'SystemID',
                    Value => '10',
                );
                my $TicketNumber = $TicketObject->TicketCreateNumber();

                $Self->True(
                    scalar $TicketNumber,
                    "$Backend - $TicketSubjectFormat - $Count - TicketCreateNumber() - result $TicketNumber",
                );

                #
                # Simple test: find ticket number in subject
                #
                my $Subject = $TicketObject->TicketSubjectBuild(
                    TicketNumber => $TicketNumber,
                    Subject      => 'Test',
                );

                $Self->True(
                    scalar $Subject,
                    "$Backend - $TicketSubjectFormat - $Count - TicketSubjectBuild() - result $Subject",
                );

                my $CleanSubject = $TicketObject->TicketSubjectClean(
                    TicketNumber => $TicketNumber,
                    Subject      => $Subject,
                );

                $Self->Is(
                    $CleanSubject,
                    'Test',
                    "$Backend - $TicketSubjectFormat - $Count - TicketSubjectClean() - result $CleanSubject",
                );

                #
                # Subject with spaces around ticket number
                #
                my $SubjectWithSpaces = $Subject;
                $SubjectWithSpaces =~ s{\[(.*)\]}{[ $1 ]};

                my $CleanSubjectFromSpaces = $TicketObject->TicketSubjectClean(
                    TicketNumber => $TicketNumber,
                    Subject      => $SubjectWithSpaces,
                );

                $Self->Is(
                    $CleanSubjectFromSpaces,
                    'Test',
                    "$Backend - $TicketSubjectFormat - $Count - TicketSubjectClean() - result $CleanSubject",
                );

                my $TicketNumberFound = $TicketObject->GetTNByString($Subject);

                $Self->Is(
                    $TicketNumberFound,
                    $TicketNumber,
                    "$Backend - $TicketSubjectFormat - $Count - GetTNByString",
                );

                #
                # Subject with spaces around ticket number
                #
                my $SubjectWithPrefix = $TicketObject->TicketSubjectBuild(
                    TicketNumber => $TicketNumber,
                    Subject      => 'GF: Test',
                );

                $Self->True(
                    scalar $SubjectWithPrefix,
                    "$Backend - $TicketSubjectFormat - $Count - TicketSubjectBuild() - result $Subject",
                );

                my $CleanSubjectWithPrefix = $TicketObject->TicketSubjectClean(
                    TicketNumber => $TicketNumber,
                    Subject      => $SubjectWithPrefix,
                );

                $Self->Is(
                    $CleanSubjectWithPrefix,
                    'GF: Test',
                    "$Backend - $TicketSubjectFormat - $Count - TicketSubjectClean() - result $CleanSubject",
                );

                #
                # More complex test: find ticket number in string with both ticket numbers
                #
                my $CombinedSubject = $TicketObject->TicketSubjectBuild(
                    TicketNumber => $ForeignTicketNumber,
                    Subject      => 'Test',
                );
                $CombinedSubject .= ' ' . $Subject;

                $TicketNumberFound = $TicketObject->GetTNByString($CombinedSubject);

                $Self->Is(
                    $TicketNumberFound,
                    $TicketNumber,
                    "$Backend - $TicketSubjectFormat - $Count - GetTNByString - $CombinedSubject",
                );
            }
        }
    }
}

1;
