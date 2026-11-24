# --
# Copyright (C) 2001-2021 OTRS AG, https://otrs.com/
# Copyright (C) 2021 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see https://www.gnu.org/licenses/gpl-3.0.txt.
# --

package Kernel::GenericInterface::Mapping::XSLT;

use strict;
use warnings;
use utf8;

use Cwd                           ();
use Kernel::System::VariableCheck qw(:all);
use Storable;

our $ObjectManagerDisabled = 1;

=head1 NAME

Kernel::GenericInterface::Mapping::XSLT - GenericInterface C<XSLT> data mapping backend

=head1 PUBLIC INTERFACE

=head2 new()

usually, you want to create an instance of this
by using Kernel::GenericInterface::Mapping-E<gt>new();

=cut

sub new {
    my ( $Type, %Param ) = @_;

    # Allocate new hash for object.
    my $Self = {};
    bless( $Self, $Type );

    # Check needed params.
    for my $Needed (qw(DebuggerObject MappingConfig)) {
        if ( !$Param{$Needed} ) {
            return {
                Success      => 0,
                ErrorMessage => "Got no $Needed!"
            };
        }
        $Self->{$Needed} = $Param{$Needed};
    }

    # Check mapping config.
    if ( !IsHashRefWithData( $Param{MappingConfig} ) ) {
        return $Self->{DebuggerObject}->Error(
            Summary => 'Got no MappingConfig as hash ref with content!',
        );
    }

    # Check config - if we have a map config, it has to be a non-empty hash ref.
    if (
        defined $Param{MappingConfig}->{Config}
        && !IsHashRefWithData( $Param{MappingConfig}->{Config} )
        )
    {
        return $Self->{DebuggerObject}->Error(
            Summary => 'Got MappingConfig with Data, but Data is no hash ref with content!',
        );
    }

    return $Self;
}

=head2 Map()

Provides mapping based on C<XSLT> style sheets.
Additional data is provided by the function results from various stages in requester and provider.
This data can be included in the C<XSLT> mapping as 'DataInclude' structure via configuration.

    my $ReturnData = $MappingObject->Map(
        Data => {
            'original_key' => 'original_value',
            'another_key'  => 'next_value',
        },
        DataInclude => {
            RequesterRequestInput => { ... },
            RequesterRequestPrepareOutput => { ... },
            RequesterRequestMapOutput => { ... },
            RequesterResponseInput => { ... },
            RequesterResponseMapOutput => { ... },
            RequesterErrorHandlingOutput => { ... },
            ProviderRequestInput => { ... },
            ProviderRequestMapOutput => { ... },
            ProviderResponseInput => { ... },
            ProviderResponseMapOutput => { ... },
            ProviderErrorHandlingOutput => { ... },
        },
    }
    );

    my $ReturnData = {
        'changed_key'          => 'changed_value',
        'original_key'         => 'another_changed_value',
        'another_original_key' => 'default_value',
        'default_key'          => 'changed_value',
    };

=cut

