#!/usr/bin/perl

use strict;

require "$ENV{MYPERLDIR}/lib/load_args.pl";

my $egs_null = "__EGS__NULL__";

if ($ARGV[0] eq "--help")
{
  print <DATA>;
  exit;
}

#--------------------------------------------------------------------------------
#
#--------------------------------------------------------------------------------
sub extract_go_subsets
{
  my ($annotations_file, $go_file) = @_;

  if ($annotations_file ne $egs_null)
  {
    my %selected_annotations;
    open(ANNOTATIONS_FILE, "<$annotations_file");
    while(<ANNOTATIONS_FILE>)
    {
      chop;
      $selected_annotations{$_} = "1";
    }

    open(GO_FILE, "<$go_file");
    my $header_line = <GO_FILE>;
    chop $header_line;
    my @row = split(/\t/, $header_line);
    my %selected_columns;
    for (my $i = 0; $i < @row; $i++)
    {
      if ($selected_annotations{$row[$i]} eq "1") { $selected_columns{$i} = "1"; }
    }

    while(<GO_FILE>)
    {
      chop;

      my @row = split(/\t/);

      my $print_gene = 0;

      foreach my $key (keys %selected_columns)
      {
	if ($row[$key] eq "1") { $print_gene = 1; }
      }

      if ($print_gene) { print "$row[0]\n"; }
    }
  }
}

#--------------------------------------------------------------------------------
# STDIN
#--------------------------------------------------------------------------------
if (length($ARGV[1]) > 0)
{
  my %args = load_args(\@ARGV);

  extract_go_subsets(get_arg("f", $egs_null, \%args),
		     get_arg("g", "/u/erans/D/Biology/DATA/GO/yeast/yeast.go.dat", \%args));
}

__DATA__

Usage: extract_go_subsets.pl

     -f <file name>: extract the genes that have the annotations listed in the file
     -g <go file>:   the name of the go file to use (default is the go file for yeast)


