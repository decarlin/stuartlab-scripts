#! /usr/bin/perl

#-------------------------------------------------------------------------------------------------------------------------------------------------
# input: 
#    BRPH_mql = the mql execution command
#    BRPH_database = the database to use
#    BRPH_prefix = the prefix of the files
#    BRPH_gene_table = the name of the gene table
#    BRPH_dir = the directory on which we work on
#    BRPH_round_robin = the number of times to iterate through all the hide groups
#    BRPH_iteration = the iteration number. CAN ALSO BE PASSED IN ARGV[1]
#    BRPH_exp_level_time_series_length = the number of attributes (exp_level_0,exp_level_1,...) in the time series or 0 if there is no time series
#    BRPH_hide_groups = the number of hide groups
#    BRPH_hide_group_num_i = the number of attributes in the i-th group
#    BRPH_hide_group_i_j = the j-th attribute that we want to hide in each em
#    BRPH_hide_group_table_i_j = the table of the j-th attribute/s that is being hidden in the group
#    BRPH_hide_group_table_key_i_j = the key of the table of the j-th attribute/s that is being hidden in the group
#    BRPH_hide_group_first_cluster_i_j = the first cluster of the j-th attribute/s that is being hidden in the group
#    BRPH_hide_group_column_type_i_j = the type of the j-th column that belongs to the group
#
#    BRPH_hide_parents_of = a list of attributes separated_ by commas -- only hide attributes that are parents of this list (e.g. exp_level)
#
# output:
#    run the hidden prm
#-------------------------------------------------------------------------------------------------------------------------------------------------

use strict;

require "$ENV{MYPERLDIR}/lib/bio_load_settings.pl";
require "$ENV{MYPERLDIR}/lib/bio_execute.pl";
require "$ENV{MYPERLDIR}/lib/bio_system.pl";
require "$ENV{MYPERLDIR}/lib/bio_change_attribute_in_file.pl";

my %settings = load_settings($ARGV[0]);

my $mql = $settings{"BRPH_mql"};
my $database = $settings{"BRPH_database"};
my $prefix = $settings{"BRPH_prefix"};
my $gene_table = $settings{"BRPH_gene_table"};
my $dir = $settings{"BRPH_dir"};
my $round_robin = $settings{"BRPH_round_robin"};
my $hide_groups = $settings{"BRPH_hide_groups"};
my $exp_level_time_series_length = $settings{"BRPH_exp_level_time_series_length"};

my $iteration;
if (length($ARGV[1]) > 0) { $iteration = $ARGV[1]; }
else { $iteration = $settings{"BRPH_iteration"}; }

my $next_iteration = $iteration + 1;

my $experiment_table = "c_$gene_table";
my $expression_table = "e_$gene_table";

my $verbose = 1;

my @num_hide_attributes;
my @hide_attributes;
my @hide_tables;
my @hide_tables_keys;
my @hide_first_clusters;
my @hide_types;

my $r = int(rand 1000000000);

my $total_em_executions = 0;

my %parents_of_attributes;

#----------------------------------------------------------------
# load_allowed_hide_attributes
#----------------------------------------------------------------
sub load_allowed_hide_attributes
{
  my $hide_parents_of = $settings{"BRPH_hide_parents_of"};

  if (length($hide_parents_of) > 0)
  {
    my @parents = split(/\,/, $hide_parents_of);
    my $structure_file = "$dir/out/${prefix}_$iteration.out";

    for (my $i = 0; $i < @parents; $i++)
    {
      my $parent = $parents[$i];

      execute("grep -n \"$parent [\|]\" $structure_file > tmp.$r");
      open(TMP, "<tmp.$r");
      while(<TMP>)
      {
	chop;

	/[\|][\s](.*)[\)]/;

	my $relevant_parents = $1;
	my @parent_set = split(/\,/, $relevant_parents);

	for (my $j = 0; $j < @parent_set; $j++)
	{
	  my @path = split(/\./, $parent_set[$j]);
	  my $path_last = @path - 1;
	  my $legal_attribute = $path[$path_last];
	  $legal_attribute =~ s/_i$iteration/_i$next_iteration/g;
	  $parents_of_attributes{$legal_attribute} = "1";
	  print "Add $legal_attribute\n";
	}
      }
      delete_file("tmp.$r");
    }
  }
}

