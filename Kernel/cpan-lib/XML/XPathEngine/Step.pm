# $Id: Step.pm,v 1.35 2001/04/01 16:56:40 matt Exp $

package XML::XPathEngine::Step;
use XML::XPathEngine;
use strict;

# the beginnings of using XS for this file...
# require DynaLoader;
# use vars qw/$VERSION @ISA/;
# $VERSION = '1.0';
# @ISA = qw(DynaLoader);
# 
# bootstrap XML::XPathEngine::Step $VERSION;

sub test_qname () { 0; } # Full name
sub test_ncwild () { 1; } # NCName:*
sub test_any () { 2; } # *

sub test_attr_qname () { 3; } # @ns:attrib
sub test_attr_ncwild () { 4; } # @nc:*
sub test_attr_any () { 5; } # @*

sub test_nt_comment () { 6; } # comment()
sub test_nt_text () { 7; } # text()
sub test_nt_pi () { 8; } # processing-instruction()
sub test_nt_node () { 9; } # node()

sub new {
    my $class = shift;
    my ($pp, $axis, $test, $literal) = @_;
    my $axis_method = "axis_$axis";
    $axis_method =~ tr/-/_/;
    my $self = {
        pp => $pp, # the XML::XPathEngine class
        axis => $axis,
        axis_method => $axis_method,
        test => $test,
        literal => $literal,
        predicates => [],
        };
    bless $self, $class;
}

sub as_string {
    my $self = shift;
    my $string = $self->{axis} . "::";

    my $test = $self->{test};
        
    if ($test == test_nt_pi) {
        $string .= 'processing-instruction(';
        if ($self->{literal}->value) {
            $string .= $self->{literal}->as_string;
        }
        $string .= ")";
    }
    elsif ($test == test_nt_comment) {
        $string .= 'comment()';
    }
    elsif ($test == test_nt_text) {
        $string .= 'text()';
    }
    elsif ($test == test_nt_node) {
        $string .= 'node()';
    }
    elsif ($test == test_ncwild || $test == test_attr_ncwild) {
        $string .= $self->{literal} . ':*';
    }
    else {
        $string .= $self->{literal};
    }
    
    foreach (@{$self->{predicates}}) {
        next unless defined $_;
        $string .= "[" . $_->as_string . "]";
    }
    return $string;
}

sub as_xml {
    my $self = shift;
    my $string = "<Step>\n";
    $string .= "<Axis>" . $self->{axis} . "</Axis>\n";
    my $test = $self->{test};
    
    $string .= "<Test>";
    
    if ($test == test_nt_pi) {
        $string .= '<processing-instruction';
        if ($self->{literal}->value) {
            $string .= '>';
            $string .= $self->{literal}->as_string;
            $string .= '</processing-instruction>';
        }
        else {
            $string .= '/>';
        }
    }
    elsif ($test == test_nt_comment) {
        $string .= '<comment/>';
    }
    elsif ($test == test_nt_text) {
        $string .= '<text/>';
    }
    elsif ($test == test_nt_node) {
        $string .= '<node/>';
    }
    elsif ($test == test_ncwild || $test == test_attr_ncwild) {
        $string .= '<namespace-prefix>' . $self->{literal} . '</namespace-prefix>';
    }
    else {
        $string .= '<nametest>' . $self->{literal} . '</nametest>';
    }
    
    $string .= "</Test>\n";
    
    foreach (@{$self->{predicates}}) {
        next unless defined $_;
        $string .= "<Predicate>\n" . $_->as_xml() . "</Predicate>\n";
    }
    
    $string .= "</Step>\n";
    
    return $string;
}

sub evaluate {
    my $self = shift;
    my $from = shift; # context nodeset

    if( $from && !$from->isa( 'XML::XPathEngine::NodeSet'))
      { 
        my $from_nodeset= XML::XPathEngine::NodeSet->new();
        $from_nodeset->push( $from); 
        $from= $from_nodeset;
      }
      #warn "Step::evaluate called with ", $from->size, " length nodeset\n";
    
    my $saved_context = $self->{pp}->_get_context_set;
    my $saved_pos = $self->{pp}->_get_context_pos;
    $self->{pp}->_set_context_set($from);
    
    my $initial_nodeset = XML::XPathEngine::NodeSet->new();
    
    # See spec section 2.1, paragraphs 3,4,5:
    # The node-set selected by the location step is the node-set
    # that results from generating an initial node set from the
    # axis and node-test, and then filtering that node-set by
    # each of the predicates in turn.
    
    # Make each node in the nodeset be the context node, one by one
    for(my $i = 1; $i <= $from->size; $i++) {
        $self->{pp}->_set_context_pos($i);
        $initial_nodeset->append($self->evaluate_node($from->get_node($i)));
    }
    
#    warn "Step::evaluate initial nodeset size: ", $initial_nodeset->size, "\n";
    
    $self->{pp}->_set_context_set($saved_context);
    $self->{pp}->_set_context_pos($saved_pos);

    return $initial_nodeset;
}

