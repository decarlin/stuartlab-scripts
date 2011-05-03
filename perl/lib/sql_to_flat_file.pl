#! /usr/bin/perl

use strict;

require "$ENV{MYPERLDIR}/lib/load_args.pl";
require "$ENV{MYPERLDIR}/lib/bio_load_file_to_memory.pl";
require "$ENV{MYPERLDIR}/lib/bio_system.pl";
require "$ENV{MYPERLDIR}/lib/bio_get_file_dsc.pl";

my $stff_null_value = "STFF___NULL___STFF";

my $mql = "/usr/bin/mysql";

my $r = int(rand 100000000);

my $verbose = 1;

sub sql_to_flat_file
{
  my ($database, $table, $target_table, $target_file, $keys_file, $add_missing_keys) = @_;

  open(SETTINGS, ">tmp.settings.$r");
  print SETTINGS "BSTTI_num_tables_to_copy=1\n";
  print SETTINGS "BSTTI_table_to_copy_1=$table\n";
  print SETTINGS "BSTTI_table_to_copy_target_name_1=$target_table\n";
  print SETTINGS "BSTTI_from_database=$database\n";
  print SETTINGS "BSTTI_to_database=\n";
  print SETTINGS "BSTTI_mql=$mql\n";
  print SETTINGS "BSTTI_action=file\n";
  print SETTINGS "BSTTI_output_prefix=$target_file\n";
  execute("$ENV{HOME}/develop/perl/bio_sql_table_to_install.pl tmp.settings.$r", $verbose);
  delete_file("tmp.settings.$r");

  if ($keys_file ne $stff_null_value)
  {
    execute("$ENV{HOME}/develop/perl/lib/select_from_file.pl ARGS_SFF $target_file.dat -f $keys_file > tmp.$r", $verbose);

    if ($add_missing_keys)
    {
      execute("$ENV{HOME}/develop/perl/lib/select_from_file.pl ARGS_SFF tmp.$r -f $keys_file -pni -pds > tmp2.$r", $verbose);
      my $num_columns = get_num_columns_in_file("tmp.$r");
      open(OUT_DATA_FILE, ">>tmp.$r");
      open(ADD_THESE_KEYS, "<tmp2.$r");
      while(<ADD_THESE_KEYS>)
      {
	chop;
	print OUT_DATA_FILE "$_";
	for (my $i = 0; $i < $num_columns - 1; $i++) { print OUT_DATA_FILE "\t0"; }
	print OUT_DATA_FILE "\n";
      }
      delete_file("tmp2.$r");
      move_file("tmp.$r", "$target_file.dat");
    }
  }
}

#--------------------------------------------------------------------------------
# STDIN
#--------------------------------------------------------------------------------
if (length($ARGV[0]) > 0)
{
  my %args = load_args(\@ARGV);

  sql_to_flat_file($ARGV[0],
		   $ARGV[1],
		   get_arg("t",   $ARGV[1],         \%args),
		   get_arg("o",   $ARGV[1],         \%args),
		   get_arg("f",   $stff_null_value, \%args),
		   get_arg("m",   0,                \%args));
}
else
{
  print "Usage: sql_to_flat_file.pl database table\n";
  print "      -t <table name>:   target table (default is the same table name as the input)\n";
  print "      -o <file prefix>:  prefix for the sql and data files that will be created (default is the table name)\n\n";
  print "      -f <file name>:    a file containing keys to select (default select all)\n";
  print "      -m:                missing keys are added at the end of the flat file with zeros in all fields\n";
}

1
