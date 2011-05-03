#!/usr/bin/perl

##############################################################################
##############################################################################
##
## libgeo.pl
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
## Utilities for manipulating Gene Expression Omnibus files.
##
##############################################################################
##############################################################################

require "$ENV{MYPERLDIR}/lib/libfile.pl";
require "$ENV{MYPERLDIR}/lib/libset.pl";
require "$ENV{MYPERLDIR}/lib/libfunc.pl";

use strict;
use warnings;

sub readGeoGdsHeader
{
   my ($filep, $id_field) = @_;

   my %desc;

   my @data_attribs;

   my $desc = '';

   my $done = 0;

   my $header_line = '';

   while(not($done))
   {
      if(eof($filep))
      {
         $done = 1;
      }
      else
      {
         my $line = <$filep>;

         chomp($line);

         if($line =~ /^\^(\S+)\s*=\s*(\S.*)\s*$/)
         {
            push(@data_attribs, "$1\t$2");
         }
         elsif($line =~ /^\s*#\s*(\S+)\s*=\s*(\S.*)\s*$/)
         {
            push(@data_attribs, "$1\t$2");
         }
         elsif($line =~ /^\!dataset_(\S+)\s*=\s*(\S.*)\s*$/)
         {
            push(@data_attribs, "$1\t$2");
         }
         elsif($line =~ /^\!subset_description\s*=\s*(\S.*)/)
         {
            $desc = $1;
         }
         elsif($line =~ /^\!subset_sample_id\s*=\s*(\S.*)/)
         {
            my $match = $1;

            $match =~ s/\s//g;

            my @gsms = split(",", $match);

            foreach my $gsm (@gsms)
            {
               if(not(exists($desc{$gsm})))
               {
                  $desc{$gsm} = [];
               }
               push(@{$desc{$gsm}}, $desc);
            }
         }
         elsif($line =~ /^ID_REF/)
         {
            $header_line = $line;

            $done = 1;
         }
      }
   }

   foreach my $gsm (keys(%desc))
   {
      $desc{$gsm} = join(";", @{$desc{$gsm}});
   }

   my @header = split("\t", $header_line);

   my $num_fields = scalar(@header);

   my $id_col = 0;

   my @data_cols;

   for(my $f = $num_fields - 1; $f >= 0; $f--)
   {
      $header[$f] =~ s/^\s+//;

      $header[$f] =~ s/\s+$//;

      if($header[$f] =~ /^$id_field$/)
      {
         $id_col = $f;
      }

      if($header[$f] =~ /^GSM\d+/)
      {
         unshift(@data_cols, $f);
      }
      else
      {
         splice(@header, $f, 1);
      }
   }

   for(my $i = 0; $i < scalar(@header); $i++)
   {
      my $gsm = $header[$i];

      $gsm =~ s/\s//g;

      $header[$i] = exists($desc{$gsm}) ? ($gsm . ';' . $desc{$gsm}) : $gsm;
   }

   return (\@header, $id_col, \@data_cols, \@data_attribs);
}

sub readGeoDataset
{
   my ($filep, $id2gene_list, $id_field) = @_;

   $id_field = defined($id_field) ? $id_field : 'ID_REF';

   my %data;

   my ($header, $id_col, $data_cols, $data_attribs) = &readGeoGdsHeader($filep, $id_field);
   print STDERR "data_cols=@{$data_cols}\n";
   my $max_cols = 0;

   while(my $line = <$filep>)
   {
      if(not(defined(&geoComment($line))))
      {
         my @tuple = split("\t", $line);

         chomp($tuple[$#tuple]);

         my $id = $tuple[$id_col];

         my @data;

         foreach my $i (@{$data_cols})
         {
            push(@data, $tuple[$i]);
         }

         if(scalar(@data) > $max_cols)
         {
            $max_cols = scalar(@data);
         }

         if(defined($id2gene_list))
         {
            my $found = 0;

            for(my $i = 0; $i < scalar(@{$id2gene_list}) and not($found); $i++)
            {
               my $id2gene = $$id2gene_list[$i];

               if(defined($id2gene) and exists($$id2gene{$id}))
               {
                  my $gene = $$id2gene{$id};

                  push(@{$data{$gene}}, \@data);

                  $found = 1;
               }
            }
         }
         else
         {
            push(@{$data{$id}}, \@data);
         }
      }
   }

   foreach my $gene (keys(%data))
   {
      $data{$gene} = &truncateNumber(&meanCols($data{$gene}, $max_cols), 3);
   }

   $data{'HEADER'} = $header;

   return (\%data, $data_attribs);
}

sub getGeoFamilySamples
{
   my ($filep, $id2gene, $id_field, $data_field) = @_;

   my %sample;

   my $title_line = &findLine($filep, ['Sample_title']);

   my $title = '';

   if($title_line =~ /Sample_title\s*=\s*(\S.+)\s*$/)
   {
      $title = $1;
   }

   my $header = &findLine($filep, [$id_field, $data_field], 'all');

   if(not(defined($header)))
   {
      return \%sample;
   }

   my @header = split("\t", $header);

   chomp($header[$#header]);

   my %header = %{&list2Set(\@header)};

   my $id_col = exists($header{$id_field}) ? $header{$id_field} : undef;

   my $data_col = exists($header{$data_field}) ? $header{$data_field} : undef;

   if(defined($id_col) and defined($data_col))
   {
      my $done = 0;

      while(not($done))
      {
         if(not(eof($filep)))
         {
            my $line = <$filep>;

            my $comment = &geoComment($line);

            if(defined($comment))
            {
               $done = 1;
            }
            else
            {
               my @tuple = split("\t", $line);

               chomp($tuple[$#tuple]);

               my $id   = $tuple[$id_col];

               if(exists($$id2gene{$id}))
               {
                  my $gene = $$id2gene{$id};

                  my $data = $tuple[$data_col];

                  if(defined($data))
                  {
                     $data = ($data =~ /error/i) ? 'NaN' : $data;

                     push(@{$sample{$gene}}, $data);
                  }
               }
            }
         }
         else
         {
            $done = 1;
         }
      }
   }

   foreach my $gene (keys(%sample))
   {
      my $vector = $sample{$gene};

      my $value;

      if(scalar(@{$vector}) > 1)
      {
         $value = &evalMean($vector);
      }
      else
      {
         $value = $vector;
      }
      $sample{$gene} = $value;
   }

   return (\%sample, $title);
}

sub getGeoPlatformAliases
{
   my ($file, $id_field, $gene_field) = @_;

   my $is_filename = ((-f $file) or (-l $file)) ? 1 : 0;

   my $filep       = $is_filename ? &openFile($file) : $file;

   my %genes;

   my $header = &findLine($filep, ["^$id_field", $gene_field], 'all');

   my @header = defined($header) ? split("\t", $header) : ();

   chomp($header[$#header]);

   my %header        = %{&list2Set(\@header)};

   my $id_col        = exists($header{$id_field}) ? $header{$id_field} : undef;

   my $gene_col      = exists($header{$gene_field}) ? $header{$gene_field} : undef;

   my $max_col       = $id_col > $gene_col ? $id_col : $gene_col;

   my $done          = 0;

   my $seen_platform = 0;

   while(not($done))
   {
      if(not(eof($filep)))
      {
         my $line = <$filep>;

         my $comment = &geoComment($line);

         if(defined($comment))
         {
            chomp($line);

            $done = 1;
         }
         else
         {
            chomp($line);

            my @tuple = split("\t", $line);

            if(scalar(@tuple) > $max_col)
            {
               my $id      = $tuple[$id_col];

               my $gene    = $tuple[$gene_col];

               $genes{$id} = $gene;
            }
         }
      }
      else
      {
         $done = 1;
      }
   }

   if($is_filename)
   {
      close($filep);
   }

   return \%genes;
}

sub geoComment
{
   my ($line) = @_;

   my $comment = undef;

   if (($line =~ /^\!(.+)$/) or
       ($line =~ /^\^(.+)$/) or
       ($line =~ /^#(.+)$/))
   {
      $comment = $1;
   }

   return $comment;
}

1
