#! /usr/bin/perl

use strict;

require "$ENV{MYPERLDIR}/lib/bio_sort_vec.pl";

my @a;

$a[0][0] = 3;
$a[0][1] = 2;
$a[0][2] = 1;

$a[1][0] = 1;
$a[1][1] = 3;
$a[1][2] = 0;

$a[2][0] = 2;
$a[2][1] = 1;
$a[2][2] = 2;

$a[3][0] = 0;
$a[3][1] = 0;
$a[3][2] = 3;

sort_vec(\@a, 3, 2, "numeric");

1
