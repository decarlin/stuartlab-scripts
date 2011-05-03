#! /usr/bin/perl

#-----------------------------------------------------------------------------------------------------------
# input: 
#    BAC_update_table = the table to which the column is added
#    BAC_update_column = the column that we add and update
#    BAC_update_column_file = the file that stores the information with which the column will be updated
#    BAC_column_type = we need the type of the column to write the add column command in mysql
#    BAC_where_column = the where columns that will be used as the key in the table to which the column is added
#    BAC_database = the database to use
#    BAC_mql = the mysql command
#    BAC_add_key = adds a key to the added column if this attribute is 1
# output:
#    sets the database in mysql with the additional column and then calls bio_update_column.pl to load data
#-----------------------------------------------------------------------------------------------------------

use strict;

require "$ENV{MYPERLDIR}/lib/bio_load_settings.pl";
require "$ENV{MYPERLDIR}/lib/bio_execute.pl";

my %settings = load_settings($ARGV[0]);

my $table = $settings{"BAC_update_table"};
my $update_column = $settings{"BAC_update_column"};
my $update_column_file = $settings{"BAC_update_column_file"};
my $column_type = $settings{"BAC_column_type"};
my $where_column = $settings{"BAC_where_column"};
my $database = $settings{"BAC_database"};
my $mql = $settings{"BAC_mql"}; 
my $add_key = $settings{"BAC_add_key"};

my $exec = "$mql -e 'alter table $table add column $update_column $column_type' $database";
system($exec);

if ($add_key)
{
  $exec = "$mql -e 'alter table $table add key($update_column)' $database";
  system($exec);
}

my $r = int(rand 1000000000);
open(SETTINGS, ">tmp.settings.$r");
print SETTINGS "BUC_update_table=$table\n";
print SETTINGS "BUC_update_column=$update_column\n";
print SETTINGS "BUC_update_column_file=$update_column_file\n";
print SETTINGS "BUC_where_column=$where_column\n";
print SETTINGS "BUC_database=$database\n";
print SETTINGS "BUC_mql=$mql\n"; 

$exec = "$ENV{MYPERLDIR}/lib/bio_update_column.pl tmp.settings.$r";
system($exec);

execute("rm tmp.settings.$r");

1
