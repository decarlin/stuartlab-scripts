#!/usr/bin/perl

use strict;

require "$ENV{MYPERLDIR}/lib/load_args.pl";

my $r = int(rand(10000));

if ($ARGV[0] eq "--help")
{
  print STDOUT <DATA>;
  exit;
}

my %args = load_args(\@ARGV);

my $search_str = $ARGV[0];

#my $files_str = `find . -name "$search_str"`;
my $files_str = `ls $search_str`;
my @files = split(/\n/, $files_str);
foreach my $file (@files)
{
  print "$file\n";

  my $in_map_html_include = 0;
  open(FILE, "<$file");
  open(OUTFILE, ">tmp.$r");
  while(<FILE>)
  {
    chop;

    if (/MAP_HTML_INCLUDE.*file=[\"]([^\"]+)[\"]/)
    {
      $in_map_html_include = 1;
      print OUTFILE "$_\n";

      open(INCLUDE_FILE, "<$1");
      while(<INCLUDE_FILE>)
      {
	print OUTFILE "$_";
      }
    }
    elsif (/<[\/]MAP_HTML_INCLUDE>/)
    {
      $in_map_html_include = 0;
      print OUTFILE "$_\n";
    }
    elsif ($in_map_html_include == 0)
    {
      print OUTFILE "$_\n";
    }
  }

  system("mv tmp.$r $file");
}


__DATA__

html_convert.pl <search string>

   Takes in a file search argument and converts each of the
   found files based on MAP HTML commands. Current commands are:
   <MAP_HTML_INCLUDE file="a"> --- replaces the text between the map include with contents of file "a"

