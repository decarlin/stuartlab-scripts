#!/usr/local/bin/perl

##############################################################################
##############################################################################
##
## bed_overlap.pl
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
my @files   = @{$args{'--file'}};

scalar(@files) == 2 or die("Please supply both a SOURCE and TARGET bed-formatted files.");

# Read in the target coordinates.
my %target_coords;
my $filep;
open($filep, $files[1]) or die("Could not open target file '$files[1]' for reading");
while(<$filep>)
{
   my @x = split($delim, $_);
   chomp($x[$#x]);
   my $key  = splice(@x,$col,1);
   $target_coords{$key} = \@x;
}
close($filep);

# Map the source id's to the target coordinates.
open($filep, $files[0]) or die("Could not open source file '$files[0]' for reading");
while(<$filep>) {
   my @x = split($delim, $_);
   chomp($x[$#x]);
   my $source_key = splice(@x,$col,1);
   my $target_key = &findLargestContainingSegment(\@x,\%target_coords);
   if(defined($target_key)) {
      print "$source_key\t$target_key\n";
   }
}
close($filep);

exit(0);

sub findLargestContainingSegment {
   my ($source_pos, $segments) = @_;
   my ($src_chr, $src_strand, $src_start, $src_end) = @{$source_pos};
   my $max_len = undef;
   my $max_seg = undef;
   foreach my $tgt_key (keys(%{$segments})) {
      my ($tgt_chr, $tgt_strand, $tgt_start, $tgt_end) = @{$$segments{$tgt_key}};
      if($tgt_chr eq $src_chr and $tgt_strand eq $src_strand and
         &isContainedInside($src_start, $src_end, $tgt_start, $tgt_end)) {
	 my $len = $tgt_end - $tgt_start + 1;
         if(not(defined($max_len)) or ($len > $max_len)) {
	    $max_seg = $tgt_key;
	 }
      }
   }
   return $max_seg;
}

sub isContainedInside {
   my ($small_start,$small_end,$big_start,$big_end) = @_;
   if($small_start >= $big_start and $small_start <= $big_end) {
      if($small_end >= $big_start and $small_end <= $big_end) {
	 return 1;
      }
   }
   return 0;
}


__DATA__
syntax: bed_overlap.pl [OPTIONS]

OPTIONS are:

-q: Quiet mode (default is verbose)

-k COL: Compare the values in column COL to the threshold in the file (default is 1).

-d DELIM: Set the field delimiter to DELIM (default is tab).



