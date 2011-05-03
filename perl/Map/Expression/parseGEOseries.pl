#!/usr/local/bin/perl

##############################################################################
##############################################################################
##
## parseGEOseries.pl
##
##############################################################################
##############################################################################
##
## Author: Daniel Sam
## Date:
##
## Josh Stuart Lab, BME, UCSC
##
## Overview:
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

my %sample_hs = ();
my $sample;

my $filep;
open($filep, $file) or die("Could not open file '$file' for reading");
while(my $line = <$filep>) {
   chomp($line);

   if($line =~ /^\^SAMPLE = (GSM\d+)/) {
      $sample = $1;
   }
   elsif($line =~ /^\!(Sample_\w+)\s+=\s+(.*)/) {
      if(defined($sample_hs{$sample}{$1})) { 
         $sample_hs{$sample}{$1} = $sample_hs{$sample}{$1} . " ; " . $2;
      }
      else {
	 $sample_hs{$sample}{$1} = $2;
      }
   }
}
close($filep);

foreach my $s (keys %sample_hs) {
   foreach my $attributes (sort keys %{$sample_hs{$s}}) {
      if($attributes =~ /Sample_geo_accession/ or
         $attributes =~ /Sample_title/ or
         $attributes =~ /Sample_type/ or
         $attributes =~ /Sample_channel_count/ or
         $attributes =~ /Sample_source_name/ or
         $attributes =~ /Sample_organism/ or
         $attributes =~ /Sample_characteristics/ or
         $attributes =~ /Sample_description/ or
         $attributes =~ /Sample_platform_id/) {
        print $s, "\t", $attributes, "\t", $sample_hs{$s}{$attributes}, "\n";
     }
   }
}

exit(0);

__DATA__
syntax: .pl [OPTIONS]

OPTIONS are:

-q: Quiet mode (default is verbose)

-k COL: Set the key column to COL (default is 1).

-d DELIM: Set the field delimiter to DELIM (default is tab).



