package Graph::Base;

use strict;
local $^W = 1;

use vars qw(@ISA);

=head1 NAME

Graph::Base - graph base class

=head1 SYNOPSIS

    use Graph::Directed;
    use Graph::Undirected;

    $d1 = new Graph;
    $d2 = new Graph::Directed;
    $u  = new Graph::Undirected;

=head1 DESCRIPTION

You create new graphs by calling the C<new> constructors of classes
C<Graph>, C<Graph::Directed>, and C<Graph::Undirected>.  The classes
C<Graph> and C<Graph::Directed> are identical.  After creating the
graph you can modify and explore the graph with following methods.

=over 4

=cut

require Exporter;
@ISA = qw(Exporter);

=pod
=item new

	$G = Graph->new(@V)

Returns a new graph $G with the optional vertices @V.

=cut
sub new {
   my $class = shift;

   my $G = { };

   bless $G, $class;

   $G->add_vertices(@_) if @_;

   return $G;
}

=pod
=item add_vertices

	$G = $G->add_vertices(@v)

Adds the vertices to the graph $G, returns the graph.

=cut
sub add_vertices {
    my ($G, @v) = @_;

    @{ $G->{ V } }{ @v } = @v;

    return $G;
}

=pod
=item add_vertex

	$G = $G->add_vertex($v)

Adds the vertex $v to the graph $G, returns the graph.

=cut
sub add_vertex {
    my ($G, $v) = @_;

    return $G->add_vertices($v);
}

=pod
=item vertices

	@V = $G->vertices

In list context returns the vertices @V of the graph $G.
In scalar context returns the number of the vertices.

=cut
sub vertices {
    my $G = shift;
    my @V = exists $G->{ V } ? sort values %{ $G->{ V } } : ();

    return @V;
}

=pod
=item has_vertices

	$G->has_vertices(@v)

In list context returns a list which contains the vertex
of the vertices @v if the vertex exists in the graph $G
and undef if it doesn't.  In scalar context returns the
number of the existing vertices.

=cut
sub has_vertices {
    my $G = shift;

    return wantarray ?
	map  { exists $G->{ V }->{ $_ } ? $_ : undef } @_ :
        grep { exists $G->{ V }->{ $_ }              } @_ ;
}

=pod
=item has_vertex

	$b = $G->has_vertex($v)

Returns true if the vertex $v exists in
the graph $G and false if it doesn't.

=cut
sub has_vertex {
    my ($G, $v) = @_;

    return exists $G->{V}->{ $v };
}

=pod
=item vertex

	$v = $G->has_vertex($v)

Returns the vertex $v if the vertex exists in the graph $G
or undef if it doesn't.

=cut
sub vertex {
    my ($G, $v) = @_;

    return $G->{ V }->{ $v };
}

=pod
=item directed

	$b = $G->directed($d)

Set the directedness of the graph $G to $d or return the
current directedness.  Directedness defaults to true.

=cut
sub directed {
    my ($G, $d) = @_;

    if (defined $d) {
	if ($d) {
	    my $o = $G->{ D }; # Old directedness.

	    $G->{ D } = $d;
	    if (not $o) {
		my @E = $G->edges;

		while (my ($u, $v) = splice(@E, 0, 2)) {
		    $G->add_edge($v, $u);
		}
	    }

	    return bless $G, 'Graph::Directed'; # Re-bless.
	} else {
	    return $G->undirected(not $d);
	}
    }

    return $G->{ D };
}

=pod
=item undirected

	$b = $G->undirected($d)

Set the undirectedness of the graph $G to $u or return the
current undirectedness.  Undirectedness defaults to false.

=cut
sub undirected {
    my ($G, $u) = @_;

    $G->{ D } = 1 unless defined $G->{ D };

    if (defined $u) {
	if ($u) {
	    my $o = $G->{ D }; # Old directedness.

	    $G->{ D } = not $u;
	    if ($o) {
		my @E = $G->edges;
		my %E;

		while (my ($u, $v) = splice(@E, 0, 2)) {
		    # Throw away duplicate edges.
		    $G->delete_edge($u, $v) if exists $E{$v}->{$u};
		    $E{$u}->{$v}++;
		}
	    }

	    return bless $G, 'Graph::Undirected'; # Re-bless.
	} else {
	    return $G->directed(not $u);
	}
    }

    return not $G->{ D };
}

=pod
=item has_edge

	$b = $G->has_edge($u, $v)

Return true if the graph $G has the edge between
the vertices $u, $v.

=cut
sub has_edge {
    my ($G, $u, $v) = @_;

    return exists $G->{ Succ }->{ $u }->{ $v } ||
           ($G->undirected && exists $G->{ Succ }->{ $v }->{ $u });
}

=pod
=item has_edges

	$G->has_edges($u1, $v1, $u2, $v2, ...)

In list context returns a list which contains true for each
edge in the graph $G defined by the vertices $u1, $v1, ...,
and false for each non-existing edge.  In scalar context
returns the number of the existing edges.

=cut
sub has_edges {
    my $G = shift;
    my @e;

    while (my ($u, $v) = splice(@_, 0, 2)) {
	push @e, $G->has_edge($u, $v);
    }

    return wantarray ? @e : grep { $_ } @e;
}

=pod
=item has_path

	$G->has_path($u, $v, ...)

Return true if the graph $G has the cycle defined by
the vertices $u, $v, ..., false otherwise.

=cut
sub has_path {
    my $G = shift;
    my $u = shift;

    while (my $v = shift) {
	return 0 unless $G->has_edge($u, $v);
	$u = $v;
    }

    return 1;
}

=pod
=item has_cycle

	$G->has_cycle($u, $v, ...)

Return true if the graph $G has the cycle defined by
the vertices $u, $v, ...,false otherwise.

=cut
sub has_cycle {
    my $G = shift;

    return $G->has_path(@_, $_[0]); # Just wrap around.
}

# _union_vertex_set
#
#	$G->_union_vertex_set($u, $v)
#
#	(INTERNAL USE ONLY)
#	Adds the vertices $u and $v in the graph $G to the same vertex set.
#
sub _union_vertex_set {
    my ($G, $u, $v) = @_;

    my $su = $G->vertex_set( $u );
    my $sv = $G->vertex_set( $v );
    my $ru = $G->{ VertexSetRank }->{ $su };
    my $rv = $G->{ VertexSetRank }->{ $sv };

    if ( $ru < $rv ) {	# Union by rank (weight balancing).
	$G->{ VertexSetParent }->{ $su } = $sv;
    } else {
	$G->{ VertexSetParent }->{ $sv } = $su;
	$G->{ VertexSetRank   }->{ $sv }++ if $ru == $rv;
    }
}

=pod
=item vertex_set

	$s = $G->vertex_set($v)

Returns the vertex set of the vertex $v in the graph $G.
A "vertex set" is represented by its parent vertex.

=cut
sub vertex_set {
    my ($G, $v) = @_;

    if ( exists  $G->{ VertexSetParent }->{ $v } ) {
	# Path compression.
	$G->{ VertexSetParent }->{ $v } =
	  $G->vertex_set( $G->{ VertexSetParent }->{ $v } )
	    if $v ne $G->{ VertexSetParent }->{ $v };
    } else {
	$G->{ VertexSetParent }->{ $v } = $v;
	$G->{ VertexSetRank   }->{ $v } = 0;
    }

    return $G->{ VertexSetParent }->{ $v };
}

=pod
=item add_edge

	$G = $G->add_edge($u, $v)

