package Sisimai::Lhost::GoogleGroups;
use parent 'Sisimai::Lhost';
use feature ':5.10';
use strict;
use warnings;

sub description { 'Google Groups: https://groups.google.com' }
sub make {
    # Detect an error from Google Groups
    # @param    [Hash] mhead    Message headers of a bounce email
    # @param    [String] mbody  Message body of a bounce email
    # @return   [Hash]          Bounce data list and message/rfc822 part
    # @return   [Undef]         failed to parse or the arguments are missing
    # @since v4.25.6
    my $class = shift;
    my $mhead = shift // return undef;
    my $mbody = shift // return undef;

    return undef unless rindex($mhead->{'from'}, '<mailer-daemon@googlemail.com>') > -1;
    return undef unless index($mhead->{'subject'}, 'Delivery Status Notification') > -1;
    return undef unless exists $mhead->{'x-failed-recipients'};
    return undef unless exists $mhead->{'x-google-smtp-source'};

    # Hello kijitora@libsisimai.org,
    #
    # We're writing to let you know that the group you tried to contact (group-name)
    # may not exist, or you may not have permission to post messages to the group.
    # A few more details on why you weren't able to post:
    #
    #  * You might have spelled or formatted the group name incorrectly.
    #  * The owner of the group may have removed this group.
    #  * You may need to join the group before receiving permission to post.
    #  * This group may not be open to posting.
    #
    # If you have questions related to this or any other Google Group,
    # visit the Help Center at https://groups.google.com/support/.
    #
    # Thanks,
    #
    # Google Groups
    state $indicators = __PACKAGE__->INDICATORS;
    state $rebackbone = qr/^-----[ ]Original[ ]message[ ]-----$/m;

    my $dscontents = [__PACKAGE__->DELIVERYSTATUS];
    my $emailsteak = Sisimai::RFC5322->fillet($mbody, $rebackbone);
    my $recordwide = { 'rhost' => '', 'reason' => '', 'diagnosis' => '' };
    my $recipients = 0;
    my $v = $dscontents->[-1];

    # * You might have spelled or formatted the group name incorrectly.
    # * The owner of the group may have removed this group.
    # * You may need to join the group before receiving permission to post.
    # * This group may not be open to posting.
    my $fewdetails = [$emailsteak->[0] =~ /^[ ]?[*][ ]?/gm] || [];
    $recordwide->{'reason'} = scalar @$fewdetails == 4 ? 'rejected' : 'onhold';

    my @entiremesg = split(/\n\n/, $emailsteak->[0], 5); pop @entiremesg;
    my $diagnostic = join(' ', @entiremesg); $diagnostic =~ y/\n/ /;
    $recordwide->{'diagnosis'} = Sisimai::String->sweep($diagnostic);

    my $serverlist = Sisimai::RFC5322->received($mhead->{'received'}->[0]);
    $recordwide->{'rhost'} = shift @$serverlist;

    for my $e ( split(',', $mhead->{'x-failed-recipients'}) ) {
        # X-Failed-Recipients: neko@example.jp, nyaan@example.org, ...
        next unless Sisimai::RFC5322->is_emailaddress($e);

        if( $v->{'recipient'} ) {
            # There are multiple recipient addresses in the message body.
            push @$dscontents, __PACKAGE__->DELIVERYSTATUS;
            $v = $dscontents->[-1];
        }
        $v->{'recipient'} = Sisimai::Address->s3s4($e);
        $recipients++;
        $v->{ $_ } = $recordwide->{ $_ } for keys %$recordwide;
    }
    return undef unless $recipients;
    return { 'ds' => $dscontents, 'rfc822' => $emailsteak->[1] };
}

1;
__END__

=encoding utf-8

=head1 NAME

Sisimai::Lhost::GoogleGroups - bounce mail parser class for C<Google Groups>.

=head1 SYNOPSIS

    use Sisimai::Lhost::GoogleGroups;

=head1 DESCRIPTION

Sisimai::Lhost::GoogleGroups parses a bounce email which created by C<Gmail>.
Methods in the module are called from only Sisimai::Message.

=head1 CLASS METHODS

=head2 C<B<description()>>

C<description()> returns description string of this module.

    print Sisimai::Lhost::GoogleGroups->description;

=head2 C<B<make(I<header data>, I<reference to body string>)>>

C<make()> method parses a bounced email and return results as a array reference.
See Sisimai::Message for more details.

=head1 AUTHOR

azumakuniyuki

=head1 COPYRIGHT

Copyright (C) 2020,2022 azumakuniyuki, All rights reserved.

=head1 LICENSE

This software is distributed under The BSD 2-Clause License.

=cut

