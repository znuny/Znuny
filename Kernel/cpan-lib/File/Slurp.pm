package File::Slurp;

use strict;
use warnings ;

our $VERSION = '9999.32';
$VERSION = eval $VERSION;

use Carp ;
use Exporter qw(import);
use Fcntl qw( :DEFAULT ) ;
use File::Basename ();
use File::Spec;
use File::Temp qw(tempfile);
use IO::Handle ();
use POSIX qw( :fcntl_h ) ;
use Errno ;

my @std_export = qw(
	read_file
	write_file
	overwrite_file
	append_file
	read_dir
) ;

my @edit_export = qw(
	edit_file
	edit_file_lines
) ;

my @abbrev_export = qw(
	rf
	wf
	ef
	efl
) ;

our @EXPORT_OK = (
	@edit_export,
	@abbrev_export,
	qw(
		slurp
		prepend_file
	),
) ;

our %EXPORT_TAGS = (
	'all'	=> [ @std_export, @edit_export, @abbrev_export, @EXPORT_OK ],
	'edit'	=> [ @edit_export ],
	'std'	=> [ @std_export ],
	'abr'	=> [ @abbrev_export ],
) ;

our @EXPORT = @std_export ;

my $max_fast_slurp_size = 1024 * 100 ;

my $is_win32 = $^O =~ /win32/i ;

*slurp = \&read_file ;
*rf = \&read_file ;

sub read_file {
	my $file_name = shift;
	my $opts = (ref $_[0] eq 'HASH') ? shift : {@_};
	# options we care about:
	# array_ref binmode blk_size buf_ref chomp err_mode scalar_ref

	# let's see if we have a stringified object before doing anything else
	# We then only have to deal with when we are given a file handle/globref
	if (ref($file_name)) {
		my $ref_result = _check_ref($file_name, $opts);
		if (ref($ref_result)) {
			@_ = ($opts, $ref_result);
			goto &_error;
		}
		$file_name = $ref_result if $ref_result;
		# we have now stringified $file_name if possible. if it's still a ref
		# then we probably have a file handle
	}

	my $fh;
	if (ref($file_name)) {
		$fh = $file_name;
	}
	else {
		# to keep with the old ways, read in :raw by default
		unless (open $fh, "<:raw", $file_name) {
			@_ = ($opts, "read_file '$file_name' - open: $!");
			goto &_error;
		}
		# even though we set raw, let binmode take place here (busted)
		if (my $bm = $opts->{binmode}) {
			binmode $fh, $bm;
		}
	}

	# we are now sure to have an open file handle. Let's slurp it in the same
	# way that File::Slurper does.
	my $buf;
	my $buf_ref = $opts->{buf_ref} || \$buf;
	${$buf_ref} = '';
	my $blk_size = $opts->{blk_size} || 1024 * 1024;
	if (my $size = -f $fh && -s _) {
		$blk_size = $size if $size < $blk_size;
		my ($pos, $read) = 0;
		do {
			unless(defined($read = read $fh, ${$buf_ref}, $blk_size, $pos)) {
				@_ = ($opts, "read_file '$file_name' - read: $!");
				goto &_error;
			}
			$pos += $read;
		} while ($read && $pos < $size);
	}
	else {
		${$buf_ref} = do { local $/; <$fh> };
	}
	seek($fh, $opts->{_data_tell}, SEEK_SET) if $opts->{_is_data} && $opts->{_data_tell};

	# line endings if we're on Windows
	${$buf_ref} =~ s/\015\012/\012/g if ${$buf_ref} && $is_win32 && !$opts->{binmode};

	# we now have a buffer filled with the file content. Figure out how to
	# return it to the user
	my $want_array = wantarray; # let's only ask for this once
	if ($want_array || $opts->{array_ref}) {
		use re 'taint';
		my $sep = $/;
		$sep = '\n\n+' if defined $sep && $sep eq '';
		# split the buffered content into lines
		my @lines = length(${$buf_ref}) ?
			${$buf_ref} =~ /(.*?$sep|.+)/sg : ();
		chomp @lines if $opts->{chomp};
		return \@lines if $opts->{array_ref};
		return @lines;
	}
	return $buf_ref if $opts->{scalar_ref};
	# if the function was called in scalar context, return the contents
	return ${$buf_ref} if defined $want_array;
	# if we were called in void context, return nothing
	return;
}

