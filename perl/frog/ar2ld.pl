#!/usr/bin/perl

use strict;

while(<STDIN>)
{
  # Change call to ar to a call to ld:
  my $old = 'ar\s+r\s+\$\(LIB\) \$\(OBJS\)';
  my $new = 'ld $(LD_FLAGS) $(OBJS) -o $(LIB)';
  s/$old/$new/;

  # Change all *.a suffixes to *.so suffixes!
  s/\.a([\s\n])/.so\1/g;
  s/\.a$/.so/;
  print;
}
