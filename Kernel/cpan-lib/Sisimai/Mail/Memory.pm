package Sisimai::Mail::Memory;
use feature ':5.10';
use strict;
use warnings;
use Class::Accessor::Lite (
    'new' => 0,
    'ro'  => [
        'path',     # [String] Fixed string "<MEMORY>"
        'size',     # [Integer] data size
    ],
    'rw'  => [
        'payload',  # [Array] entire bounce mail message
        'offset',   # [Integer] Index of "data"
    ]
);

sub new {
    # Constructor of Sisimai::Mail::Memory
    # @param    [String] argv1          Entire email string
    # @return   [Sisimai::Mail::Memory] Object
    #           [Undef]                 is not a valid email text
    my $class = shift;
    my $argv1 = shift // return undef;
    my $param = {
        'payload' => [],
        'path'    => '<MEMORY>',
        'size'    => length $$argv1 || 0,
        'offset'  => 0,
    };
    return undef unless $param->{'size'};

    if( (substr($$argv1, 0, 5) || '') eq 'From ') {
        # UNIX mbox
        $param->{'payload'} = [split(/^From /m, $$argv1)];
        shift @{ $param->{'payload'} };
        $_ = 'From '.$_ for @{ $param->{'payload'} };
    } else {
        $param->{'payload'} = [$$argv1];
    }
    return bless($param, __PACKAGE__);
}

sub read {
    # Memory reader, works as a iterator.
    # @return   [String] Contents of a bounce mail
    my $self = shift;
    return undef unless scalar @{ $self->{'payload'} };

    $self->{'offset'} += 1;
    return shift @{ $self->{'payload'} };
}

1;
__END__
=encoding utf-8

=head1 NAME

Sisimai::Mail::Memory - Mailbox reader

=head1 SYNOPSIS

    use Sisimai::Mail::Memory;
    my $mailtxt = 'From Mailer-Daemon ...';
    my $mailobj = Sisimai::Mail::Memory->new(\$mailtxt);
    while( my $r = $mailobj->read ) {
        print $r;   # print contents of each mail in the mailbox or Maildir/
    }

=head1 DESCRIPTION

Sisimai::Mail::Memory is a class for reading a mailbox, files in Maildir/, or
JSON string from variable.

=head1 CLASS METHODS

=head2 C<B<new(I<\$scalar>)>>

C<new()> is a constructor of Sisimai::Mail::Memory

    my $mailtxt = 'From Mailer-Daemon ...';
    my $mailobj = Sisimai::Mail::Memory->new(\$mailtxt);

=head1 INSTANCE METHODS

=head2 C<B<path()>>

C<path()> returns "<MEMORY>"

    print $mailbox->path;   # "<MEMORY>"

=head2 C<B<size()>>

C<size()> returns a memory size of the mailbox or JSON string.

    print $mailobj->size;   # 94515

=head2 C<B<payload()>>

C<payload()> returns an array reference to each email message or JSON string

    print scalar @{ $mailobj->payload };   # 17

=head2 C<B<offset()>>

C<offset()> returns an offset position for seeking "payload" list. The value of
"offset" is an index number which have already read.

    print $mailobj->offset;   # 0

=head2 C<B<read()>>

C<read()> works as a iterator for reading each email in the mailbox.

    my $mailtxt = 'From Mailer-Daemon ...';
    my $mailobj = Sisimai::Mail->new(\$mailtxt);
    while( my $r = $mailobj->read ) {
        print $r;   # print each email in the first argument of new().
    }

=head1 AUTHOR

azumakuniyuki

=head1 COPYRIGHT

Copyright (C) 2018-2020 azumakuniyuki, All rights reserved.

=head1 LICENSE

This software is distributed under The BSD 2-Clause License.

=cut

