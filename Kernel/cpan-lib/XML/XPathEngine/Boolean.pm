# $Id: Boolean.pm,v 1.7 2000/07/03 08:54:47 matt Exp $

package XML::XPathEngine::Boolean;
use XML::XPathEngine::Number;
use XML::XPathEngine::Literal;
use strict;

use overload
		'""' => \&value,
		'<=>' => \&cmp;

sub True {
	my $class = shift;
	my $val = 1;
	bless \$val, $class;
}

sub False {
	my $class = shift;
	my $val = 0;
	bless \$val, $class;
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

sub to_number { XML::XPathEngine::Number->new($_[0]->value); }
sub to_boolean { $_[0]; }
sub to_literal { XML::XPathEngine::Literal->new($_[0]->value ? "true" : "false"); }

sub string_value { return $_[0]->to_literal->value; }

sub getChildNodes { return wantarray ? () : []; }
sub getAttributes { return wantarray ? () : []; }

1;
__END__

=head1 NAME

XML::XPathEngine::Boolean - Boolean true/false values

=head1 DESCRIPTION

XML::XPathEngine::Boolean objects implement simple boolean true/false objects.

=head1 API

=head2 XML::XPathEngine::Boolean->True

Creates a new Boolean object with a true value.

=head2 XML::XPathEngine::Boolean->False

Creates a new Boolean object with a false value.

=head2 value()

Returns true or false.

=head2 to_literal()

Returns the string "true" or "false".

=cut
