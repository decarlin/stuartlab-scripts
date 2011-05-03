package Graph::Undirected;

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
#	$U = Graph::Undirected->new(@V)
#
#	The Constructor.  Returns a new undirected graph $U, possibly
#	populated with the optional initial vertices @V.
#
sub new {
    my $class = shift;

    my $G = Graph::Base->new(@_);

    bless $G, $class;

    $G->directed(0);

    return $G;
}

sub stringify {
    my $G = shift;

    return $G->_stringify("=", ",");
}

sub eq {
    my ($G, $H) = @_;
    
    return ref $H ? $G->stringify eq $H->stringify : $G->stringify eq $H;
}

# _edges
#
#	@e = $G->_edges($u, $v, $E)
#
#	(INTERNAL USE ONLY)
#	Both vertices undefined:
#		returns all the edges of the graph.
#	Both vertices defined:
#		returns all the edges between the vertices.
#	Only 1st vertex defined:
#		returns all the edges at the vertex.
#	Only 2nd vertex defined:
#		returns all the edges at the vertex.
#	The already seen vertices are recorded in $E.
#	Edges @e are returned as ($start_vertex, $end_vertex) pairs.
#
sub _edges {
    my ($G, $u, $v, $E) = @_;
    my @e;

    $E = { } unless defined $E;

    if (defined $u and defined $v) {
	if (exists $G->{ Succ }->{ $u }->{ $v }) {
	    @e = ($u, $v)
		if not $E->{ $u }->{ $v } and
		   not $E->{ $v }->{ $u };
	    $E->{ $u }->{ $v } = $E->{ $v }->{ $u } = 1;
	}
    } elsif (defined $u) {
	foreach $v ($G->successors($u)) {
	    push @e, $G->_edges($u, $v);
	}
    } elsif (defined $v) {
	foreach $u ($G->predecessors($v)) {
	    push @e, $G->_edges($u, $v);
	}
    } else {
	foreach $u ($G->vertices) {
	    push @e, $G->_edges($u);
	}
    }

    return @e;
}

1;
