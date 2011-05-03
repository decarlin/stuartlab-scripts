#! /usr/bin/perl

#---------------------------------------------------------------------------------------------------------------------------------------------------------
# input: 
#    BCTB_mql - the command to run the mysql database
#    BCTB_database - the database name
#    BCTB_gene_rel_name - the gene table in the database
#    BCTB_experiment_rel_name - the experiment table in the databaes
#    BCTB_expressions_rel_name - the expression table in the database
#    BCTB_prm_file - the name of the prm file to convert
#    BCTB_add_attributes - 0:no attributes, 1:add attributes
#    BCTB_output_file - the resulting bicluster
#    BCTB_dictionary_file - the dictionary file to use for converting gene ids to their description (format: col1: gene id, col2: gene name, col3: gene dsc
#    BCTB_num_attribute_db_tables - the number of attribute tables in the database
#    BCTB_attribute_db_table<num> - the name of each of the attribute tables
#    BCTB_attribute_join_from<num> - the name of the field in the GENES table by which to join the genes table with the attribute table
#    BCTB_attribute_join_to<num> - the name of the field in the OTHER ATTRIBUTE table by which to join the genes table with the attribute table
#    BCTB_num_experiment_groups - the number of experiment groups that will be placed together (e.g. for time series)
#    BCTB_experiment_group_i - a list of the experiment names, separated by semicolons (e.g. nitrogen 1;nitrogen 2)
#
#    FOR BIO_ATTRIBUTES_TO_BICLUSTER.PL which is called internally
#    BATB_mql - database access
#    BATB_database - the name of the database to use
#
#    BATB_num_attribute_db_tables - the number of attribute tables that we're going to use
#    BATB_attribute_db_table<num> - the table name of the <num> attribute table
#    BATB_attribute_list_file<num> - list of attributes to include (columns in attribute_db_table) for the <num> attribute table
#    BATB_attribute_gene_column_name<num> - the name of the gene column in the db table of the <num> attribute table
#
#    BATB_gene_list_file - list of the genes to output    
#    BATB_ignore_attribute_value - if the value of the attribute is equal to this, don't print it (since we use a sparse representation in the visualizer)
#
# output:
#    converts the prm file to a bicluster file
#---------------------------------------------------------------------------------------------------------------------------------------------------------

use strict;

require "$ENV{MYPERLDIR}/lib/bio_load_settings.pl";
require "$ENV{MYPERLDIR}/lib/bio_execute.pl";
require "$ENV{MYPERLDIR}/lib/bio_str.pl";

my $settings_file;
if (length($ARGV[0]) == 0) { $settings_file = "settings"; } else { $settings_file = $ARGV[0]; }
my %settings = load_settings($ARGV[0]);

#----------------------------------------------------------------
# parameters
#----------------------------------------------------------------
my $dictionary_file = $settings{"BCTB_dictionary_file"};

my $mql = $settings{"BCTB_mql"};
my $database = $settings{"BCTB_database"};
my $gene_rel_name = $settings{"BCTB_gene_rel_name"};
my $experiment_rel_name = $settings{"BCTB_experiment_rel_name"};
my $expressions_rel_name = $settings{"BCTB_expressions_rel_name"};
my $add_attributes = $settings{"BCTB_add_attributes"};
my $output_file = $settings{"BCTB_output_file"};
my $num_attribute_db_tables = $settings{"BCTB_num_attribute_db_tables"};
my $num_experiment_groups = $settings{"BCTB_num_experiment_groups"};

my $prm_file;
if (length($ARGV[1]) > 0) { $prm_file = $ARGV[1]; }
else { $prm_file = $settings{"BCTB_prm_file"}; }
open(TREE_CPD, "<$prm_file") or die "could not open prm $prm_file";

my $exp_level_attr;
if ($num_experiment_groups > 0) { $exp_level_attr = "exp_level_0"; } else { $exp_level_attr = "exp_level"; }

