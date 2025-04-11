package Sisimai;
use feature ':5.10';
use strict;
use warnings;
use version; our $VERSION = version->declare('v4.25.16'); our $PATCHLV = 0;

sub version { return substr($VERSION->stringify, 1).($PATCHLV > 0 ? 'p'.$PATCHLV : '') }
sub sysname { 'bouncehammer' }
sub libname { 'Sisimai'      }

sub make {
    # Wrapper method for parsing mailbox or Maildir/
    # @param         [String]  argv0      Path to mbox or Maildir/
    # @param         [Hash]    argv0      or Hash (decoded JSON)
    # @param         [Handle]  argv0      or STDIN
    # @param         [Hash]    argv1      Parser options
    # @options argv1 [Integer] delivered  1 = Including "delivered" reason
    # @options argv1 [Code]    hook       Code reference to a callback method
    # @return        [Array]              Parsed objects
    # @return        [Undef]              Undef if the argument was wrong or an empty array
    my $class = shift;
    my $argv0 = shift // return undef; die ' ***error: wrong number of arguments' if scalar @_ % 2;
    my $argv1 = { @_ };

    require Sisimai::Data;
    require Sisimai::Message;
    require Sisimai::Mail;

    my $list = [];
    my $mail = Sisimai::Mail->new($argv0) || return undef;
    while( my $r = $mail->data->read ) {
        # Read and parse each email file
        my $p = { 'data' => $r, 'hook' => $argv1->{'hook'} };
        next unless my $mesg = Sisimai::Message->new(%$p);

        $p = { 'data' => $mesg, 'delivered' => $argv1->{'delivered'}, 'origin' => $mail->data->path };
        my $data = Sisimai::Data->make(%$p);
        push @$list, @$data if scalar @$data;
    }
    return undef unless scalar @$list;
    return $list;
}

sub dump {
    # Wrapper method to parse mailbox/Maildir and dump as JSON
    # @param         [String]  argv0      Path to mbox or Maildir/
    # @param         [Hash]    argv0      or Hash (decoded JSON)
    # @param         [Handle]  argv0      or STDIN
    # @param         [Hash]    argv1      Parser options
    # @options argv1 [Integer] delivered  1 = Including "delivered" reason
    # @options argv1 [Code]    hook       Code reference to a callback method
    # @return        [String]             Parsed data as JSON text
    my $class = shift;
    my $argv0 = shift // return undef; die ' ***error: wrong number of arguments' if scalar @_ % 2;
    my $argv1 = { @_ };
    my $nyaan = __PACKAGE__->make($argv0, %$argv1) // [];

    for my $e ( @$nyaan ) {
        # Set UTF8 flag before converting to JSON string
        utf8::decode $e->{'subject'};
        utf8::decode $e->{'diagnosticcode'};
    }

    require Module::Load;
    Module::Load::load('JSON', '-convert_blessed_universally');
    my $jsonparser = JSON->new->allow_blessed->convert_blessed->utf8;
    my $jsonstring = $jsonparser->encode($nyaan);

    utf8::encode $jsonstring if utf8::is_utf8 $jsonstring;
    return $jsonstring;
}

sub engine {
    # Parser engine list (MTA modules)
    # @return   [Hash]     Parser engine table
    my $class = shift;
    my $table = {};

    for my $e ('Lhost', 'ARF', 'RFC3464', 'RFC3834') {
        my $r = 'Sisimai::'.$e;
        (my $loads = $r) =~ s|::|/|g;
        require $loads.'.pm';

        if( $e eq 'Lhost' ) {
            # Sisimai::Lhost::*
            for my $ee ( @{ $r->index } ) {
                # Load and get the value of "description" from each module
                my $rr = 'Sisimai::'.$e.'::'.$ee;
                ($loads = $rr) =~ s|::|/|g;
                require $loads.'.pm';
                $table->{ $rr } = $rr->description;
            }
        } else {
            # Sisimai::ARF, Sisimai::RFC3464, and Sisimai::RFC3834
            $table->{ $r } = $r->description;
        }
    }
    return $table;
}

sub reason {
    # Reason list Sisimai can detect
    # @return   [Hash]     Reason list table
    my $class = shift;
    my $table = {};

    # These reasons are not included in the results of Sisimai::Reason->index
    require Sisimai::Reason;
    my @names = (@{ Sisimai::Reason->index }, qw|Delivered Feedback Undefined Vacation|);

    for my $e ( @names ) {
        # Call ->description() method of Sisimai::Reason::*
        my $r = 'Sisimai::Reason::'.$e;
        (my $loads = $r) =~ s|::|/|g;
        require $loads.'.pm';
        $table->{ $e } = $r->description;
    }
    return $table;
}

sub match {
    # Try to match with message patterns
    # @param    [String]    Error message text
    # @return   [String]    Reason text
    my $class = shift;
    my $argvs = shift || return undef;

    require Sisimai::Reason;
    return Sisimai::Reason->match(lc $argvs);
}

1;
__END__

=encoding utf-8

=head1 NAME

Sisimai - Mail Analyzing Interface for bounce mails.

=head1 SYNOPSIS

    use Sisimai;

=head1 DESCRIPTION

C<Sisimai> is a Mail Analyzing Interface for email bounce, is a Perl module to
parse RFC5322 bounce mails and generating structured data as JSON from parsed
results. C<Sisimai> is a coined word: Sisi (the number 4 is pronounced "Si" in
Japanese) and MAI (acronym of "Mail Analyzing Interface").

