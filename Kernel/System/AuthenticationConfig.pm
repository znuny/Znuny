# --
# Copyright (C) 2021 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --
package Kernel::System::AuthenticationConfig;

use strict;
use warnings;

use utf8;

use Kernel::Language qw(Translatable);

our @ObjectDependencies = (
    'Kernel::Config',
    'Kernel::System::Log',
    'Kernel::System::Main',
    'Kernel::System::SystemData',
    'Kernel::System::VirtualFS',
);

use parent qw(Kernel::System::DBCRUD);

=head1 NAME

Kernel::System::AuthenticationConfig - AuthenticationConfig lib

=head1 SYNOPSIS

Manages staged authentication configurations for the agent and customer
interfaces, and their deployment to
Kernel/Config/Files/ZZZZnunyGeneratedAuthentication.pm.

Each config row has a C<Type> (e.g. C<SAML>) that resolves to a registered
plugin module (see C<AuthenticationConfig::Plugin###&lt;Type&gt;> in SysConfig,
mirroring how C<DynamicFields::Driver###&lt;Type&gt;> resolves DynamicField
backends) which implements everything specific to that authentication type:
certificate/metadata handling, and the actual config lines to deploy. This
class only knows the generic parts: CRUD, slot bookkeeping, revision
tracking, and orchestrating the deploy across all rows regardless of type.

=head1 PUBLIC INTERFACE

=head2 new()

create an object

    my $AuthenticationConfigObject = $Kernel::OM->Get('Kernel::System::AuthenticationConfig');

=cut

=head2 InitConfig()

init config for object

=cut

sub InitConfig {
    my ( $Self, %Param ) = @_;

    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');

    $Self->{Columns} = {
        ID => {
            Column       => 'id',
            SearchTarget => 0,
        },
        Name => {
            Column       => 'name',
            SearchTarget => 1,
            ImportID     => 1,
        },
        Type => {
            Column       => 'type',
            SearchTarget => 0,
        },
        Context => {
            Column       => 'context_type',
            SearchTarget => 0,
        },
        Slot => {
            Column       => 'slot',
            SearchTarget => 0,
        },
        AuthConfig => {
            Column       => 'auth_config',
            SearchTarget => 0,
            ContentJSON  => 1,
            DisableWhere => 1,
        },
        SyncEnabled => {
            Column       => 'sync_enabled',
            SearchTarget => 0,
        },
        SyncConfig => {
            Column       => 'sync_config',
            SearchTarget => 0,
            ContentJSON  => 1,
            DisableWhere => 1,
        },
        ValidID => {
            Column       => 'valid_id',
            SearchTarget => 0,
        },
        CreateTime => {
            Column       => 'create_time',
            SearchTarget => 0,
            TimeStampAdd => 1,
        },
        CreateBy => {
            Column       => 'create_by',
            SearchTarget => 0,
        },
        ChangeTime => {
            Column          => 'change_time',
            SearchTarget    => 0,
            TimeStampUpdate => 1,
            TimeStampAdd    => 1,
        },
        ChangeBy => {
            Column       => 'change_by',
            SearchTarget => 0,
        },
    };

    # base table configuration
    $Self->{Name}           = 'AuthenticationConfig';
    $Self->{Identifier}     = 'ID';
    $Self->{DatabaseTable}  = 'authentication_config';
    $Self->{DefaultSortBy}  = 'Name';
    $Self->{DefaultOrderBy} = 'ASC';
    $Self->{CacheType}      = 'AuthenticationConfig';
    $Self->{CacheTTL}       = $ConfigObject->Get( 'DBCRUD::' . $Self->{Name} . '::CacheTTL' ) || 60 * 60 * 8;

    $Self->{UserIDCheck} = 1;

    $Self->{AutoCreateMissingUUIDDatabaseTableColumns} = 1;

    # Oracle stores an empty string as NULL, which the NOT NULL slot column rejects,
    # so the default slot ('') is stored as this value instead.
    $Self->{DefaultSlotDBValue} = 'D';

    # base function activation
    $Self->{FunctionDataAdd}     = 1;
    $Self->{FunctionDataUpdate}  = 1;
    $Self->{FunctionDataGet}     = 1;
    $Self->{FunctionDataListGet} = 1;
    $Self->{FunctionDataDelete}  = 1;
    $Self->{FunctionDataSearch}  = 1;

    return 1;
}

