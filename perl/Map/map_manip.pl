#!/usr/bin/perl

use strict;

require "$ENV{MYPERLDIR}/lib/load_args.pl";

my $null = "__NULL__";

if ($ARGV[0] eq "--help")
{
  print STDOUT <DATA>;
  exit(0);
}

my %args = load_args(\@ARGV);

my $tag = get_arg("tag", $null, \%args);
my @tags = split(/,/, $tag);
my $name = $tags[0];
my $value = $tags[1];

while(<STDIN>)
{
  chop;

  if (/$name=\"[^\"]+\"/)
  {
    s/$name=\"[^\"]+\"/$name="$value"/;
  }

  print $_ . "\n";
}

exit(0);

__DATA__
syntax: map_manip.pl

   -tag <name,value>: replaces all occurences of name="*" with name="value"

