#!/usr/bin/perl

use strict;

my $fin = \*STDIN;

while(@ARGV)
{
  my $arg = shift @ARGV;
  if(-f $arg)
  {
    open($fin,$arg) or die("Could not open file '$arg' for reading.");
  }
}

while(<$fin>)
{
  s/\\t/\t/g;
  s/\\n/\n/g;
  print;
}

__DATA__
resolve_meta_strings.pl

