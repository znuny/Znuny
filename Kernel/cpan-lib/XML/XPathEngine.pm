package XML::XPathEngine;

use warnings;
use strict;

use vars qw($VERSION $AUTOLOAD $revision);

$VERSION = '0.14';
$XML::XPathEngine::Namespaces = 0;
$XML::XPathEngine::DEBUG = 0;

use vars qw/
        $NCName 
        $QName 
        $NCWild
        $QNWild
        $NUMBER_RE 
        $NODE_TYPE 
        $AXIS_NAME 
        %AXES 
        $LITERAL
        $REGEXP_RE
        $REGEXP_MOD_RE
        %CACHE/;

use XML::XPathEngine::Step;
use XML::XPathEngine::Expr;
use XML::XPathEngine::Function;
use XML::XPathEngine::LocationPath;
use XML::XPathEngine::Variable;
use XML::XPathEngine::Literal;
use XML::XPathEngine::Number;
use XML::XPathEngine::NodeSet;
use XML::XPathEngine::Root;

# Axis name to principal node type mapping
%AXES = (
        'ancestor' => 'element',
        'ancestor-or-self' => 'element',
        'attribute' => 'attribute',
        'namespace' => 'namespace',
        'child' => 'element',
        'descendant' => 'element',
        'descendant-or-self' => 'element',
        'following' => 'element',
        'following-sibling' => 'element',
        'parent' => 'element',
        'preceding' => 'element',
        'preceding-sibling' => 'element',
        'self' => 'element',
        );

$NCName = '([A-Za-z_][\w\\.\\-]*)';
$QName = "($NCName:)?$NCName";
$NCWild = "${NCName}:\\*";
$QNWild = "\\*";
$NODE_TYPE = '((text|comment|processing-instruction|node)\\(\\))';
$AXIS_NAME = '(' . join('|', keys %AXES) . ')::';
$NUMBER_RE = '\d+(\\.\d*)?|\\.\d+';
$LITERAL = '\\"[^\\"]*\\"|\\\'[^\\\']*\\\'';
$REGEXP_RE     = qr{(?:m?/(?:\\.|[^/])*/)};
$REGEXP_MOD_RE = qr{(?:[imsx]+)};

sub new {
    my $class = shift;
    my $self = bless {}, $class;
    _debug("New Parser being created.\n") if( $XML::XPathEngine::DEBUG);
    $self->{context_set} = XML::XPathEngine::NodeSet->new();
    $self->{context_pos} = undef; # 1 based position in array context
    $self->{context_size} = 0; # total size of context
    $self->clear_namespaces();
    $self->{vars} = {};
    $self->{direction} = 'forward';
    $self->{cache} = {};
    return $self;
}

sub find {
    my $self = shift;
    my( $path, $context) = @_;
    my $parsed_path= $self->_parse( $path);
    my $results= $parsed_path->evaluate( $context);
    if( $results->isa( 'XML::XPathEngine::NodeSet'))
      { return $results->sort->remove_duplicates; }
    else
      { return $results; }
}


sub matches {
    my $self = shift;
    my ($node, $path, $context) = @_;

    my @nodes = $self->findnodes( $path, $context);

    if (grep { "$node" eq "$_" } @nodes) { return 1; }
    return;
}

sub findnodes {
    my $self = shift;
    my ($path, $context) = @_;
    
    my $results = $self->find( $path, $context);
    
    if ($results->isa('XML::XPathEngine::NodeSet')) 
      { return wantarray ? $results->get_nodelist : $results; }
    else
      { return wantarray ? XML::XPathEngine::NodeSet->new($results) 
                         : $results; 
      } # result should be SCALAR
      #{ return wantarray ? ($results) : $results; } # result should be SCALAR
      #{ return wantarray ? () : XML::XPathEngine::NodeSet->new();   }
}


sub findnodes_as_string {
    my $self = shift;
    my ($path, $context) = @_;
    
    my $results = $self->find( $path, $context);
    

    if ($results->isa('XML::XPathEngine::NodeSet')) {
        return join '', map { $_->toString } $results->get_nodelist;
    }
    elsif ($results->isa('XML::XPathEngine::Boolean')) {
        return ''; # to behave like XML::LibXML
    }
    elsif ($results->isa('XML::XPathEngine::Node')) {
        return $results->toString;
    }
    else {
        return _xml_escape_text($results->value);
    }
}

sub findnodes_as_strings {
    my $self = shift;
    my ($path, $context) = @_;
    
    my $results = $self->find( $path, $context);
    
    if ($results->isa('XML::XPathEngine::NodeSet')) {
        return map { $_->getValue } $results->get_nodelist;
    }
    elsif ($results->isa('XML::XPathEngine::Boolean')) {
        return (); # to behave like XML::LibXML
    }
    elsif ($results->isa('XML::XPathEngine::Node')) {
        return $results->getValue;
    }
    else {
        return _xml_escape_text($results->value);
    }
}

