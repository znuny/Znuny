# --
# Copyright (C) 2001-2021 OTRS AG, https://otrs.com/
# Copyright (C) 2021 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see https://www.gnu.org/licenses/gpl-3.0.txt.
# --

package Kernel::System::Console::Command::Admin::Package::List;

use strict;
use utf8;
use warnings;

use parent qw(Kernel::System::Console::BaseCommand);

use Kernel::System::VariableCheck qw(:all);

our @ObjectDependencies = (
    'Kernel::Config',
    'Kernel::System::Cache',
    'Kernel::System::Main',
    'Kernel::System::Package',
);

sub Configure {
    my ( $Self, %Param ) = @_;

    $Self->Description('List all installed packages.');

    $Self->AddOption(
        Name        => 'package-name',
        Description => '(Part of) package name to filter for. Omit to show all installed packages.',
        Required    => 0,
        HasValue    => 1,
        ValueRegex  => qr/.*/,
    );

    $Self->AddOption(
        Name        => 'show-deployment-info',
        Description => 'Show package and files status (package deployment info).',
        Required    => 0,
        HasValue    => 0,
    );

    return;
}

sub Run {
    my ( $Self, %Param ) = @_;

    $Self->Print("<yellow>Listing all installed packages...</yellow>\n");

    my @Packages = $Kernel::OM->Get('Kernel::System::Package')->RepositoryList();

    if ( !@Packages ) {
        $Self->Print("<green>There are no packages installed.</green>\n");
        return $Self->ExitCodeOk();
    }

    my $PackageNameOption        = $Self->GetOption('package-name');
    my $ShowDeploymentInfoOption = $Self->GetOption('show-deployment-info');

    my $PackageObject = $Kernel::OM->Get('Kernel::System::Package');

    PACKAGE:
    for my $Package (@Packages) {

        # Just show if PackageIsVisible flag is enabled.
        if (
            defined $Package->{PackageIsVisible}
            && !$Package->{PackageIsVisible}->{Content}
            )
        {
            next PACKAGE;
        }

        if ( defined $PackageNameOption && length $PackageNameOption ) {
            my $PackageString = $Package->{Name}->{Content} . '-' . $Package->{Version}->{Content};
            next PACKAGE if $PackageString !~ m{$PackageNameOption}i;
        }

        my %Data = $Self->_PackageMetadataGet(
            Tag       => $Package->{Description},
            StripHTML => 0,
        );
        $Self->Print("+----------------------------------------------------------------------------+\n");
        $Self->Print("| <yellow>Name:</yellow>        $Package->{Name}->{Content}\n");
        $Self->Print("| <yellow>Version:</yellow>     $Package->{Version}->{Content}\n");
        $Self->Print("| <yellow>Vendor:</yellow>      $Package->{Vendor}->{Content}\n");
        $Self->Print("| <yellow>URL:</yellow>         $Package->{URL}->{Content}\n");
        $Self->Print("| <yellow>License:</yellow>     $Package->{License}->{Content}\n");
        $Self->Print("| <yellow>Description:</yellow> $Data{Description}\n");

        if ($ShowDeploymentInfoOption) {
            my $PackageDeploymentOK = $PackageObject->DeployCheck(
                Name    => $Package->{Name}->{Content},
                Version => $Package->{Version}->{Content},
                Log     => 0,
            );

            my %PackageDeploymentInfo = $PackageObject->DeployCheckInfo();
            if ( defined $PackageDeploymentInfo{File} && %{ $PackageDeploymentInfo{File} } ) {
                $Self->Print(
                    '| <red>Deployment:</red>  ' . ( $PackageDeploymentOK ? 'OK' : 'Not OK' ) . "\n"
                );
                for my $File ( sort keys %{ $PackageDeploymentInfo{File} } ) {
                    my $FileMessage = $PackageDeploymentInfo{File}->{$File};
                    $Self->Print("| <red>File Status:</red> $File => $FileMessage\n");
                }
            }
            else {
                $Self->Print(
                    '| <yellow>Pck. Status:</yellow> ' . ( $PackageDeploymentOK ? 'OK' : 'Not OK' ) . "\n"
                );
            }
        }
    }
    $Self->Print("+----------------------------------------------------------------------------+\n");

    $Self->Print("<green>Done.</green>\n");
    return $Self->ExitCodeOk();
}

# =item _PackageMetadataGet()
#
# locates information in tags that are language specific.
# First, 'en' is looked for, if that is not present, the first found language will be used.
#
#     my %Data = $CommandObject->_PackageMetadataGet(
#         Tag       => $Package->{Description},
#         StripHTML => 1,         # optional, perform HTML->ASCII conversion (default 1)
#     );
#
#     my %Data = $Self->_PackageMetadataGet(
#         Tag => $Structure{IntroInstallPost},
#         AttributeFilterKey   => 'Type',
#         AttributeFilterValue =>  'pre',
#     );
#
# Returns the content and the title of the tag in a hash:
#
#     my %Result = (
#         Description => '...',   # tag content
#         Title       => '...',   # tag title
#     );
#
# =cut

