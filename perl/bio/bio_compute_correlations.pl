#! /usr/bin/perl

#-----------------------------------------------------------------------------------------------------------------------------------------
# PREFIX: BCC_
#
# input: 
#    BCC_mql - database access
#    BCC_keys_list - a list of keys that restricts both sources (e.g. a reduced gene list) or ALL for no restriction
#    BCC_output_correlation_file - the name of the correlation file to output
#    BCC_output_max_correlation_file - the name of the max correlation file to output
#    BCC_source_type1 - either "db" or "file" (if "db" then the names of the descriptions come from desc and if "file" then it's the first row
#    BCC_source_join1 - the name of the column on which the join is done
#    BCC_source_table_name1 - if source_type1 is "db" then this is the name of the table
#    BCC_source_database_name1 - if source_type1 is "db" then this is the name of the database
#    BCC_source_file_name1 - if source_type1 is "file" then this is the name of the file
#    BCC_source_type2 - either "db" or "file" (if "db" then the names of the descriptions come from desc and if "file" then it's the first row
#    BCC_source_join2 - the name of the column on which the join is done
#    BCC_source_table_name2 - if source_type1 is "db" then this is the name of the table
#    BCC_source_database_name2 - if source_type1 is "db" then this is the name of the database
#    BCC_source_file_name2 - if source_type1 is "file" then this is the name of the file
#
# output:
#    given two input sources, computes the correlations between each pair of columns in each of the sources
#-----------------------------------------------------------------------------------------------------------------------------------------

use strict;

require "$ENV{MYPERLDIR}/lib/bio_load_settings.pl";
require "$ENV{MYPERLDIR}/lib/bio_get_sql_table_dsc.pl";
require "$ENV{MYPERLDIR}/lib/bio_get_file_dsc.pl";
require "$ENV{MYPERLDIR}/lib/bio_load_sql_table_to_memory.pl";
require "$ENV{MYPERLDIR}/lib/bio_load_file_to_memory.pl";
require "$ENV{MYPERLDIR}/lib/bio_sort_vec.pl";

my %settings = load_settings($ARGV[0]);

my $mql = $settings{"BCC_mql"};
my $keys_list = $settings{"BCC_keys_list"};
my $output_correlation_file = $settings{"BCC_output_correlation_file"};
my $output_max_correlation_file = $settings{"BCC_output_max_correlation_file"};
my $source_type1 = $settings{"BCC_source_type1"};
my $source_join1 = $settings{"BCC_source_join1"};
my $source_table_name1 = $settings{"BCC_source_table_name1"};
my $source_database_name1 = $settings{"BCC_source_database_name1"};
my $source_file_name1 = $settings{"BCC_source_file_name1"};
my $source_type2 = $settings{"BCC_source_type2"};
my $source_join2 = $settings{"BCC_source_join2"};
my $source_table_name2 = $settings{"BCC_source_table_name2"};
my $source_database_name2 = $settings{"BCC_source_database_name2"};
my $source_file_name2 = $settings{"BCC_source_file_name2"};

open(OUT_CORRELATIONS, ">$output_correlation_file");
open(OUT_MAX_CORRELATIONS, ">$output_max_correlation_file");

