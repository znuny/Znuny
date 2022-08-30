#!/usr/bin/env perl
# --
# Copyright (C) 2001-2021 OTRS AG, https://otrs.com/
# Copyright (C) 2021-2022 Znuny GmbH, https://znuny.org/
# --
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program. If not, see https://www.gnu.org/licenses/gpl-3.0.txt.
# --

use strict;
use warnings;

use File::Basename;
use FindBin qw($RealBin);
use lib dirname($RealBin);
use lib dirname($RealBin) . '/Kernel/cpan-lib';
use lib dirname($RealBin) . '/Custom';

use Kernel::System::Environment;
use Kernel::System::VariableCheck qw( :all );

use ExtUtils::MakeMaker;
use File::Path;
use Getopt::Long;
use Term::ANSIColor;

our %InstTypeToCMD = (

    # [InstType] => {
    #    CMD       => '[cmd to install module]',
    #    UseModule => 1/0,
    # }
    # Set UseModule to 1 if you want to use the
    # cpan module name of the package as replace string.
    # e.g. yum install "perl(Date::Format)"
    # If you set it 0 it will use the name
    # for the InstType of the module
    # e.g. apt-get install -y libtimedate-perl
    # and as fallback the default cpan install command
    # e.g. cpan DBD::Oracle
    aptget => {
        CMD       => 'apt-get install -y %s',
        UseModule => 0,
    },
    emerge => {
        CMD       => 'emerge %s',
        UseModule => 0,
    },
    ppm => {
        CMD       => 'ppm install %s',
        UseModule => 0,
    },
    yum => {
        CMD       => 'yum install "%s"',
        SubCMD    => 'perl(%s)',
        UseModule => 1,
    },
    zypper => {
        CMD       => 'zypper install %s',
        UseModule => 0,
    },
    ports => {
        CMD       => 'cd /usr/ports %s',
        SubCMD    => ' && make -C %s install clean',
        UseModule => 0,
    },
    default => {
        CMD => 'cpan %s',
    },
);

our %DistToInstType = (

    # apt-get
    debian => 'aptget',
    ubuntu => 'aptget',

    # emerge
    # for reasons unknown, some environments return "gentoo" (incl. the quotes)
    '"gentoo"' => 'emerge',
    gentoo     => 'emerge',

    # yum
    centos => 'yum',
    fedora => 'yum',
    rhel   => 'yum',
    redhat => 'yum',

    # zypper
    suse => 'zypper',

    # FreeBSD
    freebsd => 'ports',
);

our $OSDist;
eval {
    require Linux::Distribution;    ## nofilter(TidyAll::Plugin::OTRS::Perl::Require)
    import Linux::Distribution;
    $OSDist = Linux::Distribution::distribution_name() || '';
};
if ( !defined $OSDist ) {
    $OSDist = $^O;
}

my $AllModules;
my $PackageList;
my $Help;
GetOptions(
    all  => \$AllModules,
    list => \$PackageList,
    h    => \$Help
);

# check needed params
if ($Help) {
    print "\nReturn all required and optional packages of OTRS.\n\n";
    print "Usage:\n";
    print " otrs.CheckModules.pl [-list|all]\n\n";
    print "Options:\n";
    printf " %-22s - %s", '[-list]', 'Return an install command with all required packages.' . "\n";
    printf " %-22s - %s", '[-all]',  'Return all required, optional and bundled packages of OTRS.' . "\n\n";
    exit 1;
}

my $Options = shift || '';
my $NoColors;

if ( $ENV{nocolors} || $Options =~ m{\A nocolors}msxi ) {
    $NoColors = 1;
}

my $ExitCode = 0;    # success

