#!/usr/bin/perl

require "$ENV{MYPERLDIR}/lib/worm.pl";
use strict;

my $error_log_file = "errors_merge_genes.log";

# First argument is the output file.
my $out_file = shift @ARGV;
open(OUT,">$out_file") or die("Could not open output file '$out_file'");

my $orf;
my @genes;
my $gene;
my %genes;
my %gene1;
my $genes;
my $delim="\t";
my $error_log_open=0;
my %orf_and_gene;
foreach my $file (@ARGV)
{
  open(FILE,$file) or die("Could not open input file '$file'.");

  my $line=0;
  while(<FILE>)
  {
    $line++;
    chop;
    ($orf,@genes) = split($delim);
    my $orig_orf=$orf;
    $orf = &FixOrfWorm($orf);
    if(&IsSpliceWorm($orf))
      { $orf = &Splice2OrfWorm($orf); }
    if(&IsOrfWorm($orf))
    {
      $gene1{$genes[0]} = $orf;
      if(not(exists($genes{$orf})))
        { $genes{$orf} = join($delim,@genes); }
      else
        { $genes{$orf} .= $delim . join($delim,@genes); }
    }
    else
    {
      if(not($error_log_open))
      {
        if(open(ERR,">$error_log_file"))
	  { $error_log_open=1; }
      }
      if($error_log_open)
      {
        print ERR "In '$file' line $line: non-ORF '$orig_orf' in ORF column, skipped.\n";
      }
    }
  }
  close(FILE);
}

my %seen;
foreach $gene (sort CmpGeneWorm (keys(%gene1)))
{
  $orf = $gene1{$gene};
  if(not(exists($seen{$orf})))
  {
    @genes = split($delim,$genes{$orf});
    $genes='';
    foreach $gene (@genes)
    {
      $gene = &FixGeneWorm($gene);
      if(&IsGeneWorm($gene))
      {
	if(not(exists($orf_and_gene{$orf,$gene})))
	{
          if(not(exists($seen{$gene})))
          {
            $seen{$gene} = 1;
          }
          else
          {
            if(not($error_log_open))
            {
              if(open(ERR,">$error_log_file"))
	        { $error_log_open=1; }
            }
            if($error_log_open)
            {
              print ERR "WARNING '$gene' have multiple ORF assignments.\n";
            }
          }
          $genes .= $delim . $gene;
	  $orf_and_gene{$orf,$gene} = 1;
        }
      }
      else
      {
        if(not($error_log_open))
        {
          if(open(ERR,">$error_log_file"))
	    { $error_log_open=1; }
        }
        if($error_log_open)
        {
          print ERR "Gene '$gene' not a valid gene name.\n";
        }
      }
    }
    if(length($genes)>0)
    {
      print OUT $orf, $genes, "\n";
    }
    else
    {
      if(not($error_log_open))
      {
        if(open(ERR,">$error_log_file"))
	  { $error_log_open=1; }
      }
      if($error_log_open)
      {
        print ERR "ORF '$orf' had no valid genes.\n";
      }
    }
    $seen{$orf}=1;
  }
}
close(OUT);
if($error_log_open)
  { close(ERR); }


