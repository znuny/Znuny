# --
# Copyright (C) 2021-2022 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --
## nofilter(TidyAll::Plugin::OTRS::Perl::Pod::NamePod)

package scripts::Migration::Znuny::ReindexSMIMECertificates;    ## no critic

use strict;
use warnings;

use parent qw(scripts::Migration::Base);

our @ObjectDependencies = (
    'Kernel::Config',
    'Kernel::System::Crypt::SMIME',
);

=head1 SYNOPSIS

Reindexes S/MIME certificates so that these are available after initial upgrade/setup instead
of having to wait for the cron task ReindexSMIMECertificates.
Also see Kernel::System::Console::Command::Maint::SMIME::ReindexKeys.

=head1 PUBLIC INTERFACE

=cut

sub Run {
    my ( $Self, %Param ) = @_;

    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');
    my $CryptObject  = $Kernel::OM->Get('Kernel::System::Crypt::SMIME');

    return 1 if !$ConfigObject->Get('SMIME');

    my $ReIndexCertificate = $CryptObject->ReIndexCertificate( CanReHash => 1 );
    my $ReIndexPrivate     = $CryptObject->ReIndexPrivate( CanNormalize => 1 );

    print "    Public: " . $ReIndexCertificate->{Details};
    print "\n    Private: " . $ReIndexPrivate->{Details} . "\n";

    return 1;
}

1;
