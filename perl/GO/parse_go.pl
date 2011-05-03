#!/usr/bin/perl

use strict;

if (length($ARGV[1]) == 0 && $ARGV[0] ne "GO")
{
  print <DATA>;
  exit;
}

if ($ARGV[0] eq "GO")
{
  system("flatten_go_files.pl");
  system("flatten_go_hierarchy.pl");
}
else
{
  my $r = int(rand(10000000));
  my $organism = "$ARGV[0]";
  system("parse_gene_associations.pl $ARGV[1] tmp.$r $ARGV[0]");
  #system("flatten_gene_associations.pl tmp.$r /u/erans/D/Biology/DATA/GO/$ARGV[0]/$ARGV[0].go.dat");
  #my $lower_case_organism = "\L$ARGV[0]";
  my $lower_case_organism = "$ARGV[0]";
  system("flatten_gene_associations.pl tmp.$r $ARGV[0]/$lower_case_organism.go.dat");
  system("rm tmp.$r");
}

__DATA__

Usage: parse_go.pl <organism name> <gene association file>

Note: if organism name is "GO" then we prepare the GO hierarchy itself

