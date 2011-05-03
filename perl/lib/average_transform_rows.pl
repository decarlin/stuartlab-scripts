#!/usr/bin/perl

use strict;

require "$ENV{MYPERLDIR}/lib/load_args.pl";
require "$ENV{MYPERLDIR}/lib/libfile.pl";

my $log2 = log(2);

if ($ARGV[0] eq "--help")
{
  print STDOUT <DATA>;
  exit;
}

my $source_file = $ARGV[0];

my %args = load_args(\@ARGV);

my $column_list = get_arg("zero", "", \%args);
my $skip_num = get_arg("skip", 0, \%args);
my $precision = get_arg("precision", 3, \%args);
my $min = get_arg("min", "", \%args);
my $max = get_arg("max", "", \%args);
my $log_ratio = get_arg("log_ratio", 0, \%args);
my $mean_columns = get_arg("mean_columns", "", \%args);
my $median_center = get_arg("median_center", 0, \%args);
my $no_average = get_arg("no_average", 0, \%args);

my %mean_columns_hash;
if (length($mean_columns) > 0)
{
  my @row = split(/\,/, $mean_columns);
  for (my $i = 0; $i < @row; $i++)
  {
    $mean_columns_hash{$row[$i]} = "1";
  }
}

open(FILE, "<$source_file");

for (my $i = 0; $i < $skip_num; $i++)
{
  my $line = <FILE>;

  print "$line";
}

while(<FILE>)
{
  chop;

  my @row = split(/\t/);

  my $num = 0;
  my $sum = 0;

  for (my $i = 1; $i < @row; $i++)
  {
    if (length($row[$i]) > 0)
    {
      if (length($min) > 0 and $row[$i] < $min) { $row[$i] = $min; }
      if (length($max) > 0 and $row[$i] > $max) { $row[$i] = $max; }

      if (length($mean_columns) == 0 or $mean_columns_hash{$i} eq "1")
      {
	$sum += $row[$i];
	$num++;
      }
    }
  }

  my $mean = 0;
  if ($num > 0) { $mean = $sum / $num; }

  if ($median_center == 1)
  {
    my @sorted_data;
    for (my $i = 1; $i < @row; $i++) { $sorted_data[$i - 1] = $row[$i]; }
    @sorted_data = sort { $a <=> $b } @sorted_data;
    my $median_index = @sorted_data;
    my $median_index = int($median_index / 2);
    $mean = $sorted_data[$median_index];
  }

  print "$row[0]\t";

  for (my $i = 1; $i < @row; $i++)
  {
    if (length($row[$i]) > 0)
    {
      if ($no_average == 1) { print format_number($row[$i], $precision); }
      elsif ($log_ratio == 1) { print format_number(log($row[$i] / $mean) / $log2, $precision); }
      else { print format_number($row[$i] - $mean, $precision); }
    }

    print "\t";
  }

  print "\n";
}

__DATA__

average_transform_rows.pl <source file>

   Subtracts the average of each row from each entry in the row

   -skip <num>:          Skip num rows in the source file and just print them (default: 0)
   -precision <num>:     Precision of the numbers printed (default: 3 digits)
   -min <num>:           If specified, values below num are converted to num
   -max <num>:           If specified, values above num are converted to num
   -log_ratio:           If specified, each value is printed as the log-ratio to the subtracted average
   -no_average:          If specified, averaging is not done at all (useful for trimming values)
   -mean_columns <list>: If specified, then the mean is computer from the column <list> (format: 1,3,6)
   -median_center:       If specified, then will use the median of the gene as the average to subtract

