#!/usr/bin/perl

use strict;

require "$ENV{MYPERLDIR}/lib/libmap_worm.pl";

my $fin = \*STDIN;
my $col = 1;
my $delim = "\t";
while(@ARGV)
{
  my $arg = shift @ARGV;
  if($arg eq '--help')
  {
    print STDOUT <DATA>;
    exit(0);
  }
  elsif($arg eq '-f')
  {
    $col = int(shift @ARGV);
  }
  elsif($arg eq '-d')
  {
    $delim = shift @ARGV;
  }
  elsif(-f $arg)
  {
    open($fin,$arg) or die("Could not open file '$arg' for reading.");
  }
  else
  {
    die("Bad argument '$arg' given.");
  }
}
$col--;

while(<$fin>)
{
  if(/\S/)
  {
    chomp;

    my @tuple = split($delim);
    my $key = $tuple[$col];
    $key = &formatWormbaseCloneId($key);
    $tuple[$col] = $key;

    print join($delim,@tuple), "\n";
  }
}

exit(0);

__DATA__
syntax: format_wormbase_clone_id.pl [OPTIONS] < TABFILE

Format's the Id's in the first column to meet MAP specifications

OPTIONS are:

-f N: extract key from column N (default is 1).
-d DELIM: set the delimiter to DELIM (default is <tab>).
