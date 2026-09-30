# $Id: Variable.pm,v 1.5 2001/03/16 11:10:08 matt Exp $

package XML::XPathEngine::Variable;
use strict;

# This class does NOT contain 1 instance of a variable
# see the XML::XPathEngine::Parser class for the instances
# This class simply holds the name of the var

sub new {
    my $class = shift;
    my ($pp, $name) = @_;
    bless { name => $name, path_parser => $pp }, $class;
}

sub as_string {
    my $self = shift;
    '\$' . $self->{name};
}

sub as_xml {
    my $self = shift;
    return "<Variable>" . $self->{name} . "</Variable>\n";
}

sub get_value {
    my $self = shift;
    $self->{path_parser}->get_var($self->{name});
}

sub set_value {
    my $self = shift;
    my ($val) = @_;
    $self->{path_parser}->set_var($self->{name}, $val);
}

sub evaluate {
    my $self = shift;
    my $val = $self->get_value;
    return $val;
}

1;
