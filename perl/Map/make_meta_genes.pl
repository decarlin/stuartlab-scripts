#!/usr/bin/perl

use strict;

require "$ENV{MYPERLDIR}/lib/libmap.pl";

my $meta_gene_dir = &getMapDir('Data') . '/MetaGene';
my $meta_gene_type = '';

my @organisms;
my @orf_lists;
my $delim = "\t";
my $col = 1;
my $suffix = '';
my $ghosts = 0;
my $lists = 1;
while(@ARGV)
{
  my $arg = shift @ARGV;

  if($arg eq '--help')
  {
    print STDOUT <DATA>;
    exit(0);
  }
  elsif($arg eq '-k')
  {
    $col = int(shift @ARGV);
  }
  elsif($arg eq '-d')
  {
    $delim = shift @ARGV;
  }
  elsif($arg eq '-suffix')
  {
    $suffix = shift @ARGV;
  }
  elsif($arg eq '-ghosts')
  {
    $ghosts = 1;
  }
  elsif($arg eq '-lists')
  {
    $lists = 1;
  }
  elsif($arg =~ /^([^=]+)=([^=]+)$/)
  {
    my $organism = $1;
    my $orf_list = $2;

    $organism =~ tr/[A-Z]/[a-z]/;
    my $org_first_letter = substr($organism, 0, 1);
    my $org_remaining = substr($organism, 1, length($organism)-1);
    $org_first_letter =~ tr/[a-z]/[A-Z]/;
    $organism = $org_first_letter . $org_remaining;
    # print STDERR "[$organism]\n";
    push(@organisms,$organism);
    push(@orf_lists, $orf_list);
  }
  elsif(length($meta_gene_type)==0)
  {
    $meta_gene_type = $arg;
  }
  else
  {
    die("Bad argument '$arg' given.");
  }
}
$col--;

length($meta_gene_type)>0 or die("Please supply a meta-gene source.");

my $meta_gene_type_dir = "$meta_gene_dir/$meta_gene_type/";
(-d $meta_gene_type_dir) or die("No meta-gene source directory '$meta_gene_type_dir'.");

# (1) Collect all the orfs in each species
my %organisms_orfs;
for(my $i=0; $i<=$#orf_lists; $i++)
{
  my $orf_list = $orf_lists[$i];
  my $organism = $organisms[$i];
  my %orfs;

  if($ghosts)
  {
    $orf_list = &convert_if_ghost($orf_list);
  }


  if($orf_list ne '.')
  {
    (-f $orf_list) or die("List '$orf_list' not a regular file.");
    open(ORFS,$orf_list) or die("Could not open orf_list file '$orf_list' for reading.");

    while(<ORFS>)
    {
      if(/\S/)
      {
        chomp;
	my @tuple = split($delim);
	my $gene  = $tuple[$col];
	$orfs{$gene} = 1;
      }
    }
    close(ORFS);
  }
  $organisms_orfs{$organism} = \%orfs;
}

# (2) Collect all the meta-genes covered by the orfs in all the species' gene lists.
my %meta_genes;
foreach my $organism (@organisms)
{
  my %orf_included = %{$organisms_orfs{$organism}};
  my $meta_gene_data = "$meta_gene_type_dir/$organism/data.tab";
  (-f $meta_gene_data) or die("No meta-gene source file '$meta_gene_data'.");
  open(METAGENES,$meta_gene_data) or die("Could not open file '$meta_gene_data'.");
  while(<METAGENES>)
  {
    if(/\S/)
    {
      chomp;
      my($meta_gene,$orf) = split($delim);
      if($meta_gene ne 'METAGENE' and exists($orf_included{$orf}))
      {
        # print STDERR "[$organism] [$meta_gene] [$orf]\n";
	$meta_genes{$meta_gene} = 1;
      }
    }
  }
  close(METAGENES);
}

# (3) Collect all the orfs from all the species that are in the meta-genes found from (2)
foreach my $organism (@organisms)
{
  my $meta_gene_data = "$meta_gene_type_dir/$organism/data.tab";
  (-f $meta_gene_data) or die("No meta-gene source file '$meta_gene_data'.");
  open(METAGENES,$meta_gene_data) or die("Could not open file '$meta_gene_data'.");
  my $meg_file = &make_file($organism,$meta_gene_type,$suffix,'.meg');
  my $list_file = undef;
  if($lists)
  {
    $list_file = &make_file($organism,$meta_gene_type,$suffix,'.lst');
  }
  my %orf_printed;
  while(<METAGENES>)
  {
    if(/\S/)
    {
      chomp;
      my($meta_gene,$orf) = split($delim);
      if($meta_gene eq 'METAGENE')
      {
        print $meg_file "gene_name\tmeta_gene_name\n";
      }
      elsif(exists($meta_genes{$meta_gene}))
      {
        print $meg_file "$orf\t$meta_gene\n";

	if($lists)
	{
          print $list_file "$orf\n";
	}

	$orf_printed{$orf} = 1;
      }
    }
  }

  my %orf_included = %{$organisms_orfs{$organism}};
  foreach my $orf (keys(%orf_included))
  {
    if(not(exists($orf_printed{$orf})))
    {
      print $meg_file "$orf\t$orf\n";
      if($lists)
      {
        print $list_file "$orf\n";
      }
    }
  }

  close(METAGENES);
  close($meg_file);

  if($lists)
  {
    close($list_file);
  }

}

exit(0);

sub make_file
{
  my $organism = shift;
  my $type = shift;
  my $suffix = shift;
  my $extension = shift;

  $organism =~ tr/[A-Z]/[a-z]/;
  $type =~ tr/[A-Z]/[a-z]/;

  my $filename = $type . '_' . $organism;
  $filename   .= (length($suffix)>0) ? '_' . $suffix : '';
  $filename   .= $extension;

  my $file;
  open($file,">$filename") or die("Could not open file '$filename' for writing.");
  return $file;
}

sub convert_if_ghost # ($file)
{
  my $file = shift;

  if(not(-f $file))
  {
    $file = '.';
  }
  return $file;
}

__DATA__
syntax: make_meta_orfs.pl [OPTIONS] MEGTYPE ORG1=ORFS1 [ORG2=ORFS2 ...]

Takes a list of organism=orf_list pairs and constructs meta-gene mappings for each
organism.  It outputs the files:

	MEGTYPE_ORG1.meg
	MEGTYPE_ORG2.meg

where MEGTYPE and the ORGi's are converted to lowercase from their original.  For example:

	cogs_yeast.meg
	cogs_worm.meg

would be generated if the Cogs meta-gene type is used.

MEGTYPE - Must match one of the subdirectory names under ~/Map/Data/MetaGene (e.g. Cogs)

ORGi - ith organism suffix (e.g. yeast, worm, fly, human).  Use the common suffix (case does not
       matter).

ORFSi - a tab-delimited file containing a list of orfs.  If the symbol '.' is given then
        only orfs found in meta-gene groups from the other organisms will be included in the
	output.


OPTIONS are:

-suffix NAME: Specify a suffix NAME to add to the output filenames.  The script will now produce
              the files:

	        MEGTYPE_ORG1_NAME.meg
	        MEGTYPE_ORG2_NAME.meg

        for example:

                cogs_yeast_cellcycle.meg
	        cogs_worm_cellcycle.meg

-ghosts: Allow file names to be passed in as arguments that do not exist.  These arguments
         are treated the same as '.' passed in.

-lists: In addition to printing out *.meg files this prints out *.lst files that contain
        only the gene names that were included.  These files contain the same result that
	would be obtained if a cut -f 1 were used on the *.meg files.

