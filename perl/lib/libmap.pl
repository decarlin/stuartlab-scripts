################################################################################
#
# MAP -- Multi-species analysis with probablistic frameworks -- perl libraries
#
################################################################################
use strict;

require "$ENV{MYPERLDIR}/lib/libfile.pl";
require "$ENV{MYPERLDIR}/lib/libmap_ecoli.pl";
require "$ENV{MYPERLDIR}/lib/libmap_fly.pl";
require "$ENV{MYPERLDIR}/lib/libmap_human.pl";
require "$ENV{MYPERLDIR}/lib/libmap_mouse.pl";
require "$ENV{MYPERLDIR}/lib/libmap_ncbi.pl";
require "$ENV{MYPERLDIR}/lib/libmap_rat.pl";
require "$ENV{MYPERLDIR}/lib/libmap_worm.pl";
require "$ENV{MYPERLDIR}/lib/libmap_yeast.pl";

##------------------------------------------------------------------------------
## The root of the whole MAP hierarchy
##------------------------------------------------------------------------------
my $map_root = "/projects/sysbio/map";

##------------------------------------------------------------------------------
## The MAP executaable
##------------------------------------------------------------------------------
my $map_exe = "$ENV{MYPERLDIR}/lib/map_learn";
sub getMapExe # ()
  { return $map_exe; }

##------------------------------------------------------------------------------
## Error log file.
##------------------------------------------------------------------------------
my $map_error_log = undef;
my $map_error_log_file_name = 'errors.log';
my $printed_map_error_log_header = 0;

##------------------------------------------------------------------------------
## 
##------------------------------------------------------------------------------
sub openMapErrorLog
{
  if(not(defined($map_error_log)))
  {
    if(not(open($map_error_log,">>$map_error_log_file_name")))
    {
      $map_error_log = undef;
    }
  }
}

##------------------------------------------------------------------------------
## 
##------------------------------------------------------------------------------
sub closeMapErrorLog
{
  if(defined($map_error_log))
  {
    close($map_error_log);
  }
}

##------------------------------------------------------------------------------
## 
##------------------------------------------------------------------------------
sub printMapLogErrorHeader # (string $message)
{
  my $message = shift;
  if(not($printed_map_error_log_header))
  {
    &openMapErrorLog();
    if(defined($map_error_log))
    {
      print $map_error_log &getMapLogErrorHeader($message);
      $printed_map_error_log_header = 1;
    }
  }
}

##------------------------------------------------------------------------------
## 
##------------------------------------------------------------------------------
sub printMapLogErrorFooter # (string $message)
{
  my $message = shift;
  &openMapErrorLog();
  if(defined($map_error_log))
  {
    print $map_error_log &getMapLogErrorFooter($message);
    &closeMapErrorLog();
  }
}

##------------------------------------------------------------------------------
## 
##------------------------------------------------------------------------------
sub logMapError # (string $message, string $header, string $footer)
{
  my $message = shift;
  &printMapLogErrorHeader();
  if(defined($map_error_log))
  {
    print $map_error_log "$message";
  }
}

##------------------------------------------------------------------------------
## 
##------------------------------------------------------------------------------
my %MapDirs = 
(
  # The root of the MAP hierarchy:
  'ROOT'        => $map_root,

  # Data related directories:
  'TEMPLATES'   => "$map_root/Templates",

  # Data related directories:
  'DATA'        => "$map_root/Data",

  'ALIASES'     => "$map_root/Data/Aliases",

  # Orthologous groups
  'METAGENES'   => "$map_root/Data/MetaGene/Reciprocal/Fly_Human_Worm_Yeast",

  # Run related directories:
  'RUN'         => "$map_root/Run",

  # Evaluation related directories:
  'EVAL'        => "$map_root/Eval",

  # HTML related directories:
  'HTML'        => "$map_root/Html",

  # Backup directory
  'BACKUP'      => "$map_root/Backup"
);

