#! /usr/bin/perl

#----------------------------------------------------------------------------------------------------------
# input: 
#    mql = the mysql command
#
#    prefix - the prefix of the files that we use
#
#    dir - the directory of the prm files
#
#    database = the name of the database we'll work on
#    gene_table = the name of the gene table
#    gene_list - the list of genes or ALL if we want to use all genes
#    has_gene_cluster - do we have a gene cluster
#    has_cond_cluster - do we have a cond cluster
#
#    dissect_gene_file - the master annotation file to use as the dictionary
#
#    iteration - the iteration #
#
#    dataset_name - for analysis files that are printed out
#
#    num_experiment_groups - the number of experiment groups that will be placed together (e.g. for time series)
#    experiment_group_i - a list of the experiment names, separated by semicolons (e.g. nitrogen 1;nitrogen 2)
#
#    attribute_groups - the number of attribute groups
#    attribute_group_num_i - the number of attribute in the i-th group
#    attribute_group_i_j - the name of the j-th attribute in the i-th group
#
# output:
#    creates a default settings that will be used for a full prm run in all its stages
#----------------------------------------------------------------------------------------------------------

use strict;

require "$ENV{MYPERLDIR}/lib/bio_load_settings.pl";
require "$ENV{MYPERLDIR}/lib/bio_execute.pl";
require "$ENV{MYPERLDIR}/lib/bio_system.pl";
require "$ENV{MYPERLDIR}/lib/bio_change_attribute_in_file.pl";
require "$ENV{MYPERLDIR}/lib/load_file_attribute_groups.pl";

my %settings = load_settings($ARGV[0]);
my %file_attribute_groups = load_file_attribute_groups($ARGV[0]);

my $mql = $settings{"mql"};

my $prefix = $settings{"prefix"};

my $dir = $settings{"dir"};

my $database = $settings{"database"};
my $gene_table = $settings{"gene_table"};
my $gene_list = $settings{"gene_list"};

my $has_gene_cluster = $settings{"has_gene_cluster"};
my $has_cond_cluster = $settings{"has_cond_cluster"};

my $iteration;
if (length($ARGV[1]) > 0) { $iteration = $ARGV[1]; }
else { $iteration = $settings{"iteration"}; }
my $next_iteration = $iteration + 1;

my $dissect_gene_file = $settings{"dissect_gene_file"};

my $attribute_groups = $settings{"attribute_groups"};

my $num_experiment_groups = $settings{"num_experiment_groups"};

my $experiment_table = "c_$gene_table";
my $expression_table = "e_$gene_table";

my $prm_file = "$dir/out/${prefix}_l$iteration.out";
my $tsc_file = "$dir/out/${prefix}_l$iteration.tsc";

my $prev_xml_file = "$dir/out/${prefix}_$iteration.xml";
my $cur_xml_file = "$dir/out/${prefix}_l$iteration.xml";

my $r = int(rand 1000000000);
my $verbose = 1;

my $external_attributes_file = $settings{"external_attributes_file"};
my $gene_dsc_file = $settings{"gene_description_file"};

open(SETTINGS, ">settings.$r");

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

