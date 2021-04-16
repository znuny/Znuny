package Sisimai::Mail::Maildir;
use feature ':5.10';
use strict;
use warnings;
use IO::Dir;
use IO::File;
use Class::Accessor::Lite (
    'new' => 0,
    'ro'  => [
        'dir',      # [String] Path to Maildir/
    ],
    'rw'  => [
        'path',     # [String] Path to each file
        'file',     # [String] Each file name of a mail in the Maildir/
        'size',     # [Integer] The number of email files in the Maildir/
        'offset',   # [Integer] The number of email files which have been read
        'handle',   # [IO::Dir] Directory handle
    ]
);

sub new {
    # Constructor of Sisimai::Mail::Maildir
    # @param    [String] argv1              Path to Maildir/
    # @return   [Sisimai::Mail::Maildir]    Object
    #           [Undef]                     is not a directory or does not exist
    my $class = shift;
    my $argv1 = shift // return undef;
    my $files = 0;
    return undef unless -d $argv1;

    eval {
        # Count the number of files in the Maildir/
        opendir MAILDIR, $argv1;
        while( my $e = readdir MAILDIR ) {
            next unless -f sprintf("%s/%s", $argv1, $e);
            $files += 1;
        }
        closedir MAILDIR;
    };

    my $param = {
        'dir'    => $argv1,
        'file'   => undef,
        'path'   => undef,
        'size'   => $files,
        'offset' => 0,
        'handle' => IO::Dir->new($argv1),
    };
    return bless($param, __PACKAGE__);
}

sub read {
    # Maildir reader, works as a iterator.
    # @return       [String] Contents of file in Maildir/
    my $self = shift;
    return undef unless defined $self->{'dir'};
    return undef unless -d $self->{'dir'};
    return undef unless $self->{'offset'} < $self->{'size'};

    my $seekhandle = $self->{'handle'};
    my $readbuffer = '';

    eval {
        $seekhandle = IO::Dir->new($self->{'dir'}) unless $seekhandle;
        while( my $r = $seekhandle->read ) {
            # Read each file in the directory
            next if( $r eq '.' || $r eq '..' );

            my $emailindir =  $self->{'dir'}.'/'.$r;
               $emailindir =~ y{/}{}s;
            $self->{'offset'} += 1;
            next unless -f $emailindir;
            next unless -s $emailindir;
            next unless -r $emailindir;

            $self->{'path'} = $emailindir;
            $self->{'file'} = $r;
            my $filehandle = IO::File->new($emailindir, 'r');
               $readbuffer = do { local $/; <$filehandle> };
               $filehandle->close;
            last;
        }
        $seekhandle->close unless $self->{'offset'} < $self->{'size'};
    };
    return $readbuffer;
}

1;
__END__
=encoding utf-8

=head1 NAME

Sisimai::Mail::Maildir - Mailbox reader

=head1 SYNOPSIS

    use Sisimai::Mail::Maildir;
    my $maildir = Sisimai::Mail::Maildir->new('/home/neko/Maildir/new');
    while( my $r = $maildir->read ) {
        print $r;   # print contents of the mail in the Maildir/
    }

=head1 DESCRIPTION

Sisimai::Mail::Maildir is a reader for getting contents of each email in the
Maildir/ directory.

=head1 CLASS METHODS

=head2 C<B<new(I<path to Maildir/>)>>

C<new()> is a constructor of Sisimai::Mail::Maildir

    my $maildir = Sisimai::Mail::Maildir->new('/home/neko/Maildir/new');

=head1 INSTANCE METHODS

=head2 C<B<dir()>>

C<dir()> returns the path to Maildir/

    print $maildir->dir;   # /home/neko/Maildir/new/

=head2 C<B<path()>>

C<path()> returns the path to each email in Maildir/

    print $maildir->path;   # /home/neko/Maildir/new/1.eml

=head2 C<B<file()>>

C<file()> returns current file name of the Maildir.

    print $maildir->file;

=head2 C<B<size()>>

C<size()> returns the amount of email size which has been read

    print $maildir->size;

=head2 C<B<offset()>>

C<offset()> returns the number of emails which have been read in Maildir/

    $maildir->offset;   # 2

=head2 C<B<handle()>>

C<handle()> returns file handle object (IO::Dir) of the Maildir.

    $maildir->handle->close;

=head2 C<B<read()>>

C<read()> works as a iterator for reading each email in the Maildir.

    my $maildir = Sisimai::Mail->new('/home/neko/Maildir/new');
    while( my $r = $mailbox->read ) {
        print $r;   # print each email in /home/neko/Maildir/new
    }

=head1 AUTHOR

azumakuniyuki

=head1 COPYRIGHT

Copyright (C) 2014-2016,2018-2020 azumakuniyuki, All rights reserved.

=head1 LICENSE

This software is distributed under The BSD 2-Clause License.

=cut
