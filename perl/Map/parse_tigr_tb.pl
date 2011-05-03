#!/usr/bin/perl

$tigr_file = shift(@ARGV);

open(IN, "$tigr_file") || die "can't open $tigr_file";

while($line = <IN>) {
    if ($line=~/(Rv(\w|\d)+)\t([^\t]+)\t([^\t]+)\t/) {
         $rv = "\U$1";
         $mainrole = $3;
         $subrole = $4;
         $mainrole=~s/\W+/_/g;
         $subrole=~s/\W+/_/g;
         print "$rv\t$mainrole\t$subrole\n";
    } else {
         #print "$line";
    }
}
