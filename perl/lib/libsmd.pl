##---------------------------------------------------------------------------------
## Routines for manipulating data from SMD
##---------------------------------------------------------------------------------

use strict;

require "$ENV{MYPERLDIR}/lib/libfile.pl";
require "$ENV{MYPERLDIR}/lib/libmap.pl";

##---------------------------------------------------------------------------------
##
##---------------------------------------------------------------------------------
my %MapSmdDir =
(
  'Experiments'     => &getMapDir('Data') . '/Expression/Any/Smd/Remote',
  'Publications'    => &getMapDir('Data') . '/Expression/Any/Smd/Remote',
  'ExperimentSets'  => &getMapDir('Data') . '/Expression/Any/Smd/Remote'
);
sub getMapSmdDir # ($type)
{
  my $type     = shift;
  return $MapSmdDir{$type};
}

##---------------------------------------------------------------------------------
## getMapOrganismNameFromSmdXlsGzip - returns the MAP standard organism name for
## the SMD experiment.
##---------------------------------------------------------------------------------
sub getExptNameFromSmdXlsGzip # ($file_xls_gz)
{
  my $file_xls_gz = shift;

  if(-f $file_xls_gz)
  {
    open(PIPE, "zcat < $file_xls_gz | strings |") or die("Could not zcat '$file_xls_gz'.");
    my $first_line = <PIPE>;
    if($first_line =~ /^\!Exptid=(\d+)\s*$/)
    {
      while(<PIPE>)
      {
        if(/^\!Experiment\s+Name\s*=\s*(.+)$/)
        {
          close(PIPE);
          my $name = $1;
          $name =~ s/^\s+//;
          $name =~ s/\s+$//;
          $name =~ s/(\s)\s+/\1/g;
          $name =~ s/\s/_/g;
          $name =~ s/['"\(\)]//g;
          $name =~ s/\W/_/g;
          $name =~ s/[_]+/_/g;
          return $name;
        }
      }
    }
  }
}

##---------------------------------------------------------------------------------
## getMapOrganismNameFromSmdXlsGzip - returns the MAP standard organism name for
## the SMD experiment.
##---------------------------------------------------------------------------------
sub getMapOrganismNameFromSmdXlsGzip # ($file_xls_gz)
{
  my $file_xls_gz = shift;

  if(-f $file_xls_gz)
  {
    open(PIPE, "zcat < $file_xls_gz | strings |") or die("Could not zcat '$file_xls_gz'.");

    # Only look if this is an SMD Excel file containing !Exptid as the first line.
    my $first_line = <PIPE>;
    if($first_line =~ /^\!Exptid=(\d+)\s*$/)
    {
      while(<PIPE>)
      {
        if(/^\!Organism=(.+)$/)
        {
          close(PIPE);
          my $organism = $1;
          my $map_organism = &getMapOrganismName($organism);
          return length($map_organism)>0 ? $map_organism : $organism;
        }
      }
    }
    close(PIPE);
  }
  return '';
}

##---------------------------------------------------------------------------------
## getSmdExptIdsFromExptSetMeta
##
## This is currently a hack since it does not parse XML, it just looks for
## !Exptid=???? to get the experiment id (-js 5/31/02).
##---------------------------------------------------------------------------------
sub getSmdExptIdsFromExptSetMeta # (@file_exptset_meta)
{
  my @exptids;
  foreach my $file_exptset_meta (@_)
  {
    # Just read in the whole file into 1 string.
    open(META,$file_exptset_meta) or 
      die("Could not open SMD exptset meta file '$file_exptset_meta'.");
    my @lines  = <META>;
    close(META);

    # Tokenize the whole file.
    my @tokens = split(/\s+/, join(" ",@lines));

    foreach my $token (@tokens)
    {
      if($token =~ /\!Exptid\s*=\s*(\d+)/i)
      {
        push(@exptids,$1);
      }
    }
  }
  return @exptids;
}

##---------------------------------------------------------------------------------
## getMapOrganismNamesFromSmdExptSetMeta
##
##   Returns the MAP standard organism name for
##   the experiment set.  It does this by looking at each experiment in the set.
##
##   $file_exptset_meta -- SMD experiment set meta file
##   $smd_xls_dir       -- directory where experiments with names like ####.xls.gz
##                         reside.  The numbers should map to the exptid.  If no
##                         directory is supplied one is extracted from the path of
##                         the experiment set meta file.
##---------------------------------------------------------------------------------
sub getMapOrganismNamesFromSmdExptSetMeta # (@file_exptset_meta)
{
  my $smd_xls_dir = &getMapSmdDir('Experiments');
  my %organisms;
  foreach my $file_exptset_meta (@_)
  {
    # Get the experiment ids in this experimental set:
    my @exptids = &getSmdExptIdsFromExptSetMeta($file_exptset_meta);

    foreach my $exptid (@exptids)
    {
      my $file_xls_gz = $smd_xls_dir . '/' . $exptid . '.xls.gz';

      if(-f $file_xls_gz)
      {
        my $organism = &getMapOrganismNameFromSmdXlsGzip($file_xls_gz);
        if(length($organism)>0)
        {
          $organisms{$organism} = 1;
        }
      }
    }
  }
  my @organisms = sort(keys(%organisms));
  return @organisms;
}

##---------------------------------------------------------------------------------
##
##---------------------------------------------------------------------------------
sub getMapPublicationNameFromSmdPublicationMeta # (@file_publication_metas)
{
  my @publication_names;
  my %pubs;
  foreach my $file_publication_meta (@_)
  {
    my $author           = '';
    my $year             = '';

    # Just read in the whole file into 1 string.
    open(META,$file_publication_meta) or 
      die("Could not open SMD publication meta file '$file_publication_meta'.");
    while(<META>)
    {
      if(/\!Citation\s*=\s*(\S+)\s+\S+/i)
      {
        $author = $1;
        $year = '';
        if(/\!Citation\s*=\s*\S+\s+\S+\D+\d\d(\d\d)/i)
        {
          $year = $1;
        }
        elsif(/In\s+Press/i or
              /Submitted/i or
              /Accepted/i)
        {
          my $date = `date`;
          if($date =~ /\d\d(\d\d)\s*$/)
          {
            $year = "$1";
          }
        }
        else
        {
          $year = '--';
        }
      }
    }
    my $pub_name = $author . $year;
    $pub_name =~ s/,//g;
    $pubs{$pub_name}++;
    close(META);
  }
  foreach my $publication_name (sort(keys(%pubs)))
  {
    my $n = $pubs{$publication_name};
    if($n>1)
    {
      my $letter = 'a';
      for(my $i=0; $i<=$n; $i++)
      {
        push(@publication_names, $publication_name . $letter);
        $letter++;
      }
    }
    else
    {
        push(@publication_names, $publication_name);
    }
  }
  return @publication_names;
}

##---------------------------------------------------------------------------------
##
##---------------------------------------------------------------------------------
sub getSmdExptSetsFromPublicationMeta # (@file_publication_metas)
{
  my %exptsets;
  foreach my $file_publication_meta (@_)
  {
    # Just read in the whole file into 1 string.
    open(META,$file_publication_meta) or 
      die("Could not open SMD publication meta file '$file_publication_meta'.");
    my @lines  = <META>;
    close(META);

    # Tokenize the whole file.
    my @tokens = split(/\s+/, join(" ",@lines));

    foreach my $token (@tokens)
    {
      if($token =~ /\!ExptSetNo\s*=\s*(\d+)/i)
      {
        $exptsets{$1} = 1;
      }
    }
  }
  my @exptsets = sort(keys(%exptsets));
  return @exptsets;
}

##---------------------------------------------------------------------------------
##
##---------------------------------------------------------------------------------
sub getSmdExptIdsFromPublicationMeta # (@file_publication_meta)
{
  my %exptids;
  my @exptsets = &getSmdExptSetsFromPublicationMeta(@_);

  foreach my $exptset (@exptsets)
  {
    my $file_exptset_meta = &getMapSmdDir('ExperimentSets') . '/exptset_' . $exptset . '.meta';
    my @exptids = &getSmdExptIdsFromExptSetMeta($file_exptset_meta);
    foreach my $exptid (@exptids)
    {
      $exptids{$exptid} = 1;
    }
  }
  my @exptids = sort(keys(%exptids));
  return @exptids;
}

##---------------------------------------------------------------------------------
##
##---------------------------------------------------------------------------------
sub getMapOrganismNamesFromSmdPublicationMeta # (@file_publication_meta)
{
  my @exptids   = &getSmdExptIdsFromPublicationMeta(shift);
  my %organisms;
  foreach my $exptid (@exptids)
  {
    my $file = &getMapSmdDir('Experiments') . "/$exptid.xls.gz";
    my $organism  = &getMapOrganismNameFromSmdXlsGzip($file);
    $organisms{$organism} = 1;
  }
  my @organisms = sort(keys(%organisms));
  return @organisms;
}

##---------------------------------------------------------------------------------
##
##---------------------------------------------------------------------------------
sub getSmdDataSource # ($organism)
{
  my ($organism)  = @_;
  my $data_source = '';
  if($organism eq 'Human')
  {
    $data_source = 'Image';
  }
  elsif($organism eq 'Worm')
  {
    $data_source = 'Wormbase';
  }
  elsif($organism eq 'Yeast')
  {
    $data_source = 'Sgd';
  }
  return $data_source;
}

sub getSmdExptInfoFromXls
{
   my ($xls) = @_;

   my $filep = &openFile($xls);

   my $exptid = undef;

   my $exptname = undef;

   while(my $line = <$filep>)
   {
      if($line =~ /!Exptid\s*=\s*(\d+)/i)
      {
         $exptid = $1;
      }
      if($line =~ /!Experiment\s+Name\s*=\s*(.+)/i)
      {
         $exptname = $1;
      }
   }
   close($filep);

   return ($exptid, $exptname);
}

1
