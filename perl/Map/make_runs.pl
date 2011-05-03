#!/usr/bin/perl

use strict;

require "$ENV{MYPERLDIR}/lib/libmap.pl";

my $runs_mak = &getMapDir('Templates') . '/Make/runs.mak';
my $makefile = './Makefile';

my $cmd = "ln -s $runs_mak $makefile";

print STDERR "$cmd";
system("$cmd");
print STDERR "\n";