sub getMapDir # ($type)
{
  my $type = shift;
  $type =~ tr/a-z/A-Z/;
  return $MapDirs{$type};
}

my @MapEntityNames =
(
  'Gene',
  'Chromosome',
  'Strand',
  'Contig'
);

sub getMapEntityNames # ()
{
  return @MapEntityNames;
}

my @MapOrganismNames =
(
#  'Ecoli',
  'Fly',
  'Frog',
  'Human',
#  'Mouse',
#  'Rat',
  'Worm',
  'Yeast',
  'Hpylori',
  'Plant'
);

sub getMapOrganismNames # ()
{
  return @MapOrganismNames;
}

my @MapDatabaseNames =
(
  'Cogs',
  'Flybase',
  'Genbank',
  'Image',
  'Locuslink',
  'Ncbi',
  'Pdb',
  'Homologene',
  'Refseq',
  'Sgd',
  'Swissprot',
  'Unigene',
  'Wormbase',
  'Wormpd',
  'Ypd'
);

sub getMapDatabaseNames # (string $entity)
{
  my $entity = shift;
  my @none = ('None');
  if($entity eq 'Gene' or $entity eq 'Contig')
  {
    return @MapDatabaseNames;
  }
  else
  {
    return(@none);
  }
}

##------------------------------------------------------------------------------
## getMapEntityName
##
## Extracts a biological entity name from the string.  Examples are "gene",
## "orf", "chromosome", etc.,  The returned entity name is in MAP standard
## format and can be used as a key for that entity.
##------------------------------------------------------------------------------
sub getMapEntityName # (string $text)
{
  my $text = shift;
  my $entity = '';

  if($text =~ /Gene/i or
     $text =~ /Orf/i)
  {
    $entity = 'Gene';
  }
  elsif($text =~ /Chr/i)
  {
    $entity = 'Chromosome';
  }
  elsif($text =~ /Strand/i)
  {
    $entity = 'Strand';
  }
  elsif($text =~ /Contig/i)
  {
    $entity = 'Contig';
  }
  return $entity;
}

sub wordMatch
{
   my ($string, $word) = @_;

   my $match = 0;

   if($string =~ /^$word$/i or
      $string =~ /^$word\W/i or
      $string =~ /\W$word\W/i or
      $string =~ /\W$word$/i)
   {
      $match = 1;
   }

   return $match;
}

##------------------------------------------------------------------------------
## getMapOrganismName
##
## Extracts an organism name from the input string.  The function returns
## the MAP standard name for the organism.
##------------------------------------------------------------------------------
sub getMapOrganismName # (string $string)
{
  my $string = shift;
  my $organism = '';

  if(&wordMatch($string, 'fly') or
     &wordMatch($string, 'drosophila') or
     &wordMatch($string, 'melanogaster') or
     &wordMatch($string, 'drome'))
  {
    $organism = 'Fly';
  }

  elsif(&wordMatch($string, 'frog') or
        &wordMatch($string, 'xenopus') or
        &wordMatch($string, 'laevus'))
  {
    $organism = 'Frog';
  }

  elsif(&wordMatch($string, 'human') or
        &wordMatch($string, 'homo') or
        &wordMatch($string, 'sapiens'))
  {
    $organism = 'Human';
  }

  elsif(&wordMatch($string, 'worm') or
        &wordMatch($string, 'caenorhabditis') or
        &wordMatch($string, 'elegans'))
  {
    $organism = 'Worm';
  }

  elsif(&wordMatch($string, 'Plant') or
        &wordMatch($string, 'arabidopsis') or
        &wordMatch($string, 'thaliana'))
  {
    $organism = 'Plant';
  }

  elsif(&wordMatch($string, 'yeast') or
        &wordMatch($string, 'saccharomyces') or
        &wordMatch($string, 'cerevisiae'))
  {
    $organism = 'Yeast';
  }

  elsif(&wordMatch($string, 'mouse') or
        &wordMatch($string, 'mus') or
        &wordMatch($string, 'musculus'))
  {
    $organism = 'Mouse';
  }
  elsif(&wordMatch($string, 'Ecoli') or
        &wordMatch($string, 'coli') or
        &wordMatch($string, 'escherichia'))
  {
    $organism = 'Ecoli';
  }
  elsif(&wordMatch($string, 'Hpylori') or
        &wordMatch($string, 'pylori') or
        &wordMatch($string, 'hpy'))
  {
    $organism = 'Hpylori';
  }
  elsif(&wordMatch($string, 'bsub') or
        &wordMatch($string, 'subtilis') or
        &wordMatch($string, 'bacilus'))
  {
    $organism = 'Bsub';
  }
  elsif(&wordMatch($string, 'rat') or
        &wordMatch($string, 'ratticus'))
  {
    $organism = 'Rat';
  }
  elsif(&wordMatch($string, 'arabidposis') or
        &wordMatch($string, 'thaliana') or
        &wordMatch($string, 'plant'))
  {
    $organism = 'Plant';
  }
  elsif(&wordMatch($string, 'Any') or
        &wordMatch($string, 'Unassigned') or
        &wordMatch($string, 'Misc'))
  {
    $organism = 'Any';
  }
  else
  {
    $organism = &convertSymbol2MapOrganismName($string);
  }
  return $organism;
}

