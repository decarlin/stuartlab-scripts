#!/usr/bin/perl

use strict;

require "$ENV{MYPERLDIR}/lib/libfile.pl";
require "$ENV{MYPERLDIR}/lib/libmap_run.pl";

if($#ARGV == -1)
{
  print STDOUT <DATA>;
  exit(0);
}

my $verbose=1;
my @files;
my $delim = "\t";
my $key_col = 1;
my $clu_col = 2;
my $maxpairs = 10000;
my $headers = 0;
while(@ARGV)
{
  my $arg = shift @ARGV;

  if($arg eq '--help')
  {
    print STDOUT <DATA>;
    exit(0);
  }
  elsif($arg eq '-q')
  {
    $verbose = 0;
  }
  elsif($arg eq '-k')
  {
    $key_col = int(shift @ARGV);
  }
  elsif($arg eq '-c')
  {
    $clu_col = int(shift @ARGV);
  }
  elsif($arg eq '-d')
  {
    $delim = shift @ARGV;
  }
  elsif($arg eq '-maxpairs')
  {
    $maxpairs = int(shift @ARGV);
  }
  elsif($arg eq '-headers')
  {
    $headers = int(shift @ARGV);
  }
  elsif(-f $arg)
  {
    push(@files,$arg);
  }
  elsif($arg eq '-')
  {
    push(@files, '-');
  }
  else
  {
    die("Base argument '$arg' given.");
  }
}
$key_col--;
$clu_col--;


my $f=0;
my %key2num;
my $num_keys=0;
my $gold_cluster2members;
my $gold_member2clusters;
my @experimental_cluster2members;
my @experimental_member2clusters;
my $num_experimental;
foreach my $file (@files)
{

  # Gold-standard clustering
  if($f == 0)
  {
    ($gold_cluster2members,$gold_member2clusters)
      = &getClustersFromVectorized($file,$headers,$delim,$key_col,$clu_col);
  }

  # Experimental clustering
  else
  {
    ($experimental_cluster2members[$num_experimental],$experimental_member2clusters[$num_experimental])
      = &getClustersFromVectorized($file,$headers,$delim,$key_col,$clu_col);
    $num_experimental++;
  }
  $f++;
}


# For each clustering, normalize the key-space and then do the counts.
for(my $i=0; $i<=$#experimental_cluster2members; $i++)
{
  my ($gold,$experiment) = 
    &getClusteringCommonDenominator($gold_cluster2members,$experimental_cluster2members[$i]);

  my %gold_c2m  = %{$gold};
  my %experiment_c2m = %{$experiment};

  my %gold_m2c;
  foreach my $cluster (sort(keys(%gold_c2m)))
  {
    my %members = %{$gold_c2m{$cluster}};
    foreach my $member (sort(keys(%members)))
    {
      $gold_m2c{$member} = $cluster;
    }
  }

  my %experiment_m2c;
  foreach my $cluster (sort(keys(%experiment_c2m)))
  {
    my %members = %{$experiment_c2m{$cluster}};
    foreach my $member (sort(keys(%members)))
    {
      $experiment_m2c{$member} = $cluster;
    }
  }

  # Compute the sensitivity
  my ($sensitivity,$specificity) = &getClusteringROC(\%gold_c2m,\%experiment_m2c,$maxpairs,$verbose);
  my ($recall,$precision)        = &getClusteringROC(\%experiment_c2m,\%gold_m2c,$maxpairs,$verbose);
  print "$sensitivity\t$specificity\t$recall\t$precision\n";
}

exit(0);

__DATA__

syntax: cluster_pairwise_coincidence.pl [OPTIONS] GOLD CLUSTERING1 [CLUSTERING2 ...]

Reports an ROC-like measure of how well each clustering represents the gold-standard.  For
each clustering a summary line is printed.  Each summary line contains 4 numbers:

TPR <tab> TNR <tab> FPR <tab> FNR

where:
	TPR - true-positive rate
	FPR - false-positive rate
	TNR - true-negative rate
	FNR - false-negative rate

GOLD        : cluster list of the gold-standard grouping of the items.
CLUSTERINGi : cluster list of an experimental clustering of the items.

OPTIONS are:

-q: Quiet mode -- turn verbosity off (default verbose)
-d DELIM: Set the column delimiter to DELIM (default is <tab>)
-k COL: Get the key from column COL (default is 1)
-c COL: Get the cluster from column COL (default is 2)
-maxpairs N: Set the maximum number of pairs to test to N (default is $maxpairs)
-headers N: The clustering files contain N row headers that should be ignored (default is 0)


