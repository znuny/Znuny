package Sisimai::Lhost::Domino;
use parent 'Sisimai::Lhost';
use feature ':5.10';
use strict;
use warnings;
use Sisimai::String;
use Encode;
use Encode::Guess; Encode::Guess->add_suspects(@{ Sisimai::String->encodenames });

sub description { 'IBM Domino Server' }
sub make {
    # Detect an error from IBM Domino
    # @param    [Hash] mhead    Message headers of a bounce email
    # @param    [String] mbody  Message body of a bounce email
    # @return   [Hash]          Bounce data list and message/rfc822 part
    # @return   [Undef]         failed to parse or the arguments are missing
    # @since v4.0.2
    my $class = shift;
    my $mhead = shift // return undef;
    my $mbody = shift // return undef;
    return undef unless $mhead->{'subject'} =~ /\ADELIVERY(?:[ ]|_)FAILURE:/;

    state $indicators = __PACKAGE__->INDICATORS;
    state $rebackbone = qr|^Content-Type:[ ]message/rfc822|m;
    state $startingof = { 'message' => ['Your message'] };
    state $messagesof = {
        'userunknown' => [
            'not listed in Domino Directory',
            'not listed in public Name & Address Book',
            "non répertorié dans l'annuaire Domino",
            'Domino ディレクトリには見つかりません',
        ],
        'filtered'    => ['Cannot route mail to user'],
        'systemerror' => ['Several matches found in Domino Directory'],
    };

    require Sisimai::RFC1894;
    my $fieldtable = Sisimai::RFC1894->FIELDTABLE;
    my $permessage = {};    # (Hash) Store values of each Per-Message field
    my $dscontents = [__PACKAGE__->DELIVERYSTATUS];
    my $emailsteak = Sisimai::RFC5322->fillet($mbody, $rebackbone);
    my $readcursor = 0;     # (Integer) Points the current cursor position
    my $recipients = 0;     # (Integer) The number of 'Final-Recipient' header
    my $subjecttxt = '';    # (String) The value of Subject:
    my $v = undef;
    my $p = '';

    for my $e ( split("\n", $emailsteak->[0]) ) {
        # Read error messages and delivery status lines from the head of the email
        # to the previous line of the beginning of the original message.
        unless( $readcursor ) {
            # Beginning of the bounce message or message/delivery-status part
            $readcursor |= $indicators->{'deliverystatus'} if index($e, $startingof->{'message'}->[0]) == 0;
            next;
        }
        next unless $readcursor & $indicators->{'deliverystatus'};
        next unless length $e;

        # Your message
        #
        #   Subject: Test Bounce
        #
        # was not delivered to:
        #
        #   kijitora@example.net
        #
        # because:
        #
        #   User some.name (kijitora@example.net) not listed in Domino Directory
        #
        $v = $dscontents->[-1];
        if( $e eq 'was not delivered to:' ) {
            # was not delivered to:
            if( $v->{'recipient'} ) {
                # There are multiple recipient addresses in the message body.
                push @$dscontents, __PACKAGE__->DELIVERYSTATUS;
                $v = $dscontents->[-1];
            }
            $v->{'recipient'} ||= $e;
            $recipients++;

        } elsif( $e =~ /\A[ ][ ]([^ ]+[@][^ ]+)\z/ ) {
            # Continued from the line "was not delivered to:"
            #   kijitora@example.net
            $v->{'recipient'} = Sisimai::Address->s3s4($1);

        } elsif( $e eq 'because:' ) {
            # because:
            $v->{'diagnosis'} = $e;

        } else {
            if( exists $v->{'diagnosis'} && $v->{'diagnosis'} eq 'because:' ) {
                # Error message, continued from the line "because:"
                $v->{'diagnosis'} = $e;

            } elsif( $e =~ /\A[ ][ ]Subject: (.+)\z/ ) {
                #   Subject: Nyaa
                $subjecttxt = $1;

            } elsif( my $f = Sisimai::RFC1894->match($e) ) {
                # There are some fields defined in RFC3464, try to match
                next unless my $o = Sisimai::RFC1894->field($e);
                next if $o->[-1] eq 'addr';

                if( $o->[-1] eq 'code' ) {
                    # Diagnostic-Code: SMTP; 550 5.1.1 <userunknown@example.jp>... User Unknown
                    $v->{'spec'}      ||= $o->[1];
                    $v->{'diagnosis'} ||= $o->[2];

                } else {
                    # Other DSN fields defined in RFC3464
                    next unless exists $fieldtable->{ $o->[0] };
                    $v->{ $fieldtable->{ $o->[0] } } = $o->[2];

                    next unless $f == 1;
                    $permessage->{ $fieldtable->{ $o->[0] } } = $o->[2];
                }
            }
        }
    }
    return undef unless $recipients;

    for my $e ( @$dscontents ) {
        # Check the utf8 flag and fix
        UTF8FLAG: while(1) {
            # Delete the utf8 flag because there are a string including some characters which have 
            # utf8 flag but utf8::is_utf8 returns false
            last unless length $e->{'diagnosis'};
            last unless Sisimai::String->is_8bit(\$e->{'diagnosis'});

            my $cv = $e->{'diagnosis'};
            my $ce = Encode::Guess->guess($cv);
            last unless ref $ce;

            $cv = Encode::encode_utf8($cv);
            $e->{'diagnosis'} = $cv;
            last;
        }

        $e->{'diagnosis'} = Sisimai::String->sweep($e->{'diagnosis'});
        $e->{'recipient'} = Sisimai::Address->s3s4($e->{'recipient'});
        $e->{'lhost'}   ||= $permessage->{'rhost'};
        $e->{ $_ }      ||= $permessage->{ $_ } || '' for keys %$permessage;

        for my $r ( keys %$messagesof ) {
            # Check each regular expression of Domino error messages
            next unless grep { index($e->{'diagnosis'}, $_) > -1 } @{ $messagesof->{ $r } };
            $e->{'reason'}   = $r;
            $e->{'status'} ||= Sisimai::SMTP::Status->code($r, 0) || '';
            last;
        }
    }

    # Set the value of $subjecttxt as a Subject if there is no original
    # message in the bounce mail.
    $emailsteak->[1] .= sprintf("Subject: %s\n", $subjecttxt) unless $emailsteak->[1] =~ /^Subject:/m;

    return { 'ds' => $dscontents, 'rfc822' => $emailsteak->[1] };
}

1;
__END__

=encoding utf-8

=head1 NAME

Sisimai::Lhost::Domino - bounce mail parser class for IBM Domino Server.

=head1 SYNOPSIS

    use Sisimai::Lhost::Domino;

=head1 DESCRIPTION

Sisimai::Lhost::Domino parses a bounce email which created by IBM Domino Server.
Methods in the module are called from only Sisimai::Message.

=head1 CLASS METHODS

=head2 C<B<description()>>

C<description()> returns description string of this module.

    print Sisimai::Lhost::Domino->description;

=head2 C<B<make(I<header data>, I<reference to body string>)>>

C<make()> method parses a bounced email and return results as a array reference.
See Sisimai::Message for more details.

=head1 AUTHOR

azumakuniyuki

=head1 COPYRIGHT

Copyright (C) 2014-2021 azumakuniyuki, All rights reserved.

=head1 LICENSE

This software is distributed under The BSD 2-Clause License.

=cut
