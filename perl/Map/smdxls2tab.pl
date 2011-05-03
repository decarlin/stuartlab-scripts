#!/usr/bin/perl

##############################################################################
##############################################################################
##
## smdxls2data.pl
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

# Flush output to STDOUT immediately.
$| = 1;

if($ARGV[0] eq '--help')
{
   print STDOUT <DATA>;
   exit(0);
}

scalar(@ARGV) == 4 or die("Please supply 4 arguments");

my $verbose = 1;
my $delim   = "\t";

my ($id_field, $gene_field, $data_field, $dir) = @ARGV;

my @files = &getAllFiles($dir);

my %data;

my @order;

my $num_genes = 0;

my $passify = 10000;

my $iter    = 0;

my @expts;

foreach my $file (@files)
{
   if($file =~ /\.xls$/)
   {
      my $filep     = &openFile($file);
      my ($expt_id, $expt_name, $id_col, $gene_col, $data_col) = &smdHeader($filep);
      if($id_col >= 0 and $data_col >= 0)
      {
         push(@expts, "$expt_id $expt_name");

         while(<$filep>)
         {
            my @tuple = split($delim);

            my $id  = $tuple[$id_col];

            my $gene  = $gene_col >= 0 ? $tuple[$gene_col] : '';

            if(not(exists($data{$id})))
            {
               $order[$num_genes] = $id;

               $data{$id} = $id . $delim . $gene;

               $num_genes++;
            }

         }
      }
      close($filep);

      print STDERR "Read gene names from file '$file' ($num_genes unique genes).\n";
   }
}

$verbose and print STDERR "$num_genes genes read.\n";

print STDOUT "UNIQID", $delim, "GENE", $delim, join($delim, @expts), "\n";

foreach my $file (@files)
{
   if($file =~ /\.xls$/)
   {
      my $filep     = &openFile($file);

      my ($expt_id, $expt_name, $id_col, $gene_col, $data_col) = &smdHeader($filep);

      my %x;

      if($id_col >= 0 and $data_col >= 0)
      {
         while(<$filep>)
         {
            my @tuple = split($delim);

            my $id  = $tuple[$id_col];

            my $gene  = $gene_col >= 0 ? $tuple[$gene_col] : '';

            if(not(exists($x{$id})))
            {
               my @vec;
               $x{$id} = \@vec;
            }

            push(@{$x{$id}}, $tuple[$data_col]);
         }
      }
      close($filep);

      foreach my $id (@order)
      {
         if(exists($x{$id}))
         {
            $data{$id} .= $delim . &aggregate($x{$id});
         }
         else
         {
            $data{$id} .= $delim;
         }
      }

      print STDERR "Got data from file '$file'.\n";
   }
}

foreach my $id (@order)
{
   print STDOUT $data{$id}, "\n";
}

exit(0);

sub aggregate
{
   my ($list) = @_;

   my $num = 0.0;
   my $sum = 0.0;

   foreach my $x (@{$list})
   {
      if($x =~ /\d/)
      {
         $sum += $x;
         $num += 1.0;
      }
   }

   my $result = "";

   if($num > 0)
   {
      my $ave = $sum / $num;
      $result = "$ave";
   }

   return $result;
}

sub smdHeader
{
   my ($filep)   = @_;
   my $expt_name = 'no experiment name found';
   my $expt_id   = 'no experiment id found';
   my $id_col  = -1;
   my $gene_col  = -1;
   my $data_col  = -1;

   while(<$filep>)
   {
      if(/^!Exptid=(.*)$/)
      {
         $expt_id = $1;
      }
      elsif(/^!Experiment Name=(.*)$/)
      {
         $expt_name = $1;
      }
      elsif(/^SPOT/)
      {
         my @header = split($delim);

         for(my $i = 0; $i < scalar(@header); $i++)
         {
            if($header[$i] =~ /$id_field/i)
            {
               $id_col = $i;
            }
            elsif($header[$i] =~ /$gene_field/i)
            {
               $gene_col = $i;
            }
            elsif($header[$i] =~ /$data_field/i)
            {
               $data_col = $i;
            }
         }
         return ($expt_id, $expt_name, $id_col, $gene_col, $data_col);
      }
   }
}

__DATA__
syntax: smdxls2data.pl GENE_FIELD DATA_FIELD DIR


