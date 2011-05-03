require "$ENV{MYPERLDIR}/lib/libfile.pl";
require "$ENV{MYPERLDIR}/lib/libset.pl";

use strict;


#---------------------------------------------------------------------------
# $int graphNumNodes (\%\%graph)
#---------------------------------------------------------------------------
sub graphSize
{
    return &setSize(&graphNodes(@_));
}

sub graphNumEdges
{
    my $graph = @_;

    return &setsSumSizes($graph);
}

#---------------------------------------------------------------------------
# \%set graphNodes (\%\%graph)
#---------------------------------------------------------------------------
sub graphNodes
{
    my ($graph) = @_;

    return &setUnion(&graphSources($graph), &graphTargets($graph));
}

#---------------------------------------------------------------------------
# \%set graphSources (\%\%graph)
#---------------------------------------------------------------------------
sub graphSources
{
    my ($graph) = @_;
    return &setMembers($graph);
}

#---------------------------------------------------------------------------
# \%set graphTargets (\%\%graph)
#---------------------------------------------------------------------------
sub graphTargets
{
    my ($graph) = @_;
    return &setMembers(&graphReverse($graph));
}

#---------------------------------------------------------------------------
# \%node graphGetNode (\%\%graph, $node_key)
#---------------------------------------------------------------------------
sub graphGetNode
{
    my ($graph, $node_key) = @_;

    return (exists($$graph{$node_key}) ? $$graph{$node_key} : undef);
}

#---------------------------------------------------------------------------
# $int graphDegree (\%graph, $node_key)
#---------------------------------------------------------------------------
sub graphDegree
{
    my ($graph, $node_key) = @_;

    return &setSize($$graph{$node_key});
}

#---------------------------------------------------------------------------
# @int graphDegrees (\%\%graph)
#---------------------------------------------------------------------------
sub graphDegrees
{
    my ($graph) = @_;

    return &setsSizes($graph);
}

#---------------------------------------------------------------------------
# $node_key graphMaxDegreeNode (\%\%graph)
#---------------------------------------------------------------------------
sub graphMaxDegreeNode
{
    my ($graph) = @_;

    my @pairs;

    foreach my $key (keys(%{$graph}))
    {
	my $degree = &graphDegree($graph, $key);

	push(@pairs, [$key, $degree]);
    }

    @pairs = sort { $$b[1] <=> $$a[1]; } @pairs;

    my $v = $pairs[0][0];

    return $v;
}

#---------------------------------------------------------------------------
#
# \%\%graph graphUndirected (\%\%graph)
#---------------------------------------------------------------------------
sub graphUndirected
{
    my ($graph) = @_;

    return &graphMerge($graph, &graphReverse($graph));
}


#---------------------------------------------------------------------------
# \%\%graph graphReverse (\%\%graph)
#---------------------------------------------------------------------------
sub graphReverse
{
    my ($graph) = @_;

    my %reverse;

    foreach my $u (keys(%{$graph}))
    {
	my $V = $$graph{$u};

	foreach my $v (keys(%{$V}))
	{
	    if(not(exists($reverse{$v})))
	    {
		my %edges;
		$reverse{$v} = \%edges;
	    }
	    my $edges  = $reverse{$v};
	    $$edges{$u} = $$V{$v};
	}
    }

    return \%reverse;
}

#---------------------------------------------------------------------------
# \%\%graph graphMerge (\%\%graph G, \%\%graph H)
#---------------------------------------------------------------------------
sub graphMerge
{
    my ($G, $H) = @_;

    return &setsUnion($G, $H);
}

#---------------------------------------------------------------------------
# void graphConnectEdge (\%\%graph, $string from, $string to, $string attributes)
#---------------------------------------------------------------------------
sub graphConnectEdge
{
    my ($graph, $from, $to, $attributes) = @_;

    $attributes = defined($attributes) ? $attributes : "1";

    if(not(defined($graph)) or not(defined($from)) or not(defined($to)))
    {
	return;
    }

    if(not(exists($$graph{$from})))
    {
	my %node;
	$$graph{$from} = \%node;
    }

    my $node = $$graph{$from};

    $$node{$to} = $attributes;
}

