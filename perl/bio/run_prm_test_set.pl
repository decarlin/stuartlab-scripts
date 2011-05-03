#! /usr/bin/perl

#---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# input:
#
#    test_gene_list - 
#    prefix - the prefix of the files that we use
#
#    dir - the directory of the prm files
#
#---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

use strict;

require "$ENV{MYPERLDIR}/lib/bio_load_settings.pl";
require "$ENV{MYPERLDIR}/lib/bio_system.pl";
require "$ENV{MYPERLDIR}/lib/load_file_attribute_groups.pl";

my %settings = load_settings($ARGV[0]);
my %file_attribute_groups = load_file_attribute_groups($ARGV[0]);
my $settings_file = $ARGV[0];

my $r = int(rand 1000000000);

my $iteration = $ARGV[1];
my $next_iteration = $iteration + 1;

my $original_gene_table = $settings{"gene_table"};
my $original_experiment_table = "c_$original_gene_table";
my $original_expression_table = "e_$original_gene_table";

my $gene_table = $settings{"gene_table"} . "_test";
my $experiment_table = $original_experiment_table;
my $expression_table = "e_$gene_table";

my $prefix = "test_" . $settings{"prefix"};
my $original_prefix = $settings{"prefix"};
my $dir = $settings{"dir"};

my @hide_attributes;
my $num_hide_attributes = 0;

#-------------------------------------------
# get_group_attribute
#-------------------------------------------
sub get_group_attribute
{
  my $attribute_name = $_[0];

  if (length($settings{"$attribute_name"}) > 0) { return $settings{"$attribute_name"}; }
  else { return $file_attribute_groups{"$attribute_name"}; }
}

#-------------------
# make_settings_file
#-------------------
sub make_settings_file
{
  copy_file("$settings_file", "$settings_file.$r");

  append_to_file("$settings_file.$r", "is_test_set=true");
  append_to_file("$settings_file.$r", "iteration=$iteration");

  execute("bio_prepare_default_settings.pl $settings_file.$r $settings_file.$r.out");
}

#-------------------
# cleanup
#-------------------
sub cleanup
{
  delete_file("$settings_file.$r");
  delete_file("$settings_file.$r.out");
}

#---------------------
# load_hide_attributes
#---------------------
sub load_hide_attributes
{
  my $test_hide_attributes = $settings{"test_hide_attributes"};

  my @attribute_groups = split(/\,/, $test_hide_attributes);

  for (my $i = 0; $i < @attribute_groups; $i++)
  {
	 if ($attribute_groups[$i] =~ /attribute_group/)
	 {
		$attribute_groups[$i] =~ /attribute_group_(.*)/;
		my $attribute_group_num = $1;
		
		my $num_attributes_in_group = get_group_attribute("attribute_group_num_$attribute_group_num");

		for (my $j = 1; $j <= $num_attributes_in_group; $j++)
		{
		  my $attribute_name = get_group_attribute("attribute_group_${attribute_group_num}_$j");

		  $hide_attributes[$num_hide_attributes] = get_group_attribute("attribute_group_${attribute_group_num}_$j");
		  $num_hide_attributes++;
		}
	 }
	 elsif ($attribute_groups[$i] =~ /gene_cluster/)
	 {
		$hide_attributes[$num_hide_attributes] = "g_cluster";
		$num_hide_attributes++;
	 }
	 elsif ($attribute_groups[$i] =~ /cond_cluster/)
	 {
		$hide_attributes[$num_hide_attributes] = "e_cluster";
		$num_hide_attributes++;
	 }
  }
}

