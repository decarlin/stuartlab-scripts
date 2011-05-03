#! /usr/bin/perl

#---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# input: 
#    mql = the mysql command
#
#    prefix - the prefix of the files that we use
#
#    dir - the directory of the prm files
#
#    settings_output_file - the name of the output file. CAN ALSO BE PASSED BY THE ARGV[1]
#
#    expression_file = the name of the expression file
#    expression_file_num_headings = the number of header columns in the expression file
#    expression_file_num_header_rows = the number of header rows in the expression file
#    expression_file_gene_name_location_within_heading = location of gene name identifier
#    expression_file_gene_name_column_name = the name of the column of the gene name in the expression file
#
#    database = the name of the database we'll work on
#    gene_table = the name of the gene table
#    gene_list - the list of genes or ALL if we want to use all genes
#    experiment_list - the list of experiments or ALL if we want to use all experiments
#
#    max_gene_clusters - the maximum number of gene clusters that we want
#    max_cond_clusters - the maximum number of condition clusters that we want
#
#    has_gene_cluster - whether we have gene clusters
#    gene_cluster_dynamic - if true then the gene cluster will be set to the value "0" in all genes for which all the attributes of the gene table are zero
#    has_cond_cluster - whether we have condition clusters
#    cond_cluster_dynamic - if true then the cond cluster will be set to the value "0" in all experiments for which all the attributes of the experiment table are zero
#
#    missing_value_fill - all missing values will be replaced by this value
#
#    num_experiment_groups - the number of experiment groups that will be placed together (e.g. for time series)
#    experiment_group_i - a list of the experiment names, separated by semicolons (e.g. nitrogen 1;nitrogen 2)
#
#    initial_cluster_method - Clustering program to use in creating initial clusters. currently we support 'DoublePCluster' (the default), 'PCluster' 'None' and 'PredefinedClusters'
#    predefined_gene_cluster_file - a file name can be passed here and will be used as the initial clusters for the genes
#    predefined_cond_cluster_file - a file name can be passed here and will be used as the initial clusters for the conditions
#
#    tree_learning_method - the learning method for the tree -- currently we support 'global' (the default -- all trees learned together) or 'independent' (using TreeCpdIndependentEst)
#
#    naive_bayes - the attribute groups for which we will build allow the cluster variable (only) to be a parent of them naive bayes model
#
#    exp_level_type - the type of the expression type -- currently we support 'continuous' and 'discrete'
#
#    beam_size - the size of the beam to open
#    search_lookahead - the size of the lookahead to open
#    max_estimators_for_lookahead - in each lookahead, this is the maximum number of estimators that will be used
#    max_lookahead_steps - total number of times that lookahead will be invoked
#    max_lookahead_flat_steps - the maximum number of flat steps for the lookahead
#    lookahead_flat_step_delta - the score that gets considered as a flat step
#    consider_splits_separately - if true then can do lookahead on the each split of each attribute. if false then during lookahead only the best split will be considered
#
#    num_learn_phases - the number of learning phases
#    phase_i - the attribute groups in phase i, separated by commas. example: phase_1=gene_cluster,attribute_group_1,attribute_group_2
#    phase_lookahead_i - the number of lookahead steps to do for the attributes in the learning phase
#    phase_num_steps_i - the number of steps after which in the learning we go to the next learning phase
#    phase_num_force_steps_i - we can 'force' taking steps even if they harm our score -- this says how many force steps we take
#
#    hide_groups_together - specify how to hide attributes in EM: attribute_group_1,gene_cluster;attribute_group_2;cond_cluster -- means 3 groups, all of 1's attrs + gc in hide group 1
#    max_em_iterations - maximum number of em iterations when hiding each variable
#    em_acyclicity_check - if defined then we check for acyclicity in EM (default is don't check)
#
#    attribute_groups - the number of attribute groups
#    attribute_group_num_i - the number of attribute in the i-th group
#    attribute_group_source_database_i - the name of the source database for group i
#    attribute_group_source_table_i - the name of the source table for group i
#    attribute_group_target_table_i - the name of the target table for group i
#    attribute_group_source_join_column_i - the name of the source join column
#    attribute_group_target_join_column_i - the name of the target join column
#    attribute_group_type_i - the type of the attributes in the i-th group
#    attribute_group_type_dsc_i - additional description for the type of the attributes in the i-th group
#    attribute_group_hide_attributes_i - if "true" then we hide these attributes when we do EM
#
#    attribute_group_has_sensor_i - if this is true then we create a sensor for this group
#    attribute_group_sensor_identical_i - if "true" then the sensor is initialized exactly as the attribute. if "false", then it's loaded from the attribute table
#    attribute_group_sensor_type_i - the type of the sensor attribute (int, continuous or char(...))
#    attribute_group_sensor_type_dsc_i - additional description for the type of the sensor
#    attribute_group_sensor_cpd_type_i - the type of the cpd of the sensor model (nonlinear, discrete)
#    attribute_group_sensor_cpd_type_dsc_i - additional info for the cpd of choice
#    attribute_group_sensor_cpd_fixed_i - if true then this cpd will be forever fixed. otherwise, we start it fixed for structure learning and then learn it
#    attribute_group_i_j - the name of the j-th attribute in the i-th group
#
#    genexpress_gene_attribute_representation - 'Sparse' or 'Full'
#    genexpress_cond_attribute_representation - 'Sparse' or 'Full'
#
#    additional_gene_cluster_attributes - a list in the form attribute_group_1,attribute_group_2 -- which attributes should also be treated as g_cluster (keys, naive bayes)
#    additional_cond_cluster_attributes - a list in the form attribute_group_1,attribute_group_2 -- which attributes should also be treated as g_cluster (keys, naive bayes)
#
#    module_attributes - a list in the form attribute_group_1,attribute_group_2 -- which attributes should be used as defining the modules
#
#    constraints_file - a file containing constraints for learning -- this will be appended by the meta file while changing 'gene_table' and all other tables to the right ones
#
#    is_test_set - if true then creates a settings appropriate for running test set
#
# output:
#    creates a default settings that will be used for a full prm run in all its stages
#---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

use strict;

require "$ENV{MYPERLDIR}/lib/bio_load_settings.pl";
require "$ENV{MYPERLDIR}/lib/bio_execute.pl";
require "$ENV{MYPERLDIR}/lib/bio_get_sql_database_dsc.pl";
require "$ENV{MYPERLDIR}/lib/load_file_attribute_groups.pl";

my %settings = load_settings($ARGV[0]);
my %file_attribute_groups = load_file_attribute_groups($ARGV[0]);

sub get_attribute_value
{
  if (length($settings{"$_[0]"}) > 0) { return $settings{"$_[0]"}; }
  else { return $_[1]; }
}

my $mql = $settings{"mql"};

my $prefix = $settings{"prefix"};

my $dir = $settings{"dir"};

my $settings_output_file;
if (length($ARGV[1]) > 0) { $settings_output_file = $ARGV[1]; }
else { $settings_output_file = $settings{"settings_output_file"}; }

my $expression_file = $settings{"expression_file"};
my $expression_file = $settings{"expression_file"};
my $expression_file_num_headings = $settings{"expression_file_num_headings"};
my $expression_file_num_header_rows = $settings{"expression_file_num_header_rows"};
my $expression_file_gene_name_location_within_heading = $settings{"expression_file_gene_name_location_within_heading"};
my $expression_file_gene_name_column_name = $settings{"expression_file_gene_name_column_name"};

my $database = $settings{"database"};
my $gene_table = $settings{"gene_table"};

my $max_gene_clusters = $settings{"max_gene_clusters"};
my $max_cond_clusters = $settings{"max_cond_clusters"};

my $has_gene_cluster = $settings{"has_gene_cluster"};
my $gene_cluster_dynamic = $settings{"gene_cluster_dynamic"};
my $has_cond_cluster = $settings{"has_cond_cluster"};
my $cond_cluster_dynamic = $settings{"cond_cluster_dynamic"};

my $tree_learning_method = $settings{"tree_learning_method"};

my $attribute_groups = $settings{"attribute_groups"};

my $missing_value_fill = $settings{"missing_value_fill"};

my $predefined_gene_cluster_file = $settings{"predefined_gene_cluster_file"};
my $predefined_cond_cluster_file = $settings{"predefined_cond_cluster_file"};

my $num_experiment_groups = $settings{"num_experiment_groups"};

my $experiment_table = "c_$gene_table";
my $expression_table = "e_$gene_table";

my $is_test_set = $settings{"is_test_set"};
my $original_gene_table = $gene_table;
my $original_experiment_table = $experiment_table;
my $original_expression_table = $expression_table;

my $prm_file = "$dir/out/${prefix}_l0.out";
my $tsc_file = "$dir/out/${prefix}_l0.tsc";

my $r = int(rand 1000000000);
my $verbose = 1;

open(SETTINGS, ">$settings_output_file");

my $gene_list = get_attribute_value("gene_list", "ALL");
my $experiment_list = get_attribute_value("experiment_list", "ALL");

my $exp_level_type = get_attribute_value("exp_level_type", "continuous");

