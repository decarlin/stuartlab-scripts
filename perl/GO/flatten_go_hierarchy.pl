#!/usr/bin/perl

use strict;

require "$ENV{MYPERLDIR}/lib/bio_str.pl";

open (OUTFILE, ">go.hierarchy.flat");

#-------------------------------------------------------------------------------------
#
#-------------------------------------------------------------------------------------
sub find_stack_location (\@$$)
{
  my ($stack_str, $stack_size, $num_spaces) = @_;
  my @org_stack = @$stack_str;

  my $stack_location = 0;

  for (my $i = 0; $i < $stack_size; $i++)
  {
    if ($org_stack[$i] < $num_spaces)
    {
      $stack_location++;
    }
    else
    {
      last;
    }
  }

  return $stack_location;
}

#-------------------------------------------------------------------------------------
#
#-------------------------------------------------------------------------------------
sub FlattenHierarchyFile
{
  my $infile = $_[0];

  open (INFILE, "<$infile") or die "Can't open $infile.\n";

  my @num_stack;
  my @go_stack;
  my $stack_size = 0;

  while(<INFILE>)
  {
    chop;

    my $num_spaces = count_leading_spaces($_);

    my $stack_location = find_stack_location(@num_stack, $stack_size, $num_spaces);

    my $prev_on_stack  = "";
    for (my $i = 0; $i < $stack_location; $i++)
    {
      $prev_on_stack .= $go_stack[$i];
    }

    my @row = split(/[\%\<]/);

    my $go_str = "";

    for (my $i = 0; $i < @row; $i++)
    {
      my @go_row = split(/\;/, $row[$i]);

      my @go_ids = split(/\,/, $go_row[1]);

      for (my $j = 0; $j < @go_ids; $j++)
      {
	if ($go_ids[$j] =~ /(GO[\:][0-9]+)/)
	{
	  $go_str .= trim_end_spaces($go_ids[$j]) . "\t";

	  print OUTFILE $prev_on_stack;
	  print OUTFILE $go_ids[$j];
	  print OUTFILE "\n";
	}
      }
    }

    $stack_size = $stack_location + 1;

    $num_stack[$stack_location] = $num_spaces;

    $go_stack[$stack_location] = $go_str;
  }
}

FlattenHierarchyFile("process.ontology");
FlattenHierarchyFile("function.ontology");
FlattenHierarchyFile("component.ontology");
