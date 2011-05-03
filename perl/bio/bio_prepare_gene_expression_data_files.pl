#! /usr/bin/perl

#----------------------------------------------------------------------------------------------------------------------------------------------------------------------
# PREFIX: BPGEDF_
#
# input: 
#    BPGEDF_mql - database access
#    BPGEDF_database - database access
#    BPGEDF_gene_table - the prefix of the table. e.g. "g1", then we will have "g_g1" for genes, "c_g1" for conditions and "e_g1" for expressions
#    BPGEDF_experiment_table = the experiment table
#    BPGEDF_expression_table = the expression table
#    BPGEDF_max_gene_clusters - the maximum number of gene clusters to pass to DoublePCluster.exe
#    BPGEDF_max_cond_clusters - the maximum number of condition clusters to pass to DoublePCluster.exe
#    BPGEDF_expression_file - the actual expression file
#    BPGEDF_num_headings - the number of column headers that the expression file has BEFORE the actual data columns
#    BPGEDF_num_header_rows - the number of row headers that the expression file has BEFORE the actual data rows
#    BPGEDF_gene_name_location_within_heading - position of gene_name
#    BPGEDF_genes_list - the list of genes to extract from the expression file or "ALL" for extracting all the genes
#    BPGEDF_experiments_list - the list of experiments to extract from the expression file or "ALL" for extracting all the experiments
#    BPGEDF_missing_value_fill - put this string instead of missing values
#    BPGEDF_initial_cluster_method - the clustering program to use in creating the initial clusters. currently we support 'DoublePCluster' and 'PCluster'
#    BPGEDF_create_experiments_table - if true then create the experiments table -- otherwise don't
#    BPGEDF_predefined_gene_cluster_file - if this file exists then it will be used as the cluster file for the genes (format: two columns -- first gene name, second cluster)
#    BPGEDF_predefined_cond_cluster_file - if this file exists then it will be used as the cluster file for the conditions (format: two columns -- first exp. name, second cluster)
#
#    BPGEDF_num_experiment_groups - the number of experiment groups that will be placed together (e.g. for time series)
#    BPGEDF_experiment_group_i - a list of the experiment names, separated by semicolons (e.g. nitrogen 1;nitrogen 2)
#
# output:
#    creates the files for the vanila expression and gene and experiment model and loads them into the database
#----------------------------------------------------------------------------------------------------------------------------------------------------------------------

use strict;

require "$ENV{MYPERLDIR}/lib/bio_load_settings.pl";
require "$ENV{MYPERLDIR}/lib/bio_execute.pl";
require "$ENV{MYPERLDIR}/lib/bio_get_file_dsc.pl";
require "$ENV{MYPERLDIR}/lib/bio_system.pl";
require "$ENV{MYPERLDIR}/lib/bio_name_to_sql_legal_column_name.pl";

my %settings = load_settings($ARGV[0]);

my $mql = $settings{"BPGEDF_mql"};
my $database = $settings{"BPGEDF_database"};
my $gene_table = $settings{"BPGEDF_gene_table"};
my $expression_table = $settings{"BPGEDF_expression_table"};
my $experiment_table = $settings{"BPGEDF_experiment_table"};
my $max_gene_clusters = $settings{"BPGEDF_max_gene_clusters"};
my $max_cond_clusters = $settings{"BPGEDF_max_cond_clusters"};
my $expression_file = $settings{"BPGEDF_expression_file"};
my $num_headings = $settings{"BPGEDF_num_headings"};
my $num_header_rows = $settings{"BPGEDF_num_header_rows"};
my $gene_name_location_within_heading = $settings{"BPGEDF_gene_name_location_within_heading"};
my $genes_list = $settings{"BPGEDF_genes_list"};
my $experiments_list = $settings{"BPGEDF_experiments_list"};
my $missing_value_fill = $settings{"BPGEDF_missing_value_fill"};
my $initial_cluster_method = $settings{"BPGEDF_initial_cluster_method"};
my $create_experiment_table = $settings{"BPGEDF_create_experiments_table"};
my $predefined_gene_cluster_file = $settings{"BPGEDF_predefined_gene_cluster_file"};
my $predefined_cond_cluster_file = $settings{"BPGEDF_predefined_cond_cluster_file"};

