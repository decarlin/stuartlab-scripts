#!/usr/bin/perl

use strict;

require "$ENV{MYPERLDIR}/lib/load_args.pl";

if ($ARGV[0] eq "--help")
{
  print STDOUT <DATA>;
  exit;
}

my $r = int(rand(1000000));

my $gx_file = $ARGV[0];
my $combinations_file = $ARGV[1];

my %args = load_args(\@ARGV);

my $keepallgenes = get_arg("keepallgenes", 0, \%args);

my %cluster_assignments;
`extract_clusters.pl $gx_file > tmp.$r`;
open(CLUSTERS, "<tmp.$r") or die "could not get the clusters from $gx_file\n";
while(<CLUSTERS>)
{
  chop;

  my @row = split(/\t/);

  print "cluster_assignments{$row[0]} = $row[1]\n";

  $row[1] =~ s/Cluster[\s]//g;

  $cluster_assignments{$row[0]} = $row[1];
}
`rm tmp.$r`;

`gx2microarray.pl $gx_file > tmp_microarray.$r.tab`;

my @all_genes;
my $num_genes = 0;
open(MICROARRAY, "<tmp_microarray.$r.tab");
<MICROARRAY>;
while(<MICROARRAY>)
{
  chop;

  my @row = split(/\t/);

  $all_genes[$num_genes++] = $row[0];
}

my @combinations;
my $num_combinations = 0;
open(COMBINATIONS_FILE, "<$combinations_file");
while(<COMBINATIONS_FILE>)
{
  chop;

  $combinations[$num_combinations++] = $_;
}

foreach my $combination (@combinations)
{
  my %combinations_hash;
  my @row = split(/\t/, $combination);

  open(TMP_GENE_LIST, ">tmp.$r");

  foreach my $item (@row)
  {
    $combinations_hash{$item} = "1";
  }

  my %combination_genes;
  foreach my $gene (keys %cluster_assignments)
  {
    if ($combinations_hash{$cluster_assignments{$gene}} eq "1")
    {
      print TMP_GENE_LIST "$gene\n";
      $combination_genes{$gene} = "1";
    }
  }

  my $underscored_combination = $combination;
  $underscored_combination =~ s/[\t]/_/g;

  open(CLUSTER_ASSIGNMENTS, ">tmp_cluster_assignments.$r");
  print CLUSTER_ASSIGNMENTS "g_module\n";
  foreach my $gene (@all_genes)
  {
    if ($combination_genes{$gene} eq "1") { print CLUSTER_ASSIGNMENTS "1\n"; } else { print CLUSTER_ASSIGNMENTS "0\n"; }
  }

  if ($keepallgenes)
  {
    system("bind.pl /u/erans/Templates/GeneXPress/microarray2genexpress.map expression_file=tmp_microarray.$r.tab cluster_assignments=tmp_cluster_assignments.$r output_file=$underscored_combination.tsc -xml > tmp.$r.map");
  }
  else
  {
    system("bind.pl /u/erans/Templates/GeneXPress/microarray2genexpress.map expression_file=tmp_microarray.$r.tab gene_list=tmp.$r output_file=$underscored_combination.tsc -xml > tmp.$r.map");
  }

  system("map_learn tmp.$r.map");

  `rm tmp.$r`;
  `rm tmp.$r.map`;
  `rm tmp_cluster_assignments.$r`;
}

`rm tmp_microarray.$r.tab`;

__DATA__

gxgroups2gx.pl <gx file> <clusters combinations>

   -keepallgenes:    Create a file with the selected cluster combination
                     vs. all the other genes (if not set, then creates a
                     file only with the genes in the cluster combination.

Takes an existing GeneXPress file and a list of 
combinations of cluster numbers, and makes one
GeneXPress file from each combination of clusters.
The format of cluster combinations is one 
combination per line, tab-separated per line.

