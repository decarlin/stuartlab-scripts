require "$ENV{MYPERLDIR}/lib/libmap.pl";
require "$ENV{MYPERLDIR}/lib/libfile.pl";

##------------------------------------------------------------------
## parseMapEvalAnnotPath
##------------------------------------------------------------------
sub parseMapEvalAnnotPath # ($file)
{
  my $file        = shift;
  my $run         = &getMapRunFromEvalAnnotPath($file);
  my $organism    = &getMapOrganismFromEvalAnnotPath($file);
  my $annot_group = &getMapAnnotGroupFromEvalAnnotPath($file);

  return($run,$organism,$annot_group);
}

##------------------------------------------------------------------
## getMapRunFromEvalAnnotPath
##------------------------------------------------------------------
sub getMapRunFromEvalAnnotPath # ($file)
{
  my $file = shift;
  my $run  = '';

  if($file =~ /^(g[^\/]+)\//)
    { $run = $1; }
  elsif($file =~ /^(g[^\/]+$)/)
    { $run = $1; }
  elsif($file =~ /\/(g[^\/]+)\//)
    { $run = $1; }
  elsif($file =~ /\/(g[^\/]+$)/)
    { $run = $1; }

  return $run;
}

##------------------------------------------------------------------
##
##------------------------------------------------------------------
sub getMapOrganismFromEvalAnnotPath # ($file)
{
  my $file = &remPathExt(&getPathSuffix(shift));
  my $organism = '';
  if($file =~ /^([^_]+)_[^_]+$/)
  {
    $organism = $1;
  }
  return &getMapOrganismName($organism);
}

##------------------------------------------------------------------
##
##------------------------------------------------------------------
sub getMapAnnotGroupFromEvalAnnotPath # ($file)
{
  my $file = &remPathExt(&getPathSuffix(shift));
  my $annot_group = '';
  if($file =~ /^[^_]+_([^_]+)$/)
  {
    $annot_group = $1;
  }
  return &getMapAnnotGroupName($annot_group);
}

##------------------------------------------------------------------
##
##------------------------------------------------------------------
sub getMapEvalAnnotStats # ($line)
{
  my $line       = shift;
  my $annot      = &getMapEvalAnnotName($line);
  my $pvalue     = &getMapEvalAnnotPvalue($line);
  my $overlaps   = &getMapEvalAnnotOverlaps($line);
  my $num_data   = &getMapEvalAnnotNumData($line);
  my $num_global = &getMapEvalAnnotNumGlobal($line);

  return ($annot,$pvalue,$overlaps,$num_data,$num_global);
}

##------------------------------------------------------------------
##
##------------------------------------------------------------------
sub getMapEvalAnnotName # ($line)
{
  my $line = shift;
  my $annot = '';
  if($line =~ /^([^\[]+)\[[^\]]+\]/)
  {
    $annot = $1;
    $annot =~ s/^\s+//;
    $annot =~ s/\s+$//;
  }
  return $annot;
}

##------------------------------------------------------------------
##
##------------------------------------------------------------------
sub getMapEvalAnnotPvalue # ($line)
{
  my $line = shift;
  my $pvalue = 1;
  if($line =~ /^[^\[]+\[([^\]]+)\]/)
  {
    $pvalue = $1;
  }
  return $pvalue;
}

##------------------------------------------------------------------
##
##------------------------------------------------------------------
sub getMapEvalAnnotOverlaps # ($line)
{
  my $line = shift;
  my $overlaps = 0;
  if($line =~ /\[Counts=(\d+)\]/)
  {
    $overlaps = int($1);
  }
  return $overlaps;
}

##------------------------------------------------------------------
##
##------------------------------------------------------------------
sub getMapEvalAnnotNumData # ($line)
{
  my $line = shift;
  my $num_data = 0;
  if($line =~ /\[Dataset True=(\d+)\]/)
  {
    $num_data = int($1);
  }
  return $num_data;
}

##------------------------------------------------------------------
##
##------------------------------------------------------------------
sub getMapEvalAnnotNumGlobal # ($line)
{
  my $line = shift;
  my $num_global = 0;
  if($line =~ /\[Global True=(\d+)\]/)
  {
    $num_global = int($1);
  }
  return $num_global;
}

1
