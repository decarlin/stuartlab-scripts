#!/usr/bin/perl

require "$ENV{MYPERLDIR}/lib/libmap.pl";

my $makefile_template = &getMapDir('Templates') . '/Make/parent.mak';
my $pwd = "$ENV{PWD}";

system("ln -s $makefile_template $pwd/Makefile");

