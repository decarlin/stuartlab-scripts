#!/usr/bin/perl

##############################################################################
##############################################################################
##
## parse_locuslink.pl
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

my $organism;

my @aliases;

while(<$filep>)
{
   if(/>>(\S+)/)
   {
      ($locuslink, $organism, $symbol, $name) =
         (  undef,     undef,   undef, undef);

      @aliases = ();
   }

   elsif(/^LOCUSID:\s*(\S+)/i)
   {
      $locuslink = $1;
   }

   elsif(/^ORGANISM:\s*(\S.*)\s*$/)
   {
      $organism = &getMapOrganismName($1);
   }

   elsif(/^OFFICIAL_SYMBOL:\s*(\S.*)\s*$/)
   {
      $symbol = &fixName($1);
   }

   elsif(/^OFFICIAL_GENE_NAME\s*(\S.*)\s*$/)
   {
      $name = &fixName($1);
   }

   elsif(/^ALIAS_SYMBOL\s*(\S.*)\s*$/)
   {
      push(@aliases, $1);
   }

   elsif(/^SUMMARY:\s*(\S.*)\s*$/)
   {
      $desc = $1;

      $desc =~ s/Summary://;

      $desc = &fixName($desc);
   }

}
close($filep);

exit(0);


sub fixName
{
   my ($name) = @_;

   $name =~ s/^\s+//;

   $name =~ s/\s+$//;

   $name =~ s/(\s)\s+/\1/g;

   return $name;
}

__DATA__
syntax: parse_locuslink.pl [OPTIONS] [FILE | < FILE]

OPTIONS are:

-q: Quiet mode (default is verbose)

-a ACCESSIONS Specify which accessions to read.  Default=genbank.  Allowed are:

                     genbank, unigene

-t TYPE: Only process sequences of type TYPE (default is all sequences).  For
         example TYPE=EST will get only EST sequences; mRNA will retreive
         only mRNA sequences etc.,


