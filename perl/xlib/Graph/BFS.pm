package Graph::BFS;

use strict;
local $^W = 1;

use Graph::Traversal;

use vars qw(@ISA);
@ISA = qw(Graph::Traversal);

=head1 NAME

Graph::BFS - graph breadth-first search

=head1 SYNOPSIS

    use Graph::BFS;

=head1 DESCRIPTION

=over 4

=cut

=pod
=item new

	$bfs = Graph::BFS->new($G, %param)

Returns a new breadth-first search object for the graph $G
and the (optional) parameters %param.

=cut
sub new {
    my $class = shift;
    my $graph = shift;

    Graph::Traversal::new( $class,
			   $graph,
			   current =>
		           sub { $_[0]->{ active_list }->[ 0 ] },
			   finish  =>
		           sub { shift @{ $_[0]->{ active_list } } },
			   @_);
}

=pod

=back

See also C<Graph::Traversal>.

=head1 COPYRIGHT

Copyright 1999, O'Reilly & Associates.

This code is distributed under the same copyright terms as Perl itself.

=cut

1;
