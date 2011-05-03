#!/usr/bin/perl

##############################################################################
##############################################################################
##
## check_cluster_cleanup.pl
##
##############################################################################
##############################################################################
##
## Written by Josh Stuart in the lab of Stuart Kim, Stanford University.
##
##  Email address: jstuart@stanford.edu
##          Phone: (650) 725-7612
##
## Postal address: Department of Developmental Biology
##                 Beckman Center Room B314
##                 279 Campus Dr.
##                 Stanford, CA 94305
##
##       Web site: http://www.smi.stanford.edu/people/stuart
##
##############################################################################
##############################################################################
##
## Written: 00/00/02
## Updated: 00/00/02
##
##############################################################################
##############################################################################

use strict;

require "$ENV{MYPERLDIR}/lib/libfile.pl";


use strict;

my $verbose = 1;
my $col     = 1;
my $delim   = "\t";
my @files;

while(@ARGV)
{
   my $arg = shift @ARGV;
   if($arg eq '--help')
   {
      print STDOUT <DATA>;
      exit(0);
   }
   elsif(-f $arg)
   {
      push(@files, $arg);
   }
   elsif($arg eq '-q')
   {
      $verbose = 0;
   }
   elsif($arg eq '-k')
   {
      $col = int(shift @ARGV);
   }
   elsif($arg eq '-d')
   {
      $delim = shift @ARGV;
   }
   else
   {
      die("Invalid argument '$arg'");
   }
}

$col--;

if($#files == -1)
{
   push(@files,'-');
}

foreach my $file (@files)
{
   my $filep;
   open($filep, $file) or die("Could not open file '$file' for reading");
   while(<$filep>)
   {
      my @tuple = split($delim, $_);
      chomp($tuple[$#tuple]);
      my $item  = $tuple[$col];
   }
   close($filep);
}

exit(0);


__DATA__
syntax: SCRIPT.pl [OPTIONS]

OPTIONS are:

-q: Quiet mode (default is verbose)

-k COL: Compare the values in column COL to the threshold in the file (default is 1).

-d DELIM: Set the field delimiter to DELIM (default is tab).


