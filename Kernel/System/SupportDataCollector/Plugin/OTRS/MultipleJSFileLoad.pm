# --
# Copyright (C) 2021 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::SupportDataCollector::Plugin::OTRS::MultipleJSFileLoad;

use strict;
use warnings;
use utf8;

use parent qw(Kernel::System::SupportDataCollector::PluginBase);

use Kernel::Language qw(Translatable);

our @ObjectDependencies = (
    'Kernel::Config',
    'Kernel::Language',
);

sub GetDisplayPath {
    return Translatable('OTRS') . '/' . Translatable('Views with multiple loaded JavaScript files');
}

sub Run {
    my $Self = shift;

    my $ConfigObject   = $Kernel::OM->Get('Kernel::Config');
    my $LanguageObject = $Kernel::OM->Get('Kernel::Language');

    for my $Interface (qw (Agent Customer)) {

        # get global js
        my $CommonJSList = $ConfigObject->Get("Loader::$Interface\::CommonJS");

        # load js for agent views.
        my %ViewFileList;
        KEY:
        for my $Key ( sort keys %{$CommonJSList} ) {
            next KEY if $Key eq '100-CKEditor' && !$ConfigObject->Get('Frontend::RichText');
            FILE:
            for my $File ( @{ $CommonJSList->{$Key} } ) {
                $ViewFileList{$File} ||= 0;
                $ViewFileList{$File}++;
            }
        }

        my $FrontendModuleRoleLabel = $Interface eq 'Agent' ? 'Frontend::Module' : 'CustomerFrontend::Module';
        my $ActionListConfig        = $ConfigObject->Get($FrontendModuleRoleLabel);
        my @Actions                 = keys %{$ActionListConfig};

        my %MultipleJSFileActions;
        for my $Action (@Actions) {
            my $Setting = $ConfigObject->Get("Loader::Module::$Action") || {};

            $MultipleJSFileActions{$Action} = {%ViewFileList};

            MODULE:
            for my $Module ( sort keys %{$Setting} ) {
                next MODULE if ref $Setting->{$Module}->{JavaScript} ne 'ARRAY';
                FILE:
                for my $File ( @{ $Setting->{$Module}->{JavaScript} } ) {

                    if ( $MultipleJSFileActions{$Action}{$File} ) {
                        $MultipleJSFileActions{$Action}{$File}++ if $MultipleJSFileActions{$Action}{$File};

                        next FILE if $MultipleJSFileActions{$Action}{$File};
                    }

                    $MultipleJSFileActions{$Action}{$File} = 1 if !$MultipleJSFileActions{$Action}{$File};
                }
            }
        }

        for my $Action ( sort keys %MultipleJSFileActions ) {
            my $MultipleJSFileCount = 0;
            my @Files;
            for my $File ( sort keys %{ $MultipleJSFileActions{$Action} } ) {
                if ( $MultipleJSFileActions{$Action}->{$File} > 1 ) {
                    $MultipleJSFileCount++;
                    push @Files, "$File";
                }
            }

            my $Message = $LanguageObject->Translate('The following JavaScript files loaded multiple times:') . "\n\r";
            $Message .= join "\n\r", @Files;

            my $Value = $MultipleJSFileCount . " ";
            $Value .= (
                $MultipleJSFileCount > 1 ? $LanguageObject->Translate('Files') : $LanguageObject->Translate('File')
            );

            $Self->AddResultWarning(
                Identifier       => $Action,
                Label            => $Action,
                Value            => $Value,
                MessageFormatted => $Message,
            ) if $MultipleJSFileCount > 0;
        }
    }

    return $Self->GetResults();
}

1;