sub Map {
    my ( $Self, %Param ) = @_;

    my $WebserviceObject = $Kernel::OM->Get('Kernel::System::GenericInterface::Webservice');
    my $ConfigObject     = $Kernel::OM->Get('Kernel::Config');

    # Check data - only accept undef or hash ref or array ref.
    if ( defined $Param{Data} && ref $Param{Data} ne 'HASH' && ref $Param{Data} ne 'ARRAY' ) {
        return $Self->{DebuggerObject}->Error(
            Summary => 'Got Data but it is not a hash or array ref in Mapping XSLT backend!'
        );
    }

    # Check included data - only accept undef or hash ref.
    if ( defined $Param{DataInclude} && !IsHashRefWithData( $Param{DataInclude} ) ) {

        return $Self->{DebuggerObject}->Error(
            Summary => 'Got DataInclude but it is not a hash ref in Mapping XSLT backend!'
        );
    }

    # Return if data is empty.
    if (
        !defined $Param{Data}
        || (
            !IsHashRefWithData( $Param{Data} )
            && !IsArrayRefWithData( $Param{Data} )
        )
        )
    {
        return {
            Success => 1,
            Data    => {},
        };
    }

    # Prepare short config variable.
    my $Config = $Self->{MappingConfig}->{Config};

    # No config means we just return input data.
    if ( !$Config || !$Config->{Template} ) {
        return {
            Success => 1,
            Data    => $Param{Data},
        };
    }

    # Load required libraries (XML::LibXML and XML::LibXSLT).
    LIBREQUIRED:
    for my $LibRequired (qw(XML::LibXML XML::LibXSLT)) {
        my $LibFound = $Kernel::OM->Get('Kernel::System::Main')->Require($LibRequired);
        next LIBREQUIRED if $LibFound;

        return $Self->{DebuggerObject}->Error(
            Summary => "Could not find required library $LibRequired",
        );
    }

    # Prepare style sheet.
    my $LibXSLT = XML::LibXSLT->new();

    # During transformation, document() is checked by these callbacks before the input callbacks open it.
    #   read_file allows only the shipped style sheets in Kernel/GenericInterface/Mapping.
    #   read_net allows only HTTPS URLs that start with a configured include prefix.
    #   Writing files or opening network connections for writing stays denied.
    #   A security callback returning 0 denies the access.
    my $DenyAccess = sub { return 0; };
    my $ReadFile   = sub {
        shift;
        my $Value = shift // '';

        return $Self->_AllowedStyleSheetFilePathGet(
            URI => $Value,
        ) ? 1 : 0;
    };
    my $ReadNet = sub {
        shift;
        my $Value = shift // '';

        return $Self->_AllowedIncludePrefixMatches(
            URL => $Value,
        ) ? 1 : 0;
    };

    my $LibXSLTSecurity = XML::LibXSLT::Security->new();

    $LibXSLTSecurity->register_callback( read_file  => $ReadFile );
    $LibXSLTSecurity->register_callback( write_file => $DenyAccess );
    $LibXSLTSecurity->register_callback( create_dir => $DenyAccess );
    $LibXSLTSecurity->register_callback( read_net   => $ReadNet );
    $LibXSLTSecurity->register_callback( write_net  => $DenyAccess );

    $LibXSLT->security_callbacks($LibXSLTSecurity);

    # The security callbacks above are only applied during transformation, but xsl:import and
    #   xsl:include are already resolved while the style sheet is parsed. Without the following
    #   input callbacks, a template could read any local file or URL via xsl:import or xsl:include.
    $LibXSLT->input_callbacks( $Self->_LibXSLTInputCallbacksGet() );

    # Remove template line breaks and white spaces to plain text lines on the fly, see bug# 14106.
    my $Template =
        $Config->{Template}
        =~ s{ > [ \t\n]+ (?= [^< \t\n] ) }{>}xmsgr
        =~ s{ (?<! [> \t\n] ) [ \t\n]+ < }{<}xmsgr;

    $Template = $WebserviceObject->WebserviceConfigReplace($Template);
    my $LibXMLHugeXMLDataSupportEnabled = $ConfigObject->Get('LibXML::EnableHugeXMLDataSupport') ? 1 : 0;

    # The same restricted parser options are used for every XML document parsed in this mapping
    #   (template, data before mapping and data after mapping), see _LibXMLParserOptionsGet().
    my %LibXMLParserOptions = $Self->_LibXMLParserOptionsGet(
        Huge => $LibXMLHugeXMLDataSupportEnabled,
    );

    my ( $StyleDoc, $StyleSheet );
    eval {
        $StyleDoc = XML::LibXML->load_xml(
            string => $Template,
            %LibXMLParserOptions,
        );
    };
    if ( !$StyleDoc ) {
        return $Self->{DebuggerObject}->Error(
            Summary => 'Could not load configured XSLT template',
            Data    => $Template,
        );
    }

    # A document type declaration (DOCTYPE) can declare external entities,
    #   e.g. <!ENTITY x SYSTEM "file:///etc/passwd">, which read local files or URLs.
    #   The parser options already prevent loading them, but a template does not need a DOCTYPE,
    #   so it is rejected completely as an additional safeguard.
    my $TemplateHasDocumentTypeDeclaration = $Self->_DocumentTypeDeclarationExists(
        Document => $StyleDoc,
    );
    if ($TemplateHasDocumentTypeDeclaration) {
        return $Self->{DebuggerObject}->Error(
            Summary => 'Configured XSLT template must not contain a document type declaration (DOCTYPE)',
            Data    => $Template,
        );
    }

    eval {
        $StyleSheet = $LibXSLT->parse_stylesheet($StyleDoc);
    };
    if ( !$StyleSheet ) {
        return $Self->{DebuggerObject}->Error(
            Summary => 'Could not parse configured XSLT template',
            Data    => $@,
        );
    }

    # Append the configured include data to the normal data structure.
    if (
        IsHashRefWithData( $Param{DataInclude} )
        && IsArrayRefWithData( $Config->{DataInclude} )
        )
    {
        my $MergedData = Storable::dclone( $Param{Data} );
        DATAINCLUDEMODULE:
        for my $DataIncludeModule ( @{ $Config->{DataInclude} } ) {
            next DATAINCLUDEMODULE if !$Param{DataInclude}->{$DataIncludeModule};

            # Clone the data include hash to prevent circular data structure references
            $MergedData->{DataInclude}->{$DataIncludeModule}
                = Storable::dclone( $Param{DataInclude}->{$DataIncludeModule} );
        }

        $Self->{DebuggerObject}->Debug(
            Summary => 'Data merged with DataInclude before mapping',
            Data    => $MergedData,
        );

        $Param{Data} = $MergedData;
    }

    # Note: XML::Simple was chosen over alternatives like XML::LibXML and XML::Dumper
    #   due to its simplicity and because we just require a straightforward conversion.
    # Other modules provide more possibilities but don't allow directly exporting a complete
    #   and clean structure.
    # Reference:
    #   http://www.perlmonks.org/?node_id=490846
    #   http://stackoverflow.com/questions/12182129/convert-string-to-hash-using-libxml-in-perl

    # XSTL regex recursion.
    if ( IsArrayRefWithData( $Config->{PreRegExFilter} ) ) {
        $Self->_RegExRecursion(
            Data   => $Param{Data},
            Config => $Config->{PreRegExFilter},
        );
        $Self->{DebuggerObject}->Debug(
            Summary => 'Data before mapping after Pre RegExFilter',
            Data    => $Param{Data},
        );
    }

    # Convert data to xml structure.
    $Kernel::OM->Get('Kernel::System::Main')->Require('XML::Simple');
    my $XMLSimple = XML::Simple->new();
    my $XMLPre;
    eval {
        no warnings;    ## no critic

        $XMLPre = $XMLSimple->XMLout(
            $Param{Data},
            AttrIndent => 1,
            ContentKey => '-content',
            NoAttr     => 1,
            KeyAttr    => [],
            RootName   => 'RootElement',
        );
    };
    if ( !$XMLPre ) {
        return $Self->{DebuggerObject}->Error(
            Summary => 'Could not convert data from Perl to XML before mapping',
            Data    => $@,
        );
    }

    # Transform xml data.
    my ( $XMLSource, $Result );
    eval {
        $XMLSource = XML::LibXML->load_xml(
            string => $XMLPre,
            %LibXMLParserOptions,
        );
    };
    if ( !$XMLSource ) {
        return $Self->{DebuggerObject}->Error(
            Summary => 'Could not load data after conversion from Perl to XML',
            Data    => $XMLPre,
        );
    }
    eval {
        $Result = $StyleSheet->transform($XMLSource);
    };
    if ( !$Result ) {
        return $Self->{DebuggerObject}->Error(
            Summary => 'Could not map data',
            Data    => $@,
        );
    }
    my $XMLPost = $StyleSheet->output_as_bytes($Result);
    if ( !$XMLPost ) {
        return $Self->{DebuggerObject}->Error(
            Summary => "Could not write mapped data",
        );
    }

    # Convert data back to perl structure.
    my $ForceArray = 0;
    if ( IsStringWithData( $Config->{ForceArray} ) ) {
        my @ForceArrayTags = split /\s+/, $Config->{ForceArray};
        $ForceArray = \@ForceArrayTags;
    }

    my $KeepAttributes = $Config->{KeepAttributes};

    # The mapped data must be checked before it is passed to XML::Simple, because XML::Simple
    #   - treats a string without XML markup as a file name and reads that file and
    #   - expands entities of a document type declaration (DOCTYPE), which can read local files or URLs.
    #   A template with <xsl:output method="text"/> can produce both.
    my $MappedDataIsSafeXML = $Self->_MappedDataIsSafeXML(
        XML           => $XMLPost,
        ParserOptions => \%LibXMLParserOptions,
    );
    if ( !$MappedDataIsSafeXML ) {
        return $Self->{DebuggerObject}->Error(
            Summary => 'Could not convert data from XML to Perl after mapping',
            Data    => [
                'Mapped data is no well-formed XML or contains a document type declaration (DOCTYPE).',
                $XMLPost,
            ],
        );
    }

    my $ReturnData;
    eval {
        $ReturnData = $XMLSimple->XMLin(
            $XMLPost,
            ForceArray   => $ForceArray,
            ContentKey   => '-content',
            NoAttr       => $KeepAttributes ? 0 : 1,
            ForceContent => $KeepAttributes ? 1 : 0,
            KeyAttr      => [],
        );
    };
    if ( !$ReturnData ) {
        return $Self->{DebuggerObject}->Error(
            Summary => 'Could not convert data from XML to Perl after mapping',
            Data    => [ $@, $XMLPost ],
        );
    }

    # XST regex recursion.
    if ( IsArrayRefWithData( $Config->{PostRegExFilter} ) ) {
        $Self->{DebuggerObject}->Debug(
            Summary => 'Data after mapping before Post RegExFilter',
            Data    => $ReturnData,
        );
        $Self->_RegExRecursion(
            Data   => $ReturnData,
            Config => $Config->{PostRegExFilter},
        );
    }

    return {
        Success => 1,
        Data    => $ReturnData,
    };
}

