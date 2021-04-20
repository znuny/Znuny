# --
# Kernel/System/Cache/Memcached.pm - Memcached module for OTRS cache
# Copyright (C) 2014-2021 Informatyka Boguslawski sp. z o.o. sp.k., http://www.ib.pl/
# Based on:
#   http://code.google.com/p/memcached/wiki/NewProgrammingTricks#Namespacing
#   FileStorable.pm by OTRS AG, http://otrs.com/
#   Memcached.pm by c.a.p.e. IT GmbH, http://www.cape-it.de
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see https://www.gnu.org/licenses/gpl-3.0.txt.
# --

package Kernel::System::Cache::Memcached;

use strict;
use warnings;

use Cache::Memcached::Fast;
use Digest::MD5 qw();
use Time::HiRes qw();

our @ObjectDependencies = (
    'Kernel::Config',
    'Kernel::System::Encode',
    'Kernel::System::Log',
);

sub new {
    my ( $Type, %Param ) = @_;

    # Allocate new hash for object.
    my $Self = {};
    bless( $Self, $Type );

    # 0=off; 1=writes; 2=+reads; 3=+connects;
    $Self->{Debug} = $Param{Debug} || 0;

    # Get config object.
    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');

    # Get memcached connection parameters and open connection to cache.
    $Self->{Config} = $ConfigObject->Get('Cache::Module::Memcached');
    if ($Self->{Config} && $Self->{Config}->{Servers} && $Self->{Config}->{Parameters}) {
        my $InitParams = {
            servers => $Self->{Config}->{Servers},
            %{ $Self->{Config}->{Parameters} },
        };

        $Self->{MemcachedObject} = Cache::Memcached::Fast->new($InitParams);

        if (!$Self->{MemcachedObject}) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Unable to initialize memcached connector: $!",
            );
        }
    }
    else {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => 'Memcached enabled but no valid Cache::Module::Memcached configuration found!',
        );
    }

    return $Self;
}

sub Disconnect {
    my $Self = shift;

    # Debug.
    if ( $Self->{Debug} > 2 ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Caller   => 1,
            Priority => 'debug',
            Message  => 'Memcached.pm->Disconnect',
        );
    }

    # Do disconnect.
    if ( $Self->{MemcachedObject} ) {
        $Self->{MemcachedObject}->disconnect_all();
        delete $Self->{MemcachedObject};
    }

    return 1;
}


sub Set {
    my ( $Self, %Param ) = @_;

    # Check needed params.
    for my $Needed (qw(Type Key Value TTL)) {
        if ( !defined $Param{$Needed} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Needed!"
            );
            return;
        }
    }

    return if !$Self->{MemcachedObject};

    # Get memcached key name for given Type and Key.
    my $MemcachedKeyName = $Self->_GetMemcachedKeyName(
        %Param,
        InitNamespaceOnError => 1,
    );
    return if !$MemcachedKeyName;

    # Problems occured when using absolute TTLs /time()+$Param{TTL}/ and
    # relative TTLs greater than memcached threshold /$Param{TTL}>2592000/
    # so we'll limit TTLs to 2592000 (30 days) here. Probably bug in
    # Cache::Memcached::Fast. For TTL value details see memcached proto spec
    # https://github.com/memcached/memcached/blob/master/doc/protocol.txt
    if ( $Param{TTL} > 2592000 ) {
        $Param{TTL} = 2592000;
    }

    return $Self->{MemcachedObject}->set(
        $MemcachedKeyName,
        $Param{Value},
        $Param{TTL}
    );
}

sub Get {
    my ( $Self, %Param ) = @_;

    # Check needed params.
    for my $Needed (qw(Type Key)) {
        if ( !defined $Param{$Needed} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Needed!"
            );
            return;
        }
    }

    return if !$Self->{MemcachedObject};

    # Get memcached key name for given Type and Key; do not initialize
    # namespace in case of namespace reading error (namespace init after
    # simple communication errors would cause same effect as CleanUp
    # on this object data type).
    my $MemcachedKeyName = $Self->_GetMemcachedKeyName(
        %Param,
        InitNamespaceOnError => 0,
    );
    return if !$MemcachedKeyName;

    return $Self->{MemcachedObject}->get($MemcachedKeyName);
}