# config
my @NeededModules = (
    {
        Module    => 'Apache::DBI',
        Required  => 0,
        Comment   => 'Improves Performance on Apache webservers with mod_perl enabled.',
        InstTypes => {
            aptget => 'libapache-dbi-perl',
            emerge => 'dev-perl/Apache-DBI',
            zypper => 'perl-Apache-DBI',
            ports  => 'www/p5-Apache-DBI',
        },
    },
    {
        Module    => 'Apache2::Reload',
        Required  => 0,
        Comment   => 'Avoids web server restarts on mod_perl.',
        InstTypes => {
            aptget => 'libapache2-mod-perl2',
            emerge => 'dev-perl/Apache-Reload',
            zypper => 'apache2-mod_perl',
            ports  => 'www/mod_perl2',
        },
    },
    {
        Module    => 'Archive::Tar',
        Required  => 1,
        Comment   => 'Required for compressed file generation (in perlcore).',
        InstTypes => {
            emerge => 'perl-core/Archive-Tar',
            zypper => 'perl-Archive-Tar',
            ports  => 'archivers/p5-Archive-Tar',
        },
    },
    {
        Module    => 'Archive::Zip',                               # required for OTRSBusiness
        Required  => 1,
        Comment   => 'Required for compressed file generation.',
        InstTypes => {
            aptget => 'libarchive-zip-perl',
            emerge => 'dev-perl/Archive-Zip',
            zypper => 'perl-Archive-Zip',
            ports  => 'archivers/p5-Archive-Zip',
        },
    },
    {
        Module    => 'Authen::SASL',
        Required  => 1,
        Comment   => 'Required for SASL authentication mechanisms (e.g. IMAP and SMTP connections).',
        InstTypes => {
            aptget => 'libauthen-sasl-perl',
            emerge => 'dev-perl/Authen-SASL',
            zypper => 'perl-Authen-SASL',
        },
    },
    {
        Module    => 'Crypt::Eksblowfish::Bcrypt',
        Required  => 0,
        Comment   => 'For strong password hashing.',
        InstTypes => {
            aptget => 'libcrypt-eksblowfish-perl',
            emerge => 'dev-perl/Crypt-Eksblowfish',
            zypper => 'perl-Crypt-Eksblowfish',
            ports  => 'security/p5-Crypt-Eksblowfish',
        },
    },
    {
        Module    => 'Crypt::JWT',
        Required  => 0,
        Comment   => 'JSON web token support.',
        InstTypes => {
            aptget => 'libcrypt-jwt-perl',
            emerge => 'dev-perl/Crypt-JWT',
            zypper => 'perl-Crypt-JWT',
            ports  => 'security/p5-Crypt-JWT',
        },
    },
    {
        Module    => 'Crypt::OpenSSL::X509',
        Required  => 0,
        Comment   => 'X509 certificate support.',
        InstTypes => {
            aptget => 'libcrypt-openssl-x509',
            emerge => 'dev-perl/Crypt-OpenSSL-X509',
            zypper => 'perl-Crypt-OpenSSL-X509',
            ports  => 'security/p5-Crypt-OpenSSL-X509',
        },
    },
    {
        Module    => 'CSS::Minifier::XS',
        Required  => 0,
        Comment   => 'Alternative to CSS::Minifier in XS, which is slightly faster than CSS::Minifier (pure Perl).',
        InstTypes => {
            aptget => 'libcss-minifier-xs-perl',
            emerge => 'dev-perl/CSS-Minifier-XS',
            zypper => 'perl-CSS-Minifier-XS',
            ports  => 'converters/p5-CSS-Minifier-XS',
        },
    },
    {
        Module    => 'Data::UUID',
        Required  => 1,
        Comment   => 'Required to generate UUIDs.',
        InstTypes => {
            aptget => undef,
            emerge => undef,
            yum    => undef,
            zypper => undef,
            ports  => undef,
        },
    },
    {
        Module    => 'Date::Format',
        Required  => 1,
        InstTypes => {
            aptget => 'libtimedate-perl',
            emerge => 'dev-perl/TimeDate',
            zypper => 'perl-TimeDate',
            ports  => 'devel/p5-TimeDate',
        },
    },
    {
        Module    => 'DateTime',
        Required  => 1,
        InstTypes => {
            aptget => 'libdatetime-perl',
            emerge => 'dev-perl/DateTime',
            zypper => 'perl-DateTime',
            ports  => 'devel/p5-TimeDate',
        },
        Depends => [
            {
                Module              => 'DateTime::TimeZone',
                Comment             => 'Olson time zone database, required for correct time calculations.',
                VersionsRecommended => [
                    {
                        Version => '2.20',
                        Comment => 'This version includes recent time zone changes for Chile.',
                    },
                ],
            },
        ],
    },
    {
        Module    => 'DBI',
        Required  => 1,
        InstTypes => {
            aptget => 'libdbi-perl',
            emerge => 'dev-perl/DBI',
            zypper => 'perl-DBI',
            ports  => 'databases/p5-DBI',
        },
    },
    {
        Module    => 'DBD::mysql',
        Required  => 0,
        Comment   => 'Required to connect to a MySQL database.',
        InstTypes => {
            aptget => 'libdbd-mysql-perl',
            emerge => 'dev-perl/DBD-mysql',
            zypper => 'perl-DBD-mysql',
            ports  => 'databases/p5-DBD-mysql',
        },
    },
    {
        Module               => 'DBD::ODBC',
        Required             => 0,
        VersionsNotSupported => [
            {
                Version => '1.23',
                Comment =>
                    'This version is broken and not useable! Please upgrade to a higher version.',
            },
        ],
        Comment   => 'Required to connect to a MS-SQL database.',
        InstTypes => {
            aptget => 'libdbd-odbc-perl',
            emerge => undef,
            yum    => undef,
            zypper => undef,
            ports  => 'databases/p5-DBD-ODBC',
        },
    },
    {
        Module    => 'DBD::Oracle',
        Required  => 0,
        Comment   => 'Required to connect to a Oracle database.',
        InstTypes => {
            aptget => undef,
            emerge => undef,
            yum    => undef,
            zypper => undef,
            ports  => undef,
        },
    },
    {
        Module    => 'DBD::Pg',
        Required  => 0,
        Comment   => 'Required to connect to a PostgreSQL database.',
        InstTypes => {
            aptget => 'libdbd-pg-perl',
            emerge => 'dev-perl/DBD-Pg',
            zypper => 'perl-DBD-Pg',
            ports  => 'databases/p5-DBD-Pg',
        },
    },
    {
        Module    => 'Digest::SHA',    # Supposed to be in perlcore, but seems to be missing on some distributions.
        Required  => 1,
        InstTypes => {
            aptget => 'libdigest-sha-perl',
            emerge => 'dev-perl/Digest-SHA',
            zypper => 'perl-Digest-SHA',
            ports  => 'security/p5-Digest-SHA'
        },
    },
    {
        Module          => 'Encode::HanExtra',
        VersionRequired => '0.23',
        Required        => 0,
        Comment         => 'Required to handle mails with several Chinese character sets.',
        InstTypes       => {
            aptget => 'libencode-hanextra-perl',
            emerge => 'dev-perl/Encode-HanExtra',
            zypper => 'perl-Encode-HanExtra',
            ports  => 'chinese/p5-Encode-HanExtra',
        },
    },
    {
        Module          => 'Excel::Writer::XLSX',
        VersionRequired => '0.95',
        Required        => 0,
        Comment         => 'Required for the creation of Excel statistical reports.',
        InstTypes       => {
            aptget => 'libexcel-writer-xlsx-perl',
            emerge => 'dev-perl/Excel-Writer-XLSX',
            zypper => 'perl-Excel-Writer-XLSX',
            ports  => 'textproc/p5-Excel-Writer-XLSX',
        },
    },
    {
        Module          => 'Hash::Merge',
        VersionRequired => '0.300',
        Required        => 0,
        Comment         => 'Required for the creation of Excel statistical reports.',
        InstTypes       => {
            aptget => 'libhash-merge-perl',
            emerge => 'dev-perl/Hash-Merge',
            zypper => 'perl-Hash-Merge',
            ports  => 'textproc/p5-Hash-Merge',
        },
    },
    {
        Module              => 'IO::Socket::SSL',
        Required            => 0,
        Comment             => 'Required for SSL connections to web and mail servers.',
        VersionsRecommended => [
            {
                Version => '2.066',
                Comment => 'This version fixes email sending (bug#14357).',
            },
        ],
        InstTypes => {
            aptget => 'libio-socket-ssl-perl',
            emerge => 'dev-perl/IO-Socket-SSL',
            zypper => 'perl-IO-Socket-SSL',
            ports  => 'security/p5-IO-Socket-SSL',
        },
    },
    {
        Module   => 'JavaScript::Minifier::XS',
        Required => 0,
        Comment =>
            'Alternative to JavaScript::Minifier in XS, which is slightly faster than JavaScript::Minifier (pure Perl).',
        InstTypes => {
            aptget => 'libjavascript-minifier-xs-perl',
            emerge => 'dev-perl/JavaScript-Minifier-XS',
            zypper => 'perl-JavaScript-Minifier-XS',
            ports  => 'converters/p5-JavaScript-Minifier-XS',
        },
    },
    {
        Module   => 'Jq',
        Required => 0,
        Comment =>
            'Support for extended condition checking via Jq for the generic interface.',
        InstTypes => {
            aptget => undef,
            emerge => undef,
            zypper => undef,
            ports  => undef,
        },
    },
    {
        Module    => 'JSON::XS',
        Required  => 0,
        Comment   => 'Recommended for faster AJAX/JavaScript handling.',
        InstTypes => {
            aptget => 'libjson-xs-perl',
            emerge => 'dev-perl/JSON-XS',
            zypper => 'perl-JSON-XS',
            ports  => 'converters/p5-JSON-XS',
        },
    },
    {
        Module   => 'List::Util::XS',
        Required => 1,
        Comment =>
            "Do a 'force install Scalar::Util' via cpan shell to fix this problem. Please make sure to have an c compiler and make installed before.",
        InstTypes => {
            aptget => 'libscalar-list-utils-perl',
            emerge => 'perl-core/Scalar-List-Utils',
            zypper => 'perl-Scalar-List-Utils',
            ports  => 'lang/p5-Scalar-List-Utils',
        },
    },
    {
        Module    => 'LWP::UserAgent',
        Required  => 1,
        InstTypes => {
            aptget => 'libwww-perl',
            emerge => 'dev-perl/libwww-perl',
            zypper => 'perl-libwww-perl',
            ports  => 'www/p5-libwww',
        },
    },
    {
        Module          => 'Mail::IMAPClient',
        VersionRequired => '3.22',
        Required        => 1,
        InstTypes       => {
            aptget => 'libmail-imapclient-perl',
            emerge => 'dev-perl/Mail-IMAPClient',
            zypper => 'perl-Mail-IMAPClient',
            ports  => 'mail/p5-Mail-IMAPClient',
        },
        Depends => [
            {
                Module              => 'IO::Socket::SSL',
                Required            => 0,
                Comment             => 'Required for SSL connections to web and mail servers.',
                VersionsRecommended => [
                    {
                        Version => '2.066',
                        Comment => 'This version fixes email sending (bug#14357).',
                    },
                ],
                InstTypes => {
                    aptget => 'libio-socket-ssl-perl',
                    emerge => 'dev-perl/IO-Socket-SSL',
                    zypper => 'perl-IO-Socket-SSL',
                    ports  => 'security/p5-IO-Socket-SSL',
                },
            },
            {
                Module    => 'Authen::NTLM',
                Required  => 0,
                Comment   => 'Required for NTLM authentication mechanism in IMAP connections.',
                InstTypes => {
                    aptget => 'libauthen-ntlm-perl',
                    emerge => 'dev-perl/Authen-NTLM',
                    zypper => 'perl-Authen-NTLM',
                },
            },
        ],
    },
    {
        Module    => 'ModPerl::Util',
        Required  => 0,
        Comment   => 'Improves Performance on Apache webservers dramatically.',
        InstTypes => {
            aptget => 'libapache2-mod-perl2',
            emerge => 'www-apache/mod_perl',
            zypper => 'apache2-mod_perl',
            ports  => 'www/mod_perl2',
        },
    },
    {
        Module    => 'Moo',
        Required  => 1,
        Comment   => 'Required for random number generator.',
        InstTypes => {
            aptget => 'libmoo-perl',
            emerge => 'dev-perl/Moo',
            zypper => 'perl-Moo',
            ports  => 'devel/p5-Moo',
        },
    },
    {
        Module               => 'Net::DNS',
        Required             => 1,
        VersionsNotSupported => [
            {
                Version => '0.60',
                Comment =>
                    'This version is broken and not useable! Please upgrade to a higher version.',
            },
        ],
        InstTypes => {
            aptget => 'libnet-dns-perl',
            emerge => 'dev-perl/Net-DNS',
            zypper => 'perl-Net-DNS',
            ports  => 'dns/p5-Net-DNS',
        },
    },
    {
        Module    => 'Net::LDAP',
        Required  => 0,
        Comment   => 'Required for directory authentication.',
        InstTypes => {
            aptget => 'libnet-ldap-perl',
            emerge => 'dev-perl/perl-ldap',
            zypper => 'perl-ldap',
            ports  => 'net/p5-perl-ldap',
        },
    },
    {
        Module    => 'Net::LDAP::Constant',
        Required  => 0,
        Comment   => 'Required for directory authentication.',
        InstTypes => {
            aptget => 'libnet-ldap-perl',
            emerge => 'dev-perl/perl-ldap',
            zypper => 'perl-ldap',
            ports  => 'net/p5-perl-ldap',
        },
    },
    {
        Module              => 'Net::SMTP',
        Required            => 0,
        Comment             => 'Simple Mail Transfer Protocol Client.',
        VersionsRecommended => [
            {
                Version => '3.11',
                Comment => 'This version fixes email sending (bug#14357).',
            },
        ],
        InstTypes => {
            aptget => undef,
            emerge => undef,
            zypper => undef,
            ports  => undef,
        },
    },
    {
        Module    => 'Spreadsheet::XLSX',
        Required  => 0,
        Comment   => 'Spreadsheet::XLSX enables import and export of Excel files in certain dialogs.',
        InstTypes => {
            aptget => 'libspreadsheet-xlsx-perl',
            emerge => 'dev-perl/Spreadsheet-XLSX',
            zypper => 'perl-Spreadsheet-XLSX',
            ports  => 'www/p5-Spreadsheet-XLSX',
        },
    },
    {
        Module    => 'Template',
        Required  => 1,
        Comment   => 'Template::Toolkit, the rendering engine of OTRS.',
        InstTypes => {
            aptget => 'libtemplate-perl',
            emerge => 'dev-perl/Template-Toolkit',
            zypper => 'perl-Template-Toolkit',
            ports  => 'www/p5-Template-Toolkit',
        },
    },
    {
        Module    => 'Template::Stash::XS',
        Required  => 1,
        Comment   => 'The fast data stash for Template::Toolkit.',
        InstTypes => {
            aptget => 'libtemplate-perl',
            emerge => 'dev-perl/Template-Toolkit',
            zypper => 'perl-Template-Toolkit',
            ports  => 'www/p5-Template-Toolkit',
        },
    },
    {
        Module    => 'Text::Diff::FormattedHTML',
        Required  => 1,
        Comment   => undef,
        InstTypes => {
            aptget => undef,
            emerge => undef,
            zypper => undef,
            ports  => undef,
        },
    },
    {
        Module    => 'Text::CSV_XS',
        Required  => 0,
        Comment   => 'Recommended for faster CSV handling.',
        InstTypes => {
            aptget => 'libtext-csv-xs-perl',
            emerge => 'dev-perl/Text-CSV_XS',
            zypper => 'perl-Text-CSV_XS',
            ports  => 'textproc/p5-Text-CSV_XS',
        },
    },
    {
        Module    => 'Time::HiRes',
        Required  => 1,
        Comment   => 'Required for high resolution timestamps.',
        InstTypes => {
            aptget => 'perl',
            emerge => 'perl-core/Time-HiRes',
            zypper => 'perl-Time-HiRes',
            ports  => 'devel/p5-Time-HiRes',
        },
    },
    {
        Module    => 'XML::LibXML',
        Required  => 1,
        Comment   => 'Required for XML processing.',
        InstTypes => {
            aptget => 'libxml-libxml-perl',
            zypper => 'perl-XML-LibXML',
            ports  => 'textproc/p5-XML-LibXML',
        },
    },
    {
        Module    => 'XML::LibXSLT',
        Required  => 0,
        Comment   => 'Required for Generic Interface XSLT mapping module.',
        InstTypes => {
            aptget => 'libxml-libxslt-perl',
            zypper => 'perl-XML-LibXSLT',
            ports  => 'textproc/p5-XML-LibXSLT',
        },
    },
    {
        Module    => 'XML::Parser',
        Required  => 0,
        Comment   => 'Recommended for XML processing.',
        InstTypes => {
            aptget => 'libxml-parser-perl',
            emerge => 'dev-perl/XML-Parser',
            zypper => 'perl-XML-Parser',
            ports  => 'textproc/p5-XML-Parser',
        },
    },
    {
        Module   => 'YAML::XS',
        Required => 1,
        Comment  => 'Required for fast YAML processing.',

        # Example of how to use VersionsRecommended option.
        # VersionsRecommended => [
        #     {
        #         Version => '5.0.1',
        #         Comment => 'This version fixes a bug.',
        #     },
        #     {
        #         Version => '6.0.1',
        #         Comment => 'This version fixes a critical issue.',
        #     },
        # ],
        InstTypes => {
            aptget => 'libyaml-libyaml-perl',
            emerge => 'dev-perl/YAML-LibYAML',
            zypper => 'perl-YAML-LibYAML',
            ports  => 'textproc/p5-YAML-LibYAML',
        },
    },
);

