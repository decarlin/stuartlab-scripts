#!/usr/bin/perl

use strict;

require "$ENV{MYPERLDIR}/lib/load_args.pl";

if ($ARGV[0] eq "--help")
{
  print STDOUT <DATA>;
  exit;
}

my $links_file = $ARGV[0];
my %args = load_args(\@ARGV);

print "<ul>\n";

open(LINKS, "<$links_file");
while(<LINKS>)
{
  chop;

  my @row = split(/\t/);

  print "<li><A HREF=\"$row[0]\">$row[1]</A>\n";
}

print "</ul>\n";

__DATA__

create_links_section.pl <links file>

   Takes as input a two-column file with the actual link in one column and
   the name of the link in the other column and produces an HTML section
   that links to each of the links with its assigned name

