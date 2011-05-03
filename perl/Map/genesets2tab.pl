#!/usr/bin/perl

use strict;

require "$ENV{MYPERLDIR}/lib/load_args.pl";
require "$ENV{MYPERLDIR}/lib/libfile.pl";

if ($ARGV[0] eq "--help")
{
  print STDOUT <DATA>;
  exit;
}

my $file = $ARGV[0];

my %args = load_args(\@ARGV);

my $unique = get_arg("uniq", 0, \%args);
my $allowed_cluster = get_arg("c", "", \%args);

my %annotations;
collate_gene_sets($file);

print "Cluster\tAnnotation\tPvalue\tNeg-Log-Pvalue\tCluster True\tCluster Size\tDataset True\t";
print "% Cluster\t% Annotation\n";

foreach my $annotation (keys %annotations)
{
  print $annotations{$annotation};
}

sub collate_gene_sets
{
  my $file = $_[0];

  my $cluster = -1;
  my $cluster_size = -1;

  open(FILE, "<$file") or die "Could not open file $file\n";

  while(<FILE>)
  {
    chop;

    my @row_file = split(/\t/);

    if ($row_file[0] =~ /^Cluster[\s]([0-9]+)/)
    {
      $cluster = $1; 

      $row_file[0] =~ /Counts=([^\]]+)/;
      $cluster_size = $1;
    }
    elsif ($row_file[0] =~ /^[\s][\s][\s]([^\[]+)\[([^\]]+)\]/)
    {
      my $annotation = $1;
      my $pvalue = $2;
      my $neg_log_pvalue = -log($pvalue) / log(10);

      $row_file[0] =~ /Counts=([^\]]+)/;
      my $cluster_true = $1;
      $row_file[0] =~ /Dataset[\s]True=([^\]]+)/;
      my $dataset_true = $1;

      if (length($allowed_cluster) == 0 or $cluster eq $allowed_cluster)
      {
	&add_entry($cluster, $annotation, $pvalue, $neg_log_pvalue, $cluster_true, $cluster_size, $dataset_true);
      }
    }
  }
}

sub add_entry
{
  my ($cluster, $annotation, $pvalue, $neg_log_pvalue, $cluster_true, $cluster_size, $dataset_true) = @_;

  my $str = "Cluster $cluster\t$annotation\t$pvalue\t$neg_log_pvalue\t$cluster_true\t$cluster_size\t$dataset_true\t";

  my $cluster_percent = $cluster_size > 0 ? $cluster_true / $cluster_size : 0;
  $cluster_percent = format_number(100 * $cluster_percent, 3);

  my $annotation_percent = $dataset_true > 0 ? $cluster_true / $dataset_true : 0;
  $annotation_percent = format_number(100 * $annotation_percent, 3);

  $str .= "$cluster_percent\t$annotation_percent\n";

  if (!$unique or length($annotations{$annotation}) == 0)
  {
    $annotations{$annotation} .= "$str";
  }
  else
  {
    my $prev_annotation = $annotations{$annotation};
    my @row = split(/\t/, $prev_annotation);
    if ($row[2] > $pvalue)
    {
      $annotations{$annotation} = "$str";
    }
  }
}

__DATA__

genesets2tab.pl <gene sets file>

   Takes in a gene sets eval file (e.g. Go, Kegg) and outputs a tab delimited file
   with all the annotation hits.

   -uniq:            For each annotation, only print the highest pvalue for it.

