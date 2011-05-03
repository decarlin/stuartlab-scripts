#! /usr/bin/perl

#-----------------------------------------------------------------------------------------------------------
# input: 
#    clusters_file - a cluster file in the format GENE_NAME\tGENE_CLUSTER\n
#    regulated_file - the output file for genes
#    sql_file - the output file for the genes sql file
#    gene_table - the name of the gene table to create
#    dir - the directory that the sql file will point to /fiery/u2/erans/D/Biology/RECOMB02/Promoters/D/
# output:
#    sets the database in mysql with the additional column and then calls bio_update_column.pl to load data
#-----------------------------------------------------------------------------------------------------------

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
$clusters_file = $settings{"clusters_file"};
$regulated_file = $settings{"regulated_file"};
$sql_file = $settings{"sql_file"};
$gene_table = $settings{"gene_table"};
$dir = $settings{"dir"};

open(CLUSTER_FILE, "<$clusters_file");
open(REGULATED_FILE, ">$regulated_file");
open(SQL_FILE, ">$sql_file");

$max_cluster = 0;
$gene_id = 0;
while (<CLUSTER_FILE>)
{
  chop;

  ($gene_name, $gene_cluster) = split(/\t/);

  $gene_name_to_cluster{$gene_name} = $gene_cluster;
  $gene_names[$gene_id] = $gene_name;

  if ($gene_cluster > $max_cluster)
  {
	$max_cluster = $gene_cluster;
  }

  $gene_id++;
}

for ($j = 0; $j < $gene_id; $j++)
{
  $gene_name = $gene_names[$j];

  print REGULATED_FILE "$j\t$gene_name";

  for ($i = 1; $i <= $max_cluster; $i++)
  {
	if ($gene_name_to_cluster{$gene_name} eq $i)
	{
	  print REGULATED_FILE "\t1";
	}
	else
	{
	  print REGULATED_FILE "\t0";
	}
  }
  print REGULATED_FILE "\n";
}

print SQL_FILE "drop table if exists $gene_table;\n";
print SQL_FILE "create table $gene_table(\n";
print SQL_FILE "   gene_id int primary key,\n";
print SQL_FILE "   gene_name char(20)";
for ($i = 1; $i <= $max_cluster; $i++)
{
  print SQL_FILE ",\n";
  print SQL_FILE "   regulated_by_tf$i int";
}
print SQL_FILE "\n);\n";
print SQL_FILE "load data local infile \"$dir/$regulated_file\" into table $gene_table;\n";