#----------------------------------------------------------------
# calc_correlation
#----------------------------------------------------------------
sub calc_correlation (\@$\@$$)
{
  # N\sum(XY) - (sumX)(sumY) / sqrt((N \sum(X^2) - sum(X)^2) (N \sum(Y^2 - sum(X)^2)))

  my $sum_x = 0;
  my $sum_xx = 0;
  my $sum_y = 0;
  my $sum_yy = 0;
  my $sum_xy = 0;
  my $num = 0;

  my ($attr_values_1, $attr1_index, $attr_values_2, $attr2_index, $total_num_records) = @_;

  my $key;
  my $num = 0;

  my @a = @$attr_values_1;
  my @b = @$attr_values_2;

  my $i;
  for ($i = 0; $i < $total_num_records; $i++)
  {
	my $p1 = $a[$i][$attr1_index];
	my $p2 = $b[$i][$attr2_index];

	if (length($p1) > 0 && !($p1 =~ /[ \t\n\rA-Za-z]/) && length($p2) > 0 && !($p2 =~ /[ \t\n\rA-Za-z]/))
	{
	  #print "$key\t$p1\t$p2\tattr1_index=$attr1_index\tattr2_index=$attr2_index\n";

	  $sum_x += $p1;
	  $sum_xx += $p1 * $p1;
	  $sum_y += $p2;
	  $sum_yy += $p2 * $p2;
	  $sum_xy += $p1 * $p2;
	  $num++;
	}
  }

  my $correlation = 0;

  my $numerator = ($num * $sum_xy) - ($sum_x * $sum_y); 
  my $var_x = ($num * $sum_xx) - ($sum_x * $sum_x);
  my $var_y = ($num * $sum_yy) - ($sum_y * $sum_y);

  if ($var_x > 0 && $var_y > 0)
  {
	my $denominator = sqrt($var_x * $var_y);
	$correlation = $numerator / $denominator;
  }

  return $correlation;
}

my @attr_set_1;
my @attr_values_1;
my @attr_set_2;
my @attr_values_2;

my $verbose = 1;

#---------------------------------------
# LOAD ATTRIBUTES AND VALUES INTO MEMORY
#---------------------------------------
my %restricted_keys;
my @dummy;
if ($keys_list ne "ALL")
{
  @dummy = load_file_to_memory($keys_list, $verbose);
  my $i;
  for ($i = 0; $i < @dummy; $i++)
  {
	$restricted_keys{$dummy[$i][0]} = "1";
  }
}

if ($source_type1 eq "db")
{
  @attr_set_1 = get_sql_table_dsc($mql, $source_table_name1, $source_database_name1, $verbose);
  @attr_values_1 = load_sql_table_to_memory($mql, $source_table_name1, $source_database_name1, $verbose);
}
elsif ($source_type1 eq "file")
{
  @attr_set_1 = get_file_dsc($source_file_name1, $verbose);
  @attr_values_1 = load_file_to_memory($source_file_name1, $verbose);
}

if ($source_type2 eq "db")
{
  @attr_set_2 = get_sql_table_dsc($mql, $source_table_name2, $source_database_name2, $verbose);
  @attr_values_2 = load_sql_table_to_memory($mql, $source_table_name2, $source_database_name2, $verbose);
}
elsif ($source_type2 eq "file")
{
  @attr_set_2 = get_file_dsc($source_file_name2, $verbose);
  @attr_values_2 = load_file_to_memory($source_file_name2, $verbose);
}

#---------------------------------------------------------------------------------------
# CUT THE TABLES TO ROWS THAT THEY AGREE ON AND THAT THEY AFREE WITH THE RESTRICTED KEYS
#---------------------------------------------------------------------------------------
my $i;
my $j;

my $join_location_1;
for ($i = 0; $i < @attr_set_1; $i++) { if ($attr_set_1[$i] eq $source_join1) { $join_location_1 = $i; } }

my $join_location_2;
for ($i = 0; $i < @attr_set_2; $i++) { if ($attr_set_2[$i] eq $source_join2) { $join_location_2 = $i; } }

my %key_list_1;
for ($i = 0; $i < @attr_values_1; $i++) { $key_list_1{$attr_values_1[$i][$join_location_1]} = "1"; }

my %joined_keys;
my $total_common_records = 0;
for ($i = 0; $i < @attr_values_2; $i++)
{
  if ($key_list_1{$attr_values_2[$i][$join_location_2]} eq "1")
  {
	if ($keys_list eq "ALL" || $restricted_keys{$attr_values_2[$i][$join_location_2]} eq "1")
	{
	  $joined_keys{$attr_values_2[$i][$join_location_2]} = "1"; 
	  $total_common_records++;
	}
  } 
}
print "Total Common Records: $total_common_records\n";

