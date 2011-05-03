#!/usr/bin/perl

open(FROG_DIRECTORIES, "<$ENV{HOME}/develop/perl/frog/frog_directories.txt");
while(<FROG_DIRECTORIES>)
{
  chop;

  if (/\S/ && !/src/ && !/RCS/)
  {
     print "cd $_; co Makefile; cd -\n";
     system("cd $_; co Makefile; cd -");
  }
}
