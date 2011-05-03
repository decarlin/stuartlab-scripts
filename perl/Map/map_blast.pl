#!/usr/bin/perl

##############################################################################
##############################################################################
##
## map_blast.pl
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

require "$ENV{MYPERLDIR}/lib/libfile.pl";
require "$ENV{MYPERLDIR}/lib/libmap.pl";

use strict;
use warnings;

# Flush output to STDOUT immediately.
$| = 1;

my @flags   = (
                  [    '-q', 'scalar',       0,     1]
                 ,[    '-t', 'scalar',    './', undef]
                 ,[    '-p', 'scalar','blastp', undef]
                 ,[    '-o', 'scalar', 'Human', undef]
              );

my %args = %{&parseArgs(\@ARGV, \@flags, 1)};

if(exists($args{'--help'}))
{
   print STDOUT <DATA>;
   exit(0);
}

my $verbose  = not($args{'-q'});
my @extra    = @{$args{'--extra'}};
my $tmp_dir  = $args{'-t'};
my $program  = $args{'-p'};
my $organism = &getMapOrganismName($args{'-o'});
my $database = &getMapDir('DATA') . "/Blast/Protein/Db/$organism/data";
my $tmp_file = $tmp_dir . '/blast_' . time . '_' . int(rand(100000)) . '.tmp';

open(TMP, ">$tmp_file") or die("Could not open temporary file '$tmp_file'");

my $e = 0;
foreach my $entry (@extra)
{
   $e++;

   if((-f $entry) or (-l $entry) or ($entry eq '-'))
   {
      if(open(FILE, $entry))
      {
         while(<FILE>)
         {
            print TMP $_;
         }
      }
   }
   else
   {
      my $name = $e;
      print TMP ">$name\n$entry\n";
   }
}

close(TMP);

my $cmd = "blastall -p $program -d $database -i $tmp_file";

open(OUTPUT, "$cmd |") or die("Could not call blast");

while(<OUTPUT>)
{
   print;
}
close(OUTPUT);

system("rm -f $tmp_file");

exit(0);


__DATA__
syntax: map_blast.pl [OPTIONS] [FILE | < FILE] [QUERY1 QUERY2 ...]

OPTIONS are:

-q: Quiet mode (default is verbose)

-p PROGRAM: Set the blast program to PROGRAM (default is blastp).

-t DIR: The script creates one temporary file in the current directory.  You can
        reset where the temporary is made by changing the directory with this option.

-o ORGANISM: Set the organism to ORGANISM (default is Human).