Adds the edge defined by the vertices $u, $v, to the graph $G.
Also implicitly adds the vertices.  Returns the graph.

=cut
sub add_edge {
    my ($G, $u, $v) = @_;

    $G->add_vertex($u);
    $G->add_vertex($v);
    $G->_union_vertex_set( $u, $v );
    push @{ $G->{ Succ }->{ $u }->{ $v } }, $v;
    push @{ $G->{ Pred }->{ $v }->{ $u } }, $u;

    return $G;
}

=pod
=item add_edges

	$G = $G->add_edges($u1, $v1, $u2, $v2, ...)

Adds the edge defined by the vertices $u1, $v1, ...,
to the graph $G.  Also implicitly adds the vertices.
Returns the graph.

=cut
sub add_edges {
    my $G = shift;

    while (my ($u, $v) = splice(@_, 0, 2)) {
	$G->add_edge($u, $v);
    }

    return $G;
}

=pod
=item add_path

	$G->add_path($u, $v, ...)

Adds the path defined by the vertices $u, $v, ...,
to the graph $G.   Also implicitly adds the vertices.
Returns the graph.

=cut
sub add_path {
    my $G = shift;
    my $u = shift;

    while (my $v = shift) {
	$G->add_edge($u, $v);
	$u = $v;
    }

    return $G;
}

=pod
=item add_cycle

	$G = $G->add_cycle($u, $v, ...)

Adds the cycle defined by the vertices $u, $v, ...,
to the graph $G.  Also implicitly adds the vertices.
Returns the graph.

=cut
sub add_cycle {
    my $G = shift;

    $G->add_path(@_, $_[0]); # Just wrap around.
}


# _successors
#
#	@s = $G->_successors($v)
#
#	(INTERNAL USE ONLY, use only on directed graphs)
#	Returns the successor vertices @s of the vertex
#	in the graph $G.
#
sub _successors {
    my ($G, $v) = @_;

    my @s =
	defined $G->{ Succ }->{ $v } ?
	    map { @{ $G->{ Succ }->{ $v }->{ $_ } } }
                sort keys %{ $G->{ Succ }->{ $v } } :
            ( );

    return @s;
}

# _predecessors
#
#	@p = $G->_predecessors($v)
#
#	(INTERNAL USE ONLY, use only on directed graphs)
#	Returns the predecessor vertices @p of the vertex $v
#	in the graph $G.
#
sub _predecessors {
    my ($G, $v) = @_;

    my @p =
	defined $G->{ Pred }->{ $v } ?
	    map { @{ $G->{ Pred }->{ $v }->{ $_ } } }
                sort keys %{ $G->{ Pred }->{ $v } } :
            ( );

    return @p;
}

=pod
=item neighbors

	@n = $G->neighbors($v)

Returns the neighbor vertices of the vertex in the graph.
(Also 'neighbours' works.)

=cut
sub neighbors {
    my ($G, $v) = @_;

    my @n = ($G->_successors($v), $G->_predecessors($v));

    return @n;
}

use vars '*neighbours';
*neighbours = \&neighbors; # Keep both sides of the Atlantic happy.

=pod
=item successors

	@s = $G->successors($v)

Returns the successor vertices of the vertex in the graph.

=cut
sub successors {
    my ($G, $v) = @_;

    return $G->directed ? $G->_successors($v) : $G->neighbors($v);
}

=pod
=item predecessors

	@p = $G->predecessors($v)

Returns the predecessor vertices of the vertex in the graph.

=cut
sub predecessors {
    my ($G, $v) = @_;

    return $G->directed ? $G->_predecessors($v) : $G->neighbors($v);
}

=pod
=item out_edges

	@e = $G->out_edges($v)

Returns the edges leading out of the vertex $v in the graph $G.
In list context returns the edges as ($start_vertex, $end_vertex)
pairs.  In scalar context returns the number of the edges.

=cut
sub out_edges {
    my ($G, $v) = @_;

    return () unless $G->has_vertex($v);

    my @e = $G->_edges($v, undef);

    return wantarray ? @e : @e / 2;
}

=pod
=item in_edges

	@e = $G->in_edges($v)

Returns the edges leading into the vertex $v in the graph $G.
In list context returns the edges as ($start_vertex, $end_vertex)
pairs; in scalar context returns the number of the edges.

=cut
sub in_edges {
    my ($G, $v) = @_;

    return () unless $G->has_vertex($v);

    my @e = $G->_edges(undef, $v);

    return wantarray ? @e : @e / 2;
}

=pod
=item edges

	@e = $G->edges($u, $v)

Returns the edges between the vertices $u and $v, or if $v
is undefined, the edges leading into or out of the vertex $u,
or if $u is undefined, returns all the edges, of the graph $G.
In list context returns the edges as a list of
$start_vertex, $end_vertex pairs; in scalar context
returns the number of the edges.

=cut
sub edges {
    my ($G, $u, $v) = @_;

    return () if defined $v and not $G->has_vertex($v);

    my @e =
	defined $u ?
	    ( defined $v ?
	      $G->_edges($u, $v) :
              ($G->in_edges($u), $G->out_edges($u)) ) :
	    $G->_edges;

    return wantarray ? @e : @e / 2;
}

=pod
=item delete_edge

	$G = $G->delete_edge($u, $v)

Deletes an edge defined by the vertices $u, $v from the graph $G.
Note that the edge need not actually exist.
Returns the graph.

=cut
sub delete_edge {
    my ($G, $u, $v) = @_;

    pop @{ $G->{ Succ }->{ $u }->{ $v } };
    pop @{ $G->{ Pred }->{ $v }->{ $u } };

    delete $G->{ Succ }->{ $u }->{ $v }
        unless @{ $G->{ Succ }->{ $u }->{ $v } };
    delete $G->{ Pred }->{ $v }->{ $u }
        unless @{ $G->{ Pred }->{ $v }->{ $u } };

    delete $G->{ Succ }->{ $u }
        unless keys %{ $G->{ Succ }->{ $u } };
    delete $G->{ Pred }->{ $v }
        unless keys %{ $G->{ Pred }->{ $v } };

    return $G;
}

=pod
=item delete_edges

	$G = $G->delete_edges($u1, $v1, $u2, $v2, ..)

Deletes edges defined by the vertices $u1, $v1, ...,
from the graph $G.
Note that the edges need not actually exist.
Returns the graph.

=cut
sub delete_edges {
    my $G = shift;

    while (my ($u, $v) = splice(@_, 0, 2)) {
	if (defined $v) {
	    $G->delete_edge($u, $v);
	} else {
	    my @e = $G->edges($u);

	    while (($u, $v) = splice(@e, 0, 2)) {
		$G->delete_edge($u, $v);
	    }
	}
    }

    return $G;
}

=pod
=item delete_path

	$G = $G->delete_path($u, $v, ...)

Deletes a path defined by the vertices $u, $v, ..., from the graph $G.
Note that the path need not actually exist. Returns the graph.

=cut
sub delete_path {
    my $G = shift;
    my $u = shift;

    while (my $v = shift) {
	$G->delete_edge($u, $v);
	$u = $v;
    }

    return $G;
}

=pod
=item delete_cycle

	$G = $G->delete_cycle($u, $v, ...)

Deletes a cycle defined by the vertices $u, $v, ..., from the graph $G.
Note that the cycle need not actually exist. Returns the graph.

=cut
sub delete_cycle {
    my $G = shift;

    $G->delete_path(@_, $_[0]); # Just wrap around.
}

=pod
=item delete_vertex

	$G = $G->delete_vertex($v)