sub Delete {
    my ( $Self, %Param ) = @_;

    # Check needed params.
    for my $Needed (qw(Type Key)) {
        if ( !defined $Param{$Needed} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Needed!"
            );
            return;
        }
    }

    return if ( !$Self->{MemcachedObject} );

    # Get memcached key name for given Type and Key.
    my $MemcachedKeyName = $Self->_GetMemcachedKeyName(
        %Param,
        InitNamespaceOnError => 1,
    );
    return if !$MemcachedKeyName;

    return $Self->{MemcachedObject}->delete($MemcachedKeyName);
}

sub CleanUp {
    my ( $Self, %Param ) = @_;

    return if !$Self->{MemcachedObject};

    # Memcached expires data automatically.
    return 1 if $Param{Expired};

    if ( $Param{Type} ) {
        # Invalidate namespace in cache by incrementing it; memcached will
        # take care of removing invalidated keys (LRU). In case of incrementing
        # error try to create new namespace.
        if (!$Self->{MemcachedObject}->incr('Namespace:' . $Param{Type}, 1)) {
            my $Miliseconds = int(Time::HiRes::gettimeofday() * 1000);
            if (!$Self->{MemcachedObject}->add('Namespace:' . $Param{Type}, $Miliseconds)) {
                $Kernel::OM->Get('Kernel::System::Log')->Log(
                    Priority => 'error',
                    Message  => "Error deleting objects of type $Param{Type} in memcached!",
                );
            }
        }

        return 1;
    }
    else {
        # Flush all the cache if no type specified.
        return $Self->{MemcachedObject}->flush_all();
    }
}

# Use MD5 digest of Type::Namespace::Key for memcached key (memcached key max
# length is 250). Namespace for given cache object type is taken from cache.
# New namespace is created if namespace is not found. For this algo idea see
# http://code.google.com/p/memcached/wiki/NewProgrammingTricks#Namespacing
# We use miliseconds not microseconds because overflow in the "incr" memcached
# command wraps around the 64 bit mark.
#
# Returns mamcached key name if determined or nothing on error:
#
#    my $PreparedKey = $Self->_GetMemcachedKeyName(
#        Type => 'CacheObjectTypeName',
#        Key => 'KeyName',
#        InitNamespaceOnError => 0,  # set 1 to initialize namespace if cannot be read
#    );
sub _GetMemcachedKeyName {
    my ( $Self, %Param ) = @_;

    # Try to find namespace for given key object type.
    my $MemcachedNamespace = $Self->{MemcachedObject}->get('Namespace:' . $Param{Type});

    # If namespace not found - if allowed, create new one using miliseconds since the epoch.
    if (!$MemcachedNamespace && $Param{InitNamespaceOnError}) {
        my $Miliseconds = int(Time::HiRes::gettimeofday() * 1000);

        if ($Self->{MemcachedObject}->add('Namespace:' . $Param{Type}, $Miliseconds)) {
            # Get namespace from cache in case it was updated meanwhile.
            $MemcachedNamespace = $Self->{MemcachedObject}->get('Namespace:' . $Param{Type});
        }
    }

    # Return nothing if namespace cannot be found.
    return if !$MemcachedNamespace;

    my $MemcachedKeyName = $Param{Type} . ':' . $MemcachedNamespace . ':' . $Param{Key};
    $Kernel::OM->Get('Kernel::System::Encode')->EncodeOutput( \$MemcachedKeyName );
    $MemcachedKeyName = Digest::MD5::md5_hex($MemcachedKeyName);
    return $MemcachedKeyName;
}

sub DESTROY {
    my $Self = shift;

    # Disconnect before trashing object.
    $Self->Disconnect();

    return 1;
}

1;
