# --
# Copyright (C) 2021 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --
## nofilter(TidyAll::Plugin::Znuny::Perl::Pod::NamePod)
## nofilter(TidyAll::Plugin::Znuny::Deprecated::AjaxAttachment)

package scripts::Migration::Znuny::MigrateSysConfigSettings;    ## no critic

use strict;
use warnings;
use utf8;

use IO::Interactive               qw(is_interactive);
use Kernel::System::VariableCheck qw(:all);

use parent qw(scripts::Migration::Base);

our @ObjectDependencies = (
    'Kernel::Config',
    'Kernel::System::SysConfig::Migration',
);

=head1 SYNOPSIS

Migrates SysConfig settings.

=cut

=head2 _GetMigrateSysConfigSettings()

Returns the SysConfig settings to be migrated.

    my %MigrateSysConfigSettings = $MigrateToZnunyObject->_GetMigrateSysConfigSettings();

Returns:

    my %MigrateSysConfigSettings = ();

=cut

sub _GetMigrateSysConfigSettings {
    my ( $Self, %Param ) = @_;

    my %MigrateSysConfigSettings = (

        # Znuny-ZoomArticlePDFPreview and its Znuny4OTRS predecessor were merged into the framework.
        "Znuny4OTRSZoomArticlePDFPreview###Width" => {
            UpdateName => "ArticleZoomPDFPreview###Width",
        },
        "Znuny4OTRSZoomArticlePDFPreview###Height" => {
            UpdateName => "ArticleZoomPDFPreview###Height",
        },
        "Znuny4OTRSZoomArticlePDFPreview###TicketAttributes###ActivatePreview" => {
            UpdateName => "ArticleZoomPDFPreview###TicketAttributes###ActivatePreview",
        },
        "Znuny4OTRSZoomArticlePDFPreview###TicketAttributes###ShowFirstPreview" => {
            UpdateName => "ArticleZoomPDFPreview###TicketAttributes###ShowFirstPreview",
        },

        # Znuny-AdvancedAttachments and its Znuny4OTRS predecessor were merged into the
        # framework's generic attachment handling.
        "Znuny4OTRSAdvancedAttachments###ShowDuplicateFiles" => {
            UpdateName => "Attachment###ShowDuplicateFiles",
        },
        "Znuny4OTRSAdvancedAttachments###DeactivateWidgetArticleCount" => {
            UpdateName => "Attachment###DeactivateWidgetArticleCount",
        },
        "Znuny4OTRSAdvancedAttachments###DeactivateWidgetAttachmentCount" => {
            UpdateName => "Attachment###DeactivateWidgetAttachmentCount",
        },
        "Znuny4OTRSAdvancedAttachments###ShowAttachmentsCount" => {
            UpdateName => "Attachment###ShowAttachmentsCount",
        },
        "ZnunyAdvancedAttachments###ShowDuplicateFiles" => {
            UpdateName => "Attachment###ShowDuplicateFiles",
        },
        "ZnunyAdvancedAttachments###EnablePreview" => {
            UpdateName => "Attachment###EnablePreview",
        },
        "ZnunyAdvancedAttachments###DeactivateWidgetArticleCount" => {
            UpdateName => "Attachment###DeactivateWidgetArticleCount",
        },
        "ZnunyAdvancedAttachments###DeactivateWidgetAttachmentCount" => {
            UpdateName => "Attachment###DeactivateWidgetAttachmentCount",
        },
        "ZnunyAdvancedAttachments###ShowAttachmentsCount" => {
            UpdateName => "Attachment###ShowAttachmentsCount",
        },
        "ZnunyAdvancedAttachments###AgentTicketZoom###ShowAttachmentsCount" => {
            UpdateName => "Attachment###AgentTicketZoom###ShowAttachmentsCount",
        },
        "Frontend::Module###AgentTicketZnunyAdvancedAttachmentsList" => {
            UpdateName => "Frontend::Module###AgentTicketAttachmentList",
        },
        "Loader::Module::AgentTicketZnunyAdvancedAttachmentsList###001-Default" => {
            UpdateName => "Loader::Module::AgentTicketAttachmentList###001-Default",
        },
        "Loader::Agent::CommonJS###999-ZnunyAdvancedAttachments" => {
            UpdateName           => "Loader::Agent::CommonJS###999-Attachments",
            UpdateEffectiveValue => {
                'Core.Znuny.AdvancedAttachments.js' => 'Core.Agent.Attachments.js',
            },
        },
        "Loader::Agent::CommonCSS###999-ZnunyAdvancedAttachments" => {
            UpdateName           => "Loader::Agent::CommonCSS###999-Attachments",
            UpdateEffectiveValue => {
                'Core.Znuny.AdvancedAttachments.css' => 'Core.Agent.Attachments.css',
            },
        },
        SessionName => {
            UpdateEffectiveValue => {
                OTRSAgentInterface => 'ZnunyAgentInterface',
            },
        },
        CustomerPanelSessionName => {
            UpdateEffectiveValue => {
                OTRSCustomerInterface => 'ZnunyCustomerInterface',
            },
        },
        OTRSTimeZone => {
            UpdateName => 'ZnunyTimeZone',
        },
    );

    return %MigrateSysConfigSettings;
}

