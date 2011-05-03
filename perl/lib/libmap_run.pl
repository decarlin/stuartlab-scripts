
##---------------------------------------------------------------------------
##
##---------------------------------------------------------------------------
sub getClustersFromVectorized # ($file,$headers,$delim,$member_col,$cluster_col)
{
  my $file = shift;
  my $headers = shift;
  my $delim = shift;
  my $member_col = shift;
  my $cluster_col = shift;
  my $fin;
  if($file eq '-')
    { $fin = \*STDIN; }
  else
    { open($fin,$file) or die("Could not open file '$file'."); }

  my $line=0;
  my $row=0;
  my %clu2num;
  my $num_cluster2members=0;

  my %cluster2members;
  my %member2clusters;

  while(<$fin>)
  {
    $line++;
    if(/\S/ and not(/^\s*#/))
    {
      $row++;
      if($row > $headers)
      {
        my @tuple   = split($delim);
        chomp($tuple[$#tuple]);
        my $member  = $tuple[$member_col];
        my $cluster = $tuple[$cluster_col];

        # Add this member to the cluster
        if(not(exists($cluster2members{$cluster})))
          { $cluster2members{$cluster} = $member; }
        else
          { $cluster2members{$cluster} .= $delim . $member; }

	if(not(exists($member2clusters{$member})))
	  { $member2clusters{$member} = $cluster; }
	else
	  { $member2clusters{$member} .= $delim . $cluster; }
      }
    }
  }
  close($fin);

  # Convert the delimited text lists to actual perl lists

  foreach my $cluster (keys(%cluster2members))
  {
    my @members = split($delim, $cluster2members{$cluster});
    my %members;
    foreach my $member (@members)
      { $members{$member} = 1; }
    $cluster2members{$cluster} = \%members;
  }

  foreach my $member (keys(%member2clusters))
  {
    my @clusters = split($delim, $member2clusters{$member});
    my %clusters;
    foreach my $cluster (@clusters)
      { $clusters{$cluster} = 1; }
    $member2clusters{$member} = \%clusters;
  }

  return (\%cluster2members, \@member2clusters);
}

##---------------------------------------------------------------------------
##
##---------------------------------------------------------------------------
sub getClusteringCommonDenominator # ($cluster2members1,$cluster2members2)
{
  my $cluster2members1_ref = shift;
  my $cluster2members2_ref = shift;
  my %cluster2members1 = %{$cluster2members1_ref};
  my %cluster2members2 = %{$cluster2members2_ref};

  my %members1;
  my %members2;

  # Get all the members in clustering 1
  foreach my $cluster (keys(%cluster2members1))
  {
    my %members = %{$cluster2members1{$cluster}};
    foreach my $member (keys(%members))
    {
      $members1{$member} = 1;
    }
  }

  # Get all the members in clustering 2
  foreach my $cluster (keys(%cluster2members2))
  {
    my %members = %{$cluster2members2{$cluster}};
    foreach my $member (keys(%members))
    {
      $members2{$member} = 1;
    }
  }

  # Make a copy of clustering 1, but only of those members that also occur in clustering 2
  my %new_cluster2members1;
  foreach my $cluster (keys(%cluster2members1))
  {
    my %members = %{$cluster2members1{$cluster}};
    my %common_members;
    foreach my $member (keys(%members))
    {
      if(exists($members2{$member}))
      {
	$common_members{$member} = 1;
      }
    }
    $new_cluster2members1{$cluster} = \%common_members;
  }

  # Make a copy of clustering 2, but only of those members that also occur in clustering 1
  my %new_cluster2members2;
  foreach my $cluster (keys(%cluster2members2))
  {
    my %members = %{$cluster2members2{$cluster}};
    my %common_members;
    foreach my $member (keys(%members))
    {
      if(exists($members1{$member}))
      {
	$common_members{$member} = 1;
      }
    }
    $new_cluster2members2{$cluster} = \%common_members;
  }
  return (\%new_cluster2members1,\%new_cluster2members2);
}


  # Compute the sensitivity
sub getClusteringROC # ($gold_c2m,$query_m2c,$maxpairs,$verbose)
{
  my $gold_c2m_ref  = shift;
  my $query_m2c_ref = shift;
  my $maxpairs = int(shift);
  my $verbose = shift;

  my %gold_c2m  = %{$gold_c2m_ref};
  my %query_m2c = %{$query_m2c_ref};

  my $sensitivity = 0.0;
  my @gold_clusters = sort(keys(%gold_c2m));
  my $num_pairs = 0;
  my $done = 0;
  my $passify = 100;
  my $maxpairs_per_cluster = int($maxpairs/($#gold_clusters+1))+1;
  $verbose and print STDERR "Calculating sensitivity...";
  for(my $c=0; $c<=$#gold_clusters; $c++)
  {
    my $cluster = $gold_clusters[$c];
    my @members = sort(keys(%{$gold_c2m{$cluster}}));
    for(my $i=0; ($i<=$#members-1) and not($done); $i++)
    {
      my $cluster_i = $query_m2c{$members[$i]};
      for(my $j=$i+1; ($j<=$#members) and not($done); $j++)
      {
        my $cluster_j = $query_m2c{$members[$j]};
	if($cluster_i eq $cluster_j)
	  { $sensitivity++; }
        $num_pairs++;

	if($num_pairs == $maxpairs_per_cluster)
	{
	  $done = 1;
	}
	if(($num_pairs % $passify)==0)
	{
	  print STDERR " $num_pairs";
	}
      }
    }
  }
  $sensitivity /= $num_pairs;
  $verbose and print STDERR " done.\n";

  # Compute the specificity
  my $specificity = 0.0;
  $num_pairs = 0;
  $done = 0;
  for(my $i=0; ($i<=$#gold_clusters-1) and not($done); $i++)
  {
    my @members_i = sort(keys(%{$gold_c2m{$gold_clusters[$i]}}));
    for(my $j=$i+1; ($j<=$#gold_clusters) and not($done); $j++)
    {
      my @members_j = sort(keys(%{$gold_c2m{$gold_clusters[$j]}}));

      for(my $a=0; ($a<=$#members_i) and not($done); $a++)
      {
	my $cluster_a = $query_m2c{$members_i[$a]};
        for(my $b=0; ($b<=$#members_j) and not($done); $b++)
	{
	  my $cluster_b = $query_m2c{$members_j[$b]};

	  if($cluster_a ne $cluster_b)
	    { $specificity++; }
	  $num_pairs++;
	  if($num_pairs == $maxpairs)
	  {
	    $done = 1;
	  }
	  if(($num_pairs % $passify)==0)
	  {
	    print STDERR " $num_pairs";
	  }
	}
      }
    }
  }
  $specificity /= $num_pairs;

  return ($sensitivity,$specificity);
}

1
