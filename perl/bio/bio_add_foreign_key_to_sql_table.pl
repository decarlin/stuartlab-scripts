#! /usr/bin/perl

#-----------------------------------------------------------------------------------------------------------
# input: 
#    update_table = the table to which the foreign key column is added
#    foreign_table = the table to which the foreign key column is added
#    foreign_key_column = the column of the foreign key that is added
#    update_column = the name of the column that will be added to the update table
#    update_column_type = the type of the column that will be added to the update table
#    where_column = the where columns that will be used to join the updated table and the foreign_table
#    database = the database to use
#    mql = the mysql command
# output:
#    adds a column called foreign_key_column to the update_table after doing a join on the where_column
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
$update_table = $settings{"update_table"};
$foreign_table = $settings{"foreign_table"};
$foreign_key_column = $settings{"foreign_key_column"};
$update_column = $settings{"update_column"};
$update_column_type = $settings{"update_column_type"};
$where_column = $settings{"where_column"};
$database = $settings{"database"};
$mql = $settings{"mql"};

$exec = "$mql -e 'alter table $update_table add column $update_column $update_column_type' $database";
print $exec . "\n";
system($exec);

$exec = "$mql -Ne 'select $update_table.$where_column,$foreign_key_column from $update_table,$foreign_table where $update_table.$where_column=$foreign_table.$where_column' $database > $settings_file.tmp";
print $exec . "\n";
system($exec);

$exec = "$ENV{MYPERLDIR}/lib/bio_update_column.pl $settings_file";
system($exec);

$exec = "$mql -e 'alter table $update_table add key($update_column)' $database";
print $exec . "\n";
system($exec);

#system("rm x");