#----------------------------------------------------------------
# hide_this_attribute
#----------------------------------------------------------------
sub group_has_hide_attributes
{
  my $group_idx_to_hide = $_[0];

  my $hide_parents_of = $settings{"BRPH_hide_parents_of"};

  my $has_hide_attributes = 0;

  if (length($hide_parents_of) > 0)
  {
    for (my $j = 0; $j < $num_hide_attributes[$group_idx_to_hide]; $j++)
    {
      my $hide_attribute = "$hide_attributes[$group_idx_to_hide][$j]_i$next_iteration";
      print "   Query $hide_attribute\n";
      if ($parents_of_attributes{$hide_attribute} eq "1") { $has_hide_attributes = 1; last; }
    }
  }

  return $has_hide_attributes;
}

#----------------------------------------------------------------
# load_hide_groups
#----------------------------------------------------------------
sub load_hide_groups
{
  for (my $i = 1; $i <= $hide_groups; $i++)
  {
    $num_hide_attributes[$i-1] = $settings{"BRPH_hide_group_num_$i"};

    for (my $j = 1; $j <= $num_hide_attributes[$i-1]; $j++)
    {
      $hide_attributes[$i-1][$j-1] = $settings{"BRPH_hide_group_${i}_$j"};
      $hide_tables[$i-1][$j-1] = $settings{"BRPH_hide_group_table_${i}_$j"};
      $hide_tables_keys[$i-1][$j-1] = $settings{"BRPH_hide_group_table_key_${i}_$j"};
      $hide_first_clusters[$i-1][$j-1] = $settings{"BRPH_hide_group_first_cluster_${i}_$j"};
      $hide_types[$i-1][$j-1] = $settings{"BRPH_hide_group_column_type_${i}_$j"};
    }
  }
}

#----------------------------------------------------------------
# prepare_sql_for_next_iteration
#----------------------------------------------------------------
sub prepare_sql_for_next_iteration
{
  for (my $i = 0; $i < $hide_groups; $i++)
  {
    for (my $j = 0; $j < $num_hide_attributes[$i]; $j++)
    {
      execute("$mql -e 'alter table $hide_tables[$i][$j] add column $hide_attributes[$i][$j]_i$next_iteration $hide_types[$i][$j]' $database", $verbose);
      execute("$mql -e 'update $hide_tables[$i][$j] set $hide_attributes[$i][$j]_i$next_iteration=$hide_attributes[$i][$j]_i$iteration' $database", $verbose);
      #execute("$mql -e 'alter table $hide_tables[$i][$j] drop key $hide_attributes[$i][$j]_i$iteration ' $database", $verbose);

      my $hide_attribute_prev = "$hide_attributes[$i][$j]_i$iteration";
      my $hide_attribute_next = "$hide_attributes[$i][$j]_i$next_iteration";
      change_attribute_in_file("$dir/out/${prefix}_l$iteration.out", "$dir/out/${prefix}_l$iteration.out", "$hide_attribute_prev", "$hide_attribute_next", $verbose);
    }
  }
}

