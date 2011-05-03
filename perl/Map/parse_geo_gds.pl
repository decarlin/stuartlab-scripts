#!/usr/local/bin/perl

##############################################################################
##############################################################################
##
## parse_geo_gds.pl
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
## Written: 10/10/03
##
##############################################################################
##############################################################################

require "$ENV{MYPERLDIR}/lib/libfile.pl";
require "$ENV{MYPERLDIR}/lib/libmap.pl";
require "$ENV{MYPERLDIR}/lib/libgeo.pl";
require "$ENV{MYPERLDIR}/lib/libset.pl";
require "$ENV{MYPERLDIR}/lib/libattrib.pl";
require "$ENV{MYPERLDIR}/lib/liblist.pl";

use strict;
use warnings;

# Flush output to STDOUT immediately.
$| = 1;

my @flags   = (
                  [     '-q', 'scalar',                 0,     1]
                , [    '-ps', 'scalar', '_family.soft.gz', undef]
                , [    '-pp', 'scalar',                '', undef]
                , [    '-ds', 'scalar',        '.soft.gz', undef]
                , [    '-dp', 'scalar',                '', undef]
                , [     '-i', 'scalar',              'ID', undef]
                , [     '-g', 'scalar',          'GB_ACC', undef]
                , [     '-o', 'scalar',             'Any', undef]
                , [     '-d', 'scalar',             undef, undef]
                , ['-noplat', 'scalar',                 0,     1]
              );

my %args = %{&parseArgs(\@ARGV, \@flags, 1)};

if(exists($args{'--help'}))
{
   print STDOUT <DATA>;
   exit(0);
}

my $verbose          = not($args{'-q'});
my $platform_suffix  = $args{'-ps'};
my $platform_prefix  = $args{'-pp'};
my $dataset_suffix   = $args{'-ds'};
my $dataset_prefix   = $args{'-dp'};
my $def_id_field     = $args{'-i'};
my $def_gene_field   = $args{'-g'};
my $organism         = $args{'-o'};
my $desc_file        = $args{'-d'};
my $def_use_platform = not($args{'-noplat'});
my $desc_filep       = defined($desc_file) ? &openFile($desc_file, 'w') : undef;
my @extra            = @{$args{'--extra'}};

(scalar(@extra) == 2) or die("Please supply a GEO directory and a datasets file.");

my ($dir, $file) = @extra;

(-d $dir) or die("First argument '$dir' not a GEO directory.");

my %mappings;

$organism = &getMapOrganismName($organism);

my @datasets;

open(DATASETS, "cat $file | fasta2tab.pl |") or die("Could not open datasets file '$file'");

