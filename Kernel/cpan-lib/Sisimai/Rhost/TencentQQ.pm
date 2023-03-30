package Sisimai::Rhost::TencentQQ;
use feature ':5.10';
use strict;
use warnings;

sub get {
    # Detect bounce reason from Tencent QQ
    # @param    [Sisimai::Data] argvs   Parsed email object
    # @return   [String]                The bounce reason at Tencent QQ
    # @since v4.25.0
    my $class = shift;
    my $argvs = shift // return undef;

    state $messagesof = {
        # https://service.mail.qq.com/cgi-bin/help?id=20022
        'dmarc check failed'                    => 'blocked',
        'spf check failed'                      => 'blocked',
        'suspected spam ip'                     => 'blocked',
        'mail is rejected by recipients'        => 'filtered',
        'message too large'                     => 'mesgtoobig',
        'mail content denied'                   => 'spamdetected',
        'spam is embedded in the email'         => 'spamdetected',
        'suspected spam'                        => 'spamdetected',
        'bad address syntax'                    => 'syntaxerror',
        'connection denied'                     => 'toomanyconn',
        'connection frequency limited'          => 'toomanyconn',
        'domain frequency limited'              => 'toomanyconn',
        'ip frequency limited'                  => 'toomanyconn',
        'sender frequency limited'              => 'toomanyconn',
        'mailbox unavailable or access denied'  => 'toomanyconn',
        'mailbox not found'                     => 'userunknown',
    };
    my $statusmesg = lc $argvs->diagnosticcode;
    my $reasontext = '';

    for my $e ( keys %$messagesof ) {
        # Try to match the error message with message patterns defined in $MessagesOf
        next unless index($statusmesg, $e) > -1;
        $reasontext = $messagesof->{ $e };
        last;
    }
    return $reasontext;
}

1;
__END__

=encoding utf-8

=head1 NAME

Sisimai::Rhost::TencentQQ - Detect the bounce reason returned from Tencent QQ.

=head1 SYNOPSIS

    use Sisimai::Rhost;

=head1 DESCRIPTION

Sisimai::Rhost detects the bounce reason from the content of Sisimai::Data
object as an argument of get() method when the value of C<rhost> of the object
is "*.qq.com".  This class is called only Sisimai::Data class.

=head1 CLASS METHODS

=head2 C<B<get(I<Sisimai::Data Object>)>>

C<get()> detects the bounce reason.

=head1 AUTHOR

azumakuniyuki

=head1 COPYRIGHT

Copyright (C) 2019,2020 azumakuniyuki, All rights reserved.

=head1 LICENSE

This software is distributed under The BSD 2-Clause License.

=cut


