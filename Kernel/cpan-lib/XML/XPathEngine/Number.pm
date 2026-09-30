# $Id: Number.pm,v 1.14 2002/12/26 17:57:09 matt Exp $

package XML::XPathEngine::Number;
use XML::XPathEngine::Boolean;
use XML::XPathEngine::Literal;
use strict;

use overload
        '""' => \&value,
        '<=>' => \&cmp;

sub new {
    my $class = shift;
    my $number = shift;
    if ($number !~ /^\s*[+-]?(\d+(\.\d*)?|\.\d+)\s*$/) {
        $number = undef;
    }
    else {
        $number =~ s/^\s*(.*)\s*$/$1/;
    }
    bless \$number, $class;
}

sub as_string {
    my $self = shift;
    defined $$self ? $$self : 'NaN';
}

sub as_xml {
    my $self = shift;
    return "<Number>" . (defined($$self) ? $$self : 'NaN') . "</Number>\n";
}

sub value {
    my $self = shift;
    $$self;
}

sub cmp {
    my $self = shift;
    my ($other, $swap) = @_;
    if ($swap) {
        return $other <=> $$self;
    }
    return $$self <=> $other;
}

sub evaluate {
    my $self = shift;
    $self;
}

sub to_boolean {
    my $self = shift;
    return $$self ? XML::XPathEngine::Boolean->True : XML::XPathEngine::Boolean->False;
}

sub to_literal { XML::XPathEngine::Literal->new($_[0]->as_string); }
sub to_number { $_[0]; }

sub string_value { return $_[0]->value }

sub getChildNodes { return wantarray ? () : []; }
sub getAttributes { return wantarray ? () : []; }

1;
__END__

=head1 NAME

XML::XPathEngine::Number - Simple numeric values.

=head1 DESCRIPTION

This class holds simple numeric values. It doesn't support -0, +/- Infinity,
or NaN, as the XPath spec says it should, but I'm not hurting anyone I don't think.

=head1 API

=head2 new($num)

Creates a new XML::XPathEngine::Number object, with the value in $num. Does some
rudimentary numeric checking on $num to ensure it actually is a number.

=head2 value()

Also as overloaded stringification. Returns the numeric value held.

=cut
