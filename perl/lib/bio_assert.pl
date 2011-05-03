#! /usr/bin/perl

use strict;

sub assert
{
  my $assert_val = $_[0];

  if ($assert_val == 0)
  {
	 print "ASSERT FAILED: $_[1]\n";
	 exit;
  }
}

1