my %joined_key_to_row_1;
for ($i = 0; $i < @attr_values_1; $i++)
{
  my $key = $attr_values_1[$i][$join_location_1];
  if ($joined_keys{$key} eq "1")
  {
	$joined_key_to_row_1{$key} = $i;
  }
}

my %joined_key_to_row_2;
for ($i = 0; $i < @attr_values_2; $i++)
{
  my $key = $attr_values_2[$i][$join_location_2];
  if ($joined_keys{$key} eq "1")
  {
	$joined_key_to_row_2{$key} = $i;
  }
}

#---------------------------------------------------------------------------------------
# GET THE SUM OF EACH ATTRIBUTE FROM EACH TABLE/FILE
#---------------------------------------------------------------------------------------
my @attr_counts_1;
for ($i = 0; $i < @attr_set_1; $i++)
{
  $attr_counts_1[$i] = 0;

  my $key;
  foreach $key (keys %joined_keys)
  {
	$attr_counts_1[$i] += $attr_values_1[$joined_key_to_row_1{$key}][$i];
  }
}

my @attr_counts_2;
for ($i = 0; $i < @attr_set_2; $i++)
{
  $attr_counts_2[$i] = 0;

  my $key;
  foreach $key (keys %joined_keys)
  {
	$attr_counts_2[$i] += $attr_values_2[$joined_key_to_row_2{$key}][$i];
  }
}

#---------------------------------------------------------------------------------------
# CREATE THE DATA MATRICES THAT WE'RE GOING TO USE - THIS IS AN OPTIMIZATION
#---------------------------------------------------------------------------------------
my @reduced_attr_values_1;
my @reduced_attr_set_1;
my @reduced_attr_counts_1;
my $i;
my $column = 0;
for ($i = 0; $i < @attr_set_1; $i++)
{
  if (length($attr_counts_1[$i]) > 0 && $attr_counts_1[$i] != 0)
  {
	$reduced_attr_set_1[$column] = $attr_set_1[$i];
	$reduced_attr_counts_1[$column] = $attr_counts_1[$i];

	#print "reduced_attr_set_1[$column]=$reduced_attr_set_1[$column] reduced_attr_counts_1[$column]=$reduced_attr_counts_1[$column]\n";

	my $row = 0;
	my $key;
	foreach $key (keys %joined_keys)
	{
	  $reduced_attr_values_1[$row][$column] = $attr_values_1[$joined_key_to_row_1{$key}][$i];
	  $row++;
	}

	$column++;
  }
}

my @reduced_attr_values_2;
my @reduced_attr_set_2;
my @reduced_attr_counts_2;
my $i;
my $column = 0;
for ($i = 0; $i < @attr_set_2; $i++)
{
  if ($attr_counts_2[$i] != 0)
  {
	$reduced_attr_set_2[$column] = $attr_set_2[$i];
	$reduced_attr_counts_2[$column] = $attr_counts_2[$i];

	#print "reduced_attr_set_2[$column]=$reduced_attr_set_2[$column] reduced_attr_counts_2[$column]=$reduced_attr_counts_2[$column]\n";

	my $row = 0;
	my $key;
	foreach $key (keys %joined_keys)
	{
	  $reduced_attr_values_2[$row][$column] = $attr_values_2[$joined_key_to_row_2{$key}][$i];
	  $row++;
	}

	$column++;
  }
}

#---------------------------------------------------------------------------------------
# COMPUTE THE CORRELATION BETWEEN EACH PAIR
#---------------------------------------------------------------------------------------
print OUT_CORRELATIONS "ATTRIBUTE\t";
my $j;
for ($j = 0; $j < @reduced_attr_set_2; $j++)
{
	print OUT_CORRELATIONS "$reduced_attr_set_2[$j]($reduced_attr_counts_2[$j])\t";
}
print OUT_CORRELATIONS "\n";