#-------------------------------------------
# get_attribute_value
#-------------------------------------------
sub change_attributes_for_test_set
{
  $prefix = "test_" . $settings{"prefix"};

  $gene_table = $settings{"gene_table"} . "_test";
  $gene_list = $settings{"test_gene_list"};

  $experiment_table = "c_$original_gene_table";
  $expression_table = "e_$gene_table";

  $settings{"initial_cluster_method"} = "None";
}

#-------------------------------------------
# get_group_attribute
#-------------------------------------------
sub get_group_attribute
{
  my $attribute_name = $_[0];

  if (length($settings{"$attribute_name"}) > 0) { return $settings{"$attribute_name"}; }
  else { return $file_attribute_groups{"$attribute_name"}; }
}

#-------------------------------------------
# extract_attribute_names_from_list
#-------------------------------------------
sub extract_attribute_names_from_list
{
  my $attribute_list_str = $_[0];
  my $append_add_on_attribute = $_[1];
  my %attribute_list;

  my @groups = split(/\,/, $attribute_list_str);

  my $num_rvs_in_learn_phase = 0;
  for (my $j = 0; $j < @groups; $j++)
  {
    my $group_dsc = $groups[$j];
    if ($group_dsc eq "gene_cluster")
    {
      $attribute_list{"g_cluster_i0"} = $gene_table;
    }
    elsif ($group_dsc eq "cond_cluster")
    {
      $attribute_list{"e_cluster_i0"} = $experiment_table;
    }
    elsif ($group_dsc =~ /attribute_group_/)
    {
      $group_dsc =~ /attribute_group_(.*)/;
      my $attribute_group_num = $1;

      my $num_attributes_in_group = get_group_attribute("attribute_group_num_$attribute_group_num");
      my $target_table = get_group_attribute("attribute_group_target_table_$attribute_group_num");

      my $attribute_add_on = "";
      if ($append_add_on_attribute && get_group_attribute("attribute_group_hide_attributes_$attribute_group_num") eq "true") { $attribute_add_on = "_i0"; }
		
      for (my $k = 1; $k <= $num_attributes_in_group; $k++)
      {
	my $attribute_name = get_group_attribute("attribute_group_${attribute_group_num}_$k");

	$attribute_list{"${attribute_name}$attribute_add_on"} = $target_table;
      }
    }
  }

  return %attribute_list;
}

#------------------------------------------
# bio_compute_correlations.pl
#------------------------------------------
sub prepare_for_bio_compute_correlations
{
  print SETTINGS "#------------------------------------------\n";
  print SETTINGS "# bio_compute_correlations.pl\n";
  print SETTINGS "#------------------------------------------\n";
  print SETTINGS "BCC_mql=$mql\n";
  print SETTINGS "BCC_keys_list=$gene_list\n";
  print SETTINGS "BCC_source_type1=db\n";
  print SETTINGS "BCC_source_join1=gene_name\n";

  my @tables = get_sql_database_dsc($mql, "test_bio_data", $verbose);
  for (my $i = 0; $i < @tables; $i++)
  {
    print SETTINGS "#BCC_source_table_name1=$tables[$i]\n";
    print SETTINGS "#BCC_output_correlation_file=$gene_table.$tables[$i].cor.dat\n";
    print SETTINGS "#BCC_output_max_correlation_file=$gene_table.$tables[$i].max_cor.dat\n";
  }

  print SETTINGS "BCC_source_database_name1=test_bio_data\n";
  print SETTINGS "BCC_source_file_name1=\n";
  print SETTINGS "BCC_source_type2=file\n";
  print SETTINGS "BCC_source_join2=$expression_file_gene_name_column_name\n";
  print SETTINGS "BCC_source_table_name2=\n";
  print SETTINGS "BCC_source_database_name2=\n";
  print SETTINGS "BCC_source_file_name2=$expression_file\n\n";
}

#------------------------------------------
# bio_prepare_gene_expression_data_files.pl
#------------------------------------------
sub prepare_for_prepare_gene_expression_data_files
{
  print SETTINGS "#------------------------------------------\n";
  print SETTINGS "# bio_prepare_gene_expression_data_files.pl\n";
  print SETTINGS "#------------------------------------------\n";
  print SETTINGS "BPGEDF_mql=$mql\n";
  print SETTINGS "BPGEDF_database=$database\n";
  print SETTINGS "BPGEDF_gene_table=$gene_table\n";
  print SETTINGS "BPGEDF_experiment_table=$experiment_table\n";
  print SETTINGS "BPGEDF_expression_table=$expression_table\n";
  print SETTINGS "BPGEDF_max_gene_clusters=$max_gene_clusters\n";
  print SETTINGS "BPGEDF_max_cond_clusters=$max_cond_clusters\n";
  print SETTINGS "BPGEDF_expression_file=$expression_file\n";
  print SETTINGS "BPGEDF_num_headings=$expression_file_num_headings\n";
  print SETTINGS "BPGEDF_num_header_rows=$expression_file_num_header_rows\n";
  print SETTINGS "BPGEDF_gene_name_location_within_heading=$expression_file_gene_name_location_within_heading\n";
  print SETTINGS "BPGEDF_genes_list=$gene_list\n";
  print SETTINGS "BPGEDF_experiments_list=$experiment_list\n";
  print SETTINGS "BPGEDF_missing_value_fill=$missing_value_fill\n\n";
  print SETTINGS "BPGEDF_predefined_gene_cluster_file=$predefined_gene_cluster_file\n\n";
  print SETTINGS "BPGEDF_predefined_cond_cluster_file=$predefined_cond_cluster_file\n\n";

  if ($is_test_set eq "true") { print SETTINGS "BPGEDF_create_experiments_table=false\n"; } else { print SETTINGS "BPGEDF_create_experiments_table=true\n"; }

  print SETTINGS "BPGEDF_initial_cluster_method=" . get_attribute_value("initial_cluster_method", "DoublePCluster") . "\n";

  if ($num_experiment_groups > 0)
  {
    print SETTINGS "BPGEDF_num_experiment_groups=$num_experiment_groups\n";
    for (my $i = 1; $i <= $num_experiment_groups; $i++)
    {
      print SETTINGS "BPGEDF_experiment_group_$i=" . $settings{"experiment_group_$i"} . "\n";
    }
  }
  print SETTINGS "\n";
}

#-------------------------------
# bio_add_attributes_to_table.pl
#-------------------------------
sub prepare_for_add_attributes_to_table
{
  print SETTINGS "#------------------------------------------\n";
  print SETTINGS "# bio_add_attributes_to_table.pl\n";
  print SETTINGS "#------------------------------------------\n";
  print SETTINGS "BAATT_mql=$mql\n";
  print SETTINGS "BAATT_num_groups=$attribute_groups\n";

  for (my $i = 1; $i <= $attribute_groups; $i++)
  {
	 my $attribute_group_num_i = get_group_attribute("attribute_group_num_$i");
	 my $attribute_group_source_database_i = get_group_attribute("attribute_group_source_database_$i");
	 my $attribute_group_source_table_i = get_group_attribute("attribute_group_source_table_$i");
	 my $attribute_group_target_table_i = get_group_attribute("attribute_group_target_table_$i");
	 my $attribute_group_source_join_column_i = get_group_attribute("attribute_group_source_join_column_$i");
	 my $attribute_group_target_join_column_i = get_group_attribute("attribute_group_target_join_column_$i");
	 my $attribute_group_type_i = get_group_attribute("attribute_group_type_$i");
	 my $attribute_group_type_dsc_i = get_group_attribute("attribute_group_type_dsc_$i");

	 my $attribute_group_has_sensor_i = get_group_attribute("attribute_group_has_sensor_$i");
	 my $attribute_group_sensor_identical_i = get_group_attribute("attribute_group_sensor_identical_$i");

	 my $num_add_attributes_in_group = $attribute_group_num_i;
	 if ($attribute_group_has_sensor_i eq "true" && $attribute_group_sensor_identical_i eq "false")
	 {
		$num_add_attributes_in_group += $attribute_group_num_i;
	 }

	 # Conditions for skipping the group: test_set and experiment table
	 if ($is_test_set eq "true")
	 {
		if ($original_experiment_table eq $attribute_group_target_table_i) { $num_add_attributes_in_group = 0; }
		if ($original_gene_table eq $attribute_group_target_table_i) { $attribute_group_target_table_i = $gene_table; }
	 }

	 print SETTINGS "BAATT_group_target_table_$i=$attribute_group_target_table_i\n";
	 print SETTINGS "BAATT_group_source_table_$i=$attribute_group_source_table_i\n";
	 print SETTINGS "BAATT_group_target_database_$i=$database\n";
	 print SETTINGS "BAATT_group_source_database_$i=$attribute_group_source_database_i\n";
	 print SETTINGS "BAATT_group_num_attributes_$i=$num_add_attributes_in_group\n";
	 print SETTINGS "BAATT_group_source_join_column_$i=$attribute_group_source_join_column_i\n";
	 print SETTINGS "BAATT_group_target_join_column_$i=$attribute_group_target_join_column_i\n";

	 my $prev_add_attributes = 0;
	 for (my $j = 1; $j <= $attribute_group_num_i; $j++)
	 {
		my $attribute_group_i_j = get_group_attribute("attribute_group_${i}_$j");

		$prev_add_attributes++;

		print SETTINGS "BAATT_group_attribute_${i}_$prev_add_attributes=$attribute_group_i_j\n";

		if ($attribute_group_has_sensor_i eq "true" && $attribute_group_sensor_identical_i eq "false")
		{
		  $prev_add_attributes++;
		
		  print SETTINGS "BAATT_group_attribute_${i}_$prev_add_attributes=sensor_$attribute_group_i_j\n";
		}
	 }
  }

  print SETTINGS "\n";
}

