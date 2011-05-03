#!/usr/local/bin/perl

##############################################################################
##############################################################################
##
## arff2tab.pl
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
                  [    '-q', 'scalar',      0,     1]
                , [    '-l', 'scalar',      0,     1]
                , [    '-p', 'scalar',      0,     1]
                , [    '-t', 'scalar',      0,     1]
                , [    '-d', 'scalar',    ',', undef]
                , ['--file', 'scalar',    '-', undef]
              );

my %args = %{&parseArgs(\@ARGV, \@flags, 1)};

if(exists($args{'--help'})) {
   print STDOUT <DATA>;
   exit(0);
}

my $verbose   = not($args{'-q'});
my $label     = $args{'-l'};
my $predict   = $args{'-p'};
my $transpose = $args{'-t'};
my $delim     = &interpMetaChars($args{'-d'});
my $file      = $args{'--file'};
my @extra     = @{$args{'--extra'}};

my $filep = &openFile($file);
my @attrib_names;
my @attrib_types;
my @relations;
my $seen_data_tag = 0;
my @data;
my $predict_attrib = undef;
my $num_samples = 0;
while(<$filep>) {
   if(/^\@relation/) {
      push(@relations, $_);
   }
   elsif(/^\@attribute/) {
      my ($dummy, $attrib_name, $attrib_type) = split(/[ \t]+/);
      push(@attrib_names, $attrib_name);
      push(@attrib_types, $attrib_type);
   }
   elsif(/^\@data/) {
      $seen_data_tag = 1;
   }
   elsif($seen_data_tag and /\S/) {
      if($num_samples == 0) {
         my $attrib_header = ('Sample_Num');
         $attrib_header = $label   ? $attrib_header . '_ClassLabel'    : $attrib_header;
         $attrib_header = $predict ? $attrib_header . '_PredictLabel' : $attrib_header;
         if($predict) {
            pop(@attrib_names);
         }
         if($label) {
            pop(@attrib_names);
         }
         my @attrib_header = ($attrib_header);
         push(@attrib_header, @attrib_names);
         if($transpose) {
            push(@data, \@attrib_header);
         }
         else {
            print STDOUT join("\t", @attrib_header), "\n";
         }
      }
      my @x = split($delim, $_);
      chomp($x[$#x]);

      my $class_predict = $predict ? pop(@x) : undef;
      my $class_label = $label ? pop(@x) : undef;

      $num_samples++;

      my $sample_header = "Sample_$num_samples";
      $sample_header    = $label   ? $sample_header . "_$class_label"   : $sample_header;
      $sample_header    = $predict ? $sample_header . "_$class_predict" : $sample_header;

      if($transpose) {
         unshift(@x, $sample_header);
         push(@data, \@x);
      }
      else {
         print $sample_header . "\t" . join("\t", @x), "\n";
      }
   }
}
close($filep);

if($transpose) {
   my $num_attribs = scalar(@attrib_names);
   for(my $j = 0; $j < $num_attribs; $j++) {
      my @column_vector;
      for(my $i = 0; $i < $num_samples; $i++) {
         push(@column_vector, $data[$i][$j]);
      }
      print STDOUT join("\t", @column_vector), "\n";
   }
}

exit(0);

__DATA__
syntax: arff2tab.pl [OPTIONS]

OPTIONS are:

-q: Quiet mode (default is verbose)

-d DELIM: Set the attribute delimiter to DELIM (default is comma).

-l: The samples have a label. The last attribute is assumed to be a label (defaule none).

-p: The samples have a prediction class. The last attribute is assumed to be a prediction label (default none). If both -l and -p
    are used, assumes the label is second-to-last and the prediction is last.

-t: Transpose the data before outputting. This operation causes attributes to be the rows and samples to be columns. By default
    no transposition occurs.



