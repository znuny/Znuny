package Net::POP3::XOAuth2;

use 5.008001;
use strict;
use warnings;

use Carp;
use Net::POP3;
use MIME::Base64;

our $VERSION = '0.0.2';

*Net::POP3::_AUTH = sub { shift->command('AUTH', $_[0])->response() == Net::POP3::CMD_OK };
# Send a token directly
*Net::POP3::_XOAUTH2_TOKEN = sub { shift->command($_[0])->response() == Net::POP3::CMD_OK };
*Net::POP3::xoauth2 = sub {
    @_ >= 1 && @_ <= 4 or croak 'usage: $pop3->xoauth2( USER, TOKEN, separate_flag )';
    my ($me, $user, $token, $separate_flag) = @_;
    my $xoauth2_token = encode_base64("user=$user\001auth=Bearer $token\001\001");
    $xoauth2_token =~ s/[\r\n]//g;

    # If you use office365, need to call 'XOAUTH2' and token separately
    # https://docs.microsoft.com/ja-jp/Exchange/client-developer/legacy-protocols/how-to-authenticate-an-imap-pop-smtp-application-by-using-oauth
    if ($separate_flag) {
        $me->_AUTH("XOAUTH2");
        my $r = $me->_XOAUTH2_TOKEN($xoauth2_token);
        return unless $r;
    } else {
        return unless ($me->_AUTH("XOAUTH2 $xoauth2_token"));
    }
    $me->_get_mailbox_count();
};

1;
__END__

=encoding utf-8

=head1 NAME

Net::POP3::XOAuth2 - It enables to use XOAUTH2 authentication with L<Net::POP3>

=head1 SYNOPSIS

  use Net::POP3;
  use Net::POP3::XOAuth2;

  my $user = '<user_id>';
  my $token = '<token from xoauth2>';

  my $pop = Net::POP3->new('pop.gmail.com', Port => 995, Timeout => 30, SSL => 1, Debug => 1);
  $pop->xoauth2($user, $token);

  # or if you use office365
  $pop->xoauth2($user, $token, 1);

=head1 DESCRIPTION

Net::POP3::XOAuth2 is an extension for L<Net::POP3>. This allows you to use SASL XOAUTH2.

=head1 METHODS

=over 4

=item xauth2 ( USER, TOKEN )

Authenticate with the server identifying as C<USER> with OAuth2 access token C<TOKEN>.

=back

=head1 LICENSE

Copyright (C) Kizashi Nagata.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Kizashi Nagata E<lt>kizashi1122@gmail.comE<gt>

=cut
