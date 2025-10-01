# $Id: Expr.pm,v 1.20 2003/01/26 19:33:24 matt Exp $

package XML::XPathEngine::Expr;
use strict;

sub new {
    my $class = shift;
    my ($pp) = @_;
    bless { predicates => [], pp => $pp }, $class;
}

sub as_string {
    my $self = shift;
    local $^W; # Use of uninitialized value! grrr
    my $string = "(" . $self->{lhs}->as_string;
    $string .= " " . $self->{op} . " " if defined $self->{op};
    $string .= $self->{rhs}->as_string if defined $self->{rhs};
    $string .= ")";
    foreach my $predicate (@{$self->{predicates}}) {
        $string .= "[" . $predicate->as_string . "]";
    }
    return $string;
}

sub as_xml {
    my $self = shift;
    local $^W; # Use of uninitialized value! grrr
    my $string;
    if (defined $self->{op}) {
        $string .= $self->op_xml();
    }
    else {
        $string .= $self->{lhs}->as_xml();
    }
    foreach my $predicate (@{$self->{predicates}}) {
        $string .= "<Predicate>\n" . $predicate->as_xml() . "</Predicate>\n";
    }
    return $string;
}

sub op_xml {
    my $self = shift;
    my $op = $self->{op};

    my $tag;    
    for ($op) {
        /^or$/    && do {
                    $tag = "Or";
                };
        /^and$/    && do {
                    $tag = "And";
                };
        /^=$/    && do {
                    $tag = "Equals";
                };
        /^!=$/    && do {
                    $tag = "NotEquals";
                };
        /^<=$/    && do {
                    $tag = "LessThanOrEquals";
                };
        /^>=$/    && do {
                    $tag = "GreaterThanOrEquals";
                };
        /^>$/    && do {
                    $tag = "GreaterThan";
                };
        /^<$/    && do {
                    $tag = "LessThan";
                };
        /^\+$/    && do {
                    $tag = "Plus";
                };
        /^-$/    && do {
                    $tag = "Minus";
                };
        /^div$/    && do {
                    $tag = "Div";
                };
        /^mod$/    && do {
                    $tag = "Mod";
                };
        /^\*$/    && do {
                    $tag = "Multiply";
                };
        /^\|$/    && do {
                    $tag = "Union";
                };
    }
    
    return "<$tag>\n" . $self->{lhs}->as_xml() . $self->{rhs}->as_xml() . "</$tag>\n";
}

sub set_lhs {
    my $self = shift;
    $self->{lhs} = $_[0];
}

sub set_op {
    my $self = shift;
    $self->{op} = $_[0];
}

sub set_rhs {
    my $self = shift;
    $self->{rhs} = $_[0];
}

sub push_predicate {
    my $self = shift;
    
    die "Only 1 predicate allowed on FilterExpr in W3C XPath 1.0"
            if @{$self->{predicates}};
    
    push @{$self->{predicates}}, $_[0];
}

sub get_lhs { $_[0]->{lhs}; }
sub get_rhs { $_[0]->{rhs}; }
sub get_op { $_[0]->{op}; }

sub evaluate {
    my $self = shift;
    my $node = shift;
    
    # If there's an op, result is result of that op.
    # If no op, just resolve Expr
    
#    warn "Evaluate Expr: ", $self->as_string, "\n";
    
    my $results;
    
    if ($self->{op}) {
        die ("No RHS of ", $self->as_string) unless $self->{rhs};
        $results = $self->op_eval($node);
    }
    else {
        $results = $self->{lhs}->evaluate($node);
    }
    
    if (my @predicates = @{$self->{predicates}}) {
        if (!$results->isa('XML::XPathEngine::NodeSet')) {
            die "Can't have predicates execute on object type: " . ref($results);
        }
        
        # filter initial nodeset by each predicate
        foreach my $predicate (@{$self->{predicates}}) {
            $results = $self->filter_by_predicate($results, $predicate);
        }
    }
    
    return $results;
}

