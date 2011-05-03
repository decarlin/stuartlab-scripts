#!/usr/bin/perl

use strict;

require "$ENV{MYPERLDIR}/lib/load_args.pl";

if ($ARGV[0] eq "--help")
{
  print STDOUT <DATA>;
  exit;
}

my $data_file = $ARGV[0];
my $scheme_file = $ARGV[1];

my %args = load_args(\@ARGV);

my %categories;

open(SCHEME, "<$scheme_file");
while(<SCHEME>)
{
  chop;

  /^([^\s]+)[\s](.*)/;

  $categories{$1} = $2;
}

my %genes;
my %assignments;
open(DATA, "<$data_file");
while(<DATA>)
{
  chop;

  /^([^\s]+)[\s]+[\|]([^\|]+)[\|]/;

  my $gene = "\U$2";
  my $category = $1;

  $genes{$gene} = "1";

  #print STDERR "$gene --> $category\n";

  my $str = "";
  my @row = split(/\./, $category);
  for (my $i = 0; $i < @row; $i++)
  {
    if ($i > 0) { $str .= "."; }
    $str .= $row[$i];

    $assignments{$str}{$gene} = "1";

    #print STDERR "$gene --> $str\n";
  }
}

print "ORF\t";
foreach my $category (keys %categories)
{
  print "$categories{$category}\t";
}
print "\n";

foreach my $gene (keys %genes)
{
  print "$gene\t";
  foreach my $category (keys %categories)
  {
    if ($assignments{$category}{$gene} eq "1") { print "1\t"; } else { print "0\t"; }
  }
  print "\n";
}

__DATA__

parse_mips.pl <Data File> <Schema File>

   Produces a tab delimited file from the data and the schema where each
   gene is then associated with all the levels in the hierarchy to which
   it belongs (leaf and all internal nodes)
