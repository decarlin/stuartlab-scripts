#! /usr/bin/perl 

use strict;

my $in = 0;
my $str = "";

open(USERS, "</u/erans/wwwbio/genexpress/cgi_bin/registration/genexpress_users.dat");
while(<USERS>)
{
  chop;

  if (/-------/)
  {
    $in = 1;
  }
  elsif ($in >= 1 and $in <= 3)
  {
    print "$_\t";

    $in++; 

    if ($in == 4) { print "\n"; }
  }
}

