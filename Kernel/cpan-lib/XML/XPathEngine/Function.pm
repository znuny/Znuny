# $Id: Function.pm,v 1.26 2002/12/26 17:24:50 matt Exp $

package XML::XPathEngine::Function;
use XML::XPathEngine::Number;
use XML::XPathEngine::Literal;
use XML::XPathEngine::Boolean;
use XML::XPathEngine::NodeSet;
use strict;

sub new {
    my $class = shift;
    my ($pp, $name, $params) = @_;
    bless { 
        pp => $pp, 
        name => $name, 
        params => $params 
        }, $class;
}

sub as_string {
    my $self = shift;
    my $string = $self->{name} . "(";
    my $second;
    foreach (@{$self->{params}}) {
        $string .= "," if $second++;
        $string .= $_->as_string;
    }
    $string .= ")";
    return $string;
}

sub as_xml {
    my $self = shift;
    my $string = "<Function name=\"$self->{name}\"";
    my $params = "";
    foreach (@{$self->{params}}) {
        $params .= "<Param>" . $_->as_xml . "</Param>\n";
    }
    if ($params) {
        $string .= ">\n$params</Function>\n";
    }
    else {
        $string .= " />\n";
    }
    
    return $string;
}

sub evaluate {
    my $self = shift;
    my $node = shift;
    while ($node->isa('XML::XPathEngine::NodeSet')) {
        $node = $node->get_node(1);
    }
    my @params;
    foreach my $param (@{$self->{params}}) {
        my $results = $param->evaluate($node);
        push @params, $results;
    }
    $self->_execute($self->{name}, $node, @params);
}

sub _execute {
    my $self = shift;
    my ($name, $node, @params) = @_;
    $name =~ s/-/_/g;
    no strict 'refs';
    $self->$name($node, @params);
}

# All functions should return one of:
# XML::XPathEngine::Number
# XML::XPathEngine::Literal (string)
# XML::XPathEngine::NodeSet
# XML::XPathEngine::Boolean

### NODESET FUNCTIONS ###

sub last {
    my $self = shift;
    my ($node, @params) = @_;
    die "last: function doesn't take parameters\n" if (@params);
    return XML::XPathEngine::Number->new($self->{pp}->_get_context_size);
}

sub position {
    my $self = shift;
    my ($node, @params) = @_;
    if (@params) {
        die "position: function doesn't take parameters [ ", @params, " ]\n";
    }
    # return pos relative to axis direction
    return XML::XPathEngine::Number->new($self->{pp}->_get_context_pos);
}

sub count {
    my $self = shift;
    my ($node, @params) = @_;
    die "count: Parameter must be a NodeSet\n" unless $params[0]->isa('XML::XPathEngine::NodeSet');
    return XML::XPathEngine::Number->new($params[0]->size);
}

sub id {
    my $self = shift;
    my ($node, @params) = @_;
    die "id: Function takes 1 parameter\n" unless @params == 1;
    my $results = XML::XPathEngine::NodeSet->new();
    if ($params[0]->isa('XML::XPathEngine::NodeSet')) {
        # result is the union of applying id() to the
        # string value of each node in the nodeset.
        foreach my $node ($params[0]->get_nodelist) {
            my $string = $node->string_value;
            $results->append($self->id($node, XML::XPathEngine::Literal->new($string)));
        }
    }
    else { # The actual id() function...
        my $string = $self->string($node, $params[0]);
        $_ = $string->value; # get perl scalar
        my @ids = split; # splits $_
        if ($node->isAttributeNode) {
            warn "calling \($node->getParentNode->getRootNode->getChildNodes)->[0] on attribute node\n";
            $node = ($node->getParentNode->getRootNode->getChildNodes)->[0];
        }
        foreach my $id (@ids) {
            if (my $found = $node->getElementById($id)) {
                $results->push($found);
            }
        }
    }
    return $results;
}

