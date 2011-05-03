#! /usr/bin/perl

#--------------------------------------------------------------------------------------------------------
# input: 
#    BAATT_mql - the mysql command
#    BAATT_num_groups - the number of groups of attributes we want to add
#    BAATT_group_target_table_i - the name of the destination table to update
#    BAATT_group_source_table_i - the name of the source table
#    BAATT_group_target_database_i - the name of the target database
#    BAATT_group_source_database_i - the name of the source database
#    BAATT_group_num_attributes_i - the number of attributes in the group
#    BAATT_group_attribute_i_j - the j-th attribute of the i-th group
#    BAATT_group_source_join_column_i - the name of the column in the source table on which to join
#    BAATT_group_target_join_column_i - the name of the column in the target table on which to join
#
# output:
#    the database will be updated: gene_table + selected_attributes ===> gene_table
#--------------------------------------------------------------------------------------------------------

use strict;

require "$ENV{MYPERLDIR}/lib/bio_load_settings.pl";
require "$ENV{MYPERLDIR}/lib/bio_execute.pl";

my %settings = load_settings($ARGV[0]);

my $mql = $settings{"BAATT_mql"};
my $num_groups = $settings{"BAATT_num_groups"};

my $r = int(rand 100000000);

my $verbose = 1;

my $i;

for ($i = 1; $i <= $num_groups; $i++)
{
  my $group_num_attributes_i = $settings{"BAATT_group_num_attributes_$i"};

  if ($group_num_attributes_i > 0)
  {
    my $group_target_table_i = $settings{"BAATT_group_target_table_$i"};
    my $group_source_table_i = $settings{"BAATT_group_source_table_$i"};
    my $group_target_database_i = $settings{"BAATT_group_target_database_$i"};
    my $group_source_database_i = $settings{"BAATT_group_source_database_$i"};
    my $group_source_join_column_i = $settings{"BAATT_group_source_join_column_$i"};
    my $group_target_join_column_i = $settings{"BAATT_group_target_join_column_$i"};

    open(SETTINGS, ">tmp.settings.$r");
    print SETTINGS "BSTTI_num_tables_to_copy=1\n";
    print SETTINGS "BSTTI_table_to_copy_1=$group_source_table_i\n";
    print SETTINGS "BSTTI_table_to_copy_target_name_1=${group_source_table_i}_$r\n";
    print SETTINGS "BSTTI_from_database=$group_source_database_i\n";
    print SETTINGS "BSTTI_to_database=$group_target_database_i\n";
    print SETTINGS "BSTTI_mql=$mql\n";
    print SETTINGS "BSTTI_action=load\n";
    execute("$ENV{HOME}/develop/perl/bio/bio_sql_table_to_install.pl tmp.settings.$r", $verbose);

    my $select_attr = "";
    for (my $j = 1; $j <= $group_num_attributes_i; $j++)
    {
      my $group_attribute_i_j = $settings{"BAATT_group_attribute_$i" . "_$j"};

      $select_attr .= ",attr.$group_attribute_i_j";
    }

    execute("$mql -e 'drop table if exists tmp_$r' $group_target_database_i", $verbose);

    my $exec_str = "$mql -e 'create table tmp_$r select $group_target_table_i.* $select_attr from $group_target_table_i,${group_source_table_i}_$r as attr where ";
    $exec_str .= "$group_target_table_i.$group_target_join_column_i=attr.$group_source_join_column_i' $group_target_database_i";
    execute($exec_str, $verbose);

    execute("$mql -e 'drop table if exists $group_target_table_i' $group_target_database_i", $verbose);

    execute("$mql -e 'create table $group_target_table_i select * from tmp_$r' $group_target_database_i", $verbose);

    execute("$mql -e 'drop table if exists tmp_$r' $group_target_database_i", $verbose);

    execute("$mql -e 'drop table if exists ${group_source_table_i}_$r' $group_target_database_i", $verbose);

    execute("rm tmp.settings.$r");
  }
}