sub graphDeleteNode
{
    my ($graph, $u) = @_;

    my $nbrs = $$graph{$u};

    foreach my $v (keys(%{$nbrs}))
    {
	my $v_nbrs = $$graph{$v};

	if(exists($$v_nbrs{$u}))
	{
	    delete $$v_nbrs{$u};
	}
	delete $$nbrs{$v};
    }
    delete $$graph{$u};
}

sub graphDeleteNodes
{
    my ($graph, $set) = @_;   # Alex: $graph is a pointer to a hash

    foreach my $source (keys(%{$graph}))
    {
	if(not(exists($$set{$source})))
	{
	    delete(${$graph}{$source});	# Alex: this used to be "delete($graph{$source});", but that resulted in the runtime error "Global symbol "%graph" requires explicit package name"
	}
    }
    $graph = &setsReduceBySet($graph, $set);
}

sub graphDeleteEdge
{
    return &graphDisconnectEdge(@_);
}

#---------------------------------------------------------------------------
# void graphDisconnectEdge (\%\%graph, $string from, $string to)
#---------------------------------------------------------------------------
sub graphDisconnectEdge
{
    my ($graph, $from, $to) = @_;

    if(not(defined($graph)) or not(defined($from)) or not(defined($to)) or
       not(exists($$graph{$from})))
    {
	return;
    }

    my $node = $$graph{$from};

    delete($$node{$to});
}