#----------------------------
# bio_convert_to_bicluster.pl
#----------------------------
sub prepare_for_convert_to_bicluster
{
  print SETTINGS "#------------------------------------------\n";
  print SETTINGS "# bio_convert_to_bicluster.pl\n";
  print SETTINGS "#------------------------------------------\n";

  print SETTINGS "BCTB_mql=$mql\n";
  print SETTINGS "BCTB_database=$database\n";
  print SETTINGS "BCTB_gene_rel_name=$gene_table\n";
  print SETTINGS "BCTB_experiment_rel_name=$experiment_table\n";
  print SETTINGS "BCTB_expressions_rel_name=$expression_table\n";
  print SETTINGS "BCTB_prm_file=$prm_file\n";
  print SETTINGS "BCTB_add_attributes=1\n";
  print SETTINGS "BCTB_output_file=$tsc_file\n";
  print SETTINGS "BCTB_dictionary_file=$dissect_gene_file\n";
  print SETTINGS "BCTB_num_attribute_db_tables=0\n";
  print SETTINGS "BCTB_attribute_db_table=\n";
  print SETTINGS "BCTB_attribute_join_from=\n";
  print SETTINGS "BCTB_attribute_join_to=\n\n";

  if ($num_experiment_groups > 0)
  {
    print SETTINGS "BCTB_num_experiment_groups=$num_experiment_groups\n";
    for (my $i = 1; $i <= $num_experiment_groups; $i++)
    {
      print SETTINGS "BCTB_experiment_group_$i=" . $settings{"experiment_group_$i"} . "\n";
    }
  }

  print SETTINGS "BATB_mql=$mql\n";
  print SETTINGS "BATB_database=$database\n";
  print SETTINGS "BATB_num_attribute_db_tables=1\n";
  print SETTINGS "BATB_gene_list_file=$gene_list\n";
  print SETTINGS "BATB_ignore_attribute_value=0\n";

  my $num_attributes = 0;
  my $i;
  for ($i = 1; $i <= $attribute_groups; $i++)
  {
	 my $attribute_group_num_i = get_group_attribute("attribute_group_num_$i");
	 my $attribute_group_target_table_i = get_group_attribute("attribute_group_target_table_$i");

	 if ($attribute_group_target_table_i eq $gene_table)
	 {
		$num_attributes += $attribute_group_num_i;

		my $attribute_group_hide_attributes_i = get_group_attribute("attribute_group_hide_attributes_$i");

		if ($attribute_group_hide_attributes_i eq "true")
		{
		  $num_attributes += $attribute_group_num_i;
		}
	 }
  }

  if ($has_gene_cluster == 1) { $num_attributes++; }

  print SETTINGS "BATB_attribute_db_table_1=$gene_table\n";
  print SETTINGS "BATB_attribute_gene_column_name_1=gene_name\n";
  print SETTINGS "BATB_num_attributes_1=$num_attributes\n";

  my $idx = 0;
  for ($i = 1; $i <= $attribute_groups; $i++)
  {
	 my $attribute_group_num_i = get_group_attribute("attribute_group_num_$i");
	 my $attribute_group_hide_attributes_i = get_group_attribute("attribute_group_hide_attributes_$i");
	 my $attribute_group_target_table_i = get_group_attribute("attribute_group_target_table_$i");

	 my $j;
	 for ($j = 1; $j <= $attribute_group_num_i; $j++)
	 {	
		my $attribute_group_i_j = get_group_attribute("attribute_group_${i}_$j");

		if ($attribute_group_target_table_i eq $gene_table)
		{
		  $idx++;
		
		  if ($attribute_group_hide_attributes_i eq "true")
		  {
			 print SETTINGS "BATB_attribute_name_1_$idx=${attribute_group_i_j}_i$next_iteration\n";
			 $idx++;

			 print SETTINGS "BATB_attribute_name_1_$idx=${attribute_group_i_j}_i0\n";
		  }
		  else
		  {
			 print SETTINGS "BATB_attribute_name_1_$idx=${attribute_group_i_j}\n";
		  }
		}
	 }
  }

  if ($has_gene_cluster == 1)
  {
	 $idx++;
	 print SETTINGS "BATB_attribute_name_1_$idx=g_cluster_i$next_iteration\n";
  }
}

