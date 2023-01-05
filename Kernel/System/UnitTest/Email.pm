# --
# Copyright (C) 2021 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::UnitTest::Email;

use strict;
use warnings;

use Kernel::System::VariableCheck qw(:all);

our @ObjectDependencies = (
    'Kernel::Config',
    'Kernel::System::Email',
    'Kernel::System::Email::Test',
    'Kernel::System::Log',
    'Kernel::System::Ticket',
    'Kernel::System::MailQueue',
);

=head1 NAME

Kernel::System::UnitTest::Email - Helper to unit test emails

=head1 SYNOPSIS

Functions to unit test emails

=head1 PUBLIC INTERFACE

=head2 new()

create an object

    use Kernel::System::ObjectManager;
    local $Kernel::OM = Kernel::System::ObjectManager->new();
    my $UnitTestEmailObject = $Kernel::OM->Get('Kernel::System::UnitTest::Email');

=cut

sub new {
    my ( $Type, %Param ) = @_;

    my $Self = {};
    bless( $Self, $Type );

    $Self->MailBackendSetup();
    $Self->MailCleanup();

    return $Self;
}

=head2 MailCleanup()

Removes existing emails from Email::Test backend object.

    my $Success = $UnitTestEmailObject->MailCleanup();

Returns:

    my $Success = 1;

=cut

sub MailCleanup {
    my ( $Self, %Param ) = @_;

    my $TestEmailObject = $Kernel::OM->Get('Kernel::System::Email::Test');
    $TestEmailObject->CleanUp();

    return 1;
}

=head2 MailObjectDiscard()

Discards the following objects:
    Kernel::System::Ticket
    Kernel::System::Email::Test
    Kernel::System::Email
and triggers transaction notifications.

Also re-initializes the above objects.

    my $Success = $UnitTestEmailObject->MailObjectDiscard();

Returns:

    my $Success = 1;

=cut

sub MailObjectDiscard {
    my ( $Self, %Param ) = @_;

    $Kernel::OM->ObjectsDiscard(
        Objects => [
            'Kernel::System::Ticket',
            'Kernel::System::Email::Test',
            'Kernel::System::Email',
        ],
    );

    my $TicketObject    = $Kernel::OM->Get('Kernel::System::Ticket');
    my $TestEmailObject = $Kernel::OM->Get('Kernel::System::Email::Test');
    my $EmailObject     = $Kernel::OM->Get('Kernel::System::Email');

    return 1;
}

=head2 MailBackendSetup()

Configures Kernel::System::Email::Test as email backend
and disables email address check.

    my $Success = $UnitTestEmailObject->MailBackendSetup();

Returns:

    my $Success = 1;

=cut

sub MailBackendSetup {
    my ( $Self, %Param ) = @_;

    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');

    $ConfigObject->Set(
        Key   => 'SendmailModule',
        Value => 'Kernel::System::Email::Test',
    );

    $ConfigObject->Set(
        Key   => 'CheckEmailAddresses',
        Value => 0,
    );

    return 1;
}

=head2 EmailGet()

Fetches emails from email test backend and returns array of hash references containing emails.

    my @Emails = $UnitTestEmailObject->EmailGet();

Returns:

    @Emails = (
        {
            Header  => "Email1 Header text...",
            Body    => "Email1 Header text...",
            ToArray => [
                'email1realrecipient1@test.com',
                'email1realrecipient2@test.com',
                'email1realrecipient1@test.com',
            ],
        },
        {
            Header => "Email2 Header text...",
            Body => "Email2 Header text...",
            ToArray => [ 'email2realrecipient1@test.com', ],
        },
        # ...
    );

=cut

sub EmailGet {
    my ( $Self, %Param ) = @_;

    $Self->_SendEmails();

    my $TestEmailObject = $Kernel::OM->Get('Kernel::System::Email::Test');
    my $Emails          = $TestEmailObject->EmailsGet();

    my @AllEmails;
    return @AllEmails if !IsArrayRefWithData($Emails);

    for my $Email ( @{$Emails} ) {
        my $Header  = ${ $Email->{Header} };
        my $Body    = ${ $Email->{Body} };
        my @ToArray = @{ $Email->{ToArray} };

        push @AllEmails, {
            Header  => $Header,
            Body    => $Body,
            ToArray => \@ToArray,
        };
    }

    return @AllEmails;
}