sub local_name {
    my $self = shift;
    my ($node, @params) = @_;
    if (@params > 1) {
        die "name() function takes one or no parameters\n";
    }
    elsif (@params) {
        my $nodeset = shift(@params);
        $node = $nodeset->get_node(1);
    }
    
    return XML::XPathEngine::Literal->new($node->getLocalName);
}

sub namespace_uri {
    my $self = shift;
    my ($node, @params) = @_;
    die "namespace-uri: Function not supported\n";
}

sub name {
    my $self = shift;
    my ($node, @params) = @_;
    if (@params > 1) {
        die "name() function takes one or no parameters\n";
    }
    elsif (@params) {
        my $nodeset = shift(@params);
        $node = $nodeset->get_node(1);
    }
    
    return XML::XPathEngine::Literal->new($node->getName);
}

### STRING FUNCTIONS ###

sub string {
    my $self = shift;
    my ($node, @params) = @_;
    die "string: Too many parameters\n" if @params > 1;
    if (@params) {
        return XML::XPathEngine::Literal->new($params[0]->string_value);
    }
    
    # TODO - this MUST be wrong! - not sure now. -matt
    return XML::XPathEngine::Literal->new($node->string_value);
    # default to nodeset with just $node in.
}

sub concat {
    my $self = shift;
    my ($node, @params) = @_;
    die "concat: Too few parameters\n" if @params < 2;
    my $string = join('', map {$_->string_value} @params);
    return XML::XPathEngine::Literal->new($string);
}

sub starts_with {
    my $self = shift;
    my ($node, @params) = @_;
    die "starts-with: incorrect number of params\n" unless @params == 2;
    my ($string1, $string2) = ($params[0]->string_value, $params[1]->string_value);
    if (substr($string1, 0, length($string2)) eq $string2) {
        return XML::XPathEngine::Boolean->True;
    }
    return XML::XPathEngine::Boolean->False;
}

sub contains {
    my $self = shift;
    my ($node, @params) = @_;
    die "starts-with: incorrect number of params\n" unless @params == 2;
    my $value = $params[1]->string_value;
    if ($params[0]->string_value =~ /(.*?)\Q$value\E(.*)/) {
        return XML::XPathEngine::Boolean->True;
    }
    return XML::XPathEngine::Boolean->False;
}

sub substring_before {
    my $self = shift;
    my ($node, @params) = @_;
    die "starts-with: incorrect number of params\n" unless @params == 2;
    my $long = $params[0]->string_value;
    my $short= $params[1]->string_value;
    if( $long=~ m{^(.*?)\Q$short})  {
        return XML::XPathEngine::Literal->new($1); 
    }
    else {
        return XML::XPathEngine::Literal->new('');
    }
}

sub substring_after {
    my $self = shift;
    my ($node, @params) = @_;
    die "starts-with: incorrect number of params\n" unless @params == 2;
    my $long = $params[0]->string_value;
    my $short= $params[1]->string_value;
    if( $long=~ m{\Q$short\E(.*)$}) {
        return XML::XPathEngine::Literal->new($1);
    }
    else {
        return XML::XPathEngine::Literal->new('');
    }
}

sub substring {
    my $self = shift;
    my ($node, @params) = @_;
    die "substring: Wrong number of parameters\n" if (@params < 2 || @params > 3);
    my ($str, $offset, $len);
    $str = $params[0]->string_value;
    $offset = $params[1]->value;
    $offset--; # uses 1 based offsets
    if (@params == 3) {
        $len = $params[2]->value;
        return XML::XPathEngine::Literal->new(substr($str, $offset, $len));
    }
    else {
        return XML::XPathEngine::Literal->new(substr($str, $offset));
    }
}

sub string_length {
    my $self = shift;
    my ($node, @params) = @_;
    die "string-length: Wrong number of params\n" if @params > 1;
    if (@params) {
        return XML::XPathEngine::Number->new(length($params[0]->string_value));
    }
    else {
        return XML::XPathEngine::Number->new(
                length($node->string_value)
                );
    }
}