##------------------------------------------------------------------------------
## getMapDatabaseName
##
##------------------------------------------------------------------------------
# string $database
sub getMapDatabaseName # (string $string, string $entity)
{
  my $string = shift;
  my $entity = &getMapEntityName(shift);
  my $database = '';
  if($entity eq 'Gene' or $entity eq 'Contig')
  {
    $database = $string;
    $database =~ s/^\s+//;
    $database =~ s/\s+$//;
    $database =~ s/(\s)\s+/$1/g;
  }
  else
  {
    $database = 'None';
  }
  return $database;
}

##------------------------------------------------------------------------------
## $string getMapBlastDb ($string org, $int protein)
##------------------------------------------------------------------------------
sub getMapBlastDb
{
   my ($organism, $protein) = @_;

   my $db = &getMapDir('data') . '/Blast'
            . ($protein ? '/Protein' : '/Dna')
            . '/Db/' . &getMapOrganismName($organism) . '/data';

   return $db;
}

##------------------------------------------------------------------------------
## formatGeneralGene - general formatting for all keys
##------------------------------------------------------------------------------
## string $key
sub formatGeneralGene # (string $key)
{
  my $key = shift;

  # Make lower-case characters upper-case
  $key =~ tr/a-z/A-Z/;

  # Remove leading and trailing spaces
  $key =~ s/^\s+//;
  $key =~ s/\s+$//;

  return $key;
}

##------------------------------------------------------------------------------
## formatGene
##------------------------------------------------------------------------------
# (string $key, string $database)
sub formatGene # (string $key, string $database)
{
  my $key = shift;
  my $database = &getMapDatabaseName(shift,&getMapEntityName('Gene'));

  $key = &formatGeneralGene($key);

  if($database eq 'Ncbi' and length(&hasNcbiGi($key))>0)
  {
    ($key,$database) = &extractNcbiGi($key);
    ($key,$database) = &formatGene($key,$database);
  }
  
  elsif($database eq 'Refseq')
  {
    $key = &formatRefseqAccession($key);
  }

  elsif($database eq 'Genbank')
  {
    $key = &formatGenbankAccession($key);
  }

  elsif($database eq 'Wormbase')
  {
    $key = &formatWormbaseGene($key);
  }

  return ($key,$database);
}