=head2 DataAdd()

Adds an authentication config. See Kernel::System::DBCRUD::DataAdd() for
parameters. Bumps the internal revision counter used by IsDeploySynced().

The default slot is passed and returned as '' by all methods of this
class, but stored as 'D' in the database.

=cut

sub DataAdd {
    my ( $Self, %Param ) = @_;

    if ( exists $Param{Slot} ) {
        $Param{Slot} = $Self->_SlotToDB( $Param{Slot} );
    }

    my $ID = $Self->SUPER::DataAdd(%Param);
    return $ID if !$ID;

    $Self->_RevisionBump( UserID => $Param{UserID} );

    return $ID;
}

=head2 DataUpdate()

Updates an authentication config. See Kernel::System::DBCRUD::DataUpdate()
for parameters. Bumps the internal revision counter used by
IsDeploySynced().

=cut

sub DataUpdate {
    my ( $Self, %Param ) = @_;

    if ( exists $Param{Slot} ) {
        $Param{Slot} = $Self->_SlotToDB( $Param{Slot} );
    }

    my $Success = $Self->SUPER::DataUpdate(%Param);
    return $Success if !$Success;

    $Self->_RevisionBump( UserID => $Param{UserID} );

    return $Success;
}

=head2 DataGet()

Returns an authentication config. See Kernel::System::DBCRUD::DataGet() for
parameters.

=cut

sub DataGet {
    my ( $Self, %Param ) = @_;

    if ( exists $Param{Slot} ) {
        $Param{Slot} = $Self->_SlotToDB( $Param{Slot} );
    }

    my %Data = $Self->SUPER::DataGet(%Param);
    return %Data if !%Data;

    $Data{Slot} = $Self->_SlotFromDB( $Data{Slot} );

    return %Data;
}

=head2 DataListGet()

Returns a list of authentication configs. See
Kernel::System::DBCRUD::DataListGet() for parameters.

=cut

sub DataListGet {
    my ( $Self, %Param ) = @_;

    if ( exists $Param{Slot} ) {
        $Param{Slot} = $Self->_SlotToDB( $Param{Slot} );
    }

    my @List = $Self->SUPER::DataListGet(%Param);

    # Copies, the rows may be references into the cache.
    return map { +{ %{$_}, Slot => $Self->_SlotFromDB( $_->{Slot} ) } } @List;
}

=head2 DataDelete()

