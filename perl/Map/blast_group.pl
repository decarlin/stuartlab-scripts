#!/usr/bin/perl

##############################################################################
##############################################################################
##
## blast_group.pl
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
require "$ENV{MYPERLDIR}/lib/libset.pl";
require "$ENV{MYPERLDIR}/lib/liblist.pl";

use strict;
use warnings;

# Flush output to STDOUT immediately.
$| = 1;


my @flags   = (
                  [    '-q', 'scalar',     1, undef]
                , [    '-h', 'scalar',     2, undef]
                , [    '-s', 'scalar',     3, undef]
                , [    '-r', 'scalar',     0,     1]
                , [    '-d', 'scalar',  "\t", undef]
              );

my %args = %{&parseArgs(\@ARGV, \@flags, 1)};

if(exists($args{'--help'}))
{
   print STDOUT <DATA>;
   exit(0);
}

my $query_col = $args{'-q'} - 1;
my $hit_col   = $args{'-h'} - 1;
my $score_col = $args{'-s'} - 1;
my $reverse   = $args{'-r'};
my $delim     = $args{'-d'};
my (@extra)   = @{$args{'--extra'}};

if(scalar(@extra) != 3)
{
   print STDOUT <DATA>;
   exit(1);
}

my ($query_file, $a2b_file, $b2a_file) = @extra;

my %queries = %{&setRead($query_file)};

# &setPrint(\%queries);

my $a2b = &readDataMatrix($a2b_file, $query_col, $delim, undef, \%queries);

&printDataMatrix($a2b);

exit(0);

__DATA__
syntax: blast_group.pl A_QUERY A2B B2A [OPTIONS]

Finds a set of genes in organism B that are similar to
each of the genes in the query from organism A.

OPTIONS are:

-q: Quiet mode (default is verbose)

-k COL: Compare the values in column COL to the threshold in the file (default is 1).

-d DELIM: Set the field delimiter to DELIM (default is tab).

-s SCORE_COL: Where the score is.

-r: Higher scores are more significant (default assumes lower scores are).

-q COL: The column the "query" is in in the BLAST results table.

-h COL: The column the "hit" is in in the BLAST results table.



