#!/usr/bin/perl

use strict;

my $eval_dir = "$ENV{HOME}/Eval";
my $archive = "$ENV{MYPERLDIR}/lib/bio_eval.zip";

my $files = `cd $eval_dir; find . -name "Makefile*" -print`;

$files .= `cd $eval_dir; find . -name "genelist*" -print`;

$files .= `cd $eval_dir; find . -name "README*" -print`;

$files .= `cd $eval_dir; find . -name "*.xml" -print`;

print STDERR "$files\n";

`cd $eval_dir; echo '$files' | zip $archive -@`;

