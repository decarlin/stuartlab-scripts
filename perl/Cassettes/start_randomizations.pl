#!/usr/bin/perl

use strict;

my $verbose = 1;

my $dir  = "$ENV{MYPERLDIR}/lib/Cassettes";
my $data = "$dir/test/worm.tab";

my @begs = (     3,     21,     41,     61,     81);
my @ends = (    20,     40,     60,     80,    100);
my @incs = (     1,      1,      1,      1,      1);
my @nums = (  1000,   1000,   1000,   1000,   1000);

while(@ARGV)
{
   my $arg = shift @ARGV;
   if($arg eq '--help')
   {
      print STDOUT <DATA>;
      exit(0);
   }
   elsif($arg eq '-q')
   {
      $verbose = 0;
   }
   else
   {
      die("Invalid argument '$arg'");
   }
}

my $command = '';
for(my $i = 0; $i <= $#begs; $i++)
{
   my ($beg, $end, $inc, $num) = ($begs[$i], $ends[$i], $incs[$i], $nums[$i]);

   my $outfile  = "r_$beg" . "_$end" . "_$inc" . "_$num.tab";

   $command    .= "cd $dir; ".
                  "mkdir -p random; " .
                  "random_cassettes.exe $data $beg $end $inc $num > random/$outfile & ";
}

$verbose and print STDERR "Issuing '$command'.\n";

`$command`;

exit(0);


__DATA__
syntax: start_randomizations.pl [OPTIONS]

OPTIONS are:

-q: Quiet mode (default is verbose)


