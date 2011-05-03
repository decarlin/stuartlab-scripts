#!/usr/bin/perl

use strict;

require "$ENV{MYPERLDIR}/lib/load_args.pl";

if ($ARGV[0] eq "--help")
{
  print STDOUT <DATA>;
  exit;
}

my $data_file = $ARGV[0];

my %args = load_args(\@ARGV);

my $zero_threshold = get_arg("0", 0.1, \%args);
my $one_threshold = get_arg("1", 0.001, \%args);

open(DATA, "<$data_file");
my $line = <DATA>;
print $line;
while(<DATA>)
{
  chop;

  my @row = split(/\t/);

  print "$row[0]\t";

  for (my $i = 1; $i < @row; $i++)
  {
    #print "$row[$i] --> ";

    if ($row[$i] <= $one_threshold) { print "1\t"; }
    elsif ($row[$i] >= $zero_threshold) { print "0\t"; }
    else { print "-1\t"; }
  }

  print "\n";
}


__DATA__

parse_protein_dna.pl <data file>

   Parses a tab delimited protein-DNA interaction data file that contains
   p-values for protein-DNA interactions into a tab-delimited 0-1 file
   that contains '0' for everything with a pvalue higher than a certain
   threshold and contains a '1' for everything with a pvalue lower than
   a certain threshold (note that since these are two different thresholds,
   we can have a 'gray zone' that is ignored ('-1' will be printed).

   -0 <threshold>:  anything above this threshold will be a '0'
   -1 <threshold>:  anything below this threshold will be a '1'
