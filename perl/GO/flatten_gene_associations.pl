#!/usr/bin/perl

use strict;

my $min_positive_annotations = 8;

if (length($ARGV[1]) == 0)
{
  print <DATA>;
  exit;
}

my $infile = $ARGV[0];
my $outfile = $ARGV[1];

open (INFILE, "<$infile") or die "Can't open $infile.\n";
open (OUTFILE, ">$outfile");

my %orf_names;
my %annotation_counts;
my %annotation_names;
my %annotations_2_ids;
my $num_annotations = 0;
my %orf_assignments;
my $num_orfs;

while(<INFILE>)
{
  chop;

  my ($orf, $annotation) = split(/\t/);

  if ($orf_assignments{$orf . ";;;" . $annotation} ne "1")
  {
    if (length($annotation_counts{$annotation}) == 0) { $annotation_counts{$annotation} = 0; }
    else { $annotation_counts{$annotation}++; }

    if (length($orf_names{$orf}) == 0) { $num_orfs++; }

    $orf_names{$orf} = "1";
    $annotation_names{$annotation} = "1";
    $orf_assignments{$orf . ";;;" . $annotation} = "1";
  }
}

my $num_annotations_counter = 0;
foreach my $annotation (keys %annotation_names)
{
  if ($annotation_counts{$annotation} >= $min_positive_annotations)
  {
    $num_annotations_counter++
  }
}
print "Number Annotations = $num_annotations_counter\n";
print "Number ORFs = $num_orfs\n";

print OUTFILE "ORF\t";
foreach my $annotation (keys %annotation_names)
{
  if ($annotation_counts{$annotation} >= $min_positive_annotations)
  {
    print OUTFILE "$annotation\t";
  }
}
print OUTFILE "\n";

foreach my $orf (keys %orf_names)
{
  print OUTFILE "$orf\t";
  foreach my $annotation (keys %annotation_names)
  {
    if ($annotation_counts{$annotation} >= $min_positive_annotations)
    {
      if ($orf_assignments{$orf . ";;;" . $annotation} eq "1")
      {
	print OUTFILE "1\t";
      }
      else
      {
	print OUTFILE "0\t";
      }
    }
  }
  print OUTFILE "\n";
}

__DATA__

Usage: flatten_gene_associations.pl <gene association file> <output file>

