#!/usr/bin/perl

##############################################################################
##############################################################################
##
## parse_cogs.pl
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

my @flags   = (
                  [    '-q', 'scalar',     0,     1]
                , [    '-k', 'scalar',     1, undef]
                , [    '-d', 'scalar',  "\t", undef]
                , ['--file', 'scalar',   '-', undef]
              );

my %args = %{&parseArgs(\@ARGV, \@flags)};

if(exists($args{'--help'}))
{
   print STDOUT <DATA>;
   exit(0);
}

my $verbose = not($args{'-q'});
my $col     = int($args{'-k'}) - 1;
my $delim   = $args{'-d'};
my $file    = $args{'--file'};

my $filep;
open($filep, $file) or die("Could not open file '$file' for reading");
my $cog       = undef;
my $func_code = undef;
my $function  = undef;
my $organism  = undef;
my $protein   = undef;
while(<$filep>)
{
   if(/^\s*\[([^\]]+)\]\s+(COG\d+)\s+(.+)\s*$/)
   {
      $func_code = $1;
      $cog       = $2;
      $function  = $3;
   }
   elsif(/^\s*(\S+):\s*(\S.*)\s*$/)
   {
      $organism = $1;
      $protein  = $2;

      if(defined($cog))
      {
	 my @proteins = split(/\s/, $protein);

	 foreach my $pro (@proteins)
	 {
            print "$cog\t$pro\t$organism\t$func_code\t$function\n";
	 }
      }
   }
}
close($filep);

exit(0);


__DATA__
syntax: parse_cogs.pl [OPTIONS]

OPTIONS are:

-q: Quiet mode (default is verbose)

-k COL: Compare the values in column COL to the threshold in the file (default is 1).

-d DELIM: Set the field delimiter to DELIM (default is tab).



