#!/usr/bin/perl

use strict;

my $evalue_cutoff = 1e-10; # E-values equal or below this are considered significant
my $delim_in = "\t"; # BLAST table delimiter.
my $delim_out = "\t"; # The delimiter for output.
my $query1_col = 1;
my $query2_col = 2;
my $evalue_col = 11;

while(@ARGV)
{
  my $arg = shift @ARGV;
  if($arg eq '--help')
  {
    print STDOUT <DATA>;
    exit(0);
  }
  elsif($arg eq '-e')
  {
    $evalue_cutoff = shift @ARGV;
  }
}
$query1_col--;
$query2_col--;
$evalue_col--;

while(<STDIN>)
{
  if(/\S/ and not(/^\s*#/))
  {
    chop;
    my @tuple = split($delim_in);
    my $query1 = $tuple[$query1_col];
    my $query2 = $tuple[$query2_col];
    my $evalue = $tuple[$evalue_col];
    $query2 =~ s/:$//;
    if($evalue <= $evalue_cutoff)
    {
      print $query1, $delim_out, $query2, $delim_out, $evalue, "\n";
    }
  }
}

__DATA__
syntax: blasttab_sig.pl [OPTIONS] < BLASTTAB

Extract significant hits from a BLAST result

BLASTTAB is a BLAST table the result of using the "-m 9" option in blastall.

OPTIONS are:

  -e EVALUE: Set the E-value cutoff to EVALUE.  BLAST E-values equal to or less than
             this score are considered significant (default is 1e-10).