# errors in this sub are returned as scalar refs
# a normal IO/GLOB handle is an empty return
# an overloaded object returns its stringified as a scalarfilename

sub _check_ref {

	my( $handle, $opts ) = @_ ;

# check if we are reading from a handle (GLOB or IO object)

	if ( eval { $handle->isa( 'GLOB' ) || $handle->isa( 'IO' ) } ) {

# we have a handle. deal with seeking to it if it is DATA

		my $err = _seek_data_handle( $handle, $opts ) ;

# return the error string if any

		return \$err if $err ;

# we have good handle
		return ;
	}

	eval { require overload } ;

# return an error if we can't load the overload pragma
# or if the object isn't overloaded

	return \"Bad handle '$handle' is not a GLOB or IO object or overloaded"
		 if $@ || !overload::Overloaded( $handle ) ;

# must be overloaded so return its stringified value

	return "$handle" ;
}

sub _seek_data_handle {

	my( $handle, $opts ) = @_ ;
	# store some meta-data about the __DATA__ file handle
	$opts->{_is_data} = 0;
	$opts->{_data_tell} = 0;

# DEEP DARK MAGIC. this checks the UNTAINT IO flag of a
# glob/handle. only the DATA handle is untainted (since it is from
# trusted data in the source file). this allows us to test if this is
# the DATA handle and then to do a sysseek to make sure it gets
# slurped correctly. on some systems, the buffered i/o pointer is not
# left at the same place as the fd pointer. this sysseek makes them
# the same so slurping with sysread will work.

	eval{ require B } ;

	if ( $@ ) {

		return <<ERR ;
Can't find B.pm with this Perl: $!.
That module is needed to properly slurp the DATA handle.
ERR
	}

	if ( B::svref_2object( $handle )->IO->IoFLAGS & 16 ) {

		# we now know we have the data handle. Let's store its original
		# location in the file so that we can put it back after the read.
		# this is only done for Bugwards-compatibility in some dists such as
		# CPAN::Index::API that made use of the oddity where sysread was in use
		# before
		$opts->{_is_data} = 1;
		$opts->{_data_tell} = tell($handle);
# set the seek position to the current tell.

		# unless( sysseek( $handle, tell( $handle ), SEEK_SET ) ) {
		# 	return "read_file '$handle' - sysseek: $!" ;
		# }
	}

# seek was successful, return no error string

	return ;
}

*wf = \&write_file ;