#---------------------
# make_meta_file
#---------------------
sub make_meta_file
{
  execute("bio_create_prm_meta.pl $settings_file.$r.out");

  change_attribute_in_file("$dir/${prefix}_0.meta", "$dir/${prefix}_$iteration.meta", "${prefix}_0", "${prefix}_$iteration");

  change_attribute_in_file("$dir/${prefix}_$iteration.meta", "$dir/${prefix}_$iteration.meta", "_i0", "_i$next_iteration");
  change_attribute_in_file("$dir/${prefix}_$iteration.meta", "$dir/${prefix}_$iteration.meta", "#network", "network");
  change_attribute_in_file("$dir/${prefix}_$iteration.meta", "$dir/${prefix}_$iteration.meta", "force_incomplete_data=false", "force_incomplete_data=true");
  change_attribute_in_file("$dir/${prefix}_$iteration.meta", "$dir/${prefix}_$iteration.meta", "learn_tree_cpds=true", "learn_tree_cpds=false");
  change_attribute_in_file("$dir/${prefix}_$iteration.meta", "$dir/${prefix}_$iteration.meta", "NumGroupRvs", "#NumGroupRvs");
  change_attribute_in_file("$dir/${prefix}_$iteration.meta", "$dir/${prefix}_$iteration.meta", "steps_file=", "#steps_file=");
  change_attribute_in_file("$dir/${prefix}_$iteration.meta", "$dir/${prefix}_$iteration.meta", "learn_tree_cpds_independent=true", "learn_tree_cpds_independent=false");
  change_attribute_in_file("$dir/${prefix}_$iteration.meta", "$dir/${prefix}_$iteration.meta", "structure_prior_kappa", "#structure_prior_kappa");

  for (my $i = 0; $i < $num_hide_attributes; $i++)
  {
	 change_attribute_in_file("$dir/${prefix}_$iteration.meta", "$dir/${prefix}_$iteration.meta", "sensor_$hide_attributes[$i]", "tmp_$r");
	 change_attribute_in_file("$dir/${prefix}_$iteration.meta", "$dir/${prefix}_$iteration.meta", "$hide_attributes[$i]", "hidden_$hide_attributes[$i]");
	 change_attribute_in_file("$dir/${prefix}_$iteration.meta", "$dir/${prefix}_$iteration.meta", "tmp_$r", "sensor_$hide_attributes[$i]");
  }
}

#---------------------
# make_dsc_file
#---------------------
sub make_dsc_file
{
  # MAKE THE NEW DSC FILE
  copy_file("$dir/out/${original_prefix}_l$iteration.out", "$dir/${prefix}_$iteration.dsc");

  for (my $j = 0; $j < $num_hide_attributes; $j++)
  {
	 change_attribute_in_file("$dir/${prefix}_$iteration.dsc", "$dir/${prefix}_$iteration.dsc", "sensor_$hide_attributes[$j]", "tmp_$r");
	 change_attribute_in_file("$dir/${prefix}_$iteration.dsc", "$dir/${prefix}_$iteration.dsc", "$hide_attributes[$j]", "hidden_$hide_attributes[$j]");
	 change_attribute_in_file("$dir/${prefix}_$iteration.dsc", "$dir/${prefix}_$iteration.dsc", "tmp_$r", "sensor_$hide_attributes[$j]");
  }

  change_attribute_in_file("$dir/${prefix}_$iteration.dsc", "$dir/${prefix}_$iteration.dsc", "$original_experiment_table", "tmp_$r");
  change_attribute_in_file("$dir/${prefix}_$iteration.dsc", "$dir/${prefix}_$iteration.dsc", "$original_gene_table", "$gene_table");
  change_attribute_in_file("$dir/${prefix}_$iteration.dsc", "$dir/${prefix}_$iteration.dsc", "tmp_$r", "$original_experiment_table");
}

#---------------------
# make_tree_file
#---------------------
sub make_tree_file
{
  # UPDATE THE SETTINGS FOR bio_prm_to_bn_tree.pl
  open(SETTINGS, ">tmp.settings.$r");
  print SETTINGS "convert_prm_file=$dir/${prefix}_$iteration.dsc\n";
  print SETTINGS "convert_bn_file=$dir/${prefix}_$iteration.tree.dsc\n";
  print SETTINGS "convert_rel=$expression_table\n";
  print SETTINGS "join_for_$gene_table=${expression_table}_${gene_table}\n";
  print SETTINGS "join_for_$experiment_table=${expression_table}_${experiment_table}\n";
  execute("$ENV{HOME}/develop/perl/bio/bio_prm_to_bn_tree.pl tmp.settings.$r");
  delete_file("tmp.settings.$r");
}

#---------------------
# MAIN
#---------------------
make_settings_file;

execute("bio_prepare_gene_expression_data_files.pl $settings_file.$r.out");

execute("bio_add_attributes_to_table.pl $settings_file.$r.out");

execute("bio_fix_gene_expression_tables.pl $settings_file.$r.out");

load_hide_attributes;

make_meta_file;
make_dsc_file;
make_tree_file;

execute("cd $dir; $ENV{HOME}/develop/frog_linux_release/SamplePrograms/ll ${prefix}_$iteration.meta");

cleanup;
