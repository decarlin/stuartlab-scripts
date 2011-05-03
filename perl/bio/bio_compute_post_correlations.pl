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
#
#    expression_file - the expression file
#    expression_file_gene_name_column_name - the name of the gene name column in the file
#
#    iteration - the iteration #
#
# output:
#    creates a default settings that will be used for a full prm run in all its stages
#----------------------------------------------------------------------------------------------------------

use strict;

require "$ENV{MYPERLDIR}/lib/bio_load_settings.pl";
require "$ENV{MYPERLDIR}/lib/bio_execute.pl";

my %settings = load_settings($ARGV[0]);

my $mql = $settings{"mql"};

my $prefix = $settings{"prefix"};

my $dir = $settings{"dir"};

my $database = $settings{"database"};
my $gene_table = $settings{"gene_table"};
my $gene_list = $settings{"gene_list"};

my $expression_file = $settings{"expression_file"};
my $expression_file_gene_name_column_name = $settings{"expression_file_gene_name_column_name"};

my $iteration;
if (length($ARGV[1]) > 0) { $iteration = $ARGV[1]; }
else { $iteration = $settings{"iteration"}; }

my $r = int(rand 1000000000);
my $verbose = 1;

open(SETTINGS, ">settings.$r");

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
  print SETTINGS "BCC_source_table_name1=$gene_table\n";
  print SETTINGS "BCC_output_correlation_file=$dir/out/$gene_table.cor.dat.$iteration\n";
  print SETTINGS "BCC_output_max_correlation_file=$dir/out/$gene_table.max_cor.dat.$iteration\n";
  print SETTINGS "BCC_source_database_name1=$database\n";
  print SETTINGS "BCC_source_file_name1=\n";
  print SETTINGS "BCC_source_type2=file\n";
  print SETTINGS "BCC_source_join2=$expression_file_gene_name_column_name\n";
  print SETTINGS "BCC_source_table_name2=\n";
  print SETTINGS "BCC_source_database_name2=\n";
  print SETTINGS "BCC_source_file_name2=$expression_file\n\n";
}

prepare_for_bio_compute_correlations;

execute("bio_compute_correlations.pl settings.$r");

execute("rm settings.$r");
