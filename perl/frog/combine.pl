#!/usr/bin/perl

use strict;

my $combined_lib_file = 'libALL.a';

if(-f $combined_lib_file)
  { system("rm $combined_lib_file"); }
while(@ARGV)
{
  my $arg = shift @ARGV;
  if($arg ne $combined_lib_file)
    { `ar x $arg`; }
}
system("ar q $combined_lib_file *.o");