sub write_file {
	my $file_name = shift;
	my $opts = (ref $_[0] eq 'HASH') ? shift : {};
	# options we care about:
	# append atomic binmode buf_ref err_mode no_clobber perms

	my $fh;
	my $no_truncate = 0;
	my $orig_filename;
	# let's see if we have a stringified object or some sort of handle
	# or globref before doing anything else
	if (ref($file_name)) {
		my $ref_result = _check_ref($file_name, $opts);
		if (ref($ref_result)) {
			# some error happened while checking for a ref
			@_ = ($opts, $ref_result);
			goto &_error;
		}
		if ($ref_result) {
			# we have now stringified $file_name from the overloaded obj
			$file_name = $ref_result;
		}
		else {
			# we now have a proper handle ref
			# make sure we don't call truncate on it
			$fh = $file_name;
			$no_truncate = 1;
			# can't do atomic or permissions on a file handle
			delete $opts->{atomic};
			delete $opts->{perms};
		}
	}

	# open the file for writing if we were given a filename
	unless ($fh) {
		$orig_filename = $file_name;
		my $perms = defined($opts->{perms}) ? $opts->{perms} : 0666;
		# set the mode for the sysopen
		my $mode = O_WRONLY | O_CREAT;
		$mode |= O_APPEND if $opts->{append};
		$mode |= O_EXCL if $opts->{no_clobber};
		if ($opts->{atomic}) {
			# in an atomic write, we must open a new file in the same directory
			# as the original to account for ACLs. We must also set the new file
			# to the same permissions as the original unless overridden by the
			# caller's request to set a specified permission set.
			my $dir = File::Spec->rel2abs(File::Basename::dirname($file_name));
			if (!defined($opts->{perms}) && -e $file_name && -f _) {
				$perms = 07777 & (stat $file_name)[2];
			}
			# we must ensure we're using a good temporary filename (doesn't already
			# exist). This is slower, but safer.
			{
				local $^W = 0; # AYFKM
				(undef, $file_name) = tempfile('.tempXXXXX', DIR => $dir, OPEN => 0);
			}
		}
		$fh = local *FH;
		unless (sysopen($fh, $file_name, $mode, $perms)) {
			@_ = ($opts, "write_file '$file_name' - sysopen: $!");
			goto &_error;
		}
	}
	# we now have an open file handle as well as data to write to that handle
	if (my $binmode = $opts->{binmode}) {
		binmode($fh, $binmode);
	}

	# get the data to print to the file
	# get the buffer ref - it depends on how the data is passed in
	# after this if/else $buf_ref will have a scalar ref to the data
	my $buf_ref;
	my $data_is_ref = 0;
	if (ref($opts->{buf_ref}) eq 'SCALAR') {
		# a scalar ref passed in %opts has the data
		# note that the data was passed by ref
		$buf_ref = $opts->{buf_ref};
		$data_is_ref = 1;
	}
	elsif (ref($_[0]) eq 'SCALAR') {
		# the first value in @_ is the scalar ref to the data
		# note that the data was passed by ref
		$buf_ref = shift;
		$data_is_ref = 1;
	}
	elsif (ref($_[0]) eq 'ARRAY') {
		# the first value in @_ is the array ref to the data so join it.
		${$buf_ref} = join '', @{$_[0]};
	}
	else {
		# good old @_ has all the data so join it.
		${$buf_ref} = join '', @_;
	}

	# seek and print
	seek($fh, 0, SEEK_END) if $opts->{append};
	print {$fh} ${$buf_ref};
	truncate($fh, tell($fh)) unless $no_truncate;
	close($fh);

	if ($opts->{atomic} && !rename($file_name, $orig_filename)) {
		@_ = ($opts, "write_file '$file_name' - rename: $!");
		goto &_error;
	}

	return 1;
}

# this is for backwards compatibility with the previous File::Slurp module.
# write_file always overwrites an existing file
*overwrite_file = \&write_file ;

# the current write_file has an append mode so we use that. this
# supports the same API with an optional second argument which is a
# hash ref of options.

sub append_file {

# get the optional opts hash ref
	my $opts = $_[1] ;
	if ( ref $opts eq 'HASH' ) {

# we were passed an opts ref so just mark the append mode

		$opts->{append} = 1 ;
	}
	else {

# no opts hash so insert one with the append mode

		splice( @_, 1, 0, { append => 1 } ) ;
	}

# magic goto the main write_file sub. this overlays the sub without touching
# the stack or @_

	goto &write_file
}

# prepend data to the beginning of a file

sub prepend_file {

	my $file_name = shift ;

#print "FILE $file_name\n" ;

	my $opts = ( ref $_[0] eq 'HASH' ) ? shift : {} ;

# delete unsupported options

	my @bad_opts =
		grep $_ ne 'err_mode' && $_ ne 'binmode', keys %{$opts} ;

	delete @{$opts}{@bad_opts} ;

	my $prepend_data = shift ;
	$prepend_data = '' unless defined $prepend_data ;
	$prepend_data = ${$prepend_data} if ref $prepend_data eq 'SCALAR' ;

#print "PRE [$prepend_data]\n" ;

	my $err_mode = delete $opts->{err_mode} ;
	$opts->{ err_mode } = 'croak' ;
	$opts->{ scalar_ref } = 1 ;

	my $existing_data = eval { read_file( $file_name, $opts ) } ;

	if ( $@ ) {

		@_ = ( { err_mode => $err_mode },
			"prepend_file '$file_name' - read_file: $!" ) ;
		goto &_error ;
	}

#print "EXIST [$$existing_data]\n" ;

	$opts->{atomic} = 1 ;
	my $write_result =
		eval { write_file( $file_name, $opts,
		       $prepend_data, $$existing_data ) ;
	} ;

	if ( $@ ) {

		@_ = ( { err_mode => $err_mode },
			"prepend_file '$file_name' - write_file: $!" ) ;
		goto &_error ;
	}

	return $write_result ;
}

