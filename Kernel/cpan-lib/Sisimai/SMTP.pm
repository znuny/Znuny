package Sisimai::SMTP;
use feature ':5.10';
use strict;
use warnings;
1;
__END__

=encoding utf-8

=head1 NAME

Sisimai::SMTP - SMTP Status Codes related utilities

=head1 SYNOPSIS

    use Sisimai::SMTP;
    print keys %{ Sisimai::SMTP->command }; # helo, mail, rcpt, data

=head1 DESCRIPTION

Sisimai::SMTP is a parent class of Sisimai::SMTP::Status and Sisimai::SMTP::Reply.

=head1 AUTHOR

azumakuniyuki

=head1 COPYRIGHT

Copyright (C) 2015-2016,2020 azumakuniyuki, All rights reserved.

=head1 LICENSE

This software is distributed under The BSD 2-Clause License.

=cut

