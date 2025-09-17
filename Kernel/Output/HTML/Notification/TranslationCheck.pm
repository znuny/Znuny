# --
# Copyright (C) 2021 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::Output::HTML::Notification::TranslationCheck;

use strict;
use warnings;
use utf8;

use Kernel::System::ObjectManager;

our @ObjectDependencies = (
    'Kernel::Output::HTML::Layout',
    'Kernel::System::Cache',
    'Kernel::System::Log',
    'Kernel::System::Translation',
);

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {};
    bless( $Self, $Type );

    return $Self;
}

sub Run {
    my ( $Self, %Param ) = @_;

    my $LayoutObject      = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $LogObject         = $Kernel::OM->Get('Kernel::System::Log');
    my $TranslationObject = $Kernel::OM->Get('Kernel::System::Translation');
    my $CacheObject       = $Kernel::OM->Get('Kernel::System::Cache');

    my @Data = $TranslationObject->DataListGet(
        ValidID         => 1,
        DeploymentState => 0,
        UserID          => $LayoutObject->{UserID},
    );

    my $Deleted = $CacheObject->Get(
        Type => 'TranslationDeployment',
        Key  => 'Deleted',
    );

    return '' if $LayoutObject->{Action} ne 'AdminTranslation';
    return '' if !@Data && !$Deleted;

    my $Message = $LayoutObject->{LanguageObject}
        ->Translate("The translations in the database are not synchronous. Please synchronize all translations.");

    return $LayoutObject->Notify(
        Info => $Message,
        Link => $LayoutObject->{Baselink} . 'Action=AdminTranslation;Subaction=DeploymentAction;ID=1',
    );
}

1;
