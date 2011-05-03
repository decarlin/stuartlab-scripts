#!/usr/bin/perl

##############################################################################
##############################################################################
##
## parse_bioprospector.pl
##
##############################################################################
##############################################################################
##
## Written by Josh Stuart.
##
##  Email address: jstuart@ucsc.edu
##          Phone: (650) 725-7612
##
## Postal address: Department of Bioengineering, UCSC
##                 1156 High Street
##                 Santa Cruz, CA 95060
##
##       Web site: http://www.soe.ucsc.edu/~jstuart/
##
##############################################################################
##############################################################################

require "$ENV{MYPERLDIR}/lib/libfile.pl";

use strict;
use warnings;

# Flush output to STDOUT immediately.
$| = 1;


my @flags   = (
                  [    '-q', 'scalar',     0,     1]
                , [    '-k', 'scalar',     1, undef]
                , [    '-f', 'scalar',     1, undef]
                , [    '-d', 'scalar',  "\t", undef]
                , ['--file',   'list', ['-'], undef]
              );

my %args = %{&parseArgs(\@ARGV, \@flags)};

if(exists($args{'--help'}))
{
   print STDOUT <DATA>; exit(0);
}

my $verbose    = not($args{'-q'});
my $col        = int($args{'-k'}) - 1;
my $delim      = $args{'-d'};
my $print_file = $args{'-f'};
my $files      = $args{'--file'};

foreach my $file (@{$files})
{
   my $filep;
   open($filep, $file) or die("Could not open file '$file' for reading");
   my $motif  = undef;;
   my $num    = undef;
   my $segs   = undef;
   my $hits   = undef;
   my $pvalue = undef;
   my %genes;
   while(<$filep>)
   {
      # if(/^Motif\s+#(\d+):\s+\(([^\/])\)/)
      if(/^Motif\s+#(\d+):\s+\(([^\/]+)\/([^)]+)\)/)
      {
         $num   = $1;
         $motif = $2 lt $3 ? $2 : $3;
      }
      elsif(/^Width/)
      {
         if(/PValue\s(.+)\s*$/)
         {
            $pvalue = $1;
         }
         if(/Segments\s+(\d+)/)
         {
            $segs = $1;
         }
      }
      elsif(/^\s*([^\t]+)\tseg\s+\d+/)
      {
         $genes{$1} = 1;
      }
      elsif(/^[\*]+$/)
      {
         if(defined($pvalue))
         {
            my $ngenes = scalar(keys(%genes));

            if($print_file)
            {
               print STDOUT "$file\t";
            }

            print STDOUT "$num\t$ngenes\t$segs\t$motif\t$pvalue\n";

            $pvalue = undef;
            undef(%genes);
         }
      }
   }
   close($filep);
}

exit(0);

__DATA__
syntax: parse_bioprospector.pl [OPTIONS]

OPTIONS are:

-q: Quiet mode (default is verbose)

-k COL: Compare the values in column COL to the threshold in the file (default is 1).

-d DELIM: Set the field delimiter to DELIM (default is tab).

-f [0/1]: Print the file name (default is 1).


