#!/usr/bin/perl

use strict;

require "$ENV{MYPERLDIR}/lib/load_args.pl";

my $NO_STATUS = 0;
my $INSIDE_CLUSTER_STATUS = 1;
my $INSIDE_ATTRIBUTES_STATUS = 2;
my $INSIDE_ORF_STATUS= 3;

my $GK_NULL = "__GK_NULL__";

my $LAST_NUCLEATIDE = -1;

my $r = rand(int(100000));

#--------------------------------------------------------------------------------
#
#--------------------------------------------------------------------------------
sub gx2kmers
{
  my ($gxc_file, $k, $stab_file, $T, $P, $counts_file, $first_nucleatide, $last_nucleatide) = @_;

  my $status = $NO_STATUS;

  open(GXC_FILE, "<$gxc_file");
  while(<GXC_FILE>)
  {
    chop;

    if (length($_) == 0)
    {
      $status = $NO_STATUS;

      my $exec_str = "count_kmers.pl $stab_file -k $k -t $T -p $P -g tmp.$r -c $counts_file -s $first_nucleatide -e $last_nucleatide";

      print STDERR "$exec_str\n";

      system("$exec_str");

      print "\n";
    }
    elsif ($_ =~ /Cluster[\s]([0-9]+)/)
    {
      open(OUTFILE, ">tmp.$r");

      print "Cluster $1\n";
      print "============\n";

      $status = $INSIDE_CLUSTER_STATUS;
    }
    elsif ($_ =~ /=========/ && $status == $INSIDE_CLUSTER_STATUS)
    {
      $status = $INSIDE_ATTRIBUTES_STATUS;
    }
    elsif ($_ =~ /=========/ && $status == $INSIDE_ATTRIBUTES_STATUS)
    {
      $status = $INSIDE_ORF_STATUS;
    }

    if ($status == $INSIDE_ORF_STATUS && $_ !~ /=========/)
    {
      my @row = split(/\t/);

      print OUTFILE "$row[0]\n";
    }
  }

  system("rm tmp.$r");
}

#--------------------------------------------------------------------------------
# STDIN
#--------------------------------------------------------------------------------
if (length($ARGV[1]) > 0)
{
  my %args = load_args(\@ARGV);

  gx2kmers($ARGV[0],
	   get_arg("k", 7, \%args),
	   $ARGV[1],
	   get_arg("t", 1, \%args),
	   get_arg("p", 0, \%args),
	   get_arg("c", $GK_NULL, \%args),
	   get_arg("s", 0, \%args),
	   get_arg("e", $LAST_NUCLEATIDE, \%args));
}
else
{
  print STDOUT <DATA>;
}

__DATA__

syntax: gxc2kmers.pl GXC_FILE STAB_FILE

  -k K: the kmer to search for (default is 7)
  -t T: output kmers that have more than T appearances in all ORFs (default is 1)
  -p P: output kmers that have more than P percent appearances in all ORFs (default is 0)
  -c counts_file: print these counts next to each key
  -s position: start position of the promoter region within each promoter (default is 0)
  -e position: end position of the promoter region within each promoter (default is the last nucleatide)


