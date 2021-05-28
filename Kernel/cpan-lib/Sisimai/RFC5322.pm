package Sisimai::RFC5322;
use feature ':5.10';
use strict;
use warnings;
use constant HEADERTABLE => {
    'messageid' => ['message-id'],
    'subject'   => ['subject'],
    'listid'    => ['list-id'],
    'date'      => [qw|date posted-date posted resent-date|],
    'addresser' => [qw|from return-path reply-to errors-to reverse-path x-postfix-sender envelope-from x-envelope-from|],
    'recipient' => [qw|to delivered-to forward-path envelope-to x-envelope-to resent-to apparently-to|],
};

# Regular expression of valid RFC-5322 email address(<addr-spec>)
my $Re = { 'rfc5322' => undef, 'ignored' => undef, 'domain' => undef, };
BUILD_REGULAR_EXPRESSIONS: {
    # See http://www.ietf.org/rfc/rfc5322.txt
    #  or http://www.ex-parrot.com/pdw/Mail-RFC822-Address.html ...
    #   addr-spec       = local-part "@" domain
    #   local-part      = dot-atom / quoted-string / obs-local-part
    #   domain          = dot-atom / domain-literal / obs-domain
    #   domain-literal  = [CFWS] "[" *([FWS] dcontent) [FWS] "]" [CFWS]
    #   dcontent        = dtext / quoted-pair
    #   dtext           = NO-WS-CTL /     ; Non white space controls
    #                     %d33-90 /       ; The rest of the US-ASCII
    #                     %d94-126        ;  characters not including "[",
    #                                     ;  "]", or "\"
    my $atom           = qr;[a-zA-Z0-9_!#\$\%&'*+/=?\^`{}~|\-]+;o;
    my $quoted_string  = qr/"(?:\\[^\r\n]|[^\\"])*"/o;
    my $domain_literal = qr/\[(?:\\[\x01-\x09\x0B-\x0c\x0e-\x7f]|[\x21-\x5a\x5e-\x7e])*\]/o;
    my $dot_atom       = qr/$atom(?:[.]$atom)*/o;
    my $local_part     = qr/(?:$dot_atom|$quoted_string)/o;
    my $domain         = qr/(?:$dot_atom|$domain_literal)/o;

    $Re->{'rfc5322'} = qr/\A$local_part[@]$domain\z/o;
    $Re->{'ignored'} = qr/\A$local_part[.]*[@]$domain\z/o;
    $Re->{'domain'}  = qr/\A$domain\z/o;
}

my $HEADERINDEX = {};
BUILD_FLATTEN_RFC822HEADER_LIST: {
    # Convert $HEADER: hash reference to flatten hash reference for being
    # called from Sisimai::Lhost::*
    for my $v ( values %{ HEADERTABLE() } ) {
        $HEADERINDEX->{ $_ } = 1 for @$v;
    }
}

sub HEADERFIELDS {
    # Grouped RFC822 headers
    # @param    [String] group  RFC822 Header group name
    # @return   [Array,Hash]    RFC822 Header list
    my $class = shift;
    my $group = shift || return $HEADERINDEX;
    return HEADERTABLE->{ $group } if exists HEADERTABLE->{ $group };
    return HEADERTABLE;
}

sub LONGFIELDS {
    # Fields that might be long
    # @return   [Hash] Long filed(email header) list
    return { 'to' => 1, 'from' => 1, 'subject' => 1, 'message-id' => 1 };
}

sub is_emailaddress {
    # Check that the argument is an email address or not
    # @param    [String] email  Email address string
    # @return   [Integer]       0: Not email address
    #                           1: Email address
    my $class = shift;
    my $email = shift // return 0;

    return 0 if $email =~ /(?:[\x00-\x1f]|\x1f)/;
    return 0 if length $email > 254;
    return 1 if $email =~ $Re->{'ignored'};
    return 0;
}

