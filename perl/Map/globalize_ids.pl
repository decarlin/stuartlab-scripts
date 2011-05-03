#!/usr/bin/perl

use strict;

require "$ENV{MYPERLDIR}/lib/load_args.pl";

if ($ARGV[0] eq "--help")
{
  print STDOUT <DATA>;
  exit(0);
}

my @files;
my $start_copying = -1;
for (my $i = 0; $i < @ARGV; $i++)
{
  if ($start_copying >= 0) { $files[$start_copying++] = $ARGV[$i]; }
  elsif ($ARGV[$i] eq "-f") { $start_copying = 0; }
}

my %args = load_args(\@ARGV);

my $column = get_arg("c", 0, \%args);
my @tmp_columns = split(/\,/, $column);
my %columns;
for (my $i = 0; $i < @tmp_columns; $i++) { $columns{$tmp_columns[$i]} = "1"; }

my $globalize_factor = get_arg("g", 1000000, \%args);

my $id = $globalize_factor;
for (my $i = 0; $i < @files; $i++)
{
  chop;

  if (-e $files[$i])
  {
    #print "$files[$i]\n";

    open(INFILE, "<$files[$i]");
    while(<INFILE>)
    {
      chop;

      my @row = split(/\t/);
      for (my $j = 0; $j < @row; $j++)
      {
	my $new_id = $id + $row[$j];
	if ($columns{$j} eq "1") { print "$new_id\t"; }
	else { print "$row[$j]\t"; }
      }

      print "\n";
    }
  }

  $id += $globalize_factor;
}

exit(0);

__DATA__
syntax: globalize_ids.pl

  Puts ids into a global name space. You can pass several files and within each file
  specify several columns that will be globalized. The script will add a number
  (can be set by the -g option) to each of the specified columns in each file.
  This number will be incremented between files so that ids between files will not
  clash.

  -c <num1,num2>: column number to globalize
  -g <num>: globalize factor
  -f [file1 file2 ...]