Deletes the vertex $v and all its edges from the graph $G.
Note that the vertex need not actually exist.
Returns the graph.

=cut
sub delete_vertex {
    my ($G, $v) = @_;

    $G->delete_edges($v);

    delete $G->{ V }->{ $v };

    return $G;
}

=pod
=item delete_vertices

	$G = $G->delete_vertices(@v)

Deletes the vertices @v and all their edges from the graph $G.
Note that the vertices need not actually exist.
Returns the graph.

=cut
sub delete_vertices {
    my $G = shift;

    foreach my $v (@_) {
	$G->delete_vertex($v);
    }

    return $G;
}

=pod
=item in_degree

	$d = $G->in_degree($v)

Returns the in-degree of the vertex $v in the graph $G,
or, if $v is undefined, the total in-degree of all the
vertices of the graph, or undef if the vertex doesn't
exist in the graph.

=cut
sub in_degree {
    my ($G, $v) = @_;

    return undef unless $G->has_vertex($v);

    if ($G->directed) {
	if (defined $v) {
	    return scalar $G->in_edges($v);
	} else {
	    my $in = 0;
	
	    foreach my $v ($G->vertices) {
		$in += $G->in_degree($v);
	    }
	
	    return $in;
	}
    } else {
	return scalar $G->edges($v);
    }
}

=pod
=item out_degree

	$d = $G->out_degree($v)

Returns the out-degree of the vertex $v in the graph $G,
or, if $v is undefined, the total out-degree of all the
vertices of the graph, of undef if the vertex doesn't
exist in the graph.

=cut
sub out_degree {
    my ($G, $v) = @_;

    return undef unless $G->has_vertex($v);

    if ($G->directed) {
	if (defined $v) {
	    return scalar $G->out_edges($v);
	} else {
	    my $out = 0;
	
	    foreach my $v ($G->vertices) {
		$out += $G->out_degree($v);
	    }
	
	    return $out;
	}
    } else {
	return scalar $G->edges($v);
    }
}

=pod
=item degree

	$d = $G->degree($v)

Returns the degree of the vertex $v in the graph $G
or, if $v is undefined, the total degree of all the
vertices of the graph, or undef if the vertex $v
doesn't exist in the graph.

=cut
sub degree {
    my ($G, $v) = @_;

    if (defined $v) {
	return undef unless $G->has_vertex($v);

	if ($G->directed) {
	    return $G->in_degree($v) - $G->out_degree($v);
	} else {
	    return $G->edges($v);
	}
    } else {
	if ($G->directed) {
	    return 0;
	} else {
	    my $deg = 0;
	
	    foreach my $v ($G->vertices) {
		$deg += $G->degree($v);
	    }
	
	    return $deg;
	}
    }
}

=pod
=item average_degree

	$d = $G->average_degree

Returns the average degree of the vertices of the graph $G.

=cut
sub average_degree {
    my $G = shift;
    my $V = $G->vertices;

    return $V ? $G->degree / $V : 0;
}

=pod
=item is_source_vertex

	$b = $G->is_source_vertex($v)

Returns true if the vertex $v is a source vertex of the graph $G.

=cut
sub is_source_vertex {
    my ($G, $v) = @_;

    $G->in_degree($v) == 0 && $G->out_degree($v) >  0;
}

=pod
=item is_sink_vertex

	$b = $G->is_sink_vertex($v)

Returns true if the vertex $v is a sink vertex of the graph $G.

=cut
sub is_sink_vertex {
    my ($G, $v) = @_;

    $G->in_degree($v) >  0 && $G->out_degree($v) == 0;
}

=pod
=item is_isolated_vertex

	$b = $G->is_isolated_vertex($v)

Returns true if the vertex $v is a isolated vertex of the graph $G.

=cut
sub is_isolated_vertex {
    my ($G, $v) = @_;

    $G->in_degree($v) == 0 && $G->out_degree($v) == 0;
}

=pod
=item is_exterior_vertex

	$b = $G->is_exterior_vertex($v)

Returns true if the vertex $v is a exterior vertex of the graph $G.

=cut
sub is_exterior_vertex {
    my ($G, $v) = @_;

    $G->in_degree($v) == 0 xor $G->out_degree($v) == 0;
}

=pod
=item is_interior_vertex

	$b = $G->is_interior_vertex($v)

Returns true if the vertex $v is a interior vertex of the graph $G.

=cut
sub is_interior_vertex {
    my ($G, $v) = @_;

    $G->in_degree($v)      && $G->out_degree($v);
}

=pod
=item is_self_loop_vertex

	$b = $G->is_self_loop_vertex($v)

Returns true if the vertex $v is a self-loop vertex of the graph $G.

=cut
sub is_self_loop_vertex {
    my ($G, $v) = @_;

    exists $G->{ Succ }->{ $v }->{ $v };
}

=pod
=item source_vertices

	@s = $G->source_vertices

Returns the source vertices @s of the graph $G.

=cut
sub source_vertices {
    my $G = shift;

    return grep { $G->is_source_vertex($_) } $G->vertices;
}

=pod
=item sink_vertices

	@s = $G->sink_vertices

Returns the sink vertices @s of the graph $G.

=cut
sub sink_vertices {
    my $G = shift;

    return grep { $G->is_sink_vertex($_) } $G->vertices;
}

=pod
=item isolated_vertices

	@i = $G->isolated_vertices

Returns the isolated vertices @i of the graph $G.

=cut
sub isolated_vertices {
    my $G = shift;

    return grep { $G->is_isolated_vertex($_) } $G->vertices;
}

=pod
=item exterior_vertices

	@e = $G->exterior_vertices

Returns the exterior vertices @e of the graph $G.

=cut
sub exterior_vertices {
    my $G = shift;

    return grep { $G->is_exterior_vertex($_) } $G->vertices;
}

=pod
=item interior_vertices

	@i = $G->interior_vertices

Returns the interior vertices @i of the graph $G.

=cut
sub interior_vertices {
    my $G = shift;

    return grep { $G->is_interior_vertex($_) } $G->vertices;
}

=pod
=item self_loop_vertices

	@s = $G->self_loop_vertices

Returns the self-loop vertices @s of the graph $G.

=cut
sub self_loop_vertices {
    my $G = shift;

    return grep { $G->is_self_loop_vertex($_) } $G->vertices;
}

=pod
=item density_limits

	($sparse, $dense, $complete) = $G->density_limits

Returns the density limits for the number of edges
in the graph $G.  Note that reaching $complete edges
does not really guarantee completeness because we
can have multigraphs.  The limit of sparse is less
than 1/4 of the edges of the complete graph, the
limit of dense is more than 3/4 of the edges of the
complete graph.

=cut
sub density_limits {
    my $G = shift;

    my $V = $G->vertices;
    my $M = $V * ($V - 1);

    $M = $M / 2 if $G->undirected;

    return ($M/4, 3*$M/4, $M);
}

=pod
=item density

	$d = $G->density

Returns the density $d of the graph $G.

=cut
sub density {
    my $G = shift;
    my ($sparse, $dense, $complete) = $G->density_limits;

    return $complete ? $G->edges / $complete : 0;
}

=pod
=item is_sparse

	$d = $G->is_sparse

Returns true if the graph $G is sparse.

=cut
sub is_sparse {
    my $G = shift;
    my ($sparse, $dense, $complete) = $G->density_limits;

    return $complete ? $G->edges / $complete <= $dense : 1;
}

=pod
=item is_dense

	$d = $G->is_dense

Returns true if the graph $G is dense.

