#!/usr/local/bin/perl

##############################################################################
##############################################################################
##
## get_upstream.pl
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
                , [    '-b', 'scalar',  -100, undef]
                , [    '-e', 'scalar',    -1, undef]
                , ['--file',   'list',    [], undef]
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
my $beg_rel = $args{'-b'};
my $end_rel = $args{'-e'};
my @files   = @{$args{'--file'}};

if($beg_rel > 0) {
   $beg_rel--;
}
else {
   # $beg_rel++;
}

if($end_rel > 0) {
   $end_rel--;
}
else {
   # $end_rel++;
}

scalar(@files) == 2 or die("Please supply a SEQUENCE and COORDINATES file.");

my $genome = &getFastaSeqs($files[0]);

open(COORD, $files[1]) or die("Could not open the COORDINATES file for reading.");

while(<COORD>) {
   my @x = split($delim);
   chomp($x[$#x]);
   if(scalar(@x) == 5) {
      my ($gene, $chrom, $strand, $beg_gene, $end_gene) = @x;
      if($strand eq '-') {
         $beg_gene = $end_gene;
      }
      if(exists($$genome{$chrom})) {
         my $chrom_seq = $$genome{$chrom};
         if(defined($chrom_seq)) {
            $beg_gene--;
            my $beg = $strand eq '+' ? $beg_gene + $beg_rel : $beg_gene - $beg_rel;
            my $end = $strand eq '+' ? $beg_gene + $end_rel : $beg_gene - $end_rel;
            my $len = $strand eq '+' ? $end - $beg + 1 : $beg - $end + 1;
            my $seq = substr($chrom_seq, ($strand eq '+' ? $beg : $end), $len);
            if($strand eq '-') {
               $seq = reverse($seq);
               $seq =~ tr/AaCcGgTtUu/TtGgCcAaAa/;
            }
            print ">$gene\n$seq\n";
         }
      }
   }
   else {
   }
}
close(COORD);

exit(0);

sub getFastaSeqs {
   my ($fileName) = @_;
   my $filep;
   open($filep, $fileName) or die("Could not open file '$fileName' for reading");
   my %seqs;
   my $id="";
   my $seq="";
   while(<$filep>)
   {
     chomp;
     if(/\S/)
     {
       if(/^\s*>\s*(\S+)/)
       {
         my $first_head = $1;
         if(length($id)>0) {
            $seqs{$id} = $seq;
         }
         $id = $first_head;
         $seq = "";
       }
       else
       {
         s/\s//g;
         $seq .= $_;
       }
     }
  }
  if(length($id) > 0) {
     $seqs{$id} = $seq;
  }
  close($filep);
  return \%seqs;
}
__DATA__
syntax: get_upstream.pl [OPTIONS]

OPTIONS are:

-q: Quiet mode (default is verbose)

-k COL: Compare the values in column COL to the threshold in the file (default is 1).

-d DELIM: Set the field delimiter to DELIM (default is tab).



