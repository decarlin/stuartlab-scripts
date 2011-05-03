#!/usr/bin/perl

use strict;

require "$ENV{MYPERLDIR}/lib/libmap.pl";

my $data_dir = &getMapDir('Data');
my $archive = &getMapDir('Backup') . '/bio_data.zip';

my $files = `cd $data_dir; find . -name "Makefile*" -print`;

$files .= `cd $data_dir; find . -name "genelist*" -print`;

$files .= `cd $data_dir; find . -name "README*" -print`;

$files .= `cd $data_dir; find . -print | grep '\.pl'`;


print STDERR "$files\n";

`cd $data_dir; echo '$files' | zip $archive -@`;