sub _RegExRecursion {
    my ( $Self, %Param ) = @_;

    # Data must be hash ref.
    return 1 if !IsHashRefWithData( $Param{Data} );

    KEY:
    for my $Key ( sort keys %{ $Param{Data} } ) {

        # Recurse for array data in value.
        if ( IsArrayRefWithData( $Param{Data}->{$Key} ) ) {

            ARRAYENTRY:
            for my $ArrayEntry ( @{ $Param{Data}->{$Key} } ) {
                $Self->_RegExRecursion(
                    Data   => $ArrayEntry,
                    Config => $Param{Config},
                );
            }
        }

        # Recurse directly otherwise (assume hash reference).
        else {
            $Self->_RegExRecursion(
                Data   => $Param{Data}->{$Key},
                Config => $Param{Config},
            );
        }

        # Apply configured RegEx to key.
        REGEX:
        for my $RegEx ( @{ $Param{Config} } ) {
            next REGEX if $Key !~ m{$RegEx->{Search}};

            # Get the text of the capturing groups ($1, $2, ...) of the match.
            my @CaptureGroups = $Key =~ m{$RegEx->{Search}};

            # %+ is valid only until the next regex. _CaptureGroupsInsert() runs its own regex.
            my %NamedCaptures = %+;

            # Without capturing groups in the search pattern, the match returns (1) instead of group texts.
            if ( !$#+ ) {
                @CaptureGroups = ();
            }

            # Insert the capturing groups into the configured replacement,
            #   e.g. Search = '(foo|bar)bar', Replace = '$1foo'
            #   turns 'foobar' into 'foofoo' and 'barbar' into 'barfoo'.
            #   Search = '^(?<number>\d+) (?<text>.+?)$', Replace = '_$+{text}_$+{number}'
            #   turns '16 elementname' into '_elementname_16'.
            #   Replace = '\$schema' stays the literal text '$schema'.
            # The replacement comes from the web service configuration and must never be evaluated as Perl code.
            my $Replacement = $Self->_CaptureGroupsInsert(
                Replace       => $RegEx->{Replace},
                CaptureGroups => \@CaptureGroups,
                NamedCaptures => \%NamedCaptures,
            );

            # Replace the matched part of the key. $Replacement is inserted as plain text.
            my $NewKey = $Key =~ s{$RegEx->{Search}}{$Replacement}r;

            # Skip if new key is equivalent to old key.
            next KEY if $NewKey eq $Key;

            # Replace matched key with new one.
            $Param{Data}->{$NewKey} = delete $Param{Data}->{$Key};
        }

    }

    return 1;
}

