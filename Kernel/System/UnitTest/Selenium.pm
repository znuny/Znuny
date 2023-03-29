# --
# Copyright (C) 2001-2021 OTRS AG, https://otrs.com/
# Copyright (C) 2021 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see https://www.gnu.org/licenses/gpl-3.0.txt.
# --
## nofilter(TidyAll::Plugin::Znuny::CodeStyle::STDERRCheck)
## nofilter(TidyAll::Plugin::Znuny::Perl::Pod::FunctionPod)

package Kernel::System::UnitTest::Selenium;

use strict;
use warnings;

use utf8;

use Devel::StackTrace();
use MIME::Base64();
use File::Path qw(mkpath);
use File::Temp();
use Time::HiRes();
use URI::Escape;

use Kernel::Config;
use Kernel::System::User;
use Kernel::System::UnitTest::Helper;
use Kernel::System::VariableCheck qw(:all);

our @ObjectDependencies = (
    'Kernel::Config',
    'Kernel::System::AuthSession',
    'Kernel::System::DateTime',
    'Kernel::System::JSON',
    'Kernel::System::Log',
    'Kernel::System::Main',
    'Kernel::System::UnitTest::Helper',
);

# If a test throws an exception, we'll record it here in a package variable so that we can
#   take screenshots of *all* Selenium instances that are currently running on shutdown.
our $TestException;

=head1 NAME

Kernel::System::UnitTest::Selenium - run front end tests