if ($PackageList) {
    my %PackageList = _PackageList( \@NeededModules );

    if ( IsArrayRefWithData( $PackageList{Packages} ) ) {

        my $CMD = $PackageList{CMD};

        for my $Package ( @{ $PackageList{Packages} } ) {
            if ( $PackageList{SubCMD} ) {
                $Package = sprintf $PackageList{SubCMD}, $Package;
            }
        }
        printf $CMD, join( ' ', @{ $PackageList{Packages} } );
        print "\n";
    }
}
else {
    # try to determine module version number
    my $Depends = 0;

    for my $Module (@NeededModules) {
        _Check( $Module, $Depends, $NoColors );
    }

    if ($AllModules) {
        print "\nBundled modules:\n\n";

        my %PerlInfo = Kernel::System::Environment->PerlInfoGet(
            BundledModules => 1,
        );

        for my $Module ( sort keys %{ $PerlInfo{Modules} } ) {
            _Check(
                {
                    Module   => $Module,
                    Required => 1,
                },
                $Depends,
                $NoColors
            );
        }
    }
}

sub _Check {
    my ( $Module, $Depends, $NoColors ) = @_;

    print "  " x ( $Depends + 1 );
    print "o $Module->{Module}";
    my $Length = 33 - ( length( $Module->{Module} ) + ( $Depends * 2 ) );
    print '.' x $Length;

    my $Version = Kernel::System::Environment->ModuleVersionGet( Module => $Module->{Module} );
    if ($Version) {

        # cleanup version number
        my $CleanedVersion = _VersionClean(
            Version => $Version,
        );

        my $ErrorMessage;

        # Test if all module dependencies are installed by requiring the module.
        #   Don't do this for Net::DNS as it seems to take very long (>20s) in a
        #   mod_perl environment sometimes.
        my %DontRequire = (
            'Net::DNS'        => 1,
            'Email::Valid'    => 1,    # uses Net::DNS internally
            'Apache2::Reload' => 1,    # is not needed / working on systems without mod_perl (like Plack etc.)
        );

        ## no critic
        if ( !$DontRequire{ $Module->{Module} } && !eval "require $Module->{Module}" ) {
            $ErrorMessage .= 'Not all prerequisites for this module correctly installed. ';
        }
        ## use critic

        if ( $Module->{VersionsNotSupported} ) {

            my $VersionsNotSupported = 0;
            ITEM:
            for my $Item ( @{ $Module->{VersionsNotSupported} } ) {

                # cleanup item version number
                my $ItemVersion = _VersionClean(
                    Version => $Item->{Version},
                );

                if ( $CleanedVersion == $ItemVersion ) {
                    $VersionsNotSupported = $Item->{Comment};
                    last ITEM;
                }
            }

            if ($VersionsNotSupported) {
                $ErrorMessage .= "Version $Version not supported! $VersionsNotSupported ";
            }
        }

        my $AdditionalText = '';

        if ( $Module->{VersionsRecommended} ) {

            my $VersionsRecommended = 0;
            ITEM:
            for my $Item ( @{ $Module->{VersionsRecommended} } ) {

                my $ItemVersion = _VersionClean(
                    Version => $Item->{Version},
                );

                if ( $CleanedVersion < $ItemVersion ) {
                    $AdditionalText
                        .= "    Please consider updating to version $Item->{Version} or higher: $Item->{Comment}\n";
                }
            }
        }

        if ( $Module->{VersionRequired} ) {

            # cleanup item version number
            my $RequiredModuleVersion = _VersionClean(
                Version => $Module->{VersionRequired},
            );

            if ( $CleanedVersion < $RequiredModuleVersion ) {
                $ErrorMessage
                    .= "Version $Version installed but $Module->{VersionRequired} or higher is required! ";
            }
        }

        if ($ErrorMessage) {
            if ($NoColors) {
                print "FAILED! $ErrorMessage\n";
            }
            else {
                print color('red') . 'FAILED!' . color('reset') . " $ErrorMessage\n";
            }
            $ExitCode = 1;    # error
        }
        else {
            my $OutputVersion = $Version;

            if ( $OutputVersion =~ m{ [0-9.] }xms ) {
                $OutputVersion = 'v' . $OutputVersion;
            }

            if ($NoColors) {
                print "ok ($OutputVersion)\n$AdditionalText";
            }
            else {
                print color('green') . 'ok'
                    . color('reset')
                    . " ($OutputVersion)\n"
                    . color('yellow')
                    . "$AdditionalText"
                    . color('reset');
            }
        }
    }
    else {
        my $Comment  = $Module->{Comment} ? ' - ' . $Module->{Comment} : '';
        my $Required = $Module->{Required};
        my $Color    = 'yellow';

        # OS Install Command
        my %InstallCommand = _GetInstallCommand($Module);

        # create example installation string for module
        my $InstallText = '';
        if ( IsHashRefWithData( \%InstallCommand ) ) {
            my $CMD = $InstallCommand{CMD};
            if ( $InstallCommand{SubCMD} ) {
                $CMD = sprintf $InstallCommand{CMD}, $InstallCommand{SubCMD};
            }

            $InstallText = " To install, you can use: '" . sprintf( $CMD, $InstallCommand{Package} ) . "'.";
        }

        if ($Required) {
            $Required = 'required';
            $Color    = 'red';
            $ExitCode = 1;            # error
        }
        else {
            $Required = 'optional';
        }
        if ($NoColors) {
            print "Not installed! ($Required $Comment)\n";
        }
        else {
            print color($Color)
                . 'Not installed!'
                . color('reset')
                . "$InstallText ($Required$Comment)\n";
        }
    }

    if ( $Module->{Depends} ) {
        for my $ModuleSub ( @{ $Module->{Depends} } ) {
            _Check( $ModuleSub, $Depends + 1, $NoColors );
        }
    }

    return 1;
}

