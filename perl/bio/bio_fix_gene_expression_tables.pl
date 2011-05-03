#! /usr/bin/perl

#----------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# input: 
#    BFGET_mql = the mysql command
#    BFGET_database = the database to use
#    BFGET_gene_table = the gene table
#    BFGET_experiment_table = the experiment table
#    BFGET_expression_table = the expression table
#    BFGET_gene_cluster_dynamic - if true then the gene cluster will be set to the value "0" in all genes for which all the attributes of the gene table are zero
#    BFGET_cond_cluster_dynamic - if true then the cond cluster will be set to the value "0" in all experiments for which all the attributes of the experiment table are zero
#    BFGET_num_groups - the number of groups of attributes to add
#    BFGET_group_target_table_i = the table to which the attributes in the group belong
#    BFGET_group_num_attributes_i = the number of attributes in the group
#    BFGET_group_attribute_type_i = the type of the attribute
#    BFGET_group_attribute_hide_i = if "true" then we hide these attributes when we do EM (and change the name to _i0)
#    BFGET_group_has_sensor_i = if "true" then we add a sensor which is an identical variable with the prefix sensor_ in the name
#
#    BFGET_iteration
#
#    BFGET_fix_experiment_table - if "true" then we fix the experiments table. otherwise we don't touch it
#
# output:
#    adds keys to tables, adds the sensor attributes to the database if there are any
#----------------------------------------------------------------------------------------------------------------------------------------------------------------------------

use strict;

require "$ENV{MYPERLDIR}/lib/bio_load_settings.pl";
require "$ENV{MYPERLDIR}/lib/bio_execute.pl";

my %settings = load_settings($ARGV[0]);

my $mql = $settings{"BFGET_mql"};
my $database = $settings{"BFGET_database"};
my $gene_table = $settings{"BFGET_gene_table"};
my $expression_table = $settings{"BFGET_expression_table"};
my $experiment_table = $settings{"BFGET_experiment_table"};
my $gene_cluster_dynamic = $settings{"BFGET_gene_cluster_dynamic"};
my $cond_cluster_dynamic = $settings{"BFGET_cond_cluster_dynamic"};
my $num_groups = $settings{"BFGET_num_groups"};

my $fix_experiment_table = $settings{"BFGET_fix_experiment_table"};

my $r = int(rand 1000000000);

my $verbose = 1;

#-------------------------------------------------------------------------
# build_attribute_where
#-------------------------------------------------------------------------
sub build_attribute_where
{
  my $db_table = $_[0];
  my $result = "";

  my $i;
  my $first = 1;
  for ($i = 1; $i <= $num_groups; $i++)
  {
	my $group_target_table_i = $settings{"BFGET_group_target_table_$i"};
	
	if ($group_target_table_i eq $db_table)
	{
	  my $group_num_attributes_i = $settings{"BFGET_group_num_attributes_$i"};

	  if ($group_num_attributes_i > 0)
	  {
		if ($first == 1) { $first = 0; } else { $result .= " OR "; }
		
		$result .= $settings{"BFGET_group_attribute_${i}_1"} . "=\"1\"";
		
		my $j;
		for ($j = 2; $j <= $group_num_attributes_i; $j++)
		{
		  $result .= " OR " . $settings{"BFGET_group_attribute_${i}_$j"} . "=\"1\"";
		}
	  }
	}
  }

  return $result;
}

#-------------------------------------------------------------------------
# fix_expression_table (add keys)
#-------------------------------------------------------------------------
sub fix_expression_table
{
  execute("$mql -e 'drop table if exists tmp_$r' $database", $verbose);
  my $exec_str = "$mql -e 'create table tmp_$r select $expression_table.* from $expression_table, $experiment_table, $gene_table where ";
  $exec_str .= "$expression_table.gene=$gene_table.gene_id and $expression_table.experiment=$experiment_table.experiment_id' $database";
  execute($exec_str, $verbose);
  execute("$mql -e 'drop table if exists $expression_table' $database", $verbose);
  execute("$mql -e 'create table $expression_table select * from tmp_$r' $database", $verbose);
  execute("$mql -e 'alter table $expression_table add key(level_id)' $database", $verbose);
  execute("$mql -e 'alter table $expression_table add key(experiment)' $database", $verbose);
  execute("$mql -e 'alter table $expression_table add key(gene)' $database", $verbose);
  execute("$mql -e 'drop table if exists tmp_$r' $database", $verbose);
}