#----------------------------------
# bio_fix_gene_expression_tables.pl
#----------------------------------
sub prepare_for_fix_gene_expression_tables
{
  print SETTINGS "#------------------------------------------\n";
  print SETTINGS "# bio_fix_gene_expression_tables.pl\n";
  print SETTINGS "#------------------------------------------\n";
  print SETTINGS "BFGET_mql=$mql\n";
  print SETTINGS "BFGET_database=$database\n";
  print SETTINGS "BFGET_gene_table=$gene_table\n";
  print SETTINGS "BFGET_experiment_table=$experiment_table\n";
  print SETTINGS "BFGET_expression_table=$expression_table\n";
  print SETTINGS "BFGET_gene_cluster_dynamic=$gene_cluster_dynamic\n";
  print SETTINGS "BFGET_cond_cluster_dynamic=$cond_cluster_dynamic\n";
  print SETTINGS "BFGET_num_groups=$attribute_groups\n";

  if ($is_test_set eq "true") { print SETTINGS "BFGET_fix_experiment_table=false\n"; } else { print SETTINGS "BFGET_fix_experiment_table=true\n"; }

  for (my $i = 1; $i <= $attribute_groups; $i++)
  {
    my $attribute_group_num_i = get_group_attribute("attribute_group_num_$i");
    my $attribute_group_target_table_i = get_group_attribute("attribute_group_target_table_$i");
    my $attribute_group_type_i = get_group_attribute("attribute_group_type_$i");
    my $attribute_group_has_sensor_i = get_group_attribute("attribute_group_has_sensor_$i");
    my $attribute_group_sensor_identical_i = get_group_attribute("attribute_group_sensor_identical_$i");
    my $attribute_group_hide_attributes_i = get_group_attribute("attribute_group_hide_attributes_$i");

	 # Change the table name to fit the test data case
	 if ($is_test_set eq "true")
	 {
		if ($original_gene_table eq $attribute_group_target_table_i) { $attribute_group_target_table_i = $gene_table; }
		print SETTINGS "BFGET_iteration=" . ($settings{"iteration"} + 1) . "\n";
	 }

    print SETTINGS "BFGET_group_num_attributes_$i=$attribute_group_num_i\n";
    print SETTINGS "BFGET_group_target_table_$i=$attribute_group_target_table_i\n";
    print SETTINGS "BFGET_group_attribute_type_$i=$attribute_group_type_i\n";
    print SETTINGS "BFGET_group_attribute_hide_$i=$attribute_group_hide_attributes_i\n";

    if ($attribute_group_has_sensor_i eq "true" && $attribute_group_sensor_identical_i eq "true")
    {
      print SETTINGS "BFGET_group_has_sensor_$i=$attribute_group_has_sensor_i\n";
    }

    for (my $j = 1; $j <= $attribute_group_num_i; $j++)
    {
      my $attribute_group_i_j = get_group_attribute("attribute_group_${i}_$j");

      print SETTINGS "BFGET_group_attribute_${i}_$j=$attribute_group_i_j\n";
    }
  }

  print SETTINGS "\n";
}