sub _PackageList {
    my ($PackageList) = @_;

    my $CMD;
    my $SubCMD;
    my @Packages;

    # if we're on Windows we don't need to see Apache + mod_perl modules
    MODULE:
    for my $Module ( @{$PackageList} ) {

        my $Required = $Module->{Required};
        my $Version  = Kernel::System::Environment->ModuleVersionGet( Module => $Module->{Module} );
        if ( !$Version ) {
            my %InstallCommand = _GetInstallCommand($Module);

            if ( $Module->{Depends} ) {

                MODULESUB:
                for my $ModuleSub ( @{ $Module->{Depends} } ) {
                    my $Required          = $Module->{Required};
                    my %InstallCommandSub = _GetInstallCommand($ModuleSub);

                    next MODULESUB if !IsHashRefWithData( \%InstallCommandSub );
                    next MODULESUB if !$Required;

                    push @Packages, $InstallCommandSub{Package};
                }
            }

            next MODULE if !IsHashRefWithData( \%InstallCommand );
            next MODULE if !$Required;

            $CMD    = $InstallCommand{CMD};
            $SubCMD = $InstallCommand{SubCMD};
            push @Packages, $InstallCommand{Package};
        }
    }

    return (
        CMD      => $CMD,
        SubCMD   => $SubCMD,
        Packages => \@Packages,
    );
}