#----------------------------------------------------------------
# run_em_hide_attribute
#----------------------------------------------------------------
sub run_em_hide_attribute
{
  my $group_idx_to_hide = $_[0];
  my $soft_evidence_file = $_[1];

  # MAKE THE NEW DSC FILE
  execute("cp $dir/out/${prefix}_l$iteration.out $dir/${prefix}_l$iteration.dsc", $verbose);

  for (my $j = 0; $j < $num_hide_attributes[$group_idx_to_hide]; $j++)
  {
    my $hide_attribute = "$hide_attributes[$group_idx_to_hide][$j]_i$next_iteration";
    change_attribute_in_file("$dir/${prefix}_l$iteration.dsc", "$dir/${prefix}_l$iteration.dsc", "$hide_attribute", "hidden_$hide_attribute", $verbose);
  }

  # MAKE THE NEW BIO XML FILE
  if (file_exists("$dir/${prefix}_0.bio.xml"))
  {
    execute("$mql -e 'select gene_id, gene_name as ORF from $gene_table' $database > $dir/$gene_table.map", $verbose);

    execute("cp $dir/${prefix}_0.bio.xml $dir/${prefix}_l$iteration.bio.xml", $verbose);

    for (my $j = 0; $j < $num_hide_attributes[$group_idx_to_hide]; $j++)
    {
      my $prev_hide_attribute = "$hide_attributes[$group_idx_to_hide][$j]_i0";
      my $hide_attribute = "$hide_attributes[$group_idx_to_hide][$j]_i$next_iteration";
      change_attribute_in_file("$dir/${prefix}_l$iteration.bio.xml", "$dir/${prefix}_l$iteration.bio.xml", "$prev_hide_attribute", "hidden_$hide_attribute", $verbose);
    }
  }

  # UPDATE THE SETTINGS FOR bio_prm_to_bn_tree.pl
  open(SETTINGS, ">tmp.settings.$r");
  print SETTINGS "convert_prm_file=$dir/${prefix}_l$iteration.dsc\n";
  print SETTINGS "convert_bn_file=$dir/${prefix}_l$iteration.tree.dsc\n";
  print SETTINGS "convert_rel=e_$gene_table\n";
  print SETTINGS "join_for_$gene_table=${expression_table}_${gene_table}\n";
  print SETTINGS "join_for_$experiment_table=${expression_table}_${experiment_table}\n";
  execute("$ENV{HOME}/develop/perl/bio/bio_prm_to_bn_tree.pl tmp.settings.$r", $verbose);
  execute("rm tmp.settings.$r", $verbose);

  # CREATE THE NEW META FILE
  change_attribute_in_file("$dir/${prefix}_0.meta", "$dir/${prefix}_l$iteration.meta", "${prefix}_0", "${prefix}_l$iteration");
  change_attribute_in_file("$dir/${prefix}_l$iteration.meta", "$dir/${prefix}_l$iteration.meta", "#network", "network");
  change_attribute_in_file("$dir/${prefix}_l$iteration.meta", "$dir/${prefix}_l$iteration.meta", "#bio", "bio");
  change_attribute_in_file("$dir/${prefix}_l$iteration.meta", "$dir/${prefix}_l$iteration.meta", "#num_score_nodes", "num_score_nodes");
  change_attribute_in_file("$dir/${prefix}_l$iteration.meta", "$dir/${prefix}_l$iteration.meta", "force_incomplete_data=false", "force_incomplete_data=true");
  change_attribute_in_file("$dir/${prefix}_l$iteration.meta", "$dir/${prefix}_l$iteration.meta", "learn_tree_cpds=true", "learn_tree_cpds=false");
  change_attribute_in_file("$dir/${prefix}_l$iteration.meta", "$dir/${prefix}_l$iteration.meta", "NumGroupRvs", "#NumGroupRvs");
  change_attribute_in_file("$dir/${prefix}_l$iteration.meta", "$dir/${prefix}_l$iteration.meta", "steps_file=", "#steps_file=");
  change_attribute_in_file("$dir/${prefix}_l$iteration.meta", "$dir/${prefix}_l$iteration.meta", "learn_tree_cpds_independent=true", "learn_tree_cpds_independent=false");
  change_attribute_in_file("$dir/${prefix}_l$iteration.meta", "$dir/${prefix}_l$iteration.meta", "structure_prior_kappa", "#structure_prior_kappa");
  open(META_FILE, ">>$dir/${prefix}_l$iteration.meta");
  if (length($soft_evidence_file) > 0)
  {
    print META_FILE "SoftEvidenceFile=$soft_evidence_file\n";
  }

  for (my $j = 0; $j < $num_hide_attributes[$group_idx_to_hide]; $j++)
  {
    my $hide_attribute = "$hide_attributes[$group_idx_to_hide][$j]_i$next_iteration";
    my $idx = $j + 1;
	
    print META_FILE "cluster_rel_$idx=$hide_tables[$group_idx_to_hide][$j]\n";
    print META_FILE "cluster_attr_$idx=hidden_$hide_attribute\n";
  }
  print META_FILE "num_clusters=$num_hide_attributes[$group_idx_to_hide]\n\n";

  # RUN EM
  execute("cd $dir; $ENV{HOME}/develop/frog_linux_release/SamplePrograms/prm_param_learn ${prefix}_l$iteration.meta", $verbose);
  #execute("cd $dir; $ENV{HOME}/develop/frog_linux/SamplePrograms/prm_param_learn ${prefix}_l$iteration.meta", $verbose);

  # UPDATE THE NEW COLUMN AND START USING IT
  for (my $j = 0; $j < $num_hide_attributes[$group_idx_to_hide]; $j++)
  {
    my $attribute = "$hide_attributes[$group_idx_to_hide][$j]_i$next_iteration";
    my $hide_attribute = "hidden_$attribute";

    open(PRM_HARD_ASSIGNMENTS, "<$dir/out/${prefix}_l$iteration.out.$hide_tables[$group_idx_to_hide][$j].$hide_attribute.clusters");
    open(TMP, ">tmp_$r");
    my $cluster_num = $hide_first_clusters[$group_idx_to_hide][$j];
    while (<PRM_HARD_ASSIGNMENTS>)
    {
      chop;
      my @cluster_data = split(/\s/);
      for (my $i = 0; $i < @cluster_data; $i++)
      {
	print TMP $cluster_data[$i] . "\t" . $cluster_num . "\n";
      }
      $cluster_num++;
    }

    open(SETTINGS, ">tmp.settings.$r");
    print SETTINGS "BAC_update_table=$hide_tables[$group_idx_to_hide][$j]\n";
    print SETTINGS "BAC_update_column=$attribute\n";
    print SETTINGS "BAC_update_column_file=tmp_$r\n";
    print SETTINGS "BAC_column_type=$hide_types[$group_idx_to_hide][$j]\n";
    print SETTINGS "BAC_where_column=$hide_tables_keys[$group_idx_to_hide][$j]\n";
    print SETTINGS "BAC_database=$database\n";
    print SETTINGS "BAC_mql=$mql\n";
    #print SETTINGS "BAC_add_key=1\n";
    execute("$ENV{HOME}/develop/perl/bio/bio_add_column.pl tmp.settings.$r", $verbose);
    execute("rm tmp.settings.$r", $verbose);
    execute("rm tmp_$r", $verbose);

    execute("rm $dir/out/${prefix}_l$iteration.out.$hide_tables[$group_idx_to_hide][$j].$hide_attribute.clusters");
  }

  open(EM_SCORES, ">>$dir/out/${prefix}_l$iteration.scores");
  print EM_SCORES "\nAfter EM on:\n";

  for (my $j = 0; $j < $num_hide_attributes[$group_idx_to_hide]; $j++)
  {
    my $attribute = "$hide_attributes[$group_idx_to_hide][$j]_i$next_iteration";
    my $hide_attribute = "hidden_$attribute";

    change_attribute_in_file("$dir/out/${prefix}_l$iteration.out", "$dir/out/${prefix}_l$iteration.out", $hide_attribute, $attribute);

    print EM_SCORES "         $attribute\n";
  }

  for (my $j = 0; $j < $num_hide_attributes[$group_idx_to_hide]; $j++)
  {
    my $attribute = "$hide_attributes[$group_idx_to_hide][$j]_i$next_iteration";
    #execute("cp $dir/out/${prefix}_l$iteration.out $dir/out/${prefix}_l$iteration.out.$attribute", $verbose);
  }

  execute("grep score $dir/out/${prefix}_l$iteration.out >> $dir/out/${prefix}_l$iteration.scores");
}

#----------------------------------------------------------------
# change setting
#----------------------------------------------------------------
execute("cp $dir/out/${prefix}_$iteration.out $dir/out/${prefix}_l$iteration.out", $verbose);

delete_file("$dir/out/${prefix}_l$iteration.scores");

load_allowed_hide_attributes;
load_hide_groups;
prepare_sql_for_next_iteration;

for (my $round = 0; $round < $round_robin; $round++)
{
  for (my $i = 0; $i < $hide_groups; $i++)
  {
    my $hide = group_has_hide_attributes($i);

    if ($hide)
    {
      run_em_hide_attribute($i, "");

      $total_em_executions++;
    }
  }
}