##------------------------------------------------------------------------------
## extractKey
##------------------------------------------------------------------------------
# (string $key, string $database)
sub extractKey # (string $text, string $entity, string $organism, string @databases)
{
  my $text = shift;
  my $entity = shift;
  my $organism = shift;
  my @databases = @_;

  my $key = '';
  my $database = '';
  my $map_entity = &getMapEntityName($entity);
  my $map_organism = &getMapOrganismName($organism);
  my @map_databases;

  # If no databases were supplied find all the valid MAP databases
  if($#databases==-1)
  {
    @map_databases = &getMapDatabaseNames($map_entity);
  }
  else
  {
    foreach $database (@databases)
    {
      my $map_database = &getMapDatabaseName($database,$map_entity);
      if($map_database =~ /\S/)
      {
        push(@map_databases,$map_database);
      }
    }
  }

  my @map_organisms;
  if($map_organism =~ /\S/)
  {
    @map_organisms = ($map_organism);
  }
  # If no organism is supplied try all the MAP organisms.
  else
  {
    @map_organisms = &getMapOrganismNames();
  }

  foreach $map_organism (@map_organisms)
  {
    foreach my $map_database (@map_databases)
    {
      if($map_organism eq 'Any')
      {
        ($key,$map_database) = &extractAnyKey($text,$map_entity,$map_database);
      }

      elsif($map_organism eq 'Ecoli')
      {
        $key = &extractEcoliKey($text,$map_entity,$map_database);
      }

      elsif($map_organism eq 'Fly')
      {
        $key = &extractFlyKey($text,$map_entity,$map_database);
      }

      elsif($map_organism eq 'Human')
      {
        $key = &extractHumanKey($text,$map_entity,$map_database);
      }

      elsif($map_organism eq 'Worm')
      {
        $key = &extractWormKey($text,$map_entity,$map_database);
      }

      elsif($map_organism eq 'Yeast')
      {
        $key = &extractYeastKey($text,$map_entity,$map_database);
      }

      if(length($key)>0)
      {
        return ($key,$map_database);
      }
    }
  }

  # We couldn't find anything so try a general extraction for this organism
  return extractAnyKey($text,$entity,@databases);
}

##------------------------------------------------------------------------------
## extractAnyKey
##------------------------------------------------------------------------------
sub extractAnyKey # ($text,$entity,@databases)
{
  my $text = shift;
  my $entity = shift;
  my @databases = @_;

  my $map_entity = &getMapEntityName($entity);
  my $key = '';

  if(length($map_entity)==0)
  {
    return ('','');
  }

  my @map_databases;
  if($#databases>=0)
  { 
    foreach my $database (@databases)
    {
      my $map_database = &getMapDatabaseName($database,$entity);
      if($map_database =~ /\S/)
      {
        push(@map_databases,$map_database);
      }
    }
  }
  else
  { 
    @map_databases = &getMapDatabaseNames($entity);
  }

  foreach my $map_database (@map_databases)
  {
    if($map_database eq 'Ncbi' and length(&hasNcbiGi($text))>0)
    {
      ($key,$map_database) = &extractNcbiGi($text,$map_entity);
      # print STDERR "[$key,$map_database] --> ";
      # ($key,$map_database) = &formatGene($key,$map_database);
      ($key,$map_database) = &extractAnyKey($key,$map_entity,$map_database);
      # print STDERR "[$key,$map_database]\n";
    }
    elsif($map_database eq 'Image')
    {
      $key = &hasImageAccession($text,$map_entity);
    }
    elsif($map_database eq 'Genbank')
    {
      $key = &hasGenbankAccession($text,$map_entity);
    }
    elsif($map_database eq 'Locuslink')
    {
      $key = &hasLocuslinkAccession($text,$map_entity);
    }
    elsif($map_database eq 'Refseq')
    {
      $key = &hasRefseqAccession($text,$map_entity);
    }
    elsif($map_database eq 'None')
    {
      $text =~ s/^\s+//;
      $text =~ s/\s+$//;
      $text =~ s/(\s)\s+/\1/g;
      $text =~ tr/a-z/A-Z/;
      $key = $text;
    }

    if(length($key)>0)
    {
      return ($key,$map_database);
    }
  }
  return ('','');
}

##------------------------------------------------------------------------------
## getMapAliasesFile
##
##  Returns the MAP location of the alias file corresponding to the database
##  provided.  The file maps MAP keys to the databases equivalent.
##------------------------------------------------------------------------------
sub getMapAliasesFile # (string $entity, string $organism, string $database)
{
  my $entity   = &getMapEntityName(shift);
  my $organism = &getMapOrganismName(shift);
  my $database = &getMapDatabaseName(shift,$entity);
  my $file = '';

  if(length($entity)>0)
  {
    $file = &getMapDir('Aliases') . "/$entity";
    if(length($organism)>0)
    {
      $file .= "/$organism";
    }

    if(length($database)>0 and $database ne 'None')
    {
      $file .= "/$database";
    }
  }

  $file .= '/data.tab';

  return $file;
}

##------------------------------------------------------------------------------
## getMapTableDelim
##
##   Returns the file delimiter for MAP data tables.
##------------------------------------------------------------------------------
sub getMapTableDelim
{
  return "\t";
}

##------------------------------------------------------------------------------
## getMapAliases
##
##   Returns an associative array mapping aliases from keys in the given
##   database to keys in MAP.
##------------------------------------------------------------------------------
# \%aliases
sub getMapAliases # (string $entity,string $organism,string $database)
{
  my $entity   = shift;
  my $organism = shift;
  my $database = shift;
  my $file = &getMapAliasesFile($entity,$organism,$database);
  my %aliases;
  my $delim = &getMapTableDelim();
  print STDERR "\nMap alias file = '$file'\n";
  if(open(FILE,$file))
  {
    while(<FILE>)
    {
      if(/\S/)
      {
        chomp;
        my ($key,$alias) = split($delim);
        $aliases{$alias} = $key;
      }
    }
    close(FILE);
  }
  else
  {
    print STDERR "WARNING: Could not open alias file '$file' for organism ",
                 "'$organism' and database '$database'.\n";
  }
  return \%aliases;
}

##------------------------------------------------------------------------------
##
##------------------------------------------------------------------------------
sub convertSymbol2MapOrganismName # ($symbol)
{
  my $symbol = shift;
  my $organism = '';
  if($symbol =~ /^Ec$/i)
  {
    $organism = &getMapOrganismName('ecoli');
  }
  elsif($symbol =~ /^Dm$/i)
  {
    $organism = &getMapOrganismName('fly');
  }
  elsif($symbol =~ /^Hs$/i)
  {
    $organism = &getMapOrganismName('human');
  }
  elsif($symbol =~ /^Ce$/i)
  {
    $organism = &getMapOrganismName('worm');
  }
  elsif($symbol =~ /^Sc$/i)
  {
    $organism = &getMapOrganismName('yeast');
  }
  elsif($symbol =~ /^Mm$/i)
  {
    $organism = &getMapOrganismName('mouse');
  }
  elsif($symbol =~ /^Rn$/i)
  {
    $organism = &getMapOrganismName('rat');
  }
  return $organism;
}

##------------------------------------------------------------------------------
## getMapGeneSetsName
##------------------------------------------------------------------------------
sub getMapGeneSetsName # ($string)
{
  my $string = shift;
  my $name = '';

  if($string =~ /go/i)
  {
    $name = 'GO';
  }

  elsif($string =~ /kegg/i)
  {
    $name = 'KEGG';
  }

  elsif($string =~ /proteome/i or 
        $string =~ /wormpd/i or
        $string =~ /ypd/i)
  {
    $name = 'Proteome';
  }

  elsif($string =~ /sgd/i)
  {
    $name = 'SGD';
  }
  
  elsif($string =~ /compendium/i)
  {
    $name = 'Compendium';
  }
  
  return $name;
}

##------------------------------------------------------------------------------
## Converts the given name into how MAP would use it in a file name.
##------------------------------------------------------------------------------
sub formatMapFileName # ($name)
{
  my $name = shift;

  # Make everything lower-case.
  $name =~ tr/A-Z/a-z/;

  return $name;
}

##------------------------------------------------------------------------------
## Converts the given name into how MAP would name a directory for it.
##------------------------------------------------------------------------------
sub formatMapDirName # ($name)
{
  my $name = shift;

  # Make the first letter uppercase and the rest lower case:
  $name =~ tr/A-Z/a-z/;
  my $first_letter = substr($name,0,1);
  $name = substr($name,1,length($name)-1);
  $first_letter =~ tr/a-z/A-Z/;
  $name = $first_letter . $name;

  return $name;
}

##------------------------------------------------------------------------------
##
##------------------------------------------------------------------------------
sub getMapOrganismFromPath # ($path)
{
  my $path   = shift;
  for(my $prefix = $path; length($prefix)>0; $prefix = &getPathPrefix($prefix))
  {
    my $suffix   = &getPathSuffix($prefix);
    my $organism = &getMapOrganismName($suffix);
    if(length($organism)>0)
    {
      return $organism;
    }
  }
}

##------------------------------------------------------------------------------
## getMapLogErrorHeader
##------------------------------------------------------------------------------
sub getMapLogErrorHeader # ($message)
{
  my $message = shift;
  my $date = `date`;
  my $header = 
    
  "##+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++\n" .
  "## Begin error log for '$0'\n" .
  "## Date: $date";
  if(length($message)>0)
  {
    $header .= "##\n##    Comments: $message\n";
  }
  $header .= "##+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++\n";
  
  return $header;
}

##------------------------------------------------------------------------------
##
##------------------------------------------------------------------------------
sub getMapLogErrorFooter # ($message)
{
  my $message = shift;
  my $date = `date`;
  my $footer = 
    
  "##------------------------------------------------------------------------------\n" .
  "## End error log for '$0'\n";
  if(length($message)>0)
  {
    $footer .= "##\n##    Comments: $message\n";
  }
  $footer .= "##------------------------------------------------------------------------------\n";
  
  return $footer;
}

sub normalizeMapGeneDescription
{
  my $str = $_[0];
  $str =~ s/[\s]&[\s]/ and /g;
  $str =~ s/&[\s]/ and/g;
  $str =~ s/[\s]&/and /g;
  $str =~ s/&/ and /g;
  $str =~ s/\"//g;
  $str =~ s/\`//g;
  $str =~ s/\'//g;
  $str =~ s/\<//g;
  $str =~ s/\>//g;
  $str =~ s/\=//g;
  $str =~ s/\#//g;
  $str =~ s/\@//g;
  $str =~ s/\\//g;
  $str =~ s/[\/]//g;
  $str =~ s/[\+]//g;
  return $str;
}

#---------------------------------------------------------------------------
# removeIllegalChars
#---------------------------------------------------------------------------
sub removeIllegalChars
{
  my $str = $_[0];
  $str =~ s/[\s]&[\s]/ and /g;
  $str =~ s/&[\s]/ and/g;
  $str =~ s/[\s]&/and /g;
  $str =~ s/&/ and /g;
  $str =~ s/\"/ /g;
  $str =~ s/\`/ /g;
  $str =~ s/\'/ /g;
  $str =~ s/\;/ /g;
  $str =~ s/\:/ /g;
  $str =~ s/\!/ /g;
  $str =~ s/\)/ /g;
  $str =~ s/\</ /g;
  $str =~ s/\>/ /g;
  $str =~ s/\(/ /g;
  $str =~ s/\=/ /g;
  $str =~ s/\#/ /g;
  $str =~ s/\@/ /g;
  $str =~ s/\\/ /g;
  $str =~ s/[\/]/ /g;
  $str =~ s/[\+]/ /g;
  $str =~ s/[ ]+/ /g;
  return $str;
}

#---------------------------------------------------------------------------
# removeIllegalXMLChars
#---------------------------------------------------------------------------
sub removeIllegalXMLChars
{
  my $str = $_[0];
  $str =~ s/\&/&amp;/g;
  $str =~ s/\"/&quot;/g;
  $str =~ s/\'/&apos;/g;
  $str =~ s/\</&lt;/g;
  $str =~ s/\>/&gt;/g;
  return $str;
}

1
