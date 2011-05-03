#! /usr/bin/perl

#-----------------------------------------------------------------------------------------------------------
# input: 
#    mql - db access
#    prefix - the prefix of the files we're using
#    dir - the directory of the file
#    iteration - the iteration number
#    database - the database we're using
#    gene_table - the name of the main gene table we're using
#    has_cond_cluster = do we have a condition cluster
#    has_gene_cluster - do we have a gene cluster
#    dissect_gene_file - the master annotation file to use by dissect.awk
#
#    attribute_groups - the number of attribute groups
#    attribute_group_num_i - the number of attribute in the i-th group
#    attribute_group_target_table_i - the name of the target table for group i
#
#    num_experiment_groups - the number of experiment groups that will be placed together (e.g. for time series)
#    experiment_group_i - a list of the experiment names, separated by semicolons (e.g. nitrogen 1;nitrogen 2)
#
# output:
#    sets the database in mysql with the additional column and then calls bio_update_column.pl to load data
#
#
# Usage: dissect.awk <options> <TSC file> <Gene Names> <Expr Annotations>
#
#  <TSC File>         - output of PRM learning
#  <Gene Names>       - tab-seperated file (with header line)
#                       Each line <Accession> <Name> <Description>
#  <Expr Annotations> - tab-seperated file (with header line)
#                       Each line <Expr> <Annotation1> ... <AnnotationK>
#                       each annoation is binary
#
#  Options:
#
#    -v ExpandThreshold=<T>  - set score threshold for expansions
#    -v DoExpand=[01]        - control wheather to expand clusters
#    -v PrintSummary=1       - print summary line per cluster
#    -v PrintSummary=0       - print expanded description per cluster
#    -v DoBoth=1             - print summary & expanded report
# 
#-----------------------------------------------------------------------------------------------------------

use strict;

require "$ENV{MYPERLDIR}/lib/bio_load_settings.pl";
require "$ENV{MYPERLDIR}/lib/bio_execute.pl";
require "$ENV{MYPERLDIR}/lib/bio_load_file_to_memory.pl";
require "$ENV{MYPERLDIR}/lib/load_file_attribute_groups.pl";

my %settings = load_settings($ARGV[0]);
my %file_attribute_groups = load_file_attribute_groups($ARGV[0]);

my $mql = $settings{"mql"};

my $prefix = $settings{"prefix"};

my $dir = $settings{"dir"};

my $database = $settings{"database"};
my $gene_table = $settings{"gene_table"};

my $attribute_groups = $settings{"attribute_groups"};

my $num_experiment_groups = $settings{"num_experiment_groups"};

my $has_cond_cluster = $settings{"has_cond_cluster"};
my $has_gene_cluster = $settings{"has_cond_cluster"};

my $iteration;
if (length($ARGV[1]) > 0) { $iteration = $ARGV[1]; }
else { $iteration = $settings{"iteration"}; }
my $next_iteration = $iteration + 1;

my $experiment_table = "c_$gene_table";
my $expression_table = "e_$gene_table";

my $tsc_file = "$dir/out/${prefix}_l$iteration.tsc";
my $net_file = "$dir/out/${prefix}_l$iteration.net";

my $r = int(rand 1000000000);
my $verbose = 1;

my $dissect_gene_file = $settings{"dissect_gene_file"};

#-------------------------------------------
# get_group_attribute
#-------------------------------------------
sub get_group_attribute
{
  my $attribute_name = $_[0];

  if (length($settings{"$attribute_name"}) > 0) { return $settings{"$attribute_name"}; }
  else { return $file_attribute_groups{"$attribute_name"}; }
}