sub is_mailerdaemon {
    # Check that the argument is mailer-daemon or not
    # @param    [String] email  Email address
    # @return   [Integer]       0: Not mailer-daemon
    #                           1: Mailer-daemon
    my $class = shift;
    my $email = shift // return 0;
    state $match = qr{(?>
         (?:mailer-daemon|postmaster)[@]
        |[<(](?:mailer-daemon|postmaster)[)>]
        |\A(?:mailer-daemon|postmaster)\z
        |[ ]?mailer-daemon[ ]
        )
    }x;
    return 1 if lc($email) =~ $match;
    return 0;
}

sub received {
    # Convert Received headers to a structured data
    # @param    [String] argv1  Received header
    # @return   [Array]         Received header as a structured data
    my $class = shift;
    my $argv1 = shift || return [];
    my $hosts = [];
    my $value = { 'from' => '', 'by'   => '' };

    # Received: (qmail 10000 invoked by uid 999); 24 Apr 2013 00:00:00 +0900
    return [] if $argv1 =~ /qmail[ \t]+.+invoked[ \t]+/;

    if( $argv1 =~ /\Afrom[ \t]+(.+)[ \t]+by[ \t]+([^ ]+)/ ) {
        # Received: from localhost (localhost)
        #   by nijo.example.jp (V8/cf) id s1QB5ma0018057;
        #   Wed, 26 Feb 2014 06:05:48 -0500
        $value->{'from'} = $1;
        $value->{'by'}   = $2;

    } elsif( $argv1 =~ /\bby[ \t]+([^ ]+)(.+)/ ) {
        # Received: by 10.70.22.98 with SMTP id c2mr1838265pdf.3; Fri, 18 Jul 2014
        #   00:31:02 -0700 (PDT)
        $value->{'from'} = $1.$2;
        $value->{'by'}   = $1;
    }

    if( $value->{'from'} =~ / / ) {
        # Received: from [10.22.22.222] (smtp-gateway.kyoto.ocn.ne.jp [192.0.2.222])
        #   (authenticated bits=0)
        #   by nijo.example.jp (V8/cf) with ESMTP id s1QB5ka0018055;
        #   Wed, 26 Feb 2014 06:05:47 -0500
        my @received = split(' ', $value->{'from'});
        my @namelist;
        my @addrlist;
        my $hostname = '';
        my $hostaddr = '';

        for my $e ( @received ) {
            # Received: from [10.22.22.222] (smtp-gateway.kyoto.ocn.ne.jp [192.0.2.222])
            if( $e =~ /\A[(\[]\d+[.]\d+[.]\d+[.]\d+[)\]]\z/ ) {
                # [192.0.2.1] or (192.0.2.1)
                $e =~ y/[]()//d;
                push @addrlist, $e;

            } else {
                # hostname
                $e =~ y/()//d;
                push @namelist, $e;
            }
        }

        for my $e ( @namelist ) {
            # 1. Hostname takes priority over all other IP addresses
            next unless rindex($e, '.') > -1;
            $hostname = $e;
            last;
        }

        unless( $hostname ) {
            # 2. Use IP address as a remote host name
            for my $e ( @addrlist ) {
                # Skip if the address is a private address
                next if index($e, '10.') == 0;
                next if index($e, '127.') == 0;
                next if index($e, '192.168.') == 0;
                next if $e =~ /\A172[.](?:1[6-9]|2[0-9]|3[0-1])[.]/;
                $hostaddr = $e;
                last;
            }
        }
        $value->{'from'} = $hostname || $hostaddr || $addrlist[-1];
    }

    for my $e ('from', 'by') {
        # Copy entries into $hosts
        next unless defined $value->{ $e };
        $value->{ $e } =~ y/()[];?//d;
        push @$hosts, $value->{ $e };
    }
    return $hosts;
}

