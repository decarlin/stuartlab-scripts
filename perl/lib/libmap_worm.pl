################################################################################
#
# Worm -- routines specific to working with worm databases and keys
#
################################################################################

require "$ENV{MYPERLDIR}/lib/libstring.pl";

use strict;

my $worm_clone_ids_with_bogus_number = '0C24D10.5 0C26F1.3 0C33C12.1 0F01D5.10 0K07E8.1 0K09E2.3 0K09E2.3 0T05G11.4 0T08G5.3 0T19C3.7 0T27C5.1 0T27F2.3 0VW06B3R.1 0W01B11.1 0W02B3.4 0W06H12.1 0W09C5.2 0W09C5.4 0Y11D7A.9 0Y66A7A.5 0ZK353.1 0ZK637.13 1C09E8.1 1C17E4.8 1C17H12.11 1C18B12.5 1C18C4.7 1D2045.8 1T02H7.5 1T10G3.7 1T15H9.3 1T19A6.3 1W02B9.1 1W02C12.2 1Y19D2B.1 1Y19D2B.1 1Y62H9A.12 1Y73C8C.1 1Y76A2B.4 1ZC53.4 1ZK899.7 2C27C7.1 2C29F5.7 2F07A5.4 2L52.1 2T04A8.2 2T05A10.2 2T25B2.2 2T28A8.2 2T28C6.6 2Y106G6H.6 2ZK262.7 2ZK39.2 3C09E8.3 3C09G1.3 3C16B8.4 3F07F6.5 3R13D7.4 3R5.1 3R5.2 3T10D4.4 3T22D2.1 3T27A8.2 3T28A11.7 3VZC374L.1 3W03D8.7 3Y11D7A.7 3Y6B3B.11 3Y71H10A.2 3Y73F4A.1 4C18B12.4 4C18B2.3 4C54E10.5 4C55A6.1 4F01D5.9 4K02E2.5 4R13D11.5 4R79.1 4R79.2 4R79.3 4T01G9.1 4T01H8.2 4T16G1.3 4T19D12.8 4W04D2.3 4Y106G6H.1 4Y32F6B.3 4ZK370.6 5C08B6.6 5C14F5.4 5C18B12.2 5C25B8.4 5C55C2.4 5F01F1.3 5F10A3.3 5K03B4.7 5K03B4.7 5T06A10.3 5T08G3.11 5T10D4.10 5T20D3.2 5T22A3.5 5T25D3.4 5W03A5.4 5W06D12.6 5Y17G7B.6 5Y37A1B.4 5Y37A1B.4 6C18F3.3 6C18H7.5 6C25E10.12 6C56A3.2 6DY3.3 6R55.1 6R55.2 6T01B11.7 6T04G9.4 6T05F1.4 6T09F5.9 6T16G1.8 6T22E7.1 6T23G4.5 6W03D2.5 6Y106G6E.3 6Y106G6E.3 6Y52B11A.11 6Y68A4A.1 6Y8G1A.1 7C24H10.3 7C53A3.1 7T03A1.3 7T10B10.6 7T11B7.5 7T13A10.4 7T19D7.6 7T25G3.1 7T26E3.1 7T27C5.10 7Y102A5C.24 7Y102A5C.24 7Y66A7A.6 8C07D10.3 8C11E4.1 8C16C10.8 8C54C6.4 8R12C12.9 8T01C4.3 8T17A3.2 8T28A11.11 8W04E12.2 8W08E3.4 8Y11D7A.5 8Y11D7A.5 8ZC53.6 9C16A11.2 9C26E6.11 9C54G7.1 9F09F7.2 9R11A5.5 9T02C5.2 9T05E11.1 9T28H10.2 9W04C9.3 9W10C8.3 9Y102A5C.10 9Y6E2A.3 9ZC21.8 9ZK262.2';
my %worm_clone_ids_with_bogus_number;
foreach my $clone_id (split(' ',$worm_clone_ids_with_bogus_number))
  { $clone_id =~ tr/a-z/A-Z/; $worm_clone_ids_with_bogus_number{$clone_id} = 1; }

sub getWormCloneIdsWithBogusNumber
{
  my @list = split(' ',$worm_clone_ids_with_bogus_number);
  return \@list;
}

##------------------------------------------------------------------------------
## hasWormbaseCloneId
##
## WormBase clones look like ZK899.2a where ZK899.2 is the actual clone ID and
## the a suffix indicates this is the first splice variant.  This function
## strips off the splice-variant indicator at the end (so would return
## ZK899.2 if the text contained ZK899.2a).
##
## WARNING: Note Wormbase's keys are not distinguishable from a general
## Genbank accession (except maybe by key length which is not implemented
## in these functions).
##------------------------------------------------------------------------------
# string $key
sub hasWormbaseCloneId # ($text)
{
  my $text = shift;
  if($text =~ /([a-zA-Z0-9]+\.\d+)/)
  {
    return &formatWormbaseCloneId($1);
  }
  return '';
}

