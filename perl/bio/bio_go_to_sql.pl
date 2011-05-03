#! /usr/bin/perl

#--------------------------------------------------------------------------------------------------------
# input: 
#    go_file - the name of the go input file
#    sql_file - name of the data for the sql file
#    sql_dsc_file - name of the sql dsc file to make
#    output_db_table - name of the db table that will store the annotations
#    database - the name of the database 
#    sql_file_location - the location of the sql file produced
#    attribute_threshold - look only at attributes that appear in at least this much PERCENT of the genes
# output:
#    sql format of the file
#--------------------------------------------------------------------------------------------------------

#----------------------------------------------------------------
# load the settings
#----------------------------------------------------------------
if (length($ARGV[0]) == 0) { $settings_file = "settings"; } else { $settings_file = $ARGV[0]; }

open(SETTINGS, "<$settings_file") or die "could not open SETTINGS";
while (<SETTINGS>)
{
	chop;
   ($id, $value) = split(/=/, $_, 2);

	$settings{$id} = $value;
}

#----------------------------------------------------------------
# parameters
#----------------------------------------------------------------
$go_file = $settings{"go_file"};
$sql_file = $settings{"sql_file"};
$sql_dsc_file = $settings{"sql_dsc_file"};
$output_db_table = $settings{"output_db_table"};
$database = $settings{"database"};
$sql_file_location = $settings{"sql_file_location"};
$attribute_threshold = $settings{"attribute_threshold"};

open(GO_FILE, "<$go_file") or die "could not open $go_file\n";
open(SQL_FILE, ">$sql_file");
open(SQL_DSC_FILE, ">$sql_dsc_file");

#----------------------------------------------------------------
# main
#----------------------------------------------------------------
$attribute_counter = 0;
$gene_name_counter = 0;
while(<GO_FILE>)
{
  chop;

  ($gene_name, $gene_attr) = split(/\t/);
  $gene_attr =~ s/[\s]/_/g;
  $gene_attr =~ s/[-]/_/g;

  if ($gene_attributes_exists{$gene_attr} ne "1")
  {
	$gene_attributes_exists{$gene_attr} = "1";
	$gene_attributes_to_id{$gene_attr} = $attribute_counter;
	$gene_attributes_names[$attribute_counter] = $gene_attr;
	$gene_attributes_counts[$attribute_counter] = 1;
	$attribute_counter++;
  }
  else
  {
	$attr_id = $gene_attributes_to_id{$gene_attr};
	$gene_attributes_counts[$attr_id]++;
  }
  
  if ($gene_names_exists{$gene_name} ne "1")
  {
	$gene_names_exists{$gene_name} = "1";
	$gene_names_to_id{$gene_name} = $gene_name_counter;
	$gene_names[$gene_name_counter] = $gene_name;
	$gene_name_counter++;
  }
}

$min = int($gene_name_counter * $attribute_threshold / 100);
for ($j = 0; $j < $attribute_counter; $j++)
{
  if ($gene_attributes_counts[$j] >= $min)
  {
	$ignore_attribute[$j] = 0;
  }
  else
  {
	$ignore_attribute[$j] = 1;
  }
  #print "$gene_attributes_counts[$j]\t$gene_attributes_names[$j]\n";
}

for ($i = 0; $i < $gene_name_counter; $i++)
{
  for ($j = 0; $j < $attribute_counter; $j++)
  {
	if ($ignore_attribute[$j] == 0)
	{
	  $gene_attribute_values[$i][$j] = 0;
	}
  }
}

open(GO_FILE, "<$go_file") or die "could not open $go_file\n";
while(<GO_FILE>)
{
  chop;

  ($gene_name, $gene_attr) = split(/\t/);
  $gene_attr =~ s/[\s]/_/g;
  $gene_attr =~ s/[-]/_/g;

  $attr_id = $gene_attributes_to_id{$gene_attr};
  $gene_id = $gene_names_to_id{$gene_name};

  if ($ignore_attribute[$attr_id] == 0)
  {
	$gene_attribute_values[$gene_id][$attr_id] = 1;
  }
}

print SQL_FILE "gen_id\t";
print SQL_FILE "genbank_id\t";
for ($i = 0; $i < $attribute_counter; $i++)
{
  if ($ignore_attribute[$i] == 0)
  {
	print SQL_FILE "$gene_attributes_names[$i]\t";
  }
}
print SQL_FILE ");\n";

for ($i = 0; $i < $gene_name_counter; $i++)
{
  print SQL_FILE "$i\t$gene_names[$i]\t";
  for ($j = 0; $j < $attribute_counter; $j++)
  {
	if ($ignore_attribute[$j] == 0)
	{
	  print SQL_FILE "$gene_attribute_values[$i][$j]\t";
	}
  }
  print SQL_FILE "\n";
}

print SQL_DSC_FILE "drop table if exists $output_db_table;\n";
print SQL_DSC_FILE "create table $output_db_table(\n";
print SQL_DSC_FILE "gene_id int primary key,\n";
print SQL_DSC_FILE "gene_name char(50)";
for ($i = 0; $i < $attribute_counter; $i++)
{
  if ($ignore_attribute[$i] == 0)
  {
	print SQL_DSC_FILE ",\n$gene_attributes_names[$i] int";
  }
}
print SQL_DSC_FILE ");\n";
print SQL_DSC_FILE "load data local infile \"$sql_file_location/$sql_file\" into table $output_db_table;\n";
