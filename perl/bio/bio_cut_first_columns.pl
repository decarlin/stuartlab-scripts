#! /usr/bin/perl

$file = $ARGV[0];
$drop_first_k_columns = 1;

open(INPUT_FILE, "<$file");

while (<INPUT_FILE>)
{
  chop;

  @row = split("\t");

  $length = @row;
  for ($i = $drop_first_k_columns; $i < $length; $i++)
  {
	print $row[$i] . "\t";
  }
  print "\n";
}
