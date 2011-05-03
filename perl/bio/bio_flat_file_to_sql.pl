#! /usr/bin/perl

#------------------------------------------------------------------------------------------------------------------------
# input: 
#    BFFTS_file = the file to convert. expected format: first row is header, second and on are data. All is tab-delimited
#    BFFTS_table_name - the name of the sql table to be created
# output:
#    creates the sql and dat file needed for loading this file into mysql
#------------------------------------------------------------------------------------------------------------------------

use strict;

require "$ENV{MYPERLDIR}/lib/bio_load_file_to_memory.pl";
require "$ENV{MYPERLDIR}/lib/bio_get_file_dsc.pl";
require "$ENV{MYPERLDIR}/lib/bio_load_settings.pl";
require "$ENV{MYPERLDIR}/lib/bio_name_to_sql_legal_column_name.pl";

my %settings = load_settings($ARGV[0]);

my $file = length($ARGV[1]) > 0 ? $ARGV[0] : $settings{"BFFTS_file"};
my $table_name = length($ARGV[1]) > 0 ? $ARGV[1] : $settings{"BFFTS_table_name"};

my @data = load_file_to_memory($file);

my $out_sql = "$file.sql";
my $out_data = "$file.dat";
my @col_types;

open(OUT_DATA, ">$out_data");

sub make_dsc
{
  open(OUT_SQL, ">$out_sql");
  print OUT_SQL "drop table if exists $table_name;\n";
  print OUT_SQL "create table $table_name(\n";
  print OUT_SQL "   gene_id int primary key";

  my @file_dsc = get_file_dsc($file);

  for (my $i = 0; $i < @file_dsc; $i++)
  {
	my $sql_name = name_to_sql_legal_column_name($file_dsc[$i]);
	print OUT_SQL ",\n   $sql_name $col_types[$i]";
  }

  print OUT_SQL "\n);\n";
  print OUT_SQL "load data local infile \"$out_data\" into table $table_name;\n";
}

sub make_data
{
  open(OUT_DATA, ">$out_data");

  my @file_dsc = get_file_dsc($file);
  my @file_data = load_file_to_memory($file);

  my @char_lengths;

  for (my $j = 0; $j < @file_dsc; $j++) {
    $col_types[$j] = "int";
    $char_lengths[$j] = 0;
  }

  for (my $i = 1; $i < @file_data; $i++)
  {
	print OUT_DATA ($i - 1) . "\t";
	for (my $j = 0; $j < @file_dsc; $j++)
	{

	  #the type inference
	  if (!($file_data[$i][$j]=~/^\d+$/)) {
	    #its not an int, so its a character (for now)
	    my $len = length($file_data[$i][$j]);
	    
	    if ($len > $char_lengths[$j]) {
	      $char_lengths[$j] = $len + 10;
	      $col_types[$j] = "char(".$char_lengths[$j].")";
	    }
	    
	  }

	  print OUT_DATA "$file_data[$i][$j]\t";
	}	

	print OUT_DATA "\n";
  }
}


make_data;   #this will both write out the data file and infer the  type of the column
make_dsc;