sub _CaptureGroupsInsert {
    my ( $Self, %Param ) = @_;

    my $Replace       = $Param{Replace} // '';
    my @CaptureGroups = @{ $Param{CaptureGroups} || [] };
    my %NamedCaptures = %{ $Param{NamedCaptures} || {} };
    my $Result        = '';

    # The replacement comes from the web service configuration and must never be evaluated as Perl code.
    #   \\ and \$ are resolved first, so \$1 and \$+{name} stay literal text.
    CHAR:
    while ( length $Replace ) {

        # \\ or \$. The character after \$ is not parsed as a placeholder.
        if ( $Replace =~ s{\A \\ ( \\ | \$ ) }{}xms ) {
            $Result .= $1;
            next CHAR;
        }

        # $+{name}, as in the XSLT mapping admin example.
        if ( $Replace =~ s{\A \$ \+ \{ \s* ( [A-Za-z_] \w* ) \s* \} }{}xms ) {
            my $Name = $1;

            if ( defined $NamedCaptures{$Name} ) {
                $Result .= $NamedCaptures{$Name};
            }
            next CHAR;
        }

        # ${N} or $N. Placeholders for groups that do not exist are replaced by an empty string.
        if ( $Replace =~ s{\A \$ (?: \{ ( \d+ ) \} | ( \d+ ) ) }{}xms ) {
            my $GroupNumber = $1 // $2;

            if ( $GroupNumber > 0 && defined $CaptureGroups[ $GroupNumber - 1 ] ) {
                $Result .= $CaptureGroups[ $GroupNumber - 1 ];
            }
            next CHAR;
        }

        # One literal character. With /s this also consumes a newline.
        last CHAR if $Replace !~ s{\A ( . ) }{}xms;
        $Result .= $1;
    }

    return $Result;
}

