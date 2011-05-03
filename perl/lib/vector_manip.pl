#!/usr/bin/perl

use strict;

require "$ENV{MYPERLDIR}/lib/libstats.pl";
require "$ENV{MYPERLDIR}/lib/load_args.pl";
require "$ENV{MYPERLDIR}/lib/libfile.pl";
require "$ENV{MYPERLDIR}/lib/bio_load_file_to_memory.pl";

my $RUNNING_SUM = "rs";
my $SUM = "s";
my $MIN = "m";
my $MAX = "M";
my $AVG = "A";
my $STD = "STD";
my $SHRINK = "S";
my $TOP_UNIQUE = "T";
my $STAT = "stat";

#--------------------------------------------------------------------------------
# vector_manip
#--------------------------------------------------------------------------------
sub single_vector_manip (\@\@$$$$$)
{
  my ($matrix_str,
      $vec_str,
      $start_row,
      $op,
      $Tunique,
      $stat,
      $delim) = @_;

  my @matrix = @{$matrix_str};
  my @vec = @{$vec_str};

  if ($op eq $RUNNING_SUM) { my $sum = 0; for (my $i = 0; $i < @vec; $i++) { $sum += $vec[$i]; print "$sum\t@{$matrix[$i - $start_row]}\n"; } }
  if ($op eq $SUM) { print vec_sum(\@vec) . "\n"; }
  if ($op eq $MIN) { print vec_min(\@vec) . "\n"; }
  if ($op eq $MAX) { print vec_max(\@vec) . "\n"; }
  if ($op eq $AVG) { print format_number(vec_avg(\@vec), 3) . "\n"; }
  if ($op eq $STD) { print format_number(vec_std(\@vec), 3) . "\n"; }
  if ($op eq $SHRINK) { for (my $i = 0; $i < @vec; $i++) { print $vec[$i] . $delim; } print "\n"; }
  if ($op eq $STAT) { my %stats = vec_stats(\@vec); foreach my $key (keys %stats) { print "$key = $stats{$key}\n"; } print "\n"; }
  if ($op eq $TOP_UNIQUE)
  {
    my $num_distinct_keys = 0;
    my %found_keys;
    my $total_covered = 0;
    for (my $i = 0; $i < @vec; $i++)
    {
      my @rest = @{$matrix[$i]};
      if ($num_distinct_keys < $Tunique && length($found_keys{$vec[$i]}) == 0) { print "$vec[$i]\t$i\t$rest[3]\n"; $found_keys{$vec[$i]} = "1"; $num_distinct_keys++; }
      if (length($found_keys{$vec[$i]}) > 0) { $total_covered++; }
    }
    print "Total Covered $total_covered\n";
  }
}

#--------------------------------------------------------------------------------
# vector_manip
#--------------------------------------------------------------------------------
sub vector_manip
{
  my ($file_name,
      $vec_column,
      $start_row,
      $apply_to_all,
      $op,
      $Tunique,
      $stat,
      $delim) = @_;

  my @matrix = load_file_to_memory($file_name);

  if ($apply_to_all)
  {
    for (my $i = $vec_column; $i < @{$matrix[0]}; $i++)
    {
      my @vec = load_vec_to_memory($file_name, $i, $start_row);

      single_vector_manip(@matrix, @vec, $start_row, $op, $Tunique, $stat, $delim);
    }
  }
  else
  {
    my @vec = load_vec_to_memory($file_name, $vec_column, $start_row);

    single_vector_manip(@matrix, @vec, $start_row, $op, $Tunique, $stat, $delim);
  }
}

#--------------------------------------------------------------------------------
# STDIN
#--------------------------------------------------------------------------------
if (length($ARGV[0]) > 0)
{
  my %args = load_args(\@ARGV);

  vector_manip($ARGV[0],
	       get_arg("c",    0, \%args),
	       get_arg("r",    0, \%args),
	       get_arg("A",    0, \%args),
	       get_arg("o",    $RUNNING_SUM, \%args),
	       get_arg("T",    0, \%args),
	       get_arg("stat", 0, \%args),
	       get_arg("d",    "", \%args));
}
else
{
  print "Usage: vector_manip.pl data_file\n\n";
  print "      -c <N>:  The column number of the vector to manipulate (default 0) -- Also serves as the start column in the case of apply to all!\n";
  print "      -r <N>:  The row number from which to start (default 0)\n";
  print "      -A:      Apply the operation to all vectors\n";
  print "      -o <Op>: The operation to use. Supported:\n";
  print "                  rs           - Running sum (DEFAULT)\n";
  print "                  s            - Sum\n";
  print "                  m            - Min\n";
  print "                  M            - Max\n";
  print "                  A            - Avg\n";
  print "                  S <-d delim> - Shrinks the vector into one row, where each original row is separated by delim\n";
  print "                  stat         - Show stats for the vector (# of occurences for each value)\n";
  print "                  T <-T N>     - Print entries in the vector until reaching N different ones\n\n";
  print "                  STD          - Standard Deviation\n";
}

