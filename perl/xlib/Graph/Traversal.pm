package Graph::Traversal;

use strict;
local $^W = 1;

use Graph::Base;

use vars qw(@ISA);
@ISA = qw(Graph::Base);

=head1 NAME

Graph::Traversal - graph traversal

=head1 SYNOPSIS

    use Graph::Traversal;

=head1 DESCRIPTION

=over 4

=cut

=pod
=item new

	$s = Graph::Traversal->new($G, %param)

Returns a new graph search object for the graph $G
and the parameters %param.

Usually not used directly but instead via frontends like
Graph::DFS for depth-first searching and Graph::BFS for
breadth-first searching:

	$dfs = Graph::DFS->new($G, %param)
	$bfs = Graph::BFS->new($G, %param)

I<%param documentation to be written>

=cut
sub new {
    my $class  = shift;
    my $G      = shift;

    my $S = { G => $G };

    bless $S, $class;

    $S->reset(@_);

    return $S;
}

=pod
=item reset

	$S->reset

Resets a graph search object $S to its initial state.

=cut
sub reset {
    my $S = shift;
    my $G = $S->{ G };

    @{ $S->{ pool } }{ $G->vertices } = ( );
    $S->{ active_list       }         = [ ];
    $S->{ root_list         }         = [ ];
    $S->{ preorder_list     }         = [ ];
    $S->{ postorder_list    }         = [ ];
    $S->{ active_pool       }         = { };
    $S->{ vertex_found      }         = { };
    $S->{ vertex_root       }         = { };
    $S->{ vertex_successors }         = { };
    $S->{ param             }         = { @_ };
    $S->{ when              }         = 0;
}

# _get_next_root_vertex
#
#	$o = $S->_get_next_root_vertex(\%param)
#
#	(INTERNAL USE ONLY)
#	Returns a vertex hopefully suitable as a root vertex of a tree.
#
#	If $param->{ get_next_root } exists, it will be used the determine
#	the root.  If it is a code reference, the result of running it
#	with parameters ($S, %param) will be the next root.  Otherwise
#	it is assumed to be the next root vertex as it is.
#
#	Otherwise an unseen vertex having the maximal out-degree
#	will be selected.
#
sub _get_next_root_vertex {
    my $S      = shift;
    my %param  = ( %{ $S->{ param } }, @_ ? %{ $_[0] } : ( ));
    my $G      = $S->{ G };

    if ( exists $param{ get_next_root } ) {
	if ( ref $param{ get_next_root } eq 'CODE' ) {
	    return $param{ get_next_root }->( $S, %param ); # Dynamic.
	} else {
	    my $get_next_root = $param{ get_next_root };	# Static.

	    # Use only once.
	    delete $S->{ param }->{ get_next_root };
	    delete $_[0]->{ get_next_root } if @_;

	    return $get_next_root;
	}
    } else {
	return $G->largest_out_degree( keys %{ $S->{ pool } } );
    }
}

# _mark_vertex_found
#
#	$S->_mark_vertex_found( $u )
#
#	(INTERNAL USE ONLY)
#	Marks the vertex $u as a new vertex in the search object $S.
#
sub _mark_vertex_found {
    my ( $S, $u ) = @_;

    $S->{ vertex_found }->{ $u } = $S->{ when }++;
    delete $S->{ pool }->{ $u };
}