# Evaluate the step against a particular node
sub evaluate_node {
    my $self = shift;
    my $context = shift;
    
#    warn "Evaluate node: $self->{axis}\n";
    
#    warn "Node: ", $context->[node_name], "\n";
    
    my $method = $self->{axis_method};
    
    my $results = XML::XPathEngine::NodeSet->new();
    no strict 'refs';
    eval {
        $method->($self, $context, $results);
    };
    if ($@) {
        die "axis $method not implemented [$@]\n";
    }
    
#    warn("results: ", join('><', map {$_->string_value} @$results), "\n");
    # filter initial nodeset by each predicate
    foreach my $predicate (@{$self->{predicates}}) {
        $results = $self->filter_by_predicate($results, $predicate);
    }
    
    return $results;
}

sub axis_ancestor {
    my $self = shift;
    my ($context, $results) = @_;
    
    my $parent = $context->getParentNode;
        
    START:
    return $results unless $parent;
    if (node_test($self, $parent)) {
        $results->push($parent);
    }
    $parent = $parent->getParentNode;
    goto START;
}

sub axis_ancestor_or_self {
    my $self = shift;
    my ($context, $results) = @_;
    
    START:
    return $results unless $context;
    if (node_test($self, $context)) {
        $results->push($context);
    }
    $context = $context->getParentNode;
    goto START;
}

sub axis_attribute {
    my $self = shift;
    my ($context, $results) = @_;
    
    foreach my $attrib (@{$context->getAttributes}) {
        if ($self->test_attribute($attrib)) {
            $results->push($attrib);
        }
    }
}

sub axis_child {
    my $self = shift;
    my ($context, $results) = @_;
    
    foreach my $node (@{$context->getChildNodes}) {
        if (node_test($self, $node)) {
            $results->push($node);
        }
    }
}

sub axis_descendant {
    my $self = shift;
    my ($context, $results) = @_;

    my @stack = $context->getChildNodes;

    while (@stack) {
        my $node = shift @stack;
        if (node_test($self, $node)) {
            $results->push($node);
        }
        unshift @stack, $node->getChildNodes;
    }
}

sub axis_descendant_or_self {
    my $self = shift;
    my ($context, $results) = @_;
    
    my @stack = ($context);

     while (@stack) {
        my $node = shift @stack;
         if (node_test($self, $node)) {
            $results->push($node);
         }
        #warn "node is a ", ref( $node);
        unshift @stack, $node->getChildNodes;
     }
}

sub axis_following 
  { my $self = shift;
    my ($context, $results) = @_;

    my $elt= $context->getNextSibling || _next_sibling_of_an_ancestor_of( $context);
    while( $elt)
      { if (node_test($self, $elt)) { $results->push( $elt); }
        $elt= $elt->getFirstChild || $elt->getNextSibling || _next_sibling_of_an_ancestor_of( $elt);
      }
  }

sub _next_sibling_of_an_ancestor_of
  { my $elt= shift;
    $elt= $elt->getParentNode || return;
    my $next_elt;
    while( !($next_elt= $elt->getNextSibling))
      { $elt= $elt->getParentNode;  
        return unless( $elt && $elt->can( 'getNextSibling')); 
      }
    return $next_elt;
  }


sub axis_following_sibling {
    my $self = shift;
    my ($context, $results) = @_;

    #warn "in axis_following_sibling";
    while ($context = $context->getNextSibling) {
        if (node_test($self, $context)) {
            $results->push($context);
        }
    }
}

sub axis_namespace {
    my $self = shift;
    my ($context, $results) = @_;
    
    return $results unless $context->isElementNode;
    foreach my $ns (@{$context->getNamespaces}) {
        if ($self->test_namespace($ns)) {
            $results->push($ns);
        }
    }
}

sub axis_parent {
    my $self = shift;
    my ($context, $results) = @_;
    
    my $parent = $context->getParentNode;
    return $results unless $parent;
    if (node_test($self, $parent)) {
        $results->push($parent);
    }
}

sub axis_preceding 
  { my $self = shift;
    my ($context, $results) = @_;

    my $elt= $context->getPreviousSibling || _previous_sibling_of_an_ancestor_of( $context);
    while( $elt)
      { if (node_test($self, $elt)) { $results->push( $elt); }
        $elt= $elt->getLastChild || $elt->getPreviousSibling || _previous_sibling_of_an_ancestor_of( $elt);
      }
  }

sub _previous_sibling_of_an_ancestor_of
  { my $elt= shift;
    $elt= $elt->getParentNode || return;
    my $next_elt;
    while( !($next_elt= $elt->getPreviousSibling))
      { $elt= $elt->getParentNode;  
        return unless $elt->getParentNode; # so we don't have to write a getPreviousSibling 
      }
    return $next_elt;
  }


sub axis_preceding_sibling {
    my $self = shift;
    my ($context, $results) = @_;
    
    while ($context = $context->getPreviousSibling) {
        if (node_test($self, $context)) {
            $results->push($context);
        }
    }
}

sub axis_self {
    my $self = shift;
    my ($context, $results) = @_;
    
    if (node_test($self, $context)) {
        $results->push($context);
    }
}
    