Deletes an authentication config, cleaning up any certificate/key files
stored in VirtualFS for it (as reported by its type's plugin), and bumps the
internal revision counter used by IsDeploySynced().

=cut

sub DataDelete {
    my ( $Self, %Param ) = @_;

    if ( defined $Param{ $Self->{Identifier} } ) {
        my %Data = $Self->DataGet(
            $Self->{Identifier} => $Param{ $Self->{Identifier} },
            UserID              => $Param{UserID},
        );

        if (%Data) {
            my $Plugin = $Self->_PluginForRow( \%Data );

            if ($Plugin) {
                my $VirtualFSObject = $Kernel::OM->Get('Kernel::System::VirtualFS');
                my $AuthConfig      = $Data{AuthConfig} || {};

                VFSKEY:
                for my $Key ( $Plugin->VFSFilenameKeys() ) {
                    next VFSKEY if !$AuthConfig->{$Key};
                    next VFSKEY if $AuthConfig->{$Key} !~ m{\AVirtualFS::AuthenticationConfig::};

                    # Certificates/keys are stored content-addressed and may be shared by more
                    # than one config (e.g. the same IdP CA cert used for both an agent and a
                    # customer config). Only delete the VirtualFS blob if no other config still
                    # references it.
                    next VFSKEY if $Self->VFSFilenameInUse(
                        Filename  => $AuthConfig->{$Key},
                        ExcludeID => $Data{ID},
                        UserID    => $Param{UserID},
                    );

                    $VirtualFSObject->Delete(
                        Filename        => $AuthConfig->{$Key},
                        DisableWarnings => 1,
                    );
                }
            }
        }
    }

    my $Success = $Self->SUPER::DataDelete(%Param);
    return $Success if !$Success;

    $Self->_RevisionBump( UserID => $Param{UserID} );

    return $Success;
}

=head2 SlotStatusList()

Returns, for every possible AuthModule/Customer::AuthModule slot ('', 1..10),
whether it is Free, Ours (managed by one of our own rows) or Locked
(resolves to a value via the effective Kernel::Config, but not one of our
own tracked rows).

    my $SlotStatus = $AuthenticationConfigObject->SlotStatusList(
        Context => 'Agent',    # or 'Customer'
        UserID  => 1,
    );

Returns:

    my $SlotStatus = {
        '' => {
            State                    => 'Locked',      # Free|Ours|Locked
            AuthenticationConfigID   => 3,              # only set for State => 'Ours'
            AuthenticationConfigName => 'My Config',    # only set for State => 'Ours'
            SyncLocked               => 1,              # Agent context only
        },
        1 => {
            State => 'Free',
        },
        # ...
    };

=cut

sub SlotStatusList {
    my ( $Self, %Param ) = @_;

    my $LogObject = $Kernel::OM->Get('Kernel::System::Log');

    NEEDED:
    for my $Needed (qw(Context UserID)) {
        next NEEDED if defined $Param{$Needed} && length $Param{$Needed};

        $LogObject->Log(
            Priority => 'error',
            Message  => "Need $Needed!",
        );
        return;
    }

    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');

    my $ConfigKeyBase = $Param{Context} eq 'Agent' ? 'AuthModule' : 'Customer::AuthModule';

    my @Rows = $Self->DataListGet(
        Context => $Param{Context},
        UserID  => $Param{UserID},
    );

    my %OurSlots = map { $_->{Slot} => $_ } @Rows;

    my %Status;

    SLOT:
    for my $Slot ( '', 1 .. 10 ) {
        my $AuthValue = $ConfigObject->Get("$ConfigKeyBase$Slot");
        my $IsOurs    = exists $OurSlots{$Slot};

        if ($IsOurs) {
            $Status{$Slot} = {
                State                    => 'Ours',
                AuthenticationConfigID   => $OurSlots{$Slot}->{ID},
                AuthenticationConfigName => $OurSlots{$Slot}->{Name},
            };
        }
        elsif ( defined $AuthValue && length $AuthValue ) {
            $Status{$Slot} = {
                State => 'Locked',
            };
        }
        else {
            $Status{$Slot} = {
                State => 'Free',
            };
        }

        next SLOT if $Param{Context} ne 'Agent';
        next SLOT if $Status{$Slot}->{State} eq 'Locked';

        my $SyncValue  = $ConfigObject->Get("AuthSyncModule$Slot");
        my $SyncIsOurs = $IsOurs && $OurSlots{$Slot}->{SyncEnabled};

        if ( defined $SyncValue && length $SyncValue && !$SyncIsOurs ) {
            $Status{$Slot}->{SyncLocked} = 1;
        }
    }

    return \%Status;
}

=head2 VFSFilenameUsedBy()

Returns the authentication config rows that still reference a given
VirtualFS filename (as stored in a config's AuthConfig under one of its
type's VFSFilenameKeys()), across all rows, not just the one currently
being edited. Certificates/keys are stored content-addressed and may be
shared by more than one config, so this must be checked before deleting a
blob that's being replaced or removed, and is also used to surface "used
by" information about a shared certificate/key.

    my $UsedBy = $AuthenticationConfigObject->VFSFilenameUsedBy(
        Filename  => 'VirtualFS::AuthenticationConfig::SAML::IdPCACert::...',
        ExcludeID => 3,  # optional
        UserID    => 1,
    );

Returns an arrayref of hashrefs, one per config row still referencing it:
ID, Name, Context, Slot.

=cut

sub VFSFilenameUsedBy {
    my ( $Self, %Param ) = @_;

    my @Rows = $Self->DataListGet(
        UserID => $Param{UserID},
    );

    my @UsedBy;

    ROW:
    for my $Row (@Rows) {
        next ROW if $Param{ExcludeID} && $Row->{ID} == $Param{ExcludeID};

        my $Plugin = $Self->_PluginForRow($Row);
        next ROW if !$Plugin;

        my $AuthConfig = $Row->{AuthConfig} || {};

        KEY:
        for my $Key ( $Plugin->VFSFilenameKeys() ) {
            next KEY if !$AuthConfig->{$Key};
            next KEY if $AuthConfig->{$Key} ne $Param{Filename};

            push @UsedBy, {
                ID      => $Row->{ID},
                Name    => $Row->{Name},
                Context => $Row->{Context},
                Slot    => $Row->{Slot},
            };
            next ROW;
        }
    }

    return \@UsedBy;
}

=head2 VFSFilenameInUse()

Boolean shorthand for VFSFilenameUsedBy() above - see there for parameters.

=cut

sub VFSFilenameInUse {
    my ( $Self, %Param ) = @_;

    return @{ $Self->VFSFilenameUsedBy(%Param) } ? 1 : 0;
}

=head2 SortedList()

Returns all authentication configs for a given context, sorted by slot ('' first,
then 1..10 numerically).

    my @Configs = $AuthenticationConfigObject->SortedList(
        Context => 'Agent',    # or 'Customer'
        UserID  => 1,
    );

=cut

sub SortedList {
    my ( $Self, %Param ) = @_;

    my @Rows = $Self->DataListGet(
        Context => $Param{Context},
        UserID  => $Param{UserID},
    );

    my @Sorted = sort { ( $a->{Slot} || 0 ) <=> ( $b->{Slot} || 0 ) } @Rows;

    return @Sorted;
}

=head2 IsDeploySynced()

Checks whether the currently deployed ZZZZnunyGeneratedAuthentication.pm
reflects the latest saved state of all authentication configs.

    my $IsSynced = $AuthenticationConfigObject->IsDeploySynced();

=cut

sub IsDeploySynced {
    my ( $Self, %Param ) = @_;

    my $SystemDataObject = $Kernel::OM->Get('Kernel::System::SystemData');

    my $Revision         = $SystemDataObject->SystemDataGet( Key => 'AuthenticationConfig::Revision' )             || 0;
    my $DeployedRevision = $SystemDataObject->SystemDataGet( Key => 'AuthenticationConfig::LastDeployedRevision' ) || 0;

    return $Revision == $DeployedRevision ? 1 : 0;
}

=head2 Deploy()

Regenerates Kernel/Config/Files/ZZZZnunyGeneratedAuthentication.pm from
scratch, based on every currently valid authentication config, delegating
everything type-specific (certificate materialization, actual config lines)
to each row's plugin.

    my @Errors;
    my $Location = $AuthenticationConfigObject->Deploy(
        UserID => 1,
        Errors => \@Errors,    # optional, gets one entry per config that could not be deployed
    );

Returns the location of the written file, or undef on error. Nothing is
written if any valid config can't be deployed, the previously deployed file
stays active then. In that case @Errors contains:

    (
        {
            ID      => 123,
            Context => 'Agent',
            Name    => 'My SAML config',
            Message => 'Could not read the IdP CA certificate.',
        },
    )

=cut

sub Deploy {
    my ( $Self, %Param ) = @_;

    my $LogObject        = $Kernel::OM->Get('Kernel::System::Log');
    my $ConfigObject     = $Kernel::OM->Get('Kernel::Config');
    my $MainObject       = $Kernel::OM->Get('Kernel::System::Main');
    my $SystemDataObject = $Kernel::OM->Get('Kernel::System::SystemData');

    if ( !$Param{UserID} ) {
        $LogObject->Log(
            Priority => 'error',
            Message  => 'Need UserID!',
        );
        return;
    }

    my $Revision = $SystemDataObject->SystemDataGet( Key => 'AuthenticationConfig::Revision' ) || 0;

    my @Rows = $Self->DataListGet(
        ValidID => 1,
        UserID  => $Param{UserID},
    );

    # Check every row before writing anything, so a broken config never leaves a
    # half-deployed state behind.
    my @Errors;
    my @Prepared;

    ROW:
    for my $Row ( sort { $a->{Context} cmp $b->{Context} || $a->{Slot} cmp $b->{Slot} } @Rows ) {
        my $Plugin = $Self->_PluginForRow($Row);
        if ( !$Plugin ) {
            push @Errors, {
                ID      => $Row->{ID},
                Context => $Row->{Context},
                Name    => $Row->{Name},
                Message => Translatable('No authentication plugin is registered for this type.'),
            };
            next ROW;
        }

        my %Prepared = $Plugin->PrepareCertificates( Row => $Row );
        if ( !$Prepared{Success} ) {
            push @Errors, {
                ID      => $Row->{ID},
                Context => $Row->{Context},
                Name    => $Row->{Name},
                Message => $Prepared{Message},
            };
            next ROW;
        }

        push @Prepared, {
            Row          => $Row,
            Plugin       => $Plugin,
            Certificates => $Prepared{Certificates},
        };
    }

    my $Output = '';

    ENTRY:
    for my $Entry (@Prepared) {
        last ENTRY if @Errors;

        my $MaterializeSuccess = $Entry->{Plugin}->MaterializeCertificates(
            Row          => $Entry->{Row},
            Certificates => $Entry->{Certificates},
        );
        if ( !$MaterializeSuccess ) {
            push @Errors, {
                ID      => $Entry->{Row}->{ID},
                Context => $Entry->{Row}->{Context},
                Name    => $Entry->{Row}->{Name},
                Message => Translatable('Could not write the certificate files.'),
            };
            last ENTRY;
        }

        $Output .= $Entry->{Plugin}->DeployConfigLines( Row => $Entry->{Row} );
    }

    if (@Errors) {
        for my $Error (@Errors) {
            $LogObject->Log(
                Priority => 'error',
                Message  => "Authentication config '$Error->{Name}' could not be deployed: $Error->{Message}",
            );
        }

        if ( ref $Param{Errors} eq 'ARRAY' ) {
            push @{ $Param{Errors} }, @Errors;
        }

        return;
    }

    # build comment (therefore we need to trick out the filter)
    my $FileStart = <<'EOF';
# Znuny config file (automatically generated)
# VERSION:1.1
package Kernel::Config::Files::ZZZZnunyGeneratedAuthentication;
use strict;
use warnings;
no warnings 'redefine'; ## no critic
use utf8;
sub Load {
    my ($File, $Self) = @_;

EOF

    my $FileEnd = <<'EOF';
    return;
}
1;
EOF

    $Output = $FileStart . $Output . $FileEnd;

    my $Home     = $ConfigObject->Get('Home');
    my $Location = "$Home/Kernel/Config/Files/ZZZZnunyGeneratedAuthentication.pm";

    my $FileLocation = $MainObject->FileWrite(
        Location => $Location,
        Content  => \$Output,
        Mode     => 'utf8',
        Type     => 'Local',
    );
    return if !$FileLocation;

    if ( defined $SystemDataObject->SystemDataGet( Key => 'AuthenticationConfig::LastDeployedRevision' ) ) {
        $SystemDataObject->SystemDataUpdate(
            Key    => 'AuthenticationConfig::LastDeployedRevision',
            Value  => $Revision,
            UserID => $Param{UserID},
        );
    }
    else {
        $SystemDataObject->SystemDataAdd(
            Key    => 'AuthenticationConfig::LastDeployedRevision',
            Value  => $Revision,
            UserID => $Param{UserID},
        );
    }

    return $FileLocation;
}

=head2 DumpAssignment()

Dumps a single Perl value as a hash accessor assignment line, for plugins
to build their Deploy() output with (see the example below). Generic
Data::Dumper-style utility, no authentication-type awareness.

    my $Line = $AuthenticationConfigObject->DumpAssignment(
        Accessor => "\$Self->{'AuthModule::SAML::Issuer1'}",
        Value    => 'https://sp.example.com',
    );

=cut

sub DumpAssignment {
    my ( $Self, %Param ) = @_;

    my $Dump = $Kernel::OM->Get('Kernel::System::Main')->Dump( $Param{Value} );
    $Dump =~ s{\$VAR1}{$Param{Accessor}}mxs;

    return $Dump . "\n";
}

=head2 EmitConfigLines()

Emits one DumpAssignment() line per non-empty key in a config hashref, using
a common accessor prefix/slot suffix. Generic utility used by plugins to
turn their AuthConfig/SyncConfig hashes into deploy output.

    my $Lines = $AuthenticationConfigObject->EmitConfigLines(
        Config   => $Row->{AuthConfig},
        Prefix   => 'AuthModule::SAML::',
        Slot     => $Row->{Slot},
        SkipKeys => { MetaDataSourceType => 1 },
    );

=cut

sub EmitConfigLines {
    my ( $Self, %Param ) = @_;

    my $Output = '';

    KEY:
    for my $Key ( sort keys %{ $Param{Config} } ) {
        next KEY if $Param{SkipKeys}->{$Key};

        my $Value = $Param{Config}->{$Key};
        next KEY if !$Self->_KeyHasContent($Value);

        $Output .= $Self->DumpAssignment(
            Accessor => "\$Self->{'" . $Param{Prefix} . $Key . $Param{Slot} . "'}",
            Value    => $Value,
        );
    }

    return $Output;
}

=begin Internal:

=cut

sub _RevisionBump {
    my ( $Self, %Param ) = @_;

    my $SystemDataObject = $Kernel::OM->Get('Kernel::System::SystemData');

    my $CurrentValue = $SystemDataObject->SystemDataGet( Key => 'AuthenticationConfig::Revision' );
    my $Revision     = ( $CurrentValue || 0 ) + 1;

    if ( defined $CurrentValue ) {
        $SystemDataObject->SystemDataUpdate(
            Key    => 'AuthenticationConfig::Revision',
            Value  => $Revision,
            UserID => $Param{UserID} || 1,
        );
    }
    else {
        $SystemDataObject->SystemDataAdd(
            Key    => 'AuthenticationConfig::Revision',
            Value  => $Revision,
            UserID => $Param{UserID} || 1,
        );
    }

    return 1;
}

sub _SlotToDB {
    my ( $Self, $Slot ) = @_;

    return $Slot if !defined $Slot;
    return $Slot if length $Slot;

    return $Self->{DefaultSlotDBValue};
}

sub _SlotFromDB {
    my ( $Self, $Slot ) = @_;

    return $Slot if !defined $Slot;
    return ''    if $Slot eq $Self->{DefaultSlotDBValue};

    return $Slot;
}

sub _KeyHasContent {
    my ( $Self, $Value ) = @_;

    return 0 if !defined $Value;
    return %{$Value}     ? 1 : 0 if ref $Value eq 'HASH';
    return @{$Value}     ? 1 : 0 if ref $Value eq 'ARRAY';
    return length $Value ? 1 : 0;
}

=end Internal:

=cut

=head2 _PluginForRow()

Resolves the plugin object for a config row, based on its Type. See
_PluginForType().

=cut

sub _PluginForRow {
    my ( $Self, $Row ) = @_;

    return $Self->_PluginForType( $Row->{Type} );
}

=head2 _PluginForType()

Resolves and caches the plugin object registered for a given Type via
C<AuthenticationConfig::Plugin###&lt;Type&gt;> SysConfig settings (the same
registration shape C<DynamicFields::Driver###&lt;Type&gt;> uses for
DynamicField backends).

    my $Plugin = $AuthenticationConfigObject->_PluginForType('SAML');

=cut

sub _PluginForType {
    my ( $Self, $Type ) = @_;

    my $LogObject = $Kernel::OM->Get('Kernel::System::Log');

    if ( !$Type ) {
        $LogObject->Log(
            Priority => 'error',
            Message  => 'Need Type!',
        );
        return;
    }

    return $Self->{PluginCache}->{$Type} if $Self->{PluginCache}->{$Type};

    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');
    my $MainObject   = $Kernel::OM->Get('Kernel::System::Main');

    my $PluginConfig = $ConfigObject->Get('AuthenticationConfig::Plugin') || {};
    my $Module       = $PluginConfig->{$Type}->{Module};

    if ( !$Module ) {
        $LogObject->Log(
            Priority => 'error',
            Message  => "No authentication plugin registered for type '$Type'!",
        );
        return;
    }

    return if !$MainObject->Require($Module);

    my $Plugin = $Kernel::OM->Get($Module);
    $Self->{PluginCache}->{$Type} = $Plugin;

    return $Plugin;
}

1;
