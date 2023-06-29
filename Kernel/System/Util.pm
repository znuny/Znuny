# --
# Copyright (C) 2021 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --
## nofilter(TidyAll::Plugin::Znuny::Perl::LayoutObject)

package Kernel::System::Util;

use strict;
use warnings;

use MIME::Base64;

use Kernel::System::VariableCheck qw(:all);

our @ObjectDependencies = (
    'Kernel::Config',
    'Kernel::Output::HTML::Layout',
    'Kernel::System::Main',
);

=head1 NAME

Kernel::System::Util

=head1 DESCRIPTION

All Util functions.

=head1 PUBLIC INTERFACE

=head2 new()

Create an object. Do not use it directly, instead use:

    use Kernel::System::ObjectManager;
    local $Kernel::OM = Kernel::System::ObjectManager->new();
    my $UtilObject = $Kernel::OM->Get('Kernel::System::Util');

=cut

sub new {
    my ( $Type, %Param ) = @_;

    my $Self = \%Param;
    bless( $Self, $Type );

    return $Self;
}

=head2 IsITSMInstalled()

Checks if ITSM is installed.

    my $IsITSMInstalled = $UtilObject->IsITSMInstalled();

    Returns 1 if ITSM is installed and 0 otherwise.

=cut

sub IsITSMInstalled {
    my ( $Self, %Param ) = @_;

    # Use cached result because it won't change within the process.
    return $Self->{ITSMInstalled} if defined $Self->{ITSMInstalled};

    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');

    # Just use some arbitrary ITSM::Core SysConfig option to check if ITSM is present.
    $Self->{ITSMInstalled} = $ConfigObject->Get('Frontend::Module')->{AdminITSMCIPAllocate} ? 1 : 0;

    return $Self->{ITSMInstalled};
}

=head2 IsITSMIncidentProblemManagementInstalled()

Checks if ITSMIncidentProblemManagement is installed.

    my $IsITSMIncidentProblemManagementInstalled = $UtilObject->IsITSMIncidentProblemManagementInstalled();

    Returns 1 if ITSMIncidentProblemManagement is installed and 0 otherwise.

=cut

sub IsITSMIncidentProblemManagementInstalled {
    my ( $Self, %Param ) = @_;

    # Use cached result because it won't change within the process.
    return $Self->{ITSMIncidentProblemManagementInstalled} if defined $Self->{ITSMIncidentProblemManagementInstalled};

    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');

    # Just use some arbitrary SysConfig option to check if IncidentProblemManagement is present.
    $Self->{ITSMIncidentProblemManagementInstalled}
        = $ConfigObject->Get('Frontend::Module')->{AgentITSMIncidentProblemManagement} ? 1 : 0;

    return $Self->{ITSMIncidentProblemManagementInstalled};
}

=head2 IsFrontendContext()

Checks if current code is being executed in frontend context, e.g. agent frontend.

    my $IsFrontendContext = $UtilObject->IsFrontendContext();

    Returns 1 if current code is being executed in frontend context.
    Returns 0 if otherwise (e.g. console command context).

=cut

sub IsFrontendContext {
    my ( $Self, %Param ) = @_;

    # Note that "exists" is required. Otherwise Perl will create the key
    # with an undefined value which causes crashes since the object manager
    # won't work properly anymore.
    return if !exists $Kernel::OM->{Objects}->{'Kernel::Output::HTML::Layout'};

    my $LayoutObject = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    return if !$LayoutObject->{Action};

    return 1;
}

=head2 Base64DeepEncode()

    Base-64 encodes elements of given data for given keys.
    If data is an array, all of its child elements will be checked for given keys whose elements
    will be encoded recursively.

    my $Base64EncodedData = $UtilObject->Base64DeepEncode(
        # Data can be a scalar, hash or array
        Data => {
            Article => {
                # ...
            },
            # ...
        },
        HashKeys => [
            # All 'Body' elements of array $Hash->{Articles} will be base-64 encoded.
            # Also can mean: $Hash->{Articles}->{Body}, if 'Articles' is a hash.
            # Will encode nothing if last key ('Body') cannot be reached or is not a scalar/string.
            'Articles->Body',

            'QueueData->Comment',
            # ...
        ],
    );

=cut

