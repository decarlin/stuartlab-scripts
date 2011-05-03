#!/usr/bin/perl

use strict;

require "$ENV{MYPERLDIR}/lib/bio_str.pl";

#----------------------------------------------------------------------
#
#----------------------------------------------------------------------
sub FlattenFile
{
  my $infile = $_[0];
  my $outfile = $_[1];

  open (INFILE, "<$infile") or die "Can't open $infile.\n";
  open (OUTFILE, ">$outfile");

  while(<INFILE>)
  {
    chop;

    my @row = split(/[\%\<]/);

    for (my $i = 0; $i < @row; $i++)
    {
      my @go_row = split(/\;/, $row[$i]);

      my @go_ids = split(/\,/, $go_row[1]);

      for (my $j = 0; $j < @go_ids; $j++)
      {
	if ($go_ids[$j] =~ /(GO[\:][0-9]+)/)
	{
	  my $str = trim_end_spaces($go_row[0]);
	  my $go_str = trim_end_spaces($go_ids[$j]);

	  print OUTFILE "$go_str\t$str\n";
	}
      }
    }
  }
}

FlattenFile("process.ontology", "process.ontology.flat");
FlattenFile("function.ontology", "function.ontology.flat");
FlattenFile("component.ontology", "component.ontology.flat");

