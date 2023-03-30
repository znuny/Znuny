# --
# Copyright (C) 2001-2021 OTRS AG, https://otrs.com/
# Copyright (C) 2021 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see https://www.gnu.org/licenses/gpl-3.0.txt.
# --

package Kernel::Output::HTML::ArticleAttachment::HTMLViewer;

use parent 'Kernel::Output::HTML::Base';

use strict;
use warnings;

our @ObjectDependencies = (
    'Kernel::Config',
    'Kernel::Output::HTML::Layout',
    'Kernel::System::Log',
);

sub Run {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Needed (qw(File Article)) {
        if ( !$Param{$Needed} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Needed!"
            );
            return;
        }
    }

    # get config object
    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');

    # check if config exists
    if ( $ConfigObject->Get('MIME-Viewer') ) {
        for my $Key ( sort keys %{ $ConfigObject->Get('MIME-Viewer') } ) {
            if ( $Param{File}->{ContentType} =~ /^$Key/i ) {
                return (
                    %{ $Param{File} },
                    Action => 'Viewer',
                    Link   => $Kernel::OM->Get('Kernel::Output::HTML::Layout')->{Baselink} .
                        "Action=AgentTicketAttachment;TicketID=$Param{Article}->{TicketID};ArticleID=$Param{Article}->{ArticleID};FileID=$Param{File}->{FileID};Viewer=1",
                    Target => 'target="attachment"',
                    Class  => 'ViewAttachment',
                );
            }
        }
    }
    return ();
}

1;