sub findvalue {
    my $self = shift;
    my ($path, $context) = @_;
    my $results = $self->find( $path, $context);
    if ($results->isa('XML::XPathEngine::NodeSet')) 
      { return $results->to_final_value; }
      #{ return $results->to_literal; }
    return $results->value;
}

sub findvalues {
    my $self = shift;
    my ($path, $context) = @_;
    my $results = $self->find( $path, $context);
    if ($results->isa('XML::XPathEngine::NodeSet')) 
      { return $results->string_values; }
    return ($results->string_value);
}


sub exists
{
    my $self = shift;
    my ($path, $context) = @_;
    $self = '/' if (!defined $self);
    my @nodeset = $self->findnodes( $path, $context);
    return scalar( @nodeset ) ? 1 : 0;
}

sub get_var {
    my $self = shift;
    my $var = shift;
    $self->{vars}->{$var};
}

sub set_var {
    my $self = shift;
    my $var = shift;
    my $val = shift;
    $self->{vars}->{$var} = $val;
}

sub set_namespace {
    my $self = shift;
    my ($prefix, $expanded) = @_;
    $self->{uses_namespaces}=1;
    $self->{namespaces}{$prefix} = $expanded;
}

sub clear_namespaces {
    my $self = shift;
    $self->{uses_namespaces}=0;
    $self->{namespaces} = {};
}

sub get_namespace {
    my $self = shift;
    my ($prefix, $node) = @_;
   
    my $ns= $node                    ? $node->getNamespace($prefix)
          : $self->{uses_namespaces} ? $self->{namespaces}->{$prefix}
          :                            $prefix;
  return $ns;
}

sub set_strict_namespaces {
    my( $self, $strict) = @_;
    $self->{strict_namespaces}= $strict;
}

sub _get_context_set { $_[0]->{context_set}; }
sub _set_context_set { $_[0]->{context_set} = $_[1]; }
sub _get_context_pos { $_[0]->{context_pos}; }
sub _set_context_pos { $_[0]->{context_pos} = $_[1]; }
sub _get_context_size { $_[0]->{context_set}->size; }
sub _get_context_node { $_[0]->{context_set}->get_node($_[0]->{context_pos}); }

sub _parse {
    my $self = shift;
    my $path = shift;

    my $context= join( '&&', $path, map { "$_=>$self->{namespaces}->{$_}" } sort keys %{$self->{namespaces}});
    #warn "context: $context\n";

    if ($CACHE{$context}) { return $CACHE{$context}; }

    my $tokens = $self->_tokenize($path);

    $self->{_tokpos} = 0;
    my $tree = $self->_analyze($tokens);
    
    if ($self->{_tokpos} < scalar(@$tokens)) {
        # didn't manage to parse entire expression - throw an exception
        die "Parse of expression $path failed - junk after end of expression: $tokens->[$self->{_tokpos}]";
    }

    $tree->{uses_namespaces}= $self->{uses_namespaces};   
    $tree->{strict_namespaces}= $self->{strict_namespaces};   
 
    $CACHE{$context} = $tree;
    
    _debug("PARSED Expr to:\n", $tree->as_string, "\n") if( $XML::XPathEngine::DEBUG);
    
    return $tree;
}