sub normalize_space {
    my $self = shift;
    my ($node, @params) = @_;
    die "normalize-space: Wrong number of params\n" if @params > 1;
    my $str;
    if (@params) {
        $str = $params[0]->string_value;
    }
    else {
        $str = $node->string_value;
    }
    $str =~ s/^\s*//;
    $str =~ s/\s*$//;
    $str =~ s/\s+/ /g;
    return XML::XPathEngine::Literal->new($str);
}

sub translate {
    my $self = shift;
    my ($node, @params) = @_;
    die "translate: Wrong number of params\n" if @params != 3;
    local $_ = $params[0]->string_value;
    my $find = $params[1]->string_value;
    my $repl = $params[2]->string_value;
    $repl= substr( $repl, 0, length( $find));
    my %repl;
    @repl{split //, $find}= split( //, $repl);
    s{(.)}{exists $repl{$1} ? defined $repl{$1} ? $repl{$1} : '' : $1 }ges;
    return XML::XPathEngine::Literal->new($_);
}


### BOOLEAN FUNCTIONS ###

sub boolean {
    my $self = shift;
    my ($node, @params) = @_;
    die "boolean: Incorrect number of parameters\n" if @params != 1;
    return $params[0]->to_boolean;
}

sub not {
    my $self = shift;
    my ($node, @params) = @_;
    $params[0] = $params[0]->to_boolean unless $params[0]->isa('XML::XPathEngine::Boolean');
    $params[0]->value ? XML::XPathEngine::Boolean->False : XML::XPathEngine::Boolean->True;
}

sub true {
    my $self = shift;
    my ($node, @params) = @_;
    die "true: function takes no parameters\n" if @params > 0;
    XML::XPathEngine::Boolean->True;
}

sub false {
    my $self = shift;
    my ($node, @params) = @_;
    die "true: function takes no parameters\n" if @params > 0;
    XML::XPathEngine::Boolean->False;
}

sub lang {
    my $self = shift;
    my ($node, @params) = @_;
    die "lang: function takes 1 parameter\n" if @params != 1;
    my $lang = $node->findvalue('(ancestor-or-self::*[@xml:lang]/@xml:lang)[1]');
    my $lclang = lc($params[0]->string_value);
    # warn("Looking for lang($lclang) in $lang\n");
    if (substr(lc($lang), 0, length($lclang)) eq $lclang) {
        return XML::XPathEngine::Boolean->True;
    }
    else {
        return XML::XPathEngine::Boolean->False;
    }
}

### NUMBER FUNCTIONS ###

sub number {
    my $self = shift;
    my ($node, @params) = @_;
    die "number: Too many parameters\n" if @params > 1;
    if (@params) {
        if ($params[0]->isa('XML::XPathEngine::Node')) {
            return XML::XPathEngine::Number->new(
                    $params[0]->string_value
                    );
        }
        return $params[0]->to_number;
    }
    
    return XML::XPathEngine::Number->new( $node->string_value );
}

sub sum {
    my $self = shift;
    my ($node, @params) = @_;
    die "sum: Parameter must be a NodeSet\n" unless $params[0]->isa('XML::XPathEngine::NodeSet');
    my $sum = 0;
    foreach my $node ($params[0]->get_nodelist) {
        $sum += $self->number($node)->value;
    }
    return XML::XPathEngine::Number->new($sum);
}

sub floor {
    my $self = shift;
    my ($node, @params) = @_;
    require POSIX;
    my $num = $self->number($node, @params);
    return XML::XPathEngine::Number->new(
            POSIX::floor($num->value));
}

sub ceiling {
    my $self = shift;
    my ($node, @params) = @_;
    require POSIX;
    my $num = $self->number($node, @params);
    return XML::XPathEngine::Number->new(
            POSIX::ceil($num->value));
}

sub round {
    my $self = shift;
    my ($node, @params) = @_;
    my $num = $self->number($node, @params);
    require POSIX;
    return XML::XPathEngine::Number->new(
            POSIX::floor($num->value + 0.5)); # Yes, I know the spec says don't do this...
}

1;