=head1 BASIC USAGE

=head2 C<B<make(I<'/path/to/mbox'>)>>

C<make> method provides feature for getting parsed data from bounced email
messages like following.

    use Sisimai;
    my $v = Sisimai->make('/path/to/mbox'); # or Path to Maildir/
    #  $v = Sisimai->make(\'From Mailer-Daemon ...');

    if( defined $v ) {
        for my $e ( @$v ) {
            print ref $e;                   # Sisimai::Data
            print ref $e->recipient;        # Sisimai::Address
            print ref $e->timestamp;        # Sisimai::Time

            print $e->addresser->address;   # shironeko@example.org # From
            print $e->recipient->address;   # kijitora@example.jp   # To
            print $e->recipient->host;      # example.jp
            print $e->deliverystatus;       # 5.1.1
            print $e->replycode;            # 550
            print $e->reason;               # userunknown
            print $e->origin;               # /var/spool/bounce/2022-2222.eml

            my $h = $e->damn;               # Convert to HASH reference
            my $j = $e->dump('json');       # Convert to JSON string
            my $y = $e->dump('yaml');       # Convert to YAML string
        }

        # Dump entire list as a JSON
        use JSON '-convert_blessed_universally';
        my $json = JSON->new->allow_blessed->convert_blessed;

        printf "%s\n", $json->encode($v);
    }

If you want to get bounce records which reason is "delivered", set "delivered"
option to make() method like the following:

    my $v = Sisimai->make('/path/to/mbox', 'delivered' => 1);

=head2 C<B<dump(I<'/path/to/mbox'>)>>

C<dump> method provides feature to get parsed data from bounced email as JSON.

    use Sisimai;
    my $v = Sisimai->dump('/path/to/mbox'); # or Path to Maildir
    print $v;                               # JSON string

=head1 OTHER WAYS TO PARSE

=head2 Read email data from STDIN

If you want to pass email data from STDIN, specify B<STDIN> at the first argument
of dump() and make() method like following command:

    % cat ./path/to/bounce.eml | perl -MSisimai -lE 'print Sisimai->dump(STDIN)'

=head2 Callback Feature

Beginning from v4.19.0, `hook` argument is available to callback user defined
method like the following codes:

    my $cmethod = sub {
        my $argv = shift;
        my $data = {
            'queue-id' => '',
            'x-mailer' => '',
            'precedence' => '',
        };

        # Header part of the bounced mail
        for my $e ( 'x-mailer', 'precedence' ) {
            next unless exists $argv->{'headers'}->{ $e };
            $data->{ $e } = $argv->{'headers'}->{ $e };
        }

        # Message body of the bounced email
        if( $argv->{'message'} =~ /^X-Postfix-Queue-ID:\s*(.+)$/m ) {
            $data->{'queue-id'} = $1;
        }

        return $data;
    };

    my $message = Sisimai::Message->new(
        'data' => $mailtxt,
        'hook' => $cmethod,
    );
    print $message->catch->{'x-mailer'};    # Apple Mail (2.1283)
    print $message->catch->{'queue-id'};    # 2DAEB222022E
    print $message->catch->{'precedence'};  # bulk

=head1 OTHER METHODS

=head2 C<B<engine()>>

C<engine> method provides table including parser engine list and it's description.

    use Sisimai;
    my $v = Sisimai->engine();
    for my $e ( keys %$v ) {
        print $e;           # Sisimai::MTA::Sendmail
        print $v->{ $e };   # V8Sendmail: /usr/sbin/sendmail
    }

=head2 C<B<reason()>>

C<reason> method provides table including all the reasons Sisimai can detect

    use Sisimai;
    my $v = Sisimai->reason();
    for my $e ( keys %$v ) {
        print $e;           # Blocked
        print $v->{ $e };   # 'Email rejected due to client IP address or a hostname'
    }

=head2 C<B<match()>>

C<match> method receives an error message as a string and returns a reason name
like the following:

    use Sisimai;
    my $v = '550 5.1.1 User unknown';
    my $r = Sisimai->match($v);
    print $r;   # "userunknown"

=head2 C<B<version()>>

C<version> method returns the version number of Sisimai.

    use Sisimai;
    print Sisimai->version; # 4.25.0p5

=head1 SEE ALSO

=over

=item L<Sisimai::Mail> - Mailbox or Maildir object

=item L<Sisimai::Data> - Parsed data object

=item L<https://libsisimai.org/> - Sisimai — A successor to bounceHammer, Library to parse error mails

=item L<https://tools.ietf.org/html/rfc3463> - RFC3463: Enhanced Mail System Status Codes

=item L<https://tools.ietf.org/html/rfc3464> - RFC3464: An Extensible Message Format for Delivery Status Notifications

=item L<https://tools.ietf.org/html/rfc5321> - RFC5321: Simple Mail Transfer Protocol

=item L<https://tools.ietf.org/html/rfc5322> - RFC5322: Internet Message Format

=back

=head1 REPOSITORY

L<https://github.com/sisimai/p5-sisimai> - Sisimai on GitHub

=head1 WEB SITE

L<https://libsisimai.org/> - A successor to bounceHammer, Library to parse error mails.

L<https://github.com/sisimai/rb-sisimai> - Ruby version of Sisimai

=head1 AUTHOR

azumakuniyuki

=head1 COPYRIGHT

Copyright (C) 2014-2022 azumakuniyuki, All rights reserved.

=head1 LICENSE

This software is distributed under The BSD 2-Clause License.

=cut