# edit a file as a scalar in $_

*ef = \&edit_file ;

sub edit_file(&$;$) {

	my( $edit_code, $file_name, $opts ) = @_ ;
	$opts = {} unless ref $opts eq 'HASH' ;

# 	my $edit_code = shift ;
# 	my $file_name = shift ;
# 	my $opts = ( ref $_[0] eq 'HASH' ) ? shift : {} ;

#print "FILE $file_name\n" ;

# delete unsupported options

	my @bad_opts =
		grep $_ ne 'err_mode' && $_ ne 'binmode', keys %{$opts} ;

	delete @{$opts}{@bad_opts} ;

# keep the user err_mode and force croaking on internal errors

	my $err_mode = delete $opts->{err_mode} ;
	$opts->{ err_mode } = 'croak' ;

# get a scalar ref for speed and slurp the file into a scalar

	$opts->{ scalar_ref } = 1 ;
	my $existing_data = eval { read_file( $file_name, $opts ) } ;

	if ( $@ ) {

		@_ = ( { err_mode => $err_mode },
			"edit_file '$file_name' - read_file: $!" ) ;
		goto &_error ;
	}

#print "EXIST [$$existing_data]\n" ;

	my( $edited_data ) = map { $edit_code->(); $_ } $$existing_data ;

	$opts->{atomic} = 1 ;
	my $write_result =
		eval { write_file( $file_name, $opts, $edited_data ) } ;

	if ( $@ ) {

		@_ = ( { err_mode => $err_mode },
			"edit_file '$file_name' - write_file: $!" ) ;
		goto &_error ;
	}

	return $write_result ;
}

*efl = \&edit_file_lines ;

sub edit_file_lines(&$;$) {

	my( $edit_code, $file_name, $opts ) = @_ ;
	$opts = {} unless ref $opts eq 'HASH' ;

# 	my $edit_code = shift ;
# 	my $file_name = shift ;
# 	my $opts = ( ref $_[0] eq 'HASH' ) ? shift : {} ;

#print "FILE $file_name\n" ;

# delete unsupported options

	my @bad_opts =
		grep $_ ne 'err_mode' && $_ ne 'binmode', keys %{$opts} ;

	delete @{$opts}{@bad_opts} ;

# keep the user err_mode and force croaking on internal errors

	my $err_mode = delete $opts->{err_mode} ;
	$opts->{ err_mode } = 'croak' ;

# get an array ref for speed and slurp the file into lines

	$opts->{ array_ref } = 1 ;
	my $existing_data = eval { read_file( $file_name, $opts ) } ;

	if ( $@ ) {

		@_ = ( { err_mode => $err_mode },
			"edit_file_lines '$file_name' - read_file: $!" ) ;
		goto &_error ;
	}

#print "EXIST [$$existing_data]\n" ;

	my @edited_data = map { $edit_code->(); $_ } @$existing_data ;

	$opts->{atomic} = 1 ;
	my $write_result =
		eval { write_file( $file_name, $opts, @edited_data ) } ;

	if ( $@ ) {

		@_ = ( { err_mode => $err_mode },
			"edit_file_lines '$file_name' - write_file: $!" ) ;
		goto &_error ;
	}

	return $write_result ;
}

# basic wrapper around opendir/readdir

sub read_dir {

	my $dir = shift ;
	my $opts = ( ref $_[0] eq 'HASH' ) ? shift : { @_ } ;

# this handle will be destroyed upon return

	local(*DIRH);

# open the dir and handle any errors

	unless ( opendir( DIRH, $dir ) ) {

		@_ = ( $opts, "read_dir '$dir' - opendir: $!" ) ;
		goto &_error ;
	}

	my @dir_entries = readdir(DIRH) ;

	@dir_entries = grep( $_ ne "." && $_ ne "..", @dir_entries )
		unless $opts->{'keep_dot_dot'} ;

	if ( $opts->{'prefix'} ) {

		$_ = File::Spec->catfile($dir, $_) for @dir_entries;
	}

	return @dir_entries if wantarray ;
	return \@dir_entries ;
}