my $num_experiment_groups = $settings{"BPGEDF_num_experiment_groups"};

my $r = int(rand 1000000000);

my $verbose = 1;

#---------------------------------------------------------------------------
# clean_experiment_name
#---------------------------------------------------------------------------
sub clean_experiment_name
{
  my $experiment_name = $_[0];
  $experiment_name =~ s/[\"]//g;
  $experiment_name =~ s/[\']//g;
  return $experiment_name;
}

#----------------------------------------------------------------
# load_genes
#----------------------------------------------------------------
sub load_genes
{
  my $table_name = $_[0];
  my $database = $_[1];
  my $genes_data_file = $_[2];

  open(GENE_SQL, ">load_genes.$r.sql");
  print GENE_SQL "drop table if exists $table_name;\n";
  print GENE_SQL "create table $table_name(\n";
  print GENE_SQL "gene_id int primary key,\n";
  print GENE_SQL "gene_name char(50)\n";
  print GENE_SQL ");\n";
  print GENE_SQL "load data local infile \"$genes_data_file\" into table $table_name;\n";
  execute("$mql $database < load_genes.$r.sql");
}

#----------------------------------------------------------------
# load_experiments
#----------------------------------------------------------------
sub load_experiments
{
  my $table_name = $_[0];
  my $database = $_[1];
  my $experiments_data_file = $_[2];

  open(EXPERIMENT_SQL, ">load_experiments.$r.sql");
  print EXPERIMENT_SQL "drop table if exists $table_name;\n";
  print EXPERIMENT_SQL "create table $table_name(\n";
  print EXPERIMENT_SQL "	experiment_id int primary key,\n";
  print EXPERIMENT_SQL "	name char(255)\n";
  print EXPERIMENT_SQL ");\n";
  print EXPERIMENT_SQL "load data local infile \"$experiments_data_file\" into table $table_name;\n";
  execute("$mql $database < load_experiments.$r.sql");
}

#----------------------------------------------------------------
# load_expression
#----------------------------------------------------------------
sub load_expressions
{
  my $table_name = $_[0];
  my $database = $_[1];
  my $expressions_data_file = $_[2];

  open(EXPRESSION_SQL, ">load_expressions.$r.sql");
  print EXPRESSION_SQL "drop table if exists $table_name;\n";
  print EXPRESSION_SQL "create table $table_name(\n";
  print EXPRESSION_SQL "	level_id int primary key,\n";
  print EXPRESSION_SQL "	gene int,\n";
  print EXPRESSION_SQL "	experiment int,\n";

  # ASSUMPTION -- ALL THE GROUPS ARE ALIGNED THE SAME WAY (i.e. ALL HAVE THE SAME NUMBER OF COLUMNS -- SO WE TAKE THE INFO FROM THE FIRST GROUP)
  if ($num_experiment_groups > 0)
  {
    my $experiment_names_in_group = $settings{"BPGEDF_experiment_group_1"};
    my @experiment_names = split(/\;/, $experiment_names_in_group);
	 my $r = @experiment_names;
    for (my $i = 0; $i < @experiment_names; $i++)
    {
		print EXPRESSION_SQL "	exp_level_$i real,\n";
    }
  }
  else
	{
	  print EXPRESSION_SQL "	exp_level real,\n";
  }

  print EXPRESSION_SQL "	key(gene),\n";
  print EXPRESSION_SQL "	key(experiment)\n";
  print EXPRESSION_SQL ");\n";
  print EXPRESSION_SQL "load data local infile \"$expressions_data_file\" into table $table_name;\n";
  execute("$mql $database < load_expressions.$r.sql");
}

#-----------------------------------------------
# PREPARE THE GENE AND EXPRESSION TABLES FOR SQL
#-----------------------------------------------
sub make_gene_expression_sql
{
  open(SETTINGS_BIO_JOIN_GENES, ">tmp.settings.$r");
  print SETTINGS_BIO_JOIN_GENES "BJG_join_top_expressions=$expression_file\n";
  print SETTINGS_BIO_JOIN_GENES "BJG_num_headings=$num_headings\n";
  print SETTINGS_BIO_JOIN_GENES "BJG_gene_name_location_within_heading=$gene_name_location_within_heading\n";
  print SETTINGS_BIO_JOIN_GENES "BJG_number_from_top=100000000\n";
  print SETTINGS_BIO_JOIN_GENES "BJG_join_format=sql\n";
  print SETTINGS_BIO_JOIN_GENES "BJG_missing_value_fill=$missing_value_fill\n";
  print SETTINGS_BIO_JOIN_GENES "BJG_out_expressions=expressions.$r.dat\n";
  print SETTINGS_BIO_JOIN_GENES "BJG_out_genes=genes.$r.dat\n";
  print SETTINGS_BIO_JOIN_GENES "BJG_out_experiments=experiments.$r.dat\n";
  print SETTINGS_BIO_JOIN_GENES "BJG_join_genes_list=$genes_list\n";
  print SETTINGS_BIO_JOIN_GENES "BJG_join_experiments_list=$experiments_list\n";
  print SETTINGS_BIO_JOIN_GENES "BJG_num_header_rows=$num_header_rows\n";

  if ($num_experiment_groups > 0)
  {
    print SETTINGS_BIO_JOIN_GENES "BJG_num_experiment_groups=$num_experiment_groups\n";
    for (my $i = 1; $i <= $num_experiment_groups; $i++)
    {
      print SETTINGS_BIO_JOIN_GENES "BJG_experiment_group_$i=" . $settings{"BPGEDF_experiment_group_$i"} . "\n";
    }
  }

  execute("$ENV{HOME}/develop/perl/bio/bio_join_genes.pl tmp.settings.$r");
  delete_file("tmp.settings.$r");
  delete_file("full_gene_list.$r");
}

#-------------------------------------
# PREPARE THE EXPERIMENT TABLE FOR SQL
#-------------------------------------
sub make_experiment_sql
{
  if ($num_experiment_groups > 0)
  {
	 open(EXPERIMENTS, ">experiments.$r.dat");

    for (my $i = 1; $i <= $num_experiment_groups; $i++)
    {
      print EXPERIMENTS ($i - 1) . "\t" . $settings{"BPGEDF_experiment_group_$i"} . "\n";
    }
  }
}

#------------------
# DO PCLUSTER
#------------------
sub run_pcluster
{
  # CLUSTER GENES
  open(SETTINGS_BIO_JOIN_GENES, ">tmp.settings.$r");
  print SETTINGS_BIO_JOIN_GENES "BJG_join_top_expressions=$expression_file\n";
  print SETTINGS_BIO_JOIN_GENES "BJG_num_headings=$num_headings\n";
  print SETTINGS_BIO_JOIN_GENES "BJG_gene_name_location_within_heading=$gene_name_location_within_heading\n";
  print SETTINGS_BIO_JOIN_GENES "BJG_number_from_top=100000000\n";
  print SETTINGS_BIO_JOIN_GENES "BJG_join_format=pcluster\n";
  print SETTINGS_BIO_JOIN_GENES "BJG_missing_value_fill=$missing_value_fill\n";
  print SETTINGS_BIO_JOIN_GENES "BJG_out_expressions=expressions.$r.dat\n";
  print SETTINGS_BIO_JOIN_GENES "BJG_out_genes=genes.$r.dat\n";
  print SETTINGS_BIO_JOIN_GENES "BJG_out_experiments=experiments.$r.dat\n";
  print SETTINGS_BIO_JOIN_GENES "BJG_join_genes_list=$genes_list\n";
  print SETTINGS_BIO_JOIN_GENES "BJG_join_experiments_list=$experiments_list\n";
  print SETTINGS_BIO_JOIN_GENES "BJG_num_header_rows=$num_header_rows\n";
  execute("$ENV{HOME}/develop/perl/bio/bio_join_genes.pl tmp.settings.$r");

  delete_file("tmp.settings.$r");

  open(LABELS, ">labels.$r.dat");
  my @attr_set = get_file_dsc($expression_file, $verbose);
  for (my $i = $num_headings; $i < @attr_set; $i++)
  {
	 my $exp_name = $attr_set[$i];

	 print LABELS ($i - $num_headings + 1) . "\t" . $exp_name . "\n";
  }
  execute("$ENV{HOME}/develop/PCluster/PCluster.exe -u -C expressions.$r.dat.genes.clusters,$max_gene_clusters expressions.$r.dat labels.$r.dat expressions.$r.dat");

  # CLUSTER CONDITIONS
  my $num_exps = @attr_set;
  my $last_column = $num_exps + 2;
  execute("cut -f2-$last_column expressions.$r.dat > tmp.$r.1");
  execute("transpose.pl < tmp.$r.1 > tmp.$r.2");
  execute("cut -f1 tmp.$r.2 > tmp.$r.3");
  execute("paste tmp.$r.3 tmp.$r.2 > expressions.$r.dat");
  delete_file("tmp.$r.1");
  delete_file("tmp.$r.2");
  delete_file("tmp.$r.3");

  open(LABELS, ">labels.$r.dat");
  @attr_set = get_file_dsc("expressions.$r.dat", $verbose);
  for (my $i = 2; $i < @attr_set; $i++)
  {
	 my $gene_name = $attr_set[$i];

	 print LABELS ($i - 2 + 1) . "\t" . $gene_name . "\n";
  }
  execute("$ENV{HOME}/develop/PCluster/PCluster.exe -u -C expressions.$r.dat.conds.clusters,$max_cond_clusters expressions.$r.dat labels.$r.dat expressions.$r.dat");
  delete_file("labels.$r.dat");

  delete_file("full_gene_list.$r");
}

#------------------
# DO DOUBLEPCLUSTER
#------------------
sub run_doublepcluster
{
  open(SETTINGS_BIO_JOIN_GENES, ">tmp.settings.$r");
  print SETTINGS_BIO_JOIN_GENES "BJG_join_top_expressions=$expression_file\n";
  print SETTINGS_BIO_JOIN_GENES "BJG_num_headings=$num_headings\n";
  print SETTINGS_BIO_JOIN_GENES "BJG_gene_name_location_within_heading=$gene_name_location_within_heading\n";
  print SETTINGS_BIO_JOIN_GENES "BJG_number_from_top=100000000\n";
  print SETTINGS_BIO_JOIN_GENES "BJG_join_format=pcluster\n";
  print SETTINGS_BIO_JOIN_GENES "BJG_missing_value_fill=$missing_value_fill\n";
  print SETTINGS_BIO_JOIN_GENES "BJG_out_expressions=expressions.$r.dat\n";
  print SETTINGS_BIO_JOIN_GENES "BJG_out_genes=genes.$r.dat\n";
  print SETTINGS_BIO_JOIN_GENES "BJG_out_experiments=experiments.$r.dat\n";
  print SETTINGS_BIO_JOIN_GENES "BJG_join_genes_list=$genes_list\n";
  print SETTINGS_BIO_JOIN_GENES "BJG_join_experiments_list=$experiments_list\n";
  print SETTINGS_BIO_JOIN_GENES "BJG_num_header_rows=$num_header_rows\n";
  execute("$ENV{HOME}/develop/perl/bio/bio_join_genes.pl tmp.settings.$r");

  delete_file("tmp.settings.$r");
  #execute("$ENV{HOME}/develop/PCluster/DoublePCluster.exe -B -g $max_gene_clusters -c $max_cond_clusters -C expressions.$r.dat expressions.$r.dat expressions.$r.dat");

  my $exec_str = "$ENV{MYPERLDIR}/lib/DoublePCluster.exe -B ";
  $exec_str .=   "-g $max_gene_clusters ";
  $exec_str .=   "-c $max_cond_clusters ";
  $exec_str .=   "-G $max_gene_clusters ";
  $exec_str .=   "-E $max_cond_clusters ";
  $exec_str .=   "-C expressions.$r.dat ";
  $exec_str .=   "expressions.$r.dat ";
  $exec_str .=   "expressions.$r.dat";
  execute("$exec_str", 1);
  delete_file("full_gene_list.$r");
}

#----------------------------
# load_cluster_results
#----------------------------
sub load_cluster_results
{
  if (length($predefined_gene_cluster_file) > 0 && file_exists($predefined_gene_cluster_file)) { copy_file("$predefined_gene_cluster_file", "expressions.$r.dat.genes.clusters"); }
  if (length($predefined_cond_cluster_file) > 0 && file_exists($predefined_cond_cluster_file)) { copy_file("$predefined_cond_cluster_file", "expressions.$r.dat.conds.clusters"); }

  open(SETTINGS_BIO_ADD_COLUMN, ">tmp.settings.$r");
  print SETTINGS_BIO_ADD_COLUMN "BAC_update_table=$gene_table\n";
  print SETTINGS_BIO_ADD_COLUMN "BAC_update_column=g_cluster_i0\n";
  print SETTINGS_BIO_ADD_COLUMN "BAC_update_column_file=expressions.$r.dat.genes.clusters\n";
  print SETTINGS_BIO_ADD_COLUMN "BAC_column_type=int\n";
  print SETTINGS_BIO_ADD_COLUMN "BAC_where_column=gene_name\n";
  print SETTINGS_BIO_ADD_COLUMN "BAC_database=$database\n";
  print SETTINGS_BIO_ADD_COLUMN "BAC_mql=$mql\n"; 
  print SETTINGS_BIO_ADD_COLUMN "BAC_add_key=1\n";
  execute("$ENV{HOME}/develop/perl/bio/bio_add_column.pl tmp.settings.$r");
  delete_file("tmp.settings.$r");

  if (!($num_experiment_groups > 0))
  {
    open(SETTINGS_BIO_ADD_COLUMN, ">tmp.settings.$r");
    print SETTINGS_BIO_ADD_COLUMN "BAC_update_table=$experiment_table\n";
    print SETTINGS_BIO_ADD_COLUMN "BAC_update_column=e_cluster_i0\n";
    print SETTINGS_BIO_ADD_COLUMN "BAC_update_column_file=expressions.$r.dat.conds.clusters\n";
    print SETTINGS_BIO_ADD_COLUMN "BAC_column_type=int\n";
    print SETTINGS_BIO_ADD_COLUMN "BAC_where_column=name\n";
    print SETTINGS_BIO_ADD_COLUMN "BAC_database=$database\n";
    print SETTINGS_BIO_ADD_COLUMN "BAC_mql=$mql\n"; 
    print SETTINGS_BIO_ADD_COLUMN "BAC_add_key=1\n";

    open(CONDS, "<expressions.$r.dat.conds.clusters") or die "could not open expressions.$r.dat.conds.clusters\n";
    open(NEW_CONDS, ">tmp_$r");
    while(<CONDS>)
    {
      chop;
		
      my $exp_name;
      my $cluster;
      ($exp_name, $cluster) = split(/\t/);
		
      print NEW_CONDS clean_experiment_name($exp_name) . "\t$cluster\n";
      #print clean_experiment_name($exp_name) . "\t$cluster\n";
    }
    execute("mv tmp_$r expressions.$r.dat.conds.clusters");
	
    execute("$ENV{HOME}/develop/perl/bio/bio_add_column.pl tmp.settings.$r");
    delete_file("tmp.settings.$r");
  }
}

#-------------------------------------
# MAIN
#-------------------------------------
make_gene_expression_sql;
load_genes("$gene_table", $database, "genes.$r.dat");

if ($create_experiment_table eq "true")
{
  make_experiment_sql;
  load_experiments("$experiment_table", $database, "experiments.$r.dat");
}

load_expressions("$expression_table", $database, "expressions.$r.dat");

if ($initial_cluster_method eq "DoublePCluster")
{
  run_doublepcluster;
  load_cluster_results;
}
elsif ($initial_cluster_method eq "PCluster")
{
  run_pcluster;
  load_cluster_results;

}
elsif ($initial_cluster_method eq "PredefinedClusters")
{
  load_cluster_results;
}

delete_file("load_genes.$r.sql");
delete_file("load_genes.$r.sql");
delete_file("load_experiments.$r.sql");
delete_file("load_expressions.$r.sql");
delete_file("expressions.$r.dat.atr");
delete_file("expressions.$r.dat.gtr");
delete_file("expressions.$r.dat.cdt");
delete_file("expressions.$r.dat.genes.clusters");
delete_file("expressions.$r.dat.conds.clusters");
delete_file("experiments.$r.dat");
delete_file("genes.$r.dat");
delete_file("expressions.$r.dat");
