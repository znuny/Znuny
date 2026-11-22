# --
# Copyright (C) 2021 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --
## nofilter(TidyAll::Plugin::Znuny::Perl::Pod::NamePod)

package scripts::Migration::Znuny::RemoveReusedArticleFileIDsDynamicField;    ## no critic

use strict;
use warnings;
use utf8;

use parent qw(scripts::Migration::Base);

use Kernel::System::VariableCheck qw(:all);

our @ObjectDependencies = (
    'Kernel::System::DynamicField',
    'Kernel::System::ZnunyHelper',
);

=head1 SYNOPSIS

Removes the leftover article dynamic field ReusedArticleFileIDs. Attachment reuse is now
passed as ArticleID/FileID references in the Attachment parameter of ArticleCreate/ArticleSend.

=cut

sub Run {
    my ( $Self, %Param ) = @_;

    my $DynamicFieldObject = $Kernel::OM->Get('Kernel::System::DynamicField');
    my $ZnunyHelperObject  = $Kernel::OM->Get('Kernel::System::ZnunyHelper');

    my $DynamicFieldConfig = $DynamicFieldObject->DynamicFieldGet(
        Name => 'ReusedArticleFileIDs',
    );
    return 1 if !IsHashRefWithData($DynamicFieldConfig);

    my %DynamicFields = (
        ReusedArticleFileIDs => 1,
    );
    my %Screens = (
        AgentTicketClose         => \%DynamicFields,
        AgentTicketCompose       => \%DynamicFields,
        AgentTicketEmailOutbound => \%DynamicFields,
        AgentTicketForward       => \%DynamicFields,
        AgentTicketNote          => \%DynamicFields,
        AgentTicketOwner         => \%DynamicFields,
        AgentTicketPending       => \%DynamicFields,
        AgentTicketPhoneInbound  => \%DynamicFields,
        AgentTicketPhoneOutbound => \%DynamicFields,
    );

    $ZnunyHelperObject->_DynamicFieldsScreenDisable(%Screens);
    $ZnunyHelperObject->_DynamicFieldsDelete('ReusedArticleFileIDs');

    return 1;
}

1;
