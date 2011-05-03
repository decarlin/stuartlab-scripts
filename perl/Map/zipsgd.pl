#!/usr/bin/perl

use strict;

my $sgd_dir = "$ENV{HOME}/Sgd";
my $archive = "$ENV{MYPERLDIR}/lib/bio_sgd.zip";

my $files = `cd $sgd_dir; find . -name "Makefile*" -print`;

$files .= `cd $sgd_dir; find . -name "genelist*" -print`;

$files .= `cd $sgd_dir; find . -name "README*" -print`;

$files .= `cd $sgd_dir; find . -name "*.xml" -print`;

print STDERR "$files\n";

`cd $sgd_dir; echo '$files' | zip $archive -@`;