#-----------------------
# bio_create_prm_meta.pl
#-----------------------
sub prepare_for_create_prm_meta
{
  print SETTINGS "#------------------------------------------\n";
  print SETTINGS "# bio_create_prm_meta.pl\n";
  print SETTINGS "#------------------------------------------\n";
  print SETTINGS "BCPM_prefix=$prefix\n";
  print SETTINGS "BCPM_dir=$dir\n";
  print SETTINGS "BCPM_db=$database\n";
  if ($num_experiment_groups > 0) { print SETTINGS "BCPM_ignore_null=true\n"; }
  if (length($settings{"max_parents"}) > 0) { print SETTINGS "BCPM_max_parents=" . $settings{"max_parents"} . "\n"; }
  if (length($settings{"max_steps"}) > 0) { print SETTINGS "BCPM_max_steps=" . $settings{"max_steps"} . "\n"; }
  if (length($settings{"max_flat_steps"}) > 0) { print SETTINGS "BCPM_max_flat_steps=" . $settings{"max_flat_steps"} . "\n"; }
  if (length($settings{"max_em_iterations"}) > 0) { print SETTINGS "BCPM_max_em_iterations=" . $settings{"max_em_iterations"} . "\n"; }

  print SETTINGS "BCPM_gene_table=$gene_table\n";
  print SETTINGS "BCPM_experiment_table=$experiment_table\n";
  print SETTINGS "BCPM_expression_table=$expression_table\n";
  print SETTINGS "BCPM_constraints_file=" . $settings{"constraints_file"} . "\n";

  if ($tree_learning_method eq "independent")
  {
    print SETTINGS "BCPM_learn_tree_cpds_independent=true\n";
    print SETTINGS "BCPM_independent_tree_search=beam_search\n";
    print SETTINGS "BCPM_learn_tree_with_shallow_key=false\n";

	 if (length($settings{"beam_size"}) > 0) { print SETTINGS "BCPM_beam_size=" . $settings{"beam_size"} . "\n"; }
	 if (length($settings{"search_lookahead"}) > 0) { print SETTINGS "BCPM_search_lookahead=" . $settings{"search_lookahead"} . "\n"; }
 	 if (length($settings{"max_estimators_for_lookahead"}) > 0) { print SETTINGS "BCPM_max_estimators_for_lookahead=" . $settings{"max_estimators_for_lookahead"} . "\n"; }
 	 if (length($settings{"max_lookahead_steps"}) > 0) { print SETTINGS "BCPM_max_lookahead_steps=" . $settings{"max_lookahead_steps"} . "\n"; }
 	 if (length($settings{"max_lookahead_flat_steps"}) > 0) { print SETTINGS "BCPM_max_lookahead_flat_steps=" . $settings{"max_lookahead_flat_steps"} . "\n"; }
 	 if (length($settings{"lookahead_flat_step_delta"}) > 0) { print SETTINGS "BCPM_lookahead_flat_step_delta=" . $settings{"lookahead_flat_step_delta"} . "\n"; }

	 print SETTINGS "BCPM_consider_splits_separately=" . get_attribute_value("consider_splits_separately", "false") . "\n";

	 if ($num_experiment_groups > 0)
	 {
		print SETTINGS "BCPM_num_group_rvs=$num_experiment_groups\n";
		for (my $i = 1; $i <= $num_experiment_groups; $i++)
		{
		  my $experiment_attr_str = $settings{"experiment_group_$i"};
		  my @splitted_experiment_attrs = split(/\;/, $experiment_attr_str);
		  my $num_experiment_attrs = @splitted_experiment_attrs;

		  print SETTINGS "BCPM_num_rvs_in_group_$i=$num_experiment_attrs\n";
		  print SETTINGS "BCPM_rel_in_rv_group_$i=$expression_table\n";

		  for (my $j = 1; $j <= $num_experiment_attrs; $j++)
		  {
			 print SETTINGS "BCPM_attr_in_rv_group_${i}_$j=exp_level_" . ($j - 1) . "\n";
		  }
		}
    }
  }

  #-----------------------------
  # PASS ON SCORE_REL ATTRIBUTES
  #-----------------------------
  if ($num_experiment_groups > 0)
  {
	 for (my $i = 1; $i <= $num_experiment_groups; $i++)
	 {
		my $experiment_attr_str = $settings{"experiment_group_$i"};
		my @splitted_experiment_attrs = split(/\;/, $experiment_attr_str);
		my $num_experiment_attrs = @splitted_experiment_attrs;

		print SETTINGS "BCPM_num_score_nodes=$num_experiment_attrs\n";
		print SETTINGS "BCPM_hide_score_nodes=true\n";

		for (my $j = 1; $j <= $num_experiment_attrs; $j++)
		{
		  print SETTINGS "BCPM_score_rel_$j=$expression_table\n";
		  print SETTINGS "BCPM_score_$j=exp_level_" . ($j - 1) . "\n";
		}
	 }
	 print SETTINGS "\n";
  }
  else
  {
    print SETTINGS "BCPM_num_score_nodes=1\n";
    print SETTINGS "BCPM_score_rel_1=$expression_table\n";
    print SETTINGS "BCPM_score_1=exp_level\n\n";
  }

  my $naive_bayes_dsc = $settings{"naive_bayes"};
  my @nb_attribute_groups;
  my $nb_learn_phases = 0;
  if (length($naive_bayes_dsc) > 0)
  {
	 @nb_attribute_groups = split(/[\,]/, $naive_bayes_dsc);
	 for (my $i = 0; $i < @nb_attribute_groups; $i++)
	 {
		my $str = $nb_attribute_groups[$i];
		$str =~ s/attribute_group/attribute_group_num/g;
 		$nb_learn_phases += get_group_attribute("$str");
	 }
  }

  my $num_learn_phases = get_attribute_value("num_learn_phases", 0);

  if ($num_learn_phases + $nb_learn_phases > 0)
  {
    print SETTINGS "\nBCPM_num_learn_phases=" . ($num_learn_phases + $nb_learn_phases) . "\n\n";
  }

  #-----------------------------------------------------------------------------------------------
  # Exp Level Learn Phase Attributes
  #-----------------------------------------------------------------------------------------------
  if ($num_learn_phases > 0)
  {
    print SETTINGS "BCPM_phase_prefix_1=$expression_table.exp_level\n";
    print SETTINGS "BCPM_phase_num_phases_1=$num_learn_phases\n";

    for (my $i = 1; $i <= $num_learn_phases; $i++)
    {
      my @phase_groups = split(/\,/, $settings{"phase_$i"});

      my $num_rvs_in_learn_phase = 0;
      my $out_str = "";
      for (my $j = 0; $j < @phase_groups; $j++)
      {
	my $phase_dsc = $phase_groups[$j];
	if ($phase_dsc eq "gene_cluster")
	{
	  $num_rvs_in_learn_phase++;
	  $out_str .= "BCPM_RelInLearnPhase_${i}_$num_rvs_in_learn_phase=$gene_table\n";
	  $out_str .= "BCPM_AttrInLearnPhase_${i}_$num_rvs_in_learn_phase=g_cluster_i0\n";
	}
	elsif ($phase_dsc eq "cond_cluster")
	{
	  $num_rvs_in_learn_phase++;
	  $out_str .= "BCPM_RelInLearnPhase_${i}_$num_rvs_in_learn_phase=$experiment_table\n";
	  $out_str .= "BCPM_AttrInLearnPhase_${i}_$num_rvs_in_learn_phase=e_cluster_i0\n";
	}
	elsif ($phase_dsc =~ /attribute_group_/)
	{
	  $phase_dsc =~ /attribute_group_(.*)/;
	  my $attribute_group_num = $1;

	  my $num_attributes_in_group = get_group_attribute("attribute_group_num_$attribute_group_num");
	  my $target_table = get_group_attribute("attribute_group_target_table_$attribute_group_num");

	  my $attribute_add_on = "";
	  if (get_group_attribute("attribute_group_hide_attributes_$attribute_group_num") eq "true") { $attribute_add_on = "_i0"; }

	  for (my $k = 1; $k <= $num_attributes_in_group; $k++)
	  {
	    my $attribute_name = get_group_attribute("attribute_group_${attribute_group_num}_$k");

	    $num_rvs_in_learn_phase++;
	    $out_str .= "BCPM_RelInLearnPhase_${i}_$num_rvs_in_learn_phase=$target_table\n";
	    $out_str .= "BCPM_AttrInLearnPhase_${i}_$num_rvs_in_learn_phase=${attribute_name}$attribute_add_on\n";
	  }
	}
      }

      print SETTINGS "BCPM_NumRvsInLearnPhase_$i=$num_rvs_in_learn_phase\n";
      print SETTINGS "BCPM_LookaheadPhaseInLearnPhase_$i=" . $settings{"phase_lookahead_$i"} . "\n";
      print SETTINGS "BCPM_NumStepsInLearnPhase_$i=" . $settings{"phase_num_steps_$i"} . "\n";
      my $num_force_steps = length($settings{"phase_num_force_steps_$i"}) == 0 ? 0 : $settings{"phase_num_force_steps_$i"};
      print SETTINGS "BCPM_NumForceStepsInLearnPhase_$i=$num_force_steps\n";
      print SETTINGS "$out_str\n";
    }
  }

  #-----------------------------------------------------------------------------------------------
  # GeneXPress prints
  #-----------------------------------------------------------------------------------------------
  print SETTINGS "BCPM_GeneXPress_num_nodes=" . ($nb_learn_phases + 1) . "\n";
  print SETTINGS "BCPM_GeneXPress_outfile=out/${prefix}_0.xml\n";
  print SETTINGS "BCPM_GeneXPress_rel_1=$expression_table\n";
  if ($num_experiment_groups > 0) { print SETTINGS "BCPM_GeneXPress_attr_1=exp_level_0\n"; }
  else { print SETTINGS "BCPM_GeneXPress_attr_1=exp_level\n"; }
  print SETTINGS "BCPM_GeneXPress_print_1=tree\n";
  my $GeneXPress_idx = 2;

  my $GeneXPressModule_num_nodes = 0;
  if (length($settings{"module_attributes"}) > 0)
  {
	 my %module_attributes = extract_attribute_names_from_list($settings{"module_attributes"}, 1);

	 foreach my $attribute (keys %module_attributes)
	 {
		$GeneXPressModule_num_nodes++;
		print SETTINGS "BCPM_GeneXPressModule_rel_$GeneXPressModule_num_nodes=$module_attributes{$attribute}\n";
		print SETTINGS "BCPM_GeneXPressModule_attr_$GeneXPressModule_num_nodes=$attribute\n";
	 }
  }
  print SETTINGS "BCPM_GeneXPressModule_num_nodes=$GeneXPressModule_num_nodes\n";

  my $genexpress_gene_attribute_representation = length($settings{"genexpress_gene_attribute_representation"}) > 0 ? $settings{"genexpress_gene_attribute_representation"} : "Sparse";
  my $genexpress_cond_attribute_representation = length($settings{"genexpress_cond_attribute_representation"}) > 0 ? $settings{"genexpress_cond_attribute_representation"} : "Full";

  my $GeneXPressAttributes_num_groups = 0;
  $GeneXPressAttributes_num_groups++;
  print SETTINGS "BCPM_GeneXPressAttributeGroup_rel_$GeneXPressAttributes_num_groups=$gene_table\n";
  print SETTINGS "BCPM_GeneXPressAttributeGroup_type_$GeneXPressAttributes_num_groups=Genes\n";
  print SETTINGS "BCPM_GeneXPressAttributeGroup_rep_$GeneXPressAttributes_num_groups=$genexpress_gene_attribute_representation\n";
  print SETTINGS "BCPM_GeneXPressAttributeGroup_dictionary_$GeneXPressAttributes_num_groups=$gene_table.dsc\n";
  print SETTINGS "BCPM_GeneXPressAttributeGroup_link_$GeneXPressAttributes_num_groups=" . $settings{"${gene_table}_link"} . "\n";
  $GeneXPressAttributes_num_groups++;
  print SETTINGS "BCPM_GeneXPressAttributeGroup_rel_$GeneXPressAttributes_num_groups=$experiment_table\n";
  print SETTINGS "BCPM_GeneXPressAttributeGroup_type_$GeneXPressAttributes_num_groups=Experiments\n";
  print SETTINGS "BCPM_GeneXPressAttributeGroup_rep_$GeneXPressAttributes_num_groups=$genexpress_cond_attribute_representation\n";
  print SETTINGS "BCPM_GeneXPressAttributeGroup_dictionary_$GeneXPressAttributes_num_groups=$experiment_table.dsc\n";
  print SETTINGS "BCPM_GeneXPressAttribute_num_groups=$GeneXPressAttributes_num_groups\n";
  print SETTINGS "BCPM_GeneXPressAttributeGroup_link_$GeneXPressAttributes_num_groups=" . $settings{"${experiment_table}_link"} . "\n";

  #-----------------------------------------------------------------------------------------------
  # Naive Bayes Learn Phase Attributes
  #-----------------------------------------------------------------------------------------------
  if ($nb_learn_phases > 0)
  {
	 my $phase_idx = $num_learn_phases + 1;

	 for (my $i = 0; $i < @nb_attribute_groups; $i++)
	 {
		$nb_attribute_groups[$i] =~ /attribute_group_(.*)/;
		my $attribute_group_num = $1;
		
		my $num_attributes_in_group = get_group_attribute("attribute_group_num_$attribute_group_num");
		my $target_table = get_group_attribute("attribute_group_target_table_$attribute_group_num");

		my $attribute_add_on = "";
		if (get_group_attribute("attribute_group_hide_attributes_$attribute_group_num") eq "true") { $attribute_add_on = "_i0"; }

		for (my $j = 1; $j <= $num_attributes_in_group; $j++)
		{
		  my $attribute_name = get_group_attribute("attribute_group_${attribute_group_num}_$j");

		  print SETTINGS "BCPM_GeneXPress_rel_$GeneXPress_idx=$target_table\n";
		  print SETTINGS "BCPM_GeneXPress_attr_$GeneXPress_idx=${attribute_name}$attribute_add_on\n";
		  print SETTINGS "BCPM_GeneXPress_print_$GeneXPress_idx=naive_bayes\n";
		  $GeneXPress_idx++;

		  print SETTINGS "BCPM_phase_prefix_$phase_idx=$target_table.${attribute_name}$attribute_add_on\n";
		  print SETTINGS "BCPM_phase_num_phases_$phase_idx=1\n";

		  print SETTINGS "BCPM_LookaheadPhaseInLearnPhase_$phase_idx=1\n";
		  print SETTINGS "BCPM_NumStepsInLearnPhase_$phase_idx=30\n";

		  my $num_rvs_in_learn_phase = 0;

		  if ($target_table eq $gene_table || $target_table eq $original_gene_table)
		  {
			 #print SETTINGS "BCPM_NumStepsInLearnPhase_$phase_idx=$max_gene_clusters\n";

			 if ($has_gene_cluster == 1)
			 {
				$num_rvs_in_learn_phase++;
				print SETTINGS "BCPM_RelInLearnPhase_${phase_idx}_$num_rvs_in_learn_phase=$gene_table\n";
				print SETTINGS "BCPM_AttrInLearnPhase_${phase_idx}_$num_rvs_in_learn_phase=g_cluster_i0\n";
			 }

			 if (length($settings{"additional_gene_cluster_attributes"}) > 0)
			 {
				my %additional_gene_cluster_variables = extract_attribute_names_from_list($settings{"additional_gene_cluster_attributes"}, 1);

				foreach my $attribute (keys %additional_gene_cluster_variables)
				{
				  $num_rvs_in_learn_phase++;
				  print SETTINGS "BCPM_RelInLearnPhase_${phase_idx}_$num_rvs_in_learn_phase=$additional_gene_cluster_variables{$attribute}\n";
				  print SETTINGS "BCPM_AttrInLearnPhase_${phase_idx}_$num_rvs_in_learn_phase=$attribute\n";
				}
			 }
		  }
		  elsif ($target_table eq $experiment_table || $target_table eq $original_experiment_table)
		  {
			 #print SETTINGS "BCPM_NumStepsInLearnPhase_$phase_idx=$max_cond_clusters\n";

			 if ($has_cond_cluster == 1)
			 {
				$num_rvs_in_learn_phase++;
				print SETTINGS "BCPM_RelInLearnPhase_${phase_idx}_$num_rvs_in_learn_phase=$experiment_table\n";
				print SETTINGS "BCPM_AttrInLearnPhase_${phase_idx}_$num_rvs_in_learn_phase=e_cluster_i0\n";
			 }

			 if (length($settings{"additional_cond_cluster_attributes"}) > 0)
			 {
				my %additional_cond_cluster_variables = extract_attribute_names_from_list($settings{"additional_cond_cluster_attributes"}, 1);

				foreach my $attribute (keys %additional_cond_cluster_variables)
				{
				  $num_rvs_in_learn_phase++;
				  print SETTINGS "BCPM_RelInLearnPhase_${phase_idx}_$num_rvs_in_learn_phase=$additional_cond_cluster_variables{$attribute}\n";
				  print SETTINGS "BCPM_AttrInLearnPhase_${phase_idx}_$num_rvs_in_learn_phase=$attribute\n";
				}
			 }
		  }

		  print SETTINGS "BCPM_NumRvsInLearnPhase_$phase_idx=$num_rvs_in_learn_phase\n";

		  print SETTINGS "\n";

		  $phase_idx++;
		}
	 }
  }

  print SETTINGS "BCPM_use_sparse_parents=" . get_attribute_value("use_sparse_parents", "false") . "\n";
  print SETTINGS "BCPM_num_sparse_parents=" . get_attribute_value("num_sparse_parents", "1") . "\n";
  print SETTINGS "BCPM_num_steps_to_recompute_sparse_parents=" . get_attribute_value("num_steps_to_recompute_sparse_parents", "1") . "\n";
  print SETTINGS "BCPM_recompute_sparse_parents_upon_phase_change=" . get_attribute_value("recompute_sparse_parents_upon_phase_change", "false") . "\n";
  print SETTINGS "\n";

  #-------------------------------------------
  # MOTIFS
  #-------------------------------------------
  if (length($settings{"motif_variables"}) > 0)
  {
	 print SETTINGS "BCPM_bio=${prefix}_0.bio.xml\n";

	 print SETTINGS "BCPM_fasta_file=" . $settings{"fasta_file"} . "\n";
	 print SETTINGS "BCPM_mapping_file=$gene_table.map\n";
	 print SETTINGS "BCPM_upstream_length=" . $settings{"upstream_length"} . "\n";
	 print SETTINGS "BCPM_use_both_strands=" . $settings{"use_both_strands"} . "\n";
	 print SETTINGS "BCPM_pssm_length=" . $settings{"pssm_length"} . "\n";
	 print SETTINGS "BCPM_seed_length=" . $settings{"seed_length"} . "\n";
	 print SETTINGS "BCPM_projection_dist=" . $settings{"projection_dist"} . "\n";
	 print SETTINGS "BCPM_projection_num=" . $settings{"projection_num"} . "\n";
	 print SETTINGS "BCPM_num_test_seeds=" . $settings{"num_test_seeds"} . "\n";

	 my %motif_variables = extract_attribute_names_from_list($settings{"motif_variables"}, 1);

	 my $num_motif_variables = 0;
	 foreach my $attribute (keys %motif_variables)
	 {
		$num_motif_variables++;

		print SETTINGS "BCPM_motif_variable_$num_motif_variables=$attribute\n";
		print SETTINGS "BCPM_motif_table_$num_motif_variables=$motif_variables{$attribute}\n";
		print SETTINGS "BCPM_motif_target_variable_$num_motif_variables=exp_level\n";
		print SETTINGS "BCPM_motif_target_table_$num_motif_variables=$expression_table\n";
		print SETTINGS "BCPM_motif_file_$num_motif_variables=out/motifs/$attribute.pssm\n";
	 }
	 print SETTINGS "BCPM_num_motif_variables=$num_motif_variables\n\n";
  }
}

