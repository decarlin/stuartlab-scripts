#!/usr/bin/perl

require "$ENV{MYPERLDIR}/lib/libfile.pl";
require "$ENV{MYPERLDIR}/lib/libmap.pl";

use strict;

my $dir     = &getMapDir('root') . "/Sgd/Release/V1.0";

my $archive = 'sgd_release.zip';
my $files = '';
$files .= `cd $dir; find . -name "*.sgd" -print`;
print STDOUT "$files\n";
`cd $dir; echo '$files' | zip $archive -@`;

$archive = 'sgd_release_gifs.zip';
$files = '';
$files .= `cd $dir; find . -name "*.gif" -print`;
print STDOUT "$files\n";
`cd $dir; echo '$files' | zip $archive -@`;