# _next_state
#
#	$o = $S->_next_state(%param)
#
#	(INTERNAL USE ONLY)
#	Returns a graph search object.
#
sub _next_state {
    my $S = shift;	# The current state.

    my $G = $S->{ G };	# The current graph.
    my %param = ( %{ $S->{ param } }, @_);
    my ($u, $v);	# The current vertex and its successor.
    my $return = 0;	# Return when this becomes true.

    until ( $return ) {

	# Initialize our search when needed.
	# (Start up a new tree.)
	unless ( @{ $S->{ active_list } } ) {
	    do {
		$u = $S->_get_next_root_vertex(\%param);
		return wantarray ? ( ) : $u unless defined $u;
	    } while exists $S->{ vertex_found }->{ $u };

	    # A new root vertex found.
	    push @{ $S->{ active_list } }, $u;
	    $S->{ active_pool }->{ $u } = 1;
	    push @{ $S->{ root_list   } }, $u;
	    $S->{ vertex_root }->{ $u } = $#{ $S->{ root_list } };
	}

	# Get the current vertex.
	$u = $param{ current }->( $S );
	return wantarray ? () : $u unless defined $u;

	# Record the vertex if necessary.
	unless ( exists $S->{ vertex_found }->{ $u } ) {
	    $S->_mark_vertex_found( $u );
	    push @{ $S->{ preorder_list } }, $u;
	    # Time to return?
	    $return++ if $param{ return_next_preorder };
	}

	# Initialized the list successors if necessary.
	$S->{ vertex_successors }->{ $u } = [ $G->successors( $u ) ]
	    unless exists $S->{ vertex_successors }->{ $u };

	# Get the next successor vertex.
	$v = shift @{ $S->{ vertex_successors }->{ $u } };

	if ( defined $v ) {
	    # Something to do for each successor?
	    $param{ successor }->( $u, $v, $S )
		if exists $param{ successor };

	    unless ( exists $S->{ vertex_found }->{ $v } ) {
		# An unseen successor.
		$S->_mark_vertex_found( $v );
		push @{ $S->{ preorder_list } }, $v;
		$S->{ vertex_root }->{ $v } = $S->{ vertex_root }->{ $u };
		push @{ $S->{ active_list } }, $v;
		$S->{ active_pool }->{ $v } = 1;

		# Something to for each unseen edge?
		# For multiedges, triggered only for the first edge.
		$param{ unseen_successor }->( $u, $v, $S )
		    if exists $param{ unseen_successor };
	    } else {
		# Something to do for each seen edge?
		# For multiedges, triggered for the 2nd, etc, edges.
		$param{ seen_successor }->( $u, $v, $S )
		    if exists $param{ seen_successor };
	    }

	    # Time to return?
	    $return++ if $param{ return_next_edge };

	} elsif ( not exists $S->{ vertex_finished }->{ $u } ) {
	    # Finish off with this vertex (we run out of descendants).
	    $param{ finish }->( $S );

	    $S->{ vertex_finished }->{ $u } = $S->{ when }++;
	    push @{ $S->{ postorder_list } }, $u;
	    delete $S->{ active_pool }->{ $u };

	    # Time to return?
	    $return++ if $param{ return_next_postorder };
	}
    }

    # Return an edge if so asked.
    return ( $u, $v ) if $param{ return_next_edge };

    # Return a vertex.
    return $u;
}

=pod
=item next_preorder

	$v = $s->next_preorder

Returns the next vertex in preorder of the graph
encapsulated within the search object $s.

=cut
sub next_preorder {
    my $S = shift;

    $S->_next_state( return_next_preorder => 1, @_ );
}

=cut
=item next_postorder

	$v = $S->next_postorder

Returns the next vertex in postorder of the graph
encapsulated within the search object $S.

=cut
sub next_postorder {
    my $S = shift;

    $S->_next_state( return_next_postorder => 1, @_ );
}

=pod
=item next_edge

	($u, $v) = $s->next_edge

Returns the vertices of the next edge of the graph
encapsulated within the search object $s.

=cut
sub next_edge {
    my $S = shift;

    $S->_next_state( return_next_edge => 1, @_ );
}

=pod
=item preorder

	@V = $S->preorder

Returns all the vertices in preorder of the graph
encapsulated within the search object $S.

=cut
sub preorder {
    my $S = shift;

    1 while defined $S->next_preorder;  # Process entire graph.

    return @{ $S->{ preorder_list } };
}

=pod
=item postorder

	@V = $S->postorder

Returns all the vertices in postorder of the graph
encapsulated within the search object $S.

=cut
sub postorder {
    my $S = shift;

    1 while defined $S->next_postorder; # Process entire graph.

    return @{ $S->{ postorder_list } };
}

=pod
=item edges

	@V = $S->edges

Returns all the edges of the graph
encapsulated within the search object $S.

=cut
sub edges {
    my $S = shift;
    my (@E, $u, $v);

    push @E, $u, $v while ($u, $v) = $S->next_edge;

    return @E;
}

=pod
=item roots

	@R = $S->roots

Returns all the root vertices of the trees of
the graph encapsulated within the search object $S.
"The root vertices" is ambiguous: what really happens
is that either the roots from the previous search made
on the $s are returned; or a preorder search is done
and the roots of this search are returned.

=cut
sub roots {
    my $S = shift;

    $S->preorder
	unless exists $S->{ preorder_list } and
	       @{ $S->{ preorder_list } } == $S->{ G }->vertices;

    return @{ $S->{ root_list } };
}

=pod
=item vertex_roots

	%R = $S->vertex_roots

Returns as a hash of ($vertex, $root) pairs all the vertices
and the root vertices of their search trees of the graph
encapsulated within the search object $S.
"The root vertices" is ambiguous; see the documentation of
the roots() method for more details.

=cut
sub vertex_roots {
    my $S = shift;
    my $G = $S->{ G };

    $S->preorder
        unless exists $S->{ preorder_list } and
	       @{ $S->{ preorder_list } } == $G->vertices;

    return 
	map { ( $_, $S->{ vertex_root }->{ $_ } ) } $G->vertices;
}

# DELETE
#
#	(INTERNAL USE ONLY)
#	The Destructor.
#
sub DELETE {
    my $S = shift;

    delete $S->{ G }; # Release the graph.
}

=pod

=head1 COPYRIGHT

Copyright 1999, O'Reilly & Associates.

This code is distributed under the same copyright terms as Perl itself.

=cut

1;