# error handling section
#
# all the error handling uses magic goto so the caller will get the
# error message as if from their code and not this module. if we just
# did a call on the error code, the carp/croak would report it from
# this module since the error sub is one level down on the call stack
# from read_file/write_file/read_dir.


my %err_func = (
	'carp'	=> \&carp,
	'croak'	=> \&croak,
) ;

sub _error {

	my( $opts, $err_msg ) = @_ ;

# get the error function to use

 	my $func = $err_func{ $opts->{'err_mode'} || 'croak' } ;

# if we didn't find it in our error function hash, they must have set
# it to quiet and we don't do anything.

	return unless $func ;

# call the carp/croak function

	$func->($err_msg) if $func ;

# return a hard undef (in list context this will be a single value of
# undef which is not a legal in-band value)

	return undef ;
}

1;
__END__

=head1 NAME

File::Slurp - Simple and Efficient Reading/Writing/Modifying of Complete Files

=head1 SYNOPSIS

  use File::Slurp;

  # read in a whole file into a scalar
  my $text = read_file('/path/file');

  # read in a whole file into an array of lines
  my @lines = read_file('/path/file');

  # write out a whole file from a scalar
  write_file('/path/file', $text);

  # write out a whole file from an array of lines
  write_file('/path/file', @lines);

  # Here is a simple and fast way to load and save a simple config file
  # made of key=value lines.
  my %conf = read_file('/path/file') =~ /^(\w+)=(.*)$/mg;
  write_file('/path/file', {atomic => 1}, map "$_=$conf{$_}\n", keys %conf);

  # insert text at the beginning of a file
  prepend_file('/path/file', $text);

  # in-place edit to replace all 'foo' with 'bar' in file
  edit_file { s/foo/bar/g } '/path/file';

  # in-place edit to delete all lines with 'foo' from file
  edit_file_lines sub { $_ = '' if /foo/ }, '/path/file';

  # read in a whole directory of file names (skipping . and ..)
  my @files = read_dir('/path/to/dir');

=head1 DESCRIPTION

This module provides subs that allow you to read or write entire files
with one simple call. They are designed to be simple to use, have
flexible ways to pass in or get the file contents and to be very
efficient. There is also a sub to read in all the files in a
directory.

=head2 WARNING - PENDING DOOM

Although you technically I<can>, do NOT use this module to work on file handles,
pipes, sockets, standard IO, or the C<DATA> handle. These are
features implemented long ago that just really shouldn't be abused here.

Be warned: this activity will lead to inaccurate encoding/decoding of data.

All further mentions of actions on the above have been removed from this
documentation and that feature set will likely be deprecated in the future.

In other words, if you don't have a filename to pass, consider using the
standard C<< do { local $/; <$fh> } >>, or
L<Data::Section>/L<Data::Section::Simple> for working with C<__DATA__>.

=head1 FUNCTIONS

L<File::Slurp> implements the following functions.

=head2 append_file

	use File::Slurp qw(append_file write_file);
	my $res = append_file('/path/file', "Some text");
	# same as
	my $res = write_file('/path/file', {append => 1}, "Some text");

The C<append_file> function is simply a synonym for the
L<File::Slurp/"write_file"> function, but ensures that the C<append> option is
set.

=head2 edit_file

	use File::Slurp qw(edit_file);
	# perl -0777 -pi -e 's/foo/bar/g' /path/file
	edit_file { s/foo/bar/g } '/path/file';
	edit_file sub { s/foo/bar/g }, '/path/file';
	sub replace_foo { s/foo/bar/g }
	edit_file \&replace_foo, '/path/file';

The C<edit_file> function reads in a file into C<$_>, executes a code block that
should modify C<$_>, and then writes C<$_> back to the file. The C<edit_file>
function reads in the entire file and calls the code block one time. It is
equivalent to the C<-pi> command line options of Perl but you can call it from
inside your program and not have to fork out a process.

The first argument to C<edit_file> is a code block or a code reference. The
code block is not followed by a comma (as with C<grep> and C<map>) but a code
reference is followed by a comma.

The next argument is the filename.

The next argument(s) is either a hash reference or a flattened hash,
C<< key => value >> pairs. The options are passed through to the
L<File::Slurp/"write_file"> function. All options are described there.
Only the C<binmode> and C<err_mode> options are supported. The call to
L<File::Slurp/"write_file"> has the C<atomic> option set so you will always
have a consistent file.

