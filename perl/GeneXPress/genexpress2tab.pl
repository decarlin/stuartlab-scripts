#!/usr/bin/perl

use strict;

my $arg;
my $verbose=1;
my @cluster_files;
my $regulator_file='';
my $delim = "\t";
my $depth = -1;
my $gxc_format = 0;
my $suppress_orfs = 0;

while(@ARGV)
{
  $arg = shift @ARGV;

  if($arg eq '--help')
  {
    print STDOUT <DATA>;
    exit(0);
  }
  elsif($arg eq '-q')
  {
    $verbose = 0;
  }
  elsif($arg eq '-depth' or $arg eq '-d')
  {
    $depth = int(shift @ARGV);
  }
  elsif($arg eq '-gxc' or $arg eq '-g')
  {
    $gxc_format = 1;
  }
  elsif($arg eq '-sup' or $arg eq '-s')
  {
    $suppress_orfs = 1;
  }
  elsif((-f $arg) and length($regulator_file)<1)
  {
    $regulator_file = $arg;
  }
  elsif(-f $arg)
  {
    push(@cluster_files,$arg);
  }
  else
  {
    print STDERR "Bad argument '$arg' given.  Use --help for help.\n";
    exit(1);
  }
}

if(length($regulator_file)<1)
{
  print STDERR "Must supply a regulator file.  Use the --help flag for help.\n";
  exit(-2);
}

if(not(open(REG,$regulator_file)))
{
  print STDERR "Could not open the regulator file '$regulator_file'.\n";
  exit(-2);
}

my $line=0;
my %clust2reg; # maps cluster files to their regulators.

