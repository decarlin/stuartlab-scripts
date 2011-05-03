#!/usr/bin/perl

require "$ENV{MYPERLDIR}/lib/load_args.pl";
require "$ENV{MYPERLDIR}/lib/bio_execute.pl";

my $s_null_value = "S___NULL___S";
my $mql = "/usr/bin/mysql";

#--------------------------------------------------------------------------------
# 
#--------------------------------------------------------------------------------
sub sql_exec
{
  my ($database,
      $table,
      $remove_tables_file,
      $count,
      $describe) = @_;

  if ($remove_tables_file ne $s_null_value)
  {
    open(REMOVE_FILES, "<$remove_tables_file") or die "Could not find the tables to remove file\n";
    while(<REMOVE_FILES>)
    {
      chop;
      print "$mql -e 'drop table if exists $_' $database\n";
      execute("$mql -e 'drop table if exists $_' $database");
    }
  }

  if ($count) { execute("$mql -e 'select count(*) from $table' $database"); }

  if ($describe) { execute("$mql -e 'desc $table' $database"); }
}

#--------------------------------------------------------------------------------
# STDIN
#--------------------------------------------------------------------------------
if (length($ARGV[1]) > 0)
{
  my %args = load_args(\@ARGV);

  sql_exec(get_arg("d",   $s_null_value, \%args),
	   get_arg("t",   $s_null_value, \%args),
	   get_arg("r",   $s_null_value, \%args),
 	   get_arg("c",   0,             \%args),
 	   get_arg("dsc", 0,             \%args));
}
else
{
  print "Usage: sql.pl\n";
  print "      -d <database>:   database name to work on\n";
  print "      -t <table_name>: table name to work on\n";
  print "      -r <table_file>: remove all the tables that exist in this file\n";
  print "      -c:              count the records for the specified table\n";
  print "      -dsc:            describe the specified table\n";
}

1