#-----------------------------------------------------------------------------------------
# generate_GeneXPress_info
#-----------------------------------------------------------------------------------------
sub generate_GeneXPress_info
{
  execute("cp $dir/out/${prefix}_l$iteration.out $dir/${prefix}_g$iteration.dsc", $verbose);

  # MAKE THE DICTIONARIES
  my $add_on_gene_dictionary = "";
  if ($has_gene_cluster) { $add_on_gene_dictionary .= ", g_cluster_i$next_iteration as Cluster"; }
  if (length($settings{"additional_gene_cluster_attributes"}) > 0)
  {
    my %additional_gene_cluster_variables = extract_attribute_names_from_list($settings{"additional_gene_cluster_attributes"}, 0);

    foreach my $attribute (keys %additional_gene_cluster_variables) { $add_on_gene_dictionary .= ", ${attribute}_i$next_iteration as Cluster" }
  }
  print "$mql -e 'select gene_id, gene_name as ORF $add_on_gene_dictionary from $gene_table' $database > $dir/$gene_table.dsc\n";
  execute("$mql -e 'select gene_id, gene_name as ORF $add_on_gene_dictionary from $gene_table' $database > $dir/$gene_table.dsc");

  my $add_on_cond_dictionary = "";
  if ($has_cond_cluster) { $add_on_cond_dictionary .= ", e_cluster_i$next_iteration as Cluster"; }
  if (length($settings{"additional_cond_cluster_attributes"}) > 0)
  {
    my %additional_cond_cluster_variables = extract_attribute_names_from_list($settings{"additional_cond_cluster_attributes"}, 0);

    foreach my $attribute (keys %additional_cond_cluster_variables) { $add_on_cond_dictionary .= ", ${attribute}_i$next_iteration as Cluster" }
  }
  execute("$mql -e 'select experiment_id, name $add_on_cond_dictionary from $experiment_table' $database > $dir/$experiment_table.dsc");

  # UPDATE THE SETTINGS FOR bio_prm_to_bn_tree.pl
  open(SETTINGS, ">tmp.settings.$r");
  print SETTINGS "convert_prm_file=$dir/${prefix}_g$iteration.dsc\n";
  print SETTINGS "convert_bn_file=$dir/${prefix}_g$iteration.tree.dsc\n";
  print SETTINGS "convert_rel=$expression_table\n";
  print SETTINGS "join_for_$gene_table=${expression_table}_${gene_table}\n";
  print SETTINGS "join_for_$experiment_table=${expression_table}_${experiment_table}\n";
  execute("$ENV{HOME}/develop/perl/bio/bio_prm_to_bn_tree.pl tmp.settings.$r", $verbose);
  execute("rm tmp.settings.$r", $verbose);

  # CREATE THE NEW META FILE
  change_attribute_in_file("$dir/${prefix}_0.meta", "$dir/${prefix}_g$iteration.meta", "${prefix}_0", "${prefix}_g$iteration");
  change_attribute_in_file("$dir/${prefix}_g$iteration.meta", "$dir/${prefix}_g$iteration.meta", "#network", "network");
  change_attribute_in_file("$dir/${prefix}_g$iteration.meta", "$dir/${prefix}_g$iteration.meta", "steps_file=", "#steps_file=");
  change_attribute_in_file("$dir/${prefix}_g$iteration.meta", "$dir/${prefix}_g$iteration.meta", "_i$iteration", "_i$next_iteration");

  execute("cd $dir; $ENV{HOME}/develop/frog_linux_release/SamplePrograms/genexpress_gen ${prefix}_g$iteration.meta", $verbose);
}