sub _PackageMetadataGet {
    my ( $Self, %Param ) = @_;

    return if !ref $Param{Tag};

    my $AttributeFilterKey   = $Param{AttributeFilterKey};
    my $AttributeFilterValue = $Param{AttributeFilterValue};

    my $Title       = '';
    my $Description = '';

    TAG:
    for my $Tag ( @{ $Param{Tag} } ) {
        if ($AttributeFilterKey) {
            if ( lc $Tag->{$AttributeFilterKey} ne lc $AttributeFilterValue ) {
                next TAG;
            }
        }
        if ( !$Description && $Tag->{Lang} eq 'en' ) {
            $Description = $Tag->{Content} || '';
            $Title       = $Tag->{Title}   || '';
        }
    }
    if ( !$Description ) {
        TAG:
        for my $Tag ( @{ $Param{Tag} } ) {
            if ($AttributeFilterKey) {
                if ( lc $Tag->{$AttributeFilterKey} ne lc $AttributeFilterValue ) {
                    next TAG;
                }
            }
            if ( !$Description ) {
                $Description = $Tag->{Content} || '';
                $Title       = $Tag->{Title}   || '';
            }
        }
    }

    if ( !defined $Param{StripHTML} || $Param{StripHTML} ) {
        $Title       =~ s/(.{4,78})(?:\s|\z)/| $1\n/gm;
        $Description =~ s/^\s*//mg;
        $Description =~ s/\n/ /gs;
        $Description =~ s/\r/ /gs;
        $Description =~ s/\<style.+?\>.*\<\/style\>//gsi;
        $Description =~ s/\<br(\/|)\>/\n/gsi;
        $Description =~ s/\<(hr|hr.+?)\>/\n\n/gsi;
        $Description =~ s/\<(\/|)(pre|pre.+?|p|p.+?|table|table.+?|code|code.+?)\>/\n\n/gsi;
        $Description =~ s/\<(tr|tr.+?|th|th.+?)\>/\n\n/gsi;
        $Description =~ s/\.+?<\/(td|td.+?)\>/ /gsi;
        $Description =~ s/\<.+?\>//gs;
        $Description =~ s/  / /mg;
        $Description =~ s/&amp;/&/g;
        $Description =~ s/&lt;/</g;
        $Description =~ s/&gt;/>/g;
        $Description =~ s/&quot;/"/g;
        $Description =~ s/&nbsp;/ /g;
        $Description =~ s/^\s*\n\s*\n/\n/mg;
        $Description =~ s/(.{4,78})(?:\s|\z)/| $1\n/gm;
    }
    return (
        Description => $Description,
        Title       => $Title,
    );
}

sub _PackageContentGet {
    my ( $Self, %Param ) = @_;

    my $Source;
    my $PackageName = $Param{Location};
    if ( $Param{Location} =~ m{\A(.*):(.+)\z} ) {
        $Source      = $1;
        $PackageName = $2;
    }

    # File in local file system
    if (
        !IsStringWithData($Source)
        && -f $Param{Location}
        )
    {
        my $ContentRef = $Kernel::OM->Get('Kernel::System::Main')->FileRead(
            Location => $Param{Location},
            Mode     => 'utf8',             # optional - binmode|utf8
            Result   => 'SCALAR',           # optional - SCALAR|ARRAY
        );
        if ($ContentRef) {
            return ${$ContentRef};
        }
        else {
            $Self->PrintError("Can't open: $Param{Location}: $!");
            return;
        }
    }

    # File in configured remote repository or as direct download
    elsif ( IsStringWithData($Source) ) {
        my $FileContent = $Kernel::OM->Get('Kernel::System::Package')->PackageOnlineGet(
            Source => $Source,
            File   => $PackageName,
        );
        return $FileContent if IsStringWithData($FileContent);

        $Self->PrintError("File '$PackageName' not found in source '$Source'.");
        return;
    }

    # File in local repository
    elsif ( !IsStringWithData($Source) ) {
        my $FileContent;

        if ( $Param{Location} =~ m{\A(.*)\-(\d+\.\d+\.\d+)\z} ) {
            $FileContent = $Kernel::OM->Get('Kernel::System::Package')->RepositoryGet(
                Name    => $1,
                Version => $2,
            );
        }
        else {
            PACKAGE:
            for my $Package ( $Kernel::OM->Get('Kernel::System::Package')->RepositoryList() ) {
                if ( $Param{Location} eq $Package->{Name}->{Content} ) {
                    $FileContent = $Kernel::OM->Get('Kernel::System::Package')->RepositoryGet(
                        Name    => $Package->{Name}->{Content},
                        Version => $Package->{Version}->{Content},
                    );
                    last PACKAGE;
                }
            }
        }
        if ( !$FileContent ) {
            $Self->PrintError("File '$Param{Location}' not found in local repository or invalid package version.");
            return;
        }

        return $FileContent;
    }

    return;
}

1;
