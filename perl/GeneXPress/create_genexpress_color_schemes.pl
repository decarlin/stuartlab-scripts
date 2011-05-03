#! /usr/bin/perl

use strict;

require "$ENV{MYPERLDIR}/lib/bio_execute.pl";
require "$ENV{MYPERLDIR}/lib/load_args.pl";

my $cgcs_null_value = "CGCS___NULL___CGCS";
my $mql = "/u/erans/mysql/mysql-3.23.41-pc-linux-gnu-i686/bin/mysql";

my $r = int(rand(10000000));

#--------------------------------------------------------------------------------
#
#--------------------------------------------------------------------------------
sub get_keys
{
  my ($sql_query) = @_;

  my @res;
  my $counter = 0;

  execute("$sql_query > tmp.$r");
  open(TMP, "<tmp.$r");
  while(<TMP>)
  {
    chop;

    $res[$counter++] = $_;
  }

  system("rm tmp.$r");

  return @res;
}

#--------------------------------------------------------------------------------
#
#--------------------------------------------------------------------------------
sub create_genexpress_color_scheme
{
  my ($database, $table, $key_column, $column, $value, $print_header, $true_color, $false_color, $objects_type, $name) = @_;

  my $positive_sql_selection = "$mql -Ne 'select $key_column from $table where $column=\"$value\"' $database";
  #print $positive_sql_selection . "\n";

  my @positive_keys = get_keys($positive_sql_selection);
  my $positive_keys_str = "";
  for (my $i = 0; $i < @positive_keys; $i++)
  {
    if ($i > 0) { $positive_keys_str .= ";"; }
    $positive_keys_str .= $positive_keys[$i];
  }

  my $negative_sql_selection = "$mql -Ne 'select $key_column from $table where $column!=\"$value\"' $database";
  #print $negative_sql_selection . "\n";

  my @negative_keys = get_keys($negative_sql_selection);
  my $negative_keys_str = "";
  for (my $i = 0; $i < @negative_keys; $i++)
  {
    if ($i > 0) { $negative_keys_str .= ";"; }
    $negative_keys_str .= $negative_keys[$i];
  }

  if ($print_header == 1) { print "<GeneXPressColorSchemes>\n"; }
  print "  <ColorScheme Name=\"$name\" ObjectsType=\"$objects_type\">\n";

  print "    <ColorAssignment Color=\"$false_color\" Objects=\"$negative_keys_str\">\n";
  print "    </ColorAssignment>\n";

  print "    <ColorAssignment Color=\"$true_color\" Objects=\"$positive_keys_str\">\n";
  print "    </ColorAssignment>\n";

  print "  </ColorScheme>\n";
  if ($print_header == 1) { print "</GeneXPressColorSchemes>\n"; }
}

#--------------------------------------------------------------------------------
# STDIN
#--------------------------------------------------------------------------------
if (length($ARGV[0]) > 0)
{
  my %args = load_args(\@ARGV);

  create_genexpress_color_scheme(get_arg("d", $cgcs_null_value, \%args),
				 get_arg("t", $cgcs_null_value, \%args),
				 get_arg("k", $cgcs_null_value, \%args),
				 get_arg("c", $cgcs_null_value, \%args),
				 get_arg("v", $cgcs_null_value, \%args),
				 get_arg("h", 0, \%args),
				 get_arg("tc", "0,0,255,1", \%args),
				 get_arg("fc", "255,255,0,1", \%args),
				 get_arg("ot", "Experiments", \%args),
				 get_arg("n",  $cgcs_null_value, \%args));
}
else
{
  print "Usage: create_genexpress_color_schemes.pl \n\n";
  print "      -d  <database>:      The database to use\n";
  print "      -t  <table>:         The name of the table to use\n";
  print "      -k  <column name>:   The name of the key column\n";
  print "      -c  <column name>:   The name of the column on which we select\n";
  print "      -v  <column value>:  The value in the where for the column we select\n";
  print "      -h                   Print headers (default is no header for all schemas)\n";
  print "      -tc <color>:         The 'true' color to use (default \"0,0,255,1\" -- blue)\n";
  print "      -fc <color>:         The 'true' color to use (default \"255,255,0,1\" -- yellow)\n";
  print "      -ot <objects_type>:  'Genes' or 'Experiments' (default is Experiments)\n";
  print "      -n  <name>:          The name that will be assigned to this color scheme\n";
}

1
