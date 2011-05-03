#! /usr/bin/perl

#-----------------------------------------------------------------------------------------------------------
# input: 
#    mql - the command to run the mysql database
#    database - the database name
#    gene_rel_name - the gene table in the database
#    experiment_rel_name - the experiment table in the databaes
#    expressions_rel_name - the expression table in the database
#    prm_file - the name of the prm file to convert
#    output_file - the resulting sql_selects
#    num_attribute_db_tables - the number of attribute tables in the database
#    attribute_db_table<num> - the name of each of the attribute tables
#    attribute_join_from<num> - the name of the field in the GENES table by which to join the genes table with the attribute table
#    attribute_join_to<num> - the name of the field in the OTHER ATTRIBUTE table by which to join the genes table with the attribute table
#
# output:
#    converts the prm file to a bicluster file
#-----------------------------------------------------------------------------------------------------------

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
$mql = $settings{"mql"}; 
$database = $settings{"database"};

$gene_rel_name = $settings{"gene_rel_name"};
$experiment_rel_name = $settings{"experiment_rel_name"};
$expressions_rel_name = $settings{"expressions_rel_name"};

$prm_file = $settings{"prm_file"};
open(TREE_CPD, "<$prm_file") or die "could not open $prm_file";

$output_file = $settings{"output_file"};
open(OUTFILE, ">$output_file");

$startSearchStr = "probability[(]" . $settings{"expressions_rel_name"} . "[.]exp_level[ ][|]";
$probabilitySearchStr = "probability[ ][(]" . $settings{"expressions_rel_name"} . "[.]exp_level[)]";

$num_attribute_db_tables = $settings{"num_attribute_db_tables"};

#---------------------------------------------------------------------------
# execute
#---------------------------------------------------------------------------
sub execute
{
#  print $_[0] . "\n";
  system($_[0]);
}

#---------------------------------------------------------------------------
# trim leading spaces
#---------------------------------------------------------------------------
sub trim_leading_spaces
{
  $word = $_[0];

  if ($word =~ /^[\s]+(.*)/) { return $1; }
  else { return $word; }
}

#---------------------------------------------------------------------------
# trim all spaces
#---------------------------------------------------------------------------
sub trim_all_spaces
{
  $word = $_[0];

  $word =~ /([^\s]+)/;

  return $1;
}

#---------------------------------------------------------------------------
# parse the tree cpd
#---------------------------------------------------------------------------
sub build_feature_list
{
  for ($feature_table = 1; $feature_table <= $num_attribute_db_tables; $feature_table++)
  {
	$attribute_db_table = $settings{"attribute_db_table$feature_table"};
	execute "$mql -Ne 'desc $attribute_db_table' $database > $settings_file.table_dsc";

	open(TABLE_DESC, "<$settings_file.table_dsc") or die "could not open $settings_file.table_dsc";
	while (<TABLE_DESC>)
	{
	  chop;
	  
	  ($field, $remainder) = split(/\t/, $_, 2);
	  
	  $other_gene_table_attributes{$feature_table}{$field} = 1;
	}
  }

  execute "$mql -Ne 'desc $gene_rel_name' $database > $settings_file.table_dsc";

  open(TABLE_DESC, "<$settings_file.table_dsc") or die "could not open $settings_file.table_dsc";
  while (<TABLE_DESC>)
  {
	chop;

	($field, $remainder) = split(/\t/, $_, 2);

	$gene_attributes{$field} = 1;
  }

  execute "$mql -Ne 'desc $experiment_rel_name' $database > $settings_file.table_dsc";

  open(TABLE_DESC, "<$settings_file.table_dsc") or die "could not open $settings_file.table_dsc";
  while (<TABLE_DESC>)
  {
	chop;

	($field, $remainder) = split(/\t/, $_, 2);

	$experiment_attributes{$field} = 1;
  }
}

#---------------------------------------------------------------------------
# build_other_attribute_tables_from
#---------------------------------------------------------------------------
sub build_other_attribute_tables_from
{
  $res = "";
  for ($feature_table = 1; $feature_table <= $num_attribute_db_tables; $feature_table++)
  {
	$res .= "," . $settings{"attribute_db_table$feature_table"};
  }
  return $res
}

#---------------------------------------------------------------------------
# build_other_attribute_tables_from
#---------------------------------------------------------------------------
sub build_other_attribute_tables_from
{
  $res = "";
  for ($feature_table = 1; $feature_table <= $num_attribute_db_tables; $feature_table++)
  {
	$res .= "," . $settings{"attribute_db_table$feature_table"} . " as j$feature_table ";
  }
  return $res
}

