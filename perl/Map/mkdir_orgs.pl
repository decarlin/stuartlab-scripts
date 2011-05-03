#!/usr/bin/perl

require "$ENV{MYPERLDIR}/lib/libmap.pl";

my $pwd = "$ENV{PWD}";

my @orgs = &getMapOrganismNames();

foreach my $org (@orgs)
{
  system("mkdir -p $org");
}

