#! /usr/bin/perl

#------------------------------------------------------------------------------------------------------
# input: 
#    BATB_mql - database access
#    BATB_database - the name of the database to use
#    BATB_num_attribute_db_tables - the number of attribute tables that we're going to use
#    BATB_gene_list_file - list of the genes to output    
#    BATB_ignore_attribute_value - if the value of the attribute is equal to this, don't print it (since we use a sparse representation in the visualizer)
#
#    BATB_attribute_db_table_i - the table name of the i-th attribute table
#    BATB_attribute_gene_column_name_i - the name of the gene column in the db table of the i-th attribute table
#    BATB_num_attributes_i - the number of attributes in the i-th attribute table
#    BATB_attribute_name_i_j - list of attributes to include (columns in attribute_db_table) for the i-th attribute table
#
# output:
#    the attribute values for the genes in the gene list file in the format of the bicluster visualizer
#------------------------------------------------------------------------------------------------------

use strict;

require "$ENV{MYPERLDIR}/lib/bio_load_settings.pl";
require "$ENV{MYPERLDIR}/lib/bio_execute.pl";

my %settings = load_settings($ARGV[0]);

#----------------------------------------------------------------
# parameters
#----------------------------------------------------------------
my $mql = $settings{"BATB_mql"}; 
my $database = $settings{"BATB_database"};

my $num_attribute_db_tables = $settings{"BATB_num_attribute_db_tables"};

my $gene_list_file = $settings{"BATB_gene_list_file"};
my $ignore_attribute_value = $settings{"BATB_ignore_attribute_value"};

my $output_file;
if (length($ARGV[1]) > 0) { $output_file = $ARGV[1]; }
else { $output_file = "settings_file.tmp"; }
open(OUTPUT_FILE, ">$output_file");

my $r = int(rand 1000000000);

my $verbose = 1;

#----------------------------------------------------------------
# main
#----------------------------------------------------------------
my $attribute_counter = 0;
my $from_clause = "";
my $where_clause = "";
my $select_attributes = $settings{"BATB_attribute_db_table_1"} . "." . $settings{"BATB_attribute_gene_column_name_1"};
my $i;
my @attribute_names;
for ($i = 1; $i <= $num_attribute_db_tables; $i++)
{
  my $gene_column_name = $settings{"BATB_attribute_gene_column_name_$i"};
  my $attribute_db_table = $settings{"BATB_attribute_db_table_$i"};

  my $num_attributes = $settings{"BATB_num_attributes_$i"};
  my $j;
  for ($j = 1; $j <= $num_attributes; $j++)
  {
	my $attribute_i = $settings{"BATB_attribute_name_${i}_$j"};

	$select_attributes .= ",$attribute_db_table.$attribute_i";
	
	$attribute_names[$attribute_counter] = $attribute_i;
	$attribute_counter++;
  }

  if ($i == 1) { $from_clause .= "$attribute_db_table"; }
  elsif ($i > 1) { $from_clause .= ",$attribute_db_table"; }

  if ($i == 2)
  {
	 $from_clause .= " where "; 
	 $from_clause .= $settings{"BATB_attribute_db_table_" . ($i-1)} . "." . $settings{"BATB_attribute_gene_column_name_" . ($i-1)} . "=";
	 $from_clause .= $settings{"BATB_attribute_db_table_$i"} . "." . $settings{"BATB_attribute_gene_column_name_$i"};
  }
  elsif ($i > 2) 
  {
	 $from_clause .= " and "; 
	 $from_clause .= $settings{"BATB_attribute_db_table_" . ($i-1)} . "." . $settings{"BATB_attribute_gene_column_name_" . ($i-1)} . "=";
	 $from_clause .= $settings{"BATB_attribute_db_table_$i"} . "." . $settings{"BATB_attribute_gene_column_name_$i"};
  }
}

print OUTPUT_FILE "<TSCAttributes NumAttr=\"$attribute_counter\">\n\n";
for (my $i = 0; $i < $attribute_counter; $i++)
{
  print OUTPUT_FILE "<attr id=\"$i\" name=\"$attribute_names[$i]\">\n";
  print OUTPUT_FILE "</attr>\n";
}

my $actual_gene_list_file;
if ($gene_list_file eq "ALL")
{
  my $table = $settings{"BATB_attribute_db_table_1"};
  execute("$mql -Ne 'select gene_name from $table' $database > tmp.$r", $verbose);
  $actual_gene_list_file = "tmp.$r";
}
else
{
  $actual_gene_list_file = $gene_list_file;
}

my %genes;
open(GENE_LIST_FILE, "<$actual_gene_list_file") or die "could not open $actual_gene_list_file";
while(<GENE_LIST_FILE>)
{
  chop;

  $genes{$_} = "1";
}
if ($gene_list_file eq "ALL") { execute("rm tmp.$r", $verbose); }

execute("$mql -Ne 'select $select_attributes from $from_clause $where_clause' $database > attributes.$r.dat", $verbose);

open(ATTRIBUTES, "<attributes.$r.dat");
while (<ATTRIBUTES>)
{
  chop;

  my @row = split(/\t/);

  if ($genes{$row[0]} eq "1")
  {
	 my $upper_case_name = "\U$row[0]\E";

	 my $gene_description;

	 $gene_description = $upper_case_name;

	 #print OUTPUT_FILE "<gene UID=\"$upper_case_name\"";
	 print OUTPUT_FILE "<gene UID=\"$gene_description\"";

	 for (my $i = 0; $i < $attribute_counter; $i++)
	 {
		if ($row[$i+1] != $ignore_attribute_value)
		{
		  print OUTPUT_FILE " attr$i=\"$row[$i+1]\"";
		  #print OUTPUT_FILE " attr$i=\"1\"";
		}
	 }

	 print OUTPUT_FILE ">\n";
	 print OUTPUT_FILE "</gene>\n";
  }
}

print OUTPUT_FILE "\n</TSCAttributes>\n\n";

execute("rm attributes.$r.dat");
