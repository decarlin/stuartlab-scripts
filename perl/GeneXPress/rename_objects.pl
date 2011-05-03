#!/usr/bin/perl

use strict;

require "$ENV{MYPERLDIR}/lib/load_args.pl";
require "$ENV{MYPERLDIR}/lib/libmap.pl";

if ($ARGV[0] eq "--help")
{
  print STDOUT <DATA>;
  exit;
}

my $gx_file = $ARGV[0];
my $mapping_file = $ARGV[1];

my %args = load_args(\@ARGV);

my $rename_experiments = get_arg("exps", 0, \%args);
my $old_key_column = get_arg("ok", 0, \%args);
my $new_key_column = get_arg("nk", 1, \%args);
my $descriptions = get_arg("descriptions", 0, \%args);

my %mapping;
open(MAPPING, "<$mapping_file");
while(<MAPPING>)
{
  chop;

  my @row = split(/\t/);

  $mapping{$row[$old_key_column]} = $row[$new_key_column];

  #print "mapping{$row[$old_key_column]} = $row[$new_key_column]\n";
}

open(GX_FILE, "<$gx_file");
my $in_objects = 0;
my $in_raw_data = 0;
while(<GX_FILE>)
{
  chop;

  if ($rename_experiments and /Objects[\s]Type=\"Experiments\"/) { $in_objects = 1; }
  if (!$rename_experiments and /Objects[\s]Type=\"Genes\"/) { $in_objects = 1; }
  if ($in_objects and /\<\/Objects\>/) { $in_objects = 0; }
  if (/\<TSCRawData/) { $in_raw_data = 1; }
  if (/\<\/TSCRawData\>/) { $in_raw_data = 0; }

  if ($in_objects == 1)
  {
    if ($rename_experiments and /([\s]+)\<Experiment[\s]Id=\"([^\"]+)\"[\s]name=\"([^\"]+)\"\>/)
    {
      my $indent = $1;
      my $id = $2;
      my $old_name = $3;
      my $new_name = $mapping{$old_name};
      if (length($new_name) == 0) { $new_name = $old_name; }

      #print "$old_name --> $new_name\n";

      print "${indent}<Experiment Id=\"$id\" name=\"$new_name\">\n";
    }
    elsif (!$rename_experiments and /([\s]+)\<Gene[\s]Id=\"([^\"]+)\"[\s]ORF=\"([^\"]+)\"(.*)/)
    {
      my $indent = $1;
      my $id = $2;
      my $old_name = $3;
      my $rest = $4;
      my $new_name = $mapping{$old_name};
      if (length($new_name) == 0) { $new_name = $old_name; }

      #print "$old_name --> $new_name\n";

      if ($descriptions == 0) { print "${indent}<Gene Id=\"$id\" ORF=\"$new_name\"$rest\n"; }
      elsif ($descriptions == 1) { print "${indent}<Gene Id=\"$id\" ORF=\"$old_name\"$rest\n"; }
    }
    else { print "$_\n"; }
  }
  elsif ($in_raw_data == 1 and !/TSCRawData/)
  {
    if ($rename_experiments)
    {
      my @row = split(/\t/);

      print "$row[0]\t$row[1]\t$row[2]\t";

      for (my $i = 3; $i < @row; $i++)
      {
	my $old_name = $row[$i];
	my $new_name = $mapping{$old_name};
	if (length($new_name) == 0) { $new_name = $old_name; }

	print "$new_name\t";
      }
      print "\n";

      $in_raw_data = 0;
    }
    elsif (!$rename_experiments)
    {
      my @row = split(/\t/, $_, 3);

      my $old_name = $row[0];
      my $new_name = $mapping{$old_name};

      if ($descriptions == 0)
      {
	if (length($new_name) == 0) { $new_name = $old_name; }
	print "$new_name\t$row[1]\t$row[2]\n";
      }
      elsif ($descriptions == 1)
      {
	if (length($new_name) == 0) { $new_name = $row[1]; }
	print "$row[0]\t" . &removeIllegalXMLChars($new_name) . "\t$row[2]\n";
	#print "$row[0]\t" . "$row[0] - AAA" . "\t$row[2]\n";
      }
    }
    else { print "$_\n"; }
  }
  else { print "$_\n"; }

}

__DATA__

rename_objects.pl <gxp file> <mapping file>

   Rename names of genes or names of experiments where the mapping between
   the old names and the new ones are in the <mapping file>.

   -exps:         Renaming experiments (default is genes)
   -ok <num>:     Old names column in the mapping file (default 0)
   -nk <num>:     New names column in the mapping file (default 1)
   -descriptions: If specified, then in the case of genes we replace the gene's description and not the ORF

