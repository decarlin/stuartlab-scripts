#!/usr/bin/perl

use strict;

my $verbose = 1;

my $dir  = "$ENV{MYPERLDIR}/lib/Cassettes";
my $data = "$dir/test/worm.tab";

# my @begs = (     3,      4,      5,      6,      7,      8,      9,     10);
# my @ends = (     3,      4,      5,      6,      7,      8,      9,     10);
# my @incs = (     1,      1,      1,      1,      1,      1,      1,      1);
# my @nums = ( 10000,  10000,  10000,  10000,  10000,  10000,  10000,  10000);

my @begs = (    16,     43,    100,   1000);
my @ends = (    16,     43,    100,   1000);
my @incs = (     1,      1,      1,      1);
my @nums = ( 10000,  10000,  10000,  10000);

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


