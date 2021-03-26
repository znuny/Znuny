package Sisimai::Lhost::EZweb;
use parent 'Sisimai::Lhost';
use feature ':5.10';
use strict;
use warnings;

sub description { 'au EZweb: http://www.au.kddi.com/mobile/' }
sub make {
    # Detect an error from EZweb
    # @param    [Hash] mhead    Message headers of a bounce email
    # @param    [String] mbody  Message body of a bounce email
    # @return   [Hash]          Bounce data list and message/rfc822 part
    # @return   [Undef]         failed to parse or the arguments are missing
    # @since v4.0.0
    my $class = shift;
    my $mhead = shift // return undef;
    my $mbody = shift // return undef;
    my $match = 0;

    # Pre-process email headers of NON-STANDARD bounce message au by EZweb, as
    # known as ezweb.ne.jp.
    #   Subject: Mail System Error - Returned Mail
    #   From: <Postmaster@ezweb.ne.jp>
    #   Received: from ezweb.ne.jp (wmflb12na02.ezweb.ne.jp [222.15.69.197])
    #   Received: from nmomta.auone-net.jp ([aaa.bbb.ccc.ddd]) by ...
    #
    $match++ if rindex($mhead->{'from'}, 'Postmaster@ezweb.ne.jp') > -1;
    $match++ if rindex($mhead->{'from'}, 'Postmaster@au.com') > -1;
    $match++ if $mhead->{'subject'} eq 'Mail System Error - Returned Mail';
    $match++ if grep { rindex($_, 'ezweb.ne.jp (EZweb Mail) with') > -1 } @{ $mhead->{'received'} };
    $match++ if grep { rindex($_, '.au.com (') > -1 } @{ $mhead->{'received'} };
    if( defined $mhead->{'message-id'} ) {
        $match++ if substr($mhead->{'message-id'}, -13, 13) eq '.ezweb.ne.jp>';
        $match++ if substr($mhead->{'message-id'}, -8, 8) eq '.au.com>';
    }
    return undef if $match < 2;

    state $indicators = __PACKAGE__->INDICATORS;
    state $rebackbone = qr<^(?:[-]{50}|Content-Type:[ ]*message/rfc822)>m;
    my    $markingsof = {
        'message' => qr{\A(?:
             The[ ]user[(]s[)][ ]
            |Your[ ]message[ ]
            |Each[ ]of[ ]the[ ]following
            |[<][^ ]+[@][^ ]+[>]\z
            )
        }x,
        'boundary' => qr/\A__SISIMAI_PSEUDO_BOUNDARY__\z/,
    };
    state $refailures = {
        #'notaccept'  => [qr/The following recipients did not receive this message:/],
        'mailboxfull' => [qr/The user[(]s[)] account is temporarily over quota/],
        'suspend'     => [
            # http://www.naruhodo-au.kddi.com/qa3429203.html
            # The recipient may be unpaid user...?
            qr/The user[(]s[)] account is disabled[.]/,
            qr/The user[(]s[)] account is temporarily limited[.]/,
        ],
        'expired' => [
            # Your message was not delivered within 0 days and 1 hours.
            # Remote host is not responding.
            qr/Your message was not delivered within /,
        ],
        'onhold' => [qr/Each of the following recipients was rejected by a remote mail server/],
    };

    require Sisimai::RFC1894;
    my $fieldtable = Sisimai::RFC1894->FIELDTABLE;
    my $dscontents = [__PACKAGE__->DELIVERYSTATUS];
    my $emailsteak = Sisimai::RFC5322->fillet($mbody, $rebackbone);
    my $readcursor = 0;     # (Integer) Points the current cursor position
    my $recipients = 0;     # (Integer) The number of 'Final-Recipient' header
    my $v = undef;

    if( $mhead->{'content-type'} ) {
        # Get the boundary string and set regular expression for matching with
        # the boundary string.
        my $b0 = Sisimai::MIME->boundary($mhead->{'content-type'}, 1);
        $markingsof->{'boundary'} = qr/\A\Q$b0\E\z/ if $b0; # Convert to regular expression
    }
    my @rxmessages; push @rxmessages, @{ $refailures->{ $_ } } for keys %$refailures;

    for my $e ( split("\n", $emailsteak->[0]) ) {
        # Read error messages and delivery status lines from the head of the email
        # to the previous line of the beginning of the original message.
        unless( $readcursor ) {
            # Beginning of the bounce message or message/delivery-status part
            $readcursor |= $indicators->{'deliverystatus'} if $e =~ $markingsof->{'message'};
        }
        next unless $readcursor & $indicators->{'deliverystatus'};
        next unless length $e;

        # The user(s) account is disabled.
        #
        # <***@ezweb.ne.jp>: 550 user unknown (in reply to RCPT TO command)
        #
        #  -- OR --
        # Each of the following recipients was rejected by a remote
        # mail server.
        #
        #    Recipient: <******@ezweb.ne.jp>
        #    >>> RCPT TO:<******@ezweb.ne.jp>
        #    <<< 550 <******@ezweb.ne.jp>: User unknown
        $v = $dscontents->[-1];

        if( $e =~ /\A[<]([^ ]+[@][^ ]+)[>]\z/ ||
            $e =~ /\A[<]([^ ]+[@][^ ]+)[>]:?(.*)\z/ ||
            $e =~ /\A[ \t]+Recipient: [<]([^ ]+[@][^ ]+)[>]/ ) {

            if( $v->{'recipient'} ) {
                # There are multiple recipient addresses in the message body.
                push @$dscontents, __PACKAGE__->DELIVERYSTATUS;
                $v = $dscontents->[-1];
            }

            my $r = Sisimai::Address->s3s4($1);
            $v->{'recipient'} = $r;
            $recipients++;

        } elsif( my $f = Sisimai::RFC1894->match($e) ) {
            # $e matched with any field defined in RFC3464
            next unless my $o = Sisimai::RFC1894->field($e);
            next unless exists $fieldtable->{ $o->[0] };
            $v->{ $fieldtable->{ $o->[0] } } = $o->[2];

        } else {
            # The line does not begin with a DSN field defined in RFC3464
            next if Sisimai::String->is_8bit(\$e);
            if( $e =~ /\A[ \t]+[>]{3}[ \t]+([A-Z]{4})/ ) {
                #    >>> RCPT TO:<******@ezweb.ne.jp>
                $v->{'command'} = $1;

            } else {
                # Check error message
                if( grep { $e =~ $_ } @rxmessages ) {
                    # Check with regular expressions of each error
                    $v->{'diagnosis'} .= ' '.$e;
                } else {
                    # >>> 550
                    $v->{'alterrors'} .= ' '.$e;
                }
            }
        } # End of error message part
    }
    return undef unless $recipients;

    for my $e ( @$dscontents ) {
        if( exists $e->{'alterrors'} && $e->{'alterrors'} ) {
            # Copy alternative error message
            $e->{'diagnosis'} ||= $e->{'alterrors'};
            if( index($e->{'diagnosis'}, '-') == 0 || substr($e->{'diagnosis'}, -2, 2) eq '__' ) {
                # Override the value of diagnostic code message
                $e->{'diagnosis'} = $e->{'alterrors'} if $e->{'alterrors'};
            }
            delete $e->{'alterrors'};
        }
        $e->{'diagnosis'} = Sisimai::String->sweep($e->{'diagnosis'});

        if( defined $mhead->{'x-spasign'} && $mhead->{'x-spasign'} eq 'NG' ) {
            # Content-Type: text/plain; ..., X-SPASIGN: NG (spamghetti, au by EZweb)
            # Filtered recipient returns message that include 'X-SPASIGN' header
            $e->{'reason'} = 'filtered';

        } else {
            if( $e->{'command'} eq 'RCPT' ) {
                # set "userunknown" when the remote server rejected after RCPT
                # command.
                $e->{'reason'} = 'userunknown';

            } else {
                # SMTP command is not RCPT
                SESSION: for my $r ( keys %$refailures ) {
                    # Verify each regular expression of session errors
                    PATTERN: for my $rr ( @{ $refailures->{ $r } } ) {
                        # Check each regular expression
                        next(PATTERN) unless $e->{'diagnosis'} =~ $rr;
                        $e->{'reason'} = $r;
                        last(SESSION);
                    }
                }
            }
        }
        next if $e->{'reason'};
        next if $e->{'recipient'} =~ /[@](?:ezweb[.]ne[.]jp|au[.]com)\z/;
        $e->{'reason'} = 'userunknown';
    }
    return { 'ds' => $dscontents, 'rfc822' => $emailsteak->[1] };
}

1;
__END__
=encoding utf-8

=head1 NAME

Sisimai::Lhost::EZweb - bounce mail parser class for C<au EZweb>.

=head1 SYNOPSIS

    use Sisimai::Lhost::EZweb;

=head1 DESCRIPTION

Sisimai::Lhost::EZweb parses a bounce email which created by C<au EZweb>.
Methods in the module are called from only Sisimai::Message.

=head1 CLASS METHODS

=head2 C<B<description()>>

C<description()> returns description string of this module.

    print Sisimai::Lhost::EZweb->description;

=head2 C<B<make(I<header data>, I<reference to body string>)>>

C<make()> method parses a bounced email and return results as a array reference.
See Sisimai::Message for more details.

=head1 AUTHOR

azumakuniyuki

=head1 COPYRIGHT

Copyright (C) 2014-2020 azumakuniyuki, All rights reserved.

=head1 LICENSE

This software is distributed under The BSD 2-Clause License.

=cut

