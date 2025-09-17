# --
# Copyright (C) 2021 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::Output::HTML::NavBar::AgentTicketProcessCategory;

use parent 'Kernel::Output::HTML::Base';

use strict;
use warnings;
use utf8;

use Kernel::System::VariableCheck qw(:all);

our @ObjectDependencies = (
    'Kernel::Config',
    'Kernel::System::Cache',
    'Kernel::System::Ticket',
    'Kernel::System::ProcessManagement::Process',
);

sub Run {
    my ( $Self, %Param ) = @_;

    my $ConfigObject  = $Kernel::OM->Get('Kernel::Config');
    my $CacheObject   = $Kernel::OM->Get('Kernel::System::Cache');
    my $TicketObject  = $Kernel::OM->Get('Kernel::System::Ticket');
    my $ProcessObject = $Kernel::OM->Get('Kernel::System::ProcessManagement::Process');

    # get Frontend configuration
    my $FrontendModuleConfig     = $ConfigObject->Get('Frontend::Module')->{AgentTicketProcessCategory};
    my $FrontendNavigationConfig = $ConfigObject->Get('Frontend::Navigation')->{AgentTicketProcessCategory};

    # check if the registration config is valid
    return if !IsHashRefWithData($FrontendModuleConfig);
    return if !IsHashRefWithData($FrontendNavigationConfig);
    return if !IsArrayRefWithData( $FrontendNavigationConfig->{'001-ProcessManagement'} );

    my $NameForID     = $FrontendNavigationConfig->{'001-ProcessManagement'}->[0]->{Name};
    my $NameForHidden = $NameForID;
    $NameForID =~ s{[ &;]}{}ig;

    # check if the module name is valid
    return if !$NameForID;

    my $DisplayMenuItem;

    # check the cache
    my $CacheKey = 'ProcessManagement::AgentTicketProcessCategory::UserID' . $Self->{UserID} . '::DisplayMenuItem';
    my $Cache    = $CacheObject->Get(
        Type => 'ProcessManagement_Process',
        Key  => $CacheKey,
    );

    # set the cache value to show or hide the menu item (if value exists)
    if ( $Cache && ref $Cache eq 'SCALAR' ) {
        $DisplayMenuItem = ${$Cache};

        # return nothing to display the menu item
        return if $DisplayMenuItem;
    }

    # otherwise determine the value by queering the process object
    $DisplayMenuItem = 0;
    my $Processes = $ConfigObject->Get('Process');

    # avoid error messages when there is no processes and call ProcessList
    if ( IsHashRefWithData($Processes) ) {

        # get process list
        my $ProcessList = $ProcessObject->ProcessList(
            ProcessState => ['Active'],
            Interface    => ['AgentInterface'],
        );

        # prepare process list for ACLs, use only entities instead of names, convert from
        #   P1 => Name to P1 => P1. As ACLs should work only against entities
        my %ProcessListACL = map { $_ => $_ } sort keys %{$ProcessList};

        # validate the ProcessList with stored ACLs
        my $ACL = $TicketObject->TicketAcl(
            ReturnType    => 'Process',
            ReturnSubType => '-',
            Data          => \%ProcessListACL,
            UserID        => $Self->{UserID},
        );

        if ( IsHashRefWithData($ProcessList) && $ACL ) {

            # get ACL results
            my %ACLData = $TicketObject->TicketAclData();

            # recover process names
            my %ReducedProcessList = map { $_ => $ProcessList->{$_} } sort keys %ACLData;

            # replace original process list with the reduced one
            $ProcessList = \%ReducedProcessList;
        }

        my @Category = grep { $Processes->{$_}->{Category} } sort keys %{$Processes};

        # set the value to show or hide the menu item (based in process list)
        if ( IsHashRefWithData($ProcessList) && @Category ) {
            $DisplayMenuItem = 1;
        }
    }

    # get the cache TTL (in seconds)
    my $CacheTTL = int( $ConfigObject->Get('Process::NavBar::CacheTTL') || 900 );

    # set cache
    $CacheObject->Set(
        Type  => 'ProcessManagement_Process',
        Key   => $CacheKey,
        Value => \$DisplayMenuItem,
        TTL   => $CacheTTL,
    );

    # return nothing to display the menu item
    return if $DisplayMenuItem;

    # frontend module is enabled but there is no selectable process, then remove the menu entry
    my $NavBarName = $FrontendModuleConfig->{NavBarName};
    my $Priority   = sprintf( '%07d', $FrontendNavigationConfig->{'001-ProcessManagement'}->[0]->{Prio} );

    my %Return = %{ $Param{NavBar}->{Sub} || {} };

    # remove AgentTicketProcess from the TicketMenu
    delete $Return{$NavBarName}->{$Priority};

    return ( Sub => \%Return );
}

1;
