package Sisimai::Rhost;
use feature ':5.10';
use strict;
use warnings;

use constant RhostClass => {
    qr/cox[.]net/                                     => 'Cox',
    qr/[.](?:prod|protection)[.]outlook[.]com\z/      => 'ExchangeOnline',
    qr/\b(?>laposte[.]net|(?:orange|wanadoo)[.]fr)\z/ => 'FrancePTT',
    qr/\A(?:smtp|mailstore1)[.]secureserver[.]net\z/  => 'GoDaddy',
    qr/(?:aspmx|gmail-smtp-in)[.]l[.]google[.]com\z/  => 'GoogleApps',
    qr/[.]email[.]ua\z/                               => 'IUA',
    qr/[.](?:ezweb[.]ne[.]jp|au[.]com)\z/             => 'KDDI',
    qr/[.]mimecast[.]com\z/                           => 'Mimecast',
    qr/mfsmax[.]docomo[.]ne[.]jp\z/                   => 'NTTDOCOMO',
    qr/charter[.]net/                                 => 'Spectrum',
    qr/mx[0-9]+[.]qq[.]com\z/                         => 'TencentQQ',
};

sub match {
    # The value of "rhost" is listed in RhostClass or not
    # @param    [String] argv1  Remote host name
    # @return   [Integer]       0: did not match
    #                           1: match
    my $class = shift;
    my $rhost = shift // return undef;
    my $host0 = lc($rhost) || return 0;
    my $match = 0;

    for my $e ( keys %{ RhostClass() } ) {
        # Try to match with each key of RhostClass
        next unless $host0 =~ $e;
        $match = 1;
        last;
    }
    return $match;
}

sub get {
    # Detect the bounce reason from certain remote hosts
    # @param    [Sisimai::Data] argvs   Parsed email object
    # @param    [String]        proxy   The alternative of the "rhost"
    # @return   [String]                The value of bounce reason
    my $class = shift;
    my $argvs = shift || return undef;
    my $proxy = shift || undef;

    my $remotehost = $proxy || lc $argvs->rhost;
    my $rhostclass = '';

    for my $e ( keys %{ RhostClass() } ) {
        # Try to match with each key of RhostClass
        next unless $remotehost =~ $e;
        $rhostclass = __PACKAGE__.'::'.RhostClass->{ $e };
        last;
    }
    return undef unless $rhostclass;

    (my $modulepath = $rhostclass) =~ s|::|/|g;
    require $modulepath.'.pm';
    return $rhostclass->get($argvs);
}

1;
__END__

=encoding utf-8

=head1 NAME

Sisimai::Rhost - Detect the bounce reason returned from certain remote hosts.

=head1 SYNOPSIS

    use Sisimai::Rhost;

=head1 DESCRIPTION

Sisimai::Rhost detects the bounce reason from the content of Sisimai::Data
object as an argument of get() method when the value of C<rhost> of the object
is listed in the results of Sisimai::Rhost->list() method.
This class is called only Sisimai::Data class.

=head1 CLASS METHODS

=head2 C<B<match(I<remote host>)>>

Returns 1 if the remote host is listed in the results of Sisimai::Rhost->list()
method.

=head2 C<B<get(I<Sisimai::Data Object>)>>

C<get()> detects the bounce reason.

=head1 AUTHOR

azumakuniyuki

=head1 COPYRIGHT

Copyright (C) 2014-2020,2022 azumakuniyuki, All rights reserved.

=head1 LICENSE

This software is distributed under The BSD 2-Clause License.

=cut
