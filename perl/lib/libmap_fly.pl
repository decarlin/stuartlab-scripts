################################################################################
#
# Fly -- routines specific to working with fly databases and keys
#
################################################################################

use strict;

##------------------------------------------------------------------------------
## extractFlyKey
##------------------------------------------------------------------------------
sub extractFlyKey # ($text,$map_entity,$map_database)
{
  my $text         = shift;
  my $map_entity   = shift;
  my $map_database = shift;
  my $key = '';
  if($map_database eq 'Flybase')
  {
    $key = &extractFlybaseKey($text,$map_entity);
  }
  return $key;
}

##------------------------------------------------------------------------------
## extractFlybaseKey
##------------------------------------------------------------------------------
sub extractFlybaseKey # (string $text, string $map_entity)
{
  my $text       = shift;
  my $map_entity = shift;
  my $key = &extractFlybaseId($text);

  if(length($key)==0 and $map_entity eq 'Gene')
  {
    $key = &extractFlybaseCuratedGene($text);
  }

  if(length($key)==0 and $map_entity eq 'Gene')
  {
    $key = &extractFlybaseCuratedTranscript($text);
  }

  return $key;
}

##------------------------------------------------------------------------------
## extractFlybaseId
##------------------------------------------------------------------------------
sub extractFlybaseId # ($text)
{
  my $text = shift;
  my $key = '';
  if($text =~ /(FBGN\d{7})/i)
  {
    $key = $1;
  }
  return $key;
}

##------------------------------------------------------------------------------
## extractFlybaseCuratedGene
##------------------------------------------------------------------------------
sub extractFlybaseCuratedGene # ($text)
{
  my $text = shift;
  my $key = '';
  if($text =~ /(CG\d+)/)
  {
    $key = $1;
  }
  return $key;
}

##------------------------------------------------------------------------------
## extractFlybaseCuratedTranscript
##------------------------------------------------------------------------------
sub extractFlybaseCuratedTranscript # ($text)
{
  my $text = shift;
  my $key = '';
  if($text =~ /(CT\d+)/)
  {
    $key = $1;
  }
  return $key;
}

1
