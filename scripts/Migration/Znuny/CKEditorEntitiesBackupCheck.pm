# --
# Copyright (C) 2021 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --
## nofilter(TidyAll::Plugin::Znuny::Perl::Pod::NamePod)

package scripts::Migration::Znuny::CKEditorEntitiesBackupCheck;    ## no critic

use strict;
use warnings;
use utf8;

use IO::Interactive qw(is_interactive);

use parent qw(scripts::Migration::Base);

our @ObjectDependencies = (
    'Kernel::System::DB',
);

=head1 SYNOPSIS

Check if ckeditor related entities was backed up.

=cut

sub Run {
    my ( $Self, %Param ) = @_;

    return 1;
}

=head2 CheckPreviousRequirement()

Check for initial conditions for running this migration step.

Returns 1 on success:

    my $Result = $MigrateToZnunyObject->CheckPreviousRequirement();

=cut

sub CheckPreviousRequirement {
    my ( $Self, %Param ) = @_;

    return 1 if $Self->_CheckIfMigrationTableExists();

    # This check will occur only if we are in interactive mode.
    if ( $Param{CommandlineOptions}->{NonInteractive} || !is_interactive() ) {
        return 1;
    }

    if ( $Param{CommandlineOptions}->{Verbose} ) {
        print "\n        Warning: preparing ckeditor migration data is automatic, meaning this step\n"
            . "        will create a new table with prepopulated data for migration.\n"
            . "        The step before is to backup/export all relevant entities that will be migrated.\n"
            . "        Those includes: auto responses, standard templates,\n"
            . "        processes (to migrate activity dialogs), ticket notifications,\n"
            . "        appointment notifications, salutations and signatures.\n"
            . "        It is possible to export them from GUI or by console command module \"Admin::Object::Export\".\n"
            . "        A database backup should be created as an additional layer of data loss prevention.\n"
            . "        The migration script should then be executed.\n"
            . "        Make sure that all CKEditor entities content was migrated correctly by investigating them.\n\n"
            . "        Important: migration of CKEditor content does not guarantee 100% success rate of migration.\n";
    }

    print "\n        Did you backup the CKEditor entities? [Y]es/[N]o: ";

    my $Answer = <>;

    # Remove white space from input.
    $Answer =~ s{\s}{}g;

    # Continue only if user answers affirmatively.
    if ( $Answer =~ m{\Ay(?:es)?\z}i ) {
        print "\n";
        return 1;
    }

    return;
}

sub _CheckIfMigrationTableExists {
    my ( $Self, %Param ) = @_;

    return 1 if $Self->TableExists(
        Table => 'ckeditor_migration_4_5',
    );
    return;
}

1;