=head2 _LibXMLParserOptionsGet()

Returns the XML::LibXML parser options used for all XML documents parsed in this mapping.

The default options of XML::LibXML load external DTDs and external entities and allow
network access. A web service configuration could use this to read local files or URLs,
e.g. via E<lt>!ENTITY x SYSTEM "file:///etc/passwd"E<gt>.

    my %LibXMLParserOptions = $MappingObject->_LibXMLParserOptionsGet(
        Huge => 1,    # optional, support huge XML documents
    );

=cut

sub _LibXMLParserOptionsGet {
    my ( $Self, %Param ) = @_;

    my %LibXMLParserOptions = (

        # Existing options of this mapping.
        no_cdata => 1,
        huge     => $Param{Huge} ? 1 : 0,

        # Deny network access (http, ftp) of the parser.
        no_network => 1,

        # Do not load external DTDs.
        load_ext_dtd => 0,

        # Do not replace entities by their content.
        expand_entities => 0,

        # Even with expand_entities => 0, XML::LibXML still loads the content of external entities.
        #   Returning an empty string prevents reading any file or URL.
        ext_ent_handler => sub { return ''; },
    );

    return %LibXMLParserOptions;
}

=head2 _DocumentTypeDeclarationExists()

Checks if an XML document contains a document type declaration (DOCTYPE).

    my $DocumentTypeDeclarationExists = $MappingObject->_DocumentTypeDeclarationExists(
        Document => $LibXMLDocument,
    );

