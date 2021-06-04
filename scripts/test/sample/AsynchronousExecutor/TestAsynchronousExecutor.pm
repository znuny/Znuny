# --
# Copyright (C) 2001-2021 OTRS AG, https://otrs.com/
# Copyright (C) 2021 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see https://www.gnu.org/licenses/gpl-3.0.txt.
# --

package scripts::test::sample::AsynchronousExecutor::TestAsynchronousExecutor;

use strict;
use warnings;

use parent qw(Kernel::System::AsynchronousExecutor);

our @ObjectDependencies = ();

=head1 NAME

scripts::test::sample::AsynchronousExecutor::TestAsynchronousExecutor - sample of a module with AsynchronousExecutor base class

=head1 SYNOPSIS

=head1 PUBLIC INTERFACE

=over 4

=cut

=item new()

    use Kernel::System::ObjectManager;
    local $Kernel::OM = Kernel::System::ObjectManager->new();

    my $ModuleObject = $Kernel::OM->Get('scripts::test::sample::AsynchronousExecutor::TestAsynchronousExecutor');

=cut

sub new {
    my ( $Type, %Param ) = @_;

    my $Self = {};
    bless( $Self, $Type );

    return $Self;
}

=item Execute()

performs the selected test task.

    my $Success = $TaskHandlerObject->Execute(
        File    => $Filename,        # optional, create file $FileName
        Success => 1,                # 0 or 1, controls return value
    );

Returns:

    $Success = 1    # or fail in case of an error

=cut

sub Execute {
    my ( $Self, %Param ) = @_;

    # create temporary file
    if ( $Param{File} ) {
        my $Content = 123;
        return if !$Self->_FileWrite(
            Location => $Param{File},
            Content  => \$Content,
        );
    }

    return $Param{Success};
}

sub ExecuteAsyc {
    my ( $Self, %Param ) = @_;

    # create a new task for the scheduler daemon
    $Self->AsyncCall(
        FunctionName             => 'Execute',
        FunctionParams           => \%Param,
        Attempts                 => 3,
        MaximumParallelInstances => 1,
    );

    return 1;
}

sub ExecuteAsycWithObjectName {
    my ( $Self, %Param ) = @_;

    # create a new task for the scheduler daemon
    $Self->AsyncCall(
        ObjectName               => 'scripts::test::sample::AsynchronousExecutor::TestAsynchronousExecutor',
        FunctionName             => 'Execute',
        FunctionParams           => \%Param,
        Attempts                 => 3,
        MaximumParallelInstances => 1,
    );

    return 1;
}

sub _FileWrite {
    my ( $Self, %Param ) = @_;

    if ( !$Param{Location} ) {
        print STDERR "Need Location!\n";
        return;
    }

    # filename clean up
    $Param{Location} =~ s/\/\//\//g;

    # set open mode (if file exists, lock it on open, done by '+<')
    my $Exists;
    if ( -f $Param{Location} ) {
        $Exists = 1;
    }
    my $Mode = '>';
    if ($Exists) {
        $Mode = '+<';
    }
    if ( $Param{Mode} && $Param{Mode} =~ /^(utf8|utf\-8)/i ) {
        $Mode = '>:utf8';
        if ($Exists) {
            $Mode = '+<:utf8';
        }
    }

    # return if file can not open
    my $FH;
    if ( !open $FH, $Mode, $Param{Location} ) {    ## no critic
        print STDERR "Can't write '$Param{Location}': $!",
            return;
    }

    # lock file (Exclusive Lock)
    if ( !flock $FH, 2 ) {
        print STDERR "Can't lock '$Param{Location}': $!";
    }

    # empty file first (needed if file is open by '+<')
    truncate $FH, 0;

    # write file if content is not undef
    if ( defined ${ $Param{Content} } ) {
        print $FH ${ $Param{Content} };
    }

    # write empty file if content is undef
    else {
        print $FH '';
    }

    # close the file handle
    close $FH;

    return $Param{Location};
}

1;

=back

=head1 TERMS AND CONDITIONS

This software is part of the OTRS project (L<https://otrs.org/>).

This software comes with ABSOLUTELY NO WARRANTY. For details, see
the enclosed file COPYING for license information (GPL). If you
did not receive this file, see L<https://www.gnu.org/licenses/gpl-3.0.txt>.

=cut
