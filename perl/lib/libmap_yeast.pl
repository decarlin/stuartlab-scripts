################################################################################
#
# Yeast -- routines specific to working with yeast databases and keys
#
################################################################################

use strict;

require "$ENV{MYPERLDIR}/lib/libmap_ncbi.pl";

##------------------------------------------------------------------------------
## hasSgdAccession
##
## SGD accessions look like S0000009: start with S and have 7 digits.
##------------------------------------------------------------------------------
# (string $key)
sub hasSgdAccession # ($text)
{
  my $text = shift;
  my $key  = '';

  if($text =~ /(S\d{7,})/)
  {
    $key = $1;
  }

  return $key;
}

##------------------------------------------------------------------------------
## hasSgdOrf
##
## SGD ORFs look like YAL007C -- all start with "Y", followed by chromosome
## letter ("A" means chromosome 1), followed by L or R indicating left or right
## arm of the chromosome, followed by 3 digits, followed by W or C indicating
## watson or crick strand.  They can have an optional suffix indicating a
## splice variant (e.g. YAL035C-A)
##------------------------------------------------------------------------------
# (string $key)
sub hasSgdOrf # ($text)
{
  my $text = shift;
  my $key  = '';

  if($text =~ /(Y[A-Z][LR]\d{3}[CW]-[A-Z])/i or
     $text =~ /(Y[A-Z][LR]\d{3}[CW])/i or
     $text =~ /(Q\d{4})/i or
     $text =~ /(\d+S_RRNA_\d+)/i)
  {
    $key = $1;
  }
  return $key;
}

##------------------------------------------------------------------------------
## hasYeastSwissprotGene
##------------------------------------------------------------------------------
# (string $key)
sub hasYeastSwissprotGene # ($text)
{
  my $text = shift;
  my $key  = '';

  if($text =~ /([\dA-Z]+_YEAST)/i)
  {
    $key = $1;
  }

  return $key;
}

##------------------------------------------------------------------------------
## hasYeastSwissprotKey
##------------------------------------------------------------------------------
# (string $key)
sub hasYeastSwissprotKey # ($text)
{
  my $text       = shift;
  my $key = &hasYeastSwissprotGene($text);
  # if(length($key)==0)
  # {
  #   $key = &hasSwissprotAccession($text);
  # }
  return $key;
}

##------------------------------------------------------------------------------
## hasSgdKey
##------------------------------------------------------------------------------
# (string $key)
sub hasSgdKey # ($text, $map_entity)
{
  my $text       = shift;
  my $map_entity = shift; # ignored
  my $key = &hasSgdAccession($text);

  if(length($key)==0)
  {
    $key = &hasSgdOrf($text);
  }

  return $key;
}

##------------------------------------------------------------------------------
## extractYeastKey
##
## The database has to be a MAP name.
##------------------------------------------------------------------------------
# (string $key)
sub extractYeastKey # ($text, $map_entity, $map_database)
{
  my $text         = shift;
  my $map_entity   = shift;
  my $map_database = shift;
  my $key = '';

  if($map_database eq 'Sgd')
  {
    $key = &hasSgdKey($text);
  }
  elsif($map_database eq 'Swissprot')
  {
    $key = &hasYeastSwissprotKey($text);
  }
  return $key;
}

1
