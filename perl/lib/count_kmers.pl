#!/usr/bin/perl

use strict;

require "$ENV{MYPERLDIR}/lib/load_args.pl";
require "$ENV{MYPERLDIR}/lib/libfile.pl";

my $CK_NULL = "__CK_NULL__";

my $LAST_NUCLEATIDE = -1;

#-----------------------------------------------------------------------------
#
#-----------------------------------------------------------------------------
sub load_gene_list
{
  my $file = $_[0];

  my %gene_list;

  open(GENE_LIST, "<$file");
  while(<GENE_LIST>)
  {
    chop;

    my @row = split(/\t/);

    $gene_list{$row[0]} = "1";
  }

  return %gene_list;
}

#-----------------------------------------------------------------------------
#
#-----------------------------------------------------------------------------
sub load_sequences (\%$$$)
{
  my ($gene_list_str, $stab_file, $first_nucleatide, $last_nucleatide) = @_;

  my %gene_list = %$gene_list_str;

  my @res;
  my $res_counter = 0;

  open(STAB, "<$stab_file");
  while(<STAB>)
  {
    chop;

    my @row = split(/\t/);

    if ($gene_list{$row[0]} eq "1")
    {
      my $first = $first_nucleatide;
      my $size;

      if ($last_nucleatide eq $LAST_NUCLEATIDE) { $size = length($row[1]) - $first; }
      else { $size = $last_nucleatide - $first + 1; }

      $res[$res_counter++] = substr($row[1], $first, $size);
    }
  }

  return @res;
}

#-----------------------------------------------------------------------------
#
#-----------------------------------------------------------------------------
sub count_kmers (\@$)
{
  my ($sequences_str, $k) = @_;

  my @sequences = @$sequences_str;
  my $num_sequences = @sequences;

  my @kmers;
  my $kmer_counter = 0;

  my %kmer2id;

  for (my $i = 0; $i < $num_sequences; $i++)
  {
    my $sequence_length = length($sequences[$i]);
    my $sequence = $sequences[$i];

    if ($i % 100 == 0)
    {
      print STDERR "Processing $i of $num_sequences\n";
    }

    my %local_kmers;

    for (my $j = 0; $j < $sequence_length - $k; $j++)
    {
      my $kmer = substr($sequence, $j, $k);

      if ($local_kmers{$kmer} ne "1")
      {
	$local_kmers{$kmer} = "1";

	if (length($kmer2id{$kmer}) == 0)
	{
	  $kmer2id{$kmer} = $kmer_counter;
	  $kmers[$kmer_counter] = 1;	
	  $kmer_counter++;
	  $kmers[$kmer_counter] = $kmer;
	  $kmer_counter++;
	}
	else
	{
	  $kmers[$kmer2id{$kmer}]++;
	}
      }
    }
  }

  return @kmers;
}

#-----------------------------------------------------------------------------
#
#-----------------------------------------------------------------------------
sub print_kmers (\@\%$$$)
{
  my ($kmer_counts_str, $global_counts_str, $threshold, $percent_threshold, $num_sequences) = @_;

  my @kmer_counts = @$kmer_counts_str;
  my %global_counts = %$global_counts_str;

  my $num_kmer_counts = @kmer_counts;
  $num_kmer_counts = $num_kmer_counts / 2;

  for (my $i = 0; $i < $num_kmer_counts; $i++)
  {
    my $counts = $kmer_counts[2 * $i];
    my $percent = format_number(100 * $counts / $num_sequences, 3);

    if ($i % 1000 == 0)
    {
      print STDERR "Printing $i of $num_kmer_counts\n";
    }

    if ($counts >= $threshold && $percent >= $percent_threshold)
    {
      my $global = $global_counts{$kmer_counts[(2 * $i) + 1]};
      $global = length($global) == 0 ? "" : "$global\t";
      my $global_percent = $global > 0 ? (format_number(100 * $counts / $global, 3) . "\t") : "";

      print $kmer_counts[(2 * $i) + 1] . "\t$counts\t$num_sequences\t$percent\t$global$global_percent\n";
    }
  }
}

#-----------------------------------------------------------------------------
#
#-----------------------------------------------------------------------------
sub load_counts_file
{
  my $file = $_[0];

  my %counts;

  if ($file ne "$CK_NULL")
  {
    open(COUNTS, "<$file");
    while(<COUNTS>)
    {
      chop;

      my @row = split(/\t/);

      $counts{$row[0]} = $row[1];
    }
  }

  return %counts;
}

#-----------------------------------------------------------------------------
# MAIN
#-----------------------------------------------------------------------------
if (length($ARGV[0]) > 0)
{
  my %args = load_args(\@ARGV);

  my %gene_list = load_gene_list(get_arg("g", $ARGV[0], \%args));
  print STDERR "Done Loading gene list...\n";

  my @sequences = load_sequences(%gene_list, $ARGV[0], get_arg("s", 0, \%args), get_arg("e", $LAST_NUCLEATIDE, \%args));
  my $num_sequences = @sequences;
  print STDERR "Done Loading sequences...\n";

  my @kmer_counts = count_kmers(@sequences, get_arg("k", 7, \%args));
  print STDERR "Done Counting kmers...\n";

  my %counts_file = load_counts_file(get_arg("c", "$CK_NULL", \%args));
  print STDERR "Done Loading Counts file...\n";

  print_kmers(@kmer_counts, %counts_file, get_arg("t", 1, \%args), get_arg("p", 0, \%args), $num_sequences);
  print STDERR "Done Printing kmers...\n";
}
else
{
  print STDOUT <DATA>;
}

__DATA__

syntax: count_kmers.pl STAB_FILE

  -k K: the kmer to search for (default is 7)
  -t T: output kmers that have more than T appearances in all ORFs (default is 1)
  -p P: output kmers that have more than P percent appearances in all ORFs (default is 0)
  -g gene_list: search only for ORFs contained in this file
  -c counts_file: print these counts next to each key
  -s position: start position of the promoter region within each promoter (default is 0)
  -e position: end position of the promoter region within each promoter (default is the last nucleatide)