#----------------
#  make_gene_file
#----------------
sub make_gene_file
{
  my @full_genes = load_file_to_memory($dissect_gene_file);

  my $select_genes = "gene_name";
  if ($has_gene_cluster == 1) { $select_genes .= ", g_cluster_i$next_iteration as g_cluster"; }

  execute("$mql -Ne 'select $select_genes from $gene_table' $database > tmp.$r", $verbose);
  my @genes = load_file_to_memory("tmp.$r");
  execute("rm tmp.$r");

  my %hash_genes;
  my $i;
  for ($i = 0; $i < @genes; $i++)
  {
	$hash_genes{$genes[$i][0]} = $i;
  }

  open(GENE_ANNOTATION_FILE, ">genes.dissect.$r");

  if ($has_gene_cluster == 1) { print GENE_ANNOTATION_FILE "ORF\tName\tDesc\tg_cluster\n"; }
  else { print GENE_ANNOTATION_FILE "ORF\tName\tDesc\n"; }

  for ($i = 0; $i < @full_genes; $i++)
  {
	if (length($hash_genes{$full_genes[$i][0]}) > 0)
	{
	  if ($has_gene_cluster == 1)
	  {
		print GENE_ANNOTATION_FILE "$full_genes[$i][0]\t$full_genes[$i][1]\t$full_genes[$i][2]\t$genes[$hash_genes{$full_genes[$i][0]}][1]\n";
	  }
	  else
	  {
		print GENE_ANNOTATION_FILE "$full_genes[$i][0]\t$full_genes[$i][1]\t$full_genes[$i][2]\n";
	  }
	}
  }
}

#------------------------
# make experiments file
#------------------------
sub make_experiments_file
{
  if ($num_experiment_groups > 0)
  {
    open(OUT_EXPERIMENTS, ">experiments.dissect.$r");

    print OUT_EXPERIMENTS "name\n";

    for (my $i = 1; $i <= $num_experiment_groups; $i++)
    {
      my $experiment_attr_str = $settings{"experiment_group_$i"};
      my @splitted_experiment_attrs = split(/\;/, $experiment_attr_str);
      my $num_experiment_attrs = @splitted_experiment_attrs;

      for (my $j = 0; $j < $num_experiment_attrs; $j++)
      {
	#print OUT_EXPERIMENTS $splitted_experiment_attrs[$j] . "\n";
	print OUT_EXPERIMENTS "E$j\n";
      }
    }
  }
  else
  {
    my $attribute_select = "name";

    if ($has_cond_cluster == 1) { $attribute_select .= ",e_cluster_i$next_iteration as e_cluster" }

    my $i;
    for ($i = 1; $i <= $attribute_groups; $i++)
    {
      my $attribute_group_num_i = get_group_attribute("attribute_group_num_$i");
      my $attribute_group_target_table_i = get_group_attribute("attribute_group_target_table_$i");
		
      my $attribute_add_on = "";
      if (get_group_attribute("attribute_group_hide_attributes_$i") eq "true") { $attribute_add_on = "._i$next_iteration"; }

      if ($attribute_group_target_table_i eq $experiment_table)
	{
	  my $j;
	  for ($j = 1; $j <= $attribute_group_num_i; $j++)
	  {	
	    my $attribute_group_i_j = get_group_attribute("attribute_group_${i}_$j");

	    $attribute_select .= ",$attribute_group_i_j$attribute_add_on as $attribute_group_i_j ";
	  }
	}
    }

    execute("$mql -e 'select $attribute_select from $experiment_table' $database > experiments.dissect.$r", $verbose);
  }
}

#make_gene_file;
#make_experiments_file;

#execute("gawk -f $ENV{HOME}/develop/perl/dissect.awk -v PrintAll=1 -v DoExpand=0 -v PrintSummary=1 $tsc_file $dissect_gene_file > $net_file");
execute("gawk -f $ENV{HOME}/develop/perl/dissect.awk -v PrintAll=1 -v DoExpand=0 -v PrintSummary=1 $tsc_file /u/erans/D/Biology/utils/data/combined_yeast_go.out.dat > $net_file");

#execute("gawk -f $ENV{HOME}/develop/perl/dissect.awk $tsc_file genes.dissect.$r experiments.dissect.$r > $net_file", $verbose);
#execute("rm genes.dissect.$r");
#execute("rm experiments.dissect.$r");
