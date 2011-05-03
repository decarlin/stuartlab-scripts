#!/usr/local/bin/perl

##############################################################################
##############################################################################
##
## tab2report.pl
##
##############################################################################
##############################################################################
##
## Written by Josh Stuart.
##
##  Email address: jstuart@soe.ucsc.edu
##          Phone: (831) 459-1344
##
## Postal address: 1156 High Street, 308 Physical Sciences
##                 Mail Stop: SOE2
##                 Santa Cruz, CA 95064
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
                , [    '-h', 'scalar',     0, undef]
                , [    '-d', 'scalar',  "\t", undef]
                , ['--file', 'scalar',   '-', undef]
              );

my %args = %{&parseArgs(\@ARGV, \@flags, 1)};

if(exists($args{'--help'})) {
   print STDOUT <DATA>;
   exit(0);
}

my $verbose = not($args{'-q'});
my $col     = int($args{'-k'}) - 1;
my $delim   = &interpMetaChars($args{'-d'});
my $headers = int($args{'-h'});
my $file    = $args{'--file'};
my @extra   = @{$args{'--extra'}};

my ($tuples, $fields) = &tableRead($file, $delim, [$col], $headers);
my $n = scalar(@{$fields});

my $t = 0;
foreach my $tuple (@{$tuples}) {
   $t++;
   my $key = splice(@{$tuple},0,1);
   my $n_  = scalar(@{$tuple});
   $verbose and ($n_ != $n) and
      print STDERR "The number of entries ($n_) does not match the number of fields ($n) for tuple $t.\n";
   print STDOUT $key, "\n";
   for(my $i = 0; $i < $n; $i++) {
      my $lines = &breakText($$tuple[$i], 60, "\n\t\t");
      $lines = defined($lines) ? $lines : 'NaN';
      print STDOUT "\t$$fields[$i]\n\t\t$lines\n";
   }
}

exit(0);

__DATA__
syntax: skeleton.pl [OPTIONS]

OPTIONS are:

-q: Quiet mode (default is verbose)

-k COL: Compare the values in column COL to the threshold in the file (default is 1).

-d DELIM: Set the field delimiter to DELIM (default is tab).