sub Base64DeepEncode {
    my ( $Self, %Param ) = @_;

    if ( !ref $Param{Data} ) {
        return encode_base64( $Param{Data} // '' );
    }
    elsif ( ref $Param{Data} eq 'ARRAY' ) {
        for my $Element ( @{ $Param{Data} } ) {
            $Element = $Self->Base64DeepEncode(
                Data     => $Element,
                HashKeys => $Param{HashKeys},
            );
        }
    }
    elsif ( ref $Param{Data} eq 'HASH' ) {
        return $Param{Data} if !IsArrayRefWithData( $Param{HashKeys} );

        NESTEDHASHKEYS:
        for my $NestedHashKeys ( @{ $Param{HashKeys} } ) {
            my @HashKeys = split '->', $NestedHashKeys;
            while (@HashKeys) {
                my $HashKey = shift @HashKeys;

                next NESTEDHASHKEYS if !exists $Param{Data}->{$HashKey};

                $Param{Data}->{$HashKey} = $Self->Base64DeepEncode(
                    Data     => $Param{Data}->{$HashKey},
                    HashKeys => [
                        ( join '->', @HashKeys ),
                    ],
                );
            }
        }
    }

    return $Param{Data};
}

=head2 DataStructureRemoveElements()

    Removes elements of given data for given keys.
    If data is an array, all of its child elements will be checked for given keys whose elements
    will be removed recursively.

    my $Data = $UtilObject->DataStructureRemoveElements(
        # Data can be a scalar, hash or array
        Data => {
            Article => {
                # ...
            },
            # ...
        },
        HashKeys => [
            # All 'Body' elements of array $Hash->{Articles} will be removed.
            # Also can mean: $Hash->{Articles}->{Body}, if 'Articles' is a hash.
            # Will remove nothing if last key ('Body') cannot be reached or is not a scalar/string.
            'Articles->Body',

            'QueueData->Comment',
            # ...
        ],
    );

=cut

sub DataStructureRemoveElements {
    my ( $Self, %Param ) = @_;

    if ( ref $Param{Data} eq 'ARRAY' ) {
        for my $Element ( @{ $Param{Data} } ) {
            $Element = $Self->DataStructureRemoveElements(
                Data     => $Element,
                HashKeys => $Param{HashKeys},
            );
        }
    }
    elsif ( ref $Param{Data} eq 'HASH' ) {
        return $Param{Data} if !IsArrayRefWithData( $Param{HashKeys} );

        NESTEDHASHKEYS:
        for my $NestedHashKeys ( @{ $Param{HashKeys} } ) {
            my @HashKeys = split '->', $NestedHashKeys;
            while (@HashKeys) {
                my $HashKey = shift @HashKeys;

                next NESTEDHASHKEYS if !exists $Param{Data}->{$HashKey};

                # If last key, remove entire element.
                if ( !@HashKeys ) {
                    delete $Param{Data}->{$HashKey};
                    next NESTEDHASHKEYS;
                }

                $Param{Data}->{$HashKey} = $Self->DataStructureRemoveElements(
                    Data     => $Param{Data}->{$HashKey},
                    HashKeys => [
                        ( join '->', @HashKeys ),
                    ],
                );
            }
        }
    }

    return $Param{Data};
}

=head2 GetInstalledDBCRUDObjects()

    Returns installed DBCRUD objects.

    my $DBCRUDObjects = $UtilObject->GetInstalledDBCRUDObjects();

    Returns:
    my $DBCRUDObjects = [
        # DBCRUD objects as returned by $Kernel::OM->Get('Kernel::System::...')
    ];

=cut

sub GetInstalledDBCRUDObjects {
    my ( $Self, %Param ) = @_;

    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');
    my $MainObject   = $Kernel::OM->Get('Kernel::System::Main');

    my $KernelSystemPath = $ConfigObject->Get('Home') . '/Kernel/System';

    my @FilePaths = $MainObject->DirectoryRead(
        Directory => $KernelSystemPath,
        Filter    => '*.pm',
        Recursive => 1,
    );

    my @DBCRUDObjects;

    FILEPATH:
    for my $FilePath (@FilePaths) {
        my $FileContentRef = $MainObject->FileRead(
            Location => $FilePath,
        );
        next FILEPATH if ref $FileContentRef ne 'SCALAR';
        next FILEPATH if ${$FileContentRef} !~ m{^use parent\b.*?\bKernel::System::DBCRUD\b}m;

        next FILEPATH if ${$FileContentRef} !~ m{^package (.*?);$}m;
        my $DBCRUDPackage = $1;
        next FILEPATH if $DBCRUDPackage eq 'Kernel::System::DBCRUD';
        next FILEPATH if $DBCRUDPackage eq 'Kernel::System::UnitTest::DBCRUD';

        my $DBCRUDObject = $Kernel::OM->Get($DBCRUDPackage);
        next FILEPATH if !$DBCRUDObject;

        push @DBCRUDObjects, $DBCRUDObject;
    }

    return \@DBCRUDObjects;
}

1;
