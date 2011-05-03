#!/usr/bin/perl

use strict;

require "$ENV{MYPERLDIR}/lib/libmap.pl";

my $propagate_mak = &getMapDir('Templates') . '/Make/propagate.mak';
my $makefile = './Makefile';

my $cmd = "ln -s $propagate_mak $makefile";
print STDERR "$cmd";
system("$cmd");
print STDERR "\n";

