#! /usr/bin/perl

#-------------------------------------------------------------------------------------------------------------------
# input: 
#    BSTTI_num_tables_to_copy - the number of tables we want to copy information from
#    BSTTI_table_to_copy_<num> - the name of num-th table to copy
#    BSTTI_table_to_copy_target_name_<num> - the name of the num-th table as we want it given in the target database
#    BSTTI_from_database = the name of the database from which we're copying
#    BSTTI_to_database = the name of the database to which we're copying
#    BSTTI_mql = the mysql command
#    BSTTI_action = if "file" then creates a "load.sh". if "load" then loads the table to the new database
#    BSTTI_output_prefix = the prefix for the output tables to be created -- relevant only if the action is file
# output:
#    creates sql files and data files from the current database
#-------------------------------------------------------------------------------------------------------------------

use strict;

require "$ENV{MYPERLDIR}/lib/bio_load_settings.pl";
require "$ENV{MYPERLDIR}/lib/bio_execute.pl";

my %settings = load_settings($ARGV[0]);

my $num_tables_to_copy = $settings{"BSTTI_num_tables_to_copy"};
my $from_database = $settings{"BSTTI_from_database"};
my $to_database = $settings{"BSTTI_to_database"};
my $mql = $settings{"BSTTI_mql"};
my $action = $settings{"BSTTI_action"};
my $output_prefix = $settings{"BSTTI_output_prefix"};

my $verbose = 1;

if ($action eq "file")
{
  #my $main_file = "load.sh";
  #open(OUT_LELAND_MAIN, ">$main_file") or die "could not open $main_file";
  #print OUT_LELAND_MAIN "#! /bin/tcsh -f\n";
  #print OUT_LELAND_MAIN "alias mql $mql\n\n";
}

my $r = int(rand 1000000000);

for (my $i = 0; $i < $num_tables_to_copy; $i++)
{
  my $attr = "table_to_copy_" . ($i + 1);
  my $table_to_copy = $settings{"BSTTI_$attr"};

  my $target_attr = "table_to_copy_target_name_" . ($i + 1);
  my $target_table_to_copy = $settings{"BSTTI_$target_attr"};

  execute("$mql -Ne 'desc $table_to_copy' $from_database > table_dsc.$r", $verbose);

  open(TABLE_DESC, "<table_dsc.$r") or die "could not open table_dsc.$r";

  my $output_table_sql = length($output_prefix) > 0 ? "$output_prefix.sql" : "$target_table_to_copy.$r.sql";
  my $output_table_data = length($output_prefix) > 0 ? "$output_prefix.dat" : "$target_table_to_copy.$r.dat";
  open(OUT_SQL, ">$output_table_sql");

  print OUT_SQL "drop table if exists $target_table_to_copy;\n";
  print OUT_SQL "create table $target_table_to_copy (\n";

  my $first = 1;
  while (<TABLE_DESC>)
  {
    chop;

    my $field;
    my $type;
    my $remainder;
	
    ($field, $type, $remainder) = split(/\t/, $_, 3);

    if ($first == 1) { $first = 0; }
    else { print OUT_SQL ",\n"; }
	
    print OUT_SQL $field . " " . $type;
  }

  print OUT_SQL "\n);\n\n";
  print OUT_SQL "load data local infile \"" . $output_table_data . "\" into table $target_table_to_copy; \n";

  execute("$mql -Ne 'select * from $table_to_copy' $from_database > " . $output_table_data . "1", $verbose);

  execute("sed -e 's/NULL/\\\\N/g' " . $output_table_data . "1 > " . $output_table_data, $verbose);

  execute("rm " . $output_table_data . "1", $verbose);

  if ($action eq "file")
  {
    #print OUT_LELAND_MAIN "echo \"loading $target_table_to_copy\"\n";
    #print OUT_LELAND_MAIN "mql $to_database < $output_table_sql\n\n";
  }
  elsif ($action eq "load")
  {
    execute("$mql $to_database < $output_table_sql", $verbose);

    execute("rm $output_table_sql");
    execute("rm $output_table_data");
  }

  execute("rm table_dsc.$r");
}
