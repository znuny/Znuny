# $Id: Literal.pm,v 1.11 2001/03/16 11:10:08 matt Exp $

package XML::XPathEngine::Literal;
use XML::XPathEngine::Boolean;
use XML::XPathEngine::Number;
use strict;
use Carp;

use overload 
		'""'  => \&value,
		'cmp' => \&cmp;

sub new {
	my $class = shift;
	my ($string) = @_;
	
#	$string =~ s/&quot;/"/g;
#	$string =~ s/&apos;/'/g;
	
	bless \$string, $class;
}

sub as_string {
	my $self = shift;
	my $string = $$self;
	$string =~ s/'/&apos;/g;
	return "'$string'";
}

sub as_xml {
    my $self = shift;
    my $string = $$self;
    return "<Literal>$string</Literal>\n";
}

sub value {
	my $self = shift; 
	$$self;
}

sub value_as_number {
	my $self = shift; 
 warn "numifying '", $$self, "' to '", +$$self, "'\n";       
	+$$self;
}

sub cmp {
	my $self = shift;
	my ($cmp, $swap) = @_;
	if ($swap) {
		return $cmp cmp $$self;
	}
	return $$self cmp $cmp;
}

sub evaluate {
	my $self = shift;
	$self;
}

sub to_boolean {
	my $self = shift;
	return (length($$self) > 0) ? XML::XPathEngine::Boolean->True : XML::XPathEngine::Boolean->False;
}

sub to_number { return XML::XPathEngine::Number->new($_[0]->value); }
sub to_literal { return $_[0]; }

sub string_value { return $_[0]->value; }

sub getChildNodes { croak "cannot get child nodes of a literal"; }
sub getAttributes { croak "cannot get attributes of a literal";  }
sub getParentNode { croak "cannot get parent node of a literal"; }

1;
__END__

=head1 NAME

XML::XPathEngine::Literal - Simple string values.

=head1 DESCRIPTION

In XPath terms a Literal is what we know as a string.

=head1 API

=head2 new($string)

Create a new Literal object with the value in $string. Note that &quot; and
&apos; will be converted to " and ' respectively. That is not part of the XPath
specification, but I consider it useful. Note though that you have to go
to extraordinary lengths in an XML template file (be it XSLT or whatever) to
make use of this:

	<xsl:value-of select="&quot;I'm feeling &amp;quot;sad&amp;quot;&quot;"/>

Which produces a Literal of:

	I'm feeling "sad"

=head2 value()

Also overloaded as stringification, simply returns the literal string value.

=head2 cmp($literal)

Returns the equivalent of perl's cmp operator against the given $literal.

=cut
