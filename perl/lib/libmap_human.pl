################################################################################
#
# Human -- routines specific to working with human databases and keys
#
################################################################################

use strict;

require "$ENV{MYPERLDIR}/lib/libmap_ncbi.pl";

##------------------------------------------------------------------------------
## extractHumanKey
##------------------------------------------------------------------------------
sub extractHumanKey # ($text, $map_entity, $map_database)
{
  my $text         = shift;
  my $map_entity   = shift;
  my $map_database = shift;
  my $key = '';

  if($map_database eq 'Locuslink')
  {
    $key = &hasLocuslinkAccession($text,$map_entity);
  }
  elsif($map_database eq 'Refseq')
  {
    $key = &hasRefseqAccession($text,$map_entity);
  }
  elsif($map_database eq 'Unigene')
  {
    $key = &hasHumanUnigeneAccession($text,$map_entity);
  }
  elsif($map_database eq 'Genbank')
  {
    $key = &hasGenbankAccession($text,$map_entity);
  }
  elsif($map_database eq 'Swissprot')
  {
    $key = &hasSwissprotAccession($text,$map_entity);
  }
  elsif($map_database eq 'Image')
  {
    $key = &hasImageAccession($text,$map_entity);
  }
  return $key;
}

sub hasHumanUnigeneAccession # (string $text, string $map_entity)
{
  my $text = shift;
  my $map_entity = shift; # ignored
  my $key = '';

  if($text =~ /(Hs\.\d+)/i)
  {
    $key = $1;
  }

  return $key;
}


1
