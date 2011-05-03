#! /usr/bin/perl

use strict;

require "$ENV{MYPERLDIR}/lib/load_args.pl";

my $TO_UPPER = "U";

#--------------------------------------------------------------------------------
# file_manip
#--------------------------------------------------------------------------------
sub file_manip
{
  my ($file_name,
      $column,
      $delim,
      $to_upper) = @_;

  open(INPUT_FILE, "<$file_name");
  while(<INPUT_FILE>)
  {
    chop;

    my @row = split(/$delim/);

    for (my $i = 0; $i < @row; $i++)
    {
      if ($column == -1 || $column == $i)
      {
	if ($to_upper) { print "\U$row[$i]\t"; }
	else { print "$row[$i]\t"; }
      }
      else { print "$row[$i]\t"; }
    }
    print "\n";
  }
}

#--------------------------------------------------------------------------------
# STDIN
#--------------------------------------------------------------------------------
if (length($ARGV[0]) > 0)
{
  my %args = load_args(\@ARGV);

  file_manip($ARGV[0],
	     get_arg("c", -1,   \%args),
	     get_arg("d", "\t", \%args),
	     get_arg("U", "",   \%args));
}
else
{
  print "Usage: file_manip.pl data_file\n\n";
  print "      -c <N>:      The column number to manipulate (default -1 means all columns)\n";
  print "      -d <delim>:  The delimiter to use for splitting columns in each row (default is tab)\n";
  print "      -U:          To Upper case\n";
}