#-----------------------
# bio_create_prm_dsc.pl
#-----------------------
sub prepare_for_create_prm_dsc
{
  print SETTINGS "#------------------------------------------\n";
  print SETTINGS "# bio_create_prm_dsc.pl\n";
  print SETTINGS "#------------------------------------------\n";
  print SETTINGS "BCPD_prefix=$prefix\n";
  print SETTINGS "BCPD_dir=$dir\n\n";

  print SETTINGS "BCPD_num_relations=3\n\n";

  my %nb_attribute_groups_hash;
  my @nb_attribute_groups = split(/[\,]/, $settings{"naive_bayes"});
  for (my $i = 0; $i < @nb_attribute_groups; $i++)
  {
	 $nb_attribute_groups_hash{"$nb_attribute_groups[$i]"} = "1";
  }

  #-----------------------
  # HANDLE GENE ATTRIBUTES
  #-----------------------
  print SETTINGS "BCPD_relation_1=$gene_table\n";
  print SETTINGS "BCPD_relation_num_key_attributes_1=1\n";
  print SETTINGS "BCPD_relation_key_attribute_1_1=gene_id\n";
  print SETTINGS "BCPD_relation_num_foreign_key_attributes_1=0\n";

  my $total_gene_attributes = 0;

  if ($has_gene_cluster == 1) { $total_gene_attributes++; }

  my $i;
  my $num_gene_sensor_attributes = 0;
  for ($i = 1; $i <= $attribute_groups; $i++)
  {
	 my $attribute_group_num_i = get_group_attribute("attribute_group_num_$i");
	 my $attribute_group_target_table_i = get_group_attribute("attribute_group_target_table_$i");

	 my $attribute_group_has_sensor_i = get_group_attribute("attribute_group_has_sensor_$i");

	 if ($attribute_group_target_table_i eq $gene_table || $attribute_group_target_table_i eq $original_gene_table)
	 {
		$total_gene_attributes += $attribute_group_num_i; 

		if ($attribute_group_has_sensor_i eq "true")
		{
		  $num_gene_sensor_attributes += $attribute_group_num_i;
		  $total_gene_attributes += $attribute_group_num_i; 
		}
	 }
  }

  print SETTINGS "BCPD_relation_num_attributes_1=$total_gene_attributes\n";

  my $prev_gene_attributes = 0;
  if ($has_gene_cluster == 1) 
  {
    print SETTINGS "BCPD_relation_attribute_1_1=g_cluster_i0\n";
    print SETTINGS "BCPD_relation_attribute_additional_info_1_1=illegalchild; \n";
    print SETTINGS "BCPD_relation_type_attributes_1_1=int\n";
	
    my $start_gene_cluster = 1;
    if ($gene_cluster_dynamic eq "true") { $start_gene_cluster = 0; }
    print SETTINGS "BCPD_relation_enum_attributes_1_1=$start_gene_cluster,$max_gene_clusters\n";

    $prev_gene_attributes++;
  }

  for ($i = 1; $i <= $attribute_groups; $i++)
  {
    my $attribute_group_num_i = get_group_attribute("attribute_group_num_$i");
    my $attribute_group_target_table_i = get_group_attribute("attribute_group_target_table_$i");
    my $attribute_group_type_i = get_group_attribute("attribute_group_type_$i");
    my $attribute_group_type_dsc_i = get_group_attribute("attribute_group_type_dsc_$i");

    my $attribute_group_has_sensor_i = get_group_attribute("attribute_group_has_sensor_$i");
    my $attribute_group_sensor_type_i = get_group_attribute("attribute_group_sensor_type_$i");
    my $attribute_group_sensor_type_dsc_i = get_group_attribute("attribute_group_sensor_type_dsc_$i");

    my $attribute_add_on = "";
    if (get_group_attribute("attribute_group_hide_attributes_$i") eq "true") { $attribute_add_on = "_i0"; }

    if ($attribute_group_target_table_i eq $gene_table || $attribute_group_target_table_i eq $original_gene_table)
    {
      my $illegalchild;
      if ($nb_attribute_groups_hash{"attribute_group_$i"} eq "1") { $illegalchild = ""; }
      else { $illegalchild = "illegalchild;"; }

      for (my $j = 1; $j <= $attribute_group_num_i; $j++)
      {
	my $attribute_group_i_j = get_group_attribute("attribute_group_${i}_$j");

	$prev_gene_attributes++;

	print SETTINGS "BCPD_relation_attribute_1_$prev_gene_attributes=${attribute_group_i_j}$attribute_add_on\n";
	print SETTINGS "BCPD_relation_attribute_additional_info_1_$prev_gene_attributes=$illegalchild \n";
	print SETTINGS "BCPD_relation_type_attributes_1_$prev_gene_attributes=$attribute_group_type_i\n";
	print SETTINGS "BCPD_relation_enum_attributes_1_$prev_gene_attributes=$attribute_group_type_dsc_i\n";
		
	if ($attribute_group_has_sensor_i eq "true")
	{
	  $prev_gene_attributes++;
	  
	  print SETTINGS "BCPD_relation_attribute_1_$prev_gene_attributes=sensor_${attribute_group_i_j}\n";
	  print SETTINGS "BCPD_relation_attribute_additional_info_1_$prev_gene_attributes=illegalchild; illegalparent; \n";
	  print SETTINGS "BCPD_relation_type_attributes_1_$prev_gene_attributes=$attribute_group_sensor_type_i\n";
	  print SETTINGS "BCPD_relation_enum_attributes_1_$prev_gene_attributes=$attribute_group_sensor_type_dsc_i\n";
	}
      }
    }
  }

  #--------------------
  # HANDLE GENE SENSORS
  #--------------------
  print SETTINGS "BCPD_relation_prob_attributes_1=$num_gene_sensor_attributes\n";
  my $prev_sensor_gene_attributes = 0;
  for ($i = 1; $i <= $attribute_groups; $i++)
  {
	 my $attribute_group_num_i = get_group_attribute("attribute_group_num_$i");
	 my $attribute_group_target_table_i = get_group_attribute("attribute_group_target_table_$i");

	 my $attribute_group_has_sensor_i = get_group_attribute("attribute_group_has_sensor_$i");
	 my $attribute_group_sensor_cpd_type_i = get_group_attribute("attribute_group_sensor_cpd_type_$i");
	 my $attribute_group_sensor_cpd_type_dsc_i = get_group_attribute("attribute_group_sensor_cpd_type_dsc_$i");
	 my $attribute_group_sensor_cpd_fixed_i = get_group_attribute("attribute_group_sensor_cpd_fixed_$i");

	 my $attribute_add_on = "";
	 if (get_group_attribute("attribute_group_hide_attributes_$i") eq "true") { $attribute_add_on = "_i0"; }

	 if (($attribute_group_target_table_i eq $gene_table || $attribute_group_target_table_i eq $original_gene_table) && $attribute_group_has_sensor_i eq "true")
	 {
		my $j;
		for ($j = 1; $j <= $attribute_group_num_i; $j++)
		{
		  my $attribute_group_i_j = get_group_attribute("attribute_group_${i}_$j");

		  $prev_sensor_gene_attributes++;
		
		  print SETTINGS "BCPD_relation_prob_attribute_1_$prev_sensor_gene_attributes=sensor_${attribute_group_i_j}\n";
		  print SETTINGS "BCPD_relation_prob_attribute_parents_1_$prev_sensor_gene_attributes=${attribute_group_i_j}$attribute_add_on\n";
		  print SETTINGS "BCPD_relation_prob_attribute_cpd_type_1_$prev_sensor_gene_attributes=$attribute_group_sensor_cpd_type_i\n";
		  print SETTINGS "BCPD_relation_prob_attribute_cpd_type_dsc_1_$prev_sensor_gene_attributes=$attribute_group_sensor_cpd_type_dsc_i\n";
		  print SETTINGS "BCPD_relation_prob_attribute_cpd_fixed_1_$prev_sensor_gene_attributes=$attribute_group_sensor_cpd_fixed_i\n";
		}
	 }
  }

  #-----------------------
  # HANDLE COND ATTRIBUTES
  #-----------------------
  print SETTINGS "\nBCPD_relation_2=$experiment_table\n";
  print SETTINGS "BCPD_relation_num_key_attributes_2=1\n";
  print SETTINGS "BCPD_relation_key_attribute_2_1=experiment_id\n";
  print SETTINGS "BCPD_relation_num_foreign_key_attributes_2=0\n";

  my $total_cond_attributes = 0;

  if ($has_cond_cluster == 1) { $total_cond_attributes++; }

  my $i;
  my $num_cond_sensor_attributes = 0;
  for ($i = 1; $i <= $attribute_groups; $i++)
  {
	 my $attribute_group_num_i = get_group_attribute("attribute_group_num_$i");
	 my $attribute_group_target_table_i = get_group_attribute("attribute_group_target_table_$i");

	 my $attribute_group_has_sensor_i = get_group_attribute("attribute_group_has_sensor_$i");

	 if ($attribute_group_target_table_i eq $experiment_table || $attribute_group_target_table_i eq $original_experiment_table)
	 {
		$total_cond_attributes += $attribute_group_num_i;

		if ($attribute_group_has_sensor_i eq "true")
		{
		  $num_cond_sensor_attributes += $attribute_group_num_i;
		  $total_cond_attributes += $attribute_group_num_i; 
		}
	 }
  }

  print SETTINGS "BCPD_relation_num_attributes_2=$total_cond_attributes\n";

  my $prev_cond_attributes = 0;
  if ($has_cond_cluster == 1)
  {
	 print SETTINGS "BCPD_relation_attribute_2_1=e_cluster_i0\n";
	 print SETTINGS "BCPD_relation_attribute_additional_info_2_1=illegalchild; \n";
	 print SETTINGS "BCPD_relation_type_attributes_2_1=int\n";

	 my $start_cond_cluster = 1;
	 if ($cond_cluster_dynamic eq "true") { $start_cond_cluster = 0; }
	 print SETTINGS "BCPD_relation_enum_attributes_2_1=$start_cond_cluster,$max_cond_clusters\n";
	 $prev_cond_attributes++;
  }

  for ($i = 1; $i <= $attribute_groups; $i++)
  {
	 my $attribute_group_num_i = get_group_attribute("attribute_group_num_$i");
	 my $attribute_group_target_table_i = get_group_attribute("attribute_group_target_table_$i");
	 my $attribute_group_type_i = get_group_attribute("attribute_group_type_$i");
	 my $attribute_group_type_dsc_i = get_group_attribute("attribute_group_type_dsc_$i");

	 my $attribute_group_has_sensor_i = get_group_attribute("attribute_group_has_sensor_$i");
	 my $attribute_group_sensor_type_i = get_group_attribute("attribute_group_sensor_type_$i");
	 my $attribute_group_sensor_type_dsc_i = get_group_attribute("attribute_group_sensor_type_dsc_$i");

	 my $attribute_add_on = "";
	 if (get_group_attribute("attribute_group_hide_attributes_$i") eq "true") { $attribute_add_on = "_i0"; }

	 my $illegalchild;
	 if ($nb_attribute_groups_hash{"attribute_group_$i"} eq "1") { $illegalchild = ""; }
	 else { $illegalchild = "illegalchild;"; }

	 if ($attribute_group_target_table_i eq $experiment_table || $attribute_group_target_table_i eq $original_experiment_table)
	 {
		for (my $j = 1; $j <= $attribute_group_num_i; $j++)
		{
		  my $attribute_group_i_j = get_group_attribute("attribute_group_${i}_$j");
		  $prev_cond_attributes++;

		  print SETTINGS "BCPD_relation_attribute_2_$prev_cond_attributes=${attribute_group_i_j}$attribute_add_on\n";
		  print SETTINGS "BCPD_relation_attribute_additional_info_2_$prev_cond_attributes=$illegalchild \n";
		  print SETTINGS "BCPD_relation_type_attributes_2_$prev_cond_attributes=$attribute_group_type_i\n";
		  print SETTINGS "BCPD_relation_enum_attributes_2_$prev_cond_attributes=$attribute_group_type_dsc_i\n";

		  if ($attribute_group_has_sensor_i eq "true")
		  {
			 $prev_cond_attributes++;

			 print SETTINGS "BCPD_relation_attribute_2_$prev_cond_attributes=sensor_${attribute_group_i_j}\n";
			 print SETTINGS "BCPD_relation_attribute_additional_info_2_$prev_cond_attributes=illegalchild; illegalparent; \n";
			 print SETTINGS "BCPD_relation_type_attributes_2_$prev_cond_attributes=$attribute_group_sensor_type_i\n";
			 print SETTINGS "BCPD_relation_enum_attributes_2_$prev_cond_attributes=$attribute_group_sensor_type_dsc_i\n";
		  }
		}
	 }
  }

  #--------------------
  # HANDLE COND SENSORS
  #--------------------
  print SETTINGS "BCPD_relation_prob_attributes_2=$num_cond_sensor_attributes\n";
  my $prev_sensor_cond_attributes = 0;
  for ($i = 1; $i <= $attribute_groups; $i++)
  {
	 my $attribute_group_num_i = get_group_attribute("attribute_group_num_$i");
	 my $attribute_group_target_table_i = get_group_attribute("attribute_group_target_table_$i");

	 my $attribute_group_has_sensor_i = get_group_attribute("attribute_group_has_sensor_$i");
	 my $attribute_group_sensor_cpd_type_i = get_group_attribute("attribute_group_sensor_cpd_type_$i");
	 my $attribute_group_sensor_cpd_type_dsc_i = get_group_attribute("attribute_group_sensor_cpd_type_dsc_$i");
	 my $attribute_group_sensor_cpd_fixed_i = get_group_attribute("attribute_group_sensor_cpd_fixed_$i");

	 my $attribute_add_on = "";
	 if (get_group_attribute("attribute_group_hide_attributes_$i") eq "true") { $attribute_add_on = "_i0"; }

	 if (($attribute_group_target_table_i eq $experiment_table || $attribute_group_target_table_i eq $original_experiment_table) && $attribute_group_has_sensor_i eq "true")
	 {
		for (my $j = 1; $j <= $attribute_group_num_i; $j++)
		{
		  my $attribute_group_i_j = get_group_attribute("attribute_group_${i}_$j");

		  $prev_sensor_cond_attributes++;

		  print SETTINGS "BCPD_relation_prob_attribute_2_$prev_sensor_cond_attributes=sensor_${attribute_group_i_j}\n";
		  print SETTINGS "BCPD_relation_prob_attribute_parents_2_$prev_sensor_cond_attributes=${attribute_group_i_j}$attribute_add_on\n";
		  print SETTINGS "BCPD_relation_prob_attribute_cpd_type_2_$prev_sensor_cond_attributes=$attribute_group_sensor_cpd_type_i\n";
		  print SETTINGS "BCPD_relation_prob_attribute_cpd_type_dsc_2_$prev_sensor_cond_attributes=$attribute_group_sensor_cpd_type_dsc_i\n";
		  print SETTINGS "BCPD_relation_prob_attribute_cpd_fixed_2_$prev_sensor_gene_attributes=$attribute_group_sensor_cpd_fixed_i\n";
		}
	 }
  }

  #------------------------
  # HANDLE EXPRESSION TABLE
  #------------------------
  print SETTINGS "\nBCPD_relation_3=$expression_table\n";
  print SETTINGS "BCPD_relation_num_key_attributes_3=1\n";
  print SETTINGS "BCPD_relation_key_attribute_3_1=level_id\n";
  print SETTINGS "BCPD_relation_num_foreign_key_attributes_3=2\n";
  print SETTINGS "BCPD_relation_foreign_key_attribute_3_1=gene\n";
  print SETTINGS "BCPD_relation_foreign_key_type_attribute_3_1=1\n";
  print SETTINGS "BCPD_relation_foreign_key_attribute_3_2=experiment\n";
  print SETTINGS "BCPD_relation_foreign_key_type_attribute_3_2=2\n";
  if ($num_experiment_groups > 0)
  {
	 my $experiment_attr_str = $settings{"experiment_group_1"};
	 my @splitted_experiment_attrs = split(/\;/, $experiment_attr_str);
	 my $num_experiment_attrs = @splitted_experiment_attrs;

    print SETTINGS "BCPD_relation_num_attributes_3=$num_experiment_attrs\n";
    for (my $i = 1; $i <= $num_experiment_attrs; $i++)
    {
      print SETTINGS "BCPD_relation_attribute_3_$i=exp_level_" . ($i - 1) . "\n";
		if ($exp_level_type eq "continuous")
		{
		  print SETTINGS "BCPD_relation_type_attributes_3_$i=continuous\n";
		}
		elsif ($exp_level_type eq "discrete")
		{
		  print SETTINGS "BCPD_relation_type_attributes_3_$i=int\n";
        print SETTINGS "BCPD_relation_enum_attributes_3_$i=-1,1\n";
		}
      print SETTINGS "BCPD_relation_attribute_additional_info_3_$i=illegalparent; \n";
    }
  }
  else
  {
    print SETTINGS "BCPD_relation_num_attributes_3=1\n";
    print SETTINGS "BCPD_relation_attribute_3_1=exp_level\n";

	 if ($exp_level_type eq "continuous")
	 {
		print SETTINGS "BCPD_relation_type_attributes_3_1=continuous\n";
	 }
	 elsif ($exp_level_type eq "discrete")
	 {
		print SETTINGS "BCPD_relation_type_attributes_3_1=int\n";
		print SETTINGS "BCPD_relation_enum_attributes_3_1=-1,1\n";
	 }

	 print SETTINGS "BCPD_relation_attribute_additional_info_3_$i=illegalparent; \n";
  }
}