my @correlation_array;
my $num = @reduced_attr_set_1;
for ($i = 0; $i < @reduced_attr_set_1; $i++)
{
  print "Correlating $reduced_attr_set_1[$i]($reduced_attr_counts_1[$i]) --- $i out of $num\n";
  print OUT_CORRELATIONS "$reduced_attr_set_1[$i]($reduced_attr_counts_1[$i])\t";
  
  for ($j = 0; $j < @reduced_attr_set_2; $j++)
  {
	#print "reduced_attr_set_1[$i]=$reduced_attr_set_1[$i] AND reduced_attr_set_2[$j]=$reduced_attr_set_2[$j]\n";
	
	my $correlation = calc_correlation(@reduced_attr_values_1, $i, @reduced_attr_values_2, $j, $total_common_records);
	
	my $absolute_correlation;
	if ($correlation >= 0) { $absolute_correlation = $correlation; } else { $absolute_correlation = - $correlation; }
	
	print OUT_CORRELATIONS "$correlation\t";
	
	$correlation_array[$i][$j][0] = $absolute_correlation;
	$correlation_array[$i][$j][1] = $correlation;
	$correlation_array[$i][$j][2] = $reduced_attr_set_1[$i];
	$correlation_array[$i][$j][3] = $reduced_attr_set_2[$j];
	$correlation_array[$i][$j][4] = $reduced_attr_counts_1[$i];
	$correlation_array[$i][$j][5] = $reduced_attr_counts_2[$j];
	#print "$absolute_correlation\t$correlation\t$reduced_attr_set_1[$i]\t$reduced_attr_counts_1[$i]\t$reduced_attr_set_2[$j]\t$reduced_attr_counts_2[$j]\n";
  }
  
  print OUT_CORRELATIONS "\n";
}

