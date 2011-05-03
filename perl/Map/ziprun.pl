#!/usr/bin/perl

use strict;

require "$ENV{MYPERLDIR}/lib/libmap.pl";

my $run_dir = &getMapDir('Run');

my $archive = &getMapDir('Backup') . '/bio_run.zip';

my $files = `cd $run_dir; find . -name "Makefile*" -print`;

$files .= `cd $run_dir; find . -name "genelist*" -print`;

$files .= `cd $run_dir; find . -name "README*" -print`;

$files .= `cd $run_dir; find . -name "*.xml" -print`;

print STDERR "$files\n";

`cd $run_dir; echo '$files' | zip $archive -@`;

