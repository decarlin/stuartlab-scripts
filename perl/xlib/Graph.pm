package Graph;

use strict;
local $^W = 1;

use Graph::Base;
use Graph::Directed;

use vars qw($VERSION @ISA);

$VERSION = 0.201;

@ISA = qw(Graph::Directed Graph::Base);

=head1 NAME

Graph - graph operations

=head1 SYNOPSIS

    use Graph;

    $g = new Graph;

=head1 DESCRIPTION

This is just a front-end class for Graph::Directed and Graph::Base.

Instantiated Graph objects (like $g in the the above description)
are in fact Graph::Base objects in disguise, look there for the
methods available.  If you want undirected graphs, create Graph::Undirected
objects.

=head1 COPYRIGHT

Copyright 1999, O'Reilly & Associates.

This code is distributed under the same copyright terms as Perl itself.

=cut

1;

