package Sisimai::Lhost::Postfix;
use parent 'Sisimai::Lhost';
use feature ':5.10';
use strict;
use warnings;

sub description { 'Postfix' }
sub make {
    # Parse bounce messages from Postfix
    # @param    [Hash] mhead    Message headers of a bounce email
    # @param    [String] mbody  Message body of a bounce email
    # @return   [Hash]          Bounce data list and message/rfc822 part
    # @return   [Undef]         failed to parse or the arguments are missing
    # @since v4.0.0
    my $class = shift;
    my $mhead = shift // return undef;
    my $mbody = shift // return undef;

    return undef unless $mhead->{'subject'} eq 'Undelivered Mail Returned to Sender';
    return undef if $mhead->{'x-aol-ip'};

    state $indicators = __PACKAGE__->INDICATORS;
    state $rebackbone = qr<^Content-Type:[ ](?:message/rfc822|text/rfc822-headers)>m;
    state $markingsof = {
        # Postfix manual - bounce(5) - http://www.postfix.org/bounce.5.html
        'message' => qr{\A(?>
             [ ]+The[ ](?:
                 Postfix[ ](?:
                     program\z              # The Postfix program
                    |on[ ].+[ ]program\z    # The Postfix on <os name> program
                    )
                |\w+[ ]Postfix[ ]program\z  # The <name> Postfix program
                |mail[ \t]system\z             # The mail system
                |\w+[ \t]program\z             # The <custmized-name> program
                )
            |This[ ]is[ ]the[ ](?:
                 Postfix[ ]program          # This is the Postfix program
                |\w+[ ]Postfix[ ]program    # This is the <name> Postfix program
                |\w+[ ]program              # This is the <customized-name> Postfix program
                |mail[ ]system[ ]at[ ]host  # This is the mail system at host <hostname>.
                )
            )
        }x,
        # 'from'=> qr/ [(]Mail Delivery System[)]\z/,
    };

    require Sisimai::RFC1894;
    require Sisimai::Address;
    my $fieldtable = Sisimai::RFC1894->FIELDTABLE;
    my $permessage = {};    # (Hash) Store values of each Per-Message field

    my $dscontents = [__PACKAGE__->DELIVERYSTATUS];
    my $emailsteak = Sisimai::RFC5322->fillet($mbody, $rebackbone);
    my $readcursor = 0;     # (Integer) Points the current cursor position
    my $recipients = 0;     # (Integer) The number of 'Final-Recipient' header
    my $anotherset = {};    # (Hash) Another error information
    my $nomessages = 0;     # (Integer) Delivery report unavailable
    my @commandset;         # (Array) ``in reply to * command'' list
    my $v = undef;
    my $p = '';

    for my $e ( split("\n", $emailsteak->[0]) ) {
        # Read error messages and delivery status lines from the head of the email
        # to the previous line of the beginning of the original message.
        unless( $readcursor ) {
            # Beginning of the bounce message or message/delivery-status part
            $readcursor |= $indicators->{'deliverystatus'} if $e =~ $markingsof->{'message'};
            next;
        }
        next unless $readcursor & $indicators->{'deliverystatus'};
        next unless length $e;

        if( my $f = Sisimai::RFC1894->match($e) ) {
            # $e matched with any field defined in RFC3464
            next unless my $o = Sisimai::RFC1894->field($e);
            $v = $dscontents->[-1];

            if( $o->[-1] eq 'addr' ) {
                # Final-Recipient: rfc822; kijitora@example.jp
                # X-Actual-Recipient: rfc822; kijitora@example.co.jp
                if( $o->[0] eq 'final-recipient' ) {
                    # Final-Recipient: rfc822; kijitora@example.jp
                    if( $v->{'recipient'} ) {
                        # There are multiple recipient addresses in the message body.
                        push @$dscontents, __PACKAGE__->DELIVERYSTATUS;
                        $v = $dscontents->[-1];
                    }
                    $v->{'recipient'} = $o->[2];
                    $recipients++;

                } else {
                    # X-Actual-Recipient: rfc822; kijitora@example.co.jp
                    $v->{'alias'} = $o->[2];
                }
            } elsif( $o->[-1] eq 'code' ) {
                # Diagnostic-Code: SMTP; 550 5.1.1 <userunknown@example.jp>... User Unknown
                $v->{'spec'} = $o->[1];
                $v->{'spec'} = 'SMTP' if $v->{'spec'} eq 'X-POSTFIX';
                $v->{'diagnosis'} = $o->[2];

            } else {
                # Other DSN fields defined in RFC3464
                next unless exists $fieldtable->{ $o->[0] };
                $v->{ $fieldtable->{ $o->[0] } } = $o->[2];

                next unless $f == 1;
                $permessage->{ $fieldtable->{ $o->[0] } } = $o->[2];
            }
        } else {
            # If you do so, please include this problem report. You can
            # delete your own text from the attached returned message.
            #
            #           The mail system
            #
            # <userunknown@example.co.jp>: host mx.example.co.jp[192.0.2.153] said: 550
            # 5.1.1 <userunknown@example.co.jp>... User Unknown (in reply to RCPT TO command)
            if( index($p, 'Diagnostic-Code:') == 0 && $e =~ /\A[ \t]+(.+)\z/ ) {
                # Continued line of the value of Diagnostic-Code header
                $v->{'diagnosis'} .= ' '.$1;
                $e = 'Diagnostic-Code: '.$e;

            } elsif( $e =~ /\A(X-Postfix-Sender):[ ]*rfc822;[ ]*(.+)\z/ ) {
                # X-Postfix-Sender: rfc822; shironeko@example.org
                $emailsteak->[1] .= sprintf("%s: %s\n", $1, $2);

            } else {
                # Alternative error message and recipient
                if( $e =~ /[ \t][(]in reply to (?:end of )?([A-Z]{4}).*/ ||
                    $e =~ /([A-Z]{4})[ \t]*.*command[)]\z/ ) {
                    # 5.1.1 <userunknown@example.co.jp>... User Unknown (in reply to RCPT TO
                    push @commandset, $1;
                    $anotherset->{'diagnosis'} .= ' '.$e if $anotherset->{'diagnosis'};

                } elsif( $e =~ /\A[<]([^ ]+[@][^ ]+)[>] [(]expanded from [<](.+)[>][)]:[ \t]*(.+)\z/ ) {
                    # <r@example.ne.jp> (expanded from <kijitora@example.org>): user ...
                    $anotherset->{'recipient'} = $1;
                    $anotherset->{'alias'}     = $2;
                    $anotherset->{'diagnosis'} = $3;

                } elsif( $e =~ /\A[<]([^ ]+[@][^ ]+)[>]:(.*)\z/ ) {
                    # <kijitora@exmaple.jp>: ...
                    $anotherset->{'recipient'} = $1;
                    $anotherset->{'diagnosis'} = $2;

                } elsif( index($e, '--- Delivery report unavailable ---') > -1 ) {
                    # postfix-3.1.4/src/bounce/bounce_notify_util.c
                    # bounce_notify_util.c:602|if (bounce_info->log_handle == 0
                    # bounce_notify_util.c:602||| bounce_log_rewind(bounce_info->log_handle)) {
                    # bounce_notify_util.c:602|if (IS_FAILURE_TEMPLATE(bounce_info->template)) {
                    # bounce_notify_util.c:602|    post_mail_fputs(bounce, "");
                    # bounce_notify_util.c:602|    post_mail_fputs(bounce, "\t--- delivery report unavailable ---");
                    # bounce_notify_util.c:602|    count = 1;              /* xxx don't abort */
                    # bounce_notify_util.c:602|}
                    # bounce_notify_util.c:602|} else {
                    $nomessages = 1;

                } else {
                    # Get error message continued from the previous line
                    next unless $anotherset->{'diagnosis'};
                    $anotherset->{'diagnosis'} .= ' '.$e if $e =~ /\A[ \t]{4}(.+)\z/;
                }
            }
        } # End of message/delivery-status
    } continue {
        # Save the current line for the next loop
        $p = $e;
    }

    unless( $recipients ) {
        # Fallback: get a recipient address from error messages
        if( defined $anotherset->{'recipient'} && $anotherset->{'recipient'} ) {
            # Set a recipient address
            $dscontents->[-1]->{'recipient'} = $anotherset->{'recipient'};
            $recipients++;

        } else {
            # Get a recipient address from message/rfc822 part if the delivery
            # report was unavailable: '--- Delivery report unavailable ---'
            if( $nomessages && $emailsteak->[1] =~ /^To:[ ]*(.+)/m ) {
                # Try to get a recipient address from To: field in the original
                # message at message/rfc822 part
                $dscontents->[-1]->{'recipient'} = Sisimai::Address->s3s4($1);
                $recipients++;
            }
        }
    }
    return undef unless $recipients;

    for my $e ( @$dscontents ) {
        # Set default values if each value is empty.
        $e->{'lhost'} ||= $permessage->{'rhost'};
        $e->{ $_ } ||= $permessage->{ $_ } || '' for keys %$permessage;

        if( exists $anotherset->{'diagnosis'} && $anotherset->{'diagnosis'} ) {
            # Copy alternative error message
            $e->{'diagnosis'} ||= $anotherset->{'diagnosis'};
            if( $e->{'diagnosis'} =~ /\A\d+\z/ ) {
                # Override the value of diagnostic code message
                $e->{'diagnosis'} = $anotherset->{'diagnosis'};

            } else {
                # More detailed error message is in "$anotherset"
                my $as = undef; # status
                my $ar = undef; # replycode

                if( $e->{'status'} eq '' || substr($e->{'status'}, -4, 4) eq '.0.0' ) {
                    # Check the value of D.S.N. in $anotherset
                    $as = Sisimai::SMTP::Status->find($anotherset->{'diagnosis'}) || '';
                    if( length($as) > 0 && substr($as, -4, 4) ne '.0.0' ) {
                        # The D.S.N. is neither an empty nor *.0.0
                        $e->{'status'} = $as;
                    }
                }

                if( $e->{'replycode'} eq '' || substr($e->{'replycode'}, -2, 2) eq '00' ) {
                    # Check the value of SMTP reply code in $anotherset
                    $ar = Sisimai::SMTP::Reply->find($anotherset->{'diagnosis'}) || '';
                    if( length($ar) > 0 && substr($ar, -2, 2) ne '00' ) {
                        # The SMTP reply code is neither an empty nor *00
                        $e->{'replycode'} = $ar;
                    }
                }

                if( $as || $ar && ( length($anotherset->{'diagnosis'}) > length($e->{'diagnosis'}) ) ) {
                    # Update the error message in $e->{'diagnosis'}
                    $e->{'diagnosis'} = $anotherset->{'diagnosis'};
                }
            }
        }
        $e->{'diagnosis'} = Sisimai::String->sweep($e->{'diagnosis'});
        $e->{'command'}   = shift @commandset || '';
        $e->{'command'} ||= 'HELO' if $e->{'diagnosis'} =~ /refused to talk to me:/;
        $e->{'spec'}    ||= 'SMTP' if $e->{'diagnosis'} =~ /host .+ said:/;
    }
    return { 'ds' => $dscontents, 'rfc822' => $emailsteak->[1] };
}

1;
__END__

=encoding utf-8

=head1 NAME

Sisimai::Lhost::Postfix - bounce mail parser class for C<Postfix>.

=head1 SYNOPSIS

    use Sisimai::Lhost::Postfix;

=head1 DESCRIPTION

Sisimai::Lhost::Postfix parses a bounce email which created by C<Postfix>.
Methods in the module are called from only Sisimai::Message.

=head1 CLASS METHODS

=head2 C<B<description()>>

C<description()> returns description string of this module.

    print Sisimai::Lhost::Postfix->description;

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