sub node_test {
    my $self = shift;
    my $node = shift;
    
    # if node passes test, return true
    
    my $test = $self->{test};

    return 1 if $test == test_nt_node;
        
    if ($test == test_any) {
        return 1 if $node->isElementNode && defined $node->getName;
    }
        
    local $^W;

    if ($test == test_ncwild) {
        return unless $node->isElementNode;
        return _match_ns( $self, $node);
    }
    elsif ($test == test_qname) {
        return unless $node->isElementNode;
        if ($self->{literal} =~ /:/ || $self->{pp}->{strict_namespaces}) {
            my ($prefix, $name) = _name2prefix_and_local_name( $self->{literal});
            return 1 if( ($name eq $node->getLocalName) && _match_ns( $self, $node));
            }
        else {
            return 1 if $node->getName eq $self->{literal};
        }
    }
    elsif ($test == test_nt_text) {
        return 1 if $node->isTextNode;
    }
    elsif ($test == test_nt_comment) {
        return 1 if $node->isCommentNode;
    }
     elsif ($test == test_nt_pi && !$self->{literal}) {
         return 1 if $node->isPINode;
     }
    elsif ($test == test_nt_pi) {
        return unless $node->isPINode;
        if (my $val = $self->{literal}->value) {
            return 1 if $node->getTarget eq $val;
        }
        else {
            return 1;
        }
    }
    
    return; # fallthrough returns false
}

sub _name2prefix_and_local_name
  { my $name= shift; 
    return $name =~ /:/ ? split(':', $name, 2) : ( '', $name);
  }
sub _name2prefix
  { my $name= shift;
    if( $name=~ m{^(.*?):}) { return $1; } else { return ''; } 
  }

sub _match_ns
  { my( $self, $node)= @_;
    my $pp= $self->{pp};
    my $prefix= _name2prefix( $self->{literal});
    my( $match_ns, $node_ns);
    if( $pp->{uses_namespaces} || $pp->{strict_namespaces})
      { $match_ns = $pp->get_namespace($prefix);
        if( $match_ns || $pp->{strict_namespaces})
          { $node_ns= $node->getNamespace->getValue; }
        else
          { # non-standard behaviour: if the query prefix is not declared
            # compare the 2 prefixes
            $match_ns = $prefix;
            $node_ns  = _name2prefix( $node->getName);
          }
      }
    else
      { $match_ns = $prefix;
        $node_ns  = _name2prefix( $node->getName);
      }

    return $match_ns eq $node_ns;
  }


sub test_attribute {
    my $self = shift;
    my $node = shift;
    
    my $test = $self->{test};
    
    return 1 if ($test == test_attr_any) || ($test == test_nt_node);
        
    if ($test == test_attr_ncwild) {
        return 1 if _match_ns( $self, $node);
    }
    elsif ($test == test_attr_qname) {
        if ($self->{literal} =~ /:/) {
            my ($prefix, $name) = _name2prefix_and_local_name( $self->{literal});

            return 1 if ( ($name eq $node->getLocalName) && ( _match_ns( $self, $node)) );
            }
        else {
            return 1 if $node->getName eq $self->{literal};
        }
    }
    
    return; # fallthrough returns false
}

sub test_namespace {
    my $self = shift;
    my $node = shift;
    
    # Not sure if this is correct. The spec seems very unclear on what
    # constitutes a namespace test... bah!
    
    my $test = $self->{test};
    
    return 1 if $test == test_any; # True for all nodes of principal type
    
    if ($test == test_any) {
        return 1;
    }
    elsif ($self->{literal} eq $node->getExpanded) {
        return 1;
    }
    
    return;
}

sub filter_by_predicate {
    my $self = shift;
    my ($nodeset, $predicate) = @_;
    
    # See spec section 2.4, paragraphs 2 & 3:
    # For each node in the node-set to be filtered, the predicate Expr
    # is evaluated with that node as the context node, with the number
    # of nodes in the node set as the context size, and with the
    # proximity position of the node in the node set with respect to
    # the axis as the context position.
    
    if (!ref($nodeset)) { # use ref because nodeset has a bool context
        die "No nodeset!!!";
    }
    
#    warn "Filter by predicate: $predicate\n";
    
    my $newset = XML::XPathEngine::NodeSet->new();

    for(my $i = 1; $i <= $nodeset->size; $i++) {
        # set context set each time 'cos a loc-path in the expr could change it
        $self->{pp}->_set_context_set($nodeset);
        $self->{pp}->_set_context_pos($i);
        my $result = $predicate->evaluate($nodeset->get_node($i));
        if ($result->isa('XML::XPathEngine::Boolean')) {
            if ($result->value) {
                $newset->push($nodeset->get_node($i));
            }
        }
        elsif ($result->isa('XML::XPathEngine::Number')) {
            if ($result->value == $i) {
                $newset->push($nodeset->get_node($i)); last;
            }
        }
        else {
            if ($result->to_boolean->value) {
                $newset->push($nodeset->get_node($i));
            }
        }
    }
    
    return $newset;
}

1;
