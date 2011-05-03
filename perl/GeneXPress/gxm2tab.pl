#!/usr/bin/perl

use strict;

require "$ENV{MYPERLDIR}/lib/load_args.pl";

if ($ARGV[0] eq "--help")
{
  print STDOUT <DATA>;
  exit;
}

my $gxm_file = $ARGV[0];

my %args = load_args(\@ARGV);

my $motif_id = 0;

open(GXM_FILE, "<$gxm_file");
while(<GXM_FILE>)
{
  chop;

  if (/<Motif[\s]/ and /Consensus/)
  {
    /Consensus=\"([^\"]+)\"/;
    my $consensus = $1;

    /Source=\"([^\"]+)\"/;
    my $source = $1;

    /Name=\"([^\"]+)\"/;
    my $name = $1;

    print "$motif_id\t$source\t$consensus\t$name\n";
    $motif_id++;
  }
}

__DATA__

gxm2tab.pl <gxm file>

   Given a gxm file as input, outputs all the motifs along
   with their description in a flat tab delimited file

