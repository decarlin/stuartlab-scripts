################################################################################
#
# NCBI -- Scripts for dealing with NCBI-related databases.  This includes all
#         databases covered by the consortium in the US, UK, and Japan.  For
#         example Swissprot related routines should also be included here.
#
################################################################################

use strict;

##------------------------------------------------------------------------------
## extractNcbiGi ($ncbi_key)
##
##   Returns the database name and the key extracted from an NCBI gi line.  A
##   gi line looks like:
##
##   gi|7288900|gb|AAFF45315.1|
##------------------------------------------------------------------------------
# (string $key, string $database)
sub extractNcbiGi # (string $ncbi_key, string map_entity)
{
  my $ncbi_key   = shift;
  my $map_entity = shift; # ignored
  my ($key,$database) = ('','');
  if($ncbi_key =~ /gi\|\d+\|([^\|]+)\|([^\|]+)\|/i)
  {
    ($key,$database) = ($2,$1);
  }
  return ($key,$database);
}

##------------------------------------------------------------------------------
## hasNcbiGi
##
##   Returns a non-empty NCBI key if the given text contains a key.  Otherwise
##   it returns the empty string.  NCBI keys look like:
##
##   gi|7288900|gb|AAFF45315.1|
##------------------------------------------------------------------------------
# string $key
sub hasNcbiGi # (string $text, string $map_entity)
{
  my $text = shift;
  my $map_entity = shift; # ignored
  if($text =~ /(gi\|\d+\|[^\|]+\|[^\|]+\|)/i)
  {
    return $1;
  }
  return '';
}

##------------------------------------------------------------------------------
## hasLocuslinkAccession
##------------------------------------------------------------------------------
sub hasLocuslinkAccession # (string $text, string $map_entity)
{
  my $text = shift;
  my $map_entity = shift; # ignored
  my $key = '';

  if($text =~ /[Ll][Ll]\.(\d+)/ or
     $text =~ /\s+(\d+)\s+/ or 
     $text =~ /^(\d+)\s+/ or
     $text =~ /\s+(\d+)$/ or
     $text =~ /^(\d+)$/)
  {
    $key = $1;
  }
  return $key;
}

##------------------------------------------------------------------------------
## hasRefseqAccession
##
## RefSeq accessions look like XP_121975.1 where the last suffix .1 corresponds
## to the RefSeq version number.  Version suffixes are removed in the returned
## key.
##------------------------------------------------------------------------------
# string $key
sub hasRefseqAccession # (string $text, string $map_entity)
{
  my $text = shift;
  my $map_entity = shift;
  my $key = '';

  if($text =~ /([A-Z]{2}_\d{6})\.\d+/i or
    $text =~ /([A-Z]{2}_\d{6})/i)
  {
    my $refseq = $1;
    if($map_entity eq &getMapEntityName('Contig'))
    {
      if($refseq =~ /^NT/i)
      {
        $key = $refseq;
      }
    }
    else
    {
      $key = $refseq;
    }
  }
  return $key;
}

##------------------------------------------------------------------------------
## hasGenbankAccession
##
## Genbank accessions look like AAF45487.1 where the last suffix .1 corresponds
## to the NCBI version number.  Version suffixes are removed in the returned
## key.
##------------------------------------------------------------------------------
# string $key
sub hasGenbankAccession # (string $text, string $map_entity)
{
  my $text = shift;
  my $map_entity = shift; # ignored
  my $key = '';
  if($text =~ /([A-Z][A-Z0-9]+)\.\d+/i or
    $text =~ /([A-Z][A-Z0-9]+)/i)
  {
    $key = $1;
  }
  return $key;
}

##------------------------------------------------------------------------------
## hasImageAccession
##
##------------------------------------------------------------------------------
# string $key
sub hasImageAccession # (string $text, string $map_entity)
{
  my $text = shift;
  my $map_entity = shift; # ignored
  my $key = '';

  if($text =~ /(IMAGE:\d+)/i)
  {
    $key = $1;
  }
  return $key;
}

