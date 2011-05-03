#!/usr/bin/perl

##############################################################################
##############################################################################
##
## gb.pl
##
##############################################################################
##############################################################################
##
## Written by Josh Stuart.
##
##  Email address: jstuart@ucsc.edu
##          Phone: (831) 459-1344
##
## Postal address: Department of Biomolecular Engineering
##                 Baskin Engineering 129
##                 University of California, Santa Cruz
##                 Santa Cruz, CA 95064
##
##############################################################################

require("$ENV{MYPERLDIR}/lib/libseq.pl");
require("$ENV{MYPERLDIR}/lib/libset.pl");

use strict;
use warnings;

# Flush output to STDOUT immediately.
$| = 1;

if($ARGV[0] eq '--help' or scalar(@ARGV) != 4)
{
   print STDOUT <DATA>;
   exit(0);
}

my ($genbank, $genes, $five, $three) = @ARGV;

if($five > 0) { $five--; }

if($three > 0) { $three--; }

if(not(open(GENES, $genes)))
{
   die("Could not open the GENES file '$genes'");
}

my @genes;
while(<GENES>)
{
   chomp;
   push(@genes, $_);
}
close(GENES);

my %genes = %{&list2Set(\@genes)};

my $seq = &gbGetSeq($genbank);

# print STDOUT "$seq";

my %regions = %{&gbGetGenes($genbank, \%genes)};

for(my $i = 0; $i < @genes; $i++)
{
   my $gene = $genes[$i];

   if(exists($regions{$gene}))
   {
      my ($gene5, $gene3) = @{$regions{$gene}};

      my ($seq5, $seq3) = (undef, undef);

      if($gene5 <= $gene3)
      {
         $seq5 = $gene5 + $five;
         $seq3 = $gene5 + $three;
      }
      else
      {
         $seq5 = $gene5 - $five;
         $seq3 = $gene5 - $three;
      }

      my $sub = &nucSubSeq($seq, $seq5, $seq3);

      print STDOUT "$gene\t$sub\n";
   }
}

exit(0);


__DATA__
syntax: gb.pl GENBANK GENES FIVE THREE

Retrieves upstream sequences from a genbank file.

GENBANK: a genbank formatted file.

GENES: a list of genes (one per line).

FIVE: The five prime end relative to start codon (e.g. -100)

THREE: The three prime end relative to the start codon (e.g. +1).