=cut
sub is_dense {
    my $G = shift;
    my ($sparse, $dense, $complete) = $G->density_limits;

    return $complete ? $G->edges / $complete >= $dense : 0;
}

=pod
=item complete

	$C = $G->complete;

Returns a new complete graph $C corresponding to the graph $G.

=cut
sub complete {
    my $G = shift;
    my $C = (ref $G)->new;
    my @V = $G->vertices;

    if ($G->directed) {
	foreach my $u (@V) {
	    foreach my $v (@V) {
		$C->add_edge($u, $v) unless $u eq $v;
	    }
	}
    } else {
	my %E;

	foreach my $u (@V) {
	    foreach my $v (@V) {
		next if $u eq $v or $E{$u}->{$v} || $E{$v}->{$u};
		$C->add_edge($u, $v);
		$E{$u}->{$v}++;
		$E{$v}->{$u}++;
	    }
	}
    }

    $C->directed($G->directed);

    return $C;
}

=pod
=item complement

	$C = $G->complement;

Returns a new complement graph $C corresponding to the graph $G.

=cut
sub complement {
    my $G = shift;
    my $C = $G->complete;

    if (my @E = $G->edges) {
	while (my ($u, $v) = splice(@E, 0, 2)) {
	    $C->delete_edge($u, $v);
	}
    }

    return $C;
}

=pod
=item copy

	$C = $G->copy;

Returns a new graph $C corresponding to the graph $G.

=cut
sub copy {
    my $G = shift;
    my $C = (ref $G)->new($G->vertices);

    if (my @E = $G->edges) {
	while (my ($u, $v) = splice(@E, 0, 2)) {
	    $C->add_edge($u, $v);
	}
    }

    $C->directed($G->directed);

    return $C;
}

=pod
=item transpose

	$T = $G->transpose;

Returns a new transpose graph $T corresponding to the graph $G.

=cut
sub transpose {
    my $G = shift;

    return $G->copy if $G->undirected;

    my $T = (ref $G)->new($G->vertices);

    if (my @E = $G->edges) {
	while (my ($u, $v) = splice(@E, 0, 2)) {
	    $T->add_edge($v, $u);
	}
    }

    return $T;
}

# _stringify
#
#	$s = $G->_stringify($connector, $separator)
#
#	(INTERNAL USE ONLY)
#	Returns a string representation of the graph $G.
#	The edges are represented by $connector and edges/isolated
#	vertices are represented by $separator.
#
sub _stringify {
    my ($G, $connector, $separator) = @_;
    my @E = $G->edges;
    my @e = map { [ $_ ] } $G->isolated_vertices;

    while (my ($u, $v) = splice(@E, 0, 2)) {
	push @e, [$u, $v];
    }

    return join($separator,
               map { @$_ == 2 ?
                         join($connector, $_->[0], $_->[1]) :
                         $_->[0] }
                   sort { $a->[0] cmp $b->[0] || @$a <=> @$b } @e);
}

=pod
=item set_attribute

	$G->set_attribute($attribute, $value)
	$G->set_attribute($attribute, $v, $value)
	$G->set_attribute($attribute, $u, $v, $value)

Sets the $attribute of graph/vertex/edge to $value
but only if the vertex/edge already exists.  Returns
true if the attribute is set successfully, false if not.

=cut
sub set_attribute {
    my $G         = shift;
    my $attribute = shift;
    my $value     = pop;
    my ($u, $v)   = @_;

    if (defined $u) {
	return 0 unless $G->has_vertex($u);
	if (defined $v) {
	    return 0 unless $G->has_edge($u, $v);
	    $G->{ Attr }->{ E }->{ $u }->{ $v }->{ $attribute } = $value;
	    $G->{ Attr }->{ E }->{ $v }->{ $u }->{ $attribute } = $value
	        if $G->undirected;
	} else {
	    $G->{ Attr }->{ V }->{ $u }->{ $attribute }         = $value;
	}
    } else {
	$G->{ Attr }->{ G }->{ $attribute }                     = $value;
    }

    return 1;
}

=pod
=item get_attribute

	$value = $G->get_attribute($attribute)
	$value = $G->get_attribute($attribute, $v)
	$value = $G->get_attribute($attribute, $u, $v)

Returns the $value of $attribute of graph/vertex/edge.

=cut
sub get_attribute {
    my $G         = shift;
    my $attribute = shift;
    my ($u, $v)   = @_;

    if (defined $u) {
	if (defined $v) {
	    return undef
	        unless exists $G->{ Attr }->{ E };

	    my $E = $G->{ Attr }->{ E };

	    if ( $G->directed ) {
	        return $E->{ $u }->{ $v }->{ $attribute };
	    } else {
	        return undef
		    unless exists $G->{ Attr }->{ E };

	        return $E->{ $u }->{ $v }->{ $attribute }
		    if exists $E->{ $u }->{ $v }->{ $attribute };

	        return $E->{ $v }->{ $u }->{ $attribute };
	    }
	} else {
	    return $G->{ Attr }->{ V }->{ $u }->{ $attribute };
	}
    } else {
	return $G->{ Attr }->{ G }->{ $attribute };
    }
}

=pod
=item has_attribute

	$value = $G->has_attribute($attribute)
	$value = $G->has_attribute($attribute, $v)
	$value = $G->has_attribute($attribute, $u, $v)

Returns the $value of $attribute of graph/vertex/edge.

=cut
sub has_attribute {
    my $G         = shift;
    my $attribute = shift;
    my ($u, $v)   = @_;

    if (defined $u) {
	if (defined $v) {
	    return undef
	        unless exists $G->{ Attr }->{ E };

	    my $E = $G->{ Attr }->{ E };

	    if ( $G->directed ) {
	        return exists $E->{ $u }->{ $v }->{ $attribute };
	    } else {
		return exists $E->{ $u }->{ $v }->{ $attribute } or
		    exists $E->{ $v }->{ $u }->{ $attribute };
	    }
	} else {
	    exists $G->{ Attr }->{ V }->{ $u }->{ $attribute };
	}
    } else {
	exists $G->{ Attr }->{ G }->{ $attribute };
    }
}

=pod
=item get_attributes

	%attributes = $G->get_attributes()
	%attributes = $G->get_attributes($v)
	%attributes = $G->get_attributes($u, $v)

Returns as a hash all the attribute names and values
of graph/vertex/edge.

=cut
sub get_attributes {
    my $G       = shift;
    my ($u, $v) = @_;

    return ( ) unless exists $G->{ Attr };
    if (defined $u) {
	if (defined $v) {
	    return exists $G->{ Attr }->{ E } &&
                   exists $G->{ Attr }->{ E }->{ $u } &&
                   exists $G->{ Attr }->{ E }->{ $u }->{ $v } ?
                              %{ $G->{ Attr }->{ E }->{ $u }->{ $v } } :
                              ( );
	} else {
	    return exists $G->{ Attr }->{ V } &&
                   exists $G->{ Attr }->{ V }->{ $u } ?
                       %{ $G->{ Attr }->{ V }->{ $u } } : ( );
	}
    } else {
	return exists $G->{ Attr }->{ G } ?
                   %{ $G->{ Attr }->{ G } } : ( );
    }
}

=pod
=item delete_attribute

	$G->delete_attribute($attribute)
	$G->delete_attribute($attribute, $v)
	$G->delete_attribute($attribute, $u, $v)

Deletes the $attribute of graph/vertex/edge.