sub fillet {
    # Split given entire message body into error message lines and the original
    # message part only include email headers
    # @param    [String] mbody  Entire message body
    # @param    [Regexp] regex  Regular expression of the message/rfc822 or the
    #                           beginning of the original message part
    # @return   [Array]         [Error message lines, The original message]
    # @since    v4.25.5
    my $class = shift;
    my $mbody = shift || return undef;
    my $regex = shift || return undef;

    my ($a, $b) = split($regex, $$mbody, 2); $b ||= '';
    if( length $b ) {
        # Remove blank lines, the message body of the original message, and
        # append "\n" at the end of the original message headers
        # 1. Remove leading blank lines
        # 2. Remove text after the first blank line: \n\n
        # 3. Append "\n" at the end of test block when the last character is not "\n"
        $b =~ s/\A[\r\n\s]+//m;
        substr($b, index($b, "\n\n") + 1, length($b), '') if index($b, "\n\n") > 0;
        $b .= "\n" unless $b =~ /\n\z/;
    }
    return [$a, $b];
}

1;
__END__

=encoding utf-8

=head1 NAME

Sisimai::RFC5322 - Email address related utilities

=head1 SYNOPSIS

    use Sisimai::RFC5322;

    print Sisimai::RFC5322->is_emailaddress('neko@example.jp');    # 1
    print Sisimai::RFC5322->is_domainpart('example.jp');           # 1
    print Sisimai::RFC5322->is_mailerdaemon('neko@example.jp');    # 0

=head1 DESCRIPTION

Sisimai::RFC5322 provide methods for checking email address.

=head1 CLASS METHODS

=head2 C<B<is_emailaddress(I<email address>)>>

C<is_emailaddress()> checks the argument is valid email address or not.

    print Sisimai::RFC5322->is_emailaddress('neko@example.jp');  # 1
    print Sisimai::RFC5322->is_emailaddress('neko%example.jp');  # 0

    my $addr_with_name = [
        'Stray cat <neko@example.jp',
        '=?UTF-8?B?55m954yr?= <shironeko@example.co.jp>',
    ];
    for my $e ( @$addr_with_name ) {
        print Sisimai::RFC5322->is_emailaddress($e); # 1
    }

=head2 C<B<is_domainpart(I<Domain>)>>

C<is_domainpart()> checks the argument is valid domain part of an email address
or not.

    print Sisimai::RFC5322->is_domainpart('neko@example.jp');  # 0
    print Sisimai::RFC5322->is_domainpart('neko.example.jp');  # 1

=head2 C<B<is_domainpart(I<Domain>)>>

C<is_mailerdaemon()> checks the argument is mailer-daemon or not.

    print Sisimai::RFC5322->is_mailerdaemon('neko@example.jp');          # 0
    print Sisimai::RFC5322->is_mailerdaemon('mailer-daemon@example.jp'); # 1

=head2 C<B<received(I<String>)>>

C<received()> returns array reference which include host names in the Received
header.

    my $v = 'from mx.example.org (c1.example.net [192.0.2.1]) by mx.example.jp';
    my $r = Sisimai::RFC5322->received($v);

    warn Dumper $r;
    $VAR1 = [
        'mx.example.org',
        'mx.example.jp'
    ];

=head2 C<B<fillet(I<String>, I<RegExp>)>>

C<fillet()> returns array reference which include error message lines of given
message body and the original message part split by the 2nd argument.

    my $v = 'Error message here
    Content-Type: message/rfc822
    Return-Path: <neko@libsisimai.org>';
    my $r = Sisimai::RFC5322->fillet(\$v, qr|^Content-Type:[ ]message/rfc822|m);

    warn Dumper $r;
    $VAR1 = [
        'Error message here',
        'Return-Path: <neko@libsisimai.org>';
    ];

=head1 AUTHOR

azumakuniyuki

=head1 COPYRIGHT

Copyright (C) 2014-2021 azumakuniyuki, All rights reserved.

=head1 LICENSE

This software is distributed under The BSD 2-Clause License.

=cut