=head2 edit_file_lines

	use File::Slurp qw(edit_file_lines);
	# perl -pi -e '$_ = "" if /foo/' /path/file
	edit_file_lines { $_ = '' if /foo/ } '/path/file';
	edit_file_lines sub { $_ = '' if /foo/ }, '/path/file';
	sub delete_foo { $_ = '' if /foo/ }
	edit_file \&delete_foo, '/path/file';

The C<edit_file_lines> function reads each line of a file into C<$_>, and
executes a code block that should modify C<$_>. It will then write C<$_> back
to the file. It is equivalent to the C<-pi> command line options of Perl but
you can call it from inside your program and not have to fork out a process.

The first argument to C<edit_file_lines> is a code block or a code reference.
The code block is not followed by a comma (as with C<grep> and C<map>) but a
code reference is followed by a comma.

The next argument is the filename.

The next argument(s) is either a hash reference or a flattened hash,
C<< key => value >> pairs. The options are passed through to the
L<File::Slurp/"write_file"> function. All options are described there.
Only the C<binmode> and C<err_mode> options are supported. The call to
L<File::Slurp/"write_file"> has the C<atomic> option set so you will always
have a consistent file.

=head2 ef

	use File::Slurp qw(ef);
	# perl -0777 -pi -e 's/foo/bar/g' /path/file
	ef { s/foo/bar/g } '/path/file';
	ef sub { s/foo/bar/g }, '/path/file';
	sub replace_foo { s/foo/bar/g }
	ef \&replace_foo, '/path/file';

The C<ef> function is simply a synonym for the L<File::Slurp/"edit_file">
function.

=head2 efl

	use File::Slurp qw(efl);
	# perl -pi -e '$_ = "" if /foo/' /path/file
	efl { $_ = '' if /foo/ } '/path/file';
	efl sub { $_ = '' if /foo/ }, '/path/file';
	sub delete_foo { $_ = '' if /foo/ }
	efl \&delete_foo, '/path/file';

The C<efl> function is simply a synonym for the L<File::Slurp/"edit_file_lines">
function.

=head2 overwrite_file

	use File::Slurp qw(overwrite_file);
	my $res = overwrite_file('/path/file', "Some text");

The C<overwrite_file> function is simply a synonym for the
L<File::Slurp/"write_file"> function.

=head2 prepend_file

	use File::Slurp qw(prepend_file);
	prepend_file('/path/file', $header);
	prepend_file('/path/file', \@lines);
	prepend_file('/path/file', { binmode => ':raw'}, $bin_data);

	# equivalent to:
	use File::Slurp qw(read_file write_file);
	my $content = read_file('/path/file');
	my $new_content = "hahahaha";
	write_file('/path/file', $new_content . $content);

The C<prepend_file> function is the opposite of L<File::Slurp/"append_file"> as
it writes new contents to the beginning of the file instead of the end. It is a
combination of L<File::Slurp/"read_file"> and L<File::Slurp/"write_file">. It
works by first using C<read_file> to slurp in the file and then calling
C<write_file> with the new data and the existing file data.

The first argument to C<prepend_file> is the filename.

The next argument(s) is either a hash reference or a flattened hash,
C<< key => value >> pairs. The options are passed through to the
L<File::Slurp/"write_file"> function. All options are described there.

Only the C<binmode> and C<err_mode> options are supported. The
C<write_file> call has the C<atomic> option set so you will always have
a consistent file.

=head2 read_dir

	use File::Slurp qw(read_dir);
	my @files = read_dir('/path/to/dir');
	# all files, even the dots
	my @files = read_dir('/path/to/dir', keep_dot_dot => 1);
	# keep the full file path
	my @paths = read_dir('/path/to/dir', prefix => 1);
	# scalar context
	my $files_ref = read_dir('/path/to/dir');

This function returns a list of the filenames in the supplied directory. In
list context, an array is returned, in scalar context, an array reference is
returned.

The first argument is the path to the directory to read.

The next argument(s) is either a hash reference or a flattened hash,
C<< key => value >> pairs. The following options are available:

=over

=item

err_mode