#-------------------------------------------------------------------------
# fix_gene_table (add keys, handle dynamic cluster)
#-------------------------------------------------------------------------
sub fix_gene_table
{
  execute("$mql -e 'alter table $gene_table add key(gene_id)' $database", $verbose);
  execute("$mql -e 'alter table $gene_table add key(gene_name)' $database", $verbose);
  execute("$mql -e 'alter table $gene_table add key(g_cluster_i0)' $database", $verbose);

  if ($gene_cluster_dynamic eq "true")
  {
	 execute("$mql -e 'alter table $gene_table change g_cluster_i0 g_cluster_orig int' $database", $verbose);
	
	 execute("$mql -e 'alter table $gene_table add column g_cluster_i0 int' $database", $verbose);
	
	 execute("$mql -e 'update $gene_table set g_cluster_i0=g_cluster_orig' $database", $verbose);

	 my $where = build_attribute_where($gene_table);

	 if (length($where) > 0)
	 {
		execute("$mql -e 'update $gene_table set g_cluster_i0=\"0\" where $where' $database", $verbose);
	 }
  }
}

#-------------------------------------------------------------------------
# fix_gene_table (add keys, handle dynamic cluster)
#-------------------------------------------------------------------------
sub fix_experiment_table
{
  execute("$mql -e 'alter table $experiment_table add key(experiment_id)' $database", $verbose);
  execute("$mql -e 'alter table $experiment_table add key(e_cluster_i0)' $database", $verbose);

  if ($cond_cluster_dynamic eq "true")
  {
    execute("$mql -e 'alter table $experiment_table change e_cluster_i0 e_cluster_orig int' $database", $verbose);

    execute("$mql -e 'alter table $experiment_table add column e_cluster_i0 int' $database", $verbose);

    execute("$mql -e 'update $experiment_table set e_cluster_i0=e_cluster_orig' $database", $verbose);

    my $where = build_attribute_where($experiment_table);

	 if (length($where) > 0)
	 {
		execute("$mql -e 'update $experiment_table set e_cluster_i0=\"0\" where $where' $database", $verbose);
	 }
  }
}

#-------------------------------------------------------------------------
# fix_attributes (add keys, handle dynamic cluster)
#-------------------------------------------------------------------------
sub fix_attributes
{
  for (my $i = 1; $i <= $num_groups; $i++)
  {
	 my $group_target_table_i = $settings{"BFGET_group_target_table_$i"};
	 my $group_num_attributes_i = $settings{"BFGET_group_num_attributes_$i"};
	 my $group_attribute_type_i = $settings{"BFGET_group_attribute_type_$i"};
	 my $group_has_sensor_i = $settings{"BFGET_group_has_sensor_$i"};
	 my $group_attribute_hide_i = $settings{"BFGET_group_attribute_hide_$i"};
	
	 for (my $j = 1; $j <= $group_num_attributes_i; $j++)
	 {
		my $group_attribute_i_j = $settings{"BFGET_group_attribute_${i}_$j"};

		if ($group_has_sensor_i eq "true")
		{
		  execute("$mql -e 'alter table $group_target_table_i add column sensor_$group_attribute_i_j $group_attribute_type_i' $database", $verbose);

		  execute("$mql -e 'update $group_target_table_i set sensor_$group_attribute_i_j=$group_attribute_i_j' $database", $verbose);
		}

		my $iteration = length($settings{"BFGET_iteration"}) > 0 ? $settings{"BFGET_iteration"} : 0;
		if ($group_attribute_hide_i eq "true")
		{
		  execute("$mql -e 'alter table $group_target_table_i change $group_attribute_i_j ${group_attribute_i_j}_i$iteration $group_attribute_type_i' $database", $verbose);
		}
	 }
  }
}

fix_expression_table;
fix_gene_table;
if ($fix_experiment_table eq "true") { fix_experiment_table; }
fix_attributes;
