#!/usr/bin/perl

##############################################################################
##############################################################################
##
## parse_unigene.pl
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

use strict;
use warnings;

# Flush output to STDOUT immediately.
$| = 1;

my @flags   = (
                  [    '-q', 'scalar',         0,     1]
                , [    '-t', 'scalar',     undef, undef]
                , [    '-a', 'scalar', 'genbank', undef]
                , ['--file', 'scalar',       '-', undef]
              );

my %args = %{&parseArgs(\@ARGV, \@flags)};

if(exists($args{'--help'}))
{
   print STDOUT <DATA>;
   exit(0);
}

my $verbose    = not($args{'-q'});
my $accessions = $args{'-a'};
my $type       = $args{'-t'};
my $file       = $args{'--file'};

my $filep = &openFile($file);

my $locuslink;

my $unigene;

while(<$filep>)
{
   if(/^ID\s+(\S.*)\s*$/i)
   {
      $unigene = $1;
   }

   elsif(/^LOCUSLINK\s+(\S+)/)
   {
      $locuslink = $1;

      if($accessions =~ /unigene/i)
      {
         print STDOUT "$locuslink\t$unigene\n";
      }
   }

   elsif(($accessions =~ /genbank/i) and (/^SEQUENCE\s+ACC=([^\.]+)/))
   {
      my $genbank = $1;

      if(/SEQTYPE=(\S+)/)
      {
         my $seqtype = $1;

         if(not(defined($type)) or ($seqtype eq $type))
         {
            if(defined($locuslink))
            {
               print STDOUT "$locuslink\t$genbank\n";
            }
         }
      }
   }

   elsif(/^\/\//)
   {
      $locuslink = undef;

      $unigene   = undef;
   }
}
close($filep);

exit(0);


__DATA__
syntax: parse_unigene.pl [OPTIONS] [FILE | < FILE]

OPTIONS are:

-q: Quiet mode (default is verbose)

-a ACCESSIONS Specify which accessions to read.  Default=genbank.  Allowed are:

                     genbank, unigene

-t TYPE: Only process sequences of type TYPE (default is all sequences).  For
         example TYPE=EST will get only EST sequences; mRNA will retreive
         only mRNA sequences etc.,