sub op_eval {
    my $self = shift;
    my $node = shift;
    
    my $op = $self->{op};
    
    for ($op) {
        /^or$/    && do {
                    return op_or($node, $self->{lhs}, $self->{rhs});
                };
        /^and$/    && do {
                    return op_and($node, $self->{lhs}, $self->{rhs});
                };
        /^=~$/   && do {
                    return op_match($node, $self->{lhs}, $self->{rhs});
                };
        /^!~$/   && do {
                    return op_not_match($node, $self->{lhs}, $self->{rhs});
                };
        /^=$/    && do {
                    return op_equals($node, $self->{lhs}, $self->{rhs});
                };
        /^!=$/    && do {
                    return op_nequals($node, $self->{lhs}, $self->{rhs});
                };
        /^<=$/    && do {
                    return op_le($node, $self->{lhs}, $self->{rhs});
                };
        /^>=$/    && do {
                    return op_ge($node, $self->{lhs}, $self->{rhs});
                };
        /^>$/    && do {
                    return op_gt($node, $self->{lhs}, $self->{rhs});
                };
        /^<$/    && do {
                    return op_lt($node, $self->{lhs}, $self->{rhs});
                };
        /^\+$/    && do {
                    return op_plus($node, $self->{lhs}, $self->{rhs});
                };
        /^-$/    && do {
                    return op_minus($node, $self->{lhs}, $self->{rhs});
                };
        /^div$/    && do {
                    return op_div($node, $self->{lhs}, $self->{rhs});
                };
        /^mod$/    && do {
                    return op_mod($node, $self->{lhs}, $self->{rhs});
                };
        /^\*$/    && do {
                    return op_mult($node, $self->{lhs}, $self->{rhs});
                };
        /^\|$/    && do {
                    return op_union($node, $self->{lhs}, $self->{rhs});
                };
        
        die "No such operator, or operator unimplemented in ", $self->as_string, "\n";
    }
}

# Operators

use XML::XPathEngine::Boolean;

sub op_or {
    my ($node, $lhs, $rhs) = @_;
    if($lhs->evaluate($node)->to_boolean->value) {
        return XML::XPathEngine::Boolean->True;
    }
    else {
        return $rhs->evaluate($node)->to_boolean;
    }
}

sub op_and {
    my ($node, $lhs, $rhs) = @_;
    if( ! $lhs->evaluate($node)->to_boolean->value ) {
        return XML::XPathEngine::Boolean->False;
    }
    else {
        return $rhs->evaluate($node)->to_boolean;
    }
}

sub op_match 
  { my ($node, $lhs, $rhs) = @_;

    my $lh_results = $lhs->evaluate($node);
    my $rh_results = $rhs->evaluate($node);
    my $rh_value   = $rh_results->string_value;

    if ($lh_results->isa('XML::XPathEngine::NodeSet') ) 
      { foreach my $lhnode ($lh_results->get_nodelist) 
          { if ($lhnode->string_value=~ m/$rh_value/) # / is important here, regexp is / delimited
              { return XML::XPathEngine::Boolean->True; }
          }
        return XML::XPathEngine::Boolean->False;
      }
    else
      { return $lh_results->string_value =~  m/$rh_value/ ?
               XML::XPathEngine::Boolean->True : XML::XPathEngine::Boolean->False;
      }
  }
  
sub op_not_match 
  { my ($node, $lhs, $rhs) = @_;

    my $lh_results = $lhs->evaluate($node);
    my $rh_results = $rhs->evaluate($node);
    my $rh_value   = $rh_results->string_value;
    
    if ($lh_results->isa('XML::XPathEngine::NodeSet') ) 
      { foreach my $lhnode ($lh_results->get_nodelist) 
          { if ($lhnode->string_value!~ m/$rh_value/) 
              { return XML::XPathEngine::Boolean->True; }
          }
        return XML::XPathEngine::Boolean->False;
      }
    else
      { return $lh_results->string_value !~  m/$rh_value/ ?
               XML::XPathEngine::Boolean->True : XML::XPathEngine::Boolean->False;
      }
  }