#---------------------------------------------------------------------------------------
# COMPUTE THE MAX CORRELATIONS FOR EACH OF OUR ATTRIBUTE SETS
#---------------------------------------------------------------------------------------
sub extract_max_correlations
{
  my $master_attribute_set = $_[0];

  my @aset1;
  my @aset2;

  if ($master_attribute_set eq "1")
  {
	@aset1 = @reduced_attr_set_1;
	@aset2 = @reduced_attr_set_2;
  }
  elsif ($master_attribute_set eq "2")
  {
	@aset1 = @reduced_attr_set_2;
	@aset2 = @reduced_attr_set_1;
  }

  my @max_correlation_vec;
  
  my $i;
  my $j;
  my $max_counter = 0;
  for ($i = 0; $i < @aset1; $i++)
  {
	$max_correlation_vec[$max_counter][0] = -1000000;
	
	for ($j = 0; $j < @aset2; $j++)
	{
	  my $idx1;
	  my $idx2;
	  
	  if ($master_attribute_set eq "1")
	  {
		$idx1 = $i;
		$idx2 = $j;
	  }
	  elsif ($master_attribute_set eq "2")
	  {
		$idx1 = $j;
		$idx2 = $i;
	  }
	  
	  if ($correlation_array[$idx1][$idx2][0] > $max_correlation_vec[$max_counter][0])
	  {
		$max_correlation_vec[$max_counter][0] = $correlation_array[$idx1][$idx2][0];
		$max_correlation_vec[$max_counter][1] = $correlation_array[$idx1][$idx2][1];
		$max_correlation_vec[$max_counter][2] = $correlation_array[$idx1][$idx2][2];
		$max_correlation_vec[$max_counter][3] = $correlation_array[$idx1][$idx2][3];
		$max_correlation_vec[$max_counter][4] = $correlation_array[$idx1][$idx2][4];
		$max_correlation_vec[$max_counter][5] = $correlation_array[$idx1][$idx2][5];
	  }
	}
  
	$max_counter++;
  }

  @max_correlation_vec = sort_vec(\@max_correlation_vec, 6, 0, "numeric_reverse");
	
  for ($i = 0; $i < @max_correlation_vec; $i++)
  {
	if ($master_attribute_set eq "1")
	{
	  print OUT_MAX_CORRELATIONS "$max_correlation_vec[$i][2]($max_correlation_vec[$i][4])\t$max_correlation_vec[$i][1]\t$max_correlation_vec[$i][3]($max_correlation_vec[$i][5])\n";
	}
	elsif ($master_attribute_set eq "2")
	{
	  print OUT_MAX_CORRELATIONS "$max_correlation_vec[$i][3]($max_correlation_vec[$i][5])\t$max_correlation_vec[$i][1]\t$max_correlation_vec[$i][2]($max_correlation_vec[$i][4])\n";
	}
  }
  print OUT_MAX_CORRELATIONS "\n";

  if ($master_attribute_set eq "1")
  {
	if ($source_type1 eq "db")
	{
	  print OUT_MAX_CORRELATIONS "attribute_groups=1\n";
	  my $num = @reduced_attr_set_1;
	  print OUT_MAX_CORRELATIONS "attribute_group_num_1=$num\n";
	  print OUT_MAX_CORRELATIONS "attribute_group_source_database_1=$source_database_name1\n";
	  print OUT_MAX_CORRELATIONS "attribute_group_source_table_1=$source_table_name1\n";
	  print OUT_MAX_CORRELATIONS "attribute_group_target_table_1=\n";
	  print OUT_MAX_CORRELATIONS "attribute_group_type_1=int\n";
	  print OUT_MAX_CORRELATIONS "attribute_group_type_dsc_1=0,1\n";
	  print OUT_MAX_CORRELATIONS "attribute_group_source_join_column_1=gene_name\n";
	  print OUT_MAX_CORRELATIONS "attribute_group_target_join_column_1=gene_name\n";
	  print OUT_MAX_CORRELATIONS "attribute_group_hide_attributes_1=true\n";
	  for ($i = 0; $i < @max_correlation_vec; $i++)
	  {
		print OUT_MAX_CORRELATIONS "attribute_group_1_" . ($i + 1) . "=$max_correlation_vec[$i][2]\n";
	  }
	}
	print OUT_MAX_CORRELATIONS "\n";
  }
  elsif ($master_attribute_set eq "2")
  {
	if ($source_type2 eq "db")
	{
	  print OUT_MAX_CORRELATIONS "attribute_groups=1\n";
	  my $num = @reduced_attr_set_2;
	  print OUT_MAX_CORRELATIONS "attribute_group_num_1=$num\n";
	  print OUT_MAX_CORRELATIONS "attribute_group_source_database_1=$source_database_name2\n";
	  print OUT_MAX_CORRELATIONS "attribute_group_source_table_1=$source_table_name2\n";
	  print OUT_MAX_CORRELATIONS "attribute_group_target_table_1=\n";
	  print OUT_MAX_CORRELATIONS "attribute_group_type_1=int\n";
	  print OUT_MAX_CORRELATIONS "attribute_group_type_dsc_1=0,1\n";
	  print OUT_MAX_CORRELATIONS "attribute_group_source_join_column_1=gene_name\n";
	  print OUT_MAX_CORRELATIONS "attribute_group_target_join_column_1=gene_name\n";
	  print OUT_MAX_CORRELATIONS "attribute_group_hide_attributes_1=true\n";
	  for ($i = 0; $i < @max_correlation_vec; $i++)
	  {
		print OUT_MAX_CORRELATIONS "attribute_group_1_" . ($i + 1) . "=$max_correlation_vec[$i][3]\n";
	  }
	}
	print OUT_MAX_CORRELATIONS "\n";
  }
}

extract_max_correlations("1");
extract_max_correlations("2");
