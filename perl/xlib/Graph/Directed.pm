package Graph::Directed;

use strict;
local $^W = 1;

use Graph::Base;

use vars qw(@ISA);
@ISA = qw(Graph::Base);

use overload '""' => \&stringify;

=head1 NAME

Graph::Directed - directed graphs

=head1 SYNOPSIS

    use Graph::Directed;

    $g = new Graph::Directed;

=head1 DESCRIPTION

See Graph::Base for the available methods.

=head1 COPYRIGHT

Copyright 1999, O'Reilly & Associates.

This code is distributed under the same copyright terms as Perl itself.

=cut

# new
#
#	$D = Graph::Directed->new(@V)
#
#	The Constructor.  Returns a new directed graph $D, possibly
#	populated with the optional initial vertices @V.
#
sub new {
    my $class = shift;

    my $G = Graph::Base->new(@_);

    bless $G, $class;

    $G->directed(1);

    return $G;
}

# _edges
#
#	@e = $G->_edges($u, $v)
#
#	(INTERNAL USE ONLY)
#	Both vertices undefined:
#		returns all the edges of the graph.
#	Both vertices defined:
#		returns all the edges between the vertices.
#	Only 1st vertex defined:
#		returns all the edges leading out of the vertex.
#	Only 2nd vertex defined:
#		returns all the edges leading into the vertex.
#	Edges @e are returned as ($start_vertex, $end_vertex) pairs.
#
sub _edges {
    my ($G, $u, $v) = @_;
    my @e;

    if (defined $u and defined $v) {
	@e = ($u, $v)
	    if exists $G->{ Succ }->{ $u }->{ $v };
    } elsif (defined $u) {
	foreach $v ($G->successors($u)) {
	    push @e, $G->_edges($u, $v);
	}
    } elsif (defined $v) {	# not defined $u and defined $v
	foreach $u ($G->predecessors($v)) {
	    push @e, $G->_edges($u, $v);
	}
    } else { 			# not defined $u and not defined $v
	foreach $u ($G->vertices) {
	    push @e, $G->_edges($u);
	}
    }

    return @e;
}

sub stringify {
    my $G = shift;

    return $G->_stringify("-", ",");
}

1;