sub op_equals {
    my ($node, $lhs, $rhs) = @_;

    my $lh_results = $lhs->evaluate($node);
    my $rh_results = $rhs->evaluate($node);
    
    if ($lh_results->isa('XML::XPathEngine::NodeSet') &&
            $rh_results->isa('XML::XPathEngine::NodeSet')) {
        # True if and only if there is a node in the
        # first set and a node in the second set such
        # that the result of performing the comparison
        # on the string-values of the two nodes is true.
        foreach my $lhnode ($lh_results->get_nodelist) {
            foreach my $rhnode ($rh_results->get_nodelist) {
                if ($lhnode->string_value eq $rhnode->string_value) {
                    return XML::XPathEngine::Boolean->True;
                }
            }
        }
        return XML::XPathEngine::Boolean->False;
    }
    elsif (($lh_results->isa('XML::XPathEngine::NodeSet') ||
            $rh_results->isa('XML::XPathEngine::NodeSet')) &&
            (!$lh_results->isa('XML::XPathEngine::NodeSet') ||
             !$rh_results->isa('XML::XPathEngine::NodeSet'))) {
        # (that says: one is a nodeset, and one is not a nodeset)
        
        my ($nodeset, $other);
        if ($lh_results->isa('XML::XPathEngine::NodeSet')) {
            $nodeset = $lh_results;
            $other = $rh_results;
        }
        else {
            $nodeset = $rh_results;
            $other = $lh_results;
        }
        
        # True if and only if there is a node in the
        # nodeset such that the result of performing
        # the comparison on <type>(string_value($node))
        # is true.
        if ($other->isa('XML::XPathEngine::Number')) {
            foreach my $node ($nodeset->get_nodelist) {
                if ($node->string_value == $other->value) {
                    return XML::XPathEngine::Boolean->True;
                }
            }
        }
        elsif ($other->isa('XML::XPathEngine::Literal')) {
            foreach my $node ($nodeset->get_nodelist) {
                if ($node->string_value eq $other->value) {
                    return XML::XPathEngine::Boolean->True;
                }
            }
        }
        elsif ($other->isa('XML::XPathEngine::Boolean')) {
            if ($nodeset->to_boolean->value == $other->value) {
                return XML::XPathEngine::Boolean->True;
            }
        }

        return XML::XPathEngine::Boolean->False;
    }
    else { # Neither is a nodeset
        if ($lh_results->isa('XML::XPathEngine::Boolean') ||
            $rh_results->isa('XML::XPathEngine::Boolean')) {
            # if either is a boolean
            if ($lh_results->to_boolean->value == $rh_results->to_boolean->value) {
                return XML::XPathEngine::Boolean->True;
            }
            return XML::XPathEngine::Boolean->False;
        }
        elsif ($lh_results->isa('XML::XPathEngine::Number') ||
                $rh_results->isa('XML::XPathEngine::Number')) {
            # if either is a number
            local $^W; # 'number' might result in undef
            if ($lh_results->to_number->value == $rh_results->to_number->value) {
                return XML::XPathEngine::Boolean->True;
            }
            return XML::XPathEngine::Boolean->False;
        }
        else {
            if ($lh_results->to_literal->value eq $rh_results->to_literal->value) {
                return XML::XPathEngine::Boolean->True;
            }
            return XML::XPathEngine::Boolean->False;
        }
    }
}

sub op_nequals {
    my ($node, $lhs, $rhs) = @_;
    if (op_equals($node, $lhs, $rhs)->value) {
        return XML::XPathEngine::Boolean->False;
    }
    return XML::XPathEngine::Boolean->True;
}

sub op_le {
    my ($node, $lhs, $rhs) = @_;
    op_ge($node, $rhs, $lhs);
}

sub op_ge {
    my ($node, $lhs, $rhs) = @_;

    my $lh_results = $lhs->evaluate($node);
    my $rh_results = $rhs->evaluate($node);
    
    if ($lh_results->isa('XML::XPathEngine::NodeSet') &&
        $rh_results->isa('XML::XPathEngine::NodeSet')) {

        foreach my $lhnode ($lh_results->get_nodelist) {
            foreach my $rhnode ($rh_results->get_nodelist) {
                my $lhNum = XML::XPathEngine::Number->new($lhnode->string_value);
                my $rhNum = XML::XPathEngine::Number->new($rhnode->string_value);
                if ($lhNum->value >= $rhNum->value) {
                    return XML::XPathEngine::Boolean->True;
                }
            }
        }
        return XML::XPathEngine::Boolean->False;
    }
    elsif (($lh_results->isa('XML::XPathEngine::NodeSet') ||
            $rh_results->isa('XML::XPathEngine::NodeSet')) &&
            (!$lh_results->isa('XML::XPathEngine::NodeSet') ||
             !$rh_results->isa('XML::XPathEngine::NodeSet'))) {
        # (that says: one is a nodeset, and one is not a nodeset)

        if ($lh_results->isa('XML::XPathEngine::NodeSet')) {
            foreach my $node ($lh_results->get_nodelist) {
                if ($node->to_number->value >= $rh_results->to_number->value) {
                    return XML::XPathEngine::Boolean->True;
								}
            }
        }
        else {
            foreach my $node ($rh_results->get_nodelist) {
                if ( $lh_results->to_number->value >= $node->to_number->value) {
                    return XML::XPathEngine::Boolean->True;
                }
            }
				}
        return XML::XPathEngine::Boolean->False;
    }
    else { # Neither is a nodeset
        if ($lh_results->isa('XML::XPathEngine::Boolean') ||
            $rh_results->isa('XML::XPathEngine::Boolean')) {
            # if either is a boolean
            if ($lh_results->to_boolean->to_number->value
                    >= $rh_results->to_boolean->to_number->value) {
                return XML::XPathEngine::Boolean->True;
            }
        }
        else {
            if ($lh_results->to_number->value >= $rh_results->to_number->value) {
                return XML::XPathEngine::Boolean->True;
            }
        }
        return XML::XPathEngine::Boolean->False;
    }
}