#---------------------------------------------------------------------------
# build_other_attribute_tables_where
#---------------------------------------------------------------------------
sub build_other_attribute_tables_where
{
  $res = "";
  for ($feature_table = 1; $feature_table <= $num_attribute_db_tables; $feature_table++)
  {
	$res .= " and " . "j$feature_table" . "." . $settings{"attribute_join_to$feature_table"};
	$res .= "=" . $gene_rel_name . "." . $settings{"attribute_join_from$feature_table"};
  }
  return $res
}

#---------------------------------------------------------------------------
# add to the cluster matrix
#---------------------------------------------------------------------------
sub add_to_cluster_matrix
{
  $other_attribute_tables_from = build_other_attribute_tables_from;
  $other_attribute_tables_where = build_other_attribute_tables_where;

  #print "$mql -Ne \"select $gene_rel_name.gene_id from $gene_rel_name $other_attribute_tables_from $gene_where_clause $other_attribute_tables_where\" $database\n";
  if (length($gene_where_clause) == 0) { $gene_where_clause = " where 1=1 "; }
  execute "$mql -Ne \"select $gene_rel_name.gene_id from $gene_rel_name $other_attribute_tables_from $gene_where_clause $other_attribute_tables_where\" $database > $settings_file.table_dsc";

  print OUTFILE "$gene_where_clause $other_attribute_tables_where\t";

  print OUTFILE "Gene Ids=\t";
  $num_genes = 0;
  open(TABLE_DESC, "<$settings_file.table_dsc") or die "could not open $settings_file.table_dsc";
  while (<TABLE_DESC>)
  {
	chop;

	$gene_subset[$num_genes] = $_;
	$num_genes++;

	print OUTFILE "$_ ";
  }
  print OUTFILE "\t";

  execute "$mql -Ne \"select experiment_id from $experiment_rel_name $experiment_where_clause\" $database > $settings_file.table_dsc";

  print OUTFILE "Experiment Ids=\t";
  $num_experiments = 0;
  open(TABLE_DESC, "<$settings_file.table_dsc") or die "could not open $settings_file.table_dsc";
  while (<TABLE_DESC>)
  {
	chop;

	$experiment_subset[$num_experiments] = $_;
	$num_experiments++;

	print OUTFILE "$_ ";
  }
  print OUTFILE "\n";
}

