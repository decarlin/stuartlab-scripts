#!/usr/bin/perl

use strict;

require "$ENV{MYPERLDIR}/lib/load_args.pl";
require "$ENV{MYPERLDIR}/lib/libfile.pl";

if ($ARGV[0] eq "--help")
{
  print STDOUT <DATA>;
  exit;
}

my $source_file = $ARGV[0];

my %args = load_args(\@ARGV);

my $source_key = get_arg("k", 0, \%args);
my $print_num_averaged_rows = get_arg("n", 0, \%args);
my $skip_num = get_arg("skip", 0, \%args);
my $min = get_arg("min", "", \%args);
my $max = get_arg("max", "", \%args);
my $take_max = get_arg("take_max", "", \%args);
my $take_last = get_arg("take_last", "", \%args);
my $precision = get_arg("precision", 3, \%args);
my $output_file = get_arg("o", "", \%args);

if (length($output_file) > 0) { open(OUTFILE, ">$output_file"); }

my %key2id;
my $key_counter = 0;
my @averaged_data;
my @averaged_counts;
my $max_columns = 0;

open(FILE, "<$source_file");

for (my $i = 0; $i < $skip_num; $i++) { my $line = <FILE>; &myprint("$line"); }

while(<FILE>)
{
  chop;

  my @row = split(/\t/);

  if (@row > $max_columns) { $max_columns = @row; }

  my $id = $key2id{$row[$source_key]};
  if (length($id) == 0)
  {
    $id = $key_counter++;
    $key2id{$row[$source_key]} = $id;
    $averaged_data[$id][0] = $row[$source_key];
  }

  for (my $i = 1; $i < @row; $i++)
  {
    if (length($row[$i]) > 0)
    {
      if (length($min) > 0 and $row[$i] < $min) { $row[$i] = $min; }
      if (length($max) > 0 and $row[$i] > $max) { $row[$i] = $max; }

      if ($take_max == 1)
      {
	if (length($averaged_data[$id][$i]) == 0 or $averaged_data[$id][$i] < $row[$i])
	{
	  $averaged_data[$id][$i] = $row[$i];
	}
      }
      elsif ($take_last == 1)
      {
	  $averaged_data[$id][$i] = $row[$i];
      }
      else
      {
	$averaged_data[$id][$i] += $row[$i];
      }

      $averaged_counts[$id][$i]++;
    }
  }
}

for (my $i = 0; $i < $key_counter; $i++)
{
  if ($print_num_averaged_rows == 1)
  {
    my $max = 0;
    for (my $j = 1; $j < $max_columns; $j++)
    {
      if (length($averaged_counts[$i][$j]) > 0 and $averaged_counts[$i][$j] > $max)
      {
	$max = $averaged_counts[$i][$j];
      }
    }
    &myprint("$max\t");
  }

  &myprint("$averaged_data[$i][0]\t");

  for (my $j = 1; $j < $max_columns; $j++)
  {
    if ($take_max == 1)
    {
      &myprint(&format_number($averaged_data[$i][$j], $precision));
    }
    elsif ($take_last == 1)
    {
      &myprint($averaged_data[$i][$j]);
    }
    elsif (length($averaged_counts[$i][$j]) > 0)
    {
      &myprint(&format_number($averaged_data[$i][$j] / $averaged_counts[$i][$j], $precision));
    }
    
    if ($j < $max_columns - 1) { &myprint("\t"); }
  }

  &myprint("\n");
}

if (length($output_file) > 0) { close(OUTFILE); }

print STDERR "KILL ME IF SYSTEM HALTS\n";

sub myprint
{
  my ($str) = @_;

  if (length($output_file) > 0) { print OUTFILE $str; }
  else { print $str; }
}

__DATA__

average_rows.pl <source file>

   Average rows in <source file> that have the same key

   -k:               row of the key (default is 0)
   -n:               If specified, add the number of rows that went into the averaging
   -skip <num>:      Skip num rows in the source file and just print them (default: 0)
   -min <num>:       If specified, values below num are converted to num
   -max <num>:       If specified, values above num are converted to num
   -precision <num>: Precision of the numbers printed (default: 3 digits)
   -take_max:        If specified, then instead of taking average for same key, take max
   -take_last:       If specified, then instead of taking average for same key, take last occurence
   -o <file>:        If specified, print to this file, otherwise to STDOUT