not($verbose) or print STDERR "Reading regulator file '$regulator_file'...";
my $clust;
my $reg;
my @regs;
my %reg_graph;
my %is_reg;
while(<REG>)
{
  $line++;
  if(/\S/ and not(/^\s*#/))
  {
    chop;
    ($clust,@regs) = split($delim);
    $clust = &fix($clust);
    for(my $i=$#regs; $i>=0; $i--)
    {
      $regs[$i] = &fix($regs[$i]);
      if(not($regs[$i]=~/\S/))
      {
        splice(@regs,$i,1);
      }
    }
    my $mydepth = ($depth==-1 or $depth>$#regs) ? $#regs : $depth;
    for(my $i=0; $i<=$mydepth; $i++)
    {
      $reg_graph{$regs[$i] . $delim . $clust} = 1;
      $is_reg{$regs[$i]} = 1;
    }
    $clust2reg{$clust} = join($delim,@regs);
  }
}
close(REG);
not($verbose) or print STDERR " done.\n";

if($#cluster_files<0)
{
  print STDERR "Must supply at least one cluster file.\n";
  exit(-3);
}

my %orf_graph;
my $orf;
my %orf_cluster_count;
my %seen_orf;

my $count;
while(@cluster_files)
{
  my $file = shift @cluster_files;
  if(not(open(FILE,$file)))
  {
    not($verbose) or 
      print STDERR "Could not open cluster file '$file'.  Skipping.\n";
  }
  else
  {
    not($verbose) or print STDERR "Reading file '$file'...";

    if($gxc_format)
    {
      $clust = '';
      while(<FILE>)
      {
	chop;
        if(/^Cluster\s+(\d+)/)
	{
	  $clust = int($1);
          if(not(exists($clust2reg{$clust})) or length($clust2reg{$clust})<1)
          {
            not($verbose) or 
               print STDERR "No regulator known for cluster '$clust'.\n";
            exit(-2);
          }
          @regs = split($delim,$clust2reg{$clust});
	  # print STDERR "Regulator '", join($delim,@regs), "'\n";
	}
	elsif(/\S/ and not(/^[=]+$/))
	{
          ($orf) = split($delim);
	  $orf = &fix($orf);
	  if($seen_orf{$orf})
	  {
	    print STDERR "WARNING: ORF '$orf' in both '$clust'",
	                   " and '$seen_orf{$orf}'!\n";
	  }

	  my $mydepth = ($depth==-1 or $depth>$#regs) ? $#regs : $depth;
	  # print STDERR "[$mydepth] [$depth] [$#regs]\n";
	  for(my $i=0; $i<=$mydepth; $i++)
	  {
            $orf_graph{$regs[$i] . $delim . $orf} = 1;
	    # The ORF is a regulator.
	    if($is_reg{$orf})
	    {
	      $reg_graph{$regs[$i] . $delim . $orf} = 1;
	    }
	  }
	  $orf_cluster_count{$orf} = exists($orf_cluster_count{$orf}) ?
	                             $orf_cluster_count{$orf} + 1 : 1;
          $seen_orf{$orf} = $clust;

	  $count = $orf_cluster_count{$orf};
	  # print STDERR "'", join(":",@regs), "' -> '$orf' found (orf count = $count)\n";

	}
      }
    }
    elsif($file =~ /^(\d+)/)
    {
      $clust = int($1);

      if(not(exists($clust2reg{$clust})) or length($clust2reg{$clust})<1)
      {
        not($verbose) or 
           print STDERR "No regulator known for cluster '$clust'.\n";
        exit(-2);
      }
      # $reg = $clust2reg{$clust};
      @regs = split($delim, $clust2reg{$clust});
      while(<FILE>)
      {
        chop;
        ($orf) = split($delim);
        $orf = &fix($orf);

        if($seen_orf{$orf})
        {
          print STDERR "ORF '$orf' in both '$clust' and '$seen_orf{$orf}'!\n";
	}

	# foreach $reg (@regs)
	my $mydepth = ($depth==-1 or $depth>$#regs) ? $#regs : $depth;
	# print STDERR "[$mydepth] [$depth] [$#regs]\n";
	for(my $i=0; $i<=$mydepth; $i++)
	{
          $orf_graph{$regs[$i] . $delim . $orf} = 1;
	  if($is_reg{$orf})
	  {
	    $reg_graph{$regs[$i] . $delim . $orf} = 1;
	  }
	}
	$orf_cluster_count{$orf} = exists($orf_cluster_count{$orf}) ?
	                             $orf_cluster_count{$orf} + 1 : 1;
        $seen_orf{$orf} = $clust;
      }
    }
    not($verbose) or print STDERR " done.\n";
    close(FILE);
  }
}

my $edge;
if(not($suppress_orfs))
{
  foreach $edge (keys(%orf_graph))
  {
    ($reg,$orf) = split($delim,$edge);
    $count = $orf_cluster_count{$orf};

    # print STDERR "'$orf' '$count'\n";

    print "$reg\t$orf\n";
  }
}
else
{
  foreach $edge (keys(%reg_graph))
  {
    ($reg,$clust) = split($delim,$edge);
    print "$reg\t$clust\n";
  }
}

exit(0);

sub fix
{
  my $orf = shift;
  $orf =~ s/_([^_]+)\s*$/.\1/;
  return $orf;
}

__DATA__

syntax: genexpress2dotty.pl [OPTIONS] REGULATORS CLUSTER1 [CLUSTER2...]

REGULATORS - a file with 2 or more tab-delimited columns.  first column has
  cluster numbers and the others list the ORF name of the regulators that
  were predicted by GeneXPress to regulate the genes in the cluster.

OPTIONS are:

  -q: Quiet mode: turn verbosity off (default verbose)
  -depth D: Only use regulators at depth D.  -1 one means infinite (default).
  -d D
  -gxc: Each is in GeneXPress cluster format.  Instead of having a single
  -g    list of genes these files can have multiple lists seperated by the
	keyword "Cluster N" where N is the cluster number, followed by a line
	of "=======".
  -sup: suppress printing single ORFs.  Just print regulators and clusters.
  -s

	

