# $Id: Root.pm,v 1.6 2001/03/16 11:10:08 matt Exp $

package XML::XPathEngine::Root;
use strict;
use XML::XPathEngine::NodeSet;

sub new {
	my $class = shift;
	my $self; # actually don't need anything here - just a placeholder
	bless \$self, $class;
}

sub as_string {
	# do nothing
}

sub as_xml {
    return "<Root/>\n";
}

sub evaluate {
	my $self = shift;
	my $nodeset = shift;
	
#	warn "Eval ROOT\n";
	
	# must only ever occur on 1 node
	die "Can't go to root on > 1 node!" unless $nodeset->size == 1;
	
	my $newset = XML::XPathEngine::NodeSet->new();
	$newset->push($nodeset->get_node(1)->getRootNode());
	return $newset;
}

1;