=head2 EmailSentCount()

This function counts the number of sent emails.

    $UnitTestEmailObject->EmailSentCount(
        UnitTestObject => $Self,
        Count          => 3,                               # Expected number of sent emails
        Message        => '3 emails must have been sent.', # Message printed for unit test
    );

=cut

sub EmailSentCount {
    my ( $Self, %Param ) = @_;

    my $LogObject = $Kernel::OM->Get('Kernel::System::Log');

    NEEDED:
    for my $Needed (qw(UnitTestObject Count)) {
        next NEEDED if defined $Param{$Needed};

        $LogObject->Log(
            Priority => 'error',
            Message  => "Parameter '$Needed' is needed!",
        );
        return;
    }

    $Param{Message} //= "$Param{Count} email(s) sent";

    my @SentEmails = $Self->EmailGet();
    $Param{UnitTestObject}->Is(
        scalar @SentEmails,
        $Param{Count},
        $Param{Message},
    );

    return 1;
}

=head2 EmailValidate()

Checks if the sent emails match the given criteria.

Example:

    my $Success = $UnitTestEmailObject->EmailValidate(
        UnitTestObject => $Self,
        UnitTestFalse  => 1,                                         # optional, validation should get negated
        Message        => 'Sent emails must contain expected data.', # Message printed for unit test
        Email          => \@Emails,                                  # optional, result of EmailGet() will be used by default
        Header         => qr{To\:\sto\@test.com}xms,                 # Regex or array of regexes that the headers of the sent emails have to match
                                                                     #    example: [ qr{To\:\sto\@test.com}xms, qr{To\:\scc\@test.com}xms, ],
        Body           => qr{Hello [ ] World}xms,                    # Regex or string that the body of the sent emails have to match
        ToArray        => 'email1realrecipient1@test.com',           # Array of strings, string, array of regexes or regex with recipients the sent emails have to match
    );

Returns:

    my $Success = 1; # or 0 if not found

=cut