The C<err_mode> option has three possible values: C<quiet>, C<carp>, or the
default, C<croak>. In C<quiet> mode, all errors will be silent. In C<carp> mode,
all errors will be emitted as warnings. And, in C<croak> mode, all errors will
be emitted as exceptions. Take a look at L<Try::Tiny> or
L<Syntax::Keyword::Try> to see how to catch exceptions.

=item

keep_dot_dot

The C<keep_dot_dot> option is a boolean option, defaulted to false (C<0>).
Setting this option to true (C<1>) will also return the C<.> and C<..> files
that are removed from the file list by default.

=item

prefix

The C<prefix> option is a boolean option, defaulted to false (C<0>).
Setting this option to true (C<1>) add the directory as a prefix to the file.
The directory and the filename are joined using C<< File::Spec->catfile() >> to
ensure the proper directory separator is used for your OS. See L<File::Spec>.

=back

=head2 read_file

	use File::Slurp qw(read_file);
	my $text = read_file('/path/file');
	my $bin = read_file('/path/file', { binmode => ':raw' });
	my @lines = read_file('/path/file');
	my $lines_ref = read_file('/path/file', array_ref => 1);
	my $lines_ref = [ read_file('/path/file') ];

	# or we can read into a buffer:
	my $buffer;
	read_file('/path/file', buf_ref => \$buffer);

	# or we can set the block size for the read
	my $text_ref = read_file('/path/file', blk_size => 10_000_000, array_ref => 1);

	# or we can get a scalar reference
	my $text_ref = read_file('/path/file', scalar_ref => 1);

This function reads in an entire file and returns its contents to the
caller. In scalar context it returns the entire file as a single
scalar. In list context it will return a list of lines (using the
current value of C<$/> as the separator, including support for paragraph
mode when it is set to C<''>).

The first argument is the path to the file to be slurped in.

The next argument(s) is either a hash reference or a flattened hash,
C<< key => value >> pairs. The following options are available:

=over

=item

array_ref

The C<array_ref> option is a boolean option, defaulted to false (C<0>). Setting
this option to true (C<1>) will only have relevance if the C<read_file> function
is called in scalar context. When true, the C<read_file> function will return
a reference to an array of the lines in the file.

=item

binmode

The C<binmode> option is a string option, defaulted to empty (C<''>). If you
set the C<binmode> option, then its value is passed to a call to C<binmode> on
the opened handle. You can use this to set the file to be read in binary mode,
utf8, etc. See C<perldoc -f binmode> for more.

=item

blk_size

You can use this option to set the block size used when slurping from
an already open handle (like C<\*STDIN>). It defaults to 1MB.

=item

buf_ref

The C<buf_ref> option can be used in conjunction with any of the other options.
You can use this option to pass in a scalar reference and the slurped
file contents will be stored in the scalar. This saves an extra copy of
the slurped file and can lower RAM usage vs returning the file. It is
usually the fastest way to read a file into a scalar.

=item

chomp

The C<chomp> option is a boolean option, defaulted to false (C<0>). Setting
this option to true (C<1>) will cause each line to have its contents C<chomp>ed.
This option works in list context or in scalar context with the C<array_ref>
option.

=item

err_mode

The C<err_mode> option has three possible values: C<quiet>, C<carp>, or the
default, C<croak>. In C<quiet> mode, all errors will be silent. In C<carp> mode,
all errors will be emitted as warnings. And, in C<croak> mode, all errors will
be emitted as exceptions. Take a look at L<Try::Tiny> or
L<Syntax::Keyword::Try> to see how to catch exceptions.

=item

scalar_ref

The C<scalar_ref> option is a boolean option, defaulted to false (C<0>). It only
has meaning in scalar context. The return value will be a scalar reference to a
string which is the contents of the slurped file. This will usually be faster
than returning the plain scalar. It will also save memory as it will not make a
copy of the file to return.

=back

=head2 rf

	use File::Slurp qw(rf);
	my $text = rf('/path/file');

The C<rf> function is simply a synonym for the L<File::Slurp/"read_file">
function.

=head2 slurp

	use File::Slurp qw(slurp);
	my $text = slurp('/path/file');

The C<slurp> function is simply a synonym for the L<File::Slurp/"read_file">
function.

