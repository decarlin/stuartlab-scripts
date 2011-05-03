#!/usr/bin/perl

use strict;

my $frog_dirs = "$ENV{MYPERLDIR}/lib/frog_directories.txt";

while(@ARGV)
{
  my $arg = shift @ARGV;
  if($arg eq '--help')
  {
    print STDOUT <DATA>;
    exit(0);
  }
}

if(-f $frog_dirs and open(DIRS,$frog_dirs))
{
  while(<DIRS>)
  {
    if(/\S/)
    {
      if(not(/\/src[\/]*\s*$/) and 
         not(/\/RCS[\/]*\s*$/))
      {
        print;
      }
    }
  }
  close(DIRS);
}

__DATA__
syntax: cygwin_directories.pl

Prints which directories to archive on the CygWin side (for FROG).
