#!/usr/bin/perl

use strict;

require "$ENV{MYPERLDIR}/lib/load_args.pl";

if ($ARGV[0] eq "--help")
{
  print STDOUT <DATA>;
}

my $path = $ARGV[0];

my %args = load_args(\@ARGV);

my $num_keys = get_arg("keys", 0, \%args),

my $files_str .= `find $path -name "eval.out" -print`;
my @files = split(/\n/, $files_str);

foreach my $file (@files)
{
  my @row = split(/\//, $file);

  if ($row[@row - 2] =~ /ClusterTightness/)
  {
    my $str = "";
    for (my $i = @row - $num_keys - 2; $i <= @row - 3; $i++)
    {
      $str .= "$row[$i]\t";
    }

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
}

__DATA__

collate_cluster_tightness.pl <start directory> (e.g. ~/Runs/GeneProjection)

   -keys <num>:   Number of directories from the end of the file to include in the output file.
                  Example: a/b/c/d/eval.out will add 'c' and 'd' if keys is 2

