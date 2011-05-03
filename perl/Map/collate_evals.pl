#!/usr/bin/perl

use strict;

require "$ENV{MYPERLDIR}/lib/load_args.pl";

if ($ARGV[0] eq "--help")
{
  print STDOUT <DATA>;
}

my $path = $ARGV[0];

my %args = load_args(\@ARGV);

my $num_keys = get_arg("keys", 0, \%args);
my $collate_dir = get_arg("dir", "ClusterTightness", \%args);
my $eval_file =  get_arg("file", "eval.out", \%args);

my $files_str .= `find $path -name $eval_file -print`;
my @files = split(/\n/, $files_str);

&print_header;

foreach my $file (@files)
{
  my @row = split(/\//, $file);

  my $str = "";
  for (my $i = @row - $num_keys - 2; $i <= @row - 3; $i++)
  {
    $str .= "$row[$i]\t";
  }

  if ($row[@row - 2] =~ /$collate_dir/)
  {
    if ($row[@row - 2] =~ /Go/ or $row[@row - 2] =~ /Kegg/)
    {
      &collate_gene_sets($file, $str);
    }
    elsif ($row[@row - 2] =~ /ClusterTightness/)
    {
      &collate_cluster_tightness($file, $str);
    }
    elsif ($row[@row - 2] =~ /KnownMotifs/ or $row[@row - 2] =~ /NovelMotifs/)
    {
      &collate_motifs($file, $str);
    }
  }
}

sub print_header
{
  if ($collate_dir eq "KnownMotifs" or $collate_dir eq "NovelMotifs")
  {
    print "Cluster\t";
    for (my $i = 1; $i <= $num_keys; $i++)
    {
      print "key$i\t";
    }
    print "NumGenes\t";
    print "PSSM\t";
    print "pvalue\t";
    print "InClusterFraction\t";
    print "OutOfClusterFraction\n";
  }
}

sub collate_gene_sets
{
  my $file = $_[0];
  my $str = $_[1];

  my $cluster = -1;

  open(FILE, "<$file") or die "Could not open file $file\n";

  while(<FILE>)
  {
    chop;

    my @row_file = split(/\t/);

    if ($row_file[0] =~ /^Cluster[\s]([0-9]+)/)
    {
      $cluster = $1;

      if ($cluster != -1) { print "\n"; }

      print "Cluster $cluster\t$str"
    }
    elsif ($row_file[0] =~ /^[\s][\s][\s]([^\[]+)\[([^\]]+)\]/)
    {
      print "$1($2,";

      $row_file[0] =~ /Counts=([^\]]+)/;
      print "$1/";
      $row_file[0] =~ /Dataset[\s]True=([^\]]+)/;
      print "$1)\t";
    }
  }

  print "\n";
}

sub collate_cluster_tightness
{
  my $file = $_[0];
  my $str = $_[1];

  open(FILE, "<$file") or die "Could not open file $file\n";

  while(<FILE>)
  {
    chop;

    my @row_file = split(/\t/);

    if ($row_file[0] =~ /^Cluster[\s][0-9]+/)
    {
      print "$_\t$str\n";
    }
  }
}

sub collate_motifs
{
  my $file = $_[0];
  my $str = $_[1];

  my $cluster = -1;

  open(FILE, "<$file") or die "Could not open file $file\n";

  while(<FILE>)
  {
    chop;

    my @row_file = split(/\t/);

    if ($row_file[0] =~ /^Cluster[\s]([0-9]+)/)
    {
      $cluster = $1;

      if ($cluster != -1) { print "\n"; }

      print "Cluster $cluster\t$str";

      $row_file[0] =~ /NumGenes[\s][\[]([0-9]+)[\]]/;
      print "$1\t";
    }
    elsif ($row_file[0] =~ /Threshold/)
    {
      $row_file[0] =~ /(^[^\s]+)/;
      print "$1\t";

      $row_file[0] =~ /pvalue[\s]([^\]]+)/;
      print "$1\t";

      $row_file[0] =~ /cluster[\s]hits[\s]([0-9]+)[\s]([0-9]+)[\%]/;
      print "$2\t";

      $row_file[0] =~ /outside[\s]hits[\s]([0-9]+)[\s]([0-9]+)[\%]/;
      print "$2\t";

      $row_file[0] =~ /cluster[\s]hits[\s]of[\s]total[\s]([0-9]+)[\s]([0-9]+)[\%]/;
      print "$2\t";
    }
  }

  print "\n";
}

__DATA__

collate_evals.pl <start directory> (e.g. ~/Eval/GeneProjection)

   -keys <num>:   Number of directories from the end of the file to include in the output file.
                  Example: a/b/c/d/eval.out will add 'c' and 'd' if keys is 2

   -dir <name>:   Name of directory to collate. Currently supported: Go,Kegg,ClusterTightness,KnownMotifs,NovelMotifs

   -file <name>:  The name of the file to search for the outputs in each directory (default: eval.out)

