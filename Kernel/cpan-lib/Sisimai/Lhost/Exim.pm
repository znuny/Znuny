package Sisimai::Lhost::Exim;
use parent 'Sisimai::Lhost';
use feature ':5.10';
use strict;
use warnings;

sub description { 'Exim' }
sub make {
    # Detect an error from Exim
    # @param    [Hash] mhead    Message headers of a bounce email
    # @param    [String] mbody  Message body of a bounce email
    # @return   [Hash]          Bounce data list and message/rfc822 part
    # @return   [Undef]         failed to parse or the arguments are missing
    # @since v4.0.0
    my $class = shift;
    my $mhead = shift // return undef;
    my $mbody = shift // return undef;
    my $match = 0;
    return undef if $mhead->{'from'} =~/[@].+[.]mail[.]ru[>]?/;

    # Message-Id: <E1P1YNN-0003AD-Ga@example.org>
    # X-Failed-Recipients: kijitora@example.ed.jp
    $match++ if index($mhead->{'from'}, 'Mail Delivery System') == 0;
    $match++ if defined $mhead->{'message-id'} &&
                $mhead->{'message-id'} =~ /\A[<]\w{7}[-]\w{6}[-]\w{2}[@]/;
    $match++ if $mhead->{'subject'} =~ qr{(?:
         Mail[ ]delivery[ ]failed(:[ ]returning[ ]message[ ]to[ ]sender)?
        |Warning:[ ]message[ ][^ ]+[ ]delayed[ ]+
        |Delivery[ ]Status[ ]Notification
        |Mail[ ]failure
        |Message[ ]frozen
        |error[(]s[)][ ]in[ ]forwarding[ ]or[ ]filtering
        )
    }x;
    return undef if $match < 2;

    state $indicators = __PACKAGE__->INDICATORS;
    state $rebackbone = qr{^(?:
        # deliver.c:6423|          if (bounce_return_body) fprintf(f,
        # deliver.c:6424|"------ This is a copy of the message, including all the headers. ------\n");
        # deliver.c:6425|          else fprintf(f,
        # deliver.c:6426|"------ This is a copy of the message's headers. ------\n");
         [-]+[ ]This[ ]is[ ]a[ ]copy[ ]of[ ](?:the|your)[ ]message,[ ]including[ ]all[ ]the[ ]headers[.][ ][-]+
        |Content-Type:[ ]*message/rfc822\n(?:[\s\t]+.*?\n\n)?
        )
    }msx;
    state $startingof = { 'deliverystatus' => ['Content-type: message/delivery-status'] };
    state $markingsof = {
        # Error text regular expressions which defined in exim/src/deliver.c
        #
        # deliver.c:6292| fprintf(f,
        # deliver.c:6293|"This message was created automatically by mail delivery software.\n");
        # deliver.c:6294|        if (to_sender)
        # deliver.c:6295|          {
        # deliver.c:6296|          fprintf(f,
        # deliver.c:6297|"\nA message that you sent could not be delivered to one or more of its\n"
        # deliver.c:6298|"recipients. This is a permanent error. The following address(es) failed:\n");
        # deliver.c:6299|          }
        # deliver.c:6300|        else
        # deliver.c:6301|          {
        # deliver.c:6302|          fprintf(f,
        # deliver.c:6303|"\nA message sent by\n\n  <%s>\n\n"
        # deliver.c:6304|"could not be delivered to one or more of its recipients. The following\n"
        # deliver.c:6305|"address(es) failed:\n", sender_address);
        # deliver.c:6306|          }
        'alias'   => qr/\A([ ]+an undisclosed address)\z/,
        'message' => qr{\A(?>
             This[ ]message[ ]was[ ]created[ ]automatically[ ]by[ ]mail[ ]delivery[ ]software[.]
            |A[ ]message[ ]that[ ]you[ ]sent[ ]was[ ]rejected[ ]by[ ]the[ ]local[ ]scannning[ ]code
            |A[ ]message[ ]that[ ]you[ ]sent[ ]contained[ ]one[ ]or[ ]more[ ]recipient[ ]addresses[ ]
            |A[ ]message[ ]that[ ]you[ ]sent[ ]could[ ]not[ ]be[ ]delivered[ ]to[ ]all[ ]of[ ]its[ ]recipients
            |Message[ ][^ ]+[ ](?:has[ ]been[ ]frozen|was[ ]frozen[ ]on[ ]arrival)
            |The[ ][^ ]+[ ]router[ ]encountered[ ]the[ ]following[ ]error[(]s[)]:
            )
        }x,
        'frozen'  => qr/\AMessage [^ ]+ (?:has been frozen|was frozen on arrival)/,
    };
    state $recommands = [
        # transports/smtp.c:564|  *message = US string_sprintf("SMTP error from remote mail server after %s%s: "
        # transports/smtp.c:837|  string_sprintf("SMTP error from remote mail server after RCPT TO:<%s>: "
        qr/SMTP error from remote (?:mail server|mailer) after ([A-Za-z]{4})/,
        qr/SMTP error from remote (?:mail server|mailer) after end of ([A-Za-z]{4})/,
        qr/LMTP error after ([A-Za-z]{4})/,
        qr/LMTP error after end of ([A-Za-z]{4})/,
    ];
    state $messagesof = {
        # find exim/ -type f -exec grep 'message = US' {} /dev/null \;
        # route.c:1158|  DEBUG(D_uid) debug_printf("getpwnam() returned NULL (user not found)\n");
        'userunknown' => ['user not found'],
        # transports/smtp.c:3524|  addr->message = US"all host address lookups failed permanently";
        # routers/dnslookup.c:331|  addr->message = US"all relevant MX records point to non-existent hosts";
        # route.c:1826|  uschar *message = US"Unrouteable address";
        'hostunknown' => [
            'all host address lookups failed permanently',
            'all relevant MX records point to non-existent hosts',
            'Unrouteable address',
        ],
        # transports/appendfile.c:2567|  addr->user_message = US"mailbox is full";
        # transports/appendfile.c:3049|  addr->message = string_sprintf("mailbox is full "
        # transports/appendfile.c:3050|  "(quota exceeded while writing to file %s)", filename);
        'mailboxfull' => [
            'mailbox is full',
            'error: quota exceed',
        ],
        # routers/dnslookup.c:328|  addr->message = US"an MX or SRV record indicated no SMTP service";
        # transports/smtp.c:3502|  addr->message = US"no host found for existing SMTP connection";
        'notaccept' => [
            'an MX or SRV record indicated no SMTP service',
            'no host found for existing SMTP connection',
        ],
        # parser.c:666| *errorptr = string_sprintf("%s (expected word or \"<\")", *errorptr);
        # parser.c:701| if(bracket_count++ > 5) FAILED(US"angle-brackets nested too deep");
        # parser.c:738| FAILED(US"domain missing in source-routed address");
        # parser.c:747| : string_sprintf("malformed address: %.32s may not follow %.*s",
        'syntaxerror' => [
            'angle-brackets nested too deep',
            'expected word or "<"',
            'domain missing in source-routed address',
            'malformed address:',
        ],
        # deliver.c:5614|  addr->message = US"delivery to file forbidden";
        # deliver.c:5624|  addr->message = US"delivery to pipe forbidden";
        # transports/pipe.c:1156|  addr->user_message = US"local delivery failed";
        'systemerror' => [
            'delivery to file forbidden',
            'delivery to pipe forbidden',
            'local delivery failed',
            'LMTP error after ',
        ],
        # deliver.c:5425|  new->message = US"Too many \"Received\" headers - suspected mail loop";
        'contenterror' => ['Too many "Received" headers'],
    };
    state $delayedfor = [
        # retry.c:902|  addr->message = (addr->message == NULL)? US"retry timeout exceeded" :
        # deliver.c:7475|  "No action is required on your part. Delivery attempts will continue for\n"
        # smtp.c:3508|  US"retry time not reached for any host after a long failure period" :
        # smtp.c:3508|  US"all hosts have been failing for a long time and were last tried "
        #                 "after this message arrived";
        # deliver.c:7459|  print_address_error(addr, f, US"Delay reason: ");
        # deliver.c:7586|  "Message %s has been frozen%s.\nThe sender is <%s>.\n", message_id,
        # receive.c:4021|  moan_tell_someone(freeze_tell, NULL, US"Message frozen on arrival",
        # receive.c:4022|  "Message %s was frozen on arrival by %s.\nThe sender is <%s>.\n",
        'retry timeout exceeded',
        'No action is required on your part',
        'retry time not reached for any host after a long failure period',
        'all hosts have been failing for a long time and were last tried',
        'Delay reason: ',
        'has been frozen',
        'was frozen on arrival by ',
    ];

    require Sisimai::RFC1894;
    my $fieldtable = Sisimai::RFC1894->FIELDTABLE;
    my $dscontents = [__PACKAGE__->DELIVERYSTATUS];
    my $emailsteak = Sisimai::RFC5322->fillet($mbody, $rebackbone);
    my $readcursor = 0;     # (Integer) Points the current cursor position
    my $nextcursor = 0;
    my $recipients = 0;     # (Integer) The number of 'Final-Recipient' header
    my $localhost0 = '';    # (String) Local MTA
    my $boundary00 = '';    # (String) Boundary string
    my $v = undef;

    if( $mhead->{'content-type'} ) {
        # Get the boundary string and set regular expression for matching with
        # the boundary string.
        $boundary00 = Sisimai::MIME->boundary($mhead->{'content-type'});
    }

    for my $e ( split("\n", $emailsteak->[0]) ) {
        # Read error messages and delivery status lines from the head of the email
        # to the previous line of the beginning of the original message.
        unless( $readcursor ) {
            # Beginning of the bounce message or message/delivery-status part
            if( $e =~ $markingsof->{'message'} ) {
                $readcursor |= $indicators->{'deliverystatus'};
                next unless $e =~ $markingsof->{'frozen'};
            }
        }
        next unless $readcursor & $indicators->{'deliverystatus'};
        next unless length $e;

        # This message was created automatically by mail delivery software.
        #
        # A message that you sent could not be delivered to one or more of its
        # recipients. This is a permanent error. The following address(es) failed:
        #
        #  kijitora@example.jp
        #    SMTP error from remote mail server after RCPT TO:<kijitora@example.jp>:
        #    host neko.example.jp [192.0.2.222]: 550 5.1.1 <kijitora@example.jp>... User Unknown
        $v = $dscontents->[-1];

        if( $e =~ /\A[ \t]{2}([^ \t]+[@][^ \t]+[.]?[a-zA-Z]+)(:.+)?\z/ ||
            $e =~ /\A[ \t]{2}[^ \t]+[@][^ \t]+[.][a-zA-Z]+[ ]<(.+?[@].+?)>:.+\z/ ||
            $e =~ $markingsof->{'alias'} ) {
            #   kijitora@example.jp
            #   sabineko@example.jp: forced freeze
            #   mikeneko@example.jp <nekochan@example.org>: ...
            #
            # deliver.c:4549|  printed = US"an undisclosed address";
            #   an undisclosed address
            #     (generated from kijitora@example.jp)
            my $r = $1;

            if( $v->{'recipient'} ) {
                # There are multiple recipient addresses in the message body.
                push @$dscontents, __PACKAGE__->DELIVERYSTATUS;
                $v = $dscontents->[-1];
            }

            if( $e =~ /\A[ \t]+[^ \t]+[@][^ \t]+[.][a-zA-Z]+[ ]<(.+?[@].+?)>:.+\z/ ) {
                # parser.c:743| while (bracket_count-- > 0) if (*s++ != '>')
                # parser.c:744|   {
                # parser.c:745|   *errorptr = s[-1] == 0
                # parser.c:746|     ? US"'>' missing at end of address"
                # parser.c:747|     : string_sprintf("malformed address: %.32s may not follow %.*s",
                # parser.c:748|     s-1, (int)(s - US mailbox - 1), mailbox);
                # parser.c:749|   goto PARSE_FAILED;
                # parser.c:750|   }
                $r = $1;
                $v->{'diagnosis'} = $e;
            }
            $v->{'recipient'} = $r;
            $recipients++;

        } elsif( $e =~ /\A[ ]+[(]generated[ ]from[ ](.+)[)]\z/ ||
                 $e =~ /\A[ ]+generated[ ]by[ ]([^ \t]+[@][^ \t]+)/ ) {
            #     (generated from kijitora@example.jp)
            #  pipe to |/bin/echo "Some pipe output"
            #    generated by userx@myhost.test.ex
            $v->{'alias'} = $1;

        } else {
            next unless length $e;

            if( $e =~ $markingsof->{'frozen'} ) {
                # Message *** has been frozen by the system filter.
                # Message *** was frozen on arrival by ACL.
                $v->{'alterrors'} .= $e.' ';

            } else {
                if( $boundary00 ) {
                    # --NNNNNNNNNN-eximdsn-MMMMMMMMMM
                    # Content-type: message/delivery-status
                    # ...
                    if( Sisimai::RFC1894->match($e) ) {
                        # $e matched with any field defined in RFC3464
                        next unless my $o = Sisimai::RFC1894->field($e);

                        if( $o->[-1] eq 'addr' ) {
                            # Final-Recipient: rfc822;|/bin/echo "Some pipe output"
                            next unless $o->[0] eq 'final-recipient';
                            $v->{'spec'} ||= rindex($o->[2], '@') > -1 ? 'SMTP' : 'X-UNIX';

                        } elsif( $o->[-1] eq 'code' ) {
                            # Diagnostic-Code: SMTP; 550 5.1.1 <userunknown@example.jp>... User Unknown
                            $v->{'spec'} = uc $o->[1];
                            $v->{'diagnosis'} = $o->[2];

                        } else {
                            # Other DSN fields defined in RFC3464
                            next unless exists $fieldtable->{ $o->[0] };
                            $v->{ $fieldtable->{ $o->[0] } } = $o->[2];
                        }
                    } else {
                        # Error message ?
                        next if $nextcursor;
                        # Content-type: message/delivery-status
                        $nextcursor = 1 if index($e, $startingof->{'deliverystatus'}) == 0;
                        $v->{'alterrors'} .= $e.' ' if index($e, ' ') == 0;
                    }
                } else {
                    if( scalar @$dscontents == $recipients ) {
                        # Error message
                        next unless length $e;
                        $v->{'diagnosis'} .= $e.' ';

                    } else {
                        # Error message when email address above does not include '@'
                        # and domain part.
                        if( $e =~ m<\A[ ]+pipe[ ]to[ ][|]/[^ ]+> ) {
                            # pipe to |/path/to/prog ...
                            #   generated by kijitora@example.com
                            $v->{'diagnosis'} = $e;

                        } else {
                            next unless index($e, '    ') == 0;
                            $v->{'alterrors'} .= $e.' ';
                        }
                    }
                }
            }
        }
    }

    if( $recipients ) {
        # Check "an undisclosed address", "unroutable address"
        for my $q ( @$dscontents ) {
            # Replace the recipient address with the value of "alias"
            next unless $q->{'alias'};
            if( ! $q->{'recipient'} || rindex($q->{'recipient'}, '@') == -1 ) {
                # The value of "recipient" is empty or does not include "@"
                $q->{'recipient'} = $q->{'alias'};
            }
        }
    } else {
        # Fallback for getting recipient addresses
        if( defined $mhead->{'x-failed-recipients'} ) {
            # X-Failed-Recipients: kijitora@example.jp
            my @rcptinhead = split(',', $mhead->{'x-failed-recipients'});
            for my $e ( @rcptinhead ) { $e =~ s/\A[ ]+//; $e =~ s/[ ]+\z// }
            $recipients = scalar @rcptinhead;

            for my $e ( @rcptinhead ) {
                # Insert each recipient address into @$dscontents
                $dscontents->[-1]->{'recipient'} = $e;
                next if scalar @$dscontents == $recipients;
                push @$dscontents, __PACKAGE__->DELIVERYSTATUS;
            }
        }
    }
    return undef unless $recipients;

    if( scalar @{ $mhead->{'received'} } ) {
        # Get the name of local MTA
        # Received: from marutamachi.example.org (c192128.example.net [192.0.2.128])
        $localhost0 = $1 if $mhead->{'received'}->[-1] =~ /from[ \t]([^ ]+) /;
    }

    for my $e ( @$dscontents ) {
        # Set default values if each value is empty.
        $e->{'lhost'} ||= $localhost0;

        if( ! $e->{'diagnosis'} && length($boundary00) > 0 ) {
            # Empty Diagnostic-Code: or error message
            # --NNNNNNNNNN-eximdsn-MMMMMMMMMM
            # Content-type: message/delivery-status
            #
            # Reporting-MTA: dns; the.local.host.name
            #
            # Action: failed
            # Final-Recipient: rfc822;/a/b/c
            # Status: 5.0.0
            #
            # Action: failed
            # Final-Recipient: rfc822;|/p/q/r
            # Status: 5.0.0
            $e->{'diagnosis'} = $dscontents->[0]->{'diagnosis'} || '';
            $e->{'spec'}    ||= $dscontents->[0]->{'spec'};

            if( $dscontents->[0]->{'alterrors'} ) {
                # The value of "alterrors" is also copied
                $e->{'alterrors'} = $dscontents->[0]->{'alterrors'};
            }
        }

        if( exists $e->{'alterrors'} && $e->{'alterrors'} ) {
            # Copy alternative error message
            $e->{'diagnosis'} ||= $e->{'alterrors'};

            if( index($e->{'diagnosis'}, '-') == 0 || substr($e->{'diagnosis'}, -2, 2) eq '__' ) {
                # Override the value of diagnostic code message
                $e->{'diagnosis'} = $e->{'alterrors'} if $e->{'alterrors'};

            } else {
                # Check the both value and try to match
                if( length($e->{'diagnosis'}) < length($e->{'alterrors'}) ) {
                    # Check the value of alterrors
                    my $rxdiagnosis = qr/\Q$e->{'diagnosis'}\E/i;
                    if( $e->{'alterrors'} =~ $rxdiagnosis ) {
                        # Override the value of diagnostic code message because
                        # the value of alterrors includes the value of diagnosis.
                        $e->{'diagnosis'} = $e->{'alterrors'};
                    }
                }
            }
            delete $e->{'alterrors'};
        }
        $e->{'diagnosis'} =  Sisimai::String->sweep($e->{'diagnosis'});
        $e->{'diagnosis'} =~ s/\b__.+\z//;

        unless( $e->{'rhost'} ) {
            # Get the remote host name
            # host neko.example.jp [192.0.2.222]: 550 5.1.1 <kijitora@example.jp>... User Unknown
            $e->{'rhost'} = $1 if $e->{'diagnosis'} =~ /host[ \t]+([^ \t]+)[ \t]\[.+\]:[ \t]/;

            if( ! $e->{'rhost'} && scalar @{ $mhead->{'received'} } ) {
                # Get localhost and remote host name from Received header.
                my $r0 = $mhead->{'received'};
                $e->{'rhost'} = pop @{ Sisimai::RFC5322->received($r0->[-1]) };
            }
        }

        unless( $e->{'command'} ) {
            # Get the SMTP command name for the session
            SMTP: for my $r ( @$recommands ) {
                # Verify each regular expression of SMTP commands
                next unless $e->{'diagnosis'} =~ $r;
                $e->{'command'} = uc $1;
                last;
            }

            # Detect the reason of bounce
            if( $e->{'command'} eq 'HELO' || $e->{'command'} eq 'EHLO' ) {
                # HELO | Connected to 192.0.2.135 but my name was rejected.
                $e->{'reason'} = 'blocked';

            } elsif( $e->{'command'} eq 'MAIL' ) {
                # MAIL | Connected to 192.0.2.135 but sender was rejected.
                # $e->{'reason'} = 'rejected';
                $e->{'reason'} = 'onhold';

            } else {
                # Verify each regular expression of session errors
                SESSION: for my $r ( keys %$messagesof ) {
                    # Check each regular expression
                    next unless grep { index($e->{'diagnosis'}, $_) > -1 } @{ $messagesof->{ $r } };
                    $e->{'reason'} = $r;
                    last;
                }

                unless( $e->{'reason'} ) {
                    # The reason "expired"
                    $e->{'reason'} = 'expired' if grep { index($e->{'diagnosis'}, $_) > -1 } @$delayedfor;
                }
            }
        }

        STATUS: {
            # Prefer the value of smtp reply code in Diagnostic-Code:
            # See set-of-emails/maildir/bsd/exim-20.eml
            #   Action: failed
            #   Final-Recipient: rfc822;userx@test.ex
            #   Status: 5.0.0
            #   Remote-MTA: dns; 127.0.0.1
            #   Diagnostic-Code: smtp; 450 TEMPERROR: retry timeout exceeded
            # The value of "Status:" indicates permanent error but the value
            # of SMTP reply code in Diagnostic-Code: field is "TEMPERROR"!!!!
            my $sv = Sisimai::SMTP::Status->find($e->{'diagnosis'}) || '';
            my $rv = Sisimai::SMTP::Reply->find($e->{'diagnosis'})  || '';
            my $s1 = 0; # First character of Status as integer
            my $r1 = 0; # First character of SMTP reply code as integer
            my $v1 = 0;

            FIND_CODE: while(1) {
                # "Status:" field did not exist in the bounce message
                last if $sv;
                last unless $rv;

                # Check SMTP reply code
                # Generate pseudo DSN code from SMTP reply code
                $r1 = substr($rv, 0, 1);
                if( $r1 == 4 ) {
                    # Get the internal DSN(temporary error)
                    $sv = Sisimai::SMTP::Status->code($e->{'reason'}, 1) || '';

                } elsif( $r1 == 5 ) {
                    # Get the internal DSN(permanent error)
                    $sv = Sisimai::SMTP::Status->code($e->{'reason'}, 0) || '';
                }
                last;
            }

            $s1  = substr($sv, 0, 1) if $sv;
            $v1  = $s1 + $r1;
            $v1 += substr($e->{'status'}, 0, 1) if $e->{'status'};

            if( $v1 > 0 ) {
                # Status or SMTP reply code exists
                # Set pseudo DSN into the value of "status" accessor
                $e->{'status'} = $sv if $r1 > 0;

            } else {
                # Neither Status nor SMTP reply code exist
                if( $e->{'reason'} eq 'expired' || $e->{'reason'} eq 'mailboxfull' ) {
                    # Set pseudo DSN (temporary error)
                    $sv = Sisimai::SMTP::Status->code($e->{'reason'}, 1) || '';

                } else {
                    # Set pseudo DSN (permanent error)
                    $sv = Sisimai::SMTP::Status->code($e->{'reason'}, 0) || '';
                }
            }
            $e->{'status'} ||= $sv;
        }
        $e->{'command'} ||= '';
    }
    return { 'ds' => $dscontents, 'rfc822' => $emailsteak->[1] };
}

1;
__END__

=encoding utf-8

=head1 NAME

Sisimai::Lhost::Exim - bounce mail parser class for C<Exim>.

=head1 SYNOPSIS

    use Sisimai::Lhost::Exim;

=head1 DESCRIPTION

Sisimai::Lhost::Exim parses a bounce email which created by C<Exim>.
Methods in the module are called from only Sisimai::Message.

=head1 CLASS METHODS

=head2 C<B<description()>>

C<description()> returns description string of this module.

    print Sisimai::Lhost::Exim->description;

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
