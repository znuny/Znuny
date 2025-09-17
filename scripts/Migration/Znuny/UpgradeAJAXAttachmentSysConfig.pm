# --
# Copyright (C) 2021 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package scripts::Migration::Znuny::UpgradeAJAXAttachmentSysConfig;    ## no critic

use strict;
use warnings;
use utf8;

use parent qw(scripts::Migration::Base);

our @ObjectDependencies = (
    'Kernel::System::DB',
);

=head1 SYNOPSIS

Alter old entry to avoid conflicts with MariaDB
from 'Frontend::Module###AjaxAttachment'            to  'Frontend::Module###AJAXAttachment'
from 'CustomerFrontend::Module###AjaxAttachment'    to  'CustomerFrontend::Module###AJAXAttachment'


=cut

sub Run {
    my ( $Self, %Param ) = @_;

    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    return if !$DBObject->Prepare(
        SQL => "
            UPDATE sysconfig_default
            SET    name='Frontend::Module###AJAXAttachment'
            WHERE  name='Frontend::Module###AjaxAttachment'
        ",
    );

    return if !$DBObject->Prepare(
        SQL => "
            UPDATE sysconfig_default
            SET    name='CustomerFrontend::Module###AJAXAttachment'
            WHERE  name='CustomerFrontend::Module###AjaxAttachment'
        ",
    );

    return 1;
}

1;