sub _tokenize {
    my $self = shift;
    my $path = shift;
    study $path;
    
    my @tokens;
    
    _debug("Parsing: $path\n") if( $XML::XPathEngine::DEBUG);
    
    # Bug: We don't allow "'@' NodeType" which is in the grammar, but I think is just plain stupid.

    my $expected=''; # used to desambiguate conflicts (for REs)

    while( length($path))
      { my $token='';
        if( $expected eq 'RE' && ($path=~ m{\G\s*($REGEXP_RE $REGEXP_MOD_RE?)\s*}gcxso))
          { # special case: regexp expected after =~ or !~, regular parsing rules do not apply
            # ( the / is now the regexp delimiter) 
            $token= $1; $expected=''; 
          }
        elsif($path =~ m/\G
            \s* # ignore all whitespace
            ( # tokens
                $LITERAL|
                $NUMBER_RE|                            # digits
                \.\.|                                  # parent
                \.|                                    # current
                ($AXIS_NAME)?$NODE_TYPE|               # tests
                processing-instruction|
                \@($NCWild|$QName|$QNWild)|            # attrib
                \$$QName|                              # variable reference
                ($AXIS_NAME)?($NCWild|$QName|$QNWild)| # NCName,NodeType,Axis::Test
                \!=|<=|\-|>=|\/\/|and|or|mod|div|      # multi-char seps
                =~|\!~|                                # regexp (not in the XPath spec)
                [,\+=\|<>\/\(\[\]\)]|                  # single char seps
                (?<!(\@|\(|\[))\*|                     # multiply operator rules (see xpath spec)
                (?<!::)\*|
                $                                      # end of query
            )
            \s*                                        # ignore all whitespace
            /gcxso) 
          { 
            $token = $1;
            $expected= ($token=~ m{^[=!]~$}) ? 'RE' : '';
          }
        else
          { $token=''; last; }

        if (length($token)) {
            _debug("TOKEN: $token\n") if( $XML::XPathEngine::DEBUG);
            push @tokens, $token;
        }
            
        }
    
    if (pos($path) < length($path)) {
        my $marker = ("." x (pos($path)-1));
        $path = substr($path, 0, pos($path) + 8) . "...";
        $path =~ s/\n/ /g;
        $path =~ s/\t/ /g;
        die "Query:\n",
            "$path\n",
            $marker, "^^^\n",
            "Invalid query somewhere around here (I think)\n";
    }
    
    return \@tokens;
}

sub _analyze {
    my $self = shift;
    my $tokens = shift;
    # lexical analysis
    
    return _expr($self, $tokens);
}

sub _match {
    my ($self, $tokens, $match, $fatal) = @_;
    
    $self->{_curr_match} = '';
    return 0 unless $self->{_tokpos} < @$tokens;

    local $^W;
    
#    _debug ("match: $match\n") if( $XML::XPathEngine::DEBUG);
    
    if ($tokens->[$self->{_tokpos}] =~ /^$match$/) {
        $self->{_curr_match} = $tokens->[$self->{_tokpos}];
        $self->{_tokpos}++;
        return 1;
    }
    else {
        if ($fatal) {
            die "Invalid token: ", $tokens->[$self->{_tokpos}], "\n";
        }
        else {
            return 0;
        }
    }
}

sub _expr {
    my ($self, $tokens) = @_;
    
    _debug( "in _exprexpr\n") if( $XML::XPathEngine::DEBUG);
    
    return _or_expr($self, $tokens);
}

sub _or_expr {
    my ($self, $tokens) = @_;
    
    _debug( "in _or_expr\n") if( $XML::XPathEngine::DEBUG);
    
    my $expr = _and_expr($self, $tokens); 
    while (_match($self, $tokens, 'or')) {
        my $or_expr = XML::XPathEngine::Expr->new($self);
        $or_expr->set_lhs($expr);
        $or_expr->set_op('or');

        my $rhs = _and_expr($self, $tokens);

        $or_expr->set_rhs($rhs);
        $expr = $or_expr;
    }
    
    return $expr;
}

sub _and_expr {
    my ($self, $tokens) = @_;
    
    _debug( "in _and_expr\n") if( $XML::XPathEngine::DEBUG);
    
    my $expr = _match_expr($self, $tokens);
    while (_match($self, $tokens, 'and')) {
        my $and_expr = XML::XPathEngine::Expr->new($self);
        $and_expr->set_lhs($expr);
        $and_expr->set_op('and');
        
        my $rhs = _match_expr($self, $tokens);
        
        $and_expr->set_rhs($rhs);
        $expr = $and_expr;
    }
    
    return $expr;
}

sub _match_expr {
    my ($self, $tokens) = @_;
    
    _debug( "in _match_expr\n") if( $XML::XPathEngine::DEBUG);
    
    my $expr = _equality_expr($self, $tokens);

    while (_match($self, $tokens, '[=!]~')) {
        my $match_expr = XML::XPathEngine::Expr->new($self);
        $match_expr->set_lhs($expr);
        $match_expr->set_op($self->{_curr_match});
        
        my $rhs = _equality_expr($self, $tokens);
        
        $match_expr->set_rhs($rhs);
        $expr = $match_expr;
    }
    
    return $expr;
}


sub _equality_expr {
    my ($self, $tokens) = @_;
    
    _debug( "in _equality_expr\n") if( $XML::XPathEngine::DEBUG);
    
    my $expr = _relational_expr($self, $tokens);
    while (_match($self, $tokens, '!?=')) {
        my $eq_expr = XML::XPathEngine::Expr->new($self);
        $eq_expr->set_lhs($expr);
        $eq_expr->set_op($self->{_curr_match});
        
        my $rhs = _relational_expr($self, $tokens);
        
        $eq_expr->set_rhs($rhs);
        $expr = $eq_expr;
    }
    
    return $expr;
}

sub _relational_expr {
    my ($self, $tokens) = @_;
    
    _debug( "in _relational_expr\n") if( $XML::XPathEngine::DEBUG);
    
    my $expr = _additive_expr($self, $tokens);
    while (_match($self, $tokens, '(<|>|<=|>=)')) {
        my $rel_expr = XML::XPathEngine::Expr->new($self);
        $rel_expr->set_lhs($expr);
        $rel_expr->set_op($self->{_curr_match});
        
        my $rhs = _additive_expr($self, $tokens);
        
        $rel_expr->set_rhs($rhs);
        $expr = $rel_expr;
    }
    
    return $expr;
}

sub _additive_expr {
    my ($self, $tokens) = @_;
    
    _debug( "in _additive_expr\n") if( $XML::XPathEngine::DEBUG);
    
    my $expr = _multiplicative_expr($self, $tokens);
    while (_match($self, $tokens, '[\\+\\-]')) {
        my $add_expr = XML::XPathEngine::Expr->new($self);
        $add_expr->set_lhs($expr);
        $add_expr->set_op($self->{_curr_match});
        
        my $rhs = _multiplicative_expr($self, $tokens);
        
        $add_expr->set_rhs($rhs);
        $expr = $add_expr;
    }
    
    return $expr;
}

sub _multiplicative_expr {
    my ($self, $tokens) = @_;
    
    _debug( "in _multiplicative_expr\n") if( $XML::XPathEngine::DEBUG);
    
    my $expr = _unary_expr($self, $tokens);
    while (_match($self, $tokens, '(\\*|div|mod)')) {
        my $mult_expr = XML::XPathEngine::Expr->new($self);
        $mult_expr->set_lhs($expr);
        $mult_expr->set_op($self->{_curr_match});
        
        my $rhs = _unary_expr($self, $tokens);
        
        $mult_expr->set_rhs($rhs);
        $expr = $mult_expr;
    }
    
    return $expr;
}

sub _unary_expr {
    my ($self, $tokens) = @_;
    
    _debug( "in _unary_expr\n") if( $XML::XPathEngine::DEBUG);
    
    if (_match($self, $tokens, '-')) {
        my $expr = XML::XPathEngine::Expr->new($self);
        $expr->set_lhs(XML::XPathEngine::Number->new(0));
        $expr->set_op('-');
        $expr->set_rhs(_unary_expr($self, $tokens));
        return $expr;
    }
    else {
        return _union_expr($self, $tokens);
    }
}

sub _union_expr {
    my ($self, $tokens) = @_;
    
    _debug( "in _union_expr\n") if( $XML::XPathEngine::DEBUG);
    
    my $expr = _path_expr($self, $tokens);
    while (_match($self, $tokens, '\\|')) {
        my $un_expr = XML::XPathEngine::Expr->new($self);
        $un_expr->set_lhs($expr);
        $un_expr->set_op('|');
        
        my $rhs = _path_expr($self, $tokens);
        
        $un_expr->set_rhs($rhs);
        $expr = $un_expr;
    }
    
    return $expr;
}

sub _path_expr {
    my ($self, $tokens) = @_;

    _debug( "in _path_expr\n") if( $XML::XPathEngine::DEBUG);
    
    # _path_expr is _location_path | _filter_expr | _filter_expr '//?' _relative_location_path
    
    # Since we are being predictive we need to find out which function to call next, then.
        
    # LocationPath either starts with "/", "//", ".", ".." or a proper Step.
    
    my $expr = XML::XPathEngine::Expr->new($self);
    
    my $test = $tokens->[$self->{_tokpos}];
    
    # Test for AbsoluteLocationPath and AbbreviatedRelativeLocationPath
    if ($test =~ /^(\/\/?|\.\.?)$/) {
        # LocationPath
        $expr->set_lhs(_location_path($self, $tokens));
    }
    # Test for AxisName::...
    elsif (_is_step($self, $tokens)) {
        $expr->set_lhs(_location_path($self, $tokens));
    }
    else {
        # Not a LocationPath
        # Use _filter_expr instead:
        
        $expr = _filter_expr($self, $tokens);
        if (_match($self, $tokens, '//?')) {
            my $loc_path = XML::XPathEngine::LocationPath->new();
            push @$loc_path, $expr;
            if ($self->{_curr_match} eq '//') {
                push @$loc_path, XML::XPathEngine::Step->new($self, 'descendant-or-self', 
                                        XML::XPathEngine::Step::test_nt_node() );
            }
            push @$loc_path, _relative_location_path($self, $tokens);
            my $new_expr = XML::XPathEngine::Expr->new($self);
            $new_expr->set_lhs($loc_path);
            return $new_expr;
        }
    }
    
    return $expr;
}

sub _filter_expr {
    my ($self, $tokens) = @_;
    
    _debug( "in _filter_expr\n") if( $XML::XPathEngine::DEBUG);
    
    my $expr = _primary_expr($self, $tokens);
    while (_match($self, $tokens, '\\[')) {
        # really PredicateExpr...
        $expr->push_predicate(_expr($self, $tokens));
        _match($self, $tokens, '\\]', 1);
    }
    
    return $expr;
}

sub _primary_expr {
    my ($self, $tokens) = @_;

    _debug( "in _primary_expr\n") if( $XML::XPathEngine::DEBUG);
    
    my $expr = XML::XPathEngine::Expr->new($self);
    
    if (_match($self, $tokens, $LITERAL)) {
        # new Literal with $self->{_curr_match}...
        $self->{_curr_match} =~ m/^(["'])(.*)\1$/;
        $expr->set_lhs(XML::XPathEngine::Literal->new($2));
    }
    elsif (_match($self, $tokens, "$REGEXP_RE$REGEXP_MOD_RE?")) {
        # new Literal with $self->{_curr_match} turned into a regexp... 
        my( $regexp, $mod)= $self->{_curr_match} =~  m{($REGEXP_RE)($REGEXP_MOD_RE?)};
        $regexp=~ s{^m?s*/}{};
        $regexp=~ s{/$}{};                        
        if( $mod) { $regexp=~ "(?$mod:$regexp)"; } # move the mods inside the regexp
        $expr->set_lhs(XML::XPathEngine::Literal->new($regexp));
    }
    elsif (_match($self, $tokens, $NUMBER_RE)) {
        # new Number with $self->{_curr_match}...
        $expr->set_lhs(XML::XPathEngine::Number->new($self->{_curr_match}));
    }
    elsif (_match($self, $tokens, '\\(')) {
        $expr->set_lhs(_expr($self, $tokens));
        _match($self, $tokens, '\\)', 1);
    }
    elsif (_match($self, $tokens, "\\\$$QName")) {
        # new Variable with $self->{_curr_match}...
        $self->{_curr_match} =~ /^\$(.*)$/;
        $expr->set_lhs(XML::XPathEngine::Variable->new($self, $1));
    }
    elsif (_match($self, $tokens, $QName)) {
        # check match not Node_Type - done in lexer...
        # new Function
        my $func_name = $self->{_curr_match};
        _match($self, $tokens, '\\(', 1);
        $expr->set_lhs(
                XML::XPathEngine::Function->new(
                    $self,
                    $func_name,
                    _arguments($self, $tokens)
                )
            );
        _match($self, $tokens, '\\)', 1);
    }
    else {
        die "Not a _primary_expr at ", $tokens->[$self->{_tokpos}], "\n";
    }
    
    return $expr;
}

sub _arguments {
    my ($self, $tokens) = @_;
    
    _debug( "in _arguments\n") if( $XML::XPathEngine::DEBUG);
    
    my @args;
    
    if($tokens->[$self->{_tokpos}] eq ')') {
        return \@args;
    }
    
    push @args, _expr($self, $tokens);
    while (_match($self, $tokens, ',')) {
        push @args, _expr($self, $tokens);
    }
    
    return \@args;
}

sub _location_path {
    my ($self, $tokens) = @_;

    _debug( "in _location_path\n") if( $XML::XPathEngine::DEBUG);
    
    my $loc_path = XML::XPathEngine::LocationPath->new();
    
    if (_match($self, $tokens, '/')) {
        # root
        _debug("h: Matched root\n") if( $XML::XPathEngine::DEBUG);
        push @$loc_path, XML::XPathEngine::Root->new();
        if (_is_step($self, $tokens)) {
            _debug("Next is step\n") if( $XML::XPathEngine::DEBUG);
            push @$loc_path, _relative_location_path($self, $tokens);
        }
    }
    elsif (_match($self, $tokens, '//')) {
        # root
        push @$loc_path, XML::XPathEngine::Root->new();
        my $optimised = _optimise_descendant_or_self($self, $tokens);
        if (!$optimised) {
            push @$loc_path, XML::XPathEngine::Step->new($self, 'descendant-or-self',
                                XML::XPathEngine::Step::test_nt_node);
            push @$loc_path, _relative_location_path($self, $tokens);
        }
        else {
            push @$loc_path, $optimised, _relative_location_path($self, $tokens);
        }
    }
    else {
        push @$loc_path, _relative_location_path($self, $tokens);
    }
    
    return $loc_path;
}

sub _optimise_descendant_or_self {
    my ($self, $tokens) = @_;
    
    _debug( "in _optimise_descendant_or_self\n") if( $XML::XPathEngine::DEBUG);
    
    my $tokpos = $self->{_tokpos};
    
    # // must be followed by a Step.
    if ($tokens->[$tokpos+1] && $tokens->[$tokpos+1] eq '[') {
        # next token is a predicate
        return;
    }
    elsif ($tokens->[$tokpos] =~ /^\.\.?$/) {
        # abbreviatedStep - can't optimise.
        return;
    }                                                                                              
    else {
        _debug("Trying to optimise //\n") if( $XML::XPathEngine::DEBUG);
        my $step = _step($self, $tokens);
        if ($step->{axis} ne 'child') {
            # can't optimise axes other than child for now...
            $self->{_tokpos} = $tokpos;
            return;
        }
        $step->{axis} = 'descendant';
        $step->{axis_method} = 'axis_descendant';
        $self->{_tokpos}--;
        $tokens->[$self->{_tokpos}] = '.';
        return $step;
    }
}

sub _relative_location_path {
    my ($self, $tokens) = @_;
    
    _debug( "in _relative_location_path\n") if( $XML::XPathEngine::DEBUG);
    
    my @steps;
    
    push @steps,_step($self, $tokens);
    while (_match($self, $tokens, '//?')) {
        if ($self->{_curr_match} eq '//') {
            my $optimised = _optimise_descendant_or_self($self, $tokens);
            if (!$optimised) {
                push @steps, XML::XPathEngine::Step->new($self, 'descendant-or-self',
                                        XML::XPathEngine::Step::test_nt_node);
            }
            else {
                push @steps, $optimised;
            }
        }
        push @steps, _step($self, $tokens);
        if (@steps > 1 && 
                $steps[-1]->{axis} eq 'self' && 
                $steps[-1]->{test} == XML::XPathEngine::Step::test_nt_node) {
            pop @steps;
        }
    }
    
    return @steps;
}

sub _step {
    my ($self, $tokens) = @_;

    _debug( "in _step\n") if( $XML::XPathEngine::DEBUG);
    
    if (_match($self, $tokens, '\\.')) {
        # self::node()
        return XML::XPathEngine::Step->new($self, 'self', XML::XPathEngine::Step::test_nt_node);
    }
    elsif (_match($self, $tokens, '\\.\\.')) {
        # parent::node()
        return XML::XPathEngine::Step->new($self, 'parent', XML::XPathEngine::Step::test_nt_node);
    }
    else {
        # AxisSpecifier NodeTest Predicate(s?)
        my $token = $tokens->[$self->{_tokpos}];
        
        _debug("p: Checking $token\n") if( $XML::XPathEngine::DEBUG);
        
        my $step;
        if ($token eq 'processing-instruction') {
            $self->{_tokpos}++;
            _match($self, $tokens, '\\(', 1);
            _match($self, $tokens, $LITERAL);
            $self->{_curr_match} =~ /^["'](.*)["']$/;
            $step = XML::XPathEngine::Step->new($self, 'child',
                                    XML::XPathEngine::Step::test_nt_pi,
                        XML::XPathEngine::Literal->new($1));
            _match($self, $tokens, '\\)', 1);
        }
        elsif ($token =~ /^\@($NCWild|$QName|$QNWild)$/o) {
            $self->{_tokpos}++;
                        if ($token eq '@*') {
                            $step = XML::XPathEngine::Step->new($self,
                                    'attribute',
                                    XML::XPathEngine::Step::test_attr_any,
                                    '*');
                        }
                        elsif ($token =~ /^\@($NCName):\*$/o) {
                            $step = XML::XPathEngine::Step->new($self,
                                    'attribute',
                                    XML::XPathEngine::Step::test_attr_ncwild,
                                    $1);
                        }
                        elsif ($token =~ /^\@($QName)$/o) {
                            $step = XML::XPathEngine::Step->new($self,
                                    'attribute',
                                    XML::XPathEngine::Step::test_attr_qname,
                                    $1);
                        }
        }
        elsif ($token =~ /^($NCName):\*$/o) { # ns:*
            $self->{_tokpos}++;
            $step = XML::XPathEngine::Step->new($self, 'child', 
                                XML::XPathEngine::Step::test_ncwild,
                                $1);
        }
        elsif ($token =~ /^$QNWild$/o) { # *
            $self->{_tokpos}++;
            $step = XML::XPathEngine::Step->new($self, 'child', 
                                XML::XPathEngine::Step::test_any,
                                $token);
        }
        elsif ($token =~ /^$QName$/o) { # name:name
            $self->{_tokpos}++;
            $step = XML::XPathEngine::Step->new($self, 'child', 
                                XML::XPathEngine::Step::test_qname,
                                $token);
        }
        elsif ($token eq 'comment()') {
                    $self->{_tokpos}++;
            $step = XML::XPathEngine::Step->new($self, 'child',
                            XML::XPathEngine::Step::test_nt_comment);
        }
        elsif ($token eq 'text()') {
            $self->{_tokpos}++;
            $step = XML::XPathEngine::Step->new($self, 'child',
                    XML::XPathEngine::Step::test_nt_text);
        }
        elsif ($token eq 'node()') {
            $self->{_tokpos}++;
            $step = XML::XPathEngine::Step->new($self, 'child',
                    XML::XPathEngine::Step::test_nt_node);
        }
        elsif ($token eq 'processing-instruction()') {
            $self->{_tokpos}++;
            $step = XML::XPathEngine::Step->new($self, 'child',
                    XML::XPathEngine::Step::test_nt_pi);
        }
        elsif ($token =~ /^$AXIS_NAME($NCWild|$QName|$QNWild|$NODE_TYPE)$/o) {
                    my $axis = $1;
                    $self->{_tokpos}++;
                    $token = $2;
            if ($token eq 'processing-instruction') {
                _match($self, $tokens, '\\(', 1);
                _match($self, $tokens, $LITERAL);
                $self->{_curr_match} =~ /^["'](.*)["']$/;
                $step = XML::XPathEngine::Step->new($self, $axis,
                                        XML::XPathEngine::Step::test_nt_pi,
                            XML::XPathEngine::Literal->new($1));
                _match($self, $tokens, '\\)', 1);
            }
            elsif ($token =~ /^($NCName):\*$/o) { # ns:*
                $step = XML::XPathEngine::Step->new($self, $axis, 
                                    (($axis eq 'attribute') ? 
                                    XML::XPathEngine::Step::test_attr_ncwild
                                        :
                                    XML::XPathEngine::Step::test_ncwild),
                                    $1);
            }
            elsif ($token =~ /^$QNWild$/o) { # *
                $step = XML::XPathEngine::Step->new($self, $axis, 
                                    (($axis eq 'attribute') ?
                                    XML::XPathEngine::Step::test_attr_any
                                        :
                                    XML::XPathEngine::Step::test_any),
                                    $token);
            }
            elsif ($token =~ /^$QName$/o) { # name:name
                $step = XML::XPathEngine::Step->new($self, $axis, 
                                    (($axis eq 'attribute') ?
                                    XML::XPathEngine::Step::test_attr_qname
                                        :
                                    XML::XPathEngine::Step::test_qname),
                                    $token);
            }
            elsif ($token eq 'comment()') {
                $step = XML::XPathEngine::Step->new($self, $axis,
                                XML::XPathEngine::Step::test_nt_comment);
            }
            elsif ($token eq 'text()') {
                $step = XML::XPathEngine::Step->new($self, $axis,
                        XML::XPathEngine::Step::test_nt_text);
            }
            elsif ($token eq 'node()') {
                $step = XML::XPathEngine::Step->new($self, $axis,
                        XML::XPathEngine::Step::test_nt_node);
            }
            elsif ($token eq 'processing-instruction()') {
                $step = XML::XPathEngine::Step->new($self, $axis,
                        XML::XPathEngine::Step::test_nt_pi);
            }
            else {
                die "Shouldn't get here";
            }
        }
        else {
            die "token $token doesn't match format of a 'Step'\n";
        }
        
        while (_match($self, $tokens, '\\[')) {
            push @{$step->{predicates}}, _expr($self, $tokens);
            _match($self, $tokens, '\\]', 1);
        }
        
        return $step;
    }
}

sub _is_step {
    my ($self, $tokens) = @_;
    
    my $token = $tokens->[$self->{_tokpos}];
    
    return unless defined $token;
        
    _debug("p: Checking if '$token' is a step\n") if( $XML::XPathEngine::DEBUG);
    
    local $^W=0;
        
    if(   ($token eq 'processing-instruction') 
       || ($token =~ /^\@($NCWild|$QName|$QNWild)$/o)
       || (    ($token =~ /^($NCWild|$QName|$QNWild)$/o )
            && ( ($tokens->[$self->{_tokpos}+1] || '') ne '(') )
       || ($token =~ /^$NODE_TYPE$/o)
       || ($token =~ /^$AXIS_NAME($NCWild|$QName|$QNWild|$NODE_TYPE)$/o)
      )
      { return 1; }
    else
      { _debug("p: '$token' not a step\n") if( $XML::XPathEngine::DEBUG);
        return;
      }
}

{ my %ENT;
  BEGIN { %ENT= ( '&' => '&amp;', '<' => '&lt;', '>' => '&gt;', '"' => '&quote;'); }
 
  sub _xml_escape_text
    { my( $text)= @_;
      $text=~ s{([&<>])}{$ENT{$1}}g;
      return $text;
    }
}

sub _debug {
    
    my ($pkg, $file, $line, $sub) = caller(1);
    
    $sub =~ s/^$pkg\:://;
    
    while (@_) {
        my $x = shift;
        $x =~ s/\bPKG\b/$pkg/g;
        $x =~ s/\bLINE\b/$line/g;
        $x =~ s/\bg\b/$sub/g;
        print STDERR $x;
    }
}


__END__

=head1 NAME

XML::XPathEngine - a re-usable XPath engine for DOM-like trees

=head1 DESCRIPTION

This module provides an XPath engine, that can be re-used by other
module/classes that implement trees.

In order to use the XPath engine, nodes in the user module need to mimick
DOM nodes. The degree of similitude between the user tree and a DOM dictates 
how much of the XPath features can be used. A module implementing all of the
DOM should be able to use this module very easily (you might need to add
the cmp method on nodes in order to get ordered result sets). 

This code is a more or less direct copy of the L<XML::XPath> module by
Matt Sergeant. I only removed the XML processing part to remove the dependency
on XML::Parser, applied a couple of patches, renamed a whole lot of methods
to make Pod::Coverage happy, and changed the docs.

The article eXtending XML XPath, http://www.xmltwig.com/article/extending_xml_xpath/
should give authors who want to use this module enough background to do so.

Otherwise, my email is below ;--)

B<WARNING>: while the underlying code is rather solid, this module mostly lacks docs.
As they say, "patches welcome"...

=head1 SYNOPSIS

    use XML::XPathEngine;
    
    my $tree= my_tree->new( ...);
    my $xp = XML::XPathEngine->new();
    
    my @nodeset = $xp->find('/root/kid/grandkid[1]', $tree); # find all first grankids

    package XML::MyTree;

    # needs to provide DOM methods
    

=head1 DETAILS

=head1 API

XML::XPathEngine will provide the following methods:

=head2 new

=head2 findnodes ($path, $context)

Returns a list of nodes found by $path, optionally in context $context. 
In scalar context returns an XML::XPathEngine::NodeSet object.

=head2 findnodes_as_string ($path, $context)

Returns the nodes found as a single string. The result is 
not guaranteed to be valid XML though (it could for example be just text
if the query returns attribute values).

=head2 findnodes_as_strings ($path, $context)

Returns the nodes found as a list of strings, one per node found.

=head2 findvalue ($path, $context)

Returns the result as a string (the concatenation of the values of the
result nodes).

=head2 findvalues($path, $context)

Returns the values of the result nodes as a list of strings.

=head2 exists ($path, $context)

Returns true if the given path exists.

=head2 matches($node, $path, $context)

Returns true if the node matches the path.

=head2 find ($path, $context)

The find function takes an XPath expression (a string) and returns either a
XML::XPathEngine::NodeSet object containing the nodes it found (or empty if
no nodes matched the path), or one of XML::XPathEngine::Literal (a string),
XML::XPathEngine::Number, or XML::XPathEngine::Boolean. It should always return 
something - and you can use ->isa() to find out what it returned. If you
need to check how many nodes it found you should check $nodeset->size.
See L<XML::XPathEngine::NodeSet>. 

=head2 getNodeText ($path)

Returns the text string for a particular node. Returns a string,
or undef if the node doesn't exist.

=head2 set_namespace ($prefix, $uri)

Sets the namespace prefix mapping to the uri.

Normally in XML::XPathEngine the prefixes in XPath node tests take their
context from the current node. This means that foo:bar will always
match an element <foo:bar> regardless of the namespace that the prefix
foo is mapped to (which might even change within the document, resulting
in unexpected results). In order to make prefixes in XPath node tests
actually map to a real URI, you need to enable that via a call
to the set_namespace method of your XML::XPathEngine object.

=head2 clear_namespaces ()

Clears all previously set namespace mappings.

=head2 get_namespace ($prefix, $node)

Returns the uri associated to the prefix for the node (mostly for internal usage)

=head2 set_strict_namespaces ($strict)

By default, for historical as well as convenience reasons, XML::XPathEngine
has a slightly non-standard way of dealing with the default namespace. 

If you search for C<//tag> it will return elements C<tag>. As far as I understand it,
if the document has a default namespace, this should not return anything.
You would have to first do a C<set_namespace>, and then search using the namespace.

Passing a true value to C<set_strict_namespaces> will activate this behaviour, passing a
false value will return it to its default behaviour.

=head2 set_var ($var. $val)

Sets an XPath variable (that can be used in queries as C<$var>)

=head2 get_var ($var)

Returns the value of the XPath variable (mostly for internal usage)

=head2 $XML::XPathEngine::Namespaces

Set this to 0 if you I<don't> want namespace processing to occur. This
will make everything a little (tiny) bit faster, but you'll suffer for it,
probably.

=head1 Node Object Model

Nodes need to provide the same API as nodes in XML::XPath (at least the access 
API, not the tree manipulation one).


=head1 Example

Please see the test files in t/ for examples on how to use XPath.

=head1 XPath extension

The module supports the XPath recommendation to the same extend as XML::XPath 
(that is, rather completely).

It includes a perl-specific extension: direct support for regular expressions.

You can use the usual (in Perl!) C<=~> and C<!~> operators. Regular expressions 
are / delimited (no other delimiter is accepted, \ inside regexp must be 
backslashed), the C<imsx> modifiers can be used. 

  $xp->findnodes( '//@att[.=~ /^v.$/]'); # returns the list of attributes att
                                         # whose value matches ^v.$

=head1 SEE ALSO

L<XML::XPath>

L<HTML::TreeBuilder::XPath>, L<XML::Twig::XPath> for exemples of using this module

L<Tree::XPathEngine> for a similar module for non-XML trees.

L<http://www.xmltwig.com/article/extending_xml_xpath/> for background 
information. The last section of the article summarizes how to reuse XML::XPath.
As XML::XPathEngine offers the same API it should help you


=head1 AUTHOR

Michel Rodriguez, C<< <mirod@cpan.org> >>
Most code comes directly from XML::XPath, by Matt Sergeant.


=head1 BUGS

Please report any bugs or feature requests to
C<bug-tree-xpathengine@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=XML-XPathEngine>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

XML::XPath Copyright 2000 AxKit.com Ltd.
Copyright 2006 Michel Rodriguez, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of XML::XPathEngine
