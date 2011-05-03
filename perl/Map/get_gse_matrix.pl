#!/usr/local/bin/perl

##############################################################################
##############################################################################
##
## skeleton.pl
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
my $file    = $args{'--file'};
my @extra   = @{$args{'--extra'}};

my $filep = &openFile($file);
my $begin = 0;
my $end   = 0;
while(<$filep>) {
   if(not($begin)) {
      if(/^!series_matrix_table_begin/) {
         $begin = 1;
      }
   }
   elsif(not($end)) {
      if(/^!series_matrix_table_end/) {
         $end = 1;
      }
      else {
         print;
      }
   }
}
close($filep);

exit(0);

__DATA__
syntax: skeleton.pl [OPTIONS]

OPTIONS are:

-q: Quiet mode (default is verbose)

-k COL: Set the key column to COL (default is 1).

-d DELIM: Set the field delimiter to DELIM (default is tab).