=cut
sub delete_attribute {
    my $G         = shift;
    my $attribute = shift;
    my ($u, $v)   = @_;

    if (defined $u) {
	if (defined $v) {
	    return undef
	        unless exists $G->{ Attr }->{ E };

	    my $E = $G->{ Attr }->{ E };

	    if ( $G->directed ) {
	        delete $E->{ $u }->{ $v }->{ $attribute };
	    } else {
	        delete $E->{ $v }->{ $u }->{ $attribute };
	        delete $E->{ $v }->{ $u }->{ $attribute };
	    }
	} else {
	    delete $G->{ Attr }->{ V }->{ $u }->{ $attribute };
	}
    } else {
	delete $G->{ Attr }->{ G }->{ $attribute };
    }
}

=pod
=item delete_attributes

	$G->delete_attributes()
	$G->delete_attributes($v)
	$G->delete_attributes($u, $v)

Deletes all the attributes of graph/vertex/edge.

=cut
sub delete_attributes {
    my $G       = shift;
    my ($u, $v) = @_;

    if (defined $u) {
	if (defined $v) {
	    delete $G->{ Attr }->{ E }->{ $u }->{ $v };
	} else {
	    delete $G->{ Attr }->{ V }->{ $u };
	}
    } else {
	delete $G->{ Attr }->{ G };
    }
}

=pod
=item add_weighted_edge

	$G->add_weighted_edge($u, $w, $v, $a)

Adds in the graph $G an edge from vertex $u to vertex $v
and the edge attribute 'weight' set to $w.

=cut
sub add_weighted_edge {
    my ($G, $u, $w, $v, $a) = @_;

    $G->add_edge($u, $v);
    $G->set_attribute('weight', $u, $v, $w);
}

=pod
=item add_weighted_edges

	$G->add_weighted_edges($u1, $w1, $v1, $u2, $w2, $v2, ...)

Adds in the graph $G the weighted edges.

=cut
sub add_weighted_edges {
    my $G = shift;

    while (my ($u, $w, $v) = splice(@_, 0, 3)) {
        $G->add_weighted_edge($u, $w, $v);
    }
}

=pod
=item add_weighted_path

	$G->add_weighted_path($v1, $w1, $v2, $w2, ..., $wnm1, $vn)

Adds in the graph $G the n edges defined by the path $v1 ... $vn
with the n-1 'weight' attributes $w1 ... $wnm1

=cut
sub add_weighted_path {
    my $G = shift;
    my $u = shift;

    while (my ($w, $v) = splice(@_, 0, 2)) {
	$G->add_weighted_edge($u, $w, $v);
	$u = $v;
    }
}

=pod
=item MST_Kruskal

	$MST = $G->MST_Kruskal;

Returns Kruskal's Minimum Spanning Tree (as a graph) of
the graph $G based on the 'weight' attributes of the edges.
(Needs the ->vertex_set() method.)

=cut
sub MST_Kruskal {
    my $G   = shift;
    my $MST = (ref $G)->new;
    my @E   = $G->edges;
    my (@W, $u, $v, $w);

    while (($u, $v) = splice(@E, 0, 2)) {
	$w = $G->get_attribute('weight', $u, $v);
	next unless defined $w; # undef weight == infinitely heavy
	push @W, [ $u, $v, $w ];
    }

    $MST->directed( $G->directed );

    # Sort by weights.
    foreach my $e ( sort { $a->[ 2 ] <=> $b->[ 2 ] } @W ) {
	($u, $v, $w) = @$e;
	$MST->add_weighted_edge( $u, $w, $v )
	    unless $MST->vertex_set( $u ) eq $MST->vertex_set( $v );
    }

    return $MST;
}

=pod
=item edge_classify

	@C = $G->edge_classify(%param)

Returns the edge classification as a list where each element
is a triplet [$u, $v, $class] the $u, $v being the vertices
of an edge and $class being the class.  The %param can be
used to control the search.

=cut
sub edge_classify {
    my $G = shift;

    my $unseen_successor =
	sub {
	    my ($u, $v, $T) = @_;
		
	    # Freshly seen successors make for tree edges.
	    push @{ $T->{ edge_class_list } },
	         [ $u, $v, 'tree' ];
	};
    my $seen_successor =
	sub {
	    my ($u, $v, $T) = @_;
			
	    my $class;
	
	    if ( $T->{ G }->directed ) {
		$class = 'cross'; # Default for directed non-tree edges.

		unless ( exists $T->{ vertex_finished }->{ $v } ) {
		    $class = 'back';
		} elsif ( $T->{ vertex_found }->{ $u } <
			  $T->{ vertex_found }->{ $v }) {
		    $class = 'forward';
		}
	    } else {
		# No cross nor forward edges in
		# an undirected graph, by definition.
		$class = 'back';
	    }
	
	    push @{ $T->{ edge_class_list } }, [ $u, $v, $class ];
	};
    use Graph::DFS;
    my $d =
	Graph::DFS->
	    new( $G,
		 unseen_successor => $unseen_successor,
		 seen_successor   => $seen_successor,
		 @_);

    $d->preorder;

    return @{ $d->{ edge_class_list } };
}

=pod
=item toposort

	@toposort = $G->toposort

Returns the vertices of the graph $G sorted topologically.

=cut
sub toposort {
    my $G = shift;
    my $d = Graph::DFS->new($G);

    reverse $d->postorder; # That's it.
}

# _strongly_connected
#
#	$s = $G->_strongly_connected
#
#	(INTERNAL USE ONLY)
#	Returns a graph traversal object that can be used for
#	strong connection computations.
#
sub _strongly_connected {
    my $G = shift;
    my $T = $G->transpose;

    Graph::DFS->
	new($T,
	    # Pick the potential roots in their DFS postorder.
	    strong_root_order => [ Graph::DFS->new($T)->postorder ],
	    get_next_root     =>
	        sub {
		    my ($T, %param) = @_;
		
		    while (my $root =
			   shift @{ $param{ strong_root_order } }) {
			return $root if exists $T->{ pool }->{ $root };
		    }
		}
	   );
}

=pod
=item strongly_connected_components

	@S = $G->strongly_connected_components

Returns the strongly connected components @S of the graph $G
as a list of anonymous lists of vertices, each anonymous list
containing the vertices belonging to one strongly connected
component.

=cut
sub strongly_connected_components {
    my $G = shift;
    my $T = $G->_strongly_connected;
    my %R = $T->vertex_roots;
    my @C;

    # Clump together vertices having identical root vertices.
    while (my ($v, $r) = each %R) { push @{ $C[$r] }, $v }

    return @C;
}

=pod
=item strongly_connected_graph

	$T = $G->strongly_connected_graph

Returns the strongly connected graph $T of the graph $G.
The names of the strongly connected components are
formed from their constituent vertices by concatenating
their names by '+'-characters: "a" and "b" --> "a+b".

=cut
sub strongly_connected_graph {
    my $G = shift;
    my $C = (ref $G)->new;
    my $T = $G->_strongly_connected;
    my %R = $T->vertex_roots;
    my @C; # We're not calling the strongly_connected_components()
           # method because we will need also the %R.

    # Create the strongly connected components.
    while (my ($v, $r) = each %R) { push @{ $C[$r] }, $v }
    foreach my $c (@C)            { $c = join("+", @$c)  }

    $C->directed( $G->directed );

    my @E = $G->edges;

    # Copy the edges between strongly connected components.
    while (my ($u, $v) = splice(@E, 0, 2)) {
	$C->add_edge( $C[ $R{ $u } ], $C[ $R{ $v } ] )
	    unless $R{ $u } == $R{ $v };
    }

    return $C;
}

=pod
=item APSP_Floyd_Warshall

	$APSP = $G->APSP_Floyd_Warshall

