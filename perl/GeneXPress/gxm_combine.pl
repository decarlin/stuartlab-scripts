#!/usr/bin/perl

use strict;

if ($ARGV[0] eq "--help")
{
  print STDOUT <DATA>;
  exit;
}

my %motifs;
my $str = "";
my $motif = "";
my $duplicate_counter = 1;
while(<STDIN>)
{
  chop;

  if (/\<Motif[\s].*Name=\"([^\"]+)\"/)
  {
    $motif = $1;
    $str = "$_\n";
  }
  elsif (/<\/Motif>/)
  {
    $str .= "$_\n";

    if (length($motifs{$motif}) > 0)
    {
      $motif .= "-$duplicate_counter";
      $duplicate_counter++;
    }

    $motifs{$motif} = $str;
    $motif = "";
  }
  elsif ($motif ne "")
  {
    $str .= "$_\n";
  }
}

my @sorted_motifs;
foreach my $key (keys %motifs)
{
  push(@sorted_motifs, $key);
}

@sorted_motifs = sort @sorted_motifs;

print "<?xml version=\"1.0\" encoding=\"iso-8859-1\"?>\n";
print "<Motifs SeqFile=\"yeast_proms.fasta\">\n";
foreach my $key (@sorted_motifs)
{
  print "$motifs{$key}";
}
print "</Motifs>\n";

__DATA__

gxm_combine.pl

Combines all the standard input into one gxm file. For example, "cat *.gxm | gxm_combine.pl"
should combine all the gxm files in the current directory.