##------------------------------------------------------------------------------
## hasSwissprotAccession
##
## SwissProt accessions look like P18961 or Q02608.  Letter and then 5 digits.
##------------------------------------------------------------------------------
# string $key
sub hasSwissprotAccession # (string $text, string $map_entity)
{
  my $text = shift;
  my $map_entity = shift; # ignored
  my $key = '';

  if( $text =~ /[^\dA-Z]([A-Z]\d+)[^\dA-Z]/i or
      $text =~ /^([A-Z]\d+)[^\dA-Z]/i or
      $text =~ /[^\dA-Z]([A-Z]\d+)$/i or
      $text =~ /^([A-Z]\d+)$/i or
      $text =~ /^ENSP(\d+)/i)
  {
    $key = $1;
  }
  return $key;
}

##------------------------------------------------------------------------------
## hasSwissprotGene
##
## SwissProt names look like YPK2_YEAST or RT24_YEAST.  A gene name followed by
## an organism name.
##
##------------------------------------------------------------------------------
# string $key
sub hasSwissprotGene # (string $text, string $map_entity)
{
  my $text = shift;
  my $map_entity = shift; # ignored
  my $key = '';

  if($text =~ /([\dA-Z]+_[\dA-Z]+)/i)
  {
    $key = $1;
  }
  return $key;
}

##------------------------------------------------------------------------------
##
##------------------------------------------------------------------------------
sub formatRefseqAccession # (string $orf)
{
  my $key = shift;

  # Remove the version extension off the end of the
  # key.  E.g. convert XP_121973.1 to XP_121973
  $key =~ s/\.\d+$//;

  return $key;
}

##------------------------------------------------------------------------------
##
##------------------------------------------------------------------------------
sub formatGenbankAccession # (string $orf)
{
  my $key = shift;

  # Remove the version extension off the end of the
  # key.  E.g. convert AAF45315.1 to AAF45315
  $key =~ s/\.\d+$//;

  return $key;
}

##------------------------------------------------------------------------------
## parseSwissprotHeader
##
## Determines what columns SwissProt data resides in by inspecting the header
## in the SwissProt file.  Advances the file pointer so that the next call
## to <$file> should return the first row of data.
##
## $alias_col, $alias_len - section containing gene aliases
## $acc_col, $acc_len - SwissProt accession section
## $name_col, $name_len - section containing SwissProt names (e.g. MAT2_YEAST)
##------------------------------------------------------------------------------
# (int $alias_col, int $alias_len, int $acc_col, int $acc_len, 
#  int $name_col, int $name_len)
sub parseSwissprotHeader # (FILE* $file)
{
  my $file = shift;

  my ($alias_col,$alias_len,$acc_col,$acc_len,$name_col,$name_len) =
       (-1,-1,-1,-1,-1,-1);

  my $done = 0;
  my $seen_bar = 0;
  my $seen_header = 0;
  my $line_no = 0;
  while(not($done))
  {
    my $line = <$file>;
    if($line eq eof)
    {
      print STDERR "WARNING: Reached end of SwissProt file w/o finding header. ",
                   "$line_no lines read.\n";
      $done = 1;
    }
    elsif($line =~ /\S/)
    {
      chomp;
      if($line =~ /^__________/)
      {
        $seen_bar++;

        if($seen_header >= 3)
        {
          # Swissprot marks the end of a section with a break in the horizontal
          # bar.  I know this is a terrible way to detect the boundary, but
          # it's not any more arbitrary than other options...
          $alias_len = index($line,' ',$alias_col) - $alias_col + 1;
          $acc_len   = index($line,' ',$acc_col) - $acc_col + 1;
          $name_len  = index($line,' ',$name_col) - $name_col + 1;
          $done = 1;
        }
      }
      else
      {
        if($line =~ /Gene/)
        {
          $alias_col = index($line,'Gene');
          $seen_header++;
        }
        if($line =~ /AC/)
        {
          $acc_col   = index($line,'AC');
          $seen_header++;
        }
        if($line =~ /Entry/)
        {
          $name_col  = index($line,'Entry');
          $seen_header++;
        }
      }
    }
    $line_no++;
  }
  return ($alias_col,$alias_len,$acc_col,$acc_len,$name_col,$name_len);
}

1