while(<DATASETS>)
{
   my ($platform, $mappings, @dataset_names) = split("\t");

   chomp($dataset_names[$#dataset_names]);

   my @mappings = split(/[:,]/, $mappings);

   my $geo_field = 'GPL@ID';

   my @aliases_list;

   my $gds_gene_field = undef;

   foreach my $mapping (@mappings)
   {
      my @geo2map = split('->', $mapping);

      $verbose and print STDERR "Mapping: '$mapping':'$geo2map[0]'->'$geo2map[1]'\n";

      $geo_field = scalar(@geo2map) == 2 ? $geo2map[0] : $geo_field;

      my $map_alias = scalar(@geo2map) == 2 ? $geo2map[1] : $geo2map[0];

      my $map_alias_file = &getMapDir('aliases') .
                           "/Gene/$organism/$map_alias/data.tab";

      my ($geo_id_field, $gene_field, $use_platform) =
         &parseIdString($geo_field, $def_id_field, $def_gene_field, $def_use_platform);

      print STDERR "platform='$platform', id='$geo_id_field', gene='$gene_field'\n";

      my $platform_file = $dir . '/' . $platform_prefix .
                          $platform . $platform_suffix;

      not(not($use_platform) or (-f $platform_file)) and die("Platform file '$platform_file' does not exist");

      $verbose and print STDERR "Reading platform file '$platform_file.\n";

      my $aliases = $use_platform ?
                    &readPlatform($platform_file, $geo_id_field,
                                  $gene_field, $map_alias_file) :
                    &attribRead($map_alias_file, "\t", 1, 0);

      $verbose and print STDERR "Done reading platform file '$platform_file.\n";

      push(@aliases_list, $aliases);

      if(not($use_platform))
      {
         $gds_gene_field = $gene_field;
      }
   }

   foreach my $dataset_name (@dataset_names)
   {
      my $dataset_file  = $dir . '/' . $dataset_prefix
                               . $dataset_name . $dataset_suffix;

      $verbose and print STDERR "Reading dataset '$dataset_file'\n";

      my $dataset_fp    = &openFile($dataset_file);

      my ($data, $data_attribs) = &readGeoDataset($dataset_fp, \@aliases_list, $gds_gene_field);

      my $num_rows = scalar(keys(%{$data}));

      $verbose and print STDERR "Done reading dataset '$dataset_file' ($num_rows rows read)\n";

      close($dataset_fp);

      push(@datasets, $data);

      if(defined($desc_filep))
      {
         print $desc_filep join("\n", @{$data_attribs}), "\n";
      }
   }
}

close(DATASETS);

my $data = &mergeDatasets(\@datasets);

&printMatrix($data);

if(defined($desc_filep))
{
   close($desc_filep);
}

exit(0);

sub parseIdString
{
   my ($string, $default_id_field, $default_gene_field, $default_use_platform) = @_;

   my ($geo_id_field, $gene_field, $use_platform) =
         ($default_id_field, $default_gene_field, $default_use_platform);

   my $type = $default_use_platform ? 'GPL' : 'GDS';

   if($string =~ /^([^@]+)@([^@]+)@([^@]+)/)
   {
      ($type, $geo_id_field, $gene_field) = ($1, $2, $3);
   }
   elsif($string =~ /^GPL@([^@]+)/i)
   {
      $type = 'GPL';
      $gene_field = $1;
   }
   elsif($string =~ /^GDS@([^@]+)/i)
   {
      $type = 'GDS';
      $gene_field = $1;
   }
   elsif($string =~ /^([^@]+)@([^@]+)/)
   {
      ($geo_id_field, $gene_field) = ($1, $2);
   }
   else
   {
      $gene_field = $string;
   }

   $use_platform = ($type =~ /GDS/i) ? 0 :
                   (($type =~ /GPL/i) ? 1 :
                   $default_use_platform);

   return ($geo_id_field, $gene_field, $use_platform);
}

sub mergeDatasets
{
   my ($datasets) = @_;

   my %ids;

   my @blanks;

   my @data;

   $data[0] = ['Gene'];

   for(my $d = 0; $d < scalar(@{$datasets}); $d++)
   {
      my $dataset = $$datasets[$d];

      my @header = @{$$dataset{'HEADER'}};

      delete($$dataset{'HEADER'});

      foreach my $id (keys(%{$dataset}))
      {
         $ids{$id} = 1;
      }

      push(@{$data[0]}, @header);

      my @blank;

      for(my $i = 0; $i < scalar(@header); $i++)
      {
         push(@blank, 'NaN');
      }

      $blanks[$d] = \@blank;
   }

   my @ids = keys(%ids);

   for(my $i = 0; $i < scalar(@ids); $i++)
   {
      my $id = $ids[$i];

      $data[$i+1] = [$id];

      for(my $d = 0; $d < scalar(@{$datasets}); $d++)
      {
         my $dataset = $$datasets[$d];

         my $data_row = exists($$dataset{$id}) ?
                           $$dataset{$id} :
                           $blanks[$d];

         push(@{$data[$i+1]}, @{$data_row});
      }
   }

   return \@data;
}

sub lookupMapId
{
   my ($mappings, $name) = @_;

   foreach my $db (keys(%{$mappings}))
   {
      my $mapping = $$mappings{$db};

      if(exists($$mapping{$name}))
      {
         return $$mapping{$name};
      }
   }

   return '';
}

sub readPlatform
{
   my ($platform_file, $geo_id_field, $gene_field, $map_alias_file) = @_;

   my $platform_aliases = &getGeoPlatformAliases($platform_file,
                                                 $geo_id_field, $gene_field);

   my $aliases = &attribTranslateFile($platform_aliases, $map_alias_file,
                                            1, "\t", 1, 0);
   return $aliases;
}


__DATA__
syntax: parse_geo_gds.pl [OPTIONS] GEO_DIR DATASETS

OPTIONS are:

-q: Quiet mode (default is verbose)

-ps SUFFIX: The file suffix that the platform files end in (default is
           _family.soft.gz)

-pp PREFIX: The file prefix that the platform files end in (default is empty).

-ds SUFFIX:

-dp PREFIX:

-i IDFIELD: Specify what the identifier field in the platform file is called
            (default is ID).

-o ORGANISM: Specify the organism (default is Any).

-d DESC_FILE: Output a description of the dataset to this file (default none).

-noplat: Do not read the identifier mapping contained in the platform file.
         Specifying this option forces the script to look for the identifier
         in the GDS file(s) themselves.

