#!/usr/bin/perl

use strict;
require "$ENV{MYPERLDIR}/lib/libfile.pl";

my $path_file = "$ENV{MYPERLDIR}/lib/frog_directories.txt";
if($#ARGV==0)
{
  $path_file = $ARGV[0];
}

if (length($path_file) > 0)
{
  open(PATHS, $path_file) or die("Could not open the path list $path_file");
  while(<PATHS>)
  {
    if(/\S/)
    {
      chop;

      if ($_ =~ /(.*)\/src$/)
      {
	my $from_file = "$ENV{MYPERLDIR}/lib/$_";
	my $to_file = "/fiery/u3/frog/current/$1";

	if (!(-e $to_file))
	{
	  print ("ln -s $from_file $to_file\n");
	  `ln -s $from_file $to_file\n`;
	}
      }
    }
  }
}