sub op_gt {
    my ($node, $lhs, $rhs) = @_;

    my $lh_results = $lhs->evaluate($node);
    my $rh_results = $rhs->evaluate($node);
    
    if ($lh_results->isa('XML::XPathEngine::NodeSet') &&
        $rh_results->isa('XML::XPathEngine::NodeSet')) {

        foreach my $lhnode ($lh_results->get_nodelist) {
            foreach my $rhnode ($rh_results->get_nodelist) {
                my $lhNum = XML::XPathEngine::Number->new($lhnode->string_value);
                my $rhNum = XML::XPathEngine::Number->new($rhnode->string_value);
                if ($lhNum->value > $rhNum->value) {
                    return XML::XPathEngine::Boolean->True;
                }
            }
        }
        return XML::XPathEngine::Boolean->False;
    }
    elsif (($lh_results->isa('XML::XPathEngine::NodeSet') ||
            $rh_results->isa('XML::XPathEngine::NodeSet')) &&
            (!$lh_results->isa('XML::XPathEngine::NodeSet') ||
             !$rh_results->isa('XML::XPathEngine::NodeSet'))) {
        # (that says: one is a nodeset, and one is not a nodeset)

        if ($lh_results->isa('XML::XPathEngine::NodeSet')) {
            foreach my $node ($lh_results->get_nodelist) {
                if ($node->to_number->value > $rh_results->to_number->value) {
                    return XML::XPathEngine::Boolean->True;
								}
            }
        }
        else {
            foreach my $node ($rh_results->get_nodelist) {
                if ( $lh_results->to_number->value > $node->to_number->value) {
                    return XML::XPathEngine::Boolean->True;
                }
            }
				}
        return XML::XPathEngine::Boolean->False;
    }
    else { # Neither is a nodeset
        if ($lh_results->isa('XML::XPathEngine::Boolean') ||
            $rh_results->isa('XML::XPathEngine::Boolean')) {
            # if either is a boolean
            if ($lh_results->to_boolean->value > $rh_results->to_boolean->value) {
                return XML::XPathEngine::Boolean->True;
            }
        }
        else {
            if ($lh_results->to_number->value > $rh_results->to_number->value) {
                return XML::XPathEngine::Boolean->True;
            }
        }
        return XML::XPathEngine::Boolean->False;
    }
}

sub op_lt {
    my ($node, $lhs, $rhs) = @_;
    op_gt($node, $rhs, $lhs);
}

sub op_plus {
    my ($node, $lhs, $rhs) = @_;
    my $lh_results = $lhs->evaluate($node);
    my $rh_results = $rhs->evaluate($node);
    
    my $result =
        $lh_results->to_number->value
            +
        $rh_results->to_number->value
            ;
    return XML::XPathEngine::Number->new($result);
}

sub op_minus {
    my ($node, $lhs, $rhs) = @_;
    my $lh_results = $lhs->evaluate($node);
    my $rh_results = $rhs->evaluate($node);
    
    my $result =
        $lh_results->to_number->value
            -
        $rh_results->to_number->value
            ;
    return XML::XPathEngine::Number->new($result);
}

sub op_div {
    my ($node, $lhs, $rhs) = @_;
    my $lh_results = $lhs->evaluate($node);
    my $rh_results = $rhs->evaluate($node);

    my $result = eval {
        $lh_results->to_number->value
            /
        $rh_results->to_number->value
            ;
    };
    if ($@) {
        # assume divide by zero
        # This is probably a terrible way to handle this! 
        # Ah well... who wants to live forever...
        return XML::XPathEngine::Literal->new('Infinity');
    }
    return XML::XPathEngine::Number->new($result);
}

sub op_mod {
    my ($node, $lhs, $rhs) = @_;
    my $lh_results = $lhs->evaluate($node);
    my $rh_results = $rhs->evaluate($node);
    
    my $result =
        $lh_results->to_number->value
            %
        $rh_results->to_number->value
            ;
    return XML::XPathEngine::Number->new($result);
}

sub op_mult {
    my ($node, $lhs, $rhs) = @_;
    my $lh_results = $lhs->evaluate($node);
    my $rh_results = $rhs->evaluate($node);
    
    my $result =
        $lh_results->to_number->value
            *
        $rh_results->to_number->value
            ;
    return XML::XPathEngine::Number->new($result);
}

sub op_union {
    my ($node, $lhs, $rhs) = @_;
    my $lh_result = $lhs->evaluate($node);
    my $rh_result = $rhs->evaluate($node);
    
    if ($lh_result->isa('XML::XPathEngine::NodeSet') &&
            $rh_result->isa('XML::XPathEngine::NodeSet')) {
        my %found;
        my $results = XML::XPathEngine::NodeSet->new;
        foreach my $lhnode ($lh_result->get_nodelist) {
            $found{"$lhnode"}++;
            $results->push($lhnode);
        }
        foreach my $rhnode ($rh_result->get_nodelist) {
            $results->push($rhnode)
                    unless exists $found{"$rhnode"};
        }
        return $results->sort->remove_duplicates;
    }
    die "Both sides of a union must be Node Sets\n";
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
                $newset->push($nodeset->get_node($i));
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