=head2 CheckPreviousRequirement()

Check for initial conditions for running this migration step.

Returns 1 on success:

    my $Result = $MigrateToZnunyObject->CheckPreviousRequirement();

=cut

sub CheckPreviousRequirement {
    my ( $Self, %Param ) = @_;

    my %MigrateSysConfigSettings = $Self->_GetMigrateSysConfigSettings();
    return 1 if !%MigrateSysConfigSettings;

    # This check will occur only if we are in interactive mode.
    if ( $Param{CommandlineOptions}->{NonInteractive} || !is_interactive() ) {
        return 1;
    }

    if ( $Param{CommandlineOptions}->{Verbose} ) {
        my %FunctionMap = (
            'UpdateName'           => 'Change name to',
            'AddEffectiveValue'    => 'Add value(s)',
            'UpdateEffectiveValue' => "Update value(s)",
            'DeleteEffectiveValue' => "Delete value(s)",
        );

        print "\n        Warning: The following SysConfig settings will be modified.\n";
        for my $Setting ( sort keys %MigrateSysConfigSettings ) {

            print ' ' x 8 . '-' x 72 . "\n        Name:" . ' ' x 18 . "$Setting\n";

            for my $Function ( sort keys %{ $MigrateSysConfigSettings{$Setting} } ) {
                my $Length = 22 - ( length( $FunctionMap{$Function} ) );
                print "        $FunctionMap{$Function}:" . ' ' x $Length;

                if ( IsStringWithData( $MigrateSysConfigSettings{$Setting}->{$Function} ) ) {
                    print "$MigrateSysConfigSettings{$Setting}->{$Function}\n";
                }
                elsif ( IsArrayRefWithData( $MigrateSysConfigSettings{$Setting}->{$Function} ) ) {
                    print "\n";
                    for my $Key ( @{ $MigrateSysConfigSettings{$Setting}->{$Function} } ) {
                        print ' ' x 31 . "$Key \n";
                    }
                }
                elsif ( IsHashRefWithData( $MigrateSysConfigSettings{$Setting}->{$Function} ) ) {
                    print "\n";

                    for my $Key ( sort keys %{ $MigrateSysConfigSettings{$Setting}->{$Function} } ) {
                        print ' ' x 31 . "$Key => $MigrateSysConfigSettings{$Setting}->{$Function}->{$Key}\n";
                    }
                }
            }
        }
        print ' ' x 8 . '-' x 72 . "\n";
    }
    print "\n        Should the SysConfig be migrated? [Y]es/[N]o: ";

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

sub Run {
    my ( $Self, %Param ) = @_;

    my $SysConfigMigrationObject = $Kernel::OM->Get('Kernel::System::SysConfig::Migration');
    my $ConfigObject             = $Kernel::OM->Get('Kernel::Config');

    my $Home      = $ConfigObject->Get('Home');
    my $FileClass = 'Kernel::Config::Files::ZZZAAuto';
    my $FilePath  = "$Home/Kernel/Config/Backups/ZZZAAuto.pm";

    if ( !-f $FilePath ) {
        print "\n\n Error: ZZZAAuto backup file not found.\n";
        return;
    }

    my %MigrateSysConfigSettings = $Self->_GetMigrateSysConfigSettings();
    return 1 if !%MigrateSysConfigSettings;

    my $Success = $SysConfigMigrationObject->MigrateSysConfigSettings(
        FileClass => $FileClass,
        FilePath  => $FilePath,
        Data      => \%MigrateSysConfigSettings,
    );

    return 1;
}

1;