my $startSearchStr = "probability[(]" . $expressions_rel_name . "[.]" . $exp_level_attr . "[ ][|]";
my $probabilitySearchStr = "probability[ ][(]" . $expressions_rel_name . "[.]" . $exp_level_attr . "[)]";

open(BICLUSTER_FILE, ">$output_file") or die "could not open bicluster";

my $r = int(rand 1000000000);

my $verbose = 0;

my %dictionary;

my %gene_ids;
my @sorted_gene_ids;
my $num_gene_ids = 0;

my %experiment_ids;
my @sorted_experiment_ids;
my $num_experiment_ids = 0;

my $total_num_leaves;
my $num_leaves;
my $num_clusters;

my @num_experiments_in_group;
my @experiment_groups_names;

my %other_gene_table_attributes;

my %gene_attributes;
my %experiment_attributes;

my $gene_where_clause;
my $experiment_where_clause;
my %matrix;
my $current_cluster;

#---------------------------------------------------------------------------
# load dictionary
#---------------------------------------------------------------------------
sub load_dictionary
{
  open(DICTIONARY, "<$dictionary_file");
  while (<DICTIONARY>)
  {
    chop;
    my @dictionary_data = split(/\t/);

    $dictionary{$dictionary_data[0]} = remove_illegal_chars($dictionary_data[1]) . " - " . remove_illegal_chars($dictionary_data[2]);

    #print "dictionary{$dictionary_data[0]}" . "=\t" . $dictionary{$dictionary_data[0]} . "\n";
  }
}

#---------------------------------------------------------------------------
# load_experiment_groups
#---------------------------------------------------------------------------
sub load_experiment_groups
{
  if ($num_experiment_groups > 0)
  {
    for (my $i = 1; $i <= $num_experiment_groups; $i++)
    {
      my $experiment_attr_str = $settings{"BCTB_experiment_group_$i"};
      my @splitted_experiment_attrs = split(/\;/, $experiment_attr_str);
      my $num_experiment_attrs = @splitted_experiment_attrs;

      $num_experiments_in_group[$i - 1] = $num_experiment_attrs;

      for (my $j = 0; $j < $num_experiment_attrs; $j++)
      {
        $experiment_groups_names[$i - 1][$j] = $splitted_experiment_attrs[$j];
      }
    }
  }
}