#-----------------------------------------------------------------------------------------
# print_genexpress_file
#-----------------------------------------------------------------------------------------
sub print_GeneXPress_file
{
  # INITIALIZE
  open(GENEXPRESS_FILE, ">tmp.$r");
  print GENEXPRESS_FILE "<?xml version='1.0' encoding='iso-8859-1'?>\n\n<GeneXPress>\n";
  #print GENEXPRESS_FILE "<?xml version='1.0' encoding='utf-8'?>\n\n<GeneXPress>\n";

  # EXTRACT FROM THE PERL GENERALTED TSC
  execute("$ENV{HOME}/develop/perl/lib/select_from_file.pl ARGS_SFF $tsc_file -st \"<TSCRawData>\" -et \"</TSCRawData>\" >> tmp.$r", $verbose);

  # EXTRACT FROM THE C++ GENERATED TSC
  my $cur_xml_file = "$dir/out/${prefix}_g$iteration.xml";
  if (file_exists($cur_xml_file))
  {
    execute("$ENV{HOME}/develop/perl/lib/select_from_file.pl ARGS_SFF $cur_xml_file -st \"<GeneXPressAttributes>\" -et \"</GeneXPressAttributes>\" >> tmp.$r", $verbose);
  }

  # MERGE HIERARCHY CLUSTER DATA FROM THE XML GENERATED FROM THE STRUCTURE LEARNING
  my $prev_xml_file = "$dir/out/${prefix}_$iteration.xml";
  if (file_exists($prev_xml_file))
  {
    execute("$ENV{HOME}/develop/perl/lib/select_from_file.pl ARGS_SFF $tsc_file -st \"<TSCHierarchyClusterData\" -et \"</TSCHierarchyClusterData\" > tmp2.$r", $verbose);
    execute("$ENV{HOME}/develop/perl/lib/add_to_xml.pl ARGS_ATX tmp2.$r $prev_xml_file -st \"<TSCHierarchyClusterData\" -et \"</TSCHierarchyClusterData\" >> tmp.$r", $verbose);
    delete_file("tmp2.$r");
  }
  else
  {
    execute("$ENV{HOME}/develop/perl/lib/select_from_file.pl ARGS_SFF $tsc_file -st \"<TSCHierarchyClusterData\" -et \"</TSCHierarchyClusterData\" >> tmp.$r", $verbose);
  }

  # EXTRACT FROM THE PERL GENERALTED TSC
  # execute("$ENV{HOME}/develop/perl/lib/select_from_file.pl ARGS_SFF $tsc_file -st \"<TSCClusterData\" -et \"</TSCClusterData>\" >> tmp.$r", $verbose);
  # execute("$ENV{HOME}/develop/perl/lib/select_from_file.pl ARGS_SFF $tsc_file -st \"<TSCAttributes\" -et \"</TSCAttributes>\" >> tmp.$r", $verbose);

  # EXTRACT FROM THE C++ GENERATED TSC
  my $cur_xml_file = "$dir/out/${prefix}_g$iteration.xml";
  if (file_exists($cur_xml_file))
  {
    execute("$ENV{HOME}/develop/perl/lib/select_from_file.pl ARGS_SFF $cur_xml_file -st \"<Cpds>\" -et \"</Cpds>\" >> tmp.$r", $verbose);
    # execute("$ENV{HOME}/develop/perl/lib/select_from_file.pl ARGS_SFF $cur_xml_file -st \"<GeneXPressAttributes>\" -et \"</GeneXPressAttributes>\" >> tmp.$r", $verbose);
    execute("$ENV{HOME}/develop/perl/lib/select_from_file.pl ARGS_SFF $cur_xml_file -st \"<GeneXPressObjects>\" -et \"</GeneXPressObjects>\" >> tmp.$r", $verbose);
    execute("$ENV{HOME}/develop/perl/lib/select_from_file.pl ARGS_SFF $cur_xml_file -st \"<GeneLink\" -et \"</GeneLink>\" >> tmp.$r", $verbose);
  }

  # FINALIZE
  open(GENEXPRESS_FILE, ">>tmp.$r");
  print GENEXPRESS_FILE "\n</GeneXPress>\n";

  move_file("tmp.$r", "$tsc_file");

  change_attribute_in_file($tsc_file, $tsc_file, "_i0", "_Orig");
  change_attribute_in_file($tsc_file, $tsc_file, "_i$iteration", "");
  change_attribute_in_file($tsc_file, $tsc_file, "_i$next_iteration", "");
}

#-----------------------------------------------------------------------------------------
# MAIN
#-----------------------------------------------------------------------------------------
prepare_for_convert_to_bicluster;

execute("bio_convert_to_bicluster.pl settings.$r");

generate_GeneXPress_info;

print_GeneXPress_file;

execute("rm settings.$r");