##------------------------------------------------------------------------------
## hasWormbaseCe
##
## WormBase keys look like CE20433 -- they all have a CE prefix followed by
## a number.
##------------------------------------------------------------------------------
# string $key
sub hasWormbaseCe # ($text)
{
  my $text = shift;

  if($text =~ /(CE\d+)/i)
  {
    return $1;
  }
  return '';
}

##------------------------------------------------------------------------------
## hasWormbaseKey
##------------------------------------------------------------------------------
sub hasWormbaseKey # ($text, string $map_entity)
{
  my $text       = shift;
  my $map_entity = shift; # ignored
  my $key = '';

  $key = &hasWormbaseCe($text);
  if(length($key)>0)
  {
    return $key;
  }

  $key = &hasWormbaseCloneId($text);

  return $key;
}

##------------------------------------------------------------------------------
## isWormCloneIdWithBogusNumber
##------------------------------------------------------------------------------
sub isWormCloneIdWithBogusNumber
{
  my $clone = shift;
  $clone =~ tr/a-z/A-Z/;
  if(exists($worm_clone_ids_with_bogus_number{$clone}))
    { return 1; }
  return 0;
}

##------------------------------------------------------------------------------
## formatWormbaseCloneId
##------------------------------------------------------------------------------
sub formatWormbaseCloneId # (string $key)
{
  my $key = shift;
  $key =~ tr/a-z/A-Z/;
  $key =~ s/(\.\d+)[A-Z]+$/\1/; # Remove splice variant information
  
  # At some point, someone at WormBase erroneously tacked on numbers
  # at the beginning of some clone names.  Remove them the leading
  # numbers if this gene is not one of the ones that legitimately
  # start with a number.
  if($key =~ /^\d/ and not(&isWormCloneIdWithBogusNumber($key)))
  {
    $key =~ s/^\d+//;
  }
  return $key;
}

##------------------------------------------------------------------------------
## extractWormKey
##------------------------------------------------------------------------------
sub extractWormKey # (string $text, string $map_entity, string $map_database)
{
  my $text           = shift;
  my $map_entity     = shift;
  my $map_database   = shift;
  my $key = '';

  if($map_database eq 'Wormbase')
  {
    $key = &hasWormbaseKey($text, $map_entity);
  }
  return $key;
}

##------------------------------------------------------------------------------
##
##------------------------------------------------------------------------------
sub extractWormGeneFromSpliceVariant
{
  my ($splice_variant) = @_;
  my $gene = '';
  if($splice_variant =~ /(([a-zA-Z0-9]+\.\d+)\D+)/)
  {
    ($splice_variant,$gene) = ($1,$2);
  }
  elsif($splice_variant =~ /([a-zA-Z0-9]+\.\d+)/)
  {
    ($splice_variant,$gene) = ($1,$1);
  }
  return ($gene,$splice_variant);
}

# Returns true if the name is a worm gene name (splice
# variants are not considered to be gene names).
sub IsGeneWorm # ($name)
{
  my $name = shift;
  return ($name =~ /^\S\S\S-[\d\.]+$/);
}

# ORF names in worm look like F22B7.13.  Splice variants are not
# considered to be ORF names.
sub IsOrfWorm # ($name)
{
  my $name = shift;
  return (($name =~ /^[^\.]+\.[^\.]+/) and not(&IsSpliceWorm($name)));
}

# Returns true if the name is a splice variant like F32A6.4B.
sub IsSpliceWorm # ($name)
{
  my $name = shift;
  return ($name =~ /^[^\.]+\.\d+[a-zA-Z]+$/);
}

sub Splice2OrfWorm
{
  my $name = shift;
  if($name =~ /^([^\.]+\.\d+)[a-zA-Z]+$/)
  {
    $name = $1;
  }
  return $name;
}

sub FixGeneWorm
{
  my $name = shift;
  $name = &RemExtraSpaces($name);
  $name =~ tr/A-Z/a-z/;
  return $name;
}

sub FixOrfWorm
{
  my $name = shift;
  $name = &RemExtraSpaces($name);
  $name =~ tr/a-z/A-Z/;
  return $name;
}

sub CmpGeneWorm
{
  my ($a_pre,$a_suf,$b_pre,$b_suf)=('','','','');
  if($a =~ /^(\S\S\S)\.(\d+)$/)
    { $a_pre = $1; $a_suf = int($2); }
  if($b =~ /^(\S\S\S)\.(\d+)$/)
    { $b_pre = $1; $b_suf = int($2); }
  if(length($a_pre)>0 and length($b_pre)>0)
  {
    if($a_pre eq $b_pre)
    {
      return($a_suf <=> $b_suf);
    }
    else
    {
      return($a_pre cmp $b_pre);
    }
  }
  return($a cmp $b);
}

1