sub _VersionClean {
    my (%Param) = @_;

    return 0 if !$Param{Version};
    return 0 if $Param{Version} eq 'undef';

    # replace all special characters with an dot
    $Param{Version} =~ s{ [_-] }{.}xmsg;
    $Param{Version} =~ s{v}{}xmsg;

    my @VersionParts = split q{\.}, $Param{Version};

    my $CleanedVersion = '';
    for my $Count ( 0 .. 4 ) {
        $VersionParts[$Count] ||= 0;
        $CleanedVersion .= sprintf "%04d", $VersionParts[$Count];
    }

    return int $CleanedVersion;
}

sub _GetInstallCommand {
    my ($Module) = @_;
    my $CMD;
    my $SubCMD;
    my $Package;

    # returns the installation type e.g. ppm
    my $InstType     = $DistToInstType{$OSDist};
    my $OuputInstall = 1;

    if ($InstType) {

        # gets the install command for installation type
        # e.g. ppm install %s
        # default is the cpan install command
        # e.g. cpan %s
        $CMD    = $InstTypeToCMD{$InstType}->{CMD};
        $SubCMD = $InstTypeToCMD{$InstType}->{SubCMD};

        # gets the target package
        if (
            exists $Module->{InstTypes}->{$InstType}
            && !defined $Module->{InstTypes}->{$InstType}
            )
        {
            # if we a hash key for the installation type but a undefined value
            # then we prevent the output for the installation command
            $OuputInstall = 0;
        }
        elsif ( $InstTypeToCMD{$InstType}->{UseModule} ) {

            # default is the cpan module name
            $Package = $Module->{Module};
        }
        else {
            # if the package name is defined for the installation type
            # e.g. ppm then we use this as package name
            $Package = $Module->{InstTypes}->{$InstType};
        }
    }

    return if !$OuputInstall;

    if ( !$CMD || !$Package ) {
        $CMD     = $InstTypeToCMD{default}->{CMD};
        $SubCMD  = $InstTypeToCMD{default}->{SubCMD};
        $Package = $Module->{Module};
    }

    return (
        CMD     => $CMD,
        SubCMD  => $SubCMD,
        Package => $Package,
    );
}

exit $ExitCode;
