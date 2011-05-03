#!/usr/bin/perl

use strict;

require "$ENV{MYPERLDIR}/lib/load_args.pl";

if ($ARGV[0] eq "--help")
{
  print STDOUT <DATA>;
  exit;
}

my $gx_file = $ARGV[0];

my %args = load_args(\@ARGV);

my $keepnames = get_arg("keepnames", 0, \%args);

my $start_tsc_raw_data = `grep -n "<TSCRawData" $gx_file`;
$start_tsc_raw_data =~ /^([0-9]+)[\:]/;
$start_tsc_raw_data = $1 + 1;

my $end_tsc_raw_data = `grep -n "</TSCRawData" $gx_file`;
$end_tsc_raw_data =~ /^([0-9]+)[\:]/;
$end_tsc_raw_data = $1 - 1;

my $row_counter = 1;
open(GX_FILE, "<$gx_file") or die "Could not open GeneXPress file $gx_file\n";
while(<GX_FILE>)
{
  chop;

  if ($row_counter >= $start_tsc_raw_data and $row_counter <= $end_tsc_raw_data)
  {
    my @row = split(/\t/);

    for (my $i = 0; $i < @row; $i++)
    {
      if ($i == 0 or $i > 2) { print "$row[$i]\t"; }
      elsif ($i == 1 and $keepnames) { print "$row[$i]\t"; }
    }
    print "\n";
  }

  $row_counter++;
}


__DATA__

gx2microarray.pl <gx file>

Takes a GeneXPress file and extracts the microarray data
in a tab delimited format

   -keepnames:   Keeps the description of the genes in the outputted microarray