Returns the All-pairs Shortest Paths graph of the graph $G
computed using the Floyd-Warshall algorithm and the attribute
'weight' on the edges.
The returned graph has an edge for each shortest path.
An edge has attributes "weight" and "path"; for the length of
the shortest path and for the path (an anonymous list) itself.

=cut
sub APSP_Floyd_Warshall {
    my $G = shift;

    my @V = $G->vertices;
    my @E = $G->edges;
    my (%V2I, @I2V);
    my (@P, @W);

    # Compute the vertex <-> index mappings.
    @V2I{ @V     } = 0..$#V;
    @I2V[ 0..$#V ] = @V;

    # Initialize the predecessor matrix @P and the weight matrix @W.
    # (The graph is converted into adjacency-matrix representation.)
    # (The matrix is a list of lists.)
    foreach my $i ( 0..$#V ) { $W[ $i ][ $i ] = 0 }
    while ( my ($u, $v) = splice(@E, 0, 2) ) {
        my ( $ui, $vi ) = ( $V2I{ $u }, $V2I{ $v } );
	$P[ $ui ][ $vi ] = $ui unless $ui == $vi;
	$W[ $ui ][ $vi ] = $G->get_attribute( 'weight', $u, $v );
    }

    # Do the O(N**3) loop.
    for ( my $k = 0; $k < @V; $k++ ) {
	my (@nP, @nW); # new @P, new @W

	for ( my $i = 0; $i < @V; $i++ ) {
	    for ( my $j = 0; $j < @V; $j++ ) {
		my $w_ij    = $W[ $i ][ $j ];
		my $w_ik_kj = $W[ $i ][ $k ] + $W[ $k ][ $j ]
		    if defined $W[ $i ][ $k ] and
		       defined $W[ $k ][ $j ];

		# Choose the minimum of w_ij and w_ik_kj.
		if ( defined $w_ij ) {
		    if ( defined $w_ik_kj ) {
		        if ( $w_ij <= $w_ik_kj ) {
			  $nP[ $i ][ $j ] = $P[ $i ][ $j ];
			  $nW[ $i ][ $j ] = $w_ij;
			} else {
			  $nP[ $i ][ $j ] = $P[ $k ][ $j ];
			  $nW[ $i ][ $j ] = $w_ik_kj;
			}
		    } else {
			$nP[ $i ][ $j ] = $P[ $i ][ $j ];
			$nW[ $i ][ $j ] = $w_ij;
		    }
		} elsif ( defined $w_ik_kj ) {
		    $nP[ $i ][ $j ] = $P[ $k ][ $j ];
		    $nW[ $i ][ $j ] = $w_ik_kj;
		}
	    }
	}

	@P = @nP; @W = @nW; # Update the predecessors and weights.
    }

    # Now construct the APSP graph.

    my $APSP = (ref $G)->new;

    $APSP->directed( $G->directed ); # Copy the directedness.

    # Convert the adjacency-matrix representation
    # into a Graph (adjacency-list representation).
    for ( my $i = 0; $i < @V; $i++ ) {
        my $iv = $I2V[ $i ];

        for ( my $j = 0; $j < @V; $j++ ) {
            if ( $i == $j ) {
                $APSP->add_weighted_edge( $iv, 0, $iv );
                $APSP->set_attribute("path", $iv, $iv, [ $iv ]);
                next;
            }
            next unless defined $W[ $i ][ $j ];

            my $jv = $I2V[ $j ];

            $APSP->add_weighted_edge( $iv, $W[ $i ][ $j ], $jv );

            my @path = ( $jv );
            if ( $P[ $i ][ $j ] != $i ) {
                my $k = $P[ $i ][ $j ];  # Walk back the path.

                while ( $k != $i ) {
                    push @path, $I2V[ $k ];
                    $k = $P[ $i ][ $k ]; # Keep walking.
                }
            }
            $APSP->set_attribute( "path", $iv, $jv, [ $iv, reverse @path ] );
        }
    }

    return $APSP;
}

=pod
=item TransitiveClosure_Floyd_Warshall

	$TransitiveClosure = $G->TransitiveClosure_Floyd_Warshall

Returns the Transitive Closure graph of the graph $G computed
using the Floyd-Warshall algorithm.
The resulting graph has an edge between each *ordered* pair of
vertices in which the second vertex is reachable from the first.

=cut
sub TransitiveClosure_Floyd_Warshall {
    my $G = shift;

    my @V = $G->vertices;
    my @E = $G->edges;
    my (%V2I, @I2V);
    my @C = ( '' ) x @V;

    # Compute the vertex <-> index mappings.
    @V2I{ @V     } = 0..$#V;
    @I2V[ 0..$#V ] = @V;

    # Initialize the closure matrix @C.
    # (The graph is converted into adjacency-matrix representation.)
    # (The matrix is a bit matrix.  Well, a list of bit vectors.)
    foreach my $i ( 0..$#V ) { vec( $C[ $i ], $i, 1 ) = 1 }
    while ( my ($u, $v) = splice(@E, 0, 2) ) {
	vec( $C[ $V2I{ $u } ], $V2I{ $v }, 1 ) = 1
    }

    # Do the O(N**3) loop.
    for ( my $k = 0; $k < @V; $k++ ) {
	my @nC = ( '' ) x @V; # new @C

	for ( my $i = 0; $i < @V; $i++ ) {
	    for ( my $j = 0; $j < @V; $j++ ) {
	        vec( $nC[ $i ], $j, 1 ) =
		  vec( $C[ $i ], $j, 1 ) |
		    vec( $C[ $i ], $k, 1 ) & vec( $C[ $k ], $j, 1 );
	    }
	}

	@C = @nC; # Update the closure.
    }

    # Now construct the TransitiveClosure graph.

    my $TransitiveClosure = (ref $G)->new;

    $TransitiveClosure->directed( $G->directed );

    # Convert the (closure-)adjacency-matrix representation
    # into a Graph (adjacency-list representation).
    for ( my $i = 0; $i < @V; $i++ ) {
	for ( my $j = 0; $j < @V; $j++ ) {
	    $TransitiveClosure->add_edge( $I2V[ $i ], $I2V[ $j ] )
	        if vec( $C[ $i ], $j, 1 );
	}
    }

    return $TransitiveClosure;
}

=pod
=item articulation points

	@A = $G->articulation_points(%param)

Returns the articulation points (vertices) @A of the graph $G.
The %param can be used to control the search.

=cut
sub articulation_points {
    my $G = shift;
    my $articulate =
	sub {
	    my ( $u, $T ) = @_;
				
	    my $ap = $T->{ vertex_found }->{ $u };
	
	    my @S = @{ $T->{ active_list } }; # Current stack.

	    $T->{ articulation_point }->{ $u } = $ap
	        unless exists $T->{ articulation_point }->{ $u };

	    # Walk back the stack marking the active DFS branch
	    # (below $u) as belonging to the articulation point $ap.
	    for ( my $i = 1; $i < @S; $i++ ) {
		my $v = $S[ -$i ];

		last if $v eq $u;

		$T->{ articulation_point }->{ $v } = $ap
		    if not exists $T->{ articulation_point }->{ $v } or
		       $ap < $T->{ articulation_point }->{ $v };
	    }
	};
    my $unseen_successor =
	sub {
	    my ($u, $v, $T) = @_;

	    # We need to know the number of children for root vertices.
	    $T->{ articulation_children }->{ $u }++;
	};
    my $seen_successor =
	sub {
	    my ($u, $v, $T) = @_;
	
	    # If the $v is still active, articulate it.
	    $articulate->( $v, $T ) if exists $T->{ active_pool }->{ $v };
	};
    my $d =
	Graph::DFS->new($G,
			articulate       => $articulate,
			unseen_successor => $unseen_successor,
			seen_successor   => $seen_successor,
		);

    $d->preorder;

    # Now we need to find (the indices of) unique articulation points
    # and map them back to vertices.

    my (%ap, @vf);

    foreach my $v ( $G->vertices ) {
	$ap{ $d->{ articulation_point }->{ $v } } = $v;
	$vf[ $d->{ vertex_found       }->{ $v } ] = $v;
    }

    %ap = map { ( $vf[ $_ ], $_ ) } keys %ap;

    # DFS tree roots are articulation points only
    # iff they have more than one children.
    foreach my $r ( $d->roots ) {
	delete $ap{ $r } if $d->{ articulation_children }->{ $r } < 2;
    }

    keys %ap;
}

=pod
=item is_biconnected

	$b = $G->is_biconnected

Returns true is the graph $G is biconnected
(has no articulation points), false otherwise.

=cut
sub is_biconnected {
    my $G = shift;

    return $G->articulation_points == 0;
}

=pod
=item largest_out_degree

	$v = $G->largest_out_degree( @V )

Selects the vertex $v from the vertices @V having
the largest out degree in the graph $G.


=cut
sub largest_out_degree {
    my $G = shift;

    my @R = map { $_->[ 0 ] } # A Schwartzian Transform.
	        sort { $b->[ 1 ] <=> $a->[ 1 ] || $a cmp $b }
		     map { [ $_, $G->out_degree($_) ] }
			 @_;

    return $R[ 0 ];
}

# _heap_init
#
#	$G->_heap_init($heap, $u, \%in_heap, \%weight, \%parent)
#
#	(INTERNAL USE ONLY)
#	Initializes the $heap with the vertex $u as the initial
#	vertex, its weight being zero, and marking all vertices
#	of the graph $G to be $in_heap,
#
sub _heap_init {
    my ($G, $heap, $u, $in_heap, $W, $P) = @_;

    use Graph::HeapElem;

    foreach my $v ( $G->vertices ) {
	my $e = Graph::HeapElem->new( $v, $W, $P );
	$heap->add( $e );
	$in_heap->{ $v } = $e;
    }

    $W->{ $u } = 0;
}

=pod
=item MST_Prim

	$MST = $G->MST_Prim($u)

Returns Prim's Minimum Spanning Tree (as a graph) of
the graph $G based on the 'weight' attributes of the edges.
The optional start vertex is $u, if none is given, a hopefully
good one (a vertex with a large out degree) is chosen.

=cut
sub MST_Prim {
    my ( $G, $u ) = @_;
    my $MST       = (ref $G)->new;

    $u = $G->largest_out_degree( $G->vertices ) unless defined $u;

    use Heap::Fibonacci;
    my $heap = Heap::Fibonacci->new;
    my ( %in_heap, %weight, %parent );

    $G->_heap_init( $heap, $u, \%in_heap, \%weight, \%parent );

    # Walk the edges at the current BFS front
    # in the order of their increasing weight.
    while ( defined $heap->minimum ) {
	$u = $heap->extract_minimum;
	delete $in_heap{ $u->vertex };
	
	# Now extend the BFS front.
	
	foreach my $v ( $G->successors( $u->vertex ) ) {
	    if ( defined( $v = $in_heap{ $v } ) ) {
		my $nw = $G->get_attribute( 'weight',
					    $u->vertex, $v->vertex );
		my $ow = $v->weight;
		
		if ( not defined $ow or $nw < $ow ) {
		    $v->weight( $nw );
		    $v->parent( $u->vertex );
		    $heap->decrease_key( $v );
		}
	    }
	}
    }

    foreach my $v ( $G->vertices ) {
	$MST->add_weighted_edge( $v, $weight{ $v }, $parent{ $v } )
	    if defined $parent{ $v };
    }

    return $MST;
}

# _SSSP_construct
#
#	$SSSP = $G->_SSSP_construct( $s, $W, $P );
#
#	(INTERNAL USE ONLY)
#	Return the SSSP($s) graph of graph $G based on the computed
#	anonymous hashes for weights and parents: $W and $P.
#	The vertices of the graph will have two attributes: "weight",
#	which tells the length of the shortest single-source path,
#	and "path", which is an anymous list containing the path.
#
sub _SSSP_construct {
    my ($G, $s, $W, $P ) = @_;
    my $SSSP = (ref $G)->new;

    foreach my $u ( $G->vertices ) {
	$SSSP->add_vertex( $u );

        $SSSP->set_attribute( "weight", $u, $W->{ $u } || 0 );

	my @path = ( $u );
	if ( defined $P->{ $u } ) {
	    push @path, $P->{ $u };
	    if ( $P->{ $u } ne $s ) {
		my $v = $P->{ $u };

		while ( $v ne $s ) {
		    push @path, $P->{ $v };
		    $v = $P->{ $v };
		}
	    }
	}
	$SSSP->set_attribute( "path",   $u, [ reverse @path ] );
    }

    return $SSSP;
}

=pod
=item SSSP_Dijkstra

	$SSSP = $G->SSSP_Dijkstra($s)

Returns the Single-source Shortest Paths (as a graph)
of the graph $G starting from the vertex $s using Dijktra's
SSSP algorithm.

=cut
sub SSSP_Dijkstra {
    my ( $G, $s ) = @_;

    use Heap::Fibonacci;
    my $heap = Heap::Fibonacci->new;
    my ( %in_heap, %weight, %parent );

    # The other weights are by default undef (infinite).
    $weight{ $s } = 0;

    $G->_heap_init($heap, $s, \%in_heap, \%weight, \%parent );

    # Walk the edges at the current BFS front
    # in the order of their increasing weight.
    while ( defined $heap->minimum ) {
        my $u = $heap->extract_minimum;
	delete $in_heap{ $u->vertex };

	# Now extend the BFS front.
	my $uw = $u->weight;

	foreach my $v ( $G->successors( $u->vertex ) ) {
	    if ( defined( $v = $in_heap{ $v } ) ) {
	        my $ow = $v->weight;
		my $nw =
		  $G->get_attribute( 'weight', $u->vertex, $v->vertex ) +
		    ($uw || 0); # The || 0 helps for undefined $uw.

		# Relax the edge $u - $v.
		if ( not defined $ow or $ow > $nw ) {
		    $v->weight( $nw );
		    $v->parent( $u->vertex );
		    $heap->decrease_key( $v );
		}
	    }
	}
    }

    return $G->_SSSP_construct( $s, \%weight, \%parent );
}

=pod
=item SSSP_Bellman_Ford

	$SSSP = $G->SSSP_Bellman_Ford($s)

Returns the Single-source Shortest Paths (as a graph)
of the graph $G starting from the vertex $s using Bellman-Ford
SSSP algorithm.  If there are one or more negatively weighted
cycles, returns undef.

=cut
sub SSSP_Bellman_Ford {
    my ( $G, $s ) = @_;
    my ( %weight, %parent );

    $weight{ $s } = 0;

    my $V = $G->vertices;
    my @E = $G->edges;

    foreach ( 1..$V ) { # |V|-1 times (*not* |V| times)
        my @C = @E;	# Copy.
	
	while (my ($u, $v) = splice(@C, 0, 2)) {
	    my $ow = $weight{ $v };
	    my $nw = $G->get_attribute( 'weight', $u, $v );

	    $nw += $weight{ $u } if defined $weight{ $u };
	    # Relax the edge $u - $w.
	    if ( not defined $ow or $ow > $nw ) {
	        $weight{ $v } = $nw;
		$parent{ $v } = $u;
	    }
	}
    }

    my $negative;

    # Warn about detected negative cycles.
    while (my ($u, $v) = splice(@E, 0, 2)) {
        if ( $weight{ $v } >
	     $weight{ $u } + $G->get_attribute( 'weight', $u, $v ) ) {
	     warn "SSSP_Bellman_Ford: negative cycle $u $v\n";
	     $negative++;
	}
    }

    # Bail out if found negative cycles.
    return undef if $negative;

    # Otherwise return the SSSP graph.
    return $G->_SSSP_construct( $s, \%weight, \%parent );
}

=pod
=item SSSP_DAG

	$SSSP = $G->SSSP_DAG($s)

Returns the Single-source Shortest Paths (as a graph)
of the DAG $G starting from vertex $s.

=cut
sub SSSP_DAG {
    my ( $G, $s ) = @_;
    my $SSSP      = (ref $G)->new;

    my ( %weight, %parent );

    $weight{ $s } = 0;

    # Because by definition there can be no cycles
    # we can freely explore each successor of each vertex.
    foreach my $u ( $G->toposort ) {
        foreach my $v ( $G->successors( $u ) ) {
	    my $ow = $weight{ $v };
	    my $nw = $G->get_attribute( 'weight', $u, $v );

	    $nw += $weight{ $u } if defined $weight{ $u };

	    # Relax the edge $u - $v.
	    if ( not defined $ow or $ow > $nw ) {
	        $weight{ $v } = $nw;
		$parent{ $v } = $u;
	    }
	}
    }

    return $G->_SSSP_construct( $s, \%weight, \%parent );
}

=pod
=item add_capacity_edge

	$G->add_capacity_edge($u, $w, $v, $a)

Adds in the graph $G an edge from vertex $u to vertex $v
and the edge attribute 'capacity' set to $w.

=cut
sub add_capacity_edge {
    my ($G, $u, $w, $v, $a) = @_;

    $G->add_edge($u, $v);
    $G->set_attribute('capacity', $u, $v, $w);
}

=pod
=item add_capacity_edges

	$G->add_capacity_edges($u1, $w1, $v1, $u2, $w2, $v2, ...)

Adds in the graph $G the capacity edges.

=cut
sub add_capacity_edges {
    my $G = shift;

    while (my ($u, $w, $v) = splice(@_, 0, 3)) {
        $G->add_capacity_edge($u, $w, $v);
    }
}

=pod
=item add_capacity_path

	$G->add_capacity_path($v1, $w1, $v2, $w2, ..., $wnm1, $vn)

Adds in the graph $G the n edges defined by the path $v1 ... $vn
with the n-1 'capacity' attributes $w1 ... $wnm1

=cut
sub add_capacity_path {
    my $G = shift;
    my $u = shift;

    while (my ($w, $v) = splice(@_, 0, 2)) {
	$G->add_capacity_edge($u, $w, $v);
	$u = $v;
    }
}

=pod
=item Flow_Ford_Fulkerson

	$F = $G->Flow_Ford_Fulkerson($S)

Returns the (maximal) flow network of the flow network $G,
parametrized by the state $S.  The $G must have 'capacity'
attributes on its edges.  $S->{ source } must contain the
source vertex and $S->{ sink } the sink vertex, and
most importantly $S->{ next_augmenting_path } must contain
an anonymous subroutine which takes $F and $S as arguments
and returns the next potential augmenting path.
Flow_Ford_Fulkerson will do the augmenting.
The result graph $F will have 'flow' and (residual) 'capacity'
attributes on its edges.

=cut
sub Flow_Ford_Fulkerson {
    my ( $G, $S ) = @_;

    my $F = (ref $G)->new; # The flow network.
    my @E = $G->edges;
    my ( $u, $v );

    # Copy the edges and the capacities, zero the flows.
    while (($u, $v) = splice(@E, 0, 2)) {
	$F->add_edge( $u, $v );
	$F->set_attribute( 'capacity', $u, $v,
			   $G->get_attribute( 'capacity', $u, $v ) || 0 );
	$F->set_attribute( 'flow',     $u, $v, 0 );
    }

    # Walk the augmenting paths.
    while ( my $ap = $S->{ next_augmenting_path }->( $F, $S ) ) {
	my @aps = @$ap;	# augmenting path segments
	my $apr;	# augmenting path residual capacity
	my $psr;	# path segment residual capacity

	# Find the minimum capacity of the path.
	for ( $u = shift @aps; @aps; $u = $v ) {
	    $v   = shift @aps;
	    $psr = $F->get_attribute( 'capacity', $u, $v ) -
		   $F->get_attribute( 'flow',     $u, $v );
	    $apr = $psr
		if $psr >= 0 and ( not defined $apr or $psr < $apr );
	}

	if ( $apr > 0 ) { # Augment the path.
	    for ( @aps = @$ap, $u = shift @aps; @aps; $u = $v ) {
		$v = shift @aps;
		$F->set_attribute( 'flow',
				   $u, $v,
				   $F->get_attribute( 'flow', $u, $v ) +
				   $apr );
	    }
	}
    }

    return $F;
}

=pod
=item Flow_Edmonds_Karp

	$F = $G->Flow_Edmonds_Karp($source, $sink)

Return the maximal flow network of the graph $G built
using the Edmonds-Karp version of Ford-Fulkerson.
The input graph $G must have 'capacity' attributes on
its edges; resulting flow graph will have 'capacity' and 'flow'
attributes on its edges.

=cut
sub Flow_Edmonds_Karp {
    my ( $G, $source, $sink ) = @_;

    my $S;

    $S->{ source } = $source;
    $S->{ sink   } = $sink;
    $S->{ next_augmenting_path } =
	sub {
	    my ( $F, $S ) = @_;

	    my $source = $S->{ source };
	    my $sink   = $S->{ sink   };

	    # Initialize our "todo" heap.
	    unless ( exists $S->{ todo } ) {
		# The first element is a hash recording the vertices
		# seen so far, the rest are the path from the source.
		push @{ $S->{ todo } },
		     [ { $source => 1 }, $source ];
	    }

	    while ( @{ $S->{ todo } } ) {
		# $ap: The next augmenting path.
		my $ap = shift @{ $S->{ todo } };
		my $sv = shift @$ap;	# The seen vertices.
		my $v  = $ap->[ -1 ];	# The last vertex of path.

		if ( $v eq $sink ) {
		    return $ap;
		} else {
		    foreach my $s ( $G->successors( $v ) ) {
			unless ( exists $sv->{ $s } ) {
			    push @{ $S->{ todo } },
			        [ { %$sv, $s => 1 }, @$ap, $s ];
			}
		    }
		}
	    }
	};

    return $G->Flow_Ford_Fulkerson( $S );
}

use overload 'eq' => \&eq;

=pod
=item eq

	$G->eq($H)

Return true if the graphs (actually, their string representations)
are identical.  This means really identical: they must have identical
vertex names and identical edges between the vertices, and they must
be similarly directed.  (Just isomorphism isn't enough.)

=cut
sub eq {
    my ($G, $H) = @_;

    return ref $H ? $G->stringify eq $H->stringify : $G->stringify eq $H;
}

=pod
=back

=head1 COPYRIGHT

Copyright 1999, O'Reilly & Associates.

This code is distributed under the same copyright terms as Perl itself.

=cut

1;
