#!/usr/bin/perl

use strict;

my $input_file = $ARGV[0];
my $pvalue = $ARGV[1];
my $neighborhood_output = $ARGV[2];
my $neighborhood_binarized_output = $ARGV[3];

open(NEIGHBORHOOD_OUTPUT, ">$neighborhood_output");
open(NEIGHBORHOOD_BINARIZED_OUTPUT, ">$neighborhood_binarized_output");

open(FILE, "<$ARGV[0]");
while(<FILE>)
{
  chop;

  my @row = split(/\t/);

  print NEIGHBORHOOD_OUTPUT "$row[0]\t";

  for (my $i = 1; $i < @row; $i += 2)
  {
    if ($row[$i + 1] <= $pvalue)
    {
      print NEIGHBORHOOD_OUTPUT "$row[$i]\t";
      print NEIGHBORHOOD_BINARIZED_OUTPUT "$row[0]\t$row[$i]\n";
    }
  }

  print NEIGHBORHOOD_OUTPUT "\n";
}
