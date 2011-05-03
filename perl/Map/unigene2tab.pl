#!/usr/bin/perl

##############################################################################
##############################################################################
##
## unigene2tab.pl
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
my $col     = $args{'-k'};
my $delim   = $args{'-d'};
my $file    = $args{'--file'};

$col--;

my $filep;
open($filep, $file) or die("Could not open file '$file' for reading");
my $id   = undef;
my $data = undef;
while(<$filep>)
{
   if(/^\s*ID\s+(\S+)\s*$/)
   {
      &printInit($id, \$data);

      $id = $1;
   }
   elsif(/^\s*(\S+)\s+(\S.*)\s*$/)
   {
      $data .= $delim . "$1=$2";
   }
}
&printInit($id, \$data);

close($filep);

exit(0);

sub printInit
{
   my ($id, $data_ref) = @_;

   if(defined($id) and defined($$data_ref))
   {
      print STDOUT $id, $$data_ref, "\n";

      $$data_ref = '';
   }
}

__DATA__
syntax: unigene2tab.pl [OPTIONS]

OPTIONS are:

-q: Quiet mode (default is verbose)

-k COL: Compare the values in column COL to the threshold in the file (default is 1).

-d DELIM: Set the field delimiter to DELIM (default is tab).



