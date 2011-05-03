#! /usr/bin/perl

#-----------------------------------------------------------------------------------------------------------
# input: 
#    update_table = the table to which the column is added
#    update_column = the column that update
#    update_column_file = the file tha contains the information for the update
#    where_column = the where columns that will be used as the key in the table to which the column is added
#    database = the database to use
#    mql = the mysql command
# output:
#    updates the column in the database with the information in the update_column_file
#-----------------------------------------------------------------------------------------------------------

require "$ENV{MYPERLDIR}/lib/bio_load_settings.pl";

my %settings = load_settings($ARGV[0]);

my $table = $settings{"BUC_update_table"};
my $update_column = $settings{"BUC_update_column"};
my $where_column = $settings{"BUC_where_column"};
my $database = $settings{"BUC_database"};
my $mql = $settings{"BUC_mql"}; 
my $update_column_file = $settings{"BUC_update_column_file"};

open(GENES_LIST, "<$update_column_file") or die "could not open $update_column_file";

while (<GENES_LIST>)
{
  chop;

  my @row = split(/\t/);

  $where_value = $row[0];
  $update_value = $row[1];

  #print $where_value . "\t" . $update_value . "\n";

  $exec = "$mql -e 'update $table set $update_column=$update_value where $where_column=\"$where_value\"' $database";
#    print $exec . "\n";
  system($exec);
}

1
