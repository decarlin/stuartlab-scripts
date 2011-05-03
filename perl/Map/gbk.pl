#!/usr/bin/perl

##############################################################################
##############################################################################
##
## gbk.pl
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
                  [    '-q', 'scalar',      0,     1]
                , [    '-f', 'scalar',  undef, undef]
                , [    '-s', 'scalar',      0,     1]
                , ['--file', 'scalar',    '-', undef]
              );

my %args = %{&parseArgs(\@ARGV, \@flags)};

if(exists($args{'--help'}))
{
   print STDOUT <DATA>;
   exit(0);
}

my $verbose      = not($args{'-q'});
my $feature      = $args{'-f'};
my $print_sequence = $args{'-s'};
my $file         = $args{'--file'};

my $filep = &openFile($file);
my $seen_features_header = 0;
my $seen_origin_header = 0;
my $all_keys = {};
my @attribs;
my $seen_feature = 0;
my $attrib;
my $value;
my $five_prime = undef;
my $three_prime = undef;
my $printed = 0;
my $sequence = '';
while(<$filep>)
{
   if(/^\/\//)
   {
      if($seen_features_header)
      {
         &printFeatures($all_keys,\@attribs,$sequence);

         $printed = 1;
      }

      $all_keys = {};

      @attribs = ();

      $seen_features_header = 0;

      $seen_origin_header = 0;

      $sequence = '';
   }
   elsif($seen_origin_header)
   {
      if($print_sequence)
      {
         if(/^\s*\d+\s+(\S.*)$/)
         {
            my $seq = $1;

            $seq =~ s/\s//g;

            $sequence .= $seq;
         }
      }
   }
   elsif($seen_features_header)
   {
      $printed = 0;

      if(/^ORIGIN/)
      {
         $seen_origin_header = 1;
      }
      elsif(/\s+source\s+(\d+)\.\.(\d+)/)
      {
         $five_prime  = $1;
         $three_prime = $2;
      }
      elsif(/\s+source\s+complement\((\d+)\.\.(\d+)\)/)
      {
         $five_prime  = $2;
         $three_prime = $1;
      }
      elsif(/^\s+(\S.*)\s+(\d+)\.\.(\d+)/)
      {
         my $feat  = &fix($1);
         my $five  = $2;
         my $three = $3;
         if(not(defined($feature)) or ($feature eq $feat))
         {
            my %new_attribs;

            $new_attribs{'feature'} = $feat;
            $new_attribs{'five'}    = $five;
            $new_attribs{'three'}   = $three;
            $$all_keys{'feature'}   = 1;
            $$all_keys{'five'}      = 1;
            $$all_keys{'three'}     = 1;

            push(@attribs, \%new_attribs);

            $seen_feature = 1;
         }
      }
      elsif(/^\s+(\S.*)\s+complement\((\d+)\.\.(\d+)\)/)
      {
         my $feat  = &fix($1);
         my $five  = $3;
         my $three = $2;
         if(not(defined($feature)) or ($feature eq $feat))
         {
            my %new_attribs;

            $new_attribs{'feature'} = $feat;
            $new_attribs{'five'}    = $five;
            $new_attribs{'three'}   = $three;
            $$all_keys{'feature'}   = 1;
            $$all_keys{'five'}      = 1;
            $$all_keys{'three'}     = 1;

            push(@attribs, \%new_attribs);

            $seen_feature = 1;
         }
      }
      elsif($seen_feature and /^\s+\/([^=]+)=(.+)/)
      {
         $attrib = $1;

         $value  = &fix($2);

         my $attribs = $attribs[$#attribs];

         $$attribs{$attrib} = $value;

         $$all_keys{$attrib} = 1;
      }
      elsif(/^\s+\S.+\d+\.\.\d+/)
      {
         $seen_feature = 0;
      }
      elsif(/^\s*\S.+\d+\.\.\d+/)
      {
         $seen_feature = 0;
      }
      elsif(/^\S/)
      {
         $seen_feature = 0;
      }
      elsif($seen_feature and defined($attrib))
      {
         chomp;

         my $attribs = $attribs[$#attribs];

         $$attribs{$attrib} .= ' ' . &fix($_);
      }
   }
   elsif(/^FEATURES/)
   {
      $seen_features_header = 1;
   }
}
close($filep);

if(not($printed))
{
   &printFeatures($all_keys, \@attribs, $sequence);
}

exit(0);

sub printFeatures
{
   my ($all_keys,$attribs,$sequence) = @_;

   print STDOUT "Num";

   foreach my $key (keys(%{$all_keys}))
   {
      print STDOUT "\t$key";
   }
   if(length($sequence) > 0)
   {
      print STDOUT "\tsequence";
   }
   print STDOUT "\n";

   for(my $i = 0; $i < scalar(@{$attribs}); $i++)
   {
      my $attrib = $$attribs[$i];

      print STDOUT $i+1;

      foreach my $key (keys(%{$all_keys}))
      {
         my $value = exists($$attrib{$key}) ? $$attrib{$key} : '';

         print STDOUT "\t$value";
      }
      if(length($sequence) > 0)
      {
         my $five  = $$attrib{'five'} - 1;
         my $three = $$attrib{'three'} - 1;
         my $subseq = $five <= $three ? substr($sequence, $five, $three-$five+1) :
                      &reverseComplement(substr($sequence, $three, $five-$three+1));
         print STDOUT "\t$subseq";
      }
      print STDOUT "\n";
   }
}

sub reverseComplement
{
   my ($seq) = @_;

   $seq =~ tr/ACGTacgt/TGCAtgca/;

   return reverse($seq);
}

sub fix
{
   my ($txt) = @_;

   $txt =~ s/["']//g;

   $txt =~ s/^\s+//;

   $txt =~ s/\s+$//;

   $txt =~ s/(\s)\s+/$1/g;

   return $txt;
}

__DATA__
syntax: gbk.pl [OPTIONS]

OPTIONS are:

-q: Quiet mode (default is verbose)

-f FEATURE: Only get data for feature FEATURE (default gets all features).

-s: Print the sequence data for each feature (default does not print).