=head2 wf

	use File::Slurp qw(wf);
	my $res = wf('/path/file', "Some text");


The C<wf> function is simply a synonym for the
L<File::Slurp/"write_file"> function.

=head2 write_file

	use File::Slurp qw(write_file);
	write_file('/path/file', @data);
	write_file('/path/file', {append => 1}, @data);
	write_file('/path/file', {binmode => ':raw'}, $buffer);
	write_file('/path/file', \$buffer);
	write_file('/path/file', $buffer);
	write_file('/path/file', \@lines);
	write_file('/path/file', @lines);

	# binmode
	write_file('/path/file', {binmode => ':raw'}, @data);
	write_file('/path/file', {binmode => ':utf8'}, $utf_text);

	# buffered
	write_file('/path/file', {buf_ref => \$buffer});
	write_file('/path/file', \$buffer);
	write_file('/path/file', $buffer);

	# append
	write_file('/path/file', {append => 1}, @data);

	# no clobbering
	write_file('/path/file', {no_clobber => 1}, @data);

This function writes out an entire file in one call. By default C<write_file>
returns C<1> upon successfully writing the file or C<undef> if it encountered
an error. You can change how errors are handled with the C<err_mode> option.

The first argument to C<write_file> is the filename.

The next argument(s) is either a hash reference or a flattened hash,
C<< key => value >> pairs. The following options are available:

=over

=item

append

The C<append> option is a boolean option, defaulted to false (C<0>). Setting
this option to true (C<1>) will cause the data to be be written at the end of
the current file. Internally this sets the C<sysopen> mode flag C<O_APPEND>.

The L<File::Slurp/"append_file"> function sets this option by default.

=item

atomic

The C<atomic> option is a boolean option, defaulted to false (C<0>). Setting
this option to true (C<1>) will cause the file to be be written to in an
atomic fashion. A temporary file name is created using L<File::Temp/"tempfile">.
After the file is closed it is renamed to the original file name
(and C<rename> is an atomic operation on most OSes). If the program using
this were to crash in the middle of this, then the temporary file could
be left behind.

=item

binmode

The C<binmode> option is a string option, defaulted to empty (C<''>). If you
set the C<binmode> option, then its value is passed to a call to C<binmode> on
the opened handle. You can use this to set the file to be read in binary mode,
utf8, etc. See C<perldoc -f binmode> for more.

=item

buf_ref

The C<buf_ref> option is used to pass in a scalar reference which has the
data to be written. If this is set then any data arguments (including
the scalar reference shortcut) in C<@_> will be ignored.

=item

err_mode

The C<err_mode> option has three possible values: C<quiet>, C<carp>, or the
default, C<croak>. In C<quiet> mode, all errors will be silent. In C<carp> mode,
all errors will be emitted as warnings. And, in C<croak> mode, all errors will
be emitted as exceptions. Take a look at L<Try::Tiny> or
L<Syntax::Keyword::Try> to see how to catch exceptions.


=item

no_clobber

The C<no_clobber> option is a boolean option, defaulted to false (C<0>). Setting
this option to true (C<1>) will ensure an that existing file will not be
overwritten.

=item

perms

The C<perms> option sets the permissions of newly-created files. This value
is modified by your process's C<umask> and defaults to C<0666> (same as
C<sysopen>).

NOTE: this option is new as of File::Slurp version 9999.14.

=back

=head1 EXPORT

These are exported by default or with

	use File::Slurp qw(:std);
	# read_file write_file overwrite_file append_file read_dir

These are exported with

	use File::Slurp qw(:edit);
	# edit_file edit_file_lines

You can get all subs in the module exported with

	use File::Slurp qw(:all);

=head1 SEE ALSO

=over

=item *

L<File::Slurper> - Provides a straightforward set of functions for the most
common tasks of reading/writing text and binary files.

=item *

L<Path::Tiny> - Lightweight and comprehensive file handling, including simple
methods for reading, writing, and editing text and binary files.

=item *

L<Mojo::File> - Similar to Path::Tiny for the L<Mojo> toolkit, always works in
bytes.

=back

=head1 AUTHOR

Uri Guttman, <F<uri@stemsystems.com>>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2003 Uri Guttman. All rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