#------------------------
# bio_run_prm_observed.pl
#------------------------
sub prepare_for_run_prm_observed
{
  print SETTINGS "#------------------------------------------\n";
  print SETTINGS "# prepare_for_run_prm_observed.pl\n";
  print SETTINGS "#------------------------------------------\n";
  print SETTINGS "BRPO_prefix=$prefix\n";
  print SETTINGS "BRPO_dir=$dir\n";
  print SETTINGS "BRPO_mql=$mql\n";
  print SETTINGS "BRPO_database=$database\n";

  print SETTINGS "BRPO_has_gene_cluster=$has_gene_cluster\n";
  print SETTINGS "BRPO_has_cond_cluster=$has_cond_cluster\n";
  print SETTINGS "BRPO_gene_table=$gene_table\n";
  print SETTINGS "BRPO_experiment_table=$experiment_table\n";

  my $num_keys_to_add = 0;
  if ($has_gene_cluster)
  {
	 $num_keys_to_add++;
	 print SETTINGS "BRPO_key_rel_$num_keys_to_add=$gene_table\n";
	 print SETTINGS "BRPO_key_prefix_$num_keys_to_add=g_cluster\n";
  }
  if ($has_cond_cluster)
  {
	 $num_keys_to_add++;
	 print SETTINGS "BRPO_key_rel_$num_keys_to_add=$experiment_table\n";
	 print SETTINGS "BRPO_key_prefix_$num_keys_to_add=e_cluster\n";
  }
  if (length($settings{"additional_gene_cluster_attributes"}) > 0)
  {
	 my %additional_gene_cluster_variables = extract_attribute_names_from_list($settings{"additional_gene_cluster_attributes"}, 0);

	 foreach my $attribute (keys %additional_gene_cluster_variables)
	 {
		$num_keys_to_add++;

		print SETTINGS "BRPO_key_rel_$num_keys_to_add=$additional_gene_cluster_variables{$attribute}\n";
		print SETTINGS "BRPO_key_prefix_$num_keys_to_add=$attribute\n";
	 }
  }
  if (length($settings{"additional_cond_cluster_attributes"}) > 0)
  {
	 my %additional_cond_cluster_variables = extract_attribute_names_from_list($settings{"additional_cond_cluster_attributes"}, 0);

	 foreach my $attribute (keys %additional_cond_cluster_variables)
	 {
		$num_keys_to_add++;

		print SETTINGS "BRPO_key_rel_$num_keys_to_add=$additional_cond_cluster_variables{$attribute}\n";
		print SETTINGS "BRPO_key_prefix_$num_keys_to_add=$attribute\n";
	 }
  }
  print SETTINGS "BRPO_num_keys_to_add=$num_keys_to_add\n";

  print SETTINGS "BRPO_iteration=0\n\n";
}

