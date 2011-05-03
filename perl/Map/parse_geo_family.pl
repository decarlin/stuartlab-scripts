#!/usr/bin/perl

##############################################################################
##############################################################################
##
## parse_geo_family.pl
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
require "$ENV{MYPERLDIR}/lib/libset.pl";
require "$ENV{MYPERLDIR}/lib/libgeo.pl";

use strict;
use warnings;

# Flush output to STDOUT immediately.
$| = 1;

my @flags   = (
                  [    '-q', 'scalar',                  0,     1]
                , [    '-i', 'scalar',               'ID', undef]
                , [    '-g', 'scalar',              'ORF', undef]
                , [    '-a', 'scalar',              undef, undef]
                , [    '-d', 'scalar',        'LOG_RATIO', undef]
                , [   '-id', 'scalar',           'ID_REF', undef]
                , ['--file', 'scalar',                '-', undef]
              );

my %args = %{&parseArgs(\@ARGV, \@flags)};

if(exists($args{'--help'}))
{
   print STDOUT <DATA>;
   exit(0);
}

my $verbose       = not($args{'-q'});
my $id_field      = $args{'-i'};
my $gene_field    = $args{'-g'};
my $alias_field   = $args{'-a'};
$alias_field      = defined($alias_field) ? $alias_field : $gene_field;
my $data_field    = $args{'-d'};
my $id_data_field = $args{'-id'};
my $file          = $args{'--file'};

my $tmpfile  = ($file eq '-') ? &makeTmpFile('geo', $file) : $file;

my $tmpfilep = &openFile($tmpfile);

my $genes    = &getGeoFamilyGenes($tmpfilep, $id_field, $gene_field, $alias_field);

my @genes    = values(%{$genes});

@genes       = sort {$a cmp $b;} @{&set2List(&list2Set(\@genes))};

my @data;

foreach my $gene (@genes)
{
   push(@data, [$gene]);
}

my $n     = scalar(@genes);

my $done  = 0;

my $p     = 0;

my @header;

for(my $s = 0; not($done); $s++)
{
   $verbose and print STDERR "Parsing GEO family $s.\n";

   my ($sample, $title) = &getGeoFamilySample($tmpfilep, $genes, $id_data_field, $data_field);

   my $m        = scalar(keys(%{$sample}));

   if($m == 0)
   {
      $done = 1;
   }
   else
   {
      $p++;
      for(my $i = 0; $i < $n; $i++)
      {
         my $gene      = $data[$i][0];
         my $value     = exists($$sample{$gene}) ? $$sample{$gene} : 'NaN';
         $data[$i][$p] = ($value eq 'NaN') ? 'NaN' : sprintf("%.3f", $value);
      }
   }

   $verbose and print STDERR "Finished parsing GEO family $s -> '$title'.\n";

   push(@header, $title);
}

$verbose and print STDERR "Printing data file.\n";

print STDOUT "ID\t", join("\t", @header), "\n";

for(my $i = 0; $i < $n; $i++)
{
   print STDOUT join("\t", @{$data[$i]}), "\n";
}

$verbose and print STDERR "Done printing data file.\n";


if($file eq '-')
{
   &deleteFile($tmpfile);
}

exit(0);


__DATA__
syntax: parse_geo_family.pl [OPTIONS] [FILE | < FILE]

OPTIONS are:

-q: Quiet mode (default is verbose)

-i ID_FIELD:

-g GENE_FIELD:

-a ALIAS_FIELD:

-d DATA_FIELD:

-id ID_DATA_FIELD:



