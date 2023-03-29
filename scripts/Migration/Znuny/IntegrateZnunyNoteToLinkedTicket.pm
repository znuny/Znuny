# --
# Copyright (C) 2021 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --
## nofilter(TidyAll::Plugin::Znuny::Perl::Pod::NamePod)

package scripts::Migration::Znuny::IntegrateZnunyNoteToLinkedTicket;    ## no critic

use strict;
use warnings;
use IO::Interactive qw(is_interactive);
use Kernel::System::VariableCheck qw(:all);

use parent qw(scripts::Migration::Base);

our @ObjectDependencies = (
    'Kernel::Config',
    'Kernel::System::SysConfig',
);

=head1 SYNOPSIS

Migrates SysConfig settings.

=cut

sub Run {
    my ( $Self, %Param ) = @_;

    return if !$Self->_ArticleActionConfigAdd(%Param);

    return 1;
}

sub _ArticleActionConfigAdd {
    my ( $Self, %Param ) = @_;

    my $ConfigObject    = $Kernel::OM->Get('Kernel::Config');
    my $SysConfigObject = $Kernel::OM->Get('Kernel::System::SysConfig');

    my @ArticleActionConfig;
    my $ArticleActionConfig = $ConfigObject->Get('Ticket::Frontend::Article::Actions') // {};

    for my $Channel ( sort keys %{$ArticleActionConfig} ) {
        $ArticleActionConfig->{$Channel}->{AgentTicketNoteToLinkedTicket} = {
            Module => 'Kernel::Output::HTML::ArticleAction::AgentTicketNoteToLinkedTicket',
            Prio   => 50,
            Valid  => 1,
        };

        push @ArticleActionConfig, {
            Name           => 'Ticket::Frontend::Article::Actions###' . $Channel,
            EffectiveValue => $ArticleActionConfig->{$Channel},
        };
    }

    my $SettingsSet = $SysConfigObject->SettingsSet(
        UserID   => 1,
        Comments => 'Adding article actions for package Znuny-NoteToLinkedTicket.',
        Settings => \@ArticleActionConfig,
    );
    return if !$SettingsSet;

    return 1;
}

1;