#----------------------
# bio_run_prm_hidden.pl
#----------------------
sub prepare_for_run_prm_hidden
{
  print SETTINGS "#------------------------------------------\n";
  print SETTINGS "# bio_run_prm_hidden.pl\n";
  print SETTINGS "#------------------------------------------\n";
  print SETTINGS "BRPH_mql=$mql\n";
  print SETTINGS "BRPH_database=$database\n";
  print SETTINGS "BRPH_prefix=$prefix\n";
  print SETTINGS "BRPH_gene_table=$gene_table\n";
  print SETTINGS "BRPH_dir=$dir\n";
  print SETTINGS "BRPH_round_robin=" . get_attribute_value("em_round_robin", "2") . "\n";
  print SETTINGS "BRPH_iteration=0\n";
  print SETTINGS "BRPH_hide_parents_of=exp_level\n";

  print SETTINGS "BRPH_em_acyclicity_check=" . get_attribute_value("em_acyclicity_check", "false") . "\n";

  if ($num_experiment_groups > 0)
  {
    my $experiment_attr_str = $settings{"experiment_group_1"};
    my @splitted_experiment_attrs = split(/\;/, $experiment_attr_str);
    my $num_experiment_attrs = @splitted_experiment_attrs;
    print SETTINGS "BRPH_exp_level_time_series_length=$num_experiment_attrs\n"
  }

  my $hide_groups_together = $settings{"hide_groups_together"};
  if (length($hide_groups_together) > 0)
  {
    my @together_groups = split(/\;/, $hide_groups_together);
    for (my $i = 1; $i <= @together_groups; $i++)
    {
      my $total_together_attributes = 0;
      my @together_subgroups = split(/\,/, $together_groups[$i - 1]);

      for (my $j = 0; $j < @together_subgroups; $j++)
      {
	if ($together_subgroups[$j] eq "gene_cluster")
	{
	  my $start_gene_cluster = 1;
	  if ($gene_cluster_dynamic eq "true") { $start_gene_cluster = 0; }
	
	  $total_together_attributes++;
	  print SETTINGS "BRPH_hide_group_${i}_$total_together_attributes=g_cluster\n";
	  print SETTINGS "BRPH_hide_group_table_${i}_$total_together_attributes=$gene_table\n";
	  print SETTINGS "BRPH_hide_group_table_key_${i}_$total_together_attributes=gene_id\n";
	  print SETTINGS "BRPH_hide_group_first_cluster_${i}_$total_together_attributes=$start_gene_cluster\n";
	  print SETTINGS "BRPH_hide_group_column_type_${i}_$total_together_attributes=int\n";
	}
	elsif ($together_subgroups[$j] eq "cond_cluster")
	{
	  my $start_cond_cluster = 1;
	  if ($cond_cluster_dynamic eq "true") { $start_cond_cluster = 0; }
	
	  $total_together_attributes++;
	  print SETTINGS "BRPH_hide_group_${i}_$total_together_attributes=e_cluster\n";
	  print SETTINGS "BRPH_hide_group_table_${i}_$total_together_attributes=$experiment_table\n";
	  print SETTINGS "BRPH_hide_group_table_key_${i}_$total_together_attributes=experiment_id\n";
	  print SETTINGS "BRPH_hide_group_first_cluster_${i}_$total_together_attributes=$start_cond_cluster\n";
	  print SETTINGS "BRPH_hide_group_column_type_${i}_$total_together_attributes=int\n";
	}
	else
	{
	  $together_subgroups[$j] =~ /attribute_group_(.*)/;
	  my $attribute_group_num = $1;

	  my $attribute_group_num_i = get_group_attribute("attribute_group_num_$attribute_group_num");
	  my $attribute_group_target_table_i = get_group_attribute("attribute_group_target_table_$attribute_group_num");
	  my $attribute_group_type_i = get_group_attribute("attribute_group_type_$attribute_group_num");
	  my $attribute_group_type_dsc_i = get_group_attribute("attribute_group_type_dsc_$attribute_group_num");
	  my $attribute_group_hide_attributes_i = get_group_attribute("attribute_group_hide_attributes_$attribute_group_num");

	  my @type_dsc_array = split(/\,/, $attribute_group_type_dsc_i);
	  my $first_cluster_val = $type_dsc_array[0];

	  my %hide_attributes = extract_attribute_names_from_list($together_subgroups[$j], 0);
	  foreach my $attribute (keys %hide_attributes)
	  {
	    my $key;
	    if ($attribute_group_target_table_i eq $gene_table || $attribute_group_target_table_i eq $original_gene_table) { $key = "gene_id"; }
	    elsif ($attribute_group_target_table_i eq $experiment_table || $attribute_group_target_table_i eq $original_experiment_table) { $key = "experiment_id"; }

	    $total_together_attributes++;
	    print SETTINGS "BRPH_hide_group_${i}_$total_together_attributes=$attribute\n";
	    print SETTINGS "BRPH_hide_group_table_${i}_$total_together_attributes=$attribute_group_target_table_i\n";
	    print SETTINGS "BRPH_hide_group_table_key_${i}_$total_together_attributes=$key\n";
	    print SETTINGS "BRPH_hide_group_first_cluster_${i}_$total_together_attributes=$first_cluster_val\n";
	    #print SETTINGS "BRPH_hide_group_first_cluster_${i}_$total_together_attributes=0\n";
	    print SETTINGS "BRPH_hide_group_column_type_${i}_$total_together_attributes=$attribute_group_type_i\n";
	  }
	}
      }
      print SETTINGS "BRPH_hide_group_num_$i=$total_together_attributes\n";
    }
    my $num_hide_groups = @together_groups;
    print SETTINGS "BRPH_hide_groups=$num_hide_groups\n";
  }
  else
  {
    my $total_attributes = 0;

    if ($has_gene_cluster == 1) { $total_attributes++; }
    if ($has_cond_cluster == 1) { $total_attributes++; }

    for (my $i = 1; $i <= $attribute_groups; $i++)
    {
      my $attribute_group_num_i = get_group_attribute("attribute_group_num_$i");

      my $attribute_group_hide_attributes_i = get_group_attribute("attribute_group_hide_attributes_$i");

      if ($attribute_group_hide_attributes_i eq "true") { $total_attributes += $attribute_group_num_i; }
    }

    print SETTINGS "BRPH_hide_groups=$total_attributes\n";

    my $cluster_idx = 0;

    if ($has_gene_cluster == 1)
    {
      my $start_gene_cluster = 1;
      if ($gene_cluster_dynamic eq "true") { $start_gene_cluster = 0; }
	
      $cluster_idx++;
      print SETTINGS "BRPH_hide_group_num_$cluster_idx=1\n";
      print SETTINGS "BRPH_hide_group_${cluster_idx}_1=g_cluster\n";
      print SETTINGS "BRPH_hide_group_table_${cluster_idx}_1=$gene_table\n";
      print SETTINGS "BRPH_hide_group_table_key_${cluster_idx}_1=gene_id\n";
      print SETTINGS "BRPH_hide_group_first_cluster_${cluster_idx}_1=$start_gene_cluster\n";
      print SETTINGS "BRPH_hide_group_column_type_${cluster_idx}_1=int\n";
    }

    if ($has_cond_cluster == 1)
    {
      my $start_cond_cluster = 1;
      if ($cond_cluster_dynamic eq "true") { $start_cond_cluster = 0; }

      $cluster_idx++;
      print SETTINGS "BRPH_hide_group_num_$cluster_idx=1\n";
      print SETTINGS "BRPH_hide_group_${cluster_idx}_1=e_cluster\n";
      print SETTINGS "BRPH_hide_group_table_${cluster_idx}_1=$experiment_table\n";
      print SETTINGS "BRPH_hide_group_table_key_${cluster_idx}_1=experiment_id\n";
      print SETTINGS "BRPH_hide_group_first_cluster_${cluster_idx}_1=$start_cond_cluster\n";
      print SETTINGS "BRPH_hide_group_column_type_${cluster_idx}_1=int\n";
    }

    for (my $i = 1; $i <= $attribute_groups; $i++)
    {
      my $attribute_group_num_i = get_group_attribute("attribute_group_num_$i");
      my $attribute_group_target_table_i = get_group_attribute("attribute_group_target_table_$i");
      my $attribute_group_type_i = get_group_attribute("attribute_group_type_$i");
      my $attribute_group_type_dsc_i = get_group_attribute("attribute_group_type_dsc_$i");
      my $attribute_group_hide_attributes_i = get_group_attribute("attribute_group_hide_attributes_$i");

      my @type_dsc_array = split(/\,/, $attribute_group_type_dsc_i);
      my $first_cluster_val = $type_dsc_array[0];

      if ($attribute_group_hide_attributes_i eq "true")
      {
	for (my $j = 1; $j <= $attribute_group_num_i; $j++)
	{
	  my $attribute_group_i_j = get_group_attribute("attribute_group_${i}_$j");
	  $cluster_idx++;
	  my $idx = $cluster_idx;

	  my $table;
	  my $key;
	  if ($attribute_group_target_table_i eq $gene_table || $attribute_group_target_table_i eq $original_gene_table) { $key = "gene_id"; }
	  elsif ($attribute_group_target_table_i eq $experiment_table || $attribute_group_target_table_i eq $original_experiment_table) { $key = "experiment_id"; }

	  print SETTINGS "BRPH_hide_group_num_${idx}=1\n";
	  print SETTINGS "BRPH_hide_group_${idx}_1=${attribute_group_i_j}\n";
	  print SETTINGS "BRPH_hide_group_table_${idx}_1=$attribute_group_target_table_i\n";
	  print SETTINGS "BRPH_hide_group_table_key_${idx}_1=$key\n";
	  print SETTINGS "BRPH_hide_group_first_cluster_${idx}_1=$first_cluster_val\n";
	  #print SETTINGS "BRPH_hide_group_first_cluster_${idx}_1=0\n";
	  print SETTINGS "BRPH_hide_group_column_type_${idx}_1=$attribute_group_type_i\n";
	}
      }
    }
    print SETTINGS "\n";
  }
}

#---------------------------------
# bio_compute_attribute_changes.pl
#---------------------------------
sub prepare_for_compute_attribute_changes
{
  print SETTINGS "#------------------------------------------\n";
  print SETTINGS "# bio_compute_attribute_changes.pl\n";
  print SETTINGS "#------------------------------------------\n";
  print SETTINGS "BCAC_mql=$mql\n";
  print SETTINGS "BCAC_database=$database\n";
  print SETTINGS "BCAC_prefix=$prefix\n"; 
  print SETTINGS "BCAC_dir=$dir\n";
  print SETTINGS "BCAC_num_tables=2\n";
  print SETTINGS "BCAC_table_1=$gene_table\n";
  print SETTINGS "BCAC_table_2=$experiment_table\n";
}

if ($is_test_set eq "true") { change_attributes_for_test_set; }

prepare_for_bio_compute_correlations;
prepare_for_prepare_gene_expression_data_files;
prepare_for_add_attributes_to_table;
prepare_for_fix_gene_expression_tables;
prepare_for_create_prm_meta;
prepare_for_create_prm_dsc;
prepare_for_run_prm_observed;
prepare_for_run_prm_hidden;
prepare_for_compute_attribute_changes;
