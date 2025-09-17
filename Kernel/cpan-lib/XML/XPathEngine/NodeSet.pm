# $Id: NodeSet.pm,v 1.17 2002/04/24 13:06:08 matt Exp $

package XML::XPathEngine::NodeSet;
use strict;

use XML::XPathEngine::Boolean;

use overload 
		'""' => \&to_literal,
                'bool' => \&to_boolean,
        ;

sub new {
	my $class = shift;
	bless [], $class;
}

sub sort {
    my $self = CORE::shift;
    @$self = CORE::sort { $a->cmp( $b) } @$self;
    return $self;
}

sub reverse {
    my $self = CORE::shift;
    @$self = reverse @$self;
    return $self;
}

sub remove_duplicates {
    my $self = CORE::shift;
    my @unique;
    my $last_node=0;
    foreach my $node (@$self) { 
        push @unique, $node unless( $node == $last_node);
        $last_node= $node;
    }
    @$self= @unique; 
    return $self;
}


sub pop {
	my $self = CORE::shift;
	CORE::pop @$self;
}

sub push {
	my $self = CORE::shift;
	my (@nodes) = @_;
	CORE::push @$self, @nodes;
}

sub append {
	my $self = CORE::shift;
	my ($nodeset) = @_;
	CORE::push @$self, $nodeset->get_nodelist;
}

sub shift {
	my $self = CORE::shift;
	CORE::shift @$self;
}

sub unshift {
	my $self = CORE::shift;
	my (@nodes) = @_;
	CORE::unshift @$self, @nodes;
}

sub prepend {
	my $self = CORE::shift;
	my ($nodeset) = @_;
	CORE::unshift @$self, $nodeset->get_nodelist;
}

sub size {
	my $self = CORE::shift;
	scalar @$self;
}

sub get_node { # uses array index starting at 1, not 0
	my $self = CORE::shift;
	my ($pos) = @_;
	$self->[$pos - 1];
}

sub getRootNode {
    my $self = CORE::shift;
    return $self->[0]->getRootNode;
}

sub get_nodelist {
	my $self = CORE::shift;
	@$self;
}

sub getChildNodes {
    my $self = CORE::shift;
    return map { $_->getChildNodes } @$self;
}

sub getElementById {
    my $self = CORE::shift;
    return map { $_->getElementById } @$self;
}

       
sub to_boolean {
	my $self = CORE::shift;
	return (@$self > 0) ? XML::XPathEngine::Boolean->True : XML::XPathEngine::Boolean->False;
}

sub string_value {
	my $self = CORE::shift;
	return '' unless @$self;
	return $self->[0]->string_value;
}

sub to_literal {
	my $self = CORE::shift;
	return XML::XPathEngine::Literal->new(
			join('', map { $_->string_value } @$self)
			);
}

sub to_number {
	my $self = CORE::shift;
	return XML::XPathEngine::Number->new(
			$self->to_literal
			);
}

sub to_final_value {
	my $self = CORE::shift;
	return join('', map { $_->string_value } @$self);
}

sub string_values {
	my $self = CORE::shift;
	return map { $_->string_value } @$self;
}
1;
__END__

=head1 NAME

XML::XPathEngine::NodeSet - a list of XML document nodes

=head1 DESCRIPTION

An XML::XPathEngine::NodeSet object contains an ordered list of nodes. The nodes
each take the same format as described in L<XML::XPathEngine::XMLParser>.

=head1 SYNOPSIS

	my $results = $xp->find('//someelement');
	if (!$results->isa('XML::XPathEngine::NodeSet')) {
		print "Found $results\n";
		exit;
	}
	foreach my $context ($results->get_nodelist) {
		my $newresults = $xp->find('./other/element', $context);
		...
	}

=head1 API

=head2 new()

You will almost never have to create a new NodeSet object, as it is all
done for you by XPath.

=head2 get_nodelist()

Returns a list of nodes. See L<XML::XPathEngine::XMLParser> for the format of
the nodes.

=head2 string_value()

Returns the string-value of the first node in the list.
See the XPath specification for what "string-value" means.

=head2 string_values()

Returns a list of the string-values of all the nodes in the list.


=head2 to_literal()

Returns the concatenation of all the string-values of all
the nodes in the list.

=head2 get_node($pos)

Returns the node at $pos. The node position in XPath is based at 1, not 0.

=head2 size()

Returns the number of nodes in the NodeSet.

=head2 pop()

Equivalent to perl's pop function.

=head2 push(@nodes)

Equivalent to perl's push function.

=head2 append($nodeset)

Given a nodeset, appends the list of nodes in $nodeset to the end of the
current list.

=head2 shift()

Equivalent to perl's shift function.

=head2 unshift(@nodes)

Equivalent to perl's unshift function.

=head2 prepend($nodeset)

Given a nodeset, prepends the list of nodes in $nodeset to the front of
the current list.

=cut
