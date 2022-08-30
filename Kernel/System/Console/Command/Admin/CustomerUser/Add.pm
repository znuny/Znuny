# --
# Copyright (C) 2001-2021 OTRS AG, https://otrs.com/
# Copyright (C) 2021-2022 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see https://www.gnu.org/licenses/gpl-3.0.txt.
# --

package Kernel::System::Console::Command::Admin::CustomerUser::Add;

use strict;
use warnings;

use parent qw(Kernel::System::Console::BaseCommand);

our @ObjectDependencies = (
    'Kernel::System::CustomerUser',
);

sub Configure {
    my ( $Self, %Param ) = @_;

    $Self->Description('Add a customer user.');
    $Self->AddOption(
        Name        => 'user-name',
        Description => "User name for the new customer user.",
        Required    => 1,
        HasValue    => 1,
        ValueRegex  => qr/.*/smx,
    );
    $Self->AddOption(
        Name        => 'first-name',
        Description => "First name of the new customer user.",
        Required    => 1,
        HasValue    => 1,
        ValueRegex  => qr/.*/smx,
    );
    $Self->AddOption(
        Name        => 'last-name',
        Description => "Last name of the new customer user.",
        Required    => 1,
        HasValue    => 1,
        ValueRegex  => qr/.*/smx,
    );
    $Self->AddOption(
        Name        => 'email-address',
        Description => "Email address of the new customer user.",
        Required    => 1,
        HasValue    => 1,
        ValueRegex  => qr/.*/smx,
    );
    $Self->AddOption(
        Name        => 'customer-id',
        Description => "Customer ID for the new customer user.",
        Required    => 1,
        HasValue    => 1,
        ValueRegex  => qr/.*/smx,
    );
    $Self->AddOption(
        Name        => 'password',
        Description => "Password for the new customer user. If left empty, a password will be generated automatically.",
        Required    => 0,
        HasValue    => 1,
        ValueRegex  => qr/.*/smx,
    );

    return;
}

sub Run {
    my ( $Self, %Param ) = @_;

    $Self->Print("<yellow>Adding a new customer user...</yellow>\n");

    # add customer user
    if (
        !$Kernel::OM->Get('Kernel::System::CustomerUser')->CustomerUserAdd(
            Source         => 'CustomerUser',
            UserLogin      => $Self->GetOption('user-name'),
            UserFirstname  => $Self->GetOption('first-name'),
            UserLastname   => $Self->GetOption('last-name'),
            UserCustomerID => $Self->GetOption('customer-id'),
            UserPassword   => $Self->GetOption('password'),
            UserEmail      => $Self->GetOption('email-address'),
            UserID         => 1,
            ChangeUserID   => 1,
            ValidID        => 1,
        )
        )
    {
        $Self->PrintError("Can't add customer user.");
        return $Self->ExitCodeError();
    }

    $Self->Print("<green>Done.</green>\n");
    return $Self->ExitCodeOk();
}

1;
