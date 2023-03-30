package Sisimai::Rhost::IUA;
use feature ':5.10';
use strict;
use warnings;

sub get {
    # Detect bounce reason from https://www.i.ua/
    # @param    [Sisimai::Data] argvs   Parsed email object
    # @return   [String]                The bounce reason at https://www.i.ua/
    # @since v4.25.0
    my $class = shift;
    my $argvs = shift // return undef;

    state $errorcodes = {
        # http://mail.i.ua/err/$(CODE)
        '1'  => 'norelaying',  # The use of SMTP as mail gate is forbidden.
        '2'  => 'userunknown', # User is not found.
        '3'  => 'suspend',     # Mailbox was not used for more than 3 months
        '4'  => 'mailboxfull', # Mailbox is full.
        '5'  => 'toomanyconn', # Letter sending limit is exceeded.
        '6'  => 'norelaying',  # Use SMTP of your provider to send mail.
        '7'  => 'blocked',     # Wrong value if command HELO/EHLO parameter.
        '8'  => 'rejected',    # Couldn't check sender address.
        '9'  => 'blocked',     # IP-address of the sender is blacklisted.
        '10' => 'filtered',    # Not in the list Mail address management.
    };
    my $statusmesg = lc $argvs->diagnosticcode;
    my $codenumber = $statusmesg =~ m|[.]i[.]ua/err/(\d+)| ? $1 : 0;
    return $errorcodes->{ $codenumber } || '';
}

1;
__END__

=encoding utf-8

=head1 NAME

Sisimai::Rhost::IUA - Detect the bounce reason returned from https://www.i.ua/.

=head1 SYNOPSIS

    use Sisimai::Rhost;

=head1 DESCRIPTION

Sisimai::Rhost detects the bounce reason from the content of Sisimai::Data
object as an argument of get() method when the value of C<rhost> of the object
is "*.email.ua".  This class is called only Sisimai::Data class.

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

