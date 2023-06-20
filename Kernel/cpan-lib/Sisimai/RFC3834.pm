package Sisimai::RFC3834;
use feature ':5.10';
use strict;
use warnings;

# http://tools.ietf.org/html/rfc3834
sub description { 'Detector for auto replied message' }
sub make {
    # Detect auto reply message as RFC3834
    # @param    [Hash] mhead    Message headers of a bounce email
    # @param    [String] mbody  Message body of a bounce email
    # @return   [Hash]          Bounce data list and message/rfc822 part
    # @return   [Undef]         failed to parse or the arguments are missing
    # @since v4.1.28
    my $class = shift;
    my $mhead = shift // return undef;
    my $mbody = shift // return undef;
    my $leave = 0;
    my $match = 0;

    return undef unless keys %$mhead;
    return undef unless ref $mbody eq 'SCALAR';

    my    $markingsof = { 'boundary' => qr/\A__SISIMAI_PSEUDO_BOUNDARY__\z/ };
    state $autoreply1 = {
        # http://www.iana.org/assignments/auto-submitted-keywords/auto-submitted-keywords.xhtml
        'auto-submitted' => qr/\Aauto-(?:generated|replied|notified)/,
        'x-apple-action' => qr/\Avacation\z/,
        'precedence' => qr/\Aauto_reply\z/,
        'subject' => qr/\A(?>
             auto:
            |auto[ ]response:
            |automatic[ ]reply:
            |out[ ]of[ ](?:the[ ])*office:
            )
        /x,
    };
    state $excludings = {
        'subject' => qr{(?:
              security[ ]information[ ]for  # sudo
             |mail[ ]failure[ ][-]          # Exim
             )
        }x,
        'from'    => qr/(?:root|postmaster|mailer-daemon)[@]/,
        'to'      => qr/root[@]/,
    };
    state $subjectset = qr{\A(?>
         (?:.+?)?re:
        |auto(?:[ ]response):
        |automatic[ ]reply:
        |out[ ]of[ ]office:
        )
        [ ]*(.+)\z
    }x;

    DETECT_EXCLUSION_MESSAGE: for my $e ( keys %$excludings ) {
        # Exclude message from root@
        next unless exists $mhead->{ $e };
        next unless defined $mhead->{ $e };
        next unless lc($mhead->{ $e }) =~ $excludings->{ $e };
        $leave = 1;
        last;
    }
    return undef if $leave;

    DETECT_AUTO_REPLY_MESSAGE: for my $e ( keys %$autoreply1 ) {
        # RFC3834 Auto-Submitted and other headers
        next unless exists $mhead->{ $e };
        next unless defined $mhead->{ $e };
        next unless lc($mhead->{ $e }) =~ $autoreply1->{ $e };
        $match++;
        last;
    }
    return undef unless $match;

    require Sisimai::Lhost;
    my $dscontents = [Sisimai::Lhost->DELIVERYSTATUS];
    my $recipients = 0;     # (Integer) The number of 'Final-Recipient' header
    my $maxmsgline = 5;     # (Integer) Max message length(lines)
    my $haveloaded = 0;     # (Integer) The number of lines loaded from message body
    my $blanklines = 0;     # (Integer) Counter for countinuous blank lines
    my $countuntil = 1;     # (Integer) Maximun value of blank lines in the body part
    my $v = $dscontents->[-1];

    RECIPIENT_ADDRESS: {
        # Try to get the address of the recipient
        for my $e ('from', 'return-path') {
            # Get the recipient address
            next unless exists  $mhead->{ $e };
            next unless defined $mhead->{ $e };

            $v->{'recipient'} = $mhead->{ $e };
            last;
        }

        if( $v->{'recipient'} ) {
            # Clean-up the recipient address
            $v->{'recipient'} = Sisimai::Address->s3s4($v->{'recipient'});
            $recipients++;
        }
    }
    return undef unless $recipients;

    if( $mhead->{'content-type'} ) {
        # Get the boundary string and set regular expression for matching with
        # the boundary string.
        my $b0 = Sisimai::MIME->boundary($mhead->{'content-type'}, 0);
        $markingsof->{'boundary'} = qr/\A\Q$b0\E\z/ if length $b0;
    }

    BODY_PARSER: {
        # Get vacation message
        for my $e ( split("\n", $$mbody) ) {
            # Read the first 5 lines except a blank line
            $countuntil += 1 if $e =~ $markingsof->{'boundary'};

            unless( length $e ) {
                # Check a blank line
                last if ++$blanklines > $countuntil;
                next;
            }
            next unless rindex($e, ' ') > -1;
            next if index($e, 'Content-Type') == 0;
            next if index($e, 'Content-Transfer') == 0;

            $v->{'diagnosis'} .= $e.' ';
            $haveloaded++;
            last if $haveloaded >= $maxmsgline;
        }
        $v->{'diagnosis'} ||= $mhead->{'subject'};
    }

    $v->{'diagnosis'} = Sisimai::String->sweep($v->{'diagnosis'});
    $v->{'reason'}    = 'vacation';
    $v->{'date'}      = $mhead->{'date'};
    $v->{'status'}    = '';

    # Get the Subject header from the original message
    my $rfc822part = lc($mhead->{'subject'}) =~ $subjectset ? 'Subject: '.$1."\n" : '';
    return { 'ds' => $dscontents, 'rfc822' => $rfc822part };
}

1;
__END__
=encoding utf-8

=head1 NAME

Sisimai::RFC3834 - RFC3834 auto reply message detector

=head1 SYNOPSIS

    use Sisimai::RFC3834;

=head1 DESCRIPTION

Sisimai::RFC3834 is a class which called from called from only Sisimai::Message
when other Sisimai::Lhost::* modules did not detected a bounce reason.

=head1 CLASS METHODS

=head2 C<B<description()>>

C<description()> returns description string of this module.

    print Sisimai::RFC3834->description;

=head2 C<B<make(I<header data>, I<reference to body string>)>>

C<make()> method parses an auto replied message and return results as an array
reference. See Sisimai::Message for more details.

=head1 AUTHOR

azumakuniyuki

=head1 COPYRIGHT

Copyright (C) 2015-2020,2023 azumakuniyuki, All rights reserved.

=head1 LICENSE

This software is distributed under The BSD 2-Clause License.

=cut

