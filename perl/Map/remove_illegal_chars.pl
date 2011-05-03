#!/usr/bin/perl

use strict;

require "$ENV{MYPERLDIR}/lib/libmap.pl";
require "$ENV{MYPERLDIR}/lib/load_args.pl";

if ($ARGV[0] eq "--help")
{
  print STDOUT <DATA>;
  exit;
}

my %args = load_args(\@ARGV);

while(<STDIN>)
{
  print &removeIllegalXMLChars($_);
}

__DATA__

removeIllegalChars.pl

   Remove illegal characters from the file