Returns 1 if a DOCTYPE exists, 0 otherwise.

=cut

sub _DocumentTypeDeclarationExists {
    my ( $Self, %Param ) = @_;

    my $Document = $Param{Document};

    # Internal subset: <!DOCTYPE Root [ ... ]>
    return 1 if $Document->internalSubset();

    # External subset: <!DOCTYPE Root SYSTEM "...">
    return 1 if $Document->externalSubset();

    return 0;
}

=head2 _MappedDataIsSafeXML()

Checks if the mapped data (the result of the XSLT transformation) can be safely passed to XML::Simple.

XML::Simple treats a string without XML markup as a file name and reads that file.
It also expands entities of a document type declaration (DOCTYPE), which can read local files or URLs.
Therefore the mapped data must be well-formed XML without a DOCTYPE.

    my $MappedDataIsSafeXML = $MappingObject->_MappedDataIsSafeXML(
        XML           => '<RootElement>...</RootElement>',
        ParserOptions => \%LibXMLParserOptions,
    );

Returns 1 if the mapped data is safe, 0 otherwise.

=cut

sub _MappedDataIsSafeXML {
    my ( $Self, %Param ) = @_;

    my $XML           = $Param{XML} // '';
    my %ParserOptions = %{ $Param{ParserOptions} || {} };

    # XML::Simple only parses the string as XML if it contains markup, otherwise it opens it as a file.
    #   Requiring the string to start with "<" makes sure it is never used as a file name.
    return 0 if $XML !~ m{\A \s* <}xms;

    # Parse the mapped data with the restricted parser options to make sure it is well-formed XML.
    my $Document;
    eval {
        $Document = XML::LibXML->load_xml(
            string => $XML,
            %ParserOptions,
        );
    };
    return 0 if !$Document;

    # The parser of XML::Simple would expand the entities of a DOCTYPE.
    my $DocumentTypeDeclarationExists = $Self->_DocumentTypeDeclarationExists(
        Document => $Document,
    );
    return 0 if $DocumentTypeDeclarationExists;

    return 1;
}

=head2 _AllowedIncludePrefixMatches()

Returns true when the URL starts with a configured HTTPS include prefix.

The prefix is compared exactly, including case. Entries that do not start with https:// are ignored.

    my $Matches = $MappingObject->_AllowedIncludePrefixMatches(
        URL => 'https://znuny.de/mapping/functions.xsl',
    );

=cut

