# $Id: LocationPath.pm,v 1.8 2001/03/16 11:10:08 matt Exp $

package XML::XPathEngine::LocationPath;
use XML::XPathEngine::Root;
use strict;

sub new {
	my $class = shift;
	my $self = [];
	bless $self, $class;
}

sub as_string {
	my $self = shift;
	my $string;
	for (my $i = 0; $i < @$self; $i++) {
		$string .= $self->[$i]->as_string;
		$string .= "/" if $self->[$i+1];
	}
	return $string;
}

sub as_xml {
    my $self = shift;
    my $string = "<LocationPath>\n";
    
    for (my $i = 0; $i < @$self; $i++) {
        $string .= $self->[$i]->as_xml;
    }
    
    $string .= "</LocationPath>\n";
    return $string;
}

sub set_root {
	my $self = shift;
	unshift @$self, XML::XPathEngine::Root->new();
}

sub evaluate {
	my $self = shift;
	# context _MUST_ be a single node
	my $context = shift;
	die "No context" unless $context;
	
	# I _think_ this is how it should work :)
	
	my $nodeset = XML::XPathEngine::NodeSet->new();
	$nodeset->push($context);
	
	foreach my $step (@$self) {
		# For each step
		# evaluate the step with the nodeset
		my $pos = 1;
		$nodeset = $step->evaluate($nodeset);
	}
	
	return $nodeset;
}

1;
