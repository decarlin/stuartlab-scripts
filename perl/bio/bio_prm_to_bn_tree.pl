#! /usr/bin/perl

#------------------------------------------------------------------------------------------------------------------------------------------------
# input: 
#    convert_prm_file - the prm to convert
#    convert_bn_file - the bn file to create
#    convert_rel - the name of the prm relation to convert
#    join_for_<relation_name> - the name of the join for each <relation_name> that is used in the prm for accessing attributes from this relation
# output:
#    creates a bn_tree from a prm containing a tree
#------------------------------------------------------------------------------------------------------------------------------------------------

#----------------------------------------------------------------
# load the settings
#----------------------------------------------------------------
if (length($ARGV[0]) == 0) { $settings_file = "settings"; } else { $settings_file = $ARGV[0]; }

open(SETTINGS, "<$settings_file") or die "could not open SETTINGS";
while (<SETTINGS>)
{
	chop;
   ($id, $value) = split(/=/, $_, 2);

	$settings{$id} = $value;
}

#----------------------------------------------------------------
# parameters
#----------------------------------------------------------------
if ($ARGV[0] ne "") { $prm_file = $ARGV[0]; }
if ($ARGV[1] ne "") { $out_bn_file = $ARGV[1]; }

$startNodeStr = "pattribute[ ]";
$endNodeStr = "^[\}];";

$startProbStr = "for debugging purposes, the tree";
$endProbStr = "[\*]/";

$prm_file = $settings{"convert_prm_file"};
$bn_file = $settings{"convert_bn_file"};
$convert_rel = $settings{"convert_rel"};

print "prm=" . $prm_file . " bn=" . $bn_file . "\n";
open(PRM, "<$prm_file") or die "could not open $prm_file";
open(OUT_BN, ">$bn_file") or die "could not open $bn_file";

#---------------------------------------------------------------------------
# 
#---------------------------------------------------------------------------
print OUT_BN "network \"Test example\"\n";
print OUT_BN "{\n";
print OUT_BN "\tformat is \"BNFormat\";\n";
print OUT_BN "\tversion is 0.00;\n";
print OUT_BN "\tcreator is \"lcg\";\n";
print OUT_BN "}\n\n";

#---------------------------------------------------------------------------
# 
#---------------------------------------------------------------------------
$in_prob = 0;
$in_node = 0;

while(<PRM>)
{
  chop;

  #print OUT_BN $_  . "\n";

  if (/relation[ ](.*)/) { $relation = $1; $join_name = $settings{"join_for_$relation"}; }

  if (/${startNodeStr}/) { $in_node = 1; $num_rows_in_node = 0; }

  if (/${endNodeStr}/)
  {
	 if ($in_node == 1)
	 {
		print OUT_BN "position = (1,1);\n}\n\n";
		$in_node = 0;

		if ($num_rows_in_node > 0)
		{
		  $node_row[$num_rows_in_node] = "position = (1,1);\n}\n\n";
		  $num_rows_in_node++;
		}

		for ($i = 0; $i < $num_rows_in_node; $i++)
		{
		  if ($i == 0)
		  {
			 print OUT_BN "node " . $convert_rel . "__" . $join_name . "__" . $node_row[$i];
		  }
		  else
		  {
			 print OUT_BN $node_row[$i];
		  }
		}
	 }
  }

  if ($in_node == 1)
  {
	 $str = $_;

	 if ($str =~ /pattribute[ ](.*)/)
	 {
		#if ($1 =~ /(exp_level)/)
		if ($relation eq $convert_rel)
		{
		  print OUT_BN "node " . $relation . "__" . $1 . "\n";
		}
		else
		{
		  if ($num_rows_in_node == 0)
		  {
			 $node_row[$num_rows_in_node] = $1;
		  }
		  else
		  {
			 $node_row[$num_rows_in_node] = "node " . $relation . "__" . $1 . "\n";
		  }

		  $num_rows_in_node++;
		  print OUT_BN "node " . $relation . "__" . $1 . "\n";
		}
	 }
	 else
	 {
		if ($num_rows_in_node > 0)
		{
		  $node_row[$num_rows_in_node] = $_ . "\n";
		  $num_rows_in_node++;
		}

		print OUT_BN $_ . "\n";
	 }
  }

  if (/${endProbStr}/) { if ($in_prob == 1) { print OUT_BN "\n"; $in_prob = 0; } }

  if ($in_prob == 1)
  {
	 if (/tree/ && !/[\|]/) { $in_prob = 0; }
  }

  if ($in_prob == 1)
  {
	 if (/probability/ || /condition/)
	 {
		s/[\.]/__/g;
		s/FinalScore=.*//g;	
		s/InitialScore=.*//g;
		s/SplitScore=.*//g;
		s/DeltaScore=.*//g;
	 }

	 print OUT_BN $_ . "\n";
  }

  if (/${startProbStr}/) { $in_prob = 1; }
}