#---------------------------------------------------------------------------
# remove_illegal_chars
#---------------------------------------------------------------------------
sub remove_illegal_chars
{
  my $str = $_[0];
  $str =~ s/[\s]&[\s]/ and /g;
  $str =~ s/&[\s]/ and/g;
  $str =~ s/[\s]&/and /g;
  $str =~ s/&/ and /g;
  $str =~ s/\"//g;
  $str =~ s/\`//g;
  $str =~ s/\.//g;
  $str =~ s/\'//g;
  $str =~ s/\;//g;
  $str =~ s/\://g;
  $str =~ s/\)//g;
  $str =~ s/\<//g;
  $str =~ s/\>//g;
  $str =~ s/\(//g;
  $str =~ s/\=//g;
  $str =~ s/\#//g;
  $str =~ s/\@//g;
  $str =~ s/\\//g;
  $str =~ s/[\/]//g;
  $str =~ s/[\+]//g;
  return $str;
}

#---------------------------------------------------------------------------
# print the raw data
#---------------------------------------------------------------------------
sub print_raw_data
{
  my %raw_data;

  print BICLUSTER_FILE "\n<TSCRawData>\n";

  if ($num_experiment_groups > 0)
  {
    my $exp_level_select_str = "";
    for (my $i = 0; $i < $num_experiments_in_group[0]; $i++)
    {
      $exp_level_select_str .= ",exp_level_$i";
    }
    execute("$mql -Ne 'select gene,experiment $exp_level_select_str from $expressions_rel_name' $database > $settings_file.table_dsc", $verbose);
  }
  else
  {
    execute("$mql -Ne 'select gene,experiment,exp_level from $expressions_rel_name' $database > $settings_file.table_dsc", $verbose);
  }

  open(TABLE_DESC, "<$settings_file.table_dsc") or die "could not open $settings_file.table_dsc";
  while (<TABLE_DESC>)
  {
    chop;

    my $gene;
    my $experiment;
    my $exp_level;
    ($gene, $experiment, $exp_level) = split(/\t/, $_, 3);

    if ($num_experiment_groups > 0)
    {
      my @all_exp_levels = split(/\t/, $exp_level);
      for (my $i = 0; $i < $num_experiments_in_group[0]; $i++)
      {
        my $updated_experiment = ($experiment * $num_experiments_in_group[0]) + $i;
        $exp_level = trim_all_spaces($all_exp_levels[$i]);
        $raw_data{$gene}{$updated_experiment} = $exp_level;

        if ($experiment_ids{$updated_experiment} ne "1")
        {
          $experiment_ids{$updated_experiment} = "1";

          $sorted_experiment_ids[$num_experiment_ids] = $updated_experiment;
          $num_experiment_ids++;
        }
      }
    }
    else
    {
      $exp_level = trim_all_spaces($exp_level);
      $raw_data{$gene}{$experiment} = $exp_level;

      if ($experiment_ids{$experiment} ne "1")
      {
        $experiment_ids{$experiment} = "1";

        $sorted_experiment_ids[$num_experiment_ids] = $experiment;
        $num_experiment_ids++;
      }
    }

    if ($gene_ids{$gene} ne "1")
    {
      $gene_ids{$gene} = "1";

      $sorted_gene_ids[$num_gene_ids] = $gene;
      $num_gene_ids++;
    }
  }

  @sorted_experiment_ids = sort { $a <=> $b } @sorted_experiment_ids;
  @sorted_gene_ids = sort { $a <=> $b } @sorted_gene_ids;

  my %experiment_names;

  if ($num_experiment_groups > 0)
  {
    my $id = 0;
    for (my $i = 0; $i < $num_experiment_groups; $i++)
    {
      for (my $j = 0; $j < $num_experiments_in_group[$i]; $j++)
      {
        $experiment_names{$id} = $experiment_groups_names[$i][$j];
        $id++;
      }
    }
  }
  else
  {
    execute("$mql -Ne 'select experiment_id, name from $experiment_rel_name' $database > $settings_file.table_dsc", $verbose);

    open(TABLE_DESC, "<$settings_file.table_dsc") or die "could not open $settings_file.table_dsc";
    while (<TABLE_DESC>)
    {
      chop;

      my $id;
      my $name;
      ($id, $name) = split(/\t/);

      $experiment_names{$id} = $name;
    }
  }

  execute("$mql -Ne 'select gene_id, gene_name from $gene_rel_name' $database > $settings_file.table_dsc", $verbose);
  my %gene_names;

  open(TABLE_DESC, "<$settings_file.table_dsc") or die "could not open $settings_file.table_dsc";
  while (<TABLE_DESC>)
  {
    chop;

    my $id;
    my $name;
    ($id, $name) = split(/\t/);

    $gene_names{$id} = $name;
  }

  print BICLUSTER_FILE "UID\tNAME\tGWEIGHT\t";
  #my $e_i;
  #foreach $e_i (keys(%experiment_ids))
  for (my $exp_idx = 0; $exp_idx < $num_experiment_ids; $exp_idx++)
  {
	 my $e_i = $sorted_experiment_ids[$exp_idx];

    print BICLUSTER_FILE "$experiment_names{$e_i}\t";
  }
  print BICLUSTER_FILE "\n";

  #my $g_i;
  #foreach $g_i (keys(%gene_ids))
  for (my $gene_idx = 0; $gene_idx < $num_gene_ids; $gene_idx++)
  {
    my $g_i = $sorted_gene_ids[$gene_idx];
    my $gene_description;

    # PATCH FOR AFFY CHIPS
    my $probe_dsc = $gene_names{$g_i};
    $probe_dsc =~ s/.*_at_//g;
    $probe_dsc =~ s/.*_AT_//g;

    # PATCH FOR C. ELEGANS
    my $probe_dsc2 = $gene_names{$g_i};
    $probe_dsc2 =~ s/_/./g;

    if (length($dictionary{$gene_names{$g_i}}) > 0)
    {
      $gene_description = $dictionary{$gene_names{$g_i}};
    }
    elsif (length($dictionary{$probe_dsc}) > 0)
    {
      $gene_description = $dictionary{$probe_dsc};
    }
    elsif (length($dictionary{$probe_dsc2}) > 0)
    {
      $gene_description = $dictionary{$probe_dsc2};
    }
    else
    {
      $gene_description = $gene_names{$g_i};
    }

    print BICLUSTER_FILE "$gene_names{$g_i}\t$gene_description\t1\t";
    #print BICLUSTER_FILE "$gene_description\t$gene_description\t1\t";

    #my $e_i;
    #foreach $e_i (keys(%experiment_ids))
	 for (my $exp_idx = 0; $exp_idx < $num_experiment_ids; $exp_idx++)
    {
		my $e_i = $sorted_experiment_ids[$exp_idx];
      if ($raw_data{$g_i}{$e_i} =~ /\S/ && $raw_data{$g_i}{$e_i} ne "NULL")
      {
        print BICLUSTER_FILE "$raw_data{$g_i}{$e_i}\t";
      }
      else
      {
        #print BICLUSTER_FILE "0\t";
        print BICLUSTER_FILE "\t";
      }
    }
    print BICLUSTER_FILE "\n";
  }
  print BICLUSTER_FILE "</TSCRawData>\n"
}

#---------------------------------------------------------------------------
# count_leaves and total clusters
#---------------------------------------------------------------------------
sub get_counts_for_tree_cpd
{
  $num_leaves = 0;
  $num_clusters = 0;

  my $SPLIT_1 = 0;
  my $SPLIT_2 = 1;
  my $IN_SPLIT_1 = 2;
  my $IN_SPLIT_2 = 3;
  my $PROBABILITY = 4;
  my $NONE = 5;

  my $STATUS_SPLIT = 0;
  my $STATUS_PROBABILITY = 1;
  my $STATUS_POP = 2;
  my $STATUS_NONE = 3;

  my $row_num = 0;
  my $now_parsing = 0;
  my $mode = $NONE;
  my $stack_num = 0;

  my $status;
  my $stack_mode;
  my @stack_modes;

  while(<TREE_CPD>)
  {
  chop;

  my $trimmed = trim_leading_spaces($_);
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

    if ($status == $STATUS_SPLIT)
    {
		$num_clusters++;

		$stack_modes[$stack_num] = $SPLIT_1;
		$stack_num++;
    }
    elsif ($status == $STATUS_NONE && $stack_mode == $SPLIT_1)
    {
		$stack_modes[$stack_num - 1] = $IN_SPLIT_1;
    }
    elsif ($status == $STATUS_NONE && $stack_mode == $SPLIT_2)
    {
		$_ =~ /([^ ]+)/;
		if ($1 eq "true")
		{
		  $stack_modes[$stack_num - 1] = $IN_SPLIT_2;
		}
    }
    elsif ($status == $STATUS_POP)
    {
		if ($stack_modes[$stack_num - 1] == $IN_SPLIT_1)
		{
		  $stack_modes[$stack_num - 1] = $SPLIT_2;
		}
		elsif ($stack_modes[$stack_num - 1] == $IN_SPLIT_2)
		{
		  $stack_num--;

		  if ($stack_num == 0) { last; }
		}
    }
    elsif ($status == $STATUS_PROBABILITY)
    {
    $num_leaves++;
    }
  }
  }

  $total_num_leaves = $num_leaves;
  $num_clusters += $num_leaves;
  print "clusters=" . $num_clusters . " leaves=" . $num_leaves . "\n";
}

#---------------------------------------------------------------------------
# parse the tree cpd
#---------------------------------------------------------------------------
sub build_feature_list
{
  my $feature_table;
  for ($feature_table = 1; $feature_table <= $num_attribute_db_tables; $feature_table++)
  {
	 my $attribute_db_table = $settings{"attribute_db_table$feature_table"};
	 execute("$mql -Ne 'desc $attribute_db_table' $database > $settings_file.table_dsc", $verbose);

	 open(TABLE_DESC, "<$settings_file.table_dsc") or die "could not open $settings_file.table_dsc";
	 while (<TABLE_DESC>)
	 {
		chop;

		my $field;
		my $remainder;
		($field, $remainder) = split(/\t/, $_, 2);
		
		$other_gene_table_attributes{$feature_table}{$field} = 1;
	 }
  }

  execute("$mql -Ne 'desc $gene_rel_name' $database > $settings_file.table_dsc", $verbose);

  open(TABLE_DESC, "<$settings_file.table_dsc") or die "could not open $settings_file.table_dsc";
  while (<TABLE_DESC>)
  {
	 chop;

	 my $field;
	 my $remainder;
	 ($field, $remainder) = split(/\t/, $_, 2);

	 $gene_attributes{$field} = 1;
  }

  execute("$mql -Ne 'desc $experiment_rel_name' $database > $settings_file.table_dsc", $verbose);

  open(TABLE_DESC, "<$settings_file.table_dsc") or die "could not open $settings_file.table_dsc";
  while (<TABLE_DESC>)
  {
	 chop;

	 my $field;
	 my $remainder;
	 ($field, $remainder) = split(/\t/, $_, 2);

	 $experiment_attributes{$field} = 1;
  }
}

#---------------------------------------------------------------------------
# build_other_attribute_tables_from
#---------------------------------------------------------------------------
sub build_other_attribute_tables_from
{
  my $res = "";
  my $feature_table;
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
  my $res = "";
  my $feature_table;
  for ($feature_table = 1; $feature_table <= $num_attribute_db_tables; $feature_table++)
  {
  $res .= " and " . "j$feature_table" . "." . $settings{"attribute_join_to$feature_table"};
  $res .= "=" . $gene_rel_name . "." . $settings{"attribute_join_from$feature_table"};
  }
  return $res
}
my $i = 0;
#---------------------------------------------------------------------------
# add to the cluster matrix
#---------------------------------------------------------------------------
sub add_to_cluster_matrix
{
  my $other_attribute_tables_from = build_other_attribute_tables_from;
  my $other_attribute_tables_where = build_other_attribute_tables_where;

  #print "ADD_TO_CLUSTER_MATRIX\n";
  #print "$mql -Ne \"select $gene_rel_name.gene_id from $gene_rel_name $other_attribute_tables_from $gene_where_clause $other_attribute_tables_where\" $database\n";
 if (length($gene_where_clause) == 0) { $gene_where_clause = " where 1=1 "; }
  execute("$mql -Ne \"select $gene_rel_name.gene_id from $gene_rel_name $other_attribute_tables_from $gene_where_clause $other_attribute_tables_where\" $database > $settings_file.table_dsc", $verbose);

  my $num_genes = 0;
  my @gene_subset;
  open(TABLE_DESC, "<$settings_file.table_dsc") or die "could not open $settings_file.table_dsc";
  while (<TABLE_DESC>)
  {
    chop;

    $gene_subset[$num_genes] = $_;
    $num_genes++;
  }

  #print "$mql -Ne \"select experiment_id from $experiment_rel_name $experiment_where_clause\" $database\n";
  if (length($experiment_where_clause) == 0) { $experiment_where_clause = " where 1=1 "; }
  execute("$mql -Ne \"select experiment_id from $experiment_rel_name $experiment_where_clause\" $database > $settings_file.table_dsc", $verbose);

  my $num_experiments = 0;
  my @experiment_subset;
  open(TABLE_DESC, "<$settings_file.table_dsc") or die "could not open $settings_file.table_dsc";
  while (<TABLE_DESC>)
  {
    chop;

    if ($num_experiment_groups > 0)
    {
      for (my $i = 0; $i < $num_experiments_in_group[$_]; $i++)
      {
        $experiment_subset[$num_experiments] = ($_ * $num_experiments_in_group[0]) + $i;
        $num_experiments++;
      }
    }
    else
    {
      $experiment_subset[$num_experiments] = $_;
      $num_experiments++;
    }
  }

  for (my $g_i = 0; $g_i < $num_genes; $g_i++)
  {
    for (my $e_i = 0; $e_i < $num_experiments; $e_i++)
    {
      if (length($matrix{$gene_subset[$g_i]}{$experiment_subset[$e_i]}) > 0)
      {
        print "ENTRY FOR CLUSTER ALREADY FILLED - GENE_ID=$gene_subset[$g_i] EXPERIMENT_ID=$experiment_subset[$e_i] ";
        print "PREVIOUS VALUE=$matrix{$gene_subset[$g_i]}{$experiment_subset[$e_i]} CURRENT_VALUE=$current_cluster\n";
      }

      $matrix{$gene_subset[$g_i]}{$experiment_subset[$e_i]} = $current_cluster;
      #print "($gene_subset[$g_i],$experiment_subset[$e_i]) = $matrix{$gene_subset[$g_i]}{$experiment_subset[$e_i]}\n";
    }
  }
}

#---------------------------------------------------------------------------
# print the cluster matrix
#---------------------------------------------------------------------------
sub print_cluster_matrix
{
  print BICLUSTER_FILE "\n<TSCClusterData NumClusters=\"$total_num_leaves\">\n";

  #my $g_i;
  #foreach $g_i (keys(%gene_ids))
  for (my $gene_idx = 0; $gene_idx < $num_gene_ids; $gene_idx++)
  {
	 my $g_i = $sorted_gene_ids[$gene_idx];
    #my $e_i;
    #foreach $e_i (keys(%experiment_ids))
	 for (my $exp_idx = 0; $exp_idx < $num_experiment_ids; $exp_idx++)
    {
		my $e_i = $sorted_experiment_ids[$exp_idx];

      if (length($matrix{$g_i}{$e_i}) == 0)
      {
        print BICLUSTER_FILE "PROBLEM IN GENE_ID=$g_i and\tEXPERIMENT_ID=$e_i\n";
        print "PROBLEM IN GENE_ID=$g_i and\tEXPERIMENT_ID=$e_i\n";
      }

      print BICLUSTER_FILE "$matrix{$g_i}{$e_i}\t";
    }
    print BICLUSTER_FILE "\n";
  }

  print BICLUSTER_FILE "</TSCClusterData>\n";
}

#---------------------------------------------------------------------------
# parse the tree cpd
#---------------------------------------------------------------------------
sub parse_tree_cpd
{
  print BICLUSTER_FILE "\n<TSCHierarchyClusterData NumClusters=\"$num_clusters\">\n";
  $num_clusters--;
  $num_leaves--;

  my $SPLIT_1 = 0;
  my $SPLIT_2 = 1;
  my $IN_SPLIT_1 = 2;
  my $IN_SPLIT_2 = 3;
  my $PROBABILITY = 4;
  my $NONE = 5;

  my $STATUS_SPLIT = 0;
  my $STATUS_PROBABILITY = 1;
  my $STATUS_POP = 2;
  my $STATUS_NONE = 3;

  my $row_num = 0;
  my $now_parsing = 0;
  my $mode = $NONE;
  my $stack_num = 0;

  my $status;
  my $stack_mode;
  my @stack_modes;

  my @conditions;
  my $num_conditions;

  my $parent_split;
  my @stack_values;
  my @stack_attributes;
  my @stack_conditions;

  my $gene_first;
  my $experiment_first;
  my $indent;

  while(<TREE_CPD>)
  {
  chop;

  my $trimmed = trim_leading_spaces($_);
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

    for ($indent = 0; $indent < $stack_num; $indent++) { print BICLUSTER_FILE "  "; }
    if ($stack_num == 0) { print BICLUSTER_FILE "<Root ClusterNum=\"$num_clusters\" NumChildren=\"2\" "; }
    else { print BICLUSTER_FILE "<Child ClusterNum=\"$num_clusters\" NumChildren=\"2\" "; }
    print BICLUSTER_FILE "SplitAttribute=\"" . remove_illegal_chars($1) . "\" SplitValue=\"" . remove_illegal_chars($2) . "\" $parent_split>\n";
    $num_clusters--;

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

		  for ($indent = 0; $indent < $stack_num; $indent++) { print BICLUSTER_FILE "  "; }

		  if ($stack_num == 0) { last; }

		  print BICLUSTER_FILE "</Child>\n";
		}
    }
    elsif ($status == $STATUS_PROBABILITY)
    {
    #print "probability $_\n";

    if ($stack_num > 1) { $parent_split = "ParentSplit=\"$stack_values[$stack_num-1]\""; } else { $parent_split=""; }

    for ($indent = 0; $indent < $stack_num; $indent++) { print BICLUSTER_FILE "  "; }
    print BICLUSTER_FILE "<Child ClusterNum=\"$num_leaves\" NumChildren=\"0\" ";
    print BICLUSTER_FILE "$parent_split>\n";
    for ($indent = 0; $indent < $stack_num; $indent++) { print BICLUSTER_FILE "  "; }
    print BICLUSTER_FILE "</Child>\n";
    $num_leaves--;

    $gene_where_clause = "";
    $experiment_where_clause = "";
    $gene_first = 1;
    $experiment_first = 1;

    my $i;
    for ($i = 0; $i < $stack_num; $i++)
    {
      #print $stack_attributes[$i] . "\t" . $stack_conditions[$i] . "\t" . $stack_values[$i] . "\t\n";

      my $attr = $stack_attributes[$i];
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
		  my $feature_table;
		  for ($feature_table = 1; $feature_table <= $num_attribute_db_tables; $feature_table++)
		  {
			 if ($other_gene_table_attributes{$feature_table}{$attr} eq "1")
			 {
				my $attribute_db_table = $settings{"attribute_db_table$feature_table"};
				
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

    $current_cluster = $num_leaves + 1;

    add_to_cluster_matrix;
  }
  }
  }

  print BICLUSTER_FILE "</Root>\n";
  print BICLUSTER_FILE "</TSCHierarchyClusterData>\n";

  print "Ended with clusters=$num_clusters leaves=$num_leaves\n";
}

#-----------------
# print_attributes
#-----------------
sub print_attributes
{
  if ($add_attributes == 1)
  {
	 execute("$ENV{HOME}/develop/perl/bio/bio_attributes_to_bicluster.pl $settings_file tmp.$r", $verbose);

	 open(ATTRIBUTES, "<tmp.$r") or die "could not open attributes file tmp.$r expected from bio_attributes_to_bicluster.pl\n";

	 while (<ATTRIBUTES>)
	 {
		print BICLUSTER_FILE $_;
	 }

	 execute("rm tmp.$r", $verbose);
  }
}

#-----
# MAIN
#-----
print BICLUSTER_FILE "<?xml version='1.0' encoding='iso-8859-1'?>\n\n<TSC>\n";
#print BICLUSTER_FILE "<?xml version='1.0' encoding='utf-8'?>\n\n<TSC>\n";

load_dictionary;
load_experiment_groups;
print_raw_data;
build_feature_list;
get_counts_for_tree_cpd;
open(TREE_CPD, "<$prm_file") or die "could not open $prm_file";
parse_tree_cpd;
print_cluster_matrix;
print_attributes;

print BICLUSTER_FILE "\n</TSC>\n";

execute("rm $settings_file.table_dsc");