sub _AllowedIncludePrefixMatches {
    my ( $Self, %Param ) = @_;

    my $URL = $Param{URL} // '';

    return if $URL !~ m{\A https:// }xms;

    my $Prefixes = $Self->_AllowedIncludePrefixesGet();

    PREFIX:
    for my $Prefix ( @{$Prefixes} ) {
        return 1 if index( $URL, $Prefix ) == 0;
    }

    return;
}

sub _AllowedIncludePrefixesGet {
    my ( $Self, %Param ) = @_;

    return $Self->{AllowedIncludePrefixes} if ref $Self->{AllowedIncludePrefixes} eq 'ARRAY';

    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');
    my $LogObject    = $Kernel::OM->Get('Kernel::System::Log');

    my @Prefixes;
    my $ConfiguredPrefixes = $ConfigObject->Get('GenericInterface::Mapping::XSLT::AllowedIncludeURLPrefixes');

    if ( IsArrayRefWithData($ConfiguredPrefixes) ) {
        CONFIGUREDPREFIX:
        for my $Prefix ( @{$ConfiguredPrefixes} ) {
            next CONFIGUREDPREFIX if !IsStringWithData($Prefix);

            if ( $Prefix !~ m{\A https:// }xms ) {
                $LogObject->Log(
                    Priority => 'error',
                    Message  =>
                        "GenericInterface::Mapping::XSLT::AllowedIncludeURLPrefixes entry '$Prefix' does not start with https:// and is ignored.",
                );
                next CONFIGUREDPREFIX;
            }

            push @Prefixes, $Prefix;
        }
    }

    $Self->{AllowedIncludePrefixes} = \@Prefixes;

    return \@Prefixes;
}

=head2 _NetworkIncludeContentGet()

Downloads an HTTPS resource that matches a configured include prefix.

Redirects are followed only when the target URL also matches a configured prefix.

    my $ContentRef = $MappingObject->_NetworkIncludeContentGet(
        URL => 'https://znuny.de/mapping/functions.xsl',
    );

Returns a scalar reference to the response body, or undef when the URL is not allowed or the request fails.

=cut

sub _NetworkIncludeContentGet {
    my ( $Self, %Param ) = @_;

    my $MainObject         = $Kernel::OM->Get('Kernel::System::Main');
    my $WebUserAgentObject = $Kernel::OM->Get('Kernel::System::WebUserAgent');

    my $URL           = $Param{URL} // '';
    my $RedirectLimit = 5;

    return if !$MainObject->Require('URI');

    REDIRECT:
    for my $RedirectCount ( 0 .. $RedirectLimit ) {
        return if !$Self->_AllowedIncludePrefixMatches(
            URL => $URL,
        );

        my %Response = $WebUserAgentObject->Request(
            URL        => $URL,
            NoLog      => 1,
            NoRedirect => 1,
        );

        my $Status = $Response{Status} // '';

        if ( $Status =~ m{\A 30[12378] \b}xms ) {
            return if $RedirectCount == $RedirectLimit;
            return if !IsStringWithData( $Response{Location} );

            $URL = URI->new_abs( $Response{Location}, $URL )->as_string();
            next REDIRECT;
        }

        return if $Status !~ m{\A 2 \d\d \b}xms;
        return if ref $Response{Content} ne 'SCALAR';

        return $Response{Content};
    }

    return;
}

=head2 _LibXSLTInputCallbacksGet()

Returns the input callbacks for XML::LibXSLT, which restrict the resources the XSLT processor may load
while parsing the style sheet (e.g. via xsl:import or xsl:include) and while loading document().

Style sheets shipped in Kernel/GenericInterface/Mapping (e.g. ZnunyFunctions.xsl) may be loaded.
HTTPS URLs may be loaded when they start with a prefix in GenericInterface::Mapping::XSLT::AllowedIncludeURLPrefixes.
All other files and URLs are denied.

    my $LibXMLInputCallback = $MappingObject->_LibXSLTInputCallbacksGet();

    $LibXSLT->input_callbacks($LibXMLInputCallback);

=cut

sub _LibXSLTInputCallbacksGet {
    my ( $Self, %Param ) = @_;

    my $LibXMLInputCallback = XML::LibXML::InputCallback->new();

    # Responsible for every URI. If no input callback is responsible for a URI,
    #   libxml2 falls back to its default handlers, which read any file or URL.
    my $MatchCallback = sub {
        return 1;
    };

    # Opens the requested style sheet or HTTPS resource if it is allowed, otherwise dies.
    #   The error message is returned as error of parse_stylesheet() or of the transformation.
    my $OpenCallback = sub {
        my $URI = shift // '';

        # libxml2 looks up the system catalog through this callback while parsing a stylesheet
        #   that was not loaded from a local path. Return an empty catalog. The real catalog file is not read.
        if ( $URI eq 'file:///etc/xml/catalog' ) {
            my $EmptyCatalog = '<?xml version="1.0"?><catalog xmlns="urn:oasis:names:tc:entity:xmlns:xml:catalog"/>';

            open my $CatalogHandle, '<', \$EmptyCatalog;    ## no critic
            return $CatalogHandle;
        }

        if ( $URI =~ m{\A https:// }xms ) {
            my $ContentRef = $Self->_NetworkIncludeContentGet(
                URL => $URI,
            );
            if ( ref $ContentRef ne 'SCALAR' ) {
                die "Access to '$URI' is not allowed in XSLT mapping.\n";
            }

            my $FileHandle;
            if ( !open $FileHandle, '<', $ContentRef ) {    ## no critic
                die "Could not open '$URI' in XSLT mapping.\n";
            }

            return $FileHandle;
        }

        my $StyleSheetFilePath = $Self->_AllowedStyleSheetFilePathGet(
            URI => $URI,
        );
        if ( !$StyleSheetFilePath ) {
            die "Access to '$URI' is not allowed in XSLT mapping.\n";
        }

        my $FileHandle;
        if ( !open $FileHandle, '<', $StyleSheetFilePath ) {    ## no critic
            die "Could not open '$URI' in XSLT mapping.\n";
        }

        return $FileHandle;
    };

    my $ReadCallback = sub {
        my ( $FileHandle, $Length ) = @_;

        my $Buffer = '';
        read $FileHandle, $Buffer, $Length;

        return $Buffer;
    };

    my $CloseCallback = sub {
        my $FileHandle = shift;

        close $FileHandle;

        return 1;
    };

    $LibXMLInputCallback->register_callbacks(
        [ $MatchCallback, $OpenCallback, $ReadCallback, $CloseCallback ]
    );

    return $LibXMLInputCallback;
}

=head2 _AllowedStyleSheetFilePathGet()

Returns the real file path of a URI requested by the XSLT processor (e.g. via xsl:import),
if it points to a style sheet shipped in Kernel/GenericInterface/Mapping.

    my $StyleSheetFilePath = $MappingObject->_AllowedStyleSheetFilePathGet(
        URI => '/opt/znuny/Kernel/GenericInterface/Mapping/ZnunyFunctions.xsl',
    );

Returns the real file path if allowed, undef otherwise (e.g. for other files or URLs).

=cut

sub _AllowedStyleSheetFilePathGet {
    my ( $Self, %Param ) = @_;

    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');

    my $URI  = $Param{URI} // '';
    my $Home = $ConfigObject->Get('Home');

    # Local files can be requested with or without "file://".
    my $FilePath = $URI =~ s{\A file:// }{}xmsr;

    # Deny all other URI schemes, e.g. http, https or ftp, to prevent requests to other servers.
    return if $FilePath =~ m{\A [a-z][a-z0-9+.-]* : }xmsi;

    # Compare real paths (symbolic links and ".." resolved) to prevent leaving the allowed directory,
    #   e.g. via Kernel/GenericInterface/Mapping/../../Config.pm.
    my $AllowedDirectory = Cwd::realpath("$Home/Kernel/GenericInterface/Mapping");
    my $RealFilePath     = Cwd::realpath($FilePath);

    return if !$AllowedDirectory;
    return if !$RealFilePath;

    # Only style sheets (*.xsl) directly in the allowed directory are allowed.
    return if $RealFilePath !~ m{\A \Q$AllowedDirectory\E / [^/]+ \.xsl \z}xms;

    return $RealFilePath;
}

1;

=head1 TERMS AND CONDITIONS

This software is part of the OTRS project (L<https://otrs.org/>).

This software comes with ABSOLUTELY NO WARRANTY. For details, see
the enclosed file COPYING for license information (GPL). If you
did not receive this file, see L<https://www.gnu.org/licenses/gpl-3.0.txt>.

=cut
