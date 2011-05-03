#! /usr/bin/perl

#-----------------------------------------------------------------------------------------------------------
# input: 
#    BCAC_mql = the mysql client
#    BCAC_database = the database to use
#    BCAC_prefix = the prefix of all file
#    BCAC_dir = the current working directory
#    BCAC_num_tables = the number of tables for which to compute changes
#    BCAC_table_i = the name of the i-th table
# output:
#    
#-----------------------------------------------------------------------------------------------------------

use strict;

require "$ENV{MYPERLDIR}/lib/bio_load_settings.pl";
require "$ENV{MYPERLDIR}/lib/bio_execute.pl";
require "$ENV{MYPERLDIR}/lib/bio_get_sql_table_dsc.pl";

my %settings = load_settings($ARGV[0]);

my $mql = $settings{"BCAC_mql"};
my $database = $settings{"BCAC_database"};
my $prefix = $settings{"BCAC_prefix"};
my $dir = $settings{"BCAC_dir"};
my $num_tables = $settings{"BCAC_num_tables"};

my $iteration;
if (length($ARGV[1]) > 0) { $iteration = $ARGV[1]; }
else { $iteration = $settings{"BCAC_iteration"}; }

my $next_iteration = $iteration + 1;

my $verbose = 0;

my $outfile = "$dir/out/${prefix}_$iteration.stats";

execute("echo \"\" > $outfile");

sub compute_change
{
  my $iteration_1 = $_[0];
  my $iteration_2 = $_[1];
  my $attribute = $_[2];
  my $table = $_[3];

  my $attr1 = "${attribute}_i$iteration_1";
  my $attr2 = "${attribute}_i$iteration_2";

  execute("$mql -e 'select $attr1,$attr2,count(*) from $table group by $attr1,$attr2' $database >> $outfile", $verbose);
}

my $i;
for ($i = 1; $i <= $num_tables; $i++)
{
  my $table_name = $settings{"BCAC_table_$i"};

  execute("echo \"TABLE $table_name\" >> $outfile");
  execute("echo \"--------------------------\" >> $outfile");

  my @table_columns = get_sql_table_dsc($mql, $table_name, $database);

  my @attributes;
  my $attribute_counter = 0;
  my $j;
  for ($j = 0; $j < @table_columns; $j++)
  {
	if ($table_columns[$j] =~ /(.*)_i0/)
	{
	  $attributes[$attribute_counter] = $1;
	  $attribute_counter++;
	}
  }

  for ($j = 0; $j < $attribute_counter; $j++)
  {
	compute_change(0, $next_iteration, $attributes[$j], $table_name);
  }

  execute("echo \"DETAILED $table_name\" >> $outfile");
  execute("echo \"--------------------------\" >> $outfile");

  for ($j = 0; $j < $attribute_counter; $j++)
  {
	my $z;
	for ($z = 1; $z <= $next_iteration; $z++)
	{
	  compute_change(0, $z, $attributes[$j], $table_name);
	}

	for ($z = 0; $z <= $next_iteration - 1; $z++)
	{
	  compute_change($z, $z + 1, $attributes[$j], $table_name);
	}
  }
}