This class inherits from Selenium::Remote::Driver. You can use
its full API (see
L<http://search.cpan.org/~aivaturi/Selenium-Remote-Driver-0.15/lib/Selenium/Remote/Driver.pm>).

Every successful Selenium command will be logged as a successful unit test.
In case of an error, an exception will be thrown that you can catch in your
unit test file and handle with C<HandleError()> in this class. It will output
a failing test result and generate a screen shot for analysis.

=head2 new()

create a selenium object to run front end tests.

To do this, you need a running C<selenium> or C<phantomjs> server.

Specify the connection details in C<Config.pm>, like this:

    # For testing with Firefox until v. 47 (testing with recent FF and marionette is currently not supported):
    $Self->{'SeleniumTestsConfig'} = {
        remote_server_addr  => 'localhost',
        port                => '4444',
        platform            => 'ANY',
        browser_name        => 'firefox',
        extra_capabilities => {
            marionette     => \0,   # Required to run FF 47 or older on Selenium 3+.
        },
    };

    # For testing with Chrome/Chromium (requires installed geckodriver):
    $Self->{'SeleniumTestsConfig'} = {
        remote_server_addr  => 'localhost',
        port                => '4444',
        platform            => 'ANY',
        browser_name        => 'chrome',
        extra_capabilities => {
            chromeOptions => {
                # disable-infobars makes sure window size calculations are ok
                args => [ "disable-infobars" ],
            },
        },
    };

Then you can use the full API of L<Selenium::Remote::Driver> on this object.

    # For testing with other selenium configurations, change the SeleniumTestsConfig directly without changing the Config.

    $Kernel::OM->ObjectParamAdd(
        'Kernel::System::UnitTest::Selenium' => {
            SeleniumTestsConfig  => {
                remote_server_addr => 'selenium',
                port               => '4444',
                browser_name       => 'chrome',
                extra_capabilities => {
                    chromeOptions => {
                        args => [ "disable-gpu", "disable-infobars" ],
                    },
                    marionette => '',
                },
            }
        },
    );

    my $SeleniumObject = $Kernel::OM->Get('Kernel::System::UnitTest::Selenium');

=cut

sub new {
    my ( $Class, %Param ) = @_;

    my $HelperObject = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');
    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');
    my $MainObject   = $Kernel::OM->Get('Kernel::System::Main');

    $Param{UnitTestDriverObject} ||= $HelperObject->UnitTestObjectGet();
    $Param{UnitTestDriverObject}->True( 1, "Starting up Selenium scenario..." );

    my %SeleniumTestsConfig = %{ $ConfigObject->Get('SeleniumTestsConfig') // {} };
    if ( $Param{SeleniumTestsConfig} ) {
        %SeleniumTestsConfig = (
            %SeleniumTestsConfig,
            %{ $Param{SeleniumTestsConfig} }
        );
    }

    if ( !%SeleniumTestsConfig ) {
        my $Self = bless {}, $Class;
        $Self->{UnitTestDriverObject} = $Param{UnitTestDriverObject};
        return $Self;
    }

    for my $Needed (qw(remote_server_addr port browser_name platform)) {
        if ( !$SeleniumTestsConfig{$Needed} ) {
            die "SeleniumTestsConfig must provide $Needed!";
        }
    }

    $MainObject->RequireBaseClass('Selenium::Remote::Driver')
        || die "Could not load Selenium::Remote::Driver";

    $MainObject->RequireBaseClass('Kernel::System::UnitTest::Selenium::WebElement')
        || die "Could not load Kernel::System::UnitTest::Selenium::WebElement";

    my $Self;

    # TEMPORARY WORKAROUND FOR GECKODRIVER BUG https://github.com/mozilla/geckodriver/issues/1470:
    #   If marionette handshake fails, wait and try again. Can be removed after the bug is fixed
    #   in a new geckodriver version.
    eval {
        $Self = $Class->SUPER::new(
            webelement_class => 'Kernel::System::UnitTest::Selenium::WebElement',
            error_handler    => sub {
                my $Self = shift;
                return $Self->SeleniumErrorHandler(@_);
            },
            %SeleniumTestsConfig
        );
    };
    if ($@) {
        my $Exception = $@;

        # Only handle this specific geckodriver exception.
        die $Exception if $Exception !~ m{Socket timeout reading Marionette handshake data};

        # Sleep and try again, bail out if it fails a second time.
        # A long sleep of 10 seconds is acceptable here, as it occurs only very rarely.
        sleep 10;

        $Self = $Class->SUPER::new(
            webelement_class => 'Kernel::System::UnitTest::Selenium::WebElement',
            error_handler    => sub {
                my $Self = shift;
                return $Self->SeleniumErrorHandler(@_);
            },
            %SeleniumTestsConfig
        );
    }

    $Self->{UnitTestDriverObject}         = $Param{UnitTestDriverObject};
    $Self->{SeleniumTestsActive}          = 1;
    $Self->{SeleniumScreenshotsDirectory} = 'SeleniumScreenshots';
    $Self->{SeleniumDump}                 = $ENV{SELENIUM_DUMP} || $Param{SeleniumTestsConfig}->{SeleniumDump};
    $Self->{Home}                         = $Self->GetSeleniumHome();

    $Self->{UnitTestDriverObject}->{SeleniumData} = { %{ $Self->get_capabilities() }, %{ $Self->status() } };

    #$Self->debug_on();

    # set screen size from config or use defaults
    my $Height = $SeleniumTestsConfig{window_height} || 1200;
    my $Width  = $SeleniumTestsConfig{window_width}  || 1400;

    $Self->set_window_size( $Height, $Width );

    $Self->{BaseURL} = $ConfigObject->Get('HttpType') . '://';
    $Self->{BaseURL} .= $HelperObject->GetTestHTTPHostname();

    # Force usage of legacy webdriver methods in Chrome until things are more stable.
    if ( lc $SeleniumTestsConfig{browser_name} eq 'chrome' ) {
        $Self->{is_wd3} = 0;
    }

    if ( defined $SeleniumTestsConfig{is_wd3} ) {
        $Self->{is_wd3} = $SeleniumTestsConfig{is_wd3};
    }

    # Remember the start system time for the selenium test run.
    $Self->{TestStartSystemTime} = time;    ## no critic

    return $Self;
}

sub SeleniumErrorHandler {
    my ( $Self, $Error ) = @_;

    my $SuppressFrames;

    # Generate stack trace information.
    #   Don't store caller args, as this sometimes blows up due to an internal Perl bug
    #   (see https://github.com/Perl/perl5/issues/10687).
    my $StackTrace = Devel::StackTrace->new(
        indent         => 1,
        no_args        => 1,
        ignore_package => [ 'Selenium::Remote::Driver', 'Try::Tiny', __PACKAGE__ ],
        message        => 'Selenium stack trace started',
        frame_filter   => sub {

            # Limit stack trace to test evaluation itself.
            return 0          if $SuppressFrames;
            $SuppressFrames++ if $_[0]->{caller}->[3] eq 'Kernel::System::UnitTest::Driver::Run';

            # Remove the long serialized eval texts from the frame to keep the trace short.
            if ( $_[0]->{caller}->[6] ) {
                $_[0]->{caller}->[6] = '{...}';
            }
            return 1;
        }
    )->as_string();

    $Self->{_SeleniumStackTrace} = $StackTrace;
    $Self->{_SeleniumException}  = $Error;

    die $Error;
}

=head2 RunTest()

runs a selenium test if Selenium testing is configured.

    $SeleniumObject->RunTest( sub { ... } );

=cut

sub RunTest {
    my ( $Self, $Test ) = @_;

    if ( !$Self->{SeleniumTestsActive} ) {
        $Self->{UnitTestDriverObject}->True( 1, 'Selenium testing is not active, skipping tests.' );
        return 1;
    }

    eval {
        $Test->();
    };

    $TestException = $@ if $@;

    return 1;
}

=head2 _execute_command()

Override internal command of base class.

We use it to output successful command runs to the UnitTest object.
Errors will cause an exception and be caught elsewhere.

=cut

sub _execute_command {    ## no critic
    my ( $Self, $Res, $Params ) = @_;

    my $Result = $Self->SUPER::_execute_command( $Res, $Params );

    my $TestName = 'Selenium command success: ';
    my %DumpData = (
        Res    => $Res    || {},    ## no critic
        Params => $Params || {},    ## no critic
        Time   => time(),
    );

    if ( $Self->{SeleniumDump} && $Res->{command} ne 'screenshot' ) {
        $DumpData{Result} = $Result;
    }

    $TestName .= $Kernel::OM->Get('Kernel::System::Main')->Dump(
        \%DumpData
    );

    if ( $Self->{SuppressCommandRecording} ) {
        print $TestName;
    }
    else {
        $Self->{UnitTestDriverObject}->True( 1, $TestName );
    }

    return $Result;
}

=head2 get()

Override get method of base class to prepend the correct base URL.

    $SeleniumObject->get(
        $URL,
    );

=cut

sub get {    ## no critic
    my ( $Self, $URL ) = @_;

    if ( $URL !~ m{http[s]?://}smx ) {

        # Chop off leading slashes to avoid duplicates.
        $URL =~ s{\A/+}{}smx;
        $URL = "$Self->{BaseURL}/$URL";
    }

    $Self->SUPER::get($URL);

    return;
}

=head2 get_alert_text()

Override get_alert_text() method of base class to return alert text as string.

    my $AlertText = $SeleniumObject->get_alert_text();

returns

    my $AlertText = 'Some alert text!'

=cut

sub get_alert_text {    ## no critic
    my ($Self) = @_;

    my $AlertText = $Self->SUPER::get_alert_text();

    die "Alert dialog is not present" if ref $AlertText eq 'HASH';    # Chrome returns HASH when there is no alert text.

    return $AlertText;
}

=head2 VerifiedGet()

perform a get() call, but wait for the page to be fully loaded (works only within Znuny).
Will die() if the verification fails.

    $SeleniumObject->VerifiedGet(
        $URL,
    );

=cut

sub VerifiedGet {
    my ( $Self, $URL ) = @_;

    $Self->get($URL);

    $Self->WaitFor(
        JavaScript =>
            'return typeof(Core) == "object" && typeof(Core.App) == "object" && Core.App.PageLoadComplete'
    ) || die "Znuny API verification failed after page load.";

    return;
}

=head2 VerifiedRefresh()

perform a refresh() call, but wait for the page to be fully loaded (works only within Znuny).
Will die() if the verification fails.

    $SeleniumObject->VerifiedRefresh();

=cut

sub VerifiedRefresh {
    my ( $Self, $URL ) = @_;

    $Self->refresh();

    $Self->WaitFor(
        JavaScript =>
            'return typeof(Core) == "object" && typeof(Core.App) == "object" && Core.App.PageLoadComplete'
    ) || die "Znuny API verification failed after page load.";

    return;
}

=head2 Login()

login to agent or customer interface

    $SeleniumObject->Login(
        Type     => 'Agent', # Agent|Customer
        User     => 'someuser',
        Password => 'somepassword',
    );

=cut

sub Login {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Needed (qw(Type User Password)) {
        if ( !$Param{$Needed} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Needed!",
            );
            return;
        }
    }

    $Self->{UnitTestDriverObject}->True( 1, 'Initiating login...' );

    # we will try several times to log in
    my $MaxTries = 5;

    TRY:
    for my $Try ( 1 .. $MaxTries ) {

        eval {
            my $ScriptAlias = $Kernel::OM->Get('Kernel::Config')->Get('ScriptAlias');

            if ( $Param{Type} eq 'Agent' ) {
                $ScriptAlias .= 'index.pl';
            }
            else {
                $ScriptAlias .= 'customer.pl';
            }

            $Self->get("${ScriptAlias}");

            $Self->delete_all_cookies();
            $Self->VerifiedGet("${ScriptAlias}?Action=Login;User=$Param{User};Password=$Param{Password}");

            # login successful?
            $Self->find_element( 'a#LogoutButton', 'css' );    # dies if not found

            $Self->{UnitTestDriverObject}->True( 1, 'Login sequence ended...' );
        };

        # an error occurred
        if ($@) {

            $Self->{UnitTestDriverObject}->True( 1, "Login attempt $Try of $MaxTries not successful." );

            # try again
            next TRY if $Try < $MaxTries;
            $Self->HandleError($@);
            die "Login failed!";
        }

        # login was successful
        else {
            last TRY;
        }
    }

    return 1;
}

=head2 WaitFor()

wait with increasing sleep intervals until the given condition is true or the wait time is over.
Exactly one condition (JavaScript or WindowCount) must be specified.

    my $Success = $SeleniumObject->WaitFor(
        AlertPresent   => 1,                                 # Wait until an alert, confirm or prompt dialog is present
        Callback       => sub { ... }                        # Wait until function returns true
        ElementExists  => 'xpath-selector',                  # Wait until an element is present
        ElementExists  => ['css-selector', 'css'],
        ElementMissing => 'xpath-selector',                  # Wait until an element is not present
        ElementMissing => ['css-selector', 'css'],
        JavaScript     => 'return $(".someclass").length',   # JavaScript code that checks condition
        WindowCount    => 2,                                 # Wait until this many windows are open
        Time           => 20,                                # optional, wait time in seconds (default 20)
        SkipDie        => 1,                                 # Instead of a dying process do return the result of the wait for
    );

=cut

sub WaitFor {
    my ( $Self, %Param ) = @_;

    if (
        !$Param{JavaScript}
        && !$Param{WindowCount}
        && !$Param{AlertPresent}
        && !$Param{Callback}
        && !$Param{ElementExists}
        && !$Param{ElementMissing}
        )
    {
        die "Need JavaScript, WindowCount, ElementExists, ElementMissing, Callback or AlertPresent.";
    }

    local $Self->{SuppressCommandRecording} = 1;

    $Param{Time} //= 20;
    my $WaitedSeconds = 0;
    my $Interval      = 0.1;
    my $WaitSeconds   = 0.5;

    while ( $WaitedSeconds <= $Param{Time} ) {
        if ( $Param{JavaScript} ) {
            return 1 if $Self->execute_script( $Param{JavaScript} );
        }
        elsif ( $Param{WindowCount} ) {
            return 1 if scalar( @{ $Self->get_window_handles() } ) == $Param{WindowCount};
        }
        elsif ( $Param{AlertPresent} ) {

            # Eval is needed because the method would throw if no alert is present (yet).
            return 1 if eval { $Self->get_alert_text() };
        }
        elsif ( $Param{Callback} ) {
            return 1 if $Param{Callback}->();
        }
        elsif ( $Param{ElementExists} ) {
            my @Arguments
                = ref( $Param{ElementExists} ) eq 'ARRAY' ? @{ $Param{ElementExists} } : $Param{ElementExists};

            if ( eval { $Self->find_element(@Arguments) } ) {
                Time::HiRes::sleep($WaitSeconds);
                return 1;
            }
        }
        elsif ( $Param{ElementMissing} ) {
            my @Arguments
                = ref( $Param{ElementMissing} ) eq 'ARRAY' ? @{ $Param{ElementMissing} } : $Param{ElementMissing};

            if ( !eval { $Self->find_element(@Arguments) } ) {
                Time::HiRes::sleep($WaitSeconds);
                return 1;
            }
        }
        Time::HiRes::sleep($Interval);
        $WaitedSeconds += $Interval;
        $Interval      += 0.1;
    }

    my $Argument = '';
    for my $Key (qw(JavaScript WindowCount AlertPresent)) {
        $Argument = "$Key => $Param{$Key}" if $Param{$Key};
    }
    $Argument = "Callback" if $Param{Callback};

    return if $Param{SkipDie};

    # Use the selenium error handler to generate a stack trace.
    die $Self->SeleniumErrorHandler("WaitFor($Argument) failed.\n");
}

=head2 SwitchToFrame()

Change focus to another frame on the page. If C<WaitForLoad> is passed, it will wait until the frame has loaded the
page completely.

    my $Success = $SeleniumObject->SwitchToFrame(
        FrameSelector => '.Iframe',     # (required) CSS selector of the frame element
        WaitForLoad   => 1,             # (optional) Wait until the frame has loaded, if necessary
        Time          => 20,            # (optional) Wait time in seconds (default 20)
    );

=cut

sub SwitchToFrame {
    my ( $Self, %Param ) = @_;

    if ( !$Param{FrameSelector} ) {
        die 'Need FrameSelector.';
    }

    if ( $Param{WaitForLoad} ) {
        $Self->WaitFor(
            JavaScript => "return typeof(\$('$Param{FrameSelector}').get(0).contentWindow.Core) == 'object'
                && typeof(\$('$Param{FrameSelector}').get(0).contentWindow.Core.App) == 'object'
                && \$('$Param{FrameSelector}').get(0).contentWindow.Core.App.PageLoadComplete;",
            Time => $Param{Time},
        );
    }

    my $Element = $Self->FindElementSave(
        Selector     => $Param{FrameSelector},
        SelectorType => 'css',
    );

    $Self->{UnitTestDriverObject}->True(
        scalar $Element->{id},
        'SwitchToFrame: Element $Param{FrameSelector}.'
    );

    $Self->switch_to_frame($Element);

    return 1;
}

=head2 DragAndDrop()

Drag and drop an element.

    $SeleniumObject->DragAndDrop(
        Element         => '.Element', # (required) css selector of element which should be dragged
        Target          => '.Target',  # (required) css selector of element on which the dragged element should be dropped
        TargetOffset    => {           # (optional) Offset for target. If not specified, the mouse will move to the middle of the element.
            X   => 150,
            Y   => 100,
        }
    );

=cut

sub DragAndDrop {

    my ( $Self, %Param ) = @_;

    # Value is optional parameter
    for my $Needed (qw(Element Target)) {
        if ( !$Param{$Needed} ) {
            die "Need $Needed";
        }
    }

    my %TargetOffset;
    if ( $Param{TargetOffset} ) {
        %TargetOffset = (
            xoffset => $Param{TargetOffset}->{X} || 0,
            yoffset => $Param{TargetOffset}->{Y} || 0,
        );
    }

    # Make sure Element is visible
    $Self->WaitFor(
        JavaScript => 'return typeof($) === "function" && $(\'' . $Param{Element} . ':visible\').length;',
    );
    my $Element = $Self->find_element( $Param{Element}, 'css' );

    # Move mouse to from element, drag and drop
    $Self->mouse_move_to_location( element => $Element );

    # Holds the mouse button on the element
    $Self->button_down();

    # Make sure Target is visible
    $Self->WaitFor(
        JavaScript => 'return typeof($) === "function" && $(\'' . $Param{Target} . ':visible\').length;',
    );
    my $Target = $Self->find_element( $Param{Target}, 'css' );

    # Move mouse to the destination
    $Self->mouse_move_to_location(
        element => $Target,
        %TargetOffset,
    );

    # Release
    $Self->button_up();

    return;
}

=head2 HandleError()

use this method to handle any Selenium exceptions.

    $SeleniumObject->HandleError($@);

It will create a failing test result and store a screen shot of the page
for analysis (in folder /var/otrs-unittest if it exists, in $Home/var/httpd/htdocs otherwise).

=cut

sub HandleError {
    my ( $Self, $Error ) = @_;

    # If we really have a selenium error, get the stack trace for it.
    if ( $Self->{_SeleniumStackTrace} && $Error eq $Self->{_SeleniumException} ) {
        $Error .= "\n" . $Self->{_SeleniumStackTrace};
    }

    $Self->CreateScreenshot();

    $Self->{UnitTestDriverObject}->False( 1, $Error );

    return;
}

=head2 DEMOLISH()

override DEMOLISH from L<Selenium::Remote::Driver> (required because this class is managed by L<Moo>).
Performs proper error handling (calls C<HandleError()> if needed). Adds a unit test result to indicate the shutdown,
and performs some clean-ups.

=cut

sub DEMOLISH {
    my $Self = shift;

    if ($TestException) {
        $Self->HandleError($TestException);
    }

    # Could be missing on early die.
    if ( $Self->{UnitTestDriverObject} ) {
        $Self->{UnitTestDriverObject}->True( 1, "Shutting down Selenium scenario." );
    }

    if ( $Self->{SeleniumTestsActive} ) {
        $Self->SUPER::DEMOLISH(@_);

        # Cleanup possibly leftover zombie firefox profiles.
        my @LeftoverFirefoxProfiles = $Kernel::OM->Get('Kernel::System::Main')->DirectoryRead(
            Directory => '/tmp/',
            Filter    => 'anonymous*webdriver-profile',
        );

        for my $LeftoverFirefoxProfile (@LeftoverFirefoxProfiles) {
            if ( -d $LeftoverFirefoxProfile ) {
                File::Path::remove_tree($LeftoverFirefoxProfile);
            }
        }

        # Cleanup all sessions which were created after the selenium test start time.
        my $AuthSessionObject = $Kernel::OM->Get('Kernel::System::AuthSession');

        my @Sessions = $AuthSessionObject->GetAllSessionIDs();

        SESSION:
        for my $SessionID (@Sessions) {

            my %SessionData = $AuthSessionObject->GetSessionIDData( SessionID => $SessionID );

            next SESSION if !%SessionData;
            next SESSION
                if $SessionData{UserSessionStart} && $SessionData{UserSessionStart} < $Self->{TestStartSystemTime};

            $AuthSessionObject->RemoveSessionID( SessionID => $SessionID );
        }
    }

    return;
}

=head1 DEPRECATED FUNCTIONS

=head2 WaitForjQueryEventBound()

waits until event handler is bound to the selected C<jQuery> element. Deprecated - it will be removed in the future releases.

    $SeleniumObject->WaitForjQueryEventBound(
        CSSSelector => 'li > a#Test',       # (required) css selector
        Event       => 'click',             # (optional) Specify event name. Default 'click'.
    );

=cut

sub WaitForjQueryEventBound {
    my ( $Self, %Param ) = @_;

    # Check needed stuff.
    if ( !$Param{CSSSelector} ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => "Need CSSSelector!",
        );
        return;
    }

    my $Event = $Param{Event} || 'click';

    # Wait for element availability.
    $Self->WaitFor(
        JavaScript => 'return typeof($) === "function" && $("' . $Param{CSSSelector} . '").length;'
    );

    # Wait for jQuery initialization.
    $Self->WaitFor(
        JavaScript =>
            'return Object.keys($("' . $Param{CSSSelector} . '")[0]).length > 0'
    );

    # Get jQuery object keys.
    my $Keys = $Self->execute_script(
        'return Object.keys($("' . $Param{CSSSelector} . '")[0]);'
    );

    if ( !IsArrayRefWithData($Keys) ) {
        die "Couldn't determine jQuery object id";
    }

    my $JQueryObjectID;

    KEY:
    for my $Key ( @{$Keys} ) {
        if ( $Key =~ m{^jQuery\d+$} ) {
            $JQueryObjectID = $Key;
            last KEY;
        }
    }

    if ( !$JQueryObjectID ) {
        die "Couldn't determine jQuery object id.";
    }

    # Wait until click event is bound to the element.
    $Self->WaitFor(
        JavaScript =>
            'return $("' . $Param{CSSSelector} . '")[0].' . $JQueryObjectID . '.events
                && $("' . $Param{CSSSelector} . '")[0].' . $JQueryObjectID . '.events.' . $Event . '
                && $("' . $Param{CSSSelector} . '")[0].' . $JQueryObjectID . '.events.' . $Event . '.length > 0;',
    );

    return 1;
}

=head2 InputFieldValueSet()

sets modernized input field value.

    $SeleniumObject->InputFieldValueSet(
        Element => 'css-selector',              # (required) css selector
        Value   => 3,                           # (optional) Value
    );

=cut

sub InputFieldValueSet {
    my ( $Self, %Param ) = @_;

    # Check needed stuff.
    if ( !$Param{Element} ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => "Need Element!",
        );
        die 'Missing Element.';
    }
    my $Value = $Param{Value} // '';

    if ( $Value !~ m{^\[} && $Value !~ m{^".*"$} ) {

        # Quote text of Value is not array and if not already quoted.
        $Value = "\"$Value\"";
    }

    # Set selected value.
    $Self->execute_script(
        "\$('$Param{Element}').val($Value).trigger('redraw.InputField').trigger('change');"
    );

    # Wait until selection tree is closed.
    $Self->WaitFor(
        ElementMissing => [ '.InputField_ListContainer', 'css' ],
    );

    return 1;
}

=head2 SendKeys()

Wrapper for the selenium function 'send_keys'.
Send the content as single key presses/pushes to form/input.

    my $Success = $SeleniumObject->SendKeys(
        Selector     => '#DynamicField_Test',
        SelectorType => 'css',                  # optional
        Content      => 'ABCDEFG',
    );

Returns:

    my $Success = 1;

=cut

sub SendKeys {
    my ( $Self, %Param ) = @_;

    my $LogObject = $Kernel::OM->Get('Kernel::System::Log');

    NEEDED:
    for my $Needed (qw(Selector Content)) {

        next NEEDED if defined $Param{$Needed};

        $LogObject->Log(
            Priority => 'error',
            Message  => "Parameter '$Needed' is needed!",
        );
        return;
    }

    $Param{SelectorType} ||= 'css';

    return $Self->find_element( $Param{Selector}, $Param{SelectorType} )->send_keys( $Param{Content} );
}

=head2 SelectOption()

Select a option value of selection field.
Can also be used to select autocomplete fields.

    my $Success = $SeleniumObject->SelectOption(
        Selector => 'li.ui-menu-item',
        Content  => 'ABCDEFG',
    );

Returns:

    my $Success = 1;

=cut

sub SelectOption {
    my ( $Self, %Param ) = @_;

    my $LogObject = $Kernel::OM->Get('Kernel::System::Log');

    NEEDED:
    for my $Needed (qw(Selector Content)) {

        next NEEDED if defined $Param{$Needed};

        $LogObject->Log(
            Priority => 'error',
            Message  => "Parameter '$Needed' is needed!",
        );
        return;
    }

    $Self->WaitFor(
        JavaScript => 'return typeof($) === "function" && $("' . $Param{Selector} . ':visible").length'
    );
    $Self->execute_script( "\$('" . $Param{Selector} . ":contains($Param{Content})').click()" );

    return 1;
}

=head2 InputGet()

Wrapper for the Znuny.Form.Input JavaScript namespace 'Get' function.

    my $Result = $SeleniumObject->InputGet(
        Attribute => 'QueueID',
        Options   => {                          # optional
            KeyOrValue => 'Value',              # default is 'Key'
        }
    );

    $Result = 'Postmaster';

=cut

sub InputGet {
    my ( $Self, %Param ) = @_;

    my $JSONObject = $Kernel::OM->Get('Kernel::System::JSON');

    my $OptionsParameter = '';
    if ( IsHashRefWithData( $Param{Options} ) ) {

        my $OptionsJSON = $JSONObject->Encode(
            Data => $Param{Options},
        );
        $OptionsParameter = ", $OptionsJSON";
    }

    my $Result = $Self->execute_script("return Znuny.Form.Input.Get('$Param{Attribute}' $OptionsParameter);");

    return $Result if !IsHashRefWithData($Result);

    # should be recursive sometimes
    KEY:
    for my $Key ( sort keys %{$Result} ) {

        my $Value = $Result->{$Key};

        next KEY if !defined $Value;
        next KEY if ref $Value ne 'JSON::PP::Boolean';

        $Result->{$Key} = $Value ? 1 : 0;
    }

    return $Result;
}

=head2 InputSet()

Wrapper for the Znuny.Form.Input JavaScript namespace 'Set' function.

    my $Result = $SeleniumObject->InputSet(
        Attribute   => 'QueueID',
        WaitForAJAX => 0,                       # optional, default 1
        Content     => 'Misc',                  # optional, none removes content
        Options     => {                        # optional
            KeyOrValue    => 'Value',           # default is 'Key'
            TriggerChange => 0,                 # default is 1
        }
    );

!!!! ATTENTION !!!!
For setting DynamicField Date or DateTime Fields the call should look like:

    my $Result = $SeleniumObject->InputSet(
        Attribute => 'DynamicField_NameOfYourDateOrDateTimeField',
        Content   => {
            Year   => '2016',
            Month  => '08',
            Day    => '30',
            Hour   => '00',
            Minute => '00',
            Second => '00',
            Used   => 1, # THIS ONE IS IMPORTANT -
                       # if not set to 1 field will not get activated and though not transmitted
        },
        WaitForAJAX => 1,
        Options     => {
            TriggerChange => 1,
        }
    );

For Checkboxes the call has to be done with undef,
everything else like '0', 0,... will fail. Example:

    my $Result = $SeleniumObject->InputSet(
        Attribute   => 'DynamicField_ExampleCheckbox',
        WaitForAJAX => 0,                       # optional, default 1
        Content     => undef,                   # optional, none removes content
        Options     => {                        # optional
            TriggerChange => 1,                 # default is 1
        }
    );

    $Result = 1;

=cut

sub InputSet {
    my ( $Self, %Param ) = @_;

    my $JSONObject = $Kernel::OM->Get('Kernel::System::JSON');

    my $Content;
    if ( !defined $Param{Content} ) {
        $Content = 'undefined';
    }
    elsif ( IsStringWithData( $Param{Content} ) ) {

        if (
            $Param{Content} eq 'true'
            || $Param{Content} eq 'false'
            )
        {
            $Content = $Param{Content};
        }
        else {
            # quoting
            $Param{Content} =~ s{'}{\\'}xmsg;
            $Param{Content} =~ s{\n}{\\n\\\n}xmsg;

            $Content = "'$Param{Content}'";
        }
    }
    else {
        my $ContentJSON = $JSONObject->Encode(
            Data => $Param{Content},
        );
        $Content = $ContentJSON;
    }

    my $OptionsParameter = '';
    if ( IsHashRefWithData( $Param{Options} ) ) {

        my $OptionsJSON = $JSONObject->Encode(
            Data => $Param{Options},
        );
        $OptionsParameter = ", $OptionsJSON";
    }

    my $Result = $Self->execute_script(
        "return Znuny.Form.Input.Set('$Param{Attribute}', $Content $OptionsParameter);"
    );

    if (
        !defined $Param{WaitForAJAX}
        || $Param{WaitForAJAX}
        )
    {
        $Self->AJAXCompleted();
    }

    # No GuardClause :)

    return $Result;
}

=head2 InputMandatory()

Wrapper for the Znuny.Form.Input JavaScript namespace 'Mandatory' function.
Sets OR returns the Mandatory state of an input field.

    # Set mandatory state:

    my $Result = $SeleniumObject->InputMandatory(
        Attribute => 'QueueID',
        Mandatory => 1,         # 1 or 0
    );

    $Result = 1;

    # OR return mandatory state:

    my $Result = $SeleniumObject->InputMandatory(
        Attribute => 'QueueID',
    );

    $Result = 0;

=cut

sub InputMandatory {
    my ( $Self, %Param ) = @_;

    my $JSONObject = $Kernel::OM->Get('Kernel::System::JSON');

    my $Mandatory;
    if ( defined $Param{Mandatory} ) {
        $Mandatory = $Param{Mandatory} ? 'true' : 'false';
    }

    return $Self->execute_script("return Znuny.Form.Input.Mandatory('$Param{Attribute}' $Mandatory);");
}

=head2 InputFieldID()

Wrapper for the Znuny.Form.Input JavaScript namespace 'FieldID' function.

    my $Result = $SeleniumObject->InputFieldID(
        Attribute => 'QueueID',
    );

    $Result = 'Dest';

=cut

sub InputFieldID {
    my ( $Self, %Param ) = @_;

    return $Self->execute_script("return Znuny.Form.Input.FieldID('$Param{Attribute}');");
}

=head2 InputType()

Wrapper for the Znuny.Form.Input JavaScript namespace 'Type' function.
Attention: Requires the FieldID - not the Attribute! (See InputFieldID)

    my $Result = $SeleniumObject->InputType(
        FieldID => 'Dest',
    );

    $Result = 'select';

=cut

sub InputType {
    my ( $Self, %Param ) = @_;

    return $Self->execute_script("return Znuny.Form.Input.Type('$Param{FieldID}');");
}

=head2 InputHide()

Wrapper for the Znuny.Form.Input JavaScript namespace 'Hide' function.

    my $Result = $SeleniumObject->InputHide(
        Attribute => 'QueueID',
    );

    my $Result = 1;

=cut

sub InputHide {
    my ( $Self, %Param ) = @_;

    return $Self->execute_script("return Znuny.Form.Input.Hide('$Param{Attribute}');");
}

=head2 InputExists()

Wrapper for the Znuny.Form.Input JavaScript namespace 'Exists' function.

    my $Result = $SeleniumObject->InputExists(
        Attribute => 'QueueID',
    );

    $Result = 1;

=cut

sub InputExists {
    my ( $Self, %Param ) = @_;

    return $Self->execute_script("return Znuny.Form.Input.Exists('$Param{Attribute}');");
}

=head2 InputShow()

Wrapper for the Znuny.Form.Input JavaScript namespace 'Show' function.

    my $Result = $SeleniumObject->InputShow(
        Attribute => 'QueueID',
    );

    $Result = 1;

=cut

sub InputShow {
    my ( $Self, %Param ) = @_;

    return $Self->execute_script("return Znuny.Form.Input.Show('$Param{Attribute}');");
}

=head2 InputModule()

Wrapper for the Znuny.Form.Input JavaScript namespace 'Module' function.

    my $Result = $SeleniumObject->InputModule(
        Action => 'QueueID',
    );

    $Result = 1;

=cut

sub InputModule {
    my ( $Self, %Param ) = @_;

    return $Self->execute_script("return Znuny.Form.Input.Module('$Param{Action}');");
}

=head2 InputFieldIDMapping()

Wrapper for the Znuny.Form.Input JavaScript namespace 'FieldIDMapping' function.
Sets OR returns the mapping structure of the given Action.

    my $Result = $SeleniumObject->InputFieldIDMapping(
        Action  => 'AgentTicketZoom',
        Mapping => {
            ...
            QueueID => 'DestQueueID',
            ...
        },
    );

    $Result = 1;

    # OR

    my $Result = $SeleniumObject->InputFieldIDMapping(
        Action  => 'AgentTicketZoom',
    );

    $Result = {
        DestQueueID => 'DestQueueID',
        QueueID     => 'DestQueueID'
    };

=cut

sub InputFieldIDMapping {
    my ( $Self, %Param ) = @_;

    my $JSONObject = $Kernel::OM->Get('Kernel::System::JSON');

    my $MappingParameter = '';
    if ( IsHashRefWithData( $Param{Mapping} ) ) {

        my $MappingJSON = $JSONObject->Encode(
            Data => $Param{Mapping},
        );
        $MappingParameter = ", $MappingJSON";
    }

    return $Self->execute_script(
        "return Znuny.Form.Input.FieldIDMapping('$Param{Action}' $MappingParameter);"
    );
}

=head2 AgentLogin()

Creates and logs in an Agent. Calls TestUserDataGet and Login on the ZnunyHelper object.

    my %UserData = $SeleniumObject->AgentLogin(
        Groups => ['admin', 'users'],           # optional, list of groups to add this user to (rw rights)
        Language => 'de'                        # optional, defaults to 'en' if not set
    );

    %UserData = {
        UserID        => 2,
        UserFirstname => $TestUserLogin,
        UserLastname  => $TestUserLogin,
        UserLogin     => $TestUserLogin,
        UserPw        => $TestUserLogin,
        UserEmail     => $TestUserLogin . '@localunittest.com',
    };

=cut

sub AgentLogin {
    my ( $Self, %Param ) = @_;

    my $ZnunyHelper = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');

    # create test user and login
    my %TestUser = $ZnunyHelper->TestUserDataGet(
        %Param
    );

    $Self->Login(
        Type     => 'Agent',
        User     => $TestUser{UserLogin},
        Password => $TestUser{UserLogin},
    );

    return %TestUser;
}

=head2 CustomerUserLogin()

Creates and logs in an CustomerUser. Calls TestCustomerUserDataGet and Login on the ZnunyHelper object.

    my %CustomerUserData = $SeleniumObject->CustomerUserLogin(
        Language => 'de' # optional, defaults to 'en' if not set
    );

    %CustomerUserData = {
        CustomerUserID => 1,
        Source         => 'CustomerUser',
        UserFirstname  => $TestUserLogin,
        UserLastname   => $TestUserLogin,
        UserCustomerID => $TestUserLogin,
        UserLogin      => $TestUserLogin,
        UserPassword   => $TestUserLogin,
        UserEmail      => $TestUserLogin . '@localunittest.com',
        ValidID        => 1,
    };

=cut

sub CustomerUserLogin {
    my ( $Self, %Param ) = @_;

    my $ZnunyHelper = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');

    # create test user and login
    my %TestCustomerUser = $ZnunyHelper->TestCustomerUserDataGet(
        %Param
    );

    $Self->Login(
        Type     => 'Customer',
        User     => $TestCustomerUser{UserLogin},
        Password => $TestCustomerUser{UserLogin},
    );

    return %TestCustomerUser;
}

=head2 SwitchToPopUp()

Switches the Selenium context to the PopUp

    $SeleniumObject->SwitchToPopUp(
        WaitForAJAX => 0, # optional, default 1
    );

=cut

sub SwitchToPopUp {
    my ( $Self, %Param ) = @_;

    # switch to PopUp window
    $Self->WaitFor( WindowCount => 2 );
    my $Handles = $Self->get_window_handles();
    $Self->switch_to_window( $Handles->[1] );

    # wait until page has loaded, if necessary
    $Self->WaitFor(
        JavaScript =>
            'return typeof($) === "function" && ($(".CancelClosePopup").length || $(".UndoClosePopup").length)'
    );

    if (
        defined $Param{WaitForAJAX}
        && !$Param{WaitForAJAX}
        )
    {
        return;
    }

    $Self->AJAXCompleted();
    return;
}

=head2 SwitchToMainWindow()

Switches the Selenium context to the main window

    $SeleniumObject->SwitchToMainWindow(
        WaitForAJAX => 0, # optional, default 1
    );

=cut

sub SwitchToMainWindow {
    my ( $Self, %Param ) = @_;

    my $Handles = $Self->get_window_handles();
    $Self->switch_to_window( $Handles->[0] );

    if (
        defined $Param{WaitForAJAX}
        && !$Param{WaitForAJAX}
        )
    {
        return;
    }

    $Self->AJAXCompleted();
    return;
}

=head2 PageContains()

Checks if the currently opened page contains the given String

    $SeleniumObject->PageContains(
        String  => 'Ticked locked.',
        Message => "Page contains 'Ticket locked.'" # optional - default
    );

=cut

sub PageContains {
    my ( $Self, %Param ) = @_;

    my $UnitTestMessage = $Param{Message};
    $UnitTestMessage ||= "Page contains '$Param{String}'";

    $Self->{UnitTestDriverObject}->True(
        index( $Self->get_page_source(), $Param{String} ) > -1,
        $UnitTestMessage,
    );
    return;
}

=head2 PageContainsNot()

Checks if the currently opened page does not contain the given String

    $SeleniumObject->PageContainsNot(
        String  => 'Ticked locked.',
        Message => "Page does not contain 'Ticket locked.'" # optional - default
    );

=cut

sub PageContainsNot {
    my ( $Self, %Param ) = @_;

    my $UnitTestMessage = $Param{Message};
    $UnitTestMessage ||= "Page does not contain '$Param{String}'";

    $Self->{UnitTestDriverObject}->False(
        index( $Self->get_page_source(), $Param{String} ) > -1,
        $UnitTestMessage,
    );
    return;
}

=head2 AJAXCompleted()

Waits for AJAX requests to be completed by checking the jQuery 'active' attribute.

    $SeleniumObject->AJAXCompleted();

=cut

sub AJAXCompleted {
    my ( $Self, %Param ) = @_;

    my $AJAXStartedLoading = $Self->WaitFor(
        JavaScript => 'return jQuery.active',
        SkipDie    => 1,
    );

    # The idea of this improvement is the following problem case:
    # A InputSet of the Znuny.Form.Input in a selenium test does trigger an ajax request
    # which is completed too fast for the "WaitFor" check above. So the "WaitFor" check jQuery.active
    # is not set to true and will crash the test completely. In these cases we want to disable
    # the die and the following checks and hope that the ajax request is done successfully.
    if ( !$AJAXStartedLoading ) {
        print STDERR "NOTICE: SeleniumHelper->AJAXCompleted -> jQuery.active check is disabled and failed\n";
        return 1;
    }

    $Self->{UnitTestDriverObject}->True(
        $AJAXStartedLoading,
        'AJAX requests started loading.'
    );

    my $AJAXCompletedLoading = $Self->WaitFor( JavaScript => 'return jQuery.active == 0' );
    $Self->{UnitTestDriverObject}->True(
        $AJAXCompletedLoading,
        'AJAX requests have finished loading.'
    );
    return;
}

=head2 AgentInterface()

Performs a GET request to the AgentInterface with the given parameters. Interally _GETInterface is called.

    $SeleniumObject->AgentInterface(
        Action      => 'AgentTicketZoom',
        WaitForAJAX => 0,                     # optional, default 1
    );

=cut

sub AgentInterface {
    my ( $Self, %Param ) = @_;

    return $Self->_GETInterface(
        Interface   => 'Agent',
        WaitForAJAX => delete $Param{WaitForAJAX},
        Param       => \%Param,
    );
}

=head2 AgentRequest()

Performs a GET request to a non-JavaScript controller in the AgentInterface with the given parameters. Interally _GETRequest is called.

    $SeleniumObject->AgentRequest(
        Action      => 'CustomerUserSearch',
        Param       => {
            Term => 'test-customer-user'
        }
    );

=cut

sub AgentRequest {
    my ( $Self, %Param ) = @_;

    return $Self->_GETRequest(
        Interface => 'Agent',
        Param     => \%Param,
    );
}

=head2 CustomerInterface()

Performs a GET request to the CustomerInterface with the given parameters. Interally _GETInterface is called.

    $SeleniumObject->CustomerInterface(
        Action      => 'CustomerTicketMessage',
        WaitForAJAX => 0,                      # optional, default 1
    );

=cut

sub CustomerInterface {
    my ( $Self, %Param ) = @_;

    return $Self->_GETInterface(
        Interface   => 'Customer',
        WaitForAJAX => delete $Param{WaitForAJAX},
        Param       => \%Param,
    );
}

=head2 CustomerRequest()

Performs a GET request to a non-JavaScript controller in the CustomerInterface with the given parameters. Interally _GETRequest is called.

    $SeleniumObject->CustomerRequest(
        Action      => 'CustomerUserSearch',
        Param       => {
            Term => 'test-customer-user'
        }
    );

=cut

sub CustomerRequest {
    my ( $Self, %Param ) = @_;

    return $Self->_GETRequest(
        Interface => 'Customer',
        Param     => \%Param,
    );
}

=head2 PublicInterface()

Performs a GET request to the PublicInterface with the given parameters. Interally _GETInterface is called.

    $SeleniumObject->PublicInterface(
        Action      => 'PublicFAQ',
        WaitForAJAX => 0,             # optional, default 1
    );

=cut

sub PublicInterface {
    my ( $Self, %Param ) = @_;

    return $Self->_GETInterface(
        Interface   => 'Public',
        WaitForAJAX => delete $Param{WaitForAJAX},
        Param       => \%Param,
    );
}

=head2 PublicRequest()

Performs a GET request to a non-JavaScript controller in the PublicInterface with the given parameters. Interally _GETRequest is called.

    $SeleniumObject->PublicRequest(
        Action      => 'PublicUserSearch',
        Param       => {
            Term => 'test-customer-user'
        }
    );

=cut

sub PublicRequest {
    my ( $Self, %Param ) = @_;

    return $Self->_GETRequest(
        Interface => 'Public',
        Param     => \%Param,
    );
}

=head2 _GETInterface()

Performs a GET request to the given Interface with the given parameters. Interally VerifiedGet is called.
Request waits till page has finished loading via checking if the jQuery Object has been initialized and
all AJAX requests are completed via function AJAXCompleted.

    $SeleniumObject->_GETInterface(
        Interface   => 'Agent',           # or Customer or Public
        WaitForAJAX => 0,                 # optional, default 1
        Param       => {                  # optional
            Action => AgentTicketZoom,
        }
    );

=cut

sub _GETInterface {
    my ( $Self, %Param ) = @_;

    my $RequestURL = $Self->RequestURLBuild(%Param);

    $Self->VerifiedGet($RequestURL);

    my $PageFinishedLoading = $Self->WaitFor( JavaScript => 'return typeof($) === "function"' );
    $Self->{UnitTestDriverObject}->True(
        $PageFinishedLoading,
        'Page has finished loading.'
    );

    if (
        defined $Param{WaitForAJAX}
        && !$Param{WaitForAJAX}
        )
    {
        return;
    }

    $Self->AJAXCompleted();
    return;
}

=head2 _GETRequest()

Performs a GET request to a Request endpoint in the given Interface with the given parameters. Interally Seleniums get is called.

    $SeleniumObject->_GETRequest(
        Interface   => 'Agent',           # or Customer or Public
        Param       => {                  # optional
            Action => AgentTicketZoom,
        }
    );

=cut

sub _GETRequest {
    my ( $Self, %Param ) = @_;

    my $RequestURL = $Self->RequestURLBuild(%Param);

    return $Self->get($RequestURL);
}

=head2 RequestURLBuild()

This function builds a requestable HTTP GET URL to the given OTRS interface with the given parameters

    my $RequestURL = $SeleniumObject->RequestURLBuild(
        Interface   => 'Agent',           # or Customer or Public
        Param       => {                  # optional
            Action => AgentTicketZoom,
        }
    );

    $RequestURL = 'http://localhost/otrs/index.pl?Action=AgentTicketZoom';

=cut

sub RequestURLBuild {
    my ( $Self, %Param ) = @_;

    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');

    # get script alias
    my $ScriptAlias = $ConfigObject->Get('ScriptAlias');

    my %InterfaceMapping = (
        Agent    => 'index',
        Customer => 'customer',
        Public   => 'public',
    );

    my $RequestURL = $ScriptAlias . $InterfaceMapping{ $Param{Interface} } . '.pl';

    return $RequestURL if !IsHashRefWithData( $Param{Param} );

    $RequestURL .= '?';
    $RequestURL .= $Self->_Hash2GETParamString( %{ $Param{Param} } );

    return $RequestURL;
}

=head2 _Hash2GETParamString()

Converts a Hash into a GET Parameter String, without the leading ?. Inspired by http://stackoverflow.com/a/449204

    my $Result = $SeleniumObject->_Hash2GETParamString(
        Action   => 'AgentTicketZoom',
        TicketID => 1,
    );

    my $Result = $SeleniumObject->_Hash2GETParamString(
        Action   => 'AgentTicketZoom',
        TicketID => \@TicketIDs,
    );

    $Result = 'Action=AgentTicketZoom;TicketID=1';

=cut

sub _Hash2GETParamString {
    my ( $Self, %Param ) = @_;
    my @Pairs;

    for my $Key ( sort keys %Param ) {

        if ( !IsArrayRefWithData( $Param{$Key} ) ) {
            $Param{$Key} = [ $Param{$Key} ];
        }

        for my $Value ( @{ $Param{$Key} } ) {
            push @Pairs, join '=', map { uri_escape($_) } $Key, $Value;
        }
    }
    return join ';', @Pairs;
}

=head2 FindElementSave()

This function is a wrapper around the 'find_element' function which can be used to check if elements are even present.

    my $Element = $SeleniumObject->FindElementSave(
        Selector     => '#GroupID',
        SelectorType => 'css',        # optional
    );

    is equivalent to:

    $Element = $Self->find_element('#GroupID', 'css');

=cut

sub FindElementSave {
    my ( $Self, %Param ) = @_;

    my $LogObject = $Kernel::OM->Get('Kernel::System::Log');

    # check needed stuff
    NEEDED:
    for my $Needed (qw(Selector)) {

        next NEEDED if defined $Param{$Needed};

        $LogObject->Log(
            Priority => 'error',
            Message  => "Parameter '$Needed' is needed!",
        );
        return;
    }
    $Param{SelectorType} ||= 'css';

    my $Element;
    eval {
        $Element = $Self->find_element( $Param{Selector}, $Param{SelectorType} );
    };

    return $Element;
}

=head2 ElementExists()

This function checks if a given element exists.

    $SeleniumObject->ElementExists(
        Selector     => '#GroupID',
        SelectorType => 'css',        # optional
    );

=cut

sub ElementExists {
    my ( $Self, %Param ) = @_;

    my $LogObject = $Kernel::OM->Get('Kernel::System::Log');

    # check needed stuff
    NEEDED:
    for my $Needed (qw(Selector)) {

        next NEEDED if defined $Param{$Needed};

        $LogObject->Log(
            Priority => 'error',
            Message  => "Parameter '$Needed' is needed!",
        );
        return;
    }
    $Param{Message} ||= "Element '$Param{Selector}' exists.";

    my $Element = $Self->FindElementSave(%Param);

    return $Self->{UnitTestDriverObject}->True(
        $Element,
        $Param{Message},
    );
}

=head2 ElementExistsNot()

This function checks if a given element does not exist.

    $SeleniumObject->ElementExistsNot(
        Selector     => '#GroupID',
        SelectorType => 'css',        # optional
    );

=cut

sub ElementExistsNot {
    my ( $Self, %Param ) = @_;

    my $LogObject = $Kernel::OM->Get('Kernel::System::Log');

    # check needed stuff
    NEEDED:
    for my $Needed (qw(Selector)) {

        next NEEDED if defined $Param{$Needed};

        $LogObject->Log(
            Priority => 'error',
            Message  => "Parameter '$Needed' is needed!",
        );
        return;
    }
    $Param{Message} ||= "Element '$Param{Selector}' does not exist.";

    my $Element = $Self->FindElementSave(%Param);

    return $Self->{UnitTestDriverObject}->False(
        $Element,
        $Param{Message},
    );
}

=head2 CreateScreenshot()

CreateScreenshot.

    my $Success = $SeleniumObject->CreateScreenshot();

Returns:

    my $Success = 1;

=cut

sub CreateScreenshot {
    my ( $Self, %Param ) = @_;

    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');
    my $MainObject   = $Kernel::OM->Get('Kernel::System::Main');
    my $HelperObject = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');

    # Don't create a test entry for the screenshot command,
    #   to make sure it gets attached to the previous error entry.
    local $Self->{SuppressCommandRecording} = 1;

    my $Filename            = $Self->GetScreenshotFileName(%Param);
    my %ScreenshotDirectory = $Self->GetScreenshotDirectory(%Param);
    my $ScreenshotURL       = $Self->GetScreenshotURL(
        %ScreenshotDirectory,
        Filename => $Filename
    );

    my $Data = $Self->screenshot();
    if ( !$Data ) {
        $Self->{UnitTestDriverObject}->False( 1, "Could not create a screenshot" );
    }
    $Data = MIME::Base64::decode_base64($Data);

    # Attach the screenshot to the actual error entry.
    $Self->{UnitTestDriverObject}->AttachSeleniumScreenshot(
        Filename => $Filename,
        Content  => $Data
    );

    $MainObject->FileWrite(
        Directory => $ScreenshotDirectory{FullPath},
        Filename  => $Filename,
        Content   => \$Data,
    ) || return $Self->False( 1, "Could not write file $ScreenshotDirectory{FullPath}/$Filename" );

    # Make sure the screenshot URL is output even in non-verbose mode to make it visible
    #   for debugging, but don't register it as a test failure to keep the error count more correct.
    local $Self->{UnitTestDriverObject}->{Verbose} = 1;
    $Self->{UnitTestDriverObject}->True( 1, "Saved screenshot in $ScreenshotURL" );

    return 1;
}

sub CaptureScreenshot {
    my ( $Self, $Hook, $Function ) = @_;

    # extract caller information:
    # - Package for checking direct calls and early exit
    # - Line of function call to be used in filename
    my ( $CallingPackage, $CallerFilename, $TestLine ) = caller(1);
    return if $CallingPackage ne 'Kernel::System::UnitTest::Driver';

    # taking a screenshot after the SeleniumObject
    # is destroyed is not possible
    return if ( $Function eq 'DESTROY' && $Hook eq 'AFTER' );

    # late object initialization for performance reasons
    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');

    # someone might want to enable local screenshots only if needed?
    return if $ConfigObject->Get('SeleniumTestsConfig')->{DisableScreenshots};

    my $ScreenshotFileName = $Self->GetScreenshotFileName(
        Line     => $TestLine,
        Function => $Function,
        Hook     => $Hook,
    );
    my %ScreenshotDirectory = $Self->GetScreenshotDirectory(
        Directory => 'Captured',
    );
    my $FilePath = $ScreenshotDirectory{FullPath} . '/' . $ScreenshotFileName;

    # finally take the screenshot via the Selenium API
    # and store it in to the build file path
    $Self->capture_screenshot($FilePath);

    return 1;
}

=head2 GetScreenshotFileName()

    my $ScreenshotFileName = $SeleniumObject->GetScreenshotFileName(
        Filename => 'ZnunyRocks',
        # or
        Line     => '359',
        Function => 'InputFieldID',
        Hook     => 'BEFORE',
    );

Returns:

    #                         TIME      - Path to Test       - Line   - Function   - BEFORE or AFTER function
    my $ScreenshotFileName = '1497085163-Znuny_Selenium_Input-Line=359-InputFieldID-BEFORE.png';


=cut

sub GetScreenshotFileName {
    my ( $Self, %Param ) = @_;

    my $DateTimeObject = $Kernel::OM->Create('Kernel::System::DateTime');

    # trying to extract the name of the test file right from the UnitTestObject
    # kind of hacky but there is no other place where to get this information
    my $TestFile = 'UnknownTestFile';

    if (
        $Self->{UnitTestDriverObject}->{TestFile}
        && $Self->{UnitTestDriverObject}->{TestFile} =~ m{scripts\/test\/(.+?)\.t$}
        )
    {
        $TestFile = $1;

        # make folder path a filename
        $TestFile =~ s{\/}{_}g;
    }

    my $ScreenshotFileName;

    if ( $Param{Filename} ) {
        $ScreenshotFileName = $Param{Filename};
    }
    else {

        # build filename to be most reasonable and easy to follow like e.g.:
        # 1497085163-Znuny_Selenium_Input-Line=359-InputFieldID-BEFORE.png

        my $SystemTime = $DateTimeObject->ToEpoch();
        $ScreenshotFileName = "$SystemTime-$TestFile";

        if ( $Param{Line} ) {
            $ScreenshotFileName .= "-Line=$Param{Line}";
        }

        if ( $Param{Function} ) {
            $ScreenshotFileName .= "-$Param{Function}";
        }

        if ( $Param{Hook} ) {
            $ScreenshotFileName .= "-$Param{Hook}";
        }
    }

    $ScreenshotFileName .= '.png';

    return $ScreenshotFileName;
}

=head2 GetScreenshotDirectory()

    my %ScreenshotDirectory = $SeleniumObject->GetScreenshotDirectory(
        Directory => 'Captured',
    );

Returns:

    my %ScreenshotDirectory = (
        WebPath  => 'SeleniumScreenshots/Captured',
        FullPath => '/opt/otrs/var/httpd/htdocs/SeleniumScreenshots/Captured',
    );

=cut

sub GetScreenshotDirectory {
    my ( $Self, %Param ) = @_;

    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');

    my %ScreenshotDirectory;

    # Store screenshots in a local folder from where they can be opened directly in the browser.
    my $FullPath = $ConfigObject->Get('Home');

    # use CI project directory so the CI env can collect the artifacts afterwards
    if ( $ENV{CI_PROJECT_DIR} ) {
        $FullPath = $ENV{CI_PROJECT_DIR} . '/';
    }

    $FullPath .= '/var/httpd/htdocs/';
    $FullPath .= $Self->{SeleniumScreenshotsDirectory};

    my $WebPath = $ConfigObject->Get('Frontend::WebPath');
    $WebPath .= $Self->{SeleniumScreenshotsDirectory};

    if ( $Param{Directory} ) {
        $FullPath .= '/' . $Param{Directory};
        $WebPath  .= '/' . $Param{Directory};
    }

    mkpath $FullPath || return $Self->False( 1, "Could not create $FullPath." );
    %ScreenshotDirectory = (
        FullPath => $FullPath,
        WebPath  => $WebPath,
    );

    return %ScreenshotDirectory;
}

=head2 GetScreenshotURL()

    my $ScreenshotURL = $SeleniumObject->GetScreenshotURL(
        WebPath  = '/otrs-web/SeleniumScreenshots/ZnunyRocks/',
        Filename = 'AgentTicketZoom',
    );

Returns:

    my $ScreenshotURL = 'URL';

=cut

sub GetScreenshotURL {
    my ( $Self, %Param ) = @_;

    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');
    my $HelperObject = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');

    my $HttpType = $ConfigObject->Get('HttpType');
    my $Hostname = $HelperObject->GetTestHTTPHostname();
    my $URL      = "$HttpType://$Hostname" . "$Param{WebPath}/$Param{Filename}";

    return $URL;
}

=head2 GetSeleniumHome()

    my $SeleniumHome = $SeleniumObject->GetSeleniumHome(
        Directory => '/opt/otrs',
    );

Returns:

    my $SeleniumHome = '/opt/otrs';

=cut

sub GetSeleniumHome {
    my ( $Self, %Param ) = @_;

    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');

    my $SeleniumHome = $ConfigObject->Get('Home');

    # use custom directory
    if ( $Param{Directory} ) {
        $SeleniumHome = $Param{Directory};
    }

    # use CI project directory to use the uploaded artifacts for tests
    elsif ( $ENV{CI_PROJECT_DIR} ) {
        $SeleniumHome = $ENV{CI_PROJECT_DIR} . '/';
    }

    return $SeleniumHome;
}

# strongly inspired by: https://stackoverflow.com/a/2663723/7900866
if ( $ENV{SELENIUM_SCREENSHOTS} ) {
    my $ConfigObject      = $Kernel::OM->Get('Kernel::Config');
    my @FunctionBlacklist = ( 'CaptureScreenshot', 'RunTest', 'AJAXCompleted', 'Dumper' );

    my @FunctionWhitelist = map {    ## no critic
        s/^\s+//;                    # strip leading spaces
        s/\s+$//;                    # strip trailing spaces
        $_                           # return the modified string
    } split( ',', $ENV{SELENIUM_SCREENSHOTS_FUNCTIONS} || '' );

    # wonder if we can get away without 'no strict'? Hate doing that!
    no strict;                       ## no critic
    no warnings;                     ## no critic

    # iterate over symbol table of the package
    FUNCTION:
    for my $FunctionName ( sort keys %Kernel::System::UnitTest::Selenium:: ) {

        # only subroutines needed
        next FUNCTION if !defined *{ $Kernel::System::UnitTest::Selenium::{$FunctionName} }{CODE};

        # skip blacklisted functions
        next FUNCTION if grep { $FunctionName eq $_ } @FunctionBlacklist;

        # capture all if the full monty is requested
        if (@FunctionWhitelist) {

            # skip if whitelist is defined but function not whitelisted
            next FUNCTION if !grep { $FunctionName eq $_ } @FunctionWhitelist;
        }

        # skip internal and imported functions
        next FUNCTION if $FunctionName =~ /^_/;
        next FUNCTION if $FunctionName !~ /^[[:upper:]]/;
        next FUNCTION if $FunctionName =~ /^Is[[:upper:]]/;

        # build full and backup function name
        my $FullName   = "Kernel::System::UnitTest::Selenium::$FunctionName";
        my $BackupName = "Kernel::System::UnitTest::Selenium::___OLD_$FunctionName";

        # save original sub reference
        *{$BackupName} = \&{$FullName};

        # overwrite original with screenshot hook version
        *{$FullName} = sub {

            # take screenshot before the original function gets executed
            CaptureScreenshot( $_[0], 'BEFORE', $FunctionName );

            # call the original function and store
            # the response in the matching variable type
            my $Result;
            if (wantarray) {
                $Result = [ &{$BackupName}(@_) ];
            }
            else {
                $Result = &{$BackupName}(@_);
            }

            # take screenshot before the original function gets executed
            CaptureScreenshot( $_[0], 'AFTER', $FunctionName );

            # return whatever was expected to get returned
            return ( wantarray && ref $Result eq 'ARRAY' )
                ? @$Result : $Result;
        };
    }
    use strict;
    use warnings;
}

1;

=head1 TERMS AND CONDITIONS

This software is part of the OTRS project (L<https://otrs.org/>).

This software comes with ABSOLUTELY NO WARRANTY. For details, see
the enclosed file COPYING for license information (GPL). If you
did not receive this file, see L<https://www.gnu.org/licenses/gpl-3.0.txt>.

=cut
