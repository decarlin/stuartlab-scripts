#!/usr/bin/perl

use strict;
require "$ENV{MYPERLDIR}/lib/worm.pl";

my $error_log_file = "errors_merge_synonyms.log";

# First argument is the output file.
my $out_file = shift @ARGV;

my $orf;
my @genes;
my $gene;
my %genes;
my %gene1;
my $genes;
my $delim="\t";
my $error_log_open=0;
my %gene_and_gene;
my %gene2gene;
my %gene2orf;
foreach my $file (@ARGV)
{
  if(-f $file)
  {
    open(FILE,$file) or die("Could not open input file '$file'.");

    my $line=0;
    while(<FILE>)
    {
      $line++;
      chop;
      (@genes) = split($delim);
      for(my $i=0; $i<$#genes; $i++)
      {
        for(my $j=$i+1; $j<=$#genes; $j++)
        {
          if($genes[$i] ne $genes[$j] and
	       not(exists($gene_and_gene{$genes[$i] . $delim . $genes[$j]})))
          {
            if(not(exists($gene2gene{$genes[$i]})))
              { $gene2gene{$genes[$i]} = $genes[$j]; } 
            else
              { $gene2gene{$genes[$i]} .= $delim . $genes[$j]; } 
            if(not(exists($gene2gene{$genes[$j]})))
              { $gene2gene{$genes[$j]} = $genes[$i]; } 
            else
              { $gene2gene{$genes[$j]} .= $delim . $genes[$i]; } 
            $gene_and_gene{$genes[$i] . $delim . $genes[$j]} = 1;
            $gene_and_gene{$genes[$j] . $delim . $genes[$i]} = 1;
          }
        }
      }
    }
    close(FILE);
  }
}

open(OUT,">$out_file") or die("Could not open output file '$out_file'");

@genes = keys(%gene2gene);
my %seen;
while($#genes>0)
{
  my $gene = shift @genes;
  my $nbrhood = &get_synonyms($gene,$delim,\%gene2gene,\%seen);

  # Find out which ones are the ORFs and print those first
  my @orfs = ();
  @genes = ();
  foreach $gene (split($delim,$nbrhood))
  {
    if(&IsGeneWorm($gene))
    {
      push(@genes, $gene);
    }
    else
    {
      push(@orfs, $gene);
    }
  }
  # print OUT join($delim,@orfs), $delim, join($delim,@genes), "\n";
  # foreach my $g (split($delim,$nbrhood))
  # {
  #   if($g eq $gene)
  #   {
  #     print STDERR "FUCK!\n";
  #   }
  # }
  # print OUT $nbrhood, "\n";
  print OUT join($delim,(@orfs,@genes)), "\n";
  @genes = keys(%gene2gene);
}


sub get_synonyms
{
  my $name = shift;
  my $delim = shift;
  my $map_ref = shift;
  my $seen_ref = shift;
  my $nbrhood = ''; # The root's in it's own neighborhood.
  if(not(exists($$seen_ref{$name})))
  {
    $nbrhood = $name;
    $$seen_ref{$name} = 1;
    if(exists($$map_ref{$name}))
    {
      my $nbrs = $$map_ref{$name};
      my @nbrs = split($delim,$nbrs);
      delete $$map_ref{$name};
      foreach my $nbr (@nbrs)
      {
        my $nbr_nbrs = &get_synonyms($nbr,$delim,$map_ref,$seen_ref);
        $nbrhood .= length($nbr_nbrs)>0 ? $delim . $nbr_nbrs : '';
      }
    }
  }
  return $nbrhood;
}


