#! /usr/bin/perl

#-----------------------------------------------------------------------------------------------------------
# input: 
#    BRPO_dir - the directory of the prm
#    BRPO_prefix - the prefix used for all files
#    BRPO_iteration - the current iteration - THIS CAN ALSO BE ACHIEVED THROUGH ARGV[1]
#    BRPO_num_keys_to_add - the number of attributes for which to add keys in learning
#    BRPO_key_rel_i - the relation of the i-th key to add
#    BRPO_key_prefix_i - the prefix of the i-th key to add
#
#    BRPO_gene_table - the gene table -- needed for dictionary creation
#    BRPO_experiment_table - the experiment table -- needed for dictionary creation
#    BRPO_has_gene_cluster - whether or not we have a gene cluster -- needed for dictionary creation
#    BRPO_has_cond_cluster - whether or not we have a cond cluster -- needed for dictionary creation
#
# output:
#    run the observed prm
#-----------------------------------------------------------------------------------------------------------

use strict;

require "$ENV{MYPERLDIR}/lib/bio_load_settings.pl";
require "$ENV{MYPERLDIR}/lib/bio_execute.pl";
require "$ENV{MYPERLDIR}/lib/bio_change_attribute_in_file.pl";

my %settings = load_settings($ARGV[0]);

my $prefix = $settings{"BRPO_prefix"};
my $dir = $settings{"BRPO_dir"};
my $mql = $settings{"BRPO_mql"};
my $database = $settings{"BRPO_database"};
my $num_keys_to_add = $settings{"BRPO_num_keys_to_add"};

my $has_gene_cluster = $settings{"BRPO_has_gene_cluster"};
my $has_cond_cluster = $settings{"BRPO_has_cond_cluster"};
my $gene_table = $settings{"BRPO_gene_table"};
my $experiment_table = $settings{"BRPO_experiment_table"};

#my $executable_dir = "$ENV{MYPERLDIR}/lib/SamplePrograms";
my $executable_dir = "$ENV{MYPERLDIR}/lib/SamplePrograms";

my $verbose = 1;

my $iteration;
if (length($ARGV[1]) > 0) { $iteration = $ARGV[1]; }
else { $iteration = $settings{"BRPO_iteration"}; }

sub make_dictionaries
{
  # MAKE THE DICTIONARIES
  if ($has_gene_cluster) { execute("$mql -e 'select gene_id, gene_name as ORF, g_cluster_i$iteration as Cluster from $gene_table' $database > $dir/$gene_table.dsc", $verbose); }
  else { execute("$mql -e 'select gene_id, gene_name as ORF from $gene_table' $database > $dir/$gene_table.dsc", $verbose); }

  if ($has_cond_cluster) { execute("$mql -e 'select experiment_id, name, e_cluster_i$iteration as Cluster from $experiment_table' $database > $dir/$experiment_table.dsc", $verbose); }
  else { execute("$mql -e 'select experiment_id, name from $experiment_table' $database > $dir/$experiment_table.dsc", $verbose); }
}

sub change_attributes
{
  change_attribute_in_file("$dir/${prefix}_0.meta", "$dir/${prefix}_$iteration.meta", "${prefix}_0", "${prefix}_$iteration");
  change_attribute_in_file("$dir/${prefix}_$iteration.meta", "$dir/${prefix}_$iteration.meta", "_i0", "_i$iteration");

  change_attribute_in_file("$dir/${prefix}_0.dsc", "$dir/${prefix}_$iteration.dsc", "_i0", "_i$iteration");
}

sub add_keys
{
  # ADD KEYS
  for (my $i = 1; $i <= $num_keys_to_add; $i++)
  {
	 my $table = $settings{"BRPO_key_rel_$i"};
	 my $prefix = $settings{"BRPO_key_prefix_$i"};

	 execute("$mql -e 'alter table $table add key(${prefix}_i$iteration)' $database", $verbose);
  }
}

make_dictionaries;
change_attributes;
add_keys;

execute("cd $dir; $executable_dir/prm_sem ${prefix}_$iteration.meta", $verbose);