#---------------------------------------------------------------------------
# \%\%graph graphReadEdgeList ($string file, $string delim="\t",
#                               $int key_col1=0, $int key_col2=1,
#                               $int directed=0, $string attrib_cols=undef)
#---------------------------------------------------------------------------
sub graphReadEdgeList
{
    my ($file, $delim, $key_col1, $key_col2, $directed, $attrib_cols) = @_;
    $file        = defined($file)        ? $file        : '-';
    $delim       = defined($delim)       ? $delim       : "\t";
    $key_col1    = defined($key_col1)    ? $key_col1    : 0;
    $key_col2    = defined($key_col2)    ? $key_col2    : 1;
    $directed    = defined($directed)    ? $directed    : 1;
    $attrib_cols = defined($attrib_cols) ? $attrib_cols : undef;

    my %graph;

    my $cols = undef;
    
    my $fp;
    open($fp, $file) or die("Could not open file '$file'");
    while(my $line = <$fp>)
    {
	my @x = split($delim, $line); # @x is the tokenized line
	chomp($x[$#x]); # remove any newline from the end of the last token

	my ($u, $v) = ($x[$key_col1], $x[$key_col2]);

	my $attributes = undef; # *must not* be defined here
	if(defined($attrib_cols))
	{
	    for(my $i = 0; $i < scalar(@{$attrib_cols}); $i++)
	    {
		my $col = $$attrib_cols[$i];
		if(defined($col) and $col < scalar(@x))
		{
		    if (!defined($attributes)) {
			$attributes = $x[$col]; # initialize...
		    } else {
			$attributes .= ($delim . $x[$col]); # append...
		    }
		    # $attributes becomes a $delim-delimited string of the various attributes
		    # So it's like "FirstEdgeAttrib <TAB> Weight_1.32 <TAB> Protein-Protein Interaction <TAB> Label_Interesting"
		}
	    }
	}
	else
	{
	    $attributes = '1';
	    # not sure if this is a good idea: now it looks
	    # like the first attribute has value "1", even if there is no attribute
	    # at all. This may not be a problem, though, because if there are *no*
	    # attributes, then we shouldn't be looking to see if there are any, either.
	}

	&graphConnectEdge(\%graph, $u, $v, $attributes);

	if(not($directed)) {
	    # Connect the edge both ways in an undirected graph
	    &graphConnectEdge(\%graph, $v, $u, $attributes);
	}

    }
    close($fp);

    return \%graph;
}

#---------------------------------------------------------------------------
# \%\%edges graphReadEdgeTable ($string file, $string delim="\t",
#                           $int key_col=0, $int directed=0)
#---------------------------------------------------------------------------
sub graphReadEdgeTable
{
    my ($file, $delim, $key_col, $directed) = @_;
    $file     = defined($file)     ? $file     : '-';
    $delim    = defined($delim) ? $delim : "\t";
    $key_col  = defined($key_col) ? $key_col : 0;
    $directed = defined($directed) ? $directed : 1;

    my $edges = &setsReadTable($file, 1, $delim, $key_col);

    if(not($directed))
    {
	my @nodes_from = keys(%{$edges});
	foreach my $u (@nodes_from)
	{
	    my @nodes_to = keys(%{$$edges{$u}});
	    foreach my $v (@nodes_to)
	    {
		if(not(exists($$edges{$v})))
		{
		    my %new_edges;
		    $$edges{$v} = \%new_edges;
		}
		my $v_edges = $$edges{$v};
		$$v_edges{$u} = 1;
	    }
	}
    }

    return $edges;
}

sub graphPrint
{
    my ($graph, $fp, $delim, $attributes) = @_;
    $graph   = defined($graph)   ? $graph   : $_;
    $fp      = defined($fp)      ? $fp      : \*STDOUT;
    $delim   = defined($delim)   ? $delim   : "\t";
    $attributes = defined($attributes) ? $attributes : 0;

    foreach my $u (keys(%{$graph}))
    {
	my $node = $$graph{$u};

	foreach my $v (keys(%{$node}))
	{
	    my $attribs = $attributes ? ($delim . $$node{$v}) : "";
	    print $fp $u, $delim, $v, $attributes, "\n";
	}
    }
}

#---------------------------------------------------------------------------
# \%set graphConnectedComponent (\%\%sets graph, \%set nodes)
#---------------------------------------------------------------------------
sub graphConnectedComponent
{
    my ($graph, $nodes) = @_;

    my $component = &setSubset($graph, $nodes);

    my $V = &setsUnionSelf($component);

    # my $U = &setMembers($component);

    # my $union = &setUnion($U, $V);

    # return &set2List($union);

    return $V;
}

#-----------------------------------------------------------------------------------
# ($int into, $int total_out, \%set nodes) graphConnections(\%\%sets graph,
#                                                           \%set from, \%set to,
#                                                           \%\%sets exclude=undef)
#-----------------------------------------------------------------------------------
sub graphConnections
{
    my ($graph, $from, $to, $exclude) = @_;

    my $into      = 0;
    my $total_out = 0;
    my %nodes;

    if(defined($graph) and defined($from) and defined($to))
    {
	foreach my $node (keys(%{$graph}))
	{
	    if(exists($$from{$node}))
	    {
		my $nbrs = $$graph{$node};

		foreach my $nbr (keys(%{$nbrs}))
		{
		    if(not(defined($exclude)) or not(&setsCoMembers($exclude, $node, $nbr)))
		    {
			if(exists($$to{$nbr}))
			{
			    $into++;
			    $total_out++;

			    $nodes{"$node\t$nbr"} = 1;
			}
			elsif(not(exists($$from{$nbr})))
			{
			    $total_out++;
			}
		    }
		}
	    }
	}
    }
    return ($into, $total_out, \%nodes);
}

# \%clusters graphCast(\%\%graph, $double threshold)
#
# The CAST algorithm of A. Ben-Dor and R. Shamir
#
# The implementation returns a reference to a set that
# contains an entry for each node in the graph.  Each
# node is associated with an index that specifies to
# which cluster it was assigned.  All nodes with the
# same index belong to the same CAST cluster.  Here is
# the pseudocode for the algorithm from Jones & Pevzner
# page 354:
#
# CAST(G,t)
#  1 S <- set of vertices in the distance graph G
#  2 P <- {}
#  3 while S != {}
#  4   v <- ertex of maximal degree in the distance graph G
#  5   C <- {v}
#  6   while there exists a close gene i not in C or distant gene i in C
#  7     Find the nearest close gene i not in C and add it to C.
#  8     Find the farthest distant gene i in C and remove it from C
#  9   Add cluster C to the partition P
# 10   S <- S \ C
# 11   Remove vertices of cluster C from the distance graph G
# 12 return P
#
sub graphCast
{
    my ($graph, $thresh, $verbose) = @_;

    $verbose = defined($verbose) ? $verbose : 0;

    # Make a copy of the graph.
    my %G = %{$graph};

    my %clusters;

    # Initialize all nodes to cluster 0 (the garbage cluster).
    foreach my $u (keys(%G))
    {
	$clusters{$u} = 0;
    }

    # The cluster index.
    my $k = 0;

    my $init_size = &graphSize(\%G);

    for(my $size = &graphSize(\%G); $size > 0; $size = &graphSize(\%G))
    {
	$k++;

	my $u   = &graphMaxDegreeNode(\%G);

	my $deg = &graphDegree(\%G, $u);

	if($verbose)
	{
	    my $perc_done = int(($init_size - $size) / $init_size * 100);

	    print STDERR "$size nodes remaining ($perc_done% done).\n";

	    print STDERR "  CAST around node '$u' (degree=$deg).\n";
	}

	$clusters{$u} = $k;

	my %cluster;

	$cluster{$u} = 1;

	my $done = 0;

	while(not($done))
	{
	    # Sort neighbors in order of highest weight
	    my $weighted_nbrs = &graphGetSortedNbrs(\%G, $u, 0);

	    # Find the closest one not in the cluster.
	    my $found_similar = 0;
	    for(my $i = 0; ($i < @{$weighted_nbrs}) and not($found_similar); $i++)
	    {
		my ($v,$w) = @{$$weighted_nbrs[$i]};
		if($w >= $thresh and ($clusters{$v} != $k))
		{
		    $found_similar = 1;

		    $clusters{$v} = $k;

		    $cluster{$v} = 1;
		}
	    }

	    # Sort neighbors in order of decreasing weight
	    $weighted_nbrs = &graphGetSortedNbrs(\%G, $u, 1);

	    # Find the farthest one in the cluster.
	    my $found_distant = 0;
	    for(my $i = 0; ($i < @{$weighted_nbrs}) and not($found_distant); $i++)
	    {
		my ($v,$w) = @{$$weighted_nbrs[$i]};
		if($w < $thresh and ($clusters{$v} == $k))
		{
		    $found_distant = 1;

		    delete($clusters{$v});

		    delete($cluster{$v});
		}
	    }

	    $done = not($found_similar or $found_distant);
	}

	# Remove this cluster from the graph.
	foreach my $v (keys(%cluster))
	{
	    &graphDeleteNode(\%G, $v);
	}

	# If this cluster is of size 1, then set the node equal
	# to the garbage cluster (k=0).
	if(&setSize(\%cluster) == 1)
	{
	    $clusters{$u} = 0;
	}

	if($verbose)
	{
	    my $c     = $clusters{$u};

	    my $csize = &setSize(\%cluster);

	    print STDERR "  Cluster $c of size $csize built around node '$u'.\n";
	}
    }

    return \%clusters;
}

sub graphGetSortedNbrs
{
    my ($graph, $u, $ascending) = @_;

    $ascending = defined($ascending) ? $ascending : 0;

    my @pairs;

    my $nbrs = $$graph{$u};

    foreach my $v (keys(%{$nbrs}))
    {
	my $weight = $$nbrs{$v};

	push(@pairs, [$v, $weight]);
    }

    if($ascending)
    {
	@pairs = sort { $$a[1] <=> $$b[1]; } @pairs;
    }
    else
    {
	@pairs = sort { $$b[1] <=> $$a[1]; } @pairs;
    }

    return \@pairs;
}

1

