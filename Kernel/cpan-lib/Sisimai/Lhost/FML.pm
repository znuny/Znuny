package Sisimai::Lhost::FML;
use parent 'Sisimai::Lhost';
use feature ':5.10';
use strict;
use warnings;

sub description { 'fml mailing list server/manager' };
sub make {
    # Detect an error from fml mailing list server/manager
    # @param    [Hash] mhead    Message headers of a bounce email
    # @param    [String] mbody  Message body of a bounce email
    # @return   [Hash]          Bounce data list and message/rfc822 part
    # @return   [Undef]         failed to parse or the arguments are missing
    # @since v4.22.3
    my $class = shift;
    my $mhead = shift // return undef;
    my $mbody = shift // return undef;

    return undef unless defined $mhead->{'x-mlserver'};
    return undef unless $mhead->{'from'} =~ /.+[-]admin[@].+/;
    return undef unless $mhead->{'message-id'} =~ /\A[<]\d+[.]FML.+[@].+[>]\z/;

    state $rebackbone = qr|^Original[ ]mail[ ]as[ ]follows:|m;
    state $errortitle = {
        'rejected' => qr{(?>
             (?:Ignored[ ])*NOT[ ]MEMBER[ ]article[ ]from[ ]
            |reject[ ]mail[ ](?:.+:|from)[ ],
            |Spam[ ]mail[ ]from[ ]a[ ]spammer[ ]is[ ]rejected
            |You[ ].+[ ]are[ ]not[ ]member
            )
        }x,
        'systemerror' => qr{(?:
             fml[ ]system[ ]error[ ]message
            |Loop[ ]Alert:[ ]
            |Loop[ ]Back[ ]Warning:[ ]
            |WARNING:[ ]UNIX[ ]FROM[ ]Loop
            )
        }x,
        'securityerror' => qr/Security Alert/,
    };
    state $errortable = {
        'rejected' => qr{(?>
            (?:Ignored[ ])*NOT[ ]MEMBER[ ]article[ ]from[ ]
            |reject[ ](?:
                 mail[ ]from[ ].+[@].+
                |since[ ].+[ ]header[ ]may[ ]cause[ ]mail[ ]loop
                |spammers:
                )
            |You[ ]are[ ]not[ ]a[ ]member[ ]of[ ]this[ ]mailing[ ]list
            )
        }x,
        'systemerror' => qr{(?:
             Duplicated[ ]Message-ID
            |fml[ ].+[ ]has[ ]detected[ ]a[ ]loop[ ]condition[ ]so[ ]that
            |Loop[ ]Back[ ]Warning:
            )
        }x,
        'securityerror' => qr/Security alert:/,
    };

    my $dscontents = [__PACKAGE__->DELIVERYSTATUS];
    my $emailsteak = Sisimai::RFC5322->fillet($mbody, $rebackbone);
    my $readcursor = 0;     # (Integer) Points the current cursor position
    my $recipients = 0;     # (Integer) The number of 'Final-Recipient' header
    my $v = undef;

    for my $e ( split("\n", $emailsteak->[0]) ) {
        # Read error messages and delivery status lines from the head of the email
        # to the previous line of the beginning of the original message.
        next unless length $e;

        # Duplicated Message-ID in <2ndml@example.com>.
        # Original mail as follows:
        $v = $dscontents->[-1];

        if( $e =~ /[<]([^ ]+?[@][^ ]+?)[>][.]\z/ ) {
            # Duplicated Message-ID in <2ndml@example.com>.
            if( $v->{'recipient'} ) {
                # There are multiple recipient addresses in the message body.
                push @$dscontents, __PACKAGE__->DELIVERYSTATUS;
                $v = $dscontents->[-1];
            }
            $v->{'recipient'} = $1;
            $v->{'diagnosis'} = $e;
            $recipients++;

        } else {
            # If you know the general guide of this list, please send mail with
            # the mail body
            $v->{'diagnosis'} .= $e;
        }
    }
    return undef unless $recipients;

    for my $e ( @$dscontents ) {
        $e->{'diagnosis'} = Sisimai::String->sweep($e->{'diagnosis'});

        for my $f ( keys %$errortable ) {
            # Try to match with error messages defined in $errortable
            next unless $e->{'diagnosis'} =~ $errortable->{ $f };
            $e->{'reason'} = $f;
            last;
        }
        next if $e->{'reason'};

        # Error messages in the message body did not matched
        for my $f ( keys %$errortitle ) {
            # Try to match with the Subject string
            next unless $mhead->{'subject'} =~ $errortitle->{ $f };
            $e->{'reason'} = $f;
            last;
        }
    }
    return { 'ds' => $dscontents, 'rfc822' => $emailsteak->[1] };
}

1;
__END__

=encoding utf-8

=head1 NAME

Sisimai::Lhost::FML - bounce mail parser class for FML (fml.org).

=head1 SYNOPSIS

    use Sisimai::Lhost::FML;

=head1 DESCRIPTION

Sisimai::Lhost::FML parses a bounce email which created by C<fml mailing
list server/manager>. Methods in the module are called from only Sisimai::Message.

=head1 CLASS METHODS

=head2 C<B<description()>>

C<description()> returns description string of this module.

    print Sisimai::Lhost::FML->description;

=head2 C<B<make(I<header data>, I<reference to body string>)>>

C<make()> method parses a bounced email and return results as a array reference.
See Sisimai::Message for more details.

=head1 AUTHOR

azumakuniyuki

=head1 COPYRIGHT

Copyright (C) 2017-2020 azumakuniyuki, All rights reserved.

=head1 LICENSE

This software is distributed under The BSD 2-Clause License.

=cut

