#!/usr/local/bin/perl

##############################################################################
##############################################################################
##
## parseGEOSeries_data.pl
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

my $gb_acc_index = undef; # index for gb_acc
my $entrezgene_index = undef;
my $unigene_index = undef;
my $gene_desc_index = undef;
my $platform_flag = 0;
my $platform_id = "";
my $sample_flag = 0;
my $sample_id = "";
my $sample_platform_id = undef;
my $sample_val_index = undef;

open(PLATFORM, ">", "platform.tmp");
open(SAMPLE, ">", "sample.tmp");

my $filep;
open($filep, $file) or die("Could not open file '$file' for reading");
while(my $line = <$filep>) {
   chomp($line);

   if($line =~/^\^PLATFORM = (GPL\d+)/) {
      $platform_id = $1;
      $platform_flag = 1;
      $gb_acc_index = undef;
      $entrezgene_index = undef;
      $unigene_index = undef;
      $gene_desc_index = undef;
   }
   elsif($line =~ /\!platform_table_end/) {
      $platform_flag = 0;
      $platform_id = "";
   }
   elsif($platform_flag and
         $line =~ /^[^#\!]/) {
      my @x = split($delim, $line,-1);
      if($line =~ /^ID/ or
         $line =~ /^ID_REF/) {
         for(my $i=0; $i<scalar @x; $i++) {
	    if($x[$i] eq 'GB_ACC' or
	       $x[$i] =~ /GB_accession/i or
	       $x[$i] =~ /GB_LIST/i or  # new
	       $x[$i] =~ /REFSEQ/i or
	       $x[$i] =~ /REFSEQ.?ID/i) {
	       $gb_acc_index = $i;
	       last;
	    }
	 }
	 if(!defined($gb_acc_index)) {
	    for(my $i=0; $i<scalar @x; $i++) {
	       if($x[$i] =~ /ENTREZ.?GENE/i or
	          $x[$i] =~ /ENTREZ.?GENE.?ID/i) {
	          $entrezgene_index = $i;
	          last;
	       }
	    }
         }
	 if(!defined($gb_acc_index) and
	    !defined($entrezgene_index)) {
            for(my $i=0; $i<scalar @x; $i++) {
	       if($x[$i] =~ /^UNIGENE$/i or
	          $x[$i] =~ /^UNIGENE.?ID/i or
	          $x[$i] =~ /^UNIGENE.?CLUSTER/i) {
	          $unigene_index = $i;
	          last;
	       }
	    }
	 }
	 if(!defined($gb_acc_index) and
	    !defined($entrezgene_index) and
	    !defined($unigene_index)) {
            for(my $i=0; $i<scalar @x; $i++) {
	       if($x[$i] =~ /^Gene.?Description$/i) {
	          $gene_desc_index = $i;
	          last;
	       }
	    }
	 }

      }
      elsif (defined($gb_acc_index)) {
	 my @gb = split(/[\/+,;]/,$x[$gb_acc_index]);
	 foreach my $gb_acc (@gb) {
	   $gb_acc =~ s/\.\d$//; # remove accession version
	   $gb_acc =~ s/^\s+//;  # remove beginning spaces
	   $gb_acc =~ s/\s+$//;  # remove ending spaces
	   print PLATFORM $platform_id, "\t", $x[0], "\t", $gb_acc, "\n";
         }
	 #$x[$gb_acc_index] =~ s/\.\d$//;
	 #print PLATFORM $platform_id, "\t", $x[0], "\t", $x[$gb_acc_index], "\n";
      }
      elsif (defined($entrezgene_index)) {
	 print PLATFORM $platform_id, "\t", $x[0], "\t", $x[$entrezgene_index], "\n";
      }
      elsif (defined($unigene_index)) {
	 $x[$unigene_index] = "Hs." . $x[$unigene_index] if $x[$unigene_index] =~ /^\d+$/;
	 print PLATFORM $platform_id, "\t", $x[0], "\t", $x[$unigene_index], "\n";
      }
      elsif (defined($gene_desc_index)) {
	 next if $x[$gene_desc_index] =~ /^\d+$/;
	 print PLATFORM $platform_id, "\t", $x[0], "\t", $x[$gene_desc_index], "\n";
      }
   }
   if($line =~ /^\^SAMPLE = (GSM\d+)/) {
      $sample_id = $1;
      $sample_flag = 1;
      $sample_val_index = undef;
      $sample_platform_id = undef;
   }
   elsif($sample_flag and 
         $line =~ /^\!sample_table_end/) {
      $sample_flag = 0;
      $sample_id = "";
   }
   elsif($sample_flag and
        $line =~ /^\!Sample_platform_id = (GPL\d+)/) {
	$sample_platform_id = $1;
   }
   elsif($sample_flag and
         $line =~ /^[^#\!]/) {
      my @x = split($delim, $line,-1);
      if($line =~ /^ID/ or
         $line =~ /^ID_REF/) {
         for(my $j=0; $j<scalar @x; $j++) {
	    if($x[$j] eq 'VALUE') {
	       $sample_val_index = $j;
	       last;
	    }
	 }
      }
      elsif ((defined($gb_acc_index) or defined($unigene_index) or defined($gene_desc_index) or defined($entrezgene_index)) and
             defined($sample_platform_id)) {
	 print SAMPLE $sample_platform_id, "\t", $x[0], "\t", $x[$sample_val_index], "\t", $sample_id, "\n";
      }
   }
}
close($filep);
close(PLATFORM);
close(SAMPLE);

exit(0);

__DATA__
syntax: .pl [OPTIONS]

OPTIONS are:

-q: Quiet mode (default is verbose)

-k COL: Set the key column to COL (default is 1).

-d DELIM: Set the field delimiter to DELIM (default is tab).