#---------------------------------------------------------------------------
# parse the tree cpd
#---------------------------------------------------------------------------
sub parse_tree_cpd
{
  $SPLIT_1 = 0;
  $SPLIT_2 = 1;
  $IN_SPLIT_1 = 2;
  $IN_SPLIT_2 = 3;
  $PROBABILITY = 4;
  $NONE = 5;

  $STATUS_SPLIT = 0;
  $STATUS_PROBABILITY = 1;
  $STATUS_POP = 2;
  $STATUS_NONE = 3;

  $row_num = 0;
  $now_parsing = 0;
  $mode = $NONE;
  $stack_num = 0;

  while(<TREE_CPD>)
  {
	chop;

	$trimmed = trim_leading_spaces($_);
	$_ = $trimmed;

	if (/${startSearchStr}/) { $now_parsing = 1; }

    $status = $STATUS_NONE;
    if (/split[ ]on[ ]condition/) { $status = $STATUS_SPLIT; }
    if (/${probabilitySearchStr}/) { $status = $STATUS_PROBABILITY; }
    if ($_ eq "}") { $status = $STATUS_POP; }

    if ($now_parsing == 1)
    {
	  $stack_mode = $NONE;
	  if ($stack_num > 0) { $stack_mode = $stack_modes[$stack_num - 1]; }
	  
	  #print $status . " " . $stack_mode . " - LL" . $_ . "LL\n";
	  
	  if ($status == $STATUS_SPLIT)
	  {
		#print "splitting $_\n";

		@conditions = split(/\./);
		$num_conditions = @conditions;
		
		$conditions[$num_conditions-1] =~ /([^ ]+)[^\"]+"([^\"]+)"/;

		if ($stack_num > 0) { $parent_split = "ParentSplit=\"$stack_values[$stack_num-1]\""; } else { $parent_split=""; }

		$stack_attributes[$stack_num] = $1;
		$stack_conditions[$stack_num] = $2;
		$stack_modes[$stack_num] = $SPLIT_1;
		$stack_num++;
	  }
	  elsif ($status == $STATUS_NONE && $stack_mode == $SPLIT_1)
	  {
		$_ =~ /([^ ]+)/;
		
		$stack_values[$stack_num - 1] = $1;
		$stack_modes[$stack_num - 1] = $IN_SPLIT_1;
		
		#print "split1=$stack_values[$stack_num - 1] \n";
	  }
	  elsif ($status == $STATUS_NONE && $stack_mode == $SPLIT_2)
	  {
		$_ =~ /([^ ]+)/;
		
		if ($1 eq "true")
		{
 	      $stack_values[$stack_num - 1] = $1;
          $stack_modes[$stack_num - 1] = $IN_SPLIT_2;
		  
          #print "split2=$stack_values[$stack_num - 1] \n";
		}
	  }
	  elsif ($status == $STATUS_POP)
	  {
		if ($stack_modes[$stack_num - 1] == $IN_SPLIT_1)
		{
		  #print "popping from $stack_attributes[$stack_num - 1]=$stack_conditions[$stack_num - 1]$stack_values[$stack_num - 1]\n";
		  $stack_modes[$stack_num - 1] = $SPLIT_2;
		}
		elsif ($stack_modes[$stack_num - 1] == $IN_SPLIT_2)
		{
		  #print "popping from " . $stack_attributes[$stack_num - 1] . "=" . $stack_conditions[$stack_num - 1] . "=" . $stack_values[$stack_num - 1] . "\n";
		  
		  $stack_num--;

		  if ($stack_num == 0) { last; }
		}
	  }
	  elsif ($status == $STATUS_PROBABILITY)
	  {
		#print "probability $_\n";

		if ($stack_num > 1) { $parent_split = "ParentSplit=\"$stack_values[$stack_num-1]\""; } else { $parent_split=""; }

		$gene_where_clause = "";
		$experiment_where_clause = "";
		$gene_first = 1;
		$experiment_first = 1;

		for ($i = 0; $i < $stack_num; $i++)
		{
		  #print $stack_attributes[$i] . "\t" . $stack_conditions[$i] . "\t" . $stack_values[$i] . "\t\n";

		  $attr = $stack_attributes[$i];
		  if ($stack_attributes[$i] =~ /hidden_(.*)/)
		  {
			$stack_attributes[$i] =~ /hidden_(.*)/;
			$attr = $1;
		  }

		  if ($gene_attributes{$attr} eq "1")
		  {
			if ($gene_first == 0) { $gene_where_clause = $gene_where_clause . " and "; }
			elsif ($gene_first == 1) { $gene_where_clause = "where "; $gene_first = 0; }
			
			if ($stack_values[$i] eq "false") { $gene_where_clause .= $gene_rel_name . "." . $attr . "!='$stack_conditions[$i]' "; }
			elsif ($stack_values[$i] eq "true") { $gene_where_clause .= $gene_rel_name . "." . $attr . "='$stack_conditions[$i]' "; }
		  }
		  elsif ($experiment_attributes{$attr} eq "1")
		  {
			if ($experiment_first == 0) { $experiment_where_clause = $experiment_where_clause . " and "; }
			elsif ($experiment_first == 1) { $experiment_where_clause = "where "; $experiment_first = 0; }
			
			if ($stack_values[$i] eq "false") { $experiment_where_clause .= $experiment_rel_name . "." . $attr . "!='$stack_conditions[$i]' "; }
			elsif ($stack_values[$i] eq "true") { $experiment_where_clause .= $experiment_rel_name . "." . $attr . "='$stack_conditions[$i]' "; }
		  }
		  else
		  {
			for ($feature_table = 1; $feature_table <= $num_attribute_db_tables; $feature_table++)
			{
			  if ($other_gene_table_attributes{$feature_table}{$attr} eq "1")
			  {
				$attribute_db_table = $settings{"attribute_db_table$feature_table"};

				if ($gene_first == 0) { $gene_where_clause = $gene_where_clause . " and "; }
				elsif ($gene_first == 1) { $gene_where_clause = "where "; $gene_first = 0; }
			
				if ($stack_values[$i] eq "false") { $gene_where_clause .= "j$feature_table" . "." . $attr . "!='$stack_conditions[$i]' "; }
				elsif ($stack_values[$i] eq "true") { $gene_where_clause .= "j$feature_table" . "." . $attr . "='$stack_conditions[$i]' "; }
			  }
			}
		  }
		}

		#print "gene where = $gene_where_clause\t\n";
		#print "experiment where = $experiment_where_clause\t\n";

		add_to_cluster_matrix;
	  }
	}
  }
}

#-----
# MAIN
#-----
build_feature_list;
open(TREE_CPD, "<$prm_file") or die "could not open $prm_file";
parse_tree_cpd;

execute("rm $settings_file.table_dsc");
