#!/usr/bin/perl

use strict;

while(<STDIN>)
{
  # Change call to ld to a call to ar:
  my $old = 'ld\s+\$\(LD_FLAGS\)\s\$\(OBJS\)\s+-o\s+\$\(LIB\)';
  my $new = 'ar r $(LIB) $(OBJS)';
  s/$old/$new/;

  # Change *all* *.so suffixes to *.a suffixes!
  s/\.so([\s\n])/.a\1/g;
  s/\.so$/.a/;
  print;
}
