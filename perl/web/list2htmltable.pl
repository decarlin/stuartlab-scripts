#!/usr/bin/perl

use strict;

require "$ENV{MYPERLDIR}/lib/load_args.pl";

if ($ARGV[0] eq "--help")
{
  print STDOUT <DATA>;
  exit;
}

my $file = $ARGV[0];

my %args = load_args(\@ARGV);

my $body = get_arg("body", 0, \%args);

if ($body eq "1") { print "<html>\n<body>\n"; }

print "<table border=\"1\">\n";

open(FILE, "<$file") or die "could not open $file";
while(<FILE>)
{
  chop;

  my @row = split(/\t/);

  print "<tr>";
  for (my $i = 0; $i < @row; $i++)
  {
    print "<td>$row[$i]</td>";
  }
  print "</tr>\n";
}

print "</table>\n";

if ($body eq "1") { print "</body>\n</html>\n"; }



__DATA__

list2htmltable.pl <file>

   Takes in a tab delimited file and creates an html table from the list

   -body:         If specified, outputs the body of the html as well