sub EmailValidate {
    my ( $Self, %Param ) = @_;

    my $LogObject = $Kernel::OM->Get('Kernel::System::Log');

    NEEDED:
    for my $Needed (qw(UnitTestObject)) {
        next NEEDED if defined $Param{$Needed};

        $LogObject->Log(
            Priority => 'error',
            Message  => "Parameter '$Needed' is needed!",
        );
        return;
    }

    if (
        !defined $Param{Header}
        && !defined $Param{Body}
        && !defined $Param{ToArray}
        )
    {
        $LogObject->Log(
            Priority => 'error',
            Message  => 'Need at least one of parameters Header, Body or ToArray!',
        );
        return;
    }

    # Header allows only regexes
    if (
        defined $Param{Header}
        && ref $Param{Header} ne 'Regexp'
        && !IsArrayRefWithData( $Param{Header} )
        )
    {
        $LogObject->Log(
            Priority => 'error',
            Message  => 'Need regex or array of regexes in Header!',
        );
        return;
    }

    # Body allows only regexes or strings
    if (
        defined $Param{Body}
        && ref $Param{Body}
        && ref $Param{Body} ne 'Regexp'
        && ref $Param{Body} ne 'ARRAY'
        )
    {
        $LogObject->Log(
            Priority => 'error',
            Message  => 'Only regex, string or array of strings or regexes is allowed in Body!',
        );
        return;
    }

    my @Emails;
    if ( IsArrayRefWithData( $Param{Email} ) ) {
        @Emails = @{ $Param{Email} };
    }
    else {
        @Emails = $Self->EmailGet();
    }

    my $Result;

    EMAIL:
    for my $Email (@Emails) {

        # Found will contain Header and/or Body and/or ToArray as keys,
        # if the submitted Header and/or Body and/or ToArray search matched
        my %Found;

        # Counter will hold the number of search params (1 to 3 depending on Header, Body, ToArray)
        my $SearchParamCount = 0;

        SEARCHPARAM:
        for my $SearchParam (qw(Header Body ToArray)) {
            next SEARCHPARAM if !defined $Param{$SearchParam};

            $SearchParamCount++;

            # If the SearchParam contains an array (e. g. ToArray or Header)
            if ( IsArrayRefWithData( $Param{$SearchParam} ) ) {

                # Counter for each found search term
                my $FoundCount = 0;

                # Loop through the search term items of Header or ToArray
                SEARCHTERM:
                for my $SearchTerm ( @{ $Param{$SearchParam} } ) {
                    if (
                        $SearchParam eq 'Header'
                        && ref $Param{$SearchParam} ne 'Regexp'
                        && ref $Param{$SearchParam} ne 'ARRAY'
                        )
                    {
                        $LogObject->Log(
                            Priority => 'error',
                            Message  => 'Only a regex or an array of regexes is allowed in Header!',
                        );
                        return;
                    }

                    # If we had multiple Header or Body regexes
                    # the emails' header/body is a string -> just one comparison necessary
                    if ( !ref $Email->{$SearchParam} ) {
                        next SEARCHTERM if !$Self->_SearchStringOrRegex(
                            Search => $SearchTerm,
                            Data   => $Email->{$SearchParam},
                        );

                        $FoundCount++;

                        next SEARCHTERM;
                    }

                    # Check this emails' SearchParam (e. g. ToArray entries) if the current search term matches
                    EMAILSEARCHPARAM:
                    for my $EmailSearchParam ( @{ $Email->{$SearchParam} } ) {

                        # If match found, increase the FoundCount
                        next EMAILSEARCHPARAM if !$Self->_SearchStringOrRegex(
                            Search => $SearchTerm,
                            Data   => $EmailSearchParam,
                        );

                        $FoundCount++;

                        # If the search term (e.g. the regex or search string)
                        # matches one ToArray entry, we can continue to the next search term
                        #
                        # (Regexes may match multiple ToArray entries -> one match is enough)
                        next SEARCHTERM;
                    }
                }

                # If no match in this email, go to the next email
                next EMAIL if !$FoundCount;

                # If the amount of search params matches the amount of search param entries,
                # the search was successful
                if ( $FoundCount == scalar @{ $Param{$SearchParam} } ) {
                    $Found{$SearchParam} = 1;
                }
                next SEARCHPARAM;
            }

            # If we had an email with an array ref (e.g. multiple ToArray entries)
            # but only one search term for the ToArray
            if ( IsArrayRefWithData( $Email->{$SearchParam} ) ) {

                # Go through the ToArray entries and check against our single search param
                EMAILPART:
                for my $EmailPart ( @{ $Email->{$SearchParam} } ) {
                    next EMAILPART if !$Self->_SearchStringOrRegex(
                        Search => $Param{$SearchParam},
                        Data   => $EmailPart,
                    );

                    $Found{$SearchParam} = 1;
                    next SEARCHPARAM;
                }

                # If no match in this email, go to the next email
                next EMAIL;
            }

            # For everything else, just compare SearchParam against EmailParam
            next SEARCHPARAM if !$Self->_SearchStringOrRegex(
                Search => $Param{$SearchParam},
                Data   => $Email->{$SearchParam},
            );

            $Found{$SearchParam} = 1;
        }

        # If the amount of search params matches the amount of found search params
        # this email matched => *success*
        next EMAIL if $SearchParamCount != scalar keys %Found;

        $Result = 1;

        last EMAIL;
    }

    my $CheckFunction = $Param{UnitTestFalse} ? 'False' : 'True';

    $Param{UnitTestObject}->$CheckFunction(
        $Result,
        $Param{Message} || 'Verification of sent emails.',
    );

    return $Result;
}

sub _SearchStringOrRegex {
    my ( $Self, %Param ) = @_;

    return if !$Param{Search} && !$Param{Data};

    my $Search = $Param{Search};
    if ( !ref $Search ) {
        return 1 if $Param{Data} eq $Search;
    }
    if ( ref $Search eq 'Regexp' ) {
        return 1 if $Param{Data} =~ m{$Search};
    }

    return;
}

sub _SendEmails {
    my ( $Self, %Param ) = @_;

    my $MailQueueObject = $Kernel::OM->Get('Kernel::System::MailQueue');
    my $TicketObject    = $Kernel::OM->Get('Kernel::System::Ticket');

    $TicketObject->EventHandlerTransaction();

    # Get last item in the queue.
    my $Items = $MailQueueObject->List();
    my @ToReturn;
    for my $Item (@$Items) {
        $MailQueueObject->Send( %{$Item} );
        push @ToReturn, $Item->{Message};
    }

    # Clean the mail queue.
    $MailQueueObject->Delete();

    return @ToReturn;
}

1;
